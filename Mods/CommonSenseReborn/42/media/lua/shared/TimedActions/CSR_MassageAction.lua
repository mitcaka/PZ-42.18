require "TimedActions/ISBaseTimedAction"
require "CSR_FeatureFlags"
require "CSR_Utils"
require "CSR_MassageUtils"

CSR_MassageAction = ISBaseTimedAction:derive("CSR_MassageAction")

local MASSAGE_TIME = 350
local MASSAGE_RANGE = 2

local MASSAGE_OIL_TYPES = {
    ["Butter"] = true,
    ["CookingOil"] = true,
    ["OliveOil"] = true,
    ["VegetableOil"] = true,
}

local function playersInRange(doctor, patient)
    if not doctor or not patient then return false end
    if doctor.getZ and patient.getZ and doctor:getZ() ~= patient:getZ() then return false end
    if doctor.DistToSquared and patient.getX and patient.getY then
        return doctor:DistToSquared(patient:getX(), patient:getY()) <= MASSAGE_RANGE * MASSAGE_RANGE
    end
    return true
end

function CSR_MassageAction.findOilOrButter(player)
    if not player then return nil end
    return CSR_Utils.findPreferredInventoryItem(player, function(item)
        if not item or not item.getType then return false end
        return MASSAGE_OIL_TYPES[item:getType()] == true
    end)
end

function CSR_MassageAction.hasStrain(bodyPart)
    return CSR_MassageUtils and CSR_MassageUtils.hasStrain(bodyPart) or false
end

function CSR_MassageAction:new(doctor, patient, bodyPart, oil)
    local o = ISBaseTimedAction.new(self, doctor)
    o.character = doctor
    o.patient = patient
    o.bodyPart = bodyPart
    o.oil = oil
    o.oilId = oil and oil.getID and oil:getID() or nil
    o.oilType = oil and oil.getFullType and oil:getFullType() or nil
    o.patientX = patient:getX()
    o.patientY = patient:getY()
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = MASSAGE_TIME
    return o
end

function CSR_MassageAction:isValid()
    if not self.patient or self.patient:isDead() then return false end
    if self.character == self.patient then return false end
    if not self.bodyPart then return false end
    if not playersInRange(self.character, self.patient) then return false end

    if ISHealthPanel and ISHealthPanel.DidPatientMove then
        if ISHealthPanel.DidPatientMove(self.character, self.patient, self.patientX, self.patientY) then
            return false
        end
    end

    self.oil = CSR_Utils.findInventoryItemById(self.character, self.oilId, self.oilType) or self.oil
    return self.oil ~= nil
        and (CSR_MassageAction.hasStrain(self.bodyPart) or CSR_MassageUtils.hasAnyStrain(self.patient))
end

function CSR_MassageAction:waitToStart()
    self.character:faceThisObject(self.patient)
    return self.character:shouldBeTurning()
end

function CSR_MassageAction:update()
    self.character:faceThisObject(self.patient)
    if ISHealthPanel and ISHealthPanel.setBodyPartActionForPlayer then
        ISHealthPanel.setBodyPartActionForPlayer(self.patient, self.bodyPart, self, "Massage", { bandage = true })
    end
    self.character:setMetabolicTarget(Metabolics.LightDomestic)

    self.gruntTimer = (self.gruntTimer or 0) + 1
    if self.gruntTimer >= 120 then
        self.gruntTimer = 0
        local voiceSound = self.patient:isFemale() and "VoiceFemaleExercise" or "VoiceMaleExercise"
        self.patient:playSound(voiceSound)
    end
end

function CSR_MassageAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Mid")
    self.character:reportEvent("EventLootItem")
    self:setOverrideHandModels(nil, nil)
end

function CSR_MassageAction:stop()
    if ISHealthPanel and ISHealthPanel.setBodyPartActionForPlayer then
        ISHealthPanel.setBodyPartActionForPlayer(self.patient, self.bodyPart, nil, nil, nil)
    end
    ISBaseTimedAction.stop(self)
end

function CSR_MassageAction:perform()
    if ISHealthPanel and ISHealthPanel.setBodyPartActionForPlayer then
        ISHealthPanel.setBodyPartActionForPlayer(self.patient, self.bodyPart, nil, nil, nil)
    end

    -- Clear only muscle stiffness. Avoid the full-health restore API so massage does
    -- not erase unrelated wounds on the selected body part.
    if self.patient and CSR_MassageUtils then
        CSR_MassageUtils.clearAllMuscleStrain(self.patient, true)
    end

    if isClient and isClient() and self.patient then
        local pid = self.patient.getOnlineID and self.patient:getOnlineID() or nil
        if pid then
            sendClientCommand(self.character, "CommonSenseReborn", "MassageHealStrain", {
                patientID = pid,
                clearAll = true,
            })
        end
    end

    addXp(self.character, Perks.Doctor, 5)

    self.oil = CSR_Utils.findInventoryItemById(self.character, self.oilId, self.oilType) or self.oil
    if self.oil then
        if self.oil.IsDrainable and self.oil:IsDrainable() and self.oil.UseAndSync then
            self.oil:UseAndSync()
        elseif self.oil.IsDrainable and self.oil:IsDrainable() and self.oil.Use then
            self.oil:Use()
        end
        if self.oil.getContainer then
            local container = self.oil:getContainer()
            if container then
                container:setDrawDirty(true)
            end
        end
        if syncInventoryItem then
            syncInventoryItem(self.oil)
        elseif self.oil.transmitModData then
            self.oil:transmitModData()
        end
    end

    self.patient:Say("Ahh... that feels better")
    self.character:Say("Worked out the knots")

    ISBaseTimedAction.perform(self)
end

return CSR_MassageAction
