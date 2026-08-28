#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"
required=(build.sh clean.sh test.sh test-debug.sh make-iso.sh config/auto/config config/package-lists/featheros.list.chroot branding/logo/source.png scripts/prepare-branding.sh scripts/validate-iso.sh scripts/smoke-boot.sh config/bootloaders/isolinux/feather.cfg config/bootloaders/grub-efi/grub.cfg config/includes.chroot/etc/os-release)
for file in "${required[@]}"; do [[ -s "$file" ]] || { echo "Missing: $file" >&2; exit 1; }; done
while IFS= read -r file; do bash -n "$file"; done < <(find . -type f \( -name '*.sh' -o -name '*.hook.chroot' -o -name '*.hook.binary' \) -print)
python3 -m py_compile config/includes.chroot/usr/local/bin/feather-settings
python3 - <<'PY'
import json
from pathlib import Path
for p in Path('.').rglob('*.json'):
    json.loads(p.read_text())
print('JSON: OK')
PY
grep -q 'PRETTY_NAME="FeatherOS 1.0"' config/includes.chroot/etc/os-release
grep -q -- '--distribution trixie' config/auto/config
grep -q 'Debug Mode' config/bootloaders/isolinux/feather.cfg
grep -q 'console=tty0 console=ttyS0,115200' config/bootloaders/isolinux/feather.cfg
debug_line="$(grep 'append .*debug' config/bootloaders/isolinux/feather.cfg)"
[[ "$debug_line" != *quiet* && "$debug_line" != *splash* ]]
grep -q 'Start FeatherOS' config/bootloaders/grub-efi/grub.cfg
grep -q 'FeatherOS (Debug Mode)' config/bootloaders/grub-efi/grub.cfg
grep -q 'console=tty0 console=ttyS0,115200' config/bootloaders/grub-efi/grub.cfg
grub_debug_line="$(grep '^[[:space:]]*linux .*debug' config/bootloaders/grub-efi/grub.cfg)"
[[ "$grub_debug_line" != *quiet* && "$grub_debug_line" != *splash* ]]
if command -v shellcheck >/dev/null; then
  find . -type f \( -name '*.sh' -o -name '*.hook.chroot' -o -name '*.hook.binary' \) -print0 | xargs -0 shellcheck -x
fi
echo "FeatherOS source validation: OK"
