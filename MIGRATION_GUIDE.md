# PetriBench Multi-Stage Migration Guide

## Overview

PetriBench has been optimized with multi-stage Docker builds to achieve significant size reductions while maintaining full functionality. This guide explains the changes and how to adapt existing workflows.

## 🎯 Key Changes

### Size Improvements
- **42% average size reduction** across all images
- **Faster container startup** and reduced network transfer
- **Same functionality** with optimized resource usage

### Build Process Changes
- **Multi-stage builds** separate compilation from runtime
- **Compiled languages** now have pre-compiled binaries
- **Managed runtimes** separate build tools from execution

## 🔄 Migration Overview

### ✅ No Changes Required
**Most users don't need to change anything** - the optimization is transparent:

- **Same image names** and registry URLs
- **Same entry points** and command interfaces
- **Same volume mount paths** and working directories
- **Same environment variables** and configuration

### 📋 What's Different

#### Compiled Languages (C, C++, Rust)
**Before**: Compilation happened at runtime
```bash
# Old approach (still works)
docker run --rm -v $(pwd)/app.c:/workspace/app.c \
  ghcr.io/kengggg/petribench-c:latest \
  sh -c "gcc app.c -o app && ./app"
```

**After**: Pre-compiled binaries available
```bash
# New optimized approach
docker run --rm -v $(pwd)/app.c:/workspace/app.c \
  ghcr.io/kengggg/petribench-c:latest \
  /usr/local/bin/program
```

#### Managed Runtimes (Java, .NET)
**Before**: Required external compilation
```bash
# Old approach
javac Program.java
docker run --rm -v $(pwd)/Program.class:/workspace/Program.class \
  ghcr.io/kengggg/petribench-jdk:latest \
  java Program
```

**After**: Compile source files directly
```bash
# New approach - compile .java files automatically
docker run --rm -v $(pwd)/Program.java:/workspace/Program.java \
  ghcr.io/kengggg/petribench-jdk:latest \
  java -cp /workspace Program
```

## 📚 Language-Specific Migration

### Python & Node.js
**Status**: ✅ **No changes needed**
- Same commands and workflows
- Package managers (pip, npm) preserved
- All existing scripts continue to work

### Go
**Status**: ✅ **No changes needed**
- Already optimized in previous versions
- Same compilation and execution patterns

### C Language
**Migration Options**:

1. **Use pre-compiled binary** (recommended):
   ```bash
   docker run --rm -v $(pwd)/app.c:/workspace/app.c \
     ghcr.io/kengggg/petribench-c:latest \
     /usr/local/bin/program
   ```

2. **Traditional compilation** (still supported):
   ```bash
   docker run --rm -v $(pwd)/app.c:/workspace/app.c \
     ghcr.io/kengggg/petribench-c:latest \
     sh -c "gcc app.c -o app && ./app"
   ```

### C++ Language
**Migration Options**:

1. **Use pre-compiled binary** (recommended):
   ```bash
   docker run --rm -v $(pwd)/app.cpp:/workspace/app.cpp \
     ghcr.io/kengggg/petribench-cpp:latest \
     /usr/local/bin/program
   ```

2. **Traditional compilation** (still supported):
   ```bash
   docker run --rm -v $(pwd)/app.cpp:/workspace/app.cpp \
     ghcr.io/kengggg/petribench-cpp:latest \
     sh -c "g++ app.cpp -o app && ./app"
   ```

### Rust Language
**Migration Options**:

1. **Use pre-compiled binary** (recommended):
   ```bash
   docker run --rm -v $(pwd)/app.rs:/workspace/app.rs \
     ghcr.io/kengggg/petribench-rust:latest \
     /usr/local/bin/program
   ```

2. **Traditional compilation** (still supported):
   ```bash
   docker run --rm -v $(pwd)/app.rs:/workspace/app.rs \
     ghcr.io/kengggg/petribench-rust:latest \
     sh -c "rustc app.rs && ./app"
   ```

### Java JDK
**Migration Options**:

1. **Compile source files directly** (recommended):
   ```bash
   docker run --rm -v $(pwd)/Program.java:/workspace/Program.java \
     ghcr.io/kengggg/petribench-jdk:latest \
     java -cp /workspace Program
   ```

2. **Use pre-compiled classes** (traditional):
   ```bash
   docker run --rm -v $(pwd)/Program.class:/workspace/Program.class \
     ghcr.io/kengggg/petribench-jdk:latest \
     java -cp /workspace Program
   ```

### Java JRE
**Usage**: For pre-compiled classes only
```bash
docker run --rm -v $(pwd)/Program.class:/workspace/Program.class \
  ghcr.io/kengggg/petribench-jre:latest \
  java -cp /workspace Program
```

