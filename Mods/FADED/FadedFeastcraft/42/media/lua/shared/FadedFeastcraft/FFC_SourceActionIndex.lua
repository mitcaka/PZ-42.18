require "FadedFeastcraft/FFC_Config"
require "FadedFeastcraft/FFC_Utils"
require "FadedFeastcraft/FFC_Branding"
require "FadedFeastcraft/FFC_OperationRegistry"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.SourceActionIndex = FadedFeastcraft.SourceActionIndex or {}

local Index = FadedFeastcraft.SourceActionIndex
local Utils = FadedFeastcraft.Utils
local Branding = FadedFeastcraft.Branding
local Operations = FadedFeastcraft.OperationRegistry

Index.cache = Index.cache or {
    built = false,
    actions = {},
    byInput = {},
    adapters = {},
    stats = {
        indexed = 0,
        adapters = 0,
        serverAuthoritative = 0,
        csrAware = 0,
    },
}

local ADAPTERS = {
    {
        id = "vanilla",
        label = "FFC Vanilla Pantry",
        mode = "static+inferred",
        coverage = "Core canned foods and open-result naming",
        status = "active",
    },
    {
        id = "vfx",
        label = "FFC Expanded Pantry",
        mode = "inferred",
        coverage = "Expanded canned foods and jars using Open suffix outputs",
        status = "active",
    },
    {
        id = "snacktime",
        label = "FFC Snack Shelf",
        mode = "static",
        coverage = "Server-safe snack package unpack actions",
        status = "active",
    },
    {
        id = "skb_dried",
        label = "FFC Dry Storage",
        mode = "static",
        coverage = "Dried food can opening with random preserved output",
        status = "active",
    },
    {
        id = "pack_pantry",
        label = "FFC Canning Bench",
        mode = "inferred",
        coverage = "Canning-bench foods using Open suffix outputs",
        status = "active",
    },
    {
        id = "ted",
        label = "FFC Snack Shelf",
        mode = "inferred",
        coverage = "Snack-shelf canned foods using Open suffix outputs",
        status = "active",
    },
    {
        id = "mre",
        label = "FFC Field Rations",
        mode = "inferred",
        coverage = "Field ration cans using _open outputs",
        status = "active",
    },
    {
        id = "abuelita",
        label = "FFC Cocina Pantry",
        mode = "static",
        coverage = "Cocina pantry packages and snack bags",
        status = "active",
    },
    {
        id = "eliaz",
        label = "FFC Jarred Pantry",
        mode = "static",
        coverage = "Preserved jar opening with food-age inheritance",
        status = "active",
    },
    {
        id = "csr",
        label = "CSR Ecosystem",
        mode = "optional",
        coverage = "CSR detection, freshness helpers, and compatibility metadata",
        status = "optional",
        csrAware = true,
    },
    {
        id = "advanced_drying",
        label = "FFC Preservation Bench",
        mode = "recipe-callback",
        coverage = "Preservation recipes remain available through Build 42 recipes while FFC indexes them",
        status = "recipe-browser",
    },
}

local function hasText(value, text)
    return Utils.containsText(value or "", text or "")
end

local function actionTypeFor(operation)
    local label = Utils.lower(operation and operation.label or "")
    local input = Utils.lower(operation and operation.input or "")
    if string.find(label, "can", 1, true) or string.find(input, "canned", 1, true) or string.find(input, "tin", 1, true) then
        return "open-can"
    end
    if string.find(label, "jar", 1, true) or string.find(input, "jar", 1, true) or string.find(input, "canof", 1, true) then
        return "open-jar"
    end
    if string.find(label, "unpack", 1, true) or string.find(label, "package", 1, true) or string.find(label, "box", 1, true) then
        return "unpack"
    end
    if string.find(label, "preserv", 1, true) then
        return "preservation"
    end
    return "food-operation"
end

local function normalizedAction(operation)
    if not operation then return nil end
    local rawSource = tostring(operation.source or "unknown")
    local source = Branding.displaySource(rawSource, "FFC Integrated Pantry")
    return {
        id = operation.id,
        label = operation.label or "Food operation",
        actionType = actionTypeFor(operation),
        input = operation.input,
        outputPreview = Operations.outputPreview(operation),
        source = source,
        operation = operation,
        requiresTool = operation.toolLabel,
        serverAuthoritative = true,
        csrAware = Branding.isCSRSource(rawSource),
        rejectFrozen = operation.rejectFrozen == true,
        rejectRotten = operation.rejectRotten == true,
        rejectBurned = operation.rejectBurned == true,
        inheritFoodAge = operation.inheritFoodAge == true,
        consumeUse = operation.consumeUse == true,
    }
end

