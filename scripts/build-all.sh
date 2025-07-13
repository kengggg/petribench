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
if docker build -t petribench-base ./images/base/; then
    echo -e "${GREEN}✓ Base image built successfully${NC}"
else
    echo -e "${RED}✗ Failed to build base image${NC}"
    exit 1
fi

echo ""

# Build all language images
LANGUAGES=("python" "go" "node" "c" "java" "rust" "csharp")

for LANG in "${LANGUAGES[@]}"; do
    echo -e "${YELLOW}Building $LANG image...${NC}"
    if docker build -t petribench-$LANG ./images/$LANG/; then
        echo -e "${GREEN}✓ $LANG image built successfully${NC}"
    else
        echo -e "${RED}✗ Failed to build $LANG image${NC}"
        exit 1
    fi
    echo ""
done

# Show image sizes
echo -e "${YELLOW}Image sizes:${NC}"
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
echo 'fn main() { println!("Test"); }' > /tmp/test.rs
echo 'public class Test { public static void main(String[] args) { System.out.println("Test"); } }' > /tmp/Test.java

# Test each language
for LANG in "${LANGUAGES[@]}"; do
    echo -n "$LANG image: "
    case $LANG in
        python)
            if docker run --rm -v /tmp/test.py:/app/test.py petribench-python python3 test.py >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Python execution working${NC}"
            else
                echo -e "${RED}✗ Python execution failed${NC}"
            fi
            ;;
        go)
            if docker run --rm -v /tmp/test.go:/app/test.go petribench-go go run test.go >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Go execution working${NC}"
            else
                echo -e "${RED}✗ Go execution failed${NC}"
            fi
            ;;
        node)
            if docker run --rm -v /tmp/test.js:/app/test.js petribench-node node test.js >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Node.js execution working${NC}"
            else
                echo -e "${RED}✗ Node.js execution failed${NC}"
            fi
            ;;
        c)
            if docker run --rm -v /tmp/test.c:/app/test.c petribench-c sh -c "gcc test.c -o test && ./test" >/dev/null 2>&1; then
                echo -e "${GREEN}✓ C compilation and execution working${NC}"
            else
                echo -e "${RED}✗ C compilation/execution failed${NC}"
            fi
            ;;
        java)
            if docker run --rm -v /tmp/Test.java:/app/Test.java petribench-java sh -c "javac Test.java && java Test" >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Java compilation and execution working${NC}"
            else
                echo -e "${RED}✗ Java compilation/execution failed${NC}"
            fi
            ;;
        rust)
            if docker run --rm -v /tmp/test.rs:/app/test.rs petribench-rust sh -c "rustc test.rs && ./test" >/dev/null 2>&1; then
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

echo ""
echo -e "${GREEN}=== Build complete! ===${NC}"
echo ""
echo "Available images:"
echo "  petribench-base     - Base image with measurement tools"
echo "  petribench-python   - Python 3.12 runtime"
echo "  petribench-go       - Go 1.21+ compiler"
echo "  petribench-node     - Node.js 20 LTS runtime"
echo "  petribench-c        - GCC 13 C/C++ compilers"
echo "  petribench-java     - OpenJDK 17 runtime"
echo "  petribench-rust     - Rust 1.71+ compiler"
echo "  petribench-csharp   - .NET 8 runtime"
echo ""
echo "Next steps:"
echo "  1. Test RSS measurement: ./scripts/test-rss-measurement.sh"
echo "  2. Run examples: ./examples/measure-rss.sh python examples/benchmark.py"
echo "  3. Tag for fizzbuzzmem: docker tag petribench-python fizzbuzz-python"