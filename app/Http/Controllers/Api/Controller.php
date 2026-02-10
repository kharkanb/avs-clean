<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\;
use Illuminate\Http\Request;

class Controller extends Controller
{
    public function index() {
        return ::all();
    }

    public function store(Request) {
        \ = \->validate([]);
        return ::create(\);
    }

    public function show(\) {
        return ::findOrFail(\);
    }

    public function update(Request, \) {
        \ = ::findOrFail(\);
        \ = \->validate([]);
        \->update(\);
        return \;
    }

    public function destroy(\) {
        ::findOrFail(\)->delete();
        return response()->noContent();
    }
}