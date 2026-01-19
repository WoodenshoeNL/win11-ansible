# Win11-ansible

Personal Ansible deployment for fresh Windows 11 VMs.

## Overview

This Ansible playbook automates the configuration of Windows 11 machines for security assignments. It installs development tools, utilities, browsers, and AI coding assistants using winget.

## Quick Start

### 0. Install Required Ansible Collections

Before running the playbook, install the required Ansible collections:

```bash
ansible-galaxy collection install -r requirements.yml
```

This will install:
- `ansible.windows` - Core Windows modules (used for `win_command` to execute winget)

### 1. Bootstrap Windows 11 Machine

Copy `bootstrap.ps1` to your Windows 11 machine and run it as Administrator:

```powershell
.\bootstrap.ps1
```

This script will:
- Configure WinRM for Ansible management
- Set up firewall rules
- Configure PowerShell execution policy
- Verify winget availability

### 2. Run Ansible Playbook

From your Ubuntu machine:

```bash
# Run all roles
ansible-playbook -i <windows_ip>, playbook.yml -u <username> -k

# Run only specific roles using tags
ansible-playbook -i <windows_ip>, playbook.yml -u <username> -k --tags ai
ansible-playbook -i <windows_ip>, playbook.yml -u <username> -k --tags development
ansible-playbook -i <windows_ip>, playbook.yml -u <username> -k --tags utilities

# Run only specific applications
ansible-playbook -i <windows_ip>, playbook.yml -u <username> -k --tags putty
ansible-playbook -i <windows_ip>, playbook.yml -u <username> -k --tags cursor
ansible-playbook -i <windows_ip>, playbook.yml -u <username> -k --tags git,vscode

# Run multiple tags
ansible-playbook -i <windows_ip>, playbook.yml -u <username> -k --tags "ai,utilities"
```

## Structure

### Bootstrap Script

- **`bootstrap.ps1`** - PowerShell script to prepare Windows 11 for Ansible management

### Playbook

- **`playbook.yml`** - Main playbook that runs all roles

### Roles

- **Common** - PowerShell 7 installation
- **Development** - Git, VS Code, Rust, Python, Perl, OpenJDK, Windows Build Tools
- **AI** - Cursor, Google Antigravity, Claude Code
- **Utilities** - WinSCP, PuTTY, Windows Terminal, 7-Zip, WinDirStat
- **Browsers** - Google Chrome
- **Other** - Obsidian, Burp Suite

## Installation Methods

All software is installed via winget, ensuring consistent and automated installation across machines.

## Tags

Tags allow you to selectively install specific roles or applications:

### Role Tags
- `common` - PowerShell 7
- `development` - All development tools
- `ai` - All AI tools
- `utilities` - All utility tools
- `browsers` - All browsers
- `other` - Other tools

### Application Tags
- **Development**: `git`, `vscode`, `rust`, `python`, `perl`, `openjdk`, `buildtools`
- **AI**: `cursor`, `antigravity`, `claude`
- **Utilities**: `winscp`, `putty`, `terminal`, `7zip`, `windirstat`
- **Browsers**: `chrome`
- **Other**: `obsidian`, `burpsuite`
- **Common**: `powershell7`

### Examples

```bash
# Install only AI tools
ansible-playbook -i <windows_ip>, playbook.yml -u <username> -k --tags ai

# Install only PuTTY
ansible-playbook -i <windows_ip>, playbook.yml -u <username> -k --tags putty

# Install Git and VS Code
ansible-playbook -i <windows_ip>, playbook.yml -u <username> -k --tags git,vscode

# Install AI tools and utilities
ansible-playbook -i <windows_ip>, playbook.yml -u <username> -k --tags "ai,utilities"
```

## Notes

- Some winget package IDs (especially for AI tools) may need adjustment. Use `winget search <package_name>` to verify correct IDs.
- The AI role uses `ignore_errors: true` for packages that may have incorrect IDs, allowing the playbook to continue even if one package fails.
- All installations use `install_scope: machine` for system-wide installation.