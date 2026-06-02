local CSR_DualWieldUtils = require "CSR_DualWieldUtils"
require "TimedActions/ISBaseTimedAction"

local ACTION_ANIM_PUNCH = "CSR_DualWield_PunchLeft"
local ACTION_ANIM_STAB = "CSR_DualWield_StabLeft"
local ACTION_ANIM_SWING = "CSR_DualWield_SwingLeft"
local CLOSE_FALLBACK_RANGE = 1.5

local function getBodyPartPain(character, bodyPartType)
    local part = character:getBodyDamage():getBodyPart(bodyPartType)
    return part:getPain()
end

CSR_LeftHandAttackAction = ISBaseTimedAction:derive("CSR_LeftHandAttackAction")

local function setLCombatSpeed(character, speed)
    if character and character.setVariable then
        character:setVariable("LCombatSpeed", speed or 1.0)
    end
end

local function clearLCombatSpeed(character)
    if not character then return end
    if character.clearVariable then
        character:clearVariable("LCombatSpeed")
    elseif character.setVariable then
        character:setVariable("LCombatSpeed", 1.0)
    end
end

function CSR_LeftHandAttackAction.isValidTarget(enemy, character, rangeSq, allowAttackFloor)
    if not enemy or not character then
        return false, nil
    end
    if not enemy:isZombie() or enemy:isDead() or (not allowAttackFloor and enemy:isProne()) then
        return false, nil
    end
    if enemy.getZ and character.getZ and enemy:getZ() ~= character:getZ() then
        return false, nil
    end
    local dist = enemy:DistToSquared(character)
    return dist <= rangeSq, dist
end

function CSR_LeftHandAttackAction.calcRange(character, weapon)
    local ignoreProneRange = Core.getInstance():getIgnoreProneZombieRange()
    local weaponRange = weapon:getMaxRange() * weapon:getRangeMod(character)
    local lungeStateExtraRange = 1
    local range = math.max(ignoreProneRange, weaponRange + lungeStateExtraRange)
    return range ^ 2
end

local function insertCandidate(result, enemy, dist, maxHits)
    local inserted = false
    for index, other in ipairs(result) do
        if dist < other.dist then
            table.insert(result, index, { enemy = enemy, dist = dist })
            inserted = true
            break
        end
    end
    if not inserted and #result < maxHits then
        table.insert(result, { enemy = enemy, dist = dist })
    elseif #result > maxHits then
        table.remove(result)
    end
end

local function scanCellObjects(character, callback)
    local square = character and character.getSquare and character:getSquare() or nil
    local cell = square and square.getCell and square:getCell() or nil
    local objects = cell and cell.getObjectListForLua and cell:getObjectListForLua() or nil
    if not objects then return end

    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj and instanceof(obj, "IsoZombie") then
            callback(obj)
        end
    end
end

function CSR_LeftHandAttackAction.findClosestEnemiesFor(character, rangeSq, allowAttackFloor, maxHits)
    local result = {}
    local seen = {}
    maxHits = maxHits or 1

    local function consider(enemy, candidateRangeSq)
        if seen[enemy] then return end
        seen[enemy] = true
        local valid, dist = CSR_LeftHandAttackAction.isValidTarget(enemy, character, candidateRangeSq, allowAttackFloor)
        if valid then
            insertCandidate(result, enemy, dist, maxHits)
        end
    end

    local enemies = character and character.getSpottedList and character:getSpottedList() or nil
    if enemies then
        for i = 0, enemies:size() - 1 do
            consider(enemies:get(i), rangeSq)
        end
    end

    local closeRangeSq = math.min(rangeSq, CLOSE_FALLBACK_RANGE * CLOSE_FALLBACK_RANGE)
    scanCellObjects(character, function(enemy)
        consider(enemy, closeRangeSq)
    end)

    return result
end

function CSR_LeftHandAttackAction.findPreferredEnemiesFor(character, rangeSq, allowAttackFloor, maxHits, targetIDs)
    local result = {}
    local seen = {}
    local hasLivePreferred = false
    maxHits = maxHits or 1
    if not targetIDs then return result, hasLivePreferred end

    for _, targetID in ipairs(targetIDs) do
        local enemy = CSR_DualWieldUtils.getZombieFromID(character, targetID)
        if enemy and not seen[enemy] then
            seen[enemy] = true
            if enemy:isZombie() and not enemy:isDead() then
                hasLivePreferred = true
            end
            local valid, dist = CSR_LeftHandAttackAction.isValidTarget(enemy, character, rangeSq, allowAttackFloor)
            if valid then
                insertCandidate(result, enemy, dist, maxHits)
            end
        end
    end

    return result, hasLivePreferred
end

