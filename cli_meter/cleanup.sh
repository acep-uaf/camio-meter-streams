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

LOCKFILE="/var/lock/`basename $0`" # Define the lock file path using script's basename

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
  log "Starting cleanup process..."
  [[ -z "$num_dirs" || "$num_dirs" -eq 0 ]] && log "No directories to clean."

  for ((i = 0; i < num_dirs; i++)); do
    dir=$(yq ".directories[$i].source" "$config_path")
    retention_minutes=$(yq ".directories[$i].retention_minutes" "$config_path")
    log "Cleaning directory: $dir"
    log "retention_minutes: $retention_minutes"

    if [ -d "$dir" ]; then
      log "Deleting everything older than $retention_minutes minutes in directory $dir"
      find "$dir" -mindepth 1 -mmin +$retention_minutes -ls
      # Switch to days -mtime +$retention_days
    else
      log "Directory $dir does not exist. Skipping..."
    fi
  done

  log "Cleanup process completed."
else
  log "Cleanup is disabled. Check config."
fi
