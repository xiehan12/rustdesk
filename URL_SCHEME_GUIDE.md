# RustDesk URL Scheme 完整指南

## 📋 概述

RustDesk 支持通过 URL Scheme 从网页、邮件或其他应用程序直接拉起连接。

**URL Scheme 格式：** `rustdesk://`

---

## 🚀 基本格式

```
rustdesk://<模式>/<远程ID>?password=<密码>&<其他参数>
```

### 参数说明

| 部分 | 说明 | 示例 |
|------|------|------|
| `rustdesk://` | 固定前缀 | - |
| `<模式>` | 连接模式 | `connect`, `file-transfer`, `port-forward` |
| `<远程ID>` | 目标设备 ID | `123456789` |
| `?password=` | 密码参数（可选） | `?password=mypass123` |
| `&relay=true` | 强制中继（可选） | - |

---

## 💡 完整示例

### 示例 1：连接远程桌面

```html
<!-- 不带密码 -->
<a href="rustdesk://connect/123456789">连接到服务器</a>

<!-- 带密码 -->
<a href="rustdesk://connect/123456789?password=mypassword123">连接到服务器（带密码）</a>

<!-- 强制使用中继 -->
<a href="rustdesk://connect/123456789?password=mypass&relay=true">连接到服务器（中继）</a>
```

### 示例 2：文件传输

```html
<a href="rustdesk://file-transfer/123456789?password=mypass123">打开文件传输</a>
```

### 示例 3：TCP 隧道

```html
<a href="rustdesk://port-forward/123456789?password=mypass123">打开 TCP 隧道</a>
```

### 示例 4：查看摄像头

```html
<a href="rustdesk://view-camera/123456789?password=mypass123">查看远程摄像头</a>
```

---

## 🌐 网页集成示例

### HTML 完整示例

```html
<!DOCTYPE html>
<html>
<head>
    <title>RustDesk 远程连接</title>
    <style>
        .connect-btn {
            padding: 10px 20px;
            background-color: #0078d4;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            display: inline-block;
            margin: 10px;
        }
        .connect-btn:hover {
            background-color: #005a9e;
        }
    </style>
</head>
<body>
    <h1>快速连接</h1>
    
    <!-- 基本连接 -->
    <a href="rustdesk://connect/123456789" class="connect-btn">
        连接到服务器 1
    </a>
    
    <!-- 带密码连接 -->
    <a href="rustdesk://connect/987654321?password=abc123" class="connect-btn">
        连接到服务器 2（带密码）
    </a>
    
    <!-- 文件传输 -->
    <a href="rustdesk://file-transfer/123456789?password=mypass" class="connect-btn">
        文件传输
    </a>
    
    <hr>
    
    <!-- 动态生成连接 -->
    <h2>自定义连接</h2>
    <form id="connectForm">
        <label>远程 ID: <input type="text" id="remoteId" placeholder="123456789" required></label><br>
        <label>密码: <input type="password" id="password" placeholder="可选"></label><br>
        <label>模式: 
            <select id="mode">
                <option value="connect">远程桌面</option>
                <option value="file-transfer">文件传输</option>
                <option value="port-forward">TCP隧道</option>
            </select>
        </label><br>
        <button type="submit">连接</button>
    </form>
    
    <script>
        document.getElementById('connectForm').onsubmit = function(e) {
            e.preventDefault();
            
            const id = document.getElementById('remoteId').value;
            const password = document.getElementById('password').value;
            const mode = document.getElementById('mode').value;
            
            let url = `rustdesk://${mode}/${id}`;
            if (password) {
                url += `?password=${encodeURIComponent(password)}`;
            }
            
            window.location.href = url;
        };
    </script>
</body>
</html>
```

---

## 🔐 JavaScript 调用

### 方式 1：直接跳转

```javascript
// 基本连接
window.location.href = 'rustdesk://connect/123456789';

// 带密码
window.location.href = 'rustdesk://connect/123456789?password=mypass123';
```

### 方式 2：使用函数封装

```javascript
function connectRustDesk(remoteId, password = '', mode = 'connect', options = {}) {
    let url = `rustdesk://${mode}/${remoteId}`;
    
    const params = [];
    if (password) {
        params.push(`password=${encodeURIComponent(password)}`);
    }
    if (options.relay) {
        params.push('relay=true');
    }
    
    if (params.length > 0) {
        url += '?' + params.join('&');
    }
    
    window.location.href = url;
}

// 使用示例
connectRustDesk('123456789', 'mypassword123');
connectRustDesk('987654321', 'abc123', 'file-transfer');
connectRustDesk('555555555', 'pass', 'connect', { relay: true });
```

### 方式 3：按钮点击触发

```html
<button onclick="connectRustDesk('123456789', 'mypass123')">
    连接到服务器
</button>

