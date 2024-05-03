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
    log "Published message to MQTT broker. | Topic: '$topic' | Host: '$host' | Port: '$port' | Payload: '$message'"
else
    log "Failed to publish message. | Topic: '$topic' | Host: '$host' | Port: '$port' | Payload: '$message'"
fi
