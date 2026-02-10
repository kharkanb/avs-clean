<?php
namespace App\Http\Controllers\Api;

use App\Models\Feeder;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;

class FeederController extends Controller
{
    public function index() {
        return response()->json(Feeder::all());
    }

    public function store(Request $request) {
        $item = Feeder::create($request->all());
        return response()->json($item, 201);
    }

    public function show($id) {
        return response()->json(Feeder::findOrFail($id));
    }

    public function update(Request $request, $id) {
        $item = Feeder::findOrFail($id);
        $item->update($request->all());
        return response()->json($item);
    }

    public function destroy($id) {
        Feeder::findOrFail($id)->delete();
        return response()->noContent();
    }
}
