require "CSR_FeatureFlags"

CSR_MaterialBundles = CSR_MaterialBundles or {}

local MODULE = CSR_MaterialBundles
local MODDATA_KEY = "CSR_MaterialBundle"
local VERSION = 1

-- Material bundle feature inspired by DJG Bound Materials by JD. Valentine / JasonDGian.
local ROPE_TYPES = {
    ["Base.Rope"] = true,
    ["Base.SheetRope"] = true,
}

local DEFINITIONS = {
    Planks5 = { result = "Base.CSR_BoundPlanks5", contents = { { type = "Base.Plank", count = 5 } } },
    Planks10 = { result = "Base.CSR_BoundPlanks10", contents = { { type = "Base.Plank", count = 10 } } },
    Planks20 = { result = "Base.CSR_BoundPlanks20", contents = { { type = "Base.Plank", count = 20 } } },

    SheetMetal5 = { result = "Base.CSR_BoundSheetMetal5", contents = { { type = "Base.SheetMetal", count = 5 } } },
    SheetMetal10 = { result = "Base.CSR_BoundSheetMetal10", contents = { { type = "Base.SheetMetal", count = 10 } } },
    SheetMetal20 = { result = "Base.CSR_BoundSheetMetal20", contents = { { type = "Base.SheetMetal", count = 20 } } },

    SmallSheetMetal5 = { result = "Base.CSR_BoundSmallSheetMetal5", contents = { { type = "Base.SmallSheetMetal", count = 5 } } },
    SmallSheetMetal10 = { result = "Base.CSR_BoundSmallSheetMetal10", contents = { { type = "Base.SmallSheetMetal", count = 10 } } },
    SmallSheetMetal20 = { result = "Base.CSR_BoundSmallSheetMetal20", contents = { { type = "Base.SmallSheetMetal", count = 20 } } },

    LeadPipes5 = { result = "Base.CSR_BoundLeadPipes5", contents = { { type = "Base.LeadPipe", count = 5 } } },
    LeadPipes10 = { result = "Base.CSR_BoundLeadPipes10", contents = { { type = "Base.LeadPipe", count = 10 } } },
    LeadPipes20 = { result = "Base.CSR_BoundLeadPipes20", contents = { { type = "Base.LeadPipe", count = 20 } } },

    MetalPipes5 = { result = "Base.CSR_BoundMetalPipes5", contents = { { type = "Base.MetalPipe", count = 5 } } },
    MetalPipes10 = { result = "Base.CSR_BoundMetalPipes10", contents = { { type = "Base.MetalPipe", count = 10 } } },
    MetalPipes20 = { result = "Base.CSR_BoundMetalPipes20", contents = { { type = "Base.MetalPipe", count = 20 } } },

    MetalBars5 = { result = "Base.CSR_BoundMetalBars5", contents = { { type = "Base.MetalBar", count = 5 } } },
    MetalBars10 = { result = "Base.CSR_BoundMetalBars10", contents = { { type = "Base.MetalBar", count = 10 } } },
    MetalBars20 = { result = "Base.CSR_BoundMetalBars20", contents = { { type = "Base.MetalBar", count = 20 } } },

    TreeBranches5 = { result = "Base.CSR_BoundTreeBranches5", contents = { { type = "Base.TreeBranch2", count = 5 } } },
    TreeBranches10 = { result = "Base.CSR_BoundTreeBranches10", contents = { { type = "Base.TreeBranch2", count = 10 } } },
    TreeBranches20 = { result = "Base.CSR_BoundTreeBranches20", contents = { { type = "Base.TreeBranch2", count = 20 } } },

    WoodenSticks5 = { result = "Base.CSR_BoundWoodenSticks5", contents = { { type = "Base.WoodenStick2", count = 5 } } },
    WoodenSticks10 = { result = "Base.CSR_BoundWoodenSticks10", contents = { { type = "Base.WoodenStick2", count = 10 } } },
    WoodenSticks20 = { result = "Base.CSR_BoundWoodenSticks20", contents = { { type = "Base.WoodenStick2", count = 20 } } },

    MixedConstruction = {
        result = "Base.CSR_MixedConstructionBundle",
        contents = {
            { type = "Base.Plank", count = 5 },
            { type = "Base.MetalPipe", count = 2 },
            { type = "Base.MetalBar", count = 2 },
            { type = "Base.SheetMetal", count = 2 },
            { type = "Base.SmallSheetMetal", count = 4 },
        },
    },
}

MODULE.DEFINITIONS = DEFINITIONS

local function isFeatureEnabled()
    if CSR_FeatureFlags and CSR_FeatureFlags.isMaterialBundlesEnabled then
        return CSR_FeatureFlags.isMaterialBundlesEnabled()
    end
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    return sb.EnableMaterialBundles ~= false
end

function MODULE.onTestEnabled(item, result)
    return isFeatureEnabled()
end

local function getListSize(items)
    return items and items.size and items:size() or 0
end

local function listGet(items, index)
    return items and items.get and items:get(index) or nil
end

local function getCreatedItem(craftRecipeData, fullType)
    local created = craftRecipeData and craftRecipeData.getAllCreatedItems and craftRecipeData:getAllCreatedItems() or nil
    for i = 0, getListSize(created) - 1 do
        local item = listGet(created, i)
        if item and item.getFullType and (not fullType or item:getFullType() == fullType) then
            return item
        end
    end
    return nil
end

