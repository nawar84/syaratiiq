<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Model;
use App\Support\PublicAssetUrl;

class Exhibition extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'province_id',
        'name',
        'owner_name',
        'phone',
        'address',
        'logo',
        'cover_image',
        'description',
        'is_active',
        'views_count',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'views_count' => 'integer',
    ];

    protected $appends = ['logo_url', 'cover_image_url'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function province(): BelongsTo
    {
        return $this->belongsTo(Province::class);
    }

    public function cars(): HasMany
    {
        return $this->hasMany(Car::class);
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }

    public function activeSubscription(): ?Subscription
    {
        return $this->subscriptions()
            ->whereIn('status', ['trial', 'active'])
            ->where('ends_at', '>', now())
            ->latest()
            ->first();
    }

    public function getLogoUrlAttribute(): ?string
    {
        return $this->resolveStorageUrl($this->logo);
    }

    public function getCoverImageUrlAttribute(): ?string
    {
        return $this->resolveStorageUrl($this->cover_image);
    }

    private function resolveStorageUrl(?string $path): ?string
    {
        if (! $path) {
            return null;
        }

        if (str_starts_with($path, 'http')) {
            return $path;
        }

        return PublicAssetUrl::resolve($path);
    }
}
