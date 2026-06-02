require "AdvancedDrying42_Utils"

AdvancedDrying42 = AdvancedDrying42 or {}
AdvancedDrying42.TrackedFood = AdvancedDrying42.TrackedFood or {}

local TrackedFood = AdvancedDrying42.TrackedFood
local Utils = AdvancedDrying42.Utils

TrackedFood.DEFAULT_PORTION_WEIGHT = 0.25
TrackedFood.MIN_REMAINING_WEIGHT = 0.05

-- Evolved add: cap by kg and by |hunger| in Lua (getHungChange etc.): values are UI scale / 100.
TrackedFood.EVOLVED_PORTION_MAX_KG = 1
TrackedFood.EVOLVED_PORTION_MAX_HUNGER = 0.3

--- Full types that store Source*/Current* in modData (salted/dried outputs).
TrackedFood.TRACKED_FULL_TYPES = {
    ["AdvancedDrying42.SaltedMeat"] = true,
    ["AdvancedDrying42.SaltedFish"] = true,
    ["AdvancedDrying42.SaltedFishFillet"] = true,
    ["AdvancedDrying42.DriedMeat"] = true,
    ["AdvancedDrying42.DriedFish"] = true,
    ["AdvancedDrying42.DriedFishFillet"] = true,
}

local function pushStatsOntoEntity(entity, internalWeight, calories, proteins, lipids, carbs, hunger)
    if not entity then
        return
    end

    Utils.safeSet(entity, "setCustomWeight", true)
    Utils.safeSet(entity, "setActualWeight", internalWeight)
    Utils.safeSet(entity, "setWeight", internalWeight)

    Utils.safeSet(entity, "setCalories", calories)
    Utils.safeSet(entity, "setProteins", proteins)
    Utils.safeSet(entity, "setLipids", lipids)
    Utils.safeSet(entity, "setCarbohydrates", carbs)

    Utils.safeSet(entity, "setHungChange", hunger)
    Utils.safeSet(entity, "setHungerChange", hunger)
    Utils.safeSet(entity, "setBaseHunger", hunger)
end

--- skipNetworkSync: skip instance syncItemFields (e.g. after global syncItemFields(player, item) already ran).
function TrackedFood.applyFoodStats(item, internalWeight, calories, proteins, lipids, carbs, hunger, skipNetworkSync)
    if not item then
        return
    end

    pushStatsOntoEntity(item, internalWeight, calories, proteins, lipids, carbs, hunger)

    local food = Utils.getInnerFood(item)
    pushStatsOntoEntity(food, internalWeight, calories, proteins, lipids, carbs, hunger)

    if skipNetworkSync then
        return
    end

    -- MP: skip instance syncItemFields for tracked items on client (flicker); server uses global sync from callbacks.
    local mp = false
    pcall(function()
        mp = isMultiplayer()
    end)
    if not mp or not item.syncItemFields or not item.getFullType then
        return
    end

    local ft = item:getFullType()
    if TrackedFood.TRACKED_FULL_TYPES[ft] then
        return
    end

    pcall(function()
        item:syncItemFields()
    end)
    food = Utils.getInnerFood(item)
    pushStatsOntoEntity(item, internalWeight, calories, proteins, lipids, carbs, hunger)
    pushStatsOntoEntity(food, internalWeight, calories, proteins, lipids, carbs, hunger)
end

function TrackedFood.writeCurrentData(md, weight, calories, proteins, lipids, carbs, hunger)
    md.CurrentWeight = weight
    md.CurrentCalories = calories
    md.CurrentProteins = proteins
    md.CurrentLipids = lipids
    md.CurrentCarbohydrates = carbs
    md.CurrentHunger = hunger
    if weight and weight > 0 then
        md.AD42_DepletedByUse = nil
    end
end

function TrackedFood.writeSourceData(md, itemType, weight, calories, proteins, lipids, carbs, hunger)
    md.SourceType = itemType
    md.SourceWeight = weight
    md.SourceCalories = calories
    md.SourceProteins = proteins
    md.SourceLipids = lipids
    md.SourceCarbohydrates = carbs
    md.SourceHunger = hunger
end

function TrackedFood.readTrackedValue(md, currentKey, sourceKey, fallback)
    local value = md[currentKey]
    if value == nil then
        value = md[sourceKey]
    end
    if value == nil then
        value = fallback
    end
    return value
end

