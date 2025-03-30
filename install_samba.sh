#!/bin/bash

# Samba Server Installer & Configurator for Ubuntu
# ---------------------------------------------------------------
# This script installs Samba, configures a share for /mnt/ntfs,
# and sets up access with a user 'qbittorrent'.
#
# Features:
# - Installs Samba server
# - Configures /mnt/ntfs as a shared directory named 'media'
# - Uses existing 'qbittorrent' user for access
# - Sets up read/write access with authentication
#
# Access the share from another device:
# - Windows: \\<YOUR_SERVER_IP>\media
# - Linux: smb://<YOUR_SERVER_IP>/media
# - Default user: qbittorrent
# - You will set the password during script execution
#
# Usage:
# Make the script executable: chmod +x install_samba.sh
# Run the script with sudo: sudo ./install_samba.sh
# ---------------------------------------------------------------

set -e

echo "Installing Samba..."
sudo apt update && sudo apt install samba samba-common-bin -y

echo "Checking if qbittorrent user exists..."
if ! id "qbittorrent" &>/dev/null; then
    echo "Error: User 'qbittorrent' does not exist. Creating it..."
    sudo adduser --system --group --no-create-home --home /mnt/ntfs qbittorrent
else
    echo "User 'qbittorrent' already exists. Proceeding..."
fi

echo "Setting Samba password for qbittorrent user..."
echo "Please enter a password for Samba access (you'll need this to connect):"
sudo smbpasswd -a qbittorrent
sudo smbpasswd -e qbittorrent  # Enable the Samba user

echo "Configuring Samba share for /mnt/ntfs as 'media'..."
sudo bash -c 'cat > /etc/samba/smb.conf <<EOF
[global]
   workgroup = WORKGROUP
   server string = Samba Server on %h
   security = user
   map to guest = bad user
   wins support = no
   dns proxy = no

[media]
   path = /mnt/ntfs
   browseable = yes
   read only = no
   writable = yes
   valid users = qbittorrent
   create mask = 0775
   directory mask = 0775
   force user = qbittorrent
   force group = qbittorrent
EOF'

echo "Setting correct permissions for /mnt/ntfs..."
sudo chown -R qbittorrent:qbittorrent /mnt/ntfs
sudo chmod -R 775 /mnt/ntfs

echo "Restarting Samba services..."
sudo systemctl restart smbd
sudo systemctl restart nmbd

echo "Enabling Samba services to start on boot..."
sudo systemctl enable smbd
sudo systemctl enable nmbd

echo "Verifying Samba status..."
if systemctl is-active smbd >/dev/null && systemctl is-active nmbd >/dev/null; then
    echo "Success: Samba is running!"
else
    echo "Warning: Samba services failed to start. Check logs with 'journalctl -u smbd' or 'journalctl -u nmbd'"
fi

echo "Samba installed and configured successfully!"
echo "📌 Share name: media"
echo "📌 Access path: \\\\$(hostname -I | awk '{print $1}')\\media (Windows) or smb://$(hostname -I | awk '{print $1}')/media (Linux)"
echo "📌 Username: qbittorrent"
echo "📌 Password: <the password you set>"
echo "📌 If you need to change the password later, use: sudo smbpasswd qbittorrent"
