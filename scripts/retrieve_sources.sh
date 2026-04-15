#!/usr/bin/env bash
set -euo pipefail

# Downloads PearOS-like visual assets from open-source projects.
# Commit hashes can disappear (force-push/history rewrite), so we use
# clone_repo_safe to gracefully fallback to a tag/default branch.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSET_DIR="${ROOT_DIR}/stage-pearos/files/usr/local/share/pearos-like"
TMP_DIR="${ROOT_DIR}/.cache/theme-sources"

# shellcheck source=./git-safe.sh
source "${ROOT_DIR}/scripts/git-safe.sh"

mkdir -p "${ASSET_DIR}" "${TMP_DIR}"

# Desired refs can be blank (auto-select latest tag/default branch),
# or set to a known tag/branch/commit when a deterministic pin is available.
clone_repo_safe "https://github.com/vinceliuice/WhiteSur-gtk-theme.git" "" "${TMP_DIR}/WhiteSur-gtk-theme"
clone_repo_safe "https://github.com/vinceliuice/WhiteSur-icon-theme.git" "" "${TMP_DIR}/WhiteSur-icon-theme"
clone_repo_safe "https://github.com/linuxdotexe/nordic-wallpapers.git" "" "${TMP_DIR}/nordic-wallpapers"

rm -rf "${ASSET_DIR}/WhiteSur-gtk-theme" "${ASSET_DIR}/WhiteSur-icon-theme" "${ASSET_DIR}/wallpapers"
mkdir -p "${ASSET_DIR}/wallpapers"

cp -a "${TMP_DIR}/WhiteSur-gtk-theme" "${ASSET_DIR}/"
cp -a "${TMP_DIR}/WhiteSur-icon-theme" "${ASSET_DIR}/"
cp -a "${TMP_DIR}/nordic-wallpapers/wallpapers/." "${ASSET_DIR}/wallpapers/"

echo "Retrieved source assets into ${ASSET_DIR}"