function TrackedFood.getTrackedStats(item)
    local md = item:getModData()

    if md.AD42_DepletedByUse == true and md.CurrentWeight ~= nil and md.CurrentWeight > 0 then
        md.AD42_DepletedByUse = nil
    end

    if md.AD42_DepletedByUse == true then
        return 0, 0, 0, 0, 0, 0
    end

    local weight = TrackedFood.readTrackedValue(
        md,
        "CurrentWeight",
        "SourceWeight",
        Utils.getItemWeight(item)
    )

    if (not weight or weight <= 0) and md.SourceWeight and md.SourceWeight > 0 then
        local sc = md.SourceCalories
        local cc = md.CurrentCalories
        if sc and sc > 0 and cc and cc > 0 then
            weight = md.SourceWeight * (cc / sc)
        else
            weight = md.SourceWeight
        end
    end

    local calories = TrackedFood.readTrackedValue(
        md,
        "CurrentCalories",
        "SourceCalories",
        Utils.getNutrition(item, "getCalories")
    )

    local proteins = TrackedFood.readTrackedValue(
        md,
        "CurrentProteins",
        "SourceProteins",
        Utils.getNutrition(item, "getProteins")
    )

    local lipids = TrackedFood.readTrackedValue(
        md,
        "CurrentLipids",
        "SourceLipids",
        Utils.getNutrition(item, "getLipids")
    )

    local carbs = TrackedFood.readTrackedValue(
        md,
        "CurrentCarbohydrates",
        "SourceCarbohydrates",
        Utils.getNutrition(item, "getCarbohydrates")
    )

    local hunger = TrackedFood.readTrackedValue(
        md,
        "CurrentHunger",
        "SourceHunger",
        Utils.getHunger(item)
    )

    -- If Current* got zeroed, prefer positive Source* values instead of script placeholders.
    if (not calories or calories <= 0) and md.SourceCalories and md.SourceCalories > 0 then
        calories = md.SourceCalories
    end
    if (not proteins or proteins <= 0) and md.SourceProteins and md.SourceProteins > 0 then
        proteins = md.SourceProteins
    end
    if (not lipids or lipids <= 0) and md.SourceLipids and md.SourceLipids > 0 then
        lipids = md.SourceLipids
    end
    if (not carbs or carbs <= 0) and md.SourceCarbohydrates and md.SourceCarbohydrates > 0 then
        carbs = md.SourceCarbohydrates
    end
    if (not hunger or hunger >= -0.001) and md.SourceHunger and md.SourceHunger < -0.001 then
        hunger = md.SourceHunger
    end

    return weight, calories, proteins, lipids, carbs, hunger
end

-- preserveSmallRemainder: keep tiny evolved leftovers instead of forcing full deplete via MIN_REMAINING_WEIGHT.
function TrackedFood.consumeTrackedFoodPortion(item, requestedWeight, portionOpts)
    portionOpts = portionOpts or {}
    if not item then
        return nil
    end

    local currentWeight, currentCalories, currentProteins, currentLipids, currentCarbs, currentHunger =
        TrackedFood.getTrackedStats(item)

    if not currentWeight or currentWeight <= 0 then
        return nil
    end

    local usedWeight = requestedWeight or TrackedFood.DEFAULT_PORTION_WEIGHT
    usedWeight = math.min(usedWeight, currentWeight)

    if usedWeight <= 0 then
        return nil
    end

    local ratio = usedWeight / currentWeight

    local addedCalories = currentCalories * ratio
    local addedProteins = currentProteins * ratio
    local addedLipids = currentLipids * ratio
    local addedCarbs = currentCarbs * ratio
    local addedHunger = currentHunger * ratio

    local newWeight = currentWeight - usedWeight
    local newCalories = currentCalories - addedCalories
    local newProteins = currentProteins - addedProteins
    local newLipids = currentLipids - addedLipids
    local newCarbs = currentCarbs - addedCarbs
    local newHunger = currentHunger - addedHunger

    if not portionOpts.preserveSmallRemainder and newWeight <= TrackedFood.MIN_REMAINING_WEIGHT then
        newWeight = 0
        newCalories = 0
        newProteins = 0
        newLipids = 0
        newCarbs = 0
        newHunger = 0
    end

    local md = item:getModData()

    TrackedFood.writeCurrentData(
        md,
        newWeight,
        newCalories,
        newProteins,
        newLipids,
        newCarbs,
        newHunger
    )

    if newWeight <= 0 then
        md.AD42_DepletedByUse = true
    end

    TrackedFood.applyFoodStats(
        item,
        newWeight,
        newCalories,
        newProteins,
        newLipids,
        newCarbs,
        newHunger
    )

    return {
        usedWeight = usedWeight,
        ratio = ratio,
        calories = addedCalories,
        proteins = addedProteins,
        lipids = addedLipids,
        carbs = addedCarbs,
        hunger = addedHunger,
        remainingWeight = newWeight,
        depleted = newWeight <= 0
    }
