# RustDesk 使用指南

## 🎉 最新更新

**Sciter 版本现在完全支持 `--password` 参数了！**

---

## 📋 快速开始

### 方式 1：命令行连接（推荐）

```powershell
# 完整格式
& "C:\Program Files (x86)\RustDesk\rustdesk.exe" --connect 1074305050 --password xiehan12

# 简化格式（如果已在 PATH 中）
rustdesk.exe --connect 1074305050 --password xiehan12
```

### 方式 2：使用脚本

```powershell
# 快速连接
.\Quick-Connect.ps1 -RemoteID 1074305050 -Password xiehan12

# 测试参数支持
.\Test-PasswordParameter.ps1
```

### 方式 3：URL Scheme（网页）

```html
<a href="rustdesk://connect/1074305050?password=xiehan12">连接</a>
```

---

## 🛠️ 完整功能

### 命令行参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `--connect <ID>` | 连接远程桌面 | `--connect 1074305050` |
| `--password <PWD>` | 指定密码 | `--password xiehan12` |
| `--file-transfer <ID>` | 文件传输模式 | `--file-transfer 1074305050` |
| `--port-forward <ID>` | TCP 隧道模式 | `--port-forward 1074305050` |
| `--relay` | 强制中继 | `--relay` |
| `--get-id` | 获取本机 ID | `--get-id` |

### 参数组合

```powershell
# 连接 + 密码
rustdesk.exe --connect 1074305050 --password xiehan12

# 连接 + 密码 + 强制中继
rustdesk.exe --connect 1074305050 --password xiehan12 --relay

# 文件传输 + 密码
rustdesk.exe --file-transfer 1074305050 --password xiehan12
```

---

## 📝 版本差异

### Sciter 版本（您当前使用）

**特点：**
- ✅ 完整支持 `--password` 参数（已修复）
- ✅ 体积小（< 20MB）
- ✅ 资源占用低
- ⚠️ URL Scheme 支持有限

**安装位置：**
```
C:\Program Files (x86)\RustDesk\rustdesk.exe
```

### Flutter 版本

**特点：**
- ✅ 完整支持所有功能
- ✅ URL Scheme 完整支持
- ⚠️ 体积较大（> 30MB）

---

## 🚀 实际应用场景

### 场景 1：IT 运维快速连接

```powershell
# 创建多个服务器的快捷方式
$servers = @{
    "Server1" = "1074305050"
    "Server2" = "987654321"
    "Server3" = "555555555"
}

foreach ($name in $servers.Keys) {
    $id = $servers[$name]
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$Home\Desktop\$name.lnk")
    $Shortcut.TargetPath = "C:\Program Files (x86)\RustDesk\rustdesk.exe"
    $Shortcut.Arguments = "--connect $id --password xiehan12"
    $Shortcut.Save()
}
```

### 场景 2：网页管理面板

```html
<!DOCTYPE html>
<html>
<head>
    <title>服务器管理</title>
</head>
<body>
    <h1>服务器列表</h1>
    <ul>
        <li><a href="rustdesk://connect/1074305050?password=xiehan12">服务器 1</a></li>
        <li><a href="rustdesk://connect/987654321?password=abc123">服务器 2</a></li>
        <li><a href="rustdesk://connect/555555555?password=pass123">服务器 3</a></li>
    </ul>
</body>
</html>
```

### 场景 3：自动化脚本

```powershell
# 定时连接和执行任务
$RemoteID = "1074305050"
$Password = "xiehan12"

# 连接到远程服务器
& "C:\Program Files (x86)\RustDesk\rustdesk.exe" --connect $RemoteID --password $Password

# 等待连接建立
Start-Sleep -Seconds 10

# 执行其他任务...
```

---

## 🔧 诊断工具

### 工具 1：完整诊断

```powershell
.\Diagnose-RustDesk.ps1
```

**功能：**
- ✅ 检测 RustDesk 安装
- ✅ 检测 Sciter/Flutter 版本
- ✅ 检测参数支持
- ✅ 提供解决方案

### 工具 2：URL Scheme 测试

```powershell
.\Test-URLScheme.ps1 -DiagnoseOnly
```

**功能：**
- ✅ 检查 URL Scheme 注册
- ✅ 测试浏览器支持
- ✅ 生成测试 HTML

### 工具 3：参数测试

```powershell
.\Test-PasswordParameter.ps1 -RemoteID 1074305050 -Password xiehan12
```

