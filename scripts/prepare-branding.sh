#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LOGO_DIR="${PROJECT_DIR}/branding/logo"
OVERLAY="${PROJECT_DIR}/config/includes.chroot"
SOURCE="${LOGO_DIR}/source.png"
[[ -r "$SOURCE" ]] || SOURCE="${LOGO_DIR}/source.svg"
[[ -r "$SOURCE" ]] || { echo "Put the FeatherOS logo at branding/logo/source.png" >&2; exit 1; }
command -v convert >/dev/null || { echo "ImageMagick is required." >&2; exit 2; }
command -v rsvg-convert >/dev/null || { echo "librsvg2-bin is required for wallpapers and SVG branding." >&2; exit 2; }

render() {
  local size="$1" target="$2"
  mkdir -p "$(dirname -- "$target")"
  if [[ "$SOURCE" == *.svg ]]; then
    rsvg-convert -w "$size" -h "$size" -o "$target" "$SOURCE"
  else
    convert -background none "$SOURCE" -resize "${size}x${size}" -gravity center -extent "${size}x${size}" "$target"
  fi
}
render 512 "${LOGO_DIR}/logo-512.png"
render 256 "${OVERLAY}/usr/share/pixmaps/featheros-logo.png"
render 192 "${OVERLAY}/usr/share/plymouth/themes/featheros/logo.png"
convert -size 300x8 xc:none -fill '#26304a' -draw 'roundrectangle 0,0 299,7 4,4' \
  "${OVERLAY}/usr/share/plymouth/themes/featheros/progress-track.png"
convert -size 300x8 xc:none -fill '#7f92ff' -draw 'roundrectangle 0,0 299,7 4,4' \
  "${OVERLAY}/usr/share/plymouth/themes/featheros/progress-fill.png"
render 128 "${OVERLAY}/usr/share/sddm/themes/featheros/logo.png"
render 96 "${OVERLAY}/usr/share/calamares/branding/featheros/logo.png"
rsvg-convert -w 800 -h 450 -o "${OVERLAY}/usr/share/calamares/branding/featheros/welcome.png" "${PROJECT_DIR}/branding/wallpapers/Feather-Dark.svg"
render 64 "${OVERLAY}/usr/share/icons/hicolor/64x64/apps/featheros.png"
render 48 "${OVERLAY}/usr/share/icons/hicolor/48x48/apps/featheros.png"
render 32 "${OVERLAY}/usr/share/icons/hicolor/32x32/apps/featheros.png"
cp -f "$SOURCE" "${OVERLAY}/usr/share/featheros/logo.${SOURCE##*.}"
mkdir -p "${OVERLAY}/usr/share/featheros/wallpapers"
cp -f "${PROJECT_DIR}/branding/wallpapers/"*.svg "${OVERLAY}/usr/share/featheros/wallpapers/"
mkdir -p "${OVERLAY}/boot/grub/themes/featheros"
rsvg-convert -w 1920 -h 1080 -o "${OVERLAY}/boot/grub/themes/featheros/background.png" "${PROJECT_DIR}/branding/wallpapers/Feather-Dark.svg"
convert -size 64x42 xc:none -fill '#55718dcc' -stroke '#80a0ffff' -strokewidth 1 -draw 'roundrectangle 1,1 62,40 14,14' "${OVERLAY}/boot/grub/themes/featheros/select_c.png"
cp "${OVERLAY}/boot/grub/themes/featheros/select_c.png" "${OVERLAY}/boot/grub/themes/featheros/select_n.png"
cp "${OVERLAY}/boot/grub/themes/featheros/select_c.png" "${OVERLAY}/boot/grub/themes/featheros/select_s.png"
cp "${OVERLAY}/boot/grub/themes/featheros/select_c.png" "${OVERLAY}/boot/grub/themes/featheros/select_e.png"

# Live ISO boot menus are outside the chroot and need separate raster assets.
BOOT_ISOLINUX="${PROJECT_DIR}/config/bootloaders/isolinux"
BOOT_GRUB_EFI="${PROJECT_DIR}/config/bootloaders/grub-efi"
mkdir -p "$BOOT_ISOLINUX" "$BOOT_GRUB_EFI"
convert "${PROJECT_DIR}/branding/wallpapers/Feather-Dark.svg" \
  -resize '640x480^' -gravity center -extent 640x480 \
  "$BOOT_ISOLINUX/splash.png"
convert "$BOOT_ISOLINUX/splash.png" \( "$SOURCE" -resize 112x112 \) \
  -gravity north -geometry +0+34 -composite PNG8:"$BOOT_ISOLINUX/splash.png"
convert "${PROJECT_DIR}/branding/wallpapers/Feather-Dark.svg" \
  -resize '800x600^' -gravity center -extent 800x600 \
  "$BOOT_GRUB_EFI/splash.png"
convert "$BOOT_GRUB_EFI/splash.png" \( "$SOURCE" -resize 144x144 \) \
  -gravity north -geometry +0+42 -composite "$BOOT_GRUB_EFI/splash.png"