end

function TrackedFood.copyTrackedData(fromItem, toItem, newWeight, newCalories, newProteins, newLipids, newCarbs, newHunger)
    if not fromItem or not toItem then
        return
    end

    local fromMd = fromItem:getModData()
    local toMd = toItem:getModData()

    TrackedFood.writeSourceData(
        toMd,
        fromMd.SourceType or fromItem:getFullType(),
        fromMd.SourceWeight or newWeight,
        fromMd.SourceCalories or newCalories,
        fromMd.SourceProteins or newProteins,
        fromMd.SourceLipids or newLipids,
        fromMd.SourceCarbohydrates or newCarbs,
        fromMd.SourceHunger or newHunger
    )

    TrackedFood.writeCurrentData(
        toMd,
        newWeight,
        newCalories,
        newProteins,
        newLipids,
        newCarbs,
        newHunger
    )

    TrackedFood.applyFoodStats(
        toItem,
        newWeight,
        newCalories,
        newProteins,
        newLipids,
        newCarbs,
        newHunger
    )
end

function TrackedFood.removeItemCompletely(character, item)
    if not item then
        return
    end

    local container = Utils.safeCall(function()
        return item:getContainer()
    end)

    pcall(function()
        local mp = isMultiplayer and isMultiplayer()
        local srv = isServer and isServer()
        if container and mp and srv and sendRemoveItemFromContainer then
            sendRemoveItemFromContainer(container, item)
        end
    end)

    if container then
        if container.DoRemoveItem then
            pcall(function()
                container:DoRemoveItem(item)
            end)
            return
        end
        if container.Remove then
            pcall(function()
                container:Remove(item)
            end)
            return
        end
    end

    local inventory = character and Utils.safeCall(function()
        return character:getInventory()
    end)

    if inventory then
        if inventory.DoRemoveItem then
            pcall(function()
                inventory:DoRemoveItem(item)
            end)
            return
        end
        if inventory.Remove then
            pcall(function()
                inventory:Remove(item)
            end)
        end
    end
end

function TrackedFood.findSaltedMeat(items)
    if not items then
        return nil
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item:getFullType() == "AdvancedDrying42.SaltedMeat" then
            return item
        end
    end

    return nil
end

function TrackedFood.findFirstNonSaltConsumedItem(items)
    if not items then
        return nil
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item:getFullType() ~= "Base.Salt" then
            return item
        end
    end

    return nil
end

function TrackedFood.peekTrackedFoodPortion(item, requestedWeight)
    if not item then
        return nil
    end

    local currentWeight, currentCalories, currentProteins, currentLipids, currentCarbs, currentHunger =
        TrackedFood.getTrackedStats(item)

    if not currentWeight or currentWeight <= 0 then
        return nil
    end

    local usedWeight = math.min(requestedWeight, currentWeight)
    if usedWeight <= 0 then
        return nil
    end

    local ratio = usedWeight / currentWeight

    return {
        usedWeight = usedWeight,
        ratio = ratio,
        calories = currentCalories * ratio,
        proteins = currentProteins * ratio,
        lipids = currentLipids * ratio,
        carbs = currentCarbs * ratio,
        hunger = currentHunger * ratio,
    }
end

