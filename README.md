
# PHP Malware Removal Tool

This script scans a specified directory for hidden PHP files and PHP files referencing hidden files, moves the hidden files to a quarantine folder, and cleans up malicious references within PHP files.

Simple Tool to PHP Mallware removal from Prestashop, Wordpress, Joomla and ect...

## Features

- **Hidden PHP File Detection**: Detects hidden files that contain PHP code but do not have a `.php` extension.
- **Quarantine Mechanism**: Moves detected malicious files to a quarantine directory.
- **PHP File Cleanup**: Finds and removes malicious references to hidden files in PHP files.
- **Directory Structure Preservation**: Ensures the directory structure is maintained during the quarantine process.

## Requirements

- Bash Shell
- `grep`, `find`, `realpath`, and `sed` utilities installed (these should be available by default on most Unix-like systems).

## Usage

```bash
./script.sh <directory_to_scan> <quarantine_directory>
```

### Arguments:

- `<directory_to_scan>`: The directory that will be scanned for hidden PHP files and PHP files referencing hidden files.
- `<quarantine_directory>`: The directory where hidden files will be moved for quarantine.

### Example:

```bash
./script.sh /var/www/html /var/quarantine
```

This command scans the `/var/www/html` directory for hidden PHP files, quarantines them in `/var/quarantine`, and cleans up malicious code from the original PHP files.

## How It Works:

1. **Hidden File Search**: The script searches the target directory (`<directory_to_scan>`) for hidden files that contain PHP code (i.e., files starting with a `.` but not ending with `.php`).
   
2. **Create Unique List**: A unique list of all hidden PHP files is generated.

3. **PHP File Reference Search**: The script looks for PHP files that reference any of these hidden files and prepares them for cleanup.

4. **Quarantine Process**: All hidden files are moved to the `<quarantine_directory>` while preserving the original directory structure.

5. **Malware Removal**: For each identified PHP file, the script removes blocks of code that reference hidden files if they are enclosed within specific comments, ensuring the integrity of the cleaned file.

6. **Cleanup**: The script removes temporary files used during the scan.

## Quarantine Directory

The quarantine directory will hold the copies of all the hidden files and the original PHP files before the malware references were removed. This ensures that no data is lost and files can be inspected manually if needed.

## License

This script is open-source and free to use, modify, and distribute.
