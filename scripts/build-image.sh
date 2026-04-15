#!/usr/bin/env bash
set -euo pipefail

# Build a Raspberry Pi ARM64 image with a PearOS-like desktop using pi-gen.
# This script is designed for CI and is fully non-interactive.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${ROOT_DIR}/.work"
PI_GEN_DIR="${WORK_DIR}/pi-gen"
DEPLOY_DIR="${PI_GEN_DIR}/deploy"
PI_GEN_REF="master" # stable branch, with fallback to latest tag/default branch

# shellcheck source=./git-safe.sh
source "${ROOT_DIR}/scripts/git-safe.sh"

mkdir -p "${WORK_DIR}"

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

# pi-gen requires root privileges for mount/chroot/loop device operations.
# Preferred CI path is to run this whole script in a privileged container.
# Fallback for non-container local runs: use sudo for the pi-gen invocation.
run_pi_gen_build() {
  if [[ "${EUID}" -eq 0 ]]; then
    ./build.sh
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    echo "[WARN] build-image.sh is not running as root; using sudo for pi-gen build"
    sudo ./build.sh
    return 0
  fi

  echo "[ERROR] pi-gen requires root privileges. Run in a privileged container or use sudo."
  return 1
}

pushd "${PI_GEN_DIR}" >/dev/null
run_pi_gen_build
popd >/dev/null

mkdir -p "${ROOT_DIR}/out"
cp -a "${DEPLOY_DIR}"/* "${ROOT_DIR}/out/"

echo "Image build complete. Output files are in ${ROOT_DIR}/out"
