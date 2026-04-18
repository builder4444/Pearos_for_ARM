#!/usr/bin/env bash
set -euo pipefail

# Downloads PearOS-like visual assets from open-source projects.
# Uses stable refs when available and safely falls back to upstream default branches.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSET_DIR="${ROOT_DIR}/stage-pearos/files/usr/local/share/pearos-like"
TMP_DIR="${ROOT_DIR}/.cache/theme-sources"

mkdir -p "${ASSET_DIR}" "${TMP_DIR}"

clone_repo_safe() {
  local repo_url="$1"
  local ref="$2"
  local dest="$3"
  local default_branch=""

  rm -rf "${dest}"
  git clone "${repo_url}" "${dest}" || exit 1

  pushd "${dest}" >/dev/null

  default_branch="$(git remote show origin | awk '/HEAD branch/ {print $NF}' || true)"

  if [[ -n "${ref}" ]]; then
    if git fetch --all --tags && git rev-parse --verify "${ref}" >/dev/null 2>&1; then
      git checkout "${ref}" || true
      echo "[INFO] Using ref ${ref}"
    else
      echo "[WARN] Invalid ref '${ref}'"
      if [[ -n "${default_branch}" ]]; then
        git checkout "${default_branch}" || true
        echo "[INFO] Fallback to default branch '${default_branch}'"
      fi
    fi
  elif [[ -n "${default_branch}" ]]; then
    git checkout "${default_branch}" || true
    echo "[INFO] Using default branch '${default_branch}'"
  fi

  popd >/dev/null
}

# WhiteSur GTK theme (open-source) - pear-like look.
clone_repo_safe "https://github.com/vinceliuice/WhiteSur-gtk-theme.git" "main" "${TMP_DIR}/WhiteSur-gtk-theme"

# WhiteSur icon theme.
clone_repo_safe "https://github.com/vinceliuice/WhiteSur-icon-theme.git" "main" "${TMP_DIR}/WhiteSur-icon-theme"

# Apple-inspired wallpapers from an open-source collection.
clone_repo_safe "https://github.com/linuxdotexe/nordic-wallpapers.git" "main" "${TMP_DIR}/nordic-wallpapers"

rm -rf "${ASSET_DIR}/WhiteSur-gtk-theme" "${ASSET_DIR}/WhiteSur-icon-theme" "${ASSET_DIR}/wallpapers"
mkdir -p "${ASSET_DIR}/wallpapers"

cp -a "${TMP_DIR}/WhiteSur-gtk-theme" "${ASSET_DIR}/"
cp -a "${TMP_DIR}/WhiteSur-icon-theme" "${ASSET_DIR}/"
cp -a "${TMP_DIR}/nordic-wallpapers/wallpapers/." "${ASSET_DIR}/wallpapers/"

echo "Retrieved source assets into ${ASSET_DIR}"
