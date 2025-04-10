#!/bin/bash

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly OMP_DIR="$(dirname "${PACKAGES_DIR}")"
readonly LOCAL_DIR="${SCRIPT_DIR}/.local"
readonly OMZ_DIR="${SCRIPT_DIR}/.oh-my-zsh"

# Source the message functions
source "${OMP_DIR}/lib/messages.sh"

# Package information
readonly NAME="OMZ"

# Parse command line arguments
KEEP_LOCAL=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -k|--keep)
            KEEP_LOCAL=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Show uninstallation header
info "****************************************************************"
info "                     Uninstalling $NAME"
info "****************************************************************"
echo ""

# Remove symbolic links using stow
info "Removing $NAME symbolic links..."
if command -v stow &> /dev/null; then
    if ! stow -d "$PACKAGES_DIR" -t "$HOME" -D "omz"; then
        error "Failed to remove $NAME symbolic links with stow"
        exit 1
    fi
else
    warn "stow command not found, skipping symbolic link removal"
fi

# Remove local folder
if [ "$KEEP_LOCAL" = true ]; then
    info "Keeping $NAME local folder (--keep option used)"
else
    info "Removing $NAME local folder..."
    if [ -d "$LOCAL_DIR" ]; then
        rm -rf "$LOCAL_DIR" || {
            error "Failed to remove $NAME local folder"
            exit 1
        }
    else
        info "No local folder found for $NAME"
    fi
fi

# Remove .oh-my-zsh folder
if [ "$KEEP_LOCAL" = true ]; then
    info "Keeping $NAME .oh-my-zsh folder (--keep option used)"
else
    info "Removing $NAME .oh-my-zsh folder..."
    if [ -d "$OMZ_DIR" ]; then
        rm -rf "$OMZ_DIR" || {
            error "Failed to remove $NAME .oh-my-zsh folder"
            exit 1
        }
    else
        info "No .oh-my-zsh folder found"
    fi
fi

# Restore .zshrc backup if exists
readonly BACKUP_DIR="${SCRIPT_DIR}/.local"
if [ -d "$BACKUP_DIR" ]; then
    # Find the most recent backup
    LATEST_BACKUP=$(find "$BACKUP_DIR" -name ".zshrc.pre-omp-*" -type f -printf "%T@ %p\n" | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [ -n "$LATEST_BACKUP" ]; then
        info "Restoring .zshrc from backup: $(basename "$LATEST_BACKUP")"
        cp "$LATEST_BACKUP" "$HOME/.zshrc" || {
            error "Failed to restore .zshrc from backup"
            exit 1
        }
        success "Restored .zshrc from backup"
    else
        info "No .zshrc backup found"
    fi
fi

# Show uninstallation footer
echo ""
info "****************************************************************"
info "                 $NAME Uninstallation Complete"
info "****************************************************************"
echo ""

exit 0 