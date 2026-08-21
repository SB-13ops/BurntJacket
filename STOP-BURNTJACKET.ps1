$ErrorActionPreference = "SilentlyContinue"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

Write-Host "Stopping Burnt Jacket..." -ForegroundColor Yellow

Get-CimInstance Win32_Process |
    Where-Object {
        ($_.Name -match "python|node") -and
        ($_.CommandLine -match "uvicorn app.main:app|next dev")
    } |
    ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force
    }

docker compose stop db | Out-Null

Write-Host "Burnt Jacket stopped." -ForegroundColor Green
Start-Sleep -Seconds 2
