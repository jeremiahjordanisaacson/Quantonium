#!/bin/bash
#
# Quantonium OS Build Script
# Builds a bootable ISO image based on Ubuntu 24.04 LTS
#
# Usage: sudo ./build.sh [options]
#   Options:
#     --clean       Clean build directory before building
#     --quick       Skip some optional steps for faster builds
#     --variant     Build variant: desktop (default), minimal, developer
#     --help        Show this help message
#

set -e

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$SCRIPT_DIR/build"
OUTPUT_DIR="$SCRIPT_DIR/output"
CACHE_DIR="$SCRIPT_DIR/cache"

# Distribution info
DISTRO_NAME="Quantonium"
DISTRO_VERSION="1.0"
DISTRO_CODENAME="Nova"
DISTRO_FULLNAME="Quantonium OS $DISTRO_VERSION ($DISTRO_CODENAME)"

# Base system
UBUNTU_VERSION="24.04"
UBUNTU_CODENAME="noble"
ARCH="amd64"

# ISO naming
ISO_NAME="quantonium-${DISTRO_VERSION}-${ARCH}"
ISO_LABEL="Quantonium ${DISTRO_VERSION}"

# Build options
CLEAN_BUILD=false
QUICK_BUILD=false
BUILD_VARIANT="desktop"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

show_banner() {
    echo -e "${PURPLE}"
    cat << 'EOF'
   ____                    _              _
  / __ \                  | |            (_)
 | |  | |_   _  __ _ _ __ | |_ ___  _ __  _ _   _ _ __ ___
 | |  | | | | |/ _` | '_ \| __/ _ \| '_ \| | | | | '_ ` _ \
 | |__| | |_| | (_| | | | | || (_) | | | | | |_| | | | | | |
  \___\_\\__,_|\__,_|_| |_|\__\___/|_| |_|_|\__,_|_| |_| |_|

             The Future of Desktop Linux
EOF
    echo -e "${NC}"
    echo -e "${CYAN}Build System v1.0${NC}"
    echo ""
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_dependencies() {
    log_step "Checking Dependencies"

    local deps=(
        "debootstrap"
        "squashfs-tools"
        "xorriso"
        "grub-pc-bin"
        "grub-efi-amd64-bin"
        "mtools"
        "dosfstools"
        "unzip"
        "wget"
        "curl"
        "git"
        "rsync"
    )

    local missing=()

    for dep in "${deps[@]}"; do
        if ! dpkg -l | grep -q "^ii  $dep "; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warning "Missing dependencies: ${missing[*]}"
        log_info "Installing missing dependencies..."
        apt-get update
        apt-get install -y "${missing[@]}"
    fi

    log_success "All dependencies satisfied"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                CLEAN_BUILD=true
                shift
                ;;
            --quick)
                QUICK_BUILD=true
                shift
                ;;
            --variant)
                BUILD_VARIANT="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    echo "Usage: sudo $0 [options]"
    echo ""
    echo "Options:"
    echo "  --clean       Clean build directory before building"
    echo "  --quick       Skip optional steps for faster builds"
    echo "  --variant X   Build variant: desktop (default), minimal, developer"
    echo "  --help        Show this help message"
}

# =============================================================================
# Build Functions
# =============================================================================

prepare_build_env() {
    log_step "Preparing Build Environment"

    if [[ "$CLEAN_BUILD" == true ]] && [[ -d "$BUILD_DIR" ]]; then
        log_info "Cleaning previous build..."
        rm -rf "$BUILD_DIR"
    fi

    mkdir -p "$BUILD_DIR"/{chroot,iso/{boot/grub,EFI/BOOT,casper,preseed,.disk}}
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$CACHE_DIR"

    log_success "Build environment ready"
}

bootstrap_base_system() {
    log_step "Bootstrapping Base System (Ubuntu $UBUNTU_VERSION)"

    if [[ -d "$BUILD_DIR/chroot/bin" ]]; then
        log_info "Base system already bootstrapped, skipping..."
        return
    fi

    log_info "Running debootstrap (this may take a while)..."

    debootstrap \
        --arch="$ARCH" \
        --variant=minbase \
        --components=main,restricted,universe,multiverse \
        "$UBUNTU_CODENAME" \
        "$BUILD_DIR/chroot" \
        http://archive.ubuntu.com/ubuntu/

    log_success "Base system bootstrapped"
}

