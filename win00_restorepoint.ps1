<#
.SYNOPSIS
  Create a restore point and initialise logging for ARC-AIO Windows setup
#>

$ErrorActionPreference = 'SilentlyContinue'
$LogFile = "$env:SystemDrive\AIO_WinSetup.log"

Write-Host "==> Creating system restore point and log..."
Start-Transcript -Path $LogFile -Append

try {
    Checkpoint-Computer -Description "Pre-AIO-Debloat" -RestorePointType MODIFY_SETTINGS
    Write-Host "Restore point created successfully."
} catch {
    Write-Warning "Unable to create restore point. Ensure System Protection is enabled."
}

Write-Host "==> Log started at $LogFile"
