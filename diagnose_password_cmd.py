#!/usr/bin/env python3
"""
RustDesk 密码命令诊断工具
帮助排查 --password 命令不生效的原因
"""

import subprocess
import sys
import os
import ctypes
from pathlib import Path


def is_admin():
    """检查是否有管理员权限"""
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False


def check_rustdesk_installed():
    """检查 RustDesk 是否已安装"""
    install_paths = [
        Path(os.environ.get('ProgramFiles', 'C:\\Program Files')) / 'RustDesk' / 'rustdesk.exe',
        Path(os.environ.get('ProgramFiles(x86)', 'C:\\Program Files (x86)')) / 'RustDesk' / 'rustdesk.exe',
        Path(os.environ.get('LOCALAPPDATA', '')) / 'RustDesk' / 'rustdesk.exe',
    ]
    
    for path in install_paths:
        if path.exists():
            return True, str(path)
    
    return False, None


def check_rustdesk_service():
    """检查 RustDesk 服务状态"""
    try:
        result = subprocess.run(
            ['sc', 'query', 'rustdesk'],
            capture_output=True,
            text=True
        )
        
        output = result.stdout
        if 'RUNNING' in output:
            return True, "运行中"
        elif 'STOPPED' in output:
            return False, "已停止"
        else:
            return False, "未安装"
    except:
        return False, "检查失败"


def test_password_command(rustdesk_exe, password):
    """测试密码命令"""
    print(f"\n执行命令: {rustdesk_exe} --password {password}")
    print("-" * 60)
    
    try:
        result = subprocess.run(
            [rustdesk_exe, '--password', password],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        print(f"返回码: {result.returncode}")
        print(f"标准输出: '{result.stdout.strip()}'")
        print(f"错误输出: '{result.stderr.strip()}'")
        
        return result.returncode, result.stdout.strip(), result.stderr.strip()
        
    except Exception as e:
        print(f"执行异常: {e}")
        return -1, "", str(e)


def main():
    print("=" * 70)
    print("RustDesk 密码命令诊断工具")
    print("=" * 70)
    
    # 1. 检查管理员权限
    print("\n[1/5] 检查管理员权限...")
    if is_admin():
        print("    ✓ 当前拥有管理员权限")
        admin_ok = True
    else:
        print("    ✗ 当前没有管理员权限")
        print("    ⚠️  请以管理员身份运行此脚本！")
        admin_ok = False
    
    # 2. 检查 RustDesk 是否安装
    print("\n[2/5] 检查 RustDesk 安装状态...")
    installed, install_path = check_rustdesk_installed()
    if installed:
        print(f"    ✓ RustDesk 已安装")
        print(f"    路径: {install_path}")
        rustdesk_exe = str(install_path)
    else:
        print("    ✗ RustDesk 未安装（或使用便携版）")
        print("    ⚠️  --password 命令只能在安装版中使用！")
        
        # 检查当前目录
        current_exe = Path("rustdesk.exe")
        if current_exe.exists():
            print(f"    发现便携版: {current_exe.absolute()}")
            rustdesk_exe = str(current_exe.absolute())
        else:
            print("    当前目录也没有 rustdesk.exe")
            rustdesk_exe = "rustdesk.exe"
    
    # 3. 检查服务状态
    print("\n[3/5] 检查 RustDesk 服务状态...")
    service_running, service_status = check_rustdesk_service()
    if service_running:
        print(f"    ✓ RustDesk 服务正在运行")
    else:
        print(f"    ✗ RustDesk 服务状态: {service_status}")
        if service_status == "已停止":
            print("    提示: 可以运行 'sc start rustdesk' 启动服务")
        elif service_status == "未安装":
            print("    ⚠️  RustDesk 服务未安装")
    
    # 4. 检查配置文件
    print("\n[4/5] 检查配置文件...")
    config_path = Path(os.environ.get('APPDATA', '')) / 'RustDesk' / 'config' / 'RustDesk2.toml'
    if config_path.exists():
        print(f"    ✓ 配置文件存在")
        print(f"    路径: {config_path}")
    else:
        print(f"    ✗ 配置文件不存在")
        print(f"    预期路径: {config_path}")
    
    # 5. 测试密码命令
    print("\n[5/5] 测试密码命令...")
    test_password = "TestPassword123"
    returncode, stdout, stderr = test_password_command(rustdesk_exe, test_password)
    
    # 总结
    print("\n" + "=" * 70)
    print("诊断结果")
    print("=" * 70)
    
    issues = []
    
    if not admin_ok:
        issues.append("❌ 缺少管理员权限")
    
    if not installed:
        issues.append("❌ RustDesk 未安装（使用的是便携版）")
    
    if not service_running:
        issues.append(f"❌ RustDesk 服务未运行 ({service_status})")
    
    if stdout == "Done!":
        print("\n✓ 密码命令执行成功！")
        print("  如果觉得没生效，可能是因为：")
        print("  1. 客户端缓存了旧密码")
        print("  2. 需要重启 RustDesk 服务")
        print("  3. 检查配置文件中的密码是否更新")
    elif stdout == "Installation and administrative privileges required!":
        print("\n✗ 密码命令被拒绝：需要安装版和管理员权限")
    elif issues:
        print("\n✗ 发现以下问题：")
        for issue in issues:
            print(f"  {issue}")
    else:
        print("\n⚠️  命令执行但结果异常")
        print(f"  输出: {stdout or stderr or '(无)'}")
    
    # 解决方案
    if issues or stdout != "Done!":
        print("\n" + "=" * 70)
        print("解决方案")
        print("=" * 70)
        
        if not admin_ok:
            print("\n1. 以管理员身份运行:")
            print("   - 右键点击 CMD/PowerShell")
            print("   - 选择 '以管理员身份运行'")
            print("   - 或在命令前加: runas /user:Administrator")
        
        if not installed:
            print("\n2. 安装 RustDesk:")
            print("   - 下载安装版（非便携版）")
            print("   - 运行安装程序")
            print("   - 安装完成后服务会自动启动")
        
        if not service_running:
            print("\n3. 启动 RustDesk 服务:")
            print("   以管理员身份运行:")
            print("   sc start rustdesk")
            print("   或:")
            print("   net start rustdesk")
        
        print("\n4. 完整测试命令:")
        print("   以管理员身份在 CMD 中运行:")
        print(f'   "{rustdesk_exe}" --password "TestPassword123"')
    
    print("\n" + "=" * 70)


if __name__ == "__main__":
    main()
