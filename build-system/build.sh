#!/bin/bash
#
# Quantonium OS Build Script
# Builds a bootable ISO image based on Ubuntu 24.04 LTS
#
# Usage: sudo ./build.sh [--clean]

set -e

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$SCRIPT_DIR/build"
OUTPUT_DIR="$SCRIPT_DIR/output"
PACKAGE_LIST="$SCRIPT_DIR/packages/desktop.list"

DISTRO_NAME="Quantonium"
DISTRO_VERSION="1.0"
UBUNTU_CODENAME="noble"
ARCH="amd64"
ISO_NAME="quantonium-${DISTRO_VERSION}-${ARCH}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_step() {
    echo -e "\n${CYAN}━━━ $1 ━━━${NC}\n"
}

# =============================================================================
# Setup
# =============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

check_dependencies() {
    log_step "Checking Dependencies"

    local deps=(debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools dosfstools rsync)
    local missing=()

    for dep in "${deps[@]}"; do
        if ! dpkg -l "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_info "Installing: ${missing[*]}"
        apt-get update
        apt-get install -y "${missing[@]}"
    fi

    log_success "Dependencies satisfied"
}

prepare_build() {
    log_step "Preparing Build Environment"

    if [[ "$1" == "--clean" ]] && [[ -d "$BUILD_DIR" ]]; then
        log_info "Cleaning previous build..."
        rm -rf "$BUILD_DIR"
    fi

    mkdir -p "$BUILD_DIR"/{chroot,iso/{boot/grub,EFI/BOOT,casper,.disk}}
    mkdir -p "$OUTPUT_DIR"

    log_success "Build environment ready"
}

# =============================================================================
# Chroot Helpers
# =============================================================================

mount_chroot() {
    mount --bind /dev "$BUILD_DIR/chroot/dev" 2>/dev/null || true
    mount --bind /dev/pts "$BUILD_DIR/chroot/dev/pts" 2>/dev/null || true
    mount -t proc proc "$BUILD_DIR/chroot/proc" 2>/dev/null || true
    mount -t sysfs sysfs "$BUILD_DIR/chroot/sys" 2>/dev/null || true
    cp /etc/resolv.conf "$BUILD_DIR/chroot/etc/resolv.conf" 2>/dev/null || true
}

unmount_chroot() {
    umount "$BUILD_DIR/chroot/sys" 2>/dev/null || true
    umount "$BUILD_DIR/chroot/proc" 2>/dev/null || true
    umount "$BUILD_DIR/chroot/dev/pts" 2>/dev/null || true
    umount "$BUILD_DIR/chroot/dev" 2>/dev/null || true
}

run_chroot() {
    chroot "$BUILD_DIR/chroot" /bin/bash -c "$1"
}

# =============================================================================
# Build Steps
# =============================================================================

bootstrap_system() {
    log_step "Bootstrapping Ubuntu $UBUNTU_CODENAME"

    if [[ -d "$BUILD_DIR/chroot/bin" ]]; then
        log_info "Base system exists, skipping bootstrap"
        return
    fi

    debootstrap --arch="$ARCH" --variant=minbase \
        --components=main,restricted,universe,multiverse \
        "$UBUNTU_CODENAME" "$BUILD_DIR/chroot" \
        http://archive.ubuntu.com/ubuntu/

    log_success "Bootstrap complete"
}

configure_apt() {
    log_step "Configuring APT"

    cat > "$BUILD_DIR/chroot/etc/apt/sources.list" << EOF
deb http://archive.ubuntu.com/ubuntu/ $UBUNTU_CODENAME main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $UBUNTU_CODENAME-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $UBUNTU_CODENAME-security main restricted universe multiverse
EOF

    log_success "APT configured"
}

install_packages() {
    log_step "Installing Packages"

    mount_chroot

    # Read package list, filter comments and empty lines
    local packages
    packages=$(grep -v '^#' "$PACKAGE_LIST" | grep -v '^$' | tr '\n' ' ')

    run_chroot "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y --no-install-recommends $packages || {
            echo 'Some packages failed, continuing...'
        }
    "

    log_success "Packages installed"
}

