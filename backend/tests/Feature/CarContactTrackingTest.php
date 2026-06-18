<?php

namespace Tests\Feature;

use App\Models\Car;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CarContactTrackingTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
        $this->seed(\Database\Seeders\VirtualShowroomsSeeder::class);
    }

    public function test_track_phone_increments_counter(): void
    {
        $car = Car::where('is_active', true)->firstOrFail();
        $before = $car->phone_clicks_count;

        $response = $this->postJson("/api/cars/{$car->id}/track-phone");

        $response->assertOk()
            ->assertJsonPath('phone_clicks_count', $before + 1);

        $this->assertSame($before + 1, $car->fresh()->phone_clicks_count);
    }

    public function test_track_whatsapp_increments_counter(): void
    {
        $car = Car::where('is_active', true)->firstOrFail();
        $before = $car->whatsapp_clicks_count;

        $response = $this->postJson("/api/cars/{$car->id}/track-whatsapp");

        $response->assertOk()
            ->assertJsonPath('whatsapp_clicks_count', $before + 1);

        $this->assertSame($before + 1, $car->fresh()->whatsapp_clicks_count);
    }

    public function test_track_endpoints_reject_inactive_car(): void
    {
        $car = Car::where('is_active', true)->firstOrFail();
        $car->update(['is_active' => false]);

        $this->postJson("/api/cars/{$car->id}/track-phone")->assertNotFound();
        $this->postJson("/api/cars/{$car->id}/track-whatsapp")->assertNotFound();
    }
}
