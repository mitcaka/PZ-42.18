require "TimedActions/ISBaseTimedAction"
require "FAM_Core"

FAM_RemoveProstheticAction = ISBaseTimedAction:derive("FAM_RemoveProstheticAction")

local function patientOnlineId(patient)
    return FAM.getPatientOnlineID(patient)
end

function FAM_RemoveProstheticAction:isValid()
    if ISHealthPanel and ISHealthPanel.DidPatientMove and ISHealthPanel.DidPatientMove(self.character, self.patient, self.patientX, self.patientY) then
        return false
    end
    local valid = FAM.canRemoveProsthetic(self.character, self.patient, self.bodyPart)
    return valid
end

function FAM_RemoveProstheticAction:waitToStart()
    if self.character == self.patient or self.character:isSeatedInVehicle() then
        return false
    end
    self.character:faceThisObject(self.patient)
    return self.character:shouldBeTurning()
end

function FAM_RemoveProstheticAction:update()
    if self.character ~= self.patient then
        self.character:faceThisObject(self.patient)
    end
    if ISHealthPanel and ISHealthPanel.setBodyPartActionForPlayer then
        ISHealthPanel.setBodyPartActionForPlayer(self.patient, self.bodyPart, self, getText("IGUI_FAM_JobType_RemoveProsthetic"), { fam = true })
    end
    if Metabolics and Metabolics.LightDomestic then
        self.character:setMetabolicTarget(Metabolics.LightDomestic)
    end
end

function FAM_RemoveProstheticAction:serverStart()
    if self.bodyPart:manipulatingUsername() == nil or self.bodyPart:manipulatingUsername() == "" then
        self.bodyPart:setManipulatingUsername(self.character:getUsername())
    end
end

function FAM_RemoveProstheticAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Mid")
    self.character:reportEvent("EventLootItem")
    self:setOverrideHandModels(nil, nil)
    self.sound = self.character:playSound("FirstAidApplyBandage")
end

function FAM_RemoveProstheticAction:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
end

function FAM_RemoveProstheticAction:stop()
    self:stopSound()
    if ISHealthPanel and ISHealthPanel.setBodyPartActionForPlayer then
        ISHealthPanel.setBodyPartActionForPlayer(self.patient, self.bodyPart, nil, nil, nil)
    end
    self.bodyPart:setManipulatingUsername(nil)
    ISBaseTimedAction.stop(self)
end

function FAM_RemoveProstheticAction:serverStop()
    self.bodyPart:setManipulatingUsername(nil)
end

function FAM_RemoveProstheticAction:perform()
    self:stopSound()
    if ISHealthPanel and ISHealthPanel.setBodyPartActionForPlayer then
        ISHealthPanel.setBodyPartActionForPlayer(self.patient, self.bodyPart, nil, nil, nil)
    end
    ISBaseTimedAction.perform(self)
end

function FAM_RemoveProstheticAction:complete()
    local username = self.bodyPart:manipulatingUsername()
    if isServer() and username ~= nil and username ~= "" and username ~= self.character:getUsername() then
        return false
    end
    if isClient() and sendClientCommand then
        sendClientCommand(self.character, FAM.NETWORK_MODULE, "RemoveProsthetic", {
            patientId = patientOnlineId(self.patient),
            patientIsSelf = self.patient == self.character,
            bodyPartIndex = self.bodyPart and self.bodyPart:getIndex() or nil,
        })
        self.bodyPart:setManipulatingUsername(nil)
        return true
    end
    local result = FAM.performRemoveProsthetic(self.character, self.patient, self.bodyPart)
    self.bodyPart:setManipulatingUsername(nil)
    return result
end

function FAM_RemoveProstheticAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    if self.bodyPart:manipulatingUsername() ~= nil and self.bodyPart:manipulatingUsername() ~= self.character:getUsername() then
        return 0
    end
    return math.max(90, 260 - (FAM.getEffectiveDoctorLevel(self.character) * 14))
end

function FAM_RemoveProstheticAction:new(doctor, patient, bodyPart)
    local o = ISBaseTimedAction.new(self, doctor)
    o.character = doctor
    o.patient = patient
    o.bodyPart = bodyPart
    o.patientX = patient:getX()
    o.patientY = patient:getY()
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = o:getDuration()
    return o
end
