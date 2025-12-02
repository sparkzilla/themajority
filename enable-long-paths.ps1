# Enable Windows Long Path Support
# This script enables support for paths longer than 260 characters in Windows
# Requires Administrator privileges

Write-Host "Enabling Windows Long Path Support..." -ForegroundColor Green
Write-Host "This requires Administrator privileges." -ForegroundColor Yellow

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "`nERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run this script again." -ForegroundColor Yellow
    exit 1
}

# Registry path for long path support
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
$regName = "LongPathsEnabled"
$regValue = 1

try {
    # Check if the key already exists
    $currentValue = Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue
    
    if ($currentValue -and $currentValue.LongPathsEnabled -eq 1) {
        Write-Host "`nLong path support is already enabled!" -ForegroundColor Green
    } else {
        # Set the registry value
        Set-ItemProperty -Path $regPath -Name $regName -Value $regValue -Type DWord
        Write-Host "`nLong path support has been enabled!" -ForegroundColor Green
        Write-Host "`nIMPORTANT: You must restart your computer for this change to take effect." -ForegroundColor Yellow
        Write-Host "After restarting, Hugo should be able to build files with long paths." -ForegroundColor Yellow
        
        $restart = Read-Host "`nWould you like to restart now? (Y/N)"
        if ($restart -eq 'Y' -or $restart -eq 'y') {
            Write-Host "Restarting computer in 10 seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 10
            Restart-Computer
        }
    }
} catch {
    Write-Host "`nERROR: Failed to enable long path support!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "`nDone!" -ForegroundColor Green


