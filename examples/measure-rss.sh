#!/bin/bash

# Example: RSS measurement using GNU time 
# This demonstrates basic memory measurement for any script

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 <language> <script_file>"
    echo "Example: $0 python benchmark.py"
    echo "Example: $0 python fibonacci.py"
    exit 1
fi

LANGUAGE="$1"
SCRIPT_FILE="$2"

if [ ! -f "$SCRIPT_FILE" ]; then
    echo "Error: Script file '$SCRIPT_FILE' not found"
    exit 1
fi

IMAGE_NAME="ghcr.io/kengggg/petribench-${LANGUAGE}:latest"

echo "=== RSS Measurement Example ==="
echo "Language: $LANGUAGE"
echo "Script file: $SCRIPT_FILE"
echo "Image: $IMAGE_NAME"
echo ""

# Run with memory measurement
echo "Running measurement..."
RESULT=$(docker run --rm \
    -v "$(pwd)/$SCRIPT_FILE:/app/$(basename "$SCRIPT_FILE")" \
    --memory=512m --cpus=1.0 \
    "$IMAGE_NAME" \
    /usr/bin/time -v $LANGUAGE $(basename "$SCRIPT_FILE") 2>&1)

echo ""
echo "Full output:"
echo "$RESULT"

echo ""
echo "=== RSS Measurement ==="
RSS_LINE=$(echo "$RESULT" | grep "Maximum resident set size")
RSS_KB=$(echo "$RSS_LINE" | grep -oE '[0-9]+' | head -1)

echo "RSS (Resident Set Size): $RSS_KB KB"
echo ""
echo "Note: RSS includes all memory pages in RAM, including shared libraries."