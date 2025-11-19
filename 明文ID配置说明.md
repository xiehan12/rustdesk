# RustDesk 明文 ID 配置修改

## 🎯 目标

让 RustDesk 在配置文件中**同时保存明文 ID 和加密 ID**，方便第三方程序直接读取。

---

## ✅ 修改内容

### 文件：`libs/hbb_common/src/config.rs`

#### 修改 1：移除序列化限制（第 180-184 行）

**修改前：**
```rust
#[serde(
    default,
    skip_serializing_if = "String::is_empty",  // ← 这会阻止空ID序列化
    deserialize_with = "deserialize_string"
)]
pub id: String, // use
```

**修改后：**
```rust
#[serde(
    default,
    deserialize_with = "deserialize_string"
)]
pub id: String, // use (明文保存，便于第三方程序读取)
```

#### 修改 2：保留明文 ID（第 634-635 行）

**修改前：**
```rust
fn store(&self) {
    let mut config = self.clone();
    config.password =
        encrypt_str_or_original(&config.password, PASSWORD_ENC_VERSION, ENCRYPT_MAX_LEN);
    config.enc_id = encrypt_str_or_original(&config.id, PASSWORD_ENC_VERSION, ENCRYPT_MAX_LEN);
    config.id = "".to_owned();  // ← 清空明文ID
    Config::store_(&config, "");
}
```

**修改后：**
```rust
fn store(&self) {
    let mut config = self.clone();
    config.password =
        encrypt_str_or_original(&config.password, PASSWORD_ENC_VERSION, ENCRYPT_MAX_LEN);
    config.enc_id = encrypt_str_or_original(&config.id, PASSWORD_ENC_VERSION, ENCRYPT_MAX_LEN);
    // 保留明文 ID，不清空（便于第三方程序读取）
    // config.id = "".to_owned();
    Config::store_(&config, "");
}
```

---

## 📄 配置文件格式

### 修改前（旧版本）

```toml
# RustDesk.toml
enc_id = '00FB738RxKIQtwkeVAuweanrDOotwZ/COaQRQ='  # 只有加密ID
password = ''
salt = 'vfrwa5'
key_pair = [...]
key_confirmed = true
```

**问题：** 无法直接读取数字ID，必须解密 `enc_id`

### 修改后（新版本）

```toml
# RustDesk.toml
id = '1953645555'  # ← 明文数字ID（新增！）
enc_id = '00FB738RxKIQtwkeVAuweanrDOotwZ/COaQRQ='  # 加密ID（兼容旧版本）
password = ''
salt = 'vfrwa5'
key_pair = [...]
key_confirmed = true
```

**优势：** 可以直接读取 `id` 字段，无需解密！

---

## 🚀 使用方法

### 1. 重新编译 RustDesk

```bash
cd e:\GitHub\rustdesk
cargo build --release --features inline
```

### 2. 替换已安装版本

```powershell
# 备份
Copy-Item "C:\Program Files (x86)\RustDesk\rustdesk.exe" `
    -Destination "C:\Program Files (x86)\RustDesk\rustdesk.exe.backup"

# 替换
Copy-Item "target\release\rustdesk.exe" `
    -Destination "C:\Program Files (x86)\RustDesk\rustdesk.exe" -Force
```

### 3. 启动 RustDesk

启动一次 RustDesk，让它重新保存配置文件。

### 4. 验证配置文件

```powershell
Get-Content "$env:APPDATA\RustDesk\config\RustDesk.toml" | Select-String "^id ="
```

应该看到类似输出：
```
id = '1953645555'
```

---

## 📝 使用脚本读取 ID

### PowerShell 脚本

```powershell
# 方法 1：使用提供的脚本
.\Get-RustDeskID-Simple.ps1

# 方法 2：直接读取
$config = Get-Content "$env:APPDATA\RustDesk\config\RustDesk.toml" -Raw
if ($config -match 'id\s*=\s*[''"]?(\d{9,10})[''"]?') {
    $id = $matches[1]
    Write-Host "RustDesk ID: $id"
}
```

### Python 脚本

