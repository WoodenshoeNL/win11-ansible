# Bootstrap script for Windows 11 to prepare for Ansible management
# Run this script as Administrator on the Windows 11 machine

Write-Host "Starting Windows 11 Ansible bootstrap..." -ForegroundColor Green

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    exit 1
}

# Set network profile to Private (required for WinRM firewall rules)
Write-Host "Setting network profile to Private..." -ForegroundColor Yellow
$profiles = Get-NetConnectionProfile
foreach ($profile in $profiles) {
    if ($profile.NetworkCategory -ne "Private") {
        Set-NetConnectionProfile -InterfaceIndex $profile.InterfaceIndex -NetworkCategory Private
        Write-Host "Changed network profile for interface $($profile.InterfaceIndex) to Private" -ForegroundColor Green
    }
}

# Enable WinRM for Ansible
Write-Host "Configuring WinRM..." -ForegroundColor Yellow
winrm quickconfig -force -q
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'

# Configure WinRM listener
$listener = Get-ChildItem WSMan:\Localhost\Listener -ErrorAction SilentlyContinue
if (-not $listener) {
    winrm create winrm/config/Listener?Address=*+Transport=HTTP
}

# Set WinRM service to auto-start
Set-Service -Name WinRM -StartupType Automatic
Start-Service -Name WinRM

# Configure firewall rule for WinRM
Write-Host "Configuring firewall..." -ForegroundColor Yellow
New-NetFirewallRule -DisplayName "WinRM HTTP" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue

# Install Windows features required for Ansible
Write-Host "Installing Windows features..." -ForegroundColor Yellow
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -ErrorAction SilentlyContinue

# Ensure PowerShell execution policy allows scripts
Write-Host "Setting PowerShell execution policy..." -ForegroundColor Yellow
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

# Install winget if not present (should be on Windows 11, but check anyway)
Write-Host "Checking winget..." -ForegroundColor Yellow
$wingetPath = Get-Command winget -ErrorAction SilentlyContinue
if (-not $wingetPath) {
    Write-Host "WARNING: winget not found. Please install App Installer from Microsoft Store." -ForegroundColor Yellow
} else {
    Write-Host "winget is available" -ForegroundColor Green
}

# Display network information for Ansible connection
Write-Host "`n=== Network Information ===" -ForegroundColor Cyan
$ipAddresses = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" }
foreach ($ip in $ipAddresses) {
    Write-Host "IP Address: $($ip.IPAddress)" -ForegroundColor White
}

Write-Host "`n=== WinRM Status ===" -ForegroundColor Cyan
$winrmStatus = Get-Service WinRM
Write-Host "WinRM Service: $($winrmStatus.Status)" -ForegroundColor White

Write-Host "`n=== Testing WinRM ===" -ForegroundColor Cyan
try {
    $result = winrm id
    Write-Host "WinRM is working!" -ForegroundColor Green
} catch {
    Write-Host "WinRM test failed: $_" -ForegroundColor Red
}

Write-Host "`nBootstrap complete! This machine is ready for Ansible management." -ForegroundColor Green
Write-Host "You can now connect from your Ubuntu machine using:" -ForegroundColor Yellow
Write-Host "  ansible-playbook -i <ip_address>, playbook.yml -u <username> -k" -ForegroundColor White
