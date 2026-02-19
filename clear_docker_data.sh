#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./clear_docker_data.sh [--force] [--dry-run]

Options:
  --force    Run without confirmation prompt.
  --dry-run  Show Docker disk usage only (no deletion).
  -h, --help Show this help.

What gets removed:
- Stopped containers
- Unused networks
- Dangling and unused images
- Build cache
- Unused volumes
USAGE
}

FORCE=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed or not in PATH."
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Cannot access Docker daemon. Try running with a user in the docker group or use sudo."
  exit 1
fi

echo "Docker disk usage (before):"
docker system df || true

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo
  echo "Dry run mode enabled. No data was deleted."
  exit 0
fi

if [[ "$FORCE" -ne 1 ]]; then
  echo
  read -r -p "This will remove unused Docker data. Continue? [y/N] " confirm
  case "$confirm" in
    y|Y|yes|YES)
      ;;
    *)
      echo "Cancelled."
      exit 0
      ;;
  esac
fi

echo
echo "Cleaning Docker data..."
docker system prune -a --volumes -f

echo
echo "Docker disk usage (after):"
docker system df || true

echo
echo "Done."