configure_apt_sources() {
    log_step "Configuring APT Sources"

    cat > "$BUILD_DIR/chroot/etc/apt/sources.list" << EOF
# Ubuntu $UBUNTU_VERSION ($UBUNTU_CODENAME) - Main
deb http://archive.ubuntu.com/ubuntu/ $UBUNTU_CODENAME main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $UBUNTU_CODENAME-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $UBUNTU_CODENAME-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ $UBUNTU_CODENAME-security main restricted universe multiverse
EOF

    log_success "APT sources configured"
}

mount_chroot_filesystems() {
    log_info "Mounting chroot filesystems..."

    mount --bind /dev "$BUILD_DIR/chroot/dev" || true
    mount --bind /dev/pts "$BUILD_DIR/chroot/dev/pts" || true
    mount -t proc proc "$BUILD_DIR/chroot/proc" || true
    mount -t sysfs sysfs "$BUILD_DIR/chroot/sys" || true
    mount -t tmpfs tmpfs "$BUILD_DIR/chroot/tmp" || true

    # Copy resolv.conf for network access
    cp /etc/resolv.conf "$BUILD_DIR/chroot/etc/resolv.conf" || true
}

unmount_chroot_filesystems() {
    log_info "Unmounting chroot filesystems..."

    umount "$BUILD_DIR/chroot/tmp" 2>/dev/null || true
    umount "$BUILD_DIR/chroot/sys" 2>/dev/null || true
    umount "$BUILD_DIR/chroot/proc" 2>/dev/null || true
    umount "$BUILD_DIR/chroot/dev/pts" 2>/dev/null || true
    umount "$BUILD_DIR/chroot/dev" 2>/dev/null || true
}

run_in_chroot() {
    chroot "$BUILD_DIR/chroot" /bin/bash -c "$1"
}

install_kernel_and_base() {
    log_step "Installing Linux Kernel and Base Packages"

    mount_chroot_filesystems

    run_in_chroot "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y \
            linux-image-generic \
            linux-headers-generic \
            linux-firmware \
            systemd \
            systemd-sysv \
            dbus \
            udev \
            sudo \
            locales \
            console-setup \
            keyboard-configuration \
            tzdata \
            network-manager \
            wpasupplicant \
            wireless-tools \
            iw \
            rfkill \
            pciutils \
            usbutils \
            dmidecode \
            hdparm \
            smartmontools
    "

    log_success "Kernel and base packages installed"
}

install_desktop_environment() {
    log_step "Installing Desktop Environment"

    run_in_chroot "
        export DEBIAN_FRONTEND=noninteractive

        # Install GNOME Desktop
        apt-get install -y \
            gnome-shell \
            gnome-session \
            gdm3 \
            gnome-control-center \
            gnome-tweaks \
            gnome-shell-extensions \
            gnome-terminal \
            nautilus \
            nautilus-extension-gnome-terminal \
            gedit \
            eog \
            evince \
            gnome-calculator \
            gnome-calendar \
            gnome-clocks \
            gnome-contacts \
            gnome-weather \
            gnome-system-monitor \
            gnome-disk-utility \
            gnome-software \
            gnome-screenshot \
            gnome-font-viewer \
            gnome-characters \
            gnome-logs \
            baobab \
            file-roller \
            seahorse \
            deja-dup \
            simple-scan \
            cheese \
            totem \
            rhythmbox \
            shotwell \
            transmission-gtk \
            gparted

        # Enable GDM
        systemctl enable gdm
    "

    log_success "GNOME Desktop Environment installed"
}

install_applications() {
    log_step "Installing Default Applications"

    run_in_chroot "
        export DEBIAN_FRONTEND=noninteractive

        # Web Browser
        apt-get install -y firefox

        # Office Suite
        apt-get install -y libreoffice libreoffice-gnome

        # Graphics
        apt-get install -y gimp inkscape

        # Development Tools
        apt-get install -y \
            git \
            curl \
            wget \
            vim \
            nano \
            htop \
            neofetch \
            build-essential \
            python3 \
            python3-pip \
            python3-venv \
            nodejs \
            npm

        # Multimedia Codecs
        apt-get install -y \
            ubuntu-restricted-extras \
            ffmpeg \
            gstreamer1.0-plugins-bad \
            gstreamer1.0-plugins-ugly \
            gstreamer1.0-libav

        # System Utilities
        apt-get install -y \
            tlp \
            tlp-rdw \
            powertop \
            preload \
            cups \
            cups-browsed \
            system-config-printer \
            avahi-daemon \
            bluetooth \
            bluez \
            blueman \
            pulseaudio \
            pulseaudio-module-bluetooth \
            pavucontrol \
            flatpak \
            gnome-software-plugin-flatpak \
            snapd

        # Fonts
        apt-get install -y \
            fonts-inter \
            fonts-jetbrains-mono \
            fonts-noto \
            fonts-noto-color-emoji \
            fonts-liberation \
            fonts-dejavu-core

        # Archive formats
        apt-get install -y \
            p7zip-full \
            p7zip-rar \
            unrar \
            zip \
            unzip
    "

    log_success "Applications installed"
}

