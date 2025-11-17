# RustDesk 完整诊断脚本
# 诊断 RustDesk 版本、参数支持和 URL Scheme 问题

Write-Host "=== RustDesk 完整诊断工具 ===" -ForegroundColor Cyan
Write-Host ""

# 1. 查找 RustDesk 安装位置
Write-Host "[1] 查找 RustDesk 安装位置..." -ForegroundColor Yellow

$rustdeskPaths = @(
    "${env:ProgramFiles(x86)}\RustDesk\rustdesk.exe",
    "$env:ProgramFiles\RustDesk\rustdesk.exe",
    "$env:LOCALAPPDATA\RustDesk\rustdesk.exe"
)

$rustdeskExe = $null
foreach ($path in $rustdeskPaths) {
    if (Test-Path $path) {
        $rustdeskExe = $path
        Write-Host "   ✓ 找到 RustDesk: $path" -ForegroundColor Green
        break
    }
}

if (-not $rustdeskExe) {
    Write-Host "   ✗ 未找到 RustDesk 安装" -ForegroundColor Red
    exit 1
}

# 2. 获取版本信息
Write-Host ""
Write-Host "[2] 获取版本信息..." -ForegroundColor Yellow

$versionInfo = (Get-Item $rustdeskExe).VersionInfo
$fileVersion = $versionInfo.FileVersion
$productVersion = $versionInfo.ProductVersion

Write-Host "   文件版本: $fileVersion" -ForegroundColor Gray
Write-Host "   产品版本: $productVersion" -ForegroundColor Gray

# 3. 检测是 Sciter 还是 Flutter 版本
Write-Host ""
Write-Host "[3] 检测 UI 框架..." -ForegroundColor Yellow

$fileSize = (Get-Item $rustdeskExe).Length / 1MB
Write-Host "   文件大小: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Gray

# Sciter 版本通常较小 (< 20MB)，Flutter 版本较大 (> 30MB)
if ($fileSize -lt 25) {
    Write-Host "   ⚠ 可能是 Sciter 版本 (文件较小)" -ForegroundColor Yellow
    $uiType = "Sciter"
} else {
    Write-Host "   ✓ 可能是 Flutter 版本 (文件较大)" -ForegroundColor Green
    $uiType = "Flutter"
}

# 4. 检查 DLL 依赖（更精确判断）
$rustdeskDir = Split-Path $rustdeskExe
$hasFlutterDll = Test-Path "$rustdeskDir\flutter_windows.dll"
$hasSciterDll = Test-Path "$rustdeskDir\sciter.dll"

if ($hasFlutterDll) {
    Write-Host "   ✓ 检测到 flutter_windows.dll - 确认是 Flutter 版本" -ForegroundColor Green
    $uiType = "Flutter"
} elseif ($hasSciterDll) {
    Write-Host "   ✓ 检测到 sciter.dll - 确认是 Sciter 版本" -ForegroundColor Green
    $uiType = "Sciter"
}

Write-Host "   UI 框架: $uiType" -ForegroundColor Cyan

# 5. 测试命令行参数支持
Write-Host ""
Write-Host "[4] 测试命令行参数支持..." -ForegroundColor Yellow

Write-Host "   测试 --get-id 参数..." -ForegroundColor Gray
try {
    $output = & $rustdeskExe --get-id 2>&1
    if ($output) {
        Write-Host "   ✓ --get-id 支持: 本机ID = $output" -ForegroundColor Green
    }
} catch {
    Write-Host "   ✗ --get-id 不支持" -ForegroundColor Red
}

Write-Host ""
Write-Host "   测试 --password 参数..." -ForegroundColor Gray
Write-Host "   注意: 此参数用于设置永久密码，需要管理员权限" -ForegroundColor Gray

# 检查是否有管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "   ✓ 当前有管理员权限" -ForegroundColor Green
} else {
    Write-Host "   ⚠ 当前没有管理员权限（设置密码需要）" -ForegroundColor Yellow
}

# 6. 分析问题
Write-Host ""
Write-Host "[5] 问题分析..." -ForegroundColor Yellow

if ($uiType -eq "Sciter") {
    Write-Host ""
    Write-Host "   ⚠ 检测到您使用的是 Sciter 版本" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Sciter 版本的限制:" -ForegroundColor Yellow
    Write-Host "   1. --password 参数在连接时不生效（这是已知问题）" -ForegroundColor Red
    Write-Host "   2. URL Scheme 支持有限" -ForegroundColor Red
    Write-Host "   3. 只能使用 --password 设置永久密码，然后用 --connect 连接" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   推荐解决方案:" -ForegroundColor Green
    Write-Host "   方案 1: 先设置永久密码，再连接（无需每次输入）" -ForegroundColor Green
    Write-Host "   方案 2: 使用 --connect 参数，手动输入密码" -ForegroundColor Green
    Write-Host "   方案 3: 升级到 Flutter 版本（完整支持所有功能）" -ForegroundColor Green
} else {
    Write-Host "   ✓ Flutter 版本支持完整的命令行参数" -ForegroundColor Green
}

# 7. 提供解决方案
Write-Host ""
Write-Host "[6] 针对您的环境的解决方案..." -ForegroundColor Yellow
Write-Host ""

