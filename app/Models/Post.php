<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class Post extends Model {
    protected $fillable = ['name'];
    public function feeders() {
        return $this->hasMany(Feeder::class);
    }
}
