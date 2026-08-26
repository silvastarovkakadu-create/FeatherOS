#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -d "${PROJECT_DIR}/.build" ]]; then
  if [[ ${EUID} -eq 0 ]]; then
    (cd "${PROJECT_DIR}/.build" && lb clean --purge) || true
  else
    echo "Run sudo ./clean.sh if .build contains root-owned files." >&2
    exit 1
  fi
  find "${PROJECT_DIR}/.build" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
fi
find "${PROJECT_DIR}/dist" -maxdepth 1 -type f \( -name '*.iso' -o -name '*.sha256' -o -name '*.log' \) -delete 2>/dev/null || true

