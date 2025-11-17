# RustDesk 密码管理 PowerShell 完整方案

> **适用场景：** Windows 服务器环境，没有 Python，纯 PowerShell 实现

---

## 📦 文件清单

| 文件 | 说明 | 用途 |
|------|------|------|
| `Diagnose-RustDeskPassword.ps1` | 诊断工具 | 排查密码命令不生效的问题 |
| `Test-RustDeskPassword.ps1` | 快速测试 | 测试密码更新功能 |
| `RustDeskPasswordManager.ps1` | 守护进程 | 自动化密码管理 |
| `password_manager_config.json` | 配置文件 | 守护进程配置（自动生成） |

---

## 🚀 快速开始

### 步骤 1：诊断环境

**以管理员身份运行 PowerShell：**

```powershell
# 运行诊断工具
.\Diagnose-RustDeskPassword.ps1
```

**预期输出：**
```
==================================================================
RustDesk 密码命令诊断工具
==================================================================

[1/5] 检查管理员权限...
    ✓ 当前拥有管理员权限

[2/5] 检查 RustDesk 安装状态...
    ✓ RustDesk 已安装
    路径: C:\Program Files\RustDesk\rustdesk.exe

[3/5] 检查 RustDesk 服务状态...
    ✓ RustDesk 服务正在运行

[4/5] 检查配置文件...
    ✓ 配置文件存在
    路径: C:\Users\xxx\AppData\Roaming\RustDesk\config\RustDesk2.toml

[5/5] 测试密码命令...
执行命令: C:\Program Files\RustDesk\rustdesk.exe --password TestPassword123
返回码: 0
输出: 'Done!'

==================================================================
诊断结果
==================================================================

✓ 密码命令执行成功！
```

---

### 步骤 2：快速测试

```powershell
# 快速测试密码更新
.\Test-RustDeskPassword.ps1
```

**成功输出：**
```
============================================================
RustDesk 密码更新测试
============================================================

可执行文件: rustdesk.exe
测试密码: TestPassword123!@#

执行命令...

结果:
  返回码: 0
  输出: 'Done!'

✓ 测试成功！密码已更新

建议操作:
  1. 重启 RustDesk 服务以确保生效:
     Restart-Service rustdesk

  2. 查看配置文件中的密码:
     notepad $env:APPDATA\RustDesk\config\RustDesk2.toml
```

---

### 步骤 3：配置守护进程

首次运行会自动创建配置文件：

```powershell
.\RustDeskPasswordManager.ps1
```

会生成 `password_manager_config.json`：

```json
{
  "api_url": "https://your-api-server.com/api/password/update",
  "api_key": "your-secret-api-key",
  "device_id": "",
  "interval_seconds": 120,
  "password_length": 12,
  "retry_times": 3,
  "retry_delay": 5,
  "rustdesk_exe": "rustdesk.exe"
}
```

**修改配置：**

```powershell
notepad password_manager_config.json
```

填入你的 API 服务器信息和密钥。

---

### 步骤 4：运行守护进程

```powershell
# 以管理员身份运行
.\RustDeskPasswordManager.ps1
```

**运行输出：**
```
2025-11-17 22:00:00 - INFO - 配置文件加载成功: password_manager_config.json
2025-11-17 22:00:00 - INFO - 获取到 RustDesk ID: 123456789
2025-11-17 22:00:00 - INFO - ============================================================
2025-11-17 22:00:00 - INFO - RustDesk 密码管理守护进程启动
2025-11-17 22:00:00 - INFO - ============================================================
2025-11-17 22:00:00 - INFO - Device ID: 123456789
2025-11-17 22:00:00 - INFO - 更新间隔: 120 秒
2025-11-17 22:00:00 - INFO - API 服务器: https://api.example.com/api/password/update
2025-11-17 22:00:00 - INFO - 密码长度: 12
2025-11-17 22:00:00 - INFO - ============================================================
2025-11-17 22:00:00 - INFO - ============================================================
2025-11-17 22:00:00 - INFO - 开始密码更新周期 - 2025-11-17 22:00:00
2025-11-17 22:00:00 - INFO - ============================================================
2025-11-17 22:00:00 - INFO - 生成新密码 (长度: 12)
2025-11-17 22:00:01 - SUCCESS - ✓ RustDesk 密码更新成功
2025-11-17 22:00:01 - INFO - 正在上报密码到 API 服务器 (尝试 1/3)...
2025-11-17 22:00:02 - SUCCESS - ✓ 密码上报成功: {"success":true}
2025-11-17 22:00:02 - SUCCESS - ✓ 密码更新周期完成
2025-11-17 22:00:02 - INFO - 下次更新时间: 22:02:02
```

