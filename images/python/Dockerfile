FROM ghcr.io/kengggg/petribench-base:latest

# Switch to root to install packages
USER root

# Install Python 3.12 (minimal)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-minimal \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create symbolic link for convenience
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Switch back to non-root user
USER tester

# Set working directory for volume mounts
WORKDIR /app

# Add Python-specific labels
LABEL org.opencontainers.image.description="Ultra-minimal Python runtime for memory benchmarking with RSS/PSS/USS measurement"
LABEL python.version="3.12"

# Default command: Show available measurement tools and runtime info
CMD ["/bin/sh", "-c", "echo 'PetriBench Python Runtime'; echo 'Available tools:'; echo '  - python3 ($(python3 --version))'; echo '  - /usr/bin/time (GNU time for RSS measurement)'; echo '  - smem2 (PSS/USS measurement)'; echo '  - /proc/self/smaps_rollup (direct proc parsing)'; echo ''; echo 'Usage examples:'; echo '  docker run -v script.py:/app/script.py petribench-python python3 script.py'; echo '  docker run -v script.py:/app/script.py petribench-python /usr/bin/time -v python3 script.py'; echo '  docker run -v script.py:/app/script.py petribench-python sh -c \"python3 script.py & smem2 -P \\$!\"'"]