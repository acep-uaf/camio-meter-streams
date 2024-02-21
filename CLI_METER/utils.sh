#!/bin/bash

log() {
    local MESSAGE=$1
    local LOG_LEVEL=${2-"INFO"}
    local LOG_FILE=${3-"default_log.log"}
    local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${TIMESTAMP} [${LOG_LEVEL}] ${MESSAGE}" | tee -a $LOG_FILE
}

export -f log