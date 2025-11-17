# Sciter 版本 --password 参数修复说明

## 🎉 更新内容

现在 Sciter 版本**完整支持** `--password` 参数了！

---

## ✅ 修复后的用法

### 方式 1：使用 --password 参数（新功能）

```bash
# Windows CMD
"C:\Program Files (x86)\RustDesk\rustdesk.exe" --connect 1074305050 --password xiehan12

# PowerShell
& "C:\Program Files (x86)\RustDesk\rustdesk.exe" --connect 1074305050 --password xiehan12
```

### 方式 2：直接传递密码（兼容旧格式）

```bash
# 第三个参数作为密码
"C:\Program Files (x86)\RustDesk\rustdesk.exe" --connect 1074305050 xiehan12
```

### 方式 3：不传递密码（手动输入）

```bash
# RustDesk 启动后提示输入密码
"C:\Program Files (x86)\RustDesk\rustdesk.exe" --connect 1074305050
```

---

## 🔧 技术细节

### 修改的文件

**`src/ui.rs`** (行 150-171)

### 修改内容

**之前的代码：**
```rust
let pass = iter.next().unwrap_or(&"".to_owned()).clone();
let args: Vec<String> = iter.map(|x| x.clone()).collect();
```

**修改后的代码：**
```rust
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

let args = remaining_args;
```

---

## 📊 支持的参数格式

### 格式 1：标准格式（推荐）

```bash
rustdesk.exe --connect <ID> --password <PWD>
rustdesk.exe --file-transfer <ID> --password <PWD>
rustdesk.exe --port-forward <ID> --password <PWD>
```

### 格式 2：旧格式（向后兼容）

```bash
rustdesk.exe --connect <ID> <PWD>
rustdesk.exe --file-transfer <ID> <PWD>
```

### 格式 3：组合参数

```bash
rustdesk.exe --connect <ID> --password <PWD> --relay
rustdesk.exe --connect <ID> --password <PWD> --relay --other-arg
```

---

## 🎯 实际示例

### 示例 1：基本连接

```powershell
# 新格式（推荐）
& "C:\Program Files (x86)\RustDesk\rustdesk.exe" --connect 1074305050 --password xiehan12

# 旧格式（仍然支持）
& "C:\Program Files (x86)\RustDesk\rustdesk.exe" --connect 1074305050 xiehan12
```

### 示例 2：文件传输

```powershell
& "C:\Program Files (x86)\RustDesk\rustdesk.exe" --file-transfer 1074305050 --password xiehan12
```

### 示例 3：强制中继

```powershell
& "C:\Program Files (x86)\RustDesk\rustdesk.exe" --connect 1074305050 --password xiehan12 --relay
```

### 示例 4：密码包含特殊字符

```powershell
# PowerShell 中使用引号
& "C:\Program Files (x86)\RustDesk\rustdesk.exe" --connect 1074305050 --password "my@pass#123"

# CMD 中使用引号
"C:\Program Files (x86)\RustDesk\rustdesk.exe" --connect 1074305050 --password "my@pass#123"
```

---

## 🌐 URL Scheme 支持

### 修复后的 URL Scheme

URL Scheme 也会受益于此修复，虽然 Sciter 版本对 URL Scheme 的支持仍然有限。

```
rustdesk://connect/1074305050?password=xiehan12
```

**注意：** URL Scheme 在 Sciter 版本中可能不会自动填充密码，建议使用命令行参数方式。

---

## ✅ 测试方法

### 测试 1：验证参数解析

```powershell
# 运行此命令
& "C:\Program Files (x86)\RustDesk\rustdesk.exe" --connect 1074305050 --password xiehan12

# 预期结果：
# 1. RustDesk 启动
# 2. 自动填入 ID: 1074305050
# 3. 自动填入密码: xiehan12
# 4. 开始连接
```

### 测试 2：密码错误检测

```powershell
# 使用错误密码
& "C:\Program Files (x86)\RustDesk\rustdesk.exe" --connect 1074305050 --password wrong_password

# 预期结果：
# 1. RustDesk 启动并尝试连接
# 2. 提示"密码错误"或"连接失败"
```

### 测试 3：向后兼容性

```powershell
# 旧格式应该仍然工作
& "C:\Program Files (x86)\RustDesk\rustdesk.exe" --connect 1074305050 xiehan12

# 预期结果：
# 与新格式相同
```

---

## 🔄 与 Flutter 版本的对比

| 功能 | Sciter（修复后） | Flutter |
|------|-----------------|---------|
| `--password` 参数 | ✅ 支持 | ✅ 支持 |
| 旧格式兼容 | ✅ 支持 | ❓ 可能不支持 |
| URL Scheme | ⚠️ 有限 | ✅ 完整 |
| 文件大小 | ✅ 小（< 20MB） | ⚠️ 大（> 30MB） |

---

## 📝 注意事项

1. **安全性**：密码在命令行中可见，可能被其他进程读取
   - 建议：使用永久密码功能或快捷方式
   
2. **特殊字符**：密码包含空格或特殊字符时需要使用引号
   ```powershell
   --password "my password 123"
   ```

3. **日志记录**：密码可能会被记录在日志文件中
   - 建议：在生产环境中使用更安全的认证方式

4. **向后兼容**：旧的直接传递密码方式仍然支持
   ```bash
   rustdesk.exe --connect ID password
   ```

---

## 🚀 升级指南

### 如果您使用的是 Sciter 版本

1. **编译新版本**
   ```bash
   cd E:\GitHub\rustdesk
   cargo build --release --features inline
   ```

2. **替换可执行文件**
   ```bash
   # 备份旧版本
   copy "C:\Program Files (x86)\RustDesk\rustdesk.exe" "C:\Program Files (x86)\RustDesk\rustdesk.exe.bak"
   
   # 复制新版本
   copy "target\release\rustdesk.exe" "C:\Program Files (x86)\RustDesk\rustdesk.exe"
   ```

3. **测试新功能**
   ```powershell
   & "C:\Program Files (x86)\RustDesk\rustdesk.exe" --connect 1074305050 --password xiehan12
   ```

---

## 🎉 总结

此修复使 Sciter 版本的 RustDesk 能够：

✅ **支持标准的 `--password` 参数**
✅ **保持向后兼容性**
✅ **统一 Sciter 和 Flutter 版本的参数格式**
✅ **支持更复杂的参数组合**

现在 Sciter 版本用户可以使用与 Flutter 版本相同的命令行参数了！🚀
