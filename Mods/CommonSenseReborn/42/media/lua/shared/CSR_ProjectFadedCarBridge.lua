--[[
    CSR_ProjectFadedCarBridge.lua

    Lightweight CSR-side adapter for Project Faded Car's public bridge API.
    It does not poll, scan chunks, or create vehicle identity records; callers
    ask for bridge data only when they already have a live vehicle object.
]]

CSR_ProjectFadedCarBridge = CSR_ProjectFadedCarBridge or {}

local Bridge = CSR_ProjectFadedCarBridge
local DEFAULT_CACHE_MS = 1500

local snapshotCache = setmetatable({}, { __mode = "k" })
local tuneCache = setmetatable({}, { __mode = "k" })

local function nowMs()
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    if getTimestamp then return (tonumber(getTimestamp()) or 0) * 1000 end
    return os and os.time and os.time() * 1000 or 0
end

local function cacheIsFresh(entry, now, maxAgeMs)
    return entry and (maxAgeMs <= 0 or now - (entry.time or 0) <= maxAgeMs)
end

local function clampPercent(value)
    value = tonumber(value)
    if not value then return nil end
    if value < 75 then return 75 end
    if value > 125 then return 125 end
    return value
end

function Bridge.getAPI()
    local pfc = ProjectFadedCar
    local api = pfc and pfc.API or nil
    if type(api) == "table" then return api end
    return nil
end

function Bridge.isAvailable()
    return Bridge.getAPI() ~= nil
end

function Bridge.getVersion()
    local api = Bridge.getAPI()
    return api and api.version or nil
end

function Bridge.invalidate(vehicle)
    if vehicle then
        snapshotCache[vehicle] = nil
        tuneCache[vehicle] = nil
    else
        snapshotCache = setmetatable({}, { __mode = "k" })
        tuneCache = setmetatable({}, { __mode = "k" })
    end
end

function Bridge.getSnapshot(vehicle, maxAgeMs)
    if not vehicle then return nil end

    local api = Bridge.getAPI()
    if not api or type(api.getSnapshot) ~= "function" then return nil end

    local now = nowMs()
    local ttl = tonumber(maxAgeMs) or DEFAULT_CACHE_MS
    local entry = snapshotCache[vehicle]
    if cacheIsFresh(entry, now, ttl) then return entry.value end

    local snapshot = api.getSnapshot(vehicle)
    snapshotCache[vehicle] = { time = now, value = snapshot }
    return snapshot
end

function Bridge.getTowAssistPercent(vehicle, maxAgeMs)
    if not vehicle then return nil end

    local api = Bridge.getAPI()
    if not api or type(api.getVehicleTune) ~= "function" then return nil end

    local now = nowMs()
    local ttl = tonumber(maxAgeMs) or DEFAULT_CACHE_MS
    local entry = tuneCache[vehicle]
    if cacheIsFresh(entry, now, ttl) then return entry.value end

    local percent = clampPercent(api.getVehicleTune(vehicle, "towAssist"))
    tuneCache[vehicle] = { time = now, value = percent }
    return percent
end

function Bridge.applyTowAssistFactor(vehicle, baseFactor, maxAgeMs)
    baseFactor = tonumber(baseFactor)
    if not baseFactor or baseFactor == 0 then return baseFactor end

    local percent = Bridge.getTowAssistPercent(vehicle, maxAgeMs)
    if not percent then return baseFactor end

    return baseFactor * (percent / 100.0)
end

function Bridge.canReachEngine(playerObj, vehicle)
    local api = Bridge.getAPI()
    if not api or type(api.canReachEngine) ~= "function" then return nil end
    return api.canReachEngine(playerObj, vehicle) == true
end

function Bridge.openServicePanel(playerObj, vehicle)
    local api = Bridge.getAPI()
    if not api or type(api.openServicePanel) ~= "function" then return false end
    return api.openServicePanel(playerObj, vehicle) == true
end

return Bridge
