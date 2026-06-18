<?php

namespace Tests\Feature;

use App\Models\PasswordResetCode;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class PasswordResetTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
        config(['services.sms.driver' => 'log', 'app.debug' => true]);
    }

    public function test_buyer_can_request_and_reset_password_via_phone(): void
    {
        $buyer = User::where('username', 'buyer')->firstOrFail();

        $request = $this->postJson('/api/forgot-password', ['phone' => $buyer->phone]);
        $request->assertOk()
            ->assertJsonStructure(['message', 'phone_masked', 'debug_code']);

        $code = $request->json('debug_code');
        $this->assertNotEmpty($code);

        $this->postJson('/api/reset-password', [
            'phone' => $buyer->phone,
            'code' => $code,
            'password' => 'NewBuyer123',
            'password_confirmation' => 'NewBuyer123',
        ])->assertOk()
            ->assertJsonPath('message', 'تم تحديث كلمة المرور بنجاح.');

        $buyer->refresh();
        $this->assertTrue(Hash::check('NewBuyer123', $buyer->password));

        $this->postJson('/api/login', [
            'username' => 'buyer',
            'password' => 'NewBuyer123',
        ])->assertOk();
    }

    public function test_admin_can_reset_password_via_username(): void
    {
        $request = $this->postJson('/api/forgot-password', ['username' => 'admin']);
        $request->assertOk();
        $code = $request->json('debug_code');

        $this->postJson('/api/reset-password', [
            'username' => 'admin',
            'code' => $code,
            'password' => 'NewAdmin12345',
            'password_confirmation' => 'NewAdmin12345',
        ])->assertOk();

        $this->postJson('/api/login', [
            'username' => 'admin',
            'password' => 'NewAdmin12345',
        ])->assertOk();

        User::where('username', 'admin')->update([
            'password' => Hash::make('1234'),
        ]);
    }

    public function test_seller_can_reset_password_via_username(): void
    {
        $owner = User::where('username', '1234')->firstOrFail();

        $request = $this->postJson('/api/forgot-password', ['username' => '1234']);
        $request->assertOk()->assertJsonStructure(['phone_masked', 'debug_code']);

        $code = $request->json('debug_code');

        $this->postJson('/api/reset-password', [
            'username' => '1234',
            'code' => $code,
            'password' => 'NewOwner12345',
            'password_confirmation' => 'NewOwner12345',
        ])->assertOk();

        $this->postJson('/api/login', [
            'username' => '1234',
            'password' => 'NewOwner12345',
        ])->assertOk();

        $owner->update(['password' => Hash::make('1234')]);
    }

    public function test_invalid_code_is_rejected(): void
    {
        $buyer = User::where('username', 'buyer')->firstOrFail();

        $this->postJson('/api/forgot-password', ['phone' => $buyer->phone])->assertOk();

        $this->postJson('/api/reset-password', [
            'phone' => $buyer->phone,
            'code' => '000000',
            'password' => 'NewBuyer123',
            'password_confirmation' => 'NewBuyer123',
        ])->assertStatus(422);
    }

    public function test_unknown_phone_returns_generic_message(): void
    {
        $this->postJson('/api/forgot-password', ['phone' => '07999999999'])
            ->assertOk()
            ->assertJsonMissingPath('debug_code');
    }

    public function test_resend_is_rate_limited(): void
    {
        $buyer = User::where('username', 'buyer')->firstOrFail();

        $this->postJson('/api/forgot-password', ['phone' => $buyer->phone])->assertOk();
        $this->postJson('/api/forgot-password', ['phone' => $buyer->phone])->assertStatus(429);
    }

    public function test_expired_code_is_rejected(): void
    {
        $buyer = User::where('username', 'buyer')->firstOrFail();

        PasswordResetCode::create([
            'user_id' => $buyer->id,
            'phone' => $buyer->phone,
            'code_hash' => Hash::make('123456'),
            'expires_at' => now()->subMinute(),
        ]);

        $this->postJson('/api/reset-password', [
            'phone' => $buyer->phone,
            'code' => '123456',
            'password' => 'NewBuyer123',
            'password_confirmation' => 'NewBuyer123',
        ])->assertStatus(422);
    }
}
