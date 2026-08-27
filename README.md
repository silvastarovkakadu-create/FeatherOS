# FeatherOS 1.0 “Feather”

FeatherOS is an installable `amd64` Debian 13 (trixie) Live distribution with KDE Plasma 6, Wayland by default, an X11 fallback, a restrained glass-inspired visual language, and the Calamares installer. This is a real `live-build` project: it produces a hybrid ISO for UEFI and legacy BIOS, suitable for QEMU, VirtualBox, VMware and USB media.

The design is original and contains no Apple artwork, icons, fonts or copied UI resources.

## Status and honest scope

Implemented and wired to real system components:

- Debian Stable repositories including `non-free-firmware`;
- Plasma 6, KWin Wayland/X11, SDDM, NetworkManager, PipeWire/WirePlumber, BlueZ, Flatpak/Discover;
- Calamares with FeatherOS branding;
- custom `/etc/os-release`, hostname, Plymouth, GRUB theme, SDDM theme, wallpapers, Firefox policies and start page;
- centered floating top panel and auto-hiding bottom panel with pinned apps;
- four virtual desktops, Overview on `Super`, snapping through KWin, blur/compositing and desktop shortcuts;
- Feather Settings controls for Light/Dark/time-based Auto, accent color, blur, animation speed, power profile and Reduce Effects;
- common GPU/network firmware, Mesa/Vulkan and 32-bit graphics runtime;
- VirtualBox and VMware guest integration;
- five original SVG wallpapers and scalable branding generation.

Not falsely claimed as complete:

- true Dock icon magnification: stock Plasma's Icons-only Task Manager has no stable magnification API;
- arbitrary per-surface 0–100% opacity and arbitrary window corner radii: these need a maintained theme/decoration plugin, not a config toggle;
- a complete rewritten Dolphin/System Settings shell: Files uses Dolphin and Settings provides a real Feather frontend while advanced modules remain Plasma tools;
- identical three-finger remapping on every touchpad: gesture availability depends on libinput hardware and the session.

Those controls are absent rather than non-working UI.

## Requirements

Build host: Debian 13 or Ubuntu 24.04+, about 25 GB free disk, root privileges and internet. Debian 13 is recommended for reproducibility.

Target minimum: x86_64 CPU, 4 GB RAM, 20 GB storage, OpenGL 3.3 GPU. Recommended: 8 GB RAM, 40 GB SSD, Intel UHD / AMD Vega or newer.

## Add the supplied logo

The repository includes an original fallback feather glyph so builds remain testable. To use the exact supplied logo, place it at `branding/logo/source.png`; it takes priority over the SVG fallback. Then run:

```bash
./scripts/prepare-branding.sh
```

Optimized assets are generated for Plymouth, SDDM, Calamares, menus, About and app icons without non-proportional stretching.

## Build

```bash
sudo ./scripts/install-build-deps.sh
./scripts/validate.sh
sudo ./build.sh
```

Output:

```text
dist/FeatherOS-1.0-x86_64.iso
dist/FeatherOS-1.0-x86_64.iso.sha256
dist/build.log
```

`make-iso.sh` runs the same build. A first build downloads several gigabytes and can take 30–120 minutes.

`build.sh` does not stop after creating a file: it validates the ISO, SquashFS, kernel, initramfs and bootloader records, then boots the live system in QEMU and waits for a Plasma desktop readiness marker. Set `FEATHEROS_BUILD_ONLY=1` only in controlled CI pipelines that run the validation stages separately.

## Test

```bash
./test.sh
./test-debug.sh
```

It starts QEMU with 4 CPUs/4 GB RAM, KVM/OpenGL when available, software fallback otherwise, and OVMF UEFI when installed. An alternative ISO path can be passed as argument 1.

`test-debug.sh` disables Plymouth, enables kernel/systemd debug output on `tty0` and `ttyS0`, uses `panic=0`, and writes the serial trace to `logs/qemu-debug-serial.log`. CI writes its automatic desktop test to `logs/qemu-serial.log` and fails on panic, reboot, early QEMU exit, or failure to reach Plasma.

VirtualBox: choose Debian (64-bit), 4 GB RAM, 4 CPUs, VMSVGA and 128 MB video RAM. Enable EFI for the UEFI test. VMware: choose Debian 13.x 64-bit and enable 3D acceleration.

## Install and USB

Boot live mode and open **Install FeatherOS**. Calamares provides erase-disk, manual partitioning, EFI and swap through its maintained Debian modules.

On Linux, identify the whole USB device carefully with `lsblk`, unmount its partitions, then write the ISO. This erases the selected USB:

```bash
sudo dd if=dist/FeatherOS-1.0-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

On Windows, use Rufus in DD mode or Balena Etcher. Verify the SHA-256 file first.

## Layout

- `config/`: live-build configuration, package lists, hooks and root filesystem overlay;
- `branding/`: logo source and five original wallpapers;
- `plasma/`, `sddm/`, `plymouth/`, `grub/`, `calamares/`, `firefox/`: pointers to installed source paths;
- `scripts/`: dependency, branding and validation tools;
- `dist/`: ISO, checksum and build log;
- `.build/`: disposable live-build work tree.

## Troubleshooting

- Browser v86: FeatherOS is x86_64, while v86 currently lacks 64-bit CPU extensions. It can display the ISO boot menu but resets when control passes to the amd64 kernel. Use QEMU, VirtualBox, VMware or physical x86_64 hardware; this is an emulator limitation, not a supported FeatherOS boot target.
- Boot diagnostics: select **FeatherOS (Debug Mode)**. It shows kernel/initramfs/systemd output, mirrors it to 115200-baud COM1, disables Plymouth and stops instead of auto-rebooting after a panic.
- Missing build tool: run the dependency installer.
- Package not found: verify access to `deb.debian.org` and `security.debian.org`, run `sudo ./clean.sh`, then rebuild.
- Secure Boot: 1.0 has no project-owned signed shim; disable Secure Boot for testing.
- VM black screen: disable VM 3D acceleration or select Plasma (X11) in SDDM.
- NVIDIA: firmware and Nouveau/Mesa are included. Proprietary NVIDIA drivers are intentionally not preinstalled.
- Calamares debugging: run `sudo -E calamares -d` from Terminal.
- Clean rebuild: `sudo ./clean.sh && sudo ./build.sh`.

## License

Project-authored scripts and themes are GPL-3.0-or-later. Debian packages retain their licenses. Firmware from `non-free-firmware` may have separate redistribution terms; review them before publishing an ISO.
