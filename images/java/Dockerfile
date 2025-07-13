FROM ghcr.io/kengggg/petribench-base:latest

# Switch to root to install packages
USER root

# Install OpenJDK 17 JRE (headless for minimal size)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-17-jre-headless \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Switch back to non-root user
USER tester

# Set working directory for volume mounts
WORKDIR /app

# Add Java-specific labels
LABEL org.opencontainers.image.description="Ultra-minimal Java runtime for memory benchmarking with RSS/PSS/USS measurement"
LABEL java.version="17"

# Default command: Show available tools and runtime info
CMD ["/bin/sh", "-c", "echo 'PetriBench Java Runtime'; echo 'Available tools:'; echo '  - java ($(java -version 2>&1 | head -1))'; echo '  - /usr/bin/time (GNU time for RSS measurement)'; echo '  - smem2 (PSS/USS measurement)'; echo '  - /proc/self/smaps_rollup (direct proc parsing)'; echo ''; echo 'Usage examples:'; echo '  docker run -v Program.class:/app/Program.class petribench-java java Program'; echo '  docker run -v Program.class:/app/Program.class petribench-java /usr/bin/time -v java Program'; echo '  docker run -v program.jar:/app/program.jar petribench-java java -jar program.jar'"]