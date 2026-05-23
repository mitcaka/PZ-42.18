CSR_Standpipe = {}

local function sandbox()
    return SandboxVars and SandboxVars.CommonSenseReborn or {}
end

CSR_Standpipe.SPRITE_NAME = "street_decoration_01_12"
CSR_Standpipe.OBJECT_NAME = "CSRStandpipe"
CSR_Standpipe.CUSTOM_NAME = "Standpipe"
CSR_Standpipe.CONTAINER_NAME = "CSRStandpipeWater"
CSR_Standpipe.WATER_MAX = 12000.0
CSR_Standpipe.WATER_INITIAL_MIN = 3000.0
CSR_Standpipe.NOISE_RADIUS = 10
CSR_Standpipe.STRENGTH_XP = 2
CSR_Standpipe.MAINTENANCE_XP = 2

local function clampInt(value, fallback, minValue, maxValue)
    local number = math.floor(tonumber(value) or fallback)
    if number < minValue then return minValue end
    if number > maxValue then return maxValue end
    return number
end

local function clampFloat(value, fallback, minValue, maxValue)
    local number = tonumber(value) or fallback
    if number < minValue then return minValue end
    if number > maxValue then return maxValue end
    return number
end

local function predicateNotBroken(item)
    return item and item:isBroken() == false
end

function CSR_Standpipe.isEnabled()
    if sandbox().EnableCityStandpipes == false then return false end
    -- Defer to CityStandpipes mod if loaded (same sprite, would conflict)
    if getActivatedMods and getActivatedMods().contains and getActivatedMods():contains("CityStandpipes") then
        return false
    end
    return true
end

function CSR_Standpipe.getMinimumStrength()
    return clampInt(sandbox().CityStandpipeMinimumStrength, 5, 0, 10)
end

function CSR_Standpipe.getBaseDuration()
    return clampInt(sandbox().CityStandpipeBaseDuration, 20, 1, 120)
end

function CSR_Standpipe.getBaseMuscleStrain()
    return clampFloat(sandbox().CityStandpipeBaseMuscleStrain, 8.0, 0.0, 40.0)
end

function CSR_Standpipe.isStandpipeSpriteName(spriteName)
    return spriteName == CSR_Standpipe.SPRITE_NAME
end

function CSR_Standpipe.isStandpipeObject(obj)
    if not obj or type(obj.getSprite) ~= "function" then
        return false
    end

    local sprite = obj:getSprite()
    if not sprite then
        return false
    end

    local spriteName = type(sprite.getName) == "function" and sprite:getName() or nil
    if CSR_Standpipe.isStandpipeSpriteName(spriteName) then
        return true
    end

    local props = sprite:getProperties()
    if not props then
        return false
    end

    if type(props.get) == "function" then
        return props:get("CustomName") == CSR_Standpipe.CUSTOM_NAME
    end

    return false
end

function CSR_Standpipe.getStandpipeObjectOnSquare(square)
    if not square then
        return nil
    end

    local objects = square:getObjects()
    if not objects then
        return nil
    end

    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if CSR_Standpipe.isStandpipeObject(obj) then
            return obj
        end
    end

    return nil
end

function CSR_Standpipe.findStandpipeFromWorldObjects(worldObjects)
    if not worldObjects then
        return nil
    end

    for i = 1, #worldObjects do
        local worldObject = worldObjects[i]
        if CSR_Standpipe.isStandpipeObject(worldObject) then
            return worldObject
        end

        local square = worldObject and worldObject.getSquare and worldObject:getSquare() or nil
        local standpipe = CSR_Standpipe.getStandpipeObjectOnSquare(square)
        if standpipe then
            return standpipe
        end
    end

    return nil
end

function CSR_Standpipe.findPipeWrench(player)
    if not player then
        return nil
    end

    local inventory = player:getInventory()
    if not inventory then
        return nil
    end

    return inventory:getFirstTypeEvalRecurse("PipeWrench", predicateNotBroken)
        or inventory:getFirstTagEvalRecurse(ItemTag.PIPE_WRENCH, predicateNotBroken)
end

