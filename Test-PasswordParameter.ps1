# 测试 Sciter 版本 --password 参数修复
# 验证新的参数解析是否正确工作

param(
    [Parameter(Mandatory=$false)]
    [string]$RemoteID = "1074305050",
    
    [Parameter(Mandatory=$false)]
    [string]$Password = "xiehan12"
)

Write-Host "=== 测试 Sciter --password 参数修复 ===" -ForegroundColor Cyan
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
$hasSciterDll = Test-Path "$rustdeskDir\sciter.dll"
$hasFlutterDll = Test-Path "$rustdeskDir\flutter_windows.dll"

if ($hasSciterDll) {
    $version = "Sciter"
    Write-Host "检测到 Sciter 版本" -ForegroundColor Yellow
} elseif ($hasFlutterDll) {
    $version = "Flutter"
    Write-Host "检测到 Flutter 版本" -ForegroundColor Green
} else {
    if ($fileSize -lt 25) {
        $version = "Sciter"
        Write-Host "检测到 Sciter 版本（根据文件大小判断）" -ForegroundColor Yellow
    } else {
        $version = "Flutter"
        Write-Host "检测到 Flutter 版本（根据文件大小判断）" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== 测试参数格式 ===" -ForegroundColor Cyan
Write-Host ""

# 测试 1：新格式（--password 参数）
Write-Host "[测试 1] 新格式: --connect <ID> --password <PWD>" -ForegroundColor Yellow
Write-Host "命令: `"$rustdeskExe`" --connect $RemoteID --password $Password" -ForegroundColor Gray
Write-Host ""
Write-Host "是否执行此测试? [Y/N]: " -NoNewline -ForegroundColor Yellow
$response1 = Read-Host

if ($response1 -eq 'Y' -or $response1 -eq 'y') {
    Write-Host "正在启动..." -ForegroundColor Green
    & $rustdeskExe --connect $RemoteID --password $Password
    Write-Host ""
    Write-Host "✓ 测试 1 已执行" -ForegroundColor Green
    Write-Host "请检查 RustDesk 是否:" -ForegroundColor Yellow
    Write-Host "  1. 成功启动" -ForegroundColor Gray
    Write-Host "  2. 自动填入 ID: $RemoteID" -ForegroundColor Gray
    Write-Host "  3. 自动填入密码: $Password" -ForegroundColor Gray
    Write-Host "  4. 开始连接" -ForegroundColor Gray
    Write-Host ""
    Write-Host "按任意键继续下一个测试..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Write-Host ""

# 测试 2：旧格式（直接传递密码）
Write-Host "[测试 2] 旧格式: --connect <ID> <PWD>" -ForegroundColor Yellow
Write-Host "命令: `"$rustdeskExe`" --connect $RemoteID $Password" -ForegroundColor Gray
Write-Host ""
Write-Host "是否执行此测试? [Y/N]: " -NoNewline -ForegroundColor Yellow
$response2 = Read-Host

if ($response2 -eq 'Y' -or $response2 -eq 'y') {
    Write-Host "正在启动..." -ForegroundColor Green
    & $rustdeskExe --connect $RemoteID $Password
    Write-Host ""
    Write-Host "✓ 测试 2 已执行" -ForegroundColor Green
    Write-Host "请检查 RustDesk 是否:" -ForegroundColor Yellow
    Write-Host "  1. 成功启动" -ForegroundColor Gray
    Write-Host "  2. 自动填入 ID: $RemoteID" -ForegroundColor Gray
    Write-Host "  3. 自动填入密码: $Password" -ForegroundColor Gray
    Write-Host "  4. 开始连接" -ForegroundColor Gray
    Write-Host ""
    Write-Host "按任意键继续下一个测试..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Write-Host ""

# 测试 3：不带密码
Write-Host "[测试 3] 无密码: --connect <ID>" -ForegroundColor Yellow
Write-Host "命令: `"$rustdeskExe`" --connect $RemoteID" -ForegroundColor Gray
Write-Host ""
Write-Host "是否执行此测试? [Y/N]: " -NoNewline -ForegroundColor Yellow
$response3 = Read-Host

if ($response3 -eq 'Y' -or $response3 -eq 'y') {
    Write-Host "正在启动..." -ForegroundColor Green
    & $rustdeskExe --connect $RemoteID
    Write-Host ""
    Write-Host "✓ 测试 3 已执行" -ForegroundColor Green
    Write-Host "请检查 RustDesk 是否:" -ForegroundColor Yellow
    Write-Host "  1. 成功启动" -ForegroundColor Gray
    Write-Host "  2. 自动填入 ID: $RemoteID" -ForegroundColor Gray
    Write-Host "  3. 提示输入密码（不自动填充）" -ForegroundColor Gray
    Write-Host ""
    Write-Host "按任意键继续..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Write-Host ""

# 测试 4：带其他参数
Write-Host "[测试 4] 组合参数: --connect <ID> --password <PWD> --relay" -ForegroundColor Yellow
Write-Host "命令: `"$rustdeskExe`" --connect $RemoteID --password $Password --relay" -ForegroundColor Gray
Write-Host ""
Write-Host "是否执行此测试? [Y/N]: " -NoNewline -ForegroundColor Yellow
$response4 = Read-Host

if ($response4 -eq 'Y' -or $response4 -eq 'y') {
    Write-Host "正在启动..." -ForegroundColor Green
    & $rustdeskExe --connect $RemoteID --password $Password --relay
    Write-Host ""
    Write-Host "✓ 测试 4 已执行" -ForegroundColor Green
    Write-Host "请检查 RustDesk 是否:" -ForegroundColor Yellow
    Write-Host "  1. 成功启动" -ForegroundColor Gray
    Write-Host "  2. 自动填入 ID: $RemoteID" -ForegroundColor Gray
    Write-Host "  3. 自动填入密码: $Password" -ForegroundColor Gray
    Write-Host "  4. 强制使用中继连接" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== 测试完成 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "总结:" -ForegroundColor Yellow
Write-Host "• RustDesk 版本: $version" -ForegroundColor Gray
Write-Host "• 测试 ID: $RemoteID" -ForegroundColor Gray
Write-Host "• 测试密码: $Password" -ForegroundColor Gray
Write-Host ""
Write-Host "如果所有测试都正常工作，说明 --password 参数修复成功！" -ForegroundColor Green
Write-Host ""
Write-Host "问题反馈:" -ForegroundColor Yellow
Write-Host "• 如果密码没有自动填充，请检查是否使用的是最新编译的版本" -ForegroundColor Gray
Write-Host "• 如果仍然提示密码错误，请检查密码是否正确" -ForegroundColor Gray
Write-Host "• 如果有其他问题，请提供详细的错误信息" -ForegroundColor Gray
