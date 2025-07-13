#!/bin/bash

# Example: PSS/USS measurement using smem2 and /proc/smaps_rollup
# This demonstrates enhanced memory measurement for more accurate container attribution

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 <language> <script_file>"
    echo "Example: $0 python benchmark.py"
    exit 1
fi

LANGUAGE="$1"
SCRIPT_FILE="$2"

if [ ! -f "$SCRIPT_FILE" ]; then
    echo "Error: Script file '$SCRIPT_FILE' not found"
    exit 1
fi

IMAGE_NAME="ghcr.io/kengggg/petribench-${LANGUAGE}:latest"

echo "=== PSS/USS Measurement Example ==="
echo "Language: $LANGUAGE"
echo "Script file: $SCRIPT_FILE"
echo "Image: $IMAGE_NAME"
echo ""

# Method 1: Using smem2
echo "Method 1: Using smem2"
echo "Running container with smem2 measurement..."

SMEM_RESULT=$(docker run --rm \
    -v "$(pwd)/$SCRIPT_FILE:/app/$(basename "$SCRIPT_FILE")" \
    --memory=512m --cpus=1.0 \
    "$IMAGE_NAME" \
    sh -c "
        # Start the program in background
        $LANGUAGE $(basename "$SCRIPT_FILE") >/dev/null 2>&1 &
        PID=\$!
        
        # Wait a moment for startup
        sleep 0.1
        
        # Measure with smem2
        smem2 -P \$PID -c pss,uss,rss 2>/dev/null || echo 'Process finished too quickly'
        
        # Wait for completion
        wait \$PID 2>/dev/null || true
    " 2>/dev/null || echo "smem2 measurement completed")

echo "smem2 output:"
echo "$SMEM_RESULT"

echo ""
echo "Method 2: Using /proc/PID/smaps_rollup"
echo "Running container with proc parsing..."

PROC_RESULT=$(docker run --rm \
    -v "$(pwd)/$SCRIPT_FILE:/app/$(basename "$SCRIPT_FILE")" \
    --memory=512m --cpus=1.0 \
    "$IMAGE_NAME" \
    sh -c "
        # Start the program in background
        $LANGUAGE $(basename "$SCRIPT_FILE") >/dev/null 2>&1 &
        PID=\$!
        
        # Wait a moment for startup
        sleep 0.1
        
        # Parse /proc/PID/smaps_rollup if process still running
        if [ -r /proc/\$PID/smaps_rollup ]; then
            echo '=== /proc/\$PID/smaps_rollup ==='
            grep -E 'Pss:|Private_Clean:|Private_Dirty:|Rss:' /proc/\$PID/smaps_rollup
        else
            echo 'Process finished too quickly for proc measurement'
        fi
        
        # Wait for completion
        wait \$PID 2>/dev/null || true
    " 2>/dev/null || echo "/proc measurement completed")

echo "/proc parsing output:"
echo "$PROC_RESULT"

echo ""
echo "Method 3: RSS via time (for comparison)"
echo "Running with GNU time for RSS comparison..."

TIME_RESULT=$(docker run --rm \
    -v "$(pwd)/$SCRIPT_FILE:/app/$(basename "$SCRIPT_FILE")" \
    --memory=512m --cpus=1.0 \
    "$IMAGE_NAME" \
    /usr/bin/time -v $LANGUAGE $(basename "$SCRIPT_FILE") 2>&1)

RSS_LINE=$(echo "$TIME_RESULT" | grep "Maximum resident set size" || echo "No RSS found")
echo "GNU time output: $RSS_LINE"

echo ""
echo "=== Memory Metrics Explained ==="
echo "RSS (Resident Set Size): Total memory in RAM (includes shared)"
echo "PSS (Proportional Set Size): Shared memory divided by number of sharers"
echo "USS (Unique Set Size): Memory unique to this process only"
echo ""
echo "For container benchmarking:"
echo "- RSS: Good for total memory impact"
echo "- PSS: Better for multi-process containers"
echo "- USS: Best for pure process memory usage"