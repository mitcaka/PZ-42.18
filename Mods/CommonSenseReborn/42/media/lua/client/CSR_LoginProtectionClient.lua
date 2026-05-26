require "CSR_FeatureFlags"

CSR_LoginProtectionClient = CSR_LoginProtectionClient or {}
CSR_LoginProtectionClient.states = CSR_LoginProtectionClient.states or {}
CSR_LoginProtectionClient.zombieRefs = CSR_LoginProtectionClient.zombieRefs or {}

local MODULE = "CSR_LoginProtection"
local CMD_REQUEST = "Request"
local CMD_START = "Start"
local CMD_FINISH = "Finish"
local ZOMBIE_RADIUS = 30
local ZOMBIE_PULSE_MS = 500
local OUTLINE_R = 178 / 255
local OUTLINE_G = 51 / 255
local OUTLINE_B = 255 / 255
local OUTLINE_A = 0.85
local HALO_R = 178
local HALO_G = 51
local HALO_B = 255
local unpackArgs = unpack or (table and table.unpack)

local function nowMs()
    if getTimestampMs then
        return getTimestampMs()
    end
    return (getTimestamp and getTimestamp() or 0) * 1000
end

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

local function getPlayerNum(player)
    if player and player.getPlayerNum then
        local ok, num = pcall(function()
            return player:getPlayerNum()
        end)
        if ok and num ~= nil then return num end
    end
    return 0
end

local function getLocalPlayer(playerNum)
    if playerNum ~= nil and getSpecificPlayer then
        local player = getSpecificPlayer(playerNum)
        if player then return player end
    end
    return getPlayer and getPlayer() or nil
end

local function getState(player)
    local key = getPlayerNum(player)
    local state = CSR_LoginProtectionClient.states[key]
    if not state then
        state = {
            active = false,
            startedOnce = false,
            endTimeMs = 0,
            nextZombiePulseMs = 0,
            original = nil,
            zombies = {},
        }
        CSR_LoginProtectionClient.states[key] = state
    end
    return state
end

local function translatedStarted(duration)
    if getText then
        local ok, value = pcall(getText, "IGUI_CSR_LoginProtectionStarted", tostring(duration))
        if ok and value and value ~= "IGUI_CSR_LoginProtectionStarted" then
            return value
        end
    end
    return "Login protection active for " .. tostring(duration) .. " seconds."
end

local function translatedEnded()
    if getText then
        local ok, value = pcall(getText, "IGUI_CSR_LoginProtectionEnded")
        if ok and value and value ~= "IGUI_CSR_LoginProtectionEnded" then
            return value
        end
    end
    return "Login protection ended."
end

local function showHalo(player, text)
    if not player or not text or text == "" then return end
    if player.setHaloNote then
        safeCall(player, "setHaloNote", text, HALO_R, HALO_G, HALO_B, 300)
    elseif player.Say then
        safeCall(player, "Say", text)
    end
end

local function rememberOriginal(state, player)
    if state.original then return end
    state.original = {
        invisible = safeBool(player, "isInvisible"),
        ghost = safeBool(player, "isGhostMode"),
        god = safeBool(player, "isGodMod"),
        healthCheat = safeBool(player, "isHealthCheat"),
    }
end

local function protectZombieForState(state, zombie)
    if not state or not zombie then return end
    if state.zombies[zombie] then return end

    local refs = CSR_LoginProtectionClient.zombieRefs
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

    local refs = CSR_LoginProtectionClient.zombieRefs
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
    if isClient and isClient() then return end
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

local function setPurpleOutline(player, enabled)
    if not player then return end
    local playerNum = getPlayerNum(player)
    safeCall(player, "setOutlineHighlight", playerNum, enabled == true)
    if enabled then
        safeCall(player, "setOutlineHighlightCol", playerNum, OUTLINE_R, OUTLINE_G, OUTLINE_B, OUTLINE_A)
    end
end

