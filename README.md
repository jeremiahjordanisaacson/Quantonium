# Quantonium

A developer-focused Linux distribution based on Ubuntu 24.04 LTS.

## What This Is

Quantonium is Ubuntu with opinionated defaults for software developers:

- **Modern CLI tools** pre-installed: ripgrep, fd, fzf, bat, zoxide, jq, delta
- **Container-ready**: Docker, Podman, kubectl out of the box
- **Languages**: Python, Node.js, Go, Rust, C/C++ toolchains
- **System tuning**: Higher file limits, optimized kernel parameters
- **Developer configs**: Useful gitconfig, tmux, SSH defaults

It's not a fork. It's not a "new OS". It's a curated Ubuntu setup that saves you an afternoon of configuration.

## System Requirements

| | Minimum | Recommended |
|---|---------|-------------|
| CPU | 2 cores | 4+ cores |
| RAM | 4 GB | 8+ GB |
| Storage | 25 GB | 50 GB SSD |
| Display | 1024x768 | 1920x1080 |

## What's Included

### Modern CLI Tools

| Tool | Replaces | Why |
|------|----------|-----|
| [ripgrep](https://github.com/BurntSushi/ripgrep) | grep | 10-100x faster, respects .gitignore |
| [fd](https://github.com/sharkdp/fd) | find | Faster, saner defaults |
| [bat](https://github.com/sharkdp/bat) | cat | Syntax highlighting |
| [fzf](https://github.com/junegunn/fzf) | - | Fuzzy finder for everything |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | cd | Learns your habits |
| [delta](https://github.com/dandavison/delta) | diff | Better git diffs |
| [jq](https://github.com/stedolan/jq) | - | JSON processor |
| [tldr](https://github.com/tldr-pages/tldr) | man | Practical examples |

### Development Stack

```
Languages:       Python 3, Node.js, Go, Rust, GCC, Clang
Containers:      Docker, Docker Compose, Podman, buildah
Orchestration:   kubectl
Databases:       PostgreSQL, MySQL, SQLite, Redis clients
Debugging:       gdb, valgrind, strace, perf
```

### System Configuration

- **Kernel parameters** tuned for developer workloads (high inotify limits, better I/O scheduling)
- **File limits** raised for IDEs and containers
- **Bash** configured with useful aliases, completions, and fzf integration
- **Git** with delta diffs, useful aliases, sensible defaults
- **tmux** configured and themed
- **SSH** with connection multiplexing and modern crypto defaults

### Quantonium Tools

Two CLI utilities are included:

**qsys** - System diagnostics
```bash
qsys info     # System information
qsys health   # Health check (load, memory, disk, services)
qsys dev      # Development environment status
qsys net      # Network diagnostics
```

**qdev** - Development helpers
```bash
qdev init python myproject   # Scaffold Python project with venv
qdev init node myproject     # Scaffold Node.js project
qdev docker clean            # Clean unused Docker resources
qdev port kill 3000          # Kill process on port
qdev db postgres start       # Spin up local PostgreSQL
```

## Building

Requires Ubuntu 22.04+ or Debian 12+.

```bash
# Install dependencies
sudo apt install debootstrap squashfs-tools xorriso grub-pc-bin \
    grub-efi-amd64-bin mtools dosfstools

# Build
sudo ./build-system/build.sh

# Output: build-system/output/quantonium-1.0-amd64.iso
```

Write to USB:
```bash
sudo dd if=quantonium-1.0-amd64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

## What's NOT Included

Things we deliberately left out:

- **Games** - Install them yourself if you want them
- **Office suite** - LibreOffice is one `apt install` away
- **Media editors** - Too specialized, too large
- **Snap** - Flatpak only, fewer daemons
- **Ubuntu branding** - Obviously

## Customization

### Package Selection

Edit `build-system/packages/desktop.list` to add/remove packages.

### Shell Configuration

User configs live in `configs/skel/`:
- `.bashrc` - Shell configuration
- `.gitconfig` - Git defaults
- `.tmux.conf` - tmux configuration
- `.ssh/config` - SSH defaults

### System Configuration

- `configs/system/99-quantonium-sysctl.conf` - Kernel parameters
- `configs/system/99-quantonium-limits.conf` - User limits
- `configs/dconf/00-quantonium-settings` - GNOME/GTK settings

### Theme

The GTK theme is in `themes/gtk/Quantonium-Dark/`. It's a dark theme with purple/cyan accents. Modify or replace it.

## Versioning

Quantonium follows Ubuntu LTS releases. Version 1.0 is based on Ubuntu 24.04 (Noble Numbat).

| Quantonium | Ubuntu Base | Support Until |
|------------|-------------|---------------|
| 1.0 | 24.04 LTS | April 2029 |

## FAQ

**Is this just a reskin?**

Mostly, yes. But it's a reskin with substance: the CLI tools, system tuning, and developer configs are the actual value. The theme is secondary.

**Why not just a dotfiles repo?**

A dotfiles repo doesn't give you a live USB, an installer, or pre-configured system limits. This does.

**Can I use this for production servers?**

It's designed for developer workstations. For servers, use plain Ubuntu Server.

**How do I update?**

Standard apt: `sudo apt update && sudo apt upgrade`. You're running Ubuntu.

## License

GPL v3. See [LICENSE](LICENSE).

Quantonium is built on Ubuntu, GNOME, and thousands of open-source projects.
