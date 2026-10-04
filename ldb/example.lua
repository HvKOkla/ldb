

local ldb = require("ldb")
ldb.enable()

-- 1. Log a message
ldb.log.info("Example", "ldb v%s loaded", ldb._VERSION)

-- 2. Dump a table
ldb.dump.print({ user = "alice", age = 30 })

-- 3. See where you are
print(ldb.trace.here())

-- 4. Time a function
ldb.bench.avg("loop", 10000, function()
    local x = 0
    for i = 1, 100 do x = x + i end
end)

-- 5. Watch a variable
local score = 0
ldb.watch.add("score", function() return score end)
ldb.watch.setInterval(0.01)
for i = 1, 5 do
    score = score + 10
    ldb.watch.tick(0.01)
end

print("Example done.")
os.exit(0)