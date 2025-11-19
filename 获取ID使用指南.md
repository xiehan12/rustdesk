# RustDesk 获取 ID 完整指南

## 🎯 目标

获取 RustDesk 设备 ID，用于远程连接。

---

## 📋 三种获取方法

### ✅ 方法 1：命令行获取（推荐，需新版本）

```powershell
rustdesk.exe --get-id
```

**优点：**
- 快速、简单
- 无需管理员权限
- 输出纯文本，便于脚本处理

**缺点：**
- 需要编译最新代码
- 旧版本不支持

---

### ✅ 方法 2：从配置文件读取（最可靠）

使用我们提供的脚本：

```powershell
.\Get-RustDeskID-FromConfig.ps1
```

**输出示例：**
```
=== 从配置文件读取 RustDesk ID ===

✅ 找到配置文件
路径: C:\Users\YourName\AppData\Roaming\RustDesk\config\RustDesk.toml

=============================
  RustDesk ID: 1953645555
=============================

设备信息：
  计算机名: YOUR-PC
  用户名: YourName
  时间: 2024-11-19 15:20:30

✅ ID 已复制到剪贴板！
```

**优点：**
- 适用于所有版本
- 100% 可靠
- 自动复制到剪贴板

**配置文件位置：**
- Windows: `%APPDATA%\RustDesk\config\RustDesk.toml`
- Linux: `~/.config/rustdesk/RustDesk.toml`
- macOS: `~/Library/Application Support/RustDesk/config/RustDesk.toml`

---

### ✅ 方法 3：GUI 界面查看

1. 打开 RustDesk 主界面
2. ID 显示在左侧"你的桌面"区域
3. 点击 ID 旁边的三个点菜单
4. 选择"复制 ID"

**优点：**
- 最简单，无需命令行
- 适合单个设备查询

**缺点：**
- 不便于批量操作
- 需要手动复制

---

## 🔧 批量获取 ID

### 场景：获取多台计算机的 ID

```powershell
# 方法 1：直接指定计算机名
.\Get-RustDeskID-Batch.ps1 -ComputerNames "PC01","PC02","PC03"

# 方法 2：从文件读取
.\Get-RustDeskID-Batch.ps1 -ComputerListFile "computers.txt"
```

**computers.txt 格式：**
```
PC01
PC02
PC03
SERVER01
```

**输出示例：**
```
=== RustDesk ID 批量查询 ===

✅ 从文件读取 4 台计算机

[PC01] 正在查询...
[PC01] ✅ ID: 1953645555
[PC02] 正在查询...
[PC02] ✅ ID: 2041789623
[PC03] 正在查询...
[PC03] ❌ 未找到配置文件
[SERVER01] 正在查询...
[SERVER01] ✅ ID: 3156892401

=== 查询完成 ===
总计: 4 台
成功: 3 台
失败: 1 台

✅ 结果已导出到: RustDesk_IDs_20241119_152030.csv

查询结果：
ComputerName RustDeskID  Status              Timestamp
------------ ----------  ------              ---------
PC01         1953645555  成功                2024-11-19 15:20:30
PC02         2041789623  成功                2024-11-19 15:20:31
PC03         NOT_FOUND   配置文件不存在      2024-11-19 15:20:32
SERVER01     3156892401  成功                2024-11-19 15:20:33

=== 可用的 RustDesk ID ===
  PC01: 1953645555
  PC02: 2041789623
  SERVER01: 3156892401
```

---

## 🚀 快速开始

### 单个设备

```powershell
# 1. 获取 ID
.\Get-RustDeskID-FromConfig.ps1

# 2. ID 已自动复制到剪贴板，可以直接粘贴使用
```

### 多个设备

```powershell
# 1. 创建计算机列表文件
@"
PC01
PC02
PC03
"@ | Out-File computers.txt

# 2. 批量获取
.\Get-RustDeskID-Batch.ps1 -ComputerListFile "computers.txt"

# 3. 查看 CSV 结果
Import-Csv "RustDesk_IDs_*.csv" | Format-Table
```

---

## 🔍 故障排查

### 问题 1：`--get-id` 无输出

**原因：** 使用了旧版本或未编译最新代码

**解决方案：**

```powershell
# 方案 A：重新编译
cd e:\GitHub\rustdesk
cargo build --release --features inline
.\target\release\rustdesk.exe --get-id

# 方案 B：使用配置文件方法
.\Get-RustDeskID-FromConfig.ps1
```

