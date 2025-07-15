#!/bin/sh
# Enhanced measure_memory.sh - Drop-in replacement for smem2
# Provides PSS, USS, RSS memory measurements via direct /proc/smaps_rollup access
# Compatible with smem2 command line interface for seamless replacement

set -e

# Default values
PID=""
COLUMNS="pss,uss,rss"
FORMAT="text"
VERBOSE=false
HELP=false

# Parse command line arguments to match smem2 interface
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -P|--pid)
                if [ -n "$2" ] && [ "$2" != "${2#[0-9]}" ]; then
                    PID="$2"
                    shift 2
                else
                    echo "Error: -P requires a numeric PID argument" >&2
                    exit 1
                fi
                ;;
            -c|--columns)
                if [ -n "$2" ]; then
                    COLUMNS="$2"
                    shift 2
                else
                    echo "Error: -c requires a columns argument" >&2
                    exit 1
                fi
                ;;
            --format)
                if [ -n "$2" ]; then
                    FORMAT="$2"
                    shift 2
                else
                    echo "Error: --format requires an argument" >&2
                    exit 1
                fi
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                HELP=true
                shift
                ;;
            -*)
                echo "Error: Unknown option $1" >&2
                exit 1
                ;;
            *)
                # If no -P flag was used, treat first positional arg as PID
                if [ -z "$PID" ] && [ "$1" != "${1#[0-9]}" ]; then
                    PID="$1"
                else
                    echo "Error: Unexpected argument: $1" >&2
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

# Show help message
show_help() {
    cat << 'EOF'
measure_memory - Direct /proc/smaps_rollup memory measurement tool

SYNOPSIS
    measure_memory -P <PID> [-c <columns>] [--format <format>] [-v] [-h]
    measure_memory <PID> [options...]

DESCRIPTION
    Drop-in replacement for smem2 providing PSS, USS, and RSS memory measurements
    via direct kernel /proc/smaps_rollup access. Zero dependencies, maximum performance.

OPTIONS
    -P, --pid <PID>         Process ID to measure (required)
    -c, --columns <cols>    Comma-separated columns: pss,uss,rss (default: pss,uss,rss)  
    --format <format>       Output format: text, json (default: text)
    -v, --verbose           Enable verbose output with debugging info
    -h, --help              Show this help message

COLUMNS
    pss     Proportional Set Size (shared memory divided by sharing processes)
    uss     Unique Set Size (memory unique to this process only)
    rss     Resident Set Size (total memory in RAM, including shared)

FORMATS
    text    Human-readable format with units (default)
    json    JSON format: {"pss":1234,"uss":5678,"rss":9012}

EXAMPLES
    # Basic usage (same as smem2 -P 1234 -c pss,uss,rss)
    measure_memory -P 1234
    
    # JSON output (same as smem2 -P 1234 -c pss,uss,rss --format json)
    measure_memory -P 1234 --format json
    
    # Specific columns only
    measure_memory -P 1234 -c pss,uss
    
    # Positional PID argument
    measure_memory 1234

COMPATIBILITY
    Full command-line compatibility with smem2 for seamless replacement.
    Uses same /proc/smaps_rollup data source as smem2 for identical accuracy.

EXIT CODES
    0       Success
    1       Invalid arguments or options
    2       Process not found or permission denied
    3       /proc/smaps_rollup not available (old kernel)

EOF
}

# Validate process exists and is accessible
validate_pid() {
    if [ -z "$PID" ]; then
        echo "Error: Process ID required. Use -P <PID> or provide PID as argument" >&2
        exit 1
    fi
    
    if [ ! -d "/proc/$PID" ]; then
        echo "Error: Process $PID not found" >&2
        exit 2
    fi
    
    if [ ! -r "/proc/$PID/smaps_rollup" ]; then
        echo "Error: Cannot read /proc/$PID/smaps_rollup (permission denied or kernel too old)" >&2
        exit 2
    fi
}

# Extract memory metrics from /proc/PID/smaps_rollup
extract_metrics() {
    local smaps="/proc/$PID/smaps_rollup"
    
    [ "$VERBOSE" = true ] && echo "Reading $smaps..." >&2
    
    # Extract raw values in kB
    PSS_KB=$(grep '^Pss:' "$smaps" | awk '{print $2}' || echo "0")
    RSS_KB=$(grep '^Rss:' "$smaps" | awk '{print $2}' || echo "0")
    
    # Calculate USS as sum of Private_Clean + Private_Dirty
    USS_KB=$(grep '^Private_' "$smaps" | awk '{sum += $2} END {print sum+0}')
    
    [ "$VERBOSE" = true ] && echo "Raw metrics: PSS=$PSS_KB kB, USS=$USS_KB kB, RSS=$RSS_KB kB" >&2
    
    # Validate we got reasonable values
    if [ "$PSS_KB" = "0" ] && [ "$RSS_KB" = "0" ] && [ "$USS_KB" = "0" ]; then
        echo "Warning: All memory metrics are zero - process may have exited" >&2
    fi
}

# Output metrics in requested format and columns
output_metrics() {
    # Parse requested columns
    local show_pss=false show_uss=false show_rss=false
    
    case "$COLUMNS" in
        *pss*) show_pss=true ;;
    esac
    case "$COLUMNS" in  
        *uss*) show_uss=true ;;
    esac
    case "$COLUMNS" in
        *rss*) show_rss=true ;;
    esac
    
    # Default to all if none specified
    if [ "$show_pss" = false ] && [ "$show_uss" = false ] && [ "$show_rss" = false ]; then
        show_pss=true show_uss=true show_rss=true
    fi
    
    case "$FORMAT" in
        json)
            # JSON output format
            printf "{"
            local first=true
            
            if [ "$show_pss" = true ]; then
                [ "$first" = false ] && printf ","
                printf "\"pss\":%s" "$PSS_KB"
                first=false
            fi
            
            if [ "$show_uss" = true ]; then
                [ "$first" = false ] && printf ","
                printf "\"uss\":%s" "$USS_KB" 
                first=false
            fi
            
            if [ "$show_rss" = true ]; then
                [ "$first" = false ] && printf ","
                printf "\"rss\":%s" "$RSS_KB"
                first=false
            fi
            
            printf "}\n"
            ;;
            
        text|*)
            # Human-readable text format (default)
            if [ "$show_pss" = true ]; then
                printf "PSS: %s kB\n" "$PSS_KB"
            fi
            
            if [ "$show_uss" = true ]; then
                printf "USS: %s kB\n" "$USS_KB"
            fi
            
            if [ "$show_rss" = true ]; then
                printf "RSS: %s kB\n" "$RSS_KB"
            fi
            ;;
    esac
}

# Main execution
main() {
    parse_args "$@"
    
    if [ "$HELP" = true ]; then
        show_help
        exit 0
    fi
    
    validate_pid
    extract_metrics
    output_metrics
}

# Execute main function with all arguments
main "$@"