FROM ghcr.io/kengggg/petribench-base:latest

# Switch to root to install packages
USER root

# Install .NET 8 runtime from Microsoft repository
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        && \
    wget -O packages-microsoft-prod.deb https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        aspnetcore-runtime-8.0 \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Switch back to non-root user
USER tester

# Set working directory for volume mounts
WORKDIR /app

# Add .NET-specific labels
LABEL org.opencontainers.image.description="Ultra-minimal .NET C# runtime for memory benchmarking with RSS/PSS/USS measurement"
LABEL dotnet.version="8.0"

# Default command: Show available tools and runtime info
CMD ["/bin/sh", "-c", "echo 'PetriBench .NET C# Runtime'; echo 'Available tools:'; echo '  - dotnet ($(dotnet --version))'; echo '  - /usr/bin/time (GNU time for RSS measurement)'; echo '  - smem2 (PSS/USS measurement)'; echo '  - /proc/self/smaps_rollup (direct proc parsing)'; echo ''; echo 'Usage examples:'; echo '  docker run -v Program.dll:/app/Program.dll petribench-csharp dotnet Program.dll'; echo '  docker run -v Program.dll:/app/Program.dll petribench-csharp /usr/bin/time -v dotnet Program.dll'; echo '  docker run -v project:/app petribench-csharp dotnet run'"]