configure_system() {
    log_step "Configuring System"

    # Hostname
    echo "quantonium" > "$BUILD_DIR/chroot/etc/hostname"

    # Hosts
    cat > "$BUILD_DIR/chroot/etc/hosts" << EOF
127.0.0.1   localhost
127.0.1.1   quantonium
::1         localhost ip6-localhost ip6-loopback
EOF

    # OS Release
    cat > "$BUILD_DIR/chroot/etc/os-release" << EOF
PRETTY_NAME="Quantonium $DISTRO_VERSION"
NAME="Quantonium"
VERSION_ID="$DISTRO_VERSION"
VERSION="$DISTRO_VERSION"
ID=quantonium
ID_LIKE=ubuntu debian
HOME_URL="https://github.com/jeremiahjordanisaacson/Quantonium"
EOF

    # Locale
    run_chroot "
        locale-gen en_US.UTF-8
        update-locale LANG=en_US.UTF-8
    "

    # Live user
    run_chroot "
        useradd -m -s /bin/bash -G sudo,adm,cdrom,plugdev quantonium 2>/dev/null || true
        echo 'quantonium:quantonium' | chpasswd
        echo 'quantonium ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/quantonium
    "

    # Enable GDM
    run_chroot "systemctl enable gdm 2>/dev/null || true"

    log_success "System configured"
}

install_customizations() {
    log_step "Installing Quantonium Customizations"

    # Create directories
    mkdir -p "$BUILD_DIR/chroot/usr/share/themes"
    mkdir -p "$BUILD_DIR/chroot/usr/share/backgrounds/quantonium"
    mkdir -p "$BUILD_DIR/chroot/usr/local/bin"
    mkdir -p "$BUILD_DIR/chroot/etc/quantonium"
    mkdir -p "$BUILD_DIR/chroot/etc/skel/.config/ripgrep"
    mkdir -p "$BUILD_DIR/chroot/etc/skel/.ssh/sockets"

    # System configs
    [[ -f "$PROJECT_ROOT/configs/system/99-quantonium-sysctl.conf" ]] && \
        cp "$PROJECT_ROOT/configs/system/99-quantonium-sysctl.conf" "$BUILD_DIR/chroot/etc/sysctl.d/"

    [[ -f "$PROJECT_ROOT/configs/system/99-quantonium-limits.conf" ]] && \
        cp "$PROJECT_ROOT/configs/system/99-quantonium-limits.conf" "$BUILD_DIR/chroot/etc/security/limits.d/"

    # Tools
    [[ -d "$PROJECT_ROOT/tools/bin" ]] && {
        cp "$PROJECT_ROOT/tools/bin/"* "$BUILD_DIR/chroot/usr/local/bin/" 2>/dev/null || true
        chmod +x "$BUILD_DIR/chroot/usr/local/bin/"* 2>/dev/null || true
    }

    # Theme
    [[ -d "$PROJECT_ROOT/themes/gtk/Quantonium-Dark" ]] && \
        cp -r "$PROJECT_ROOT/themes/gtk/Quantonium-Dark" "$BUILD_DIR/chroot/usr/share/themes/"

    # Wallpapers
    [[ -d "$PROJECT_ROOT/wallpapers" ]] && \
        cp "$PROJECT_ROOT/wallpapers/"*.svg "$BUILD_DIR/chroot/usr/share/backgrounds/quantonium/" 2>/dev/null || true

    # User dotfiles
    [[ -d "$PROJECT_ROOT/configs/skel" ]] && \
        cp -r "$PROJECT_ROOT/configs/skel/." "$BUILD_DIR/chroot/etc/skel/"

    chmod 700 "$BUILD_DIR/chroot/etc/skel/.ssh" 2>/dev/null || true
    chmod 600 "$BUILD_DIR/chroot/etc/skel/.ssh/config" 2>/dev/null || true

    # dconf settings
    if [[ -d "$PROJECT_ROOT/configs/dconf" ]]; then
        mkdir -p "$BUILD_DIR/chroot/etc/dconf/db/local.d"
        cp "$PROJECT_ROOT/configs/dconf/"* "$BUILD_DIR/chroot/etc/dconf/db/local.d/" 2>/dev/null || true
        run_chroot "dconf update 2>/dev/null || true"
    fi

    log_success "Customizations installed"
}

