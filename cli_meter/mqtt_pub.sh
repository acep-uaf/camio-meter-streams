#!/bin/bash

# Publish message to MQTT broker

# Check command line arguments
if [ $# -ne 4 ]; then
    fail "Usage: $0 <host> <port> <topic> <message>"
fi

# MQTT Broker settings
host="$1"
port="$2"
topic="$3"
message="$4"

# Publish message to the MQTT broker
mosquitto_pub -h "$host" -p "$port" -t "$topic" -m "$message"

if [ $? -eq 0 ]; then
    log "Published message: '$message' to topic: '$topic' to host: $host on port: $port"
else
    log "Failed to published message: $message to topic: $topic to host: $host on port: $port"
fi
