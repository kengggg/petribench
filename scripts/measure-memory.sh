#!/bin/bash

# Unified memory measurement tool for PetriBench
# Supports RSS, PSS, USS measurement with multiple methods
# Works with local and registry images

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
MODE="demo"
METHOD="all"
LANGUAGE=""
SCRIPT_FILE=""
USE_LOCAL=true
VERBOSE=false

# Available languages
AVAILABLE_LANGUAGES=("python" "go" "node" "c" "cpp" "jdk" "jre" "rust" "dotnet-sdk" "dotnet-runtime")

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] <language> [script_file]"
    echo ""
    echo "DESCRIPTION:"
    echo "  Unified memory measurement tool supporting RSS, PSS, and USS metrics"
    echo "  with multiple measurement methods for PetriBench containers."
    echo ""
    echo "OPTIONS:"
    echo "  --mode MODE       Measurement mode: demo, test, benchmark (default: demo)"
    echo "  --method METHOD   Measurement method: rss, pss, uss, all (default: all)"
    echo "  --local           Use local images (petribench-X) (default)"
    echo "  --registry        Use registry images (ghcr.io/kengggg/petribench-X)"
    echo "  --verbose         Show detailed output"
    echo "  --help            Show this help message"
    echo ""
    echo "MODES:"
    echo "  demo      - Simple measurement demonstration"
    echo "  test      - Compatibility testing (multiple runs)"
    echo "  benchmark - Performance benchmarking with analysis"
    echo ""
    echo "METHODS:"
    echo "  rss       - RSS via GNU time (basic memory usage)"
    echo "  pss       - PSS via smem2 (proportional set size)"
    echo "  uss       - USS via /proc (unique set size)"
    echo "  all       - All measurement methods"
    echo ""
    echo "AVAILABLE LANGUAGES:"
    for lang in "${AVAILABLE_LANGUAGES[@]}"; do
        echo "  $lang"
    done
    echo ""
    echo "EXAMPLES:"
    echo "  $0 python                                 # Auto-detect benchmark.py"
    echo "  $0 python custom-script.py               # Use custom script file"
    echo "  $0 --mode test python                    # Test mode with auto-detection"
    echo "  $0 --method rss go                       # RSS measurement with auto-detection"
    echo "  $0 --local rust                          # Local image with auto-detection"
    echo "  $0 --registry --verbose node benchmark.js # Registry image with custom file"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --mode)
            MODE="$2"
            shift 2
            ;;
        --method)
            METHOD="$2"
            shift 2
            ;;
        --local)
            USE_LOCAL=true
            shift
            ;;
        --registry)
            USE_LOCAL=false
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        -*)
            echo -e "${RED}Error: Unknown option $1${NC}"
            echo ""
            show_usage
            exit 1
            ;;
        *)
            if [ -z "$LANGUAGE" ]; then
                LANGUAGE="$1"
            elif [ -z "$SCRIPT_FILE" ]; then
                SCRIPT_FILE="$1"
            else
                echo -e "${RED}Error: Too many arguments${NC}"
                echo ""
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate required arguments
if [ -z "$LANGUAGE" ]; then
    echo -e "${RED}Error: Language parameter required${NC}"
    echo ""
    show_usage
    exit 1
fi

# Validate language
if [[ ! " ${AVAILABLE_LANGUAGES[*]} " =~ " $LANGUAGE " ]]; then
    echo -e "${RED}Error: Unknown language '$LANGUAGE'${NC}"
    echo ""
    show_usage
    exit 1
fi