### .NET SDK
**Migration Options**:

1. **Compile source files directly** (recommended):
   ```bash
   docker run --rm -v $(pwd)/Program.cs:/workspace/Program.cs \
     ghcr.io/kengggg/petribench-dotnet-sdk:latest \
     dotnet /workspace/Program.dll
   ```

2. **Use pre-compiled assemblies** (traditional):
   ```bash
   docker run --rm -v $(pwd)/Program.dll:/workspace/Program.dll \
     ghcr.io/kengggg/petribench-dotnet-sdk:latest \
     dotnet /workspace/Program.dll
   ```

### .NET Runtime
**Usage**: For pre-compiled assemblies only
```bash
docker run --rm -v $(pwd)/Program.dll:/workspace/Program.dll \
  ghcr.io/kengggg/petribench-dotnet-runtime:latest \
  dotnet /workspace/Program.dll
```

## 🔧 Common Patterns

### Memory Measurement
**All existing measurement patterns continue to work**:

```bash
# RSS measurement (unchanged)
docker run --rm -v $(pwd)/script.py:/app/script.py \
  ghcr.io/kengggg/petribench-python:latest \
  /usr/bin/time -v python3 script.py

# PSS/USS measurement (unchanged)
docker run --rm -v $(pwd)/script.py:/app/script.py \
  ghcr.io/kengggg/petribench-python:latest \
  sh -c "python3 script.py & smem2 -P \$! -c pss,uss,rss"
```

### Volume Mounts
**All volume mount patterns continue to work**:

```bash
# Single file mount (unchanged)
-v $(pwd)/script.py:/app/script.py

# Directory mount (unchanged)
-v $(pwd)/project:/workspace

# Multiple files (unchanged)
-v $(pwd)/input.txt:/workspace/input.txt \
-v $(pwd)/script.py:/workspace/script.py
```

### Environment Variables
**All environment patterns continue to work**:

```bash
# Environment variables (unchanged)
-e PYTHONPATH=/workspace \
-e NODE_ENV=production \
-e JAVA_OPTS="-Xmx256m"
```

## 🚀 Performance Benefits

### Size Improvements
| Language | Before | After | Reduction |
|----------|--------|-------|-----------|
| Python | 298MB | 178MB | 40% |
| Node.js | 311MB | 194MB | 38% |
| C | 338MB | 100MB | 70% |
| C++ | 389MB | 106MB | 73% |
| Rust | 779MB | 144MB | 81% |
| Java JDK | 463MB | 324MB | 30% |
| Java JRE | 384MB | 324MB | 16% |
| .NET SDK | 838MB | 304MB | 64% |
| .NET Runtime | 305MB | 304MB | <1% |

### Startup Performance
- **Faster container startup** due to smaller image sizes
- **Reduced network transfer** for pulls and pushes
- **Better Docker layer caching** during builds

## 🔍 Troubleshooting

### Common Issues

#### "Binary not found" errors
**Problem**: Using old compilation patterns with new optimized images

**Solution**: Use the pre-compiled binary paths:
```bash
# For compiled languages, use the pre-compiled binary
/usr/local/bin/program
```

#### "Class not found" errors (Java)
**Problem**: Class naming mismatch in multi-stage build

**Solution**: Use the standardized class names:
```bash
# Use Program class (automatically created)
java -cp /workspace Program
```

#### "Assembly not found" errors (.NET)
**Problem**: Missing runtime configuration files

**Solution**: The multi-stage build handles this automatically:
```bash
# Both .dll and .runtimeconfig.json are created
dotnet /workspace/Program.dll
```

### Getting Help

1. **Check the examples** in the README for your language
2. **Review this migration guide** for specific patterns
3. **Test with simple programs** before complex workflows
4. **Report issues** on the GitHub repository

## 📋 Checklist

### Before Migration
- [ ] Identify which languages you're using
- [ ] Review current Docker commands and scripts
- [ ] Test with non-critical workloads first

### During Migration
- [ ] Try recommended patterns for your languages
- [ ] Verify memory measurement still works
- [ ] Test with existing benchmark scripts
- [ ] Update documentation and scripts if needed

### After Migration
- [ ] Validate performance improvements
- [ ] Update team documentation
- [ ] Monitor for any issues
- [ ] Enjoy the smaller image sizes! 🎉

## 📞 Support

- **GitHub Issues**: [Report problems or ask questions](https://github.com/kengggg/petribench/issues)
- **Documentation**: Check the updated README.md
- **Examples**: All examples in the repository work with optimized images

---

**Remember**: Most users don't need to change anything - the optimization is designed to be transparent while providing significant benefits!

*Last updated: July 15, 2025*