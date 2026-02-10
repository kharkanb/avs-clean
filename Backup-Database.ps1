# Backup-Database.ps1



#حتما your_database_name، your_db_user و your_db_password را با اطلاعات دیتابیس خودت جایگزین کن
#برای MySQL/MariaDB باید mysqldump روی سیستم نصب و در PATH باشد





# توضیح: بکاپ گیری از دیتابیس MySQL

# تنظیمات دیتابیس
$DBHost = "127.0.0.1"
$DBPort = "3306"
$DBName = "your_database_name"
$DBUser = "your_db_user"
$DBPass = "your_db_password"

# مسیر ذخیره بکاپ
$BackupFolder = "backups"
if (-not (Test-Path $BackupFolder)) {
    New-Item -ItemType Directory -Path $BackupFolder
}

# نام فایل بکاپ با تاریخ
$Date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$BackupFile = Join-Path $BackupFolder "$DBName-backup-$Date.sql"

# اجرای mysqldump
$mysqldumpPath = "mysqldump" # مسیر mysqldump را اگر در PATH نیست مشخص کن
$cmd = "$mysqldumpPath -h $DBHost -P $DBPort -u $DBUser -p$DBPass $DBName > `"$BackupFile`""

Write-Host "💾 در حال بکاپ گیری از دیتابیس $DBName ..." -ForegroundColor Cyan
cmd.exe /c $cmd

if (Test-Path $BackupFile) {
    Write-Host "✅ بکاپ با موفقیت ایجاد شد: $BackupFile" -ForegroundColor Green
} else {
    Write-Host "❌ بکاپ ایجاد نشد!" -ForegroundColor Red
}
