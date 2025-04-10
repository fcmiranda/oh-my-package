#!/bin/bash

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_DIR="$(cd "$(dirname "${SCRIPT_DIR}")" && pwd)"
readonly OMP_DIR="$(dirname "${PACKAGES_DIR}")"
readonly LOCAL_DIR="${SCRIPT_DIR}/.local"
readonly BIN_DIR="${LOCAL_DIR}/bin"

# Package information
readonly NAME="bat"
readonly VERSION="latest"
readonly REPO="sharkdp/bat"
readonly ASSET_PATTERN="x86_64-unknown-linux-musl.tar.gz" # Adjust if your architecture differs
readonly DOWNLOAD_DIR="${SCRIPT_DIR}/downloads"
readonly DESCRIPTION="A cat clone with syntax highlighting and Git integration"

# Source the message functions
source "${OMP_DIR}/lib/messages.sh"

# Show installation header
info "****************************************************************"
info "                      Installing $NAME v$VERSION"
info "****************************************************************"
echo ""

# Ensure necessary commands are available
if command -v bat &> /dev/null; then
    warn "bat is already installed"
    warn "If you want to install locally anyway, uninstall the global version first."
    exit 1
fi

if ! command -v curl &> /dev/null; then
    error "curl is not installed. Please install it."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    error "jq is not installed. Please install it."
    exit 1
fi

if ! command -v tar &> /dev/null; then
    error "tar is not installed. Please install it."
    exit 1
fi

# Create directories
info "Creating directory structure..."
mkdir -p "${BIN_DIR}"
mkdir -p "${DOWNLOAD_DIR}"

# Download and install bat
info "Downloading and installing bat..."

# Get latest release information
info "Fetching latest release information from GitHub..."
RESPONSE=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest")

if [[ $? -ne 0 ]]; then
    error "Failed to fetch release information from GitHub."
    exit 1
fi

# Extract the download URL for the specified asset
ASSET_URL=$(echo "${RESPONSE}" | jq -r --arg PATTERN "${ASSET_PATTERN}" '.assets[] | select(.name | endswith($PATTERN)) | .browser_download_url')

if [[ -z "${ASSET_URL}" ]]; then
    error "Could not find asset matching pattern '${ASSET_PATTERN}'."
    error "Please check available assets at https://github.com/${REPO}/releases"
    exit 1
fi

DOWNLOAD_FILE="${DOWNLOAD_DIR}/$(basename "${ASSET_URL}")"

# Download the asset
info "Downloading bat from: ${ASSET_URL}"
if ! curl -L -o "${DOWNLOAD_FILE}" "${ASSET_URL}"; then
    error "Failed to download bat."
    exit 1
fi

# Extract the bat binary from the archive
info "Extracting bat binary to ${BIN_DIR}..."
if ! tar -xzf "${DOWNLOAD_FILE}" -C "${BIN_DIR}" --strip-components=1 --wildcards '*/bat'; then
    error "Failed to extract bat binary."
    rm "${DOWNLOAD_FILE}" # Clean up downloaded file
    exit 1
fi

# Ensure the binary is executable
chmod +x "${BIN_DIR}/bat"
success "bat binary extracted and made executable."

# Clean up downloaded file
rm "${DOWNLOAD_FILE}"
info "Cleaned up downloaded archive."

# Create symlinks using stow
info "Creating symlinks with stow..."
if ! stow -d "${PACKAGES_DIR}" bat -t "${HOME}"; then
    error "Failed to create symlinks with stow."
    exit 1
fi

success "Symlinks created successfully."

# Show installation footer
echo ""
info "****************************************************************"
info "                  $NAME Installation Complete"
info "****************************************************************"
echo ""

success "bat has been installed successfully."
info "You can now use 'bat' in your terminal."