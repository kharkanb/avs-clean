# Test-APIs.ps1
# توضیح: این اسکریپت همه APIهای پروژه را تست کرده و وضعیت را نمایش می‌دهد


# آخر کار در PowerShell برو به مسیر پروژه                                Cd c:\Users\dear-user\Desktop\avs-clean
#اجرا کن:
#.\Test-APIs.ps1



$apis = @(
    "http://localhost:8000/api/equipment-types",
    "http://localhost:8000/api/posts",
    "http://localhost:8000/api/checklist-template/1",
    "http://localhost:8000/api/activity-price-list",
    "http://localhost:8000/api/consumables",
    "http://localhost:8000/api/brands"
)

foreach ($url in $apis) {
    Write-Host "`n🌐 Testing $url" -ForegroundColor Cyan
    try {
        $resp = curl.exe -s -w "`nHTTP_STATUS:%{http_code}" "$url"
        $parts = $resp -split "HTTP_STATUS:"
        $body = $parts[0].Trim()
        $status = $parts[1].Trim()

        if ($status -ge 200 -and $status -lt 300) {
            Write-Host "✅ Status $status" -ForegroundColor Green
        } elseif ($status -ge 400 -and $status -lt 500) {
            Write-Host "⚠️ Client Error $status" -ForegroundColor Yellow
        } elseif ($status -ge 500) {
            Write-Host "❌ Server Error $status" -ForegroundColor Red
        } else {
            Write-Host "ℹ️ Status $status" -ForegroundColor Gray
        }

        # نمایش JSON بصورت pretty
        try {
            $json = $body | ConvertFrom-Json
            $json | ConvertTo-Json -Depth 10
        } catch {
            Write-Host $body
        }
    } catch {
        Write-Host "❌ Error accessing $url : $_" -ForegroundColor Red
    }
}

# ================================
# 🌐 تست تمام API های پروژه
# ================================

# پورت سرور
$port = 8000

# مسیرهای API
$apiData = @{
    "/api/equipment-types"        = $null
    "/api/posts"                  = $null
    "/api/posts/1/feeders"        = $null
    "/api/checklist-template/1"   = $null
    "/api/activity-price-list"    = $null
    "/api/consumables"            = $null
    "/api/brands"                 = $null
}

# چک سرور
try {
    $serverStatus = Invoke-RestMethod -Uri "http://127.0.0.1:$port/up" -Method GET -TimeoutSec 3 -ErrorAction Stop
    Write-Host "✅ سرور در حال اجراست روی پورت $port" -ForegroundColor Green
} catch {
    Write-Host "⚠️ سرور اجرا نیست! ابتدا اجرا کن: php artisan serve --port=$port" -ForegroundColor Yellow
}

# تست همه API ها
foreach ($url in $apiData.Keys) {
    $fullUrl = "http://127.0.0.1:$port$url"
    try {
        $response = Invoke-RestMethod -Uri $fullUrl -Method GET -ErrorAction Stop

        # اگر آرایه باشه تعداد آیتم ها
        if ($response -is [System.Collections.IEnumerable]) {
            $count = ($response | Measure-Object).Count
            Write-Host "✅ API $url responded with $count items" -ForegroundColor Cyan
        } else {
            Write-Host "✅ API $url responded (non-array)" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "❌ API $url error: $_" -ForegroundColor Red
    }
}
