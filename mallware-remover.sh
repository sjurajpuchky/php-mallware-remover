#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <directory_to_scan> <quarantine_directory>"
    exit 1
fi

SOURCE_DIR=$1
TARGET_DIR=$2

# Ensure both directories are absolute paths
SOURCE_DIR=$(realpath "$SOURCE_DIR")
TARGET_DIR=$(realpath "$TARGET_DIR")
QUARANTINED_FILES=0
REMOVED_INVOCATIONS=0

# Ensure the target directory exists
mkdir -p "$TARGET_DIR"

# Create unique temporary files in /tmp
hidden_php_files=$(mktemp /tmp/hidden_php_files.XXXXXX)
unique_hidden_php_files=$(mktemp /tmp/unique_hidden_php_files.XXXXXX)
referenced_php_files=$(mktemp /tmp/referenced_php_files.XXXXXX)

# Find hidden files that contain PHP code but don't have .php in their name
find "$SOURCE_DIR" -name ".*" -type f ! -name "*.php*" -exec grep -l "<?php" {} \; > "$hidden_php_files"

# Create a unique list of the hidden files found
sort "$hidden_php_files" | uniq > "$unique_hidden_php_files"

# Find all PHP files that reference any of the filenames in unique_hidden_php_files.txt
> "$referenced_php_files"  # Empty the file before appending

while read -r filename; do
    # Strip any extension from the filename
    basename="${filename##*/}"  # Get the base name
    basename="${basename%.*}"   # Remove the extension
    echo "Looking for $basename"
    grep -rl "$basename.*@include_once" --include="*.php*" "$SOURCE_DIR" >> "$referenced_php_files"
done < "$unique_hidden_php_files"


# Check PHP files for comments containing the filenames, copy the files, and remove specific lines from original files
while read -r php_file; do
    for filename in $(cat "$unique_hidden_php_files"); do
        # Find the opening comment that contains the filename
        opening_comment=$(grep -E '/\*[a-z0-9]+\*/' "$php_file" 2> /dev/null|sort|uniq| head -1)
        escaped_comment=$(echo "$opening_comment" | sed 's/[\/&*]/\\&/g')
        first_line=$(grep -n "$escaped_comment" "$php_file" 2> /dev/null|head -1)
        last_line=$(grep -n "$escaped_comment" "$php_file" 2> /dev/null|tail -1)
        comment_first_line=$(echo "$first_line"|cut -d":" -f2)
        comment_last_line=$(echo "$last_line"|cut -d":" -f2)
        comment_first_n=$(echo "$first_line"|cut -d":" -f1)
        comment_last_n=$(echo "$last_line"|cut -d":" -f1)
        
        
        # If an opening comment is found, use sed to delete the block between matching comments
        if [[ -n "$opening_comment" && "$comment_first_line" == "$comment_last_line" && -n "$comment_first_n" && -n "$comment_last_n" ]]; then
            echo "Removing invocation from $php_file"
            # Copy the modified PHP file to the target directory
            relative_path="${php_file#$SOURCE_DIR/}"
            target_file_dir=$(dirname "$TARGET_DIR/$relative_path")
            mkdir -p "$target_file_dir"
            # Copy old file to the quarantine folder
            cp "$php_file" "$TARGET_DIR/$relative_path"
            # Remove mallware invocation
            sed -i "${comment_first_n},${comment_last_n}d" "$php_file"
            REMOVED_INVOCATIONS=$(expr $REMOVED_INVOCATIONS + 1)
        fi
    done
done < "$referenced_php_files"

# Move all unique hidden PHP files to the quarantine directory while preserving the directory structure
while read -r hidden_file; do
    # Determine relative path of the file in relation to the source directory
    relative_path="${hidden_file#$SOURCE_DIR/}"
    
    # Create target subdirectories as needed
    target_file_dir=$(dirname "$TARGET_DIR/$relative_path")
    mkdir -p "$target_file_dir"
    
    # Move the hidden file to the quarantine folder
    mv "$hidden_file" "$TARGET_DIR/$relative_path"
    QUARANTINED_FILES=$(expr $QUARANTINED_FILES + 1)
done < "$unique_hidden_php_files"

# Find and remove empty php files
find "$SOURCE_DIR" -name "*.php" -size 0|while read f
do
rm -f "$f"
done

# Step 6: Cleanup temporary files
rm "$hidden_php_files" "$unique_hidden_php_files" "$referenced_php_files"

echo "Script execution completed."
echo "Scanned folder: $SOURCE_DIR"
echo "Quarantine folder: $TARGET_DIR"
echo "Quarantined files: $QUARANTINED_FILES"
echo "Removed mallware invocations: $REMOVED_INVOCATIONS"
