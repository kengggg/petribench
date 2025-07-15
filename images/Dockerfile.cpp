# Multi-stage build for C++ - Separate build tools from runtime
# Build stage: Full G++ compiler with build tools
FROM ghcr.io/kengggg/petribench-base:latest AS builder

# Switch to root to install packages
USER root

# Install G++ compiler and development tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        g++ \
        libc6-dev \
        libstdc++-12-dev \
        make \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Switch to tester user for builds
USER tester
WORKDIR /workspace

# Copy source code for build
COPY --chown=tester:tester . .

# Build C++ programs if they exist
# Compile to statically linked binary for minimal runtime dependencies
RUN if [ -f benchmark.cpp ]; then \
        echo "Building benchmark.cpp as optimized static binary..."; \
        g++ -O3 -static -std=c++17 -o benchmark benchmark.cpp; \
        cp benchmark program; \
    elif [ -f program.cpp ]; then \
        echo "Building program.cpp as optimized static binary..."; \
        g++ -O3 -static -std=c++17 -o program program.cpp; \
        cp program benchmark; \
    elif [ -f Makefile ]; then \
        echo "Building using Makefile..."; \
        make; \
        # Find the first executable and copy it
        find . -maxdepth 1 -type f -executable | head -1 | xargs -I {} cp {} ./program; \
        cp ./program ./benchmark; \
    else \
        echo "No C++ source files found, creating placeholder binary..."; \
        echo '#include <iostream>\nint main() { std::cout << "No C++ program found" << std::endl; return 0; }' > placeholder.cpp; \
        g++ -O3 -static -std=c++17 -o program placeholder.cpp; \
        cp program benchmark; \
    fi

# Runtime stage: Minimal runtime without build tools
FROM ghcr.io/kengggg/petribench-base:latest

# Copy only the compiled binary from build stage
COPY --from=builder --chown=tester:tester /workspace/benchmark /usr/local/bin/benchmark
COPY --from=builder --chown=tester:tester /workspace/program /usr/local/bin/program

# Copy source code for reference (optional)
COPY --from=builder --chown=tester:tester /workspace /workspace

# Switch back to non-root user
USER tester

# Set working directory for volume mounts
WORKDIR /workspace

# Add C++-specific labels
LABEL org.opencontainers.image.description="Ultra-minimal C++ runtime for memory benchmarking with RSS/PSS/USS measurement"
LABEL cpp.compiler="g++"
LABEL cpp.standard="c++17"
LABEL build.type="multi-stage"
LABEL optimization.size="72% reduction vs single-stage"

# Default command: Run pre-compiled binary with RSS measurement
CMD ["/bin/sh", "-c", "if [ -f /usr/local/bin/benchmark ]; then /usr/bin/time -v /usr/local/bin/benchmark; elif [ -f /usr/local/bin/program ]; then /usr/bin/time -v /usr/local/bin/program; else echo 'PetriBench C++ Runtime (Multi-stage Optimized)'; echo 'Available tools:'; echo '  - Pre-compiled C++ binary (static)'; echo '  - /usr/bin/time (GNU time for RSS measurement)'; echo '  - measure_memory (PSS/USS measurement)'; echo '  - /proc/self/smaps_rollup (direct proc parsing)'; echo '  - measure_memory --help (smem2 replacement)'; echo ''; echo 'Size: ~110MB (vs ~390MB single-stage, 72% reduction)'; echo 'Runtime: Pre-compiled static binary, no G++ toolchain'; echo 'Debian: Full environment preserved for apt-get extensions'; echo 'Binary: Optimized with -O3 static linking, C++17 standard'; echo ''; echo 'Usage examples:'; echo '  # Run pre-compiled binary:'; echo '  docker run petribench-cpp'; echo '  docker run petribench-cpp /usr/bin/time -v /usr/local/bin/benchmark'; echo '  # Memory measurement:'; echo '  docker run petribench-cpp sh -c \"/usr/local/bin/benchmark & measure_memory -P \\$!\"; '; echo '  # Build custom binary:'; echo '  docker build -f Dockerfile.cpp -t petribench-cpp .'; fi"]