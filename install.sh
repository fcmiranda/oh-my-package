#!/bin/bash

# Constants
readonly OMP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the message functions
source "${OMP_DIR}/lib/messages.sh"

info "Starting installation process..."
echo ""

# Run jq installation
if ! bash "${OMP_DIR}/packages/jq/install.sh"; then
    error "jq installation failed"
    exit 1
fi

# Run stow installation
if ! bash "${OMP_DIR}/packages/stow/install.sh"; then
    error "stow installation failed"
    exit 1
fi

# Run omz installation
if ! bash "${OMP_DIR}/packages/omz/install.sh"; then
    error "oh-my-zsh installation failed"
    exit 1
fi

success "All installations completed successfully!"
echo ""