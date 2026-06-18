<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Car;
use App\Models\Exhibition;
use App\Models\Province;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class AdminDashboardController extends Controller
{
    public function index()
    {
        $carsPerProvince = Province::query()
            ->leftJoin('exhibitions', 'provinces.id', '=', 'exhibitions.province_id')
            ->leftJoin('cars', 'exhibitions.id', '=', 'cars.exhibition_id')
            ->groupBy('provinces.id', 'provinces.name')
            ->orderBy('provinces.name')
            ->get([
                'provinces.name',
                DB::raw('COUNT(cars.id) as total'),
            ]);

        $exhibitionsPerProvince = Province::query()
            ->leftJoin('exhibitions', 'provinces.id', '=', 'exhibitions.province_id')
            ->groupBy('provinces.id', 'provinces.name')
            ->orderBy('provinces.name')
            ->get([
                'provinces.name',
                DB::raw('COUNT(exhibitions.id) as total'),
            ]);

        return response()->json([
            'cards' => [
                'provinces' => 18,
                'exhibitions' => Exhibition::count(),
                'cars' => Car::count(),
                'users' => User::count(),
            ],
            'charts' => [
                'cars_per_province' => $carsPerProvince,
                'exhibitions_per_province' => $exhibitionsPerProvince,
            ],
        ]);
    }
}
