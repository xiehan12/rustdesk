# RustDesk 命令行连接指南

## 📋 概述

RustDesk 支持通过命令行参数直接连接到远程设备，无需打开GUI手动输入。

---

## 🚀 基本用法

### 方式 1：使用 Flutter 版本（推荐）

```bash
# 连接到远程桌面
rustdesk.exe --connect <REMOTE_ID> --password <PASSWORD>

# 文件传输模式
rustdesk.exe --file-transfer <REMOTE_ID> --password <PASSWORD>

# TCP 隧道模式
rustdesk.exe --port-forward <REMOTE_ID> --password <PASSWORD>

# 查看远程摄像头
rustdesk.exe --view-camera <REMOTE_ID> --password <PASSWORD>
```

### 方式 2：使用 Sciter 版本

```bash
# Sciter 版本通过窗口初始化参数传递
rustdesk.exe <REMOTE_ID> <PASSWORD>
```

---

## 💡 命令行参数详解

| 参数 | 说明 | 示例 |
|------|------|------|
| `--connect <ID>` | 连接到指定远程桌面 | `--connect 123456789` |
| `--password <PWD>` | 指定连接密码 | `--password mypassword123` |
| `--file-transfer <ID>` | 打开文件传输窗口 | `--file-transfer 123456789` |
| `--port-forward <ID>` | 打开TCP隧道窗口 | `--port-forward 123456789` |
| `--view-camera <ID>` | 查看远程摄像头 | `--view-camera 123456789` |
| `--relay` | 强制使用中继服务器 | `--relay` |

---

## 📝 完整示例

### 示例 1：连接到远程桌面

```bash
# Windows
"C:\Program Files\RustDesk\rustdesk.exe" --connect 123456789 --password mypassword123

# PowerShell
& "C:\Program Files\RustDesk\rustdesk.exe" --connect 123456789 --password mypassword123

# 简化路径（如果已在 PATH 中）
rustdesk --connect 123456789 --password mypassword123
```

### 示例 2：文件传输

```bash
rustdesk.exe --file-transfer 123456789 --password mypassword123
```

### 示例 3：强制使用中继

```bash
rustdesk.exe --connect 123456789 --password mypassword123 --relay
```

---

## 🔐 安全建议

### ⚠️ 密码安全问题

**命令行参数中的密码可能被其他进程读取！**

```powershell
# ❌ 不安全 - 密码会显示在进程列表中
rustdesk.exe --connect 123456789 --password mypassword123

# ✅ 更安全 - 使用环境变量
$env:RUSTDESK_PASSWORD = "mypassword123"
rustdesk.exe --connect 123456789 --password $env:RUSTDESK_PASSWORD
```

### 推荐方案

#### 方案 1：使用配置文件保存密码

```bash
# 首次连接时勾选"记住密码"
# 之后可以不带 --password 参数
rustdesk.exe --connect 123456789
```

#### 方案 2：使用 PowerShell 包装脚本

```powershell
# connect-rustdesk.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$RemoteID,
    
    [Parameter(Mandatory=$false)]
    [SecureString]$Password
)

if (-not $Password) {
    $Password = Read-Host "Enter password" -AsSecureString
}

# 转换 SecureString 为明文（仅用于参数传递）
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# 执行连接
& "rustdesk.exe" --connect $RemoteID --password $PlainPassword

# 清理内存
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
Remove-Variable PlainPassword
```

**使用方式：**
```powershell
.\connect-rustdesk.ps1 -RemoteID 123456789
# 会提示输入密码（不显示）
```

#### 方案 3：使用批处理脚本

```batch
@echo off
setlocal enabledelayedexpansion

set /p REMOTE_ID="Enter Remote ID: "
set /p PASSWORD="Enter Password: "

"C:\Program Files\RustDesk\rustdesk.exe" --connect %REMOTE_ID% --password %PASSWORD%

set REMOTE_ID=
set PASSWORD=
endlocal
```

