
# Ensure necessary commands are available
if command -v jq &> /dev/null; then
  echo "jq is installed"
  exit 1
fi


echo "Installing jq..."
# Define the source and target paths
SOURCE_PATH="$HOME/oh-my-package/.local/bin/jq"
TARGET_PATH="$HOME/.local/bin/jq"
# Create the symbolic link
ln -s "$SOURCE_PATH" "$TARGET_PATH"
echo "Symbolic link created successfully from '$SOURCE_PATH' to '$TARGET_PATH'."
