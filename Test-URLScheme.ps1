# RustDesk URL Scheme 测试和诊断工具
# 用于测试和诊断 rustdesk:// URL Scheme 是否正常工作

param(
    [Parameter(Mandatory=$false)]
    [string]$RemoteID = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Password = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$DiagnoseOnly
)

Write-Host "=== RustDesk URL Scheme 测试工具 ===" -ForegroundColor Cyan
Write-Host ""

# 1. 检查 RustDesk 是否已安装
Write-Host "[1] 检查 RustDesk 安装状态..." -ForegroundColor Yellow

$rustdeskPaths = @(
    "$env:ProgramFiles\RustDesk\rustdesk.exe",
    "${env:ProgramFiles(x86)}\RustDesk\rustdesk.exe",
    "$env:LOCALAPPDATA\RustDesk\rustdesk.exe"
)

$rustdeskExe = $null
foreach ($path in $rustdeskPaths) {
    if (Test-Path $path) {
        $rustdeskExe = $path
        Write-Host "   ✓ 找到 RustDesk: $path" -ForegroundColor Green
        break
    }
}

if (-not $rustdeskExe) {
    Write-Host "   ✗ 未找到 RustDesk 安装" -ForegroundColor Red
    Write-Host "   请先安装 RustDesk: https://rustdesk.com/download" -ForegroundColor Yellow
    exit 1
}

# 获取版本信息
try {
    $versionInfo = (Get-Item $rustdeskExe).VersionInfo
    Write-Host "   版本: $($versionInfo.FileVersion)" -ForegroundColor Gray
} catch {
    Write-Host "   无法获取版本信息" -ForegroundColor Gray
}

Write-Host ""

# 2. 检查 URL Scheme 注册
Write-Host "[2] 检查 URL Scheme 注册..." -ForegroundColor Yellow

$regPath = "Registry::HKEY_CLASSES_ROOT\rustdesk"
$regExists = Test-Path $regPath

