require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/Data/Schemas"
require "CSRAdminCommandCenter/Utils/Time"

local ACC = CSRAdminCommandCenter
ACC.Persistence = ACC.Persistence or {}

local Persistence = ACC.Persistence
local Keys = ACC.Schemas.Keys
local LogFiles = ACC.Schemas.LogFiles

Persistence.queue = Persistence.queue or {}

local function root()
    if not getGameTime then return nil end
    local gt = getGameTime()
    if not gt or not gt.getModData then return nil end
    local md = gt:getModData()
    if not md then return nil end
    md[Keys.Root] = md[Keys.Root] or {}
    return md[Keys.Root]
end

local function tailKeyFor(kind)
    if kind == "claims" then return Keys.ClaimHistoryTail end
    if kind == "journal" then return Keys.JournalHistoryTail end
    if kind == "authority" then return Keys.AuthorityHistoryTail end
    if kind == "movement" then return Keys.MovementHistoryTail end
    if kind == "padlocks" then return Keys.PadlockHistoryTail end
    if kind == "cleanup" then return Keys.CleanupHistoryTail end
    if kind == "access" then return Keys.AccessHistoryTail end
    if kind == "settings" then return Keys.SettingsHistoryTail end
    return Keys.DebugState .. "_Tail"
end

local function appendTail(kind, line, maxLines)
    local r = root()
    if not r then return end
    local key = tailKeyFor(kind)
    r[key] = r[key] or {}
    local tail = r[key]
    tail[#tail + 1] = tostring(line or "")
    local max = tonumber(maxLines) or 200
    while #tail > max do
        table.remove(tail, 1)
    end
end

function Persistence.getRoot()
    return root()
end

function Persistence.enqueue(kind, line)
    kind = tostring(kind or "debug")
    local stamped = "[" .. ACC.Time.stamp() .. "] " .. tostring(line or "")
    appendTail(kind, stamped, 200)
    Persistence.queue[#Persistence.queue + 1] = { kind = kind, line = stamped }
    if #Persistence.queue >= 20 then
        Persistence.flush()
    end
end

function Persistence.flush()
    if not isServer or not isServer() then return end
    if not getFileWriter then
        Persistence.queue = {}
        return
    end
    if #Persistence.queue == 0 then return end

    local pending = Persistence.queue
    Persistence.queue = {}

    for i = 1, #pending do
        local item = pending[i]
        local filename = LogFiles[item.kind] or LogFiles.debug or "csr_acc_debug.log"
        local writer = getFileWriter(filename, true, true)
        if writer then
            writer:write(tostring(item.line or "") .. "\r\n")
            writer:close()
        end
    end
end

function Persistence.tail(kind, maxLines)
    local r = root()
    local out = {}
    if not r then return out end
    local tail = r[tailKeyFor(kind)] or {}
    local max = tonumber(maxLines) or 50
    local start = math.max(1, #tail - max + 1)
    for i = start, #tail do
        out[#out + 1] = tostring(tail[i] or "")
    end
    return out
end

function Persistence.stateTable(key)
    local r = root()
    if not r then return {} end
    r[key] = r[key] or {}
    return r[key]
end

return Persistence
