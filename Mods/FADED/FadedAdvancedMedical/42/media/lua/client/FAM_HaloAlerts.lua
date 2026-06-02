if isServer() then return end

require "FAM_Core"

FAM_HaloAlerts = FAM_HaloAlerts or {}

local ALERT_COOLDOWN_HOURS = 1.0
local lastAlertByPlayer = {}

local function getWorldAgeHours()
    local gameTime = getGameTime and getGameTime() or nil
    if gameTime and gameTime.getWorldAgeHours then
        return tonumber(gameTime:getWorldAgeHours()) or 0
    end
    return 0
end

local function getPlayerKey(player)
    if player and player.getOnlineID then
        local id = player:getOnlineID()
        if id ~= nil then return tostring(id) end
    end
    if player and player.getUsername then
        local username = player:getUsername()
        if username and username ~= "" then return username end
    end
    return tostring(player)
end

local function isSelfTriageOpen(player)
    local panel = FAM_TriagePanel and FAM_TriagePanel.instance or nil
    if not panel or panel.patient ~= player then return false end
    if panel.isVisible then
        return panel:isVisible()
    end
    return true
end

local function showAlert(player, level)
    local text = level >= 2 and getText("IGUI_FAM_Halo_CriticalTriage") or getText("IGUI_FAM_Halo_CheckTriage")
    if HaloTextHelper and HaloTextHelper.addBadText then
        HaloTextHelper.addBadText(player, text)
    elseif player and player.Say then
        player:Say(text)
    end
end

local function checkPlayer(player)
    if not player or isSelfTriageOpen(player) then return end
    local level = FAM.getTriageAlertLevel(player)
    if level <= 0 then return end

    local key = getPlayerKey(player)
    local now = getWorldAgeHours()
    local lastAlert = tonumber(lastAlertByPlayer[key]) or -999
    if now - lastAlert < ALERT_COOLDOWN_HOURS then return end

    lastAlertByPlayer[key] = now
    showAlert(player, level)
end

local function onEveryTenMinutes()
    if getNumActivePlayers then
        for i = 0, getNumActivePlayers() - 1 do
            checkPlayer(getSpecificPlayer(i))
        end
        return
    end
    if getPlayer then
        checkPlayer(getPlayer())
    end
end

if Events and not FAM_HaloAlerts._registered then
    FAM_HaloAlerts._registered = true
    if Events.EveryTenMinutes then
        Events.EveryTenMinutes.Add(onEveryTenMinutes)
    elseif Events.EveryHours then
        Events.EveryHours.Add(onEveryTenMinutes)
    end
end
