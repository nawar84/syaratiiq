<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Exhibition;
use App\Models\Subscription;
use App\Services\SubscriptionService;
use Illuminate\Http\Request;

class SubscriptionController extends Controller
{
    public function __construct(private readonly SubscriptionService $subscriptions)
    {
    }

    public function mine(Request $request)
    {
        $query = Subscription::with(['exhibition.province'])->latest();
        if (! $request->user()->isAdmin()) {
            $query->where('user_id', $request->user()->id);
        }

        return response()->json($query->get());
    }

    public function status(Request $request, int $exhibitionId)
    {
        $exhibition = Exhibition::findOrFail($exhibitionId);
        $user = $request->user();

        if (! $user->isAdmin() && $exhibition->user_id !== $user->id) {
            abort(403, 'Not allowed.');
        }

        $this->subscriptions->expireOverdue($exhibition);
        $active = $exhibition->activeSubscription();

        return response()->json([
            'showroom_id' => $exhibition->id,
            'is_active' => $exhibition->is_active,
            'subscription' => $active,
            'can_manage_cars' => $user->isAdmin() || $this->subscriptions->hasActiveSubscription($exhibition),
        ]);
    }

    public function renew(Request $request, int $exhibitionId)
    {
        $exhibition = Exhibition::findOrFail($exhibitionId);
        $user = $request->user();

        if (! $user->isAdmin() && $exhibition->user_id !== $user->id) {
            abort(403, 'Not allowed.');
        }

        $data = $request->validate([
            'amount' => ['nullable', 'numeric', 'min:0'],
        ]);

        $subscription = $this->subscriptions->renew(
            $exhibition,
            (float) ($data['amount'] ?? SubscriptionService::MONTHLY_PRICE)
        );

        return response()->json([
            'message' => 'Subscription renewed',
            'subscription' => $subscription,
        ]);
    }
}
