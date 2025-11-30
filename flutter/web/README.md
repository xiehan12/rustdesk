# Flutter Web 目录说明

## 📁 目录结构

```
web/
├── index.html          # 主页面（已创建）
├── manifest.json       # PWA 配置（已创建）
├── favicon.png         # 网站图标（需要添加）
└── icons/              # 应用图标目录（需要添加）
    ├── Icon-192.png
    ├── Icon-512.png
    ├── Icon-maskable-192.png
    └── Icon-maskable-512.png
```

## ⚠️ 重要说明

### 缺失的图标文件

由于 `.gitignore` 忽略了 `*.png` 文件，以下图标文件未包含在仓库中：

- `favicon.png` (16x16 或 32x32)
- `icons/Icon-192.png` (192x192)
- `icons/Icon-512.png` (512x512)
- `icons/Icon-maskable-192.png` (192x192)
- `icons/Icon-maskable-512.png` (512x512)

### 解决方案

#### 方案 1：使用 Flutter 默认图标（推荐）

首次编译时，Flutter 会自动生成默认图标：

```bash
cd flutter
flutter build web --release
```

#### 方案 2：手动添加自定义图标

1. 准备您的图标文件（PNG 格式）
2. 修改 `.gitignore`，添加例外：
   ```
   # 允许 web 图标
   !flutter/web/favicon.png
   !flutter/web/icons/*.png
   ```
3. 添加图标文件到对应目录

#### 方案 3：使用在线生成工具

访问以下网站生成所需尺寸的图标：
- https://favicon.io/
- https://realfavicongenerator.net/

## ✅ 已包含的文件

### index.html

Flutter Web 应用的主页面，包含：
- 基础 HTML 结构
- Flutter 引擎加载脚本
- PWA 支持

### manifest.json

PWA (Progressive Web App) 配置文件，定义：
- 应用名称和描述
- 主题颜色
- 图标引用
- 显示模式

## 🚀 编译说明

### 本地编译

```bash
cd flutter
flutter build web --release
```

### GitHub Actions

访问：https://github.com/你的用户名/rustdesk/actions
点击 "Build RustDesk Web Client" -> "Run workflow"

## 📝 注意事项

1. **首次编译**时 Flutter 会自动生成缺失的图标
2. **图标文件**不会提交到仓库（被 .gitignore 忽略）
3. **每次克隆**仓库后需要重新编译生成图标
4. **生产环境**建议使用自定义品牌图标

## 🔗 相关文档

- [Flutter Web 文档](https://docs.flutter.dev/platform-integration/web)
- [PWA 配置指南](https://web.dev/progressive-web-apps/)
