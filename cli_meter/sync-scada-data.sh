#!/bin/bash
# ==============================================================================
# Script Name:        sync-scada-data.sh
# Description:        This script syncs SCADA data files from a source directory
#                     to a destination directory over a specified number of months.
#                     The script reads configuration values from a YAML file.
#
# Usage:              ./sync-scada-data.sh -c <config_path>
#
# Arguments:
#   -c, --config       Path to the configuration file
#   -h, --help         Show usage information
#
# Requirements:       yq
#                     common_utils.sh
# ==============================================================================


CUR_DIR=$(dirname "$(readlink -f "$0")")
SCRIPT_NAME=$(basename "$0")
source "$CUR_DIR/common_utils.sh"

# Trap to handle cleanup on exit
trap cleanup INT
LOCKFILE="/var/lock/$SCRIPT_NAME"

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
SRC_DIR=$(read_config "src_dir")
NUM_MONTHS=$(read_config "num_months")
DEST_DIR=$(read_config "dest_dir")
CUR_DATE=$(date +%Y-%m-01)

log "Syncing from $SRC_DIR to $DEST_DIR for the last $NUM_MONTHS months"

# Loop over the number of months specified
for ((i=0; i<NUM_MONTHS; i++)); do
    # Calculate the date for each month in the past
    cur_timestamp=$(date -d "$CUR_DATE -$i month" +%Y%m)

    # Create the destination directory if it doesn't exist
    dest_dir_path="$DEST_DIR/$cur_timestamp"
    
    log "Syncing files for timestamp $cur_timestamp to $dest_dir_path"

    # Rsync all files for the current timestamp
    rsync -av $SRC_DIR/*$cur_timestamp* $dest_dir_path
done

rsync_exit_code=$?
[ $rsync_exit_code -eq 0 ] && log "Sync from $SRC_DIR to $DEST_DIR complete" || failure $STREAMS_RSYNC_FAIL "Sync from $SRC_DIR to $DEST_DIR failed with exit code $rsync_exit_code"
