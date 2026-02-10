<?php
namespace App\Http\Controllers\Api;

use App\Models\Consumable;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;

class ConsumableController extends Controller
{
    public function index() {
        return response()->json(Consumable::all());
    }

    public function store(Request $request) {
        $item = Consumable::create($request->all());
        return response()->json($item, 201);
    }

    public function show($id) {
        return response()->json(Consumable::findOrFail($id));
    }

    public function update(Request $request, $id) {
        $item = Consumable::findOrFail($id);
        $item->update($request->all());
        return response()->json($item);
    }

    public function destroy($id) {
        Consumable::findOrFail($id)->delete();
        return response()->noContent();
    }
}