-- MP client: optional syncItemFields so UI picks up modData (not used from applyFoodStats to avoid flicker).
function TrackedFood.clientMpForceVisualFromModData(item)
    if not item or not item.getFullType then
        return
    end
    local ft = item:getFullType()
    if not TrackedFood.TRACKED_FULL_TYPES[ft] then
        return
    end
    local mp, cl, srv = false, false, false
    pcall(function()
        mp = isMultiplayer and isMultiplayer()
        cl = isClient and isClient()
        srv = isServer and isServer()
    end)
    if not mp or not cl or srv then
        return
    end

    local w, c, p, l, cb, h = TrackedFood.getTrackedStats(item)
    if not w or w <= 0 then
        return
    end

    pcall(function()
        if item.syncItemFields then
            item:syncItemFields()
        end
    end)
    TrackedFood.applyFoodStats(item, w, c, p, l, cb, h, true)
    pcall(function()
        if item.synchWithVisual then
            item:synchWithVisual()
        end
    end)

    pcall(function()
        if not getItemNameFromFullType or not item.getDisplayName or not item.setName then
            return
        end
        local disp = item:getDisplayName()
        if not disp or not string.find(disp, "AdvancedDrying42", 1, true) then
            return
        end
        local pretty = getItemNameFromFullType(ft)
        if not pretty or pretty == "" then
            return
        end
        pcall(function()
            if item.isCustomName and item.setCustomName and item:isCustomName() then
                item:setCustomName(false)
            end
        end)
        pcall(function()
            item:setName(pretty)
        end)
    end)
end

function TrackedFood.refreshContainerTrackedFood(container, clientMpForceVisual)
    if not container or not container.getItems then
        return
    end

    local items = container:getItems()
    if not items then
        return
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            pcall(function()
                if item.IsInventoryContainer and item:IsInventoryContainer() and item.getInventory then
                    local sub = item:getInventory()
                    if sub then
                        TrackedFood.refreshContainerTrackedFood(sub, clientMpForceVisual)
                    end
                end
            end)
            TrackedFood.refreshItemFromModDataIfTracked(item)
            if clientMpForceVisual then
                TrackedFood.clientMpForceVisualFromModData(item)
            end
        end
    end
end

function TrackedFood.refreshItemFromModDataIfTracked(item)
    if not item then
        return
    end

    local ft = item:getFullType()
    if not TrackedFood.TRACKED_FULL_TYPES[ft] then
        return
    end

    local md = item:getModData()
    if not md or (md.SourceWeight == nil and md.CurrentWeight == nil) then
        return
    end

    local w, c, p, l, cb, h = TrackedFood.getTrackedStats(item)

    if (not w or w <= 0) and md.AD42_DepletedByUse == true then
        TrackedFood.applyFoodStats(item, 0, 0, 0, 0, 0, 0, true)
        return
    end

    -- MP load: CurrentWeight can deserialize as 0 while macros still valid; for salted food restore from source (no loss on salting).
    if (not w or w <= 0) and md.SourceWeight and md.SourceWeight > 0 and string.find(ft, "Salted", 1, true) then
        local calLeft = md.CurrentCalories or md.SourceCalories
        if calLeft and calLeft > 0 then
            local sm = 1.0
            w = md.SourceWeight * sm
            c = md.CurrentCalories or ((md.SourceCalories or 0) * sm)
            p = md.CurrentProteins or ((md.SourceProteins or 0) * sm)
            l = md.CurrentLipids or ((md.SourceLipids or 0) * sm)
            cb = md.CurrentCarbohydrates or ((md.SourceCarbohydrates or 0) * sm)
            h = md.CurrentHunger or md.SourceHunger or h
            TrackedFood.writeCurrentData(md, w, c, p, l, cb, h)
        end
    end

    if not w or w <= 0 then
        return
    end

    TrackedFood.applyFoodStats(item, w, c, p, l, cb, h)
    pcall(function()
        if item.synchWithVisual then
            item:synchWithVisual()
        end
    end)
end

local _reapplyQueue = _reapplyQueue or {}

function TrackedFood.armReapplyFromModData(item, ticks)
    if not item or not item.getID then
        return
    end
    local id = item:getID()
    if not id or id < 0 then
        return
    end
    local n = tonumber(ticks) or 30
    if n < 1 then
        n = 1
    end
    _reapplyQueue[id] = {
        item = item,
        ticks = n,
    }
end

if Events.OnTick then
    Events.OnTick.Add(function()
        for id, entry in pairs(_reapplyQueue) do
            local it = entry and entry.item
            if not it then
                _reapplyQueue[id] = nil
            else
                TrackedFood.refreshItemFromModDataIfTracked(it)
                entry.ticks = (entry.ticks or 0) - 1
                if entry.ticks <= 0 then
                    _reapplyQueue[id] = nil
                end
            end
        end
    end)
end

if Events.OnContainerUpdate then
    Events.OnContainerUpdate.Add(function(obj)
        pcall(function()
            if not obj then
                return
            end
            if obj.getItems then
                TrackedFood.refreshContainerTrackedFood(obj)
                return
            end
            if obj.getContainer then
                local c = obj:getContainer()
                if c and c.getItems then
                    TrackedFood.refreshContainerTrackedFood(c)
                end
            end
        end)
    end)
