#!/usr/bin/env bash
set -Eeuo pipefail

ISO="${1:?usage: validate-iso.sh path/to/FeatherOS.iso}"
[[ -s "$ISO" ]] || { echo "ISO missing or empty: $ISO" >&2; exit 1; }

for tool in xorriso unsquashfs lsinitramfs file; do
    command -v "$tool" >/dev/null || { echo "Missing validation tool: $tool" >&2; exit 2; }
done

WORK="$(mktemp -d)"
trap 'rm -rf -- "$WORK"' EXIT

extract() {
    xorriso -osirrox on -indev "$ISO" -extract "$1" "$2" >/dev/null 2>&1
}

echo "[1/6] ISO9660 and El Torito records"
file "$ISO" | tee "$WORK/file.txt"
grep -qi 'bootable' "$WORK/file.txt"
xorriso -indev "$ISO" -report_el_torito plain 2>&1 | tee "$WORK/el-torito.txt"
grep -Eqi 'BIOS|El Torito boot img.*1' "$WORK/el-torito.txt"
grep -Eqi 'UEFI|EFI|El Torito boot img.*2' "$WORK/el-torito.txt"

echo "[2/6] Required live payload"
extract /live/vmlinuz "$WORK/vmlinuz"
extract /live/initrd.img "$WORK/initrd.img"
extract /live/filesystem.squashfs "$WORK/filesystem.squashfs"
test -s "$WORK/vmlinuz"
test -s "$WORK/initrd.img"
test -s "$WORK/filesystem.squashfs"
file "$WORK/vmlinuz" "$WORK/initrd.img" "$WORK/filesystem.squashfs"

echo "[3/6] SquashFS metadata and root filesystem"
unsquashfs -s "$WORK/filesystem.squashfs" | tee "$WORK/squashfs.txt"
grep -q 'Squashfs' "$WORK/squashfs.txt"
unsquashfs -cat "$WORK/filesystem.squashfs" etc/os-release > "$WORK/os-release"
grep -q 'PRETTY_NAME="FeatherOS 1.0"' "$WORK/os-release"
for path in usr/bin/systemctl usr/bin/startplasma-wayland usr/bin/sddm usr/bin/dolphin usr/bin/firefox-esr; do
    unsquashfs -ll "$WORK/filesystem.squashfs" "$path" | grep -q "$path"
done

echo "[4/6] initramfs live-boot and hardware modules"
lsinitramfs "$WORK/initrd.img" > "$WORK/initrd.list"
grep -Eq '(^|/)init$' "$WORK/initrd.list"
grep -Eq 'scripts/live|lib/live/boot' "$WORK/initrd.list"
for pattern in \
    'fs/squashfs/squashfs\.ko' \
    'fs/overlayfs/overlay\.ko' \
    'fs/isofs/isofs\.ko' \
    'drivers/block/loop\.ko' \
    'drivers/scsi/sr_mod\.ko' \
    'drivers/ata/ata_piix\.ko' \
    'drivers/block/virtio_blk\.ko' \
    'drivers/virtio/virtio_pci' \
    'drivers/scsi/virtio_scsi\.ko'; do
    grep -Eq "$pattern" "$WORK/initrd.list" || {
        echo "Required initramfs module missing: $pattern" >&2
        exit 3
    }
done

echo "[5/6] BIOS and UEFI bootloader configuration"
extract /isolinux/menu.cfg "$WORK/isolinux-menu.cfg"
extract /isolinux/feather.cfg "$WORK/isolinux-feather.cfg"
extract /boot/grub/grub.cfg "$WORK/grub.cfg"
grep -q 'Start FeatherOS' "$WORK/isolinux-feather.cfg"
grep -q 'Debug Mode' "$WORK/isolinux-feather.cfg"
grep -q 'console=tty0 console=ttyS0,115200' "$WORK/isolinux-feather.cfg"
debug_line="$(grep 'append .*debug' "$WORK/isolinux-feather.cfg")"
[[ "$debug_line" != *quiet* && "$debug_line" != *splash* ]]
grep -q 'Start FeatherOS' "$WORK/grub.cfg"
grep -q 'FeatherOS (Debug Mode)' "$WORK/grub.cfg"
! grep -qi 'Debian GNU/Linux' "$WORK/isolinux-menu.cfg" "$WORK/grub.cfg"

echo "[6/6] ISO validation complete"
echo "FeatherOS ISO static validation: OK"