function CSR_Standpipe.prepareAction(player, wrench, target)
    if not player or not wrench or not target then
        return
    end

    if player:hasEquipped(wrench:getFullType()) == false then
        ISInventoryPaneContextMenu.equipWeapon(wrench, true, true, player:getPlayerNum(), false)
    end

    luautils.walkToObject(player, target, false)
end

function CSR_Standpipe.calculateDuration(player)
    if player:isTimedActionInstant() then
        return 1
    end

    local baseDuration = CSR_Standpipe.getBaseDuration()
    local strengthReductionFactor = baseDuration / 11.0
    local actualDuration = baseDuration - ((player:getPerkLevel(Perks.Strength) or 0) * strengthReductionFactor)
    if actualDuration < 1 then
        actualDuration = 1
    end
    return math.floor(actualDuration * 60)
end

function CSR_Standpipe.calculateTimedActionMuscleStrain(player)
    local strengthLevel = math.max(0, math.min(player:getPerkLevel(Perks.Strength) or 0, 10))
    local strengthFactor = 1.0 - (strengthLevel / 30.0)
    local actualStrain = CSR_Standpipe.getBaseMuscleStrain() * strengthFactor
    return math.max(0.0, actualStrain)
end

function CSR_Standpipe.copyModData(source, target)
    if not source or not target then
        return
    end

    for key, value in pairs(source) do
        target[key] = value
    end
end

function CSR_Standpipe.getFluidAmount(obj)
    if not obj then
        return 0
    end

    if obj.getFluidAmount then
        local amount = obj:getFluidAmount()
        if type(amount) == "number" then
            return amount
        end
    end

    local fluidContainer = obj.getFluidContainer and obj:getFluidContainer() or nil
    if fluidContainer and fluidContainer.getAmount then
        local amount = fluidContainer:getAmount()
        if type(amount) == "number" then
            return amount
        end
    end

    return 0
end

function CSR_Standpipe.getFluidCapacity(obj)
    if not obj then
        return CSR_Standpipe.WATER_MAX
    end

    local fluidContainer = obj.getFluidContainer and obj:getFluidContainer() or nil
    if fluidContainer and fluidContainer.getCapacity then
        local capacity = fluidContainer:getCapacity()
        if type(capacity) == "number" and capacity > 0 then
            return capacity
        end
    end

    local modData = obj.getModData and obj:getModData() or nil
    return clampFloat(modData and modData.CSRStandpipeWaterMax, CSR_Standpipe.WATER_MAX, 1.0, CSR_Standpipe.WATER_MAX)
end

function CSR_Standpipe.syncObject(obj)
    if not obj then
        return
    end

    if obj.sync then
        obj:sync()
    end
    if obj.transmitModData then
        obj:transmitModData()
    end
end

function CSR_Standpipe.withUnlockedFluidContainer(obj, callback)
    local fluidContainer = obj and obj.getFluidContainer and obj:getFluidContainer() or nil
    if not fluidContainer or type(callback) ~= "function" then
        return false
    end

    local relock = false
    if fluidContainer.isInputLocked and fluidContainer.setInputLocked then
        local locked = fluidContainer:isInputLocked()
        if locked then
            relock = true
            fluidContainer:setInputLocked(false)
        end
    end

    local result = callback(fluidContainer)
    if relock then
        fluidContainer:setInputLocked(true)
    end
    return result ~= false
end

function CSR_Standpipe.setFluidAmount(obj, amount)
    if not obj then
        return false
    end

    local capacity = CSR_Standpipe.getFluidCapacity(obj)
    amount = clampFloat(amount, 0.0, 0.0, capacity)

    local changed = CSR_Standpipe.withUnlockedFluidContainer(obj, function(fluidContainer)
        if fluidContainer.Empty then
            fluidContainer:Empty()
        end
        if amount > 0 and fluidContainer.addFluid and Fluid and Fluid.Water then
            fluidContainer:addFluid(Fluid.Water, amount)
        end
    end)

    if changed == false and obj.setWaterAmount then
        obj:setWaterAmount(amount)
    end

    if obj.setTaintedWater then
        obj:setTaintedWater(false)
    end

    CSR_Standpipe.syncObject(obj)
    return true
