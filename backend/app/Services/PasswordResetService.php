<?php

namespace App\Services;

use App\Models\PasswordResetCode;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class PasswordResetService
{
    public const CODE_LENGTH = 6;

    public const EXPIRY_MINUTES = 10;

    public const MAX_ATTEMPTS = 5;

    public const RESEND_COOLDOWN_SECONDS = 60;

    public function __construct(private readonly SmsService $sms)
    {
    }

    /**
     * @return array{message: string, debug_code?: string}
     */
    public function requestCode(?string $phone = null, ?string $username = null): array
    {
        $user = $this->resolveUser($phone, $username);

        if (! $user) {
            return [
                'message' => 'إذا كان الحساب مسجّلاً، سيتم إرسال رمز التحقق عبر SMS.',
            ];
        }

        $this->assertCanRequest($user);

        $plainCode = $this->generateCode();
        $this->storeCode($user, $plainCode);

        $message = "رمز إعادة ضبط كلمة المرور في سياراتي IQ: {$plainCode}. صالح لمدة ".self::EXPIRY_MINUTES.' دقائق.';
        $sent = $this->sms->send($user->phone, $message);

        if (! $sent) {
            abort(503, 'تعذّر إرسال رسالة SMS. حاول لاحقاً.');
        }

        $response = [
            'message' => 'تم إرسال رمز التحقق إلى رقم الهاتف المسجّل.',
            'phone_masked' => $this->maskPhone($user->phone),
        ];

        if (config('app.debug') && config('services.sms.driver') === 'log') {
            $response['debug_code'] = $plainCode;
        }

        return $response;
    }

    public function resetPassword(
        string $code,
        string $password,
        ?string $phone = null,
        ?string $username = null,
    ): User {
        $user = $this->resolveUser($phone, $username);

        if (! $user) {
            abort(422, 'رمز التحقق غير صحيح.');
        }

        $resetCode = PasswordResetCode::query()
            ->where('user_id', $user->id)
            ->whereNull('verified_at')
            ->latest()
            ->first();

        if (! $resetCode || $resetCode->isExpired()) {
            abort(422, 'انتهت صلاحية رمز التحقق. اطلب رمزاً جديداً.');
        }

        if ($resetCode->attempts >= self::MAX_ATTEMPTS) {
            abort(422, 'تجاوزت عدد المحاولات. اطلب رمزاً جديداً.');
        }

        $resetCode->increment('attempts');

        if (! Hash::check($code, $resetCode->code_hash)) {
            abort(422, 'رمز التحقق غير صحيح.');
        }

        $resetCode->update(['verified_at' => now()]);
        $user->update(['password' => Hash::make($password)]);

        PasswordResetCode::query()
            ->where('user_id', $user->id)
            ->whereNull('verified_at')
            ->delete();

        return $user->fresh();
    }

    private function resolveUser(?string $phone, ?string $username): ?User
    {
        if ($phone) {
            $normalized = trim($phone);
            $digits = preg_replace('/\D+/', '', $normalized) ?? $normalized;

            return User::query()
                ->where('phone', $normalized)
                ->orWhere('phone', $digits)
                ->when(
                    ! str_starts_with($digits, '0') && strlen($digits) >= 10,
                    fn ($q) => $q->orWhere('phone', '0'.$digits)
                )
                ->first();
        }

        if ($username) {
            return User::where('username', trim($username))->first();
        }

        return null;
    }

    private function assertCanRequest(User $user): void
    {
        $latest = PasswordResetCode::query()
            ->where('user_id', $user->id)
            ->latest()
            ->first();

        if ($latest && $latest->created_at->diffInSeconds(now()) < self::RESEND_COOLDOWN_SECONDS) {
            abort(429, 'يرجى الانتظار دقيقة قبل طلب رمز جديد.');
        }
    }

    private function storeCode(User $user, string $plainCode): void
    {
        PasswordResetCode::query()
            ->where('user_id', $user->id)
            ->whereNull('verified_at')
            ->delete();

        PasswordResetCode::create([
            'user_id' => $user->id,
            'phone' => $user->phone,
            'code_hash' => Hash::make($plainCode),
            'expires_at' => now()->addMinutes(self::EXPIRY_MINUTES),
        ]);
    }

    private function generateCode(): string
    {
        return str_pad((string) random_int(0, 10 ** self::CODE_LENGTH - 1), self::CODE_LENGTH, '0', STR_PAD_LEFT);
    }

    private function maskPhone(string $phone): string
    {
        $digits = preg_replace('/\D+/', '', $phone) ?? $phone;
        if (strlen($digits) < 4) {
            return '****';
        }

        return str_repeat('*', max(0, strlen($digits) - 4)).substr($digits, -4);
    }
}
