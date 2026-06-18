<?php

namespace Database\Seeders;

use App\Models\Brand;
use App\Models\Car;
use App\Models\CarImage;
use App\Models\Exhibition;
use App\Models\Province;
use App\Models\User;
use App\Services\SubscriptionService;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class VirtualShowroomsSeeder extends Seeder
{
    private const SHOWROOM_COUNT = 10;

    private const CARS_PER_SHOWROOM = 15;

    private const IMAGES_PER_CAR = 5;

    public function run(): void
    {
        $subscriptionService = app(SubscriptionService::class);

        $owner = User::updateOrCreate(
            ['phone' => '07700000001'],
            [
                'name' => 'Owner Demo',
                'role' => 'owner',
                'password' => Hash::make('1234'),
            ]
        );

        $provinces = Province::all();
        $brands = Brand::all()->keyBy('name');

        if ($provinces->isEmpty() || $brands->isEmpty()) {
            $this->command?->warn('Run ProvinceSeeder and BrandSeeder first.');

            return;
        }

        $showroomNames = [
            'معرض النجوم للسيارات',
            'معرض البركة',
            'معرض الرافدين',
            'معرض الخليج',
            'معرض الواحة',
            'معرض الأصالة',
            'معرض الماسة',
            'معرض الفارس',
            'معرض الريان',
            'معرض Golden Motors',
        ];

        $addresses = [
            'شارع فلسطين، بغداد',
            'منطقة الزيونة، بغداد',
            'شارع 60، البصرة',
            'حي الجامعة، أربيل',
            'طريق الموصل، كركوك',
            'شارع 40، النجف',
            'حي المعلمين، بابل',
            'منطقة العباسية، ديالى',
            'شارع الجمهورية، كربلاء',
            'حي الصناعة، واسط',
        ];

        $colors = ['أبيض', 'أسود', 'فضي', 'رمادي', 'أزرق', 'أحمر', 'بيج'];
        $fuelTypes = ['بنزين', 'ديزل', 'هجين'];
        $transmissions = ['أوتوماتيك', 'يدوي'];

        $carTemplates = [
            ['name' => 'Toyota', 'model' => 'Camry'],
            ['name' => 'Toyota', 'model' => 'Corolla'],
            ['name' => 'Toyota', 'model' => 'Land Cruiser'],
            ['name' => 'Hyundai', 'model' => 'Elantra'],
            ['name' => 'Hyundai', 'model' => 'Tucson'],
            ['name' => 'Kia', 'model' => 'Sportage'],
            ['name' => 'Kia', 'model' => 'Cerato'],
            ['name' => 'BMW', 'model' => 'X5'],
            ['name' => 'BMW', 'model' => '320i'],
            ['name' => 'Mercedes', 'model' => 'C200'],
            ['name' => 'Mercedes', 'model' => 'E300'],
            ['name' => 'Land Rover', 'model' => 'Range Rover'],
            ['name' => 'Cadillac', 'model' => 'Escalade'],
            ['name' => 'Changan', 'model' => 'CS75'],
            ['name' => 'Changan', 'model' => 'UNI-T'],
        ];

        for ($i = 0; $i < self::SHOWROOM_COUNT; $i++) {
            $index = $i + 1;
            $phone = sprintf('0772%07d', $index);
            $province = $provinces[$i % $provinces->count()];
            $showroomName = $showroomNames[$i];

            $showroom = Exhibition::updateOrCreate(
                ['phone' => $phone],
                [
                    'user_id' => $owner->id,
                    'province_id' => $province->id,
                    'name' => $showroomName,
                    'owner_name' => $owner->name,
                    'address' => $addresses[$i],
                    'description' => 'معرض افتراضي للعرض التجريبي - '.self::CARS_PER_SHOWROOM.' سيارة متاحة',
                    'logo' => $this->showroomLogoUrl($index),
                    'cover_image' => $this->showroomCoverUrl($index),
                    'is_active' => true,
                    'views_count' => random_int(50, 500),
                ]
            );

            if ($showroom->subscriptions()->count() === 0) {
                $subscriptionService->startTrial($showroom);
            }

            for ($c = 0; $c < self::CARS_PER_SHOWROOM; $c++) {
                $template = $carTemplates[$c];
                $brand = $brands->get($template['name']) ?? $brands->first();
                $year = 2018 + ($c % 7);
                $title = $template['name'].' '.$template['model'].' '.$year;

                $car = Car::updateOrCreate(
                    [
                        'exhibition_id' => $showroom->id,
                        'model' => $template['model'],
                        'year' => $year,
                    ],
                    [
                        'brand_id' => $brand->id,
                        'title' => $title,
                        'name' => $template['name'],
                        'price' => 15000000 + ($index * 100000) + ($c * 250000),
                        'color' => $colors[$c % count($colors)],
                        'mileage' => 10000 + ($c * 8500) + ($index * 1000),
                        'fuel_type' => $fuelTypes[$c % count($fuelTypes)],
                        'transmission' => $transmissions[$c % count($transmissions)],
                        'description' => 'سيارة '.$year.' بحالة ممتازة - معرض '.$showroomName,
                        'damage_notes' => $c % 5 === 0 ? 'خدوش بسيطة' : 'لا يوجد',
                        'is_active' => true,
                        'views_count' => random_int(10, 200),
                        'phone_clicks_count' => random_int(0, 30),
                        'whatsapp_clicks_count' => random_int(0, 25),
                    ]
                );

                $car->carImages()->delete();

                for ($img = 0; $img < self::IMAGES_PER_CAR; $img++) {
                    CarImage::create([
                        'car_id' => $car->id,
                        'path' => $this->carImageUrl($index, $c + 1, $img + 1),
                        'sort_order' => $img,
                    ]);
                }
            }
        }

        Car::query()->each(function (Car $car): void {
            if ($car->carImages()->count() >= self::IMAGES_PER_CAR) {
                return;
            }

            $car->carImages()->delete();

            for ($img = 0; $img < self::IMAGES_PER_CAR; $img++) {
                CarImage::create([
                    'car_id' => $car->id,
                    'path' => 'https://picsum.photos/seed/cariq-car-'.$car->id.'-i'.($img + 1).'/900/650',
                    'sort_order' => $img,
                ]);
            }
        });

        $totalCars = self::SHOWROOM_COUNT * self::CARS_PER_SHOWROOM;
        $imageTotal = Car::count() * self::IMAGES_PER_CAR;
        $this->command?->info('Updated all cars to '.self::IMAGES_PER_CAR.' images each ('.$imageTotal.' total).');
    }

    private function showroomCoverUrl(int $index): string
    {
        return 'https://picsum.photos/seed/cariq-showroom-cover-'.$index.'/1200/700';
    }

    private function showroomLogoUrl(int $index): string
    {
        return 'https://picsum.photos/seed/cariq-showroom-logo-'.$index.'/400/400';
    }

    private function carImageUrl(int $showroomNo, int $carNo, int $imageNo): string
    {
        return 'https://picsum.photos/seed/cariq-s'.$showroomNo.'-c'.$carNo.'-i'.$imageNo.'/900/650';
    }
}