<script>
function connectRustDesk(id, password) {
    const url = `rustdesk://connect/${id}${password ? '?password=' + password : ''}`;
    window.location.href = url;
}
</script>
```

---

## 📱 移动端支持

### iOS Safari

```html
<!-- iOS 会自动识别 URL Scheme -->
<a href="rustdesk://connect/123456789">连接</a>
```

### Android Chrome

```html
<!-- Android 同样支持 -->
<a href="rustdesk://connect/123456789">连接</a>
```

---

## 🔗 二维码支持

### 生成包含密码的二维码

```html
<!DOCTYPE html>
<html>
<head>
    <title>RustDesk 连接二维码</title>
    <script src="https://cdn.jsdelivr.net/npm/qrcodejs@1.0.0/qrcode.min.js"></script>
</head>
<body>
    <h1>扫码连接</h1>
    <div id="qrcode"></div>
    
    <script>
        // 生成包含 ID 和密码的二维码
        const remoteId = '123456789';
        const password = 'mypassword123';
        const url = `rustdesk://connect/${remoteId}?password=${password}`;
        
        new QRCode(document.getElementById('qrcode'), {
            text: url,
            width: 256,
            height: 256
        });
    </script>
</body>
</html>
```

---

## 📧 邮件集成

### HTML 邮件模板

```html
<html>
<body>
    <h2>远程连接邀请</h2>
    <p>点击下方链接快速连接到您的服务器：</p>
    
    <p>
        <a href="rustdesk://connect/123456789?password=temp_password_123" 
           style="background-color: #0078d4; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
            立即连接
        </a>
    </p>
    
    <p style="color: gray; font-size: 12px;">
        如果链接无法点击，请复制以下地址到浏览器：<br>
        <code>rustdesk://connect/123456789?password=temp_password_123</code>
    </p>
</body>
</html>
```

---

## 🔒 安全建议

### ⚠️ 密码安全问题

**URL 中的密码是明文的，可能会被：**
- 浏览器历史记录
- 服务器日志
- 网络监控工具

**安全最佳实践：**

### 1. 使用临时密码

```javascript
// 为每个连接生成临时密码
function generateTempPassword() {
    return Math.random().toString(36).substring(2, 15);
}

const tempPassword = generateTempPassword();
const url = `rustdesk://connect/123456789?password=${tempPassword}`;

// 将临时密码上报到服务器
fetch('/api/set-temp-password', {
    method: 'POST',
    body: JSON.stringify({ deviceId: '123456789', password: tempPassword })
});

// 然后打开连接
window.location.href = url;
```

### 2. 不在 URL 中包含密码

```html
<!-- 只传递 ID，让用户手动输入密码 -->
<a href="rustdesk://connect/123456789">连接到服务器</a>
```

### 3. 使用短期有效的令牌

```javascript
// 从服务器获取短期令牌
async function connectWithToken(remoteId) {
    const response = await fetch(`/api/get-temp-token/${remoteId}`);
    const { token } = await response.json();
    
    // 使用令牌连接（令牌 5 分钟后失效）
    window.location.href = `rustdesk://connect/${remoteId}?password=${token}`;
}
```

---

## 🎨 UI 组件示例

### React 组件

```jsx
import React, { useState } from 'react';

function RustDeskConnector() {
    const [remoteId, setRemoteId] = useState('');
    const [password, setPassword] = useState('');
    const [mode, setMode] = useState('connect');
    
    const handleConnect = () => {
        let url = `rustdesk://${mode}/${remoteId}`;
        if (password) {
            url += `?password=${encodeURIComponent(password)}`;
        }
        window.location.href = url;
    };
    
    return (
        <div className="rustdesk-connector">
            <h2>RustDesk 快速连接</h2>
            <input 
                type="text" 
                placeholder="远程 ID"
                value={remoteId}
                onChange={(e) => setRemoteId(e.target.value)}
            />
            <input 
                type="password" 
                placeholder="密码（可选）"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
            />
            <select value={mode} onChange={(e) => setMode(e.target.value)}>
                <option value="connect">远程桌面</option>
                <option value="file-transfer">文件传输</option>
                <option value="port-forward">TCP隧道</option>
            </select>
            <button onClick={handleConnect}>连接</button>
        </div>
    );
}

export default RustDeskConnector;
```

### Vue 组件

```vue
<template>
  <div class="rustdesk-connector">
    <h2>RustDesk 快速连接</h2>
    <input v-model="remoteId" type="text" placeholder="远程 ID" />
    <input v-model="password" type="password" placeholder="密码（可选）" />
    <select v-model="mode">
      <option value="connect">远程桌面</option>
      <option value="file-transfer">文件传输</option>
      <option value="port-forward">TCP隧道</option>
    </select>
    <button @click="handleConnect">连接</button>
  </div>
</template>

<script>
export default {
  data() {
    return {
      remoteId: '',
      password: '',
      mode: 'connect'
    };
  },
  methods: {
    handleConnect() {
      let url = `rustdesk://${this.mode}/${this.remoteId}`;
      if (this.password) {
        url += `?password=${encodeURIComponent(this.password)}`;
      }
      window.location.href = url;
    }
  }
};
</script>
```

---

## 🖥️ 系统注册（Windows）

RustDesk 安装时会自动注册 URL Scheme，但如果需要手动注册：

```batch
@echo off
:: 注册 rustdesk:// URL Scheme

set RUSTDESK_PATH="C:\Program Files\RustDesk\rustdesk.exe"

