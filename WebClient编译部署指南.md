# RustDesk Web Client 编译部署指南

## 🎯 概述

本指南提供了多种方式来编译和部署 RustDesk Web Client：
- ✅ GitHub Actions 自动构建
- ✅ 本地编译（Windows / Linux / macOS）
- ✅ GitHub Pages 自动部署

---

## 🚀 方法 1：GitHub Actions 自动构建（推荐）

### 配置文件

项目已包含两个 GitHub Actions 工作流：

1. **`.github/workflows/build-webclient.yml`** - 仅编译
2. **`.github/workflows/deploy-webclient.yml`** - 编译并部署到 GitHub Pages

### 使用步骤

#### A. 仅编译（不部署）

```bash
# 1. 推送代码到 GitHub
git push origin main

# 2. GitHub Actions 自动触发编译
# 访问: https://github.com/你的用户名/rustdesk/actions

# 3. 下载编译产物
# 在 Actions 页面下载 rustdesk-webclient.tar.gz
```

**触发条件：**
- 推送到 `main` 分支
- 修改 `flutter/**` 目录下的文件
- 手动触发（Actions 页面点击 "Run workflow"）

**产出文件：**
- `rustdesk-webclient.tar.gz` - 完整部署包
- `rustdesk-webclient-files` - 构建文件目录

---

#### B. 编译并部署到 GitHub Pages

```bash
# 1. 启用 GitHub Pages
# 访问: https://github.com/你的用户名/rustdesk/settings/pages
# Source: GitHub Actions

# 2. 推送代码
git push origin main

# 3. 自动部署完成后访问
# https://你的用户名.github.io/rustdesk
```

**部署 URL：**
```
https://你的用户名.github.io/rustdesk
```

**自动连接示例：**
```
https://你的用户名.github.io/rustdesk/#/?id=123456789&autoconnect=true
```

---

### GitHub Actions 工作流详解

#### build-webclient.yml

```yaml
# 仅编译，不部署
name: Build RustDesk Web Client

on:
  push:
    branches: [main]
    paths: ['flutter/**']
  workflow_dispatch:

jobs:
  build-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.6'
      - run: flutter pub get
        working-directory: ./flutter
      - run: flutter build web --release
        working-directory: ./flutter
      - uses: actions/upload-artifact@v4
        with:
          name: rustdesk-webclient
          path: flutter/rustdesk-webclient.tar.gz
```

#### deploy-webclient.yml

```yaml
# 编译并部署到 GitHub Pages
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    # 编译步骤...
  
  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/deploy-pages@v4
```

---

## 💻 方法 2：本地编译

### Windows

#### 使用编译脚本（推荐）

```cmd
# 双击运行
build-webclient.bat

# 或命令行运行
build-webclient.bat
```

#### 手动编译

```cmd
cd flutter
flutter clean
flutter pub get
flutter build web --release --web-renderer canvaskit --base-href "/"
```

---

### Linux / macOS

#### 使用编译脚本（推荐）

```bash
# 添加执行权限
chmod +x build-webclient.sh

# 运行
./build-webclient.sh
```

#### 手动编译

```bash
cd flutter
flutter clean
flutter pub get
flutter build web --release \
  --web-renderer canvaskit \
  --base-href "/" \
  --dart-define=FLUTTER_WEB_USE_SKIA=true
```

---

### 编译参数说明

| 参数 | 说明 |
|------|------|
| `--release` | 发布模式（优化性能） |
| `--web-renderer canvaskit` | 使用 CanvasKit 渲染器 |
| `--base-href "/"` | 设置基础路径 |
| `--dart-define=FLUTTER_WEB_USE_SKIA=true` | 启用 Skia 渲染 |

---

## 📦 编译输出

### 输出目录

