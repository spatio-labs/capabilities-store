#!/bin/zsh

# Ensure an argument is provided
if [[ -z "$1" ]]; then
  echo '{"error": "Missing file path argument"}'
  exit 1
fi

# Expand `~` to full home directory path
FILE_PATH=${1/#\~/$HOME}

# Check if the file exists
if [[ ! -f "$FILE_PATH" ]]; then
  echo '{"error": "File not found"}'
  exit 1
fi

# Define a list of binary file extensions to exclude
BINARY_EXTENSIONS=("mov" "mp4" "avi" "mkv" "flv" "webm" "zip" "dmg" "iso" "exe" "bin")

# Extract file extension
EXT="${FILE_PATH##*.}"

# Check if the file is a binary file
if [[ " ${BINARY_EXTENSIONS[@]} " =~ " ${EXT} " ]]; then
  echo '{"error": "Binary file cannot be read"}'
  exit 1
fi

# Read file content safely (removes newlines, escapes quotes)
CONTENT=$(cat "$FILE_PATH" 2>/dev/null | tr '\n' ' ' | sed 's/"/\\"/g')

# Output JSON result
echo "{\"filename\": \"$(basename "$FILE_PATH")\", \"content\": \"$CONTENT\"}"