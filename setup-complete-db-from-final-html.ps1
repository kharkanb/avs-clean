# =====================================================
# setup-complete-db-from-final-html-fixed.ps1
# نسخه نهایی اصلاح شده: همه Model+Controller+Migration+Seeder + BOM + FK + داده واقعی
# =====================================================

$basePath      = Get-Location
$controllerDir = Join-Path $basePath "app\Http\Controllers"
$modelDir      = Join-Path $basePath "app\Models"
$routesDir     = Join-Path $basePath "routes"
$migrationsDir = Join-Path $basePath "database\migrations"
$seedersDir    = Join-Path $basePath "database\seeders"
$htmlFile      = Join-Path $basePath "final.html"

# ----------------------------
# تابع حذف BOM
# ----------------------------
function Remove-BOM($filePath) {
    if (Test-Path $filePath) {
        $content = Get-Content $filePath -Raw
        $content = $content -replace '^\xEF\xBB\xBF',''
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($filePath, $content, $utf8NoBom)
        Write-Host "✅ BOM removed: $filePath"
    }
}

# حذف BOM از همه فایل‌های PHP
Get-ChildItem -Path $controllerDir -Filter "*.php" -Recurse | ForEach-Object { Remove-BOM $_.FullName }
Get-ChildItem -Path $modelDir -Filter "*.php" -Recurse | ForEach-Object { Remove-BOM $_.FullName }

# ----------------------------
# Controller ها
# ----------------------------
$controllers = @(
    "EquipmentController", "PostController", "FeederController", "ChecklistTemplateController", 
    "ActivityPriceController", "ConsumableController", "BrandController", "EquipmentTypeController"
)
foreach ($c in $controllers) {
    $path = Join-Path $controllerDir "$c.php"
    if (-not (Test-Path $path)) {
        php artisan make:controller $c
        Write-Host "✅ Controller created: $c"
    }
}

# ----------------------------
# Model ها + Migration با FK و type
# ----------------------------
$modelsWithSchema = @(
    @{name="Equipment"; fields=@("id","equipment_name:string","equipment_type_id:foreign:equipment_types:id","city:string","station:string","serial_number:string","install_date:date","timestamps")},
    @{name="EquipmentType"; fields=@("id","name:string","has_height:boolean","has_brand:boolean","timestamps")},
    @{name="Post"; fields=@("id","name:string","timestamps")},
    @{name="Feeder"; fields=@("id","post_id:foreign:posts:id","name:string","timestamps")},
    @{name="ChecklistTemplate"; fields=@("id","equipment_type_id:foreign:equipment_types:id","name:string","timestamps")},
    @{name="ActivityPrice"; fields=@("id","name:string","price:decimal","timestamps")},
    @{name="ConsumableItem"; fields=@("id","name:string","unit:string","timestamps")},
    @{name="Brand"; fields=@("id","name:string","timestamps")}
)

foreach ($m in $modelsWithSchema) {
    $modelName = $m.name
    $path = Join-Path $modelDir "$modelName.php"
    if (-not (Test-Path $path)) {
        php artisan make:model $modelName -m
        Write-Host "✅ Model + Migration created: $modelName"
    }

    # اصلاح migration با FK و type واقعی
    $migFile = Get-ChildItem $migrationsDir -Filter "*create_$($modelName.ToLower())_table.php" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($migFile) {
        $migContent = @"
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('$($modelName.ToLower())', function (Blueprint \$table) {
"@
        foreach ($f in $m.fields) {
            $parts = $f.Split(":")
            switch ($parts[1]) {
                "string"    { $migContent += "            \$table->string('$($parts[0])');`n" }
                "boolean"   { $migContent += "            \$table->boolean('$($parts[0])');`n" }
                "decimal"   { $migContent += "            \$table->decimal('$($parts[0])', 10,2);`n" }
                "date"      { $migContent += "            \$table->date('$($parts[0])');`n" }
                "foreign"   { $migContent += "            \$table->foreignId('$($parts[0])')->constrained('$($parts[2])')->cascadeOnDelete();`n" }
                "timestamps"{ $migContent += "            \$table->timestamps();`n" }
            }
        }
        $migContent += @"
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('$($modelName.ToLower())');
    }
};
"@
        [System.IO.File]::WriteAllText($migFile.FullName, $migContent, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "✅ Migration updated with FK & types: $($migFile.Name)"
    }
}

# ----------------------------
# پاک کردن cache و autoload
# ----------------------------
php artisan config:clear
php artisan route:clear
php artisan view:clear
composer dump-autoload

# ----------------------------
# migrate واقعی
# ----------------------------
php artisan migrate:install
php artisan migrate --force

# ----------------------------
# Seed کردن از final.html
# ----------------------------
$htmlContent = Get-Content -Path $htmlFile -Raw
$matches = [regex]::Matches($htmlContent, 'http://localhost:8000/api/[\w\-/]+[\s\S]*?(\[.*?\])')
$apiData = @{}
foreach ($m in $matches) {
    $url = $m.Value -replace '.*(http://localhost:8000/api/[\w\-/]+).*', '$1'
    $json = $m.Groups[1].Value
    try { $apiData[$url] = $json | ConvertFrom-Json } catch { Write-Host "⚠️ Failed parse $url" }
}

foreach ($key in $apiData.Keys) {
    $tableName = ($key -replace '/api/','') -replace '/','_'
    $seederName = ($tableName.Substring(0,1).ToUpper() + $tableName.Substring(1)) + "Seeder"
    $filePath = Join-Path $seedersDir "$seederName.php"

    $items = $apiData[$key] | ForEach-Object {
        $props = $_ | Get-Member -MemberType NoteProperty | ForEach-Object { "`"$($_.Name)`" => `"$(($_.Value).ToString().Replace('\"','\\"'))`"" }
        "{ " + ($props -join ", ") + " }"
    }

    $content = @"
<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class $seederName extends Seeder {
    public function run() {
        DB::table('$tableName')->insert([
            $(($items -join ",`n            "))
        ]);
    }
}
"@
    [System.IO.File]::WriteAllText($filePath, $content, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "✅ Seeder created: $seederName"

    php artisan db:seed --class=$seederName
    Write-Host "✅ Seeded: $seederName"
}

# ----------------------------
# پاک کردن cache و autoload مجدد
# ----------------------------
php artisan config:clear
php artisan route:clear
php artisan view:clear
composer dump-autoload

# ----------------------------
# بررسی route ها و تست API
# ----------------------------
php artisan route:list

$port = 8000
foreach ($url in $apiData.Keys) {
    $fullUrl = "http://127.0.0.1:$port$url"
    try {
        $response = Invoke-RestMethod -Uri $fullUrl -Method GET -ErrorAction SilentlyContinue
        if ($response) { Write-Host "✅ API $url responded" }
        else { Write-Host "⚠️ API $url did not respond" }
    } catch { Write-Host "❌ API $url error: $_" }
}

Write-Host "🎯 FULL FK + Seed + Routes setup complete!"
