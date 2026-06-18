<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Model;
use App\Support\PublicAssetUrl;

class Car extends Model
{
    use HasFactory;

    protected $fillable = [
        'exhibition_id',
        'brand_id',
        'title',
        'name',
        'model',
        'year',
        'price',
        'color',
        'mileage',
        'fuel_type',
        'transmission',
        'images',
        'description',
        'damage_notes',
        'is_active',
        'views_count',
        'phone_clicks_count',
        'whatsapp_clicks_count',
    ];

    protected $casts = [
        'images' => 'array',
        'year' => 'integer',
        'price' => 'decimal:2',
        'mileage' => 'integer',
        'is_active' => 'boolean',
        'views_count' => 'integer',
        'phone_clicks_count' => 'integer',
        'whatsapp_clicks_count' => 'integer',
    ];

    protected $appends = ['image_urls', 'display_title'];

    public function exhibition(): BelongsTo
    {
        return $this->belongsTo(Exhibition::class);
    }

    public function brand(): BelongsTo
    {
        return $this->belongsTo(Brand::class);
    }

    public function carImages(): HasMany
    {
        return $this->hasMany(CarImage::class)->orderBy('sort_order');
    }

    public function favorites(): HasMany
    {
        return $this->hasMany(Favorite::class);
    }

    public function getDisplayTitleAttribute(): string
    {
        return $this->title ?: trim("{$this->name} {$this->model}");
    }

    public function getImageUrlsAttribute(): array
    {
        $fromTable = $this->relationLoaded('carImages')
            ? $this->carImages->pluck('url')->all()
            : [];

        if (! empty($fromTable)) {
            return $fromTable;
        }

        $images = $this->images ?? [];

        return array_map(function ($path): string {
            if (is_string($path) && str_starts_with($path, 'http')) {
                return $path;
            }

            return PublicAssetUrl::resolve((string) $path);
        }, $images);
    }
}