:: 注册到注册表
reg add "HKEY_CLASSES_ROOT\rustdesk" /ve /d "URL:RustDesk Protocol" /f
reg add "HKEY_CLASSES_ROOT\rustdesk" /v "URL Protocol" /d "" /f
reg add "HKEY_CLASSES_ROOT\rustdesk\shell\open\command" /ve /d "%RUSTDESK_PATH% \"%%1\"" /f

echo RustDesk URL Scheme 注册成功！
pause
```

---

## 🧪 测试工具

### 在线测试页面

```html
<!DOCTYPE html>
<html>
<head>
    <title>RustDesk URL Scheme 测试工具</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }
        .test-item { margin: 20px 0; padding: 15px; background: #f5f5f5; border-radius: 5px; }
        .test-link { color: #0078d4; text-decoration: none; font-weight: bold; }
        .test-link:hover { text-decoration: underline; }
        code { background: #e0e0e0; padding: 2px 6px; border-radius: 3px; }
    </style>
</head>
<body>
    <h1>🧪 RustDesk URL Scheme 测试工具</h1>
    
    <div class="test-item">
        <h3>测试 1：基本连接（无密码）</h3>
        <code>rustdesk://connect/123456789</code><br><br>
        <a href="rustdesk://connect/123456789" class="test-link">点击测试</a>
    </div>
    
    <div class="test-item">
        <h3>测试 2：带密码连接</h3>
        <code>rustdesk://connect/123456789?password=test123</code><br><br>
        <a href="rustdesk://connect/123456789?password=test123" class="test-link">点击测试</a>
    </div>
    
    <div class="test-item">
        <h3>测试 3：文件传输</h3>
        <code>rustdesk://file-transfer/123456789?password=test123</code><br><br>
        <a href="rustdesk://file-transfer/123456789?password=test123" class="test-link">点击测试</a>
    </div>
    
    <div class="test-item">
        <h3>测试 4：强制中继</h3>
        <code>rustdesk://connect/123456789?password=test123&relay=true</code><br><br>
        <a href="rustdesk://connect/123456789?password=test123&relay=true" class="test-link">点击测试</a>
    </div>
    
    <hr>
    
    <h2>自定义测试</h2>
    <form id="testForm">
        <label>远程 ID: <input type="text" id="testId" value="123456789"></label><br>
        <label>密码: <input type="text" id="testPass" value="test123"></label><br>
        <label>模式: 
            <select id="testMode">
                <option value="connect">connect</option>
                <option value="file-transfer">file-transfer</option>
                <option value="port-forward">port-forward</option>
            </select>
        </label><br>
        <label><input type="checkbox" id="testRelay"> 使用中继</label><br><br>
        <button type="submit">生成并测试</button>
    </form>
    
    <div id="result" style="margin-top: 20px;"></div>
    
    <script>
        document.getElementById('testForm').onsubmit = function(e) {
            e.preventDefault();
            
            const id = document.getElementById('testId').value;
            const pass = document.getElementById('testPass').value;
            const mode = document.getElementById('testMode').value;
            const relay = document.getElementById('testRelay').checked;
            
            let url = `rustdesk://${mode}/${id}`;
            const params = [];
            if (pass) params.push(`password=${encodeURIComponent(pass)}`);
            if (relay) params.push('relay=true');
            if (params.length) url += '?' + params.join('&');
            
            document.getElementById('result').innerHTML = `
                <div class="test-item">
                    <h3>生成的 URL:</h3>
                    <code>${url}</code><br><br>
                    <a href="${url}" class="test-link">点击测试此 URL</a>
                </div>
            `;
        };
    </script>
</body>
</html>
```

---

## 📋 URL 格式速查表

| 功能 | URL 格式 | 示例 |
|------|---------|------|
| 连接远程桌面 | `rustdesk://connect/<ID>` | `rustdesk://connect/123456789` |
| 带密码连接 | `rustdesk://connect/<ID>?password=<PWD>` | `rustdesk://connect/123456789?password=abc123` |
| 文件传输 | `rustdesk://file-transfer/<ID>?password=<PWD>` | `rustdesk://file-transfer/123456789?password=abc123` |
| TCP 隧道 | `rustdesk://port-forward/<ID>?password=<PWD>` | `rustdesk://port-forward/123456789?password=abc123` |
| 查看摄像头 | `rustdesk://view-camera/<ID>?password=<PWD>` | `rustdesk://view-camera/123456789?password=abc123` |
| 强制中继 | `rustdesk://connect/<ID>?password=<PWD>&relay=true` | `rustdesk://connect/123456789?password=abc&relay=true` |

---

## 🎉 总结

RustDesk 的 URL Scheme 功能强大且灵活，可以轻松集成到：
- ✅ 网页应用
- ✅ 内部管理系统
- ✅ 移动应用
- ✅ 邮件系统
- ✅ 二维码
- ✅ 快捷方式

**最佳实践：**
1. 避免在 URL 中包含长期密码
2. 使用临时密码或令牌
3. 结合服务器端验证
4. 考虑用户体验（自动连接 vs 手动确认）

现在你可以通过网页一键拉起 RustDesk 连接了！🚀