---

## 🛠️ 高级用法

### 1. 批量连接脚本

```powershell
# batch-connect.ps1
$connections = @(
    @{ID="123456789"; Password="pass1"},
    @{ID="987654321"; Password="pass2"},
    @{ID="555555555"; Password="pass3"}
)

foreach ($conn in $connections) {
    Write-Host "Connecting to $($conn.ID)..."
    Start-Process "rustdesk.exe" -ArgumentList "--connect", $conn.ID, "--password", $conn.Password
    Start-Sleep -Seconds 2
}
```

### 2. 快捷方式创建

```powershell
# 创建桌面快捷方式
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\RustDesk-Server1.lnk")
$Shortcut.TargetPath = "C:\Program Files\RustDesk\rustdesk.exe"
$Shortcut.Arguments = "--connect 123456789 --password mypass"
$Shortcut.IconLocation = "C:\Program Files\RustDesk\rustdesk.exe,0"
$Shortcut.Description = "Connect to Server 1"
$Shortcut.Save()
```

### 3. 定时连接任务

```powershell
# 创建计划任务 - 每天早上9点自动连接
$Action = New-ScheduledTaskAction -Execute "rustdesk.exe" `
    -Argument "--connect 123456789 --password mypassword"
    
$Trigger = New-ScheduledTaskTrigger -Daily -At 9am

Register-ScheduledTask -TaskName "RustDesk Auto Connect" `
    -Action $Action `
    -Trigger $Trigger `
    -Description "Auto connect to remote desktop"
```

---

## 🔍 故障排查

### 问题 1：命令行参数不生效

**症状：**
```
运行命令后打开了主窗口，但没有自动连接
```

**原因：**
- Sciter 版本不支持部分参数
- 参数顺序错误
- 已有实例正在运行

**解决：**
```bash
# 确保使用正确的参数顺序
rustdesk.exe --connect <ID> --password <PASSWORD>

# 关闭所有 RustDesk 实例后再试
taskkill /f /im rustdesk.exe
rustdesk.exe --connect 123456789 --password mypass
```

### 问题 2：密码包含特殊字符

**症状：**
```bash
密码中有空格或特殊字符时连接失败
```

**解决：**
```bash
# 使用引号包裹密码
rustdesk.exe --connect 123456789 --password "my password 123!"

# PowerShell 中转义特殊字符
rustdesk.exe --connect 123456789 --password "my`$pass`@123"
```

### 问题 3：找不到 rustdesk.exe

**症状：**
```
'rustdesk.exe' 不是内部或外部命令
```

**解决：**
```powershell
# 使用完整路径
& "C:\Program Files\RustDesk\rustdesk.exe" --connect 123456789

# 或添加到 PATH
$env:Path += ";C:\Program Files\RustDesk"
rustdesk.exe --connect 123456789
```

---

## 📚 API 集成示例

### Python 调用

```python
import subprocess
import os

def connect_rustdesk(remote_id: str, password: str, mode: str = "connect"):
    """
    连接到 RustDesk 远程设备
    
    Args:
        remote_id: 远程设备 ID
        password: 连接密码
        mode: 连接模式 (connect, file-transfer, port-forward)
    """
    rustdesk_exe = r"C:\Program Files\RustDesk\rustdesk.exe"
    
    args = [rustdesk_exe, f"--{mode}", remote_id, "--password", password]
    
    try:
        subprocess.Popen(args)
        print(f"✓ 正在连接到 {remote_id}...")
        return True
    except Exception as e:
        print(f"✗ 连接失败: {e}")
        return False

# 使用示例
connect_rustdesk("123456789", "mypassword123")
connect_rustdesk("987654321", "pass2", mode="file-transfer")
```

### Node.js 调用

