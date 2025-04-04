#!/bin/bash
# Script: stow_local.sh
# Description: Creates or removes symbolic links to files in child folders to ~/
# Usage: stow_local.sh [-r] [source_dir]
#   -r: Remove symbolic links instead of creating them.
#   -d: Enable debug mode for verbose output.
#   source_dir: The directory containing the child folders with files to link.
#                If omitted, defaults to the current directory.

# --- Configuration ---

TARGET_DIR="$HOME"
IGNORE_FILE=".linkignore"
DEBUG=0  # Set to 1 to enable debug output

# --- Argument Parsing ---

REMOVE_MODE=0
SOURCE_DIR="$PWD" # Default to current directory

while getopts "rd" opt; do
  case "$opt" in
    r)
      REMOVE_MODE=1
      ;;
    d)
      DEBUG=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

if [ $# -gt 1 ]; then
  echo "Error: Too many arguments.  Only one source directory allowed."
  exit 1
fi

if [ $# -eq 1 ]; then
  if [ -d "$1" ]; then
    # Convert to absolute path to avoid issues with relative paths
    SOURCE_DIR=$(cd "$1" && pwd)
  else
    echo "Error: Directory \"$1\" does not exist."
    exit 1
  fi
fi

echo "Using source directory: $SOURCE_DIR"

# --- Functions ---

debug_log() {
  if [ "$DEBUG" -eq 1 ]; then
    echo "DEBUG: $1" >&2
  fi
}

should_ignore() {
  local file_path="$1"
  local rel_path=$(echo "$file_path" | sed "s|^$SOURCE_DIR/||")
  
  # Special case for .gitignore - hardcoded check
  if [[ "$rel_path" == ".gitignore" ]]; then
    echo "Ignoring file: $rel_path (special case for .gitignore)"
    return 0
  fi
  
  # Check for ignore file in SOURCE_DIR
  local ignore_file="$SOURCE_DIR/$IGNORE_FILE"
  if [ ! -f "$ignore_file" ]; then
    debug_log "No ignore file found at $ignore_file"
    return 1
  fi
  
  debug_log "Checking if '$rel_path' matches any pattern in $ignore_file"
  
  # Get just the filename without directory
  local basename=$(basename "$rel_path")
  debug_log "Basename: $basename"
  
  # First check direct match with common files without reading the ignore file
  # This is a failsafe in case there are issues with the file reading
  for special_file in ".gitignore" "*.sh" ".linkignore"; do
    if [[ "$basename" == "$special_file" || "$rel_path" == "$special_file" || 
          ("$special_file" == "*.sh" && "$basename" == *.sh) ]]; then
      echo "Ignoring file: $rel_path (hardcoded special case: $special_file)"
      return 0
    fi
  done
  
  # Check if file matches any pattern in the ignore file
  while IFS= read -r pattern || [ -n "$pattern" ]; do
    # Skip empty lines and comments
    [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
    
    # Trim leading/trailing whitespace
    pattern=$(echo "$pattern" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    
    debug_log "Testing pattern: '$pattern' against '$rel_path' (basename: '$basename')"
    
    # DIRECT FILENAME MATCH - highest priority
    if [[ "$basename" == "$pattern" || "$rel_path" == "$pattern" ]]; then
      echo "Ignoring file: $rel_path (exact filename match: $pattern)"
      return 0
    fi
    
    # Path-based matches
    if [[ "$rel_path" == "$pattern"* || "$rel_path" == *"/$pattern" ]]; then
      echo "Ignoring file: $rel_path (path match: $pattern)"
      return 0
    fi
    
    # Handle glob patterns
    if [[ "$pattern" == *"*"* || "$pattern" == *"?"* ]]; then
      # Simple glob test using bash's native pattern matching
      if [[ "$basename" == $pattern || "$rel_path" == $pattern ]]; then
        echo "Ignoring file: $rel_path (glob match: $pattern)"
        return 0
      fi
    fi
  done < "$ignore_file"
  
  debug_log "File '$rel_path' does not match any ignore patterns"
  return 1  # Don't ignore
}

create_link() {
  local target_link="$1"
  local source_file="$2"
  echo "Creating symbolic link: $target_link -> $source_file"
  ln -s "$source_file" "$target_link"
}

remove_link() {
  local target_link="$1"
  echo "Removing symbolic link: $target_link"
  rm "$target_link"
}

# --- Main Logic ---

if [ "$REMOVE_MODE" -eq 1 ]; then
  echo "Removing symbolic links from $TARGET_DIR to files under $SOURCE_DIR."
else
  echo "Creating symbolic links from $TARGET_DIR to files under $SOURCE_DIR."
fi

# First, check if the linkignore file exists and has the right permissions
if [ -f "$SOURCE_DIR/$IGNORE_FILE" ]; then
  echo "Found ignore file: $SOURCE_DIR/$IGNORE_FILE"
  if [ "$DEBUG" -eq 1 ]; then
    echo "Contents:"
    cat "$SOURCE_DIR/$IGNORE_FILE" | sed 's/^/  /'
  fi
else
  echo "No ignore file found at $SOURCE_DIR/$IGNORE_FILE"
fi

find "$SOURCE_DIR" -type f -print0 | while IFS= read -r -d $'\0' source_file; do
  # Get relative path from SOURCE_DIR to the file
  rel_path=$(echo "$source_file" | sed "s|^$SOURCE_DIR/||") # remove leading SOURCE_DIR/
  
  debug_log "Processing file: $rel_path (full path: $source_file)"
  
  # Skip the ignore file itself
  if [[ "$rel_path" == "$IGNORE_FILE" ]]; then
    debug_log "Skipping the ignore file itself: $rel_path"
    continue
  fi
  
  # Check if file should be ignored based on patterns
  if should_ignore "$source_file"; then
    continue
  fi
  
  target_link="$TARGET_DIR/$rel_path"

  if [ "$REMOVE_MODE" -eq 1 ]; then
    if [ -L "$target_link" ]; then
      remove_link "$target_link"
      if [ $? -ne 0 ]; then
        echo "Error removing link: $target_link"
        exit 1
      fi
    else
      echo "Skipping missing link: $target_link"
    fi

  else
    # Create parent directory if it doesn't exist
    target_dir=$(dirname "$target_link")

    if [ ! -d "$target_dir" ]; then
      echo "Creating directory: $target_dir"
      mkdir -p "$target_dir"
      if [ $? -ne 0 ]; then
        echo "Error creating directory: $target_dir"
        exit 1
      fi
    fi

    if [ ! -e "$target_link" ]; then
      create_link "$target_link" "$source_file"
      if [ $? -ne 0 ]; then
        echo "Error creating link from $source_file to $target_link"
        exit 1
      fi
    else
      echo "Skipping existing file: $target_link" # Could be a file, a directory, or a link. We skip it
    fi
  fi
done

echo
echo "Done."

exit 0