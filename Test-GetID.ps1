# Test-GetID.ps1
# 测试 --get-id 功能

Write-Host "=== 测试 RustDesk --get-id 功能 ===" -ForegroundColor Cyan
Write-Host ""

$rustdeskPath = "C:\Program Files (x86)\RustDesk\rustdesk.exe"

# 检查文件
if (-not (Test-Path $rustdeskPath)) {
    Write-Host "❌ 找不到 RustDesk：$rustdeskPath" -ForegroundColor Red
    exit 1
}

Write-Host "RustDesk 路径: $rustdeskPath" -ForegroundColor Gray
Write-Host ""

# 测试 --version (这个应该总是有效的)
Write-Host "[测试 1] 运行: rustdesk.exe --version" -ForegroundColor Yellow
$version = & $rustdeskPath --version 2>&1
Write-Host "输出: $version" -ForegroundColor Gray
Write-Host "退出代码: $LASTEXITCODE" -ForegroundColor Gray
Write-Host ""

# 测试 --get-id
Write-Host "[测试 2] 运行: rustdesk.exe --get-id" -ForegroundColor Yellow
$id = & $rustdeskPath --get-id 2>&1
Write-Host "输出: $id" -ForegroundColor Gray
Write-Host "退出代码: $LASTEXITCODE" -ForegroundColor Gray

if ($id -and $id -match '^\d+$') {
    Write-Host ""
    Write-Host "✅ 成功获取 ID: $id" -ForegroundColor Green
} elseif ($id) {
    Write-Host ""
    Write-Host "⚠️ 有输出但不是预期的 ID 格式" -ForegroundColor Yellow
    Write-Host "可能的原因：错误消息或其他输出" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "❌ 没有任何输出" -ForegroundColor Red
    Write-Host ""
    Write-Host "可能的原因：" -ForegroundColor Yellow
    Write-Host "  1. 使用的是旧版本（不包含 --get-id 功能）" -ForegroundColor White
    Write-Host "  2. 代码未正确编译" -ForegroundColor White
    Write-Host "  3. RustDesk 未正确初始化 ID" -ForegroundColor White
    Write-Host ""
    Write-Host "解决方案：" -ForegroundColor Yellow
    Write-Host "  1. 重新编译最新代码" -ForegroundColor White
    Write-Host "  2. 确保使用编译后的 exe 文件" -ForegroundColor White
    Write-Host "  3. 尝试先启动 RustDesk GUI 生成 ID" -ForegroundColor White
}

Write-Host ""
Write-Host "=== 检查编译后的文件 ===" -ForegroundColor Cyan
$targetPath = "e:\GitHub\rustdesk\target\release\rustdesk.exe"
if (Test-Path $targetPath) {
    Write-Host "✅ 找到编译文件: $targetPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "[测试 3] 测试编译后的版本" -ForegroundColor Yellow
    $newId = & $targetPath --get-id 2>&1
    Write-Host "输出: $newId" -ForegroundColor Gray
    if ($newId) {
        Write-Host "✅ 编译版本的 --get-id 有效！" -ForegroundColor Green
        Write-Host ""
        Write-Host "请替换安装目录中的文件：" -ForegroundColor Yellow
        Write-Host "  Copy-Item '$targetPath' -Destination '$rustdeskPath' -Force" -ForegroundColor White
    }
} else {
    Write-Host "❌ 未找到编译文件: $targetPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "请先编译项目：" -ForegroundColor Yellow
    Write-Host "  cd e:\GitHub\rustdesk" -ForegroundColor White
    Write-Host "  cargo build --release --features inline" -ForegroundColor White
}
