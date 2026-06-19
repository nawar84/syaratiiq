<?php

use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;

$serveSpa = static function () {
    $spa = public_path('index.html');

    if (! File::isFile($spa)) {
        abort(503, 'Frontend build missing. Deploy public/index.html from the Expo web export.');
    }

    return response()->file($spa, [
        'Content-Type' => 'text/html; charset=UTF-8',
    ]);
};

Route::get('/', $serveSpa);

Route::get('/{path}', $serveSpa)->where('path', '^(?!api(?:/|$)|up$).+');
