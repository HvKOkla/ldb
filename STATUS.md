# ldb - Status

**Version**: 0.1.2
**Last tested**: 2026-10-05



## ✅ Tested and working

| Feature | Status | Notes |
|---------|--------|-------|
| `ldb.log` | ✅ | Levels, scopes, filters, file output |
| `ldb.dump` | ✅ | Tables, cycles, depth/item limits |
| `ldb.trace` | ✅ | Stack traces, tail calls, C functions |
| `ldb.bench.avg` | ✅ | Warmup + average over N runs |
| `ldb.bench.time` | ✅ | Single-run timing |
| `ldb.bench.start/stop` | ✅ | Manual timers |
| `ldb.watch` | ✅ | add, snapshot, tick, remove |



## ⚠️ Not tested

| Feature | Status | Notes |
|---------|--------|-------|
| Lua 5.2, 5.3, 5.4 | ⚠️ | Written with compat in mind, not verified |
| LuaJIT | ⚠️ | Same |
| Linux / macOS | ⚠️ | Only tested on Windows PowerShell |
| `ldb.hook` (breakpoints) | ⚠️ | Code exists, never executed |
| `ldb.log.toFile()` | ⚠️ | Not in test suite |
| `ldb.install_globals()` | ⚠️ | Not in test suite |



## File roles

| File | Type | What it does |
|------|------|--------------|
| `ldb.lua` | **Module** | Public API + Logger. **Entry point.** |
| `ldb_dump.lua` | **Module** | Dump, Trace, Bench. Loaded lazily. |
| `ldb_live.lua` | **Module** | Watch, Hook. Loaded lazily. |
| `main.lua` | **Example** | Demo usage. Run it to see it in action. |
| `test_ldb.lua` | **Test** | Test suite. Run it to verify. |

**Only `main.lua` and `test_ldb.lua` produce output when run.**
The other files are modules — running them directly prints a message
explaining this.



## How to run

```sh
# Linux / macOS
DBG=1 lua test_ldb.lua

# Windows PowerShell
$env:DBG = "1"; lua test_ldb.lua

# Demo
DBG=1 lua main.lua