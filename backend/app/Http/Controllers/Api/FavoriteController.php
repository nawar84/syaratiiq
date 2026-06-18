<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Car;
use App\Models\Favorite;
use Illuminate\Http\Request;

class FavoriteController extends Controller
{
    public function index(Request $request)
    {
        $favorites = Favorite::with(['car.brand', 'car.exhibition.province', 'car.carImages'])
            ->where('user_id', $request->user()->id)
            ->latest()
            ->get();

        return response()->json($favorites->pluck('car'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'car_id' => ['required', 'exists:cars,id'],
        ]);

        $car = Car::where('is_active', true)
            ->whereHas('exhibition', fn ($q) => $q->where('is_active', true))
            ->findOrFail($data['car_id']);

        $favorite = Favorite::firstOrCreate([
            'user_id' => $request->user()->id,
            'car_id' => $car->id,
        ]);

        return response()->json([
            'message' => 'Added to favorites',
            'favorite_id' => $favorite->id,
        ], 201);
    }

    public function destroy(Request $request, int $carId)
    {
        Favorite::where('user_id', $request->user()->id)
            ->where('car_id', $carId)
            ->delete();

        return response()->json(['message' => 'Removed from favorites']);
    }

    public function check(Request $request, int $carId)
    {
        $exists = Favorite::where('user_id', $request->user()->id)
            ->where('car_id', $carId)
            ->exists();

        return response()->json(['is_favorite' => $exists]);
    }
}
