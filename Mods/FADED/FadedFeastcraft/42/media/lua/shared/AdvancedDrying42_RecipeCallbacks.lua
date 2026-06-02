require "AdvancedDrying42_Utils"
require "AdvancedDrying42_TrackedFood"

Recipe = Recipe or {}
Recipe.OnCreate = Recipe.OnCreate or {}
Recipe.OnTest = Recipe.OnTest or {}

local Utils = AdvancedDrying42.Utils
local TrackedFood = AdvancedDrying42.TrackedFood

--- Do NOT call sendAddItemToContainer again — item is already in the container (causes "Dupe item ID" in console).
--- Vanilla MP uses global syncItemFields(IsoPlayer, InventoryItem) to push edits for an existing item (see ISReadABook, etc.).
local function ad42NotifyCraftedItemMp(result, player)
    if not result then
        return
    end
    local okMp = false
    pcall(function()
        okMp = isMultiplayer and isMultiplayer()
    end)
    local srv = false
    pcall(function()
        srv = isServer and isServer()
    end)
    if not okMp or not srv then
        return
    end
    if not player then
        return
    end
    pcall(function()
        if type(syncItemFields) == "function" then
            syncItemFields(player, result)
        end
    end)
    -- Instance method can still recompute weight; re-apply from modData on server only (no second net sync).
    pcall(function()
        local w, c, p0, l, cb, h = TrackedFood.getTrackedStats(result)
        if w and w > 0 then
            TrackedFood.applyFoodStats(result, w, c, p0, l, cb, h, true)
        end
    end)
end

local DRY_NUTRY_MULTIPLIER = 0.9
local SALT_MULTIPLIER = 1.0
local DRY_WEIGHT_MULTIPLIER = 0.35
local DRY_NUTRITION_MULTIPLIER = 0.5
local SPLIT_MIN_WEIGHT = 1.0

local PRESERVED_TYPES = {
    ["AdvancedDrying42.SaltedMeat"] = {
        dried = "AdvancedDrying42.DriedMeat",
        splittable = true,
        dryable = true,
        foodKind = "meat",
    },
    ["AdvancedDrying42.SaltedFish"] = {
        dried = "AdvancedDrying42.DriedFish",
        splittable = true,
        dryable = true,
        foodKind = "fish",
    },
    ["AdvancedDrying42.SaltedFishFillet"] = {
        dried = "AdvancedDrying42.DriedFishFillet",
        splittable = true,
        dryable = true,
        foodKind = "fish",
    },
    ["AdvancedDrying42.DriedMeat"] = {
        splittable = true,
        foodKind = "meat",
    },
    ["AdvancedDrying42.DriedFish"] = {
        splittable = true,
        foodKind = "fish",
    },
    ["AdvancedDrying42.DriedFishFillet"] = {
        splittable = true,
        foodKind = "fish",
    },
}

local function findTrackedItemByType(items, expectedFullType)
    if not items then
        return nil
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item:getFullType() == expectedFullType then
            return item
        end
    end

    return nil
end

local function findFirstTrackedPreservedItem(items)
    if not items then
        return nil
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and PRESERVED_TYPES[item:getFullType()] then
            return item
        end
    end

    return nil
end

local function canSplitTrackedFood(item, expectedFullType, minWeight)
    if not item then
        return false
    end

    local fullType = item:getFullType()

    local isTrackedPreserved = PRESERVED_TYPES[fullType] ~= nil

    if not isTrackedPreserved then
        return true
    end

    if fullType ~= expectedFullType then
        return false
    end

    local def = PRESERVED_TYPES[expectedFullType]
    if not def or not def.splittable then
        return false
    end

    local weight = TrackedFood.readTrackedValue(
        item:getModData(),
        "CurrentWeight",
        "SourceWeight",
        Utils.getItemWeight(item)
    )

    return weight > minWeight
end

local function postCraftTrackedMpSync(result, player)
    if not result then
        return
    end
    pcall(function()
        if player and player.getInventory then
            local inv = player:getInventory()
            if inv and inv.setDrawDirty then
                inv:setDrawDirty(true)
            end
        end
    end)
    ad42NotifyCraftedItemMp(result, player)
end

