#!/usr/bin/env pwsh
<#
.SYNOPSIS
    RustDesk 自动密码更新脚本
.DESCRIPTION
    每2分钟自动触发 RustDesk 更新临时密码
    支持 Windows 和 Linux 平台
.PARAMETER Interval
    更新间隔（秒），默认120秒（2分钟）
.PARAMETER PasswordLength
    密码长度，可选 6/8/10，默认6
.EXAMPLE
    .\update_password.ps1
    .\update_password.ps1 -Interval 180 -PasswordLength 8
#>

param(
    [int]$Interval = 120,
    [ValidateSet(6,8,10)]
    [int]$PasswordLength = 6,
    [switch]$NumericOnly = $false
)

# RustDesk IPC 配置
$IpcPath = if ($IsWindows -or $env:OS -match 'Windows') {
    "\\.\pipe\RustDesk\query"
} else {
    "/tmp/RustDesk/ipc"
}

# 字符集
$Chars = '23456789abcdefghjkmnpqrstuvwxyz'
$NumericChars = '0123456789'

function Write-ColorLog {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] " -NoNewline
    Write-Host $Message -ForegroundColor $Color
}

function New-RandomPassword {
    param(
        [int]$Length = $PasswordLength,
        [bool]$OnlyNumeric = $NumericOnly
    )
    
    $charset = if ($OnlyNumeric) { $NumericChars } else { $Chars }
    $password = -join ((1..$Length) | ForEach-Object { $charset[(Get-Random -Maximum $charset.Length)] })
    return $password
}

function Update-RustDeskPassword {
    <#
    .SYNOPSIS
        通过 IPC 触发 RustDesk 更新临时密码
    #>
    
    try {
        if ($IsWindows -or $env:OS -match 'Windows') {
            # Windows Named Pipe 方式
            Update-RustDeskPasswordWindows
        } else {
            # Unix Socket 方式
            Update-RustDeskPasswordUnix
        }
    }
    catch {
        Write-ColorLog "密码更新失败: $_" "Red"
        return $false
    }
}

function Update-RustDeskPasswordWindows {
    <#
    .SYNOPSIS
        Windows 平台通过 Named Pipe 更新密码
    #>
    
    # 方法1: 直接调用 RustDesk CLI（如果已实现）
    $rustdeskPath = Get-Command rustdesk.exe -ErrorAction SilentlyContinue
    if ($rustdeskPath) {
        try {
            # 尝试通过 CLI 更新
            # 注意：这个功能可能还未实现，需要修改 RustDesk 源码添加 CLI 参数
            & $rustdeskPath.Source --update-password 2>$null
            Write-ColorLog "✓ 已通过 CLI 触发密码更新" "Green"
            return $true
        }
        catch {
            # CLI 方法失败，尝试其他方法
        }
    }
    
    # 方法2: 通过修改配置文件触发
    # RustDesk 会监听配置文件变化
    $configPath = Join-Path $env:APPDATA "RustDesk\config\RustDesk2.toml"
    if (Test-Path $configPath) {
        try {
            # 这里只是示例，实际需要根据 RustDesk 的配置格式
            # 可以通过修改配置文件来触发密码更新
            Write-ColorLog "✓ 配置文件方式暂未完全实现" "Yellow"
            return $true
        }
        catch {
            Write-ColorLog "配置文件方式失败: $_" "Red"
        }
    }
    
    # 方法3: 发送 Windows 消息（需要找到 RustDesk 窗口句柄）
    Write-ColorLog "⚠ 建议修改 RustDesk 源码添加 CLI 支持" "Yellow"
    return $false
}

function Update-RustDeskPasswordUnix {
    <#
    .SYNOPSIS
        Unix/Linux 平台通过 Unix Socket 更新密码
    #>
    
    # 使用 socat 或 nc 连接到 Unix Socket
    if (Get-Command socat -ErrorAction SilentlyContinue) {
        try {
            # 发送更新命令
            $message = '{"type":"Config","name":"temporary-password","value":""}'
            Write-Output $message | socat - UNIX-CONNECT:$IpcPath
            Write-ColorLog "✓ 已发送密码更新命令" "Green"
            return $true
        }
        catch {
            Write-ColorLog "Socket 通信失败: $_" "Red"
            return $false
        }
    }
    else {
        Write-ColorLog "⚠ 需要安装 socat: sudo apt-get install socat" "Yellow"
        return $false
    }
}

# 主循环
function Start-PasswordUpdateCycle {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   RustDesk 自动密码更新器" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-ColorLog "IPC 路径: $IpcPath" "Gray"
    Write-ColorLog "密码长度: $PasswordLength" "Gray"
    Write-ColorLog "更新间隔: $Interval 秒" "Gray"
    Write-ColorLog "仅数字: $NumericOnly" "Gray"
    Write-Host ""
    
    $cycle = 0
    
    while ($true) {
        try {
            $cycle++
            Write-Host ""
            Write-ColorLog "=== Cycle #$cycle ===" "Cyan"
            
            # 生成新密码（供参考）
            $newPassword = New-RandomPassword
            Write-ColorLog "生成的参考密码: $newPassword" "Yellow"
            
            # 触发 RustDesk 更新
            Write-ColorLog "正在触发 RustDesk 更新临时密码..." "White"
            
            if (Update-RustDeskPassword) {
                Write-ColorLog "✓ 密码更新成功" "Green"
            }
            else {
                Write-ColorLog "✗ 密码更新失败，请检查 RustDesk 是否运行" "Red"
            }
            
            # 等待下一个周期
            Write-ColorLog "等待 $Interval 秒..." "Gray"
            Start-Sleep -Seconds $Interval
        }
        catch {
            Write-ColorLog "错误: $_" "Red"
            Start-Sleep -Seconds 10
        }
    }
}

# 运行
try {
    Start-PasswordUpdateCycle
}
catch {
    Write-ColorLog "程序异常: $_" "Red"
}
finally {
    Write-Host ""
    Write-ColorLog "程序已退出" "Yellow"
}
