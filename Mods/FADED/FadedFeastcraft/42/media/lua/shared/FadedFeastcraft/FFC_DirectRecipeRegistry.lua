require "FadedFeastcraft/FFC_Utils"
require "FadedFeastcraft/FFC_Branding"
require "FadedFeastcraft/FFC_Preservation"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.DirectRecipeRegistry = FadedFeastcraft.DirectRecipeRegistry or {}

local Registry = FadedFeastcraft.DirectRecipeRegistry
local Utils = FadedFeastcraft.Utils
local Branding = FadedFeastcraft.Branding
local Preservation = FadedFeastcraft.Preservation

Registry.cache = Registry.cache or { built = false, actions = {}, byId = {}, stats = {} }

local function itemTypeExists(fullType)
    if not fullType or fullType == "" then return false end
    if not getScriptManager then return true end
    local scriptManager = getScriptManager()
    if not scriptManager or not scriptManager.FindItem then return true end
    local ok, result = pcall(function() return scriptManager:FindItem(fullType) end)
    return ok and result ~= nil
end

local function textureFor(fullType)
    return Utils.getScriptItemTextureName and Utils.getScriptItemTextureName(Utils.getScriptItem(fullType)) or nil
end

local function expandedOutputs(outputs)
    local out = {}
    for _, entry in ipairs(outputs or {}) do
        local count = tonumber(entry.count) or 1
        for _ = 1, count do
            out[#out + 1] = entry.fullType
        end
    end
    return out
end

local function action(id, name, opts)
    opts = opts or {}
    local outputs = expandedOutputs(opts.outputs)
    local firstOutput = outputs[1] or (opts.outputs and opts.outputs[1] and opts.outputs[1].fullType) or nil
    return {
        id = id,
        name = name,
        kind = "directRecipeAction",
        family = opts.family or "prep",
        familyLabel = opts.familyLabel or "Direct",
        source = Branding.displaySource(opts.source or "FFC Core", "FFC Core"),
        requirements = opts.requirements or {},
        toolGroups = opts.toolGroups or {},
        outputs = outputs,
        outputSpecs = opts.outputs or {},
        resultType = firstOutput,
        textureName = textureFor(firstOutput),
        allowFrozen = opts.allowFrozen == true,
        allowRotten = opts.allowRotten == true,
        allowBurned = opts.allowBurned == true,
        inheritFoodAge = opts.inheritFoodAge == true,
        requiresPreservation = opts.requiresPreservation == true,
        search = Utils.lower(tostring(name) .. " " .. tostring(firstOutput or "") .. " " .. tostring(opts.familyLabel or "") .. " " .. tostring(opts.source or "")),
    }
end

local function add(cache, record)
    if not record or not record.id then return end
    if record.requiresPreservation and Preservation and Preservation.enabled and not Preservation.enabled() then return end
    for _, output in ipairs(record.outputs or {}) do
        if not itemTypeExists(output) then return end
    end
    cache.actions[#cache.actions + 1] = record
    cache.byId[record.id] = record
    cache.stats.total = cache.stats.total + 1
    cache.stats.byFamily[record.family] = (cache.stats.byFamily[record.family] or 0) + 1
end

local function addPackActions(cache)
    local map = {
        { "VFX.CannedHam", "VFX.CannedHam_Box", "Pack canned ham box" },
        { "VFX.CannedSalmon", "VFX.CannedSalmon_Box", "Pack canned salmon box" },
        { "VFX.CannedAnchovies", "VFX.CannedAnchovies_Box", "Pack canned anchovies box" },
        { "VFX.CannedCatFood", "VFX.CannedCatFood_Box", "Pack canned cat food box" },
        { "VFX.CannedChicken", "VFX.CannedChicken_Box", "Pack canned chicken box" },
    }
    for _, entry in ipairs(map) do
        add(cache, action("pack:" .. entry[1], entry[3], {
            family = "prep",
            familyLabel = "Packing",
            source = "FFC Expanded Pantry",
            requirements = { { fullTypes = { entry[1] }, count = 6 } },
            outputs = { { fullType = entry[2], count = 1 } },
        }))
    end
end

function Registry.build(force)
    if Registry.cache.built and not force then return Registry.cache end
    local cache = {
        built = true,
        actions = {},
        byId = {},
        stats = {
            total = 0,
            available = 0,
            blocked = 0,
            byFamily = {},
        },
    }

    add(cache, action("homestead:hamburger_bun_from_slice", "Make hamburger bun from bread slice", {
        family = "prep",
        familyLabel = "Prep",
        source = "FFC Homestead Recipes",
        requirements = { { fullTypes = { "Base.BreadSlices" }, count = 1 } },
        outputs = { { fullType = "Base.BunsHamburger_single", count = 1 } },
        inheritFoodAge = true,
    }))
    add(cache, action("homestead:hotdog_bun_from_slice", "Make hotdog bun from bread slice", {
        family = "prep",
        familyLabel = "Prep",
        source = "FFC Homestead Recipes",
        requirements = { { fullTypes = { "Base.BreadSlices" }, count = 1 } },
        outputs = { { fullType = "Base.BunsHotdog_single", count = 1 } },
        inheritFoodAge = true,
    }))
    add(cache, action("homestead:processed_cheese", "Slice processed cheese", {
        family = "prep",
        familyLabel = "Prep",
        source = "FFC Homestead Recipes",
        requirements = { { fullTypes = { "Base.Cheese" }, count = 1 } },
        toolGroups = { { group = "sharp", label = "Knife or cleaver" } },
        outputs = { { fullType = "Base.Processedcheese", count = 2 } },
        inheritFoodAge = true,
    }))
    add(cache, action("expanded:sliced_potato", "Slice potato", {
        family = "prep",
        familyLabel = "Prep",
        source = "FFC Expanded Pantry",
        requirements = { { fullTypes = { "Base.Potato" }, count = 1 } },
        toolGroups = { { group = "sharp", label = "Knife or cleaver" } },
        outputs = { { fullType = "VFX.SlicedPotato", count = 1 } },
        inheritFoodAge = true,
    }))
    add(cache, action("ffc:pack_field_meal", "Pack FFC field meal", {
        family = "preservation",
        familyLabel = "Packing",
        source = "FFC",
        requirements = { { fullTypes = { "FadedFeastcraft.FFC_SurvivalMeal" }, count = 1 } },
        outputs = { { fullType = "FadedFeastcraft.FFC_PackedMeal", count = 1 } },
        inheritFoodAge = true,
        requiresPreservation = true,
    }))
    add(cache, action("ffc:seal_preserved_ration", "Seal FFC preserved ration", {
        family = "preservation",
        familyLabel = "Preservation",
        source = "FFC",
        requirements = { { fullTypes = { "FadedFeastcraft.FFC_SurvivalMeal", "FadedFeastcraft.FFC_PackedMeal" }, count = 1 } },
        outputs = { { fullType = "FadedFeastcraft.FFC_PreservedRation", count = 1 } },
        inheritFoodAge = true,
        requiresPreservation = true,
    }))
    addPackActions(cache)

    table.sort(cache.actions, function(a, b)
        if a.family ~= b.family then return tostring(a.family) < tostring(b.family) end
        return tostring(a.name) < tostring(b.name)
    end)

    Registry.cache = cache
    return cache
end

function Registry.get(id)
    return Registry.build(false).byId[tostring(id or "")]
end

function Registry.getStats()
    return Registry.build(false).stats or {}
end

local function recordIsSafe(record, actionRecord)
    if not record then return false end
    if record.usable == false then return false end
    if record.frozen and not actionRecord.allowFrozen then return false end
    if record.rotten and not actionRecord.allowRotten then return false end
    if record.burnt and not actionRecord.allowBurned then return false end
    return true
end

local function countRequirement(records, requirement, actionRecord)
    local count = 0
    local typeSet = {}
    for _, fullType in ipairs(requirement.fullTypes or {}) do
        typeSet[fullType] = true
    end
    for _, record in ipairs(records or {}) do
        if typeSet[record.fullType] and recordIsSafe(record, actionRecord) then
            count = count + 1
        end
    end
    return count
end

local function availability(records, actionRecord)
    local reasons = {}
    for _, requirement in ipairs(actionRecord.requirements or {}) do
        local needed = tonumber(requirement.count) or 1
        local found = countRequirement(records, requirement, actionRecord)
        if found < needed then
            reasons[#reasons + 1] = "Needs " .. tostring(needed) .. "x " .. table.concat(requirement.fullTypes or {}, " or ")
        end
    end
    if #reasons == 0 then return true, nil end
    return false, table.concat(reasons, "; ")
end

function Registry.availableForRecords(records, search, familyFilter)
    local out = {}
    local stats = { total = 0, available = 0, blocked = 0 }
    local filter = tostring(familyFilter or "all")
    for _, actionRecord in ipairs(Registry.build(false).actions or {}) do
        if filter == "all" or actionRecord.family == filter then
            local ok, reason = availability(records, actionRecord)
            local searchText = tostring(actionRecord.search or "") .. " " .. tostring(reason or "")
            if Utils.containsText(searchText, search) then
                local row = {}
                for key, value in pairs(actionRecord) do row[key] = value end
                row.blocked = not ok
                row.blockedReason = reason
                row.search = searchText
                out[#out + 1] = row
                stats.total = stats.total + 1
                if ok then stats.available = stats.available + 1 else stats.blocked = stats.blocked + 1 end
            end
        end
    end
    return out, stats
end

function Registry.outputPreview(actionRecord)
    local parts = {}
    local counts = {}
    local order = {}
    for _, output in ipairs(actionRecord and actionRecord.outputs or {}) do
        if not counts[output] then
            counts[output] = 0
            order[#order + 1] = output
        end
        counts[output] = counts[output] + 1
    end
    for _, output in ipairs(order) do
        local count = counts[output] or 1
        parts[#parts + 1] = count > 1 and (tostring(count) .. "x " .. output) or output
    end
    return table.concat(parts, ", ")
end

Registry.build(true)

return Registry
