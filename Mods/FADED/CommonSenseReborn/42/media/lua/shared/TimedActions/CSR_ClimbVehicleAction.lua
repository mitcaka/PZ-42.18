--
-- CSR_ClimbVehicleAction
-- =========================================================================
-- Timed action for climbing onto / down from a vehicle's roof.
-- Mode: "up" or "down". The action only flips player position + modData on
-- :perform(); the actual per-tick anchoring lives in CSR_RoofClimb.lua.
--
-- File-scope class so MP server can resolve via LuaManager.getFunctionObject.
-- =========================================================================

require "TimedActions/ISBaseTimedAction"

CSR_ClimbVehicleAction = ISBaseTimedAction:derive("CSR_ClimbVehicleAction")

function CSR_ClimbVehicleAction:isValid()
    if not self.character or self.character:isDead() then return false end
    if self.character:getVehicle() then return false end -- can't climb while seated
    if not self.vehicle or not self.vehicle:getCurrentSquare() then return false end
    return true
end

function CSR_ClimbVehicleAction:waitToStart()
    if self.vehicle and self.vehicle.getCurrentSquare and self.vehicle:getCurrentSquare() then
        self.character:faceLocation(self.vehicle:getX(), self.vehicle:getY())
    end
    return self.character:shouldBeTurning()
end

function CSR_ClimbVehicleAction:start()
    -- Vanilla animation that reads as a quick scramble. We don't ship custom
    -- AnimSets; the source mod's startVehicle/struggleVehicle/successVehicle
    -- XML files are not used.
    self:setActionAnim("Loot")
    self.character:reportEvent("EventLootItem")
end

function CSR_ClimbVehicleAction:update()
    if self.vehicle and self.vehicle:getCurrentSquare() then
        self.character:faceLocation(self.vehicle:getX(), self.vehicle:getY())
    end
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function CSR_ClimbVehicleAction:stop()
    ISBaseTimedAction.stop(self)
end

function CSR_ClimbVehicleAction:perform()
    local CSR_RoofClimb = _G.CSR_RoofClimb
    if CSR_RoofClimb then
        if self.mode == "up" then
            CSR_RoofClimb.applyMount(self.character, self.vehicle)
        else
            CSR_RoofClimb.applyDismount(self.character)
        end
    end
    ISBaseTimedAction.perform(self)
end

function CSR_ClimbVehicleAction:new(character, vehicle, mode, durationTicks)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.vehicle = vehicle
    o.mode = mode or "up"
    o.maxTime = durationTicks or 60
    o.stopOnWalk = true
    o.stopOnRun = true
    o.useProgressBar = true
    o.caloriesModifier = 6
    return o
end

return CSR_ClimbVehicleAction
