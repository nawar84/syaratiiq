<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class SmsService
{
    public function send(string $phone, string $message): bool
    {
        $driver = config('services.sms.driver', 'log');

        return match ($driver) {
            'http' => $this->sendViaHttp($phone, $message),
            default => $this->sendViaLog($phone, $message),
        };
    }

    private function sendViaLog(string $phone, string $message): bool
    {
        Log::info('SMS sent', [
            'phone' => $phone,
            'message' => $message,
        ]);

        return true;
    }

    private function sendViaHttp(string $phone, string $message): bool
    {
        $url = config('services.sms.http_url');
        $apiKey = config('services.sms.api_key');
        $sender = config('services.sms.sender', 'CarIQ');

        if (! $url || ! $apiKey) {
            Log::warning('SMS HTTP driver not configured, falling back to log.', compact('phone'));

            return $this->sendViaLog($phone, $message);
        }

        $response = Http::withHeaders([
            'Authorization' => "Bearer {$apiKey}",
            'Accept' => 'application/json',
        ])->post($url, [
            'to' => $phone,
            'from' => $sender,
            'message' => $message,
        ]);

        if (! $response->successful()) {
            Log::error('SMS HTTP send failed', [
                'phone' => $phone,
                'status' => $response->status(),
                'body' => $response->body(),
            ]);

            return false;
        }

        return true;
    }
}
