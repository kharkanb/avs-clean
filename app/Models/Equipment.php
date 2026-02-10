<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Equipment extends Model
{
    protected $table = 'equipment';

    protected $fillable = [
        'equipment_name',
        'equipment_type',
        'city',
        'station',
        'serial_number',
        'install_date',
    ];
}