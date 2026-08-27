#!/usr/bin/env bash
set -Eeuo pipefail

ISO="${1:?usage: smoke-boot.sh path/to/FeatherOS.iso}"
[[ -r "$ISO" ]] || { echo "ISO not readable: $ISO" >&2; exit 1; }
command -v xorriso >/dev/null || { echo "xorriso is required" >&2; exit 2; }
command -v qemu-system-x86_64 >/dev/null || { echo "qemu-system-x86_64 is required" >&2; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf -- "$WORK"' EXIT
xorriso -osirrox on -indev "$ISO" -extract /live/vmlinuz "$WORK/vmlinuz" >/dev/null 2>&1
xorriso -osirrox on -indev "$ISO" -extract /live/initrd.img "$WORK/initrd.img" >/dev/null 2>&1

set +e
timeout 240 qemu-system-x86_64 \
    -machine q35,accel=tcg -cpu max -m 3072 -smp 2 \
    -kernel "$WORK/vmlinuz" -initrd "$WORK/initrd.img" \
    -append 'boot=live components username=feather hostname=featheros systemd.unit=multi-user.target console=ttyS0,115200 systemd.show_status=1' \
    -drive "file=$ISO,media=cdrom,readonly=on" \
    -display none -monitor none -serial stdio -no-reboot \
    >"$WORK/qemu.log" 2>&1
rc=$?
set -e

if grep -Eqi 'Reached target .*Multi-User|Started .*Display Manager|Welcome to FeatherOS|featheros login:' "$WORK/qemu.log"; then
    echo "QEMU live boot smoke test: OK"
    exit 0
fi

tail -n 120 "$WORK/qemu.log" >&2
echo "QEMU live boot smoke test failed (qemu exit $rc)" >&2
exit 3
