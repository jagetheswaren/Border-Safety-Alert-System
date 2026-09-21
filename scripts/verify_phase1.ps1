# Phase 1 verification helper. Run from repo root: .\scripts\verify_phase1.ps1
flutter --version
flutter pub get
flutter analyze
flutter test
Write-Host "Phase 1 structure check:"
Get-ChildItem -Directory ml, backend, boundary-data, docs, scripts, tests, assets
