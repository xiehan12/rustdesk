#!/usr/bin/env python3
"""
测试 RustDesk 命令行密码修改功能
演示如何通过命令行调用 rustdesk.exe --password
"""

import subprocess
import sys
from pathlib import Path


def test_password_update(rustdesk_exe: str, new_password: str):
    """
    测试密码更新功能
    
    Args:
        rustdesk_exe: RustDesk 可执行文件路径
        new_password: 新密码
    
    Returns:
        (success: bool, message: str)
    """
    print("=" * 60)
    print("测试 RustDesk 密码更新")
    print("=" * 60)
    print(f"可执行文件: {rustdesk_exe}")
    print(f"新密码长度: {len(new_password)} 字符")
    print("-" * 60)
    
    try:
        # 执行命令：rustdesk.exe --password "new_password"
        result = subprocess.run(
            [rustdesk_exe, '--password', new_password],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        stdout = result.stdout.strip()
        stderr = result.stderr.strip()
        
        print(f"返回码: {result.returncode}")
        print(f"标准输出: {stdout}")
        if stderr:
            print(f"错误输出: {stderr}")
        print("-" * 60)
        
        # 判断是否成功
        if result.returncode == 0 and stdout == "Done!":
            print("✓ 密码更新成功！")
            return True, "Done!"
        else:
            print(f"✗ 密码更新失败: {stdout or stderr}")
            return False, stdout or stderr
            
    except subprocess.TimeoutExpired:
        msg = "命令执行超时"
        print(f"✗ {msg}")
        return False, msg
        
    except FileNotFoundError:
        msg = f"找不到可执行文件: {rustdesk_exe}"
        print(f"✗ {msg}")
        return False, msg
        
    except Exception as e:
        msg = f"执行异常: {e}"
        print(f"✗ {msg}")
        return False, str(e)


def main():
    """主函数"""
    # 配置
    rustdesk_exe = "rustdesk.exe"  # 或完整路径
    test_password = "TestPassword123!@#"
    
    print("\n" + "=" * 60)
    print("RustDesk 密码更新命令行测试工具")
    print("=" * 60)
    print()
    
    # 提示需要管理员权限
    print("⚠️  注意事项:")
    print("   1. 需要以管理员权限运行")
    print("   2. RustDesk 必须已安装（不是便携版）")
    print("   3. RustDesk 服务必须正在运行")
    print()
    
    # 执行测试
    success, message = test_password_update(rustdesk_exe, test_password)
    
    print("\n" + "=" * 60)
    if success:
        print("✓ 测试通过")
    else:
        print("✗ 测试失败")
    print("=" * 60)
    
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
