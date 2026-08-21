$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "Burnt Jacket Launcher"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

Write-Host ""
Write-Host "==========================================" -ForegroundColor DarkYellow
Write-Host "              BURNT JACKET" -ForegroundColor Yellow
Write-Host "      Your collection. Your hunt." -ForegroundColor DarkYellow
Write-Host "              Your music." -ForegroundColor DarkYellow
Write-Host "==========================================" -ForegroundColor DarkYellow
Write-Host ""

if (-not (Test-Path "apps\api\.venv\Scripts\python.exe")) {
    Write-Host "Burnt Jacket has not been set up yet." -ForegroundColor Yellow
    Write-Host "Running first-time setup now..." -ForegroundColor Cyan
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root "SETUP-BURNTJACKET.ps1")
}

try {
    docker info | Out-Null
} catch {
    Write-Host "Docker Desktop is not running." -ForegroundColor Red
    Write-Host "Start Docker Desktop and run START-BURNTJACKET.bat again." -ForegroundColor Yellow
    Read-Host "Press Enter to close"
    exit 1
}

Write-Host "Starting Burnt Jacket database..." -ForegroundColor Cyan
docker compose up -d db | Out-Null

$PythonExe = Join-Path $Root "apps\api\.venv\Scripts\python.exe"
$ApiDir = Join-Path $Root "apps\api"
$WebDir = Join-Path $Root "apps\web"

Write-Host "Starting Burnt Jacket API..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-NoProfile",
    "-Command",
    "Set-Location '$ApiDir'; `$Host.UI.RawUI.WindowTitle='Burnt Jacket API'; & '$PythonExe' -m uvicorn app.main:app --host 127.0.0.1 --port 8000"
)

$apiReady = $false
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 1
    try {
        $health = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/health" -TimeoutSec 2
        if ($health.status -eq "ok") {
            $apiReady = $true
            break
        }
    } catch {}
}

if (-not $apiReady) {
    Write-Host "API did not become ready. Check the 'Burnt Jacket API' window." -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}

# Ensure tables are present.
try {
    Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8000/api/v1/dev/bootstrap-db" | Out-Null
} catch {}

Write-Host "Starting Burnt Jacket website..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-NoProfile",
    "-Command",
    "Set-Location '$WebDir'; `$Host.UI.RawUI.WindowTitle='Burnt Jacket Web'; npm run dev"
)

$webReady = $false
for ($i = 0; $i -lt 45; $i++) {
    Start-Sleep -Seconds 1
    try {
        $r = Invoke-WebRequest -Uri "http://127.0.0.1:3000" -TimeoutSec 2 -UseBasicParsing
        if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 500) {
            $webReady = $true
            break
        }
    } catch {}
}

if ($webReady) {
    Write-Host ""
    Write-Host "Burnt Jacket is running." -ForegroundColor Green
    Write-Host "Opening http://localhost:3000" -ForegroundColor Yellow
    Start-Process "http://localhost:3000"
} else {
    Write-Host ""
    Write-Host "The web app is still starting." -ForegroundColor Yellow
    Write-Host "When the 'Burnt Jacket Web' window says Ready, open:" -ForegroundColor White
    Write-Host "http://localhost:3000" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Keep the Burnt Jacket API and Burnt Jacket Web windows open while using the site." -ForegroundColor Gray
Write-Host "To stop Burnt Jacket, close those two windows and run STOP-BURNTJACKET.bat." -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to close this launcher"
