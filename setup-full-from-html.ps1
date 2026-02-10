# =====================================================
# setup-full-from-html.ps1
# آماده سازی کامل پروژه با داده‌های final.html
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
# Model ها + Migration
# ----------------------------
$models = @(
    "Equipment", "Post", "Feeder", "ChecklistTemplate", 
    "ActivityPrice", "ConsumableItem", "Brand", "EquipmentType"
)
foreach ($m in $models) {
    $path = Join-Path $modelDir "$m.php"
    if (-not (Test-Path $path)) {
        php artisan make:model $m -m
        Write-Host "✅ Model + Migration created: $m"
    }
}

# ----------------------------
# پاک کردن cache لاراول
# ----------------------------
php artisan config:clear
php artisan route:clear
php artisan view:clear
composer dump-autoload

# ----------------------------
# استخراج داده‌ها از final.html
# ----------------------------
$htmlContent = Get-Content -Path $htmlFile -Raw

# استخراج JSONها از فایل HTML
$matches = [regex]::Matches($htmlContent, 'http://localhost:8000/api/[\w\-/]+[\s\S]*?(\[.*?\])')
$apiData = @{}
foreach ($m in $matches) {
    $url = $m.Value -replace '.*(http://localhost:8000/api/[\w\-/]+).*', '$1'
    $json = $m.Groups[1].Value
    try {
        $apiData[$url] = $json | ConvertFrom-Json
        Write-Host "✅ Parsed data from $url"
    } catch {
        Write-Host "⚠️ Failed to parse $url"
    }
}

# ----------------------------
# ساخت Seeder ها از داده‌های واقعی
# ----------------------------
foreach ($key in $apiData.Keys) {
    $name = ($key -replace '/api/','') -replace '/','_'
    $seederName = ($name.Substring(0,1).ToUpper() + $name.Substring(1)) + "Seeder"
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
        DB::table('$name')->insert([
            $(($items -join ",`n            "))
        ]);
    }
}
"@
    [System.IO.File]::WriteAllText($filePath, $content, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "✅ Seeder created: $seederName"
}

# ----------------------------
# اجرای migrate
# ----------------------------
php artisan migrate:install
php artisan migrate --force

# ----------------------------
# اجرای seed ها
# ----------------------------
Get-ChildItem -Path $seedersDir -Filter "*Seeder.php" | ForEach-Object {
    $className = $_.BaseName
    php artisan db:seed --class=$className
    Write-Host "✅ Seeded: $className"
}

# ----------------------------
# پاک کردن cache و autoload مجدد
# ----------------------------
php artisan config:clear
php artisan route:clear
php artisan view:clear
composer dump-autoload

# ----------------------------
# بررسی route ها
# ----------------------------
php artisan route:list

# ----------------------------
# تست API پایه
# ----------------------------
$port = 8000
foreach ($url in $apiData.Keys) {
    $fullUrl = "http://127.0.0.1:$port$url"
    try {
        $response = Invoke-RestMethod -Uri $fullUrl -Method GET -ErrorAction SilentlyContinue
        if ($response) { Write-Host "✅ API $url responded" }
        else { Write-Host "⚠️ API $url did not respond" }
    } catch {
        Write-Host "❌ API $url error: $_"
    }
}

Write-Host "🎯 Full setup complete!"
