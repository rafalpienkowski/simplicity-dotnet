#!/bin/bash

# Define endpoint URL
ENDPOINT="http://localhost:5000/tickets/events/3/sectors/A?data=aaa"
OUTPUT_FILE="seats.json"
K6_SCRIPT="$(dirname "$0")/load.js"

# Download response from the endpoint
curl -s "$ENDPOINT" -o "$OUTPUT_FILE"

# Check if download was successful
if [[ -s "$OUTPUT_FILE" ]]; then
    echo "Successfully downloaded data to $OUTPUT_FILE"
else
    echo "Failed to download data" >&2
    exit 1
fi

# Run k6 load test
if [[ -f "$K6_SCRIPT" ]]; then
    k6 run "$K6_SCRIPT"
else
    echo "k6 script $K6_SCRIPT not found" >&2
    exit 1
fi