install_drivers() {
    log_step "Installing Hardware Drivers"

    run_in_chroot "
        export DEBIAN_FRONTEND=noninteractive

        # GPU Drivers
        apt-get install -y \
            xserver-xorg-video-all \
            mesa-utils \
            mesa-vulkan-drivers \
            libgl1-mesa-dri \
            vainfo \
            vdpauinfo

        # NVIDIA support (will be enabled if hardware detected)
        apt-get install -y \
            nvidia-driver-535 \
            nvidia-settings \
            || true

        # Printer drivers
        apt-get install -y \
            printer-driver-all \
            hplip \
            || true

        # Touchpad
        apt-get install -y \
            xserver-xorg-input-all \
            libinput-tools

        # Firmware
        apt-get install -y \
            firmware-sof-signed \
            || true
    "

    log_success "Hardware drivers installed"
}

install_live_system_packages() {
    log_step "Installing Live System Packages"

    run_in_chroot "
        export DEBIAN_FRONTEND=noninteractive

        apt-get install -y \
            casper \
            lupin-casper \
            discover \
            laptop-detect \
            os-prober \
            ubiquity \
            ubiquity-frontend-gtk \
            ubiquity-slideshow-ubuntu \
            memtest86+ \
            grub-pc \
            grub-efi-amd64-signed \
            shim-signed
    "

    log_success "Live system packages installed"
}

configure_system() {
    log_step "Configuring System"

    # Set hostname
    echo "quantonium" > "$BUILD_DIR/chroot/etc/hostname"

    # Configure hosts
    cat > "$BUILD_DIR/chroot/etc/hosts" << EOF
127.0.0.1   localhost
127.0.1.1   quantonium

# IPv6
::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

    # Set locale
    run_in_chroot "
        locale-gen en_US.UTF-8
        update-locale LANG=en_US.UTF-8
    "

    # Set timezone (will be configured during install)
    run_in_chroot "
        ln -sf /usr/share/zoneinfo/UTC /etc/localtime
    "

    # Configure live user
    run_in_chroot "
        useradd -m -s /bin/bash -G sudo,adm,cdrom,plugdev,lpadmin quantonium || true
        echo 'quantonium:quantonium' | chpasswd
        echo 'quantonium ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/quantonium
    "

    log_success "System configured"
}

