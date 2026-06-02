require "TimedActions/ISBaseTimedAction"
require "CSR_Config"
require "CSR_Utils"

--[[
    CSR_UnHotwireAction.lua
    Removes (un-hotwires) a vehicle the player is currently driving.
    Mirrors the un-hotwire mechanic from "Expanded Hotwire" (2736032294)
    using CSR's own validated server command instead of vanilla's admin-only
    mechanics cheat command.

    Requirements: driver, engine off, vehicle currently hotwired.
    Tool: screwdriver (consumes 1 condition on success, like the install path).
    Duration: scales with Electrical + Mechanics perk levels.
]]

CSR_UnHotwireAction = ISBaseTimedAction:derive("CSR_UnHotwireAction")

function CSR_UnHotwireAction:isValid()
    local vehicle = self.character and self.character:getVehicle() or nil
    if not vehicle then return false end
    if not vehicle:isDriver(self.character) then return false end
    if vehicle:isEngineRunning() or vehicle:isEngineStarted() then return false end
    return vehicle:isHotwired() == true
end

function CSR_UnHotwireAction:update()
    self.character:setMetabolicTarget(Metabolics.HeavyDomestic)
end

function CSR_UnHotwireAction:start()
    self.sound = self.character:getEmitter():playSound("unlockDoor")
    if self.screwdriver then
        self:setOverrideHandModels(self.screwdriver, nil)
    end
    self.jobType = "Remove Hotwire"
end

function CSR_UnHotwireAction:stop()
    self:stopSound()
    ISBaseTimedAction.stop(self)
end

function CSR_UnHotwireAction:perform()
    self:stopSound()

    local vehicle = self.character and self.character:getVehicle() or nil
    if vehicle then
        if isClient() then
            sendClientCommand(self.character, "CommonSenseReborn", "UnHotwireVehicle", {
                vehicleId = vehicle:getId(),
                screwdriverId = self.screwdriver and self.screwdriver.getID and self.screwdriver:getID() or nil,
                requestId = CSR_Utils.makeRequestId(self.character, "UnHotwireVehicle"),
                requestTimestamp = getTimestampMs and getTimestampMs() or os.time() * 1000,
            })
        else
            if vehicle.cheatHotwire then
                vehicle:cheatHotwire(false, false)
            elseif vehicle.setHotwired then
                vehicle:setHotwired(false)
            end
            if self.screwdriver and self.screwdriver.setCondition then
                self.screwdriver:setCondition(math.max(0, self.screwdriver:getCondition() - 1))
            end
        end
    end

    ISBaseTimedAction.perform(self)
end

function CSR_UnHotwireAction:stopSound()
    if self.sound and self.character and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
end

function CSR_UnHotwireAction:new(character, screwdriver)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.screwdriver = screwdriver
    local base = (CSR_Config and CSR_Config.BASE_UN_HOTWIRE_TIME) or 200
    if character:isTimedActionInstant() then
        o.maxTime = 1
    else
        local elec = character:getPerkLevel(Perks.Electricity) or 0
        local mech = character:getPerkLevel(Perks.Mechanics) or 0
        local reduction = (elec * 8) + (mech * 4)
        o.maxTime = math.max(40, base - reduction)
    end
    return o
end