end

function CSR_Standpipe.ensureFluidCapacity(obj, capacity)
    local fluidContainer = obj and obj.getFluidContainer and obj:getFluidContainer() or nil
    if not fluidContainer or not fluidContainer.setCapacity then
        return
    end

    local currentCapacity = nil
    if fluidContainer.getCapacity then
        currentCapacity = fluidContainer:getCapacity()
    end

    if type(currentCapacity) == "number" and math.abs(currentCapacity - capacity) <= 0.001 then
        return
    end

    fluidContainer:setCapacity(capacity)
end

local function getStableObjectHash(obj)
    local square = obj and obj.getSquare and obj:getSquare() or nil
    if not square then
        return 0
    end

    local hash = (square:getX() * 73856093) + (square:getY() * 19349663) + (square:getZ() * 83492791)
    local sprite = obj.getSprite and obj:getSprite() or nil
    local spriteName = sprite and sprite:getName() or ""
    for i = 1, #spriteName, 4 do
        hash = hash + ((string.byte(spriteName, i) or 0) * i)
    end
    return math.abs(math.floor(hash))
end

function CSR_Standpipe.getInitialWaterAmount(obj, capacity)
    capacity = clampFloat(capacity, CSR_Standpipe.WATER_MAX, 1.0, CSR_Standpipe.WATER_MAX)
    local minimum = math.min(CSR_Standpipe.WATER_INITIAL_MIN, capacity)
    if capacity <= minimum then
        return capacity
    end

    local ratio = (getStableObjectHash(obj) % 10001) / 10000
    return math.floor(minimum + ((capacity - minimum) * ratio) + 0.5)
end

function CSR_Standpipe.ensureManagedData(obj)
    local modData = obj:getModData()
    modData.CSRStandpipeManaged = true
    modData.CSRStandpipeWaterMax = clampFloat(modData.CSRStandpipeWaterMax, CSR_Standpipe.WATER_MAX, 1.0, CSR_Standpipe.WATER_MAX)
    CSR_Standpipe.ensureFluidCapacity(obj, modData.CSRStandpipeWaterMax)

    if modData.CSRStandpipeOpen == nil then
        modData.CSRStandpipeOpen = false
    end
    if modData.CSRStandpipeLiveAmountKnown == nil then
        modData.CSRStandpipeLiveAmountKnown = false
    end

    if modData.CSRStandpipeStoredWater == nil then
        local currentAmount = clampFloat(CSR_Standpipe.getFluidAmount(obj), 0.0, 0.0, modData.CSRStandpipeWaterMax)
        if currentAmount > 0 then
            modData.CSRStandpipeStoredWater = currentAmount
            modData.CSRStandpipeLiveAmountKnown = true
        else
            modData.CSRStandpipeStoredWater = CSR_Standpipe.getInitialWaterAmount(obj, modData.CSRStandpipeWaterMax)
        end
    else
        modData.CSRStandpipeStoredWater = clampFloat(modData.CSRStandpipeStoredWater, 0.0, 0.0, modData.CSRStandpipeWaterMax)
    end

    return modData
end

function CSR_Standpipe.isOpen(obj)
    return obj and obj:getModData().CSRStandpipeOpen == true or false
end

function CSR_Standpipe.attachGameEntity(obj, spriteName)
    if not obj or obj:getFluidContainer() then
        return
    end

    local info = SpriteConfigManager and SpriteConfigManager.getObjectInfoFromSprite and SpriteConfigManager.getObjectInfoFromSprite(spriteName) or nil
    if info and info.getScript and info:getScript() and info:getScript():getParent() then
        GameEntityFactory.CreateIsoObjectEntity(obj, info:getScript():getParent(), true)
    elseif obj.createFluidContainer then
        obj:createFluidContainer()
    end
end

