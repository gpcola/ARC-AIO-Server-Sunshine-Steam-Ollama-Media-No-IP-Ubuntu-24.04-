# ARC-AIO Bootable USB Creator

## Overview
This tool creates a **bootable USB drive** that installs and configures the **ARC-AIO Server**, including:
- Ubuntu 24.04.3 Server (downloaded automatically if not present)
- Optional Windows 11 Pro 24H2 ISO (also auto-downloaded if missing)
- Preloaded setup scripts and post-install configuration tools
- Automatic exFAT formatting for large drives
- Full compatibility with high-capacity USB drives (up to 2TB)

---

## ✨ Key Features

- **Automatic ISO Download** – The script fetches the latest Ubuntu and Windows images if not found locally.
- **Universal Formatting** – Uses DiskPart for robust formatting and exFAT support for any drive size.
- **Robust Copying** – Uses Robocopy to reliably copy all files and preserve folder structure.
- **Auto-Elevation** – Automatically relaunches with Administrator privileges when required.
- **Execution Policy Bypass** – Temporarily adjusts PowerShell policy for smooth script execution.

---

## 🧰 Files Included

| File | Description |
|------|-------------|
| `Make-BootUSB_Ubuntu.ps1` | Main PowerShell script to create the bootable ARC-AIO USB. |
| `setup_all.sh` | Master setup script executed after booting into Ubuntu from the USB. |
| `00_prep.sh` – `05_optimisations.sh` | Modular setup scripts for the ARC-AIO system. |
| `configure_media_drive.sh` | Post-install configuration for media storage and AI model directories. |
| `README.md` | This documentation file. |

---

## ⚙️ Prerequisites

- Windows 10 or 11 (Administrator rights required)
- PowerShell 5.1 or newer
- Active internet connection (for ISO download)
- USB drive (minimum 16GB, 64GB+ recommended)
- Sufficient disk space for downloaded ISOs (15GB+)

---

## 🚀 Usage Instructions

1. **Open PowerShell as Administrator.**
2. Navigate to the folder containing `Make-BootUSB_Ubuntu.ps1`.
3. Run:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\Make-BootUSB_Ubuntu.ps1
   ```
4. Select your USB drive letter when prompted.
5. The script will automatically download missing ISOs, format the USB, and copy all required setup files.
6. Once completed, boot your target system from the USB.

---

## 🧩 Post-Installation

After Ubuntu installation completes:
```bash
sudo bash /cdrom/setup/setup_all.sh
```
After Windows installation (if included):
```powershell
C:\AIO_Setup\windows\run_all_windows.ps1
```

---

## 🌐 Services Accessible via Browser
Once installed, the ARC-AIO system provides the following services locally:

| Service | Default Port | Description |
|----------|---------------|-------------|
| `Sunshine` | 47989 | Game streaming host compatible with Moonlight. |
| `Ollama` | 11434 | Local AI model runner (LLMs). |
| `qBittorrent-nox` | 8080 | Web-based torrent management. |
| `No-IP` | n/a | Dynamic DNS service for remote access. |
| `LibreHardwareMonitor Exporter` | 8085 | System metrics for local dashboard. |

---

## 💡 Notes

- If ISOs fail to download, check your connection or temporarily disable your firewall.
- The script will always prefer **local ISOs** over downloads.
- The generated USB is fully compatible with both UEFI and legacy BIOS.

---

## ✅ Summary
- One-step bootable USB creator.
- Handles large drives and missing ISOs.
- Integrates all ARC-AIO setup and monitoring tools.

**After the USB is created, simply boot from it and let the setup run unattended.**
