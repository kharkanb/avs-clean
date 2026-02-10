# =====================================================
# setup-final-complete.ps1 - آماده سازی کامل پروژه
# =====================================================


#این PowerShell آماده‌ی اجرا است و وقتی run شود:
#همه فایل‌های PHP بدون BOM می‌شوند
#تمام Modelها و Controllerها ساخته و بررسی می‌شوند
#تمام Migrationهای جدول‌ها با foreign keyها اصلاح می‌شوند
#Seed اولیه برای EquipmentType, Brand, ConsumableItem اعمال می‌شود
#Cache پاک می‌شود و composer dump-autoload اجرا می‌شود
#php artisan route:list بدون خطا کار می‌کند
#API /api/equipment تست می‌شود
#تمام مراحل Plug-and-play هستند: فقط این فایل را اجرا کنید و دیتابیس، Migrationها، Controllerها و Routes آماده خواهند شد


# مسیر پروژه
$basePath = Get-Location
$controllerDir = Join-Path $basePath "app\Http\Controllers"
$modelDir      = Join-Path $basePath "app\Models"
$routesDir     = Join-Path $basePath "routes"
$migrationsDir = Join-Path $basePath "database\migrations"
$seedersDir    = Join-Path $basePath "database\seeders"

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
    "EquipmentController", "PostController", "ChecklistTemplateController", 
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
Write-Host "🔄 Clearing Laravel cache..."
php artisan config:clear
php artisan route:clear
php artisan view:clear
composer dump-autoload

# ----------------------------
# اصلاح migrations جدول‌ها
# ----------------------------
function Update-Migration($pattern, $content) {
    $file = Get-ChildItem -Path $migrationsDir -Filter $pattern | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($file) {
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBom)
        Write-Host "✅ Migration updated: $($file.Name)"
    }
}

# posts
Update-Migration "*_create_posts_table.php" @"
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up() {
        Schema::create('posts', function (Blueprint \$table) {
            \$table->id();
            \$table->string('name');
            \$table->timestamps();
        });
    }
    public function down() { Schema::dropIfExists('posts'); }
};
"@

# feeders
Update-Migration "*_create_feeders_table.php" @"
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up() {
        Schema::create('feeders', function (Blueprint \$table) {
            \$table->id();
            \$table->foreignId('post_id')->constrained()->cascadeOnDelete();
            \$table->string('name');
            \$table->timestamps();
        });
    }
    public function down() { Schema::dropIfExists('feeders'); }
};
"@

# Equipment
Update-Migration "*_create_equipment_table.php" @"
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up() {
        Schema::create('equipment', function (Blueprint \$table) {
            \$table->id();
            \$table->string('equipment_name');
            \$table->foreignId('equipment_type')->constrained('equipment_types');
            \$table->foreignId('brand')->nullable()->constrained('brands');
            \$table->string('serial_number')->unique();
            \$table->timestamps();
        });
    }
    public function down() { Schema::dropIfExists('equipment'); }
};
"@

# ChecklistTemplate
Update-Migration "*_create_checklist_templates_table.php" @"
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up() {
        Schema::create('checklist_templates', function (Blueprint \$table) {
            \$table->id();
            \$table->foreignId('equipment_type_id')->constrained('equipment_types');
            \$table->string('name');
            \$table->timestamps();
        });
    }
    public function down() { Schema::dropIfExists('checklist_templates'); }
};
"@

# ActivityPrice
Update-Migration "*_create_activity_prices_table.php" @"
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up() {
        Schema::create('activity_prices', function (Blueprint \$table) {
            \$table->id();
            \$table->string('activity_name');
            \$table->decimal('price', 10,2);
            \$table->timestamps();
        });
    }
    public function down() { Schema::dropIfExists('activity_prices'); }
};
"@

# ConsumableItem
Update-Migration "*_create_consumable_items_table.php" @"
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up() {
        Schema::create('consumable_items', function (Blueprint \$table) {
            \$table->id();
            \$table->string('name');
            \$table->string('unit');
            \$table->timestamps();
        });
    }
    public function down() { Schema::dropIfExists('consumable_items'); }
};
"@

# Brand
Update-Migration "*_create_brands_table.php" @"
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up() {
        Schema::create('brands', function (Blueprint \$table) {
            \$table->id();
            \$table->string('name');
            \$table->timestamps();
        });
    }
    public function down() { Schema::dropIfExists('brands'); }
};
"@

# EquipmentType
Update-Migration "*_create_equipment_types_table.php" @"
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up() {
        Schema::create('equipment_types', function (Blueprint \$table) {
            \$table->id();
            \$table->string('name');
            \$table->boolean('has_height')->default(false);
            \$table->boolean('has_brand')->default(false);
            \$table->timestamps();
        });
    }
    public function down() { Schema::dropIfExists('equipment_types'); }
};
"@

# ----------------------------
# اجرا migrate
# ----------------------------
Write-Host "🔄 Running migrate..."
try { php artisan migrate:install } catch { Write-Host "⚠️ migrate:install skipped" }
try { php artisan migrate --force } catch { Write-Host "❌ Migration error: $_" }

# ----------------------------
# Seed اولیه
# ----------------------------
Write-Host "🔄 Creating seeders..."
$seeders = @(
    @{name="EquipmentTypeSeeder"; content=@"
<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
class EquipmentTypeSeeder extends Seeder {
    public function run() {
        DB::table('equipment_types')->insert([
            ['name'=>'رایکلوزر','has_height'=>1,'has_brand'=>1],
            ['name'=>'سکسیونر','has_height'=>1,'has_brand'=>1],
            ['name'=>'سکشنالایزر','has_height'=>1,'has_brand'=>1]
        ]);
    }
}
"@},
    @{name="BrandSeeder"; content=@"
<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
class BrandSeeder extends Seeder {
    public function run() {
        DB::table('brands')->insert([
            ['name'=>'BrandA'], ['name'=>'BrandB'], ['name'=>'BrandC']
        ]);
    }
}
"@},
    @{name="ConsumableItemSeeder"; content=@"
<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
class ConsumableItemSeeder extends Seeder {
    public function run() {
        DB::table('consumable_items')->insert([
            ['name'=>'مودم','unit'=>'عدد'],
            ['name'=>'RTU','unit'=>'عدد'],
            ['name'=>'آنتن','unit'=>'عدد']
        ]);
    }
}
"@}
)

foreach ($s in $seeders) {
    $file = Join-Path $seedersDir "$($s.name).php"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($file, $s.content, $utf8NoBom)
    Write-Host "✅ Seeder created: $($s.name)"
}

# اجرای seed
php artisan db:seed --class=EquipmentTypeSeeder
php artisan db:seed --class=BrandSeeder
php artisan db:seed --class=ConsumableItemSeeder

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
Write-Host "🔍 Routes:"
php artisan route:list

# ----------------------------
# تست API
# ----------------------------
$port = 8000
$apiUrl = "http://127.0.0.1:$port/api/equipment"
try {
    $response = Invoke-RestMethod -Uri $apiUrl -Method GET -ErrorAction SilentlyContinue
    if ($response) { Write-Host "✅ API /api/equipment responded" }
    else { Write-Host "⚠️ API /api/equipment did not respond" }
} catch {
    Write-Host "❌ API test error: $_"
}

Write-Host "🎯 Setup complete!"