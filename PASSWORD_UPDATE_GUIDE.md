# RustDesk 第三方程序定时更新密码指南

## 📋 需求

通过第三方程序每2分钟自动更换 RustDesk 的一次性（临时）密码，密码由第三方程序随机生成。

## ✅ 可行性分析

**完全可行！** RustDesk 提供了完整的 IPC（进程间通信）接口支持这个功能。

---

## 🔧 实现方案

### 方案一：通过 IPC 接口（推荐）

#### Windows 平台
- **IPC 路径**: `\\.\pipe\RustDesk\query`
- **协议**: Windows Named Pipe

#### Linux/Unix 平台
- **IPC 路径**: `/tmp/RustDesk/ipc`
- **协议**: Unix Domain Socket

#### 关键代码位置

```rust
// 位置: src/ipc.rs:1000-1002
pub fn update_temporary_password() -> ResultType<()> {
    set_config("temporary-password", "".to_owned())
}

// 位置: src/ipc.rs:558-559
} else if name == "temporary-password" {
    password::update_temporary_password();
```

#### 工作原理

1. 第三方程序通过 IPC 连接到 RustDesk
2. 发送配置更新命令：`Config("temporary-password", "")`
3. RustDesk 接收到命令后调用 `password::update_temporary_password()`
4. 自动生成新的随机密码

---

### 方案二：修改 RustDesk 添加 CLI 支持（需要修改源码）

在 RustDesk 源码中添加命令行参数支持：

```rust
// 修改 src/core_main.rs 或 src/main.rs

if args.contains(&"--update-password".to_string()) {
    password::update_temporary_password();
    println!("Temporary password updated");
    return Ok(());
}
```

然后第三方程序可以简单地调用：
```bash
rustdesk.exe --update-password
```

---

### 方案三：自定义密码（需要修改 RustDesk 源码）

如果需要第三方程序生成密码并设置到 RustDesk：

#### 修改 1: 添加设置临时密码的接口

```rust
// 位置: libs/hbb_common/src/password_security.rs

pub fn set_temporary_password(password: String) {
    *TEMPORARY_PASSWORD.write().unwrap() = password;
}
```

#### 修改 2: 添加 IPC 支持

```rust
// 位置: src/ipc.rs:558 附近

} else if name == "set-temporary-password" {
    password_security::set_temporary_password(value);
    log::info!("Temporary password set to custom value");
```

#### 修改 3: 第三方程序调用

```python
# Python 示例
import random
import string

def generate_password(length=6):
    chars = '23456789abcdefghjkmnpqrstuvwxyz'
    return ''.join(random.choice(chars) for _ in range(length))

# 生成密码
new_password = generate_password()

# 通过 IPC 设置到 RustDesk
send_ipc_command("set-temporary-password", new_password)
```

---

## 📁 提供的示例脚本

### 1. Python 完整实现
**文件**: `update_password_example.py`

功能：
- ✅ 跨平台支持（Windows/Linux）
- ✅ 完整的 IPC 通信实现
- ✅ 自定义密码生成
- ✅ 定时循环更新

依赖：
```bash
# Windows
pip install pywin32

# Linux
# 无额外依赖
```

使用：
```bash
python update_password_example.py
```

### 2. PowerShell 实现
**文件**: `update_password.ps1`

功能：
- ✅ Windows/Linux 跨平台
- ✅ 参数化配置
- ✅ 彩色日志输出

使用：
```powershell
# 默认配置（2分钟，6位密码）
.\update_password.ps1

# 自定义配置
.\update_password.ps1 -Interval 180 -PasswordLength 8 -NumericOnly
```

### 3. 批处理脚本（简化版）
**文件**: `update_password_simple.bat`

适用于快速测试和简单场景。

---

## 🔒 当前 RustDesk 密码机制

### 临时密码生成

```rust
// 位置: libs/hbb_common/src/password_security.rs:23-30
fn get_auto_password() -> String {
    let len = temporary_password_length(); // 6/8/10
    if Config::get_bool_option("allow-numeric-one-time-password") {
        Config::get_auto_numeric_password(len) // 纯数字
    } else {
        Config::get_auto_password(len) // 字母数字混合
    }
}
```

### 字符集

```rust
// 位置: libs/hbb_common/src/config.rs:109-113
const CHARS: &[char] = &[
    '2', '3', '4', '5', '6', '7', '8', '9', 
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k',
    'm', 'n', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
]; // 排除了容易混淆的字符：0, 1, l, o

const NUM_CHARS: &[char] = &['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
```

