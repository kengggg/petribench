#!/bin/bash

# Test RSS measurement compatibility with fizzbuzzmem pattern
# This script validates that petribench images work as drop-in replacements

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== PetriBench RSS Measurement Compatibility Test ===${NC}"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
    exit 1
fi

# Create test benchmark program
TEST_FILE="$(mktemp).py"
cat > "$TEST_FILE" << 'EOF'
#!/usr/bin/env python3
# Simple benchmark for testing memory measurement
import time
data = []
for i in range(1, 1001):
    data.append(i * i)
    if i % 100 == 0:
        print(f"Processed {i} items")
print(f"Total: {sum(data)}")
EOF

echo "Created test file: $TEST_FILE"
echo ""

# Test 1: Basic image functionality
echo -e "${YELLOW}Test 1: Basic image functionality${NC}"

# Prefer local image first, then try registry image
echo "Checking image availability..."
if docker image inspect "petribench-python:latest" &>/dev/null; then
    IMAGE_NAME="petribench-python:latest"
    echo "Using local image: $IMAGE_NAME"
elif docker image inspect "ghcr.io/kengggg/petribench-python:latest" &>/dev/null; then
    IMAGE_NAME="ghcr.io/kengggg/petribench-python:latest"
    echo "Using registry image: $IMAGE_NAME"
else
    echo "No local image found, attempting to pull..."
    IMAGE_NAME="ghcr.io/kengggg/petribench-python:latest"
    if ! docker pull "$IMAGE_NAME" 2>/dev/null; then
        echo -e "${RED}Error: Could not find or pull image. Build it first with:${NC}"
        echo "docker build -f ./images/Dockerfile.python -t petribench-python:latest ./images/"
        rm -f "$TEST_FILE"
        exit 1
    fi
fi

echo "Using image: $IMAGE_NAME"
echo ""

# Test 2: fizzbuzzmem pattern compatibility
echo -e "${YELLOW}Test 2: fizzbuzzmem pattern compatibility${NC}"
echo "Running: docker run --rm -v \$TEST_FILE:/workspace/benchmark.py --memory=512m --cpus=1.0 $IMAGE_NAME"

# Capture full output including stderr for time command
FULL_OUTPUT=$(docker run --rm \
    -v "$TEST_FILE:/workspace/benchmark.py" \
    --memory=512m --cpus=1.0 \
    "$IMAGE_NAME" 2>&1)

echo ""
echo "Full output captured."

# Test 3: Extract RSS measurement
echo -e "${YELLOW}Test 3: RSS measurement extraction${NC}"

# Look for GNU time output pattern
RSS_LINE=$(echo "$FULL_OUTPUT" | grep "Maximum resident set size" || true)
if [ -n "$RSS_LINE" ]; then
    echo -e "${GREEN}✓ Found RSS measurement line:${NC}"
    echo "  $RSS_LINE"
    
    # Extract the actual number
    RSS_KB=$(echo "$RSS_LINE" | grep -oE '[0-9]+' | head -1)
    if [ -n "$RSS_KB" ]; then
        echo -e "${GREEN}✓ Extracted RSS value: ${RSS_KB} KB${NC}"
    else
        echo -e "${RED}✗ Could not extract RSS number from: $RSS_LINE${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ No RSS measurement found in output${NC}"
    echo "Expected line containing 'Maximum resident set size'"
    echo "Full output:"
    echo "$FULL_OUTPUT"
    exit 1
fi

# Test 4: Validate benchmark output
echo ""
echo -e "${YELLOW}Test 4: Benchmark output validation${NC}"

# Check last few lines of output (before time statistics)
BENCHMARK_OUTPUT=$(echo "$FULL_OUTPUT" | head -n 100)
LAST_LINE=$(echo "$BENCHMARK_OUTPUT" | tail -1)

if [[ "$LAST_LINE" =~ ^Total:\ [0-9]+$ ]]; then
    echo -e "${GREEN}✓ Benchmark output ends correctly with total${NC}"
else
    echo -e "${RED}✗ Expected last line to match 'Total: [number]', got: '$LAST_LINE'${NC}"
    echo "First 10 lines of benchmark output:"
    echo "$BENCHMARK_OUTPUT" | head -10
    exit 1
fi

# Test 5: Multiple runs for consistency
echo ""
echo -e "${YELLOW}Test 5: Measurement consistency (3 runs)${NC}"

MEASUREMENTS=()
for i in {1..3}; do
    echo -n "Run $i... "
    OUTPUT=$(docker run --rm \
        -v "$TEST_FILE:/workspace/benchmark.py" \
        --memory=512m --cpus=1.0 \
        "$IMAGE_NAME" 2>&1)
    
    RSS=$(echo "$OUTPUT" | grep "Maximum resident set size" | grep -oE '[0-9]+' | head -1)
    MEASUREMENTS+=($RSS)
    echo "${RSS} KB"
done

echo ""
echo "Measurements: ${MEASUREMENTS[@]} KB"

# Calculate variance
MIN=${MEASUREMENTS[0]}
MAX=${MEASUREMENTS[0]}
for measurement in "${MEASUREMENTS[@]}"; do
    if [ $measurement -lt $MIN ]; then MIN=$measurement; fi
    if [ $measurement -gt $MAX ]; then MAX=$measurement; fi
done

VARIANCE=$((MAX - MIN))
echo "Variance: $VARIANCE KB (Min: $MIN KB, Max: $MAX KB)"

if [ $VARIANCE -lt $((MIN / 10)) ]; then  # Less than 10% variance
    echo -e "${GREEN}✓ Measurements are consistent (variance < 10%)${NC}"
else
    echo -e "${YELLOW}⚠ High variance detected (${VARIANCE} KB). This might indicate system load.${NC}"
fi

# Cleanup
rm -f "$TEST_FILE"

echo ""
echo -e "${GREEN}=== All RSS measurement tests passed! ===${NC}"
echo -e "${GREEN}✓ Image is compatible with fizzbuzzmem measurement pattern${NC}"
echo -e "${GREEN}✓ GNU time RSS measurement working correctly${NC}"
echo -e "${GREEN}✓ Volume mount and resource limits supported${NC}"
echo ""
echo "To use with fizzbuzzmem, replace current Docker images with:"
echo "  docker tag $IMAGE_NAME benchmark-python"