end

-- Client: after crafting, MP inventory may not fire OnContainerUpdate; UI refresh is a reliable hook.
local _nextInvUiHealTick = -1

if Events.OnRefreshInventoryWindowContainers then
    Events.OnRefreshInventoryWindowContainers.Add(function(page)
        pcall(function()
            local gt = getGameTime and getGameTime()
            local now = 0
            if gt and gt.getGameTicks then
                now = gt:getGameTicks()
                if now < _nextInvUiHealTick then
                    return
                end
                _nextInvUiHealTick = now + 10
            end

            local function healContainerIfAny(inv)
                if inv and inv.getItems then
                    TrackedFood.refreshContainerTrackedFood(inv)
                end
            end

            local p = getPlayer()
            if p and p.getInventory then
                healContainerIfAny(p:getInventory())
            end

            if page then
                if page.getInventory then
                    healContainerIfAny(page:getInventory())
                end
                if page.inventory then
                    healContainerIfAny(page.inventory)
                end
                if page.inventoryPane and page.inventoryPane.inventory then
                    healContainerIfAny(page.inventoryPane.inventory)
                end
                if page.lootInventory then
                    healContainerIfAny(page.lootInventory)
                end
                if page.getPinnedItems then
                    local pin = page:getPinnedItems()
                    if pin and pin.getInventory then
                        healContainerIfAny(pin:getInventory())
                    end
                end
            end
        end)
    end)
end

-- Right-click inventory item: refresh before tooltip / menu (covers hover that never opened inv window refresh).
if Events.OnFillInventoryObjectContextMenu then
    Events.OnFillInventoryObjectContextMenu.Add(function(_playerIndex, _context, items)
        pcall(function()
            if not items then
                return
            end
            local function tryItem(it)
                if it and it.getFullType then
                    TrackedFood.refreshItemFromModDataIfTracked(it)
                end
            end
            if type(items) == "table" then
                for _, entry in pairs(items) do
                    if entry then
                        tryItem(entry)
                        pcall(function()
                            if entry.items then
                                for _, it in pairs(entry.items) do
                                    tryItem(it)
                                end
                            end
                        end)
                        pcall(function()
                            if entry.getItems then
                                local its = entry:getItems()
                                if its and its.size then
                                    for j = 0, its:size() - 1 do
                                        tryItem(its:get(j))
                                    end
                                end
                            end
                        end)
                    end
                end
            end
        end)
    end)
end

function TrackedFood.consumeTrackedFoodFractionPortion(item, fraction, _portionKey)
    if not item then
        return nil
    end

    fraction = tonumber(fraction) or 0.2
    if fraction <= 0 then
        return nil
    end

    local currentWeight = TrackedFood.getTrackedStats(item)

    if not currentWeight or currentWeight <= 0 then
        return nil
    end

    local usedWeight = math.min(currentWeight * fraction, currentWeight)
    if usedWeight <= 0 then
        return nil
    end
    return TrackedFood.consumeTrackedFoodPortion(item, usedWeight)
end

--- One evolved add: min(remaining, maxKg), and cap weight so |hunger contribution| ≤ maxHungerMag (Lua getters use ÷100 vs display).
function TrackedFood.consumeTrackedFoodEvolvedPortion(item, maxKg, maxHungerMag)
    if not item then
        return nil
    end
    maxKg = tonumber(maxKg) or TrackedFood.EVOLVED_PORTION_MAX_KG
    maxHungerMag = tonumber(maxHungerMag) or TrackedFood.EVOLVED_PORTION_MAX_HUNGER
    if maxKg <= 0 or maxHungerMag <= 0 then
        return nil
    end

    local w, _c, _p, _l, _cb, h = TrackedFood.getTrackedStats(item)
    if not w or w <= 0 then
        return nil
    end

    local usedWeight = math.min(maxKg, w)
    local absH = h and math.abs(h) or 0
    if absH > 1e-8 then
        local wCapByHunger = maxHungerMag * w / absH
        usedWeight = math.min(usedWeight, wCapByHunger)
    end

    if usedWeight <= 0 then
        return nil
    end
    return TrackedFood.consumeTrackedFoodPortion(item, usedWeight, { preserveSmallRemainder = true })
end