#!/usr/bin/env bash
set -euo pipefail

# Downloads PearOS-like visual assets from open-source projects.
# Reproducibility: each repository is pinned to a commit SHA.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSET_DIR="${ROOT_DIR}/stage-pearos/files/usr/local/share/pearos-like"
TMP_DIR="${ROOT_DIR}/.cache/theme-sources"

mkdir -p "${ASSET_DIR}" "${TMP_DIR}"

clone_or_refresh() {
  local repo_url="$1"
  local dir_name="$2"
  local commit_sha="$3"

  if [[ ! -d "${TMP_DIR}/${dir_name}/.git" ]]; then
    git clone --depth 1 "${repo_url}" "${TMP_DIR}/${dir_name}"
  fi

  git -C "${TMP_DIR}/${dir_name}" fetch --depth 1 origin "${commit_sha}"
  git -C "${TMP_DIR}/${dir_name}" checkout --detach "${commit_sha}"
}

# WhiteSur GTK theme (open-source) - pear-like look.
clone_or_refresh "https://github.com/vinceliuice/WhiteSur-gtk-theme.git" "WhiteSur-gtk-theme" "5d6a39f58dcaeff8e331ee8a3ef1769681234cb2"

# WhiteSur icon theme.
clone_or_refresh "https://github.com/vinceliuice/WhiteSur-icon-theme.git" "WhiteSur-icon-theme" "f8065c52fef2da5c4f14df298f3fd49ed6f108fa"

# Apple-inspired wallpapers from an open-source collection.
clone_or_refresh "https://github.com/linuxdotexe/nordic-wallpapers.git" "nordic-wallpapers" "f877e40ed2df4667e2de8f6fb0ea060f7f79e0af"

rm -rf "${ASSET_DIR}/WhiteSur-gtk-theme" "${ASSET_DIR}/WhiteSur-icon-theme" "${ASSET_DIR}/wallpapers"
mkdir -p "${ASSET_DIR}/wallpapers"

cp -a "${TMP_DIR}/WhiteSur-gtk-theme" "${ASSET_DIR}/"
cp -a "${TMP_DIR}/WhiteSur-icon-theme" "${ASSET_DIR}/"
cp -a "${TMP_DIR}/nordic-wallpapers/wallpapers/." "${ASSET_DIR}/wallpapers/"

echo "Retrieved source assets into ${ASSET_DIR}"
