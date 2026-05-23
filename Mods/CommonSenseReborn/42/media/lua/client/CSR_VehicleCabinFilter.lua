-- CSR_VehicleCabinFilter.lua — soften BaseCorpseSickness gain while inside
-- a sealed vehicle. Pure client-side, smooths the player's own stat tick.
-- Reads window/door/windshield states; running heater further dampens.
local CHECK_IDS = {
    "Windshield", "WindshieldRear",
    "WindowFrontLeft", "WindowFrontRight", "WindowRearLeft", "WindowRearRight",
    "DoorFrontLeft", "DoorFrontRight", "DoorRearLeft", "DoorRearRight", "TrunkDoor",
}

local function sandbox()
    return SandboxVars.CommonSenseReborn or {}
end

local function isExternalActive()
    local mods = getActivatedMods()
    if not mods then return false end
    if mods:contains("NoMoreSicknessInsideVehicle") then return true end
    return false
end

local function sealedFraction(vehicle)
    local total = 0
    local sealed = 0
    for i = 1, #CHECK_IDS do
        local part = vehicle:getPartById(CHECK_IDS[i])
        if part then
            total = total + 1
            local installed = part:getInventoryItem() ~= nil
            local cond = installed and (part:getCondition() or 0) or 0
            local window = part:getWindow()
            local door = part:getDoor()
            local pid = part:getId()
            local isWindshield = (pid == "Windshield" or pid == "WindshieldRear")
            local thisSealed = 0
            if isWindshield then
                thisSealed = installed and (cond / 100) or 0
            elseif window then
                if installed and not window:isOpen() and not window:isDestroyed() then
                    thisSealed = (cond / 100)
                end
            elseif door then
                if installed and not door:isOpen() then
                    thisSealed = 0.5 + (cond / 200) -- doors leak less than open windows
                end
            else
                thisSealed = 1
            end
            sealed = sealed + thisSealed
        end
    end
    if total == 0 then return 0 end
    return sealed / total
end

local function isHeaterRunning(vehicle)
    local heater = vehicle.getHeater and vehicle:getHeater() or nil
    if not heater then return false end
    local md = heater.getModData and heater:getModData() or nil
    if md and md.active == true then return true end
    return false
end

local function onEveryOneMinute()
    if sandbox().EnableVehicleCabinFilter == false then return end
    if isExternalActive() then return end

    local player = getPlayer()
    if not player or not player:isAlive() then return end
    local vehicle = player:getVehicle()
    if not vehicle then return end

    local bd = player:getBodyDamage()
    if not bd then return end
    -- B42.17 only exposes the getter for BaseCorpseSickness from Lua, no
    -- public setter. If we can't write the value back, skip silently so we
    -- don't spam "Object tried to call nil" through the error handler.
    if type(bd.setBaseCorpseSickness) ~= "function" then return end
    local current = bd:GetBaseCorpseSickness()
    if not current or current <= 0 then return end

    if player.isProtectedFromToxic and player:isProtectedFromToxic() then return end

    local strength = sandbox().CabinFilterStrength or 0.7
    if strength < 0 then strength = 0 end
    if strength > 1 then strength = 1 end

    local sealed = sealedFraction(vehicle)
    local damp = 1 - (sealed * strength)

    if isHeaterRunning(vehicle) then
        local boost = sandbox().CabinFilterHeaterBoost or 0.7
        if boost < 0.1 then boost = 0.1 end
        if boost > 1 then boost = 1 end
        damp = damp * boost
    end

    if damp >= 1 then return end
    if damp < 0 then damp = 0 end

    pcall(function() bd:setBaseCorpseSickness(current * damp) end)
end

Events.EveryOneMinute.Add(onEveryOneMinute)
