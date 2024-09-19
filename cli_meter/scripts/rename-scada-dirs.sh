#!/bin/bash
# ==============================================================================
# Script Name:        rename-scada-dirs.sh
#
# Description:        This script renames directories that follow the YYYYMM 
#                     format (e.g., 202301, 202306) to the YYYY-MM format 
#                     (e.g., 2023-01, 2023-06) in a given directory. It skips 
#                     directories that are already in the YYYY-MM format or 
#                     do not follow the YYYYMM pattern.
#
# Naming Convention:  Directories in the format YYYYMM will be renamed to 
#                     YYYY-MM (e.g., 202301 -> 2023-01).
#                     
# Log Output:         All operations are logged to a log file specified at 
#                     rename-scada-dirs.log in the same directory as the script.
#
# Usage:              ./rename-scada-dirs.sh <directory_path>
#
# Arguments:          <directory_path> - The base directory where directories 
#                                         should be renamed.
#
# Example:            ./rename-scada-dirs.sh /path/to/directories
#
# ==============================================================================

# Check if a directory path was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <directory_path>"
    exit 1
fi

start_time=$(date +"%Y-%m-%d %H:%M:%S")
LOG_FILE="rename-scada-dirs.log"

# Log function to echo to console and log file using tee
log() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Get the directory path from the argument
DIR_PATH="$1"
log "Script started at: $start_time"
log "Renaming directories in: $DIR_PATH"

# Loop through all directories in the provided path
for dir in "$DIR_PATH"/*/; do
    # Remove the trailing slash from the directory name
    dir=${dir%/}

    # Get the directory's base name (i.e., the name without the full path)
    base_name=$(basename "$dir")

    # Check if the directory name matches the YYYYMM pattern
    if [[ $base_name =~ ^([0-9]{4})([0-9]{2})$ ]]; then
        # Extract the year and month
        year=${BASH_REMATCH[1]}
        month=${BASH_REMATCH[2]}

        # Format it as YYYY-MM
        new_name="${year}-${month}"

        log "Renaming $base_name to $new_name"
        mv "$dir" "$DIR_PATH/$new_name"
    else
        log "Skipping $base_name (not in YYYYMM format)"
    fi
done

log "Script completed."