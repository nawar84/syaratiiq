<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\PasswordResetService;
use App\Services\SellerAccountService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    public function __construct(
        private readonly SellerAccountService $sellerAccounts,
        private readonly PasswordResetService $passwordReset,
    ) {
    }

    public function register(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:25', 'unique:users,phone'],
            'password' => ['required', 'confirmed', Password::min(8)],
        ]);

        $user = User::create([
            'name' => $data['name'],
            'phone' => $data['phone'],
            'role' => 'buyer',
            'password' => Hash::make($data['password']),
            'account_status' => 'active',
        ]);

        $token = $user->createToken('mobile-token')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $this->formatUser($user),
        ], 201);
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'username' => ['nullable', 'string'],
            'phone' => ['nullable', 'string'],
            'password' => ['required', 'string'],
        ]);

        if (empty($credentials['username']) && empty($credentials['phone'])) {
            return response()->json(['message' => 'Username or phone is required.'], 422);
        }

        $user = ! empty($credentials['username'])
            ? User::where('username', $credentials['username'])->first()
            : User::where('phone', $credentials['phone'])->first();

        if (! $user || ! Hash::check($credentials['password'], $user->password)) {
            return response()->json(['message' => 'Invalid credentials.'], 422);
        }

        if ($user->isOwner() && $user->isAccountSuspended()) {
            return response()->json(['message' => 'تم تعليق الحساب. تواصل مع الإدارة.'], 403);
        }

        if ($user->isOwner()) {
            $this->sellerAccounts->syncAccountStatus($user);
        }

        $token = $user->createToken('mobile-token')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $this->formatUser($user->fresh()),
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()?->currentAccessToken()?->delete();

        return response()->json(['message' => 'Logged out']);
    }

    public function me(Request $request)
    {
        $user = $request->user();

        if ($user->isOwner()) {
            $this->sellerAccounts->syncAccountStatus($user);
            $user->refresh();
        }

        return response()->json($this->formatUser($user));
    }

    public function forgotPassword(Request $request)
    {
        $data = $request->validate([
            'phone' => ['nullable', 'string', 'max:25'],
            'username' => ['nullable', 'string', 'max:255'],
        ]);

        if (empty($data['phone']) && empty($data['username'])) {
            return response()->json(['message' => 'رقم الهاتف أو اسم المستخدم مطلوب.'], 422);
        }

        $result = $this->passwordReset->requestCode(
            phone: $data['phone'] ?? null,
            username: $data['username'] ?? null,
        );

        return response()->json($result);
    }

    public function resetPassword(Request $request)
    {
        $data = $request->validate([
            'phone' => ['nullable', 'string', 'max:25'],
            'username' => ['nullable', 'string', 'max:255'],
            'code' => ['required', 'string', 'size:6'],
            'password' => ['required', 'confirmed', Password::min(8)],
        ]);

        if (empty($data['phone']) && empty($data['username'])) {
            return response()->json(['message' => 'رقم الهاتف أو اسم المستخدم مطلوب.'], 422);
        }

        $user = $this->passwordReset->resetPassword(
            code: $data['code'],
            password: $data['password'],
            phone: $data['phone'] ?? null,
            username: $data['username'] ?? null,
        );

        return response()->json([
            'message' => 'تم تحديث كلمة المرور بنجاح.',
            'user' => $this->formatUser($user),
        ]);
    }

    private function formatUser(User $user): array
    {
        $user->loadMissing(['province', 'exhibitions']);

        return [
            'id' => $user->id,
            'name' => $user->name,
            'phone' => $user->phone,
            'username' => $user->username,
            'role' => $user->role,
            'showroom_name' => $user->showroom_name,
            'province_id' => $user->province_id,
            'province' => $user->province,
            'subscription_type' => $user->subscription_type,
            'subscription_start' => $user->subscription_start,
            'subscription_end' => $user->subscription_end,
            'account_status' => $user->account_status,
            'can_manage_cars' => $this->sellerAccounts->canManageCars($user),
        ];
    }
}
