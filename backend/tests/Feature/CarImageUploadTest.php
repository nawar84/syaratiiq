<?php

namespace Tests\Feature;

use App\Models\Car;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CarImageUploadTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
        Storage::fake('public');
    }

    public function test_seller_can_create_car_with_multiple_images_array(): void
    {
        $owner = User::where('username', '1234')->firstOrFail();
        Sanctum::actingAs($owner);

        $exhibitionId = $owner->exhibitions()->firstOrFail()->id;

        $response = $this->post('/api/cars', [
            'exhibition_id' => $exhibitionId,
            'brand' => 'Lexus',
            'name' => 'LX',
            'model' => '570',
            'year' => 2022,
            'price' => 85000000,
            'images' => [
                UploadedFile::fake()->create('car-1.jpg', 100, 'image/jpeg'),
                UploadedFile::fake()->create('car-2.png', 100, 'image/png'),
            ],
        ]);

        $response->assertCreated();
        $car = Car::findOrFail($response->json('id'));
        $this->assertCount(2, $car->images ?? []);
        $this->assertCount(2, $car->carImages);

        $imageUrls = $response->json('image_urls');
        $this->assertCount(2, $imageUrls);
        foreach ($imageUrls as $url) {
            $this->assertStringContainsString('/storage/cars/images/', $url);
        }
    }

    public function test_seller_can_update_car_keep_existing_and_add_new_images(): void
    {
        $owner = User::where('username', '1234')->firstOrFail();
        Sanctum::actingAs($owner);

        $car = Car::whereHas('exhibition', fn ($q) => $q->where('user_id', $owner->id))->firstOrFail();
        $existingPath = 'cars/images/existing.jpg';
        Storage::disk('public')->put($existingPath, 'existing');
        $removedPath = 'cars/images/removed.jpg';
        Storage::disk('public')->put($removedPath, 'removed');
        $car->update(['images' => [$existingPath, $removedPath]]);
        $car->carImages()->delete();
        $car->carImages()->createMany([
            ['path' => $existingPath, 'sort_order' => 0],
            ['path' => $removedPath, 'sort_order' => 1],
        ]);

        $response = $this->post("/api/cars/{$car->id}?_method=PUT", [
            'name' => $car->name,
            'model' => $car->model,
            'year' => $car->year,
            'price' => $car->price,
            'description' => $car->description ?? '',
            'update_images' => 1,
            'keep_images' => [$existingPath],
            'images' => [
                UploadedFile::fake()->create('new-car.jpg', 100, 'image/jpeg'),
            ],
        ]);

        $response->assertOk();
        $car->refresh();
        $this->assertCount(2, $car->images ?? []);
        Storage::disk('public')->assertExists($existingPath);
        Storage::disk('public')->assertMissing($removedPath);
    }
}