if ($regExists) {
    Write-Host "   ✓ rustdesk:// 已注册" -ForegroundColor Green
    
    try {
        $urlProtocol = Get-ItemProperty -Path $regPath -Name "URL Protocol" -ErrorAction SilentlyContinue
        if ($urlProtocol) {
            Write-Host "   ✓ URL Protocol 标记存在" -ForegroundColor Green
        }
        
        $commandPath = "Registry::HKEY_CLASSES_ROOT\rustdesk\shell\open\command"
        if (Test-Path $commandPath) {
            $command = (Get-ItemProperty -Path $commandPath).'(default)'
            Write-Host "   注册的命令: $command" -ForegroundColor Gray
        }
    } catch {
        Write-Host "   ⚠ 无法读取注册表详细信息" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ✗ rustdesk:// 未注册" -ForegroundColor Red
    Write-Host ""
    Write-Host "   需要注册 URL Scheme。是否现在注册？(Y/N): " -NoNewline -ForegroundColor Yellow
    $response = Read-Host
    
    if ($response -eq 'Y' -or $response -eq 'y') {
        Write-Host "   正在注册 URL Scheme..." -ForegroundColor Yellow
        
        try {
            # 需要管理员权限
            if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                Write-Host "   ✗ 需要管理员权限才能注册 URL Scheme" -ForegroundColor Red
                Write-Host "   请以管理员身份运行此脚本" -ForegroundColor Yellow
                exit 1
            }
            
            # 注册 URL Scheme
            New-Item -Path "Registry::HKEY_CLASSES_ROOT\rustdesk" -Force | Out-Null
            Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\rustdesk" -Name "(default)" -Value "URL:RustDesk Protocol"
            New-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\rustdesk" -Name "URL Protocol" -Value "" -PropertyType String -Force | Out-Null
            
            New-Item -Path "Registry::HKEY_CLASSES_ROOT\rustdesk\shell\open\command" -Force | Out-Null
            Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\rustdesk\shell\open\command" -Name "(default)" -Value "`"$rustdeskExe`" `"%1`""
            
            Write-Host "   ✓ URL Scheme 注册成功" -ForegroundColor Green
        } catch {
            Write-Host "   ✗ 注册失败: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "   取消注册" -ForegroundColor Gray
        exit 1
    }
}

Write-Host ""

# 3. 检查 RustDesk 是否正在运行
Write-Host "[3] 检查 RustDesk 进程状态..." -ForegroundColor Yellow

$processes = Get-Process -Name "rustdesk" -ErrorAction SilentlyContinue
if ($processes) {
    Write-Host "   ✓ RustDesk 正在运行 (进程数: $($processes.Count))" -ForegroundColor Green
    foreach ($proc in $processes) {
        Write-Host "   PID: $($proc.Id), 路径: $($proc.Path)" -ForegroundColor Gray
    }
} else {
    Write-Host "   ⚠ RustDesk 未运行" -ForegroundColor Yellow
    Write-Host "   注意: URL Scheme 通常需要 RustDesk 已启动或允许自动启动" -ForegroundColor Gray
}

Write-Host ""

# 如果只是诊断模式，到这里结束
if ($DiagnoseOnly) {
    Write-Host "=== 诊断完成 ===" -ForegroundColor Cyan
    exit 0
}

# 4. 测试 URL Scheme
Write-Host "[4] 测试 URL Scheme..." -ForegroundColor Yellow

if (-not $RemoteID) {
    Write-Host "   请输入远程 ID: " -NoNewline -ForegroundColor Yellow
    $RemoteID = Read-Host
}

if (-not $Password) {
    Write-Host "   请输入密码 (可选，直接回车跳过): " -NoNewline -ForegroundColor Yellow
    $securePassword = Read-Host -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
}

# 构造 URL
$url = "rustdesk://connect/$RemoteID"
if ($Password) {
    $encodedPassword = [System.Web.HttpUtility]::UrlEncode($Password)
    $url += "?password=$encodedPassword"
}

Write-Host ""
Write-Host "   生成的 URL: $url" -ForegroundColor Cyan
Write-Host ""

Write-Host "   选择测试方式:" -ForegroundColor Yellow
Write-Host "   [1] 使用 Start-Process (推荐)" -ForegroundColor Gray
Write-Host "   [2] 使用 PowerShell 命令行" -ForegroundColor Gray
Write-Host "   [3] 创建测试 HTML 文件" -ForegroundColor Gray
Write-Host "   [4] 直接调用 RustDesk.exe 命令行参数" -ForegroundColor Gray
Write-Host ""
Write-Host "   请选择 (1-4): " -NoNewline -ForegroundColor Yellow
$choice = Read-Host

switch ($choice) {
    "1" {
        Write-Host "   正在使用 Start-Process 启动 URL..." -ForegroundColor Yellow
        try {
            Start-Process $url
            Write-Host "   ✓ URL 已发送" -ForegroundColor Green
            Write-Host "   如果没有反应，请检查浏览器是否弹出确认对话框" -ForegroundColor Gray
        } catch {
            Write-Host "   ✗ 失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "2" {
        Write-Host "   正在使用 PowerShell 启动 URL..." -ForegroundColor Yellow
        try {
            & $url
            Write-Host "   ✓ URL 已发送" -ForegroundColor Green
        } catch {
            Write-Host "   ✗ 失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "3" {
        Write-Host "   正在创建测试 HTML 文件..." -ForegroundColor Yellow
        
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>RustDesk URL Scheme 测试</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            max-width: 800px; 
            margin: 50px auto; 
            padding: 20px; 
        }
        .test-link { 
            display: inline-block;
            padding: 15px 30px; 
            background-color: #0078d4; 
            color: white; 
            text-decoration: none; 
            border-radius: 5px; 
            font-size: 18px;
            margin: 20px 0;
        }
        .test-link:hover { 
            background-color: #005a9e; 
        }
        code {
            background: #f0f0f0;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
        }
        .info {
            background: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 15px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <h1>🧪 RustDesk URL Scheme 测试</h1>
    
    <div class="info">
        <strong>提示：</strong>点击下方链接后，浏览器可能会弹出确认对话框，请选择"打开 RustDesk"。
    </div>
    
    <h2>测试 URL:</h2>
    <code>$url</code>
    
    <br><br>
    <a href="$url" class="test-link">点击测试连接</a>
    
    <h2>说明：</h2>
    <ul>
        <li>如果点击后 RustDesk 启动并开始连接，说明 URL Scheme 工作正常</li>
        <li>如果没有反应，请检查：
            <ul>
                <li>RustDesk 是否已正确安装</li>
                <li>URL Scheme 是否已注册</li>
                <li>浏览器是否阻止了自动跳转</li>
            </ul>
        </li>
    </ul>
    
    <h2>手动测试方法：</h2>
    <ol>
        <li>复制上面的 URL</li>
        <li>在浏览器地址栏粘贴</li>
        <li>按回车</li>
    </ol>
</body>
</html>
"@
        
        $htmlFile = "$env:TEMP\rustdesk_url_test.html"
        $htmlContent | Out-File -FilePath $htmlFile -Encoding UTF8
        
        Write-Host "   ✓ 测试文件已创建: $htmlFile" -ForegroundColor Green
        Write-Host "   正在打开浏览器..." -ForegroundColor Yellow
        Start-Process $htmlFile
    }
    
    "4" {
        Write-Host "   正在使用命令行参数方式启动..." -ForegroundColor Yellow
        try {
            $arguments = @("--connect", $RemoteID)
            if ($Password) {
                $arguments += @("--password", $Password)
            }
            
            Write-Host "   执行命令: `"$rustdeskExe`" $($arguments -join ' ')" -ForegroundColor Gray
            Start-Process -FilePath $rustdeskExe -ArgumentList $arguments
            Write-Host "   ✓ RustDesk 已启动" -ForegroundColor Green
        } catch {
            Write-Host "   ✗ 失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    default {
        Write-Host "   ✗ 无效选择" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=== 测试完成 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "故障排查提示:" -ForegroundColor Yellow
Write-Host "1. 确保使用的是 Flutter 版本的 RustDesk（URL Scheme 主要支持 Flutter 版）" -ForegroundColor Gray
Write-Host "2. 某些浏览器需要用户手动确认才能打开外部应用" -ForegroundColor Gray
Write-Host "3. 如果是首次使用，可能需要关闭并重新打开浏览器" -ForegroundColor Gray
Write-Host "4. 检查防火墙或安全软件是否阻止了 RustDesk" -ForegroundColor Gray
Write-Host "5. 尝试使用命令行方式作为替代: rustdesk.exe --connect <ID> --password <PWD>" -ForegroundColor Gray