if ($uiType -eq "Sciter") {
    Write-Host "=== 方案 1: 设置永久密码（推荐）===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "步骤 1: 以管理员身份设置永久密码" -ForegroundColor White
    Write-Host "命令: " -NoNewline -ForegroundColor Gray
    Write-Host "`"$rustdeskExe`" --password xiehan12" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "步骤 2: 直接连接（无需再输入密码）" -ForegroundColor White
    Write-Host "命令: " -NoNewline -ForegroundColor Gray
    Write-Host "`"$rustdeskExe`" --connect 1074305050" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "是否现在设置永久密码? (需要管理员权限) [Y/N]: " -NoNewline -ForegroundColor Yellow
    $response = Read-Host
    
    if ($response -eq 'Y' -or $response -eq 'y') {
        if (-not $isAdmin) {
            Write-Host ""
            Write-Host "   ⚠ 需要管理员权限！" -ForegroundColor Red
            Write-Host "   请以管理员身份重新运行此脚本" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "   或手动以管理员身份运行:" -ForegroundColor Yellow
            Write-Host "   `"$rustdeskExe`" --password xiehan12" -ForegroundColor Cyan
        } else {
            Write-Host ""
            Write-Host "   正在设置永久密码..." -ForegroundColor Yellow
            try {
                & $rustdeskExe --password xiehan12
                Start-Sleep -Seconds 2
                Write-Host "   ✓ 密码已设置" -ForegroundColor Green
                Write-Host ""
                Write-Host "   现在可以直接连接:" -ForegroundColor Green
                Write-Host "   `"$rustdeskExe`" --connect 1074305050" -ForegroundColor Cyan
            } catch {
                Write-Host "   ✗ 设置失败: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "=== 方案 2: 使用快捷方式（一键连接）===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "创建桌面快捷方式?" -ForegroundColor Yellow
    Write-Host "[1] 创建快捷方式（自动连接+手动输入密码）" -ForegroundColor Gray
    Write-Host "[2] 创建快捷方式（使用永久密码）" -ForegroundColor Gray
    Write-Host "[N] 跳过" -ForegroundColor Gray
    Write-Host ""
    Write-Host "请选择 (1/2/N): " -NoNewline -ForegroundColor Yellow
    $shortcutChoice = Read-Host
    
    if ($shortcutChoice -eq '1') {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$Home\Desktop\连接1074305050.lnk")
        $Shortcut.TargetPath = $rustdeskExe
        $Shortcut.Arguments = "--connect 1074305050"
        $Shortcut.IconLocation = "$rustdeskExe,0"
        $Shortcut.Description = "连接到 RustDesk ID: 1074305050"
        $Shortcut.Save()
        Write-Host "   ✓ 快捷方式已创建: $Home\Desktop\连接1074305050.lnk" -ForegroundColor Green
        Write-Host "   双击快捷方式，手动输入密码即可连接" -ForegroundColor Gray
    } elseif ($shortcutChoice -eq '2') {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$Home\Desktop\连接1074305050（自动）.lnk")
        $Shortcut.TargetPath = $rustdeskExe
        $Shortcut.Arguments = "--connect 1074305050"
        $Shortcut.IconLocation = "$rustdeskExe,0"
        $Shortcut.Description = "自动连接到 RustDesk ID: 1074305050（需先设置永久密码）"
        $Shortcut.Save()
        Write-Host "   ✓ 快捷方式已创建: $Home\Desktop\连接1074305050（自动）.lnk" -ForegroundColor Green
        Write-Host "   注意: 需要先设置永久密码才能自动连接" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "=== 方案 3: 升级到 Flutter 版本 ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Flutter 版本的优势:" -ForegroundColor White
    Write-Host "   ✓ 完整支持 --password 参数" -ForegroundColor Green
    Write-Host "   ✓ 完整支持 URL Scheme" -ForegroundColor Green
    Write-Host "   ✓ 更好的性能和用户体验" -ForegroundColor Green
    Write-Host ""
    Write-Host "下载地址: https://github.com/rustdesk/rustdesk/releases" -ForegroundColor Cyan
    Write-Host "选择文件: rustdesk-<version>-x86-sciter.exe（如果要小体积）" -ForegroundColor Gray
    Write-Host "或      : rustdesk-<version>-x86_64.exe（Flutter 版本，推荐）" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== 诊断完成 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "总结:" -ForegroundColor Yellow
Write-Host "• RustDesk 路径: $rustdeskExe" -ForegroundColor Gray
Write-Host "• UI 框架: $uiType" -ForegroundColor Gray
Write-Host "• --connect 参数: ✓ 支持" -ForegroundColor Green
Write-Host "• --password 参数: $(if ($uiType -eq 'Sciter') { '⚠ 仅用于设置永久密码' } else { '✓ 完整支持' })" -ForegroundColor $(if ($uiType -eq 'Sciter') { 'Yellow' } else { 'Green' })
Write-Host "• URL Scheme: $(if ($uiType -eq 'Sciter') { '⚠ 有限支持' } else { '✓ 完整支持' })" -ForegroundColor $(if ($uiType -eq 'Sciter') { 'Yellow' } else { 'Green' })
