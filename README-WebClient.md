# 🌐 RustDesk Web Client 快速开始

## 🚀 三种使用方式

### 1️⃣ GitHub Actions 自动构建（推荐）

```bash
# 直接推送到 GitHub，自动编译
git push origin main

# 访问 Actions 页面下载构建产物
# https://github.com/你的用户名/rustdesk/actions
```

**自动触发条件：**
- ✅ 推送到 `main` 分支
- ✅ 修改 `flutter/**` 文件
- ✅ 手动触发（Actions 页面）

---

### 2️⃣ 本地一键编译

**Windows:**
```cmd
build-webclient.bat
```

**Linux/macOS:**
```bash
chmod +x build-webclient.sh
./build-webclient.sh
```

**输出：**
- `flutter/build/web/` - Web 文件目录
- `flutter/build/rustdesk-webclient.tar.gz` - 部署包

---

### 3️⃣ GitHub Pages 部署

```bash
# 1. 启用 GitHub Pages
# Settings -> Pages -> Source: GitHub Actions

# 2. 推送代码，自动部署
git push origin main

# 3. 访问
# https://你的用户名.github.io/rustdesk
```

---

## 📝 快速测试

```bash
cd flutter/build/web
python3 -m http.server 8080

# 访问: http://localhost:8080
```

---

## 🔗 自动连接示例

```
# 基础连接
https://yourserver.com/#/?id=123456789

# 自动连接
https://yourserver.com/#/?id=123456789&password=yourpass&autoconnect=true
```

---

## 📚 完整文档

- **WebClient编译部署指南.md** - 详细编译和部署说明
- **WebClient自动连接功能说明.md** - 自动连接功能
- **WebClient自动连接示例.html** - URL 生成工具

---

## ⚙️ 编译选项

```bash
flutter build web --release \
  --web-renderer canvaskit \
  --base-href "/" \
  --dart-define=FLUTTER_WEB_USE_SKIA=true
```

---

## 🎯 快速部署

### Nginx

```bash
# 解压
tar -xzf rustdesk-webclient.tar.gz -C /var/www/rustdesk/

# 配置 Nginx
server {
    listen 443 ssl;
    server_name rustdesk.yourcompany.com;
    root /var/www/rustdesk;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### Docker

```bash
docker build -t rustdesk-web .
docker run -d -p 8080:80 rustdesk-web
```

---

## ✅ GitHub Actions 工作流

### build-webclient.yml
- ✅ 仅编译 Web Client
- ✅ 上传构建产物
- ✅ 创建 tar.gz 部署包

### deploy-webclient.yml
- ✅ 编译 Web Client
- ✅ 自动部署到 GitHub Pages
- ✅ 支持自定义域名

---

## 🐛 故障排查

```bash
# 清理缓存
flutter clean
flutter pub cache repair

# 重新编译
flutter pub get
flutter build web --release
```

---

## 📊 文件大小

| 组件 | 大小 |
|------|------|
| 总计 | ~15-25 MB |
| main.dart.js | ~3-5 MB |
| canvaskit.wasm | ~8-10 MB |
| 其他资源 | ~2-5 MB |

---

## 🎉 完成！

现在您可以：
- ✅ 在 GitHub 上自动构建
- ✅ 本地快速编译
- ✅ 部署到 GitHub Pages
- ✅ 使用自动连接功能

**需要帮助？** 查看 `WebClient编译部署指南.md`
