<?php

namespace Database\Seeders;

use App\Models\Brand;
use App\Models\Car;
use App\Models\Exhibition;
use App\Models\Province;
use App\Models\User;
use App\Services\SubscriptionService;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class MarketplaceSeeder extends Seeder
{
    public function run(): void
    {
        $subscriptionService = app(SubscriptionService::class);

        $owner = User::updateOrCreate(
            ['phone' => '07700000001'],
            [
                'name' => 'Owner Demo',
                'role' => 'owner',
                'password' => Hash::make('1234'),
                'username' => '1234',
                'showroom_name' => 'معرض بغداد للسيارات',
                'province_id' => null,
                'subscription_type' => 'free_trial',
                'subscription_start' => now(),
                'subscription_end' => now()->addDays(30),
                'account_status' => 'active',
            ]
        );

        $buyer = User::updateOrCreate(
            ['username' => 'buyer'],
            [
                'name' => 'Buyer Demo',
                'phone' => '07800000001',
                'role' => 'buyer',
                'password' => Hash::make('1234'),
            ]
        );

        $province = Province::first();
        $brand = Brand::first();
        if (! $province || ! $brand) {
            return;
        }

        $showroom = Exhibition::updateOrCreate(
            ['phone' => $owner->phone],
            [
                'user_id' => $owner->id,
                'name' => 'معرض بغداد للسيارات',
                'province_id' => $province->id,
                'owner_name' => $owner->name,
                'address' => 'شارع فلسطين، بغداد',
                'description' => 'معرض سيارات معتمد',
                'is_active' => true,
            ]
        );

        $owner->update([
            'province_id' => $province->id,
            'showroom_name' => $showroom->name,
        ]);

        if ($showroom->subscriptions()->count() === 0) {
            $subscriptionService->startTrial($showroom);
        }

        Exhibition::query()->each(function (Exhibition $item) use ($subscriptionService): void {
            if ($item->subscriptions()->count() === 0) {
                $subscriptionService->startTrial($item);
            }
        });

        Car::updateOrCreate(
            ['exhibition_id' => $showroom->id, 'model' => 'Camry', 'year' => 2022],
            [
                'brand_id' => $brand->id,
                'title' => 'Toyota Camry 2022',
                'name' => 'Toyota',
                'price' => 28500000,
                'color' => 'White',
                'mileage' => 45000,
                'fuel_type' => 'Petrol',
                'transmission' => 'Automatic',
                'description' => 'سيارة بحالة ممتازة',
                'damage_notes' => 'لا يوجد',
                'is_active' => true,
            ]
        );
    }
}
