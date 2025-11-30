# RustDesk Web Client 自动连接功能

## 🎯 功能概述

RustDesk Web Client 现在支持通过 URL 参数实现：
- ✅ 自动填充远程设备 ID
- ✅ 自动填充连接密码
- ✅ 自动发起连接（可选）
- ✅ 强制中继模式（可选）

这大大简化了 Web 端的远程连接流程，特别适合批量部署、客服支持和快速连接场景。

---

## 📝 修改内容

### 新增文件

**1. `flutter/lib/mobile/pages/web_home_page_enhanced.dart`**
- 增强版 Web 主页
- 自动解析 URL 参数
- 自动填充 ID 和密码
- 可选自动连接

**2. `WebClient自动连接示例.html`**
- 交互式示例页面
- URL 生成器
- 参数说明

**3. `WebClient自动连接功能说明.md`**
- 完整功能文档
- 使用指南
- 安全建议

### 修改文件

**`flutter/lib/main.dart`**
```dart
// 添加导入
import 'mobile/pages/web_home_page_enhanced.dart';

// 使用增强版主页
home: isWeb
    ? WebHomePageEnhanced()
    : HomePage(),
```

---

## 🚀 使用方法

### 基础用法

#### 1. 仅预填充 ID

```
https://yourserver.com/#/?id=123456789
```

**效果：**
- ✅ ID 输入框自动填充为 `123456789`
- ✅ 显示 "ID pre-filled" 提示
- ❌ 不会自动连接，需要用户点击连接按钮

---

#### 2. 预填充 ID 和密码

```
https://yourserver.com/#/?id=123456789&password=yourpassword
```

**效果：**
- ✅ ID 自动填充
- ✅ 密码自动保存（内部处理，不显示在界面）
- ✅ 用户点击连接时自动使用该密码
- ❌ 不会自动连接

---

#### 3. 自动连接（推荐）

```
https://yourserver.com/#/?id=123456789&password=yourpassword&autoconnect=true
```

**效果：**
- ✅ ID 自动填充
- ✅ 密码自动保存
- ✅ **自动发起连接！**
- ✅ 显示 "Auto-connecting..." 提示
- ⏱️ 页面加载后约 0.8 秒自动连接

---

#### 4. 强制中继模式

```
https://yourserver.com/#/?id=123456789&relay=true&autoconnect=true
```

**效果：**
- ✅ 自动连接
- ✅ 强制使用中继服务器（不尝试 P2P 直连）
- 🚀 适合网络受限环境

---

## 📖 参数详解

### URL 格式

```
https://yourserver.com/#/?param1=value1&param2=value2&param3=value3
```

**注意：** 参数必须在 `#/?` 之后！

### 参数列表

| 参数名 | 类型 | 必需 | 说明 | 示例 |
|--------|------|------|------|------|
| `id` | String | ✅ | 远程设备 ID | `123456789` |
| `password` | String | ❌ | 连接密码 | `mypassword` |
| `pwd` | String | ❌ | 密码的简写形式 | `mypassword` |
| `autoconnect` | Boolean | ❌ | 是否自动连接 | `true` / `false` |
| `auto` | Boolean | ❌ | autoconnect 简写 | `true` / `false` |
| `relay` | Boolean | ❌ | 强制中继模式 | `true` / `false` |
| `forcerelay` | Boolean | ❌ | relay 的完整形式 | `true` / `false` |

### 参数别名

为了兼容性和便利性，部分参数提供了别名：

```
password = pwd
autoconnect = auto
relay = forcerelay
```

---

## 🎨 使用场景

### 场景 1：客服支持链接

**需求：** 客服人员需要快速连接客户设备

**解决方案：**
```html
<!-- 生成客户专属连接链接 -->
<a href="https://support.yourcompany.com/#/?id=123456789&password=temp123&autoconnect=true" 
   target="_blank">
   点击远程协助
</a>
```

**优势：**
- ✅ 客户点击即可自动连接
- ✅ 无需手动输入 ID 和密码
- ✅ 减少操作失误
- ✅ 提升客户体验

---

### 场景 2：批量设备管理

**需求：** IT 管理员需要管理多台设备

