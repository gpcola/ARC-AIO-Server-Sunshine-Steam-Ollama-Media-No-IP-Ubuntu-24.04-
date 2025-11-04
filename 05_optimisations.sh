#!/bin/bash
# ==============================================================
# 05_optimisations.sh — Final system tuning
# ==============================================================

set -e
echo "==> Applying final performance optimisations..."

# --- Install tuned and gamemode ---
apt install -y tuned tuned-utils gamemode libgamemodeauto0 libgamemode0

systemctl enable tuned
tuned-adm profile throughput-performance

# --- Enable zRAM for better memory efficiency ---
echo "==> Enabling zRAM..."
apt install -y zram-tools
cat <<'EOF' >/etc/default/zramswap
ALGO=zstd
PERCENT=50
PRIORITY=100
EOF
systemctl enable zramswap
systemctl start zramswap

# --- Kernel boot parameters ---
echo "==> Applying kernel boot parameters for latency and performance..."
if ! grep -q "mitigations=off" /etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="mitigations=off nowatchdog nosoftlockup nohz_full=all nohz=on tsc=nowatchdog irqaffinity=0 /' /etc/default/grub
    update-grub
fi

# --- Filesystem tuning ---
echo "==> Optimising filesystem mount options..."
cat <<'EOF' >/etc/fstab.d/99-performance.conf
# Apply noatime for all local filesystems
UUID=$(blkid -s UUID -o value $(findmnt -n -o SOURCE /)) / ext4 defaults,noatime,errors=remount-ro 0 1
EOF

# --- Network throughput tweaks ---
echo "==> Enabling advanced TCP features..."
cat <<'EOF' >/etc/sysctl.d/99-network-optimisations.conf
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_no_metrics_save = 1
EOF
sysctl --system

# --- Scheduler optimisations ---
echo "==> Setting tuned CPU scheduler profile..."
tuned-adm profile latency-performance

# --- Optional NVIDIA removal sanity check ---
if lsmod | grep -q nouveau; then
    echo "Removing leftover Nouveau driver..."
    echo "blacklist nouveau" > /etc/modprobe.d/blacklist-nouveau.conf
    update-initramfs -u
fi

# --- Clean up old kernels & cache ---
apt autoremove -y && apt clean

# --- Final system summary ---
echo ""
echo "---------------------------------------------------------------"
echo " ✅ Optimisations complete!"
echo " - Tuned + Gamemode active"
echo " - zRAM configured (50%)"
echo " - Kernel mitigations disabled for performance"
echo " - Filesystem, network and scheduler optimised"
echo "---------------------------------------------------------------"
