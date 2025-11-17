# 修复 RustDesk URL Scheme 注册问题
# 解决 rustdesk:// 无法拉起客户端的问题

Write-Host "=== RustDesk URL Scheme 修复工具 ===" -ForegroundColor Cyan
Write-Host ""

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "✗ 需要管理员权限" -ForegroundColor Red
    Write-Host ""
    Write-Host "请以管理员身份运行此脚本:" -ForegroundColor Yellow
    Write-Host "右键点击 PowerShell -> 以管理员身份运行" -ForegroundColor Yellow
    Write-Host "然后执行: .\Fix-URLScheme.ps1" -ForegroundColor Cyan
    exit 1
}

Write-Host "✓ 已获得管理员权限" -ForegroundColor Green
Write-Host ""

# 查找 RustDesk 安装位置
Write-Host "[1] 查找 RustDesk 安装位置..." -ForegroundColor Yellow

$rustdeskPaths = @(
    "${env:ProgramFiles(x86)}\RustDesk\rustdesk.exe",
    "$env:ProgramFiles\RustDesk\rustdesk.exe",
    "$env:LOCALAPPDATA\RustDesk\rustdesk.exe"
)

$rustdeskExe = $null
foreach ($path in $rustdeskPaths) {
    if (Test-Path $path) {
        $rustdeskExe = $path
        Write-Host "   ✓ 找到: $path" -ForegroundColor Green
        break
    }
}

