#!/bin/bash
# ==============================================================
# 00_prep.sh — Hardware prep and system foundations
# ==============================================================

set -e
echo "==> Starting hardware and system preparation..."

# --- Update and baseline packages ---
apt update -y && apt full-upgrade -y
apt install -y wget curl git unzip p7zip-full build-essential dkms \
    software-properties-common lsb-release ca-certificates gnupg

# --- Enable repositories for additional packages ---
add-apt-repository universe -y
add-apt-repository multiverse -y
apt update -y

# --- Intel GPU Drivers (Arc + iGPU) ---
echo "==> Adding Intel GPU repositories..."
wget -qO - https://repositories.intel.com/graphics/intel-graphics.key | gpg --dearmor | tee /usr/share/keyrings/intel-graphics.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/graphics/ubuntu jammy arc" > /etc/apt/sources.list.d/intel.gpu.list
apt update -y
apt install -y intel-opencl-icd intel-level-zero-gpu level-zero intel-media-va-driver-non-free \
               libmfx1 libva-drm2 libva-x11-2 intel-gpu-tools vainfo clinfo

# --- Mellanox / high-speed NIC setup ---
echo "==> Installing Mellanox 40GbE drivers and tools..."
apt install -y mlnx-ofed-basic mstflint ethtool iperf3 net-tools
echo "mlx5_core" >> /etc/modules

# --- CPU governor tuning ---
apt install -y cpufrequtils
echo 'GOVERNOR="performance"' > /etc/default/cpufrequtils
systemctl enable cpufrequtils

# --- Enable thermal & power management ---
apt install -y thermald powertop
systemctl enable thermald

# --- Create swapfile ---
if ! grep -q swap /etc/fstab; then
    echo "==> Creating 8GB swap file..."
    fallocate -l 8G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# --- Sysctl tuning for network & performance ---
cat <<EOF >/etc/sysctl.d/99-performance.conf
# General performance tuning
fs.file-max = 2097152
vm.swappiness = 10
vm.dirty_ratio = 15

# Networking
net.core.rmem_max = 268435456
net.core.wmem_max = 268435456
net.ipv4.tcp_rmem = 4096 87380 268435456
net.ipv4.tcp_wmem = 4096 65536 268435456
net.ipv4.tcp_congestion_control = bbr
EOF
sysctl --system

# --- Install useful monitoring tools early ---
apt install -y htop nvtop glances lm-sensors

# --- Initial cleanup ---
apt autoremove -y && apt clean

echo "==> Hardware prep complete. Proceeding to base install..."
