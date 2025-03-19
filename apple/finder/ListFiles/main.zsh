#!/bin/zsh

# Default directory to root ("/") if no argument is provided
DIR_PATH="${1:-/}"

# Expand `~` to full home directory path
DIR_PATH=${DIR_PATH/#\~/$HOME}

# Check if the directory exists
if [[ ! -d "$DIR_PATH" ]]; then
  echo '{"error": "Directory not found"}'
  exit 1
fi

# List files in JSON format
FILES=$(ls -1 "$DIR_PATH" | jq -R . | jq -s .)
echo "{\"files\": $FILES}"