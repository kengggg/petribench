#!/bin/bash

# Build all PetriBench images locally for development and testing

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Building PetriBench Images Locally ===${NC}"
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
echo -e "${YELLOW}Building base image...${NC}"
if docker build -f ./images/Dockerfile.base -t petribench-base ./images/; then
    echo -e "${GREEN}✓ Base image built successfully${NC}"
else
    echo -e "${RED}✗ Failed to build base image${NC}"
    exit 1
fi

echo ""

# Build all language images (aligned with current Dockerfiles)
LANGUAGES=("python" "go" "node" "c" "cpp" "jdk" "jre" "rust" "dotnet-sdk" "dotnet-runtime")

for LANG in "${LANGUAGES[@]}"; do
    echo -e "${YELLOW}Building $LANG image...${NC}"
    if docker build -f ./images/Dockerfile.$LANG -t petribench-$LANG ./images/; then
        echo -e "${GREEN}✓ $LANG image built successfully${NC}"
    else
        echo -e "${RED}✗ Failed to build $LANG image${NC}"
        exit 1
    fi
    echo ""
done

# Show image sizes with targets (issue #1 requirements)
echo -e "${YELLOW}Image sizes (with targets):${NC}"
echo -e "${YELLOW}Targets: Base <40MB, Python/Node <100MB, Go <60MB, Others <250MB${NC}"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(REPOSITORY|petribench-)"

echo ""

# Test basic functionality
echo -e "${YELLOW}Testing basic functionality...${NC}"

# Test base image
echo -n "Base image tools: "
if docker run --rm petribench-base /usr/bin/time --version >/dev/null 2>&1; then
    echo -e "${GREEN}✓ GNU time available${NC}"
else
    echo -e "${RED}✗ GNU time not working${NC}"
fi

# Use actual benchmark files from scripts/benchmarks/ directory

# Pre-compiled files used directly from scripts/benchmarks/ - no copying needed

# Test each language
for LANG in "${LANGUAGES[@]}"; do
    echo -n "$LANG image: "
    case $LANG in
        python)
            if docker run --rm -v ./scripts/benchmarks/benchmark.py:/workspace/benchmark.py petribench-python >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Python execution working${NC}"
            else
                echo -e "${RED}✗ Python execution failed${NC}"
            fi
            ;;
        go)
            if docker run --rm -v ./scripts/benchmarks/benchmark.go:/workspace/benchmark.go petribench-go >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Go execution working${NC}"
            else
                echo -e "${RED}✗ Go execution failed${NC}"
            fi
            ;;
        node)
            if docker run --rm -v ./scripts/benchmarks/benchmark.js:/workspace/benchmark.js petribench-node >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Node.js execution working${NC}"
            else
                echo -e "${RED}✗ Node.js execution failed${NC}"
            fi
            ;;
        c)
            if docker run --rm -v ./scripts/benchmarks/benchmark.c:/workspace/benchmark.c petribench-c >/dev/null 2>&1; then
                echo -e "${GREEN}✓ C compilation and execution working${NC}"
            else
                echo -e "${RED}✗ C compilation/execution failed${NC}"
            fi
            ;;
        cpp)
            if docker run --rm -v ./scripts/benchmarks/benchmark.cpp:/workspace/benchmark.cpp petribench-cpp >/dev/null 2>&1; then
                echo -e "${GREEN}✓ C++ compilation and execution working${NC}"
            else
                echo -e "${RED}✗ C++ compilation/execution failed${NC}"
            fi
            ;;
        jdk)
            if docker run --rm -v ./scripts/benchmarks/Benchmark.java:/workspace/Benchmark.java petribench-jdk >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Java JDK compilation and execution working${NC}"
            else
                echo -e "${RED}✗ Java JDK compilation/execution failed${NC}"
            fi
            ;;
        jre)
            if docker run --rm -v ./scripts/benchmarks/Benchmark.class:/workspace/Benchmark.class petribench-jre >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Java JRE execution working${NC}"
            else
                echo -e "${RED}✗ Java JRE execution failed${NC}"
            fi
            ;;
        rust)
            if docker run --rm -v ./scripts/benchmarks/benchmark.rs:/workspace/benchmark.rs petribench-rust >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Rust compilation and execution working${NC}"
            else
                echo -e "${RED}✗ Rust compilation/execution failed${NC}"
            fi
            ;;
        dotnet-sdk)
            if docker run --rm -v ./scripts/benchmarks/Benchmark.cs:/workspace/Benchmark.cs petribench-dotnet-sdk >/dev/null 2>&1; then
                echo -e "${GREEN}✓ .NET SDK working${NC}"
            else
                echo -e "${RED}✗ .NET SDK failed${NC}"
            fi
            ;;
        dotnet-runtime)
            if docker run --rm -v ./scripts/benchmarks/Benchmark.dll:/workspace/Benchmark.dll -v ./scripts/benchmarks/Benchmark.runtimeconfig.json:/workspace/Benchmark.runtimeconfig.json petribench-dotnet-runtime >/dev/null 2>&1; then
                echo -e "${GREEN}✓ .NET Runtime working${NC}"
            else
                echo -e "${RED}✗ .NET Runtime failed${NC}"
            fi
            ;;
    esac
done

# Cleanup test files
# Cleanup no longer needed - using actual benchmark files

# Size monitoring (issue #1 requirement)
echo ""
echo -e "${YELLOW}=== Size Analysis (Issue #1 Targets) ===${NC}"
echo "Checking image sizes against targets..."

# Get actual sizes and check targets
BASE_SIZE=$(docker images petribench-base --format "{{.Size}}" | head -1)
PYTHON_SIZE=$(docker images petribench-python --format "{{.Size}}" | head -1)
NODE_SIZE=$(docker images petribench-node --format "{{.Size}}" | head -1)
GO_SIZE=$(docker images petribench-go --format "{{.Size}}" | head -1)

echo "Target compliance:"
echo "  Base: $BASE_SIZE (target: <40MB compressed)"
echo "  Python: $PYTHON_SIZE (target: <100MB)"
echo "  Node: $NODE_SIZE (target: <100MB)"
echo "  Go: $GO_SIZE (target: <60MB)"
echo "  Other compiled languages (target: <250MB)"

echo ""
echo -e "${GREEN}=== Build complete! ===${NC}"
echo ""
echo "Available images:"
echo "  petribench-base            - Base image with procfs tools"
echo "  petribench-python          - Python 3.12 minimal runtime"
echo "  petribench-go              - Go 1.21+ compiler"
echo "  petribench-node            - Node.js 20 LTS runtime"
echo "  petribench-c               - GCC 13 C compiler"
echo "  petribench-cpp             - G++ 13 C++ compiler"
echo "  petribench-jdk             - OpenJDK 21 JDK (development)"
echo "  petribench-jre             - OpenJDK 21 JRE (runtime)"
echo "  petribench-rust            - Rust 1.71+ compiler"
echo "  petribench-dotnet-sdk      - .NET 8 SDK (development)"
echo "  petribench-dotnet-runtime  - .NET 8 Runtime"
echo ""
echo "Next steps:"
echo "  1. Test memory measurement: ./scripts/measure-memory.sh --mode test python scripts/benchmarks/benchmark.py"
echo "  2. Build individual images: ./scripts/build-individual.sh [language]"
echo "  3. Build base + all: ./scripts/build-base.sh"
echo "  4. Publish to GHCR: gh workflow run build-all.yml"