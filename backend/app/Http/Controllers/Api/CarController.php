<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Brand;
use App\Models\Car;
use App\Models\CarImage;
use App\Models\Exhibition;
use App\Services\SubscriptionService;
use App\Support\MarketplaceSearch;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class CarController extends Controller
{
    public function __construct(private readonly SubscriptionService $subscriptions)
    {
    }

    public function index(Request $request)
    {
        $query = Car::with(['brand', 'exhibition.province', 'carImages'])
            ->where('is_active', true)
            ->whereHas('exhibition', fn ($q) => $q->where('is_active', true))
            ->latest();

        $this->applyFilters($query, $request);

        return response()->json($query->paginate((int) $request->query('per_page', 20)));
    }

    public function show(int $id)
    {
        $car = Car::with(['brand', 'exhibition.province', 'carImages'])
            ->where('is_active', true)
            ->whereHas('exhibition', fn ($q) => $q->where('is_active', true))
            ->findOrFail($id);

        $car->increment('views_count');

        return response()->json($car);
    }

    public function trackPhone(int $id)
    {
        $car = Car::where('is_active', true)
            ->whereHas('exhibition', fn ($q) => $q->where('is_active', true))
            ->findOrFail($id);

        $car->increment('phone_clicks_count');

        return response()->json([
            'message' => 'Phone click tracked',
            'phone_clicks_count' => $car->fresh()->phone_clicks_count,
        ]);
    }

    public function trackWhatsApp(int $id)
    {
        $car = Car::where('is_active', true)
            ->whereHas('exhibition', fn ($q) => $q->where('is_active', true))
            ->findOrFail($id);

        $car->increment('whatsapp_clicks_count');

        return response()->json([
            'message' => 'WhatsApp click tracked',
            'whatsapp_clicks_count' => $car->fresh()->whatsapp_clicks_count,
        ]);
    }

    public function mine(Request $request)
    {
        $query = Car::with(['brand', 'exhibition', 'carImages'])->latest();
        if (! $request->user()->isAdmin()) {
            $query->whereHas('exhibition', fn ($q) => $q->where('user_id', $request->user()->id));
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $data = $this->validateCar($request, true);
        $user = $request->user();
        $data = $this->resolveBrandId($data);
        $data = $this->applyCarDefaults($data, $user);

        $exhibition = Exhibition::findOrFail($data['exhibition_id']);

        if (! $user->isAdmin() && $exhibition->user_id !== $user->id) {
            abort(403, 'Not allowed to add cars to this showroom.');
        }

        if (! $user->isAdmin()) {
            $this->subscriptions->assertCanManageCars($exhibition);
        }

        $imagePaths = $this->storeUploadedImages($request);
        if ($request->filled('image_urls')) {
            $imagePaths = array_merge($imagePaths, $request->input('image_urls', []));
        }

        $data['images'] = empty($imagePaths) ? null : $imagePaths;
        $data['title'] = $data['title'] ?? $data['name'];
        unset($data['image_urls']);

        $car = Car::create($data);
        $this->syncCarImages($car, $imagePaths);

        return response()->json($car->load(['brand', 'exhibition', 'carImages']), 201);
    }

    public function update(Request $request, int $id)
    {
        $car = Car::with('exhibition')->findOrFail($id);
        $user = $request->user();

        if (! $user->isAdmin() && $car->exhibition->user_id !== $user->id) {
            abort(403, 'Not allowed to edit this car.');
        }

        if (! $user->isAdmin()) {
            $this->subscriptions->assertCanManageCars($car->exhibition);
        }

        $data = $this->validateCar($request, false);
        $data = $this->resolveBrandId($data);

        if (($data['reset_images'] ?? false) && $car->images) {
            $this->deleteStoredImages($car);
            $car->carImages()->delete();
            $car->images = null;
        }

        $newPaths = $this->storeUploadedImages($request);

        if ($request->boolean('update_images') || ! empty($newPaths) || ($data['reset_images'] ?? false)) {
            if ($data['reset_images'] ?? false) {
                $finalImages = $newPaths;
            } else {
                $kept = $this->normalizeKeptImages($request->input('keep_images', []));
                $finalImages = array_values(array_merge($kept, $newPaths));
            }

            $removed = array_diff($car->images ?? [], $finalImages);
            foreach ($removed as $path) {
                if (is_string($path) && ! str_starts_with($path, 'http')) {
                    Storage::disk('public')->delete($path);
                }
            }

            $data['images'] = empty($finalImages) ? null : $finalImages;
            $this->syncCarImages($car, $finalImages, true);
        }

        unset($data['image_urls'], $data['reset_images'], $data['exhibition_id'], $data['keep_images'], $data['update_images']);
        if (isset($data['name']) && ! isset($data['title'])) {
            $data['title'] = $data['name'];
        }

        $car->update($data);

        return response()->json($car->fresh()->load(['brand', 'exhibition', 'carImages']));
    }

    public function destroy(Request $request, int $id)
    {
        $car = Car::with('exhibition')->findOrFail($id);
        $user = $request->user();

        if (! $user->isAdmin() && $car->exhibition->user_id !== $user->id) {
            abort(403, 'Not allowed to delete this car.');
        }

        if (! $user->isAdmin()) {
            $this->subscriptions->assertCanManageCars($car->exhibition);
        }

        $this->deleteStoredImages($car);
        $car->carImages()->delete();
        $car->delete();

        return response()->json(['message' => 'Car deleted']);
    }

    public function stats(Request $request)
    {
        $user = $request->user();
        $query = Car::query();
        if (! $user->isAdmin()) {
            $query->whereHas('exhibition', fn ($q) => $q->where('user_id', $user->id));
        }

        return response()->json([
            'total_cars' => (clone $query)->count(),
            'total_views' => (clone $query)->sum('views_count'),
            'total_phone_clicks' => (clone $query)->sum('phone_clicks_count'),
            'total_whatsapp_clicks' => (clone $query)->sum('whatsapp_clicks_count'),
            'active_cars' => (clone $query)->where('is_active', true)->count(),
            'cars' => (clone $query)
                ->with(['brand', 'exhibition'])
                ->latest()
                ->get()
                ->map(fn (Car $car) => [
                    'id' => $car->id,
                    'title' => $car->display_title,
                    'brand_name' => $car->brand?->name,
                    'showroom_name' => $car->exhibition?->name,
                    'views_count' => $car->views_count,
                    'phone_clicks_count' => $car->phone_clicks_count,
                    'whatsapp_clicks_count' => $car->whatsapp_clicks_count,
                ]),
        ]);
    }

    private function applyFilters($query, Request $request): void
    {
        $terms = MarketplaceSearch::collectCarSearchTerms(
            $request->filled('search') ? (string) $request->query('search') : null,
            $request->filled('brand') ? (string) $request->query('brand') : null,
            $request->filled('model') ? (string) $request->query('model') : null,
            $request->filled('color') ? (string) $request->query('color') : null,
            $request->filled('fuel_type') ? (string) $request->query('fuel_type') : null,
            $request->filled('transmission') ? (string) $request->query('transmission') : null,
        );

        foreach ($terms as $term) {
            MarketplaceSearch::applyCarSearch($query, $term);
        }

        if ($request->filled('province_id')) {
            $query->whereHas('exhibition', fn ($q) => $q->where('province_id', (int) $request->query('province_id')));
        }

        if ($request->filled('exhibition_id')) {
            $query->where('exhibition_id', (int) $request->query('exhibition_id'));
        }

        if ($request->filled('brand_id')) {
            $query->where('brand_id', (int) $request->query('brand_id'));
        }

        if ($request->filled('year')) {
            $query->where('year', (int) $request->query('year'));
        }

        if ($request->filled('year_min')) {
            $query->where('year', '>=', (int) $request->query('year_min'));
        }

        if ($request->filled('year_max')) {
            $query->where('year', '<=', (int) $request->query('year_max'));
        }

        if ($request->filled('price_min')) {
            $query->where('price', '>=', (float) $request->query('price_min'));
        }

        if ($request->filled('price_max')) {
            $query->where('price', '<=', (float) $request->query('price_max'));
        }
    }

    private function validateCar(Request $request, bool $creating): array
    {
        $rules = [
            'brand_id' => ['nullable', 'exists:brands,id'],
            'brand' => ['nullable', 'string', 'max:255'],
            'title' => ['nullable', 'string', 'max:255'],
            'name' => ['nullable', 'string', 'max:255'],
            'model' => ['nullable', 'string', 'max:255'],
            'year' => ['nullable', 'integer', 'between:1950,2100'],
            'price' => ['nullable', 'numeric', 'min:0'],
            'color' => ['nullable', 'string', 'max:100'],
            'mileage' => ['nullable', 'integer', 'min:0'],
            'fuel_type' => ['nullable', 'string', 'max:50'],
            'transmission' => ['nullable', 'string', 'max:50'],
            'images' => ['nullable', 'array'],
            'images.*' => ['image', 'mimes:jpg,jpeg,png,webp,heic,heif', 'max:51200'],
            'image_urls' => ['nullable', 'array'],
            'image_urls.*' => ['string', 'max:255'],
            'keep_images' => ['nullable', 'array'],
            'keep_images.*' => ['string', 'max:500'],
            'description' => ['nullable', 'string'],
            'damage_notes' => ['nullable', 'string'],
            'reset_images' => ['nullable', 'boolean'],
            'update_images' => ['nullable', 'boolean'],
        ];

        if ($creating) {
            $rules['exhibition_id'] = ['nullable', 'exists:exhibitions,id'];
        } else {
            $rules['brand_id'] = ['sometimes', 'exists:brands,id'];
            $rules['name'] = ['sometimes', 'nullable', 'string', 'max:255'];
            $rules['model'] = ['sometimes', 'nullable', 'string', 'max:255'];
            $rules['year'] = ['sometimes', 'nullable', 'integer', 'between:1950,2100'];
            $rules['price'] = ['sometimes', 'nullable', 'numeric', 'min:0'];
        }

        return $request->validate($rules);
    }

    private function applyCarDefaults(array $data, $user): array
    {
        if (empty($data['exhibition_id'])) {
            $query = Exhibition::query();
            if (! $user->isAdmin()) {
                $query->where('user_id', $user->id);
            }
            $exhibition = $query->first();
            if (! $exhibition) {
                abort(422, 'لا يوجد معرض. أضف معرضاً أولاً.');
            }
            $data['exhibition_id'] = $exhibition->id;
        }

        if (empty($data['brand_id'])) {
            $brand = Brand::query()->first();
            if (! $brand) {
                abort(422, 'لا توجد ماركات في النظام.');
            }
            $data['brand_id'] = $brand->id;
        }

        $name = trim((string) ($data['name'] ?? ''));
        $data['name'] = $name !== '' ? $name : 'سيارة';
        $model = trim((string) ($data['model'] ?? ''));
        $data['model'] = $model !== '' ? $model : 'غير محدد';
        $data['year'] = $data['year'] ?? (int) date('Y');
        $data['price'] = $data['price'] ?? 0;
        $data['title'] = $data['title'] ?? $data['name'];

        return $data;
    }

    private function storeUploadedImages(Request $request): array
    {
        $paths = [];
        $files = $request->file('images');

        if ($files === null) {
            return $paths;
        }

        if (! is_array($files)) {
            $files = [$files];
        }

        foreach ($files as $file) {
            if ($file && $file->isValid()) {
                $paths[] = $file->store('cars/images', 'public');
            }
        }

        return $paths;
    }

    private function resolveBrandId(array $data): array
    {
        if (! empty($data['brand_id'])) {
            unset($data['brand']);

            return $data;
        }

        $name = trim((string) ($data['brand'] ?? ''));
        if ($name !== '') {
            $brand = Brand::query()
                ->whereRaw('LOWER(name) = ?', [mb_strtolower($name)])
                ->first();

            if (! $brand) {
                $brand = Brand::create(['name' => $name]);
            }

            $data['brand_id'] = $brand->id;
        }

        unset($data['brand']);

        return $data;
    }

    private function normalizeKeptImages(array $values): array
    {
        $normalized = [];

        foreach ($values as $value) {
            if (! is_string($value) || $value === '') {
                continue;
            }

            $normalized[] = $this->normalizeImageReference($value);
        }

        return array_values(array_unique($normalized));
    }

    private function normalizeImageReference(string $value): string
    {
        return \App\Support\PublicAssetUrl::toStoragePath($value);
    }

    private function syncCarImages(Car $car, array $paths, bool $replace = false): void
    {
        if ($replace) {
            $car->carImages()->delete();
        }

        foreach ($paths as $index => $path) {
            CarImage::create([
                'car_id' => $car->id,
                'path' => $path,
                'sort_order' => $index,
            ]);
        }
    }

    private function deleteStoredImages(Car $car): void
    {
        foreach ($car->images ?? [] as $path) {
            if (is_string($path) && ! str_starts_with($path, 'http')) {
                Storage::disk('public')->delete($path);
            }
        }
    }
}
