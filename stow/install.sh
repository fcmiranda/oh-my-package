#!/bin/bash

# Script to install Stow locally (into $HOME/.local)

# Check if Stow is already installed
if command -v stow &> /dev/null; then
  echo "Stow is already installed (likely globally)."
  echo "If you want to install locally anyway, uninstall the global version first."
  exit 1
fi
echo "Starting the installation..."
printf "...\n...\n...\n"

URL="http://ftp.gnu.org/gnu/stow/stow-latest.tar.gz"
SOURCE_DIR="$HOME/Downloads"
STOW_VERSION="2.4.1"
STOW_FILE="$SOURCE_DIR/stow-latest.tar.gz"
OMP_STOW_DIR="$HOME/oh-my-package/stow/"
INSTALL_DIR="$OMP_STOW_DIR/.local"
TARGET_LINK_DIR="$OMP_STOW_DIR"


if [ ! -f "$STOW_FILE" ]; then
  echo "Error: There's no source file to be extracted."
  echo "Download the source file at $URL"
  exit 1
fi

# Check if installation directory exists, create if not
mkdir -p "$INSTALL_DIR/bin"

echo "Extracting Stow source..."
tar -xzf "$STOW_FILE"

STOW_DIR="stow-${STOW_VERSION}"

if [ ! -d "$STOW_DIR" ]; then
  echo "Error: Could not find the zip file."
  exit 1
fi

# Build and install Stow
echo "Building and installing Stow..."
cd "$STOW_DIR"

./configure --prefix="$INSTALL_DIR"

if [ $? -ne 0 ]; then
  echo "Error: ./configure failed.  Check dependencies."
  exit 1
fi

make

if [ $? -ne 0 ]; then
  echo "Error: make failed."
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "Error: make install failed."
  exit 1
fi


# Add to PATH
if grep -q "export PATH=\"$INSTALL_DIR/bin:\$PATH\"" "$HOME/.zshrc"; then
  echo "PATH already configured."
else

  if ! [ -f "$HOME/.zshrc" ]; then
    echo "creating $HOME/.zshrc file"
    echo "adding $INSTALL_DIR/bin to PATH in ~/.zshrc"
    echo "export PATH=\"$INSTALL_DIR/bin:\$PATH\"" > "$HOME/.zshrc"
  else
    echo "warning: .zshrc file found. You'll need to manually add $INSTALL_DIR/bin to your PATH."
  fi
fi

# Clean up
echo "cleaning up..."
cd ..
rm -rf "$STOW_DIR"
rm "$STOW_FILE"

# Source the configuration file to update the PATH
if [ -n "$CONFIG_FILE" ]; then
  echo "sourcing $CONFIG_FILE to update PATH..."
  source "$CONFIG_FILE"
fi

echo "stow installed locally to $INSTALL_DIR/bin"

echo "make $INSTALL_DIR/bin/stow executable"
chmod +x "$INSTALL_DIR/bin/stow"
echo "make $INSTALL_DIR/bin/chkstow executable"
chmod +x "$INSTALL_DIR/bin/chkstow"

echo "make link.sh executable"
chmod +x "$OMP_STOW_DIR/link.sh"

printf "...\n...\n...\n"
echo "Creating symbolic links from $TARGET_LINK_DIR to $HOME..."
sh "$OMP_STOW_DIR/link.sh" .

printf "...\n...\n...\n"
echo "verifying installation..."

if stow --version &> /dev/null; then
  echo "stow installation verified successfully."
else
  echo "error: Stow installation verification failed.  Check your PATH."
fi

exit 0