**功能：**
- ✅ 测试新格式参数
- ✅ 测试旧格式参数
- ✅ 测试参数组合

---

## 📚 相关文档

| 文档 | 说明 |
|------|------|
| `COMMAND_LINE_CONNECT.md` | 命令行连接完整指南 |
| `URL_SCHEME_GUIDE.md` | URL Scheme 使用指南 |
| `SCITER_PASSWORD_FIX.md` | Sciter 版本 --password 修复说明 |
| `POWERSHELL_GUIDE.md` | PowerShell 脚本使用指南 |
| `PASSWORD_CLI_GUIDE.md` | 密码命令行详细说明 |

---

## ⚙️ 高级配置

### 设置永久密码

```powershell
# 以管理员身份运行
& "C:\Program Files (x86)\RustDesk\rustdesk.exe" --password xiehan12

# 之后可以不带密码参数连接
& "C:\Program Files (x86)\RustDesk\rustdesk.exe" --connect 1074305050
```

### 配置文件位置

```
%APPDATA%\RustDesk\config\RustDesk2.toml
```

### 环境变量

```powershell
# 设置默认服务器
$env:RUSTDESK_DEFAULT_SERVER = "your-server.com"

# 设置日志级别
$env:RUST_LOG = "debug"
```

---

## 🔒 安全建议

### ⚠️ 命令行密码安全

**问题：**
- 密码在命令行中可见
- 可能被其他进程读取
- 可能被记录在日志中

**建议：**

1. **使用永久密码功能**
```powershell
# 一次设置，永久使用
& "C:\Program Files (x86)\RustDesk\rustdesk.exe" --password your_password
```

2. **使用环境变量**
```powershell
$env:RUSTDESK_PASSWORD = "your_password"
& "C:\Program Files (x86)\RustDesk\rustdesk.exe" --connect 1074305050 --password $env:RUSTDESK_PASSWORD
```

3. **使用快捷方式**
```powershell
# 密码存储在快捷方式中，不在命令历史中
.\Quick-Connect.ps1 -RemoteID 1074305050 -Password your_password
```

---

## 🎯 常见问题

### Q: 如何确认我使用的是 Sciter 还是 Flutter 版本？

```powershell
.\Diagnose-RustDesk.ps1
```

或检查文件大小：
- Sciter: < 20MB
- Flutter: > 30MB

### Q: --password 参数不生效怎么办？

1. 确认使用的是最新编译的版本
2. 运行测试脚本验证：
```powershell
.\Test-PasswordParameter.ps1
```

### Q: URL Scheme 点击后没反应？

1. 检查 URL Scheme 注册：
```powershell
.\Test-URLScheme.ps1 -DiagnoseOnly
```

2. 对于 Sciter 版本，建议使用命令行参数

### Q: 密码包含特殊字符怎么办？

使用引号包裹：
```powershell
& "rustdesk.exe" --connect 1074305050 --password "my@pass#123"
```

---

## 📦 文件清单

### 主程序

- `rustdesk.exe` - RustDesk 主程序

### PowerShell 脚本

- `Quick-Connect.ps1` - 快速连接脚本
- `Diagnose-RustDesk.ps1` - 完整诊断工具
- `Test-URLScheme.ps1` - URL Scheme 测试
- `Test-PasswordParameter.ps1` - 参数测试

### HTML 工具

- `test-url-scheme.html` - URL Scheme 网页测试工具

### 文档

- `README_USAGE.md` - 本文档
- `COMMAND_LINE_CONNECT.md` - 命令行指南
- `URL_SCHEME_GUIDE.md` - URL Scheme 指南
- `SCITER_PASSWORD_FIX.md` - 修复说明
- 其他文档...

---

## 🎉 总结

现在您可以：

✅ 使用 `--password` 参数直接连接（Sciter 和 Flutter 都支持）
✅ 通过命令行快速连接到任意远程设备
✅ 通过网页 URL Scheme 拉起 RustDesk
✅ 使用 PowerShell 脚本自动化连接
✅ 使用诊断工具快速排查问题

**开始使用：**

```powershell
# 快速测试
.\Test-PasswordParameter.ps1 -RemoteID 1074305050 -Password xiehan12

# 实际连接
.\Quick-Connect.ps1 -RemoteID 1074305050 -Password xiehan12
```

祝您使用愉快！🚀
