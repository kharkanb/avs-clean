<?php
namespace App\Http\Controllers\Api;

use App\Models\EquipmentType;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;

class EquipmentTypeController extends Controller
{
    public function index() {
        return response()->json(EquipmentType::all());
    }

    public function store(Request $request) {
        $item = EquipmentType::create($request->all());
        return response()->json($item, 201);
    }

    public function show($id) {
        return response()->json(EquipmentType::findOrFail($id));
    }

    public function update(Request $request, $id) {
        $item = EquipmentType::findOrFail($id);
        $item->update($request->all());
        return response()->json($item);
    }

    public function destroy($id) {
        EquipmentType::findOrFail($id)->delete();
        return response()->noContent();
    }
}
