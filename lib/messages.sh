#!/bin/bash

# Constants
readonly LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the colors
source "${LIB_DIR}/colors.sh"

# Message functions
error() {
    echo -e "${Red}[ERROR]${Color_Off} $1" >&2
}

warn() {
    echo -e "${Yellow}[WARN]${Color_Off} $1" >&2
}

success() {
    echo -e "${Green}[SUCCESS]${Color_Off} $1" >&2
}

info() {
    echo -e "${Blue}[INFO]${Color_Off} $1" >&2
}

url() {
    echo -e "${Cyan}$1${Color_Off}"
}

# Example usage:
# error "This is an error message"
# warn "This is a warning message"
# success "This is a success message"
# info "This is an info message"
# url "https://example.com" 