#!/usr/bin/env bash
set -euo pipefail

TARGET_USER="${1:-${SUDO_USER:-$(logname 2>/dev/null || echo alex)}}"
QBIT_WEBUI_PORT="${QBIT_WEBUI_PORT:-9091}"
PLEX_UNIT="plexmediaserver.service"
QBIT_TEMPLATE="qbittorrent-nox@.service"
QBIT_UNIT="qbittorrent-nox@${TARGET_USER}.service"
QBIT_OVERRIDE_DIR="/etc/systemd/system/qbittorrent-nox@.service.d"
QBIT_OVERRIDE_FILE="${QBIT_OVERRIDE_DIR}/override.conf"

if ! command -v systemctl >/dev/null 2>&1; then
  echo "systemctl not found; this script requires systemd." >&2
  exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo $0 [username]" >&2
  exit 1
fi

echo "==> Target user: ${TARGET_USER}"

enable_and_start() {
  local unit="$1"
  echo "==> Enabling ${unit}"
  systemctl enable "${unit}"
  echo "==> Starting ${unit}"
  systemctl restart "${unit}" || systemctl start "${unit}"
  echo "==> ${unit}: enabled=$(systemctl is-enabled "${unit}" 2>/dev/null || echo unknown), active=$(systemctl is-active "${unit}" 2>/dev/null || echo unknown)"
}

configure_qbit_override() {
  mkdir -p "${QBIT_OVERRIDE_DIR}"
  cat > "${QBIT_OVERRIDE_FILE}" <<EOT
[Service]
ExecStart=
ExecStart=/usr/bin/qbittorrent-nox --webui-port=${QBIT_WEBUI_PORT}
EOT
  systemctl daemon-reload
  echo "==> qBittorrent systemd override set: ${QBIT_OVERRIDE_FILE}"
}

if systemctl cat "${PLEX_UNIT}" >/dev/null 2>&1; then
  enable_and_start "${PLEX_UNIT}"
else
  echo "[warn] ${PLEX_UNIT} unit not found; skipping Plex."
fi

if systemctl cat "${QBIT_TEMPLATE}" >/dev/null 2>&1; then
  configure_qbit_override
  enable_and_start "${QBIT_UNIT}"
else
  echo "[warn] ${QBIT_TEMPLATE} unit template not found; install qbittorrent-nox first."
fi

echo "==> Listening ports (32400/${QBIT_WEBUI_PORT})"
ss -ltnp | awk -v p=":${QBIT_WEBUI_PORT}" 'NR==1 || /:32400/ || index($0,p)' || true

LAN_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
PLEX_LOCAL_URL="http://127.0.0.1:32400/web/index.html#!/"
QBIT_LOCAL_URL="http://localhost:${QBIT_WEBUI_PORT}/"

echo
echo "Plex URL:        ${PLEX_LOCAL_URL}"
if [[ -n "${LAN_IP}" ]]; then
  echo "Plex LAN URL:    http://${LAN_IP}:32400/web/index.html#!/"
  echo "qBittorrent URL: http://${LAN_IP}:${QBIT_WEBUI_PORT}/"
else
  echo "qBittorrent URL: ${QBIT_LOCAL_URL}"
fi

echo "==> Endpoint checks"
if curl -fsS -I "${PLEX_LOCAL_URL}" >/dev/null; then
  echo "[ok] Plex Web UI endpoint is reachable"
else
  echo "[warn] Plex Web UI endpoint check failed"
fi
if curl -fsS -I "${QBIT_LOCAL_URL}" >/dev/null; then
  echo "[ok] qBittorrent endpoint is reachable"
else
  echo "[warn] qBittorrent endpoint check failed"
fi

echo "Note: http://localhost:32400/ can return Unauthorized/Bad Request depending on headers/session. Use /web/index.html#!/"