function CSR_LeftHandAttackAction.anyEnemyInRange(character, weapon, mode)
    local rangeSq = CSR_LeftHandAttackAction.calcRange(character, weapon)
    return #CSR_LeftHandAttackAction.findClosestEnemiesFor(character, rangeSq, mode.ALLOWATTACKFLOOR, 1) > 0
end

function CSR_LeftHandAttackAction.getMaxHits(character, weapon, mode)
    local result = mode.MAXHITS_BASE or 1
    if mode.MAXHITS_PERKBONUS then
        local perk = weapon:getPerk()
        result = result + math.floor(character:getPerkLevel(perk) * mode.MAXHITS_PERKBONUS + 0.5)
    end
    return result
end

function CSR_LeftHandAttackAction.getSpeed(character, weapon, mode)
    local result = mode.SPEED_BASE or 1
    if mode.SPEED_PERKBONUS then
        local perk = weapon:getPerk()
        result = result + character:getPerkLevel(perk) * mode.SPEED_PERKBONUS
    end
    return result
end

function CSR_LeftHandAttackAction.getConditionMultiplier(character, weapon, mode)
    local result = mode.CONDITIONLOWER_BASE or 1
    if mode.CONDITIONLOWER_PERKBONUS then
        local perk = weapon:getPerk()
        result = result + character:getPerkLevel(perk) * mode.CONDITIONLOWER_PERKBONUS
    end
    return result
end

function CSR_LeftHandAttackAction.getMaxTime(character, weapon, mode)
    local res = CSR_DualWield.LEFT_ATTACK_TIME
    res = res * (1 + (character:getMoodles():getMoodleLevel(MoodleType.DRUNK) / 4))
    local maxPain = getBodyPartPain(character, BodyPartType.Hand_L)
        + getBodyPartPain(character, BodyPartType.ForeArm_L)
        + getBodyPartPain(character, BodyPartType.UpperArm_L)
    local speed = CSR_LeftHandAttackAction.getSpeed(character, weapon, mode)
    res = res * (1 + (maxPain / 300))
    res = res * character:getCombatSpeed() / speed
    return res
end

local function isStabWeapon(weapon)
    if not weapon then return false end
    if weapon.getSwingAnim and weapon:getSwingAnim() == "Stab" then return true end
    if weapon.getSubCategory and weapon:getSubCategory() == "Stab" then return true end
    return false
end

function CSR_LeftHandAttackAction.getActionAnimName(weapon, weaponMode)
    if weaponMode == CSR_DualWield.ArmedMode then
        if isStabWeapon(weapon) then
            return ACTION_ANIM_STAB
        end
        return ACTION_ANIM_SWING
    end
    return ACTION_ANIM_PUNCH
end

function CSR_LeftHandAttackAction:update()
    self.character:setMetabolicTarget(Metabolics.UsingTools)
    -- Safety fallback: if animEvent never fired (e.g. animation interrupted)
    if not self.attackDone and self:getJobDelta() >= 0.95 then
        self.attackDone = true
        self:doAttack()
    end
end

function CSR_LeftHandAttackAction:animEvent(event, parameter)
    if event == "StartAttack" then
        local swingSound = self.weapon:getSwingSound()
        if swingSound and swingSound ~= "" then
            self.sound = self.character:playSound(swingSound)
        end
    elseif event == "AttackCollisionCheck" then
        if not self.attackDone then
            self.attackDone = true
            self:doAttack()
        end
    elseif event == "EndAttack" then
        self:forceComplete()
    end
end

function CSR_LeftHandAttackAction:restoreSecondaryWeapon()
    local weapon = self.savedSecondaryWeapon
    if not weapon then return end
    if weapon.isBroken and weapon:isBroken() then return end
    local inv = self.character and self.character:getInventory()
    if inv and inv.contains and not inv:contains(weapon) then return end
    if self.character:getSecondaryHandItem() == weapon then return end
    -- Preserve hotbar metadata while combat restores the held secondary weapon.
    -- Clearing attachedSlot here detaches the weapon from its assigned hotbar slot.
    self.character:setSecondaryHandItem(weapon)
end

function CSR_LeftHandAttackAction:start()
    if self.weaponMode == CSR_DualWield.ArmedMode then
        if self.character:getSecondaryHandItem() ~= self.weapon then
            self:forceComplete()
            return
        end
        self.savedSecondaryWeapon = self.weapon
    end
    sendClientCommand(CSR_DualWield.COMMANDMODULE, CSR_DualWield.Commands.TRIGGERLEFTHANDATTACK, {})
    setLCombatSpeed(self.character, self.speed)
    self:setActionAnim(self.actionAnim or CSR_LeftHandAttackAction.getActionAnimName(self.weapon, self.weaponMode))
    if self.weaponMode == CSR_DualWield.ArmedMode and self.setOverrideHandModels then
        self:setOverrideHandModels(nil, self.weapon)
    end
    self.character:setMeleeDelay(self.maxTime)
    self.character:setAuthorizeMeleeAction(false)
    self.character:setAuthorizeShoveStomp(false)
    self.character:setAuthorizedHandToHandAction(false)
