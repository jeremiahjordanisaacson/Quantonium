# Building Quantonium OS

This document provides complete instructions for building a Quantonium OS ISO image from source.

## Prerequisites

### System Requirements

- **Operating System:** Ubuntu 22.04 LTS or newer (or Debian 12+)
- **CPU:** 4+ cores recommended
- **RAM:** 8 GB minimum, 16 GB recommended
- **Storage:** 50 GB free space minimum
- **Internet:** Broadband connection for downloading packages

### Required Packages

Install the build dependencies:

```bash
sudo apt update
sudo apt install -y \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    grub-efi-amd64-signed \
    shim-signed \
    mtools \
    dosfstools \
    isolinux \
    syslinux-utils \
    unzip \
    wget \
    curl \
    git \
    rsync \
    gnupg \
    apt-transport-https \
    ca-certificates \
    software-properties-common
```

For building Plymouth themes:

```bash
sudo apt install -y inkscape imagemagick
```

For building GTK themes (optional, for development):

```bash
sudo apt install -y sassc
```

## Quick Build

For a standard build with default options:

```bash
# Clone the repository
git clone https://github.com/quantonium/quantonium-os.git
cd quantonium-os

# Run the build script (requires root)
sudo ./build-system/build.sh

# The ISO will be in build-system/output/
```

## Build Options

The build script supports several options:

```bash
sudo ./build-system/build.sh [OPTIONS]

Options:
  --clean       Remove previous build files before building
  --quick       Skip optional steps for faster builds (development only)
  --variant X   Build variant: desktop (default), minimal, developer
  --help        Show help message
```

### Build Variants

- **desktop** (default): Full desktop experience with all applications
- **minimal**: Basic system with minimal applications
- **developer**: Desktop plus additional development tools

## Build Process Overview

The build process consists of these stages:

1. **Bootstrap** - Create base Ubuntu system using debootstrap
2. **Configure APT** - Set up package repositories
3. **Install Kernel** - Install Linux kernel and firmware
4. **Install Desktop** - Install GNOME and desktop applications
5. **Install Applications** - Add default applications
6. **Install Drivers** - Add hardware drivers
7. **Configure System** - Apply system configuration
8. **Install Branding** - Apply Quantonium themes and branding
9. **Clean** - Remove unnecessary files
10. **Create SquashFS** - Compress the filesystem
11. **Create ISO** - Generate bootable ISO image

## Directory Structure

```
build-system/
├── build.sh            # Main build script
├── build/              # Build workspace (created during build)
│   ├── chroot/         # Root filesystem being built
│   └── iso/            # ISO structure
├── cache/              # Download cache
├── output/             # Final ISO output
└── packages/           # Package lists
    ├── desktop.list    # Desktop variant packages
    ├── minimal.list    # Minimal variant packages
    └── developer.list  # Developer variant packages
```

## Customization

### Changing Package Selection

Edit the package lists in `build-system/packages/`:

```bash
# Add packages (one per line)
nano build-system/packages/desktop.list
```

### Changing Theme/Branding

1. Modify files in `themes/` directory
2. Update brand guidelines in `branding/`
3. Rebuild

### Changing Default Settings

Edit dconf settings in `configs/dconf/00-quantonium-settings`

## Converting Assets

### Plymouth Theme Assets

Convert SVG to PNG for Plymouth:

```bash
cd themes/plymouth

# Convert logo
inkscape logo.svg -w 200 -h 200 -o logo.png

# Convert progress bar
inkscape progress-bar.svg -w 400 -h 8 -o progress-bar.png
inkscape progress-bg.svg -w 400 -h 8 -o progress-bg.png

# Convert particle
inkscape particle.svg -w 12 -h 12 -o particle.png
```

### GRUB Theme Assets

```bash
cd themes/grub

# Convert background
inkscape background.svg -w 1920 -h 1080 -o background.png

# Convert logo
inkscape logo.svg -w 200 -h 100 -o logo.png
```

### Wallpapers

```bash
cd wallpapers

# Convert to PNG at multiple resolutions
for file in *.svg; do
    base="${file%.svg}"
    inkscape "$file" -w 3840 -h 2160 -o "${base}-4k.png"
    inkscape "$file" -w 2560 -h 1440 -o "${base}-2k.png"
    inkscape "$file" -w 1920 -h 1080 -o "${base}-1080p.png"
done
```

## Testing

### Testing in VM

```bash
# Using QEMU
qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -cdrom build-system/output/quantonium-1.0-amd64.iso \
    -boot d

# Using VirtualBox
VBoxManage createvm --name "Quantonium Test" --ostype Ubuntu_64 --register
VBoxManage modifyvm "Quantonium Test" --memory 4096 --vram 128
VBoxManage storagectl "Quantonium Test" --name "IDE" --add ide
VBoxManage storageattach "Quantonium Test" --storagectl "IDE" \
    --port 0 --device 0 --type dvddrive \
    --medium build-system/output/quantonium-1.0-amd64.iso
VBoxManage startvm "Quantonium Test"
```

### Testing on Real Hardware

```bash
# Write to USB (replace /dev/sdX with your USB device)
# WARNING: This will erase all data on the USB drive!
sudo dd if=build-system/output/quantonium-1.0-amd64.iso \
       of=/dev/sdX \
       bs=4M \
       status=progress \
       conv=fsync
```

## Troubleshooting

### Build Fails at Debootstrap

- Check internet connectivity
- Ensure Ubuntu mirrors are accessible
- Try with `--clean` flag

### Out of Disk Space

- Ensure 50+ GB free space
- Use `--clean` to remove previous builds
- Clear APT cache: `sudo apt clean`

### Package Installation Failures

- Check package names in package lists
- Ensure all PPAs are valid
- Check for version conflicts

### SquashFS Creation Hangs

- Check available RAM (needs 4+ GB free)
- Check disk I/O (avoid network drives)
- Try reducing compression with `-Xcompression-level 1`

### ISO Won't Boot

- Verify UEFI and BIOS boot files are present
- Check GRUB configuration
- Test both UEFI and Legacy boot modes

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build Quantonium

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y debootstrap squashfs-tools xorriso \
            grub-pc-bin grub-efi-amd64-bin mtools dosfstools

      - name: Build ISO
        run: sudo ./build-system/build.sh --quick

      - name: Upload ISO
        uses: actions/upload-artifact@v4
        with:
          name: quantonium-iso
          path: build-system/output/*.iso
```

## Release Process

1. Update version numbers in:
   - `build-system/build.sh`
   - `configs/system/quantonium.conf`
   - `README.md`

2. Update changelog

3. Create release commit and tag:
   ```bash
   git commit -am "Release v1.0"
   git tag -a v1.0 -m "Quantonium OS 1.0"
   git push origin main --tags
   ```

4. Build final ISO:
   ```bash
   sudo ./build-system/build.sh --clean
   ```

5. Generate checksums:
   ```bash
   cd build-system/output
   sha256sum *.iso > SHA256SUMS
   gpg --detach-sign --armor SHA256SUMS
   ```

6. Upload to release server

## Support

- **Documentation:** https://docs.quantonium.io
- **Issues:** https://github.com/quantonium/quantonium-os/issues
- **Community:** https://community.quantonium.io
