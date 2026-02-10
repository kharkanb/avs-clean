# =====================================================
# setup-final.ps1 - آماده سازی کامل پروژه با تمام Migrationها
# =====================================================

# ----------------------------
# مسیر پروژه و فایل‌ها
# ----------------------------
$basePath = Get-Location
$controllerDir = Join-Path $basePath "app\Http\Controllers"
$modelDir      = Join-Path $basePath "app\Models"
$routesDir     = Join-Path $basePath "routes"
$migrationsDir = Join-Path $basePath "database\migrations"

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
# بررسی و ساخت Controller ها
# ----------------------------
$controllers = @("EquipmentController", "PostController", "ChecklistTemplateController", "ActivityPriceController", "ConsumableController", "BrandController")
foreach ($c in $controllers) {
    $path = Join-Path $controllerDir "$c.php"
    if (-not (Test-Path $path)) {
        php artisan make:controller $c
        Write-Host "✅ Controller created: $c"
    }
}

# ----------------------------
# بررسی و ساخت Model ها
# ----------------------------
$models = @("Equipment", "Post", "Feeder", "ChecklistTemplate", "ActivityPrice", "ConsumableItem", "Brand", "EquipmentType")
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
Write-Host "🔄 Clearing Laravel cache..."
php artisan config:clear
php artisan route:clear
php artisan view:clear
composer dump-autoload

# ----------------------------
# اصلاح migrations برای foreign key و جدول‌ها
# ----------------------------
# مثال posts
$postMigration = Get-ChildItem -Path $migrationsDir -Filter "*_create_posts_table.php" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($postMigration) {
    $content = @"
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('posts', function (Blueprint \$table) {
            \$table->id();
            \$table->string('name');
            \$table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('posts');
    }
};
"@
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($postMigration.FullName, $content, $utf8NoBom)
    Write-Host "✅ posts migration updated"
}

# مثال feeders
$feederMigration = Get-ChildItem -Path $migrationsDir -Filter "*_create_feeders_table.php" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($feederMigration) {
    $content = @"
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('feeders', function (Blueprint \$table) {
            \$table->id();
            \$table->foreignId('post_id')->constrained()->cascadeOnDelete();
            \$table->string('name');
            \$table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('feeders');
    }
};
"@
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($feederMigration.FullName, $content, $utf8NoBom)
    Write-Host "✅ feeders migration updated"
}

# ----------------------------
# اجرا migrate
# ----------------------------
Write-Host "🔄 Running migrate..."
try {
    php artisan migrate:install
} catch { Write-Host "⚠️ migrate:install skipped"; }
try {
    php artisan migrate --force
} catch {
    Write-Host "❌ Migration error: $_"
}

# ----------------------------
# بررسی route ها
# ----------------------------
Write-Host "🔍 Routes:"
php artisan route:list

# ----------------------------
# تست API
# ----------------------------
$port = 8000
$apiUrl = "http://127.0.0.1:$port/api/equipment"
try {
    $response = Invoke-RestMethod -Uri $apiUrl -Method GET -ErrorAction SilentlyContinue
    if ($response) {
        Write-Host "✅ API /api/equipment responded"
    } else {
        Write-Host "⚠️ API /api/equipment did not respond"
    }
} catch {
    Write-Host "❌ API test error: $_"
}

Write-Host "🎯 Setup complete!"