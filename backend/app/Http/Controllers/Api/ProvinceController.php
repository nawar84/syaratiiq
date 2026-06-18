<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Province;

class ProvinceController extends Controller
{
    public function index()
    {
        return response()->json(Province::orderBy('name')->get());
    }
}
