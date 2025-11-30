# 🚀 GitHub Actions 使用说明

## ✅ 已修复的问题

### 问题 1：缺少 `flutter/web/` 目录
```
错误: Missing index.html.
原因: flutter/web/ 被 .gitignore 忽略
解决: 创建必需文件并修改 .gitignore
```

### 问题 2：自动触发构建
```
问题: 每次推送都自动触发构建
解决: 修改为仅手动触发
```

---

## 🎯 手动触发构建

### 方法 1：通过 GitHub 网页

1. **访问 Actions 页面**
   ```
   https://github.com/你的用户名/rustdesk/actions
   ```

2. **选择工作流**
   - 点击左侧 "Build RustDesk Web Client" (仅编译)
   - 或点击 "Deploy RustDesk Web Client to GitHub Pages" (编译+部署)

3. **运行工作流**
   - 点击右上角 "Run workflow" 按钮
   - 选择分支（默认 main）
   - 点击绿色 "Run workflow" 按钮

4. **查看进度**
   - 刷新页面查看构建状态
   - 点击工作流名称查看详细日志

5. **下载产物**
   - 构建完成后，滚动到页面底部
   - 在 "Artifacts" 部分下载 `rustdesk-webclient`

---

### 方法 2：通过 GitHub CLI

```bash
# 安装 GitHub CLI (如未安装)
# Windows: winget install GitHub.cli
# macOS: brew install gh
# Linux: 查看 https://cli.github.com/

# 登录
gh auth login

# 运行编译工作流
gh workflow run build-webclient.yml

# 运行部署工作流
gh workflow run deploy-webclient.yml

# 查看运行状态
gh run list --workflow=build-webclient.yml

# 查看详细日志
gh run view --log
```

---

## 📦 两个工作流的区别

### Build Web Client (build-webclient.yml)

**功能：**
- ✅ 仅编译 Web Client
- ✅ 不部署，仅生成文件
- ✅ 上传构建产物到 Artifacts

**适用场景：**
- 需要下载编译文件部署到自己的服务器
- 测试编译是否成功
- 生成部署包

**产出：**
- `rustdesk-webclient.tar.gz` - 完整部署包
- `rustdesk-webclient-files` - 原始文件目录

---

### Deploy Web Client to GitHub Pages (deploy-webclient.yml)

**功能：**
- ✅ 编译 Web Client
- ✅ 自动部署到 GitHub Pages
- ✅ 同时上传构建产物

**适用场景：**
- 需要公开访问的 Web 版本
- 快速演示和测试
- 免费托管方案

**访问地址：**
```
https://你的用户名.github.io/rustdesk
```

**产出：**
- 自动部署到 GitHub Pages
- `rustdesk-webclient.tar.gz` 部署包

---

## 🔧 工作流配置

### 触发方式

```yaml
on:
  workflow_dispatch:  # 仅手动触发
  
  # 以下已注释，如需自动触发可取消注释
  # push:
  #   branches:
  #     - main
  #   paths:
  #     - 'flutter/**'
```

### 如果需要自动触发

编辑 `.github/workflows/build-webclient.yml`：

```yaml
on:
  workflow_dispatch:  # 保留手动触发
  push:
    branches:
      - main
    paths:
      - 'flutter/**'  # 仅当 flutter 目录变更时触发
```

---

## 📊 构建流程

### Build Web Client

```mermaid
graph LR
    A[手动触发] --> B[Checkout 代码]
    B --> C[安装 Flutter 3.24.5]
    C --> D[flutter pub get]
    D --> E[flutter build web]
    E --> F[创建 tar.gz]
    F --> G[上传 Artifacts]
```

### Deploy to GitHub Pages

```mermaid
graph LR
    A[手动触发] --> B[编译 Web Client]
    B --> C[上传到 Pages]
    C --> D[部署到 GitHub Pages]
    D --> E[可访问 URL]
```

---

## 🐛 故障排查

### 问题：找不到 "Run workflow" 按钮

