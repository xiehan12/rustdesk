#!/bin/bash
# RustDesk Web Client 本地编译脚本

set -e

echo "========================================="
echo "  RustDesk Web Client 编译脚本"
echo "========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查 Flutter 是否安装
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter 未安装！${NC}"
    echo "请从 https://flutter.dev/docs/get-started/install 安装 Flutter"
    exit 1
fi

echo -e "${GREEN}✓ Flutter 已安装${NC}"
flutter --version
echo ""

# 进入 flutter 目录
cd flutter

# 清理之前的构建
echo -e "${YELLOW}→ 清理之前的构建...${NC}"
flutter clean

# 获取依赖
echo -e "${YELLOW}→ 获取依赖...${NC}"
flutter pub get

# 编译 Web Client
echo -e "${YELLOW}→ 开始编译 Web Client...${NC}"
flutter build web --release \
  --web-renderer canvaskit \
  --base-href "/" \
  --dart-define=FLUTTER_WEB_USE_SKIA=true

# 检查编译结果
if [ -d "build/web" ]; then
    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}✓ 编译成功！${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "输出目录: flutter/build/web"
    echo "文件大小:"
    du -sh build/web
    echo ""
    echo "文件列表:"
    ls -lh build/web
    echo ""
    
    # 创建压缩包
    echo -e "${YELLOW}→ 创建部署包...${NC}"
    cd build/web
    tar -czf ../rustdesk-webclient.tar.gz .
    cd ../..
    
    echo -e "${GREEN}✓ 部署包已创建: flutter/build/rustdesk-webclient.tar.gz${NC}"
    echo ""
    echo "部署说明:"
    echo "1. 将 build/web 目录内容上传到 Web 服务器"
    echo "2. 或解压 rustdesk-webclient.tar.gz 到服务器"
    echo "3. 配置 Web 服务器指向该目录"
    echo ""
    echo "本地测试:"
    echo "cd flutter/build/web && python3 -m http.server 8080"
    echo "然后访问: http://localhost:8080"
    
else
    echo -e "${RED}✗ 编译失败！${NC}"
    exit 1
fi
