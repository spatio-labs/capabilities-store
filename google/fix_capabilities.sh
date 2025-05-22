#!/bin/bash

# Script to standardize all Google capabilities
# Fixes issues with duplicate functions and ensures consistent structure

set -e  # Exit on any error

ROOT_DIR="$(pwd)"
SERVICES=("gmail" "google_drive" "google_calendar")

echo "Starting standardization of all Google capabilities..."

# Process each service directory
for service in "${SERVICES[@]}"; do
  echo "Processing $service service..."
  
  # Find all capability main.swift files
  for swift_file in $(find "$service" -type f -name "main.swift"); do
    echo "  Fixing $swift_file..."
    
    # Create a temporary file
    temp_file="${swift_file}.tmp"
    
    # Update shebang line and import statement
    sed '1s|^#!/usr/bin/env swift sh|#!/usr/bin/swift sh|' "$swift_file" | \
    sed '2s|^import SpatioSDK.*$|import SpatioSDK // @spatio-labs == main|' > "$temp_file"
    
    # Remove duplicate configureGoogleAuth() function
    # This removes the second occurrence of the function and everything up to the configureGoogleAuth() call
    awk '
      BEGIN { skip=0; found=0; }
      /^\/\/ Entry point for the capability/ { skip=1; }
      /^\/\/ Configure authentication/ { if (skip==1) { skip=0; } }
      /^func configureGoogleAuth\(\)/ { 
        if (found==0) { 
          found=1; 
          print; 
        } else { 
          skip=1; 
        } 
        next; 
      }
      { if (skip==0) print; }
    ' "$temp_file" > "${temp_file}.2"
    
    # Replace the original file
    mv "${temp_file}.2" "$swift_file"
    rm -f "$temp_file"
    
    # Make the script executable
    chmod +x "$swift_file"
    
    echo "  ✅ Fixed $swift_file"
  done
done

echo "All capabilities standardized successfully!" 