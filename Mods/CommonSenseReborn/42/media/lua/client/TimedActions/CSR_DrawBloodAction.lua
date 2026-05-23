require "TimedActions/ISBaseTimedAction"
require "CSR_Antibodies"
require "CSR_FeatureFlags"

CSR_DrawBloodAction = ISBaseTimedAction:derive("CSR_DrawBloodAction")

local function showHalo(player, key, ok)
    if not player or not player.setHaloNote or not key then return end
    local text = getText and getText(key) or key
    if ok then
        player:setHaloNote(text, 120, 255, 120, 250)
    else
        player:setHaloNote(text, 255, 90, 90, 250)
    end
end

function CSR_DrawBloodAction:new(character, donor, emptySyringe)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.donor = donor or character
    o.emptySyringe = emptySyringe
    o.emptySyringeId = emptySyringe and emptySyringe.getID and emptySyringe:getID() or nil
    o.targetOnlineID = o.donor and o.donor.getOnlineID and o.donor:getOnlineID() or nil
    o.maxTime = math.max(90, 260 - (CSR_Antibodies.getMedicalLevel(character) * 12))
    o.stopOnWalk = true
    o.stopOnRun = true
    o.forceProgressBar = true
    o.jobType = getText("IGUI_CSR_Antibody_JobDraw")
    -- Opt out of third-party action-duration scalers (e.g. FasterActions) so the
    -- custom blood-draw animation has time to blend in and play.
    o._TWF_FA_SkipScale = true
    return o
end

function CSR_DrawBloodAction:isValid()
    if not CSR_FeatureFlags.isAntibodySystemEnabled() then return false end
    if not self.character or self.character:isDead() then return false end
    self.emptySyringe = CSR_Antibodies.findInventoryItemById(
        self.character,
        self.emptySyringeId,
        CSR_Antibodies.ITEM_EMPTY_SYRINGE
    ) or self.emptySyringe
    if not self.emptySyringe then return false end
    if not self.donor or self.donor:isDead() then return false end
    return CSR_Antibodies.distanceOK(self.character, self.donor, 2.5)
end

function CSR_DrawBloodAction:waitToStart()
    if self.donor and self.donor ~= self.character and self.character.faceThisObject then
        self.character:faceThisObject(self.donor)
        return self.character:shouldBeTurning()
    end
    return false
end

function CSR_DrawBloodAction:update()
    if self.donor and self.donor ~= self.character and self.character.faceThisObject then
        self.character:faceThisObject(self.donor)
    end
    if Metabolics and Metabolics.LightWork then
        self.character:setMetabolicTarget(Metabolics.LightWork)
    end
    self.animTick = (self.animTick or 0) + 1
    if not self.animLooped and self.animTick > 45 then
        self:setActionAnim("CSRAntibodyInjectLoop")
        if self.setOverrideHandModels then
            self:setOverrideHandModels(self.emptySyringe, nil)
        end
        self.animLooped = true
    end
end

function CSR_DrawBloodAction:start()
    self.emptySyringe = CSR_Antibodies.findInventoryItemById(
        self.character,
        self.emptySyringeId,
        CSR_Antibodies.ITEM_EMPTY_SYRINGE
    ) or self.emptySyringe
    self:setActionAnim("CSRAntibodyInject")
    self.animTick = 0
    self.animLooped = false
    if self.setOverrideHandModels then
        self:setOverrideHandModels(self.emptySyringe, nil)
    end
end

function CSR_DrawBloodAction:perform()
    if isClient and isClient() then
        sendClientCommand(self.character, CSR_Antibodies.MODULE, CSR_Antibodies.CMD_DRAW, {
            targetOnlineID = self.targetOnlineID,
            emptySyringeId = self.emptySyringeId,
        })
    else
        local ok, key = CSR_Antibodies.applyDrawBlood(self.character, self.donor, {
            emptySyringeId = self.emptySyringeId,
        })
        showHalo(self.character, key, ok)
    end

    ISBaseTimedAction.perform(self)
end

return CSR_DrawBloodAction
