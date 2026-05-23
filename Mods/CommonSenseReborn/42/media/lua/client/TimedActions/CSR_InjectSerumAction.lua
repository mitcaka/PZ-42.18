require "TimedActions/ISBaseTimedAction"
require "CSR_Antibodies"
require "CSR_FeatureFlags"

CSR_InjectSerumAction = ISBaseTimedAction:derive("CSR_InjectSerumAction")

local function showHalo(player, key, ok)
    if not player or not player.setHaloNote or not key then return end
    local text = getText and getText(key) or key
    if ok then
        player:setHaloNote(text, 120, 255, 120, 250)
    else
        player:setHaloNote(text, 255, 90, 90, 250)
    end
end

function CSR_InjectSerumAction:new(character, recipient, serum)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.recipient = recipient or character
    o.serum = serum
    o.serumId = serum and serum.getID and serum:getID() or nil
    o.targetOnlineID = o.recipient and o.recipient.getOnlineID and o.recipient:getOnlineID() or nil
    o.maxTime = math.max(70, 190 - (CSR_Antibodies.getMedicalLevel(character) * 8))
    o.stopOnWalk = true
    o.stopOnRun = true
    o.forceProgressBar = true
    o.jobType = getText("IGUI_CSR_Antibody_JobInject")
    -- Opt out of third-party action-duration scalers (e.g. FasterActions) so the
    -- custom inject animation has time to blend in and play.
    o._TWF_FA_SkipScale = true
    return o
end

function CSR_InjectSerumAction:isValid()
    if not CSR_FeatureFlags.isAntibodySystemEnabled() then return false end
    if not self.character or self.character:isDead() then return false end
    self.serum = CSR_Antibodies.findInventoryItemById(
        self.character,
        self.serumId,
        CSR_Antibodies.ITEM_IMMUNE_SYRINGE
    ) or self.serum
    if not self.serum then return false end
    if not self.recipient or self.recipient:isDead() then return false end
    return CSR_Antibodies.distanceOK(self.character, self.recipient, 2.5)
end

function CSR_InjectSerumAction:waitToStart()
    if self.recipient and self.recipient ~= self.character and self.character.faceThisObject then
        self.character:faceThisObject(self.recipient)
        return self.character:shouldBeTurning()
    end
    return false
end

function CSR_InjectSerumAction:update()
    if self.recipient and self.recipient ~= self.character and self.character.faceThisObject then
        self.character:faceThisObject(self.recipient)
    end
    if Metabolics and Metabolics.LightWork then
        self.character:setMetabolicTarget(Metabolics.LightWork)
    end
    self.animTick = (self.animTick or 0) + 1
    if not self.animLooped and self.animTick > 45 then
        self:setActionAnim("CSRAntibodyInjectLoop")
        if self.setOverrideHandModels then
            self:setOverrideHandModels(self.serum, nil)
        end
        self.animLooped = true
    end
end

function CSR_InjectSerumAction:start()
    self.serum = CSR_Antibodies.findInventoryItemById(
        self.character,
        self.serumId,
        CSR_Antibodies.ITEM_IMMUNE_SYRINGE
    ) or self.serum
    self:setActionAnim("CSRAntibodyInject")
    self.animTick = 0
    self.animLooped = false
    if self.setOverrideHandModels then
        self:setOverrideHandModels(self.serum, nil)
    end
end

function CSR_InjectSerumAction:perform()
    if isClient and isClient() then
        sendClientCommand(self.character, CSR_Antibodies.MODULE, CSR_Antibodies.CMD_INJECT, {
            targetOnlineID = self.targetOnlineID,
            serumId = self.serumId,
        })
    else
        local ok, key = CSR_Antibodies.applyInjectSerum(self.character, self.recipient, {
            serumId = self.serumId,
        })
        showHalo(self.character, key, ok)
    end

    ISBaseTimedAction.perform(self)
end

return CSR_InjectSerumAction
