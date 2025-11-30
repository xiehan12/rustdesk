# 🚀 Web Client 自动连接 - 快速开始

## 一分钟上手

### 1. URL 格式

```
https://yourserver.com/#/?参数1=值1&参数2=值2
```

### 2. 常用参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `id` | 设备 ID（必需） | `id=123456789` |
| `password` | 连接密码 | `password=yourpass` |
| `autoconnect` | 自动连接 | `autoconnect=true` |
| `relay` | 强制中继 | `relay=true` |

### 3. 快速示例

```bash
# 示例 1：仅填充 ID
https://yourserver.com/#/?id=123456789

# 示例 2：填充 ID + 自动连接
https://yourserver.com/#/?id=123456789&autoconnect=true

# 示例 3：完整功能（推荐）
https://yourserver.com/#/?id=123456789&password=yourpass&autoconnect=true
```

---

## 编译和部署

### 编译 Flutter Web

```bash
cd flutter
flutter build web --release
```

### 部署文件

```bash
# 将 build/web 目录内容部署到 Web 服务器
cp -r build/web/* /var/www/rustdesk/
```

### 测试

```bash
# 本地测试
cd build/web
python -m http.server 8080

# 访问
http://localhost:8080/#/?id=123456789&autoconnect=true
```

---

## 使用工具

打开 `WebClient自动连接示例.html` 可以：
- ✅ 可视化生成连接 URL
- ✅ 一键复制链接
- ✅ 直接打开测试

---

## 详细文档

完整功能说明请查看：
- 📄 `WebClient自动连接功能说明.md` - 完整文档
- 🌐 `WebClient自动连接示例.html` - 交互示例

---

**快速支持：** 如有问题，请查看完整文档的"故障排查"章节
