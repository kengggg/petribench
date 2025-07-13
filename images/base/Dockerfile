FROM debian:bookworm-slim

# Install measurement tools for RSS, PSS, USS memory analysis
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        time \
        python3 \
        python3-pip \
        ca-certificates \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install smem2 for enhanced PSS/USS measurement
RUN pip3 install --no-cache-dir --break-system-packages smem2

# Create directories for measurement and test code
RUN mkdir -p /app /measurements

# Create non-root user for security
RUN useradd -m -u 1000 -g 1000 tester

# Set working directory for volume mounts (fizzbuzzmem compatibility)
WORKDIR /app

# Switch to non-root user
USER tester

# Add labels for GHCR integration
LABEL org.opencontainers.image.source=https://github.com/kengggg/petribench
LABEL org.opencontainers.image.description="Ultra-minimal base image for language performance benchmarking with RSS/PSS/USS measurement support"
LABEL org.opencontainers.image.licenses=Apache-2.0

# Default command shows available measurement tools and usage
CMD ["/bin/sh", "-c", "echo 'PetriBench Base Image'; echo 'Available measurement tools:'; echo '  - /usr/bin/time (GNU time for RSS measurement)'; echo '  - smem2 (PSS/USS measurement)'; echo '  - /proc/self/smaps_rollup (direct proc parsing)'; echo ''; echo 'Usage: Extend this base image with your language runtime'"]