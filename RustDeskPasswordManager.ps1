# RustDesk 密码动态管理守护进程 (PowerShell 版本)
# 每 N 分钟自动修改密码并上报到 API 服务器

#Requires -RunAsAdministrator

<#
.SYNOPSIS
    RustDesk 密码动态管理守护进程
    
.DESCRIPTION
    定期生成随机密码，更新 RustDesk 并上报到 API 服务器
    
.PARAMETER ConfigFile
    配置文件路径，默认为当前目录下的 password_manager_config.json
    
.EXAMPLE
    .\RustDeskPasswordManager.ps1
    
.EXAMPLE
    .\RustDeskPasswordManager.ps1 -ConfigFile "C:\config\myconfig.json"
#>

param(
    [string]$ConfigFile = "password_manager_config.json"
)

# 日志函数
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Level - $Message"
    
    # 控制台输出
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage -ForegroundColor White }
    }
    
    # 写入日志文件
    Add-Content -Path "password_manager.log" -Value $logMessage
}

# 加载配置
function Load-Config {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        # 创建默认配置
        $defaultConfig = @{
            api_url = "https://your-api-server.com/api/password/update"
            api_key = "your-secret-api-key"
            device_id = ""
            interval_seconds = 120
            password_length = 12
            retry_times = 3
            retry_delay = 5
            rustdesk_exe = "rustdesk.exe"
        }
        
        $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
        Write-Log "配置文件不存在，已创建默认配置: $Path" -Level "WARNING"
        Write-Log "请修改配置文件后重新运行！" -Level "WARNING"
        exit 1
    }
    
    try {
        $config = Get-Content -Path $Path -Raw | ConvertFrom-Json
        Write-Log "配置文件加载成功: $Path"
        return $config
    } catch {
        Write-Log "配置文件加载失败: $_" -Level "ERROR"
        exit 1
    }
}

# 获取 RustDesk ID
function Get-RustDeskID {
    param([string]$RustDeskExe)
    
    try {
        $id = & $RustDeskExe --get-id 2>&1
        if ($LASTEXITCODE -eq 0 -and $id) {
            Write-Log "获取到 RustDesk ID: $id"
            return $id.Trim()
        }
    } catch {
        Write-Log "获取 RustDesk ID 失败: $_" -Level "ERROR"
    }
    
    return "unknown"
}

# 生成安全的随机密码
function Generate-SecurePassword {
    param([int]$Length = 12)
    
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
    $password = -join ((1..$Length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    
    Write-Log "生成新密码 (长度: $Length)"
    return $password
}

# 更新 RustDesk 密码
function Update-RustDeskPassword {
    param(
        [string]$RustDeskExe,
        [string]$Password
    )
    
    try {
        $output = & $RustDeskExe --password $Password 2>&1
        
        if ($LASTEXITCODE -eq 0 -and $output -eq "Done!") {
            Write-Log "✓ RustDesk 密码更新成功" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "✗ RustDesk 密码更新失败: $output" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "✗ RustDesk 密码更新异常: $_" -Level "ERROR"
        return $false
    }
}

# 上报密码到 API 服务器
function Report-ToAPI {
    param(
        [string]$ApiUrl,
        [string]$ApiKey,
        [string]$DeviceId,
        [string]$Password,
        [int]$RetryTimes = 3,
        [int]$RetryDelay = 5
    )
    
    $payload = @{
        device_id = $DeviceId
        password = $Password
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        version = "1.0"
    } | ConvertTo-Json
    
    $headers = @{
        "Authorization" = "Bearer $ApiKey"
        "Content-Type" = "application/json"
    }
    
    for ($i = 1; $i -le $RetryTimes; $i++) {
        try {
            Write-Log "正在上报密码到 API 服务器 (尝试 $i/$RetryTimes)..."
            
            $response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Body $payload -Headers $headers -TimeoutSec 10
            
            Write-Log "✓ 密码上报成功: $($response | ConvertTo-Json -Compress)" -Level "SUCCESS"
            return $true
            
        } catch {
            Write-Log "✗ API 请求失败: $_" -Level "WARNING"
            
            if ($i -lt $RetryTimes) {
                Write-Log "等待 $RetryDelay 秒后重试..."
                Start-Sleep -Seconds $RetryDelay
            }
        }
    }
    
    Write-Log "✗ 密码上报失败，已重试 $RetryTimes 次" -Level "ERROR"
    return $false
}

# 执行一次完整的密码更新周期
function Invoke-PasswordUpdateCycle {
    param(
        [object]$Config
    )
    
    Write-Log ("=" * 60)
    Write-Log "开始密码更新周期 - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Log ("=" * 60)
    
    # 1. 生成新密码
    $newPassword = Generate-SecurePassword -Length $Config.password_length
    
    # 2. 更新 RustDesk 密码
    if (-not (Update-RustDeskPassword -RustDeskExe $Config.rustdesk_exe -Password $newPassword)) {
        Write-Log "密码更新失败，跳过 API 上报" -Level "ERROR"
        return $false
    }
    
    # 3. 上报到 API 服务器
    if (-not (Report-ToAPI -ApiUrl $Config.api_url -ApiKey $Config.api_key -DeviceId $Config.device_id -Password $newPassword -RetryTimes $Config.retry_times -RetryDelay $Config.retry_delay)) {
        Write-Log "API 上报失败，但 RustDesk 密码已更新" -Level "WARNING"
        return $false
    }
    
    Write-Log "✓ 密码更新周期完成" -Level "SUCCESS"
    return $true
}

# 主函数
function Start-PasswordManager {
    # 检查管理员权限
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Log "错误：需要管理员权限才能运行此脚本！" -Level "ERROR"
        Write-Log "请以管理员身份运行 PowerShell" -Level "ERROR"
        exit 1
    }
    
    # 加载配置
    $config = Load-Config -Path $ConfigFile
    
    # 获取 Device ID（如果配置中没有）
    if (-not $config.device_id) {
        $config.device_id = Get-RustDeskID -RustDeskExe $config.rustdesk_exe
    }
    
    # 显示启动信息
    Write-Log ("=" * 60)
    Write-Log "RustDesk 密码管理守护进程启动"
    Write-Log ("=" * 60)
    Write-Log "Device ID: $($config.device_id)"
    Write-Log "更新间隔: $($config.interval_seconds) 秒"
    Write-Log "API 服务器: $($config.api_url)"
    Write-Log "密码长度: $($config.password_length)"
    Write-Log ("=" * 60)
    
    # 立即执行一次
    Invoke-PasswordUpdateCycle -Config $config
    
    # 循环执行
    try {
        while ($true) {
            $nextUpdate = (Get-Date).AddSeconds($config.interval_seconds)
            Write-Log "下次更新时间: $($nextUpdate.ToString('HH:mm:ss'))"
            
            Start-Sleep -Seconds $config.interval_seconds
            
            Invoke-PasswordUpdateCycle -Config $config
        }
    } catch {
        if ($_.Exception.Message -match "KeyboardInterrupt|Ctrl\+C") {
            Write-Log "`n收到中断信号，正在退出..." -Level "WARNING"
        } else {
            Write-Log "未知错误: $_" -Level "ERROR"
        }
    }
}

# 启动
try {
    Start-PasswordManager
} catch {
    Write-Log "程序启动失败: $_" -Level "ERROR"
    exit 1
}
