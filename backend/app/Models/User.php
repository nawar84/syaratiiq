<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'phone',
        'username',
        'role',
        'password',
        'showroom_name',
        'province_id',
        'subscription_type',
        'subscription_start',
        'subscription_end',
        'account_status',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'password' => 'hashed',
            'subscription_start' => 'datetime',
            'subscription_end' => 'datetime',
        ];
    }

    public function province(): BelongsTo
    {
        return $this->belongsTo(Province::class);
    }

    public function exhibitions(): HasMany
    {
        return $this->hasMany(Exhibition::class);
    }

    public function favorites(): HasMany
    {
        return $this->hasMany(Favorite::class);
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function isOwner(): bool
    {
        return $this->role === 'owner';
    }

    public function isSeller(): bool
    {
        return $this->isOwner();
    }

    public function isBuyer(): bool
    {
        return in_array($this->role, ['buyer', 'visitor'], true);
    }

    public function isAccountActive(): bool
    {
        return $this->account_status === 'active';
    }

    public function isAccountExpired(): bool
    {
        return $this->account_status === 'expired';
    }

    public function isAccountSuspended(): bool
    {
        return $this->account_status === 'suspended';
    }
}
