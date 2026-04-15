# PearOS-like Raspberry Pi ARM Image Builder

This repository provides a fully automated pipeline that builds a **bootable Raspberry Pi 4+ ARM64 image** with a **PearOS-inspired desktop experience** using only open-source components.

## Design overview

- **Image builder**: [`pi-gen`](https://github.com/RPi-Distro/pi-gen) (Raspberry Pi OS image factory).
- **Base OS**: Debian Bookworm (ARM64) via pi-gen stages.
- **Desktop stack**: XFCE + LightDM + Plank.
- **PearOS-like styling**: WhiteSur GTK + WhiteSur icons + curated wallpapers.
- **CI**: GitHub Actions workflow produces compressed image artifacts and checksums.
- **Privilege model**: CI runs build steps in a `--privileged` Docker container so pi-gen can perform chroot/mount/loop operations.

## Directory structure

```text
.
├── .github/
│   └── workflows/
│       └── build-pearos-rpi-image.yml   # CI pipeline
├── config/
│   └── pearos-package-map.csv           # Feature → package mapping
├── docs/
│   └── BUILD_PIPELINE.md                # Build pipeline explanation
├── scripts/
│   ├── build-image.sh                   # Main non-interactive image build entrypoint
│   ├── git-safe.sh                      # Resilient clone/checkout helper with fallback
│   └── retrieve_sources.sh              # Fetch theme & visual assets with fallback
└── stage-pearos/
    ├── 00-packages                      # apt packages injected into pi-gen custom stage
    ├── 00-run.sh                        # Theme/icon install and wallpapers
    ├── 01-run.sh                        # Autologin + XFCE defaults + dock autostart
    └── files/
        └── usr/local/share/pearos-like  # Asset landing zone copied into image
```

## Quick start

```bash
./scripts/build-image.sh
```

Build outputs are placed in `out/`.
