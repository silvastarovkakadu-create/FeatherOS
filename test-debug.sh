#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ISO="${1:-}"
if [[ -z "$ISO" ]]; then
    ISO="$(find "${PROJECT_DIR}/dist" -maxdepth 1 -type f -name 'FeatherOS-*.iso' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-)"
fi
[[ -r "$ISO" ]] || { echo "FeatherOS ISO not found" >&2; exit 1; }

for tool in qemu-system-x86_64 qemu-img xorriso; do
    command -v "$tool" >/dev/null || { echo "Install required tool: $tool" >&2; exit 2; }
done

LOG_DIR="${PROJECT_DIR}/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/qemu-debug-serial.log"
WORK="$(mktemp -d)"
trap 'rm -rf -- "$WORK"' EXIT
xorriso -osirrox on -indev "$ISO" -extract /live/vmlinuz "$WORK/vmlinuz" >/dev/null 2>&1
xorriso -osirrox on -indev "$ISO" -extract /live/initrd.img "$WORK/initrd.img" >/dev/null 2>&1
qemu-img create -q -f qcow2 "$WORK/disk.qcow2" 24G

accel=tcg
cpu=max
if [[ -r /dev/kvm && -w /dev/kvm ]]; then
    accel=kvm
    cpu=host
fi

set +e
qemu-system-x86_64 \
    -name 'FeatherOS Debug' -machine "q35,accel=$accel" -cpu "$cpu" \
    -m 4096 -smp 2 -kernel "$WORK/vmlinuz" -initrd "$WORK/initrd.img" \
    -append 'boot=live components debug loglevel=7 systemd.show_status=1 systemd.log_level=debug plymouth.enable=0 rd.plymouth=0 panic=0 console=tty0 console=ttyS0,115200 username=feather hostname=featheros featheros.safe_graphics=1' \
    -drive "file=$ISO,media=cdrom,readonly=on" \
    -drive "file=$WORK/disk.qcow2,if=virtio,format=qcow2" \
    -device virtio-vga -display gtk \
    -nic user,model=virtio-net-pci \
    -serial "file:$LOG" -no-reboot
rc=$?
set -e

echo "Serial log: $LOG"
grep -Ei 'panic|failed|error|reboot|FEATHEROS_' "$LOG" | tail -n 80 || true
exit "$rc"
