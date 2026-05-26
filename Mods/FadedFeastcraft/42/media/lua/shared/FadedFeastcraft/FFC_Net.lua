require "FadedFeastcraft/FFC_Config"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.Net = FadedFeastcraft.Net or {}

local Net = FadedFeastcraft.Net
local Config = FadedFeastcraft.Config

function Net.makeRequestId(player)
    local online = player and player.getOnlineID and player:getOnlineID() or 0
    local age = getGameTime and math.floor(getGameTime():getWorldAgeHours() * 3600) or 0
    return tostring(online) .. "-" .. tostring(age) .. "-" .. tostring(ZombRand and ZombRand(1000000) or 0)
end

function Net.itemIdsToCsv(itemIds)
    local out = {}
    for _, id in ipairs(itemIds or {}) do
        local numericId = tonumber(id)
        if numericId then out[#out + 1] = tostring(math.floor(numericId)) end
    end
    return table.concat(out, ",")
end

local function dispatch(player, command, payload)
    if player and sendClientCommand then
        sendClientCommand(player, Config.NET_MODULE, command, payload)
        return true
    end

    local commands = FadedFeastcraft and FadedFeastcraft.ServerCommands or nil
    if commands then
        if command == "CraftFieldMeal" and commands.handleCraftFieldMeal then
            commands.handleCraftFieldMeal(player, payload)
            return true
        end
        if command == "RunOperation" and commands.handleRunOperation then
            commands.handleRunOperation(player, payload)
            return true
        end
        if command == "RunBatchOperations" and commands.handleRunBatchOperations then
            commands.handleRunBatchOperations(player, payload)
            return true
        end
        if command == "StartStationCooking" and commands.handleStartStationCooking then
            commands.handleStartStationCooking(player, payload)
            return true
        end
        if command == "CraftDirectRecipe" and commands.handleCraftDirectRecipe then
            commands.handleCraftDirectRecipe(player, payload)
            return true
        end
    end

    return false
end

function Net.requestFieldMeal(player, itemIds)
    if not player then return false end
    return dispatch(player, "CraftFieldMeal", {
        requestId = Net.makeRequestId(player),
        itemIds = Net.itemIdsToCsv(itemIds),
        expectedResult = Config.RESULT_FIELD_MEAL,
    })
end

function Net.requestOperation(player, itemId, operationId, fullType)
    if not player then return false end
    return dispatch(player, "RunOperation", {
        requestId = Net.makeRequestId(player),
        itemId = tonumber(itemId),
        operationId = tostring(operationId or ""),
        fullType = tostring(fullType or ""),
    })
end

function Net.requestBatchOperations(player, itemIds)
    if not player then return false end
    return dispatch(player, "RunBatchOperations", {
        requestId = Net.makeRequestId(player),
        itemIds = Net.itemIdsToCsv(itemIds),
    })
end

function Net.requestStationCooking(player, recipeId, stationKey, itemIds, requestId)
    if not player then return false end
    return dispatch(player, "StartStationCooking", {
        requestId = requestId or Net.makeRequestId(player),
        recipeId = tostring(recipeId or ""),
        stationKey = tostring(stationKey or ""),
        itemIds = Net.itemIdsToCsv(itemIds),
    })
end

function Net.requestDirectRecipe(player, actionId)
    if not player then return false end
    return dispatch(player, "CraftDirectRecipe", {
        requestId = Net.makeRequestId(player),
        actionId = tostring(actionId or ""),
    })
end

return Net