if (-not $rustdeskExe) {
    Write-Host "   ✗ 未找到 RustDesk 安装" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 检查当前 URL Scheme 注册状态
Write-Host "[2] 检查当前 URL Scheme 注册..." -ForegroundColor Yellow

$regPath = "Registry::HKEY_CLASSES_ROOT\rustdesk"
$regExists = Test-Path $regPath

if ($regExists) {
    Write-Host "   ✓ rustdesk:// 已注册" -ForegroundColor Green
    
    try {
        $commandPath = "Registry::HKEY_CLASSES_ROOT\rustdesk\shell\open\command"
        if (Test-Path $commandPath) {
            $currentCommand = (Get-ItemProperty -Path $commandPath).'(default)'
            Write-Host "   当前命令: $currentCommand" -ForegroundColor Gray
        }
    } catch {
        Write-Host "   ⚠ 无法读取当前命令" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠ rustdesk:// 未注册" -ForegroundColor Yellow
}

Write-Host ""

# 注册或修复 URL Scheme
Write-Host "[3] 注册/修复 URL Scheme..." -ForegroundColor Yellow
Write-Host ""

try {
    # 删除旧的注册（如果存在）
    if ($regExists) {
        Write-Host "   正在清除旧注册..." -ForegroundColor Gray
        Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # 创建新注册
    Write-Host "   正在创建新注册..." -ForegroundColor Gray
    
    # HKEY_CLASSES_ROOT\rustdesk
    New-Item -Path "Registry::HKEY_CLASSES_ROOT\rustdesk" -Force | Out-Null
    Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\rustdesk" -Name "(default)" -Value "URL:RustDesk Protocol"
    New-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\rustdesk" -Name "URL Protocol" -Value "" -PropertyType String -Force | Out-Null
    
    # HKEY_CLASSES_ROOT\rustdesk\DefaultIcon
    New-Item -Path "Registry::HKEY_CLASSES_ROOT\rustdesk\DefaultIcon" -Force | Out-Null
    Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\rustdesk\DefaultIcon" -Name "(default)" -Value "`"$rustdeskExe`",0"
    
    # HKEY_CLASSES_ROOT\rustdesk\shell\open\command
    New-Item -Path "Registry::HKEY_CLASSES_ROOT\rustdesk\shell\open\command" -Force | Out-Null
    
    # 关键：正确的命令格式
    # 格式 1：传递完整 URL（推荐）
    $command = "`"$rustdeskExe`" `"%1`""
    
    Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\rustdesk\shell\open\command" -Name "(default)" -Value $command
    
    Write-Host ""
    Write-Host "   ✓ URL Scheme 注册成功" -ForegroundColor Green
    Write-Host "   注册的命令: $command" -ForegroundColor Gray
    
} catch {
    Write-Host ""
    Write-Host "   ✗ 注册失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 验证注册
Write-Host "[4] 验证注册..." -ForegroundColor Yellow

try {
    $commandPath = "Registry::HKEY_CLASSES_ROOT\rustdesk\shell\open\command"
    $registeredCommand = (Get-ItemProperty -Path $commandPath).'(default)'
    
    if ($registeredCommand -eq $command) {
        Write-Host "   ✓ 注册验证成功" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ 注册的命令不匹配" -ForegroundColor Yellow
        Write-Host "   期望: $command" -ForegroundColor Gray
        Write-Host "   实际: $registeredCommand" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ✗ 验证失败" -ForegroundColor Red
}

Write-Host ""

# 测试 URL Scheme
Write-Host "[5] 测试 URL Scheme..." -ForegroundColor Yellow
Write-Host ""

Write-Host "选择测试方式:" -ForegroundColor Cyan
Write-Host "[1] 使用 Start-Process 测试（模拟浏览器行为）" -ForegroundColor Gray
Write-Host "[2] 创建 HTML 测试文件" -ForegroundColor Gray
Write-Host "[3] 跳过测试" -ForegroundColor Gray
Write-Host ""
Write-Host "请选择 (1/2/3): " -NoNewline -ForegroundColor Yellow
$testChoice = Read-Host

switch ($testChoice) {
    "1" {
        Write-Host ""
        Write-Host "请输入远程 ID（回车使用默认 1074305050）: " -NoNewline -ForegroundColor Yellow
        $testID = Read-Host
        if ([string]::IsNullOrWhiteSpace($testID)) {
            $testID = "1074305050"
        }
        
        $testURL = "rustdesk://connect/$testID"
        Write-Host ""
        Write-Host "测试 URL: $testURL" -ForegroundColor Cyan
        Write-Host "正在启动..." -ForegroundColor Yellow
        
        try {
            Start-Process $testURL
            Write-Host ""
            Write-Host "✓ 测试命令已发送" -ForegroundColor Green
            Write-Host ""
            Write-Host "请检查 RustDesk 是否启动..." -ForegroundColor Yellow
            Write-Host "如果 RustDesk 启动成功，说明 URL Scheme 已修复！" -ForegroundColor Green
        } catch {
            Write-Host ""
            Write-Host "✗ 测试失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "2" {
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>RustDesk URL Scheme 测试</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            max-width: 600px; 
            margin: 50px auto; 
            padding: 20px; 
            text-align: center;
        }
        .test-link { 
            display: inline-block;
            padding: 20px 40px; 
            background-color: #0078d4; 
            color: white; 
            text-decoration: none; 
            border-radius: 10px; 
            font-size: 20px;
            margin: 20px;
        }
        .test-link:hover { 
            background-color: #005a9e; 
        }
    </style>
</head>
<body>
    <h1>🧪 RustDesk URL Scheme 测试</h1>
    <p>点击下方链接测试 URL Scheme 是否工作：</p>
    
    <a href="rustdesk://connect/1074305050" class="test-link">
        🚀 测试连接
    </a>
    
    <p style="color: gray; margin-top: 40px;">
        如果点击后 RustDesk 启动，说明修复成功！
    </p>
</body>
</html>
"@
        
        $htmlFile = "$env:TEMP\rustdesk_url_test_fixed.html"
        $htmlContent | Out-File -FilePath $htmlFile -Encoding UTF8
        
        Write-Host ""
        Write-Host "✓ 测试文件已创建: $htmlFile" -ForegroundColor Green
        Write-Host "正在打开浏览器..." -ForegroundColor Yellow
        Start-Process $htmlFile
    }
    
    "3" {
        Write-Host ""
        Write-Host "跳过测试" -ForegroundColor Gray
    }
    
    default {
        Write-Host ""
        Write-Host "无效选择，跳过测试" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== 修复完成 ===" -ForegroundColor Cyan
Write-Host ""

# 检查 Sciter 版本特殊说明
$fileSize = (Get-Item $rustdeskExe).Length / 1MB
$rustdeskDir = Split-Path $rustdeskExe
$isSciter = (Test-Path "$rustdeskDir\sciter.dll") -or ($fileSize -lt 25)

if ($isSciter) {
    Write-Host "⚠️ 注意：检测到 Sciter 版本" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Sciter 版本对 URL Scheme 的支持可能有限。" -ForegroundColor Yellow
    Write-Host "如果 URL Scheme 仍然不工作，建议使用以下替代方案：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "方案 1: 使用命令行参数" -ForegroundColor Cyan
    Write-Host "`"$rustdeskExe`" --connect 1074305050 --password <密码>" -ForegroundColor Gray
    Write-Host ""
    Write-Host "方案 2: 使用快捷脚本" -ForegroundColor Cyan
    Write-Host ".\Quick-Connect.ps1 -RemoteID 1074305050 -Password <密码>" -ForegroundColor Gray
    Write-Host ""
    Write-Host "方案 3: 升级到 Flutter 版本（推荐）" -ForegroundColor Cyan
    Write-Host "Flutter 版本对 URL Scheme 有完整支持" -ForegroundColor Gray
}

Write-Host ""
Write-Host "故障排查:" -ForegroundColor Yellow
Write-Host "1. 如果浏览器弹出确认对话框，请选择'打开 RustDesk'" -ForegroundColor Gray
Write-Host "2. 如果还是不工作，请关闭所有浏览器窗口后重试" -ForegroundColor Gray
Write-Host "3. 某些浏览器（如 Chrome）可能需要刷新设置" -ForegroundColor Gray
Write-Host "4. 运行 .\Diagnose-RustDesk.ps1 进行完整诊断" -ForegroundColor Gray
