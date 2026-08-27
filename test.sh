#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ISO="${1:-}"
if [[ -z "$ISO" ]]; then
  ISO="$(find "${PROJECT_DIR}/dist" -maxdepth 1 -type f -name 'FeatherOS-*.iso' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-)"
fi
[[ -r "$ISO" ]] || { echo "ISO not found: $ISO" >&2; exit 1; }
command -v qemu-system-x86_64 >/dev/null || { echo "Install qemu-system-x86 and ovmf." >&2; exit 2; }
command -v qemu-img >/dev/null || { echo "Install qemu-utils." >&2; exit 2; }
mkdir -p "${PROJECT_DIR}/logs"
WORK="$(mktemp -d)"
trap 'rm -rf -- "$WORK"' EXIT
qemu-img create -q -f qcow2 "$WORK/featheros-test.qcow2" 24G
QEMU=(qemu-system-x86_64 -name FeatherOS -m 4096 -smp 4 -machine q35 -cpu host -enable-kvm -device virtio-vga-gl -display "gtk,gl=on" -device intel-hda -device hda-duplex -nic "user,model=virtio-net-pci" -boot d -cdrom "$ISO" -drive "file=$WORK/featheros-test.qcow2,if=virtio,format=qcow2" -serial "file:${PROJECT_DIR}/logs/qemu-serial.log" -no-reboot)
if [[ ! -e /dev/kvm ]]; then
  QEMU=(qemu-system-x86_64 -name FeatherOS -m 4096 -smp 2 -machine "q35,accel=tcg" -cpu max -device virtio-vga -display gtk -device intel-hda -device hda-duplex -nic "user,model=virtio-net-pci" -boot d -cdrom "$ISO" -drive "file=$WORK/featheros-test.qcow2,if=virtio,format=qcow2" -serial "file:${PROJECT_DIR}/logs/qemu-serial.log" -no-reboot)
fi
if [[ -r /usr/share/OVMF/OVMF_CODE_4M.fd ]]; then
  VARS="$WORK/OVMF_VARS.fd"
  cp /usr/share/OVMF/OVMF_VARS_4M.fd "$VARS"
  QEMU+=( -drive "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd" -drive "if=pflash,format=raw,file=$VARS" )
fi
exec "${QEMU[@]}"
