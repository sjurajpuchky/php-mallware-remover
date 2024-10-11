#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_directory> <target_directory>"
    exit 1
fi

SOURCE_DIR=$1
TARGET_DIR=$2

# Ensure both directories are absolute paths
SOURCE_DIR=$(realpath "$SOURCE_DIR")
TARGET_DIR=$(realpath "$TARGET_DIR")

# Ensure the target directory exists
mkdir -p "$TARGET_DIR"

# Create unique temporary files in /tmp
hidden_php_files=$(mktemp /tmp/hidden_php_files.XXXXXX)
unique_hidden_php_files=$(mktemp /tmp/unique_hidden_php_files.XXXXXX)
referenced_php_files=$(mktemp /tmp/referenced_php_files.XXXXXX)

# Step 1: Find hidden files that contain PHP code but don't have .php in their name
find "$SOURCE_DIR" -name ".*" -type f ! -name "*.php*" -exec grep -l "<?php" {} \; > "$hidden_php_files"

# Step 2: Create a unique list of the hidden files found
sort "$hidden_php_files" | uniq > "$unique_hidden_php_files"

# Step 3: Find all PHP files that reference any of the filenames in unique_hidden_php_files.txt
> "$referenced_php_files"  # Empty the file before appending

while read -r filename; do
    basename=$(basename "$filename")
    grep -rl "$basename" --include="*.php*" "$SOURCE_DIR" >> "$referenced_php_files"
done < "$unique_hidden_php_files"

# Step 4: Copy all unique hidden PHP files to the target directory while preserving the directory structure
while read -r hidden_file; do
    # Determine relative path of the file in relation to the source directory
    relative_path="${hidden_file#$SOURCE_DIR/}"
    
    # Create target subdirectories as needed
    target_file_dir=$(dirname "$TARGET_DIR/$relative_path")
    mkdir -p "$target_file_dir"
    
    # Copy the hidden file to the target directory while preserving the directory structure
    cp "$hidden_file" "$TARGET_DIR/$relative_path"
done < "$unique_hidden_php_files"

# Step 5: Check PHP files for comments containing the filenames, copy the files, and remove specific lines from original files
while read -r php_file; do
    for filename in $(cat "$unique_hidden_php_files"); do
        # Find the opening comment that contains the filename
        opening_comment=$(grep -oP "/\*.*$filename.*\*/" "$php_file" | head -n 1)
        
        # If an opening comment is found, use sed to delete the block between matching comments
        if [[ -n "$opening_comment" ]]; then
            # Escape special characters for use in sed
            escaped_comment=$(echo "$opening_comment" | sed 's/[\/&]/\\&/g')
            
            # Use sed to delete the lines between the opening and closing matching comment blocks
            sed -i "/$escaped_comment/,/$escaped_comment/d" "$php_file"
            
            # Copy the modified PHP file to the target directory
            relative_path="${php_file#$SOURCE_DIR/}"
            target_file_dir=$(dirname "$TARGET_DIR/$relative_path")
            mkdir -p "$target_file_dir"
            cp "$php_file" "$TARGET_DIR/$relative_path"
        fi
    done
done < "$referenced_php_files"

# Step 6: Cleanup temporary files
rm "$hidden_php_files" "$unique_hidden_php_files" "$referenced_php_files"

echo "Script execution completed."
