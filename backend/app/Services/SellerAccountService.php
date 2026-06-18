<?php

namespace App\Services;

use App\Models\Exhibition;
use App\Models\Province;
use App\Models\Subscription;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class SellerAccountService
{
    public const SUBSCRIPTION_TYPES = ['free_trial', 'monthly', 'premium'];

    public const ACCOUNT_STATUSES = ['active', 'expired', 'suspended'];

    public function generatePassword(int $length = 8): string
    {
        $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

        return collect(range(1, $length))
            ->map(fn () => $chars[random_int(0, strlen($chars) - 1)])
            ->implode('');
    }

    public function syncAccountStatus(User $user): User
    {
        if (! $user->isOwner()) {
            return $user;
        }

        if ($user->account_status === 'suspended') {
            return $user;
        }

        if ($user->subscription_end && Carbon::parse($user->subscription_end)->isPast()) {
            if ($user->account_status !== 'expired') {
                $user->update(['account_status' => 'expired']);
                $user->refresh();
            }

            $user->exhibitions()->update(['is_active' => false]);
            $user->subscriptions()
                ->whereIn('status', ['trial', 'active'])
                ->where('ends_at', '<=', now())
                ->update(['status' => 'expired']);

            return $user;
        }

        if ($user->account_status === 'expired' && $user->subscription_end && Carbon::parse($user->subscription_end)->isFuture()) {
            $user->update(['account_status' => 'active']);
            $user->exhibitions()->update(['is_active' => true]);
            $user->refresh();
        }

        return $user;
    }

    public function assertUserCanManageCars(User $user): void
    {
        if (! $user->isOwner()) {
            return;
        }

        $this->syncAccountStatus($user);

        if ($user->account_status === 'suspended') {
            abort(403, 'تم تعليق الحساب. تواصل مع الإدارة.');
        }

        if ($user->account_status === 'expired') {
            abort(403, 'انتهى الاشتراك. يرجى التجديد للمتابعة.');
        }
    }

    public function canManageCars(User $user): bool
    {
        if (! $user->isOwner()) {
            return true;
        }

        $this->syncAccountStatus($user);

        return $user->account_status === 'active';
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array{user: User, password: string}
     */
    public function create(array $data): array
    {
        $plainPassword = $this->generatePassword();
        $startsAt = now();
        $endsAt = Carbon::parse($data['subscription_end']);

        $user = DB::transaction(function () use ($data, $plainPassword, $startsAt, $endsAt) {
            $province = Province::findOrFail($data['province_id']);
            $accountStatus = $endsAt->isPast() ? 'expired' : 'active';

            $user = User::create([
                'name' => $data['owner_name'],
                'phone' => $data['phone'],
                'role' => 'owner',
                'password' => Hash::make($plainPassword),
                'showroom_name' => $data['showroom_name'],
                'province_id' => $data['province_id'],
                'subscription_type' => $data['subscription_type'],
                'subscription_start' => $startsAt,
                'subscription_end' => $endsAt,
                'account_status' => $accountStatus,
            ]);

            $user->update(['username' => 'showroom_'.$user->id]);

            $exhibition = Exhibition::create([
                'user_id' => $user->id,
                'province_id' => $data['province_id'],
                'name' => $data['showroom_name'],
                'owner_name' => $data['owner_name'],
                'phone' => $data['phone'],
                'address' => $province->name ?? '—',
                'description' => 'معرض سيارات',
                'is_active' => $accountStatus === 'active',
            ]);

            $this->createSubscriptionRecord($user, $exhibition, $data['subscription_type'], $startsAt, $endsAt);

            return $user->fresh(['province', 'exhibitions']);
        });

        return [
            'user' => $user,
            'password' => $plainPassword,
        ];
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function update(User $user, array $data): User
    {
        if (! $user->isOwner()) {
            abort(422, 'User is not a seller account.');
        }

        return DB::transaction(function () use ($user, $data) {
            $user->update([
                'name' => $data['owner_name'] ?? $user->name,
                'phone' => $data['phone'] ?? $user->phone,
                'showroom_name' => $data['showroom_name'] ?? $user->showroom_name,
                'province_id' => $data['province_id'] ?? $user->province_id,
                'subscription_type' => $data['subscription_type'] ?? $user->subscription_type,
                'subscription_end' => isset($data['subscription_end'])
                    ? Carbon::parse($data['subscription_end'])
                    : $user->subscription_end,
            ]);

            $exhibition = $user->exhibitions()->first();
            if ($exhibition) {
                $exhibition->update([
                    'name' => $data['showroom_name'] ?? $exhibition->name,
                    'owner_name' => $data['owner_name'] ?? $exhibition->owner_name,
                    'phone' => $data['phone'] ?? $exhibition->phone,
                    'province_id' => $data['province_id'] ?? $exhibition->province_id,
                ]);
            }

            $this->syncAccountStatus($user->fresh());

            return $user->fresh(['province', 'exhibitions']);
        });
    }

    public function resetPassword(User $user): array
    {
        if (! $user->isOwner()) {
            abort(422, 'User is not a seller account.');
        }

        $plainPassword = $this->generatePassword();
        $user->update(['password' => Hash::make($plainPassword)]);

        return [
            'user' => $user->fresh(['province', 'exhibitions']),
            'password' => $plainPassword,
        ];
    }

    /**
     * @return array{user: User, password: string|null}
     */
    public function renewSubscription(User $user, Carbon $endsAt, ?string $subscriptionType = null): array
    {
        if (! $user->isOwner()) {
            abort(422, 'User is not a seller account.');
        }

        $type = $subscriptionType ?? $user->subscription_type ?? 'monthly';

        return DB::transaction(function () use ($user, $endsAt, $type) {
            $startsAt = now();

            $user->update([
                'subscription_type' => $type,
                'subscription_start' => $startsAt,
                'subscription_end' => $endsAt,
                'account_status' => 'active',
            ]);

            $exhibition = $user->exhibitions()->first();
            if ($exhibition) {
                $exhibition->update(['is_active' => true]);
                $this->createSubscriptionRecord($user, $exhibition, $type, $startsAt, $endsAt, renewed: true);
            }

            return [
                'user' => $user->fresh(['province', 'exhibitions']),
                'password' => null,
            ];
        });
    }

    public function suspend(User $user): User
    {
        if (! $user->isOwner()) {
            abort(422, 'User is not a seller account.');
        }

        $user->update(['account_status' => 'suspended']);
        $user->exhibitions()->update(['is_active' => false]);

        return $user->fresh(['province', 'exhibitions']);
    }

    public function activate(User $user): User
    {
        if (! $user->isOwner()) {
            abort(422, 'User is not a seller account.');
        }

        $user->update(['account_status' => 'active']);
        $this->syncAccountStatus($user);
        $user->exhibitions()->update(['is_active' => $user->account_status === 'active']);

        return $user->fresh(['province', 'exhibitions']);
    }

    public function delete(User $user): void
    {
        if (! $user->isOwner()) {
            abort(422, 'User is not a seller account.');
        }

        $user->delete();
    }

    public function formatSellerAccount(User $user): array
    {
        $this->syncAccountStatus($user);
        $user->loadMissing(['province', 'exhibitions']);

        return [
            'id' => $user->id,
            'username' => $user->username,
            'showroom_name' => $user->showroom_name,
            'owner_name' => $user->name,
            'phone' => $user->phone,
            'province_id' => $user->province_id,
            'province' => $user->province,
            'subscription_type' => $user->subscription_type,
            'subscription_start' => $user->subscription_start,
            'subscription_end' => $user->subscription_end,
            'account_status' => $user->account_status,
            'role' => $user->role,
            'exhibition' => $user->exhibitions->first(),
            'created_at' => $user->created_at,
        ];
    }

    private function createSubscriptionRecord(
        User $user,
        Exhibition $exhibition,
        string $type,
        Carbon $startsAt,
        Carbon $endsAt,
        bool $renewed = false,
    ): Subscription {
        $status = match ($type) {
            'free_trial' => 'trial',
            default => 'active',
        };

        $amount = match ($type) {
            'free_trial' => 0,
            'monthly' => SubscriptionService::MONTHLY_PRICE,
            'premium' => SubscriptionService::MONTHLY_PRICE * 2,
            default => 0,
        };

        return Subscription::create([
            'user_id' => $user->id,
            'exhibition_id' => $exhibition->id,
            'status' => $endsAt->isPast() ? 'expired' : $status,
            'amount' => $amount,
            'starts_at' => $startsAt,
            'ends_at' => $endsAt,
            'renewed_at' => $renewed ? now() : null,
        ]);
    }
}
