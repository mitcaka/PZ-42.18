require "TimedActions/ISBaseTimedAction"
require "CSR_Utils"

CSR_FieldDressAction = ISBaseTimedAction:derive("CSR_FieldDressAction")
CSR_FieldDressAction.soundDelay = 1

function CSR_FieldDressAction:isValid()
    if not self.corpse or not self.corpse:getSquare() then return false end
    -- Some MP setups return -1 for getStaticMovingObjectIndex on corpses
    -- that the server hasn't registered for this client yet, even though
    -- the corpse is fully usable. Treat negative-index corpses as valid;
    -- if the corpse has truly despawned, the square check above catches it.
    if not self.knife or self.character:getInventory():getItemById(self.knife:getID()) == nil then return false end
    return true
end

function CSR_FieldDressAction:waitToStart()
    self.character:faceThisObject(self.corpse)
    return self.character:shouldBeTurning()
end

function CSR_FieldDressAction:update()
    local now = getTimestamp and getTimestamp() or 0
    if self.nextEffectTime <= now then
        self.nextEffectTime = now + CSR_FieldDressAction.soundDelay
        local emitter = self.character.getEmitter and self.character:getEmitter() or nil
        if emitter and emitter.playSound then self.sound = emitter:playSound("SliceMeat") end
        addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 6, 4)
        addBloodSplat(self.corpse:getSquare(), 2, ZombRandFloat(-0.25, 0.25), ZombRandFloat(-0.25, 0.25))
        self.character:addBlood(nil, true, false, false)
    end

    if self.knife and self.knife.setJobDelta then
        self.knife:setJobDelta(self:getJobDelta())
    end
    self.character:faceThisObject(self.corpse)
    self.character:setMetabolicTarget(Metabolics.MediumWork)
end

function CSR_FieldDressAction:start()
    if self.knife and self.knife.setJobType then
        self.knife:setJobType(getText("ContextMenu_CSR_FieldDressCorpse"))
        self.knife:setJobDelta(0.0)
    end
    -- Match vanilla animal butchering exactly: kneeling Loot anim with the
    -- Low position variable, plus the butcher sound bank for audible
    -- feedback. Using the same anim/event pair vanilla uses ensures the
    -- character actually crouches over the corpse rather than standing.
    self.character:SetVariable("LootPosition", "Low")
    self:setActionAnim("Loot")
    self.character:reportEvent("EventLootItem")
    self.sound = self.character:playSound("ButcheringGatherMeatSmall")
end

function CSR_FieldDressAction:stop()
    if self.sound and self.sound ~= 0 and self.character.getEmitter and self.character:getEmitter():isPlaying(self.sound) then
        self.character:getEmitter():stopSound(self.sound)
    end
    if self.knife and self.knife.setJobDelta then
        self.knife:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function CSR_FieldDressAction:perform()
    if self.knife and self.knife.setJobDelta then
        self.knife:setJobDelta(0.0)
    end

    local args = {
        x = self.corpse:getX(),
        y = self.corpse:getY(),
        z = self.corpse:getZ(),
        knifeId = self.knife:getID(),
        corpseIndex = self.corpse.getStaticMovingObjectIndex and self.corpse:getStaticMovingObjectIndex() or -1,
        requestId = CSR_Utils.makeRequestId(self.character, "FieldDressCorpse"),
        requestTimestamp = getTimestampMs and getTimestampMs() or os.time() * 1000,
    }
    if isClient() then
        sendClientCommand(self.character, "CommonSenseReborn", "FieldDressCorpse", args)
    else
        local handler = CSR_ServerCommands and CSR_ServerCommands.handleFieldDressCorpse
        if handler then handler(self.character, args) end
    end
    ISBaseTimedAction.perform(self)
end

function CSR_FieldDressAction:new(character, corpse, knife)
    local o = ISBaseTimedAction.new(self, character)
    o.corpse = corpse
    o.knife = knife
    o.maxTime = 200
    if character:isTimedActionInstant() then o.maxTime = 1 end
    o.forceProgressBar = true
    o.nextEffectTime = 0
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end
