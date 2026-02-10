<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Equipment;
use Illuminate\Http\Request;

class EquipmentController extends Controller
{
    public function index()
    {
        return Equipment::all();
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'equipment_name' => 'required|string',
            'equipment_type' => 'nullable|string',
            'city'           => 'nullable|string',
            'station'        => 'nullable|string',
            'serial_number'  => 'nullable|string',
            'install_date'   => 'nullable|date',
        ]);

        return Equipment::create($data);
    }
}