---

### 问题 2：配置文件不存在

**原因：** RustDesk 从未启动过

**解决方案：**

1. 启动 RustDesk GUI 程序（至少一次）
2. 等待程序生成 ID
3. 然后再运行脚本

---

### 问题 3：批量获取失败

**原因：** 网络权限或防火墙阻止

**检查清单：**

```powershell
# 1. 测试网络连接
Test-Connection PC01

# 2. 测试文件共享
Test-Path "\\PC01\C$"

# 3. 检查防火墙规则
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*File*"}
```

---

## 📊 使用场景对比

| 场景 | 推荐方法 | 说明 |
|------|---------|------|
| **单台设备快速查询** | 方法 2 (配置文件) | 最快最可靠 |
| **批量部署记录** | 批量脚本 | 自动生成 CSV |
| **脚本集成** | 方法 2 (配置文件) | 返回值易处理 |
| **非技术人员** | 方法 3 (GUI) | 最简单 |
| **远程查询** | 批量脚本 | 支持远程访问 |

---

## 📝 实用脚本示例

### 示例 1：获取并发送邮件

```powershell
# 获取 ID
$id = & ".\Get-RustDeskID-FromConfig.ps1"

# 构建邮件
$body = @"
计算机名: $env:COMPUTERNAME
RustDesk ID: $id
用户: $env:USERNAME
时间: $(Get-Date)
"@

# 发送邮件（需配置 SMTP）
Send-MailMessage -To "admin@company.com" `
    -From "rustdesk@company.com" `
    -Subject "RustDesk ID - $env:COMPUTERNAME" `
    -Body $body `
    -SmtpServer "smtp.company.com"
```

---

### 示例 2：部署时自动记录

```powershell
# 部署脚本
param([string]$LogFile = "C:\Deploy\rustdesk_deployment.log")

# 1. 安装 RustDesk
rustdesk.exe --silent-install --path="C:\Program Files\RustDesk"

# 2. 等待生成 ID
Start-Sleep -Seconds 5

# 3. 获取 ID
$config = Get-Content "$env:APPDATA\RustDesk\config\RustDesk.toml" -Raw
if ($config -match 'id\s*=\s*"([^"]+)"') {
    $id = $matches[1]
    
    # 4. 记录到日志
    $log = "$(Get-Date)|$env:COMPUTERNAME|$id|SUCCESS"
    Add-Content $LogFile $log
    
    Write-Host "✅ 部署成功！ID: $id" -ForegroundColor Green
}
```

---

### 示例 3：定时收集 ID

```powershell
# 创建定时任务，每天收集一次
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-File C:\Scripts\Get-RustDeskID-FromConfig.ps1"

$trigger = New-ScheduledTaskTrigger -Daily -At "08:00"

Register-ScheduledTask -TaskName "CollectRustDeskID" `
    -Action $action `
    -Trigger $trigger `
    -Description "每天收集 RustDesk ID"
```

---

## 🎉 总结

| 方法 | 难度 | 速度 | 可靠性 | 推荐度 |
|------|------|------|--------|--------|
| **命令行 --get-id** | 简单 | ⭐⭐⭐ | ⭐⭐⭐ (需新版本) | ⭐⭐⭐ |
| **配置文件读取** | 简单 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **GUI 界面** | 最简单 | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **批量脚本** | 中等 | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ (批量场景) |

**最佳实践：**
1. 单个设备：使用 `Get-RustDeskID-FromConfig.ps1`
2. 多个设备：使用 `Get-RustDeskID-Batch.ps1`
3. 部署集成：直接读取配置文件

---

## 📁 提供的脚本文件

| 文件名 | 用途 |
|--------|------|
| `Get-RustDeskID.ps1` | 使用 --get-id 命令获取（需新版本） |
| `Get-RustDeskID-FromConfig.ps1` | 从配置文件读取（推荐） |
| `Get-RustDeskID-Batch.ps1` | 批量获取多台设备 ID |
| `Test-GetID.ps1` | 诊断 --get-id 功能 |
| `获取ID问题诊断.md` | 问题诊断文档 |
| `获取ID使用指南.md` | 本文档 |

---

**最后更新：** 2024-11-19  
**版本：** 1.0.0
