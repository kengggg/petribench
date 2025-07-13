FROM ghcr.io/kengggg/petribench-base:latest

# Switch to root to install packages
USER root

# Install .NET 8 runtime
# Using direct download method instead of package manager for better compatibility
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        libicu-dev \
        libssl-dev \
        && \
    case $(dpkg --print-architecture) in \
        amd64) ARCH=x64 ;; \
        arm64) ARCH=arm64 ;; \
        *) echo "Unsupported architecture" && exit 1 ;; \
    esac && \
    wget -O dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Runtime/8.0.10/dotnet-runtime-8.0.10-linux-$ARCH.tar.gz && \
    mkdir -p /usr/share/dotnet && \
    tar -zxf dotnet.tar.gz -C /usr/share/dotnet && \
    rm dotnet.tar.gz && \
    ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet && \
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