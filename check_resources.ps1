#!/usr/bin/env pwsh
# Resource Files Validation Script for RustDesk

Write-Host "=== RustDesk Resource Files Check ===" -ForegroundColor Cyan
Write-Host ""

$issues = @()
$warnings = @()

# Check Rust/Cargo resources
Write-Host "[1] Checking Rust Build Resources..." -ForegroundColor Yellow

# Icon files for Windows (build.rs)
$resourceFiles = @{
    "res/icon.ico" = "Windows icon (build.rs)"
    "res/manifest.xml" = "Windows manifest (build.rs)"
    "res/tray-icon.ico" = "Tray icon"
    "libs/portable/src/res/label.png" = "Portable packer UI label"
    "libs/portable/src/res/spin.gif" = "Portable packer UI spinner"
}

foreach ($file in $resourceFiles.Keys) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file - OK" -ForegroundColor Green
    } else {
        $issues += "Missing: $file - $($resourceFiles[$file])"
        Write-Host "  ✗ $file - MISSING" -ForegroundColor Red
    }
}

# macOS bundle icons (Cargo.toml metadata.bundle)
Write-Host ""
Write-Host "[2] Checking macOS Bundle Icons (Cargo.toml)..." -ForegroundColor Yellow
$macIcons = @("res/32x32.png", "res/128x128.png", "res/128x128@2x.png")
foreach ($icon in $macIcons) {
    if (Test-Path $icon) {
        Write-Host "  ✓ $icon - OK" -ForegroundColor Green
    } else {
        $warnings += "Missing macOS icon: $icon (not required for Windows build)"
        Write-Host "  ⚠ $icon - MISSING (macOS only, safe for Windows)" -ForegroundColor Yellow
    }
}

# Flutter assets
Write-Host ""
Write-Host "[3] Checking Flutter Assets..." -ForegroundColor Yellow

$flutterFonts = @(
    "flutter/assets/gestures.ttf",
    "flutter/assets/tabbar.ttf",
    "flutter/assets/peer_searchbar.ttf",
    "flutter/assets/address_book.ttf",
    "flutter/assets/device_group.ttf",
    "flutter/assets/more.ttf"
)

foreach ($font in $flutterFonts) {
    if (Test-Path $font) {
        Write-Host "  ✓ $font - OK" -ForegroundColor Green
    } else {
        $issues += "Missing Flutter font: $font"
        Write-Host "  ✗ $font - MISSING" -ForegroundColor Red
    }
}

# Flutter Windows runner resources
Write-Host ""
Write-Host "[4] Checking Flutter Windows Runner Resources..." -ForegroundColor Yellow
$winRunnerIcon = "flutter/windows/runner/resources/app_icon.ico"
if (Test-Path $winRunnerIcon) {
    Write-Host "  ✓ $winRunnerIcon - OK" -ForegroundColor Green
} else {
    $issues += "Missing: $winRunnerIcon"
    Write-Host "  ✗ $winRunnerIcon - MISSING" -ForegroundColor Red
}

# MSI resources
Write-Host ""
Write-Host "[5] Checking MSI Package Resources..." -ForegroundColor Yellow
if (Test-Path "res/msi/Package/Resources/icon.ico") {
    Write-Host "  ✓ res/msi/Package/Resources/icon.ico - OK" -ForegroundColor Green
} elseif (Test-Path "res/icon.ico") {
    Write-Host "  ⚠ MSI icon will be copied from res/icon.ico during build" -ForegroundColor Yellow
} else {
    $issues += "Missing: res/icon.ico (required for MSI)"
    Write-Host "  ✗ res/icon.ico - MISSING" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
if ($issues.Count -eq 0) {
    Write-Host "✓ All critical resources are present for Windows build!" -ForegroundColor Green
} else {
    Write-Host "✗ Found $($issues.Count) critical issue(s):" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠ Found $($warnings.Count) warning(s):" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  - $warning" -ForegroundColor Yellow
    }
}

Write-Host ""
if ($issues.Count -eq 0) {
    Write-Host "Status: READY FOR BUILD ✓" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Status: BUILD MAY FAIL ✗" -ForegroundColor Red
    exit 1
}
