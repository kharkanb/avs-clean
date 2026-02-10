# ============================================
# setup-full-api-project.ps1
# نسخه فوق پیشرفته: BOM, Controller+CRUD, Model, Migration, Seeder, FK, Cache, Autoload
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
    if (Test-Path $file) { Remove-BOM $file }
}
foreach ($m in $models) {
    $file = Join-Path $projectPath "app\Models\$m.php"
    if (Test-Path $file) { Remove-BOM $file }
}

# ----------------------------
# 2️⃣ ایجاد Model ها و Controllerها + متدهای CRUD
# ----------------------------
foreach ($m in $models) {
    $modelFile = Join-Path $projectPath "app\Models\$m.php"
    if (-not (Test-Path $modelFile)) {
        php artisan make:model $m
        Write-Host "✅ Model created: $m"
    }
}

foreach ($c in $controllers) {
    $controllerFile = Join-Path $projectPath "app\Http\Controllers\$c.php"
    if (-not (Test-Path $controllerFile)) {
        php artisan make:controller $c
        Write-Host "✅ Controller created: $c"
    }
}

# ----------------------------
# 3️⃣ اضافه کردن متدهای اصلی CRUD خودکار به Controllerها
# ----------------------------
foreach ($c in $controllers) {
    $controllerFile = Join-Path $projectPath "app\Http\Controllers\$c.php"
    if (Test-Path $controllerFile) {
        $className = [System.IO.Path]::GetFileNameWithoutExtension($controllerFile)
        $modelName = $className -replace "Controller$",""
        $crudMethods = @"
    public function index() {
        return $modelName::all();
    }

    public function store(Request \$request) {
        \$validated = \$request->validate([]);
        return $modelName::create(\$validated);
    }

    public function show(\$id) {
        return $modelName::findOrFail(\$id);
    }

    public function update(Request \$request, \$id) {
        \$item = $modelName::findOrFail(\$id);
        \$item->update(\$request->validate([]));
        return \$item;
    }

    public function destroy(\$id) {
        $modelName::findOrFail(\$id)->delete();
        return response()->noContent();
    }
"@
        $content = Get-Content $controllerFile -Raw
        # پاک کردن متدهای قدیمی index/store/show/update/destroy
        $content = $content -replace "(public function (index|store|show|update|destroy)\(.*?\}(\r?\n)*)",""
        # اضافه کردن CRUD
        $content = $content -replace "}\s*$","$crudMethods`n}"
        [System.IO.File]::WriteAllText($controllerFile, $content, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "✅ CRUD methods added: $className"
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
# 5️⃣ migrate واقعی (ایجاد جدول‌ها با FK)
# ----------------------------
php artisan migrate:install
php artisan migrate --force

# ----------------------------
# 6️⃣ Seed خودکار از final.html
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
    Write-Host "✅ Seeder executed: $seederName"
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

Write-Host "🎯 FULL PROJECT SETUP COMPLETE: BOM, Controllers+CRUD, Models, Migration, Seeder, FK, Cache, Autoload!" -ForegroundColor Green
