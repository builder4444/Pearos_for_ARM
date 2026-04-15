#!/usr/bin/env bash

# Shared resilient git clone/checkout helpers for CI automation.
# Behavior:
# 1) Clone/fetch repository with retries.
# 2) Try desired ref (commit/tag/branch) if provided.
# 3) Fallback to latest tag (preferred) or default branch.
# 4) Print warnings and keep going when possible.

set -euo pipefail

log_info() {
  echo "[INFO] $*"
}

log_warn() {
  echo "[WARN] $*" >&2
}

retry_cmd() {
  local attempts="$1"
  local sleep_secs="$2"
  shift 2

  local i=1
  while (( i <= attempts )); do
    if "$@"; then
      return 0
    fi

    if (( i == attempts )); then
      return 1
    fi

    log_warn "Command failed (attempt ${i}/${attempts}): $*"
    sleep "${sleep_secs}"
    i=$((i + 1))
  done
}

get_default_branch() {
  local repo_dir="$1"

  git -C "${repo_dir}" remote set-head origin --auto >/dev/null 2>&1 || true
  local origin_head
  origin_head="$(git -C "${repo_dir}" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"

  if [[ -n "${origin_head}" ]]; then
    echo "${origin_head#origin/}"
  else
    # conservative fallback for repos without origin/HEAD metadata
    echo "main"
  fi
}

checkout_with_fallback() {
  local repo_dir="$1"
  local desired_ref="${2:-}"

  # 1) Explicit desired ref.
  if [[ -n "${desired_ref}" ]]; then
    if git -C "${repo_dir}" checkout --detach "${desired_ref}" 2>/dev/null || git -C "${repo_dir}" checkout "${desired_ref}" 2>/dev/null; then
      log_info "Checked out requested ref '${desired_ref}' in ${repo_dir}"
      return 0
    fi
    log_warn "Requested ref '${desired_ref}' not found in ${repo_dir}; using fallback strategy"
  fi

  # 2) Prefer latest version-like tag.
  local latest_tag
  latest_tag="$(git -C "${repo_dir}" tag --sort=-version:refname | head -n1 || true)"
  if [[ -n "${latest_tag}" ]]; then
    if git -C "${repo_dir}" checkout --detach "${latest_tag}"; then
      log_info "Using latest tag fallback '${latest_tag}' in ${repo_dir}"
      return 0
    fi
    log_warn "Latest tag fallback '${latest_tag}' failed in ${repo_dir}"
  fi

  # 3) Fallback to latest commit on default branch.
  local default_branch
  default_branch="$(get_default_branch "${repo_dir}")"

  if git -C "${repo_dir}" checkout "${default_branch}"; then
    if git -C "${repo_dir}" pull --ff-only origin "${default_branch}"; then
      log_info "Using default branch fallback '${default_branch}' in ${repo_dir}"
      return 0
    fi
  fi

  # Final branch fallback for repositories that still use master.
  if [[ "${default_branch}" != "master" ]] && git -C "${repo_dir}" checkout master 2>/dev/null; then
    git -C "${repo_dir}" pull --ff-only origin master 2>/dev/null || true
    log_info "Using fallback branch 'master' in ${repo_dir}"
    return 0
  fi

  return 1
}

clone_repo_safe() {
  local repo_url="$1"
  local desired_ref="${2:-}"
  local dest_dir="$3"

  export GIT_TERMINAL_PROMPT=0

  if [[ ! -d "${dest_dir}/.git" ]]; then
    rm -rf "${dest_dir}"
    retry_cmd 3 2 git clone --no-single-branch "${repo_url}" "${dest_dir}" || {
      log_warn "Unable to clone ${repo_url} after retries"
      return 1
    }
  else
    retry_cmd 3 2 git -C "${dest_dir}" fetch --all --tags --prune || {
      log_warn "Unable to refresh ${repo_url} after retries"
      return 1
    }
  fi

  checkout_with_fallback "${dest_dir}" "${desired_ref}" || {
    log_warn "Unable to checkout any usable ref for ${repo_url}"
    return 1
  }

  return 0
}
