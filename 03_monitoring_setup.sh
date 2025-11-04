#!/bin/bash
# ==============================================================
# 03_monitoring_setup.sh — Monitoring & telemetry setup
# ==============================================================

set -e
echo "==> Setting up monitoring stack..."

# --- Install dependencies ---
apt install -y lm-sensors hddtemp nvme-cli smartmontools curl wget python3-pip jq

# --- Sensors configuration ---
echo "==> Configuring hardware sensors..."
yes | sensors-detect || true
systemctl enable kmod

# --- Glances (CLI dashboard) ---
echo "==> Installing Glances..."
pip3 install glances[web] bottle psutil
cat <<'EOF' >/etc/systemd/system/glances.service
[Unit]
Description=Glances - Web-based monitoring
After=network.target

[Service]
ExecStart=/usr/local/bin/glances -w
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable glances
systemctl start glances

# --- Netdata (real-time web monitoring) ---
echo "==> Installing Netdata..."
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --disable-telemetry
systemctl enable netdata

# --- Node Exporter (for Prometheus / optional) ---
echo "==> Installing Node Exporter..."
useradd -rs /bin/false node_exporter || true
cd /tmp
VER=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | jq -r '.tag_name')
wget -q "https://github.com/prometheus/node_exporter/releases/download/${VER}/node_exporter-${VER#v}.linux-amd64.tar.gz"
tar -xzf node_exporter-*.tar.gz
cp node_exporter-*/node_exporter /usr/local/bin/

cat <<'EOF' >/etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# --- Disk SMART and NVMe monitoring ---
systemctl enable smartd
systemctl start smartd

# --- Custom dashboard note ---
cat <<'EOF' >/root/MONITORING_INFO.txt
Access monitoring dashboards:

Glances Web: http://<server_ip>:61208
Netdata:      http://<server_ip>:19999
NodeExporter: http://<server_ip>:9100/metrics
EOF

# --- Cleanup ---
apt autoremove -y && apt clean

echo "==> Monitoring stack setup complete."
echo "Proceed to 04_gpu_modes.sh for GPU toggling and performance management."
