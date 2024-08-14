#!/usr/bin/env bash
current_dir=$(dirname "$(readlink -f "$0")")
script_name=$(basename "$0")
source "$current_dir/common_utils.sh"

# Trap to handle cleanup on exit
trap cleanup INT
LOCKFILE="/var/lock/$script_name"

# Check for at least 1 argument
[ "$#" -lt 1 ] && show_help_flag && failure $STREAMS_INVALID_ARGS "No arguments provided"

# On start
_prepare_locking

# Try to lock exclusively without waiting; exit if another instance is running
exlock_now || _failed_locking

# Configuration file path
CONFIG_FILE=$(parse_config_arg "$@")
[ -f "$CONFIG_FILE" ] && log "Config file exists at: $CONFIG_FILE" || failure $STREAMS_FILE_NOT_FOUND "Config file does not exist"

# Read values from the YAML config
SRC_DIR=$(read_config "source")
NUM_MONTHS=$(read_config "num_months")
SSH_KEY_PATH=$(read_config "ssh_key_path")
USER=$(read_config "dest_user")
HOST=$(read_config "dest_host")
DEST_DIR=$(read_config "dest_dir")

log "Syncing from $SRC_DIR to $DEST_DIR for the last $NUM_MONTHS months"

# Calculate the timestamp for the given number of months
END_DATE=$(date -d "$NUM_MONTHS months ago" +%Y%m%d)

# Add the SSH key to the agent
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY_PATH"

# Create an associative array to track which timestamps have been processed
declare -A synced_timestamps

# Iterate over files in the source directory
for file in "$SRC_DIR"/*; do
    # Extract the timestamp from the filename
    timestamp=$(echo "$file" | cut -d' ' -f2 | cut -c1-6)
    
    # Check if the timestamp is within the desired range and not already processed
    if [[ "$timestamp" > "${END_DATE:0:6}" ]] && [[ -z "${synced_timestamps[$timestamp]}" ]]; then
        # Mark the timestamp as processed to avoid duplicate processing
        synced_timestamps["$timestamp"]=1
        
        # Create the destination directory if it doesn't exist
        dest_dir_path="$DEST_DIR/$timestamp"
        ssh -i "$SSH_KEY_PATH" "$USER@$HOST" "mkdir -p $dest_dir_path"
        
        log "Syncing files with timestamp $timestamp to $dest_dir_path"
        
        # Rsync all files with the same timestamp in their filenames to timestamped dirs
        rsync -av -e "ssh -i $SSH_KEY_PATH" "$SRC_DIR"/*"$timestamp"* "$USER@$HOST:$dest_dir_path/"
    fi
done

rsync_exit_code=$?
[ $rsync_exit_code -eq 0 ] && log "Sync from $SRC_DIR to $DEST_DIR complete" || failure $STREAMS_RSYNC_FAIL "Sync from $SRC_DIR to $DEST_DIR failed with exit code $rsync_exit_code"

# Remove the SSH key from the agent
ssh-agent -k

