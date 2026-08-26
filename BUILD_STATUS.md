# FeatherOS 1.0 build status

Date: 2026-08-26

## Passed in the Codex workspace

- Shell syntax for all build scripts and hooks.
- Python bytecode compilation for `feather-settings`.
- JSON parsing for Plasma metadata and Firefox policies.
- Required-file and identity checks from `scripts/validate.sh`.
- Official Debian Stable package verification for Calamares, PyQt 6, Fastfetch, Qt 6 Graphical Effects, Plasma 6 and KWin Wayland.

## Not executed in this workspace

The final ISO build and QEMU boot test were not run because this managed Ubuntu container blocks APT's `_apt` user/group transitions (`setgroups: Operation not permitted`). That prevents installing `live-build`, `librsvg2-bin`, QEMU and their dependencies here.

Run these on a normal Debian 13 or Ubuntu 24.04 build machine:

```bash
sudo ./scripts/install-build-deps.sh
./scripts/prepare-branding.sh
./scripts/validate.sh
sudo ./build.sh
./test.sh
```

Do not publish an ISO until it passes an actual live boot and a Calamares installation test in both UEFI and legacy BIOS VMs.
