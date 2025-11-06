<#
.SYNOPSIS
  ARC-AIO Bootable USB Creator (Ubuntu + Windows)
  Creates a fully bootable USB for automated ARC-AIO server setup.
#>

# ===============================================================
# ARC-AIO Bootable USB Creator – Final Version
# ===============================================================

# --- Auto-elevate if not admin ---
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "🔒 Relaunching as Administrator..."
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# --- Temporarily bypass execution policy ---
if ((Get-ExecutionPolicy) -ne 'Bypass') {
    Set-ExecutionPolicy Bypass -Scope Process -Force
}

$ErrorActionPreference = 'Stop'
Write-Host "`n=== ARC-AIO USB Creator ===`n"

# --- Detect removable drives ---
Write-Host "Available removable drives:`n"
Get-Volume | Where-Object DriveType -eq 'Removable' | Format-Table DriveLetter,FileSystemLabel,SizeRemaining -AutoSize

# --- Confirm target drive ---
$UsbDrive = Read-Host "Enter target USB drive letter (e.g. E)"
if (-not (Test-Path "$UsbDrive`:")) { Write-Error "Invalid drive letter."; exit }

$Confirm = Read-Host "⚠️  ALL DATA ON $UsbDrive`: WILL BE ERASED. Continue? (y/n)"
if ($Confirm -ne 'y') { Write-Host "Aborted."; exit }

# --- Working paths ---
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$UsbPath    = "$UsbDrive`:"
$UbuntuIso  = "$ScriptRoot\ubuntu-24.04.3-live-server-amd64.iso"
$WinIso     = "$ScriptRoot\Win11_24H2_English_x64.iso"

# --- Download ISOs if missing ---
if (-not (Test-Path $UbuntuIso)) {
    Write-Host "`nDownloading Ubuntu 24.04.3 Server ISO..."
    $UbuntuUrl = "https://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-amd64.iso"
    Invoke-WebRequest -Uri $UbuntuUrl -OutFile $UbuntuIso -UseBasicParsing
}

if (-not (Test-Path $WinIso)) {
    Write-Host "`nDownloading Windows 11 Pro ISO..."
    $WinUrl = "https://software-download.microsoft.com/db/Win11_24H2_English_x64.iso"
    Invoke-WebRequest -Uri $WinUrl -OutFile $WinIso -UseBasicParsing
}

# --- Format USB using DiskPart ---
Write-Host "`nFormatting drive $UsbDrive`: ..."
$DiskNum = (Get-Partition -DriveLetter $UsbDrive).DiskNumber
$DiskSizeGB = [math]::Round((Get-Disk -Number $DiskNum).Size / 1GB, 2)

$diskpartScript = @"
select disk $DiskNum
clean
convert gpt
create partition primary
format fs=exfat quick label=ARC-AIO
assign letter=$UsbDrive
exit
"@
$diskpartScript | diskpart | Out-Null
Write-Host "Disk $DiskNum formatted as exFAT ($DiskSizeGB GB)."

# --- Mount Ubuntu ISO and copy contents ---
Write-Host "Mounting Ubuntu ISO..."
$IsoMount = Mount-DiskImage -ImagePath $UbuntuIso -PassThru
Start-Sleep -Seconds 3
$IsoLetter = ($IsoMount | Get-Volume).DriveLetter + ":"
if (-not (Test-Path "$IsoLetter\")) {
    Write-Error "ISO mount failed."
    Dismount-DiskImage $UbuntuIso
    exit
}

Write-Host "Copying Ubuntu setup files..."
robocopy "$IsoLetter\" "$UsbPath\" /E /NFL /NDL /NJH /NJS /NC /NS > $null
Dismount-DiskImage $UbuntuIso

# --- Create setup folder ---
Write-Host "Copying ARC-AIO setup scripts..."
New-Item -ItemType Directory -Force -Path "$UsbPath\setup" | Out-Null
Copy-Item "$ScriptRoot\*" "$UsbPath\setup\" -Recurse -Force -Exclude @('*.iso')

# --- Copy README if present ---
if (Test-Path "$ScriptRoot\README_Replit.md") {
    Copy-Item "$ScriptRoot\README_Replit.md" "$UsbPath\" -Force
}

# --- Copy Windows ISO ---
Write-Host "Copying Windows ISO..."
Copy-Item $WinIso "$UsbPath\setup\" -Force

# --- Verify copy ---
Write-Host "`nVerifying copy integrity..."
$Files = Get-ChildItem "$UsbPath\" -Recurse | Measure-Object
Write-Host "$($Files.Count) files written to USB."

# --- Summary ---
Write-Host "`n✅ Bootable ARC-AIO USB created successfully!"
Write-Host "---------------------------------------------"
Write-Host "Ubuntu ISO:   $UbuntuIso"
Write-Host "Windows ISO:  $WinIso"
Write-Host "Target Drive: $UsbDrive`:"
Write-Host "---------------------------------------------"
Write-Host "Boot from the USB and run:"
Write-Host "    sudo bash /cdrom/setup/setup.sh"
Write-Host ""
Write-Host "After Ubuntu install, reboot into Windows and run:"
Write-Host "    C:\\AIO_Setup\\windows\\run_all_windows.ps1"
Write-Host ""
Write-Host "Safely eject the USB drive when finished."
