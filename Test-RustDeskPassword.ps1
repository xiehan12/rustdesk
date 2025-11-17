# 测试 RustDesk 密码更新功能
# 简单快速的测试脚本

#Requires -RunAsAdministrator

param(
    [string]$RustDeskExe = "rustdesk.exe",
    [string]$TestPassword = "TestPassword123!@#"
)

Write-Host "`n" -NoNewline
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "RustDesk 密码更新测试" -ForegroundColor Yellow
Write-Host ("=" * 60) -ForegroundColor Cyan

Write-Host "`n可执行文件: $RustDeskExe" -ForegroundColor Gray
Write-Host "测试密码: $TestPassword" -ForegroundColor Gray
Write-Host "`n执行命令..." -ForegroundColor Cyan

try {
    # 执行命令
    $output = & $RustDeskExe --password $TestPassword 2>&1
    $exitCode = $LASTEXITCODE
    
    Write-Host "`n结果:" -ForegroundColor Cyan
    Write-Host "  返回码: $exitCode" -ForegroundColor Gray
    Write-Host "  输出: '$output'" -ForegroundColor Gray
    
    # 判断结果
    if ($exitCode -eq 0 -and $output -eq "Done!") {
        Write-Host "`n✓ 测试成功！密码已更新" -ForegroundColor Green
        
        Write-Host "`n建议操作:" -ForegroundColor Yellow
        Write-Host "  1. 重启 RustDesk 服务以确保生效:" -ForegroundColor Gray
        Write-Host "     Restart-Service rustdesk" -ForegroundColor Cyan
        Write-Host "`n  2. 查看配置文件中的密码:" -ForegroundColor Gray
        Write-Host "     notepad `$env:APPDATA\RustDesk\config\RustDesk2.toml" -ForegroundColor Cyan
        
        exit 0
    } else {
        Write-Host "`n✗ 测试失败" -ForegroundColor Red
        
        if ($output -match "Installation and administrative privileges required") {
            Write-Host "`n原因: 需要安装版和管理员权限" -ForegroundColor Yellow
            Write-Host "  - 确保使用的是安装版（非便携版）" -ForegroundColor Gray
            Write-Host "  - 确保以管理员身份运行 PowerShell" -ForegroundColor Gray
        }
        
        Write-Host "`n运行诊断工具获取更多信息:" -ForegroundColor Yellow
        Write-Host "  .\Diagnose-RustDeskPassword.ps1" -ForegroundColor Cyan
        
        exit 1
    }
} catch {
    Write-Host "`n✗ 执行异常: $_" -ForegroundColor Red
    exit 1
}
