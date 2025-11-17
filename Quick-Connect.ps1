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
    Write-Host "检测到 Sciter 版本（已支持 --password 参数）" -ForegroundColor Green
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
        # 连接模式 - 现在支持 --password 参数了！
        Write-Host "正在连接到: $RemoteID（使用密码: $Password）..." -ForegroundColor Yellow
        Write-Host ""
        
        if ($Password) {
            & $rustdeskExe --connect $RemoteID --password $Password
        } else {
            Write-Host "未提供密码，将提示手动输入..." -ForegroundColor Gray
            & $rustdeskExe --connect $RemoteID
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
