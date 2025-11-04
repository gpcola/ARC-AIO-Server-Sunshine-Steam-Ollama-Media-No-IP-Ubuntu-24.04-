#!/bin/bash
# ==============================================================
# setup_all.sh — Master unattended setup chain
# ==============================================================

set -e

echo "=============================================================="
echo "     ARC-AIO Server: Full Ubuntu Setup Automation"
echo "=============================================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Confirm network connection
ping -c 2 8.8.8.8 >/dev/null 2>&1 || {
  echo "⚠️  No network connection detected. Connect and rerun."
  exit 1
}

echo "==> Running all setup phases..."
sleep 2

# Each stage logs to /var/log for review
bash "$SCRIPT_DIR/00_prep.sh" | tee /var/log/00_prep.log
bash "$SCRIPT_DIR/01_base_install.sh" | tee /var/log/01_base_install.log
bash "$SCRIPT_DIR/02_services_install.sh" | tee /var/log/02_services_install.log
bash "$SCRIPT_DIR/03_monitoring_setup.sh" | tee /var/log/03_monitoring_setup.log
bash "$SCRIPT_DIR/04_gpu_modes.sh" | tee /var/log/04_gpu_modes.log
bash "$SCRIPT_DIR/05_optimisations.sh" | tee /var/log/05_optimisations.log
bash "$SCRIPT_DIR/configure_media_drive.sh" | tee /var/log/configure_media_drive.log

echo ""
echo "✅ All setup phases completed."
echo "Reboot now to finalise configuration."
