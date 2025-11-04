<#
.SYNOPSIS
  Disable unneeded Windows services for a lean streaming build
#>

Write-Host "==> Disabling background and telemetry services..."

$DisableList = @(
    'DiagTrack',            # Connected User Experience and Telemetry
    'dmwappushservice',     # WAP Push
    'WerSvc',               # Windows Error Reporting
    'WSearch',              # Windows Search
    'SysMain',              # Superfetch / SysMain
    'RetailDemo',           # Retail demo
    'RemoteRegistry',       # Remote Registry
    'CDPSvc',               # Connected Devices Platform
    'CDPUserSvc',           # Connected Devices Platform User
    'MapsBroker',           # Downloaded Maps Manager
    'DeliveryOptimization'  # Windows Update Delivery
)

foreach ($svc in $DisableList) {
    Write-Host "→ Stopping and disabling service: $svc"
    Stop-Service $svc -Force -ErrorAction SilentlyContinue
    Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue
}

Write-Host "✅ Services disabled successfully."
