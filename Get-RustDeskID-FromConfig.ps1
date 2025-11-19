# Get-RustDeskID-FromConfig.ps1
# 从配置文件读取 RustDesk ID（不依赖 --get-id 命令）

param(
    [string]$ConfigPath = "$env:APPDATA\RustDesk\config\RustDesk.toml"
)

Write-Host "=== 从配置文件读取 RustDesk ID ===" -ForegroundColor Cyan
Write-Host ""

# 检查配置文件
if (-not (Test-Path $ConfigPath)) {
    Write-Host "❌ 配置文件不存在" -ForegroundColor Red
    Write-Host "路径: $ConfigPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "解决方案：" -ForegroundColor Yellow
    Write-Host "  1. 启动 RustDesk GUI 程序（至少一次）" -ForegroundColor White
    Write-Host "  2. 等待程序生成 ID 和配置文件" -ForegroundColor White
    Write-Host "  3. 然后再运行此脚本" -ForegroundColor White
    exit 1
}

Write-Host "✅ 找到配置文件" -ForegroundColor Green
Write-Host "路径: $ConfigPath" -ForegroundColor Gray
Write-Host ""

# 读取配置文件
try {
    $config = Get-Content $ConfigPath -Raw -ErrorAction Stop
    
    # 提取 ID（支持多种格式）
    $id = $null
    
    # 格式 1: id = "123456789"
    if ($config -match 'id\s*=\s*"([^"]+)"') {
        $id = $matches[1]
    }
    # 格式 2: id = '123456789'
    elseif ($config -match "id\s*=\s*'([^']+)'") {
        $id = $matches[1]
    }
    # 格式 3: id = 123456789
    elseif ($config -match 'id\s*=\s*([^\s]+)') {
        $id = $matches[1]
    }
    
    if ($id) {
        Write-Host "=============================" -ForegroundColor Green
        Write-Host "  RustDesk ID: $id" -ForegroundColor Green
        Write-Host "=============================" -ForegroundColor Green
        Write-Host ""
        Write-Host "设备信息：" -ForegroundColor Cyan
        Write-Host "  计算机名: $env:COMPUTERNAME" -ForegroundColor White
        Write-Host "  用户名: $env:USERNAME" -ForegroundColor White
        Write-Host "  时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
        Write-Host ""
        
        # 复制到剪贴板
        $id | Set-Clipboard
        Write-Host "✅ ID 已复制到剪贴板！" -ForegroundColor Green
        Write-Host ""
        
        # 提供连接命令
        Write-Host "快速连接命令：" -ForegroundColor Yellow
        Write-Host "  rustdesk.exe --connect $id --password <密码>" -ForegroundColor White
        
        # 返回 ID（便于脚本调用）
        return $id
    } else {
        Write-Host "❌ 无法从配置文件中提取 ID" -ForegroundColor Red
        Write-Host ""
        Write-Host "配置文件内容（前 500 字符）：" -ForegroundColor Yellow
        Write-Host $config.Substring(0, [Math]::Min(500, $config.Length)) -ForegroundColor Gray
        Write-Host ""
        Write-Host "可能的原因：" -ForegroundColor Yellow
        Write-Host "  1. RustDesk 尚未生成 ID" -ForegroundColor White
        Write-Host "  2. 配置文件格式已更改" -ForegroundColor White
        Write-Host "  3. 配置文件损坏" -ForegroundColor White
        exit 1
    }
} catch {
    Write-Host "❌ 读取配置文件时出错" -ForegroundColor Red
    Write-Host "错误信息: $($_.Exception.Message)" -ForegroundColor Yellow
    exit 1
}
