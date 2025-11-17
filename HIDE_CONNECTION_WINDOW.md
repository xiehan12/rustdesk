# 隐藏被控端连接提示窗口

## 🎯 需求说明

默认情况下，当有人远程连接到您的设备时，会弹出一个连接提示窗口，显示：
- 连接者的名称和 ID
- 连接时长
- 权限控制按钮
- 断开连接按钮

如果您希望**默认隐藏这个窗口**，不在被远程机器上显示连接提示，本文档提供了解决方案。

---

## ✅ 解决方案

### 方案 1：修改默认行为（已实现）

**修改文件：** `libs/hbb_common/src/password_security.rs`

**修改内容：**
```rust
pub fn approve_mode() -> ApproveMode {
    let mode = Config::get_option("approve-mode");
    if mode == "password" {
        ApproveMode::Password
    } else if mode == "click" {
        ApproveMode::Click
    } else if mode == "both" {
        ApproveMode::Both
    } else {
        // 默认使用密码模式，不显示连接提示窗口
        ApproveMode::Password  // ✅ 修改：原来默认是 Both
    }
}
```

**效果：**
- ✅ 默认不显示连接提示窗口
- ✅ 使用密码验证后自动接受连接
- ✅ 如果密码正确，直接建立连接，无需用户确认

---

## 🔧 工作原理

### ApproveMode 三种模式

| 模式 | 说明 | 连接提示窗口 |
|------|------|--------------|
| `Password` | 密码验证模式 | ❌ 不显示 |
| `Click` | 点击确认模式 | ✅ 显示，必须点击接受 |
| `Both` | 混合模式 | ⚠️ 根据密码情况决定 |

### 代码逻辑

在 `src/server/connection.rs` 第 2171-2176 行：

```rust
} else if (password::approve_mode() == ApproveMode::Click
    && !(crate::get_builtin_option(keys::OPTION_ALLOW_LOGON_SCREEN_PASSWORD) == "Y"
        && is_logon()))
    || password::approve_mode() == ApproveMode::Both && !password::has_valid_password()
{
    self.try_start_cm(lr.my_id, lr.my_name, false);  // 显示连接提示窗口
    ...
```

**逻辑说明：**
- 如果 `approve_mode()` 返回 `Click`：总是显示窗口
- 如果 `approve_mode()` 返回 `Both` 且没有有效密码：显示窗口
- 如果 `approve_mode()` 返回 `Password`：**不显示窗口**，直接验证密码

---

## 🚀 使用方法

### 重新编译

修改代码后，需要重新编译：

```powershell
cd E:\GitHub\rustdesk
cargo build --release --features inline
```

### 替换可执行文件

```powershell
# 停止 RustDesk
taskkill /f /im rustdesk.exe

# 备份
copy "C:\Program Files (x86)\RustDesk\rustdesk.exe" "C:\Program Files (x86)\RustDesk\rustdesk.exe.bak"

# 替换
copy "target\release\rustdesk.exe" "C:\Program Files (x86)\RustDesk\rustdesk.exe"
```

### 测试

1. 从另一台设备连接到这台设备
2. 输入正确的密码
3. 应该直接建立连接，**不会显示连接提示窗口**

---

## 🔄 方案 2：通过配置文件控制（可选）

如果您希望保持代码不变，通过配置文件控制行为，可以设置配置选项。

### 配置文件位置

```
Windows: %APPDATA%\RustDesk\config\RustDesk2.toml
Linux:   ~/.config/rustdesk/RustDesk2.toml
macOS:   ~/Library/Preferences/RustDesk2.toml
```

### 配置内容

在配置文件中添加：

```toml
[options]
approve-mode = "password"
```

**可选值：**
- `"password"` - 密码模式，不显示窗口
- `"click"` - 点击模式，总是显示窗口
- `"both"` - 混合模式，根据密码情况决定

### 使用 PowerShell 设置

创建配置设置脚本：

```powershell
# Set-ApproveMode.ps1
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("password", "click", "both")]
    [string]$Mode = "password"
)

$configPath = "$env:APPDATA\RustDesk\config\RustDesk2.toml"
$configDir = Split-Path $configPath

# 创建目录
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

# 读取或创建配置
if (Test-Path $configPath) {
    $content = Get-Content $configPath -Raw
} else {
    $content = "[options]`n"
}

