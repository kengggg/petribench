#!/bin/bash

# Build base image and all dependent language images locally
# Mirrors CI logic: base change triggers all language builds

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Building Base + All Language Images ===${NC}"
echo "This mirrors CI behavior: base Dockerfile change triggers all language builds"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
    exit 1
fi

# Change to project root (script can be run from anywhere)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Verify we're in the right location
if [ ! -d "./images" ]; then
    echo -e "${RED}Error: Cannot find images/ directory. Are you in the PetriBench project root?${NC}"
    exit 1
fi

# Build base image first
echo -e "${YELLOW}Step 1/2: Building base image...${NC}"
if docker build -f ./images/Dockerfile.base -t petribench-base ./images/; then
    echo -e "${GREEN}✓ Base image built successfully${NC}"
else
    echo -e "${RED}✗ Failed to build base image${NC}"
    exit 1
fi

echo ""

# Build all language images that depend on base
echo -e "${YELLOW}Step 2/2: Building all dependent language images...${NC}"
LANGUAGES=("python" "go" "node" "c" "cpp" "jdk" "jre" "rust" "dotnet-sdk" "dotnet-runtime")

FAILED_IMAGES=()
SUCCESSFUL_IMAGES=()

for LANG in "${LANGUAGES[@]}"; do
    echo -e "${YELLOW}Building $LANG image...${NC}"
    if docker build -f ./images/Dockerfile.$LANG -t petribench-$LANG ./images/; then
        echo -e "${GREEN}✓ $LANG image built successfully${NC}"
        SUCCESSFUL_IMAGES+=("$LANG")
    else
        echo -e "${RED}✗ Failed to build $LANG image${NC}"
        FAILED_IMAGES+=("$LANG")
    fi
    echo ""
done

# Show results summary
echo -e "${BLUE}=== Build Summary ===${NC}"
echo -e "${GREEN}✓ Successful builds ($(( ${#SUCCESSFUL_IMAGES[@]} + 1 )) images):${NC}"
echo "  - base"
for img in "${SUCCESSFUL_IMAGES[@]}"; do
    echo "  - $img"
done

if [ ${#FAILED_IMAGES[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}✗ Failed builds (${#FAILED_IMAGES[@]} images):${NC}"
    for img in "${FAILED_IMAGES[@]}"; do
        echo "  - $img"
    done
fi

# Show image sizes
echo ""
echo -e "${YELLOW}Image sizes:${NC}"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(REPOSITORY|petribench-)"

echo ""
if [ ${#FAILED_IMAGES[@]} -eq 0 ]; then
    echo -e "${GREEN}=== All images built successfully! ===${NC}"
    echo ""
    echo "Next steps:"
    echo "  - Test functionality: ./scripts/measure-memory.sh --mode test python scripts/benchmarks/benchmark.py"
    echo "  - Build individual images: ./scripts/build-individual.sh [language]"
    echo "  - Available languages: ${LANGUAGES[*]}"
    exit 0
else
    echo -e "${RED}=== Some builds failed ===${NC}"
    echo "Failed images: ${FAILED_IMAGES[*]}"
    exit 1
fi