install_quantonium_branding() {
    log_step "Installing Quantonium Customizations"

    # Create directories
    mkdir -p "$BUILD_DIR/chroot/usr/share/quantonium"
    mkdir -p "$BUILD_DIR/chroot/usr/share/themes"
    mkdir -p "$BUILD_DIR/chroot/usr/share/backgrounds/quantonium"
    mkdir -p "$BUILD_DIR/chroot/usr/local/bin"
    mkdir -p "$BUILD_DIR/chroot/etc/quantonium"
    mkdir -p "$BUILD_DIR/chroot/etc/skel/.config/ripgrep"
    mkdir -p "$BUILD_DIR/chroot/etc/skel/.ssh"

    # --- System Configuration ---
    log_info "Installing system configuration..."

    # Sysctl settings (kernel parameters)
    if [[ -f "$PROJECT_ROOT/configs/system/99-quantonium-sysctl.conf" ]]; then
        cp "$PROJECT_ROOT/configs/system/99-quantonium-sysctl.conf" \
            "$BUILD_DIR/chroot/etc/sysctl.d/"
    fi

    # User limits
    if [[ -f "$PROJECT_ROOT/configs/system/99-quantonium-limits.conf" ]]; then
        cp "$PROJECT_ROOT/configs/system/99-quantonium-limits.conf" \
            "$BUILD_DIR/chroot/etc/security/limits.d/"
    fi

    # Quantonium config
    if [[ -f "$PROJECT_ROOT/configs/system/quantonium.conf" ]]; then
        cp "$PROJECT_ROOT/configs/system/quantonium.conf" \
            "$BUILD_DIR/chroot/etc/quantonium/"
    fi

    # --- Quantonium Tools ---
    log_info "Installing Quantonium tools..."

    if [[ -d "$PROJECT_ROOT/tools/bin" ]]; then
        cp "$PROJECT_ROOT/tools/bin/"* "$BUILD_DIR/chroot/usr/local/bin/" || true
        chmod +x "$BUILD_DIR/chroot/usr/local/bin/qsys" 2>/dev/null || true
        chmod +x "$BUILD_DIR/chroot/usr/local/bin/qdev" 2>/dev/null || true
    fi

    # --- Theme ---
    log_info "Installing theme..."

    if [[ -d "$PROJECT_ROOT/themes/gtk/Quantonium-Dark" ]]; then
        cp -r "$PROJECT_ROOT/themes/gtk/Quantonium-Dark" "$BUILD_DIR/chroot/usr/share/themes/"
    fi

    # --- Wallpapers ---
    if [[ -d "$PROJECT_ROOT/wallpapers" ]]; then
        cp -r "$PROJECT_ROOT/wallpapers/"* "$BUILD_DIR/chroot/usr/share/backgrounds/quantonium/" || true
    fi

    # --- User Skeleton (dotfiles) ---
    log_info "Installing user defaults..."

    if [[ -d "$PROJECT_ROOT/configs/skel" ]]; then
        # Copy all dotfiles
        cp -r "$PROJECT_ROOT/configs/skel/." "$BUILD_DIR/chroot/etc/skel/"

        # Ensure SSH directory has correct permissions
        chmod 700 "$BUILD_DIR/chroot/etc/skel/.ssh" 2>/dev/null || true
        chmod 600 "$BUILD_DIR/chroot/etc/skel/.ssh/config" 2>/dev/null || true

        # Create SSH sockets directory
        mkdir -p "$BUILD_DIR/chroot/etc/skel/.ssh/sockets"
    fi

    # --- dconf Settings (GNOME) ---
    if [[ -d "$PROJECT_ROOT/configs/dconf" ]]; then
        mkdir -p "$BUILD_DIR/chroot/etc/dconf/profile"
        mkdir -p "$BUILD_DIR/chroot/etc/dconf/db/local.d"
        cp -r "$PROJECT_ROOT/configs/dconf/"* "$BUILD_DIR/chroot/etc/dconf/db/local.d/" || true

        run_in_chroot "dconf update" || true
    fi

    # Set OS release info
    cat > "$BUILD_DIR/chroot/etc/os-release" << EOF
PRETTY_NAME="$DISTRO_FULLNAME"
NAME="$DISTRO_NAME"
VERSION_ID="$DISTRO_VERSION"
VERSION="$DISTRO_VERSION ($DISTRO_CODENAME)"
VERSION_CODENAME=$DISTRO_CODENAME
ID=quantonium
ID_LIKE=ubuntu debian
HOME_URL="https://quantonium.io"
SUPPORT_URL="https://quantonium.io/support"
BUG_REPORT_URL="https://github.com/quantonium/quantonium-os/issues"
PRIVACY_POLICY_URL="https://quantonium.io/privacy"
UBUNTU_CODENAME=$UBUNTU_CODENAME
EOF

    # LSB release
    cat > "$BUILD_DIR/chroot/etc/lsb-release" << EOF
DISTRIB_ID=$DISTRO_NAME
DISTRIB_RELEASE=$DISTRO_VERSION
DISTRIB_CODENAME=$DISTRO_CODENAME
DISTRIB_DESCRIPTION="$DISTRO_FULLNAME"
EOF

    log_success "Quantonium branding installed"
}

clean_chroot() {
    log_step "Cleaning Chroot Environment"

    run_in_chroot "
        apt-get autoremove -y
        apt-get clean
        rm -rf /var/cache/apt/archives/*.deb
        rm -rf /var/lib/apt/lists/*
        rm -rf /tmp/*
        rm -rf /var/tmp/*
        rm -f /etc/resolv.conf
        rm -f /root/.bash_history
        rm -f /home/*/.bash_history
    "

    unmount_chroot_filesystems

    log_success "Chroot cleaned"
}

