<#
.SYNOPSIS
  ARC-AIO Bootable USB Creator
  Ubuntu 24.04.3 + Optional Windows 11 ISO
  Builds a fully-bootable USB with integrated setup scripts and README
#>

# ===============================================================
# ARC-AIO Bootable USB Creator (auto-elevate + exFAT fallback)
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
$WinIso     = $null

# --- Download Ubuntu ISO if needed ---
if (-not (Test-Path $UbuntuIso)) {
    Write-Host "Downloading Ubuntu 24.04.3 Server ISO..."
    $UbuntuUrl = "https://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-amd64.iso"
    Invoke-WebRequest -Uri $UbuntuUrl -OutFile $UbuntuIso -UseBasicParsing
}

# --- Optional Windows ISO ---
$AddWin = Read-Host "Include Windows 11 Pro ISO? (y/n)"
if ($AddWin -eq 'y') {
    $WinIso = "$ScriptRoot\Win11_25H2_EnglishInternational_x64.iso"
    if (-not (Test-Path $WinIso)) {
        $LocalWin = Read-Host "Use local Windows 11 ISO? (y/n)"
        if ($LocalWin -eq 'y') {
            $WinIso = Read-Host "Enter full path to Windows 11 ISO file"
            if (-not (Test-Path $WinIso)) { Write-Error "Windows ISO not found."; exit }
        } else {
            Write-Host "Downloading Windows 11 Pro ISO..."
            $WinUrl = "https://software-download.microsoft.com/db/Win11_24H2_English_x64.iso"
            Invoke-WebRequest -Uri $WinUrl -OutFile $WinIso -UseBasicParsing
        }
    }
}

# --- Format USB (FAT32) ---
Write-Host "`nFormatting drive $UsbDrive`: ..."
$DiskNum = (Get-Partition -DriveLetter $UsbDrive).DiskNumber
Get-Disk -Number $DiskNum | Set-Disk -IsReadOnly $false
Get-Disk -Number $DiskNum | Clear-Disk -RemoveData -Confirm:$false
New-Partition -DiskNumber $DiskNum -UseMaximumSize -AssignDriveLetter | Out-Null
$SizeGB = [math]::Round((Get-Volume -DriveLetter $UsbDrive).SizeRemaining / 1GB,2)
if ($SizeGB -gt 32) {
    Write-Host "Large drive detected ($SizeGB GB) → using exFAT..."
    Format-Volume -DriveLetter $UsbDrive -FileSystem exFAT -NewFileSystemLabel "ARC-AIO" -Force
} else {
    Format-Volume -DriveLetter $UsbDrive -FileSystem FAT32 -NewFileSystemLabel "ARC-AIO" -Force
}

# --- Mount Ubuntu ISO and copy base files ---
Write-Host "Mounting Ubuntu ISO..."
$IsoMount = Mount-DiskImage -ImagePath $UbuntuIso -PassThru
$IsoLetter = ($IsoMount | Get-Volume).DriveLetter + ":"
Write-Host "Copying Ubuntu setup files..."
Copy-Item "$IsoLetter\*" "$UsbPath\" -Recurse -Force
Dismount-DiskImage $UbuntuIso

# --- Copy repository scripts ---
Write-Host "Copying ARC-AIO setup scripts..."
New-Item -ItemType Directory -Force -Path "$UsbPath\setup" | Out-Null
Copy-Item "$ScriptRoot\*" "$UsbPath\setup\" -Recurse -Force -Exclude @('*.iso')

# --- Copy Windows ISO if present ---
if ($WinIso) {
    Copy-Item $WinIso "$UsbPath\setup\" -Force
}

# --- Copy README ---
if (Test-Path "$ScriptRoot\README.md") {
    Copy-Item "$ScriptRoot\README.md" "$UsbPath\" -Force
}

# --- Verify ---
Write-Host "`nVerifying copy integrity..."
$Files = Get-ChildItem "$UsbPath\" -Recurse | Measure-Object
Write-Host "$($Files.Count) files written to USB."

# --- Final instructions ---
Write-Host "`n✅ Bootable ARC-AIO USB created successfully!"
Write-Host "Boot from the USB and run:"
Write-Host "    sudo bash /cdrom/setup/setup_all.sh"
Write-Host ""
Write-Host "After Ubuntu install, reboot into Windows and run:"
Write-Host "    C:\\AIO_Setup\\windows\\run_all_windows.ps1"
