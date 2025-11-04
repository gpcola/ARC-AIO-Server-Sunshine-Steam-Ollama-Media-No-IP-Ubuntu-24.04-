<#
.SYNOPSIS
  Install required runtimes for games and Sunshine
#>

Write-Host "==> Installing core runtimes (.NET, VC++, DirectX)..."

# Ensure Winget is available
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Warning "Winget not found. Please run Windows Update or App Installer to enable it."
    exit 1
}

# Microsoft Visual C++ Redistributables (2015+)
winget install -e --id Microsoft.VCRedist.2015+.x64 --accept-package-agreements --accept-source-agreements

# .NET Desktop Runtime
winget install -e --id Microsoft.DotNet.DesktopRuntime.8 --accept-package-agreements --accept-source-agreements

# DirectX runtime
winget install -e --id Microsoft.DirectX --accept-package-agreements --accept-source-agreements

Write-Host "✅ Core runtimes installed."
