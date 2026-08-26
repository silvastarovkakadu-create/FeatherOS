#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${EUID} -eq 0 ]] || { echo "Run: sudo ./scripts/install-build-deps.sh" >&2; exit 1; }
apt-get update
apt-get install -y live-build debootstrap squashfs-tools xorriso isolinux syslinux-common grub-pc-bin grub-efi-amd64-bin mtools dosfstools rsync imagemagick librsvg2-bin qemu-system-x86 ovmf shellcheck
