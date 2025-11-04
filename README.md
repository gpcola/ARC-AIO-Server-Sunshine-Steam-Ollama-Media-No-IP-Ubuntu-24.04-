# ARC-AIO Server  
### Ubuntu 24.04 + Windows 11 Dual Boot | AI • Game Streaming • Media

A complete hybrid workstation environment for **AI inference, game streaming, and media serving**,  
powered by Ubuntu 24.04 Server and a lean Windows 11 Pro installation.

---

## 🧭 Overview

**Hardware Baseline**

| Component | Example |
|------------|----------|
| CPU | Intel Core i5-12400 (12th Gen) |
| GPU 1 | Intel Arc B580 (primary for AI & games) |
| GPU 2 | Intel UHD 770 iGPU (media/transcode) |
| RAM | 64 GB DDR5-6000 CL30 |
| Network | Mellanox QSFP+ 40 Gb Dual NIC + 10 Gb SFP+ Switch |
| Storage | 1 TB NVMe + 10 TB HDD |

---

## 🐧 Ubuntu 24.04 Server

| Feature | Description |
|----------|-------------|
| **Ollama + local LLMs** | GPU-accelerated AI inference |
| **Sunshine Server** | Game-streaming host (Moonlight-compatible) |
| **qBittorrent** | Headless torrent + VPN ready |
| **Jellyfin** | DLNA + browser-based media library |
| **No-IP DDNS** | Dynamic DNS for public reachability |
| **LibreHardwareMonitor Bridge** | Temperature dashboard |
| **Netdata + Glances + Node Exporter** | Real-time monitoring stack |
| **GPU Mode Switcher** | AI / Game / Balanced toggle (Arc ⇄ iGPU) |
| **Media Drive Setup** | `/srv/media` and `/srv/llm_models` shares |
| **System Optimisations** | Tuned, zRAM, BBR, noatime, low-latency kernel |

---

## 🪟 Windows 11 Pro (dual-boot)

Purpose-built for **Steam + Sunshine** streaming only.  
All telemetry, bloatware, and background tasks removed.

**Installed Automatically**

- Steam  
- Sunshine (latest release)  
- Intel Arc GPU drivers  
- VC++ / .NET / DirectX runtimes  

**Performance Tweaks**

- Ultimate Performance power plan  
- Disabled updates, Cortana, Widgets, FeedbackHub  
- Minimal services set (no SysMain, Search, DiagTrack, etc.)  
- Visual effects off, animations disabled  
- Firewall rules for Steam & Sunshine  

---

## 🗂️ Folder Layout

```
/
├─ setup_all.sh
├─ 00_prep.sh
├─ 01_base_install.sh
├─ 02_services_install.sh
├─ 03_monitoring_setup.sh
├─ 04_gpu_modes.sh
├─ 05_optimisations.sh
├─ configure_media_drive.sh
├─ Make-BootUSB_Ubuntu.ps1
├─ README.md
└─ windows/
   ├─ win00_restorepoint.ps1
   ├─ win01_power_plan.ps1
   ├─ win02_debloat.ps1
   ├─ win03_services.ps1
   ├─ win04_visuals.ps1
   ├─ win05_runtimes.ps1
   ├─ win06_apps.ps1
   ├─ win07_firewall.ps1
   ├─ win08_updates.ps1
   ├─ win99_summary.ps1
   └─ run_all_windows.ps1
```

---

## ⚙️ USB Creation (Windows)

1. Plug in a USB ≥ 16 GB.  
2. Open PowerShell (Admin).  
3. Run:

   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\Make-BootUSB_Ubuntu.ps1
   ```

4. Confirm the target drive when prompted.  
   - Ubuntu ISO downloads automatically.  
   - Optional Windows 11 ISO (local or download).  
   - All scripts + this README copied automatically.

Boot the machine from the USB to install Ubuntu first,  
then reboot into Windows and run `windows\run_all_windows.ps1`.

---

## 🚀 Post-Install Commands

**Ubuntu**
```bash
sudo bash /cdrom/setup/setup_all.sh
sudo /opt/modes/04_gpu_modes.sh game     # or ai / balanced
```

**Windows**
```powershell
cd "C:\AIO_Setup\windows"
.\run_all_windows.ps1
```

---

## 🌐 Browser-Accessible Services

| Service | URL | Purpose |
|----------|-----|----------|
| **Sunshine Dashboard** | https://<server-ip>:47990 | Manage game streaming sessions |
| **Jellyfin Media Server** | http://<server-ip>:8096 | Stream local media library |
| **Glances Web UI** | http://<server-ip>:61208 | Lightweight system monitor |
| **Netdata Dashboard** | http://<server-ip>:19999 | Full-stack performance graphs |
| **Node Exporter** | http://<server-ip>:9100/metrics | Prometheus metrics endpoint |
| **qBittorrent Web UI** | http://<server-ip>:8080 | Download manager |
| **LibreHardwareMonitor Bridge** | http://<server-ip>:9525 | Temperature & sensor telemetry |
| **Samba Media Share** | \\\\<server-ip>\\Media | Network file access |

---

## 🧠 Tips

- **GPU Mode Switch**:  
  `sudo /opt/modes/04_gpu_modes.sh game|ai|balanced`
- **No-IP Update**:  
  Edit `/etc/no-ip2.conf` and run `sudo systemctl restart noip2`.
- **Logs**:  
  All stages write to `/var/log/00–05_*.log`.
- **Windows Restore**:  
  Use restore point `Pre-AIO-Debloat`.

---

## 🗾 Credits

Built for ARC B580 hybrid servers by  
**Gail Trueman / 1LG Digital**  
[GitHub Repo → gpcola/ARC-AIO-Server-Sunshine-Steam-Ollama-Media-No-IP-Ubuntu-24.04-](https://github.com/gpcola/ARC-AIO-Server-Sunshine-Steam-Ollama-Media-No-IP-Ubuntu-24.04-)

