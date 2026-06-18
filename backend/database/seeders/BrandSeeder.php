<?php

namespace Database\Seeders;

use App\Models\Brand;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class BrandSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $brands = [
            'Toyota',
            'Hyundai',
            'BMW',
            'Mercedes',
            'Kia',
            'Land Rover',
            'Cadillac',
            'Changan',
        ];

        Brand::query()->whereNotIn('name', $brands)->delete();

        foreach ($brands as $name) {
            Brand::updateOrCreate(['name' => $name], ['logo' => null]);
        }
    }
}
