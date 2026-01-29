#!/bin/bash
#
# Quantonium OS Build Script
# Builds a bootable ISO image based on Ubuntu 24.04 LTS

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$SCRIPT_DIR/build"
OUTPUT_DIR="$SCRIPT_DIR/output"
CHROOT="$BUILD_DIR/chroot"
ISO_DIR="$BUILD_DIR/iso"

DISTRO_VERSION="1.0"
UBUNTU_CODENAME="noble"
ARCH="amd64"
ISO_NAME="quantonium-${DISTRO_VERSION}-${ARCH}"

echo "=== Quantonium Build System ==="
echo ""

# Check root
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Must run as root"
    exit 1
fi

# Prepare directories
echo "[1/9] Preparing build environment..."
rm -rf "$BUILD_DIR"
mkdir -p "$CHROOT"
mkdir -p "$ISO_DIR"/{boot/grub,casper,.disk,EFI/BOOT}
mkdir -p "$OUTPUT_DIR"

# Bootstrap
echo "[2/9] Bootstrapping Ubuntu $UBUNTU_CODENAME (this takes a while)..."
debootstrap --arch="$ARCH" --variant=minbase \
    "$UBUNTU_CODENAME" "$CHROOT" \
    http://archive.ubuntu.com/ubuntu/

# Configure APT
echo "[3/9] Configuring APT..."
cat > "$CHROOT/etc/apt/sources.list" << EOF
deb http://archive.ubuntu.com/ubuntu/ $UBUNTU_CODENAME main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $UBUNTU_CODENAME-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $UBUNTU_CODENAME-security main restricted universe multiverse
EOF

# Mount for chroot
mount --bind /dev "$CHROOT/dev"
mount --bind /dev/pts "$CHROOT/dev/pts"
mount -t proc proc "$CHROOT/proc"
mount -t sysfs sysfs "$CHROOT/sys"
cp /etc/resolv.conf "$CHROOT/etc/resolv.conf"

cleanup() {
    echo "Cleaning up mounts..."
    umount "$CHROOT/sys" 2>/dev/null || true
    umount "$CHROOT/proc" 2>/dev/null || true
    umount "$CHROOT/dev/pts" 2>/dev/null || true
    umount "$CHROOT/dev" 2>/dev/null || true
}
trap cleanup EXIT

# Install packages
echo "[4/9] Installing packages..."
chroot "$CHROOT" /bin/bash << 'CHROOT_SCRIPT'
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C

apt-get update

# Core packages that must succeed
apt-get install -y --no-install-recommends \
    linux-image-generic \
    linux-headers-generic \
    systemd \
    systemd-sysv \
    dbus \
    sudo \
    locales \
    casper \
    lupin-casper \
    grub-pc-bin \
    grub-efi-amd64-bin \
    grub-efi-amd64-signed

# Desktop (allow some failures)
apt-get install -y --no-install-recommends \
    gnome-shell \
    gnome-session \
    gdm3 \
    gnome-terminal \
    nautilus \
    firefox \
    || echo "Some desktop packages failed, continuing..."

# Dev tools (allow failures)
apt-get install -y --no-install-recommends \
    git \
    vim \
    curl \
    wget \
    htop \
    tmux \
    build-essential \
    python3 \
    python3-pip \
    nodejs \
    npm \
    docker.io \
    ripgrep \
    fd-find \
    fzf \
    jq \
    || echo "Some dev packages failed, continuing..."

# Generate locale
locale-gen en_US.UTF-8

# Enable GDM
systemctl enable gdm || true

# Clean up
apt-get autoremove -y
apt-get clean
rm -rf /var/cache/apt/archives/*.deb
rm -rf /var/lib/apt/lists/*
CHROOT_SCRIPT

# Configure system
echo "[5/9] Configuring system..."
echo "quantonium" > "$CHROOT/etc/hostname"

cat > "$CHROOT/etc/os-release" << EOF
PRETTY_NAME="Quantonium $DISTRO_VERSION"
NAME="Quantonium"
VERSION_ID="$DISTRO_VERSION"
ID=quantonium
ID_LIKE=ubuntu
EOF

# Create live user
chroot "$CHROOT" /bin/bash -c "
useradd -m -s /bin/bash -G sudo quantonium 2>/dev/null || true
echo 'quantonium:quantonium' | chpasswd
echo 'quantonium ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/quantonium
"

# Copy customizations
echo "[6/9] Installing customizations..."
if [[ -d "$PROJECT_ROOT/configs/skel" ]]; then
    cp -r "$PROJECT_ROOT/configs/skel/." "$CHROOT/etc/skel/" 2>/dev/null || true
fi
if [[ -d "$PROJECT_ROOT/tools/bin" ]]; then
    mkdir -p "$CHROOT/usr/local/bin"
    cp "$PROJECT_ROOT/tools/bin/"* "$CHROOT/usr/local/bin/" 2>/dev/null || true
    chmod +x "$CHROOT/usr/local/bin/"* 2>/dev/null || true
fi

# Clean resolv.conf
rm -f "$CHROOT/etc/resolv.conf"

# Unmount before squashfs
cleanup
trap - EXIT

# Create squashfs
echo "[7/9] Creating squashfs (this takes a while)..."
mksquashfs "$CHROOT" "$ISO_DIR/casper/filesystem.squashfs" \
    -comp xz -b 1M -noappend -e boot

# Prepare ISO
echo "[8/9] Preparing ISO structure..."
cp "$CHROOT/boot/vmlinuz-"* "$ISO_DIR/casper/vmlinuz"
cp "$CHROOT/boot/initrd.img-"* "$ISO_DIR/casper/initrd"

echo "Quantonium $DISTRO_VERSION" > "$ISO_DIR/.disk/info"
touch "$ISO_DIR/.disk/base_installable"

cat > "$ISO_DIR/boot/grub/grub.cfg" << 'EOF'
set timeout=10
menuentry "Quantonium" {
    linux /casper/vmlinuz boot=casper quiet splash ---
    initrd /casper/initrd
}
menuentry "Quantonium (Safe Graphics)" {
    linux /casper/vmlinuz boot=casper nomodeset quiet splash ---
    initrd /casper/initrd
}
EOF

# EFI setup
cp "$ISO_DIR/boot/grub/grub.cfg" "$ISO_DIR/EFI/BOOT/"
dd if=/dev/zero of="$ISO_DIR/boot/grub/efi.img" bs=1M count=4
mkfs.vfat "$ISO_DIR/boot/grub/efi.img"
mmd -i "$ISO_DIR/boot/grub/efi.img" EFI EFI/BOOT
mcopy -i "$ISO_DIR/boot/grub/efi.img" "$ISO_DIR/boot/grub/grub.cfg" ::EFI/BOOT/

# Generate ISO
echo "[9/9] Generating ISO..."
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "Quantonium" \
    -output "$OUTPUT_DIR/${ISO_NAME}.iso" \
    -eltorito-boot boot/grub/efi.img \
    -no-emul-boot \
    -append_partition 2 0xef "$ISO_DIR/boot/grub/efi.img" \
    -appended_part_as_gpt \
    "$ISO_DIR"

# Checksums
cd "$OUTPUT_DIR"
sha256sum "${ISO_NAME}.iso" > "${ISO_NAME}.iso.sha256"

echo ""
echo "=== Build Complete ==="
ls -lh "$OUTPUT_DIR/${ISO_NAME}.iso"
