<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            ProvinceSeeder::class,
            BrandSeeder::class,
        ]);

        User::updateOrCreate(
            ['username' => 'admin'],
            [
                'name' => 'Admin',
                'phone' => '07800000000',
                'role' => 'admin',
                'password' => Hash::make('1234'),
            ]
        );

        User::query()
            ->whereNull('username')
            ->whereIn('phone', ['1234', '1236', '07000000000', '07700000002'])
            ->delete();

        $this->call(MarketplaceSeeder::class);
        $this->call(VirtualShowroomsSeeder::class);
    }
}
