# RustDesk 密码命令诊断工具 (PowerShell 版本)
# 用于排查 --password 命令不生效的原因

#Requires -RunAsAdministrator

Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("=" * 69) -ForegroundColor Cyan
Write-Host "RustDesk 密码命令诊断工具" -ForegroundColor Yellow
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("=" * 69) -ForegroundColor Cyan
Write-Host ""

$issues = @()

# 1. 检查管理员权限
Write-Host "[1/5] 检查管理员权限..." -ForegroundColor Cyan
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "    ✓ 当前拥有管理员权限" -ForegroundColor Green
} else {
    Write-Host "    ✗ 当前没有管理员权限" -ForegroundColor Red
    Write-Host "    ⚠️  请以管理员身份运行 PowerShell！" -ForegroundColor Yellow
    $issues += "缺少管理员权限"
}

# 2. 检查 RustDesk 是否安装
Write-Host "`n[2/5] 检查 RustDesk 安装状态..." -ForegroundColor Cyan
$installPaths = @(
    "$env:ProgramFiles\RustDesk\rustdesk.exe",
    "${env:ProgramFiles(x86)}\RustDesk\rustdesk.exe",
    "$env:LOCALAPPDATA\RustDesk\rustdesk.exe"
)

$rustdeskExe = $null
foreach ($path in $installPaths) {
    if (Test-Path $path) {
        Write-Host "    ✓ RustDesk 已安装" -ForegroundColor Green
        Write-Host "    路径: $path" -ForegroundColor Gray
        $rustdeskExe = $path
        break
    }
}

if (-not $rustdeskExe) {
    Write-Host "    ✗ RustDesk 未安装（或使用便携版）" -ForegroundColor Red
    Write-Host "    ⚠️  --password 命令只能在安装版中使用！" -ForegroundColor Yellow
    
    # 检查当前目录
    if (Test-Path ".\rustdesk.exe") {
        Write-Host "    发现便携版: $(Resolve-Path '.\rustdesk.exe')" -ForegroundColor Yellow
        $rustdeskExe = ".\rustdesk.exe"
    } else {
        Write-Host "    当前目录也没有 rustdesk.exe" -ForegroundColor Red
        $rustdeskExe = "rustdesk.exe"
    }
    $issues += "RustDesk 未安装（使用便携版）"
}

# 3. 检查服务状态
Write-Host "`n[3/5] 检查 RustDesk 服务状态..." -ForegroundColor Cyan
try {
    $service = Get-Service -Name "rustdesk" -ErrorAction SilentlyContinue
    if ($service) {
        if ($service.Status -eq 'Running') {
            Write-Host "    ✓ RustDesk 服务正在运行" -ForegroundColor Green
        } else {
            Write-Host "    ✗ RustDesk 服务状态: $($service.Status)" -ForegroundColor Red
            Write-Host "    提示: 可以运行 'Start-Service rustdesk' 启动服务" -ForegroundColor Yellow
            $issues += "RustDesk 服务未运行"
        }
    } else {
        Write-Host "    ✗ RustDesk 服务未安装" -ForegroundColor Red
        $issues += "RustDesk 服务未安装"
    }
} catch {
    Write-Host "    ✗ 检查服务失败: $_" -ForegroundColor Red
}

# 4. 检查配置文件
Write-Host "`n[4/5] 检查配置文件..." -ForegroundColor Cyan
$configPath = "$env:APPDATA\RustDesk\config\RustDesk2.toml"
if (Test-Path $configPath) {
    Write-Host "    ✓ 配置文件存在" -ForegroundColor Green
    Write-Host "    路径: $configPath" -ForegroundColor Gray
} else {
    Write-Host "    ✗ 配置文件不存在" -ForegroundColor Red
    Write-Host "    预期路径: $configPath" -ForegroundColor Gray
}

