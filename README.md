# PetriBench - Ultra-Minimal Docker Images for Language Performance Benchmarking

PetriBench provides ultra-minimal, reproducible Docker images for measuring memory usage across programming languages. Built on `debian:bookworm-slim` with support for RSS, PSS, and USS memory measurement methods.

## Quick Start

### Pull Pre-built Images

```bash
# Base image with measurement tools
docker pull ghcr.io/kengggg/petribench-base:latest

# Language-specific images
docker pull ghcr.io/kengggg/petribench-python:latest
docker pull ghcr.io/kengggg/petribench-go:latest
docker pull ghcr.io/kengggg/petribench-node:latest
docker pull ghcr.io/kengggg/petribench-c:latest
docker pull ghcr.io/kengggg/petribench-cpp:latest
docker pull ghcr.io/kengggg/petribench-jdk:latest
docker pull ghcr.io/kengggg/petribench-jre:latest
docker pull ghcr.io/kengggg/petribench-rust:latest
docker pull ghcr.io/kengggg/petribench-dotnet-sdk:latest
docker pull ghcr.io/kengggg/petribench-dotnet-runtime:latest
```

### Basic Usage

```bash
# Show available tools and usage examples
docker run --rm ghcr.io/kengggg/petribench-python:latest

# Run Python script with RSS measurement
docker run --rm -v $(pwd)/script.py:/app/script.py \
  ghcr.io/kengggg/petribench-python:latest \
  /usr/bin/time -v python3 script.py

# Run Python script normally
docker run --rm -v $(pwd)/script.py:/app/script.py \
  ghcr.io/kengggg/petribench-python:latest \
  python3 script.py
```

## 🚀 Multi-Stage Optimization

PetriBench uses **multi-stage Docker builds** to achieve optimal size and performance while maintaining full functionality:

### How Multi-Stage Works
- **Build Stage**: Full development environment with compilers, SDKs, and build tools
- **Runtime Stage**: Minimal execution environment with only runtime dependencies
- **Result**: Dramatically smaller images with identical functionality

### Benefits
- **42% average size reduction** across all images
- **Faster container startup** due to smaller image sizes
- **Reduced network transfer** for pulls and pushes
- **Better Docker layer caching** during builds
- **Lower storage costs** in registries

### Language-Specific Optimizations
- **Interpreted languages** (Python, Node.js): Remove build dependencies, preserve package managers
- **Compiled languages** (C, C++, Rust): Static compilation, remove toolchains
- **Managed runtimes** (Java, .NET): Separate compilation from execution, runtime-only final stage

### Backwards Compatibility
All existing workflows continue to work without changes - the optimization is transparent to users.

## Memory Measurement Methods

### RSS (Resident Set Size) - Default
Uses GNU `time -v` for total memory in RAM:
```bash
docker run --rm -v $(pwd)/script.py:/app/script.py \
  ghcr.io/kengggg/petribench-python:latest \
  /usr/bin/time -v python3 script.py
# Output includes: "Maximum resident set size (kbytes): XXXX"
```

### PSS/USS (Enhanced) 
Uses `smem2` for more accurate container memory attribution:
```bash
# PSS (Proportional Set Size) - shared memory divided proportionally
# USS (Unique Set Size) - memory unique to process
docker run --rm -v $(pwd)/script.py:/app/script.py \
  ghcr.io/kengggg/petribench-python:latest \
  sh -c "python3 script.py & smem2 -P \$! -c pss,uss,rss"
```

### /proc/smaps_rollup (Raw)
Direct parsing of kernel memory data:
```bash
docker run --rm -v $(pwd)/script.py:/app/script.py \
  ghcr.io/kengggg/petribench-python:latest \
  sh -c "python3 script.py & cat /proc/\$!/smaps_rollup"
```

## Use Cases

### Language Performance Benchmarking

Compare memory usage across different programming languages:

