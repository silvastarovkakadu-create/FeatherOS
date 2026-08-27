#!/usr/bin/env bash
set -Eeuo pipefail

ISO="${1:?usage: smoke-boot.sh path/to/FeatherOS.iso}"
[[ -r "$ISO" ]] || { echo "ISO not readable: $ISO" >&2; exit 1; }
command -v xorriso >/dev/null || { echo "xorriso is required" >&2; exit 2; }
command -v qemu-system-x86_64 >/dev/null || { echo "qemu-system-x86_64 is required" >&2; exit 2; }
command -v qemu-img >/dev/null || { echo "qemu-img is required" >&2; exit 2; }

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${PROJECT_DIR}/logs"
mkdir -p "$LOG_DIR"
WORK="$(mktemp -d)"
qemu_pid=""
cleanup() {
    if [[ -n "$qemu_pid" ]]; then
        kill "$qemu_pid" 2>/dev/null || true
        wait "$qemu_pid" 2>/dev/null || true
    fi
    rm -rf -- "$WORK"
}
trap cleanup EXIT INT TERM
xorriso -osirrox on -indev "$ISO" -extract /live/vmlinuz "$WORK/vmlinuz" >/dev/null 2>&1
xorriso -osirrox on -indev "$ISO" -extract /live/initrd.img "$WORK/initrd.img" >/dev/null 2>&1
qemu-img create -q -f qcow2 "$WORK/disk.qcow2" 24G

set +e
qemu-system-x86_64 \
    -machine q35,accel=tcg -cpu max -m 4096 -smp 2 \
    -kernel "$WORK/vmlinuz" -initrd "$WORK/initrd.img" \
    -append 'boot=live components username=feather hostname=featheros systemd.unit=graphical.target featheros.ci=1 featheros.safe_graphics=1 console=tty0 console=ttyS0,115200 loglevel=6 systemd.show_status=1 panic=0 plymouth.enable=0 rd.plymouth=0' \
    -drive "file=$ISO,media=cdrom,readonly=on" \
    -drive "file=$WORK/disk.qcow2,if=virtio,format=qcow2" \
    -device virtio-vga \
    -nic user,model=virtio-net-pci \
    -display none -monitor none -serial stdio -no-reboot \
    >"$LOG_DIR/qemu-serial.log" 2>&1 &
qemu_pid=$!
set -e

result=timeout
for _ in $(seq 1 600); do
    if grep -q 'FEATHEROS_DESKTOP_OK' "$LOG_DIR/qemu-serial.log"; then
        result=success
        break
    fi
    if grep -Eqi 'Kernel panic|reboot: Restarting system|FEATHEROS_DESKTOP_FAILED' "$LOG_DIR/qemu-serial.log"; then
        result=boot-failure
        break
    fi
    if ! kill -0 "$qemu_pid" 2>/dev/null; then
        result=unexpected-exit
        break
    fi
    sleep 1
done

kill "$qemu_pid" 2>/dev/null || true
wait "$qemu_pid" 2>/dev/null || true

if [[ "$result" == success ]]; then
    echo "QEMU live boot to Plasma desktop: OK"
    exit 0
fi

tail -n 180 "$LOG_DIR/qemu-serial.log" >&2
echo "QEMU live boot smoke test failed: $result" >&2
exit 3