# 5. 测试密码命令
Write-Host "`n[5/5] 测试密码命令..." -ForegroundColor Cyan
$testPassword = "TestPassword123"
Write-Host "执行命令: $rustdeskExe --password $testPassword" -ForegroundColor Gray
Write-Host ("-" * 70) -ForegroundColor Gray

try {
    $output = & $rustdeskExe --password $testPassword 2>&1
    $exitCode = $LASTEXITCODE
    
    Write-Host "返回码: $exitCode" -ForegroundColor Gray
    Write-Host "输出: '$output'" -ForegroundColor Gray
    
} catch {
    Write-Host "执行异常: $_" -ForegroundColor Red
    $output = $_.Exception.Message
    $exitCode = -1
}

# 总结
Write-Host "`n" -NoNewline
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "诊断结果" -ForegroundColor Yellow
Write-Host ("=" * 70) -ForegroundColor Cyan

if ($output -eq "Done!") {
    Write-Host "`n✓ 密码命令执行成功！" -ForegroundColor Green
    Write-Host "  如果觉得没生效，可能是因为：" -ForegroundColor Yellow
    Write-Host "  1. 客户端缓存了旧密码" -ForegroundColor Gray
    Write-Host "  2. 需要重启 RustDesk 服务" -ForegroundColor Gray
    Write-Host "  3. 检查配置文件中的密码是否更新" -ForegroundColor Gray
    
    Write-Host "`n建议操作:" -ForegroundColor Yellow
    Write-Host "  # 重启 RustDesk 服务" -ForegroundColor Gray
    Write-Host "  Restart-Service rustdesk" -ForegroundColor Cyan
    
} elseif ($output -match "Installation and administrative privileges required") {
    Write-Host "`n✗ 密码命令被拒绝：需要安装版和管理员权限" -ForegroundColor Red
    $issues += "命令被拒绝"
    
} elseif ($issues.Count -gt 0) {
    Write-Host "`n✗ 发现以下问题：" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "  ❌ $issue" -ForegroundColor Red
    }
} else {
    Write-Host "`n⚠️  命令执行但结果异常" -ForegroundColor Yellow
    Write-Host "  输出: $output" -ForegroundColor Gray
}

# 解决方案
if ($issues.Count -gt 0 -or $output -ne "Done!") {
    Write-Host "`n" -NoNewline
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "解决方案" -ForegroundColor Yellow
    Write-Host ("=" * 70) -ForegroundColor Cyan
    
    if (-not $isAdmin) {
        Write-Host "`n1. 以管理员身份运行 PowerShell:" -ForegroundColor Yellow
        Write-Host "   - 右键点击 PowerShell 图标" -ForegroundColor Gray
        Write-Host "   - 选择 '以管理员身份运行'" -ForegroundColor Gray
        Write-Host "   - 或在命令行运行: Start-Process powershell -Verb RunAs" -ForegroundColor Cyan
    }
    
    if ($rustdeskExe -eq "rustdesk.exe" -or $rustdeskExe -eq ".\rustdesk.exe") {
        Write-Host "`n2. 安装 RustDesk:" -ForegroundColor Yellow
        Write-Host "   - 下载安装版（非便携版）" -ForegroundColor Gray
        Write-Host "   - 运行安装程序" -ForegroundColor Gray
        Write-Host "   - 安装完成后服务会自动启动" -ForegroundColor Gray
    }
    
    if ($issues -match "服务") {
        Write-Host "`n3. 启动 RustDesk 服务:" -ForegroundColor Yellow
        Write-Host "   Start-Service rustdesk" -ForegroundColor Cyan
        Write-Host "   # 或" -ForegroundColor Gray
        Write-Host "   sc start rustdesk" -ForegroundColor Cyan
    }
    
    Write-Host "`n4. 完整测试命令:" -ForegroundColor Yellow
    Write-Host "   以管理员身份在 PowerShell 中运行:" -ForegroundColor Gray
    Write-Host "   & `"$rustdeskExe`" --password `"TestPassword123`"" -ForegroundColor Cyan
}

Write-Host "`n" -NoNewline
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ""
