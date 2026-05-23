-- CSR_KnoxSyndicateContext.lua (client)
-- Right-click any radio (inventory or vehicle) tuned to the Knox Syndicate
-- frequency to call in support. Sends a server command; server validates
-- cooldown, frequency, location, and starts the support run.

require "CSR_FeatureFlags"
require "CSR_KnoxSyndicate"

local K = CSR_KnoxSyndicate

local function gameHourLeft(player)
    local md = player:getModData()
    local last = tonumber(md.csrKnoxLastHour or 0) or 0
    return (last + K.cooldownHours()) - K.gameHour()
end

local function buildTooltip(player, tunedOk)
    local tt = ISToolTip:new()
    tt:initialise()
    tt:setVisible(false)
    if not tunedOk then
        tt.description = getText("IGUI_CSR_KnoxNotTuned", K.FREQUENCY_LABEL)
        return tt
    end
    local left = gameHourLeft(player)
    if left > 0 then
        tt.description = getText("IGUI_CSR_KnoxCallCooldown", tostring(left))
    else
        tt.description = getText("IGUI_CSR_KnoxCallReady")
    end
    return tt
end

local function onCallSupport(player, fromVehicle)
    sendClientCommand(player, "CommonSenseReborn", "KnoxCallSupport",
        { fromVehicle = fromVehicle and true or false })
end

local function appendOption(context, player, fromVehicle, tunedOk)
    local opt = context:addOption(getText("IGUI_CSR_KnoxCallSupport"), player,
        onCallSupport, fromVehicle)
    if not tunedOk or gameHourLeft(player) > 0 then
        opt.notAvailable = true
    end
    opt.toolTip = buildTooltip(player, tunedOk)
end

-- Inventory radios
local function onFillInv(playerNum, context, items)
    if not K.isEnabled() then return end
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local anyRadio, anyTuned = false, false
    for _, it in ipairs(items) do
        local actual = it
        if type(it) == "table" and it.items then actual = it.items[1] end
        if K.isWorkingHandRadio(actual) then
            anyRadio = true
            if K.isTunedHandRadio(actual) then anyTuned = true; break end
        end
    end
    if not anyRadio then return end
    appendOption(context, player, false, anyTuned)
end

-- Vehicle radios
local function onFillWorld(playerNum, context, worldObjects, test)
    if not K.isEnabled() then return end
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local veh = player:getVehicle()
    if not veh then return end
    local anyRadio, anyTuned = false, false
    for i = 0, veh:getPartCount() - 1 do
        local part = veh:getPartByIndex(i)
        local dd = part and part.getDeviceData and part:getDeviceData()
        if dd then
            anyRadio = true
            if K.isTunedDeviceData(dd) then anyTuned = true; break end
        end
    end
    if not anyRadio then return end
    appendOption(context, player, true, anyTuned)
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInv)
Events.OnFillWorldObjectContextMenu.Add(onFillWorld)

-- ----------------------------------------------------------------
-- Server -> client feedback (chatter + audio)
-- ----------------------------------------------------------------

local KNOX_LINES_START = {
    "Knox Syndicate, copy your beacon. Wheels up.",
    "Hold position, survivor. We're inbound.",
    "Eyes on. Move tight, keep your head down.",
}
local KNOX_LINES_END = {
    "Last pass. Bingo fuel.",
    "Knox Syndicate is RTB. Stay safe out there.",
}

-- Schedule a chat line N ms in the future without blocking.
local function scheduleSay(player, line, delayMs)
    if not player or not line then return end
    if delayMs <= 0 then
        pcall(function() player:Say(line) end)
        return
    end
    local startMs = getTimestampMs()
    local fired = false
    local fn
    fn = function()
        if fired then return end
        if getTimestampMs() - startMs >= delayMs then
            fired = true
            pcall(function() player:Say(line) end)
            Events.OnTick.Remove(fn)
        end
    end
    Events.OnTick.Add(fn)
end

local function sayLines(player, lines, gap)
    if not player then return end
    for i, line in ipairs(lines) do
        scheduleSay(player, line, (i - 1) * (gap or 2200))
    end
end

-- Single helicopter ambience handle. We start ONE looping sound when the
-- support call begins and stop it when the server tells us it ended. The
-- previous version retriggered the sound every 6s, which stacked emitters
-- and produced the runaway-volume "horrible" loop the user reported.
local _heliHandle = nil
local _heliPlayer = nil

local function startHelicopterLoop(player)
    if not player or not player.getEmitter then return end
    local emitter = player:getEmitter()
    if not emitter then return end
    -- Stop any previous handle before starting a new one.
    if _heliHandle and _heliPlayer and _heliPlayer.getEmitter then
        pcall(function() _heliPlayer:getEmitter():stopSound(_heliHandle) end)
    end
    _heliPlayer = player
    pcall(function() _heliHandle = emitter:playSound("HelicopterOverhead") end)
    -- Fallback to a generic helicopter cue if the music event isn't available
    if not _heliHandle or _heliHandle == 0 then
        pcall(function() _heliHandle = emitter:playSound("Helicopter") end)
    end
end

local function stopHelicopterLoop()
    if _heliHandle and _heliPlayer and _heliPlayer.getEmitter then
        pcall(function() _heliPlayer:getEmitter():stopSound(_heliHandle) end)
    end
    _heliHandle = nil
    _heliPlayer = nil
end

local function onServerCommand(module, command, args)
    if module ~= "CommonSenseReborn" then return end
    if command == "KnoxCallStarted" then
        local player = getPlayer()
        if player then
            sayLines(player, KNOX_LINES_START, 2200)
            -- Local audio cue: door gunner racks his M16, then rotor wash kicks in
            pcall(function() player:getEmitter():playSound("M16Rack") end)
            startHelicopterLoop(player)
        end
    elseif command == "KnoxCallEnded" then
        stopHelicopterLoop()
        local player = getPlayer()
        if player then sayLines(player, KNOX_LINES_END, 1800) end
    elseif command == "KnoxCallShot" then
        -- Per-shot gunshot from the strafing run, played at the local player
        -- (server picked the zombie). Alternates burst vs precision shot.
        local player = getPlayer()
        if not player then return end
        local heavy = (args and args.heavy) and true or false
        local snd = heavy and "SniperRifleShoot" or "M16ShootFullAuto"
        pcall(function() player:getEmitter():playSound(snd) end)
    elseif command == "KnoxCallReject" then
        local player = getPlayer()
        local key = (args and args.reason) or "IGUI_CSR_KnoxCallNoSignal"
        if player then
            local msg
            if key == "IGUI_CSR_KnoxNotTuned" then
                msg = getText(key, K.FREQUENCY_LABEL)
            elseif key == "IGUI_CSR_KnoxCallCooldown" then
                msg = getText(key, tostring(gameHourLeft(player)))
            else
                msg = getText(key)
            end
            player:Say(msg)
        end
    end
end

Events.OnServerCommand.Add(onServerCommand)
