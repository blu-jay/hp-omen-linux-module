#!/bin/bash
# Unified installer for HP Omen Linux Module
# Supports: Debian/Ubuntu (apt), Arch (pacman), Fedora (dnf), openSUSE (zypper)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_NAME="hp-omen-wmi"
MODULE_VERSION="0.9"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root (use sudo)"
    fi
}

detect_package_manager() {
    if command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
    elif command -v zypper &> /dev/null; then
        PKG_MANAGER="zypper"
    else
        error "Unsupported package manager. Please install dkms and kernel headers manually."
    fi
    info "Detected package manager: $PKG_MANAGER"
}

install_dependencies() {
    info "Installing dependencies (dkms, kernel headers)..."

    case $PKG_MANAGER in
        apt)
            apt update
            apt install -y dkms linux-headers-$(uname -r)
            ;;
        pacman)
            pacman -Sy --noconfirm dkms linux-headers
            ;;
        dnf)
            dnf install -y dkms kernel-devel-$(uname -r)
            ;;
        zypper)
            zypper install -y dkms kernel-devel
            ;;
    esac

    info "Dependencies installed successfully"
}

install_module() {
    info "Installing kernel module via DKMS..."

    # Remove old version if exists
    if dkms status "$MODULE_NAME/$MODULE_VERSION" &> /dev/null; then
        warn "Removing existing module version..."
        dkms remove "$MODULE_NAME/$MODULE_VERSION" --all 2>/dev/null || true
    fi

    # Install new version
    cd "$SCRIPT_DIR"
    dkms install .

    # Load the module
    info "Loading kernel module..."
    modprobe hp-wmi 2>/dev/null || true

    info "Kernel module installed successfully"
}

install_cli() {
    info "Installing omen-rgb CLI tool..."

    if [ ! -f "$SCRIPT_DIR/omen-rgb" ]; then
        warn "omen-rgb not found, skipping CLI installation"
        return
    fi

    ln -sf "$SCRIPT_DIR/omen-rgb" /usr/local/bin/omen-rgb
    info "omen-rgb CLI installed to /usr/local/bin/omen-rgb"
}

uninstall_all() {
    info "Uninstalling HP Omen Linux Module..."

    # Stop daemon if running
    if [ -f /tmp/omen-rgb.pid ]; then
        info "Stopping omen-rgb daemon..."
        kill "$(cat /tmp/omen-rgb.pid)" 2>/dev/null || true
        rm -f /tmp/omen-rgb.pid
    fi

    # Unload module
    info "Unloading kernel module..."
    rmmod hp-wmi 2>/dev/null || true

    # Remove from DKMS
    info "Removing from DKMS..."
    dkms remove "$MODULE_NAME/$MODULE_VERSION" --all 2>/dev/null || true

    # Remove CLI symlink
    if [ -L /usr/local/bin/omen-rgb ]; then
        info "Removing omen-rgb CLI..."
        rm -f /usr/local/bin/omen-rgb
    fi

    info "Uninstallation complete"
}

show_help() {
    echo "HP Omen Linux Module Installer"
    echo ""
    echo "Usage: sudo ./install.sh [OPTION]"
    echo ""
    echo "Options:"
    echo "  --install, -i    Install the module and CLI (default)"
    echo "  --uninstall, -u  Uninstall everything"
    echo "  --help, -h       Show this help message"
}

main() {
    case "${1:-}" in
        --uninstall|-u)
            check_root
            uninstall_all
            ;;
        --help|-h)
            show_help
            ;;
        --install|-i|"")
            check_root
            detect_package_manager
            install_dependencies
            install_module
            install_cli
            echo ""
            info "Installation complete!"
            echo ""
            echo "Try it out:"
            echo "  sudo omen-rgb --all --color red    # Set all zones to red"
            echo "  omen-rgb --get-all                 # See current colors"
            echo "  omen-rgb --help                    # Full usage"
            ;;
        *)
            error "Unknown option: $1 (use --help for usage)"
            ;;
    esac
}

main "$@"
