<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminPanelTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private User $buyer;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
        $this->seed(\Database\Seeders\VirtualShowroomsSeeder::class);

        $this->admin = User::where('username', 'admin')->firstOrFail();
        $this->buyer = User::where('username', 'buyer')->firstOrFail();
    }

    public function test_admin_dashboard_returns_cards_and_charts(): void
    {
        Sanctum::actingAs($this->admin);

        $response = $this->getJson('/api/admin/dashboard');

        $response->assertOk()
            ->assertJsonStructure([
                'cards' => ['provinces', 'exhibitions', 'cars', 'users'],
                'charts' => ['cars_per_province', 'exhibitions_per_province'],
            ]);

        $this->assertGreaterThan(0, $response->json('cards.cars'));
        $this->assertGreaterThan(0, $response->json('cards.exhibitions'));
    }

    public function test_admin_users_list_and_role_update(): void
    {
        Sanctum::actingAs($this->admin);

        $users = $this->getJson('/api/admin/users');
        $users->assertOk()->assertJsonStructure(['data']);
        $this->assertNotEmpty($users->json('data'));

        $this->putJson("/api/admin/users/{$this->buyer->id}/role", ['role' => 'owner'])
            ->assertOk()
            ->assertJsonPath('role', 'owner');

        $this->putJson("/api/admin/users/{$this->buyer->id}/role", ['role' => 'buyer'])
            ->assertOk()
            ->assertJsonPath('role', 'buyer');
    }

    public function test_admin_cannot_change_own_role(): void
    {
        Sanctum::actingAs($this->admin);

        $this->putJson("/api/admin/users/{$this->admin->id}/role", ['role' => 'buyer'])
            ->assertStatus(422);
    }

    public function test_admin_showrooms_cars_subscriptions_and_revenue(): void
    {
        Sanctum::actingAs($this->admin);

        $this->getJson('/api/admin/showrooms')->assertOk()->assertJsonStructure(['data']);
        $this->getJson('/api/admin/cars')->assertOk()->assertJsonStructure(['data']);
        $this->getJson('/api/admin/subscriptions')->assertOk()->assertJsonStructure(['data']);

        $revenue = $this->getJson('/api/admin/revenue');
        $revenue->assertOk()->assertJsonStructure([
            'total_revenue',
            'active_subscriptions',
            'monthly_reports',
        ]);
    }

    public function test_buyer_cannot_access_admin_endpoints(): void
    {
        Sanctum::actingAs($this->buyer);

        $this->getJson('/api/admin/dashboard')->assertForbidden();
        $this->getJson('/api/admin/users')->assertForbidden();
        $this->getJson('/api/admin/showrooms')->assertForbidden();
        $this->getJson('/api/admin/cars')->assertForbidden();
        $this->getJson('/api/admin/subscriptions')->assertForbidden();
        $this->getJson('/api/admin/revenue')->assertForbidden();
    }
}
