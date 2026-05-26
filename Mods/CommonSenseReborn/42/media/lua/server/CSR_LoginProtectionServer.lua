require "CSR_FeatureFlags"

CSR_LoginProtectionServer = CSR_LoginProtectionServer or {}
CSR_LoginProtectionServer.active = CSR_LoginProtectionServer.active or {}
CSR_LoginProtectionServer.started = CSR_LoginProtectionServer.started or {}
CSR_LoginProtectionServer.zombieRefs = CSR_LoginProtectionServer.zombieRefs or {}

local MODULE = "CSR_LoginProtection"
local CMD_REQUEST = "Request"
local CMD_START = "Start"
local CMD_FINISH = "Finish"
local ZOMBIE_RADIUS = 30
local ZOMBIE_PULSE_MS = 500

local function nowMs()
    if getTimestampMs then
        return getTimestampMs()
    end
    return (getTimestamp and getTimestamp() or 0) * 1000
end

local unpackArgs = unpack or (table and table.unpack)
local function safeCall(obj, methodName, ...)
    if not obj or not methodName then return false end
    local fn = obj[methodName]
    if not fn then return false end
    local args = { ... }
    local ok = pcall(function()
        fn(obj, unpackArgs(args))
    end)
    return ok == true
end

local function safeBool(obj, methodName)
    if not obj or not methodName then return false end
    local fn = obj[methodName]
    if not fn then return false end
    local ok, result = pcall(function()
        return fn(obj)
    end)
    return ok == true and result == true
end

local function isEnabled()
    return CSR_FeatureFlags
        and CSR_FeatureFlags.isLoginProtectionEnabled
        and CSR_FeatureFlags.isLoginProtectionEnabled()
end

local function getDurationSeconds()
    if CSR_FeatureFlags and CSR_FeatureFlags.getLoginProtectionSeconds then
        return CSR_FeatureFlags.getLoginProtectionSeconds()
    end
    return 45
end

local function playerKey(player)
    if not player then return nil end

    if player.getOnlineID then
        local ok, onlineId = pcall(function()
            return player:getOnlineID()
        end)
        if ok and onlineId ~= nil then
            return tostring(onlineId)
        end
    end

    if player.getUsername then
        local ok, username = pcall(function()
            return player:getUsername()
        end)
        if ok and username ~= nil then
            return tostring(username)
        end
    end

    return tostring(player)
end

local function protectZombieForState(state, zombie)
    if not state or not zombie then return end
    if state.zombies[zombie] then return end

    local refs = CSR_LoginProtectionServer.zombieRefs
    local entry = refs[zombie]
    if not entry then
        entry = {
            count = 0,
            useless = safeBool(zombie, "isUseless"),
        }
        refs[zombie] = entry
    end

    entry.count = entry.count + 1
    state.zombies[zombie] = true
    safeCall(zombie, "setUseless", true)
    safeCall(zombie, "setNoDamage", true)
end

local function releaseZombiesForState(state)
    if not state or not state.zombies then return end

    local refs = CSR_LoginProtectionServer.zombieRefs
    for zombie, _ in pairs(state.zombies) do
        local entry = refs[zombie]
        if entry then
            entry.count = (entry.count or 1) - 1
            if entry.count <= 0 then
                safeCall(zombie, "setUseless", entry.useless == true)
                safeCall(zombie, "setNoDamage", false)
                refs[zombie] = nil
            end
        end
    end

    state.zombies = {}
end

