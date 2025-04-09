#!/bin/bash

# Constants
readonly OMP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_DIR="${OMP_DIR}/packages"
readonly OMP_HOME="$HOME/oh-my-package"
readonly STOW_VERSION="2.4.1"
readonly EXTRACTED_DIR="$HOME/Downloads/extracted/stow-latest/stow-${STOW_VERSION}"
readonly PACKAGE_JSON="$OMP_HOME/omp-package.json"

# Source the message functions
source "${OMP_DIR}/lib/messages.sh"

# --- Functions ---

# Remove symbolic links using stow
remove_stow_links() {
    local package="$1"
    info "Removing $package symbolic links..."
    
    if [ -d "$PACKAGES_DIR/$package" ]; then
        info "Removing "$PACKAGES_DIR/$package" symbolic links..."
        if ! stow -d "$PACKAGES_DIR" -t "$HOME" -D "$package"; then
            error "Failed to remove $package symbolic links"
            return 1
        fi
        cd - > /dev/null
    else
        info "Package $package not found in $PACKAGES_DIR"
    fi
    return 0
}

# Remove symbolic links using link.sh
remove_link_links() {
    local package="$1"
    info "Removing $package symbolic links..."
    if [ -d "$PACKAGES_DIR/$package" ]; then
        if ! bash "${OMP_DIR}/lib/link.sh" -r "$PACKAGES_DIR/$package"; then
            error "Failed to remove $package symbolic links"
            return 1
        fi
    else
        info "Package $package not found in $PACKAGES_DIR"
    fi
    return 0
}

# Remove local folder
remove_local_folder() {
    local package="$1"
    local folder="$PACKAGES_DIR/$package/.local"
    
    if [ "$KEEP_LOCAL" = true ]; then
        info "Keeping $package local folder (--keep option used)"
        return 0
    fi
    
    info "Removing $package local folder..."
    if [ -d "$folder" ]; then
        rm -rf "$folder" || {
            error "Failed to remove $package local folder"
            return 1
        }
    fi
    return 0
}

# Remove OMZ specific folders
remove_omz_folders() {
    local omz_dir="$PACKAGES_DIR/omz"
    
    # Remove .local folder
    if ! remove_local_folder "omz"; then
        return 1
    fi
    
    # Remove .oh-my-zsh folder
    if [ "$KEEP_LOCAL" = true ]; then
        info "Keeping OMZ .oh-my-zsh folder (--keep option used)"
        return 0
    fi
    
    info "Removing OMZ .oh-my-zsh folder..."
    if [ -d "$omz_dir/.oh-my-zsh" ]; then
        rm -rf "$omz_dir/.oh-my-zsh" || {
            error "Failed to remove OMZ .oh-my-zsh folder"
            return 1
        }
    fi
    
    return 0
}

# Remove extracted stow files
remove_extracted_stow() {
    info "Removing extracted stow files..."
    if [ -d "$EXTRACTED_DIR" ]; then
        rm -rf "$EXTRACTED_DIR" || {
            error "Failed to remove extracted stow files"
            return 1
        }
    fi
    return 0
}

# Remove package.json file
remove_package_json() {
    info "Removing omp-package.json..."
    if [ -f "$PACKAGE_JSON" ]; then
        rm -f "$PACKAGE_JSON" || {
            error "Failed to remove omp-package.json"
            return 1
        }
    fi
    return 0
}

# Show usage information
show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -k, --keep    Keep .local and .oh-my-zsh folders"
    echo "  -h, --help    Show this help message"
    exit 0
}

# --- Main Logic ---

# Parse command line arguments
KEEP_LOCAL=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -k|--keep)
            KEEP_LOCAL=true
            shift
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            error "Unknown option: $1"
            show_usage
            ;;
    esac
done

info "Starting uninstallation process..."
if [ "$KEEP_LOCAL" = true ]; then
    info "Keeping local folders (--keep option used)"
fi
echo ""

# Remove OMZ
# if ! remove_stow_links "omz"; then
#     exit 1
# fi
# if ! remove_omz_folders; then
#     exit 1
# fi

# Remove stow
if ! remove_link_links "stow"; then
    exit 1
fi
if ! remove_local_folder "stow"; then
    exit 1
fi
if ! remove_extracted_stow; then
    exit 1
fi

# Remove jq
if ! remove_link_links "jq"; then
    exit 1
fi
if ! remove_local_folder "jq"; then
    exit 1
fi

# Remove package.json
if ! remove_package_json; then
    exit 1
fi

success "Uninstallation completed successfully!"
echo ""
