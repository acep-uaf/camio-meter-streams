#!/bin/bash

# Function to generate the help message
help_msg() {
    script_name=$1
    echo "Usage: ./$script_name [options]

Options:
  -c, --config <path>          Specify the path to the YML config file.
  -h, --help                   Display this help message and exit.

Examples:
  ./$script_name -c /path/to/config.yml
  ./$script_name --config /path/to/config.yml"
}
