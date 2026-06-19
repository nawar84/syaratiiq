<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Exhibition;
use App\Services\SubscriptionService;
use App\Support\MarketplaceSearch;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class ExhibitionController extends Controller
{
    public function __construct(private readonly SubscriptionService $subscriptions)
    {
    }

    public function index(Request $request)
    {
        $query = Exhibition::with(['province', 'user'])
            ->withCount(['cars as cars_count' => fn ($q) => $this->applyActiveCarFilters($q, $request)])
            ->where('is_active', true)
            ->latest();

        if ($request->filled('province_id')) {
            $query->where('province_id', (int) $request->query('province_id'));
        }

        if ($request->filled('search')) {
            MarketplaceSearch::applyExhibitionSearch($query, (string) $request->query('search'));
        }

        if ($request->filled('brand_id') || $request->filled('brand') || $request->filled('model') || $request->filled('color')) {
            $query->whereHas('cars', fn ($q) => $this->applyActiveCarFilters($q, $request));
        }

        return response()->json($query->paginate((int) $request->query('per_page', 20)));
    }

    public function show(int $id)
    {
        $exhibition = Exhibition::with([
            'province',
            'user',
            'cars' => fn ($q) => $q->where('is_active', true)->with(['brand', 'carImages'])->latest(),
        ])
            ->withCount(['cars as cars_count' => fn ($q) => $q->where('is_active', true)])
            ->where('is_active', true)
            ->findOrFail($id);

        $exhibition->increment('views_count');

        return response()->json($exhibition);
    }

    public function mine(Request $request)
    {
        $query = Exhibition::with(['province', 'cars.brand', 'cars.carImages', 'subscriptions'])->latest();
        if (! $request->user()->isAdmin()) {
            $query->where('user_id', $request->user()->id);
        }

        $items = $query->get()->map(function (Exhibition $exhibition) {
            $this->subscriptions->expireOverdue($exhibition);
            $exhibition->subscription_status = $exhibition->activeSubscription();

            return $exhibition;
        });

        return response()->json($items);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'owner_name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:25', Rule::unique('exhibitions', 'phone')],
            'province_id' => ['required', 'exists:provinces,id'],
            'address' => ['required', 'string', 'max:255'],
            'logo' => ['nullable', 'image', 'max:5120'],
            'logo_url' => ['nullable', 'string', 'max:255'],
            'cover_image' => ['nullable', 'image', 'max:5120'],
            'cover_image_url' => ['nullable', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
        ], [
            'phone.unique' => 'رقم الهاتف مسجّل لمعرض آخر. يُسمح بمعرض واحد لكل رقم.',
        ]);

        $data = $this->handleUploads($request, $data);
        $data['user_id'] = $request->user()->id;
        $data['is_active'] = true;

        $exhibition = Exhibition::create($data);
        $this->subscriptions->startTrial($exhibition);

        return response()->json($exhibition->load(['province', 'user', 'subscriptions']), 201);
    }

    public function update(Request $request, int $id)
    {
        $exhibition = Exhibition::findOrFail($id);
        $user = $request->user();

        if (! $user->isAdmin() && $exhibition->user_id !== $user->id) {
            abort(403, 'Not allowed to edit this showroom.');
        }

        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'owner_name' => ['sometimes', 'required', 'string', 'max:255'],
            'phone' => ['sometimes', 'required', 'string', 'max:25', Rule::unique('exhibitions', 'phone')->ignore($id)],
            'province_id' => ['sometimes', 'required', 'exists:provinces,id'],
            'address' => ['sometimes', 'required', 'string', 'max:255'],
            'logo' => ['nullable', 'image', 'max:5120'],
            'logo_url' => ['nullable', 'string', 'max:255'],
            'cover_image' => ['nullable', 'image', 'max:5120'],
            'cover_image_url' => ['nullable', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'remove_logo' => ['sometimes', 'boolean'],
        ]);

        if ($request->boolean('remove_logo')) {
            if ($exhibition->logo && ! str_starts_with($exhibition->logo, 'http')) {
                Storage::disk('public')->delete($exhibition->logo);
            }
            $data['logo'] = null;
        }

        $data = $this->handleUploads($request, $data, $exhibition);
        $exhibition->update($data);

        return response()->json($exhibition->fresh()->load(['province', 'user', 'subscriptions']));
    }

    public function destroy(Request $request, int $id)
    {
        $exhibition = Exhibition::findOrFail($id);
        $user = $request->user();

        if (! $user->isAdmin() && $exhibition->user_id !== $user->id) {
            abort(403, 'Not allowed to delete this showroom.');
        }

        foreach (['logo', 'cover_image'] as $field) {
            if ($exhibition->{$field} && ! str_starts_with($exhibition->{$field}, 'http')) {
                Storage::disk('public')->delete($exhibition->{$field});
            }
        }

        $exhibition->delete();

        return response()->json(['message' => 'Showroom deleted']);
    }

    private function applyActiveCarFilters($query, Request $request)
    {
        $query->where('is_active', true);

        if ($request->filled('brand_id')) {
            $query->where('brand_id', (int) $request->query('brand_id'));
        }

        if ($request->filled('brand')) {
            $query->whereHas('brand', fn ($q) => MarketplaceSearch::applyBrandFilter($q, (string) $request->query('brand')));
        }

        if ($request->filled('model')) {
            MarketplaceSearch::applyTextFilter($query, 'model', (string) $request->query('model'));
        }

        if ($request->filled('color')) {
            MarketplaceSearch::applyTextFilter($query, 'color', (string) $request->query('color'));
        }

        return $query;
    }

    private function handleUploads(Request $request, array $data, ?Exhibition $exhibition = null): array
    {
        if ($request->hasFile('logo')) {
            if ($exhibition?->logo && ! str_starts_with($exhibition->logo, 'http')) {
                Storage::disk('public')->delete($exhibition->logo);
            }
            $data['logo'] = $request->file('logo')->store('exhibitions/logos', 'public');
        } elseif (array_key_exists('logo_url', $data)) {
            $data['logo'] = $data['logo_url'];
        }

        if ($request->hasFile('cover_image')) {
            if ($exhibition?->cover_image && ! str_starts_with($exhibition->cover_image, 'http')) {
                Storage::disk('public')->delete($exhibition->cover_image);
            }
            $data['cover_image'] = $request->file('cover_image')->store('exhibitions/covers', 'public');
        } elseif (array_key_exists('cover_image_url', $data)) {
            $data['cover_image'] = $data['cover_image_url'];
        }

        unset($data['logo_url'], $data['cover_image_url']);

        return $data;
    }
}
