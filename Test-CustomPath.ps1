# RustDesk 自定义路径安装测试脚本
# 用于测试 --path 参数功能

param(
    [string]$InstallerPath = ".\target\release\rustdesk.exe",
    [string]$TestPath = "D:\Test\RustDesk"
)

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  RustDesk 自定义路径安装测试" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# 检查安装文件
if (-not (Test-Path $InstallerPath)) {
    Write-Host "错误: 找不到安装文件 $InstallerPath" -ForegroundColor Red
    Write-Host "请先编译项目: cargo build --release --features inline" -ForegroundColor Yellow
    exit 1
}

Write-Host "测试配置:" -ForegroundColor Yellow
Write-Host "  安装程序: $InstallerPath" -ForegroundColor White
Write-Host "  目标路径: $TestPath" -ForegroundColor White
Write-Host ""

# 测试 1: 默认路径安装
Write-Host "[测试 1/3] 默认路径安装测试" -ForegroundColor Green
Write-Host "命令: rustdesk.exe --silent-install" -ForegroundColor Gray
Write-Host "预期: 安装到 C:\Program Files\RustDesk" -ForegroundColor Gray
Write-Host ""

# 测试 2: 自定义路径安装（不带引号）
Write-Host "[测试 2/3] 自定义路径安装测试（不带空格）" -ForegroundColor Green
Write-Host "命令: rustdesk.exe --silent-install --path=`"$TestPath`"" -ForegroundColor Gray
Write-Host "预期: 安装到 $TestPath" -ForegroundColor Gray
Write-Host ""

# 测试 3: 自定义路径安装（带空格）
$testPathWithSpace = "D:\Test\My RustDesk"
Write-Host "[测试 3/3] 自定义路径安装测试（带空格）" -ForegroundColor Green
Write-Host "命令: rustdesk.exe --silent-install --path=`"$testPathWithSpace`"" -ForegroundColor Gray
Write-Host "预期: 安装到 $testPathWithSpace" -ForegroundColor Gray
Write-Host ""

# 询问是否执行实际安装
$confirm = Read-Host "是否执行实际安装测试? (y/n)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "测试取消" -ForegroundColor Yellow
    exit 0
}

# 执行测试 2
Write-Host ""
Write-Host "执行测试 2: 安装到 $TestPath" -ForegroundColor Cyan
Write-Host "命令: & `"$InstallerPath`" --silent-install --path=`"$TestPath`" debug" -ForegroundColor Gray
Write-Host ""

# 执行安装
$installArgs = "--silent-install --path=`"$TestPath`" debug"
Start-Process -FilePath $InstallerPath -ArgumentList $installArgs -Wait -Verb RunAs

Start-Sleep -Seconds 3

# 验证安装结果
Write-Host ""
Write-Host "验证安装结果..." -ForegroundColor Yellow

$targetExe = Join-Path $TestPath "rustdesk.exe"
if (Test-Path $targetExe) {
    Write-Host "✅ 成功: 程序已安装到自定义路径" -ForegroundColor Green
    Write-Host "   路径: $targetExe" -ForegroundColor White
    
    # 检查文件大小
    $fileInfo = Get-Item $targetExe
    Write-Host "   大小: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor White
    Write-Host "   创建时间: $($fileInfo.CreationTime)" -ForegroundColor White
} else {
    Write-Host "❌ 失败: 未在目标路径找到程序" -ForegroundColor Red
    Write-Host "   预期路径: $targetExe" -ForegroundColor White
}

# 检查默认路径（确保没有安装到默认位置）
$defaultPath = "C:\Program Files\RustDesk\rustdesk.exe"
if (Test-Path $defaultPath) {
    Write-Host "⚠️  警告: 默认路径也存在安装文件" -ForegroundColor Yellow
    Write-Host "   路径: $defaultPath" -ForegroundColor White
}

# 检查桌面快捷方式
$desktopShortcut = "$env:PUBLIC\Desktop\RustDesk.lnk"
if (Test-Path $desktopShortcut) {
    Write-Host "✅ 桌面快捷方式已创建" -ForegroundColor Green
    
    # 检查快捷方式指向
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($desktopShortcut)
    Write-Host "   目标: $($shortcut.TargetPath)" -ForegroundColor White
} else {
    Write-Host "❌ 桌面快捷方式未创建" -ForegroundColor Red
}

# 检查服务
Write-Host ""
Write-Host "检查 RustDesk 服务..." -ForegroundColor Yellow
$service = Get-Service -Name "RustDesk" -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "✅ 服务已安装" -ForegroundColor Green
    Write-Host "   状态: $($service.Status)" -ForegroundColor White
    Write-Host "   启动类型: $($service.StartType)" -ForegroundColor White
} else {
    Write-Host "❌ 服务未安装" -ForegroundColor Red
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "测试完成！" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# 询问是否卸载
$uninstall = Read-Host "是否卸载测试安装? (y/n)"
if ($uninstall -eq 'y' -or $uninstall -eq 'Y') {
    Write-Host "执行卸载..." -ForegroundColor Yellow
    & $targetExe --uninstall
    Start-Sleep -Seconds 2
    
    # 手动删除测试目录
    if (Test-Path $TestPath) {
        Write-Host "删除测试目录: $TestPath" -ForegroundColor Yellow
        Remove-Item -Path $TestPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "卸载完成！" -ForegroundColor Green
}