# 更新或添加 approve-mode
if ($content -match 'approve-mode\s*=') {
    $content = $content -replace 'approve-mode\s*=\s*"[^"]*"', "approve-mode = `"$Mode`""
} else {
    if ($content -notmatch '\[options\]') {
        $content = "[options]`n" + $content
    }
    $content = $content -replace '\[options\]', "[options]`napprove-mode = `"$Mode`""
}

# 保存配置
$content | Set-Content $configPath -NoNewline

Write-Host "✓ approve-mode 已设置为: $Mode" -ForegroundColor Green
Write-Host "  配置文件: $configPath" -ForegroundColor Gray
```

**使用方式：**
```powershell
# 设置为密码模式（不显示窗口）
.\Set-ApproveMode.ps1 -Mode password

# 设置为点击模式（显示窗口）
.\Set-ApproveMode.ps1 -Mode click

# 设置为混合模式
.\Set-ApproveMode.ps1 -Mode both
```

---

## 📊 对比

| 方案 | 优点 | 缺点 |
|------|------|------|
| 方案 1（修改代码） | ✅ 永久生效<br>✅ 无需配置<br>✅ 所有安装默认隐藏 | ⚠️ 需要重新编译<br>⚠️ 代码变更 |
| 方案 2（配置文件） | ✅ 无需编译<br>✅ 灵活控制<br>✅ 可随时切换 | ⚠️ 需要每台设备配置<br>⚠️ 可能被用户修改 |

---

## 🎯 推荐方案

**如果您是开发者，为内部使用或特定场景编译：**
- 使用**方案 1**（修改代码），这样默认行为就是隐藏窗口

**如果您是普通用户，不想重新编译：**
- 使用**方案 2**（配置文件），简单快捷

**如果您需要灵活控制：**
- 两种方案结合使用
- 代码设置默认值
- 配置文件允许覆盖

---

## 🔒 安全注意事项

### ⚠️ 隐藏窗口的影响

隐藏连接提示窗口意味着：
1. **用户不知道有人连接** - 没有视觉提示
2. **无法快速断开** - 没有"断开连接"按钮
3. **权限控制隐藏** - 无法实时调整权限

### 🛡️ 安全建议

1. **使用强密码**
   - 确保设置了复杂的连接密码
   - 定期更换密码

2. **启用日志记录**
   - 记录所有连接会话
   - 定期检查连接日志

3. **限制使用场景**
   - 仅在可信环境使用
   - 服务器维护场景
   - 无人值守访问

4. **配合其他安全措施**
   - 使用 VPN
   - 启用防火墙
   - 限制连接 IP

---

## 🧪 测试验证

### 测试步骤

1. **编译并安装修改后的版本**
2. **设置连接密码**
   ```powershell
   & "C:\Program Files (x86)\RustDesk\rustdesk.exe" --password your_password
   ```
3. **从远程设备连接**
   ```powershell
   & rustdesk.exe --connect <ID> --password your_password
   ```
4. **验证结果**
   - ✅ 应该直接建立连接
   - ✅ 被控端不显示连接提示窗口
   - ✅ 可以正常操作远程桌面

### 故障排查

**如果还是显示窗口：**
1. 检查是否使用了正确的可执行文件
2. 检查配置文件中是否有冲突设置
3. 查看日志确认 approve_mode 的值

**查看日志：**
```powershell
$env:RUST_LOG = "info"
& "C:\Program Files (x86)\RustDesk\rustdesk.exe"
```

---

## 📝 代码变更记录

### 修改文件

| 文件 | 修改行 | 变更内容 |
|------|--------|----------|
| `libs/hbb_common/src/password_security.rs` | 85-87 | 修改默认 approve_mode 从 Both 到 Password |

### Git Commit

```bash
git add libs/hbb_common/src/password_security.rs
git commit -m "feat: 默认隐藏被控端连接提示窗口

- 修改 approve_mode() 默认返回值
- 从 Both 改为 Password
- 密码验证后不显示连接提示窗口
- 适用于无人值守和服务器维护场景"
```

---

## 🎉 总结

通过修改 `approve_mode()` 函数的默认返回值，您可以：

✅ **默认隐藏连接提示窗口**
✅ **使用密码直接建立连接**
✅ **无需用户交互**
✅ **适合无人值守场景**

**立即测试：**
```powershell
# 重新编译
cargo build --release --features inline

# 测试连接
.\Quick-Connect.ps1 -RemoteID <ID> -Password <PWD>
```

🚀 享受更流畅的远程连接体验！
