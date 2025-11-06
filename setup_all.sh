#!/usr/bin/env bash
# ============================================================
# ARC-AIO Unified Setup Script
# Runs 01–08 automatically and prints summary
# ============================================================

set -e
LOGFILE="/var/log/arc_setup.log"
START_TIME=$(date +%s)

echo "============================================================"
echo "        ARC-AIO SERVER INITIALISATION SEQUENCE"
echo "============================================================"
echo "Logging to $LOGFILE"
echo ""

# Ensure we’re in correct folder
cd "$(dirname "$0")"

SCRIPTS=(
  "00_prep.sh"
  "01_base_install.sh"
  "02_services_install.sh"
  "03_monitoring_setup.sh"
  "04_gpu_modes.sh"
  "05_optimisations.sh"
  "06_replit_clone.sh"
  "07_replit_ui.sh"
  "08_gpu_service_toggle.sh"
)

for SCRIPT in "${SCRIPTS[@]}"; do
  if [ -x "$SCRIPT" ]; then
    echo ">>> Running $SCRIPT..."
    bash "$SCRIPT" >>"$LOGFILE" 2>&1
    echo ">>> $SCRIPT completed."
  else
    echo "⚠️  Skipping $SCRIPT (not found or not executable)."
  fi
  echo ""
done

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "============================================================"
echo "             ARC-AIO SETUP COMPLETE"
echo "============================================================"

# --- gather quick summary info ---
IPADDR=$(hostname -I | awk '{print $1}')
UPTIME=$(uptime -p)
DISK=$(df -h / | awk 'NR==2 {print $4}')
GPU=$(lspci | grep -i 'vga' | head -n 1 | cut -d: -f3- | sed 's/^ //')
RAM=$(free -h | awk '/Mem:/ {print $2}')
CODER_PASS=$(grep -A1 'password:' /home/gp/.config/code-server/config.yaml | tail -n1 | awk '{print $2}')

cat <<EOF

System Summary
--------------
Hostname:      $(hostname)
IP Address:    $IPADDR
Uptime:        $UPTIME
Available Disk:$DISK
Total RAM:     $RAM
GPU Detected:  $GPU

Replit Dashboard:
    http://repl.all.ddnskey.com
    User: gp
    Password: ${CODER_PASS:-<see code-server config>}
    Workspace: /srv/replit

Logs:          $LOGFILE
Duration:      ${DURATION}s

Use 'systemctl status' on any service (sunshine, ollama, caddy, nginx)
to check runtime states.

EOF
