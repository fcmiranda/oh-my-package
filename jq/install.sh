#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMP_DIR="$(dirname "${SCRIPT_DIR}")"

# Source the message functions
source "${OMP_DIR}/messages.sh"

# Package information
readonly NAME="jq"
readonly VERSION="1.7"

# Show installation header
info "****************************************************************"
info "                      Installing $NAME v$VERSION"
info "****************************************************************"
echo ""

# Check if jq is already installed
if command -v jq &> /dev/null; then
    info "jq is already installed"
    exit 0
fi

info "Linking jq..."
sh "$OMP_DIR/link.sh" "$OMP_DIR/jq"

# Show installation footer
echo ""
info "****************************************************************"
info "                  $NAME Installation Complete"
info "****************************************************************"
echo ""

success "jq installed successfully"
echo ""