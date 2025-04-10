#!/bin/bash

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly OMP_DIR="$(dirname "${PACKAGES_DIR}")"
readonly LOCAL_DIR="${SCRIPT_DIR}/.local"
readonly BIN_DIR="${LOCAL_DIR}/bin"
readonly DOWNLOAD_DIR="${SCRIPT_DIR}/downloads"

# Source the message functions
source "${OMP_DIR}/lib/messages.sh"

# Package information
readonly NAME="bat"

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
    if ! stow -d "$PACKAGES_DIR" -t "$HOME" -D "bat"; then
        error "Failed to remove $NAME symbolic links with stow"
        exit 1
    fi
    success "Symbolic links removed successfully."
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
        success "Local folder removed successfully."
    else
        info "No local folder found for $NAME"
    fi
fi

# Remove downloads folder
if [ "$KEEP_LOCAL" = true ]; then
    info "Keeping $NAME downloads folder (--keep option used)"
else
    info "Removing $NAME downloads folder..."
    if [ -d "$DOWNLOAD_DIR" ]; then
        rm -rf "$DOWNLOAD_DIR" || {
            error "Failed to remove $NAME downloads folder"
            exit 1
        }
        success "Downloads folder removed successfully."
    else
        info "No downloads folder found for $NAME"
    fi
fi

# Remove package from omp-package.json
info "Removing $NAME from omp-package.json..."
PACKAGE_JSON="${OMP_DIR}/omp-package.json"
if [ -f "$PACKAGE_JSON" ] && command -v jq &> /dev/null; then
    jq --arg name "bat" 'del(.[$name])' "$PACKAGE_JSON" > "${PACKAGE_JSON}.tmp" && \
    mv "${PACKAGE_JSON}.tmp" "$PACKAGE_JSON"
    success "Package information removed from omp-package.json"
else
    warn "Could not update omp-package.json - file not found or jq not installed"
fi

# Show uninstallation footer
echo ""
info "****************************************************************"
info "                 $NAME Uninstallation Complete"
info "****************************************************************"
echo ""

# Provide informational message
info "The 'bat' command may no longer be available in your terminal."
info "You may need to restart your terminal for the changes to take effect."

exit 0 