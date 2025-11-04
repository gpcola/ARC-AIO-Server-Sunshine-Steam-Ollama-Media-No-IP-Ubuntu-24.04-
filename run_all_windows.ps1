<#
.SYNOPSIS
  Run all ARC-AIO Windows post-install scripts in sequence
#>

$ErrorActionPreference = 'Continue'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogFile   = "$env:SystemDrive\AIO_WinSetup.log"

Write-Host "`n==============================================================="
Write-Host "      Starting ARC-AIO Windows Stream-Only Configuration"
Write-Host "==============================================================="
Write-Host "Logs: $LogFile`n"
Start-Transcript -Path $LogFile -Append

$Steps = @(
    "win00_restorepoint.ps1",
    "win01_power_plan.ps1",
    "win02_debloat.ps1",
    "win03_services.ps1",
    "win04_visuals.ps1",
    "win05_runtimes.ps1",
    "win06_apps.ps1",
    "win07_firewall.ps1",
    "win08_updates.ps1",
    "win99_summary.ps1"
)

foreach ($step in $Steps) {
    $Path = Join-Path $ScriptDir $step
    if (Test-Path $Path) {
        Write-Host "`n---------------------------------------------------------------"
        Write-Host "Running $step ..."
        Write-Host "---------------------------------------------------------------`n"
        try {
            & "$Path"
        } catch {
            Write-Warning "⚠️  $step encountered an error: $($_.Exception.Message)"
            Pause
        }
    } else {
        Write-Warning "❌ Missing script: $step"
    }
}

Write-Host "`n==============================================================="
Write-Host "✅  ARC-AIO Windows configuration finished."
Write-Host "Reboot your system before first stream."
Write-Host "==============================================================="

Stop-Transcript
