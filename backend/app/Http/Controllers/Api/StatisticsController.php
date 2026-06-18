<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Car;
use App\Models\Exhibition;

class StatisticsController extends Controller
{
    public function index()
    {
        return response()->json([
            'provinces' => 18,
            'exhibitions' => Exhibition::count(),
            'cars' => Car::count(),
        ]);
    }
}
