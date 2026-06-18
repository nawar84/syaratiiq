<?php

namespace Database\Seeders;

use App\Models\Province;
use Illuminate\Database\Seeder;

class ProvinceSeeder extends Seeder
{
    public function run(): void
    {
        $provinces = [
            'Baghdad' => 'بغداد',
            'Basra' => 'البصرة',
            'Nineveh' => 'نينوى',
            'Erbil' => 'أربيل',
            'Sulaymaniyah' => 'السليمانية',
            'Duhok' => 'دهوك',
            'Kirkuk' => 'كركوك',
            'Anbar' => 'الأنبار',
            'Babil' => 'بابل',
            'Karbala' => 'كربلاء',
            'Najaf' => 'النجف',
            'Wasit' => 'واسط',
            'Diyala' => 'ديالى',
            'Salahuddin' => 'صلاح الدين',
            'Muthanna' => 'المثنى',
            'Dhi Qar' => 'ذي قار',
            'Maysan' => 'ميسان',
            'Qadisiyah' => 'القادسية',
        ];

        foreach ($provinces as $legacyName => $arabicName) {
            $existing = Province::where('name', $legacyName)->first();
            if ($existing) {
                $existing->update(['name' => $arabicName]);

                continue;
            }

            Province::updateOrCreate(['name' => $arabicName]);
        }
    }
}
