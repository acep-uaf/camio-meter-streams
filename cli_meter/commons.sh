#!/bin/bash

##################################
#
# This sourced by data_pipeline.sh
#
#################################

log() {
    local priority=${2:-info}
    local tag="STREAM"

    # This will send the message to stderr
    #echo "$1" >&2

    # This will send the message to the systemd journal with a dynamic priority
    logger -p user.$priority -t "$tag" "$1"
}

# Function to exit script with an error message
exit_with_error() {
  echo "$1" >&2
  exit 1
}

export -f log
export -f exit_with_error