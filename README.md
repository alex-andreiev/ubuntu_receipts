# Ubuntu Receipts Scripts

Collection of helper scripts for Ubuntu server setup and maintenance.

## Scripts

### `fix_apt_repos.sh`
Resets APT repository sources to clean Ubuntu Noble sources and disables third-party repo files.

- Backs up `/etc/apt/sources.list.d` to `/etc/apt/sources.list.d.backup.<timestamp>`
- Moves third-party source files to `/etc/apt/disabled-sources`
- Writes a fresh Ubuntu `ubuntu.sources`
- Runs `apt clean` and `apt update`

Usage:
```bash
chmod +x fix_apt_repos.sh
./fix_apt_repos.sh [sudo_password]
```

Example:
```bash
./fix_apt_repos.sh mypassword
```

Notes:
- If no password is passed, the script uses its internal default value.
- This script modifies system APT configuration.

---

### `install_plex.sh`
Installs Plex Media Server, enables the service, opens firewall port `32400/tcp`, and creates `/media/plex/movies`.

Usage:
```bash
chmod +x install_plex.sh
sudo ./install_plex.sh
```

After install:
- Open Plex at `http://<server-ip>:32400/web`

---

### `install_qbittorrent.sh`
Installs and configures `qbittorrent-nox` as a systemd service.

What it sets up:
- System user: `qbittorrent`
- Download path: `/mnt/ntfs/movies`
- Config path: `/mnt/ntfs/movies/.config/qBittorrent/qBittorrent.conf`
- Web UI port: `9091`
- Service: `/etc/systemd/system/qbittorrent.service`

Usage:
```bash
chmod +x install_qbittorrent.sh
sudo ./install_qbittorrent.sh
```

After install:
- Web UI: `http://<server-ip>:9091`
- Username: `admin`
- Password: read script output/logs for generated password

---

### `install_samba.sh`
Installs Samba and configures a guest-access share:

- Share name: `media`
- Share path: `/mnt/ntfs`
- Guest read/write access enabled

Usage:
```bash
chmod +x install_samba.sh
sudo ./install_samba.sh
```

Access examples:
- Windows: `\\<server-ip>\media`
- Linux: `smb://<server-ip>/media`

Notes:
- Rewrites `/etc/samba/smb.conf`.

---

### `clear_docker_data.sh`
Cleans unused Docker data to reclaim disk space.

What gets removed:
- Stopped containers
- Unused networks
- Dangling and unused images
- Build cache
- Unused volumes

Usage:
```bash
chmod +x clear_docker_data.sh
./clear_docker_data.sh [--dry-run] [--force]
```

Options:
- `--dry-run`: shows Docker disk usage only, does not delete
- `--force`: skip confirmation prompt

Examples:
```bash
./clear_docker_data.sh --dry-run
./clear_docker_data.sh
./clear_docker_data.sh --force
```

Requirements:
- Docker installed
- Access to Docker daemon (docker group or sudo)

## General Notes

- Most scripts require `sudo` and make system-level changes.
- Review each script before running in production.
- These scripts are designed for Ubuntu-based systems.
