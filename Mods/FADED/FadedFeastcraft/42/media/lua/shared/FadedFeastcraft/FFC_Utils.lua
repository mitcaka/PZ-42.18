require "FadedFeastcraft/FFC_Config"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.Utils = FadedFeastcraft.Utils or {}

local Utils = FadedFeastcraft.Utils

function Utils.safeCall(target, methodName, ...)
    if not target or not methodName then return nil end
    local fn = target[methodName]
    if type(fn) ~= "function" then return nil end
    local ok, result = pcall(fn, target, ...)
    if ok then return result end
    return nil
end

function Utils.safeSet(target, methodName, ...)
    if not target or not methodName then return false end
    local fn = target[methodName]
    if type(fn) ~= "function" then return false end
    local ok = pcall(fn, target, ...)
    return ok == true
end

function Utils.safeGlobalCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

function Utils.log(message)
    print("[FFC] " .. tostring(message))
end

function Utils.debug(message)
    local enabled = SandboxVars
        and SandboxVars.FadedFeastcraft
        and SandboxVars.FadedFeastcraft.EnableDebugLogging == true
    if enabled then
        Utils.log(message)
    end
end

function Utils.getSandbox()
    return (SandboxVars and SandboxVars.FadedFeastcraft) or {}
end

function Utils.sbBool(key, fallback)
    local sb = Utils.getSandbox()
    if sb[key] == nil then return fallback end
    return sb[key] == true
end

function Utils.sbNumber(key, fallback, minValue, maxValue)
    local value = tonumber(Utils.getSandbox()[key]) or fallback
    if minValue ~= nil and value < minValue then value = minValue end
    if maxValue ~= nil and value > maxValue then value = maxValue end
    return value
end

function Utils.round(value, places)
    local n = tonumber(value) or 0
    local p = 10 ^ (places or 0)
    return math.floor(n * p + 0.5) / p
end

function Utils.trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function Utils.lower(value)
    return string.lower(tostring(value or ""))
end

function Utils.containsText(haystack, needle)
    needle = Utils.lower(Utils.trim(needle))
    if needle == "" then return true end
    return string.find(Utils.lower(haystack), needle, 1, true) ~= nil
end

function Utils.isModActive(modId)
    if not modId or not getActivatedMods then return false end
    local mods = getActivatedMods()
    if not mods then return false end
    if mods.contains then
        local ok, result = pcall(function() return mods:contains(modId) end)
        if ok then return result == true end
    end
    if mods.size and mods.get then
        for i = 0, mods:size() - 1 do
            if mods:get(i) == modId then return true end
        end
    end
    return false
end

function Utils.isAnyModActive(modIds)
    for _, modId in ipairs(modIds or {}) do
        if Utils.isModActive(modId) then return true, modId end
    end
    return false, nil
end

function Utils.getFullType(item)
    return (item and item.getFullType and item:getFullType())
        or (item and item.getType and item:getType())
        or ""
end

function Utils.getDisplayName(item)
    return (item and item.getDisplayName and item:getDisplayName())
        or (item and item.getName and item:getName())
        or Utils.getFullType(item)
        or "Unknown"
end

local function textureName(texture)
    if not texture then return nil end
    if type(texture) == "string" then return texture end
    local name = Utils.safeCall(texture, "getName")
    if name and tostring(name) ~= "" then return tostring(name) end
    return nil
end

function Utils.getScriptItem(fullType)
    if not fullType or tostring(fullType) == "" then return nil end
    if ScriptManager and ScriptManager.instance and ScriptManager.instance.getItem then
        local ok, item = pcall(function() return ScriptManager.instance:getItem(fullType) end)
        if ok and item then return item end
    end
    if getScriptManager and getScriptManager().getItem then
        local ok, item = pcall(function() return getScriptManager():getItem(fullType) end)
        if ok and item then return item end
    end
    return nil
end

function Utils.getScriptItemTextureName(scriptItem)
    if not scriptItem then return nil end
    local texture = Utils.safeCall(scriptItem, "getNormalTexture")
        or Utils.safeCall(scriptItem, "getTexture")
        or Utils.safeCall(scriptItem, "getTex")
    return textureName(texture)
end

function Utils.getItemTextureName(item)
    if not item then return nil end
    local texture = Utils.safeCall(item, "getTexture")
        or Utils.safeCall(item, "getTex")
        or Utils.safeCall(item, "getNormalTexture")
    local name = textureName(texture)
    if name then return name end

    local scriptItem = Utils.safeCall(item, "getScriptItem") or Utils.getScriptItem(Utils.getFullType(item))
    return Utils.getScriptItemTextureName(scriptItem)
