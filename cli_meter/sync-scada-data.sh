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
CUR_DATE=$(date +%Y-%m-01)

log "Syncing from $SRC_DIR to $DEST_DIR for the last $NUM_MONTHS months"

# Loop over the number of months specified
for ((i=0; i<NUM_MONTHS; i++)); do
    # Calculate the date for each month in the past
    timestamp=$(date -d "$CUR_DATE -$i month" +%Y%m)

    # Create the destination directory if it doesn't exist
    dest_dir_path="$DEST_DIR/$timestamp"
    ssh -i "$SSH_KEY_PATH" "$USER@$HOST" "mkdir -p $dest_dir_path"
    
    log "Syncing files for timestamp $timestamp to $dest_dir_path"

    # Rsync all files for the current timestamp
    rsync -av -e "ssh -i $SSH_KEY_PATH" "$SRC_DIR"/*"$timestamp"* "$USER@$HOST:$dest_dir_path/"
done

rsync_exit_code=$?
[ $rsync_exit_code -eq 0 ] && log "Sync from $SRC_DIR to $DEST_DIR complete" || failure $STREAMS_RSYNC_FAIL "Sync from $SRC_DIR to $DEST_DIR failed with exit code $rsync_exit_code"
