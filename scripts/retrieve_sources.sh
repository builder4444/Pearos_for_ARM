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

  if [[ ! -d "${dest}/.git" ]]; then
    git clone "${repo_url}" "${dest}" || exit 1
  else
    git -C "${dest}" fetch --all --tags --prune
  fi

  pushd "${dest}" >/dev/null

  local default_branch
  default_branch="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@' || true)"

  if [[ -n "${default_branch}" ]]; then
    git checkout "${default_branch}" || true
    git pull --ff-only origin "${default_branch}" || true
  fi

  if [[ -n "${ref}" ]]; then
    if ! git checkout "${ref}"; then
      echo "[WARN] Failed to checkout ${ref}, using default branch"
      if [[ -n "${default_branch}" ]]; then
        git checkout "${default_branch}" || true
      fi
    fi
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
