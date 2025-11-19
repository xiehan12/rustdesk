# RustDesk 静默安装 Debug 模式说明

## 🎯 问题说明

### 修改前的问题

在使用 `--silent-install` 命令时，如果带有多个参数，会自动触发 debug 模式：

```powershell
# 这个命令会触发 debug 模式（因为参数 > 1）
rustdesk.exe --silent-install --path=C:\RustDesk --nolink

# 结果：显示安装界面并等待 300 秒（修改后为 10 秒）
```

**原因：**
```rust
// 错误的逻辑：参数个数 > 1 就认为是 debug 模式
let res = platform::install_me(&options, install_path, true, args.len() > 1);
```

---

## ✅ 解决方案

### 修改后的逻辑

现在只有**显式指定 `debug` 参数**才会启用 debug 模式：

```rust
// 正确的逻辑：检查是否有显式的 debug 参数
let mut debug_mode = false;
for arg in &args[1..] {
    if arg == "debug" {
        debug_mode = true;
    }
}
let res = platform::install_me(&options, install_path, true, debug_mode);
```

---

## 🚀 使用方法

### 正常安装（无等待）

```powershell
# 基本安装
rustdesk.exe --silent-install

# 自定义路径
rustdesk.exe --silent-install --path=C:\RustDesk

# 不创建桌面快捷方式
rustdesk.exe --silent-install --nolink

# 完整参数
rustdesk.exe --silent-install --path=C:\CQNTServer\RustDesk --nolink
```

**特点：**
- ✅ 完全静默
- ✅ 无窗口显示
- ✅ 无等待时间
- ✅ 适合批量部署

---

### Debug 模式（等待 10 秒）

```powershell
# 启用 debug 模式
rustdesk.exe --silent-install debug

# 带其他参数的 debug 模式
rustdesk.exe --silent-install --path=C:\RustDesk --nolink debug

# 或者任意位置
rustdesk.exe --silent-install debug --path=C:\RustDesk
```

**特点：**
- ✅ 显示安装窗口
- ✅ 等待 10 秒（可按键跳过）
- ✅ 方便查看安装过程
- ✅ 便于排查问题

---

## 📊 对比表

| 命令 | Debug 模式 | 等待时间 | 显示窗口 |
|------|-----------|---------|---------|
| `--silent-install` | ❌ | 0秒 | ❌ |
| `--silent-install --path=C:\RustDesk` | ❌ | 0秒 | ❌ |
| `--silent-install --nolink` | ❌ | 0秒 | ❌ |
| `--silent-install --path=C:\RustDesk --nolink` | ❌ | 0秒 | ❌ |
| `--silent-install debug` | ✅ | 10秒 | ✅ |
| `--silent-install --path=C:\RustDesk debug` | ✅ | 10秒 | ✅ |

---

## 🔧 修改内容

### 文件 1：`src/core_main.rs`

**修改前：**
```rust
let res = platform::install_me(&options, install_path, true, args.len() > 1);
// 问题：参数个数 > 1 就启用 debug
```

**修改后：**
```rust
// 解析 debug 参数
let mut debug_mode = false;
for arg in &args[1..] {
    if arg == "debug" {
        debug_mode = true;
    }
}

let res = platform::install_me(&options, install_path, true, debug_mode);
// 正确：只有显式指定 debug 才启用
```

---

### 文件 2：`src/platform/windows.rs`

**修改：**
```rust
// 修改前
sleep = if debug { "timeout 300" } else { "" },

// 修改后
sleep = if debug { "timeout 10" } else { "" },
```

**说明：**
- Debug 模式等待时间从 300 秒改为 10 秒
- 10 秒足够查看安装过程
- 可按任意键跳过等待

---

## 📝 批量部署示例

### 标准部署（无等待）

```powershell
# 批量部署脚本
$computers = @("PC01", "PC02", "PC03")

foreach ($pc in $computers) {
    Copy-Item "rustdesk.exe" "\\$pc\C$\Temp\"
    
    Invoke-Command -ComputerName $pc -ScriptBlock {
        # 静默安装，无等待
        $output = & C:\Temp\rustdesk.exe --silent-install `
            --path="C:\Program Files\RustDesk" --nolink 2>&1
        
        # 提取 ID
        if ($output -match 'RustDesk ID:\s*(\d{9,10})') {
            return $matches[1]
        }
    }
}
```

**特点：**
- ✅ 完全自动化
- ✅ 无需人工干预
- ✅ 快速部署
- ✅ 立即获取 ID

---

### Debug 部署（排查问题）

```powershell
# 测试单台机器（debug 模式）
Invoke-Command -ComputerName "TestPC" -ScriptBlock {
    # 启用 debug 模式，等待 10 秒查看输出
    & C:\Temp\rustdesk.exe --silent-install `
        --path="C:\Program Files\RustDesk" --nolink debug
    
    # 等待查看安装过程
    # 按任意键继续
}
```

**使用场景：**
- ✅ 测试安装流程
- ✅ 排查安装问题
- ✅ 验证参数设置
- ✅ 查看详细输出

---

## 🎯 常见问题

### Q1: 为什么我的安装会等待？

**原因：** 可能使用了旧版本，或者意外启用了 debug 模式。

**解决：**
```powershell
# 检查命令是否包含 debug 参数
rustdesk.exe --silent-install --path=C:\RustDesk --nolink
# ✅ 正确：无 debug，不等待

rustdesk.exe --silent-install --path=C:\RustDesk --nolink debug
# ⚠️ 注意：有 debug，会等待 10 秒
```

---

### Q2: 如何完全跳过等待？

**方法 1：** 不使用 debug 参数
```powershell
rustdesk.exe --silent-install --path=C:\RustDesk
```

**方法 2：** Debug 模式下按任意键跳过
```
Waiting for 10 seconds, press a key to continue ...
# 按任意键立即继续
```

---

### Q3: Debug 模式有什么用？

**用途：**
1. **查看安装过程**：显示详细的安装步骤
2. **排查问题**：能看到错误信息
3. **验证配置**：确认文件复制和注册表设置
4. **开发测试**：调试安装脚本

**示例输出：**
```
Creating directory: C:\Program Files\RustDesk
Copying files...
Creating service...
Setting registry values...
RustDesk ID: 1953645555
Configuration file: C:\Users\Admin\AppData\Roaming\RustDesk\config\RustDesk.toml
Installation completed successfully!
Waiting for 10 seconds, press a key to continue ...
```

---

## 📊 版本对比

| 版本 | Debug 触发条件 | 等待时间 | 适用场景 |
|------|--------------|---------|---------|
| **旧版本** | 参数个数 > 1 | 300秒 | ❌ 不合理 |
| **v2.1.0** | 显式 debug 参数 | 10秒 | ✅ 合理 |

---

## ✅ 总结

### 核心改进

| 改进项 | 说明 |
|--------|------|
| **触发逻辑** | 参数个数 → 显式 debug 参数 |
| **等待时间** | 300 秒 → 10 秒 |
| **默认行为** | 完全静默，无等待 |
| **Debug 模式** | 需要显式指定 |

### 使用建议

| 场景 | 推荐命令 |
|------|---------|
| **生产部署** | `--silent-install --path=... --nolink` |
| **批量安装** | `--silent-install` |
| **测试调试** | `--silent-install debug` |
| **排查问题** | `--silent-install --path=... debug` |

---

**版本：** v2.1.0  
**最后更新：** 2024-11-20  
**文档维护：** xiehan12
