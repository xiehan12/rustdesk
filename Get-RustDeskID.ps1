# Get-RustDeskID.ps1
# 获取当前设备的 RustDesk ID

param(
    [string]$RustDeskPath = "C:\Program Files (x86)\RustDesk\rustdesk.exe"
)

Write-Host "=== RustDesk ID 查询 ===" -ForegroundColor Cyan
Write-Host ""

# 检查文件是否存在
if (-not (Test-Path $RustDeskPath)) {
    Write-Host "错误: 找不到 RustDesk 程序" -ForegroundColor Red
    Write-Host "路径: $RustDeskPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "请指定正确的路径，例如:" -ForegroundColor Yellow
    Write-Host "  .\Get-RustDeskID.ps1 -RustDeskPath 'D:\RustDesk\rustdesk.exe'" -ForegroundColor Gray
    exit 1
}

# 获取 ID
Write-Host "正在获取 ID..." -ForegroundColor Yellow
$ID = & $RustDeskPath --get-id

if ($LASTEXITCODE -eq 0 -and $ID) {
    Write-Host ""
    Write-Host "=============================" -ForegroundColor Green
    Write-Host "  RustDesk ID: $ID" -ForegroundColor Green
    Write-Host "=============================" -ForegroundColor Green
    Write-Host ""
    Write-Host "计算机名: $env:COMPUTERNAME" -ForegroundColor Cyan
    Write-Host "用户名: $env:USERNAME" -ForegroundColor Cyan
    Write-Host "获取时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    
    # 复制到剪贴板
    $ID | Set-Clipboard
    Write-Host ""
    Write-Host "✅ ID 已复制到剪贴板！" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ 获取 ID 失败" -ForegroundColor Red
    Write-Host "请确保 RustDesk 已正确安装" -ForegroundColor Yellow
    exit 1
}
