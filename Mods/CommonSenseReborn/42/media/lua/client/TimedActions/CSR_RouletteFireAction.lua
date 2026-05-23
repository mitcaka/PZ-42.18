require "TimedActions/ISBaseTimedAction"
require "CSR_RouletteData"

CSR_RouletteFireAction = ISBaseTimedAction:derive("CSR_RouletteFireAction")

local function nowMs()
    if getTimestampMs then return getTimestampMs() end
    if getTimestamp then return getTimestamp() * 1000 end
    return (os and os.time and os.time() or 0) * 1000
end

function CSR_RouletteFireAction:isValid()
    return self.character and not self.character:isDead() and self.weapon ~= nil
end

function CSR_RouletteFireAction:captureAmmoState()
    local weapon = self.weapon
    if not weapon then return end
    local snapshot = {}
    if weapon.getCurrentAmmoCount then
        snapshot.ammo = tonumber(weapon:getCurrentAmmoCount())
    end
    if weapon.isRoundChambered then
        snapshot.chambered = weapon:isRoundChambered() == true
    elseif weapon.getRoundChambered then
        snapshot.chambered = weapon:getRoundChambered() == true
    end
    self.ammoSnapshot = snapshot
end

function CSR_RouletteFireAction:restoreAmmoState()
    local weapon = self.weapon
    local snapshot = self.ammoSnapshot
    if not weapon or not snapshot then return end

    if snapshot.ammo ~= nil and weapon.setCurrentAmmoCount then
        weapon:setCurrentAmmoCount(snapshot.ammo)
    end
    if snapshot.chambered ~= nil and weapon.setRoundChambered then
        weapon:setRoundChambered(snapshot.chambered)
    end
    if weapon.syncItemFields then weapon:syncItemFields() end
    if self.character and self.character.sendInventory then
        self.character:sendInventory()
    end
end

function CSR_RouletteFireAction:start()
    self:captureAmmoState()
    self.startedMs = nowMs()
    self.character:setVariable("PerformSuicideSpeed", 1)
    self:setActionAnim(self.anim)
end

function CSR_RouletteFireAction:update()
    -- Vanilla suicide anim is gated on game speed 1 to avoid timing skips
    -- when watching a session at fast-forward.
    local speedControls = UIManager and UIManager.getSpeedControls and UIManager:getSpeedControls() or nil
    if speedControls and speedControls.getCurrentGameSpeed and speedControls:getCurrentGameSpeed() ~= 1 then
        if speedControls.SetCurrentGameSpeed then speedControls:SetCurrentGameSpeed(1) end
    end
    if not self.resolved and self.timeoutMs and self.timeoutMs > 0 then
        local current = nowMs()
        local started = self.startedMs or current
        if current - started >= self.timeoutMs then
            self:resolveAnimEvent()
        end
    end
end

function CSR_RouletteFireAction:resolveAnimEvent()
    if self.resolved then return end
    self.resolved = true
    self:restoreAmmoState()
    if self.killOutcome then
        if self.weapon and self.weapon.getSwingSound then
            self.character:playSound(self.weapon:getSwingSound())
        end
        local bd = self.character:getBodyDamage()
        local head = bd and bd.getBodyPart and bd:getBodyPart(BodyPartType.Head) or nil
        if head then
            head:setHaveBullet(true, 0)
        end
        if self.character.splatBloodFloorBig then
            self.character:splatBloodFloorBig()
        end
        -- MP-aware self-kill: Kill(killer) is the canonical path PZ uses for
        -- death events.  Setting health to zero directly bypasses the death
        -- replication that the server needs to fire respawn.
        self.character:Kill(self.character)
    else
        if self.weapon and self.weapon.getClickSound then
            self.character:playSound(self.weapon:getClickSound())
        end
        if HaloTextHelper and HaloTextHelper.addText then
            HaloTextHelper.addText(self.character, "Click.", HaloTextHelper.getColorWhite and HaloTextHelper.getColorWhite() or nil)
        else
            self.character:Say("Click.")
        end
    end
    self:forceComplete()
end

function CSR_RouletteFireAction:animEvent(event, parameter)
    if event == "shootTime" or event == "killTime" then
        self:resolveAnimEvent()
    end
end

function CSR_RouletteFireAction:perform()
    if not self.resolved then self:resolveAnimEvent() end
    self:restoreAmmoState()
    ISBaseTimedAction.perform(self)
end

function CSR_RouletteFireAction:stop()
    self:restoreAmmoState()
    ISBaseTimedAction.stop(self)
end

function CSR_RouletteFireAction:new(character, weapon, killOutcome, anim)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.weapon = weapon
    o.killOutcome = killOutcome and true or false
    o.anim = anim or "CSR_Roulette_Handgun"
    o.stopOnAim = true
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = -1
    o.useProgressBar = false
    o.resolved = false
    o.timeoutMs = 6500
    return o
end

return CSR_RouletteFireAction