local function syncItem(item)
    if not item then return end
    if item.transmitModData then item:transmitModData() end
    local container = item.getContainer and item:getContainer() or nil
    if container and sendReplaceItemInContainer then
        sendReplaceItemInContainer(container, item, item)
    elseif sendItemStats then
        sendItemStats(item)
    end
end

local function addInventoryItem(character, fullType)
    if not character or not character.getInventory or not fullType then
        return nil
    end
    local inv = character:getInventory()
    if not inv or not inv.AddItem then
        return nil
    end
    local item = inv:AddItem(fullType)
    if item and sendAddItemToContainer then
        sendAddItemToContainer(inv, item)
    end
    return item
end

local function storeCondition(item)
    if not item or not item.getFullType then
        return nil
    end
    local entry = { type = item:getFullType() }
    if item.getCondition then
        entry.condition = item:getCondition()
    end
    if item.getConditionMax then
        entry.conditionMax = item:getConditionMax()
    end
    return entry
end

local function applyCondition(item, entry)
    if not item or not entry or entry.condition == nil or not item.setCondition then
        return
    end
    local maxCondition = entry.conditionMax
    if item.getConditionMax then
        maxCondition = item:getConditionMax()
    end
    if maxCondition and maxCondition > 0 then
        item:setCondition(math.max(0, math.min(maxCondition, entry.condition)))
    else
        item:setCondition(math.max(0, entry.condition))
    end
end

local function buildExpectedTypes(def)
    local expected = {}
    if not def or not def.contents then return expected end
    for _, entry in ipairs(def.contents) do
        expected[entry.type] = (expected[entry.type] or 0) + (entry.count or 0)
    end
    return expected
end

local function collectBundleData(def, consumed)
    local expected = buildExpectedTypes(def)
    local contents = {}
    local ropes = {}

    for i = 0, getListSize(consumed) - 1 do
        local item = listGet(consumed, i)
        local fullType = item and item.getFullType and item:getFullType() or nil
        if fullType and ROPE_TYPES[fullType] then
            ropes[#ropes + 1] = fullType
        elseif fullType and expected[fullType] and expected[fullType] > 0 then
            contents[#contents + 1] = storeCondition(item)
            expected[fullType] = expected[fullType] - 1
        end
    end

    return contents, ropes
end

local function restoreCreatedConditions(craftRecipeData, contents)
    local created = craftRecipeData and craftRecipeData.getAllCreatedItems and craftRecipeData:getAllCreatedItems() or nil
    if not created or not contents then
        return
    end

    local byType = {}
    for _, entry in ipairs(contents) do
        if entry and entry.type then
            byType[entry.type] = byType[entry.type] or {}
            byType[entry.type][#byType[entry.type] + 1] = entry
        end
    end

    for i = 0, getListSize(created) - 1 do
        local item = listGet(created, i)
        local fullType = item and item.getFullType and item:getFullType() or nil
        local entries = fullType and byType[fullType] or nil
        if entries and #entries > 0 then
            local entry = table.remove(entries, 1)
            applyCondition(item, entry)
            syncItem(item)
        end
    end
end

local function getConsumedBundle(craftRecipeData)
    local consumed = craftRecipeData and craftRecipeData.getAllConsumedItems and craftRecipeData:getAllConsumedItems() or nil
    for i = 0, getListSize(consumed) - 1 do
        local item = listGet(consumed, i)
        local data = item and item.getModData and item:getModData() or nil
        if data and data[MODDATA_KEY] then
            return item, data[MODDATA_KEY]
        end
    end
    return listGet(consumed, 0), nil
end

function MODULE.bundle(defKey, craftRecipeData, character)
    local def = DEFINITIONS[defKey]
    if not def then return end

    local bundle = getCreatedItem(craftRecipeData, def.result)
    if not bundle or not bundle.getModData then
        return
    end

    local consumed = craftRecipeData and craftRecipeData.getAllConsumedItems and craftRecipeData:getAllConsumedItems() or nil
    local contents, ropes = collectBundleData(def, consumed)
    local data = bundle:getModData()
    data[MODDATA_KEY] = {
        version = VERSION,
        key = defKey,
        contents = contents,
        ropes = ropes,
    }
    syncItem(bundle)
end

function MODULE.unbundle(defKey, craftRecipeData, character)
    local def = DEFINITIONS[defKey]
    if not def then return end

    local bundle, bundleData = getConsumedBundle(craftRecipeData)
    if not bundleData and bundle and bundle.getModData then
        bundleData = bundle:getModData()[MODDATA_KEY]
    end

    if bundleData and bundleData.contents then
        restoreCreatedConditions(craftRecipeData, bundleData.contents)
    end

    local ropes = bundleData and bundleData.ropes or nil
    if ropes and #ropes > 0 then
        for _, ropeType in ipairs(ropes) do
            if ROPE_TYPES[ropeType] then
                addInventoryItem(character, ropeType)
            end
        end
    else
        addInventoryItem(character, "Base.Rope")
    end
end

local function makeBundleCallback(defKey)
    return function(craftRecipeData, character)
        return MODULE.bundle(defKey, craftRecipeData, character)
    end
end

local function makeUnbundleCallback(defKey)
    return function(craftRecipeData, character)
        return MODULE.unbundle(defKey, craftRecipeData, character)
    end
end

for key, _ in pairs(DEFINITIONS) do
    MODULE["onBundle" .. key] = makeBundleCallback(key)
    MODULE["onUnbundle" .. key] = makeUnbundleCallback(key)
end

return MODULE
