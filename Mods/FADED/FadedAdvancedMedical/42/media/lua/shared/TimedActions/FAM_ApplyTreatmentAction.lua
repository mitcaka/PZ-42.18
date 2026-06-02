require "TimedActions/ISBaseTimedAction"
require "FAM_Core"

FAM_ApplyTreatmentAction = ISBaseTimedAction:derive("FAM_ApplyTreatmentAction")

local function itemId(item)
    return item and item.getID and item:getID() or nil
end

local function patientOnlineId(patient)
    return FAM.getPatientOnlineID(patient)
end

function FAM_ApplyTreatmentAction:isValid()
    if ISHealthPanel and ISHealthPanel.DidPatientMove and ISHealthPanel.DidPatientMove(self.character, self.otherPlayer, self.patientX, self.patientY) then
        return false
    end
    if self.itemId then
        self.item = FAM.findInventoryItemById(self.character, self.itemId) or self.item
    end
    if self.itemWasPresent and not self.item then
        return false
    end
    local valid = FAM.canUseTreatment(self.character, self.otherPlayer, self.bodyPart, self.treatment)
    return valid
end

function FAM_ApplyTreatmentAction:waitToStart()
    if self.character == self.otherPlayer or self.character:isSeatedInVehicle() then
        return false
    end
    self.character:faceThisObject(self.otherPlayer)
    return self.character:shouldBeTurning()
end

function FAM_ApplyTreatmentAction:update()
    if self.character ~= self.otherPlayer then
        self.character:faceThisObject(self.otherPlayer)
    end
    if self.item then
        self.item:setJobDelta(self:getJobDelta())
    end
    if ISHealthPanel and ISHealthPanel.setBodyPartActionForPlayer then
        ISHealthPanel.setBodyPartActionForPlayer(self.otherPlayer, self.bodyPart, self, getText(FAM.TREATMENTS[self.treatment].job), { fam = true })
    end
    if Metabolics and Metabolics.LightDomestic then
        self.character:setMetabolicTarget(Metabolics.LightDomestic)
    end
end

function FAM_ApplyTreatmentAction:serverStart()
    if self.bodyPart:manipulatingUsername() == nil or self.bodyPart:manipulatingUsername() == "" then
        self.bodyPart:setManipulatingUsername(self.character:getUsername())
    end
end

function FAM_ApplyTreatmentAction:start()
    if self.itemId then
        self.item = FAM.findInventoryItemById(self.character, self.itemId) or self.item
    end

    if self.item then
        self.item:setJobType(getText(FAM.TREATMENTS[self.treatment].job))
        self.item:setJobDelta(0)
    end

    if self.character == self.otherPlayer then
        self:setActionAnim(CharacterActionAnims.Bandage)
        if ISHealthPanel and ISHealthPanel.getBandageType then
            self:setAnimVariable("BandageType", ISHealthPanel.getBandageType(self.bodyPart))
        end
        self.character:reportEvent("EventBandage")
    else
        self:setActionAnim("Loot")
        self.character:SetVariable("LootPosition", "Mid")
        self.character:reportEvent("EventLootItem")
    end
    self:setOverrideHandModels(nil, nil)
    self.sound = self.character:playSound("FirstAidApplyBandage")
    if self.bodyPart:HasInjury() then
        self.sound2 = self.otherPlayer:playerVoiceSound("ApplyBandage")
    end
end

function FAM_ApplyTreatmentAction:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
    if self.sound2 and self.otherPlayer:getEmitter():isPlaying(self.sound2) then
        self.otherPlayer:stopOrTriggerSound(self.sound2)
    end
end

function FAM_ApplyTreatmentAction:stop()
    self:stopSound()
    if ISHealthPanel and ISHealthPanel.setBodyPartActionForPlayer then
        ISHealthPanel.setBodyPartActionForPlayer(self.otherPlayer, self.bodyPart, nil, nil, nil)
    end
    ISBaseTimedAction.stop(self)
    if self.item then
        self.item:setJobDelta(0)
    end
    self.bodyPart:setManipulatingUsername(nil)
end

function FAM_ApplyTreatmentAction:serverStop()
    self.bodyPart:setManipulatingUsername(nil)
end

function FAM_ApplyTreatmentAction:perform()
    self:stopSound()
    if self.item then
        self.item:setJobDelta(0)
    end
    if ISHealthPanel and ISHealthPanel.setBodyPartActionForPlayer then
        ISHealthPanel.setBodyPartActionForPlayer(self.otherPlayer, self.bodyPart, nil, nil, nil)
    end
    ISBaseTimedAction.perform(self)
end

function FAM_ApplyTreatmentAction:complete()
    local username = self.bodyPart:manipulatingUsername()
    if isServer() and username ~= nil and username ~= "" and username ~= self.character:getUsername() then
        return false
    end

    if isClient() and sendClientCommand then
        sendClientCommand(self.character, FAM.NETWORK_MODULE, "ApplyTreatment", {
            patientId = patientOnlineId(self.otherPlayer),
            patientIsSelf = self.otherPlayer == self.character,
            bodyPartIndex = self.bodyPart and self.bodyPart:getIndex() or nil,
            itemId = self.itemId or itemId(self.item),
            treatment = self.treatment,
        })
        self.bodyPart:setManipulatingUsername(nil)
        return true
    end

    local result = FAM.applyTreatment(self.character, self.otherPlayer, self.item, self.bodyPart, self.treatment)
    self.bodyPart:setManipulatingUsername(nil)
    return result
end

function FAM_ApplyTreatmentAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    if self.bodyPart:manipulatingUsername() ~= nil and self.bodyPart:manipulatingUsername() ~= self.character:getUsername() then
        return 0
    end
    local level = FAM.getEffectiveDoctorLevel(self.character)
    if self.treatment == "tourniquet" then
        return math.max(240, 760 - (level * 45))
    end
    if self.treatment == "sanitation" then
        return math.max(90, 260 - (level * 14))
    end
    if self.treatment == "stumpcare" then
        return math.max(180, 520 - (level * 28))
    end
    if self.treatment == "ivfluids" then
        return math.max(170, 460 - (level * 24))
    end
    if self.treatment == "bloodpack" then
        return math.max(220, 620 - (level * 32))
    end
    if self.treatment == "epinephrine" then
        return math.max(55, 145 - (level * 7))
    end
    return math.max(50, 125 - (level * 6))
end

function FAM_ApplyTreatmentAction:new(doctor, otherPlayer, item, bodyPart, treatment)
    local o = ISBaseTimedAction.new(self, doctor)
    o.character = doctor
    o.otherPlayer = otherPlayer
    o.item = item
    o.itemId = itemId(item)
    o.bodyPart = bodyPart
    o.treatment = treatment
    o.stopOnWalk = bodyPart:getIndex() > BodyPartType.ToIndex(BodyPartType.Groin)
    o.stopOnRun = true
    o.patientX = otherPlayer:getX()
    o.patientY = otherPlayer:getY()
    o.itemWasPresent = item ~= nil
    o.maxTime = o:getDuration()
    return o
end