local function splitTrackedFoodByType(craftRecipeData, expectedFullType, player)
    if not craftRecipeData then
        return
    end

    local items = craftRecipeData:getAllConsumedItems()
    local results = craftRecipeData:getAllCreatedItems()

    if not items or not results or results:size() < 2 then
        return
    end

    local sourceItem = findTrackedItemByType(items, expectedFullType)
    local resultA = results:get(0)
    local resultB = results:get(1)

    if not sourceItem or not resultA or not resultB then
        return
    end

    local sourceWeight, sourceCalories, sourceProteins, sourceLipids, sourceCarbs, sourceHunger =
        TrackedFood.getTrackedStats(sourceItem)

    local splitWeight = sourceWeight / 2
    local splitCalories = sourceCalories / 2
    local splitProteins = sourceProteins / 2
    local splitLipids = sourceLipids / 2
    local splitCarbs = sourceCarbs / 2
    local splitHunger = sourceHunger / 2

    TrackedFood.copyTrackedData(
        sourceItem,
        resultA,
        splitWeight,
        splitCalories,
        splitProteins,
        splitLipids,
        splitCarbs,
        splitHunger
    )

    TrackedFood.copyTrackedData(
        sourceItem,
        resultB,
        splitWeight,
        splitCalories,
        splitProteins,
        splitLipids,
        splitCarbs,
        splitHunger
    )

    postCraftTrackedMpSync(resultA, player)
    postCraftTrackedMpSync(resultB, player)
end

local function saltTrackedFood(craftRecipeData, player)
    local items = craftRecipeData:getAllConsumedItems()
    local results = craftRecipeData:getAllCreatedItems()

    if not items or not results or results:size() == 0 then
        return
    end

    local result = results:get(0)
    if not result then
        return
    end

    local sourceItem = TrackedFood.findFirstNonSaltConsumedItem(items)
    if not sourceItem then
        return
    end

    local _, sourceWeight, nutrScale = Utils.computeSaltingWeights(sourceItem)

    local sourceCalories = Utils.getNutrition(sourceItem, "getCalories") * nutrScale
    local sourceProteins = Utils.getNutrition(sourceItem, "getProteins") * nutrScale
    local sourceLipids = Utils.getNutrition(sourceItem, "getLipids") * nutrScale
    local sourceCarbs = Utils.getNutrition(sourceItem, "getCarbohydrates") * nutrScale
    local sourceHunger = Utils.getHunger(sourceItem)

    local saltedWeight = sourceWeight * SALT_MULTIPLIER
    -- Salting keeps weight/macros unchanged; reduction is applied only at drying stage.
    local saltedCalories = sourceCalories * SALT_MULTIPLIER
    local saltedProteins = sourceProteins * SALT_MULTIPLIER
    local saltedLipids = sourceLipids * SALT_MULTIPLIER
    local saltedCarbs = sourceCarbs * SALT_MULTIPLIER
    local saltedHunger = sourceHunger

    local md = result:getModData()

    TrackedFood.writeSourceData(
        md,
        sourceItem:getFullType(),
        sourceWeight,
        sourceCalories,
        sourceProteins,
        sourceLipids,
        sourceCarbs,
        sourceHunger
    )

    TrackedFood.writeCurrentData(
        md,
        saltedWeight,
        saltedCalories,
        saltedProteins,
        saltedLipids,
        saltedCarbs,
        saltedHunger
    )

    TrackedFood.applyFoodStats(
        result,
        saltedWeight,
        saltedCalories,
        saltedProteins,
        saltedLipids,
        saltedCarbs,
        saltedHunger
    )

    postCraftTrackedMpSync(result, player)
end

function Recipe.OnCreate.SaltMeat(craftRecipeData, player)
    saltTrackedFood(craftRecipeData, player)
end

function Recipe.OnCreate.SaltFish(craftRecipeData, player)
    saltTrackedFood(craftRecipeData, player)
end

function Recipe.OnCreate.SaltFishFillet(craftRecipeData, player)
    saltTrackedFood(craftRecipeData, player)
end

function Recipe.OnTest.SplitSaltedMeat(item)
    return canSplitTrackedFood(item, "AdvancedDrying42.SaltedMeat", SPLIT_MIN_WEIGHT)
end

function Recipe.OnCreate.SplitSaltedMeat(craftRecipeData, player)
    splitTrackedFoodByType(craftRecipeData, "AdvancedDrying42.SaltedMeat", player)
end

function Recipe.OnTest.SplitDriedMeat(item)
    return canSplitTrackedFood(item, "AdvancedDrying42.DriedMeat", SPLIT_MIN_WEIGHT)
end

function Recipe.OnCreate.SplitDriedMeat(craftRecipeData, player)
    splitTrackedFoodByType(craftRecipeData, "AdvancedDrying42.DriedMeat", player)
end

function Recipe.OnTest.SplitSaltedFish(item)
    return canSplitTrackedFood(item, "AdvancedDrying42.SaltedFish", SPLIT_MIN_WEIGHT)
