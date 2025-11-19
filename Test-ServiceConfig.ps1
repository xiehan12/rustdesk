# RustDesk 服务配置测试脚本
# 用于验证服务启动时是否正确生成配置文件

<#
.SYNOPSIS
    测试 RustDesk 服务模式下的配置文件生成

.DESCRIPTION
    此脚本用于测试和诊断 RustDesk 在 --service 模式下的配置文件生成情况
    会检查配置文件路径、权限、内容等

.EXAMPLE
    .\Test-ServiceConfig.ps1
    
.EXAMPLE
    .\Test-ServiceConfig.ps1 -Verbose
#>

param(
    [string]$RustDeskPath = "rustdesk.exe"
)

Write-Host "=== RustDesk 服务配置测试 ===" -ForegroundColor Cyan
Write-Host ""

# 1. 检查 RustDesk 可执行文件
Write-Host "1. 检查 RustDesk 可执行文件..." -ForegroundColor Yellow
if (Test-Path $RustDeskPath) {
    Write-Host "   ✅ 找到: $RustDeskPath" -ForegroundColor Green
    $exeInfo = Get-Item $RustDeskPath
    Write-Host "   📁 大小: $([math]::Round($exeInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray
    Write-Host "   📅 修改时间: $($exeInfo.LastWriteTime)" -ForegroundColor Gray
} else {
    Write-Host "   ❌ 未找到: $RustDeskPath" -ForegroundColor Red
    Write-Host "   请指定正确的 RustDesk 路径，例如:" -ForegroundColor Yellow
    Write-Host "   .\Test-ServiceConfig.ps1 -RustDeskPath 'C:\Program Files\RustDesk\rustdesk.exe'" -ForegroundColor Gray
    exit 1
}
Write-Host ""

# 2. 检查当前用户的配置路径
Write-Host "2. 检查当前用户的配置路径..." -ForegroundColor Yellow
$userConfigPath = "$env:APPDATA\RustDesk\config\RustDesk.toml"
Write-Host "   📁 配置路径: $userConfigPath" -ForegroundColor Gray

