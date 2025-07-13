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

# Build base image first
echo -e "${YELLOW}Building base image...${NC}"
if docker build -f ./images/Dockerfile.base -t petribench-base ./images/; then
    echo -e "${GREEN}✓ Base image built successfully${NC}"
else
    echo -e "${RED}✗ Failed to build base image${NC}"
    exit 1
fi

echo ""

# Build all language images (aligned with issue #1)
LANGUAGES=("python" "go" "node" "c" "cpp" "java-jdk" "java-jre" "rust" "dotnet-sdk" "dotnet-runtime")

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

# Test language images with simple scripts
echo 'print("Test")' > /tmp/test.py
echo 'package main; import "fmt"; func main() { fmt.Println("Test") }' > /tmp/test.go
echo 'console.log("Test")' > /tmp/test.js
echo '#include <stdio.h>; int main() { printf("Test\\n"); return 0; }' > /tmp/test.c
echo '#include <iostream>; int main() { std::cout << "Test" << std::endl; return 0; }' > /tmp/test.cpp
echo 'fn main() { println!("Test"); }' > /tmp/test.rs
echo 'public class Test { public static void main(String[] args) { System.out.println("Test"); } }' > /tmp/Test.java

# Test each language
for LANG in "${LANGUAGES[@]}"; do
    echo -n "$LANG image: "
    case $LANG in
        python)
            if docker run --rm -v /tmp/test.py:/workspace/test.py petribench-python python3 test.py >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Python execution working${NC}"
            else
                echo -e "${RED}✗ Python execution failed${NC}"
            fi
            ;;
        go)
            if docker run --rm -v /tmp/test.go:/workspace/test.go petribench-go go run test.go >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Go execution working${NC}"
            else
                echo -e "${RED}✗ Go execution failed${NC}"
            fi
            ;;
        node)
            if docker run --rm -v /tmp/test.js:/workspace/test.js petribench-node node test.js >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Node.js execution working${NC}"
            else
                echo -e "${RED}✗ Node.js execution failed${NC}"
            fi
            ;;
        c)
            if docker run --rm -v /tmp/test.c:/workspace/test.c petribench-c sh -c "gcc test.c -o test && ./test" >/dev/null 2>&1; then
                echo -e "${GREEN}✓ C compilation and execution working${NC}"
            else
                echo -e "${RED}✗ C compilation/execution failed${NC}"
            fi
            ;;
        cpp)
            if docker run --rm -v /tmp/test.cpp:/workspace/test.cpp petribench-cpp sh -c "g++ test.cpp -o test && ./test" >/dev/null 2>&1; then
                echo -e "${GREEN}✓ C++ compilation and execution working${NC}"
            else
                echo -e "${RED}✗ C++ compilation/execution failed${NC}"
            fi
            ;;
        java)
            if docker run --rm -v /tmp/Test.java:/workspace/Test.java petribench-java sh -c "javac Test.java && java Test" >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Java compilation and execution working${NC}"
            else
                echo -e "${RED}✗ Java compilation/execution failed${NC}"
            fi
            ;;
        rust)
            if docker run --rm -v /tmp/test.rs:/workspace/test.rs petribench-rust sh -c "rustc test.rs && ./test" >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Rust compilation and execution working${NC}"
            else
                echo -e "${RED}✗ Rust compilation/execution failed${NC}"
            fi
            ;;
        csharp)
            echo -e "${YELLOW}⚠ C# runtime only (requires pre-compiled .dll)${NC}"
            ;;
    esac
done

# Cleanup test files
rm -f /tmp/test.* /tmp/Test.*

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
echo "Available images (Issue #1 specification):"
echo "  petribench-base     - Base image with procfs tools"
echo "  petribench-python   - Python 3.12 minimal runtime"
echo "  petribench-go       - Go 1.21+ compiler"
echo "  petribench-node     - Node.js 20 LTS runtime"
echo "  petribench-c        - GCC 13 C compiler"
echo "  petribench-cpp      - G++ 13 C++ compiler"
echo "  petribench-java     - OpenJDK 21 runtime"
echo "  petribench-rust     - Rust 1.71+ compiler"
echo "  petribench-csharp   - .NET 8 runtime"
echo ""
echo "Next steps:"
echo "  1. Test RSS measurement: ./scripts/test-rss-measurement.sh"
echo "  2. Run examples: ./examples/measure-rss.sh python examples/benchmark.py"
echo "  3. Publish to GHCR: gh workflow run build-publish.yml"
echo "  4. Tag for fizzbuzzmem: docker tag petribench-python benchmark-python"