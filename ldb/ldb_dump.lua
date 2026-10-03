
local M = {}

local unpack = table.unpack or unpack
local math_type = math.type or function(_) return nil end

local function assert_function(fn, name, fname)
    if type(fn) ~= "function" then
        error(("[ldb.%s] '%s' doit être une fonction (reçu: %s)")
            :format(fname, name, type(fn)), 3)
    end
end

local function assert_string(s, name, fname)
    if type(s) ~= "string" then
        error(("[ldb.%s] '%s' doit être une string (reçu: %s)")
            :format(fname, name, type(s)), 3)
    end
end

local function ser_scalar(v)
    local t = type(v)
    if t == "string" then
        return string.format("%q", v)
    elseif t == "number" then
        if v ~= v then return "nan" end
        if v == math.huge then return "inf" end
        if v == -math.huge then return "-inf" end
        if math_type(v) == "integer" then return tostring(v) end
        return string.format("%.14g", v)
    elseif t == "boolean" then
        return tostring(v)
    elseif t == "nil" then
        return "nil"
    elseif t == "function" then
        local info = debug.getinfo(v, "S")
        return string.format("<function %s:%d>",
            info.short_src or "?", info.linedefined or -1)
    elseif t == "userdata" then
        return "<userdata " .. tostring(v) .. ">"
    elseif t == "thread" then
        return "<thread " .. tostring(v) .. ">"
    else
        return tostring(v)
    end
end

local function key_str(k)
    if type(k) == "string" and k:match("^[%a_][%w_]*$") then return k end
    return "[" .. ser_scalar(k) .. "]"
end

function M.inspect(value, opts)
    opts = opts or {}
    local max_depth = tonumber(opts.depth) or 5
    local max_items = tonumber(opts.items) or 50
    local out, seen = {}, {}

    local function rec(v, depth, indent)
        local t = type(v)

       
        if t == "table" then
            local mt = getmetatable(v)
            if mt and mt.__tostring then
                local ok, s = pcall(tostring, v)
                if ok then
                    out[#out+1] = indent .. s
                    return
                end
            end
        end

        if t ~= "table" then
            out[#out+1] = indent .. ser_scalar(v)
            return
        end
        if seen[v] then
            out[#out+1] = indent .. "<cycle>"
            return
        end
        if depth > max_depth then
            out[#out+1] = indent .. "{...}"
            return
        end

        seen[v] = true
        out[#out+1] = indent .. "{"
        local i = 0
        for k, val in pairs(v) do
            i = i + 1
            if i > max_items then
                out[#out+1] = indent .. "  ... (+" .. tostring(i - 1) .. " items)"
                break
            end
            out[#out+1] = indent .. "  " .. key_str(k) .. " = "
            rec(val, depth + 1, indent .. "  ")
        end
        out[#out+1] = indent .. "}"
        seen[v] = nil
    end

    rec(value, 0, "")
    return table.concat(out, "\n")
end

function M.print(value, opts)
    print(M.inspect(value, opts))
end

function M.tap(label, value, opts)
    print("=== " .. tostring(label) .. " ===")
    M.print(value, opts)
    return value
end

function M.stack(levels, skip)
    levels = tonumber(levels) or 15
    skip   = (tonumber(skip) or 0) + 2
    local lines = {}
    for i = skip, skip + levels do
        local info = debug.getinfo(i, "Sln")
        if not info then break end

        local line = info.currentline or -1
        local name = info.name or "?"
        local what = info.what or "?"

        -- Gestion propre des tail calls et fonctions C
        if line == -1 then
            if what == "C" then name = "<C>" else name = "<tail call>" end
        end

        lines[#lines+1] = string.format("  #%-2d %s:%d  (%s)",
            i - skip + 1,
            info.short_src or "?",
            line,
            name)
    end
    return table.concat(lines, "\n")
end

function M.here(levels)
    return M.stack(levels or 10, 1)
end

function M.error(msg, levels)
    error(string.format("%s\nStack:\n%s", tostring(msg), M.stack(levels)), 2)
end

function M.wrap(fn, name)
    assert_function(fn, "fn", "trace.wrap")
    name = name or "<anon>"
    return function(...)
        local info = debug.getinfo(2, "Sl")
        print(string.format("[TRACE] %s appelée depuis %s:%d",
            name, info.short_src or "?", info.currentline or -1))
        return fn(...)
    end
end

local _timers = {}

function M.time(label, fn, ...)
    assert_string(label, "label", "bench.time")
    assert_function(fn, "fn", "bench.time")
    local t0 = os.clock()
    local res = table.pack(fn(...))
    print(string.format("[BENCH] %-30s %8.3f ms",
        tostring(label), (os.clock() - t0) * 1000))
    return unpack(res, 1, res.n)
end

function M.avg(label, n, fn, ...)
    assert_string(label, "label", "bench.avg")
    assert_function(fn, "fn", "bench.avg")
    n = tonumber(n) or 1
    if n < 1 then n = 1 end

    -- Warmup
    for _ = 1, math.min(10, n) do fn(...) end

    local t0 = os.clock()
    for _ = 1, n do fn(...) end
    local total = (os.clock() - t0) * 1000
    print(string.format("[BENCH] %-30s %8.3f ms (x%d)",
        tostring(label), total / n, n))
end

function M.start(label)
    assert_string(label, "label", "bench.start")
    _timers[label] = os.clock()
end

function M.stop(label)
    assert_string(label, "label", "bench.stop")
    local t0 = _timers[label]
    if not t0 then
        error(("[ldb.bench.stop] Timer '%s' non démarré")
            :format(tostring(label)), 2)
    end
    _timers[label] = nil
    local dt = (os.clock() - t0) * 1000
    print(string.format("[BENCH] %-30s %8.3f ms", tostring(label), dt))
    return dt
end

return M