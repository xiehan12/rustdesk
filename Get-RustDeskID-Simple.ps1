# Get-RustDeskID-Simple.ps1
# 从配置文件直接读取明文 ID（修改后的版本）

param(
    [string]$ConfigPath = "$env:APPDATA\RustDesk\config\RustDesk.toml"
)

Write-Host "=== RustDesk ID 查询（明文版本） ===" -ForegroundColor Cyan
Write-Host ""

# 检查配置文件
if (-not (Test-Path $ConfigPath)) {
    Write-Host "❌ 配置文件不存在: $ConfigPath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 配置文件: $ConfigPath" -ForegroundColor Green
Write-Host ""

# 读取配置文件
$config = Get-Content $ConfigPath -Raw

# 提取明文 ID
# 格式: id = "1953645555" 或 id = '1953645555' 或 id = 1953645555
$id = $null

if ($config -match '^\s*id\s*=\s*[''"]?(\d{9,10})[''"]?' -or 
    $config -match 'id\s*=\s*[''"]?(\d{9,10})[''"]?') {
    $id = $matches[1]
}

if ($id) {
    Write-Host "=============================" -ForegroundColor Green
    Write-Host "  RustDesk ID: $id" -ForegroundColor Green
    Write-Host "=============================" -ForegroundColor Green
    Write-Host ""
    Write-Host "计算机名: $env:COMPUTERNAME" -ForegroundColor Cyan
    Write-Host "用户名: $env:USERNAME" -ForegroundColor Cyan
    Write-Host "时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host ""
    
    # 复制到剪贴板
    $id | Set-Clipboard
    Write-Host "✅ ID 已复制到剪贴板！" -ForegroundColor Green
    Write-Host ""
    
    # 输出纯ID（便于脚本调用）
    return $id
} else {
    Write-Host "⚠️ 未找到明文 ID" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "可能的原因：" -ForegroundColor Yellow
    Write-Host "  1. 使用的是旧版本（未包含明文 ID 修改）" -ForegroundColor White
    Write-Host "  2. 配置文件格式不正确" -ForegroundColor White
    Write-Host "  3. RustDesk 尚未生成 ID" -ForegroundColor White
    Write-Host ""
    Write-Host "解决方案：" -ForegroundColor Cyan
    Write-Host "  1. 重新编译并使用修改后的 RustDesk" -ForegroundColor White
    Write-Host "  2. 启动 RustDesk 一次，让它生成新的配置文件" -ForegroundColor White
    Write-Host ""
    
    # 显示配置文件内容（前 500 字符）
    Write-Host "配置文件内容（部分）：" -ForegroundColor Gray
    Write-Host $config.Substring(0, [Math]::Min(500, $config.Length)) -ForegroundColor DarkGray
    
    exit 1
}
