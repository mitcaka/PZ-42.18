require "FadedFeastcraft/FFC_Boot"
require "FadedFeastcraft/FFC_CraftingValidator"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.ServerCommands = FadedFeastcraft.ServerCommands or {}

local Commands = FadedFeastcraft.ServerCommands
local Config = FadedFeastcraft.Config
local Utils = FadedFeastcraft.Utils
local Validator = FadedFeastcraft.CraftingValidator

Commands.recentRequests = Commands.recentRequests or {}

local function itemPayload(item)
    if not item then return nil end
    local md = item.getModData and item:getModData() or {}
    local nutrition = Utils.getNutrition(item)
    return {
        fullType = Utils.getFullType(item),
        name = Utils.getDisplayName(item),
        textureName = Utils.getItemTextureName and Utils.getItemTextureName(item) or nil,
        hunger = nutrition.hunger,
        calories = nutrition.calories,
        proteins = nutrition.proteins,
        lipids = nutrition.lipids,
        carbohydrates = nutrition.carbohydrates,
        boredom = nutrition.boredom,
        unhappy = nutrition.unhappy,
        balance = md and md.FFC_Balance or nil,
        preservation = md and md.FFC_Preservation or nil,
        effect = md and md.FFC_MealEffect or nil,
    }
end

local function firstItemPayload(value)
    if not value then return nil end
    if value.getFullType then return itemPayload(value) end
    if type(value) == "table" then
        for _, item in ipairs(value) do
            if item and item.getFullType then return itemPayload(item) end
        end
    end
    return nil
end

local function respond(player, requestId, ok, message, extra)
    local payload = {
        requestId = requestId,
        ok = ok == true,
        message = tostring(message or ""),
    }
    if type(extra) == "table" then
        for key, value in pairs(extra) do
            payload[key] = value
        end
    end

    if isServer and isServer() and player and sendServerCommand then
        sendServerCommand(player, Config.NET_MODULE, "CraftResult", payload)
        return
    end

    if FadedFeastcraft.HandleCraftResult then
        FadedFeastcraft.HandleCraftResult(payload)
        return
    end

    if sendServerCommand then
        pcall(sendServerCommand, Config.NET_MODULE, "CraftResult", payload)
    end
end

local function nowSeconds()
    if getGameTime then
        return math.floor(getGameTime():getWorldAgeHours() * 3600)
    end
    return 0
end

local function pruneRequests(now)
    local cutoff = now - 300
    for key, stamp in pairs(Commands.recentRequests) do
        if type(stamp) ~= "number" or stamp < cutoff then
            Commands.recentRequests[key] = nil
        end
    end
end

local function isDuplicate(player, requestId)
    if not requestId then return true end
    local now = nowSeconds()
    pruneRequests(now)
    local key = tostring(player and player.getOnlineID and player:getOnlineID() or 0) .. ":" .. tostring(requestId)
    if Commands.recentRequests[key] then return true end
    Commands.recentRequests[key] = now
    return false
end

function Commands.handleCraftFieldMeal(player, args)
    local requestId = args and args.requestId or nil
    if isDuplicate(player, requestId) then
        respond(player, requestId, false, "Duplicate crafting request")
        return
    end

    local ok, validation = Validator.validateFieldMeal(player, args)
    if not ok then
        respond(player, requestId, false, validation)
        return
    end

    local made, resultOrReason = Validator.applyFieldMeal(player, validation)
    if made then
        respond(player, requestId, true, "Created FFC Field Meal", { command = "CraftFieldMeal", result = itemPayload(resultOrReason) })
    else
        respond(player, requestId, false, resultOrReason)
    end
end

function Commands.handleRunOperation(player, args)
    local requestId = args and args.requestId or nil
    if isDuplicate(player, requestId) then
        respond(player, requestId, false, "Duplicate operation request")
        return
    end

    local ok, validation = Validator.validateOperation(player, args)
    if not ok then
        respond(player, requestId, false, validation)
        return
    end

    local made, resultOrReason = Validator.applyOperation(player, validation)
    if made then
        respond(player, requestId, true, "FFC operation complete: " .. tostring(validation.operation.label or "operation"), { command = "RunOperation", result = firstItemPayload(resultOrReason) })
    else
        respond(player, requestId, false, resultOrReason)
    end
end

function Commands.handleRunBatchOperations(player, args)
    local requestId = args and args.requestId or nil
    if isDuplicate(player, requestId) then
        respond(player, requestId, false, "Duplicate batch operation request")
        return
    end

    local ok, validation = Validator.validateBatchOperations(player, args)
    if not ok then
        respond(player, requestId, false, validation)
        return
    end

    local made, resultOrReason = Validator.applyBatchOperations(player, validation)
    if made then
        respond(player, requestId, true, "FFC batch prep complete: " .. tostring(resultOrReason) .. " operation(s)")
    else
        respond(player, requestId, false, resultOrReason)
    end
end

function Commands.handleCraftDirectRecipe(player, args)
    local requestId = args and args.requestId or nil
    if isDuplicate(player, requestId) then
        respond(player, requestId, false, "Duplicate direct recipe request")
        return
    end

    local ok, validation = Validator.validateDirectRecipe(player, args)
    if not ok then
        respond(player, requestId, false, validation)
        return
    end

    local made, resultOrReason = Validator.applyDirectRecipe(player, validation)
    if made then
        respond(player, requestId, true, "FFC recipe complete: " .. tostring(validation.action.name or "recipe"), { command = "CraftDirectRecipe", result = firstItemPayload(resultOrReason) })
    else
        respond(player, requestId, false, resultOrReason)
    end
end

function Commands.handleStartStationCooking(player, args)
    local requestId = args and args.requestId or nil
    if isDuplicate(player, requestId) then
        respond(player, requestId, false, "Duplicate cooking station request")
        return
    end

    local ok, validation = Validator.validateStationCooking(player, args)
    if not ok then
        respond(player, requestId, false, validation)
        return
    end

    local made, resultOrReason = Validator.applyStationCooking(player, validation)
    if made then
        respond(player, requestId, true, "Created FFC Hot Meal at " .. tostring(validation.station and validation.station.kind or "heat source"), { command = "StartStationCooking", result = itemPayload(resultOrReason) })
    else
        respond(player, requestId, false, resultOrReason)
    end
end

local function onClientCommand(module, command, player, args)
    if module ~= Config.NET_MODULE then return end
    if command == "CraftFieldMeal" then
        Commands.handleCraftFieldMeal(player, args)
    elseif command == "RunOperation" then
        Commands.handleRunOperation(player, args)
    elseif command == "RunBatchOperations" then
        Commands.handleRunBatchOperations(player, args)
    elseif command == "CraftDirectRecipe" then
        Commands.handleCraftDirectRecipe(player, args)
    elseif command == "StartStationCooking" then
        Commands.handleStartStationCooking(player, args)
    else
        Utils.debug("Unknown server command: " .. tostring(command))
    end
end

if Events and Events.OnClientCommand and not Commands.eventRegistered then
    Commands.eventRegistered = true
    Events.OnClientCommand.Add(onClientCommand)
end

return Commands
