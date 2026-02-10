<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class PostController
{
    //
    public function index() {
        return Post::all();
    }

    public function store(Request \) {
        \ = \->validate([]);
        return Post::create(\);
    }

    public function show(\) {
        return Post::findOrFail(\);
    }

    public function update(Request \, \) {
        \ = Post::findOrFail(\);
        \->update(\->validate([]));
        return \;
    }

    public function destroy(\) {
        Post::findOrFail(\)->delete();
        return response()->noContent();
    }
    public function index() {
        return Post::all();
    }

    public function store(Request \) {
        \ = \->validate([]);
        return Post::create(\);
    }

    public function show(\) {
        return Post::findOrFail(\);
    }

    public function update(Request \, \) {
        \ = Post::findOrFail(\);
        \->update(\->validate([]));
        return \;
    }

    public function destroy(\) {
        Post::findOrFail(\)->delete();
        return response()->noContent();
    }
    public function index() {
        return Post::all();
    }

    public function store(Request \) {
        \ = \->validate([]);
        return Post::create(\);
    }

    public function show(\) {
        return Post::findOrFail(\);
    }

    public function update(Request \, \) {
        \ = Post::findOrFail(\);
        \->update(\->validate([]));
        return \;
    }

    public function destroy(\) {
        Post::findOrFail(\)->delete();
        return response()->noContent();
    }
    public function index() {
        return Post::all();
    }

    public function store(Request \) {
        \ = \->validate([]);
        return Post::create(\);
    }

    public function show(\) {
        return Post::findOrFail(\);
    }

    public function update(Request \, \) {
        \ = Post::findOrFail(\);
        \->update(\->validate([]));
        return \;
    }

    public function destroy(\) {
        Post::findOrFail(\)->delete();
        return response()->noContent();
    }
    public function index() {
        return Post::all();
    }

    public function store(Request \) {
        \ = \->validate([]);
        return Post::create(\);
    }

    public function show(\) {
        return Post::findOrFail(\);
    }

    public function update(Request \, \) {
        \ = Post::findOrFail(\);
        \->update(\->validate([]));
        return \;
    }

    public function destroy(\) {
        Post::findOrFail(\)->delete();
        return response()->noContent();
    }
}