#!/bin/bash

# Script to save package name and version information in omp-package.json

# Initialize empty JSON object if file doesn't exist
if [ ! -f omp-package.json ]; then
    echo "{}" > omp-package.json
fi

# Function to add a package to the JSON
add_package() {
    local package_name="$1"
    local version="$2"
    
    # Check if jq is available
    if command -v jq &> /dev/null; then
        # Use jq to add or update the package in the JSON file
        jq --arg name "$package_name" --arg ver "$version" '.[$name] = $ver' omp-package.json > temp.json
        mv temp.json omp-package.json
    else
        echo "Error: jq is required but not installed."
        echo "Please run the install script first: ./install.sh"
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
        echo "Added $package_name version $version to omp-package.json"
        exit 0
    else
        echo "Invalid format. Please use the format: package@version"
        echo "Example: ./package.sh stow@2.4.7"
        exit 1
    fi
fi

echo "Package information saved to omp-package.json"
