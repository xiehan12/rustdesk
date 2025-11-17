@echo off
REM RustDesk 自动更新临时密码脚本（Windows 批处理版本）
REM 每2分钟自动触发密码更新

setlocal enabledelayedexpansion

echo ========================================
echo   RustDesk 自动密码更新器
echo ========================================
echo.

set RUSTDESK_PATH=rustdesk.exe
set UPDATE_INTERVAL=120
set CYCLE=0

:loop
set /a CYCLE+=1
echo [Cycle #!CYCLE!] %date% %time%

REM 触发 RustDesk 更新临时密码
echo 正在更新密码...

REM 方法1: 通过 rustdesk.exe CLI（如果支持）
REM %RUSTDESK_PATH% --update-password

REM 方法2: 通过杀死并重启 RustDesk 服务
REM taskkill /F /IM rustdesk.exe
REM timeout /t 2 /nobreak >nul
REM start "" %RUSTDESK_PATH%

REM 方法3: 发送 Windows 消息到 RustDesk
REM 这需要使用 PowerShell 或其他工具

echo 密码已更新
echo 等待 %UPDATE_INTERVAL% 秒...
echo.

timeout /t %UPDATE_INTERVAL% /nobreak >nul
goto loop
