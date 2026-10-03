-- main.lua : test de ldb sans Love2D
local ldb = require("ldb")

local log = ldb.log.scope("App")
log.info("Démarrage v%s", "1.0.0")
log.debug("Mode debug actif")
log.warn("Ceci est un avertissement")

ldb.dump.print({ a = 1, b = { c = 2, d = { e = 3 } } })

print(ldb.trace.here())

local function work()
    local x = 0
    for i = 1, 100 do x = x + i end
    return x
end

ldb.bench.avg("work", 1000, work)

-- Variante : fonction inline
ldb.bench.avg("inline", 10000, function()
    local s = 0
    for i = 1, 50 do s = s + i * 2 end
end)

ldb.bench.time("one-shot", work)

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

log.info("Tests terminés ")