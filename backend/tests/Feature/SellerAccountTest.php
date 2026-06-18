<?php

namespace Tests\Feature;

use App\Models\Province;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SellerAccountTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();

        $this->admin = User::where('username', 'admin')->firstOrFail();
    }

    public function test_public_register_cannot_create_seller(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Fake Seller',
            'phone' => '07999999999',
            'password' => 'Password123',
            'password_confirmation' => 'Password123',
            'role' => 'owner',
        ]);

        $response->assertCreated();
        $this->assertDatabaseHas('users', [
            'phone' => '07999999999',
            'role' => 'buyer',
        ]);
    }

    public function test_admin_can_create_seller_account(): void
    {
        Sanctum::actingAs($this->admin);
        $province = Province::firstOrFail();

        $response = $this->postJson('/api/admin/seller-accounts', [
            'showroom_name' => 'معرض النجوم',
            'owner_name' => 'أحمد علي',
            'phone' => '07811111111',
            'province_id' => $province->id,
            'subscription_type' => 'free_trial',
            'subscription_end' => now()->addDays(30)->toDateString(),
        ]);

        $response->assertCreated()
            ->assertJsonStructure([
                'username',
                'password',
                'user' => ['id', 'username', 'showroom_name', 'account_status'],
            ]);

        $username = $response->json('username');
        $password = $response->json('password');

        $this->assertStringStartsWith('showroom_', $username);
        $this->assertSame(8, strlen($password));

        $this->assertDatabaseHas('users', [
            'username' => $username,
            'role' => 'owner',
            'showroom_name' => 'معرض النجوم',
            'account_status' => 'active',
        ]);

        $this->assertDatabaseHas('exhibitions', [
            'name' => 'معرض النجوم',
            'phone' => '07811111111',
        ]);
    }

    public function test_seller_logs_in_with_username_only(): void
    {
        Sanctum::actingAs($this->admin);
        $province = Province::firstOrFail();

        $created = $this->postJson('/api/admin/seller-accounts', [
            'showroom_name' => 'معرض الاختبار',
            'owner_name' => 'بائع تجريبي',
            'phone' => '07822222222',
            'province_id' => $province->id,
            'subscription_type' => 'monthly',
            'subscription_end' => now()->addDays(30)->toDateString(),
        ])->json();

        $login = $this->postJson('/api/login', [
            'username' => $created['username'],
            'password' => $created['password'],
        ]);

        $login->assertOk()
            ->assertJsonPath('user.role', 'owner')
            ->assertJsonPath('user.username', $created['username']);
    }

    public function test_expired_seller_can_login_but_cannot_add_cars(): void
    {
        Sanctum::actingAs($this->admin);
        $province = Province::firstOrFail();

        $created = $this->postJson('/api/admin/seller-accounts', [
            'showroom_name' => 'معرض منتهي',
            'owner_name' => 'بائع منتهي',
            'phone' => '07833333333',
            'province_id' => $province->id,
            'subscription_type' => 'monthly',
            'subscription_end' => now()->addDay()->toDateString(),
        ])->json();

        $user = User::where('username', $created['username'])->firstOrFail();
        $user->update([
            'subscription_end' => now()->subDay(),
            'account_status' => 'expired',
        ]);

        $login = $this->postJson('/api/login', [
            'username' => $created['username'],
            'password' => $created['password'],
        ]);
        $login->assertOk();

        Sanctum::actingAs($user->fresh());

        $this->postJson('/api/cars', [
            'exhibition_id' => $user->exhibitions()->first()->id,
            'brand_id' => 1,
            'title' => 'Test Car',
            'name' => 'Toyota',
            'model' => 'Corolla',
            'year' => 2020,
            'price' => 10000000,
            'color' => 'White',
            'mileage' => 10000,
            'fuel_type' => 'Petrol',
            'transmission' => 'Automatic',
        ])->assertForbidden();
    }

    public function test_admin_seller_account_actions(): void
    {
        Sanctum::actingAs($this->admin);
        $province = Province::firstOrFail();

        $created = $this->postJson('/api/admin/seller-accounts', [
            'showroom_name' => 'معرض الإجراءات',
            'owner_name' => 'مالك',
            'phone' => '07844444444',
            'province_id' => $province->id,
            'subscription_type' => 'premium',
            'subscription_end' => now()->addDays(15)->toDateString(),
        ])->json();

        $id = $created['user']['id'];

        $this->getJson('/api/admin/seller-accounts')->assertOk()->assertJsonStructure(['data']);
        $this->getJson("/api/admin/seller-accounts/{$id}")->assertOk();

        $this->putJson("/api/admin/seller-accounts/{$id}", [
            'showroom_name' => 'معرض محدّث',
        ])->assertOk()->assertJsonPath('showroom_name', 'معرض محدّث');

        $reset = $this->postJson("/api/admin/seller-accounts/{$id}/reset-password");
        $reset->assertOk()->assertJsonStructure(['username', 'password']);

        $this->postJson("/api/admin/seller-accounts/{$id}/renew-subscription", [
            'subscription_end' => now()->addDays(60)->toDateString(),
            'subscription_type' => 'monthly',
        ])->assertOk()->assertJsonPath('user.account_status', 'active');

        $this->postJson("/api/admin/seller-accounts/{$id}/suspend")
            ->assertOk()
            ->assertJsonPath('account_status', 'suspended');

        $this->postJson('/api/login', [
            'username' => $created['username'],
            'password' => $reset->json('password'),
        ])->assertForbidden();

        $this->postJson("/api/admin/seller-accounts/{$id}/activate")
            ->assertOk()
            ->assertJsonPath('account_status', 'active');

        $this->deleteJson("/api/admin/seller-accounts/{$id}")->assertOk();
        $this->assertDatabaseMissing('users', ['id' => $id]);
    }

    public function test_buyer_cannot_access_seller_account_admin_routes(): void
    {
        $buyer = User::where('username', 'buyer')->firstOrFail();
        Sanctum::actingAs($buyer);

        $this->getJson('/api/admin/seller-accounts')->assertForbidden();
        $this->postJson('/api/admin/seller-accounts', [])->assertForbidden();
    }
}