---

## 🚀 推荐实现步骤

### 快速实现（无需修改源码）

1. **使用 PowerShell 脚本**
   ```powershell
   .\update_password.ps1 -Interval 120
   ```

2. **脚本会定时触发 RustDesk 更新密码**
   - 通过 IPC 发送 `Config("temporary-password", "")`
   - RustDesk 自动生成新密码

3. **配置自动启动**
   - Windows: 添加到任务计划程序
   - Linux: 添加到 systemd 服务

### 完整实现（需要修改源码）

1. **克隆你的 RustDesk 仓库**
   ```bash
   git clone https://github.com/xiehan12/rustdesk.git
   cd rustdesk
   ```

2. **添加自定义密码支持**
   
   修改 `libs/hbb_common/src/password_security.rs`:
   ```rust
   // 新增函数
   pub fn set_temporary_password(password: String) {
       if password.len() >= 6 && password.len() <= 10 {
           *TEMPORARY_PASSWORD.write().unwrap() = password;
           log::info!("Temporary password set by external program");
       }
   }
   ```

3. **添加 IPC 处理**
   
   修改 `src/ipc.rs` 第 558 行附近:
   ```rust
   } else if name == "temporary-password" {
       if value.is_empty() {
           password::update_temporary_password();
       } else {
           password_security::set_temporary_password(value);
       }
   ```

4. **添加 CLI 支持（可选）**
   
   修改 `src/core_main.rs`:
   ```rust
   if args.contains(&"--update-password".to_string()) {
       password::update_temporary_password();
       return Ok(());
   }
   
   if let Some(pos) = args.iter().position(|x| x == "--set-password") {
       if let Some(pwd) = args.get(pos + 1) {
           password_security::set_temporary_password(pwd.clone());
           return Ok(());
       }
   }
   ```

5. **编译并测试**
   ```bash
   cargo build --release
   
   # 测试 CLI
   ./target/release/rustdesk --update-password
   ./target/release/rustdesk --set-password "abc123"
   ```

6. **部署第三方程序**
   ```python
   # your_password_manager.py
   import subprocess
   import time
   import random
   import string
   
   while True:
       pwd = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
       subprocess.run(['rustdesk', '--set-password', pwd])
       print(f"Password updated to: {pwd}")
       time.sleep(120)  # 2分钟
   ```

---

## 🔐 安全建议

1. **密码记录**
   - 将生成的密码记录到安全的日志文件
   - 使用加密存储
   - 定期清理旧密码记录

2. **访问控制**
   - 限制可以调用密码更新的程序
   - 使用文件权限保护 IPC socket

3. **审计日志**
   - 记录每次密码更新的时间
   - 记录更新来源
   - 监控异常更新行为

4. **备份机制**
   - 保留永久密码作为备用
   - 配置 2FA 双因素认证
   - 使用 IP 白名单

---

## 📊 配置选项

### RustDesk 配置文件

编辑 `RustDesk2.toml`:

```toml
[options]
temporary-password-length = "6"  # 或 "8", "10"
allow-numeric-one-time-password = "N"  # "Y" 为纯数字
verification-method = "use-both-passwords"  # 同时支持临时和永久密码
```

### 环境变量（可选）

```bash
# 设置更新间隔
export RUSTDESK_PASSWORD_INTERVAL=120

# 设置密码长度
export RUSTDESK_PASSWORD_LENGTH=6
```

---

## 🎯 总结

**✅ 完全可以实现第三方程序定时更换密码！**

### 最简单的方案
1. 使用提供的 PowerShell 脚本
2. 每2分钟触发 RustDesk 自动生成新密码
3. 无需修改源码

### 完整的方案
1. 修改 RustDesk 源码添加自定义密码支持
2. 第三方程序生成并设置密码
3. 完全控制密码生成逻辑

### 推荐配置
- **更新间隔**: 120秒（2分钟）
- **密码长度**: 6-8位
- **字符集**: 字母数字混合（排除易混淆字符）
- **日志记录**: 启用密码更新审计日志

---

## 📚 相关文件

- `update_password.ps1` - PowerShell 实现脚本
- `update_password_example.py` - Python 完整实现
- `update_password_simple.bat` - Windows 批处理脚本
- 本文档 - 完整实现指南

## 🔗 参考

- RustDesk IPC 实现: `src/ipc.rs`
- 密码安全模块: `libs/hbb_common/src/password_security.rs`
- 配置管理: `libs/hbb_common/src/config.rs`
