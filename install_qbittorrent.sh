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
# ---------------------------------------------------------------

set -e

echo "Updating system and installing qBittorrent-nox..."
sudo apt update && sudo apt install qbittorrent-nox -y

echo "Creating qbittorrent user..."
sudo adduser --system --group --home /mnt/ntfs/movies qbittorrent
sudo chown -R qbittorrent:qbittorrent /mnt/ntfs/movies

echo "Starting qBittorrent for initial setup..."
sudo -u qbittorrent qbittorrent-nox & sleep 10
sudo pkill -f qbittorrent-nox

echo "Configuring qBittorrent settings..."
CONFIG_DIR="/home/qbittorrent/.config/qBittorrent"
sudo -u qbittorrent mkdir -p $CONFIG_DIR
sudo bash -c "cat > $CONFIG_DIR/qBittorrent.conf <<EOF
[Preferences]
WebUI\Port=9091
EOF"
sudo chown -R qbittorrent:qbittorrent $CONFIG_DIR

echo "Creating systemd service..."
sudo bash -c 'cat > /etc/systemd/system/qbittorrent.service <<EOF
[Unit]
Description=qBittorrent-nox service
After=network.target

[Service]
User=qbittorrent
Group=qbittorrent
ExecStart=/usr/bin/qbittorrent-nox --profile=/mnt/ntfs/movies
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF'

echo "Reloading systemd and enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable qbittorrent
sudo systemctl start qbittorrent

echo "qBittorrent installed and configured successfully!"
echo "Access the Web UI at: http://<YOUR_SERVER_IP>:9091"
echo "Default login: admin | Password: adminadmin"

