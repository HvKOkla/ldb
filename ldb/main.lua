
local ldb = require("ldb")
ldb.enable()

local log = ldb.log.scope("App")
log.info("Demo ldb v%s", ldb._VERSION)
log.debug("Mode debug actif")
log.warn("Ceci est un avertissement")

-- Dump
ldb.dump.print({ a = 1, b = { c = 2, d = { e = 3 } } })

-- Trace
print(ldb.trace.here())

-- Bench
local function work()
    local x = 0
    for i = 1, 100 do x = x + i end
    return x
end

ldb.bench.avg("work", 1000, work)

ldb.bench.avg("inline", 10000, function()
    local s = 0
    for i = 1, 50 do s = s + i * 2 end
end)

ldb.bench.time("one-shot", work)

-- Watch
local counter = 0
ldb.watch.add("counter", function() return counter end)
ldb.watch.add("time",    function() return os.clock() end)
ldb.watch.setInterval(0.5)

for i = 1, 3 do
    counter = counter + 1
    ldb.watch.tick(0.2)
end


-- ldb.hook.break_at("main.lua", 40)
-- ldb.hook.install()

log.info("Demo terminee")
os.exit(0)