
local ldb = {
    _VERSION = "0.1.2",
    _NAME    = "ldb",
    _URL     = "https://codeberg.org/HvK_Okla/ldb",
}


local function env_enabled()
    local v = os.getenv("DBG")
    if v == "1" or v == "true" then return true end
    if rawget(_G, "DEV") == true then return true end
    return false
end

ldb.enabled = env_enabled()
function ldb.enable()  ldb.enabled = true  end
function ldb.disable() ldb.enabled = false end


local Logger = {}
ldb.log = Logger

Logger.LEVELS = { TRACE=0, DEBUG=1, INFO=2, WARN=3, ERROR=4, FATAL=5, OFF=99 }
Logger._level    = Logger.LEVELS.INFO
Logger._targets  = {}
Logger._file     = nil
Logger._start    = os.clock()
Logger._no_color = os.getenv("NO_COLOR") ~= nil
                     or (package.config:sub(1,1) == "\\" and not os.getenv("WT_SESSION"))

local COLORS = {
    TRACE="\27[90m", DEBUG="\27[36m", INFO="\27[32m",
    WARN="\27[33m",  ERROR="\27[31m", FATAL="\27[35m\27[1m",
    RESET="\27[0m",
}

function Logger.setLevel(l) Logger._level = Logger.LEVELS[l] or l end
function Logger.only(m)    Logger._targets[m] = true  end
function Logger.except(m)  Logger._targets[m] = false end

function Logger.reset()
    Logger._targets = {}
    Logger._level = Logger.LEVELS.INFO
end

function Logger.toFile(path)
    if Logger._file then Logger._file:close() end
    local f, err = io.open(path, "w")
    if not f then error("[ldb] Impossible d'ouvrir " .. path .. ": " .. tostring(err)) end
    Logger._file = f
end

function Logger.close()
    if Logger._file then Logger._file:close(); Logger._file = nil end
end

local function should_log(level, mod)
    if not ldb.enabled then return false end
    if Logger.LEVELS[level] < Logger._level then return false end
    local has_explicit = false
    for _, v in pairs(Logger._targets) do
        if v == true then has_explicit = true; break end
    end
    if has_explicit then return Logger._targets[mod] == true end
    return true
end

local function emit(level, mod, msg, ...)
    if not should_log(level, mod) then return end
    local formatted
    if select("#", ...) > 0 then
        local ok, res = pcall(string.format, msg, ...)
        formatted = ok and res or (tostring(msg) .. " <bad fmt: " .. tostring(res) .. ">")
    else
        formatted = tostring(msg)
    end
    local elapsed = os.clock() - Logger._start
    local line = string.format("[%7.3f] [%-5s] [%-10s] %s",
        elapsed, level, mod or "-", formatted)
    if Logger._file then
        Logger._file:write(line, "\n"); Logger._file:flush()
    else
        if Logger._no_color then print(line)
        else print(COLORS[level] .. line .. COLORS.RESET) end
    end
end

function Logger.trace(m, ...) emit("TRACE", m, ...) end
function Logger.debug(m, ...) emit("DEBUG", m, ...) end
function Logger.info (m, ...) emit("INFO",  m, ...) end
function Logger.warn (m, ...) emit("WARN",  m, ...) end
function Logger.error(m, ...) emit("ERROR", m, ...) end
function Logger.fatal(m, ...) emit("FATAL", m, ...) end

function Logger.scope(prefix)
    local sub = {}
    for _, lvl in ipairs({"trace","debug","info","warn","error","fatal"}) do
        local up = lvl:upper()
        sub[lvl] = function(msg, ...) emit(up, prefix, msg, ...) end
    end
    sub.scope    = function(p) return Logger.scope(prefix .. "." .. p) end
    sub.setLevel = Logger.setLevel
    sub.only     = Logger.only
    return sub
end


local function lazy(name, methods)
    local mod = nil
    local proxy = {}
    for _, m in ipairs(methods) do
        proxy[m] = function(...)
            if not mod then
                local ok, loaded = pcall(require, name)
                if not ok then
                    error("[ldb] Module '" .. name .. "' introuvable.\n" ..
                          "Copie " .. name .. ".lua a cote de ldb.lua.", 2)
                end
                mod = loaded
            end
            return mod[m](...)
        end
    end
    return proxy
end

ldb.dump  = lazy("ldb_dump",  {"print", "inspect", "tap"})
ldb.trace = lazy("ldb_dump",  {"stack", "here", "error", "wrap"})
ldb.bench = lazy("ldb_dump",  {"time", "avg", "start", "stop"})
ldb.watch = lazy("ldb_live",  {"add", "remove", "clear", "print", "tick",
                               "setInterval", "snapshot"})
ldb.hook  = lazy("ldb_live",  {"break_at", "remove_break", "clear_breaks",
                               "install", "uninstall", "step", "cont",
                               "set_handler", "set_condition"})


function ldb.install_globals()
    _G.ldb_log  = Logger
    _G.ldb_dump = ldb.dump.print
    _G.ldb_trc  = ldb.trace.here
    _G.ldb_w    = ldb.watch.add
end


if ... == nil then
    io.stderr:write("ldb.lua is a module, not a script.\n")
    io.stderr:write("Use: local ldb = require('ldb')\n")
    io.stderr:write("Run 'test_ldb.lua' to test it, or 'main.lua' for a demo.\n")
end

return ldb