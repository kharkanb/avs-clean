use App\Http\Controllers\Api\EquipmentController;

Route::prefix('equipment')->group(function () {
    Route::get('/', [EquipmentController::class, 'index']);
    Route::post('/', [EquipmentController::class, 'store']);
});
use App\Http\Controllers\Api\EquipmentController;

Route::get("/equipment", [EquipmentController::class, "index"]);
Route::post("/equipment", [EquipmentController::class, "store"]);
Route::get("/equipment/{equipment}", [EquipmentController::class, "show"]);
Route::put("/equipment/{equipment}", [EquipmentController::class, "update"]);
Route::delete("/equipment/{equipment}", [EquipmentController::class, "destroy"]);
