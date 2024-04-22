#!/bin/bash

# This sourced by data_pipeline.sh and contains common functions used by other scripts

fail() {
  echo "[ERROR] $1" >&2
  exit 1
}

# Output message to stdout & stderr
log() {
  echo "$1" >&2
}

show_help_flag() {
  download_flag=false

  if [[ "$1" == "-d" ]]; then
    download_flag=true
  fi

  log "Usage: $0 [options]"
  log ""
  log "Options:"
  log "  -c, --config <path>          Specify the path to the YML config file."
  if [[ "$download_flag" == true ]]; then
    log "  -d, --download_dir <path>    Specify the path to the download directory."
  fi
  log "  -h, --help                   Display this help message and exit."
  log ""
  log "Examples:"
  if [[ "$download_flag" == true ]]; then
    log "  $0 -c /path/to/config.yml -d /path/to/download_dir"
    log "  $0 --config /path/to/config.yml --download_dir /path/to/download_dir"
  else
    log "  $0 -c /path/to/config.yml"
    log "  $0 --config /path/to/config.yml"
  fi
  exit 0

}

export -f log
export -f fail
export -f show_help_flag
