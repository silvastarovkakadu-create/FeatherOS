#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/.build"
DIST_DIR="${PROJECT_DIR}/dist"
ISO_NAME="FeatherOS-1.0-x86_64.iso"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run with root privileges: sudo ./build.sh" >&2
  exit 1
fi
for tool in lb rsync xorriso mksquashfs; do
  command -v "$tool" >/dev/null || { echo "Missing build tool: $tool" >&2; exit 2; }
done

"${PROJECT_DIR}/scripts/prepare-branding.sh"
mkdir -p "$BUILD_DIR" "$DIST_DIR"
rsync -a --delete --exclude auto/config --exclude auto/clean \
  "${PROJECT_DIR}/config/" "${BUILD_DIR}/config/"
install -Dm755 "${PROJECT_DIR}/config/auto/config" "${BUILD_DIR}/auto/config"
install -Dm755 "${PROJECT_DIR}/config/auto/clean" "${BUILD_DIR}/auto/clean"

cd "$BUILD_DIR"
lb clean --purge || true
./auto/config
lb build 2>&1 | tee "${DIST_DIR}/build.log"

image="$(find . -maxdepth 1 -type f \( -name '*.hybrid.iso' -o -name '*.iso' \) -print -quit)"
[[ -n "$image" ]] || { echo "live-build finished without an ISO" >&2; exit 3; }
install -m644 "$image" "${DIST_DIR}/${ISO_NAME}"
(cd "$DIST_DIR" && sha256sum "$ISO_NAME" > "${ISO_NAME}.sha256")
echo "Built: ${DIST_DIR}/${ISO_NAME}"

if [[ "${FEATHEROS_BUILD_ONLY:-0}" != 1 ]]; then
  "${PROJECT_DIR}/scripts/validate-iso.sh" "${DIST_DIR}/${ISO_NAME}"
  "${PROJECT_DIR}/scripts/smoke-boot.sh" "${DIST_DIR}/${ISO_NAME}"
fi
