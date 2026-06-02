require "TimedActions/ISBaseTimedAction"
require "CSR_Throwables"
require "CSR_Utils"
require "CSR_SignalLights"

CSR_ThrowItemAction = ISBaseTimedAction:derive("CSR_ThrowItemAction")

local function getItemById(character, itemId, expectedType)
    if CSR_Utils and CSR_Utils.findInventoryItemById then
        return CSR_Utils.findInventoryItemById(character, itemId, expectedType)
    end
    return nil
end

function CSR_ThrowItemAction:new(character, item, targetX, targetY, targetZ)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.itemId = item and item.getID and item:getID() or nil
    o.itemType = item and item.getFullType and item:getFullType() or nil
    o.targetX = targetX
    o.targetY = targetY
    o.targetZ = targetZ
    local profile = CSR_Throwables.getProfile(item)
    o.maxTime = CSR_Throwables.getActionTime(item, profile)
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = true
    return o
end

function CSR_ThrowItemAction:resolveItem()
    self.item = getItemById(self.character, self.itemId, self.itemType) or self.item
    return self.item
end

function CSR_ThrowItemAction:isValid()
    local item = self:resolveItem()
    local ok, _reason, profile = CSR_Throwables.validatePlayerItem(self.character, item)
    if not ok or not profile then return false end

    local dx = (tonumber(self.targetX) or self.character:getX()) + 0.5 - self.character:getX()
    local dy = (tonumber(self.targetY) or self.character:getY()) + 0.5 - self.character:getY()
    local maxRange = CSR_Throwables.getMaxRange(profile) + 1.0
    return (dx * dx + dy * dy) <= (maxRange * maxRange)
end

function CSR_ThrowItemAction:waitToStart()
    if self.character.faceLocation then
        self.character:faceLocation((self.targetX or self.character:getX()) + 0.5, (self.targetY or self.character:getY()) + 0.5)
    end
    return self.character.shouldBeTurning and self.character:shouldBeTurning()
end

function CSR_ThrowItemAction:update()
    if self.character.faceLocation then
        self.character:faceLocation((self.targetX or self.character:getX()) + 0.5, (self.targetY or self.character:getY()) + 0.5)
    end
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function CSR_ThrowItemAction:start()
    self:resolveItem()
    self:setActionAnim("CSR_ThrowItem")
    self:setOverrideHandModels(self.item, nil)
    self.jobType = getText("ContextMenu_CSR_ThrowablesRoot")
end

function CSR_ThrowItemAction:perform()
    local item = self:resolveItem()
    local args = {
        itemId = self.itemId,
        itemType = self.itemType,
        targetX = self.targetX,
        targetY = self.targetY,
        targetZ = self.targetZ,
        requestId = CSR_Utils.makeRequestId(self.character, CSR_Throwables.CMD_THROW),
        requestTimestamp = getTimestampMs and getTimestampMs() or os.time() * 1000,
    }

    if isClient() then
        if CSR_ThrowablesClient and CSR_ThrowablesClient.spawnProjectile then
            CSR_ThrowablesClient.spawnProjectile(item, self.character, self.targetX, self.targetY, self.targetZ)
        end
        sendClientCommand(self.character, CSR_Throwables.MODULE, CSR_Throwables.CMD_THROW, args)
    else
        local result = CSR_Throwables.performThrow(self.character, item, args)
        if result and result.ok and self.character and result.sound then
            if CSR_ThrowablesClient and CSR_ThrowablesClient.spawnProjectile then
                CSR_ThrowablesClient.spawnProjectile(item, self.character, result.x, result.y, result.z)
            end
            if CSR_SignalLights and CSR_SignalLights.addGlowstickImpact then
                CSR_SignalLights.addGlowstickImpact(result.itemType or self.itemType, result.x, result.y, result.z)
            end
            local sq = getCell() and getCell():getGridSquare(result.x, result.y, result.z) or nil
            if sq and sq.playSound then
                sq:playSound(result.sound)
            else
                self.character:playSound(result.sound)
            end
        end
    end

    ISBaseTimedAction.perform(self)
end

return CSR_ThrowItemAction