create_squashfs() {
    log_step "Creating SquashFS Filesystem"

    log_info "Compressing filesystem (this may take a while)..."

    mksquashfs "$BUILD_DIR/chroot" "$BUILD_DIR/iso/casper/filesystem.squashfs" \
        -comp xz \
        -b 1M \
        -Xdict-size 100% \
        -noappend \
        -e boot

    # Generate filesystem size
    du -sx --block-size=1 "$BUILD_DIR/chroot" | cut -f1 > "$BUILD_DIR/iso/casper/filesystem.size"

    # Generate filesystem manifest
    run_in_chroot "dpkg-query -W --showformat='\${Package} \${Version}\n'" > "$BUILD_DIR/iso/casper/filesystem.manifest"

    log_success "SquashFS created"
}

prepare_iso_structure() {
    log_step "Preparing ISO Structure"

    # Copy kernel and initrd
    cp "$BUILD_DIR/chroot/boot/vmlinuz-"* "$BUILD_DIR/iso/casper/vmlinuz"
    cp "$BUILD_DIR/chroot/boot/initrd.img-"* "$BUILD_DIR/iso/casper/initrd"

    # Create disk info
    echo "$DISTRO_FULLNAME - Build $(date +%Y%m%d)" > "$BUILD_DIR/iso/.disk/info"
    touch "$BUILD_DIR/iso/.disk/base_installable"
    echo "full_cd/single" > "$BUILD_DIR/iso/.disk/cd_type"

    # Copy memtest
    if [[ -f "$BUILD_DIR/chroot/boot/memtest86+x64.bin" ]]; then
        cp "$BUILD_DIR/chroot/boot/memtest86+x64.bin" "$BUILD_DIR/iso/boot/memtest86+"
    fi

    log_success "ISO structure prepared"
}

create_grub_config() {
    log_step "Creating GRUB Configuration"

    cat > "$BUILD_DIR/iso/boot/grub/grub.cfg" << 'EOF'
# Quantonium OS GRUB Configuration

set default=0
set timeout=10

# Load theme if available
if [ -d /boot/grub/themes/quantonium ]; then
    set theme=/boot/grub/themes/quantonium/theme.txt
fi

# Colors
set menu_color_normal=light-gray/black
set menu_color_highlight=white/dark-gray

menuentry "Quantonium OS (Live)" {
    set gfxpayload=keep
    linux /casper/vmlinuz boot=casper quiet splash ---
    initrd /casper/initrd
}

menuentry "Quantonium OS (Safe Graphics)" {
    set gfxpayload=keep
    linux /casper/vmlinuz boot=casper nomodeset quiet splash ---
    initrd /casper/initrd
}

menuentry "Quantonium OS (Install)" {
    set gfxpayload=keep
    linux /casper/vmlinuz boot=casper only-ubiquity quiet splash ---
    initrd /casper/initrd
}

menuentry "OEM Install (for manufacturers)" {
    set gfxpayload=keep
    linux /casper/vmlinuz boot=casper only-ubiquity quiet splash oem-config/enable=true ---
    initrd /casper/initrd
}

menuentry "Check disc for defects" {
    set gfxpayload=keep
    linux /casper/vmlinuz boot=casper integrity-check quiet splash ---
    initrd /casper/initrd
}

menuentry "Memory test" {
    linux /boot/memtest86+
}

menuentry "Boot from first hard disk" {
    set root=(hd0)
    chainloader +1
}

submenu "Advanced options..." {
    menuentry "Quantonium OS (Debug Mode)" {
        linux /casper/vmlinuz boot=casper debug ---
        initrd /casper/initrd
    }

    menuentry "Quantonium OS (Recovery Mode)" {
        linux /casper/vmlinuz boot=casper recovery ---
        initrd /casper/initrd
    }

    menuentry "Quantonium OS (Text Mode)" {
        linux /casper/vmlinuz boot=casper systemd.unit=multi-user.target ---
        initrd /casper/initrd
    }
}
EOF

    log_success "GRUB configuration created"
}