end

function CSR_LeftHandAttackAction:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
end

function CSR_LeftHandAttackAction:stop()
    self:stopSound()
    self:restoreSecondaryWeapon()
    clearLCombatSpeed(self.character)
    self.character:setAuthorizeMeleeAction(true)
    self.character:setAuthorizeShoveStomp(true)
    self.character:setAuthorizedHandToHandAction(true)
    ISBaseTimedAction.stop(self)
end

function CSR_LeftHandAttackAction:forceCancel()
    self:restoreSecondaryWeapon()
    clearLCombatSpeed(self.character)
    self.character:setAuthorizeMeleeAction(true)
    self.character:setAuthorizeShoveStomp(true)
    self.character:setAuthorizedHandToHandAction(true)
end

function CSR_LeftHandAttackAction:hasPreferredTargets()
    return self.preferredTargetIDs and #self.preferredTargetIDs > 0
end

function CSR_LeftHandAttackAction:findPreferredEnemies()
    return CSR_LeftHandAttackAction.findPreferredEnemiesFor(
        self.character,
        self.rangeSq,
        self.allowAttackFloor,
        self.maxHits,
        self.preferredTargetIDs
    )
end

function CSR_LeftHandAttackAction:findClosestEnemies()
    if self:hasPreferredTargets() then
        local preferred, hasLivePreferred = self:findPreferredEnemies()
        if #preferred > 0 then
            return preferred
        end
        if hasLivePreferred then
            return preferred
        end
    end
    return CSR_LeftHandAttackAction.findClosestEnemiesFor(self.character, self.rangeSq, self.allowAttackFloor, self.maxHits)
end

function CSR_LeftHandAttackAction:doAttack()
    local targets = self:findClosestEnemies()
    if #targets <= 0 then return end
    self.character:playSound(self.weapon:getZombieHitSound())
    local targetIDs = {}
    for _, target in ipairs(targets) do
        table.insert(targetIDs, CSR_DualWieldUtils.getCharacterID(target.enemy))
    end
    sendClientCommand(CSR_DualWield.COMMANDMODULE, CSR_DualWield.Commands.TRIGGERLEFTHANDHIT, targetIDs)
end

function CSR_LeftHandAttackAction:perform()
    self:restoreSecondaryWeapon()
    clearLCombatSpeed(self.character)
    self.character:setAuthorizeMeleeAction(true)
    self.character:setAuthorizeShoveStomp(true)
    self.character:setAuthorizedHandToHandAction(true)
    ISBaseTimedAction.perform(self)
end

function CSR_LeftHandAttackAction:adjustMaxTime(maxTime)
    return maxTime
end

function CSR_LeftHandAttackAction:isValid()
    if not self.character or self.character:isDead() then
        return false
    end
    if not self.weapon then
        return false
    end
    if self.weapon.isBroken and self.weapon:isBroken() then
        return false
    end
    if self.weaponMode == CSR_DualWield.ArmedMode then
        local sec = self.character:getSecondaryHandItem()
        if sec ~= self.weapon then
            self:restoreSecondaryWeapon()
            sec = self.character:getSecondaryHandItem()
            if sec ~= self.weapon then
                return false
            end
        end
    end
    return true
end

function CSR_LeftHandAttackAction:new(character, weapon, weaponMode, preferredTargetIDs)
    local o = ISBaseTimedAction.new(self, character)
    o.weapon = weapon
    o.weaponMode = weaponMode
    o.preferredTargetIDs = preferredTargetIDs
    o.actionAnim = CSR_LeftHandAttackAction.getActionAnimName(weapon, weaponMode)
    o.speed = CSR_LeftHandAttackAction.getSpeed(character, weapon, weaponMode)
    o.allowAttackFloor = weaponMode.ALLOWATTACKFLOOR
    o.stopWalking = false
    o.stopOnWalk = false
    o.stopOnRun = true
    o.stopOnAim = false
    o.useProgressBar = false
    o.maxTime = CSR_LeftHandAttackAction.getMaxTime(character, weapon, weaponMode)
    o.rangeSq = CSR_LeftHandAttackAction.calcRange(character, weapon)
    o.attackDone = false
    o.maxHits = CSR_LeftHandAttackAction.getMaxHits(character, weapon, weaponMode)
    -- Opt out of third-party action-duration scalers (e.g. FasterActions). The
    -- swing recovery timing is computed from the weapon and must match the
    -- right-hand swing -- any external division of getDuration() desyncs the
    -- attack animation.
    o._TWF_FA_SkipScale = true
    return o
end
