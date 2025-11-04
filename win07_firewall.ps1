<#
.SYNOPSIS
  Configure firewall rules for Steam and Sunshine
#>

Write-Host "==> Configuring Windows Firewall for Sunshine and Steam..."

# Ensure firewall service is running
Set-Service -Name MpsSvc -StartupType Automatic
Start-Service MpsSvc

# Remove any existing conflicting rules
netsh advfirewall firewall delete rule name="Sunshine"    >$null 2>&1
netsh advfirewall firewall delete rule name="Steam Remote Play" >$null 2>&1

# Sunshine rules
Write-Host "→ Adding Sunshine firewall rules..."
$SunshinePath = "C:\Program Files\Sunshine\sunshine.exe"
if (Test-Path $SunshinePath) {
    netsh advfirewall firewall add rule name="Sunshine" dir=in  action=allow program="$SunshinePath" enable=yes
    netsh advfirewall firewall add rule name="Sunshine" dir=out action=allow program="$SunshinePath" enable=yes
}

# Steam rules
Write-Host "→ Adding Steam firewall rules..."
$SteamPath = "C:\Program Files (x86)\Steam\steam.exe"
if (Test-Path $SteamPath) {
    netsh advfirewall firewall add rule name="Steam Remote Play" dir=in  action=allow program="$SteamPath" enable=yes
    netsh advfirewall firewall add rule name="Steam Remote Play" dir=out action=allow program="$SteamPath" enable=yes
}

Write-Host "✅ Firewall rules applied successfully."
