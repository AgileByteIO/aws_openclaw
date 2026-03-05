#!/bin/bash
# Local provisioning script - run this from your local machine
# Usage: ./provision-openclaw.sh <ec2-public-ip> <path-to-ssh-key>

set -e

if [ $# -ne 3 ]; then
    echo "Usage: $0 <ec2-public-ip> <path-to-ssh-key>"
    echo "Example: $0 54.123.45.67 ~/.ssh/my-key.pem"
    exit 1
fi

EC2_IP=$1
SSH_KEY=$2
SSH_USER=$3
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== OpenClaw Remote Installation Script ==="
echo "Target EC2: $EC2_IP"
echo "SSH Key: $SSH_KEY"
echo "SSH_USER: $SSH_USER"

# Verify SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    echo "Error: SSH key not found at $SSH_KEY"
    exit 1
fi

# Verify SSH key permissions
chmod 400 "$SSH_KEY"

echo "Testing SSH connection..."
if ! ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$SSH_USER@$EC2_IP" "echo 'Connection successful'"; then
    echo "Error: Cannot connect to Instance"
    exit 1
fi

echo "Uploading installation script..."
scp -i "$SSH_KEY" "$SCRIPT_DIR/install-openclaw.sh" "$SSH_USER@$EC2_IP:/tmp/install-openclaw.sh"

echo "Running installation on remote server..."
ssh -i "$SSH_KEY" "$SSH_USER@$EC2_IP" "chmod +x /tmp/install-openclaw.sh && sudo /tmp/install-openclaw.sh"

echo ""
echo "=== Installation Complete ==="
echo ""
echo "To connect to your server:"
echo "  ssh -i $SSH_KEY $SSH_USER@$EC2_IP"
echo ""
echo "To check installation status:"
echo "  ssh -i $SSH_KEY $SSH_USER@$EC2_IP 'tail -f /var/log/openclaw-install.log'"
echo ""
echo "To run OpenClaw:"
echo "  ssh -i $SSH_KEY $SSH_USER@$EC2_IP"
echo "  sudo su - openclaw"
echo "  ./start-openclaw.sh"
echo ""
