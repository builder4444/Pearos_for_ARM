# Build pipeline details

## 1) Source retrieval

`scripts/retrieve_sources.sh` fetches open-source visual components used to emulate PearOS aesthetics:

- WhiteSur GTK Theme
- WhiteSur Icon Theme
- Wallpaper collection

The retrieval logic uses `clone_repo_safe` from `scripts/git-safe.sh` to avoid hard failures when a pinned commit no longer exists upstream.

## 2) Package mapping

`config/pearos-package-map.csv` maps UI/UX expectations (dock, launcher, themes, apps) to ARM64-available Debian packages.

## 3) Image building

`scripts/build-image.sh` performs:

1. Retrieve visual sources.
2. Clone `pi-gen` with safe checkout + fallback.
3. Inject custom `stage-pearos`.
4. Build ARM64 image with `STAGE_LIST='stage0 stage1 stage2 stage-pearos'`.
5. Copy resulting `.img.xz` and related outputs into `out/`.

## 4) Safe git fallback strategy

`scripts/git-safe.sh` introduces resilient clone behavior for CI:

1. Clone/fetch with retries.
2. Attempt the requested ref (commit/tag/branch).
3. If missing, fall back to the latest tag (preferred).
4. If no tag is available, fall back to the default branch (`origin/HEAD`, then `main`/`master`).

This prevents failures like:

`fatal: remote error: upload-pack: not our ref <commit-hash>`

## 5) System customization

`stage-pearos` applies system-wide customizations during image construction:

- Installs XFCE, LightDM, Plank, and daily desktop utilities.
- Enables LightDM autologin to user `pi`.
- Sets default session to XFCE.
- Installs WhiteSur themes/icons from source assets.
- Seeds `/etc/skel` defaults for appearance and Plank autostart.

## 6) GitHub Actions automation

Workflow `.github/workflows/build-pearos-rpi-image.yml`:

- Triggers on `push` and `workflow_dispatch`.
- Installs builder dependencies.
- Runs `./scripts/build-image.sh`.
- Generates SHA256 checksums.
- Uploads generated image artifacts.
