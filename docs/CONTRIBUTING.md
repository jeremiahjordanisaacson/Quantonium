# Contributing to Quantonium OS

Thank you for your interest in contributing to Quantonium OS! This document provides guidelines and information for contributors.

## Code of Conduct

We are committed to providing a welcoming and inspiring community for all. Please be respectful, inclusive, and constructive in all interactions.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/quantonium/quantonium-os/issues)
2. If not, create a new issue with:
   - Clear, descriptive title
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (run `neofetch` and include output)
   - Screenshots if applicable

### Suggesting Features

1. Check existing issues for similar suggestions
2. Create a new issue with the "Feature Request" template
3. Describe the feature and its use case
4. Explain why it would benefit users

### Contributing Code

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Test thoroughly
5. Commit with clear messages: `git commit -m "Add amazing feature"`
6. Push to your fork: `git push origin feature/amazing-feature`
7. Open a Pull Request

## Development Setup

### Prerequisites

- Ubuntu 22.04 LTS or newer
- Basic familiarity with Linux, bash, and Git
- At least 50 GB free disk space

### Setting Up Development Environment

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/quantonium-os.git
cd quantonium-os

# Add upstream remote
git remote add upstream https://github.com/quantonium/quantonium-os.git

# Install build dependencies
sudo apt install debootstrap squashfs-tools xorriso grub-pc-bin \
    grub-efi-amd64-bin mtools dosfstools inkscape sassc

# Optional: Install theme development tools
sudo apt install gtk-3-examples libgtk-4-dev
```

## Project Structure

```
Quantonium/
├── assets/            # Design assets (logos, screenshots)
├── branding/          # Brand guidelines
├── build-system/      # ISO build scripts
├── themes/
│   ├── gtk/           # GTK themes
│   ├── icons/         # Icon themes
│   ├── cursors/       # Cursor themes
│   ├── sounds/        # Sound themes
│   ├── plymouth/      # Boot splash
│   └── grub/          # Bootloader theme
├── wallpapers/        # Default wallpapers
├── apps/              # Custom applications
├── installer/         # Installer configuration
├── configs/           # System configuration
│   ├── dconf/         # GNOME settings
│   ├── skel/          # Default user files
│   └── system/        # System-wide config
├── packages/          # Custom packages
└── docs/              # Documentation
```

## Contribution Areas

### Themes and Visual Design

- **GTK Theme:** `themes/gtk/`
- **Icon Theme:** `themes/icons/Nebula/`
- **GNOME Shell Theme:** `themes/gtk/Quantonium-Dark/gnome-shell/`
- **Wallpapers:** `wallpapers/`

Guidelines:
- Follow the brand guidelines in `branding/BRAND_GUIDELINES.md`
- Use the defined color palette
- Test on both Xorg and Wayland
- Test with both light and dark mode applications

### Applications

- **Welcome App:** `apps/welcome-app/`
- **Settings App:** `apps/settings-app/`

Guidelines:
- Use GTK4 and libadwaita
- Follow GNOME HIG (Human Interface Guidelines)
- Support both light and dark themes
- Include `.desktop` files

### Documentation

- **User docs:** `docs/`
- **README:** `README.md`

Guidelines:
- Use clear, simple language
- Include code examples where helpful
- Keep documentation up to date with changes

### Build System

- **Main script:** `build-system/build.sh`
- **Package lists:** `build-system/packages/`

Guidelines:
- Keep scripts portable and well-commented
- Test on clean Ubuntu systems
- Document any new dependencies

## Coding Standards

### Shell Scripts

- Use `#!/bin/bash` shebang
- Use `set -e` for error handling
- Quote variables: `"$variable"`
- Use meaningful variable names
- Add comments for complex logic
- Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

### Python

- Use Python 3.10+
- Follow PEP 8
- Use type hints where helpful
- Document functions with docstrings
- Use `black` for formatting

### CSS (GTK/GNOME Shell)

- Use consistent indentation (2 spaces)
- Group related properties
- Comment non-obvious values
- Test with GTK Inspector

## Testing

### Before Submitting PR

1. **Build test:** Run full build with `sudo ./build-system/build.sh --clean`
2. **Theme test:** Install themes locally and test
3. **VM test:** Boot ISO in QEMU/VirtualBox
4. **Real hardware test:** If possible, test on actual hardware

### Testing Themes

```bash
# Copy theme to system directory
sudo cp -r themes/gtk/Quantonium-Dark /usr/share/themes/

# Apply theme
gsettings set org.gnome.desktop.interface gtk-theme "Quantonium-Dark"

# Open GTK Inspector to debug
GTK_DEBUG=interactive gnome-calculator
```

## Pull Request Process

1. Ensure all tests pass
2. Update documentation if needed
3. Fill out the PR template completely
4. Wait for review
5. Address any feedback
6. Once approved, a maintainer will merge

## Recognition

Contributors will be:
- Listed in the project's CONTRIBUTORS file
- Credited in release notes for significant contributions
- Eligible for "Quantonium Contributor" community badge

## Questions?

- Open a Discussion on GitHub
- Join our community forum at https://community.quantonium.io
- Chat with us on Matrix/Discord

Thank you for contributing to Quantonium OS!
