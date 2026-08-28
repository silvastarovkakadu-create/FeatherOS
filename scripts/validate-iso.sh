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
    local iso_path="$1"
    local output_path="$2"
    if ! xorriso -osirrox on -indev "$ISO" -extract "$iso_path" "$output_path" >/dev/null 2>&1; then
        echo "Required ISO path missing or unreadable: $iso_path" >&2
        exit 5
    fi
    if [[ ! -s "$output_path" ]]; then
        echo "Extracted ISO file is empty: $iso_path" >&2
        exit 5
    fi
}

require_text() {
    local pattern="$1"
    local path="$2"
    local description="$3"
    if ! grep -Fq -- "$pattern" "$path"; then
        echo "Bootloader validation failed: $description ($pattern in $path)" >&2
        echo "----- $path -----" >&2
        sed -n '1,160p' "$path" >&2
        exit 6
    fi
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
grep -qi 'squashfs' "$WORK/squashfs.txt"
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
    'drivers/ata/ata_piix\.ko'; do
    grep -Eq "$pattern" "$WORK/initrd.list" || {
        echo "Boot-critical initramfs module missing: $pattern" >&2
        exit 3
    }
done

# VirtIO is not needed to discover this ISO: the live root is on a standard
# IDE/SATA CD-ROM.  It is still required for installed systems and QEMU disks,
# so accept it from either the early initramfs or the complete live rootfs.
unsquashfs -ll "$WORK/filesystem.squashfs" lib/modules > "$WORK/rootfs-modules.list"
for pattern in \
    'drivers/block/virtio_blk\.ko' \
    'drivers/virtio/virtio_pci' \
    'drivers/scsi/virtio_scsi\.ko'; do
    if ! grep -Eq "$pattern" "$WORK/initrd.list" && \
       ! grep -Eq "$pattern" "$WORK/rootfs-modules.list"; then
        echo "VirtIO module not listed as a loadable module: $pattern; QEMU runtime test will verify support" >&2
    fi
done

echo "[5/6] BIOS and UEFI bootloader configuration"
extract /isolinux/menu.cfg "$WORK/isolinux-menu.cfg"
extract /isolinux/feather.cfg "$WORK/isolinux-feather.cfg"
extract /boot/grub/grub.cfg "$WORK/grub.cfg"
require_text 'Start FeatherOS' "$WORK/isolinux-feather.cfg" 'BIOS normal entry missing'
require_text 'Debug Mode' "$WORK/isolinux-feather.cfg" 'BIOS debug entry missing'
require_text 'console=tty0 console=ttyS0,115200' "$WORK/isolinux-feather.cfg" 'BIOS serial console missing'
debug_line="$(grep 'append .*debug' "$WORK/isolinux-feather.cfg")"
if [[ "$debug_line" == *quiet* || "$debug_line" == *splash* ]]; then
    echo "BIOS Debug Mode still contains quiet/splash: $debug_line" >&2
    exit 6
fi
require_text 'Start FeatherOS' "$WORK/grub.cfg" 'UEFI normal entry missing'
require_text 'FeatherOS (Debug Mode)' "$WORK/grub.cfg" 'UEFI debug entry missing'
if grep -qi 'Debian GNU/Linux' "$WORK/isolinux-menu.cfg" "$WORK/grub.cfg"; then
    echo "Debian user-facing branding found in bootloader configuration" >&2
    exit 4
fi

echo "[6/6] ISO validation complete"
echo "FeatherOS ISO static validation: OK"
