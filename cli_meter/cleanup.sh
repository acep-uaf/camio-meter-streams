#!/bin/bash
# ==============================================================================
# Script Name:        cleanup.sh
# Description:        This script cleans up outdated event files and temporary working directories.
#
# Usage:              ./cleanup.sh -c <config_path>
#
# Arguments:
#   -c, --config       Path to the configuration file
#   -h, --help         Show usage information
#
# Requirements:       yq
#                     commons.sh
# ==============================================================================

current_dir=$(dirname "$(readlink -f "$0")")
# Source the commons.sh file
source "$current_dir/commons.sh"

LOCKFILE="/var/lock/$(basename $0)" # Define the lock file path using script's basename

# On start
_prepare_locking 

# Try to lock exclusively without waiting; exit if another instance is running
exlock_now || _failed_locking

# Parse the config path argument
config_path=$(parse_config_arg "$@") || exit 1

# Make sure the output config file exists
[ -f "$config_path" ] && log "Config file exists at: $config_path" || fail "Config: Config file does not exist."

# Load configuration
enable_cleanup=$(yq '.enable_cleanup' "$config_path")
num_dirs=$(yq '.directories | length' "$config_path")

# Check if cleanup is enabled
if [ "$enable_cleanup" ]; then
  log "Cleanup enabled, starting cleanup process..."
  [[ -z "$num_dirs" || "$num_dirs" -eq 0 ]] && log "No directories to clean."

  for ((i = 0; i < num_dirs; i++)); do
    base_dir=$(yq ".directories[$i].source" "$config_path")
    retention_days=$(yq ".directories[$i].retention_days" "$config_path")
    
    if [ -d "$base_dir" ] && [ -n "$retention_days" ]; then
      log "Cleaning level0 directories older than $retention_days days in $base_dir"
      
      # Find level0 directories
      find "$base_dir" -type d -regex '.*/level0' | while read -r level0_dir; do
        log "Cleaning level0 directory: $level0_dir"
        
        # Find and delete files older than retention_days, logging each deletion
        find "$level0_dir" -type f -mmin +$retention_days | while read -r file; do
          rm -f "$file" && log "Deleted file: $file" || log "Failed to delete file: $file"
        done

        # Now check and remove empty directories
        find "$level0_dir" -depth -type d | while read -r dir; do
          if [ -z "$(ls -A "$dir")" ]; then
            rmdir "$dir" && log "Removing empty directory: $dir" || log "Failed to remove empty directory: $dir"
          fi
        done

      done
    else
      log "Directory $base_dir does not exist or retention_days not set. Skipping..."
    fi
  done
  log "Cleanup process completed."
else
  log "Cleanup is disabled."
fi
