@echo off
REM RustDesk Web Client Windows 编译脚本

echo =========================================
echo   RustDesk Web Client 编译脚本 (Windows)
echo =========================================
echo.

REM 检查 Flutter 是否安装
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [错误] Flutter 未安装！
    echo 请从 https://flutter.dev/docs/get-started/install/windows 安装 Flutter
    pause
    exit /b 1
)

echo [OK] Flutter 已安装
flutter --version
echo.

REM 进入 flutter 目录
cd flutter

REM 清理之前的构建
echo [步骤 1/4] 清理之前的构建...
flutter clean

REM 获取依赖
echo [步骤 2/4] 获取依赖...
flutter pub get

REM 编译 Web Client
echo [步骤 3/4] 开始编译 Web Client...
flutter build web --release --web-renderer canvaskit --base-href "/" --dart-define=FLUTTER_WEB_USE_SKIA=true

REM 检查编译结果
if exist "build\web" (
    echo.
    echo =========================================
    echo [成功] 编译完成！
    echo =========================================
    echo.
    echo 输出目录: flutter\build\web
    echo.
    dir build\web
    echo.
    
    REM 创建压缩包
    echo [步骤 4/4] 创建部署包...
    cd build\web
    tar -czf ..\rustdesk-webclient.tar.gz .
    if %ERRORLEVEL% EQU 0 (
        echo [成功] 部署包已创建: flutter\build\rustdesk-webclient.tar.gz
    ) else (
        echo [警告] 无法创建 tar.gz 包（需要 Windows 10 1803+ 或安装 tar）
        echo 您可以手动压缩 build\web 目录
    )
    cd ..\..
    
    echo.
    echo 部署说明:
    echo 1. 将 build\web 目录内容上传到 Web 服务器
    echo 2. 或使用 rustdesk-webclient.tar.gz 部署
    echo.
    echo 本地测试:
    echo cd flutter\build\web
    echo python -m http.server 8080
    echo 然后访问: http://localhost:8080
    echo.
    
) else (
    echo.
    echo [错误] 编译失败！
    echo 请检查错误信息
    pause
    exit /b 1
)

pause
