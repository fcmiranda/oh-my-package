#!/bin/bash

# Constants
OMP_DIR="$(dirname "${BASH_SOURCE[0]}")"
readonly DOWNLOAD_DIR="$HOME/Downloads"
readonly EXTRACT_DIR="$DOWNLOAD_DIR/extracted"  
readonly TIMEOUT=300  # 5 minutes timeout
readonly STABLE_CHECKS=3  # Number of checks to confirm file is stable
readonly SLEEP_INTERVAL=1  # Seconds between checks

# Error codes
readonly ERR_NO_URL=1
readonly ERR_TIMEOUT=2
readonly ERR_EXTRACTION=3
readonly ERR_UNSUPPORTED_FORMAT=4

# Source the message functions
source "${OMP_DIR}/messages.sh"

# Function to display usage information
show_usage() {
    info "Usage: $0 <URL>"
    info "Downloads and extracts files from the given URL"
    exit $ERR_NO_URL
}

# Function to display error message and exit
die() {
    local message="$1"
    local code="${2:-1}"
    error "$message"
    exit "$code"
}

# Function to ensure directory exists
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || die "Failed to create directory: $dir"
    fi
}

# Function to get filename from URL
get_filename_from_url() {
    local url="$1"
    echo "${url##*/}"
}

# Function to get file size
get_file_size() {
    local file="$1"
    if [ -f "$file" ]; then
        stat -c %s "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Function to check if file exists and is complete
is_file_complete() {
    local file="$1"
    local current_size="$2"
    local last_size="$3"
    local stable_count="$4"
    
    if [ "$current_size" -eq "$last_size" ] && [ "$current_size" -gt 0 ]; then
        if [ "$stable_count" -ge "$STABLE_CHECKS" ]; then
            return 0
        fi
    fi
    return 1
}

# Function to wait for download
wait_for_download() {
    local url="$1"
    local filename=$(get_filename_from_url "$url")
    local file_path="$DOWNLOAD_DIR/$filename"
    local start_time=$(date +%s)
    local last_size="0"
    local stable_count=0
    
    info "Waiting for $filename to be fully downloaded..."
    
    while true; do
        if [ -f "$file_path" ]; then
            local current_size=$(get_file_size "$file_path")
            
            if is_file_complete "$file_path" "$current_size" "$last_size" "$stable_count"; then
                success "Download complete: $filename"
                echo "$file_path"
                return 0
            fi
            
            if [ "$current_size" -eq "$last_size" ]; then
                stable_count=$((stable_count + 1))
            else
                stable_count=0
            fi
            
            last_size="$current_size"
        fi
        
        if [ $(($(date +%s) - start_time)) -gt $TIMEOUT ]; then
            die "Download timeout reached" $ERR_TIMEOUT
        fi
        
        sleep $SLEEP_INTERVAL
    done
}

# Function to extract file
extract_file() {
    local file="$1"
    local filename=$(basename "$file")
    local base_name="${filename%%.*}"  # Remove all extensions
    local extract_path="$EXTRACT_DIR/$base_name"
    
    ensure_dir "$extract_path"
    
    info "Extracting $filename to $extract_path..."
    
    # Wait a moment to ensure the file is fully written
    sleep $SLEEP_INTERVAL
    
    case "$file" in
        *.zip)
            unzip -q "$file" -d "$extract_path" || die "Failed to extract zip file" $ERR_EXTRACTION
            ;;
        *.tar.gz)
            tar -xzf "$file" -C "$extract_path" || die "Failed to extract tar.gz file" $ERR_EXTRACTION
            ;;
        *)
            die "Unsupported file format: $filename" $ERR_UNSUPPORTED_FORMAT
            ;;
    esac
    
    # Delete the original file after successful extraction
    rm "$file" || die "Failed to delete original file: $file"
    
    success "Extraction complete. Files are in: $extract_path"
    warn "Original file has been deleted."
}

# Function to ask user about existing file
ask_about_existing_file() {
    local file="$1"
    local filename=$(basename "$file")
    local mod_time=$(date -d "@$(stat -c %Y "$file")" "+%Y-%m-%d %H:%M:%S")
    
    warn "Found existing file: $filename"
    warn "Last modified: $mod_time"
    read -p "$(info "Do you want to use this file? (y/n) ")" choice
    
    case "$choice" in 
        y|Y ) return 0 ;;
        n|N ) return 1 ;;
        * ) error "Invalid choice. Please answer y or n."; return 1 ;;
    esac
}

# Main script execution
main() {
    # Check if URL is provided
    if [ $# -eq 0 ]; then
        show_usage
    fi

    local url="$1"
    
    ensure_dir "$DOWNLOAD_DIR"
    ensure_dir "$EXTRACT_DIR"
    
    info "Please click on the following link to download the file:"
    url "$url"
    echo ""
    
    # Check for existing files first
    local filename=$(get_filename_from_url "$url")
    local existing_file="$DOWNLOAD_DIR/$filename"
    
    if [ -f "$existing_file" ]; then
        if ask_about_existing_file "$existing_file"; then
            extract_file "$existing_file"
            exit 0
        fi
    fi
    
    local downloaded_file
    downloaded_file=$(wait_for_download "$url")
    
    if [ $? -eq 0 ] && [ -n "$downloaded_file" ]; then
        extract_file "$downloaded_file"
    else
        die "Download failed or file not found"
    fi
}

# Run the main function
main "$@"
