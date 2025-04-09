#!/bin/bash

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_DIR="$(cd "$(dirname "${SCRIPT_DIR}")" && pwd)"
readonly OMP_DIR="$(dirname "${PACKAGES_DIR}")"

# Package information
readonly NAME="OMZ"
readonly VERSION="latest"

# Source the message functions
source "${OMP_DIR}/lib/messages.sh"

# Show installation header
info "****************************************************************"
info "                      Installing $NAME v$VERSION"
info "****************************************************************"
echo ""

# Ensure necessary commands are available
if command -v omz &> /dev/null; then
    warn "omz is already installed"
    warn "If you want to install locally anyway, uninstall the global version first."
    exit 1
fi

info "Installing omz..."

# Constants
readonly OMZ_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
readonly DOWNLOAD_DIR="$HOME/Downloads"
readonly OMZ_INSTALL_SCRIPT="$HOME/omz-install.sh"
readonly ZSH_DIR="$SCRIPT_DIR/.oh-my-zsh"

# Create download directory
info "Creating download directory..."
mkdir -p "$DOWNLOAD_DIR"

# Check if mktemp command failed
if [ -z "$OMZ_INSTALL_SCRIPT" ]; then
    error "Could not create temporary file."
    exit 1
fi

# Download the installation script
info "Downloading Oh My Zsh installation script..."
if ! curl -sSL "$OMZ_INSTALL_URL" -o "$OMZ_INSTALL_SCRIPT"; then
    error "Failed to download the Oh My Zsh installation script."
    rm -f "$OMZ_INSTALL_SCRIPT"  # Clean up the temporary file
    exit 1
fi

# Make the downloaded script executable
info "Making the script executable..."
chmod +x "$OMZ_INSTALL_SCRIPT"

# Run the installation script
info "Running the Oh My Zsh installation script..."
info "--------------------------------------------------"
# Run OMZ install script with custom ZSH directory
ZSH="$ZSH_DIR" "$OMZ_INSTALL_SCRIPT" --unattended || die "OMZ installation failed"

# Clean up the temporary file
rm -f "$OMZ_INSTALL_SCRIPT"

info "--------------------------------------------------"
success "Oh my Zsh installation complete."

# Clean up the .zshrc file
info "Handling existing .zshrc file..."
if [ -f "$HOME/.zshrc" ]; then

    # Generate timestamp
    readonly TIMESTAMP=$(date '+%Y-%m-%d-%H-%M-%S')
    readonly BACKUP_FILE="$SCRIPT_DIR/.zshrc.pre-omp-${TIMESTAMP}"

    # Backup existing .zshrc
    info "Backing up existing .zshrc to ${BACKUP_FILE}"
    mv "$HOME/.zshrc" "$BACKUP_FILE" || {
        error "Failed to backup existing .zshrc"
        exit 1
    }
    success "Existing .zshrc backed up successfully"
else
    info "No existing .zshrc found"
fi


# Create symlinks using stow
info "Creating symlinks with stow..."
if ! stow -d "$PACKAGES_DIR" omz -t "$HOME"; then
    error "Failed to create symlinks with stow."
    exit 1
fi

# Set ZSH environment variable
info "Setting ZSH environment variable..."
export ZSH="$HOME/.oh-my-zsh"
zsh

# Show installation footer
echo ""
info "****************************************************************"
info "                  $NAME Installation Complete"
info "****************************************************************"
echo ""

info "Installation complete. Please restart your terminal or run:"
zsh