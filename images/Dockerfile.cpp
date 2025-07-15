FROM ghcr.io/kengggg/petribench-base:latest

# Switch to root to install packages
USER root

# Install G++ compiler (minimal)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        g++ \
        libc6-dev \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Switch back to non-root user
USER tester

# Set working directory for volume mounts
WORKDIR /workspace

# Add C++-specific labels
LABEL org.opencontainers.image.description="Ultra-minimal C++ compiler environment for memory benchmarking with RSS/PSS/USS measurement"
LABEL cpp.compiler="g++"
LABEL cpp.standard="c++17"

# Auto-detect and compile C++ programs with RSS measurement
CMD ["/bin/sh", "-c", "if [ -f /workspace/benchmark.cpp ]; then /usr/bin/time -v sh -c 'g++ /workspace/benchmark.cpp -o /tmp/benchmark && /tmp/benchmark'; elif [ -f /workspace/program.cpp ]; then /usr/bin/time -v sh -c 'g++ /workspace/program.cpp -o /tmp/program && /tmp/program'; else echo 'PetriBench C++ Runtime'; echo 'Available tools:'; echo '  - g++ ('$(g++ --version | head -1)')'; echo '  - /usr/bin/time (GNU time for RSS measurement)'; echo '  - measure_memory (PSS/USS measurement)'; echo '  - /proc/self/smaps_rollup (direct proc parsing)'; echo '  - measure_memory --help (smem2 replacement)'; echo ''; echo 'Usage examples:'; echo '  docker run -v program.cpp:/workspace/program.cpp petribench-cpp g++ program.cpp -o program && ./program'; echo '  docker run -v program.cpp:/workspace/program.cpp petribench-cpp /usr/bin/time -v sh -c \"g++ program.cpp -o program && ./program\"'; echo '  docker run -v program.cpp:/workspace/program.cpp petribench-cpp sh -c \"g++ program.cpp -o program && ./program & measure_memory -P \\$!\"'; fi"]