#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"
required=(build.sh clean.sh test.sh make-iso.sh config/auto/config config/package-lists/featheros.list.chroot branding/logo/source.svg scripts/prepare-branding.sh config/includes.chroot/etc/os-release)
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
if command -v shellcheck >/dev/null; then
  find . -type f \( -name '*.sh' -o -name '*.hook.chroot' -o -name '*.hook.binary' \) -print0 | xargs -0 shellcheck -x
fi
echo "FeatherOS source validation: OK"
