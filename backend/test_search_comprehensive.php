<?php

require __DIR__.'/vendor/autoload.php';
$app = require __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

$tests = [
    ['cars', 'أبيض', null],
    ['cars', 'white', null],
    ['cars', 'بنزين', null],
    ['cars', 'petrol', null],
    ['cars', 'Toyota', null],
    ['cars', 'تويوتا', null],
    ['cars', 'Camry', null],
    ['cars', 'automatic', null],
    ['cars', 'أوتوماتيك', null],
    ['cars', 'zzzznotfound999', 0],
    ['showrooms', 'بغداد', null],
    ['showrooms', 'Baghdad', null],
    ['showrooms', 'معرض البركة', null],
];

$failed = 0;
$totalCars = App\Models\Car::where('is_active', true)->count();

echo "Active cars baseline: {$totalCars}\n\n";

foreach ($tests as [$type, $term, $expected]) {
    $path = $type === 'cars' ? '/api/cars' : '/api/showrooms';
    $request = Illuminate\Http\Request::create($path.'?search='.urlencode($term).'&per_page=100', 'GET');
    $response = $kernel->handle($request);
    $payload = json_decode($response->getContent(), true);
    $count = $payload['total'] ?? count($payload['data'] ?? []);

    if ($expected === 0) {
        $ok = $count === 0;
    } else {
        $ok = $count > 0;
    }

    if (! $ok) {
        $failed++;
    }

    echo ($ok ? 'PASS' : 'FAIL')." | {$type} | '{$term}' => {$count} (HTTP {$response->getStatusCode()})\n";
}

$pairs = [
    ['cars', 'أبيض', 'white'],
    ['cars', 'بنزين', 'petrol'],
    ['showrooms', 'بغداد', 'Baghdad'],
];

echo "\nParity checks:\n";
foreach ($pairs as [$type, $ar, $en]) {
    $path = $type === 'cars' ? '/api/cars' : '/api/showrooms';
    $reqAr = Illuminate\Http\Request::create($path.'?search='.urlencode($ar), 'GET');
    $reqEn = Illuminate\Http\Request::create($path.'?search='.urlencode($en), 'GET');
    $countAr = json_decode($kernel->handle($reqAr)->getContent(), true)['total'] ?? 0;
    $countEn = json_decode($kernel->handle($reqEn)->getContent(), true)['total'] ?? 0;
    $ok = $countAr === $countEn && $countAr > 0;
    if (! $ok) {
        $failed++;
    }
    echo ($ok ? 'PASS' : 'FAIL')." | {$type} | '{$ar}' ({$countAr}) vs '{$en}' ({$countEn})\n";
}

echo "\n".($failed === 0 ? 'All tests passed.' : "{$failed} test(s) failed.")."\n";
exit($failed === 0 ? 0 : 1);
