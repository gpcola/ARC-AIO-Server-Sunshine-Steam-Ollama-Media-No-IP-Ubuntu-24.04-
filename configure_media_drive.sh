#!/bin/bash
# ==============================================================
# configure_media_drive.sh — Storage, shares & mount setup
# ==============================================================

set -e
echo "==> Configuring media and model storage drives..."

# --- Detect drives ---
echo "==> Detecting non-system drives..."
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "loop"

# Ask for target drive
read -rp "Enter the device name for your media drive (e.g. sdb, sdc): " DRIVE

# Validate
if [ ! -b "/dev/$DRIVE" ]; then
    echo "❌ Drive /dev/$DRIVE not found. Exiting."
    exit 1
fi

# Ask for confirmation
read -rp "Format /dev/$DRIVE and create /srv/media + /srv/llm_models? (y/N): " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "==> Formatting /dev/$DRIVE as ext4..."
    umount "/dev/$DRIVE"* || true
    mkfs.ext4 -F "/dev/$DRIVE"
else
    echo "==> Skipping format. Assuming it already contains data."
fi

# --- Create mount points ---
mkdir -p /srv/media /srv/llm_models

# --- Get UUID and update fstab ---
UUID=$(blkid -s UUID -o value /dev/$DRIVE)
if [ -z "$UUID" ]; then
    echo "❌ Could not retrieve UUID for /dev/$DRIVE."
    exit 1
fi

# Add fstab entries if missing
if ! grep -q "$UUID" /etc/fstab; then
cat <<EOF >> /etc/fstab
UUID=$UUID /srv/media ext4 defaults,noatime 0 2
/srv/media/llm /srv/llm_models none bind 0 0
EOF
fi

# --- Mount now ---
mount -a

# --- Fix permissions ---
chown -R gp:gp /srv/media /srv/llm_models
chmod -R 775 /srv/media /srv/llm_models

# --- Samba consistency check ---
if grep -q "\[Media\]" /etc/samba/smb.conf; then
    echo "✅ Samba share already exists."
else
    cat <<'EOF' >>/etc/samba/smb.conf

[Media]
path = /srv/media
browsable = yes
writable = yes
guest ok = yes
read only = no
create mask = 0777
directory mask = 0777
EOF
    systemctl restart smbd
fi

# --- Jellyfin library auto-link ---
if systemctl is-active --quiet jellyfin; then
    echo "==> Linking Jellyfin library to /srv/media..."
    mkdir -p /var/lib/jellyfin/media
    ln -s /srv/media /var/lib/jellyfin/media/library 2>/dev/null || true
    systemctl restart jellyfin
fi

echo ""
echo "---------------------------------------------------------------"
echo " ✅ Media drive configuration complete!"
echo " - Mounted at /srv/media and /srv/llm_models"
echo " - Added to /etc/fstab for persistence"
echo " - Samba share active on network"
echo "---------------------------------------------------------------"