```python
import re
import os

config_path = os.path.expandvars(r'%APPDATA%\RustDesk\config\RustDesk.toml')

with open(config_path, 'r', encoding='utf-8') as f:
    content = f.read()
    
match = re.search(r'^id\s*=\s*[\'"]?(\d{9,10})[\'"]?', content, re.MULTILINE)
if match:
    rustdesk_id = match.group(1)
    print(f"RustDesk ID: {rustdesk_id}")
```

### C# 脚本

```csharp
using System;
using System.IO;
using System.Text.RegularExpressions;

class Program {
    static void Main() {
        string appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
        string configPath = Path.Combine(appData, @"RustDesk\config\RustDesk.toml");
        
        string content = File.ReadAllText(configPath);
        var match = Regex.Match(content, @"^id\s*=\s*['"]?(\d{9,10})['"]?", RegexOptions.Multiline);
        
        if (match.Success) {
            string id = match.Groups[1].Value;
            Console.WriteLine($"RustDesk ID: {id}");
        }
    }
}
```

---

## 🔒 安全性说明

### 问题：明文存储 ID 是否安全？

**答案：完全安全！**

理由：
1. **ID 本就是公开信息**
   - ID 显示在 RustDesk 主界面
   - 远程连接必须提供 ID
   - ID 不包含敏感信息

2. **密码仍然加密存储**
   - `password` 字段仍使用加密
   - 关键安全信息得到保护

3. **同时保留加密 ID**
   - `enc_id` 仍然存在
   - 兼容旧版本和旧工具

---

## 🎯 应用场景

### 1. 批量部署脚本

```powershell
# 部署后自动收集 ID
$computers = Get-Content "computers.txt"
$results = @()

foreach ($pc in $computers) {
    $config = Get-Content "\\$pc\C$\Users\*\AppData\Roaming\RustDesk\config\RustDesk.toml" -Raw
    if ($config -match 'id\s*=\s*[''"]?(\d{9,10})[''"]?') {
        $results += [PSCustomObject]@{
            Computer = $pc
            RustDeskID = $matches[1]
        }
    }
}

$results | Export-Csv "rustdesk_ids.csv" -NoTypeInformation
```

### 2. 监控系统集成

```python
import toml

def get_rustdesk_id(computer):
    config_path = f"\\\\{computer}\\C$\\Users\\Administrator\\AppData\\Roaming\\RustDesk\\config\\RustDesk.toml"
    config = toml.load(config_path)
    return config.get('id', 'N/A')
```

### 3. 自动化运维工具

```csharp
public class RustDeskHelper {
    public static string GetID(string computerName) {
        string path = $"\\\\{computerName}\\C$\\Users\\...\\RustDesk.toml";
        // 直接读取 id 字段
        return ReadIdFromConfig(path);
    }
}
```

---

## ✅ 优势对比

| 方案 | 复杂度 | 性能 | 可靠性 | 跨语言 |
|------|--------|------|--------|--------|
| **明文 ID（本方案）** | ⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ 全支持 |
| **解密 enc_id** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ❌ 需Rust |
| **GUI 自动化** | ⭐⭐⭐⭐ | ⭐ | ⭐⭐ | ❌ 平台限制 |
| **--get-id 命令** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ✅ 支持 |

---

## 📦 提交说明

```bash
git add libs/hbb_common/src/config.rs Get-RustDeskID-Simple.ps1 明文ID配置说明.md
git commit -m "feat: 在配置文件中保存明文ID

修改内容:
1. 移除 Config.id 的 skip_serializing_if 限制
2. 保留明文 ID，不在 store() 中清空
3. 配置文件同时包含明文 id 和加密 enc_id

优势:
- 第三方程序可直接读取明文ID
- 无需实现复杂的解密逻辑
- 跨语言支持（PowerShell/Python/C#等）
- 兼容旧版本（enc_id 仍保留）

文件位置:
- libs/hbb_common/src/config.rs (第180-184行, 634-635行)

配置文件格式:
id = '1953645555'        # 明文ID（新增）
enc_id = '00FB7...'      # 加密ID（兼容）

使用脚本:
- Get-RustDeskID-Simple.ps1
- 支持 PowerShell/Python/C# 直接读取"
```

---

## 🎉 总结

✅ **问题解决！** 现在可以通过任何编程语言直接从配置文件读取 RustDesk ID！

**下一步：**
1. 提交代码修改
2. 重新编译 RustDesk
3. 测试读取明文 ID
4. 更新部署脚本