# Auto-detect script file if not provided
if [ -z "$SCRIPT_FILE" ]; then
    echo -e "${YELLOW}No script file specified, attempting auto-detection...${NC}"
    
    # Define benchmark file mappings for each language
    case $LANGUAGE in
        python) SCRIPT_FILE="scripts/benchmarks/benchmark.py" ;;
        go) SCRIPT_FILE="scripts/benchmarks/benchmark.go" ;;
        node) SCRIPT_FILE="scripts/benchmarks/benchmark.js" ;;
        c) SCRIPT_FILE="scripts/benchmarks/benchmark.c" ;;
        cpp) SCRIPT_FILE="scripts/benchmarks/benchmark.cpp" ;;
        jdk) SCRIPT_FILE="scripts/benchmarks/Benchmark.java" ;;
        jre) SCRIPT_FILE="scripts/benchmarks/Benchmark.class" ;;
        rust) SCRIPT_FILE="scripts/benchmarks/benchmark.rs" ;;
        dotnet-sdk) SCRIPT_FILE="scripts/benchmarks/Benchmark.cs" ;;
        dotnet-runtime) SCRIPT_FILE="scripts/benchmarks/Benchmark.dll" ;;
        *)
            echo -e "${RED}Error: No auto-detection mapping for language '$LANGUAGE'${NC}"
            echo "Please specify the script file manually."
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}Auto-detected: $SCRIPT_FILE${NC}"
fi

