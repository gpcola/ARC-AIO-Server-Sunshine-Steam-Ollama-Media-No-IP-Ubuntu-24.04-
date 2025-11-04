<#
.SYNOPSIS
  Install Steam, Sunshine, and Intel Arc GPU drivers
#>

Write-Host "==> Installing Steam, Sunshine, and Intel ARC drivers..."

# Ensure Winget is present
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "Winget not available. Run Windows Update to enable App Installer first."
    exit 1
}

# --- Install Steam ---
Write-Host "→ Installing Steam..."
winget install -e --id Valve.Steam --accept-package-agreements --accept-source-agreements

# --- Install Sunshine ---
Write-Host "→ Installing Sunshine..."
$temp = "$env:TEMP\sunshine"
New-Item -ItemType Directory -Force -Path $temp | Out-Null
$rel = (Invoke-RestMethod https://api.github.com/repos/LizardByte/Sunshine/releases/latest).tag_name
Invoke-WebRequest -Uri "https://github.com/LizardByte/Sunshine/releases/download/$rel/SunshineSetup.exe" -OutFile "$temp\SunshineSetup.exe"
Start-Process "$temp\SunshineSetup.exe" -ArgumentList "/VERYSILENT /NORESTART" -Wait
Remove-Item $temp -Recurse -Force

# --- Install Intel ARC driver ---
Write-Host "→ Installing Intel ARC Graphics Driver..."
winget install -e --id Intel.IntelARCGraphicsDriver --accept-package-agreements --accept-source-agreements

Write-Host "✅ Steam, Sunshine, and Intel drivers installed successfully."
