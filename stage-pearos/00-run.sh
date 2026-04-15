#!/bin/bash
set -euo pipefail

# Install WhiteSur GTK and icon themes system-wide from retrieved sources.
ASSET_DIR="/usr/local/share/pearos-like"

if [ -d "${ASSET_DIR}/WhiteSur-gtk-theme" ]; then
  bash "${ASSET_DIR}/WhiteSur-gtk-theme/install.sh" -l -c dark -s 220 || true
fi

if [ -d "${ASSET_DIR}/WhiteSur-icon-theme" ]; then
  bash "${ASSET_DIR}/WhiteSur-icon-theme/install.sh" -a || true
fi

mkdir -p /usr/share/backgrounds/pearos-like
if [ -d "${ASSET_DIR}/wallpapers" ]; then
  cp -a "${ASSET_DIR}/wallpapers/." /usr/share/backgrounds/pearos-like/
fi
