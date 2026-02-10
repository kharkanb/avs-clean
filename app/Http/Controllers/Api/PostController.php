<?php
namespace App\Http\Controllers\Api;

use App\Models\Post;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;

class PostController extends Controller
{
    public function index() {
        return response()->json(Post::all());
    }

    public function store(Request $request) {
        $item = Post::create($request->all());
        return response()->json($item, 201);
    }

    public function show($id) {
        return response()->json(Post::findOrFail($id));
    }

    public function update(Request $request, $id) {
        $item = Post::findOrFail($id);
        $item->update($request->all());
        return response()->json($item);
    }

    public function destroy($id) {
        Post::findOrFail($id)->delete();
        return response()->noContent();
    }
}
