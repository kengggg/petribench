# Multi-stage build for Go - Separate compilation from runtime
# Build stage: Full Go toolchain for compilation
FROM ghcr.io/kengggg/petribench-base:latest AS builder

# Switch to root to install packages
USER root

# Install Go compiler + ca-certificates for go mod SSL support
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        golang-go \
        ca-certificates \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set Go environment for static compilation
ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOARCH=amd64

# Switch to tester user for compilation
USER tester
WORKDIR /workspace

# Copy source code - this will be overridden by volume mounts
COPY --chown=tester:tester . .

# Compile Go program with optimization flags
# This handles both single .go files and go.mod projects
RUN if [ -f go.mod ]; then \
        echo "Building Go module project..."; \
        go mod download; \
        go build -ldflags="-s -w" -o /tmp/program .; \
    elif [ -f benchmark.go ]; then \
        echo "Building benchmark.go..."; \
        go build -ldflags="-s -w" -o /tmp/program benchmark.go; \
    elif [ -f script.go ]; then \
        echo "Building script.go..."; \
        go build -ldflags="-s -w" -o /tmp/program script.go; \
    else \
        echo "No Go source found, creating placeholder..."; \
        echo 'package main; import "fmt"; func main() { fmt.Println("No Go source provided. Mount .go files or go.mod project to /workspace") }' > main.go; \
        go build -ldflags="-s -w" -o /tmp/program main.go; \
    fi

# Runtime stage: Minimal image with compiled binary
FROM ghcr.io/kengggg/petribench-base:latest

# Copy the compiled binary from build stage
COPY --from=builder /tmp/program /usr/local/bin/program

# Ensure proper permissions
USER root
RUN chmod +x /usr/local/bin/program && \
    chown tester:tester /usr/local/bin/program

# Switch back to non-root user
USER tester

# Set working directory for volume mounts
WORKDIR /workspace

# Add Go-specific labels
LABEL org.opencontainers.image.description="Ultra-minimal Go runtime for memory benchmarking with RSS/PSS/USS measurement"
LABEL go.version="1.21+"
LABEL build.type="multi-stage"
LABEL optimization.size="27% reduction vs single-stage"

# Default command: Run compiled program with measurement
CMD ["/bin/sh", "-c", "if [ -f /workspace/benchmark.go ] || [ -f /workspace/script.go ] || [ -f /workspace/go.mod ]; then echo 'Note: Source files detected. For compilation, rebuild the image with source code.'; echo 'Running pre-compiled program:'; /usr/bin/time -v /usr/local/bin/program; else echo 'PetriBench Go Runtime (Multi-stage Optimized)'; echo 'Available tools:'; echo '  - /usr/local/bin/program (compiled Go binary)'; echo '  - /usr/bin/time (GNU time for RSS measurement)'; echo '  - measure_memory (PSS/USS measurement)'; echo '  - /proc/self/smaps_rollup (direct proc parsing)'; echo '  - measure_memory --help (smem2 replacement)'; echo ''; echo 'Size: ~110MB (vs ~150MB single-stage, 27% reduction)'; echo 'Runtime: Static binary, no Go toolchain needed'; echo 'Debian: Full environment preserved for apt-get extensions'; echo ''; echo 'Usage examples:'; echo '  # Mount source and rebuild:'; echo '  docker build -f Dockerfile.go -t petribench-go .'; echo '  docker run -v benchmark.go:/workspace/benchmark.go petribench-go'; echo '  # Memory measurement:'; echo '  docker run petribench-go sh -c \"/usr/local/bin/program & measure_memory -P \\$!\"'; fi"]