clean_chroot() {
    log_step "Cleaning Build"

    run_chroot "
        apt-get autoremove -y
        apt-get clean
        rm -rf /var/cache/apt/archives/*.deb
        rm -rf /var/lib/apt/lists/*
        rm -rf /tmp/*
        rm -f /etc/resolv.conf
    "

    unmount_chroot

    log_success "Cleaned"
}

create_squashfs() {
    log_step "Creating SquashFS"

    mksquashfs "$BUILD_DIR/chroot" "$BUILD_DIR/iso/casper/filesystem.squashfs" \
        -comp xz -b 1M -noappend -e boot

    du -sx --block-size=1 "$BUILD_DIR/chroot" | cut -f1 > "$BUILD_DIR/iso/casper/filesystem.size"

    log_success "SquashFS created"
}

prepare_iso() {
    log_step "Preparing ISO"

    # Copy kernel
    cp "$BUILD_DIR/chroot/boot/vmlinuz-"* "$BUILD_DIR/iso/casper/vmlinuz"
    cp "$BUILD_DIR/chroot/boot/initrd.img-"* "$BUILD_DIR/iso/casper/initrd"

    # Disk info
    echo "Quantonium $DISTRO_VERSION" > "$BUILD_DIR/iso/.disk/info"
    touch "$BUILD_DIR/iso/.disk/base_installable"

    # GRUB config
    cat > "$BUILD_DIR/iso/boot/grub/grub.cfg" << 'EOF'
set default=0
set timeout=10

menuentry "Quantonium (Live)" {
    linux /casper/vmlinuz boot=casper quiet splash ---
    initrd /casper/initrd
}

menuentry "Quantonium (Safe Graphics)" {
    linux /casper/vmlinuz boot=casper nomodeset quiet splash ---
    initrd /casper/initrd
}

menuentry "Install Quantonium" {
    linux /casper/vmlinuz boot=casper only-ubiquity quiet splash ---
    initrd /casper/initrd
}
EOF

    # EFI
    mkdir -p "$BUILD_DIR/iso/EFI/BOOT"
    cp "$BUILD_DIR/chroot/usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed" \
        "$BUILD_DIR/iso/EFI/BOOT/grubx64.efi" 2>/dev/null || \
    cp "$BUILD_DIR/chroot/usr/lib/grub/x86_64-efi/monolithic/grubx64.efi" \
        "$BUILD_DIR/iso/EFI/BOOT/grubx64.efi" 2>/dev/null || true

    cp "$BUILD_DIR/iso/boot/grub/grub.cfg" "$BUILD_DIR/iso/EFI/BOOT/"

    # Create EFI image
    dd if=/dev/zero of="$BUILD_DIR/iso/boot/grub/efi.img" bs=1M count=10
    mkfs.vfat "$BUILD_DIR/iso/boot/grub/efi.img"
    mmd -i "$BUILD_DIR/iso/boot/grub/efi.img" EFI EFI/BOOT
    mcopy -i "$BUILD_DIR/iso/boot/grub/efi.img" "$BUILD_DIR/iso/EFI/BOOT/grubx64.efi" ::EFI/BOOT/ 2>/dev/null || true
    mcopy -i "$BUILD_DIR/iso/boot/grub/efi.img" "$BUILD_DIR/iso/boot/grub/grub.cfg" ::EFI/BOOT/

    log_success "ISO prepared"
}

generate_iso() {
    log_step "Generating ISO"

    local iso_file="$OUTPUT_DIR/${ISO_NAME}.iso"

    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "Quantonium" \
        -output "$iso_file" \
        -eltorito-boot boot/grub/efi.img \
        -no-emul-boot \
        -append_partition 2 0xef "$BUILD_DIR/iso/boot/grub/efi.img" \
        -appended_part_as_gpt \
        "$BUILD_DIR/iso"

    # Checksums
    cd "$OUTPUT_DIR"
    sha256sum "${ISO_NAME}.iso" > "${ISO_NAME}.iso.sha256"

    log_success "ISO created: $iso_file"
    ls -lh "$iso_file"
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    echo "  Quantonium OS Build System"
    echo "  =========================="
    echo ""

    check_root
    check_dependencies
    prepare_build "$1"

    bootstrap_system
    configure_apt
    install_packages
    configure_system
    install_customizations
    clean_chroot

    create_squashfs
    prepare_iso
    generate_iso

    echo ""
    log_success "Build complete!"
    echo ""
}

trap unmount_chroot EXIT
main "$@"
