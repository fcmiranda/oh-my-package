#!/bin/bash

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_DIR="$(cd "$(dirname "${SCRIPT_DIR}")" && pwd)"
readonly OMP_DIR="$(dirname "${PACKAGES_DIR}")"
readonly STOW_URL="http://ftp.gnu.org/gnu/stow/stow-latest.tar.gz"
readonly STOW_VERSION="2.4.1"
readonly INSTALL_DIR="$SCRIPT_DIR/.local"
readonly EXTRACTED_DIR="$HOME/Downloads/omp-temp/stow-latest/stow-${STOW_VERSION}"

# Package information
readonly NAME="stow"
readonly DESCRIPTION="Symlink farm manager"

# Source the message functions
source "${OMP_DIR}/lib/messages.sh"

# Show installation header
info "****************************************************************"
info "                      Installing $NAME v$STOW_VERSION"
info "****************************************************************"
echo ""

# Check if stow is already installed
if command -v stow &> /dev/null; then
    info "stow is already installed"
    exit 0
fi

warn "Installing from source..."

# Create installation directory
info "Creating installation directory..."
mkdir -p "$INSTALL_DIR/bin"

# Download and extract stow
info "Downloading stow source..."
bash "${OMP_DIR}/bin/download.sh" "$STOW_URL"

# Build and install stow
info "Building and installing stow..."
if [ ! -d "$EXTRACTED_DIR" ]; then
    error "Could not find extracted stow directory at $EXTRACTED_DIR"
    exit 1
fi

cd "$EXTRACTED_DIR" || {
    error "Failed to change to stow directory"
    exit 1
}

info "Running configure..."
./configure --prefix="$INSTALL_DIR" || {
    error "Configure failed. Check dependencies."
    exit 1
}

info "Running make..."
make || {
    error "Make failed."
    exit 1
}

info "Running make install..."
make install || {
    error "Make install failed."
    exit 1
}

# Make files executable
info "Setting file permissions..."
chmod +x "$INSTALL_DIR/bin/stow"
chmod +x "$INSTALL_DIR/bin/chkstow"

# Link stow
info "Creating symlinks..."
if [ -f "${OMP_DIR}/lib/link.sh" ]; then
    bash "${OMP_DIR}/lib/link.sh" "${SCRIPT_DIR}" || {
        error "Failed to create symlinks"
        exit 1
    }
else
    error "link.sh not found at ${OMP_DIR}/link.sh"
    exit 1
fi

# Verify installation
if ! command -v stow &> /dev/null; then
    error "Failed to install stow"
    exit 1
fi

# Add version to omp-package.json
info "Adding stow version to omp-package.json..."
bash "${OMP_DIR}/bin/package.sh" "stow@${STOW_VERSION}"

# Clean up extracted files
info "Cleaning up extracted files..."
if [ -d "$EXTRACTED_DIR" ]; then
    rm -rf "$EXTRACTED_DIR" || {
        warn "Failed to remove extracted files at $EXTRACTED_DIR"
    }
fi

# Show installation footer
echo ""
info "****************************************************************"
info "                  $NAME Installation Complete"
info "****************************************************************"
echo ""