end

function Utils.isFood(item)
    if not item then return false end
    if instanceof and instanceof(item, "Food") then return true end
    if item.getCategory and item:getCategory() == "Food" then return true end
    return false
end

function Utils.getNutrition(item)
    local hunger = Utils.safeCall(item, "getHungerChange")
    if hunger == nil then hunger = Utils.safeCall(item, "getHungChange") end
    return {
        hunger = tonumber(hunger) or 0,
        calories = tonumber(Utils.safeCall(item, "getCalories")) or 0,
        proteins = tonumber(Utils.safeCall(item, "getProteins")) or 0,
        lipids = tonumber(Utils.safeCall(item, "getLipids")) or 0,
        carbohydrates = tonumber(Utils.safeCall(item, "getCarbohydrates")) or 0,
        boredom = tonumber(Utils.safeCall(item, "getBoredomChange")) or 0,
        unhappy = tonumber(Utils.safeCall(item, "getUnhappyChange")) or 0,
    }
end

function Utils.getRemainingAmount(item)
    if not item then return nil end
    if item.IsDrainable and item:IsDrainable() then
        local uses = Utils.safeCall(item, "getCurrentUsesFloat")
        if uses ~= nil then return tonumber(uses) end
        local delta = Utils.safeCall(item, "getDelta")
        if delta ~= nil then return tonumber(delta) end
    end
    local nutrition = Utils.getNutrition(item)
    if nutrition.hunger ~= 0 then return math.abs(nutrition.hunger * 100) end
    return nil
end

function Utils.walkInventory(container, callback, limit)
    if not container or not container.getItems or type(callback) ~= "function" then return 0 end
    local visited = {}
    local count = 0
    local maxCount = tonumber(limit) or 1000

    local function walk(inv)
        if not inv or visited[inv] or count >= maxCount then return end
        visited[inv] = true
        local items = inv:getItems()
        if not items then return end
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item then
                count = count + 1
                callback(item, inv)
                if count >= maxCount then return end
            end
        end
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            local subInv = item and item.getInventory and item:getInventory() or nil
            if subInv then walk(subInv) end
            if count >= maxCount then return end
        end
    end

    walk(container)
    return count
end

function Utils.walkNearbyContainerItems(player, callback, options)
    if not player or type(callback) ~= "function" then return 0, 0 end
    local radius = tonumber(options and options.radius) or Utils.sbNumber("IngredientScanRadius", 2, 0, 8)
    if radius <= 0 then return 0, 0 end

    local maxContainers = tonumber(options and options.maxContainers) or Utils.sbNumber("MaxScannedContainers", 24, 4, 80)
    local maxItems = tonumber(options and options.maxItems) or Utils.sbNumber("MaxScannedItems", 350, 50, 1000)
    local cell = getCell and getCell() or nil
    if not cell then return 0, 0 end

    local px = math.floor(player:getX())
    local py = math.floor(player:getY())
    local pz = math.floor(player:getZ())
    local containers = 0
    local itemsVisited = 0

    for x = px - radius, px + radius do
        for y = py - radius, py + radius do
            if containers >= maxContainers or itemsVisited >= maxItems then return containers, itemsVisited end
            local square = cell:getGridSquare(x, y, pz)
            local objects = square and square:getObjects() or nil
            if objects then
                for i = 0, objects:size() - 1 do
                    local obj = objects:get(i)
                    local count = Utils.safeCall(obj, "getContainerCount") or 0
                    for c = 0, count - 1 do
                        if containers >= maxContainers or itemsVisited >= maxItems then return containers, itemsVisited end
                        local ok, container = pcall(function() return obj:getContainerByIndex(c) end)
                        if ok and container and container.getItems then
                            containers = containers + 1
                            local items = container:getItems()
                            if items then
                                for n = 0, items:size() - 1 do
                                    if itemsVisited >= maxItems then return containers, itemsVisited end
                                    local item = items:get(n)
                                    itemsVisited = itemsVisited + 1
                                    callback(item, container, "Nearby")
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return containers, itemsVisited
end

