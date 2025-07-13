FROM ghcr.io/kengggg/petribench-base:latest

# Switch to root to install packages
USER root

# Install GCC compiler for C
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc \
        libc6-dev \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Switch back to non-root user
USER tester

# Set working directory for volume mounts
WORKDIR /workspace

# Add C-specific labels
LABEL org.opencontainers.image.description="Ultra-minimal C compiler environment for memory benchmarking with RSS/PSS/USS measurement"
LABEL gcc.version="13+"

# Default command: Show available tools and runtime info
CMD ["/bin/sh", "-c", "if [ -f /workspace/benchmark.c ]; then /usr/bin/time -v sh -c 'gcc /workspace/benchmark.c -o /tmp/benchmark && /tmp/benchmark'; elif [ -f /workspace/program.c ]; then /usr/bin/time -v sh -c 'gcc /workspace/program.c -o /tmp/program && /tmp/program'; else echo 'PetriBench C Runtime'; echo 'Available tools:'; echo '  - gcc ($(gcc --version | head -1))'; echo '  - /usr/bin/time (GNU time for RSS measurement)'; echo '  - smem2 (PSS/USS measurement)'; echo '  - /proc/self/smaps_rollup (direct proc parsing)'; echo ''; echo 'Usage examples:'; echo '  docker run -v program.c:/workspace/program.c petribench-c sh -c \"gcc program.c -o program && ./program\"'; echo '  docker run -v program.c:/workspace/program.c petribench-c /usr/bin/time -v sh -c \"gcc program.c -o program && ./program\"'; fi"]