```bash
# Python benchmark
docker run --rm -v $(pwd)/benchmark.py:/app/script.py \
  ghcr.io/kengggg/petribench-python:latest \
  /usr/bin/time -v python3 script.py

# Go benchmark  
docker run --rm -v $(pwd)/benchmark.go:/app/script.go \
  ghcr.io/kengggg/petribench-go:latest \
  /usr/bin/time -v go run script.go

# Node.js benchmark
docker run --rm -v $(pwd)/benchmark.js:/app/script.js \
  ghcr.io/kengggg/petribench-node:latest \
  /usr/bin/time -v node script.js

# C benchmark (multi-stage: compiles in build, runs optimized binary)
docker run --rm -v $(pwd)/benchmark.c:/workspace/benchmark.c \
  ghcr.io/kengggg/petribench-c:latest \
  /usr/bin/time -v /usr/local/bin/program

# Rust benchmark (multi-stage: compiles in build, runs optimized binary)
docker run --rm -v $(pwd)/benchmark.rs:/workspace/benchmark.rs \
  ghcr.io/kengggg/petribench-rust:latest \
  /usr/bin/time -v /usr/local/bin/program

# Java JDK benchmark (multi-stage: compiles .java to .class, runs in JRE)
docker run --rm -v $(pwd)/Benchmark.java:/workspace/Benchmark.java \
  ghcr.io/kengggg/petribench-jdk:latest \
  /usr/bin/time -v java -cp /workspace Program

# Java JRE benchmark (runtime-only: for pre-compiled .class files)
docker run --rm -v $(pwd)/Benchmark.class:/workspace/Benchmark.class \
  ghcr.io/kengggg/petribench-jre:latest \
  /usr/bin/time -v java -cp /workspace Program

# .NET SDK benchmark (multi-stage: compiles .cs to .dll, runs in runtime)
docker run --rm -v $(pwd)/benchmark.cs:/workspace/benchmark.cs \
  ghcr.io/kengggg/petribench-dotnet-sdk:latest \
  /usr/bin/time -v dotnet /workspace/Program.dll

# .NET Runtime benchmark (runtime-only: for pre-compiled .dll files)
docker run --rm -v $(pwd)/benchmark.dll:/workspace/benchmark.dll \
  ghcr.io/kengggg/petribench-dotnet-runtime:latest \
  /usr/bin/time -v dotnet /workspace/Program.dll
```

### fizzbuzzmem Integration (Example Use Case)

PetriBench can replace existing benchmark Docker images:

```bash
# Tag petribench image for fizzbuzzmem compatibility
docker tag ghcr.io/kengggg/petribench-python:latest benchmark-python

# Use with existing fizzbuzzmem measurement script
docker run --rm \
  -v "$(pwd)/benchmark.py:/workspace/benchmark.py" \
  --memory=512m --cpus=1.0 \
  benchmark-python \
  /usr/bin/time -v python3 benchmark.py
```

### Custom Measurement Workflows

Create your own measurement scripts:

```bash
#!/bin/bash
# Custom benchmark script
LANGUAGE="$1"
SCRIPT="$2"

docker run --rm \
  -v "$(pwd)/$SCRIPT:/app/script.py" \
  --memory=512m --cpus=1.0 \
  ghcr.io/kengggg/petribench-$LANGUAGE:latest \
  sh -c "python3 script.py & smem2 -P \$! -c pss,uss,rss --format json"
```

## Image Specifications

**All images use multi-stage builds for optimal size and performance** 🚀

| Image | Size | Build Type | Languages | Description |
|-------|------|------------|-----------|-------------|
| `petribench-base` | ~32MB | Single-stage | - | debian:bookworm-slim + measurement tools |
| `petribench-python` | ~178MB | Multi-stage | Python 3.12 | Interpreter + pip preserved |
| `petribench-go` | ~60MB | Multi-stage | Go 1.21+ | Compiled binaries, minimal runtime |
| `petribench-node` | ~194MB | Multi-stage | Node.js 20 LTS | Runtime + npm preserved |
| `petribench-c` | ~100MB | Multi-stage | C GCC 13 | Statically compiled, no build tools |
| `petribench-cpp` | ~106MB | Multi-stage | C++ G++ 13 | Statically compiled, no build tools |
| `petribench-jdk` | ~324MB | Multi-stage | OpenJDK 17 JDK | Pre-compiled classes, JRE runtime |
| `petribench-jre` | ~324MB | Multi-stage | OpenJDK 17 JRE | Runtime for pre-compiled classes |
| `petribench-rust` | ~144MB | Multi-stage | Rust 1.71+ | Statically compiled, no toolchain |
| `petribench-dotnet-sdk` | ~304MB | Multi-stage | .NET 8 SDK | Pre-compiled assemblies, runtime only |
| `petribench-dotnet-runtime` | ~304MB | Multi-stage | .NET 8 Runtime | Runtime for pre-compiled assemblies |