```javascript
const { spawn } = require('child_process');

function connectRustDesk(remoteId, password, mode = 'connect') {
    const rustdeskExe = 'C:\\Program Files\\RustDesk\\rustdesk.exe';
    
    const args = [`--${mode}`, remoteId, '--password', password];
    
    const process = spawn(rustdeskExe, args, {
        detached: true,
        stdio: 'ignore'
    });
    
    process.unref();
    console.log(`✓ 正在连接到 ${remoteId}...`);
}

// 使用示例
connectRustDesk('123456789', 'mypassword123');
```

### C# 调用

```csharp
using System.Diagnostics;

public class RustDeskConnector
{
    private const string RustDeskExe = @"C:\Program Files\RustDesk\rustdesk.exe";
    
    public static void Connect(string remoteId, string password, string mode = "connect")
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = RustDeskExe,
            Arguments = $"--{mode} {remoteId} --password {password}",
            UseShellExecute = false,
            CreateNoWindow = true
        };
        
        try
        {
            Process.Start(startInfo);
            Console.WriteLine($"✓ 正在连接到 {remoteId}...");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"✗ 连接失败: {ex.Message}");
        }
    }
}

// 使用示例
RustDeskConnector.Connect("123456789", "mypassword123");
```

---

## 🎯 实际应用场景

### 场景 1：IT 运维脚本

```powershell
# IT 管理员快速连接到多台服务器
$servers = Import-Csv servers.csv
# CSV 格式: Name,ID,Password

foreach ($server in $servers) {
    Write-Host "Connecting to $($server.Name)..."
    Start-Process rustdesk.exe -ArgumentList `
        "--connect", $server.ID, `
        "--password", $server.Password
}
```

### 场景 2：远程支持工具集成

```python
# 集成到客户支持系统
def remote_support(ticket_id):
    # 从数据库获取连接信息
    connection = get_connection_info(ticket_id)
    
    # 自动连接
    connect_rustdesk(
        remote_id=connection['device_id'],
        password=connection['temp_password']
    )
    
    # 记录日志
    log_support_session(ticket_id, connection['device_id'])
```

### 场景 3：自动化测试

```python
# 自动化测试脚本
def test_remote_application():
    # 连接到测试环境
    connect_rustdesk("test-machine-id", "test-password")
    
    # 等待连接建立
    time.sleep(5)
    
    # 执行测试操作...
    run_automated_tests()
```

---

## ✅ 命令速查表

| 命令 | 作用 |
|------|------|
| `rustdesk --connect <ID> --password <PWD>` | 连接远程桌面 |
| `rustdesk --file-transfer <ID> --password <PWD>` | 文件传输 |
| `rustdesk --port-forward <ID> --password <PWD>` | TCP 隧道 |
| `rustdesk --connect <ID> --password <PWD> --relay` | 强制中继 |
| `rustdesk --get-id` | 获取本机 ID |
| `rustdesk --password <PWD>` | 设置永久密码 |
| `rustdesk --service start` | 启动服务 |

---

## 🔗 相关文档

- `PASSWORD_CLI_GUIDE.md` - 密码命令行详细指南
- `POWERSHELL_GUIDE.md` - PowerShell 完整方案
- `PASSWORD_MANAGER_README.md` - 密码管理总览

---

## 💡 提示

- 首次连接建议先手动连接并勾选"记住密码"，之后可以省略 `--password` 参数
- 密码会保存在配置文件中：`%APPDATA%\RustDesk\config\RustDesk2.toml`
- 使用 `rustdesk --password "new_password"` 可以更新保存的密码
- 命令行连接支持所有 RustDesk 的连接模式

---

## 🎉 总结

RustDesk 的命令行连接功能非常灵活，可以轻松集成到各种自动化脚本和系统中。

**最佳实践：**
1. ✅ 使用包装脚本保护密码
2. ✅ 利用"记住密码"功能简化命令
3. ✅ 结合任务计划程序实现自动化
4. ✅ 在生产环境中使用环境变量传递密码

现在你可以通过命令行快速连接 RustDesk 了！🚀
