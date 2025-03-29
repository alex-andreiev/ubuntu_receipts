#!/bin/bash

# This script installs Plex Media Server on an Ubuntu system.
# It performs the following steps:
# 1. Installs required dependencies (curl, wget).
# 2. Downloads the specified version of Plex Media Server.
# 3. Installs Plex Media Server and enables it as a system service.
# 4. Configures the firewall to allow Plex traffic.
# 5. Creates a default media folder for Plex.

# Usage:
# Make the script executable: chmod +x install_plex.sh
# Run the script with sudo: sudo ./install_plex.sh

# Stop execution on error
set -e

#echo "🔹 Updating package lists..."
#sudo apt update && sudo apt upgrade -y

echo "🔹 Installing dependencies..."
sudo apt install curl wget -y

echo "🔹 Downloading Plex Media Server..."
PLEX_VERSION="plexmediaserver_1.32.5.7349-8f4248874_amd64.deb"
wget "https://downloads.plex.tv/plex-media-server-new/1.32.5.7349-8f4248874/debian/$PLEX_VERSION"

echo "🔹 Installing Plex..."
sudo dpkg -i "$PLEX_VERSION"
sudo systemctl enable --now plexmediaserver

echo "🔹 Allowing firewall access..."
sudo ufw allow 32400/tcp

echo "🔹 Creating media folder..."
sudo mkdir -p /media/plex/movies
sudo chmod -R 777 /media/plex

echo "✅ Installation complete!"
echo "📌 Open Plex in your browser: http://$(hostname -I | awk '{print $1}'):32400/web"

