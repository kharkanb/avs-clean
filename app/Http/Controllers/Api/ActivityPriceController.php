<?php
namespace App\Http\Controllers\Api;

use App\Models\ActivityPrice;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;

class ActivityPriceController extends Controller
{
    public function index() {
        return response()->json(ActivityPrice::all());
    }

    public function store(Request $request) {
        $item = ActivityPrice::create($request->all());
        return response()->json($item, 201);
    }

    public function show($id) {
        return response()->json(ActivityPrice::findOrFail($id));
    }

    public function update(Request $request, $id) {
        $item = ActivityPrice::findOrFail($id);
        $item->update($request->all());
        return response()->json($item);
    }

    public function destroy($id) {
        ActivityPrice::findOrFail($id)->delete();
        return response()->noContent();
    }
}
