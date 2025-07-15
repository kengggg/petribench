#!/bin/bash

# Build individual language image locally
# Mirrors CI logic: individual language Dockerfile change triggers only that language build

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Available languages (must match actual Dockerfiles)
AVAILABLE_LANGUAGES=("python" "go" "node" "c" "cpp" "jdk" "jre" "rust" "dotnet-sdk" "dotnet-runtime")

# Function to show usage
show_usage() {
    echo "Usage: $0 <language>"
    echo ""
    echo "Available languages:"
    for lang in "${AVAILABLE_LANGUAGES[@]}"; do
        echo "  - $lang"
    done
    echo ""
    echo "Examples:"
    echo "  $0 python    # Build only Python image"
    echo "  $0 go        # Build only Go image"
    echo "  $0 rust      # Build only Rust image"
}

# Check if language parameter is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No language specified${NC}"
    echo ""
    show_usage
    exit 1
fi

LANGUAGE="$1"

# Validate language parameter
if [[ ! " ${AVAILABLE_LANGUAGES[*]} " =~ " $LANGUAGE " ]]; then
    echo -e "${RED}Error: Unknown language '$LANGUAGE'${NC}"
    echo ""
    show_usage
    exit 1
fi

echo -e "${BLUE}=== Building Individual Language Image: $LANGUAGE ===${NC}"
echo "This mirrors CI behavior: individual language Dockerfile change triggers only that language"
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

# Check if Dockerfile exists
DOCKERFILE_PATH="./images/Dockerfile.$LANGUAGE"
if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo -e "${RED}Error: Dockerfile not found: $DOCKERFILE_PATH${NC}"
    exit 1
fi

# Check if base image exists (most language images depend on it)
if ! docker images petribench-base --format "{{.Repository}}" | grep -q "petribench-base"; then
    echo -e "${YELLOW}Warning: Base image 'petribench-base' not found${NC}"
    echo "Building base image first..."
    echo ""
    if docker build -f ./images/Dockerfile.base -t petribench-base ./images/; then
        echo -e "${GREEN}✓ Base image built successfully${NC}"
    else
        echo -e "${RED}✗ Failed to build base image${NC}"
        exit 1
    fi
    echo ""
fi

# Build the specific language image
echo -e "${YELLOW}Building $LANGUAGE image...${NC}"
IMAGE_NAME="petribench-$LANGUAGE"

if docker build -f "$DOCKERFILE_PATH" -t "$IMAGE_NAME" ./images/; then
    echo -e "${GREEN}✓ $LANGUAGE image built successfully${NC}"
else
    echo -e "${RED}✗ Failed to build $LANGUAGE image${NC}"
    exit 1
fi

echo ""

# Show image info
echo -e "${YELLOW}Image information:${NC}"
docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

echo ""

# Basic functionality test based on language
echo -e "${YELLOW}Testing basic functionality...${NC}"
case $LANGUAGE in
    python)
        if docker run --rm "$IMAGE_NAME" python3 -c "print('✓ Python working')" 2>/dev/null; then
            echo -e "${GREEN}✓ Python execution test passed${NC}"
        else
            echo -e "${RED}✗ Python execution test failed${NC}"
        fi
        ;;
    go)
        if docker run --rm "$IMAGE_NAME" /usr/local/bin/program >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Go compiled binary test passed${NC}"
        else
            echo -e "${RED}✗ Go compiled binary test failed${NC}"
        fi
        ;;
    node)
        if docker run --rm "$IMAGE_NAME" node -e "console.log('✓ Node.js working')" 2>/dev/null; then
            echo -e "${GREEN}✓ Node.js execution test passed${NC}"
        else
            echo -e "${RED}✗ Node.js execution test failed${NC}"
        fi
        ;;
    c)
        if docker run --rm "$IMAGE_NAME" /usr/local/bin/program >/dev/null 2>&1; then
            echo -e "${GREEN}✓ C binary execution test passed${NC}"
        else
            echo -e "${RED}✗ C binary execution test failed${NC}"
        fi
        ;;
    cpp)
        if docker run --rm "$IMAGE_NAME" /usr/local/bin/program >/dev/null 2>&1; then
            echo -e "${GREEN}✓ C++ binary execution test passed${NC}"
        else
            echo -e "${RED}✗ C++ binary execution test failed${NC}"
        fi
        ;;
    jdk)
        if docker run --rm "$IMAGE_NAME" java -cp /workspace Program >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Java JDK execution test passed${NC}"
        else
            echo -e "${RED}✗ Java JDK execution test failed${NC}"
        fi
        ;;
    jre)
        if docker run --rm "$IMAGE_NAME" java -version >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Java JRE test passed${NC}"
        else
            echo -e "${RED}✗ Java JRE test failed${NC}"
        fi
        ;;
    rust)
        if docker run --rm "$IMAGE_NAME" /usr/local/bin/program >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Rust binary execution test passed${NC}"
        else
            echo -e "${RED}✗ Rust binary execution test failed${NC}"
        fi
        ;;
    dotnet-sdk)
        if docker run --rm "$IMAGE_NAME" dotnet --version >/dev/null 2>&1; then
            echo -e "${GREEN}✓ .NET SDK test passed${NC}"
        else
            echo -e "${RED}✗ .NET SDK test failed${NC}"
        fi
        ;;
    dotnet-runtime)
        if docker run --rm "$IMAGE_NAME" dotnet --version >/dev/null 2>&1; then
            echo -e "${GREEN}✓ .NET Runtime test passed${NC}"
        else
            echo -e "${RED}✗ .NET Runtime test failed${NC}"
        fi
        ;;
esac

echo ""
echo -e "${GREEN}=== Build completed for $LANGUAGE! ===${NC}"
echo ""
echo "Image available: $IMAGE_NAME"
echo ""
echo "Next steps:"
echo "  - Test memory measurement: ./scripts/measure-memory.sh --mode test $LANGUAGE scripts/benchmarks/benchmark.*"
echo "  - Build all images: ./scripts/build-all.sh"
echo "  - Build base + all: ./scripts/build-base.sh"