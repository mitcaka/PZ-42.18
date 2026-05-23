require "TimedActions/ISBaseTimedAction"
require "FAM_Core"

FAM_FieldAmputationAction = ISBaseTimedAction:derive("FAM_FieldAmputationAction")

local function itemId(item)
    return item and item.getID and item:getID() or nil
end

local function patientOnlineId(patient)
    return FAM.getPatientOnlineID(patient)
end

local function resolveActionItems(action)
    if not action then return end
    if action.sawItemId then
        action.sawItem = FAM.findCharacterItemById(action.character, action.sawItemId) or action.sawItem
    end
    action.sawItem = action.sawItem or FAM.findSurgicalSaw(action.character)

    if action.stitchItemId then
        action.stitchItem = FAM.findCharacterItemById(action.character, action.stitchItemId) or action.stitchItem
    end
    action.stitchItem = action.stitchItem or FAM.findStitchItem(action.character)

    if action.bandageItemId then
        action.bandageItem = FAM.findCharacterItemById(action.character, action.bandageItemId) or action.bandageItem
    end
    action.bandageItem = action.bandageItem or FAM.findBandageItem(action.character)
end

local function sendActionResult(character, success, reason)
    if FAM_ServerCommands and FAM_ServerCommands.sendCareActionResult then
        FAM_ServerCommands.sendCareActionResult(character, "FieldAmputation", success, reason)
    end
end

local function sendActionSync(character, patient)
    if FAM_ServerCommands and FAM_ServerCommands.sendCareSync then
        FAM_ServerCommands.sendCareSync(character, patient)
    end
end

function FAM_FieldAmputationAction:sendStartCommand()
    if self.sentStartCommand then return true end
    self.sentStartCommand = true
    if isClient() and sendClientCommand then
        sendClientCommand(self.character, FAM.NETWORK_MODULE, "FieldAmputationStarted", {
            patientId = patientOnlineId(self.patient),
            patientIsSelf = self.patient == self.character,
            bodyPartIndex = self.bodyPart and self.bodyPart:getIndex() or nil,
        })
        return true
    end
    return false
end

function FAM_FieldAmputationAction:sendStopCommand()
    if self.sentStopCommand then return true end
    self.sentStopCommand = true
    if isClient() and sendClientCommand then
        sendClientCommand(self.character, FAM.NETWORK_MODULE, "FieldAmputationStopped", {
            patientId = patientOnlineId(self.patient),
            patientIsSelf = self.patient == self.character,
            bodyPartIndex = self.bodyPart and self.bodyPart:getIndex() or nil,
        })
        return true
    end
    return false
end

function FAM_FieldAmputationAction:isValid()
    if ISHealthPanel and ISHealthPanel.DidPatientMove and ISHealthPanel.DidPatientMove(self.character, self.patient, self.patientX, self.patientY) then
        return false
    end
    resolveActionItems(self)
    if not self.sawItem then
        return false
    end
    local valid = FAM.canUseTreatment(self.character, self.patient, self.bodyPart, "amputation")
    return valid
end

function FAM_FieldAmputationAction:waitToStart()
    if self.character == self.patient or self.character:isSeatedInVehicle() then
        return false
    end
    self.character:faceThisObject(self.patient)
    return self.character:shouldBeTurning()
end

function FAM_FieldAmputationAction:update()
    if self.character ~= self.patient then
        self.character:faceThisObject(self.patient)
    end
    if self.sawItem then
        self.sawItem:setJobDelta(self:getJobDelta())
    end
    if ISHealthPanel and ISHealthPanel.setBodyPartActionForPlayer then
        ISHealthPanel.setBodyPartActionForPlayer(self.patient, self.bodyPart, self, getText("IGUI_FAM_JobType_FieldAmputation"), { fam = true })
    end
    if Metabolics and Metabolics.HeavyWork then
        self.character:setMetabolicTarget(Metabolics.HeavyWork)
        if self.character ~= self.patient then
            self.patient:setMetabolicTarget(Metabolics.HeavyWork)
        end
    end
end

function FAM_FieldAmputationAction:serverStart()
    if self.bodyPart:manipulatingUsername() == nil or self.bodyPart:manipulatingUsername() == "" then
        self.bodyPart:setManipulatingUsername(self.character:getUsername())
    end
end

function FAM_FieldAmputationAction:start()
    resolveActionItems(self)

    if self.sawItem then
        self.sawItem:setJobType(getText("IGUI_FAM_JobType_FieldAmputation"))
        self.sawItem:setJobDelta(0)
    end

    if isClient() then
        self:sendStartCommand()
    else
        self.bodyPart:setBleeding(true)
        self.bodyPart:setCut(true)
        self.bodyPart:setBleedingTime(math.max(self.bodyPart:getBleedingTime(), FAM.hasTourniquet(self.patient, self.bodyPart) and 4 or 14))
        if syncBodyPart then
            syncBodyPart(self.bodyPart, 0xFFFFFFFFFFF)
        end
    end

    self:setActionAnim("SawLog")
    self:setOverrideHandModels(self.sawItem, nil)
    self.sound = self.character:getEmitter():playSound("FAM_Amputation")
    if addSound then
        addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 5, 5)
    end
