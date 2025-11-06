# ARC-AIO Replit Dashboard

## Overview
Adds a Replit-style, browser-based development and control environment to the ARC-AIO Ubuntu server.  
Provides access to code-server (VS Code in browser), Sunshine, Ollama, and local app previews.

---

## ✨ Features
- **code-server + Caddy** – VS Code accessible at `http://repl.all.ddnskey.com`
- **Dynamic service detection** – dashboard lists active local apps automatically
- **LAN auto-login** for 192.168.1.0/24 and 10.29.1.0/24 (toggleable)
- **GPU Service Toggles** – start/stop or enable/disable Ollama + Sunshine
- **Configurable service names** (`replit-defaults.json`)
- **Trusted LAN toggle** directly in the UI sidebar
- **One-click bundle** via `bundle.sh`

---

## 📁 Folder Layout
| Path | Purpose |
|------|----------|
| `/srv/replit/ui/` | Dashboard static files |
| `/opt/replit-api/` | Backend scripts and API handlers |
| `/etc/replit-defaults.json` | Rename / hide services |
| `/etc/replit-flags.json` | Dashboard toggles & LAN flag |
| `/etc/nginx/conf.d/trusted_auth.conf` | Nginx LAN-auth include |

---

## 🚀 Access
**Local:** [http://repl.all.ddnskey.com](http://repl.all.ddnskey.com)  
If inside trusted LAN → auto-login.  
If remote → password required (set during `06_replit_clone.sh` install).

---

## 🧩 Dashboard Controls
### Toolbox
- Toggle autostart
- Toggle toolbox visibility
- Adjust autonomy level (0–3)
- Toggle trusted LAN access

### GPU Services
- Start Ollama + Sunshine  
- Stop Ollama + Sunshine  
- Toggle auto-start at boot

---

## ⚙️ Configuration
### Rename / Hide Services
Edit `/etc/replit-defaults.json`:
```json
{
  "5173": {"name": "Preview", "visible": true},
  "8080": {"name": "Editor", "visible": true}
}