**可能原因：**
- 没有推送 workflow 配置文件到 GitHub
- 分支不是 main

**解决：**
```bash
# 确认 workflow 文件已推送
git push origin main

# 刷新 Actions 页面
```

---

### 问题：构建失败 - Missing index.html

**原因：** flutter/web/ 文件未提交

**解决：**
```bash
# 检查文件是否存在
ls flutter/web/

# 应该看到：
# index.html
# manifest.json
# README.md

# 如果不存在，重新拉取
git pull origin main
```

---

### 问题：Flutter 版本错误

**错误信息：**
```
extended_text requires SDK version >=3.5.0
```

**解决：** 已修复，workflow 使用 Flutter 3.24.5

---

### 问题：GitHub Pages 无法访问

**检查步骤：**

1. **启用 GitHub Pages**
   - Settings -> Pages
   - Source: GitHub Actions

2. **等待部署完成**
   - Actions 页面查看部署状态
   - 通常需要 2-5 分钟

3. **检查 URL**
   ```
   https://你的用户名.github.io/rustdesk
   ```

---

## 📝 构建日志示例

### 成功的构建日志

```
✓ Checkout code
✓ Setup Flutter (3.24.5)
✓ Get Flutter dependencies
  Resolving dependencies...
  ✓ All dependencies resolved
✓ Build Web Client
  Building RustDesk Web Client...
  Compiling...
  ✓ Build completed successfully
✓ Create deployment package
✓ Upload Web Client artifact
  Uploaded rustdesk-webclient.tar.gz
```

### 失败的构建日志

```
✓ Checkout code
✓ Setup Flutter (3.24.5)
✓ Get Flutter dependencies
✗ Build Web Client
  Building RustDesk Web Client...
  Missing index.html.
  Error: Process completed with exit code 1.
```

---

## ⚙️ 高级配置

### 修改 Flutter 版本

编辑 `.github/workflows/build-webclient.yml`:

```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.24.5'  # 修改为需要的版本
    channel: 'stable'
    cache: true
```

### 添加构建参数

```yaml
- name: Build Web Client
  working-directory: ./flutter
  run: |
    flutter build web --release \
      --web-renderer canvaskit \
      --base-href "/" \
      --dart-define=FLUTTER_WEB_USE_SKIA=true \
      --dart-define=YOUR_CUSTOM_FLAG=value  # 添加自定义参数
```

### 修改保留时间

```yaml
- name: Upload Web Client artifact
  uses: actions/upload-artifact@v4
  with:
    name: rustdesk-webclient
    path: flutter/rustdesk-webclient.tar.gz
    retention-days: 90  # 修改为需要的天数 (1-90)
```

---

## 📚 相关文档

| 文档 | 说明 |
|------|------|
| **WebClient编译部署指南.md** | 详细编译部署说明 |
| **版本要求.md** | Flutter/Dart 版本要求 |
| **flutter/web/README.md** | Web 目录说明 |
| **README-WebClient.md** | Web Client 快速开始 |

---

## ✅ 检查清单

### 首次使用

- [ ] workflow 文件已推送到 GitHub
- [ ] flutter/web/ 目录文件已提交
- [ ] 访问 Actions 页面确认工作流可见

### 每次构建前

- [ ] 代码已提交并推送
- [ ] 选择正确的工作流
- [ ] 选择正确的分支

### 构建完成后

- [ ] 查看构建日志确认成功
- [ ] 下载 Artifacts（如需要）
- [ ] 访问 GitHub Pages（如部署）

---

## 🎉 快速开始

```bash
# 1. 访问 Actions 页面
https://github.com/你的用户名/rustdesk/actions

# 2. 点击 "Build RustDesk Web Client"

# 3. 点击 "Run workflow"

# 4. 等待构建完成（约 5 分钟）

# 5. 下载构建产物或访问 GitHub Pages
```

---

**最后更新：** 2024-12-01  
**维护者：** xiehan12
