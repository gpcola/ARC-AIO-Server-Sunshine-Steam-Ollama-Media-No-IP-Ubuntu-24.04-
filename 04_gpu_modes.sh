#!/bin/bash
# ==============================================================
# 04_gpu_modes.sh — GPU mode manager (AI / Game / Balanced)
# ==============================================================

set -e
MODE_FILE="/var/lib/gpu_mode/current_mode"
mkdir -p "$(dirname "$MODE_FILE")"

# --- Helper: service control ---
pause_services() {
    systemctl stop ollama qbittorrent noip2 jellyfin || true
}
resume_services() {
    systemctl start ollama qbittorrent noip2 jellyfin || true
}

# --- Game Mode ---
game_mode() {
    echo "==> Activating Game Mode..."
    echo "game" > "$MODE_FILE"

    pause_services
    systemctl restart sunshine

    # Set CPU governor to performance
    for CPUF in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo performance | tee "$CPUF" >/dev/null || true
    done

    # Prioritise Arc GPU for rendering, iGPU idle
    echo "==> Prioritising Intel Arc GPU..."
    echo "options i915 enable_dc=0" > /etc/modprobe.d/i915-game.conf
    update-initramfs -u

    echo "✅ Game Mode active. Sunshine is ready."
}

# --- AI Mode ---
ai_mode() {
    echo "==> Activating AI Mode..."
    echo "ai" > "$MODE_FILE"

    # Pause non-AI services
    systemctl stop sunshine jellyfin || true
    systemctl start ollama qbittorrent noip2 || true

    # Governor to performance
    for CPUF in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo performance | tee "$CPUF" >/dev/null || true
    done

    echo "✅ AI Mode active. Ollama ready for inference."
}

# --- Balanced Mode ---
balanced_mode() {
    echo "==> Activating Balanced Mode..."
    echo "balanced" > "$MODE_FILE"

    resume_services
    systemctl restart sunshine ollama || true

    # Governor to schedutil for power balance
    for CPUF in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo schedutil | tee "$CPUF" >/dev/null || true
    done

    echo "✅ Balanced Mode active. All services normal."
}

# --- Show current mode ---
status_mode() {
    if [ -f "$MODE_FILE" ]; then
        echo "Current GPU mode: $(cat "$MODE_FILE")"
    else
        echo "No mode set yet."
    fi
}

# --- CLI interface ---
case "$1" in
    game) game_mode ;;
    ai) ai_mode ;;
    balanced) balanced_mode ;;
    status) status_mode ;;
    *)
        echo "Usage: $0 {game|ai|balanced|status}"
        exit 1
        ;;
esac
