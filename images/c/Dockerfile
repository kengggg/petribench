FROM ghcr.io/kengggg/petribench-base:latest

# Switch to root to install packages
USER root

# Install GCC compilers for C and C++
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc \
        g++ \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Switch back to non-root user
USER tester

# Set working directory for volume mounts
WORKDIR /app

# Add C/C++-specific labels
LABEL org.opencontainers.image.description="Ultra-minimal C/C++ runtime for memory benchmarking with RSS/PSS/USS measurement"
LABEL gcc.version="13+"

# Default command: Show available tools and runtime info
CMD ["/bin/sh", "-c", "echo 'PetriBench C/C++ Runtime'; echo 'Available tools:'; echo '  - gcc ($(gcc --version | head -1))'; echo '  - g++ ($(g++ --version | head -1))'; echo '  - /usr/bin/time (GNU time for RSS measurement)'; echo '  - smem2 (PSS/USS measurement)'; echo '  - /proc/self/smaps_rollup (direct proc parsing)'; echo ''; echo 'Usage examples:'; echo '  docker run -v program.c:/app/program.c petribench-c sh -c \"gcc program.c -o program && ./program\"'; echo '  docker run -v program.cpp:/app/program.cpp petribench-c sh -c \"g++ program.cpp -o program && ./program\"'; echo '  docker run -v program.c:/app/program.c petribench-c /usr/bin/time -v sh -c \"gcc program.c -o program && ./program\"'"]