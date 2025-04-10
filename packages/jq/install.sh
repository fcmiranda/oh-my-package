#!/bin/bash

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly OMP_DIR="$(dirname "${PACKAGES_DIR}")"
readonly JQ_URL="https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64"
readonly JQ_VERSION="1.7.1"
readonly LOCAL_DIR="${SCRIPT_DIR}/.local"
readonly LOCAL_BIN_DIR="${LOCAL_DIR}/bin"

# Source the message functions
source "${OMP_DIR}/lib/messages.sh"

# Package information
readonly NAME="jq"

# Show installation header
info "****************************************************************"
info "                      Installing $NAME v$JQ_VERSION"
info "****************************************************************"
echo ""

# Check if jq is already installed
if command -v jq &> /dev/null; then
    info "jq is already installed"
    exit 0
fi

# Create directory structure
info "Creating directory structure..."
for dir in "$LOCAL_DIR" "$LOCAL_BIN_DIR"; do
    if [ -d "$dir" ]; then
        info "Cleaning existing directory: $dir"
        rm -rf "$dir" || {
            error "Failed to clean directory: $dir"
            exit 1
        }
    fi
    info "Creating directory: $dir"
    mkdir -p "$dir" || {
        error "Failed to create directory: $dir"
        exit 1
    }
done

# Download jq binary
info "Downloading jq binary..."
bash "${OMP_DIR}/bin/download.sh" "$JQ_URL"

# Move downloaded binary to the correct location
info "Moving binary to local bin..."
mv "$HOME/Downloads/omp-temp/jq-linux-amd64" "$LOCAL_BIN_DIR/jq" || {
    error "Failed to move jq binary"
    exit 1
}

# Make binary executable
info "Making binary executable..."
chmod +x "$LOCAL_BIN_DIR/jq" || {
    error "Failed to make jq executable"
    exit 1
}

# Create symlinks
info "Creating symlinks..."
if [ -f "${OMP_DIR}/lib/link.sh" ]; then
    bash "${OMP_DIR}/lib/link.sh" "${SCRIPT_DIR}" || {
        error "Failed to create symlinks"
        exit 1
    }
else
    error "link.sh not found at ${OMP_DIR}/lib/link.sh"
    exit 1
fi

# Verify installation
if ! command -v jq &> /dev/null; then
    error "Failed to install jq"
    exit 1
fi

# Add version to omp-package.json
info "Adding jq version to omp-package.json..."
bash "${OMP_DIR}/bin/package.sh" "jq@${JQ_VERSION}" || {
    error "Failed to add jq version to omp-package.json"
    exit 1
}

# Show installation footer
echo ""
info "****************************************************************"
info "                  $NAME Installation Complete"
info "****************************************************************"
echo ""

echo ""