```
flutter/build/web/
├── index.html                    # 主页面
├── main.dart.js                  # 编译后的代码
├── flutter.js                    # Flutter 引擎
├── canvaskit/                    # CanvasKit 库
│   ├── canvaskit.wasm
│   └── canvaskit.js
├── assets/                       # 资源文件
│   ├── AssetManifest.json
│   ├── FontManifest.json
│   └── fonts/
├── icons/                        # 图标
└── favicon.png                   # 网站图标
```

### 部署包

```
flutter/build/rustdesk-webclient.tar.gz
```

---

## 🌐 部署方法

### 方法 1：Nginx

```nginx
server {
    listen 80;
    server_name rustdesk.yourcompany.com;
    
    # 重定向到 HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name rustdesk.yourcompany.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    root /var/www/rustdesk-web;
    index index.html;
    
    # 支持 HTML5 History API
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # 启用 gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript application/wasm;
    
    # 缓存静态资源
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|wasm)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

**部署命令：**
```bash
# 解压
tar -xzf rustdesk-webclient.tar.gz -C /var/www/rustdesk-web/

# 设置权限
chown -R www-data:www-data /var/www/rustdesk-web/
chmod -R 755 /var/www/rustdesk-web/

# 重启 Nginx
systemctl restart nginx
```

---

### 方法 2：Apache

```apache
<VirtualHost *:80>
    ServerName rustdesk.yourcompany.com
    Redirect permanent / https://rustdesk.yourcompany.com/
</VirtualHost>

<VirtualHost *:443>
    ServerName rustdesk.yourcompany.com
    
    DocumentRoot /var/www/rustdesk-web
    
    SSLEngine on
    SSLCertificateFile /path/to/cert.pem
    SSLCertificateKeyFile /path/to/key.pem
    
    <Directory /var/www/rustdesk-web>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
        
        # 支持 HTML5 History API
        RewriteEngine On
        RewriteBase /
        RewriteRule ^index\.html$ - [L]
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule . /index.html [L]
    </Directory>
    
    # 启用压缩
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/json application/wasm
    </IfModule>
    
    # 缓存控制
    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType image/x-icon "access plus 1 year"
        ExpiresByType image/gif "access plus 1 year"
        ExpiresByType image/png "access plus 1 year"
        ExpiresByType image/jpg "access plus 1 year"
        ExpiresByType image/jpeg "access plus 1 year"
        ExpiresByType text/css "access plus 1 year"
        ExpiresByType text/javascript "access plus 1 year"
        ExpiresByType application/javascript "access plus 1 year"
        ExpiresByType application/wasm "access plus 1 year"
    </IfModule>
</VirtualHost>
```

---

### 方法 3：Docker

**Dockerfile：**
```dockerfile
FROM nginx:alpine

# 复制编译好的文件
COPY flutter/build/web /usr/share/nginx/html

# 自定义 Nginx 配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

**nginx.conf：**
```nginx
server {
    listen 80;
    server_name localhost;
    
    root /usr/share/nginx/html;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript application/wasm;
}
```

**构建和运行：**
```bash
# 构建镜像
docker build -t rustdesk-webclient .

# 运行容器
docker run -d -p 8080:80 --name rustdesk-web rustdesk-webclient

# 访问
http://localhost:8080
```

---

### 方法 4：GitHub Pages（已集成）

**自动部署：**
- 推送代码到 `main` 分支
- GitHub Actions 自动编译和部署
- 访问: `https://你的用户名.github.io/rustdesk`

**手动部署：**
```bash
# 1. 编译
flutter build web --release --base-href "/rustdesk/"

# 2. 创建 gh-pages 分支
git checkout --orphan gh-pages

# 3. 清空工作区
git rm -rf .

# 4. 复制构建文件
cp -r flutter/build/web/* .

# 5. 提交并推送
git add .
git commit -m "Deploy to GitHub Pages"
git push origin gh-pages

# 6. 在 GitHub 仓库设置中启用 Pages
# Settings -> Pages -> Source: gh-pages branch
```

---

## 🧪 本地测试

### Python SimpleHTTPServer

```bash
cd flutter/build/web
python3 -m http.server 8080

# 或 Python 2
python -m SimpleHTTPServer 8080

# 访问: http://localhost:8080
```

