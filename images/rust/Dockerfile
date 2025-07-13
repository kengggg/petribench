FROM ghcr.io/kengggg/petribench-base:latest

# Switch to root to install packages
USER root

# Install Rust compiler and Cargo package manager
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        rustc \
        cargo \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Switch back to non-root user
USER tester

# Set working directory for volume mounts
WORKDIR /app

# Add Rust-specific labels
LABEL org.opencontainers.image.description="Ultra-minimal Rust runtime for memory benchmarking with RSS/PSS/USS measurement"
LABEL rust.version="1.71+"

# Default command: Show available tools and runtime info
CMD ["/bin/sh", "-c", "echo 'PetriBench Rust Runtime'; echo 'Available tools:'; echo '  - rustc ($(rustc --version))'; echo '  - cargo ($(cargo --version))'; echo '  - /usr/bin/time (GNU time for RSS measurement)'; echo '  - smem2 (PSS/USS measurement)'; echo '  - /proc/self/smaps_rollup (direct proc parsing)'; echo ''; echo 'Usage examples:'; echo '  docker run -v program.rs:/app/program.rs petribench-rust sh -c \"rustc program.rs && ./program\"'; echo '  docker run -v program.rs:/app/program.rs petribench-rust /usr/bin/time -v sh -c \"rustc program.rs && ./program\"'; echo '  docker run -v src:/app/src -v Cargo.toml:/app/Cargo.toml petribench-rust cargo run'"]