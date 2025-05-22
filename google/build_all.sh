#!/bin/bash

# Script to compile all Swift capabilities and update their capability.json files

set -e  # Exit on any error

ROOT_DIR="$(pwd)"
SERVICES=("gmail" "google_drive" "google_calendar")

echo "Starting compilation of all Google capabilities..."

# First, standardize all main.swift files using the fix_capabilities.sh script
echo "Standardizing all capabilities..."
./fix_capabilities.sh

# Process each service directory
for service in "${SERVICES[@]}"; do
  echo "Processing $service service..."
  
  # Find all capability directories (containing main.swift)
  for capability_dir in $(find "$service" -type f -name "main.swift" -exec dirname {} \;); do
    echo "  Compiling capability in $capability_dir..."
    
    # Go to capability directory
    cd "$ROOT_DIR/$capability_dir"
    
    # Compile the Swift script
    swift sh main.swift --compile -o main
    
    # Update the capability.json to use the compiled binary
    sed -i '' 's/"entry_point": "main.swift"/"entry_point": "main"/g' capability.json
    
    echo "  ✅ Compiled and updated $capability_dir"
  done
done

echo "All capabilities compiled successfully!"