**HTML 页面：**
```html
<!DOCTYPE html>
<html>
<head>
    <title>设备管理面板</title>
</head>
<body>
    <h1>设备管理面板</h1>
    <table>
        <tr>
            <th>设备名称</th>
            <th>设备 ID</th>
            <th>操作</th>
        </tr>
        <tr>
            <td>服务器 A</td>
            <td>123456789</td>
            <td>
                <a href="https://admin.yourcompany.com/#/?id=123456789&password=adminpass&autoconnect=true" 
                   target="_blank">
                   立即连接
                </a>
            </td>
        </tr>
        <tr>
            <td>服务器 B</td>
            <td>987654321</td>
            <td>
                <a href="https://admin.yourcompany.com/#/?id=987654321&password=adminpass&autoconnect=true" 
                   target="_blank">
                   立即连接
                </a>
            </td>
        </tr>
    </table>
</body>
</html>
```

---

### 场景 3：动态生成连接链接

**JavaScript 示例：**
```javascript
function generateConnectionLink(deviceId, password) {
    const baseUrl = 'https://yourserver.com';
    const params = [
        `id=${encodeURIComponent(deviceId)}`,
        `password=${encodeURIComponent(password)}`,
        'autoconnect=true'
    ];
    
    return `${baseUrl}/#/?${params.join('&')}`;
}

// 使用
const link = generateConnectionLink('123456789', 'mypassword');
window.open(link, '_blank');
```

---

### 场景 4：二维码扫码连接

**生成二维码：**
```javascript
const QRCode = require('qrcode');

const connectionUrl = 'https://yourserver.com/#/?id=123456789&password=temp123&autoconnect=true';

QRCode.toDataURL(connectionUrl, (err, url) => {
    // url 是二维码图片的 Data URL
    document.getElementById('qrcode').src = url;
});
```

**使用流程：**
1. 客服生成客户专属二维码
2. 客户手机扫码
3. 自动打开 Web Client 并连接

---

## 🔒 安全建议

### ⚠️ 密码安全

**问题：** 密码以明文形式出现在 URL 中

**风险：**
- 🚨 浏览器历史记录会保存完整 URL
- 🚨 服务器日志可能记录 URL
- 🚨 屏幕截图可能暴露密码
- 🚨 通过社交工程攻击获取链接

### ✅ 安全最佳实践

#### 1. 使用临时密码

```bash
# 服务端为每次连接生成临时密码
# 密码有效期：1小时
# 使用后自动失效
```

#### 2. 不在 URL 中包含密码

```
# 推荐：仅预填充 ID
https://yourserver.com/#/?id=123456789

# 让用户手动输入密码
```

#### 3. 使用连接令牌（Token）

```
# 替代密码的更安全方式
https://yourserver.com/#/?id=123456789&token=a1b2c3d4e5f6

# Token 特点：
# - 单次有效
# - 时间限制
# - 可追踪使用
```

#### 4. HTTPS 传输

```
✅ 使用: https://yourserver.com
❌ 避免: http://yourserver.com

# HTTPS 可以防止中间人攻击
```

#### 5. 内网环境使用

```
# 最安全的方式：仅在内网环境使用
https://192.168.1.100/#/?id=123456789&password=xxx&autoconnect=true

