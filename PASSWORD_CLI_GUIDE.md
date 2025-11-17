# RustDesk 命令行密码修改功能详解

## 📋 功能说明

RustDesk 提供了命令行参数 `--password` 用于修改永久密码。

### 基本用法

```bash
rustdesk.exe --password "new_password_here"
```

---

## 🔍 实现原理

### 代码位置

**文件:** `src/core_main.rs` (第375-387行)

```rust
} else if args[0] == "--password" {
    if args.len() == 2 {
        if crate::platform::is_installed() && is_root() {
            if let Err(err) = crate::ipc::set_permanent_password(args[1].to_owned()) {
                println!("{err}");
            } else {
                println!("Done!");
            }
        } else {
            println!("Installation and administrative privileges required!");
        }
    }
    return None;
}
```

### 执行流程

```
命令行输入
    ↓
rustdesk.exe --password "新密码"
    ↓
检查条件
├─ 是否已安装? (is_installed)
└─ 是否管理员权限? (is_root)
    ↓
调用 IPC 接口
crate::ipc::set_permanent_password()
    ↓
更新配置
Config::set_permanent_password()
set_config("permanent-password", v)
    ↓
返回结果
├─ 成功: "Done!"
└─ 失败: 错误消息
```

---

## ⚠️ 使用条件

### 必要条件

| 条件 | 说明 | 检查方式 |
|------|------|---------|
| ✅ **已安装** | 必须是安装版，不能是便携版 | `is_installed()` |
| ✅ **管理员权限** | 必须以管理员身份运行 | `is_root()` |
| ✅ **服务运行中** | RustDesk 服务必须在运行 | IPC 通信需要 |

### 如果不满足条件

```bash
> rustdesk.exe --password "test123"
Installation and administrative privileges required!
```

---

## 💻 在第三方程序中调用

### Python 实现

```python
import subprocess

def update_rustdesk_password(rustdesk_exe: str, new_password: str) -> tuple[bool, str]:
    """
    更新 RustDesk 密码
    
    Args:
        rustdesk_exe: RustDesk 可执行文件路径
        new_password: 新密码
        
    Returns:
        (成功标志, 消息)
    """
    try:
        result = subprocess.run(
            [rustdesk_exe, '--password', new_password],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        output = result.stdout.strip()
        
        if result.returncode == 0 and output == "Done!":
            return True, "密码更新成功"
        else:
            return False, output
            
    except Exception as e:
        return False, str(e)

# 使用示例
success, message = update_rustdesk_password("rustdesk.exe", "NewPassword123")
if success:
    print(f"✓ {message}")
else:
    print(f"✗ {message}")
```

### PowerShell 实现

```powershell
# 更新密码函数
function Update-RustDeskPassword {
    param(
        [string]$RustDeskExe = "rustdesk.exe",
        [string]$NewPassword
    )
    
    try {
        $result = & $RustDeskExe --password $NewPassword 2>&1
        
        if ($result -eq "Done!") {
            Write-Host "✓ 密码更新成功" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ 密码更新失败: $result" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "✗ 执行错误: $_" -ForegroundColor Red
        return $false
    }
}

# 使用示例
Update-RustDeskPassword -NewPassword "NewPassword123"
```

### Batch 脚本实现

```batch
@echo off
setlocal enabledelayedexpansion

set "RUSTDESK_EXE=rustdesk.exe"
set "NEW_PASSWORD=NewPassword123"

echo 正在更新 RustDesk 密码...
"%RUSTDESK_EXE%" --password "%NEW_PASSWORD%" > temp_output.txt 2>&1

set /p OUTPUT=<temp_output.txt
del temp_output.txt

if "!OUTPUT!"=="Done!" (
    echo ✓ 密码更新成功
    exit /b 0
) else (
    echo ✗ 密码更新失败: !OUTPUT!
    exit /b 1
)
```

---

## 🔧 底层实现分析

### IPC 通信机制

**文件:** `src/ipc.rs` (第1019-1022行)

```rust
pub fn set_permanent_password(v: String) -> ResultType<()> {
    Config::set_permanent_password(&v);
    set_config("permanent-password", v)
}
```

### 配置存储

密码存储在配置文件中：

**Windows:**
```
%APPDATA%\RustDesk\config\RustDesk2.toml
```

**Linux:**
```
~/.config/rustdesk/RustDesk2.toml
```

**配置格式:**
```toml
[options]
permanent-password = "加密后的密码"
```

### 密码加密

密码在存储前会经过加密处理（具体加密算法在 `Config::set_permanent_password()` 中实现）。

---

## 🧪 测试方法

### 1. 手动测试

```bash
# 以管理员身份打开 PowerShell 或 CMD

# 测试密码更新
rustdesk.exe --password "TestPassword123"

# 预期输出
Done!
```

