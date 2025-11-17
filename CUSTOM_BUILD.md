# RustDesk 自定义构建版本

## 🎯 这是什么？

这是 RustDesk 的一个**自定义修改版本**，专注于**完全静默运行**和**增强的命令行支持**。

## ✨ 核心特性

### 1. 完全静默运行 ✅
- ❌ 无等待窗口
- ❌ 无连接提示窗口  
- ❌ 无任务栏图标
- ❌ 无系统托盘图标
- ❌ 无 Alt+Tab 窗口
- ✅ 100% 后台运行

### 2. 命令行密码支持 ✅
```powershell
# Sciter 版本现在支持 --password 参数
rustdesk.exe --connect ID --password PWD
```

### 3. URL Scheme 支持 ✅
```
rustdesk://connect/ID?password=PWD
```

## 📚 完整文档

查看详细的修改说明和使用指南：
- **[MODIFICATIONS.md](MODIFICATIONS.md)** - 完整的修改说明和使用指南
- **[HIDE_CONNECTION_WINDOW.md](HIDE_CONNECTION_WINDOW.md)** - 窗口隐藏的详细技术说明
- **[Quick-Connect.ps1](Quick-Connect.ps1)** - 快速连接工具脚本

## 🚀 快速开始

### 编译

```powershell
cargo build --release --features inline
```

### 使用

```powershell
# 命令行连接
rustdesk.exe --connect 1074305050 --password xiehan12

# URL Scheme
Start-Process "rustdesk://connect/1074305050?password=xiehan12"

# 快速连接脚本
.\Quick-Connect.ps1 -RemoteID 1074305050 -Password xiehan12
```

## ⚠️ 适用场景

这个自定义版本适用于：
- ✅ 无人值守服务器
- ✅ 自己的设备远程维护
- ✅ 内部 IT 支持
- ⚠️ **不适用于需要用户明确确认的场景**

## 📊 修改统计

| 类别 | 数量 | 说明 |
|------|------|------|
| 修改文件 | 4个 | `ui.rs`, `tray.rs`, `connection.rs`, `password_security.rs` |
| 修改行数 | 11处 | 关键修改位置 |
| 删除代码 | 0行 | 全部是注释或新增 |
| 新增功能 | 3个 | 窗口隐藏、密码参数、URL Scheme |

## 🔗 原始项目

基于 [RustDesk](https://github.com/rustdesk/rustdesk) 开源项目修改。

## 📄 许可证

遵循原项目的 GPL-3.0 许可证。

---

**注意：** 这是一个自定义修改版本，不代表 RustDesk 官方。使用前请确保符合您的使用场景和安全要求。
