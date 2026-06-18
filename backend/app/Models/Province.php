<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Model;

class Province extends Model
{
    use HasFactory;

    protected $fillable = ['name'];

    public function exhibitions(): HasMany
    {
        return $this->hasMany(Exhibition::class);
    }

    protected static function booted(): void
    {
        static::deleting(function (): bool {
            return false;
        });
    }
}
