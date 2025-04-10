#!/bin/bash

# Constants
readonly OMP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the message functions
source "${OMP_DIR}/lib/messages.sh"

# Make omp script executable
chmod +x "${OMP_DIR}/omp"

# Create symbolic link to make omp globally available
if [ -d "$HOME/bin" ]; then
    # Use ~/bin if it exists (and is likely in PATH)
    ln -sf "${OMP_DIR}/omp" "$HOME/bin/omp"
    success "Linked omp to $HOME/bin/omp"
elif [ -d "$HOME/.local/bin" ] && [ -w "$HOME/.local/bin" ]; then
    # Use $HOME/.local/bin if it's writable
    ln -sf "${OMP_DIR}/omp" "$HOME/.local/bin/omp"
    success "Linked omp to $HOME/.local/bin/omp"
else
    # Ask user for sudo to install to $HOME/.local/bin
    warn "Neither ~/bin exists nor $HOME/.local/bin is writable."
    info "Attempting to create symlink with sudo..."
    if sudo ln -sf "${OMP_DIR}/omp" "$HOME/.local/bin/omp"; then
        success "Linked omp to $HOME/.local/bin/omp (with sudo)"
    else
        warn "Could not create global symlink. To use omp globally, either:"
        info "  1. Create a symlink manually: ln -s \"${OMP_DIR}/omp\" $HOME/.local/bin/omp"
        info "  2. Add this directory to your PATH in ~/.bashrc or ~/.zshrc:"
        info "     export PATH=\"\$PATH:${OMP_DIR}\""
    fi
fi

info "Oh My Package it was installed..."

echo ""