# 外网不可访问，安全性最高
```

---

## 🛠️ 开发指南

### 代码结构

```
flutter/lib/mobile/pages/
├── web_home_page_enhanced.dart   # 增强版主页（新增）
├── home_page.dart                # 原主页（保留）
└── connection_page.dart          # 连接页面（复用）
```

### 关键函数

#### 1. URL 参数解析

```dart
void _parseUrlParameters() {
  try {
    final uri = Uri.parse(html.window.location.href);
    
    // 解析 hash 后的参数
    String? queryString;
    if (uri.fragment.isNotEmpty) {
      final fragment = uri.fragment;
      if (fragment.contains('?')) {
        queryString = fragment.split('?').last;
      }
    }
    
    // 解析参数
    final params = Uri.splitQueryString(queryString);
    
    _autoId = params['id'];
    _autoPassword = params['password'] ?? params['pwd'];
    _autoConnect = params['autoconnect']?.toLowerCase() == 'true';
    
  } catch (e) {
    debugPrint('[WebAutoConnect] Error: $e');
  }
}
```

#### 2. 自动填充

```dart
Future<void> _executeAutoFill() async {
  // 等待控制器初始化
  await Future.delayed(Duration(milliseconds: 500));
  
  // 设置 ID
  if (Get.isRegistered<IDTextEditingController>()) {
    final idController = Get.find<IDTextEditingController>();
    idController.id = _autoId!;
  }
  
  // 自动连接
  if (_autoConnect) {
    await Future.delayed(Duration(milliseconds: 300));
    connect(context, _autoId!, password: _autoPassword);
  }
}
```

### 调试日志

启用详细日志：
```dart
debugPrint('[WebAutoConnect] Parsed parameters:');
debugPrint('  - ID: ${_autoId ?? "(empty)"}');
debugPrint('  - Password: ${_autoPassword != null ? "***" : "(empty)"}');
debugPrint('  - AutoConnect: $_autoConnect');
```

---

## 📊 功能对比

| 功能 | 原版本 | 增强版本 | 改进 |
|------|--------|---------|------|
| **手动输入 ID** | ✅ | ✅ | - |
| **URL 预填充 ID** | ❌ | ✅ | ⬆️ 100% |
| **URL 填充密码** | ❌ | ✅ | ⬆️ 100% |
| **自动连接** | ❌ | ✅ | ⬆️ 100% |
| **强制中继** | ❌ | ✅ | ⬆️ 100% |
| **视觉提示** | ❌ | ✅ | ⬆️ 用户体验 |

---

## 🧪 测试步骤

### 本地测试

#### 1. 编译 Flutter Web

```bash
cd flutter
flutter build web --release
```

#### 2. 启动本地服务器

```bash
cd build/web
python -m http.server 8080
```

#### 3. 测试 URL

```
# 测试 1：预填充 ID
http://localhost:8080/#/?id=123456789

# 测试 2：预填充 ID 和密码
http://localhost:8080/#/?id=123456789&password=test123

# 测试 3：自动连接
http://localhost:8080/#/?id=123456789&password=test123&autoconnect=true

