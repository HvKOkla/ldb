
local ok, ldb = pcall(require, "ldb")
if not ok then
    io.stderr:write("[FATAL] Cannot load ldb: " .. tostring(ldb) .. "\n")
    os.exit(1)
end

ldb.enable()
ldb.enabled = true

local function ljust(s, n)
    s = tostring(s)
    if #s >= n then return s end
    return s .. string.rep(" ", n - #s)
end

local function line(c) return string.rep(c or "=", 62) end

local function section(n, title)
    print()
    print(line("-"))
    print(ljust(("  [%d] %s"):format(n, title), 62))
    print(line("-"))
end

local function info(msg) print("  [i] " .. msg) end
local function ok(msg)   print("  [OK] " .. msg) end

print()
print(line())
print(ljust("  ldb v" .. ldb._VERSION .. " - test suite", 62))
print(line())

section(1, "LOGGER")
ldb.log.info ("Test", "hello %s", "world")
ldb.log.debug("Test", "debug message")
ldb.log.warn ("Test", "warning")
ldb.log.trace("Test", "trace")
ldb.log.scope("Scope").info("scoped logger works")
ok("Logger OK")

section(2, "DUMP")
ldb.dump.print({ a = 1, b = { c = 2, d = 3 } })
ok("Dump OK")

section(3, "TRACE")
print(ldb.trace.here())
ok("Trace OK")

section(4, "BENCH")
local function work()
    local s = 0
    for i = 1, 500 do s = s + i end
    return s
end
ldb.bench.avg("named-function", 10000, work)
ldb.bench.time("single-run", work)
ldb.bench.start("manual-timer")
for i = 1, 1000 do local x = i * 2 end
ldb.bench.stop("manual-timer")
ok("All benchmark modes work")

section(5, "WATCH")
local counter = 0
ldb.watch.add("counter", function() return counter end)
ldb.watch.setInterval(0.3)
for i = 1, 3 do
    counter = counter + 1
    ldb.watch.tick(0.15)
end
ok("Watch OK")

print()
print(line())
print(ljust("  [OK] Core tests passed", 62))
print(ljust("       (hook, toFile, install_globals NOT tested)", 62))
print(line())
print()

os.exit(0)