end

function Recipe.OnCreate.SplitSaltedFish(craftRecipeData, player)
    splitTrackedFoodByType(craftRecipeData, "AdvancedDrying42.SaltedFish", player)
end

function Recipe.OnTest.SplitSaltedFishFillet(item)
    return canSplitTrackedFood(item, "AdvancedDrying42.SaltedFishFillet", SPLIT_MIN_WEIGHT)
end

function Recipe.OnCreate.SplitSaltedFishFillet(craftRecipeData, player)
    splitTrackedFoodByType(craftRecipeData, "AdvancedDrying42.SaltedFishFillet", player)
end

function Recipe.OnTest.SplitDriedFish(item)
    return canSplitTrackedFood(item, "AdvancedDrying42.DriedFish", SPLIT_MIN_WEIGHT)
end

function Recipe.OnCreate.SplitDriedFish(craftRecipeData, player)
    splitTrackedFoodByType(craftRecipeData, "AdvancedDrying42.DriedFish", player)
end

function Recipe.OnTest.SplitDriedFishFillet(item)
    return canSplitTrackedFood(item, "AdvancedDrying42.DriedFishFillet", SPLIT_MIN_WEIGHT)
end

function Recipe.OnCreate.SplitDriedFishFillet(craftRecipeData, player)
    splitTrackedFoodByType(craftRecipeData, "AdvancedDrying42.DriedFishFillet", player)
end

local function isDryableRawSaltedFood(item)
    if not item then
        return false
    end

    local def = PRESERVED_TYPES[item:getFullType()]
    if not def or not def.dryable then
        return false
    end

    if item.isCooked and item:isCooked() then
        return false
    end

    if item.isBurnt and item:isBurnt() then
        return false
    end

    if item.isRotten and item:isRotten() then
        return false
    end

    return true
end

function Recipe.OnTest.CanDryRawSaltedFood(item)
    return isDryableRawSaltedFood(item)
end

local function dryTrackedFood(craftRecipeData, player)
    if not craftRecipeData then
        return
    end

    local items = craftRecipeData:getAllConsumedItems()
    local results = craftRecipeData:getAllCreatedItems()

    if not items or not results or results:size() == 0 then
        return
    end

    local sourceItem = findFirstTrackedPreservedItem(items)
    local result = results:get(0)

    if not sourceItem or not result then
        return
    end

    local def = PRESERVED_TYPES[sourceItem:getFullType()]
    if not def or not def.dried then
        return
    end

    local sourceMd = sourceItem:getModData()

    local sourceWeight, sourceCalories, sourceProteins, sourceLipids, sourceCarbs, sourceHunger =
        TrackedFood.getTrackedStats(sourceItem)

    local driedWeight = sourceWeight * DRY_WEIGHT_MULTIPLIER
    local driedCalories = sourceCalories * DRY_NUTRY_MULTIPLIER
    local driedProteins = sourceProteins * DRY_NUTRY_MULTIPLIER
    local driedLipids = sourceLipids * DRY_NUTRY_MULTIPLIER
    local driedCarbs = sourceCarbs * DRY_NUTRY_MULTIPLIER
    local driedHunger = sourceHunger * DRY_NUTRY_MULTIPLIER

    local resultMd = result:getModData()

    TrackedFood.writeSourceData(
        resultMd,
        sourceMd.SourceType or sourceItem:getFullType(),
        sourceMd.SourceWeight or sourceWeight,
        sourceMd.SourceCalories or sourceCalories,
        sourceMd.SourceProteins or sourceProteins,
        sourceMd.SourceLipids or sourceLipids,
        sourceMd.SourceCarbohydrates or sourceCarbs,
        sourceMd.SourceHunger or sourceHunger
    )

    TrackedFood.writeCurrentData(
        resultMd,
        driedWeight,
        driedCalories,
        driedProteins,
        driedLipids,
        driedCarbs,
        driedHunger
    )

    TrackedFood.applyFoodStats(
        result,
        driedWeight,
        driedCalories,
        driedProteins,
        driedLipids,
        driedCarbs,
        driedHunger
    )

    postCraftTrackedMpSync(result, player)
end

function Recipe.OnCreate.DrySaltedMeat(craftRecipeData, player)
    dryTrackedFood(craftRecipeData, player)
end

function Recipe.OnCreate.DrySaltedFish(craftRecipeData, player)
    dryTrackedFood(craftRecipeData, player)
end

function Recipe.OnCreate.DrySaltedFishFillet(craftRecipeData, player)
    dryTrackedFood(craftRecipeData, player)
end