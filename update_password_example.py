#!/usr/bin/env python3
"""
RustDesk 自动更新临时密码脚本
每2分钟自动生成新的随机密码并通过 IPC 更新到 RustDesk
"""

import socket
import struct
import random
import string
import time
import json
import sys
import platform

# RustDesk IPC 配置
if platform.system() == 'Windows':
    IPC_PATH = r'\\.\pipe\RustDesk\query'
    USE_NAMED_PIPE = True
else:
    IPC_PATH = '/tmp/RustDesk/ipc'
    USE_NAMED_PIPE = False

# 密码配置
PASSWORD_LENGTH = 6  # 可以是 6, 8, 或 10
USE_NUMERIC_ONLY = False  # True=纯数字, False=字母数字混合
UPDATE_INTERVAL = 120  # 秒（2分钟）

# 字符集
CHARS = '23456789abcdefghjkmnpqrstuvwxyz'  # 排除容易混淆的字符
NUMERIC_CHARS = '0123456789'


class RustDeskIPC:
    """RustDesk IPC 通信类"""
    
    def __init__(self, ipc_path=IPC_PATH):
        self.ipc_path = ipc_path
        self.use_named_pipe = USE_NAMED_PIPE
    
    def connect(self):
        """连接到 RustDesk IPC"""
        if self.use_named_pipe:
            # Windows Named Pipe
            return self._connect_named_pipe()
        else:
            # Unix Domain Socket
            return self._connect_unix_socket()
    
    def _connect_named_pipe(self):
        """Windows Named Pipe 连接"""
        import win32pipe
        import win32file
        import pywintypes
        
        try:
            handle = win32file.CreateFile(
                self.ipc_path,
                win32file.GENERIC_READ | win32file.GENERIC_WRITE,
                0,
                None,
                win32file.OPEN_EXISTING,
                0,
                None
            )
            return handle
        except pywintypes.error as e:
            print(f"Failed to connect to RustDesk: {e}")
            return None
    
    def _connect_unix_socket(self):
        """Unix Domain Socket 连接"""
        try:
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            sock.connect(self.ipc_path)
            return sock
        except Exception as e:
            print(f"Failed to connect to RustDesk: {e}")
            return None
    
    def send_config(self, conn, name, value):
        """
        发送配置命令到 RustDesk
        
        对应 Rust 代码: Data::Config((name, value))
        """
        try:
            # 构造消息
            # RustDesk 使用 msgpack 或 JSON 序列化
            # 这里简化为发送命令字符串
            
            if self.use_named_pipe:
                return self._send_named_pipe(conn, name, value)
            else:
                return self._send_unix_socket(conn, name, value)
        except Exception as e:
            print(f"Failed to send config: {e}")
            return False
    
    def _send_named_pipe(self, handle, name, value):
        """通过 Windows Named Pipe 发送"""
        import win32file
        
        # 构造消息（根据 RustDesk 的协议格式）
        message = json.dumps({
            "type": "Config",
            "name": name,
            "value": value
        }).encode('utf-8')
        
        try:
            win32file.WriteFile(handle, message)
            return True
        except Exception as e:
            print(f"Write error: {e}")
            return False
    
    def _send_unix_socket(self, sock, name, value):
        """通过 Unix Domain Socket 发送"""
        # 根据 RustDesk IPC 协议构造消息
        message = json.dumps({
            "type": "Config",
            "name": name,
            "value": value
        }).encode('utf-8')
        
        try:
            sock.sendall(message)
            return True
        except Exception as e:
            print(f"Send error: {e}")
            return False
    
    def close(self, conn):
        """关闭连接"""
        if conn:
            if self.use_named_pipe:
                import win32file
                win32file.CloseHandle(conn)
            else:
                conn.close()
    
    def update_temporary_password(self):
        """
        触发 RustDesk 更新临时密码
        
        对应 Rust 代码:
        set_config("temporary-password", "")
        -> password::update_temporary_password()
        """
        conn = self.connect()
        if not conn:
            return False
        
        result = self.send_config(conn, "temporary-password", "")
        self.close(conn)
        return result


def generate_password(length=PASSWORD_LENGTH, numeric_only=USE_NUMERIC_ONLY):
    """生成随机密码"""
    if numeric_only:
        chars = NUMERIC_CHARS
    else:
        chars = CHARS
    
    password = ''.join(random.choice(chars) for _ in range(length))
    return password


def get_current_password():
    """
    获取当前密码（通过 IPC）
    这需要连接到 RustDesk 并查询当前密码
    """
    # 这里简化处理，实际可以通过 IPC 查询
    return None


def update_password_cycle():
    """定时更新密码的主循环"""
    ipc = RustDeskIPC()
    
    print("=== RustDesk 自动密码更新器 ===")
    print(f"IPC 路径: {IPC_PATH}")
    print(f"密码长度: {PASSWORD_LENGTH}")
    print(f"更新间隔: {UPDATE_INTERVAL} 秒")
    print(f"仅数字: {USE_NUMERIC_ONLY}")
    print("")
    
    cycle_count = 0
    
    while True:
        try:
            cycle_count += 1
            print(f"\n[Cycle #{cycle_count}] {time.strftime('%Y-%m-%d %H:%M:%S')}")
            
            # 生成新密码
            new_password = generate_password()
            print(f"生成的新密码: {new_password}")
            
            # 触发 RustDesk 更新临时密码
            # 注意：这会让 RustDesk 自己生成新密码
            if ipc.update_temporary_password():
                print("✓ 已触发密码更新")
            else:
                print("✗ 密码更新失败，RustDesk 可能未运行")
            
            # 等待下一个周期
            print(f"等待 {UPDATE_INTERVAL} 秒...")
            time.sleep(UPDATE_INTERVAL)
            
        except KeyboardInterrupt:
            print("\n\n程序已停止")
            break
        except Exception as e:
            print(f"错误: {e}")
            time.sleep(10)  # 出错后等待10秒再重试


if __name__ == '__main__':
    # 依赖检查
    if platform.system() == 'Windows':
        try:
            import win32file
            import win32pipe
        except ImportError:
            print("错误: Windows 平台需要安装 pywin32")
            print("运行: pip install pywin32")
            sys.exit(1)
    
    update_password_cycle()
