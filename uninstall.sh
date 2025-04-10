#!/bin/bash

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_DIR="${SCRIPT_DIR}/packages"
readonly PACKAGE_JSON="$HOME/oh-my-package/omp-package.json"

# Source the message functions
source "${SCRIPT_DIR}/lib/messages.sh"

# Function to show usage information
show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -k, --keep    Keep local package directories (.local, .oh-my-zsh)"
    echo "  -h, --help    Show this help message"
    exit 0
}

# Function to remove package.json file
remove_package_json() {
    info "Removing omp-package.json..."
    if [ -f "$PACKAGE_JSON" ]; then
        rm -f "$PACKAGE_JSON" || {
            error "Failed to remove omp-package.json"
            return 1
        }
    else
        info "No omp-package.json found"
    fi
    return 0
}

# Function to remove global symlink
remove_global_symlink() {
    info "Removing global omp command..."
    
    # Check common locations for the symlink
    if [ -L "$HOME/bin/omp" ]; then
        rm -f "$HOME/bin/omp" || {
            warn "Failed to remove symlink from $HOME/bin/omp"
            return 1
        }
        success "Removed symlink from $HOME/bin/omp"
    elif [ -L "$HOME/.local/bin/omp" ]; then
        if [ -w "$HOME/.local/bin" ]; then
            rm -f "$HOME/.local/bin/omp" || {
                warn "Failed to remove symlink from $HOME/.local/bin/omp"
                return 1
            }
            success "Removed symlink from $HOME/.local/bin/omp"
        else
            info "Attempting to remove symlink with sudo..."
            if sudo rm -f "$HOME/.local/bin/omp"; then
                success "Removed symlink from $HOME/.local/bin/omp (with sudo)"
            else
                warn "Failed to remove symlink from $HOME/.local/bin/omp"
                return 1
            fi
        fi
    else
        info "No global symlink found for omp command"
    fi
    
    return 0
}

# --- Main Logic ---

# Parse command line arguments
KEEP_LOCAL=false
SHOW_HELP=false
ARGS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -k|--keep)
            KEEP_LOCAL=true
            ARGS="$ARGS -k"
            shift
            ;;
        -h|--help)
            SHOW_HELP=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            show_usage
            ;;
    esac
done

if [ "$SHOW_HELP" = true ]; then
    show_usage
fi

# Header
info "****************************************************************"
info "            Starting Oh-My-Package Uninstallation"
info "****************************************************************"
echo ""

if [ "$KEEP_LOCAL" = true ]; then
    info "Keeping local folders (--keep option used)"
fi

# Uninstall each package
PACKAGES=("omz" "stow" "jq")
SUCCESS=true

for package in "${PACKAGES[@]}"; do
    if [ -f "${PACKAGES_DIR}/${package}/uninstall.sh" ]; then
        info "Uninstalling ${package}..."
        if ! bash "${PACKAGES_DIR}/${package}/uninstall.sh" $ARGS; then
            error "Failed to uninstall ${package}"
            SUCCESS=false
        fi
    else
        warn "No uninstall script found for ${package}"
    fi
done

# Remove global symlink
if ! remove_global_symlink; then
    SUCCESS=false
fi

# Remove package.json
if ! remove_package_json; then
    SUCCESS=false
fi

# Footer
echo ""
info "****************************************************************"
if [ "$SUCCESS" = true ]; then
    success "       Oh-My-Package Uninstallation Completed Successfully"
else
    error "       Oh-My-Package Uninstallation Completed with Errors"
fi
info "****************************************************************"
echo ""

if [ "$SUCCESS" = true ]; then
    exit 0
else
    exit 1
fi
