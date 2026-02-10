<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Feeder;
use Illuminate\Http\Request;

class FeedersController extends Controller
{
    public function index()
    {
        return Feeder::all();
    }
}