if (Test-Path $userConfigPath) {
    Write-Host "   ✅ 配置文件存在" -ForegroundColor Green
    $configInfo = Get-Item $userConfigPath
    Write-Host "   📁 大小: $($configInfo.Length) 字节" -ForegroundColor Gray
    Write-Host "   📅 修改时间: $($configInfo.LastWriteTime)" -ForegroundColor Gray
    
    # 读取并显示配置内容
    $configContent = Get-Content $userConfigPath -Raw
    if ($configContent -match 'id\s*=\s*[''"]?(\d{9,10})[''"]?') {
        Write-Host "   🆔 当前 ID: $($matches[1])" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  未找到明文 ID" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠️  配置文件不存在（正常，首次运行会创建）" -ForegroundColor Yellow
}
Write-Host ""

# 3. 检查 SYSTEM 账户的配置路径
Write-Host "3. 检查 SYSTEM 账户的配置路径..." -ForegroundColor Yellow
$systemConfigPaths = @(
    "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml",
    "C:\Windows\ServiceProfiles\NetworkService\AppData\Roaming\RustDesk\config\RustDesk.toml",
    "C:\Windows\System32\config\systemprofile\AppData\Roaming\RustDesk\config\RustDesk.toml"
)

foreach ($path in $systemConfigPaths) {
    Write-Host "   检查: $path" -ForegroundColor Gray
    if (Test-Path $path) {
        Write-Host "   ✅ 找到配置文件" -ForegroundColor Green
        $configInfo = Get-Item $path
        Write-Host "      📁 大小: $($configInfo.Length) 字节" -ForegroundColor Gray
        Write-Host "      📅 修改时间: $($configInfo.LastWriteTime)" -ForegroundColor Gray
        
        # 读取并显示配置内容
        try {
            $configContent = Get-Content $path -Raw -ErrorAction Stop
            if ($configContent -match 'id\s*=\s*[''"]?(\d{9,10})[''"]?') {
                Write-Host "      🆔 SYSTEM ID: $($matches[1])" -ForegroundColor Green
            }
        } catch {
            Write-Host "      ⚠️  无权限读取文件内容" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ⚠️  不存在" -ForegroundColor Gray
    }
}
Write-Host ""

# 4. 测试服务启动（模拟，不实际启动服务）
Write-Host "4. 测试配置生成（使用 --get-id）..." -ForegroundColor Yellow
try {
    $output = & $RustDeskPath --get-id 2>&1 | Out-String
    if ($output -match '(\d{9,10})') {
        $testId = $matches[1]
        Write-Host "   ✅ 成功获取 ID: $testId" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  无法从输出中提取 ID" -ForegroundColor Yellow
        Write-Host "   输出内容: $output" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ❌ 执行失败: $_" -ForegroundColor Red
}
Write-Host ""

# 5. 检查服务状态
Write-Host "5. 检查 RustDesk 服务状态..." -ForegroundColor Yellow
$service = Get-Service -Name "RustDesk" -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "   ✅ 服务已安装" -ForegroundColor Green
    Write-Host "   📊 状态: $($service.Status)" -ForegroundColor Gray
    Write-Host "   🔧 启动类型: $($service.StartType)" -ForegroundColor Gray
    
    # 获取服务账户
    $serviceAccount = (Get-WmiObject Win32_Service -Filter "Name='RustDesk'").StartName
    Write-Host "   👤 运行账户: $serviceAccount" -ForegroundColor Gray
    
    if ($serviceAccount -eq "LocalSystem") {
        Write-Host "   ℹ️  服务以 LocalSystem 运行，配置文件在:" -ForegroundColor Cyan
        Write-Host "      C:\Windows\System32\config\systemprofile\AppData\Roaming\RustDesk\config\" -ForegroundColor Gray
    }
} else {
    Write-Host "   ⚠️  服务未安装" -ForegroundColor Yellow
    Write-Host "   安装命令: & '$RustDeskPath' --install-service" -ForegroundColor Gray
}
Write-Host ""

# 6. 建议的测试步骤
Write-Host "=== 建议的测试步骤 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "如果服务未生成配置，请尝试以下步骤：" -ForegroundColor Yellow
Write-Host ""
Write-Host "步骤 1: 停止服务" -ForegroundColor White
Write-Host "   Stop-Service RustDesk" -ForegroundColor Gray
Write-Host ""
Write-Host "步骤 2: 清理现有配置（可选）" -ForegroundColor White
Write-Host "   Remove-Item '$userConfigPath' -Force" -ForegroundColor Gray
Write-Host ""
Write-Host "步骤 3: 使用新版本重新安装" -ForegroundColor White
Write-Host "   & '$RustDeskPath' --silent-install" -ForegroundColor Gray
Write-Host ""
Write-Host "步骤 4: 启动服务" -ForegroundColor White
Write-Host "   Start-Service RustDesk" -ForegroundColor Gray
Write-Host ""
Write-Host "步骤 5: 检查日志" -ForegroundColor White
Write-Host "   Get-EventLog -LogName Application -Source RustDesk -Newest 20" -ForegroundColor Gray
Write-Host ""
Write-Host "步骤 6: 验证配置文件" -ForegroundColor White
Write-Host "   # SYSTEM 账户配置路径" -ForegroundColor Gray
Write-Host "   Test-Path 'C:\Windows\System32\config\systemprofile\AppData\Roaming\RustDesk\config\RustDesk.toml'" -ForegroundColor Gray
Write-Host ""

# 7. 创建测试报告
Write-Host "=== 生成诊断报告 ===" -ForegroundColor Cyan
$report = @{
    TestTime = Get-Date
    RustDeskPath = $RustDeskPath
    RustDeskExists = Test-Path $RustDeskPath
    UserConfigPath = $userConfigPath
    UserConfigExists = Test-Path $userConfigPath
    ServiceInstalled = $null -ne $service
    ServiceStatus = if ($service) { $service.Status } else { "Not Installed" }
    ServiceAccount = if ($service) { $serviceAccount } else { "N/A" }
}

$reportPath = ".\RustDesk-Service-Config-Report.json"
$report | ConvertTo-Json | Out-File $reportPath
Write-Host "   ✅ 诊断报告已保存到: $reportPath" -ForegroundColor Green
Write-Host ""

Write-Host "=== 测试完成 ===" -ForegroundColor Cyan
Write-Host ""

# 返回诊断结果
return $report
