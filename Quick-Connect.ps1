# RustDesk 快速连接脚本
# 适配 Sciter 版本的限制

param(
    [Parameter(Mandatory=$false)]
    [string]$RemoteID = "1074305050",
    
    [Parameter(Mandatory=$false)]
    [string]$Password = "xiehan12",
    
    [Parameter(Mandatory=$false)]
    [switch]$SetPermanentPassword
)

Write-Host "=== RustDesk 快速连接 ===" -ForegroundColor Cyan
Write-Host ""

# 查找 RustDesk
$rustdeskPaths = @(
    "${env:ProgramFiles(x86)}\RustDesk\rustdesk.exe",
    "$env:ProgramFiles\RustDesk\rustdesk.exe",
    "$env:LOCALAPPDATA\RustDesk\rustdesk.exe"
)

$rustdeskExe = $null
foreach ($path in $rustdeskPaths) {
    if (Test-Path $path) {
        $rustdeskExe = $path
        break
    }
}

if (-not $rustdeskExe) {
    Write-Host "✗ 未找到 RustDesk" -ForegroundColor Red
    exit 1
}

Write-Host "找到 RustDesk: $rustdeskExe" -ForegroundColor Green
Write-Host ""

# 检测版本
$fileSize = (Get-Item $rustdeskExe).Length / 1MB
$rustdeskDir = Split-Path $rustdeskExe
$isSciter = (Test-Path "$rustdeskDir\sciter.dll") -or ($fileSize -lt 25)

if ($isSciter) {
    Write-Host "检测到 Sciter 版本" -ForegroundColor Yellow
    Write-Host ""
    
    if ($SetPermanentPassword) {
        # 设置永久密码模式
        Write-Host "正在设置永久密码..." -ForegroundColor Yellow
        Write-Host "密码: $Password" -ForegroundColor Gray
        Write-Host ""
        
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Host "✗ 需要管理员权限才能设置永久密码" -ForegroundColor Red
            Write-Host ""
            Write-Host "请以管理员身份运行:" -ForegroundColor Yellow
            Write-Host ".\Quick-Connect.ps1 -SetPermanentPassword -Password $Password" -ForegroundColor Cyan
            exit 1
        }
        
        try {
            & $rustdeskExe --password $Password
            Start-Sleep -Seconds 2
            Write-Host "✓ 永久密码已设置" -ForegroundColor Green
            Write-Host ""
            Write-Host "现在可以直接连接，无需再输入密码:" -ForegroundColor Green
            Write-Host ".\Quick-Connect.ps1 -RemoteID $RemoteID" -ForegroundColor Cyan
        } catch {
            Write-Host "✗ 设置失败: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    } else {
        # 连接模式
        Write-Host "Sciter 版本使用说明:" -ForegroundColor Yellow
        Write-Host "• --password 参数在连接时不生效" -ForegroundColor Yellow
        Write-Host "• 需要先设置永久密码，或手动输入" -ForegroundColor Yellow
        Write-Host ""
        
        Write-Host "选择连接方式:" -ForegroundColor Cyan
        Write-Host "[1] 使用永久密码自动连接（需先设置）" -ForegroundColor Gray
        Write-Host "[2] 手动输入密码连接" -ForegroundColor Gray
        Write-Host "[3] 现在设置永久密码" -ForegroundColor Gray
        Write-Host ""
        Write-Host "请选择 (1/2/3): " -NoNewline -ForegroundColor Yellow
        $choice = Read-Host
        
        switch ($choice) {
            "1" {
                Write-Host ""
                Write-Host "正在连接到: $RemoteID（使用永久密码）..." -ForegroundColor Yellow
                & $rustdeskExe --connect $RemoteID
            }
            "2" {
                Write-Host ""
                Write-Host "正在连接到: $RemoteID（请手动输入密码）..." -ForegroundColor Yellow
                & $rustdeskExe --connect $RemoteID
            }
            "3" {
                Write-Host ""
                Write-Host "设置永久密码需要管理员权限" -ForegroundColor Yellow
                Write-Host "请以管理员身份运行:" -ForegroundColor Yellow
                Write-Host ".\Quick-Connect.ps1 -SetPermanentPassword -Password $Password" -ForegroundColor Cyan
            }
            default {
                Write-Host ""
                Write-Host "✗ 无效选择" -ForegroundColor Red
                exit 1
            }
        }
    }
} else {
    # Flutter 版本 - 完整支持
    Write-Host "检测到 Flutter 版本" -ForegroundColor Green
    Write-Host "正在连接到: $RemoteID..." -ForegroundColor Yellow
    Write-Host ""
    
    & $rustdeskExe --connect $RemoteID --password $Password
}

Write-Host ""
Write-Host "=== 完成 ===" -ForegroundColor Cyan
