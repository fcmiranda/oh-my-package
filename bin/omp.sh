#!/bin/bash

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OMP_DIR="$(dirname "${SCRIPT_DIR}")"
readonly PACKAGES_DIR="${OMP_DIR}/packages"
readonly PACKAGE_JSON="${OMP_DIR}/omp-package.json"

toilet -d "$OMP_DIR/_/figlet" -f smblock "Oh My Pkg" -F border:metal 

# Source the message functions
source "${OMP_DIR}/lib/messages.sh"

# Show usage information
show_usage() {
    echo "Usage: omp <command> [options]"
    echo ""
    echo "Commands:"
    echo "  install, i [packages...]  Install one or more packages"
    echo "  uninstall <package|all>   Uninstall a specific package or all packages"
    echo "  rm <package|all>          Alias for uninstall"
    echo "  list                     List installed packages"
    echo "  available                List all available packages"
    echo "  help                     Show this help message"
    echo ""
    echo "Options:"
    echo "  -k, --keep               Keep local files when uninstalling"
    echo "  -y, --yes                Automatically answer yes to all prompts"
    echo "  -i, --interactive        Enable interactive mode for installation"
    echo "  -h, --help               Show help for a specific command"
    echo ""
    echo "Examples:"
    echo "  omp i                    Install all packages without prompting"
    echo "  omp i -i                 Interactive installation of packages"
    echo "  omp install jq stow      Install specific packages"
    echo "  omp uninstall stow       Uninstall stow"
    echo "  omp rm all               Uninstall all packages"
    echo "  omp available            Show all available packages"
    exit 0
}

# Function to ask for confirmation
ask_for_install() {
    local package="$1"
    local description="$2"
    local default="$3"
    local yes_flag="$4"
    local interactive_mode="$5"
    
    # If yes flag is set or not in interactive mode, assume yes
    if [ "$yes_flag" = true ] || [ "$interactive_mode" = false ]; then
        return 0
    fi
    
    local prompt="Install $package ($description)? [Y/n]: "
    if [ "$default" = "n" ]; then
        prompt="Install $package ($description)? [y/N]: "
    fi
    
    read -p "$prompt" response
    response=${response:-$default}
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0  # Yes
    else
        return 1  # No
    fi
}

# Function to install a specific package
install_package() {
    local package_name="$1"
    local yes_flag="$2"
    local interactive_mode="$3"
    
    # Check if package exists
    if [ ! -d "${PACKAGES_DIR}/${package_name}" ]; then
        error "Package '${package_name}' is not available"
        return 1
    fi
    
    # Check if install script exists
    if [ ! -f "${PACKAGES_DIR}/${package_name}/install.sh" ]; then
        error "No installation script found for ${package_name}"
        return 1
    fi
    
    # Get package description from install.sh
    local description="no description"
    if grep -q "readonly DESCRIPTION=" "${PACKAGES_DIR}/${package_name}/install.sh"; then
        description=$(grep "readonly DESCRIPTION=" "${PACKAGES_DIR}/${package_name}/install.sh" | cut -d'"' -f2)
    fi
    
    # Ask for confirmation if in interactive mode
    if [ "$interactive_mode" = true ]; then
        if ! ask_for_install "$package_name" "$description" "y" "$yes_flag" "$interactive_mode"; then
            info "Skipping $package_name installation"
            return 0
        fi
    fi
    
    # Run installation script
    info "Installing ${package_name}..."
    if bash "${PACKAGES_DIR}/${package_name}/install.sh"; then
        success "${package_name} installed successfully"
        return 0
    else
        error "Failed to install ${package_name}"
        return 1
    fi
}

# Function to uninstall a specific package
uninstall_package() {
    local package_name="$1"
    local keep_local="$2"
    
    # Check if package exists
    if [ ! -d "${PACKAGES_DIR}/${package_name}" ]; then
        error "Package '${package_name}' is not available"
        return 1
    fi
    
    # Check if uninstall script exists
    if [ ! -f "${PACKAGES_DIR}/${package_name}/uninstall.sh" ]; then
        error "No uninstall script found for ${package_name}"
        return 1
    fi
    
    # Build arguments for uninstall script
    local args=""
    if [ "$keep_local" = true ]; then
        args="-k"
    fi
    
    # Run uninstall script
    info "Uninstalling ${package_name}..."
    if bash "${PACKAGES_DIR}/${package_name}/uninstall.sh" $args; then
        success "${package_name} uninstalled successfully"
        
        # Update the package.json file if it exists and jq is available
        if [ -f "$PACKAGE_JSON" ] && command -v jq &> /dev/null; then
            jq --arg name "$package_name" 'del(.[$name])' "$PACKAGE_JSON" > "${PACKAGE_JSON}.tmp" && \
            mv "${PACKAGE_JSON}.tmp" "$PACKAGE_JSON"
        fi
        
        return 0
    else
        error "Failed to uninstall ${package_name}"
        return 1
    fi
}