---

## 🔧 常见问题排查

### 问题 1：密码命令不生效

**症状：**
```powershell
PS> rustdesk.exe --password "test123"
Installation and administrative privileges required!
```

**原因和解决：**

| 原因 | 检查方法 | 解决方案 |
|------|---------|---------|
| 未以管理员运行 | 运行诊断工具 | 右键 PowerShell → 以管理员身份运行 |
| 使用便携版 | 检查安装路径 | 下载并安装正式版 |
| 服务未运行 | `Get-Service rustdesk` | `Start-Service rustdesk` |

**快速诊断：**
```powershell
.\Diagnose-RustDeskPassword.ps1
```

---

### 问题 2：服务未运行

**检查服务状态：**
```powershell
Get-Service rustdesk
```

**启动服务：**
```powershell
Start-Service rustdesk
```

**查看服务日志：**
```powershell
Get-EventLog -LogName Application -Source RustDesk -Newest 10
```

---

### 问题 3：找不到 rustdesk.exe

**查找安装路径：**
```powershell
# 方法 1：搜索文件
Get-ChildItem -Path "C:\Program Files" -Filter "rustdesk.exe" -Recurse -ErrorAction SilentlyContinue

# 方法 2：从服务获取
(Get-WmiObject Win32_Service -Filter "Name='rustdesk'").PathName
```

**使用完整路径：**
```powershell
# 修改配置文件中的路径
$config = Get-Content password_manager_config.json | ConvertFrom-Json
$config.rustdesk_exe = "C:\Program Files\RustDesk\rustdesk.exe"
$config | ConvertTo-Json | Set-Content password_manager_config.json
```

---

## 🎯 配置为 Windows 服务

### 方法 1：使用任务计划程序

```powershell
# 创建计划任务
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"C:\path\to\RustDeskPasswordManager.ps1`""

$trigger = New-ScheduledTaskTrigger -AtStartup

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "RustDeskPasswordManager" `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Description "RustDesk 密码自动管理"
```

**启动任务：**
```powershell
Start-ScheduledTask -TaskName "RustDeskPasswordManager"
```

**查看任务状态：**
```powershell
Get-ScheduledTask -TaskName "RustDeskPasswordManager" | Get-ScheduledTaskInfo
```

---

### 方法 2：使用 NSSM

```powershell
# 下载 NSSM
Invoke-WebRequest -Uri "https://nssm.cc/release/nssm-2.24.zip" -OutFile "nssm.zip"
Expand-Archive -Path "nssm.zip" -DestinationPath "."

# 安装服务
.\nssm-2.24\win64\nssm.exe install RustDeskPasswordManager `
    "PowerShell.exe" `
    "-NoProfile -ExecutionPolicy Bypass -File C:\path\to\RustDeskPasswordManager.ps1"

# 启动服务
.\nssm-2.24\win64\nssm.exe start RustDeskPasswordManager
```

---

## 📊 手动测试密码更新

### 基本测试

```powershell
# 方式 1：使用测试脚本
.\Test-RustDeskPassword.ps1

# 方式 2：直接运行命令
rustdesk.exe --password "TestPassword123"

# 方式 3：使用完整路径
& "C:\Program Files\RustDesk\rustdesk.exe" --password "TestPassword123"
```

### 验证密码是否生效

```powershell
# 1. 重启 RustDesk 服务
Restart-Service rustdesk

# 2. 查看配置文件
notepad $env:APPDATA\RustDesk\config\RustDesk2.toml

# 3. 尝试使用新密码连接
```

---

## 🔐 安全最佳实践

### 1. 保护 API 密钥

