# ============================================
# setup-complete-project.ps1
# نسخه نهایی: BOM, Controller, Model, Migration, Seeder, FK, Cache, Autoload
# ============================================

$projectPath = "C:\Users\dear-user\Desktop\avs-clean"
$baseUrl = "http://127.0.0.1:8000/api"
$controllers = @("EquipmentController","PostController","FeederController","ChecklistTemplateController","ActivityPriceController","ConsumableController","BrandController","EquipmentTypeController")
$models = @("Equipment","Post","Feeder","ChecklistTemplate","ActivityPrice","ConsumableItem","Brand","EquipmentType")
$htmlFile = Join-Path $projectPath "final.html"

# ----------------------------
# تابع حذف BOM
# ----------------------------
function Remove-BOM($filePath) {
    if (Test-Path $filePath) {
        $content = Get-Content $filePath -Raw
        $content = $content -replace '^\xEF\xBB\xBF',''
        [System.IO.File]::WriteAllText($filePath, $content, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "✅ BOM removed: $filePath"
    }
}

# ----------------------------
# 1️⃣ حذف BOM از همه فایل‌های PHP
# ----------------------------
foreach ($c in $controllers) {
    $file = Join-Path $projectPath "app\Http\Controllers\$c.php"
    Remove-BOM $file
}
foreach ($m in $models) {
    $file = Join-Path $projectPath "app\Models\$m.php"
    Remove-BOM $file
}

# ----------------------------
# 2️⃣ ایجاد Controller ها اگر وجود ندارند
# ----------------------------
foreach ($c in $controllers) {
    $file = Join-Path $projectPath "app\Http\Controllers\$c.php"
    if (-not (Test-Path $file)) {
        php artisan make:controller $c
        Write-Host "✅ Controller created: $c"
    }
}

# ----------------------------
# 3️⃣ ایجاد Model ها و Migration با FK و types
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

$migrationsDir = Join-Path $projectPath "database\migrations"
$modelDir = Join-Path $projectPath "app\Models"

foreach ($m in $modelsWithSchema) {
    $modelName = $m.name
    $modelFile = Join-Path $modelDir "$modelName.php"
    if (-not (Test-Path $modelFile)) {
        php artisan make:model $modelName -m
        Write-Host "✅ Model + Migration created: $modelName"
    }

    # اصلاح migration با FK و type واقعی
    $migFile = Get-ChildItem $migrationsDir -Filter "*create_$($modelName.ToLower())_table.php" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($migFile) {
        $migContent = "Schema::create('$($modelName.ToLower())', function (Blueprint \$table) {`n"
        foreach ($f in $m.fields) {
            $parts = $f.Split(":")
            switch ($parts[1]) {
                "string"    { $migContent += "    \$table->string('$($parts[0])');`n" }
                "boolean"   { $migContent += "    \$table->boolean('$($parts[0])');`n" }
                "decimal"   { $migContent += "    \$table->decimal('$($parts[0])',10,2);`n" }
                "date"      { $migContent += "    \$table->date('$($parts[0])');`n" }
                "foreign"   { $migContent += "    \$table->foreignId('$($parts[0])')->constrained('$($parts[2])')->cascadeOnDelete();`n" }
                "timestamps"{ $migContent += "    \$table->timestamps();`n" }
            }
        }
        $migContent += "});"
        [System.IO.File]::WriteAllText($migFile.FullName, "<?php`nuse Illuminate\Database\Migrations\Migration;`nuse Illuminate\Database\Schema\Blueprint;`nuse Illuminate\Support\Facades\Schema;`nreturn new class extends Migration { public function up() { $migContent } public function down() { Schema::dropIfExists('$($modelName.ToLower())'); } };", (New-Object System.Text.UTF8Encoding($false))
        Write-Host "✅ Migration updated: $($migFile.Name)"
    }
}

# ----------------------------
# 4️⃣ پاک کردن cache و autoload
# ----------------------------
php artisan config:clear
php artisan route:clear
php artisan view:clear
composer dump-autoload

# ----------------------------
# 5️⃣ migrate واقعی
# ----------------------------
php artisan migrate:install
php artisan migrate --force

# ----------------------------
# 6️⃣ seed کردن واقعی (از final.html)
# ----------------------------
$seedersDir = Join-Path $projectPath "database\seeders"
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
    $content = "<?php`nnamespace Database\Seeders;`nuse Illuminate\Database\Seeder;`nuse Illuminate\Support\Facades\DB;`nclass $seederName extends Seeder { public function run() { DB::table('$tableName')->insert([" + ($items -join ",`n") + "]); } }"
    [System.IO.File]::WriteAllText($filePath, $content, (New-Object System.Text.UTF8Encoding($false)))
    php artisan db:seed --class=$seederName
    Write-Host "✅ Seeder: $seederName executed"
}

# ----------------------------
# 7️⃣ پاک کردن cache و autoload مجدد
# ----------------------------
php artisan config:clear
php artisan route:clear
php artisan view:clear
composer dump-autoload

# ----------------------------
# 8️⃣ بررسی نهایی route ها
# ----------------------------
php artisan route:list

Write-Host "🎯 FULL FK + Seed + Routes setup complete!" -ForegroundColor Green