local function addAction(cache, operation)
    local action = normalizedAction(operation)
    if not action or not action.input then return end
    cache.actions[#cache.actions + 1] = action
    cache.byInput[action.input] = action
    cache.stats.indexed = cache.stats.indexed + 1
    if action.serverAuthoritative then
        cache.stats.serverAuthoritative = cache.stats.serverAuthoritative + 1
    end
    if action.csrAware then
        cache.stats.csrAware = cache.stats.csrAware + 1
    end
end

function Index.build(force)
    if Index.cache.built and not force then return Index.cache end

    local cache = {
        built = true,
        actions = {},
        byInput = {},
        adapters = {},
        stats = {
            indexed = 0,
            adapters = 0,
            serverAuthoritative = 0,
            csrAware = 0,
        },
    }

    for _, adapter in ipairs(ADAPTERS) do
        cache.adapters[#cache.adapters + 1] = adapter
        cache.stats.adapters = cache.stats.adapters + 1
        if adapter.csrAware then cache.stats.csrAware = cache.stats.csrAware + 1 end
    end

    if Operations and Operations.listStatic then
        for _, operation in ipairs(Operations.listStatic()) do
            addAction(cache, operation)
        end
    end

    table.sort(cache.actions, function(a, b)
        local left = tostring(a.source) .. tostring(a.label) .. tostring(a.input)
        local right = tostring(b.source) .. tostring(b.label) .. tostring(b.input)
        return left < right
    end)

    Index.cache = cache
    return cache
end

function Index.getCache()
    return Index.build(false)
end

function Index.getAdapters()
    return Index.build(false).adapters
end

function Index.getStats()
    return Index.build(false).stats
end

function Index.actionForFullType(fullType)
    fullType = tostring(fullType or "")
    if fullType == "" then return nil end

    local cache = Index.build(false)
    local action = cache.byInput[fullType]
    if action then return action end

    local operation = Operations and Operations.operationForFullType and Operations.operationForFullType(fullType) or nil
    action = normalizedAction(operation)
    if action then
        cache.byInput[fullType] = action
    end
    return action
end

function Index.actionForItem(item)
    return Index.actionForFullType(Utils.getFullType(item))
end

function Index.recordForIngredient(record)
    if not record then return nil end
    local action = Index.actionForFullType(record.fullType)
    if not action then return nil end
    local opRecord = {
        kind = "operation",
        name = tostring(action.label or "Operation") .. ": " .. tostring(record.name or record.fullType),
        search = tostring(action.label or "") .. " " .. tostring(record.name or "") .. " " .. tostring(record.fullType or "") .. " " .. tostring(action.source or "") .. " " .. tostring(action.actionType or ""),
        action = action,
        operation = action.operation,
        ingredient = record,
        fullType = record.fullType,
        textureName = record.textureName,
        resultType = action.operation and action.operation.outputs and action.operation.outputs[1] or nil,
        source = action.source,
        category = action.actionType or "food-operation",
        frozen = record.frozen,
        rotten = record.rotten,
        burnt = record.burnt,
    }
    opRecord.blocked = Operations.isBlockedByRecord and Operations.isBlockedByRecord(action.operation, record) or false
    return opRecord
end

function Index.availableForRecords(records, search)
    local list = {}
    local stats = {
        total = 0,
        blocked = 0,
        visible = 0,
        byType = {},
    }

    for _, record in ipairs(records or {}) do
        local opRecord = Index.recordForIngredient(record)
        if opRecord then
            stats.total = stats.total + 1
            stats.byType[opRecord.category] = (stats.byType[opRecord.category] or 0) + 1
            if opRecord.blocked then stats.blocked = stats.blocked + 1 end
            if hasText(opRecord.search, search) then
                list[#list + 1] = opRecord
                stats.visible = stats.visible + 1
            end
        end
    end

    table.sort(list, function(a, b)
        local left = tostring(a.source) .. tostring(a.name)
        local right = tostring(b.source) .. tostring(b.name)
        return left < right
    end)

    return list, stats
end

function Index.describeAction(action)
    if not action then return {} end
    return {
        tostring(action.label or "Food operation"),
        "Action type: " .. tostring(action.actionType or "food-operation"),
        "FFC shelf: " .. tostring(Branding.displaySource(action.source, "FFC Integrated Pantry")),
        "Input: " .. tostring(action.input or ""),
        "Output: " .. tostring(action.outputPreview or "unknown"),
        "Tool: " .. tostring(action.requiresTool or "none"),
        "Server authoritative: " .. tostring(action.serverAuthoritative == true),
        "Consumes one package use: " .. tostring(action.consumeUse == true),
        "Frozen allowed: " .. tostring(action.rejectFrozen ~= true),
    }
end

Index.build(true)

return Index
