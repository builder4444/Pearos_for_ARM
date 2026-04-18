#!/usr/bin/env bash
set -euo pipefail

# Build a Raspberry Pi ARM64 image with a PearOS-like desktop using pi-gen.
# This script is designed for CI and is fully non-interactive.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${ROOT_DIR}/.work"
PI_GEN_DIR="${WORK_DIR}/pi-gen"
DEPLOY_DIR="${PI_GEN_DIR}/deploy"
# Keep empty to use the repository default branch automatically.
PI_GEN_REF=""

mkdir -p "${WORK_DIR}"

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

"${ROOT_DIR}/scripts/retrieve_sources.sh"

clone_repo_safe "https://github.com/RPi-Distro/pi-gen.git" "${PI_GEN_REF}" "${PI_GEN_DIR}"

# Inject custom stage with package installs + desktop customization.
rm -rf "${PI_GEN_DIR}/stage-pearos"
cp -a "${ROOT_DIR}/stage-pearos" "${PI_GEN_DIR}/stage-pearos"

cat > "${PI_GEN_DIR}/config" <<'CFG'
IMG_NAME='pearos-like-rpi'
RELEASE='bookworm'
TARGET_ARCH='arm64'
DEPLOY_COMPRESSION='xz'
ENABLE_SSH=1
FIRST_USER_NAME='pi'
FIRST_USER_PASS='raspberry'
PUBKEY_ONLY_SSH=0
LOCALE_DEFAULT='en_US.UTF-8'
KEYBOARD_KEYMAP='us'
KEYBOARD_LAYOUT='English (US)'
TIMEZONE_DEFAULT='UTC'
DISABLE_FIRST_BOOT_USER_RENAME=1
STAGE_LIST='stage0 stage1 stage2 stage-pearos'
CFG

pushd "${PI_GEN_DIR}" >/dev/null
./build.sh
popd >/dev/null

mkdir -p "${ROOT_DIR}/out"
cp -a "${DEPLOY_DIR}"/* "${ROOT_DIR}/out/"

echo "Image build complete. Output files are in ${ROOT_DIR}/out"
