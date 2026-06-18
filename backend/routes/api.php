<?php

use App\Http\Controllers\Api\AdminDashboardController;
use App\Http\Controllers\Api\AdminManagementController;
use App\Http\Controllers\Api\AdminSellerAccountController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BrandController;
use App\Http\Controllers\Api\CarController;
use App\Http\Controllers\Api\ExhibitionController;
use App\Http\Controllers\Api\FavoriteController;
use App\Http\Controllers\Api\ProvinceController;
use App\Http\Controllers\Api\StatisticsController;
use App\Http\Controllers\Api\SubscriptionController;
use Illuminate\Support\Facades\Route;

Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/reset-password', [AuthController::class, 'resetPassword']);

Route::get('/statistics', [StatisticsController::class, 'index']);
Route::get('/provinces', [ProvinceController::class, 'index']);
Route::get('/brands', [BrandController::class, 'index']);

// Showrooms (exhibitions)
Route::get('/showrooms', [ExhibitionController::class, 'index']);
Route::get('/showrooms/{id}', [ExhibitionController::class, 'show']);
Route::get('/exhibitions', [ExhibitionController::class, 'index']);
Route::get('/exhibitions/{id}', [ExhibitionController::class, 'show']);

// Cars marketplace
Route::get('/cars', [CarController::class, 'index']);
Route::get('/cars/{id}', [CarController::class, 'show']);
Route::post('/cars/{id}/track-phone', [CarController::class, 'trackPhone']);
Route::post('/cars/{id}/track-whatsapp', [CarController::class, 'trackWhatsApp']);

Route::middleware('auth:sanctum')->group(function (): void {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Buyer favorites
    Route::get('/favorites', [FavoriteController::class, 'index'])->middleware('role:buyer');
    Route::post('/favorites', [FavoriteController::class, 'store'])->middleware('role:buyer');
    Route::delete('/favorites/{carId}', [FavoriteController::class, 'destroy'])->middleware('role:buyer');
    Route::get('/favorites/{carId}/check', [FavoriteController::class, 'check'])->middleware('role:buyer');

    // Owner / admin showroom management
    Route::get('/my/showrooms', [ExhibitionController::class, 'mine'])->middleware('role:admin,owner');
    Route::get('/my/exhibitions', [ExhibitionController::class, 'mine'])->middleware('role:admin,owner');
    Route::post('/showrooms', [ExhibitionController::class, 'store'])->middleware('role:admin,owner');
    Route::post('/exhibitions', [ExhibitionController::class, 'store'])->middleware('role:admin,owner');
    Route::put('/showrooms/{id}', [ExhibitionController::class, 'update'])->middleware('role:admin,owner');
    Route::put('/exhibitions/{id}', [ExhibitionController::class, 'update'])->middleware('role:admin,owner');
    Route::delete('/showrooms/{id}', [ExhibitionController::class, 'destroy'])->middleware('role:admin,owner');
    Route::delete('/exhibitions/{id}', [ExhibitionController::class, 'destroy'])->middleware('role:admin,owner');

    // Subscriptions
    Route::get('/my/subscriptions', [SubscriptionController::class, 'mine'])->middleware('role:admin,owner');
    Route::get('/showrooms/{id}/subscription', [SubscriptionController::class, 'status'])->middleware('role:admin,owner');
    Route::post('/showrooms/{id}/renew', [SubscriptionController::class, 'renew'])->middleware('role:admin,owner');

    // Owner cars
    Route::get('/my/cars', [CarController::class, 'mine'])->middleware('role:admin,owner');
    Route::get('/my/cars/stats', [CarController::class, 'stats'])->middleware('role:admin,owner');
    Route::post('/cars', [CarController::class, 'store'])->middleware('role:admin,owner');
    Route::put('/cars/{id}', [CarController::class, 'update'])->middleware('role:admin,owner');
    Route::delete('/cars/{id}', [CarController::class, 'destroy'])->middleware('role:admin,owner');

    // Admin-only: full platform management (users, showrooms, cars, subscriptions, revenue)
    Route::get('/admin/dashboard', [AdminDashboardController::class, 'index'])->middleware('role:admin');
    Route::get('/admin/users', [AdminManagementController::class, 'users'])->middleware('role:admin');
    Route::put('/admin/users/{id}/role', [AdminManagementController::class, 'updateUserRole'])->middleware('role:admin');
    Route::get('/admin/showrooms', [AdminManagementController::class, 'showrooms'])->middleware('role:admin');
    Route::get('/admin/cars', [AdminManagementController::class, 'cars'])->middleware('role:admin');
    Route::get('/admin/subscriptions', [AdminManagementController::class, 'subscriptions'])->middleware('role:admin');
    Route::get('/admin/revenue', [AdminManagementController::class, 'revenue'])->middleware('role:admin');

    // Admin seller account management
    Route::get('/admin/seller-accounts', [AdminSellerAccountController::class, 'index'])->middleware('role:admin');
    Route::post('/admin/seller-accounts', [AdminSellerAccountController::class, 'store'])->middleware('role:admin');
    Route::get('/admin/seller-accounts/{id}', [AdminSellerAccountController::class, 'show'])->middleware('role:admin');
    Route::put('/admin/seller-accounts/{id}', [AdminSellerAccountController::class, 'update'])->middleware('role:admin');
    Route::post('/admin/seller-accounts/{id}/reset-password', [AdminSellerAccountController::class, 'resetPassword'])->middleware('role:admin');
    Route::post('/admin/seller-accounts/{id}/renew-subscription', [AdminSellerAccountController::class, 'renewSubscription'])->middleware('role:admin');
    Route::post('/admin/seller-accounts/{id}/suspend', [AdminSellerAccountController::class, 'suspend'])->middleware('role:admin');
    Route::post('/admin/seller-accounts/{id}/activate', [AdminSellerAccountController::class, 'activate'])->middleware('role:admin');
    Route::delete('/admin/seller-accounts/{id}', [AdminSellerAccountController::class, 'destroy'])->middleware('role:admin');
});
