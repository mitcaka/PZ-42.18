require "FadedFeastcraft/FFC_Boot"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.CraftingValidator = FadedFeastcraft.CraftingValidator or {}

local Validator = FadedFeastcraft.CraftingValidator
local Utils = FadedFeastcraft.Utils
local Config = FadedFeastcraft.Config
local Operations = FadedFeastcraft.OperationRegistry
local Actions = FadedFeastcraft.SourceActionIndex
local CookingStation = FadedFeastcraft.CookingStation
local MealEffects = FadedFeastcraft.MealEffects
local DirectRecipes = FadedFeastcraft.DirectRecipeRegistry
local Balance = FadedFeastcraft.Balance
local Preservation = FadedFeastcraft.Preservation

local function fail(reason)
    return false, tostring(reason or "Crafting request rejected")
end

local function normalizeItemIds(raw)
    if type(raw) == "table" then
        return raw
    end
    if type(raw) ~= "string" then
        return nil
    end

    local ids = {}
    for token in string.gmatch(raw, "[^,]+") do
        local id = tonumber(token)
        if id then ids[#ids + 1] = id end
    end
    return ids
end

local function categoryProbe(item)
    local fullType = Utils.lower(Utils.getFullType(item))
    local name = Utils.lower(Utils.getDisplayName(item))
    local text = fullType .. " " .. name
    if string.find(text, "meat", 1, true) or string.find(text, "beef", 1, true) or string.find(text, "pork", 1, true) or string.find(text, "chicken", 1, true) or string.find(text, "fish", 1, true) then return "protein" end
    if string.find(text, "rice", 1, true) or string.find(text, "pasta", 1, true) or string.find(text, "bread", 1, true) or string.find(text, "potato", 1, true) then return "starch" end
    if string.find(text, "fruit", 1, true) or string.find(text, "apple", 1, true) or string.find(text, "berry", 1, true) then return "fruit" end
    if string.find(text, "vegetable", 1, true) or string.find(text, "carrot", 1, true) or string.find(text, "cabbage", 1, true) or string.find(text, "tomato", 1, true) then return "veg" end
    if string.find(text, "spice", 1, true) or string.find(text, "salt", 1, true) or string.find(text, "pepper", 1, true) then return "seasoning" end
    return "other"
end

local function mealVariety(items)
    local seen = {}
    local count = 0
    for _, item in ipairs(items or {}) do
        local key = categoryProbe(item)
        if not seen[key] then
            seen[key] = true
            count = count + 1
        end
    end
    return count
end

function Validator.validateFieldMeal(player, args)
    if not Utils.sbBool("EnableExperimentalMealBuilder", true) then
        return fail("Meal builder is disabled")
    end
    local itemIds = args and normalizeItemIds(args.itemIds) or nil
    if not player or not args or not itemIds then
        return fail("Malformed request")
    end
    if args.expectedResult and args.expectedResult ~= Config.RESULT_FIELD_MEAL then
        return fail("Unexpected result type")
    end

    local count = #itemIds
    if count < Config.MIN_MEAL_INGREDIENTS then return fail("No ingredients selected") end
    local maxIngredients = Balance and Balance.maxMealIngredients and Balance.maxMealIngredients() or Config.MAX_MEAL_INGREDIENTS
    if count > maxIngredients then return fail("Too many ingredients selected") end

    local items = {}
    local seen = {}
    local totals = {
        hunger = 0,
        calories = 0,
        proteins = 0,
        lipids = 0,
        carbohydrates = 0,
        boredom = 0,
        unhappy = 0,
    }

    for _, id in ipairs(itemIds) do
        local numericId = tonumber(id)
        if not numericId or seen[numericId] then return fail("Invalid duplicate ingredient") end
        seen[numericId] = true
        local item = Utils.findAccessibleItemById(player, numericId)
        if not item then return fail("Ingredient no longer exists") end
        if not (item.getContainer and item:getContainer()) then return fail("Ingredient is not accessible") end
        if not Utils.isFood(item) then return fail("Ingredient is not food") end
        if Utils.getFullType(item) == Config.RESULT_FIELD_MEAL then return fail("Prepared FFC meals cannot be reused as builder ingredients") end
        if item.isRotten and item:isRotten() then return fail(Utils.getDisplayName(item) .. " is rotten") end
        if item.isBurnt and item:isBurnt() then return fail(Utils.getDisplayName(item) .. " is burned") end
        if item.isFrozen and item:isFrozen() then return fail(Utils.getDisplayName(item) .. " is frozen") end
        local dangerous = false
        if item.isbDangerousUncooked and item:isbDangerousUncooked() then dangerous = true end
        if item.isDangerousUncooked and item:isDangerousUncooked() then dangerous = true end
        local cooked = item.isCooked and item:isCooked() == true or false
        if dangerous and not cooked then
            return fail(Utils.getDisplayName(item) .. " is dangerous raw")
        end

        local n = Utils.getNutrition(item)
        totals.hunger = totals.hunger + n.hunger
        totals.calories = totals.calories + n.calories
        totals.proteins = totals.proteins + n.proteins
        totals.lipids = totals.lipids + n.lipids
        totals.carbohydrates = totals.carbohydrates + n.carbohydrates
        totals.boredom = totals.boredom + n.boredom
        totals.unhappy = totals.unhappy + n.unhappy
        items[#items + 1] = item
    end

    return true, { items = items, totals = totals }
end

function Validator.applyFieldMeal(player, validation)
    if not player or not validation or not validation.items then
        return fail("Missing validated meal data")
    end

    for _, item in ipairs(validation.items) do
        if not (item.getContainer and item:getContainer()) then
            return fail("Ingredient moved before crafting")
        end
    end

    for _, item in ipairs(validation.items) do
        if not Utils.removeInventoryItem(item) then
            return fail("Could not consume ingredient")
        end
    end

    local inv = player:getInventory()
    local result = Utils.addItem(inv, Config.RESULT_FIELD_MEAL)
    if not result then return fail("Could not create meal") end

    local totals = validation.totals or {}
    local hunger = tonumber(totals.hunger) or -0.15
    if hunger > -0.01 then hunger = -0.01 end
    if hunger < -1.0 then hunger = -1.0 end

    Utils.safeSet(result, "setName", "FFC Field Meal")
    Utils.safeSet(result, "setHungChange", hunger)
    Utils.safeSet(result, "setHungerChange", hunger)
    if Balance and Balance.applyMealTuning then
        Balance.applyMealTuning(result, player, totals, {
            source = "builder",
            variety = mealVariety(validation.items),
        })
    else
        Utils.safeSet(result, "setCalories", math.max(1, totals.calories or 1))
        Utils.safeSet(result, "setProteins", math.max(0, totals.proteins or 0))
        Utils.safeSet(result, "setLipids", math.max(0, totals.lipids or 0))
        Utils.safeSet(result, "setCarbohydrates", math.max(0, totals.carbohydrates or 0))
        Utils.safeSet(result, "setBoredomChange", totals.boredom or 0)
        Utils.safeSet(result, "setUnhappyChange", totals.unhappy or 0)
    end

    local md = result:getModData()
    md.FFC_Crafted = true
    md.FFC_IngredientCount = #validation.items
    md.FFC_CraftedWorldAge = getGameTime and getGameTime():getWorldAgeHours() or 0
    if MealEffects and MealEffects.stampMeal then
        MealEffects.stampMeal(result, player, validation, { source = "builder" })
    end
    Utils.syncItem(player, result)
    return true, result
end

local TOOL_GROUPS = {
    can = {
        fullTypes = { "Base.TinOpener", "Base.CanOpener" },
        tags = { "CanOpener", "base:canopener", "canopener" },
        tokens = { "can opener", "tin opener", "canopener", "tinopener" },
    },
    sharp = {
        tags = { "SharpKnife", "sharpknife", "base:sharpknife", "Knife", "knife" },
        tokens = { "knife", "cleaver", "sharp stone", "stone flake" },
    },
    can_or_sharp = {
        groups = { "can", "sharp" },
    },
    tin_sealer = {
        fullTypes = { "ExtraCraft.TinSealer" },
        tokens = { "tin sealer", "can sealer", "sealer" },
    },
    cooking_vessel = {
        tokens = { "pot", "saucepan", "frying pan", "fryingpan", "roasting pan", "roastingpan", "baking pan", "bakingpan", "bowl" },
    },
}

local function collectionContains(collection, value)
    if not collection or value == nil then return false end
    if collection.contains then
        local ok, result = pcall(function() return collection:contains(value) end)
        if ok and result == true then return true end
    end
    if collection.size and collection.get then
        local ok, size = pcall(function() return collection:size() end)
        if ok and size then
            for i = 0, size - 1 do
                local gotOk, entry = pcall(function() return collection:get(i) end)
                if gotOk and tostring(entry) == tostring(value) then return true end
            end
        end
    end
    return false
end

local function itemHasTag(item, tag)
    local tags = Utils.safeCall(item, "getTags")
    if collectionContains(tags, tag) then return true end

    local scriptItem = Utils.safeCall(item, "getScriptItem")
    local scriptTags = Utils.safeCall(scriptItem, "getTags")
    if collectionContains(scriptTags, tag) then return true end

    return false
end

local function matchesToolGroup(item, groupName, depth)
    if not item or not groupName then return false end
    depth = depth or 0
    if depth > 3 then return false end

    local group = TOOL_GROUPS[groupName]
    if not group then return false end

    for _, nested in ipairs(group.groups or {}) do
        if matchesToolGroup(item, nested, depth + 1) then return true end
    end

    local fullType = Utils.getFullType(item)
    for _, expected in ipairs(group.fullTypes or {}) do
        if fullType == expected then return true end
    end

    for _, tag in ipairs(group.tags or {}) do
        if itemHasTag(item, tag) then return true end
    end

    local text = Utils.lower(fullType .. " " .. Utils.getDisplayName(item))
    for _, token in ipairs(group.tokens or {}) do
        if string.find(text, Utils.lower(token), 1, true) then return true end
    end

    return false
end

function Validator.findTool(player, groupName)
    if not player or not groupName then return nil end
    local found = nil
    Utils.walkInventory(player:getInventory(), function(item)
        if not found and matchesToolGroup(item, groupName) then
            found = item
        end
    end, 1000)
    if found then return found end

    if Utils.sbBool("EnableNearbyContainerScanning", true) then
        Utils.walkNearbyContainerItems(player, function(item)
            if not found and matchesToolGroup(item, groupName) then
                found = item
            end
        end, {
            maxItems = Utils.sbNumber("MaxScannedItems", 350, 50, 1000),
            maxContainers = Utils.sbNumber("MaxScannedContainers", 24, 4, 80),
            radius = Utils.sbNumber("IngredientScanRadius", 2, 0, 8),
        })
    end
    return found
end

local function directRecipeItemSafe(item, action)
    if not item then return false, "missing item" end
    if not (item.getContainer and item:getContainer()) then return false, "item is not accessible" end
    if item.isFrozen and item:isFrozen() and not action.allowFrozen then return false, Utils.getDisplayName(item) .. " is frozen" end
    if item.isRotten and item:isRotten() and not action.allowRotten then return false, Utils.getDisplayName(item) .. " is rotten" end
    if item.isBurnt and item:isBurnt() and not action.allowBurned then return false, Utils.getDisplayName(item) .. " is burned" end
    return true, nil
end

local function requirementTypeSet(requirement)
    local set = {}
    for _, fullType in ipairs(requirement and requirement.fullTypes or {}) do
        set[fullType] = true
    end
    return set
end

local function findDirectRecipeItems(player, requirement, action, usedIds)
    local needed = tonumber(requirement and requirement.count) or 1
    local typeSet = requirementTypeSet(requirement)
    local found = {}
    local failReason = nil

    local function consider(item)
        if #found >= needed or not item then return end
        local id = item.getID and item:getID() or nil
        if id and usedIds[id] then return end
        if not typeSet[Utils.getFullType(item)] then return end
        local ok, reason = directRecipeItemSafe(item, action)
        if ok then
            found[#found + 1] = item
            if id then usedIds[id] = true end
        elseif reason and not failReason then
            failReason = reason
        end
    end

    Utils.walkInventory(player:getInventory(), consider, 2000)
    if #found < needed and Utils.sbBool("EnableNearbyContainerScanning", true) then
        Utils.walkNearbyContainerItems(player, consider, {
            maxItems = Utils.sbNumber("MaxScannedItems", 350, 50, 1000),
            maxContainers = Utils.sbNumber("MaxScannedContainers", 24, 4, 80),
            radius = Utils.sbNumber("IngredientScanRadius", 2, 0, 8),
        })
    end

    if #found < needed then
        return nil, failReason or ("Needs " .. tostring(needed) .. "x " .. table.concat(requirement.fullTypes or {}, " or "))
    end
    return found, nil
end

function Validator.validateDirectRecipe(player, args)
    if not player or not args then return fail("Malformed direct recipe request") end
    local actionId = tostring(args.actionId or "")
    local action = DirectRecipes and DirectRecipes.get and DirectRecipes.get(actionId) or nil
    if not action then return fail("Direct recipe is not registered") end
    if action.requiresPreservation and Preservation and Preservation.enabled and not Preservation.enabled() then
        return fail("Preservation system is disabled")
    end

    for _, tool in ipairs(action.toolGroups or {}) do
        if not Validator.findTool(player, tool.group) then
            return fail("Requires " .. tostring(tool.label or tool.group))
        end
    end

    local usedIds = {}
    local items = {}
    for _, requirement in ipairs(action.requirements or {}) do
        local found, reason = findDirectRecipeItems(player, requirement, action, usedIds)
        if not found then return fail(reason) end
        for _, item in ipairs(found) do
            items[#items + 1] = item
        end
    end

    if #items == 0 then return fail("No ingredients selected for direct recipe") end
    for _, outputFullType in ipairs(action.outputs or {}) do
        if Operations.itemTypeExists and not Operations.itemTypeExists(outputFullType) then
            return fail("Missing output item script: " .. tostring(outputFullType))
        end
    end

    local first = items[1]
    return true, {
        action = action,
        items = items,
        sourceState = {
            age = first and Utils.safeCall(first, "getAge") or nil,
            freezingTime = first and Utils.safeCall(first, "getFreezingTime") or nil,
            cooked = first and Utils.safeCall(first, "isCooked") == true,
            burnt = first and Utils.safeCall(first, "isBurnt") == true,
            nutrition = first and Utils.getNutrition(first) or nil,
        },
    }
end

local function chooseOperationOutputs(operation)
    local outputs = {}
    if operation.randomOutputs and #operation.randomOutputs > 0 then
        local index = 1
        if ZombRand then
            index = ZombRand(#operation.randomOutputs) + 1
        else
            index = math.random(#operation.randomOutputs)
        end
        outputs[#outputs + 1] = operation.randomOutputs[index]
    else
        for _, output in ipairs(operation.outputs or {}) do
            outputs[#outputs + 1] = output
        end
    end
    if operation.emptyCan then
        outputs[#outputs + 1] = "Base.TinCanEmpty"
    end
    return outputs
end

local function drainableUsesLeft(item)
    if not item or not item.IsDrainable or not item:IsDrainable() then return nil end
    local useDelta = item.getUseDelta and item:getUseDelta() or nil
    if not useDelta or useDelta <= 0 then return nil end
    local delta = 1.0
    if item.getDelta then
        delta = item:getDelta() or 1.0
    elseif item.getUsedDelta then
        local usedDelta = item:getUsedDelta()
        if usedDelta ~= nil then
            delta = 1.0 - usedDelta
        end
    end
    if delta < 0 then delta = 0 end
    if delta > 1 then delta = 1 end
    return math.floor((delta / useDelta) + 0.0001)
end

local function consumeOperationSource(item, operation)
    if not operation or not operation.consumeUse then
        return Utils.removeInventoryItem(item)
    end

    if item and item.IsDrainable and item:IsDrainable() then
        if item.UseAndSync then
            item:UseAndSync()
        elseif item.Use then
            item:Use()
        else
            return Utils.removeInventoryItem(item)
        end

        local remaining = drainableUsesLeft(item)
        if remaining ~= nil and remaining <= 0 and item.getContainer and item:getContainer() then
            return Utils.removeInventoryItem(item)
        end

        if item and item.transmitModData then item:transmitModData() end
        return true
    end

    return Utils.removeInventoryItem(item)
end

function Validator.validateOperation(player, args)
    if not player or not args then return fail("Malformed operation request") end

    local itemId = tonumber(args.itemId)
    local operationId = tostring(args.operationId or "")
    if not itemId or operationId == "" then return fail("Malformed operation request") end

    local item = Utils.findAccessibleItemById(player, itemId, args.fullType)
    if not item then return fail("Item is no longer accessible") end
    if not (item.getContainer and item:getContainer()) then return fail("Item is not accessible") end

    local fullType = Utils.getFullType(item)
    local action = Actions and Actions.actionForFullType and Actions.actionForFullType(fullType) or nil
    local operation = action and action.operation or nil
    if not operation then return fail("No FFC operation is available for " .. tostring(fullType)) end
    if operation.id ~= operationId then return fail("Operation no longer matches the selected item") end

    if operation.rejectFrozen and Utils.safeCall(item, "isFrozen") == true then
        return fail(Utils.getDisplayName(item) .. " is frozen. Thaw it before using Faded's Feastcraft.")
    end
    if operation.rejectRotten and Utils.safeCall(item, "isRotten") == true then
        return fail(Utils.getDisplayName(item) .. " is rotten")
    end
    if operation.rejectBurned and Utils.safeCall(item, "isBurnt") == true then
        return fail(Utils.getDisplayName(item) .. " is burned")
    end

    local tool = nil
    if operation.toolGroup then
        tool = Validator.findTool(player, operation.toolGroup)
        if not tool then
            return fail("Requires " .. tostring(operation.toolLabel or operation.toolGroup))
        end
    end

    local outputs = chooseOperationOutputs(operation)
    if #outputs == 0 then return fail("Operation has no output") end
    for _, outputFullType in ipairs(outputs) do
        if Operations.itemTypeExists and not Operations.itemTypeExists(outputFullType) then
            return fail("Missing output item script: " .. tostring(outputFullType))
        end
    end

    return true, {
        item = item,
        fullType = fullType,
        action = action,
        operation = operation,
        outputs = outputs,
        tool = tool,
        sourceState = {
            age = Utils.safeCall(item, "getAge"),
            freezingTime = Utils.safeCall(item, "getFreezingTime"),
        },
    }
end

function Validator.validateBatchOperations(player, args)
    local itemIds = args and normalizeItemIds(args.itemIds) or nil
    if not player or not itemIds then return fail("Malformed batch operation request") end
    local limit = Balance and Balance.maxBatchOperations and Balance.maxBatchOperations() or 10
    if #itemIds == 0 then return fail("No batch operations selected") end
    if #itemIds > limit then return fail("Too many batch operations selected") end

    local seen = {}
    local validations = {}
    for _, rawId in ipairs(itemIds) do
        local itemId = tonumber(rawId)
        if not itemId or seen[itemId] then return fail("Invalid duplicate batch item") end
        seen[itemId] = true
        local item = Utils.findAccessibleItemById(player, itemId)
        if not item then return fail("Batch item is no longer accessible") end
        local fullType = Utils.getFullType(item)
        local action = Actions and Actions.actionForFullType and Actions.actionForFullType(fullType) or nil
        local operation = action and action.operation or nil
        if not operation then return fail("No FFC operation is available for " .. tostring(fullType)) end
        local ok, validation = Validator.validateOperation(player, {
            itemId = itemId,
            operationId = operation.id,
            fullType = fullType,
        })
        if not ok then return fail(validation) end
        validations[#validations + 1] = validation
    end

    return true, { validations = validations }
end

local function applyInheritedFoodState(result, state)
    if not result or not state then return end
    if state.age ~= nil then
        pcall(function() result:setAge(state.age) end)
    end
    if state.freezingTime ~= nil then
        pcall(function() result:setFreezingTime(state.freezingTime) end)
    end
end

function Validator.applyDirectRecipe(player, validation)
    if not player or not validation or not validation.action or not validation.items then
        return fail("Missing validated direct recipe data")
    end

    for _, item in ipairs(validation.items or {}) do
        if not (item.getContainer and item:getContainer()) then
            return fail("Recipe ingredient moved before crafting")
        end
    end

    for _, item in ipairs(validation.items or {}) do
        if not Utils.removeInventoryItem(item) then
            return fail("Could not consume recipe ingredient")
        end
    end

    local added = {}
    local inv = player:getInventory()
    for _, outputFullType in ipairs(validation.action.outputs or {}) do
        local result = Utils.addItem(inv, outputFullType)
        if not result then
            return fail("Could not create " .. tostring(outputFullType))
        end
        if validation.action.inheritFoodAge then
            applyInheritedFoodState(result, validation.sourceState)
        end
        if string.find(tostring(outputFullType), "^FadedFeastcraft%.FFC_", 1, false) and validation.sourceState and validation.sourceState.nutrition then
            local n = validation.sourceState.nutrition
            local hunger = tonumber(n.hunger) or -0.15
            if hunger > -0.01 then hunger = -0.01 end
            if hunger < -1.0 then hunger = -1.0 end
            Utils.safeSet(result, "setHungChange", hunger)
            Utils.safeSet(result, "setHungerChange", hunger)
            if Balance and Balance.applyMealTuning then
                Balance.applyMealTuning(result, player, n, {
                    source = outputFullType == "FadedFeastcraft.FFC_PreservedRation" and "preservation" or "packed",
                    variety = 1,
                })
            end
        end
        if Preservation and Preservation.isPreservationAction and Preservation.isPreservationAction(validation.action) then
            Preservation.stampItem(result, player, {
                method = Preservation.methodForProbe(validation.action.name, validation.action.id, outputFullType),
                label = validation.action.name,
                source = validation.action.source,
            })
        end
        local md = result:getModData()
        md.FFC_DirectRecipe = validation.action.id
        md.FFC_DirectRecipeName = validation.action.name
        md.FFC_CraftedWorldAge = getGameTime and getGameTime():getWorldAgeHours() or 0
        Utils.syncItem(player, result)
        added[#added + 1] = result
    end

    return true, added
end

function Validator.applyOperation(player, validation)
    if not player or not validation or not validation.item or not validation.operation then
        return fail("Missing validated operation data")
    end
    local item = validation.item
    if not (item.getContainer and item:getContainer()) then
        return fail("Item moved before operation")
    end
    if Utils.getFullType(item) ~= validation.fullType then
        return fail("Item changed before operation")
    end

    if not consumeOperationSource(item, validation.operation) then
        return fail("Could not consume source item")
    end

    local added = {}
    local inv = player:getInventory()
    for _, outputFullType in ipairs(validation.outputs or {}) do
        local result = Utils.addItem(inv, outputFullType)
        if not result then
            return fail("Could not create " .. tostring(outputFullType))
        end
        if validation.operation.inheritFoodAge then
            applyInheritedFoodState(result, validation.sourceState)
        end
        if Preservation and Preservation.isPreservationAction and Preservation.isPreservationAction(validation.operation) then
            Preservation.stampItem(result, player, {
                method = Preservation.methodForProbe(validation.operation.label, validation.operation.input, outputFullType),
                label = validation.operation.label,
                source = validation.operation.source,
            })
        end
        local md = result:getModData()
        md.FFC_Operation = validation.operation.id
        md.FFC_ActionType = validation.action and validation.action.actionType or "food-operation"
        md.FFC_SourceItem = validation.fullType
        md.FFC_OperatedWorldAge = getGameTime and getGameTime():getWorldAgeHours() or 0
        Utils.syncItem(player, result)
        added[#added + 1] = result
    end

    return true, added
end

function Validator.applyBatchOperations(player, validation)
    if not player or not validation or not validation.validations then
        return fail("Missing validated batch data")
    end

    local count = 0
    local lastReason = nil
    for _, one in ipairs(validation.validations or {}) do
        local ok, resultOrReason = Validator.applyOperation(player, one)
        if ok then
            count = count + 1
        else
            lastReason = resultOrReason
            break
        end
    end

    if count == 0 then
        return fail(lastReason or "No batch operations completed")
    end
    return true, count
end

function Validator.validateStationCooking(player, args)
    if not player or not args then return fail("Malformed cooking station request") end
    if tostring(args.recipeId or "") ~= "ffc_hot_meal" then
        return fail("This cooking station recipe is not bound to a safe FFC adapter yet")
    end

    local stationOk, stationOrReason = CookingStation.validateStationKey(player, args.stationKey)
    if not stationOk then return fail(stationOrReason) end

    local itemIds = normalizeItemIds(args.itemIds)
    if not itemIds or #itemIds == 0 then return fail("No cooking ingredients selected") end
    local maxIngredients = Balance and Balance.maxMealIngredients and Balance.maxMealIngredients() or Config.MAX_MEAL_INGREDIENTS
    if #itemIds > maxIngredients then return fail("Too many cooking ingredients selected") end

    local vessel = Validator.findTool(player, "cooking_vessel")
    if not vessel then return fail("Requires a nearby cooking vessel") end

    local seen = {}
    local items = {}
    local totals = {
        hunger = 0,
        calories = 0,
        proteins = 0,
        lipids = 0,
        carbohydrates = 0,
        boredom = 0,
        unhappy = 0,
    }

    for _, id in ipairs(itemIds) do
        local numericId = tonumber(id)
        if not numericId or seen[numericId] then return fail("Invalid duplicate cooking ingredient") end
        seen[numericId] = true

        local item = Utils.findAccessibleItemById(player, numericId)
        if not item then return fail("Cooking ingredient no longer exists") end
        if not (item.getContainer and item:getContainer()) then return fail("Cooking ingredient is not accessible") end
        if not Utils.isFood(item) then return fail("Cooking ingredient is not food") end
        if Utils.safeCall(item, "isRotten") == true then return fail(Utils.getDisplayName(item) .. " is rotten") end
        if Utils.safeCall(item, "isBurnt") == true then return fail(Utils.getDisplayName(item) .. " is burned") end
        if Utils.safeCall(item, "isFrozen") == true then return fail(Utils.getDisplayName(item) .. " is frozen") end

        local dangerous = false
        if item.isbDangerousUncooked and item:isbDangerousUncooked() then dangerous = true end
        if item.isDangerousUncooked and item:isDangerousUncooked() then dangerous = true end
        if dangerous and not (item.isCooked and item:isCooked()) then
            return fail(Utils.getDisplayName(item) .. " is dangerous raw")
        end

        local n = Utils.getNutrition(item)
        totals.hunger = totals.hunger + n.hunger
        totals.calories = totals.calories + n.calories
        totals.proteins = totals.proteins + n.proteins
        totals.lipids = totals.lipids + n.lipids
        totals.carbohydrates = totals.carbohydrates + n.carbohydrates
        totals.boredom = totals.boredom + n.boredom
        totals.unhappy = totals.unhappy + n.unhappy
        items[#items + 1] = item
    end

    return true, {
        station = stationOrReason,
        vessel = vessel,
        items = items,
        totals = totals,
    }
end

function Validator.applyStationCooking(player, validation)
    if not player or not validation or not validation.items then
        return fail("Missing validated cooking station data")
    end

    for _, item in ipairs(validation.items) do
        if not (item.getContainer and item:getContainer()) then
            return fail("Cooking ingredient moved before cooking")
        end
    end

    for _, item in ipairs(validation.items) do
        if not Utils.removeInventoryItem(item) then
            return fail("Could not consume cooking ingredient")
        end
    end

    local result = Utils.addItem(player:getInventory(), Config.RESULT_FIELD_MEAL)
    if not result then return fail("Could not create hot meal") end

    local totals = validation.totals or {}
    local hunger = tonumber(totals.hunger) or -0.15
    if hunger > -0.04 then hunger = -0.04 end
    if hunger < -1.0 then hunger = -1.0 end

    Utils.safeSet(result, "setName", "FFC Hot Meal")
    Utils.safeSet(result, "setCooked", true)
    Utils.safeSet(result, "setHungChange", hunger)
    Utils.safeSet(result, "setHungerChange", hunger)
    if Balance and Balance.applyMealTuning then
        Balance.applyMealTuning(result, player, totals, {
            source = "station",
            variety = mealVariety(validation.items),
        })
    else
        Utils.safeSet(result, "setCalories", math.max(1, (totals.calories or 1) * 1.08))
        Utils.safeSet(result, "setProteins", math.max(0, totals.proteins or 0))
        Utils.safeSet(result, "setLipids", math.max(0, totals.lipids or 0))
        Utils.safeSet(result, "setCarbohydrates", math.max(0, totals.carbohydrates or 0))
        Utils.safeSet(result, "setBoredomChange", (totals.boredom or 0) - 2)
        Utils.safeSet(result, "setUnhappyChange", (totals.unhappy or 0) - 2)
    end

    local xpMult = Utils.sbNumber("CookingXPMultiplier", 1.0, 0.0, 5.0)
    pcall(function()
        if player.getXp and Perks and Perks.Cooking then
            player:getXp():AddXP(Perks.Cooking, math.max(0, 1.5 * xpMult))
        end
    end)

    local md = result:getModData()
    md.FFC_CookedAtStation = true
    md.FFC_CookingStation = validation.station and validation.station.kind or "Heat Source"
    md.FFC_IngredientCount = #validation.items
    md.FFC_CraftedWorldAge = getGameTime and getGameTime():getWorldAgeHours() or 0
    if MealEffects and MealEffects.stampMeal then
        MealEffects.stampMeal(result, player, validation, { source = "station" })
    end
    Utils.syncItem(player, result)
    return true, result
end

return Validator
