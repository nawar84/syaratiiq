<?php

namespace App\Support;

use Illuminate\Support\Facades\Storage;

class PublicAssetUrl
{
    public static function resolve(string $path): string
    {
        if ($path === '') {
            return $path;
        }

        if (str_starts_with($path, 'http')) {
            return $path;
        }

        if (! app()->runningInConsole()) {
            $request = request();
            if ($request) {
                $host = $request->getSchemeAndHttpHost();
                if ($host !== '') {
                    return rtrim($host, '/').'/storage/'.ltrim($path, '/');
                }
            }
        }

        return Storage::disk('public')->url($path);
    }

    public static function toStoragePath(string $value): string
    {
        if (! str_starts_with($value, 'http')) {
            return $value;
        }

        if (preg_match('#/storage/(.+)$#', $value, $matches)) {
            return $matches[1];
        }

        $storageUrl = Storage::disk('public')->url('');
        if (str_starts_with($value, $storageUrl)) {
            return ltrim(substr($value, strlen($storageUrl)), '/');
        }

        return $value;
    }
}
