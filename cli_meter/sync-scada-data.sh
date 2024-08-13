#!/usr/bin/env bash

# Trap to handle cleanup on exit
trap cleanup INT

function cleanup() {
    echo "exiting..."
    exit 0
}

# Function to read config values using yq
function read_config() {
    local key=$1
    yq e ".$key" $CONFIG_FILE
}

CONFIG_FILE="$1"

# Read values from the YAML config
SRC_DIR=$(read_config "source")
NUM_MONTHS=$(read_config "num_months")
SSH_KEY_PATH=$(read_config "ssh_key_path")
USER=$(read_config "dest_user")
HOST=$(read_config "dest_host")
DEST_DIR=$(read_config "dest_dir")

echo "Syncing from $SRC_DIR to $DEST_DIR for the last $NUM_MONTHS months"

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

        echo "Syncing files with timestamp $timestamp to $dest_dir_path"

        # Rsync all files with the same timestamp in their filenames to timestamped dirs
        rsync -av -e "ssh -i $SSH_KEY_PATH" "$SRC_DIR"/*"$timestamp"* "$USER@$HOST:$dest_dir_path/"
    else
        if [[ -z "${synced_timestamps[$timestamp]}" ]]; then
            echo "Skipping file, timestamp $timestamp is already synced"
        else
            echo "Skipping file, $timestamp is outside the range"
        fi
    fi
done

# Kill the ssh-agent after the script runs
ssh-agent -k

echo "Syncing from $SRC_DIR to $DEST_DIR complete"