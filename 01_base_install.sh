#!/bin/bash
# ==============================================================
# 01_base_install.sh — System base configuration
# ==============================================================

set -e
echo "==> Running base install configuration..."

# --- Create main user if missing ---
if ! id "gp" &>/dev/null; then
    echo "==> Creating user gp..."
    adduser --disabled-password --gecos "" gp
    usermod -aG sudo,adm,video,render gp
fi

# --- Disable root SSH login ---
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart ssh

# --- Enable UFW firewall ---
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 8080,47984:48010/tcp
ufw --force enable

# --- Ensure iGPU + Arc B580 both active ---
echo "==> Checking GPUs..."
lspci | grep -Ei 'vga|3d|display'

echo "==> Configuring Intel iGPU and Arc support..."
cat <<'EOF' >/etc/modprobe.d/i915.conf
options i915 enable_guc=3 force_probe=*
EOF
update-initramfs -u

# --- Blacklist Nouveau just in case ---
echo "blacklist nouveau" > /etc/modprobe.d/blacklist-nouveau.conf
update-initramfs -u

# --- Install Mesa and Vulkan stack ---
apt install -y mesa-utils vulkan-tools vulkan-validationlayers libvulkan1 libvulkan-dev \
    libva-drm2 libva-x11-2 mesa-va-drivers mesa-vdpau-drivers

# --- Intel firmware ---
apt install -y intel-gpu-firmware intel-microcode

# --- PRIME render offload for hybrid usage ---
cat <<'EOF' >/usr/share/X11/xorg.conf.d/20-intel-prime.conf
Section "Device"
    Identifier "Intel Graphics"
    Driver "modesetting"
EndSection

Section "Device"
    Identifier "Intel ARC"
    Driver "modesetting"
    Option "PrimaryGPU" "yes"
EndSection
EOF

# --- Install general productivity & dev tools ---
apt install -y tmux vim neofetch curl wget p7zip-full unzip zip rsync parted gparted

# --- Set timezone to UTC (adjust later if desired) ---
timedatectl set-timezone UTC

# --- Enable GRUB dual-boot detection (for Windows 11) ---
echo "==> Enabling Windows dual-boot support..."
apt install -y os-prober
echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
update-grub

# --- Configure power management ---
apt install -y tlp irqbalance
systemctl enable tlp irqbalance
tlp start

# --- Ensure performance governor ---
echo 'GOVERNOR="performance"' > /etc/default/cpufrequtils
systemctl enable cpufrequtils || true

# --- Misc polish ---
echo "alias ll='ls -alF --color=auto'" >> /home/gp/.bashrc
echo "neofetch" >> /home/gp/.bashrc

echo "==> Base system configuration complete. Proceed to 02_services_install.sh."
