#!/bin/bash

# Loop through each directory in the current directory
for dir in */; do
  # Define paths
  config_file="$dir/config.json"
  main_script="$dir/main.zsh"

  # Generate the name by converting the directory name into spaces and proper capitalization
  name=$(echo "$dir" | sed 's/\([a-z0-9]\)\([A-Z]\)/\1 \2/g' | sed 's/_/ /g' | sed 's/^[a-z]/\u&/g')

  # Create a main.zsh file if it doesn't exist
  if [[ ! -f "$main_script" ]]; then
    echo "#!/bin/zsh" > "$main_script"
    echo "# Main script for $name" >> "$main_script"
    echo "echo \"Executing $name capability...\"" >> "$main_script"
    chmod +x "$main_script"  # Make it executable
    echo "✅ Created main.zsh in: $dir"
  else
    echo "⚠️ main.zsh already exists in: $dir (Skipping)"
  fi
done