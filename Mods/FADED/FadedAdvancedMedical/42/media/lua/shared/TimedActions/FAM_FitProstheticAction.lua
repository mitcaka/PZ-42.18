require "TimedActions/ISBaseTimedAction"
require "FAM_Core"

FAM_FitProstheticAction = ISBaseTimedAction:derive("FAM_FitProstheticAction")

local function itemId(item)
    return item and item.getID and item:getID() or nil
end

local function patientOnlineId(patient)
    return FAM.getPatientOnlineID(patient)
end

function FAM_FitProstheticAction:isValid()
    if ISHealthPanel and ISHealthPanel.DidPatientMove and ISHealthPanel.DidPatientMove(self.character, self.patient, self.patientX, self.patientY) then
        return false
    end
    if self.prostheticItemId then
        self.prostheticItem = FAM.findInventoryItemById(self.character, self.prostheticItemId) or self.prostheticItem
    end
    if self.itemWasPresent and not self.prostheticItem then
        return false
    end
    local valid = FAM.canFitProsthetic(self.character, self.patient, self.bodyPart, self.prostheticItem)
    return valid
end

function FAM_FitProstheticAction:waitToStart()
    if self.character == self.patient or self.character:isSeatedInVehicle() then
        return false
    end
    self.character:faceThisObject(self.patient)
    return self.character:shouldBeTurning()
end

function FAM_FitProstheticAction:update()
    if self.character ~= self.patient then
        self.character:faceThisObject(self.patient)
    end
    if self.prostheticItem then
        self.prostheticItem:setJobDelta(self:getJobDelta())
    end
    if ISHealthPanel and ISHealthPanel.setBodyPartActionForPlayer then
        ISHealthPanel.setBodyPartActionForPlayer(self.patient, self.bodyPart, self, getText("IGUI_FAM_JobType_FitProsthetic"), { fam = true })
    end
    if Metabolics and Metabolics.LightDomestic then
        self.character:setMetabolicTarget(Metabolics.LightDomestic)
    end
end

function FAM_FitProstheticAction:serverStart()
    if self.bodyPart:manipulatingUsername() == nil or self.bodyPart:manipulatingUsername() == "" then
        self.bodyPart:setManipulatingUsername(self.character:getUsername())
    end
end

function FAM_FitProstheticAction:start()
    if self.prostheticItemId then
        self.prostheticItem = FAM.findInventoryItemById(self.character, self.prostheticItemId) or self.prostheticItem
    end
    if self.prostheticItem then
        self.prostheticItem:setJobType(getText("IGUI_FAM_JobType_FitProsthetic"))
        self.prostheticItem:setJobDelta(0)
    end
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Mid")
    self.character:reportEvent("EventLootItem")
    self:setOverrideHandModels(nil, nil)
    self.sound = self.character:playSound("FirstAidApplyBandage")
end

function FAM_FitProstheticAction:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
end

function FAM_FitProstheticAction:stop()
    self:stopSound()
    if ISHealthPanel and ISHealthPanel.setBodyPartActionForPlayer then
        ISHealthPanel.setBodyPartActionForPlayer(self.patient, self.bodyPart, nil, nil, nil)
    end
    if self.prostheticItem then
        self.prostheticItem:setJobDelta(0)
    end
    self.bodyPart:setManipulatingUsername(nil)
    ISBaseTimedAction.stop(self)
end

function FAM_FitProstheticAction:serverStop()
    self.bodyPart:setManipulatingUsername(nil)
end

function FAM_FitProstheticAction:perform()
    self:stopSound()
    if self.prostheticItem then
        self.prostheticItem:setJobDelta(0)
    end
    if ISHealthPanel and ISHealthPanel.setBodyPartActionForPlayer then
        ISHealthPanel.setBodyPartActionForPlayer(self.patient, self.bodyPart, nil, nil, nil)
    end
    ISBaseTimedAction.perform(self)
end

function FAM_FitProstheticAction:complete()
    local username = self.bodyPart:manipulatingUsername()
    if isServer() and username ~= nil and username ~= "" and username ~= self.character:getUsername() then
        return false
    end
    if isClient() and sendClientCommand then
        sendClientCommand(self.character, FAM.NETWORK_MODULE, "FitProsthetic", {
            patientId = patientOnlineId(self.patient),
            patientIsSelf = self.patient == self.character,
            bodyPartIndex = self.bodyPart and self.bodyPart:getIndex() or nil,
            prostheticItemId = self.prostheticItemId or itemId(self.prostheticItem),
        })
        self.bodyPart:setManipulatingUsername(nil)
        return true
    end
    local result = FAM.performFitProsthetic(self.character, self.patient, self.prostheticItem, self.bodyPart)
    self.bodyPart:setManipulatingUsername(nil)
    return result
end

function FAM_FitProstheticAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    if self.bodyPart:manipulatingUsername() ~= nil and self.bodyPart:manipulatingUsername() ~= self.character:getUsername() then
        return 0
    end
    return math.max(220, 700 - (FAM.getEffectiveDoctorLevel(self.character) * 36))
end

function FAM_FitProstheticAction:new(doctor, patient, prostheticItem, bodyPart)
    local o = ISBaseTimedAction.new(self, doctor)
    o.character = doctor
    o.patient = patient
    o.prostheticItem = prostheticItem
    o.prostheticItemId = itemId(prostheticItem)
    o.bodyPart = bodyPart
    o.patientX = patient:getX()
    o.patientY = patient:getY()
    o.itemWasPresent = prostheticItem ~= nil
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = o:getDuration()
    return o
end