end

function FAM_FieldAmputationAction:stopSound()
    if self.sound then
        self.character:getEmitter():stopSound(self.sound)
        self.sound = nil
    end
end

function FAM_FieldAmputationAction:stop()
    self:stopSound()
    if ISHealthPanel and ISHealthPanel.setBodyPartActionForPlayer then
        ISHealthPanel.setBodyPartActionForPlayer(self.patient, self.bodyPart, nil, nil, nil)
    end
    if self.sawItem then
        self.sawItem:setJobDelta(0)
    end
    self:sendStopCommand()
    self.bodyPart:setManipulatingUsername(nil)
    ISBaseTimedAction.stop(self)
end

function FAM_FieldAmputationAction:serverStop()
    self.bodyPart:setManipulatingUsername(nil)
end

function FAM_FieldAmputationAction:perform()
    self:stopSound()
    if self.sawItem then
        self.sawItem:setJobDelta(0)
    end
    if ISHealthPanel and ISHealthPanel.setBodyPartActionForPlayer then
        ISHealthPanel.setBodyPartActionForPlayer(self.patient, self.bodyPart, nil, nil, nil)
    end
    ISBaseTimedAction.perform(self)
end

function FAM_FieldAmputationAction:complete()
    local username = self.bodyPart:manipulatingUsername()
    if isServer() and username ~= nil and username ~= "" and username ~= self.character:getUsername() then
        return false
    end

    resolveActionItems(self)

    if isClient() and sendClientCommand then
        sendClientCommand(self.character, FAM.NETWORK_MODULE, "FieldAmputation", {
            patientId = patientOnlineId(self.patient),
            patientIsSelf = self.patient == self.character,
            bodyPartIndex = self.bodyPart and self.bodyPart:getIndex() or nil,
            sawItemId = self.sawItemId or itemId(self.sawItem),
            stitchItemId = self.stitchItemId or itemId(self.stitchItem),
            bandageItemId = self.bandageItemId or itemId(self.bandageItem),
        })
        self.bodyPart:setManipulatingUsername(nil)
        return true
    end

    -- Dedicated server NetAction tick: don't redo work here. The real amputation
    -- is dispatched by the "FieldAmputation" client command handler with valid
    -- server-side player/patient/item lookups. Returning false here keeps Java
    -- holding the action open ("stuck at 100%"); always ack with true.
    if isServer() then
        self.bodyPart:setManipulatingUsername(nil)
        return true
    end

    -- Single-player path: run the amputation locally.
    if FAM.hasAmputation(self.patient, self.bodyPart) then
        self.bodyPart:setManipulatingUsername(nil)
        return true
    end
    local valid, reason = FAM.canUseTreatment(self.character, self.patient, self.bodyPart, "amputation")
    if not valid then
        self.bodyPart:setManipulatingUsername(nil)
        sendActionResult(self.character, false, reason)
        return false
    end
    if not FAM.isItemAnyFullType(self.sawItem, FAM.SAW_TYPES) then
        self.bodyPart:setManipulatingUsername(nil)
        sendActionResult(self.character, false, "Tooltip_FAM_MissingSaw")
        return false
    end
    local result = FAM.performFieldAmputation(self.character, self.patient, self.sawItem, self.bodyPart, self.stitchItem, self.bandageItem)
    self.bodyPart:setManipulatingUsername(nil)
    if result then
        sendActionSync(self.character, self.patient)
    else
        sendActionResult(self.character, false, "Tooltip_FAM_InvalidTreatment")
    end
    return result
end

function FAM_FieldAmputationAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    if self.bodyPart:manipulatingUsername() ~= nil and self.bodyPart:manipulatingUsername() ~= self.character:getUsername() then
        return 0
    end
    return math.max(420, 1000 - (FAM.getEffectiveDoctorLevel(self.character) * 50))
end

function FAM_FieldAmputationAction:new(surgeon, patient, sawItem, bodyPart, stitchItem, bandageItem)
    local o = ISBaseTimedAction.new(self, surgeon)
    o.character = surgeon
    o.patient = patient
    o.sawItem = sawItem
    o.sawItemId = itemId(sawItem)
    o.bodyPart = bodyPart
    o.stitchItem = stitchItem
    o.stitchItemId = itemId(stitchItem)
    o.bandageItem = bandageItem
    o.bandageItemId = itemId(bandageItem)
    o.patientX = patient:getX()
    o.patientY = patient:getY()
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = o:getDuration()
    return o
end
