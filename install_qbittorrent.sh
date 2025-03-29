#!/bin/bash

# qBittorrent-nox Auto Installer & Configurator for Ubuntu Server
# ---------------------------------------------------------------
# This script installs qBittorrent-nox, configures it to run as a systemd service,
# and sets up a download directory on an NTFS partition.
#
# Features:
# - Installs qbittorrent-nox
# - Creates a dedicated user "qbittorrent"
# - Configures automatic startup via systemd
# - Changes the download directory to /mnt/ntfs/movies
# - Sets the Web UI to run on port 9091
#
# Access the qBittorrent Web UI at: http://<YOUR_SERVER_IP>:9091
# Default login: admin
# Default password: adminadmin
#
# Usage:
# Make the script executable: chmod +x install_qbittorrent.sh
# Run the script with sudo: sudo ./install_qbittorrent.sh
# ---------------------------------------------------------------
set -e

echo "Updating system and installing qBittorrent-nox..."
sudo apt update && sudo apt install qbittorrent-nox -y

echo "Creating qbittorrent user..."
if ! id "qbittorrent" &>/dev/null; then
    sudo adduser --system --group --no-create-home --home /mnt/ntfs/movies qbittorrent
else
    echo "User qbittorrent already exists. Skipping..."
fi

echo "Setting correct permissions for /mnt/ntfs/movies..."
sudo chown -R qbittorrent:qbittorrent /mnt/ntfs/movies
sudo chmod -R 775 /mnt/ntfs/movies

echo "Configuring qBittorrent settings..."
CONFIG_DIR="/mnt/ntfs/movies/.config/qBittorrent"
sudo mkdir -p "$CONFIG_DIR"
sudo chown qbittorrent:qbittorrent "$CONFIG_DIR"
sudo chmod 775 "$CONFIG_DIR"

CONFIG_FILE="$CONFIG_DIR/qBittorrent.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating configuration file..."
    sudo -u qbittorrent bash -c "cat > $CONFIG_FILE <<EOF
[LegalNotice]
Accepted=true

[Preferences]
Downloads\\SavePath=/mnt/ntfs/movies/
WebUI\\Port=9091
WebUI\\Address=*

[WebUI]
Port=9091
Address=*
EOF"
fi

echo "Verifying configuration directory ownership..."
sudo chown -R qbittorrent:qbittorrent "$CONFIG_DIR"
sudo chmod -R 775 "$CONFIG_DIR"

echo "Creating systemd service..."
sudo bash -c 'cat > /etc/systemd/system/qbittorrent.service <<EOF
[Unit]
Description=qBittorrent-nox service
After=network.target

[Service]
User=qbittorrent
Group=qbittorrent
ExecStart=/usr/bin/qbittorrent-nox --profile=/mnt/ntfs/movies/.config --webui-port=9091
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF'

echo "Reloading systemd and enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable qbittorrent
sudo systemctl restart qbittorrent

echo "Verifying port..."
sleep 5  # Даём время на запуск
if sudo netstat -tuln | grep -q ":9091"; then
    echo "Success: qBittorrent is running on port 9091"
else
    echo "Warning: qBittorrent is not running on port 9091"
    echo "Checking current port..."
    sudo netstat -tuln | grep qbittorrent || echo "qBittorrent not running"
fi

echo "qBittorrent installed and configured successfully!"
echo "📌 Open Web UI in your browser: http://$(hostname -I | awk '{print $1}'):9091"
echo "Default login: admin | Password: adminadmin"
echo "Config file location: $CONFIG_FILE"
