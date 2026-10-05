# ldb

> A tiny, zero-dependency debugger for Lua.
> Log, dump, trace, benchmark, watch, and break — all in 3 files.
> 
> ⚠️ **Status: alpha (0.1.x)**
> The API is **not stable yet**. Expect breaking changes until 1.0.0.
> Use in production at your own risk.
> See [STATUS.md](STATUS.md) for what's tested.
>
> 
[![Lua](https://img.shields.io/badge/Lua-5.1%20|%205.2%20|%205.3%20|%205.4%20|%20LuaJIT-blue)](https://www.lua.org/)



## Features

- **Logger** — level-based (TRACE/DEBUG/INFO/WARN/ERROR/FATAL), scoped, colored, file output
- **Dump** — inspect any table, handles cycles, depth & item limits, `__tostring` support
- **Trace** — clean stack traces, handles tail calls and C functions
- **Bench** — `time`, `avg`, `start`/`stop` for quick profiling
- **Watch** — monitor variables in real time with a simple tick
- **Hook** — conditional breakpoints and step mode via `debug.sethook`
- **Zero dependency** — pure Lua, no C, no FFI
- **3 files** — `ldb.lua`, `ldb_dump.lua`, `ldb_live.lua`


## Installation

### Option 1 — Copy the files

Drop `ldb.lua`, `ldb_dump.lua` and `ldb_live.lua` in your project folder.

### Option 2 — LuaRocks (coming soon)

```sh
luarocks install ldb
```

### Option 3 — Git clone

```sh
git clone https://codeberg.org/<your-user>/ldb.git
```

---

## 🚀 Quick start

```lua
local ldb = require("ldb")
ldb.enable()  -- or set DBG=1 in your environment

-- Logger with scope
local log = ldb.log.scope("App")
log.info("Starting v%s", "1.0.0")
log.warn("Config file not found")

-- Dump any table
ldb.dump.print({ a = 1, b = { c = 2 } })

-- Stack trace
print(ldb.trace.here())

-- Benchmark
ldb.bench.avg("update", 1000, function()
    local x = 0
    for i = 1, 100 do x = x + i end
end)

-- Watch a variable
ldb.watch.add("fps", function() return love.timer.getFPS() end)
function love.update(dt) ldb.watch.tick(dt) end

-- Breakpoints
ldb.hook.break_at("main.lua", 42)
ldb.hook.install()
```

## API Reference

### `ldb` (root)

| Function | Description |
|----------|-------------|
| `ldb.enable()` | Enable the debugger |
| `ldb.disable()` | Disable the debugger |
| `ldb.enabled` | Boolean flag (auto from `DBG` env or `_G.DEV`) |
| `ldb.install_globals()` | Expose `ldb_log`, `ldb_dump`, `ldb_trc`, `ldb_w` as globals |


### `ldb.log` — Logger

| Function | Description |
|----------|-------------|
| `ldb.log.trace(mod, fmt, ...)` | Log at TRACE level |
| `ldb.log.debug(mod, fmt, ...)` | Log at DEBUG level |
| `ldb.log.info(mod, fmt, ...)` | Log at INFO level |
| `ldb.log.warn(mod, fmt, ...)` | Log at WARN level |
| `ldb.log.error(mod, fmt, ...)` | Log at ERROR level |
| `ldb.log.fatal(mod, fmt, ...)` | Log at FATAL level |
| `ldb.log.setLevel("WARN")` | Set minimum level |
| `ldb.log.only("Module")` | Whitelist a module |
| `ldb.log.except("Module")` | Blacklist a module |
| `ldb.log.reset()` | Reset filters |
| `ldb.log.toFile("debug.log")` | Redirect output to a file |
| `ldb.log.close()` | Close the log file |
| `ldb.log.scope("Prefix")` | Create a scoped sub-logger |

**Levels**: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`, `OFF`


### `ldb.dump` — Table inspection

| Function | Description |
|----------|-------------|
| `ldb.dump.print(value, opts)` | Print a readable representation |
| `ldb.dump.inspect(value, opts)` | Return it as a string |
| `ldb.dump.tap(label, value, opts)` | Print and return the value |

**Options**:
- `depth` (default `5`) — max recursion depth
- `items` (default `50`) — max items per table

**Handles**: cycles, `__tostring`, functions, userdata, threads.

### `ldb.trace` — Stack traces

| Function | Description |
|----------|-------------|
| `ldb.trace.here(levels)` | Return the current stack trace |
| `ldb.trace.stack(levels, skip)` | Custom stack trace |
| `ldb.trace.error(msg)` | Raise an error with a stack trace |
| `ldb.trace.wrap(fn, name)` | Wrap a function to log calls |

### `ldb.bench` — Benchmarks

| Function | Description |
|----------|-------------|
| `ldb.bench.avg(label, n, fn, ...)` | Average over `n` runs |
| `ldb.bench.time(label, fn, ...)` | Single run |
| `ldb.bench.start(label)` | Start a manual timer |
| `ldb.bench.stop(label)` | Stop it and print the elapsed time |


### `ldb.watch` — Variable monitoring

| Function | Description |
|----------|-------------|
| `ldb.watch.add(name, getter)` | Register a variable |
| `ldb.watch.remove(name)` | Unregister |
| `ldb.watch.clear()` | Remove all |
| `ldb.watch.snapshot()` | Return a table of current values |
| `ldb.watch.print()` | Print all watched variables |
| `ldb.watch.tick(dt)` | Call each frame — prints every `interval` seconds |
| `ldb.watch.setInterval(sec)` | Change the print interval |


### `ldb.hook` — Breakpoints

| Function | Description |
|----------|-------------|
| `ldb.hook.break_at(file, line)` | Set a breakpoint |
| `ldb.hook.remove_break(file, line)` | Remove one |
| `ldb.hook.clear_breaks()` | Remove all |
| `ldb.hook.install()` | Install the debug hook (slow) |
| `ldb.hook.uninstall()` | Remove the hook |
| `ldb.hook.step()` | Enable step mode |
| `ldb.hook.cont()` | Resume execution |
| `ldb.hook.set_handler(fn)` | Custom handler |
| `ldb.hook.set_condition(fn)` | Conditional breakpoints |

**Warning**: `install()` uses `debug.sethook` and slows execution **10× to 100×**.
Use it only in development.

## What does each file do?

| File | Role | Loaded when? |
|------|------|--------------|
| `ldb.lua` | **Public API + Logger** — the only file you need to `require()` | Always (entry point) |
| `ldb_dump.lua` | **Dump, Trace, Bench** — table inspection, stack traces, benchmarks | Lazily, when you call `ldb.dump.*`, `ldb.trace.*`, or `ldb.bench.*` |
| `ldb_live.lua` | **Watch, Hook** — real-time variable monitoring and breakpoints | Lazily, when you call `ldb.watch.*` or `ldb.hook.*` |
| `test_ldb.lua` | **Test suite** — verifies all modules work | Only when you run it manually |

### How lazy loading works

You only need to `require("ldb")`. The other files are loaded **on demand** the first time you use one of their functions.

```lua
local ldb = require("ldb")   

ldb.log.info("App", "hi")    

ldb.dump.print({ a = 1 })    
ldb.bench.avg("test", 1000, fn)  

ldb.watch.add("fps", getFPS) 
```

If `ldb_dump.lua` or `ldb_live.lua` is missing, `ldb.lua` still works — only the missing module errors.

### Running the tests

```sh
DBG=1 lua test_ldb.lua          # Linux / macOS
$env:DBG = "1"; lua test_ldb.lua  # Windows PowerShell
```

Expected output ends with:
```
========================================
  ✅ All tests passed
========================================
```


## Environment activation

`ldb` is **silent by default**. To enable it:

**Linux / macOS**
```sh
DBG=1 lua main.lua
```

**Windows (PowerShell)**
```powershell
$env:DBG = "1"; lua main.lua
```

**Windows (CMD)**
```cmd
set DBG=1 && lua main.lua
```

Or from Lua:
```lua
DEV = true          -- before requiring ldb
local ldb = require("ldb")
```

---

## Running the tests

```sh
DBG=1 lua test_ldb.lua
```

Expected output ends with:
```
Tests terminés

```

And exit code `0`.



## Compatibility

| Lua version | Status |
|-------------|--------|
| Lua 5.1     | ✅ Tested |
| Lua 5.2     | ✅ Compatible (fallbacks) |
| Lua 5.3     | ✅ Compatible |
| Lua 5.4     | ✅ Compatible |
| LuaJIT 2.x  | ✅ Compatible |

## Contributing

Pull requests are welcome!
For major changes, please open an issue first.

1. Fork the repo
2. Create your branch (`git checkout -b feature/amazing`)
3. Commit (`git commit -m "Add amazing feature"`)
4. Push (`git push origin feature/amazing`)
5. Open a Pull Request


##  License

Apache 2.0 — see [LICENSE](LICENSE) for details.


##  Inspiration

- [Zerobrane Studio](https://studio.zerobrane.com/)
- [MobDebug](https://github.com/pkulchenko/MobDebug)
- [debugger.lua](https://github.com/slembcke/debugger.lua)
- [lume.lua](https://github.com/rxi/lume)


**Made with ❤️ and Lua.**