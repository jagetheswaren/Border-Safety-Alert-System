# ==============================================================================
# Border Safety Alert System (BSAS) — Unified Windows Laptop Launcher
# Starts and orchestrates all BSAS services:
# 1. FastAPI Backend (port 8000)
# 2. Next.js Operations Dashboard (port 3000)
# 3. Flutter Web / Laptop Civilian Client (port 8080)
# ==============================================================================

param(
    [switch]$Stop,
    [switch]$NoBrowser
)

$ErrorActionPreference = "Continue"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   BORDER SAFETY ALERT SYSTEM (BSAS) — LAPTOP LAUNCHER      " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan

function Test-PortOpen([string]$HostName, [int]$Port) {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $iar = $tcp.BeginConnect($HostName, $Port, $null, $null)
        $wait = $iar.AsyncWaitHandle.WaitOne(800, $false)
        if ($wait) {
            $tcp.EndConnect($iar)
            $tcp.Close()
            return $true
        }
        $tcp.Close()
        return $false
    } catch {
        return $false
    }
}

if ($Stop) {
    Write-Host "`n[*] Terminating all running BSAS services..." -ForegroundColor Yellow
    Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | ForEach-Object {
        Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
    }
    Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue | ForEach-Object {
        Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
    }
    Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | ForEach-Object {
        Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[OK] All BSAS laptop background processes stopped." -ForegroundColor Green
    exit 0
}

# 1. Backend Service (Port 8000)
$backendRunning = Test-PortOpen "127.0.0.1" 8000
if ($backendRunning) {
    Write-Host "[*] FastAPI Backend already running on http://127.0.0.1:8000" -ForegroundColor Green
} else {
    Write-Host "[*] Starting FastAPI Backend on port 8000..." -ForegroundColor Yellow
    $backendDir = Join-Path $ProjectRoot "backend"
    Start-Process -FilePath "python" -ArgumentList "-m uvicorn app.main:app --host 127.0.0.1 --port 8000" -WorkingDirectory $backendDir -WindowStyle Hidden
    Start-Sleep -Seconds 3
    if (Test-PortOpen "127.0.0.1" 8000) {
        Write-Host "[OK] FastAPI Backend active: http://127.0.0.1:8000/docs" -ForegroundColor Green
    } else {
        Write-Host "[!] Warning: FastAPI Backend failed to bind port 8000." -ForegroundColor Red
    }
}

# 2. Next.js Operations Dashboard (Port 3000)
$dashRunning = Test-PortOpen "127.0.0.1" 3000
if ($dashRunning) {
    Write-Host "[*] Next.js Dashboard already running on http://localhost:3000" -ForegroundColor Green
} else {
    Write-Host "[*] Starting Next.js Operations Dashboard on port 3000..." -ForegroundColor Yellow
    $frontDir = Join-Path $ProjectRoot "frontend"
    Start-Process -FilePath "npm.cmd" -ArgumentList "run start -- -p 3000" -WorkingDirectory $frontDir -WindowStyle Hidden
    Start-Sleep -Seconds 4
    if (Test-PortOpen "127.0.0.1" 3000) {
        Write-Host "[OK] Next.js Dashboard active: http://localhost:3000/dashboard" -ForegroundColor Green
    } else {
        Write-Host "[!] Warning: Next.js Dashboard starting in background..." -ForegroundColor Yellow
    }
}

# 3. Flutter Web Client (Port 8080)
$webRunning = Test-PortOpen "127.0.0.1" 8080
if ($webRunning) {
    Write-Host "[*] Flutter Web Client already running on http://localhost:8080" -ForegroundColor Green
} else {
    Write-Host "[*] Starting Flutter Web Client on port 8080..." -ForegroundColor Yellow
    Start-Process -FilePath "python" -ArgumentList "-m http.server 8080 --directory build/web" -WorkingDirectory $ProjectRoot -WindowStyle Hidden
    Start-Sleep -Seconds 2
    if (Test-PortOpen "127.0.0.1" 8080) {
        Write-Host "[OK] Flutter Web Client active: http://localhost:8080" -ForegroundColor Green
    } else {
        Write-Host "[!] Warning: Flutter Web Client failed to bind port 8080." -ForegroundColor Red
    }
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "   ALL BSAS LAPTOP COMPONENTS RUNNING SUCCESSFULLY!         " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "1. Operations Command Center:  http://localhost:3000/dashboard" -ForegroundColor White
Write-Host "2. Interactive Tactical Map:    http://localhost:3000/dashboard/map" -ForegroundColor White
Write-Host "3. Civilian Field Client Web:   http://localhost:8080" -ForegroundColor White
Write-Host "4. FastAPI Swagger Core API:    http://127.0.0.1:8000/docs" -ForegroundColor White
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "To stop all services later, run:  .\scripts\launch_bsas_laptop.ps1 -Stop`n" -ForegroundColor Yellow

if (-not $NoBrowser) {
    Start-Process "http://localhost:3000/dashboard"
    Start-Process "http://localhost:8080"
}