### 📊 Size Optimization Results
- **Average size reduction**: 42% across all images
- **Best optimization**: Rust (81% reduction: 779MB → 144MB)
- **Total storage savings**: ~1.8GB across all images
- **Maintained functionality**: 100% backwards compatibility

## Development

### Build Locally

```bash
# Build base image
docker build -f ./images/Dockerfile.base -t petribench-base ./images/

# Build language image
docker build -f ./images/Dockerfile.python -t petribench-python ./images/
```

### Test Compatibility

```bash
# Test memory measurement compatibility
./scripts/measure-memory.sh --mode test python scripts/benchmarks/benchmark.py

# Test image sizes and functionality
docker images | grep petribench
```

### Examples

```bash
# Memory measurement demo (RSS, PSS, USS)
./scripts/measure-memory.sh python scripts/benchmarks/benchmark.py

# Specific measurement methods
./scripts/measure-memory.sh --method rss python scripts/benchmarks/benchmark.py
./scripts/measure-memory.sh --method pss python scripts/benchmarks/benchmark.py

# Benchmark mode with statistical analysis
./scripts/measure-memory.sh --mode benchmark python scripts/benchmarks/benchmark.py
```

## Architecture

### Multi-Method Support
- **RSS**: GNU time compatibility for fizzbuzzmem
- **PSS/USS**: smem2 and /proc parsing for enhanced accuracy
- **Extensible**: Support for additional measurement tools

### Security & Isolation
- Non-root user execution (UID 1000)
- Minimal attack surface (distroless philosophy)
- Read-only volume mount support
- Memory/CPU resource limits compatible

### CI/CD
- Multi-architecture builds (amd64/arm64)
- Automated GHCR publishing
- Size monitoring and alerts
- Weekly security updates

## Contributing

1. **Add New Language**: Create `images/Dockerfile.{language}` extending `petribench-base`
2. **Update CI**: Add language to matrix in `.github/workflows/build-and-publish.yml`
3. **Add Benchmarks**: Create `scripts/benchmarks/benchmark.{ext}` for the language
4. **Test**: Update `scripts/build-all.sh` with test cases
5. **Document**: Update README with usage examples and image specifications

### Currently Supported Languages
✅ **All languages optimized with multi-stage builds** (11 total images, 8 language families):
- **Python** (178MB, 40% reduction)
- **Go** (60MB, already optimized)
- **Node.js** (194MB, 38% reduction)
- **C** (100MB, 70% reduction)
- **C++** (106MB, 73% reduction)
- **Java JDK** (324MB, 30% reduction)
- **Java JRE** (324MB, 16% reduction)
- **Rust** (144MB, 81% reduction) 🏆
- **.NET SDK** (304MB, 64% reduction)
- **.NET Runtime** (304MB, minimal change)

**Total project impact**: 42% average size reduction, 1.8GB total storage savings

## Support

- **Issues**: [GitHub Issues](https://github.com/kengggg/petribench/issues)
- **fizzbuzzmem Integration**: See [fizzbuzzmem project](https://github.com/kengggg/fizzbuzzmem)
- **Docker Registry**: [GHCR Packages](https://github.com/kengggg/petribench/pkgs/container/petribench-base)

## License

Apache-2.0 - See [LICENSE](LICENSE) for details.

---

Providing reproducible, minimal environments for language performance comparison. Originally built to support the [fizzbuzzmem memory challenge](https://github.com/kengggg/fizzbuzzmem).