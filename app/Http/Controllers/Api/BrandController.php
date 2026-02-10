<?php
namespace App\Http\Controllers\Api;

use App\Models\Brand;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;

class BrandController extends Controller
{
    public function index() {
        return response()->json(Brand::all());
    }

    public function store(Request $request) {
        $item = Brand::create($request->all());
        return response()->json($item, 201);
    }

    public function show($id) {
        return response()->json(Brand::findOrFail($id));
    }

    public function update(Request $request, $id) {
        $item = Brand::findOrFail($id);
        $item->update($request->all());
        return response()->json($item);
    }

    public function destroy($id) {
        Brand::findOrFail($id)->delete();
        return response()->noContent();
    }
}