function CSR_Standpipe.refreshWaterState(obj)
    if not obj then
        return
    end

    local modData = CSR_Standpipe.ensureManagedData(obj)
    local currentAmount = clampFloat(CSR_Standpipe.getFluidAmount(obj), 0.0, 0.0, modData.CSRStandpipeWaterMax)
    local shouldProvideWater = modData.CSRStandpipeOpen == true and CSR_Standpipe.isEnabled()
    local targetAmount = 0.0

    if shouldProvideWater then
        if currentAmount > 0 then
            modData.CSRStandpipeStoredWater = currentAmount
            modData.CSRStandpipeLiveAmountKnown = true
            targetAmount = currentAmount
        elseif modData.CSRStandpipeLiveAmountKnown == true then
            modData.CSRStandpipeStoredWater = 0.0
        else
            targetAmount = clampFloat(modData.CSRStandpipeStoredWater, 0.0, 0.0, modData.CSRStandpipeWaterMax)
        end
    else
        if currentAmount > 0 then
            modData.CSRStandpipeStoredWater = currentAmount
        end
        modData.CSRStandpipeLiveAmountKnown = false
    end

    if math.abs(currentAmount - targetAmount) > 0.001 then
        CSR_Standpipe.setFluidAmount(obj, targetAmount)
        return
    end

    if obj.setTaintedWater then
        obj:setTaintedWater(false)
    end
    CSR_Standpipe.syncObject(obj)
end

function CSR_Standpipe.replaceWithManagedObject(obj)
    if not obj then
        return nil
    end

    local square = obj:getSquare()
    if not square then
        return nil
    end

    local sprite = obj:getSprite()
    local spriteName = sprite and sprite:getName() or CSR_Standpipe.SPRITE_NAME
    local index = obj:getObjectIndex()
    local oldModData = obj:getModData()

    square:transmitRemoveItemFromSquare(obj)

    local newObj = IsoObject.new(square, spriteName, CSR_Standpipe.OBJECT_NAME)
    CSR_Standpipe.attachGameEntity(newObj, spriteName)
    CSR_Standpipe.copyModData(oldModData, newObj:getModData())

    square:AddTileObject(newObj, index)
    CSR_Standpipe.ensureManagedData(newObj)
    CSR_Standpipe.refreshWaterState(newObj)
    newObj:transmitCompleteItemToClients()
    return newObj
end

function CSR_Standpipe.resolveManagedObject(obj)
    if not CSR_Standpipe.isStandpipeObject(obj) then
        return nil
    end

    if obj:getFluidContainer() == nil then
        if isClient() then
            return obj
        end
        return CSR_Standpipe.replaceWithManagedObject(obj)
    end

    CSR_Standpipe.ensureManagedData(obj)
    return obj
end

function CSR_Standpipe.applyMuscleStrain(player, strainDelta)
    if player and strainDelta and strainDelta > 0 then
        player:addBothArmMuscleStrain(strainDelta)
    end
end

function CSR_Standpipe.applyCompletionEffects(player, wrench, opening)
    if not player then
        return
    end

    CSR_Standpipe.applyMuscleStrain(player, CSR_Standpipe.calculateTimedActionMuscleStrain(player))
    addXp(player, Perks.Strength, CSR_Standpipe.STRENGTH_XP)

    if wrench and wrench.damageCheck and wrench:damageCheck(0, 0.05, true, true, player) == true then
        addXp(player, Perks.Maintenance, CSR_Standpipe.MAINTENANCE_XP)
    end

    if opening then
        addSound(player, player:getX(), player:getY(), player:getZ(), CSR_Standpipe.NOISE_RADIUS, 1)
    end
end

function CSR_Standpipe.setOpenState(obj, open)
    obj = CSR_Standpipe.resolveManagedObject(obj)
    if not obj then
        return false
    end

    local modData = CSR_Standpipe.ensureManagedData(obj)
    modData.CSRStandpipeOpen = open == true
    modData.CSRStandpipeLiveAmountKnown = false
    CSR_Standpipe.refreshWaterState(obj)
    return true
end

function CSR_Standpipe.applyAction(player, obj, wrench, open)
    obj = CSR_Standpipe.resolveManagedObject(obj)
    if not obj then
        return false
    end

    if CSR_Standpipe.setOpenState(obj, open) then
        CSR_Standpipe.applyCompletionEffects(player, wrench, open == true)
        return true
    end
    return false
end

return CSR_Standpipe
