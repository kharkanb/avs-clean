<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\EquipmentController;

Route::get('/equipment', [EquipmentController::class, 'index']);
Route::post('/equipment', [EquipmentController::class, 'store']);