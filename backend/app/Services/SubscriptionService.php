<?php

namespace App\Services;

use App\Models\Exhibition;
use App\Models\Subscription;
use Carbon\Carbon;

class SubscriptionService
{
    public const TRIAL_DAYS = 30;

    public const MONTHLY_PRICE = 50000;

    public function startTrial(Exhibition $exhibition): Subscription
    {
        $startsAt = now();
        $endsAt = $startsAt->copy()->addDays(self::TRIAL_DAYS);

        return Subscription::create([
            'user_id' => $exhibition->user_id,
            'exhibition_id' => $exhibition->id,
            'status' => 'trial',
            'amount' => 0,
            'starts_at' => $startsAt,
            'ends_at' => $endsAt,
        ]);
    }

    public function renew(Exhibition $exhibition, float $amount = self::MONTHLY_PRICE): Subscription
    {
        $latest = $exhibition->subscriptions()->latest()->first();
        $startsAt = $latest && $latest->ends_at->isFuture()
            ? $latest->ends_at
            : now();

        $subscription = Subscription::create([
            'user_id' => $exhibition->user_id,
            'exhibition_id' => $exhibition->id,
            'status' => 'active',
            'amount' => $amount,
            'starts_at' => $startsAt,
            'ends_at' => $startsAt->copy()->addDays(30),
            'renewed_at' => now(),
        ]);

        $exhibition->update(['is_active' => true]);

        return $subscription;
    }

    public function syncExhibitionStatus(Exhibition $exhibition): void
    {
        $active = $this->hasActiveSubscription($exhibition);
        $exhibition->update(['is_active' => $active]);
    }

    public function hasActiveSubscription(Exhibition $exhibition): bool
    {
        $this->expireOverdue($exhibition);

        return $exhibition->fresh()->is_active;
    }

    public function expireOverdue(Exhibition $exhibition): void
    {
        $exhibition->subscriptions()
            ->whereIn('status', ['trial', 'active'])
            ->where('ends_at', '<=', now())
            ->update(['status' => 'expired']);

        $hasActive = $exhibition->subscriptions()
            ->whereIn('status', ['trial', 'active'])
            ->where('ends_at', '>', now())
            ->exists();

        $exhibition->update(['is_active' => $hasActive]);
    }

    public function assertCanManageCars(Exhibition $exhibition): void
    {
        $this->expireOverdue($exhibition);

        $user = $exhibition->user;
        if ($user) {
            app(SellerAccountService::class)->assertUserCanManageCars($user);
        }

        if (! $this->hasActiveSubscription($exhibition)) {
            abort(403, 'Showroom subscription expired. Renew to manage cars.');
        }
    }
}
