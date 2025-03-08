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

# Define a list of video file extensions
VIDEO_EXTENSIONS=("mov" "mp4" "avi" "mkv" "flv" "webm")

# Initialize JSON output
echo -n '{"files": ['

FIRST_ENTRY=true

# Iterate through files in directory
for FILE in "$DIR_PATH"/*; do
  if [[ -f "$FILE" ]]; then
    # Extract file extension
    EXT="${FILE##*.}"

    # Check if the file is a video file
    if [[ " ${VIDEO_EXTENSIONS[@]} " =~ " ${EXT} " ]]; then
      CONTENT=""  # Empty content for video files
    else
      # Read file content safely (removes newlines, escapes quotes)
      CONTENT=$(cat "$FILE" 2>/dev/null | tr '\n' ' ' | sed 's/"/\\"/g')
    fi

    # Add comma separator if not the first entry
    if [[ "$FIRST_ENTRY" == "false" ]]; then
      echo -n ','
    fi
    FIRST_ENTRY=false

    # Output JSON entry
    echo -n "{\"filename\": \"$(basename "$FILE")\", \"content\": \"$CONTENT\"}"
  fi
done

# Close JSON array
echo ']}'