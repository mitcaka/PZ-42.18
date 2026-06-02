-- CSR_TrunkSpillage.lua
-- Client-side driver tick for server-authoritative open/exposed-trunk spillage.
-- The client never removes cargo or drops world items; it only asks the server
-- to process the current driven vehicle/trailer using server-side state.
require "CSR_FeatureFlags"

CSR_TrunkSpillage = CSR_TrunkSpillage or {}

local MODULE = "CommonSenseReborn"
local COMMAND = "TrunkSpillageTick"
local TICK_PERIOD = 30

local function isEnabled()
    if not CSR_FeatureFlags or not CSR_FeatureFlags.isTrunkSpillageEnabled then return false end
    return CSR_FeatureFlags.isTrunkSpillageEnabled()
end

local function sendTick(player, target)
    sendClientCommand(player, MODULE, COMMAND, { target = target })
end

local _tick = 0
local function onTick()
    if not isEnabled() then return end
    _tick = _tick + 1
    if (_tick % TICK_PERIOD) ~= 0 then return end

    local player = getSpecificPlayer(0)
    if not player then return end
    local vehicle = player:getVehicle()
    if not vehicle then return end
    if vehicle:getDriver() ~= player then return end

    sendTick(player, "vehicle")
    if vehicle.getVehicleTowing then
        local trailer = vehicle:getVehicleTowing()
        if trailer then sendTick(player, "trailer") end
    end
end

if Events and Events.OnTick then
    Events.OnTick.Add(onTick)
end

return CSR_TrunkSpillage
