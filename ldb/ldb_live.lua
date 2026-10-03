
local M = {}

M._items    = {}
M._interval = 1.0
M._last     = 0

function M.add(name, getter)
    if type(name) ~= "string"     then error("ldb.watch.add: name doit être string", 2) end
    if type(getter) ~= "function" then error("ldb.watch.add: getter doit être function", 2) end
    M._items[name] = getter
end

function M.remove(name) M._items[name] = nil end
function M.clear()      M._items = {} end

function M.snapshot()
    local snap = {}
    for n, g in pairs(M._items) do
        local ok, v = pcall(g)
        snap[n] = ok and v or ("<err: " .. tostring(v) .. ">")
    end
    return snap
end

function M.print()
    print("=== WATCH ===")
    for n, v in pairs(M.snapshot()) do
        print(string.format("  %-20s = %s", n, tostring(v)))
    end
    print("=============")
end

function M.tick(dt)
    M._last = M._last + (dt or 0)
    if M._last >= M._interval then
        M._last = 0
        M.print()
    end
end

function M.setInterval(s) M._interval = s end

-- ============================================================================
-- HOOK (breakpoints + step)
-- ============================================================================
M.breakpoints = {}
M.condition   = nil
M.on_hit      = nil
M.enabled     = false
M.step_mode   = false
M._installed  = false

local function bp_key(f, l) return (f or "?") .. ":" .. (l or -1) end

function M.break_at(file, line)     M.breakpoints[bp_key(file, line)] = true end
function M.remove_break(file, line) M.breakpoints[bp_key(file, line)] = nil end
function M.clear_breaks()           M.breakpoints = {} end
function M.set_handler(fn)          M.on_hit = fn end
function M.set_condition(fn)        M.condition = fn end

local function default_handler(info)
    print(string.format("\n  BREAKPOINT %s:%d", info.short_src, info.currentline))
    print("  Locals :")
    local i = 1
    while true do
        local name, value = debug.getlocal(2, i)
        if not name then break end
        print(string.format("    %-20s = %s", name, tostring(value)))
        i = i + 1
    end
end

local function hook_fn(_, line)
    if not M.enabled then return end
    local info = debug.getinfo(2, "Sl")
    if not info then return end
    local hit = M.breakpoints[bp_key(info.short_src, line)] or M.step_mode
    if hit and M.condition then
        local ok, res = pcall(M.condition, info)
        if not ok or not res then hit = false end
    end
    if hit then (M.on_hit or default_handler)(info) end
end

function M.install()
    if M._installed then return end
    debug.sethook(hook_fn, "l")
    M._installed = true
    M.enabled = true
end

function M.uninstall()
    debug.sethook()
    M._installed = false
    M.enabled = false
    M.step_mode = false
end

function M.step() M.step_mode = true end
function M.cont() M.step_mode = false end

return M