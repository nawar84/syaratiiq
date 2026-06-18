<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('exhibitions', function (Blueprint $table): void {
            $table->string('cover_image')->nullable()->after('logo');
            $table->boolean('is_active')->default(true)->after('description');
            $table->unsignedInteger('views_count')->default(0)->after('is_active');
        });

        Schema::table('cars', function (Blueprint $table): void {
            $table->string('title')->nullable()->after('brand_id');
            $table->string('color')->nullable()->after('price');
            $table->unsignedInteger('mileage')->nullable()->after('color');
            $table->string('fuel_type')->nullable()->after('mileage');
            $table->string('transmission')->nullable()->after('fuel_type');
            $table->text('damage_notes')->nullable()->after('description');
            $table->boolean('is_active')->default(true)->after('damage_notes');
            $table->unsignedInteger('views_count')->default(0)->after('is_active');
        });

        Schema::create('car_images', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('car_id')->constrained()->cascadeOnDelete();
            $table->string('path');
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::create('favorites', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('car_id')->constrained()->cascadeOnDelete();
            $table->timestamps();
            $table->unique(['user_id', 'car_id']);
        });

        Schema::create('subscriptions', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('exhibition_id')->constrained()->cascadeOnDelete();
            $table->string('status')->default('trial');
            $table->decimal('amount', 10, 2)->default(0);
            $table->timestamp('starts_at');
            $table->timestamp('ends_at');
            $table->timestamp('renewed_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscriptions');
        Schema::dropIfExists('favorites');
        Schema::dropIfExists('car_images');

        Schema::table('cars', function (Blueprint $table): void {
            $table->dropColumn([
                'title', 'color', 'mileage', 'fuel_type', 'transmission',
                'damage_notes', 'is_active', 'views_count',
            ]);
        });

        Schema::table('exhibitions', function (Blueprint $table): void {
            $table->dropColumn(['cover_image', 'is_active', 'views_count']);
        });
    }
};
