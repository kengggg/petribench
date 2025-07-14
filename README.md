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

# C benchmark
docker run --rm -v $(pwd)/benchmark.c:/app/script.c \
  ghcr.io/kengggg/petribench-c:latest \
  /usr/bin/time -v sh -c "gcc script.c -o script && ./script"

# Rust benchmark
docker run --rm -v $(pwd)/benchmark.rs:/app/script.rs \
  ghcr.io/kengggg/petribench-rust:latest \
  /usr/bin/time -v sh -c "rustc script.rs && ./script"

# Java benchmark (requires pre-compiled .class or .jar)
docker run --rm -v $(pwd)/Benchmark.class:/app/Benchmark.class \
  ghcr.io/kengggg/petribench-java:latest \
  /usr/bin/time -v java Benchmark

# C# benchmark (requires pre-compiled .dll)
docker run --rm -v $(pwd)/benchmark.dll:/app/benchmark.dll \
  ghcr.io/kengggg/petribench-csharp:latest \
  /usr/bin/time -v dotnet benchmark.dll
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

| Image | Size Target | Languages | Base |
|-------|-------------|-----------|------|
| `petribench-base` | <40MB | - | debian:bookworm-slim + measurement tools |
| `petribench-python` | <100MB | Python 3.12 | petribench-base + python3 |
| `petribench-go` | <60MB | Go 1.21+ | petribench-base + golang |
| `petribench-node` | <100MB | Node.js 20 LTS | petribench-base + nodejs |
| `petribench-c` | <250MB | C GCC 13 | petribench-base + gcc |
| `petribench-cpp` | <250MB | C++ G++ 13 | petribench-base + g++ |
| `petribench-jdk` | <380MB | OpenJDK 17 JDK | petribench-base + openjdk-jdk |
| `petribench-jre` | <220MB | OpenJDK 17 JRE | petribench-base + openjdk-jre |
| `petribench-rust` | <250MB | Rust 1.71+ | petribench-base + rustc |
| `petribench-dotnet-sdk` | <450MB | .NET 8 SDK | petribench-base + dotnet-sdk |
| `petribench-dotnet-runtime` | <180MB | .NET 8 Runtime | petribench-base + dotnet-runtime |

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
✅ Python, Go, Node.js, C, C++, Java (JDK/JRE), Rust, .NET (SDK/Runtime) (11 total images, 8 language families)

## Support

- **Issues**: [GitHub Issues](https://github.com/kengggg/petribench/issues)
- **fizzbuzzmem Integration**: See [fizzbuzzmem project](https://github.com/kengggg/fizzbuzzmem)
- **Docker Registry**: [GHCR Packages](https://github.com/kengggg/petribench/pkgs/container/petribench-base)

## License

Apache-2.0 - See [LICENSE](LICENSE) for details.

---

Providing reproducible, minimal environments for language performance comparison. Originally built to support the [fizzbuzzmem memory challenge](https://github.com/kengggg/fizzbuzzmem).