### 2. 使用测试脚本

我已经为你创建了 `test_password_update.py`：

```bash
# 以管理员身份运行
python test_password_update.py
```

**输出示例：**
```
============================================================
RustDesk 密码更新命令行测试工具
============================================================

⚠️  注意事项:
   1. 需要以管理员权限运行
   2. RustDesk 必须已安装（不是便携版）
   3. RustDesk 服务必须正在运行

============================================================
测试 RustDesk 密码更新
============================================================
可执行文件: rustdesk.exe
新密码长度: 19 字符
------------------------------------------------------------
返回码: 0
标准输出: Done!
------------------------------------------------------------
✓ 密码更新成功！

============================================================
✓ 测试通过
============================================================
```

---

## ❌ 常见错误及解决方案

### 错误 1: 权限不足

**错误信息:**
```
Installation and administrative privileges required!
```

**原因:**
- 未以管理员身份运行
- 使用的是便携版（未安装）

**解决方案:**
```bash
# Windows: 右键 → 以管理员身份运行
# 或使用命令行
runas /user:Administrator "rustdesk.exe --password NewPass123"
```

### 错误 2: IPC 通信失败

**错误信息:**
```
Failed to connect to IPC
```

**原因:**
- RustDesk 服务未运行
- IPC 管道被占用

**解决方案:**
```bash
# 检查服务状态
sc query rustdesk

# 启动服务
sc start rustdesk

# 或重启服务
rustdesk.exe --service restart
```

### 错误 3: 文件不存在

**错误信息:**
```
找不到可执行文件
```

**原因:**
- 路径错误
- 文件名错误

**解决方案:**
```python
# 使用绝对路径
rustdesk_exe = r"C:\Program Files\RustDesk\rustdesk.exe"
```

---

## 🔐 安全建议

### 1. 密码复杂度

```python
import secrets
import string

def generate_secure_password(length=12):
    """生成安全的随机密码"""
    characters = string.ascii_letters + string.digits + "!@#$%^&*"
    return ''.join(secrets.choice(characters) for _ in range(length))

# 使用
secure_password = generate_secure_password(16)
```

### 2. 传递密码的安全方式

**❌ 不安全：**
```bash
# 密码会显示在进程列表中
rustdesk.exe --password "MyPassword123"
```

**✅ 更安全：**
```python
# 通过环境变量传递
import os
import subprocess

password = os.environ.get('RUSTDESK_PASSWORD')
subprocess.run(['rustdesk.exe', '--password', password])
```

### 3. 日志安全

```python
# 不要在日志中记录明文密码
logger.info(f"密码长度: {len(password)} 字符")  # ✓
logger.info(f"新密码: {password}")  # ✗
```

---

## 📊 集成到密码管理守护进程

在 `password_manager_daemon.py` 中的实现：

```python
def update_rustdesk_password(self, password: str) -> bool:
    """通过命令行更新 RustDesk 密码"""
    try:
        result = subprocess.run(
            [self.rustdesk_exe, '--password', password],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0 and result.stdout.strip() == "Done!":
            logger.info("✓ RustDesk 密码更新成功")
            return True
        else:
            logger.error(f"✗ RustDesk 密码更新失败: {result.stderr}")
            return False
            
    except Exception as e:
        logger.error(f"✗ RustDesk 密码更新异常: {e}")
        return False
```

---

## 🎯 完整工作流程示例

```python
#!/usr/bin/env python3
import subprocess
import secrets
import string
import requests

def main():
    # 1. 生成安全密码
    password = ''.join(secrets.choice(
        string.ascii_letters + string.digits + "!@#$%^&*"
    ) for _ in range(12))
    
    # 2. 更新 RustDesk 密码
    result = subprocess.run(
        ['rustdesk.exe', '--password', password],
        capture_output=True,
        text=True
    )
    
    if result.stdout.strip() != "Done!":
        print(f"更新失败: {result.stdout}")
        return False
    
    # 3. 上报到 API 服务器
    response = requests.post(
        'https://api.example.com/password/update',
        json={'device_id': '123456', 'password': password}
    )
    
    if response.status_code == 200:
        print("✓ 密码更新并上报成功")
        return True
    else:
        print(f"✗ API 上报失败: {response.text}")
        return False

if __name__ == "__main__":
    main()
```

---

## 📚 相关文件

- `test_password_update.py` - 测试工具
- `password_manager_daemon.py` - 完整守护进程
- `PASSWORD_MANAGER_README.md` - 完整方案文档

---

## 🚀 快速开始

```bash
# 1. 测试命令行功能
python test_password_update.py

# 2. 启动密码管理守护进程
python password_manager_daemon.py
```

现在你已经完全了解如何使用 `rustdesk.exe --password` 功能了！🎉