# Validate script file exists
if [ ! -f "$SCRIPT_FILE" ]; then
    echo -e "${RED}Error: Script file '$SCRIPT_FILE' not found${NC}"
    if [[ "$SCRIPT_FILE" == scripts/benchmarks/* ]]; then
        echo "Available benchmark files:"
        ls scripts/benchmarks/ 2>/dev/null || echo "  (benchmarks directory not found)"
    fi
    exit 1
fi

# Validate mode
if [[ ! " demo test benchmark " =~ " $MODE " ]]; then
    echo -e "${RED}Error: Unknown mode '$MODE'${NC}"
    echo ""
    show_usage
    exit 1
fi

# Validate method
if [[ ! " rss pss uss all " =~ " $METHOD " ]]; then
    echo -e "${RED}Error: Unknown method '$METHOD'${NC}"
    echo ""
    show_usage
    exit 1
fi


# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
    exit 1
fi

# Change to project root if script file is relative to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# If script file starts with scripts/benchmarks/, we need to be in project root
if [[ "$SCRIPT_FILE" == scripts/benchmarks/* ]]; then
    cd "$PROJECT_ROOT"
    # Verify the benchmark file exists from project root
    if [ ! -f "$SCRIPT_FILE" ]; then
        echo -e "${RED}Error: Benchmark file '$SCRIPT_FILE' not found from project root${NC}"
        echo "Available benchmark files:"
        ls scripts/benchmarks/ 2>/dev/null || echo "  (benchmarks directory not found)"
        exit 1
    fi
fi

# Determine image name
if [ "$USE_LOCAL" = true ]; then
    IMAGE_NAME="petribench-$LANGUAGE:latest"
    REGISTRY_IMAGE="ghcr.io/kengggg/petribench-$LANGUAGE:latest"
else
    IMAGE_NAME="ghcr.io/kengggg/petribench-$LANGUAGE:latest"
    REGISTRY_IMAGE="$IMAGE_NAME"
fi

# Function to check and ensure image availability
ensure_image() {
    if [ "$USE_LOCAL" = true ]; then
        if docker image inspect "$IMAGE_NAME" &>/dev/null; then
            [ "$VERBOSE" = true ] && echo "Using local image: $IMAGE_NAME"
            return 0
        else
            echo -e "${YELLOW}Local image not found. Checking registry image...${NC}"
            if docker image inspect "$REGISTRY_IMAGE" &>/dev/null; then
                IMAGE_NAME="$REGISTRY_IMAGE"
                [ "$VERBOSE" = true ] && echo "Using registry image: $IMAGE_NAME"
                return 0
            else
                echo -e "${YELLOW}Attempting to pull registry image...${NC}"
                if docker pull "$REGISTRY_IMAGE" 2>/dev/null; then
                    IMAGE_NAME="$REGISTRY_IMAGE"
                    echo "Pulled registry image: $IMAGE_NAME"
                    return 0
                else
                    echo -e "${RED}Error: No image available. Build locally with:${NC}"
                    echo "  ./scripts/build-individual.sh $LANGUAGE"
                    exit 1
                fi
            fi
        fi
    else
        if docker image inspect "$IMAGE_NAME" &>/dev/null; then
            [ "$VERBOSE" = true ] && echo "Using registry image: $IMAGE_NAME"
            return 0
        else
            echo -e "${YELLOW}Attempting to pull registry image...${NC}"
            if docker pull "$IMAGE_NAME" 2>/dev/null; then
                echo "Pulled registry image: $IMAGE_NAME"
                return 0
            else
                echo -e "${RED}Error: Could not pull registry image${NC}"
                exit 1
            fi
        fi
    fi
}

# Function to determine container file path and command based on language
get_container_mapping() {
    local language="$1"
    local script_file="$2"
    local basename_file=$(basename "$script_file")
    
    # Map local file to expected container path and determine execution method
    case $language in
        python)
            CONTAINER_PATH="/workspace/$basename_file"
            EXEC_COMMAND="" # Uses default container CMD
            ;;
        go)
            CONTAINER_PATH="/workspace/$basename_file"  
            EXEC_COMMAND=""
            ;;
        node)
            CONTAINER_PATH="/workspace/$basename_file"
            EXEC_COMMAND=""
            ;;
        c)
            CONTAINER_PATH="/workspace/$basename_file"
            EXEC_COMMAND=""
            ;;
        cpp)
            CONTAINER_PATH="/workspace/$basename_file"
            EXEC_COMMAND=""
            ;;
        jdk)
            CONTAINER_PATH="/workspace/$basename_file"
            EXEC_COMMAND=""
            ;;
        jre)
            # JRE expects .class files, but we might have .java - let container handle it
            CONTAINER_PATH="/workspace/$basename_file"
            EXEC_COMMAND=""
            ;;
        rust)
            CONTAINER_PATH="/workspace/$basename_file"
            EXEC_COMMAND=""
            ;;
        dotnet-sdk)
            CONTAINER_PATH="/workspace/$basename_file"
            EXEC_COMMAND=""
            ;;
        dotnet-runtime)
            CONTAINER_PATH="/workspace/$basename_file"
            EXEC_COMMAND=""
            ;;
        *)
            echo "Unknown language: $language" >&2
            return 1
            ;;
    esac
}

# Function to run RSS measurement
measure_rss() {
    local output_var="$1"
    [ "$VERBOSE" = true ] && echo "Running RSS measurement via GNU time..."
    
    # Get container path mapping
    get_container_mapping "$LANGUAGE" "$SCRIPT_FILE"
    
    local result=$(docker run --rm \
        -v "$(pwd)/$SCRIPT_FILE:$CONTAINER_PATH" \
        --memory=512m --cpus=1.0 \
        "$IMAGE_NAME" 2>&1)
    
    eval "$output_var='$result'"
}

# Function to run PSS/USS measurement
measure_pss_uss() {
    local output_var="$1"
    [ "$VERBOSE" = true ] && echo "Running PSS/USS measurement via smem2 and /proc..."
    
    # Get container path mapping
    get_container_mapping "$LANGUAGE" "$SCRIPT_FILE"
    local basename_file=$(basename "$SCRIPT_FILE")
    
    local result=$(docker run --rm \
        -v "$(pwd)/$SCRIPT_FILE:$CONTAINER_PATH" \
        --memory=512m --cpus=1.0 \
        "$IMAGE_NAME" \
        sh -c "
            # Start the program in background by leveraging container's default execution
            # Use the same execution path as the container would normally use
            case \"$LANGUAGE\" in
                python) python3 /workspace/$basename_file >/dev/null 2>&1 & ;;
                go) go run /workspace/$basename_file >/dev/null 2>&1 & ;;
                node) node /workspace/$basename_file >/dev/null 2>&1 & ;;
                c) gcc /workspace/$basename_file -o /workspace/program && /workspace/program >/dev/null 2>&1 & ;;
                cpp) g++ /workspace/$basename_file -o /workspace/program && /workspace/program >/dev/null 2>&1 & ;;
                jdk) javac /workspace/$basename_file && java -cp /workspace \$(basename \"$basename_file\" .java) >/dev/null 2>&1 & ;;
                jre) java -cp /workspace \$(basename \"$basename_file\" .class) >/dev/null 2>&1 & ;;
                rust) rustc /workspace/$basename_file && ./\$(basename \"$basename_file\" .rs) >/dev/null 2>&1 & ;;
                dotnet-sdk) cd /workspace && dotnet new console -n test --force && cp $basename_file test/Program.cs && cd test && dotnet run >/dev/null 2>&1 & ;;
                dotnet-runtime) dotnet /workspace/$basename_file >/dev/null 2>&1 & ;;
                *) echo 'Unknown language for PSS/USS measurement' >&2; exit 1 ;;
            esac
            PID=\$!
            
            # Wait a moment for startup
            sleep 0.1
            
            echo '=== smem2 measurement ==='
            smem2 -P \$PID -c pss,uss,rss 2>/dev/null || echo 'Process finished too quickly for smem2'
            
            echo '=== /proc/PID/smaps_rollup ==='
            if [ -r /proc/\$PID/smaps_rollup ]; then
                grep -E 'Pss:|Private_Clean:|Private_Dirty:|Rss:' /proc/\$PID/smaps_rollup
            else
                echo 'Process finished too quickly for /proc measurement'
            fi
            
            # Wait for completion
            wait \$PID 2>/dev/null || true
        " 2>/dev/null)
    
    eval "$output_var='$result'"
}

# Function to extract RSS value
extract_rss() {
    local output="$1"
    local rss_line=$(echo "$output" | grep "Maximum resident set size" || echo "")
    if [ -n "$rss_line" ]; then
        echo "$rss_line" | grep -oE '[0-9]+' | head -1
    else
        echo "0"
    fi
}

# Function to extract PSS/USS values
extract_pss_uss() {
    local output="$1"
    local pss=$(echo "$output" | grep -E "Pss:" | grep -oE '[0-9]+' | head -1 || echo "0")
    local uss=$(echo "$output" | grep -E "Private_Clean:|Private_Dirty:" | grep -oE '[0-9]+' | awk '{sum+=$1} END {print sum+0}')
    echo "$pss $uss"
}

# Main execution
echo -e "${BLUE}=== PetriBench Memory Measurement ===${NC}"
echo "Language: $LANGUAGE"
echo "Script: $SCRIPT_FILE"
echo "Mode: $MODE"
echo "Method: $METHOD"
echo ""

# Ensure image is available
ensure_image

# Get container path mapping and show it
get_container_mapping "$LANGUAGE" "$SCRIPT_FILE"

echo "Using image: $IMAGE_NAME"
[ "$VERBOSE" = true ] && echo "Container path mapping: $(pwd)/$SCRIPT_FILE → $CONTAINER_PATH"
echo ""

# Execute based on mode
case $MODE in
    demo)
        echo -e "${YELLOW}=== Demo Mode ===${NC}"
        echo ""
        
        if [[ "$METHOD" == "all" || "$METHOD" == "rss" ]]; then
            echo -e "${YELLOW}RSS Measurement (GNU time):${NC}"
            measure_rss rss_output
            rss_kb=$(extract_rss "$rss_output")
            echo "RSS (Resident Set Size): $rss_kb KB"
            [ "$VERBOSE" = true ] && echo "Full RSS output:" && echo "$rss_output"
            echo ""
        fi
        
        if [[ "$METHOD" == "all" || "$METHOD" == "pss" || "$METHOD" == "uss" ]]; then
            echo -e "${YELLOW}PSS/USS Measurement (smem2 + /proc):${NC}"
            measure_pss_uss pss_uss_output
            read pss_kb uss_kb <<< $(extract_pss_uss "$pss_uss_output")
            echo "PSS (Proportional Set Size): $pss_kb KB"
            echo "USS (Unique Set Size): $uss_kb KB"
            [ "$VERBOSE" = true ] && echo "Full PSS/USS output:" && echo "$pss_uss_output"
            echo ""
        fi
        
        echo -e "${GREEN}=== Memory Metrics Explained ===${NC}"
        echo "RSS: Total memory in RAM (includes shared libraries)"
        echo "PSS: Shared memory divided by number of processes sharing it"
        echo "USS: Memory unique to this process only"
        ;;
        
    test)
        echo -e "${YELLOW}=== Test Mode (Compatibility & Consistency) ===${NC}"
        echo ""
        
        # Test 1: Basic functionality
        echo -e "${YELLOW}Test 1: Basic functionality${NC}"
        measure_rss test_output
        rss_kb=$(extract_rss "$test_output")
        
        if [ "$rss_kb" -gt 0 ]; then
            echo -e "${GREEN}✓ RSS measurement working: $rss_kb KB${NC}"
        else
            echo -e "${RED}✗ RSS measurement failed${NC}"
            exit 1
        fi
        
        # Test 2: Consistency check (3 runs)
        echo ""
        echo -e "${YELLOW}Test 2: Measurement consistency (3 runs)${NC}"
        measurements=()
        for i in {1..3}; do
            echo -n "Run $i... "
            measure_rss run_output
            rss=$(extract_rss "$run_output")
            measurements+=($rss)
            echo "${rss} KB"
        done
        
        # Calculate variance
        min=${measurements[0]}
        max=${measurements[0]}
        for measurement in "${measurements[@]}"; do
            if [ $measurement -lt $min ]; then min=$measurement; fi
            if [ $measurement -gt $max ]; then max=$measurement; fi
        done
        
        variance=$((max - min))
        echo ""
        echo "Measurements: ${measurements[@]} KB"
        echo "Variance: $variance KB (Min: $min KB, Max: $max KB)"
        
        if [ $variance -lt $((min / 10)) ]; then
            echo -e "${GREEN}✓ Measurements are consistent (variance < 10%)${NC}"
        else
            echo -e "${YELLOW}⚠ High variance detected. This might indicate system load.${NC}"
        fi
        
        echo ""
        echo -e "${GREEN}✓ All compatibility tests passed!${NC}"
        ;;
        
    benchmark)
        echo -e "${YELLOW}=== Benchmark Mode ===${NC}"
        echo ""
        
        # Run multiple measurements for statistical analysis
        echo "Running 5 measurement cycles..."
        rss_measurements=()
        
        for i in {1..5}; do
            echo -n "Cycle $i... "
            measure_rss bench_output
            rss=$(extract_rss "$bench_output")
            rss_measurements+=($rss)
            echo "${rss} KB"
            sleep 1  # Brief pause between measurements
        done
        
        # Statistical analysis
        echo ""
        echo -e "${YELLOW}=== Statistical Analysis ===${NC}"
        
        # Calculate statistics
        total=0
        min=${rss_measurements[0]}
        max=${rss_measurements[0]}
        
        for measurement in "${rss_measurements[@]}"; do
            total=$((total + measurement))
            if [ $measurement -lt $min ]; then min=$measurement; fi
            if [ $measurement -gt $max ]; then max=$measurement; fi
        done
        
        average=$((total / ${#rss_measurements[@]}))
        variance=$((max - min))
        
        echo "All measurements: ${rss_measurements[@]} KB"
        echo "Average RSS: $average KB"
        echo "Minimum RSS: $min KB"
        echo "Maximum RSS: $max KB"
        echo "Variance: $variance KB"
        echo "Coefficient of variation: $(( (variance * 100) / average ))%"
        echo ""
        
        if [ $variance -lt $((average / 20)) ]; then
            echo -e "${GREEN}✓ Excellent consistency (CV < 5%)${NC}"
        elif [ $variance -lt $((average / 10)) ]; then
            echo -e "${GREEN}✓ Good consistency (CV < 10%)${NC}"
        else
            echo -e "${YELLOW}⚠ Moderate variance detected (CV ≥ 10%)${NC}"
        fi
        ;;
esac

echo ""
echo -e "${GREEN}=== Measurement Complete ===${NC}"
echo ""
echo "Next steps:"
echo "  - Build other languages: ./scripts/build-individual.sh [language]"
echo "  - Test all images: ./scripts/build-all.sh"
echo "  - Change measurement method: $0 --method [rss|pss|uss] $LANGUAGE $SCRIPT_FILE"