### Node.js http-server

```bash
# 安装
npm install -g http-server

# 运行
cd flutter/build/web
http-server -p 8080

# 访问: http://localhost:8080
```

### PHP 内置服务器

```bash
cd flutter/build/web
php -S localhost:8080

# 访问: http://localhost:8080
```

---

## 🔧 自定义配置

### 修改基础路径

如果部署在子目录下：

```bash
flutter build web --release --base-href "/subfolder/"
```

**Nginx 配置：**
```nginx
location /subfolder/ {
    alias /var/www/rustdesk-web/;
    try_files $uri $uri/ /subfolder/index.html;
}
```

---

### 自定义标题和图标

**修改 `flutter/web/index.html`：**
```html
<head>
  <title>Your Company RustDesk</title>
  <link rel="icon" type="image/png" href="favicon.png"/>
</head>
```

**替换图标：**
```bash
# 替换 flutter/web/favicon.png
cp your-icon.png flutter/web/favicon.png

# 重新编译
flutter build web --release
```

---

## 📊 性能优化

### 启用缓存

**Nginx：**
```nginx
location ~* \.(js|css|png|jpg|jpeg|gif|ico|wasm)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### 启用压缩

**Nginx：**
```nginx
gzip on;
gzip_comp_level 6;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript application/wasm;
gzip_min_length 1000;
```

### CDN 加速

使用 Cloudflare 或其他 CDN 服务加速静态资源加载。

---

## 🐛 故障排查

### 问题 1：编译失败

**检查 Flutter 版本：**
```bash
flutter --version
# 推荐: 3.24.0+ (需要 Dart SDK 3.5.0+)
```

**清理缓存：**
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

---

### 问题 2：白屏或加载失败

**检查控制台错误：**
- 按 F12 打开开发者工具
- 查看 Console 和 Network 标签

**常见原因：**
- `base-href` 设置不正确
- CORS 问题
- 资源路径错误

**解决方案：**
```bash
# 使用正确的 base-href
flutter build web --release --base-href "/"

# 检查 Web 服务器配置
```

---

### 问题 3：无法自动连接

**检查 URL 格式：**
```
正确: https://yourserver.com/#/?id=123&autoconnect=true
错误: https://yourserver.com/?id=123&autoconnect=true
```

**检查日志：**
- 按 F12 打开控制台
- 查找 `[WebAutoConnect]` 日志

---

## 📚 相关文档

| 文档 | 说明 |
|------|------|
| **WebClient自动连接功能说明.md** | 自动连接功能详解 |
| **WebClient自动连接示例.html** | 可视化 URL 生成器 |
| **WebClient自动连接快速开始.md** | 快速上手指南 |

---

## ✅ 检查清单

### 编译前

- [ ] Flutter 已安装（3.24.0+，Dart SDK 3.5.0+）
- [ ] 依赖已获取（`flutter pub get`）
- [ ] 代码已提交

### 编译后

- [ ] `build/web` 目录存在
- [ ] 文件大小合理（通常 10-30 MB）
- [ ] 本地测试通过

### 部署前

- [ ] 域名已配置
- [ ] SSL 证书已安装（推荐）
- [ ] 服务器配置正确

### 部署后

- [ ] 网站可访问
- [ ] 自动连接功能正常
- [ ] 控制台无错误

---

## 🎯 总结

| 方法 | 适用场景 | 难度 |
|------|---------|------|
| **GitHub Actions** | 自动化构建，推荐！ | ⭐ |
| **本地编译** | 快速测试，离线环境 | ⭐⭐ |
| **GitHub Pages** | 免费托管，快速部署 | ⭐ |
| **自建服务器** | 生产环境，完全控制 | ⭐⭐⭐ |
| **Docker** | 容器化部署，易扩展 | ⭐⭐⭐ |

---

**版本：** v2.2.0  
**最后更新：** 2024-12-01  
**文档维护：** xiehan12
