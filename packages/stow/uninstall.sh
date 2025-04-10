#!/bin/bash

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly OMP_DIR="$(dirname "${PACKAGES_DIR}")"
readonly LOCAL_DIR="${SCRIPT_DIR}/.local"
readonly STOW_VERSION="2.4.1"
readonly EXTRACTED_DIR="$HOME/Downloads/omp-temp/stow-latest/stow-${STOW_VERSION}"

# Source the message functions
source "${OMP_DIR}/lib/messages.sh"

# Package information
readonly NAME="stow"

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

# Remove symbolic links
info "Removing $NAME symbolic links..."
if [ -f "${OMP_DIR}/lib/link.sh" ]; then
    bash "${OMP_DIR}/lib/link.sh" -r "$SCRIPT_DIR" || {
        error "Failed to remove $NAME symbolic links"
        exit 1
    }
else
    error "link.sh not found at ${OMP_DIR}/lib/link.sh"
    exit 1
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

# Remove extracted stow files
info "Removing extracted stow files..."
if [ -d "$EXTRACTED_DIR" ]; then
    rm -rf "$EXTRACTED_DIR" || {
        error "Failed to remove extracted stow files"
        exit 1
    }
else
    info "No extracted stow files found"
fi

# Show uninstallation footer
echo ""
info "****************************************************************"
info "                 $NAME Uninstallation Complete"
info "****************************************************************"
echo ""

exit 0 