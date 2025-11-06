#!/usr/bin/env bash
# ARC-AIO 08_gpu_service_toggle.sh – Ollama & Sunshine toggle integration
set -e

echo "==> Linking Ollama & Sunshine to dashboard toggles..."

# Ensure services exist
systemctl list-unit-files | grep -q sunshine.service || \
  echo "[Unit]
Description=Sunshine Game Streaming
After=network.target

[Service]
ExecStart=/usr/bin/sunshine
Restart=on-failure
[Install]
WantedBy=multi-user.target" >/etc/systemd/system/sunshine.service

systemctl daemon-reload
systemctl enable sunshine.service || true

systemctl list-unit-files | grep -q ollama.service || \
  echo "[Unit]
Description=Ollama LLM Server
After=network.target

[Service]
ExecStart=/usr/local/bin/ollama serve
Restart=on-failure
[Install]
WantedBy=multi-user.target" >/etc/systemd/system/ollama.service

systemctl daemon-reload
systemctl enable ollama.service || true

# Extend API
cat >/opt/replit-api/gpu_services.sh <<'EOF'
#!/usr/bin/env bash
ACTION=$1
SERVICES=(ollama sunshine)

case "$ACTION" in
  start|stop)
    for s in "${SERVICES[@]}"; do
      systemctl "$ACTION" "$s"
    done ;;
  toggle)
    for s in "${SERVICES[@]}"; do
      systemctl is-enabled "$s" &>/dev/null && \
        systemctl disable "$s" || systemctl enable "$s"
    done ;;
  status)
    for s in "${SERVICES[@]}"; do
      systemctl is-active "$s" && echo "$s: active" || echo "$s: inactive"
    done ;;
esac
EOF
chmod +x /opt/replit-api/gpu_services.sh

# Add API route hook
if ! grep -q "gpu" /opt/replit-api/replit-api.sh; then
  sed -i '/ports)/i \
  gpu)\n    /opt/replit-api/gpu_services.sh "$2";;\n' /opt/replit-api/replit-api.sh
fi

echo "✅ Ollama & Sunshine toggles linked."
