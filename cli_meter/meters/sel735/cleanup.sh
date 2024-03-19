#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <output_dir> <event_id> <meter_ip>"
    exit 1
fi

output_dir=$1
event_id=$2
event_dir="$output_dir/level0/$event_id"

# New path with .incomplete suffix
incomplete_event_dir="${event_dir}.incomplete"

if [ -d "$event_dir" ]; then
    log "Renaming directory to mark as incomplete: $event_dir -> $incomplete_event_dir" "warn"
    echo "Incomplete download: $event_id"
    mv "$event_dir" "$incomplete_event_dir"
else
    echo "No path found: $event_dir"
fi