local function calmNearbyZombies(player, state, currentTime)
    if not player or not state or not getCell or not instanceof then return end
    if (state.nextZombiePulseMs or 0) > currentTime then return end
    state.nextZombiePulseMs = currentTime + ZOMBIE_PULSE_MS

    local cell = getCell()
    if not cell or not cell.getGridSquare then return end

    local px = player:getX()
    local py = player:getY()
    local pz = math.floor(player:getZ() or 0)
    local radiusSq = ZOMBIE_RADIUS * ZOMBIE_RADIUS
    local minX = math.floor(px - ZOMBIE_RADIUS)
    local maxX = math.floor(px + ZOMBIE_RADIUS)
    local minY = math.floor(py - ZOMBIE_RADIUS)
    local maxY = math.floor(py + ZOMBIE_RADIUS)

    for x = minX, maxX do
        for y = minY, maxY do
            local dx = (x + 0.5) - px
            local dy = (y + 0.5) - py
            if (dx * dx + dy * dy) <= radiusSq then
                local square = cell:getGridSquare(x, y, pz)
                local movers = square and square.getMovingObjects and square:getMovingObjects() or nil
                if movers then
                    for i = 0, movers:size() - 1 do
                        local obj = movers:get(i)
                        if obj and instanceof(obj, "IsoZombie") and not safeBool(obj, "isDead") then
                            protectZombieForState(state, obj)
                        end
                    end
                end
            end
        end
    end
end

local function forceProtectedState(player, state)
    if not player or not state then return end

    safeCall(player, "setInvisible", true)
    safeCall(player, "setGhostMode", true)
    safeCall(player, "setGodMod", true)
    safeCall(player, "setHealthCheat", true)
    calmNearbyZombies(player, state, nowMs())
end

local function finishProtection(key, state, notifyClient)
    if not key or not state then return end

    local player = state.player
    if player then
        local original = state.original or {}
        safeCall(player, "setInvisible", original.invisible == true)
        safeCall(player, "setGhostMode", original.ghost == true)
        safeCall(player, "setGodMod", original.god == true)
        safeCall(player, "setHealthCheat", original.healthCheat == true)

        if notifyClient ~= false and sendServerCommand then
            sendServerCommand(player, MODULE, CMD_FINISH, {})
        end
    end

    releaseZombiesForState(state)
    CSR_LoginProtectionServer.active[key] = nil
end

local function applyProtection(player)
    if not player then return end

    local key = playerKey(player)
    if not key then return end

    if CSR_LoginProtectionServer.started[key] then
        return
    end

    if not isEnabled() then
        if sendServerCommand then
            sendServerCommand(player, MODULE, CMD_FINISH, {})
        end
        return
    end

    local duration = getDurationSeconds()
    CSR_LoginProtectionServer.started[key] = true
    local state = CSR_LoginProtectionServer.active[key]
    if not state then
        state = {
            player = player,
            original = {
                invisible = safeBool(player, "isInvisible"),
                ghost = safeBool(player, "isGhostMode"),
                god = safeBool(player, "isGodMod"),
                healthCheat = safeBool(player, "isHealthCheat"),
            },
            zombies = {},
            nextZombiePulseMs = 0,
        }
        CSR_LoginProtectionServer.active[key] = state
    end

    state.player = player
    state.endTimeMs = nowMs() + (duration * 1000)
    forceProtectedState(player, state)

    if sendServerCommand then
        sendServerCommand(player, MODULE, CMD_START, { duration = duration })
    end
end

local function onClientCommand(module, command, player, args)
    if module ~= MODULE or command ~= CMD_REQUEST then return end
    applyProtection(player)
end

local function onTick()
    local currentTime = nowMs()
    for key, state in pairs(CSR_LoginProtectionServer.active) do
        if not isEnabled() or currentTime >= (state.endTimeMs or 0) then
            finishProtection(key, state)
        else
            forceProtectedState(state.player, state)
        end
    end
end

local function onPlayerDeath(player)
    local key = playerKey(player)
    if key and CSR_LoginProtectionServer.active[key] then
        finishProtection(key, CSR_LoginProtectionServer.active[key])
    end
end

local function onPlayerDisconnect(player)
    local key = playerKey(player)
    if not key then return end
    if CSR_LoginProtectionServer.active[key] then
        finishProtection(key, CSR_LoginProtectionServer.active[key], false)
    end
    CSR_LoginProtectionServer.started[key] = nil
end

if Events then
    if Events.OnClientCommand then Events.OnClientCommand.Add(onClientCommand) end
    if Events.OnTick then Events.OnTick.Add(onTick) end
    if Events.OnPlayerDeath then Events.OnPlayerDeath.Add(onPlayerDeath) end
    if Events.OnPlayerDisconnect then Events.OnPlayerDisconnect.Add(onPlayerDisconnect) end
end
