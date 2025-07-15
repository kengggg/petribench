# /proc/smaps_rollup Access Requirements

## Overview

The `measure_memory` script requires access to `/proc/PID/smaps_rollup` to gather PSS, USS, and RSS memory metrics. This document explains the access model and potential limitations.

## Access Model

### ✅ What Works

1. **Same-user processes**: The script can measure any process owned by the same user
2. **Container environments**: In PetriBench containers, the `tester` user can measure all processes it starts
3. **Child processes**: Processes spawned by measured scripts are automatically accessible

### ⚠️ Limitations

1. **Cross-user access**: Cannot measure processes owned by different users
2. **Root processes**: Non-root users cannot typically access root-owned process memory
3. **Race conditions**: Very short-lived processes may exit before measurement

## Container Behavior

In PetriBench containers:
- The `tester` user (UID 1000) runs as the primary user
- All benchmark processes run as `tester`
- `/proc/PID/smaps_rollup` files are owned by `tester:tester`
- No permission issues for typical benchmarking scenarios

## Error Scenarios

### Process Not Found
```bash
$ measure_memory -P 99999
Error: Process 99999 not found
```

### Permission Denied (Cross-user)
```bash
$ measure_memory -P 1234
Error: Cannot read /proc/1234/smaps_rollup - process owned by 'root', running as 'tester'
Hint: This tool can only measure processes owned by the same user
```

### Race Condition (Process Exits)
```bash
$ measure_memory -P 5678
Error: Process 5678 disappeared or became unreadable during measurement
```

## Best Practices

1. **Measure long-running processes**: Ensure target process runs long enough for measurement
2. **Use background jobs carefully**: Add small delays after starting background processes
3. **Handle errors gracefully**: Check exit codes and handle permission failures
4. **Prefer same-user workflows**: Design benchmarks to run under consistent user context

## Technical Details

### File Permissions
```bash
$ ls -la /proc/1234/smaps_rollup
-r--r--r-- 1 tester tester 0 Jul 15 02:27 /proc/1234/smaps_rollup
```

- Read-only file (`r--r--r--`)
- Owned by process owner (`tester:tester`)
- Accessible to owner and group

### Kernel Requirements
- Linux kernel 4.14+ for `/proc/PID/smaps_rollup` support
- Earlier kernels require parsing `/proc/PID/smaps` (slower)
- Container runtimes must expose `/proc` filesystem

## Troubleshooting

### Issue: Permission denied errors
**Solution**: Ensure processes are started by the same user running `measure_memory`

### Issue: "Process not found" for existing process
**Solution**: Check if process still exists, may have exited during measurement

### Issue: All metrics return zero
**Solution**: Process likely exited, verify target process lifetime

### Issue: File not found errors
**Solution**: Kernel may be too old, check kernel version and smaps_rollup support