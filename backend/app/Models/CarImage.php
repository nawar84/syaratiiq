<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Support\PublicAssetUrl;

class CarImage extends Model
{
    protected $fillable = ['car_id', 'path', 'sort_order'];

    protected $appends = ['url'];

    public function car(): BelongsTo
    {
        return $this->belongsTo(Car::class);
    }

    public function getUrlAttribute(): string
    {
        if (str_starts_with($this->path, 'http')) {
            return $this->path;
        }

        return PublicAssetUrl::resolve($this->path);
    }
}
