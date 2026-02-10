<?php
namespace App\Http\Controllers\Api;

use App\Models\ChecklistTemplate;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;

class ChecklistTemplateController extends Controller
{
    public function index() {
        return response()->json(ChecklistTemplate::all());
    }

    public function store(Request $request) {
        $item = ChecklistTemplate::create($request->all());
        return response()->json($item, 201);
    }

    public function show($id) {
        return response()->json(ChecklistTemplate::findOrFail($id));
    }

    public function update(Request $request, $id) {
        $item = ChecklistTemplate::findOrFail($id);
        $item->update($request->all());
        return response()->json($item);
    }

    public function destroy($id) {
        ChecklistTemplate::findOrFail($id)->delete();
        return response()->noContent();
    }
}
