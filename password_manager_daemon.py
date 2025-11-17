#!/usr/bin/env python3
"""
RustDesk 密码动态管理守护进程
每2分钟自动修改密码并上报到API服务器
"""

import json
import time
import secrets
import string
import logging
import requests
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

# 配置
CONFIG_FILE = Path(__file__).parent / "password_manager_config.json"
LOG_FILE = Path(__file__).parent / "password_manager.log"

# 日志配置
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE, encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


class PasswordManager:
    """RustDesk 密码管理器"""
    
    def __init__(self, config_path: Path):
        self.config = self.load_config(config_path)
        self.rustdesk_exe = self.config.get('rustdesk_exe', 'rustdesk.exe')
        self.api_url = self.config['api_url']
        self.api_key = self.config['api_key']
        self.device_id = self.config.get('device_id', self.get_rustdesk_id())
        self.interval = self.config.get('interval_seconds', 120)  # 默认2分钟
        self.password_length = self.config.get('password_length', 12)
        self.retry_times = self.config.get('retry_times', 3)
        self.retry_delay = self.config.get('retry_delay', 5)
        
    def load_config(self, config_path: Path) -> dict:
        """加载配置文件"""
        if not config_path.exists():
            # 创建默认配置
            default_config = {
                "api_url": "https://your-api-server.com/api/password/update",
                "api_key": "your-secret-api-key",
                "device_id": "",
                "interval_seconds": 120,
                "password_length": 12,
                "retry_times": 3,
                "retry_delay": 5,
                "rustdesk_exe": "rustdesk.exe"
            }
            config_path.write_text(json.dumps(default_config, indent=2, ensure_ascii=False))
            logger.warning(f"配置文件不存在，已创建默认配置: {config_path}")
            logger.warning("请修改配置文件后重新运行！")
            sys.exit(1)
        
        with open(config_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    def get_rustdesk_id(self) -> str:
        """获取 RustDesk ID"""
        try:
            # 通过命令行获取 RustDesk ID
            result = subprocess.run(
                [self.rustdesk_exe, '--get-id'],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                rustdesk_id = result.stdout.strip()
                logger.info(f"获取到 RustDesk ID: {rustdesk_id}")
                return rustdesk_id
        except Exception as e:
            logger.error(f"获取 RustDesk ID 失败: {e}")
        
        return "unknown"
    
    def generate_password(self) -> str:
        """生成安全的随机密码"""
        # 包含大小写字母、数字和特殊字符
        characters = string.ascii_letters + string.digits + "!@#$%^&*"
        password = ''.join(secrets.choice(characters) for _ in range(self.password_length))
        logger.debug(f"生成新密码: {'*' * len(password)} (长度: {len(password)})")
        return password
    
    def update_rustdesk_password(self, password: str) -> bool:
        """通过 IPC 更新 RustDesk 密码"""
        try:
            # 使用 RustDesk 命令行接口修改密码
            result = subprocess.run(
                [self.rustdesk_exe, '--password', password],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                logger.info("✓ RustDesk 密码更新成功")
                return True
            else:
                logger.error(f"✗ RustDesk 密码更新失败: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            logger.error("✗ RustDesk 密码更新超时")
            return False
        except Exception as e:
            logger.error(f"✗ RustDesk 密码更新异常: {e}")
            return False
    
    def report_to_api(self, password: str) -> bool:
        """上报密码到 API 服务器"""
        payload = {
            "device_id": self.device_id,
            "password": password,
            "timestamp": datetime.now().isoformat(),
            "version": "1.0"
        }
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        for attempt in range(self.retry_times):
            try:
                logger.info(f"正在上报密码到 API 服务器 (尝试 {attempt + 1}/{self.retry_times})...")
                
                response = requests.post(
                    self.api_url,
                    json=payload,
                    headers=headers,
                    timeout=10
                )
                
                if response.status_code == 200:
                    logger.info(f"✓ 密码上报成功: {response.json()}")
                    return True
                else:
                    logger.warning(f"✗ 密码上报失败 (HTTP {response.status_code}): {response.text}")
                    
            except requests.exceptions.RequestException as e:
                logger.error(f"✗ API 请求异常: {e}")
            
            if attempt < self.retry_times - 1:
                logger.info(f"等待 {self.retry_delay} 秒后重试...")
                time.sleep(self.retry_delay)
        
        logger.error(f"✗ 密码上报失败，已重试 {self.retry_times} 次")
        return False
    
    def update_cycle(self) -> bool:
        """执行一次完整的密码更新周期"""
        logger.info("=" * 60)
        logger.info(f"开始密码更新周期 - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        logger.info("=" * 60)
        
        # 1. 生成新密码
        new_password = self.generate_password()
        
        # 2. 更新 RustDesk 密码
        if not self.update_rustdesk_password(new_password):
            logger.error("密码更新失败，跳过 API 上报")
            return False
        
        # 3. 上报到 API 服务器
        if not self.report_to_api(new_password):
            logger.warning("API 上报失败，但 RustDesk 密码已更新")
            return False
        
        logger.info("✓ 密码更新周期完成")
        return True
    
    def run(self):
        """运行守护进程"""
        logger.info("=" * 60)
        logger.info("RustDesk 密码管理守护进程启动")
        logger.info("=" * 60)
        logger.info(f"Device ID: {self.device_id}")
        logger.info(f"更新间隔: {self.interval} 秒")
        logger.info(f"API 服务器: {self.api_url}")
        logger.info(f"密码长度: {self.password_length}")
        logger.info("=" * 60)
        
        # 立即执行一次
        self.update_cycle()
        
        # 循环执行
        while True:
            try:
                logger.info(f"下次更新时间: {datetime.fromtimestamp(time.time() + self.interval).strftime('%H:%M:%S')}")
                time.sleep(self.interval)
                self.update_cycle()
                
            except KeyboardInterrupt:
                logger.info("\n收到中断信号，正在退出...")
                break
            except Exception as e:
                logger.error(f"未知错误: {e}", exc_info=True)
                logger.info(f"等待 {self.interval} 秒后继续...")
                time.sleep(self.interval)


def main():
    """主函数"""
    try:
        manager = PasswordManager(CONFIG_FILE)
        manager.run()
    except Exception as e:
        logger.error(f"程序启动失败: {e}", exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
