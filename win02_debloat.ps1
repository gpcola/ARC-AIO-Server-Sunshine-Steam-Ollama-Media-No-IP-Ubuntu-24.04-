<#
.SYNOPSIS
  Remove bloatware apps and disable telemetry collection
#>

Write-Host "==> Removing default apps..."
Get-AppxPackage *xboxapp*        | Remove-AppxPackage
Get-AppxPackage *bing*           | Remove-AppxPackage
Get-AppxPackage *news*           | Remove-AppxPackage
Get-AppxPackage *widgets*        | Remove-AppxPackage
Get-AppxPackage *teams*          | Remove-AppxPackage
Get-AppxPackage *cortana*        | Remove-AppxPackage
Get-AppxPackage *yourphone*      | Remove-AppxPackage
Get-AppxPackage *feedbackhub*    | Remove-AppxPackage
Get-AppxPackage *officehub*      | Remove-AppxPackage

Write-Host "==> Disabling telemetry..."
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f

Write-Host "==> Disabling telemetry tasks..."
$tasks = @(
 '\Microsoft\Windows\Application Experience\ProgramDataUpdater',
 '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
 '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip'
)
foreach ($t in $tasks) { schtasks /Change /TN $t /Disable 2>$null }

Write-Host "Bloatware removed and telemetry disabled."