local function forceProtectedState(player, state)
    if not player or not state then return end

    safeCall(player, "setInvisible", true)
    safeCall(player, "setGhostMode", true)
    safeCall(player, "setGodMod", true)
    safeCall(player, "setHealthCheat", true)
    setPurpleOutline(player, true)
    calmNearbyZombies(player, state, nowMs())
end

local function requestServerProtection(player)
    if not (isClient and isClient()) then return end
    if not sendClientCommand then return end
    sendClientCommand(player, MODULE, CMD_REQUEST, {})
end

local function finishProtection(player, state, notify)
    if not state or not state.active then return end
    player = player or getLocalPlayer(state.playerNum or 0)

    if player then
        local original = state.original or {}
        safeCall(player, "setInvisible", original.invisible == true)
        safeCall(player, "setGhostMode", original.ghost == true)
        safeCall(player, "setGodMod", original.god == true)
        safeCall(player, "setHealthCheat", original.healthCheat == true)
        setPurpleOutline(player, false)
        if notify ~= false then
            showHalo(player, translatedEnded())
        end
    end

    releaseZombiesForState(state)
    state.active = false
    state.endTimeMs = 0
    state.nextZombiePulseMs = 0
    state.original = nil
end

local function applyProtection(player, durationSeconds, fromServer)
    if not player or not isEnabled() then return end

    local duration = tonumber(durationSeconds) or getDurationSeconds()
    if duration < 1 then duration = 1 end
    if duration > 120 then duration = 120 end

    local state = getState(player)
    local wasActive = state.active == true

    state.playerNum = getPlayerNum(player)
    state.active = true
    state.startedOnce = true
    state.endTimeMs = math.max(state.endTimeMs or 0, nowMs() + (duration * 1000))
    state.zombies = state.zombies or {}
    rememberOriginal(state, player)
    forceProtectedState(player, state)

    if not wasActive then
        showHalo(player, translatedStarted(duration))
    end

    if not fromServer then
        requestServerProtection(player)
    end
end

local function updateState(player, state)
    if not state or not state.active then return end
    if not player then return end

    if not isEnabled() then
        finishProtection(player, state)
        return
    end

    if nowMs() >= (state.endTimeMs or 0) then
        finishProtection(player, state)
        return
    end

    forceProtectedState(player, state)
end

local function startForPlayer(player)
    if not player or not isEnabled() then return end

    local state = getState(player)
    if state.startedOnce then return end
    applyProtection(player, getDurationSeconds(), false)
end

local function onCreatePlayer(playerNum, player)
    startForPlayer(player or getLocalPlayer(playerNum or 0))
end

local function onGameStart()
    startForPlayer(getLocalPlayer(0))
end

local function onTick()
    local count = getNumActivePlayers and getNumActivePlayers() or 1
    for i = 0, count - 1 do
        local player = getLocalPlayer(i)
        if player then
            local state = getState(player)
            if not state.startedOnce then
                startForPlayer(player)
            end
            updateState(player, state)
        end
    end
end

local function onPlayerUpdate(player)
    if not player then return end
    updateState(player, getState(player))
end

local function onPlayerDeath(player)
    if not player then return end
    finishProtection(player, getState(player), false)
end

local function onServerCommand(module, command, args)
    if module ~= MODULE then return end

    local player = getLocalPlayer(0)
    if command == CMD_START then
        applyProtection(player, args and args.duration or getDurationSeconds(), true)
    elseif command == CMD_FINISH then
        finishProtection(player, player and getState(player) or nil, true)
    end
end

if Events then
    if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(onCreatePlayer) end
    if Events.OnGameStart then Events.OnGameStart.Add(onGameStart) end
    if Events.OnTick then Events.OnTick.Add(onTick) end
    if Events.OnPlayerUpdate then Events.OnPlayerUpdate.Add(onPlayerUpdate) end
    if Events.OnPlayerDeath then Events.OnPlayerDeath.Add(onPlayerDeath) end
    if Events.OnServerCommand then Events.OnServerCommand.Add(onServerCommand) end
end