**不要硬编码密钥：**
```powershell
# ❌ 不安全
$apiKey = "my-secret-key"

# ✅ 使用环境变量
$apiKey = $env:RUSTDESK_API_KEY

# ✅ 或从加密文件读取
$apiKey = Get-Content "encrypted_key.txt" | ConvertTo-SecureString
```

### 2. 限制文件权限

```powershell
# 限制配置文件权限（仅管理员可读）
$acl = Get-Acl password_manager_config.json
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Administrators", "FullControl", "Allow"
)
$acl.AddAccessRule($rule)
Set-Acl password_manager_config.json $acl
```

### 3. 使用 HTTPS

确保 API URL 使用 HTTPS：
```json
{
  "api_url": "https://api.example.com/api/password/update"
}
```

---

## 📝 日志管理

### 查看日志

```powershell
# 查看最新日志
Get-Content password_manager.log -Tail 50

# 实时监控日志
Get-Content password_manager.log -Wait

# 搜索错误
Select-String -Path password_manager.log -Pattern "ERROR"
```

### 日志轮转

```powershell
# 创建日志轮转脚本
$logFile = "password_manager.log"
$maxSize = 10MB

if ((Get-Item $logFile).Length -gt $maxSize) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    Move-Item $logFile "password_manager_$timestamp.log"
}
```

---

## 🎛️ 高级配置

### 自定义密码生成规则

修改 `RustDeskPasswordManager.ps1` 中的密码生成函数：

```powershell
function Generate-SecurePassword {
    param([int]$Length = 12)
    
    # 自定义字符集（例如：只用数字）
    $chars = "0123456789"
    
    # 或添加前缀
    $prefix = "RD-"
    $password = $prefix + (-join ((1..($Length-3)) | ForEach-Object { 
        $chars[(Get-Random -Maximum $chars.Length)] 
    }))
    
    return $password
}
```

### 配置多设备管理

```powershell
# 为每个设备创建独立配置
.\RustDeskPasswordManager.ps1 -ConfigFile "device1_config.json"
.\RustDeskPasswordManager.ps1 -ConfigFile "device2_config.json"
```

---

## 🚨 故障恢复

### 守护进程崩溃

**使用任务计划程序自动重启：**
```powershell
# 配置任务在失败时重启
$task = Get-ScheduledTask -TaskName "RustDeskPasswordManager"
$settings = $task.Settings
$settings.RestartCount = 3
$settings.RestartInterval = "PT1M"  # 1分钟
Set-ScheduledTask -TaskName "RustDeskPasswordManager" -Settings $settings
```

### API 服务器故障

守护进程会自动重试（配置中的 `retry_times`），但 RustDesk 密码已经更新，不影响远程连接。

### 回滚密码

如果需要手动设置密码：
```powershell
rustdesk.exe --password "my-known-password"
```

---

## 📞 命令速查表

| 操作 | 命令 |
|------|------|
| 诊断环境 | `.\Diagnose-RustDeskPassword.ps1` |
| 测试密码更新 | `.\Test-RustDeskPassword.ps1` |
| 启动守护进程 | `.\RustDeskPasswordManager.ps1` |
| 检查服务 | `Get-Service rustdesk` |
| 启动服务 | `Start-Service rustdesk` |
| 重启服务 | `Restart-Service rustdesk` |
| 查看日志 | `Get-Content password_manager.log -Tail 50` |
| 查看配置 | `notepad password_manager_config.json` |
| 测试密码 | `rustdesk.exe --password "test123"` |

---

## ✅ 检查清单

部署前请确认：

- [ ] 以管理员身份运行
- [ ] RustDesk 已安装（非便携版）
- [ ] RustDesk 服务正在运行
- [ ] 配置文件已正确填写
- [ ] API 服务器可访问
- [ ] 防火墙允许 HTTPS 出站连接
- [ ] 已配置为 Windows 服务（可选）
- [ ] 日志文件可写入
- [ ] 测试密码更新成功

---

## 🎉 总结

**PowerShell 方案优势：**

✅ 无需安装 Python  
✅ Windows 原生支持  
✅ 脚本简单易懂  
✅ 便于集成到企业环境  
✅ 可配置为 Windows 服务  

现在你可以在纯 Windows 环境中轻松管理 RustDesk 密码！🚀
