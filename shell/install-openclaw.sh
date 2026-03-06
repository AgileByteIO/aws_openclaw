#!/bin/bash
set -e

# Log output to file
exec > >(tee /var/log/openclaw-install.log)
exec 2>&1

echo "=== Starting OpenClaw Installation ==="
echo "Timestamp: $(date)"

# Update system packages
echo "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
apt-get update
apt-get upgrade -y

# Install required dependencies
echo "Installing dependencies..."
apt-get install -y \
    curl \
    ca-certificates \
    dbus-user-session

# Install Node.js (required for OpenClaw CLI)
echo "Installing Node.js (latest LTS)..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs

# Mount data volume if available
echo "Checking for data volume..."
DATA_DEVICE="${DATA_DEVICE:-}"

if [ -n "$DATA_DEVICE" ] && [ -b "$DATA_DEVICE" ]; then
    :
elif [ -b /dev/xvdf ]; then
    DATA_DEVICE="/dev/xvdf"
elif [ -b /dev/nvme1n1 ]; then
    DATA_DEVICE="/dev/nvme1n1"
elif [ -b /dev/sdb ]; then
    DATA_DEVICE="/dev/sdb"
elif [ -b /dev/vdb ]; then
    DATA_DEVICE="/dev/vdb"
else
    DETECTED_DEVICE=$(lsblk -ndo NAME,TYPE | grep -v 'sda' | grep -v 'vda' | grep -m 1 'disk' | awk '{print $1}')
    if [ -n "$DETECTED_DEVICE" ] && [ -b "/dev/$DETECTED_DEVICE" ]; then
        DATA_DEVICE="/dev/$DETECTED_DEVICE"
    fi
fi

if [ -n "$DATA_DEVICE" ] && [ -b "$DATA_DEVICE" ]; then
    if [ "$DATA_DEVICE" = "/dev/sda" ] || [ "$DATA_DEVICE" = "/dev/vda" ]; then
        echo "Skipping root disk $DATA_DEVICE for data volume"
        DATA_DEVICE=""
    fi
fi

if [ -n "$DATA_DEVICE" ] && [ -b "$DATA_DEVICE" ]; then
    echo "Data volume found ($DATA_DEVICE), formatting and mounting..."
    if ! blkid "$DATA_DEVICE" | grep -q TYPE; then
        mkfs.ext4 "$DATA_DEVICE"
    fi
    mkdir -p /data
    if ! mountpoint -q /data; then
        mount "$DATA_DEVICE" /data
    fi
    DATA_UUID=$(blkid -s UUID -o value "$DATA_DEVICE")
    if [ -n "$DATA_UUID" ] && ! grep -q "^UUID=$DATA_UUID /data " /etc/fstab; then
        echo "UUID=$DATA_UUID /data ext4 defaults,nofail 0 2" >> /etc/fstab
    fi

    # Use /data as the OpenClaw home
    mkdir -p /data/openclaw
    if ! id -u openclaw > /dev/null 2>&1; then
        useradd -m -d /home/openclaw -s /bin/bash openclaw
    fi
    chown openclaw:openclaw /data/openclaw

    if [ -d /home/openclaw ] && [ ! -L /home/openclaw ]; then
        if [ "$(ls -A /home/openclaw 2>/dev/null)" ]; then
            shopt -s dotglob
            mv /home/openclaw/* /data/openclaw/ || true
            shopt -u dotglob
        fi
        rmdir /home/openclaw 2>/dev/null || true
    fi

    if [ ! -L /home/openclaw ]; then
        ln -s /data/openclaw /home/openclaw
    fi
fi

# Ensure openclaw user exists
if ! id -u openclaw > /dev/null 2>&1; then
    useradd -m -d /home/openclaw -s /bin/bash openclaw
fi

# Configure npm global prefix and PATH for openclaw user
echo "Configuring npm global prefix..."
sudo -u openclaw mkdir -p /home/openclaw/.npm-global/bin
sudo -u openclaw npm config set prefix /home/openclaw/.npm-global
if ! grep -q '/home/openclaw/.npm-global/bin' /home/openclaw/.bashrc; then
    echo 'export PATH="/home/openclaw/.npm-global/bin:$PATH"' >> /home/openclaw/.bashrc
fi

# Enable user-level systemd and runtime dir for headless servers
echo "Configuring user-level systemd..."
loginctl enable-linger openclaw
if ! grep -q 'XDG_RUNTIME_DIR=/run/user/' /home/openclaw/.bashrc; then
    echo 'export XDG_RUNTIME_DIR=/run/user/$(id -u)' >> /home/openclaw/.bashrc
fi

# Install OpenClaw agent CLI
echo "Installing OpenClaw agent CLI..."
sudo -u openclaw bash -c "cd /home/openclaw && curl -fsSL https://openclaw.ai/install.sh | bash"

# Set permissions
chown -R openclaw:openclaw /home/openclaw

# Create README for the user
cat > /home/openclaw/README.txt << 'EOF'
OpenClaw Installation Complete!

Home Directory: /home/openclaw (on /data volume)

To use OpenClaw agent CLI:
1. Switch to openclaw user: sudo su - openclaw
2. Run: openclaw --help

Logs:
- Installation log: /var/log/openclaw-install.log

For more information:
https://openclaw.ai/
EOF

chown openclaw:openclaw /home/openclaw/README.txt

echo "=== OpenClaw Installation Complete ==="
echo "Timestamp: $(date)"
echo "Check /home/openclaw/README.txt for usage instructions"
