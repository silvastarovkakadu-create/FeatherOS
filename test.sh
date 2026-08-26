#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ISO="${1:-${PROJECT_DIR}/dist/FeatherOS-1.0-x86_64.iso}"
[[ -r "$ISO" ]] || { echo "ISO not found: $ISO" >&2; exit 1; }
command -v qemu-system-x86_64 >/dev/null || { echo "Install qemu-system-x86 and ovmf." >&2; exit 2; }
QEMU=(qemu-system-x86_64 -name FeatherOS -m 4096 -smp 4 -machine q35 -cpu host -enable-kvm -device virtio-vga-gl -display "gtk,gl=on" -device intel-hda -device hda-duplex -nic "user,model=virtio-net-pci" -boot d -cdrom "$ISO")
if [[ ! -e /dev/kvm ]]; then
  QEMU=(qemu-system-x86_64 -name FeatherOS -m 4096 -smp 4 -machine q35 -cpu max -device virtio-vga -display gtk -device intel-hda -device hda-duplex -nic "user,model=virtio-net-pci" -boot d -cdrom "$ISO")
fi
if [[ -r /usr/share/OVMF/OVMF_CODE_4M.fd ]]; then
  VARS="$(mktemp --suffix=.fd)"
  trap 'rm -f -- "$VARS"' EXIT
  cp /usr/share/OVMF/OVMF_VARS_4M.fd "$VARS"
  QEMU+=( -drive "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd" -drive "if=pflash,format=raw,file=$VARS" )
fi
exec "${QEMU[@]}"
