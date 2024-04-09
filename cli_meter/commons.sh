#!/bin/bash

##################################
#
# This sourced by data_pipeline.sh
#
#################################

fail() {
  echo "$1" >&2
  exit 1
}

# Output message to stdout & stderr
log() {
  echo "$1" >&2
}

export -f log
export -f fail