# Function to uninstall all packages
uninstall_all_packages() {
    local keep_local="$1"
    local yes_flag="$2"
    
    # Get list of available packages
    local AVAILABLE_PACKAGES=()
    for pkg_dir in "${PACKAGES_DIR}"/*; do
        if [ -d "$pkg_dir" ]; then
            AVAILABLE_PACKAGES+=("$(basename "$pkg_dir")")
        fi
    done
    
    if [ ${#AVAILABLE_PACKAGES[@]} -eq 0 ]; then
        warn "No packages available to uninstall"
        return 0
    fi
    
    # Confirm with user unless yes flag is set
    if [ "$yes_flag" != true ]; then
        read -p "Are you sure you want to uninstall all packages? This cannot be undone [y/N]: " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            info "Uninstallation cancelled"
            return 0
        fi
    fi
    
    info "Uninstalling all packages..."
    
    local SUCCESS=true
    local UNINSTALLED_COUNT=0
    
    # Uninstall packages in reverse order to handle dependencies
    for ((i=${#AVAILABLE_PACKAGES[@]}-1; i>=0; i--)); do
        local package="${AVAILABLE_PACKAGES[$i]}"
        if uninstall_package "$package" "$keep_local"; then
            ((UNINSTALLED_COUNT++))
        else
            SUCCESS=false
        fi
        echo ""
    done
    
    if [ $UNINSTALLED_COUNT -eq 0 ]; then
        warn "No packages were uninstalled"
    else
        if [ "$SUCCESS" = true ]; then
            success "All packages were uninstalled successfully!"
        else
            warn "Some packages failed to uninstall"
        fi
    fi
    
    return 0
}

# Parse command-line arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

# Process commands
COMMAND="$1"
shift

case "$COMMAND" in
    install|i)
        # Process install options
        YES_FLAG=false
        INTERACTIVE_MODE=false
        PACKAGES=()
        
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -y|--yes)
                    YES_FLAG=true
                    shift
                    ;;
                -i|--interactive)
                    INTERACTIVE_MODE=true
                    shift
                    ;;
                -h|--help)
                    echo "Usage: omp install|i [packages...] [-y|--yes] [-i|--interactive]"
                    echo ""
                    echo "Options:"
                    echo "  -y, --yes          Automatically answer yes to all prompts"
                    echo "  -i, --interactive  Enable interactive mode with prompts for each package"
                    echo ""
                    echo "Examples:"
                    echo "  omp i                  Install all packages without prompting"
                    echo "  omp i -i               Interactive installation with prompts"
                    echo "  omp install jq stow    Install specific packages"
                    exit 0
                    ;;
                *)
                    PACKAGES+=("$1")
                    shift
                    ;;
            esac
        done
        
        # If no specific packages provided, install all packages
        if [ ${#PACKAGES[@]} -eq 0 ]; then
            # Get available packages from packages directory
            ALL_PACKAGES=()
            for pkg_dir in "${PACKAGES_DIR}"/*; do
                if [ -d "$pkg_dir" ] && [ -f "${pkg_dir}/install.sh" ]; then
                    ALL_PACKAGES+=("$(basename "$pkg_dir")")
                fi
            done
            
            SUCCESS=true
            INSTALLED_COUNT=0
            
            info "Installing all packages..."
            if [ "$INTERACTIVE_MODE" = true ]; then
                info "Using interactive mode - you will be prompted for each package"
            fi
            
            for package in "${ALL_PACKAGES[@]}"; do
                # Get package description from install.sh
                description="no description"
                if grep -q "readonly DESCRIPTION=" "${PACKAGES_DIR}/${package}/install.sh"; then
                    description=$(grep "readonly DESCRIPTION=" "${PACKAGES_DIR}/${package}/install.sh" | cut -d'"' -f2)
                fi
                
                if [ "$INTERACTIVE_MODE" = true ]; then
                    # In interactive mode, ask before installing
                    if ask_for_install "$package" "$description" "y" "$YES_FLAG" "$INTERACTIVE_MODE"; then
                        if install_package "$package" true "$INTERACTIVE_MODE"; then
                            ((INSTALLED_COUNT++))
                        else
                            SUCCESS=false
                        fi
                    else
                        info "Skipping $package installation"
                    fi
                else
                    # In non-interactive mode, install all packages
                    if install_package "$package" "$YES_FLAG" "$INTERACTIVE_MODE"; then
                        ((INSTALLED_COUNT++))
                    else
                        SUCCESS=false
                    fi
                fi
                echo ""
            done
            
            if [ $INSTALLED_COUNT -eq 0 ]; then
                warn "No packages were installed"
            else
                if [ "$SUCCESS" = true ]; then
                    success "All packages were installed successfully!"
                else
                    warn "Some packages failed to install"
                fi
            fi
        else
            # Install specific packages
            SUCCESS=true
            
            for package in "${PACKAGES[@]}"; do
                if ! install_package "$package" "$YES_FLAG" "$INTERACTIVE_MODE"; then
                    SUCCESS=false
                fi
                echo ""
            done
            
            if [ "$SUCCESS" = true ]; then
                success "All packages installed successfully!"
            else
                error "Some packages failed to install"
                exit 1
            fi
        fi
        ;;
    uninstall|rm)
        # Process uninstall options
        KEEP_LOCAL=false
        YES_FLAG=false
        PACKAGE_NAME=""
        
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -k|--keep)
                    KEEP_LOCAL=true
                    shift
                    ;;
                -y|--yes)
                    YES_FLAG=true
                    shift
                    ;;
                -h|--help)
                    echo "Usage: omp uninstall|rm <package|all> [-k|--keep] [-y|--yes]"
                    echo ""
                    echo "Options:"
                    echo "  -k, --keep    Keep local files when uninstalling"
                    echo "  -y, --yes     Skip confirmation prompt for uninstall all"
                    echo ""
                    echo "Examples:"
                    echo "  omp uninstall stow     Uninstall stow"
                    echo "  omp rm omz -k          Uninstall Oh My Zsh but keep local files"
                    echo "  omp rm all             Uninstall all packages"
                    echo "  omp rm all -y -k       Uninstall all packages without prompting, keeping local files"
                    exit 0
                    ;;
                *)
                    if [ -z "$PACKAGE_NAME" ]; then
                        PACKAGE_NAME="$1"
                    else
                        error "Only one package can be uninstalled at a time"
                        exit 1
                    fi
                    shift
                    ;;
            esac
        done
        
        if [ -z "$PACKAGE_NAME" ]; then
            error "No package specified for uninstallation"
            echo "Usage: omp uninstall|rm <package|all>"
            exit 1
        fi
        
        if [ "$PACKAGE_NAME" = "all" ]; then
            uninstall_all_packages "$KEEP_LOCAL" "$YES_FLAG"
        else
            uninstall_package "$PACKAGE_NAME" "$KEEP_LOCAL"
        fi
        ;;
    list)
        # List installed packages
        if [ -f "$PACKAGE_JSON" ] && command -v jq &> /dev/null; then
            info "Installed packages:"
            jq -r 'to_entries | .[] | "  \(.key) (version: \(.value))"' "$PACKAGE_JSON"
        else
            info "No packages installed or package information unavailable"
        fi
        ;;
    available)
        # List available packages
        info "Available packages:"
        
        # Get all packages in the packages directory
        FOUND_PACKAGES=0
        for pkg_dir in "${PACKAGES_DIR}"/*; do
            if [ -d "$pkg_dir" ] && [ -f "${pkg_dir}/install.sh" ]; then
                PKG_NAME=$(basename "$pkg_dir")
                
                # Get description from install.sh
                DESCRIPTION="no description"
                if grep -q "readonly DESCRIPTION=" "${pkg_dir}/install.sh"; then
                    DESCRIPTION=$(grep "readonly DESCRIPTION=" "${pkg_dir}/install.sh" | cut -d'"' -f2)
                fi
                
                echo "  ${PKG_NAME} - ${DESCRIPTION}"
                ((FOUND_PACKAGES++))
            fi
        done
        
        if [ $FOUND_PACKAGES -eq 0 ]; then
            warn "No packages available for installation"
        fi
        ;;
    help)
        show_usage
        ;;
    *)
        error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac

exit 0 