#!/bin/bash

log() {
    local priority=${2:-info}
    local tag="STREAM"

    # This will send the message to stderr
    echo "$1" >&2

    # This will send the message to the systemd journal with a dynamic priority
    logger -p user.$priority -t "$tag" "$1"
}

export -f log
