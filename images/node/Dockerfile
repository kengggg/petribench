FROM ghcr.io/kengggg/petribench-base:latest

# Switch to root to install packages
USER root

# Install Node.js and npm
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nodejs \
        npm \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Switch back to non-root user
USER tester

# Set working directory for volume mounts
WORKDIR /app

# Add Node.js-specific labels
LABEL org.opencontainers.image.description="Ultra-minimal Node.js runtime for memory benchmarking with RSS/PSS/USS measurement"
LABEL node.version="20+"

# Default command: Show available tools and runtime info
CMD ["/bin/sh", "-c", "echo 'PetriBench Node.js Runtime'; echo 'Available tools:'; echo '  - node ($(node --version))'; echo '  - npm ($(npm --version))'; echo '  - /usr/bin/time (GNU time for RSS measurement)'; echo '  - smem2 (PSS/USS measurement)'; echo '  - /proc/self/smaps_rollup (direct proc parsing)'; echo ''; echo 'Usage examples:'; echo '  docker run -v script.js:/app/script.js petribench-node node script.js'; echo '  docker run -v script.js:/app/script.js petribench-node /usr/bin/time -v node script.js'; echo '  docker run -v script.js:/app/script.js petribench-node sh -c \"node script.js & smem2 -P \\$!\"'"]