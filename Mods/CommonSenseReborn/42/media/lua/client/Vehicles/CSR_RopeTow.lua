-- CSR_RopeTow.lua
-- Adds rope/chain-based towing for vehicles that can't power themselves
-- (engine dead / out of fuel / battery depleted). The vanilla hitch
-- attachment system still governs which hitch points line up; rope tow
-- is layered on top as an extra requirement when the towed vehicle is
-- in "needs rescue" condition.
--
-- Behavior:
--   * When ISAttachTrailerToVehicle:perform fires, if the towed vehicle
--     (vehicleB) has no engine power AND no battery charge, a rope or
--     chain item is consumed from the player's inventory.
--   * The chosen item type is stashed on the towing vehicle's modData
--     as a flat string key (csrTowMaterial), MP-safe via transmitModData.
--   * On ISDetachTrailerFromVehicle:perform, the same item type is
--     spawned back into the detacher's inventory and the modData is
--     cleared.
--   * If no eligible rope/chain is in inventory, the attach is blocked
--     with a halo note.
--
-- Sandbox: EnableRopeTow (default true).
require "CSR_FeatureFlags"
require "CSR_Utils"

CSR_RopeTow = CSR_RopeTow or {}

local TOW_KEY     = "csrTowMaterial"
local ROPE_TYPES  = { "Base.Rope", "Base.Chain", "Base.HeavyChain", "Base.HeavyChain_Hook" }

local function isEnabled()
    if not CSR_FeatureFlags or not CSR_FeatureFlags.isRopeTowEnabled then return true end
    return CSR_FeatureFlags.isRopeTowEnabled()
end

local function vehicleBool(v, methodName)
    local method = v and v[methodName]
    if not method then return false end
    return method(v) == true
end

local function vehicleNumber(v, methodName, fallback)
    local method = v and v[methodName]
    if not method then return fallback or 0 end
    return tonumber(method(v)) or fallback or 0
end

local function vehicleHasPower(v)
    if not v then return true end
    -- B42.17 does not expose getCurrentEnginePower() in every environment,
    -- so probe it only when present and fall back to stable engine-state APIs.
    local enginePower = vehicleNumber(v, "getCurrentEnginePower", 0)
    if enginePower and enginePower > 0 then return true end
    if vehicleBool(v, "isEngineRunning") or vehicleBool(v, "isEngineStarted") then return true end
    -- Battery: a vehicle with a charged battery can be pushed/coasted
    -- but for our purposes we treat zero battery + zero engine power
    -- as the "needs rope" trigger.
    local battery = vehicleNumber(v, "getBatteryCharge", 0)
    if battery and battery > 0.05 then return true end
    return false
end

local function findFirstRope(character)
    if not character then return nil end
    local inv = character:getInventory()
    if not inv then return nil end
    for i = 1, #ROPE_TYPES do
        local found = nil
        if inv.getFirstTypeRecurse then
            pcall(function() found = inv:getFirstTypeRecurse(ROPE_TYPES[i]) end)
        end
        if not found and inv.getFirstTypeEval then
            pcall(function()
                found = inv:getFirstTypeEval(ROPE_TYPES[i], predicateNotBroken)
            end)
        end
        if found then return found, ROPE_TYPES[i] end
    end
    return nil
end

local function transferToFloor(character, item)
    -- Remove the rope from inventory cleanly (server-aware).
    if not item or not character then return end
    local container = item:getContainer() or character:getInventory()
    if container and container.removeItemOnServer then
        pcall(function() container:removeItemOnServer(item) end)
    end
    if container then
        pcall(function() container:DoRemoveItem(item) end)
    end
end

local function spawnRopeBack(character, fullType)
    if not character or not fullType or fullType == "" then return false end
    local inv = character:getInventory()
    if not inv then return false end
    local ok = pcall(function() inv:AddItem(fullType) end)
    return ok
end

-- Deferred wrap: ISAttachTrailerToVehicle classes are loaded lazily, so
-- we install the wraps OnGameStart after Vehicles/TimedActions has been
-- pulled in. Server-side commands run untouched.
local function installAttachWrap()
    if CSR_RopeTow._attachHooked then return end
    if not ISAttachTrailerToVehicle or not ISAttachTrailerToVehicle.perform then return end
    local _origPerform = ISAttachTrailerToVehicle.perform
    function ISAttachTrailerToVehicle:perform()
        if not isEnabled() then return _origPerform(self) end
        local vA = self.vehicleA
        local vB = self.vehicleB
        local ch = self.character
        local needsRope = vB and not vehicleHasPower(vB)
        if not needsRope then return _origPerform(self) end

        local rope, fullType = findFirstRope(ch)
        if not rope then
            if ch and ch.Say then
                pcall(function()
                    ch:Say(getText and getText("IGUI_CSR_RopeTow_Need") or "I need a rope or chain to tow this.")
                end)
            end
            -- Forcibly forget the action — call original with vehicleB
            -- mismatch suppressed: stop the action by clearing self.vehicleB.
            self.vehicleB = nil
            return _origPerform(self)
        end

        -- Stash material BEFORE the server attach runs, so any reload
        -- between attach and the next session still finds the flag on
        -- the towing vehicle's persisted modData.
        if vA and vA.getModData then
            local md = vA:getModData()
            md[TOW_KEY] = fullType
            pcall(function() vA:transmitModData() end)
        end
        transferToFloor(ch, rope)

        return _origPerform(self)
    end
    CSR_RopeTow._attachHooked = true
end

local function installDetachWrap()
    if CSR_RopeTow._detachHooked then return end
    if not ISDetachTrailerFromVehicle or not ISDetachTrailerFromVehicle.perform then return end
    local _origPerform = ISDetachTrailerFromVehicle.perform
    function ISDetachTrailerFromVehicle:perform()
        if not isEnabled() then return _origPerform(self) end
        local v = self.vehicle
        local ch = self.character
        local fullType = nil
        if v and v.getModData then
            local md = v:getModData()
            if md and type(md[TOW_KEY]) == "string" then fullType = md[TOW_KEY] end
        end
        local result = _origPerform(self)
        if fullType and ch then
            spawnRopeBack(ch, fullType)
            if v and v.getModData then
                local md = v:getModData()
                md[TOW_KEY] = nil
                pcall(function() v:transmitModData() end)
            end
        end
        return result
    end
    CSR_RopeTow._detachHooked = true
end

local function install()
    pcall(installAttachWrap)
    pcall(installDetachWrap)
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(install)
end

return CSR_RopeTow
