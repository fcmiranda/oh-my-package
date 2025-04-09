#!/bin/bash

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OMP_DIR="$(dirname "${SCRIPT_DIR}")"
readonly PACKAGE_JSON="$OMP_DIR/omp-package.json"

# Source the message functions
source "${OMP_DIR}/lib/messages.sh"

# Initialize empty JSON object if file doesn't exist
if [ ! -f "$PACKAGE_JSON" ]; then
    info "Creating new omp-package.json file..."
    echo "{}" > "$PACKAGE_JSON"
fi

# Function to add a package to the JSON
add_package() {
    local package_name="$1"
    local version="$2"
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        error "jq is required but not installed"
        error "Please run the install script first: ./install.sh"
        exit 1
    fi

    # Use jq to add or update the package in the JSON file
    if jq --arg name "$package_name" --arg ver "$version" '.[$name] = $ver' "$PACKAGE_JSON" > "${PACKAGE_JSON}.tmp"; then
        mv "${PACKAGE_JSON}.tmp" "$PACKAGE_JSON"
        success "Added $package_name version $version to omp-package.json"
    else
        error "Failed to update omp-package.json"
        exit 1
    fi
}

# Process command line parameter if provided
if [ $# -eq 1 ]; then
    # Check if parameter follows the pattern package@version
    if [[ "$1" == *@* ]]; then
        # Extract package name and version
        package_name=$(echo "$1" | cut -d '@' -f 1)
        version=$(echo "$1" | cut -d '@' -f 2)
        
        # Add the package to the JSON
        add_package "$package_name" "$version"
        exit 0
    else
        error "Invalid format. Please use the format: package@version"
        info "Example: ./package.sh stow@2.4.7"
        exit 1
    fi
fi

info "No package information provided"
info "Usage: ./package.sh package@version"
info "Example: ./package.sh stow@2.4.7"
exit 0
