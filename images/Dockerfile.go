FROM ghcr.io/kengggg/petribench-base:latest

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

# Switch back to non-root user
USER tester

# Set working directory for volume mounts
WORKDIR /workspace

# Add Go-specific labels
LABEL org.opencontainers.image.description="Ultra-minimal Go runtime for memory benchmarking with RSS/PSS/USS measurement"
LABEL go.version="1.21+"

# Default command: Show available tools and runtime info
CMD ["/bin/sh", "-c", "if [ -f /workspace/benchmark.go ]; then /usr/bin/time -v go run /workspace/benchmark.go; elif [ -f /workspace/script.go ]; then /usr/bin/time -v go run /workspace/script.go; else echo 'PetriBench Go Runtime'; echo 'Available tools:'; echo '  - go ($(go version))'; echo '  - /usr/bin/time (GNU time for RSS measurement)'; echo '  - smem2 (PSS/USS measurement)'; echo '  - /proc/self/smaps_rollup (direct proc parsing)'; echo ''; echo 'Usage examples:'; echo '  docker run -v script.go:/workspace/script.go petribench-go go run script.go'; echo '  docker run -v script.go:/workspace/script.go petribench-go /usr/bin/time -v go run script.go'; echo '  docker run -v script.go:/workspace/script.go petribench-go sh -c \"go run script.go & smem2 -P \\$!\"'; fi"]