# 测试 4：强制中继
http://localhost:8080/#/?id=123456789&relay=true&autoconnect=true
```

---

### 部署测试

#### 1. 部署到服务器

```bash
# 将 build/web 目录内容上传到服务器
scp -r build/web/* user@yourserver.com:/var/www/rustdesk/
```

#### 2. 配置 Nginx

```nginx
server {
    listen 443 ssl http2;
    server_name yourserver.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    root /var/www/rustdesk;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

#### 3. 测试生产环境

```
https://yourserver.com/#/?id=123456789&autoconnect=true
```

---

## 🐛 故障排查

### 问题 1：参数未生效

**症状：** URL 中有参数，但 ID 未填充

**检查步骤：**
```javascript
// 1. 检查 URL 格式
console.log(window.location.href);
// 应该是: https://xxx.com/#/?id=xxx

// 2. 检查 hash 部分
console.log(window.location.hash);
// 应该是: #/?id=xxx

// 3. 检查参数解析
const uri = new URL(window.location.href);
console.log(uri.searchParams.get('id'));
```

**解决方案：**
- ✅ 确保参数在 `#/?` 之后
- ✅ 确保使用 `&` 分隔多个参数
- ✅ 确保参数正确 URL 编码

---

### 问题 2：自动连接失败

**症状：** autoconnect=true 但没有自动连接

**检查步骤：**
```dart
// 1. 检查日志
// 应该看到:
[WebAutoConnect] Starting auto-fill process...
[WebAutoConnect] ID set to: xxx
[WebAutoConnect] Initiating connection...

// 2. 检查 ID 有效性
// ID 必须是有效的设备 ID

// 3. 检查网络连接
// 确保能连接到 RustDesk 服务器
```

---

### 问题 3：密码未自动填充

**症状：** password 参数有值，但仍提示输入密码

**说明：**
- 密码是自动传递给连接函数的
- 不会在界面上显示（安全考虑）
- 如果密码错误，会在连接时提示

**验证方法：**
```dart
// 在 connect() 调用前打印
debugPrint('Connecting with password: ${password != null ? "***" : "none"}');
```

---

## 📚 示例代码

### 示例 1：客服支持页面

```html
<!DOCTYPE html>
<html>
<head>
    <title>远程协助</title>
</head>
<body>
    <h1>欢迎使用远程协助</h1>
    <p>您的客服专员将通过此链接为您提供支持</p>
    
    <script>
        // 从服务器获取临时连接信息
        fetch('/api/get-support-link')
            .then(r => r.json())
            .then(data => {
                const link = `https://support.company.com/#/?id=${data.id}&password=${data.tempPassword}&autoconnect=true`;
                
                // 3 秒后自动跳转
                setTimeout(() => {
                    window.location.href = link;
                }, 3000);
                
                document.body.innerHTML += `
                    <p>正在连接客服... (${data.id})</p>
                    <p>如果没有自动跳转，<a href="${link}">点击这里</a></p>
                `;
            });
    </script>
</body>
</html>
```

---

### 示例 2：设备监控面板

```html
<!DOCTYPE html>
<html>
<head>
    <title>设备监控</title>
    <style>
        .device-card {
            border: 1px solid #ddd;
            padding: 15px;
            margin: 10px;
            border-radius: 8px;
        }
        .device-card.online {
            border-color: green;
        }
        .device-card.offline {
            border-color: red;
        }
        button {
            padding: 10px 20px;
            background: #007bff;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <h1>设备监控面板</h1>
    <div id="devices"></div>
    
    <script>
        const devices = [
            { id: '123456789', name: '生产服务器 A', status: 'online', password: 'prod123' },
            { id: '987654321', name: '测试服务器 B', status: 'online', password: 'test123' },
            { id: '555666777', name: '开发服务器 C', status: 'offline', password: 'dev123' }
        ];
        
        const container = document.getElementById('devices');
        
        devices.forEach(device => {
            const card = document.createElement('div');
            card.className = `device-card ${device.status}`;
            card.innerHTML = `
                <h3>${device.name}</h3>
                <p>ID: ${device.id}</p>
                <p>状态: <span style="color: ${device.status === 'online' ? 'green' : 'red'}">${device.status}</span></p>
                <button onclick="connectDevice('${device.id}', '${device.password}')" ${device.status === 'offline' ? 'disabled' : ''}>
                    快速连接
                </button>
            `;
            container.appendChild(card);
        });
        
        function connectDevice(id, password) {
            const link = `https://admin.company.com/#/?id=${id}&password=${password}&autoconnect=true`;
            window.open(link, '_blank');
        }
    </script>
</body>
</html>
```

---

## 📦 完整文件清单

### 新增文件

```
e:\GitHub\rustdesk\
├── flutter\lib\mobile\pages\
│   └── web_home_page_enhanced.dart          # 增强版 Web 主页
├── WebClient自动连接示例.html                 # 交互式示例页面
└── WebClient自动连接功能说明.md               # 功能文档
```

### 修改文件

```
e:\GitHub\rustdesk\
└── flutter\lib\
    └── main.dart                            # 使用增强版主页
```

---

## ✅ 提交说明

```bash
git add flutter/lib/mobile/pages/web_home_page_enhanced.dart
git add flutter/lib/main.dart
git add WebClient自动连接示例.html
git add WebClient自动连接功能说明.md

git commit -m "feat: Web Client 支持 URL 参数自动连接" \
           -m "新增功能:" \
           -m "- 通过 URL 参数自动填充 ID 和密码" \
           -m "- 支持自动连接 (autoconnect=true)" \
           -m "- 支持强制中继模式 (relay=true)" \
           -m "- 添加视觉提示指示器" \
           -m "" \
           -m "使用示例:" \
           -m "https://yourserver.com/#/?id=123456789&password=xxx&autoconnect=true"

git push origin main
```

---

## 🎯 总结

### 核心优势

| 优势 | 说明 |
|------|------|
| ✅ **零配置连接** | URL 点击即连接 |
| ✅ **批量部署友好** | 适合IT管理场景 |
| ✅ **客服支持优化** | 提升客户体验 |
| ✅ **向后兼容** | 不影响现有功能 |
| ✅ **安全可控** | 支持临时密码 |

---

**版本：** v2.2.0  
**最后更新：** 2024-12-01  
**文档维护：** xiehan12
