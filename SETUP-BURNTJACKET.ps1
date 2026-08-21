$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "Burnt Jacket Setup"

Write-Host ""
Write-Host "==========================================" -ForegroundColor DarkYellow
Write-Host "          BURNT JACKET - FIRST SETUP" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor DarkYellow
Write-Host ""

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

function Require-Command($Name, $InstallHint) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Host "Missing requirement: $Name" -ForegroundColor Red
        Write-Host $InstallHint -ForegroundColor Yellow
        Write-Host ""
        return $false
    }
    return $true
}

$ok = $true
$ok = (Require-Command "python" "Install Python 3.11+ from https://www.python.org/downloads/ and check 'Add Python to PATH'.") -and $ok
$ok = (Require-Command "node" "Install Node.js LTS from https://nodejs.org/") -and $ok
$ok = (Require-Command "npm" "npm is included with Node.js LTS.") -and $ok
$ok = (Require-Command "docker" "Install Docker Desktop from https://www.docker.com/products/docker-desktop/ and start it.") -and $ok

if (-not $ok) {
    Write-Host "Install the missing requirement(s), then run SETUP-BURNTJACKET.bat again." -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}

Write-Host "Checking Docker..." -ForegroundColor Cyan
try {
    docker info | Out-Null
} catch {
    Write-Host "Docker Desktop is installed but does not appear to be running." -ForegroundColor Red
    Write-Host "Start Docker Desktop, wait until it is ready, then run setup again." -ForegroundColor Yellow
    Read-Host "Press Enter to close"
    exit 1
}

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env from .env.example" -ForegroundColor Green
}

if (-not (Test-Path "apps\web\.env.local")) {
    Copy-Item "apps\web\.env.local.example" "apps\web\.env.local"
    Write-Host "Created apps\web\.env.local" -ForegroundColor Green
}

Write-Host ""
Write-Host "Starting PostgreSQL..." -ForegroundColor Cyan
docker compose up -d db

Write-Host ""
Write-Host "Creating Python virtual environment..." -ForegroundColor Cyan
if (-not (Test-Path "apps\api\.venv")) {
    python -m venv "apps\api\.venv"
}

$PythonExe = Join-Path $Root "apps\api\.venv\Scripts\python.exe"
$PipExe = Join-Path $Root "apps\api\.venv\Scripts\pip.exe"

Write-Host "Installing API packages..." -ForegroundColor Cyan
& $PythonExe -m pip install --upgrade pip
& $PipExe install -r "apps\api\requirements.txt"

Write-Host ""
Write-Host "Installing website packages..." -ForegroundColor Cyan
Push-Location "apps\web"
npm install
Pop-Location

Write-Host ""
Write-Host "Starting API temporarily to initialize the database..." -ForegroundColor Cyan
$ApiProcess = Start-Process -FilePath $PythonExe `
    -ArgumentList "-m","uvicorn","app.main:app","--host","127.0.0.1","--port","8000" `
    -WorkingDirectory (Join-Path $Root "apps\api") `
    -PassThru -WindowStyle Hidden

$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 1
    try {
        $health = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/health" -TimeoutSec 2
        if ($health.status -eq "ok") {
            $ready = $true
            break
        }
    } catch {}
}

if (-not $ready) {
    try { Stop-Process -Id $ApiProcess.Id -Force } catch {}
    Write-Host "The API did not start correctly." -ForegroundColor Red
    Write-Host "Run START-BURNTJACKET.bat and review the API window for details." -ForegroundColor Yellow
    Read-Host "Press Enter to close"
    exit 1
}

try {
    Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8000/api/v1/dev/bootstrap-db" | Out-Null
    Write-Host "Database initialized." -ForegroundColor Green
} finally {
    try { Stop-Process -Id $ApiProcess.Id -Force } catch {}
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor DarkYellow
Write-Host "         BURNT JACKET SETUP COMPLETE" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor DarkYellow
Write-Host ""
Write-Host "Next time, double-click:" -ForegroundColor White
Write-Host "    START-BURNTJACKET.bat" -ForegroundColor Yellow
Write-Host ""
Write-Host "Optional integrations:" -ForegroundColor White
Write-Host "  Discogs keys:      edit .env" -ForegroundColor Gray
Write-Host "  Ticketmaster key:  edit .env" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to close"
