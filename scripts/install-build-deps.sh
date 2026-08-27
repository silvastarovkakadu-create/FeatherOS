#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${EUID} -eq 0 ]] || { echo "Run: sudo ./scripts/install-build-deps.sh" >&2; exit 1; }
apt-get update
apt-get install -y python3 live-build debootstrap squashfs-tools xorriso genisoimage file initramfs-tools-core cpio isolinux syslinux-common grub-pc-bin grub-efi-amd64-bin mtools dosfstools rsync imagemagick librsvg2-bin qemu-system-x86 qemu-utils ovmf shellcheck
