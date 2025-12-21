#!/usr/bin/env python3
# Github: github.com/0nsec/BurpsuitePro.git
# install.py - To install the BurpSuitePro on various operating systems

import argparse
import os
import platform
import subprocess
import sys
import shutil
from pathlib import Path

RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
CYAN = "\033[96m"
RESET = "\033[0m"

HERE = Path(__file__).resolve().parent
WIN_SCRIPT = HERE / 'burp-files' / 'os' / 'windows' / 'install.ps1'
LINUX_SCRIPT = HERE / 'burp-files' / 'os' / 'linux' / 'install.sh'


def check_python_installed():
    python_exec = shutil.which("python") or shutil.which("python3")
    if not python_exec:
        print(f"{RED}[X]{RESET} Python is not installed or not found in PATH.")
        print(f"{YELLOW}[!] Please install Python 3.x and try again.{RESET}")
        sys.exit(1)
    else:
        try:
            version = subprocess.check_output([python_exec, "--version"]).decode().strip()
            print(f"{GREEN}[DONE]{RESET} Python detected: {version}")
        except Exception:
            print(f"{YELLOW}[!] Found python executable but failed to query version.{RESET}")


def detect_os():
    system = platform.system().lower()
    # detect WSL by checking /proc/version or release hints
    is_wsl = False
    try:
        if system == 'linux':
            with open('/proc/version', 'r', encoding='utf-8', errors='ignore') as f:
                if 'microsoft' in f.read().lower():
                    is_wsl = True
    except Exception:
        pass
    if is_wsl:
        return 'wsl'
    if system == 'windows':
        return 'windows'
    if system == 'darwin':
        return 'darwin'
    if system == 'linux':
        return 'linux'
    return system


def run_windows_installer():
    if not WIN_SCRIPT.exists():
        print(f"{RED}[X]{RESET} Windows install script not found: {WIN_SCRIPT}")
        sys.exit(1)
    # prefer pwsh (PowerShell Core) but fall back to powershell
    ps = shutil.which('pwsh') or shutil.which('powershell')
    if not ps:
        print(f"{RED}[X]{RESET} PowerShell not found in PATH. Please install PowerShell (pwsh/powershell) and try again.")
        sys.exit(1)
    print(f"{BLUE}[*]{RESET} Running Windows installer with: {ps}")
    try:
        subprocess.run([ps, '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(WIN_SCRIPT)], check=True)
        print(f"{GREEN}[DONE]{RESET} Windows installer completed.")
    except subprocess.CalledProcessError as e:
        print(f"{RED}[X]{RESET} Windows installer failed (exit {e.returncode}).")
        sys.exit(e.returncode)


def run_linux_installer():
    if not LINUX_SCRIPT.exists():
        print(f"{RED}[X]{RESET} Linux install script not found: {LINUX_SCRIPT}")
        sys.exit(1)
    bash = shutil.which('bash') or shutil.which('sh')
    if not bash:
        print(f"{RED}[X]{RESET} 'bash' not found in PATH. Please install bash and try again.")
        sys.exit(1)
    # make sure the script is executable
    try:
        LINUX_SCRIPT.chmod(LINUX_SCRIPT.stat().st_mode | 0o111)
    except Exception:
        pass
    print(f"{BLUE}[*]{RESET} Running Linux installer with: {bash}")
    try:
        subprocess.run([bash, str(LINUX_SCRIPT)], check=True)
        print(f"{GREEN}[DONE]{RESET} Linux installer completed.")
    except subprocess.CalledProcessError as e:
        print(f"{RED}[X]{RESET} Linux installer failed (exit {e.returncode}).")
        sys.exit(e.returncode)


def parse_args():
    p = argparse.ArgumentParser(description='BurpSuitePro installer launcher')
    p.add_argument('--os', choices=['auto', 'windows', 'linux', 'wsl', 'darwin'], default='auto', help='Override detected OS')
    return p.parse_args()


def main():
    check_python_installed()
    args = parse_args()
    if args.os == 'auto':
        os_type = detect_os()
    else:
        os_type = args.os

    print(f"\n{CYAN}Detected/Chosen OS:{RESET} {YELLOW}{os_type}{RESET}\n")

    if os_type == 'windows':
        run_windows_installer()
    elif os_type == 'wsl' or os_type == 'linux' or os_type == 'darwin':
        # darwin uses the linux installer for now (script may need OS-specific changes)
        if os_type == 'darwin':
            print(f"{YELLOW}[!] macOS detected: using the Linux installer path. This may not be fully supported.{RESET}")
        run_linux_installer()
    else:
        print(f"{RED}[X]{RESET} Unsupported or unknown OS: {os_type}")
        print(f"{YELLOW}[!] You can override with --os windows|linux|wsl|darwin{RESET}")
        sys.exit(2)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        os.system('cls' if platform.system().lower().startswith('win') else 'clear')
        ascii_art = """
       /$$$$$$                                                    
      /$$$_  $$                                                   
     | $$$$\ $$ /$$$$$$$   /$$$$$$$  /$$$$$$   /$$$$$$$           
     | $$ $$ $$| $$__  $$ /$$_____/ /$$__  $$ /$$_____/           
     | $$\ $$$$| $$  \ $$|  $$$$$$ | $$$$$$$$| $$                 
     | $$ \ $$$| $$  | $$ \____  $$| $$_____/| $$                 
     |  $$$$$$/| $$  | $$ /$$$$$$$/|  $$$$$$$|  $$$$$$$           
      \______/ |__/  |__/|_______/  \_______/ \_______/                

          Github: github.com/0nsec/BurpsuitePro.git
    """
        print(ascii_art)
        print(f"{YELLOW}[!] Installation cancelled by user.{RESET}\n")
        sys.exit(130)