create_efi_image() {
    log_step "Creating EFI Boot Image"

    # Create EFI directory structure
    mkdir -p "$BUILD_DIR/iso/EFI/BOOT"

    # Copy EFI files
    cp "$BUILD_DIR/chroot/usr/lib/shim/shimx64.efi.signed" "$BUILD_DIR/iso/EFI/BOOT/BOOTx64.EFI" || \
    cp "$BUILD_DIR/chroot/usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed" "$BUILD_DIR/iso/EFI/BOOT/BOOTx64.EFI"

    cp "$BUILD_DIR/chroot/usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed" "$BUILD_DIR/iso/EFI/BOOT/grubx64.efi" || true

    # Create EFI GRUB config
    mkdir -p "$BUILD_DIR/iso/boot/grub"
    cp "$BUILD_DIR/iso/boot/grub/grub.cfg" "$BUILD_DIR/iso/EFI/BOOT/grub.cfg"

    # Create EFI image
    dd if=/dev/zero of="$BUILD_DIR/iso/boot/grub/efi.img" bs=1M count=10
    mkfs.vfat "$BUILD_DIR/iso/boot/grub/efi.img"

    mmd -i "$BUILD_DIR/iso/boot/grub/efi.img" EFI
    mmd -i "$BUILD_DIR/iso/boot/grub/efi.img" EFI/BOOT
    mcopy -i "$BUILD_DIR/iso/boot/grub/efi.img" "$BUILD_DIR/iso/EFI/BOOT/BOOTx64.EFI" ::EFI/BOOT/
    mcopy -i "$BUILD_DIR/iso/boot/grub/efi.img" "$BUILD_DIR/iso/EFI/BOOT/grubx64.efi" ::EFI/BOOT/ || true
    mcopy -i "$BUILD_DIR/iso/boot/grub/efi.img" "$BUILD_DIR/iso/boot/grub/grub.cfg" ::EFI/BOOT/

    log_success "EFI boot image created"
}

generate_iso() {
    log_step "Generating ISO Image"

    local iso_file="$OUTPUT_DIR/${ISO_NAME}.iso"

    log_info "Creating ISO: $iso_file"

    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "$ISO_LABEL" \
        -output "$iso_file" \
        -eltorito-boot boot/grub/bios.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog boot/grub/boot.cat \
        --grub2-boot-info \
        --grub2-mbr "$BUILD_DIR/chroot/usr/lib/grub/i386-pc/boot_hybrid.img" \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -append_partition 2 0xef "$BUILD_DIR/iso/boot/grub/efi.img" \
        -m "boot/grub/efi.img" \
        -graft-points \
        "$BUILD_DIR/iso" \
        /boot/grub/bios.img="$BUILD_DIR/chroot/usr/lib/grub/i386-pc/boot.img"

    # Generate checksums
    log_info "Generating checksums..."
    cd "$OUTPUT_DIR"
    sha256sum "${ISO_NAME}.iso" > "${ISO_NAME}.iso.sha256"
    md5sum "${ISO_NAME}.iso" > "${ISO_NAME}.iso.md5"

    log_success "ISO generated successfully!"
}

print_summary() {
    local iso_file="$OUTPUT_DIR/${ISO_NAME}.iso"
    local iso_size=$(du -h "$iso_file" | cut -f1)

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  BUILD COMPLETE${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${CYAN}Distribution:${NC}  $DISTRO_FULLNAME"
    echo -e "  ${CYAN}Architecture:${NC}  $ARCH"
    echo -e "  ${CYAN}Variant:${NC}       $BUILD_VARIANT"
    echo ""
    echo -e "  ${CYAN}ISO Location:${NC}  $iso_file"
    echo -e "  ${CYAN}ISO Size:${NC}      $iso_size"
    echo ""
    echo -e "  ${CYAN}SHA256:${NC}        $(cat "$OUTPUT_DIR/${ISO_NAME}.iso.sha256" | cut -d' ' -f1)"
    echo ""
    echo -e "  ${YELLOW}To write to USB:${NC}"
    echo -e "    sudo dd if=$iso_file of=/dev/sdX bs=4M status=progress conv=fsync"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    show_banner
    parse_args "$@"
    check_root
    check_dependencies

    prepare_build_env
    bootstrap_base_system
    configure_apt_sources

    install_kernel_and_base
    install_desktop_environment
    install_applications
    install_drivers
    install_live_system_packages

    configure_system
    install_quantonium_branding

    clean_chroot
    create_squashfs
    prepare_iso_structure
    create_grub_config
    create_efi_image
    generate_iso

    print_summary
}

# Trap to ensure cleanup on exit
trap unmount_chroot_filesystems EXIT

main "$@"
