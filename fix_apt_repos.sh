#!/usr/bin/env bash
set -euo pipefail

SUDO_PASS="${1:-cnj12}"
DISABLED_DIR="/etc/apt/disabled-sources"
BACKUP_TAG="$(date +%F-%H%M%S)"

sudo_run() {
  printf '%s\n' "$SUDO_PASS" | sudo -S -p '' "$@"
}

echo "[1/6] Backing up APT sources..."
sudo_run mkdir -p "$DISABLED_DIR"
sudo_run cp -a /etc/apt/sources.list.d "/etc/apt/sources.list.d.backup.$BACKUP_TAG"

echo "[2/6] Disabling third-party repos..."
for f in /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
  [ -e "$f" ] || continue
  case "$f" in
    */ubuntu.sources|*/ubuntu.sources.curtin.orig) continue ;;
  esac
  sudo_run mv "$f" "$DISABLED_DIR"/
done

echo "[3/6] Writing clean Ubuntu noble sources..."
TMP_FILE="$(mktemp)"
cat > "$TMP_FILE" <<'SRC'
Types: deb
URIs: http://archive.ubuntu.com/ubuntu/
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
SRC
sudo_run install -m 0644 "$TMP_FILE" /etc/apt/sources.list.d/ubuntu.sources
rm -f "$TMP_FILE"

echo "[4/6] Cleaning APT cache..."
sudo_run apt clean

echo "[5/6] Updating package lists..."
sudo_run apt update

echo "[6/6] Done."
echo "Disabled repos moved to: $DISABLED_DIR"
echo "Backup created at: /etc/apt/sources.list.d.backup.$BACKUP_TAG"
