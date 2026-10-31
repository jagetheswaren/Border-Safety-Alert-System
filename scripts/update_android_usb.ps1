param([string]$Device = 'RZ8RC0FB4GY', [switch]$SkipBuild, [switch]$ConnectOnly, [string]$AdbPath = '')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $AdbPath) {
    $adbCommand = Get-Command adb -ErrorAction SilentlyContinue
    $candidates = @(
        $(if ($adbCommand) { $adbCommand.Source }),
        (Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'),
        (Join-Path (Split-Path -Parent $projectRoot) 'Border Safety & Alert System\platform-tools\adb.exe')
    )
    $AdbPath = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
}
if (-not $AdbPath) { throw 'Android platform tools missing. Supply -AdbPath with the adb executable path.' }
$deviceState = & $AdbPath -s $Device get-state 2>&1
if ($LASTEXITCODE -ne 0 -or $deviceState -notcontains 'device') { throw 'Unlock the phone and allow USB debugging, then run again.' }
Push-Location $projectRoot
try {
    if (-not $SkipBuild -and -not $ConnectOnly) {
        # Imported read-only asset folders can make Gradle's incremental cleanup fail.
        # Only file attributes are changed; asset contents and app data are retained.
        foreach ($relativePath in @('assets', 'build')) {
            $attributeTarget = Join-Path $projectRoot $relativePath
            if (Test-Path -LiteralPath $attributeTarget) {
                Get-ChildItem -LiteralPath $attributeTarget -Recurse -Force | ForEach-Object {
                    if ($_.Attributes -band [System.IO.FileAttributes]::ReadOnly) {
                        $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
                    }
                }
            }
        }
        flutter build apk --release --no-pub --dart-define=BSAS_API_URL=http://127.0.0.1:8000
        if ($LASTEXITCODE -ne 0) { throw 'APK build failed. The installed application was not changed.' }
    }
    $apkPath = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-release.apk'
    if (-not $ConnectOnly -and -not (Test-Path -LiteralPath $apkPath)) { throw 'APK missing. Run without -SkipBuild first.' }
    & $AdbPath -s $Device reverse tcp:8000 tcp:8000
    if ($LASTEXITCODE -ne 0) { throw 'Could not connect the phone to the API over USB.' }
    & $AdbPath -s $Device reverse tcp:3000 tcp:3000
    if ($LASTEXITCODE -ne 0) { throw 'Could not connect the phone to the web app over USB.' }
    if (-not $ConnectOnly) {
        & $AdbPath -s $Device install -r $apkPath
        if ($LASTEXITCODE -ne 0) { throw 'Installation failed. No application data was deleted.' }
    }
    & $AdbPath -s $Device shell am start -n com.bordersafety.border_safety_alert/.MainActivity
    Write-Host 'BSAS updated. Keep USB connected and the laptop backend running for AI.'
    Write-Host 'Phone browser URL over this USB connection: http://localhost:3000'
} finally { Pop-Location }