function Utils.walkRoomContainerItems(player, callback, options)
    if not player or type(callback) ~= "function" then return 0, 0 end
    local radius = tonumber(options and options.radius) or Utils.sbNumber("ExpiryRoomScanRadius", 8, 2, 16)
    local maxContainers = tonumber(options and options.maxContainers) or Utils.sbNumber("MaxScannedContainers", 24, 4, 80)
    local maxItems = tonumber(options and options.maxItems) or Utils.sbNumber("MaxScannedItems", 350, 50, 1000)
    local cell = getCell and getCell() or nil
    if not cell then return 0, 0 end

    local square = Utils.safeCall(player, "getSquare")
    local room = Utils.safeCall(square, "getRoom")
    local px = math.floor(player:getX())
    local py = math.floor(player:getY())
    local pz = math.floor(player:getZ())
    local containers = 0
    local itemsVisited = 0
    local visitedContainers = {}

    for x = px - radius, px + radius do
        for y = py - radius, py + radius do
            if containers >= maxContainers or itemsVisited >= maxItems then return containers, itemsVisited end
            local scanSquare = cell:getGridSquare(x, y, pz)
            if scanSquare then
                local scanRoom = Utils.safeCall(scanSquare, "getRoom")
                local includeSquare = false
                if room then
                    includeSquare = scanRoom == room
                else
                    local dx = x - px
                    local dy = y - py
                    includeSquare = (dx * dx + dy * dy) <= 4
                end

                if includeSquare then
                    local objects = scanSquare:getObjects()
                    if objects then
                        for i = 0, objects:size() - 1 do
                            local obj = objects:get(i)
                            local count = Utils.safeCall(obj, "getContainerCount") or 0
                            for c = 0, count - 1 do
                                if containers >= maxContainers or itemsVisited >= maxItems then return containers, itemsVisited end
                                local ok, container = pcall(function() return obj:getContainerByIndex(c) end)
                                if ok and container and container.getItems and not visitedContainers[container] then
                                    visitedContainers[container] = true
                                    containers = containers + 1
                                    local items = container:getItems()
                                    if items then
                                        for n = 0, items:size() - 1 do
                                            if itemsVisited >= maxItems then return containers, itemsVisited end
                                            local item = items:get(n)
                                            itemsVisited = itemsVisited + 1
                                            callback(item, container, room and "Room" or "Outdoor")
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return containers, itemsVisited
end

function Utils.findInventoryItemById(player, itemId, expectedFullType)
    if not player or itemId == nil then return nil end
    local wantedId = tonumber(itemId)
    local found = nil
    Utils.walkInventory(player:getInventory(), function(item)
        if found then return end
        if item and item.getID and item:getID() == wantedId then
            if not expectedFullType or Utils.getFullType(item) == expectedFullType then
                found = item
            end
        end
    end, 2000)
    return found
end

function Utils.findAccessibleItemById(player, itemId, expectedFullType)
    local found = Utils.findInventoryItemById(player, itemId, expectedFullType)
    if found then return found end
    if not Utils.sbBool("EnableNearbyContainerScanning", true) then return nil end

    local wantedId = tonumber(itemId)
    Utils.walkNearbyContainerItems(player, function(item)
        if found then return end
        if item and item.getID and item:getID() == wantedId then
            if not expectedFullType or Utils.getFullType(item) == expectedFullType then
                found = item
            end
        end
    end, {
        maxItems = Utils.sbNumber("MaxScannedItems", 350, 50, 1000),
        maxContainers = Utils.sbNumber("MaxScannedContainers", 24, 4, 80),
        radius = Utils.sbNumber("IngredientScanRadius", 2, 0, 8),
    })

    return found
end

function Utils.removeInventoryItem(item)
    if not item then return false end
    local container = item.getContainer and item:getContainer() or nil
    if not container then return false end
    if container.DoRemoveItem then
        container:DoRemoveItem(item)
    else
        container:Remove(item)
    end
    if sendRemoveItemFromContainer then
        pcall(sendRemoveItemFromContainer, container, item)
    end
    return true
end

function Utils.addItem(container, itemType)
    if not container or not itemType then return nil end
    local item = container:AddItem(itemType)
    if item and sendAddItemToContainer then
        pcall(sendAddItemToContainer, container, item)
    end
    return item
end

function Utils.syncItem(player, item)
    if not item then return end
    if syncItemFields and player then
        pcall(syncItemFields, player, item)
    elseif item.syncItemFields then
        pcall(function() item:syncItemFields() end)
    end
    if item.transmitModData then
        pcall(function() item:transmitModData() end)
    end
end

return Utils
