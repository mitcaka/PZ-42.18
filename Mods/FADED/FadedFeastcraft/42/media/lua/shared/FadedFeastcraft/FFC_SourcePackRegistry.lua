require "FadedFeastcraft/FFC_Config"
require "FadedFeastcraft/FFC_Utils"
require "FadedFeastcraft/FFC_Branding"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.SourcePackRegistry = FadedFeastcraft.SourcePackRegistry or {}

local Registry = FadedFeastcraft.SourcePackRegistry
local Utils = FadedFeastcraft.Utils
local Branding = FadedFeastcraft.Branding

Registry.PACKS = Registry.PACKS or {
    {
        id = "FFC",
        label = "FFC",
        workshopId = "local",
        modIds = { "FadedFeastcraft" },
        prefixes = { "FadedFeastcraft." },
        status = "native",
        embedded = true,
        scripts = 2,
        textures = 0,
        models = 0,
        translations = 2,
        notes = "Native GUI, scanner, meal planner, and server crafting validation.",
    },
    {
        id = "VFX",
        label = "FFC Expanded Pantry",
        workshopId = "3577903007",
        modIds = { "VanillaFoodsExpanded" },
        prefixes = { "VFX." },
        status = "embedded-content",
        embedded = true,
        scripts = 30,
        textures = 2834,
        models = 183,
        translations = 6,
        notes = "Expanded pantry items, recipes, distributions, animal parts, and recipe extensions are embedded under FFC.",
    },
    {
        id = "AbuelitaLinda",
        label = "FFC Cocina Pantry",
        workshopId = "3622474939",
        modIds = { "AbuelitaLinda" },
        prefixes = { "AbuelitaLinda." },
        status = "embedded-content",
        embedded = true,
        scripts = 28,
        textures = 783,
        models = 148,
        translations = 3,
        notes = "Cocina-style food items, appliances/workstations, recipes, models, textures, and distributions are embedded under FFC.",
    },
    {
        id = "TedFoodPack",
        label = "FFC Snack Shelf",
        workshopId = "3717223708",
        modIds = { "TedFoodPack" },
        prefixes = { "Ted." },
        status = "embedded-content",
        embedded = true,
        scripts = 5,
        textures = 134,
        models = 0,
        translations = 2,
        notes = "Burgers, snacks, drinks, canned foods, recipes, fluids, and procedural distributions are embedded under FFC.",
    },
    {
        id = "SnackTime89",
        label = "FFC Snack Shelf",
        workshopId = "3589560764",
        modIds = { "SnackTime89" },
        prefixes = { "SnackTime89." },
        status = "embedded-content",
        embedded = true,
        scripts = 7,
        textures = 123,
        models = 123,
        translations = 5,
        notes = "Snack/drink items, server loot, mystery-box data, and MP-safe unpack handlers are embedded; legacy client context menus are intentionally not imported.",
    },
    {
        id = "MREfood",
        label = "FFC Field Rations",
        workshopId = "3488617262",
        modIds = { "MREfood4213" },
        prefixes = { "MR." },
        status = "embedded-content",
        embedded = true,
        scripts = 4,
        textures = 208,
        models = 89,
        translations = 12,
        notes = "Field rations, drinks, recipes, fluids, distributions, and special loot naming data are embedded under FFC.",
    },
    {
        id = "EGNHInuman",
        label = "FFC Beverage Cellar",
        workshopId = "2673329292",
        modIds = { "EGNHInuman" },
        prefixes = {},
        hints = { "brandyemperador", "ginginebra", "pilsen", "redhorse", "soju", "tequilacuervo" },
        status = "embedded-content",
        embedded = true,
        scripts = 3,
        textures = 17,
        models = 5,
        translations = 0,
        notes = "Beverage items, fluids, models, textures, and loot distributions are embedded under FFC.",
    },
    {
        id = "AdvancedDrying",
        label = "FFC Preservation Bench",
        workshopId = "3687773661",
        modIds = { "MeatDrying" },
        prefixes = { "AdvancedDrying42." },
        status = "embedded-content",
        embedded = true,
        scripts = 2,
        textures = 12,
        models = 0,
        translations = 3,
        notes = "Salting, drying, tracked nutrition callbacks, and MP sync helpers are embedded under FFC.",
    },
    {
        id = "SkbDriedFood",
        label = "FFC Dry Storage",
        workshopId = "3635697728",
        modIds = { "SkbDriedFood[42.13]" },
        prefixes = { "DriedFoodMod." },
        status = "embedded-content",
        embedded = true,
        scripts = 4,
        textures = 5,
        models = 0,
        translations = 4,
        notes = "Dried-food items, recipes, recipe callbacks, and loot distribution are embedded under FFC.",
    },
    {
        id = "PackPantry",
        label = "FFC Canning Bench",
        workshopId = "3416584592",
        modIds = { "PackPantry" },
        prefixes = { "ExtraCraft." },
        hints = { "tinsealer", "pp-", "cannedcarrots", "cannedtomatos", "cannedpotatos" },
        status = "embedded-content",
        embedded = true,
        scripts = 5,
        textures = 2,
        models = 1,
        translations = 0,
        notes = "Can sealer, canned-food items, preservation recipes, and distribution are embedded under FFC.",
    },
    {
        id = "EliazCanning",
        label = "FFC Jarred Pantry",
        workshopId = "3425502668",
        modIds = { "EliazBetterCanningJarredFoodB42" },
        prefixes = {},
        hints = { "better canning", "makecanned", "opencanned", "canof" },
        status = "embedded-content",
        embedded = true,
        scripts = 1,
        textures = 0,
        models = 0,
        translations = 1,
        notes = "Vegetable canning items and recipes are embedded under FFC.",
    },
    {
        id = "MergeCanned",
        label = "FFC Can Consolidation",
        workshopId = "3593308510",
        modIds = { "AR_Merge_Canned_42" },
        prefixes = {},
        hints = { "ar.merge", "mergeopenedcan", "merge canned" },
        status = "embedded-content",
        embedded = true,
        scripts = 1,
        textures = 0,
        models = 0,
        translations = 0,
        notes = "Opened-can merge recipe and nutrition merge callback are embedded under FFC.",
    },
    {
        id = "CraftableVanillaFood",
        label = "FFC Homestead Recipes",
        workshopId = "3714174568",
        modIds = { "CraftableVanillaFoodItems" },
        prefixes = {},
        hints = { "makecheese", "makeicecream", "makegroundbeef", "maketortilla", "makehomemadepancake" },
        status = "embedded-content",
        embedded = true,
        scripts = 1,
        textures = 0,
        models = 0,
        translations = 1,
        notes = "Homestead food crafting recipes are embedded under FFC.",
    },
    {
        id = "EveryMissingFoodModels",
        label = "FFC Food Visuals",
        workshopId = "3322066592",
        modIds = { "AatheomEMVFSM" },
        prefixes = { "AEMVFSM." },
        status = "embedded-assets",
        embedded = true,
        scripts = 2,
        textures = 0,
        models = 40,
        translations = 0,
        notes = "Static model definitions and models are embedded for better FFC food visuals.",
    },
    {
        id = "WildFruits",
        label = "FFC Foraged Fruit",
        workshopId = "2618566294",
        modIds = { "MattSimpleAddonsFriuts" },
        prefixes = { "MattSimpleAddons." },
        hints = { "msablack", "msaraspberries", "msamulberry", "msawild" },
        status = "embedded-content",
        embedded = true,
        scripts = 1,
        textures = 7,
        models = 0,
        translations = 0,
        notes = "Foraged fruit items, textures, and defensive forage definitions are embedded under FFC.",
    },
    {
        id = "CSR",
        label = "CSR Ecosystem",
        workshopId = "3698958906",
        modIds = {
            "CommonSenseReborn",
            "CommonSenseRebornB42",
            "CommonSenseReborn_B42",
            "CommonSenseRebornTest",
            "CommonSenseReborn_Test",
            "CommonSenseRebornTestB42",
            "CommonSenseReborn_Test_B42",
            "CommonSenseRebornB42Test",
            "CommonSenseRebornB42_Test",
            "CSRTest",
            "CSR_Test",
            "CSRTestB42",
            "CSR_Test_B42",
        },
        prefixes = { "Base.CSR_" },
        status = "optional-ecosystem",
        embedded = false,
        scripts = 0,
        textures = 0,
        models = 0,
        translations = 0,
        notes = "Detected defensively. FFC uses CSR helpers when present and does not override CSR.",
    },
    {
        id = "FoodExpirationDate",
        label = "FFC Expiry Toolkit",
        workshopId = "3720209890 / 3721170507",
        modIds = { "foodAll_v1", "FoodExpirationDate" },
        prefixes = {},
        status = "reference-hook",
        embedded = false,
        scripts = 0,
        textures = 0,
        models = 0,
        translations = 0,
        notes = "Reference for expiry UX; FFC uses its own defensive freshness panel and CSR when available.",
    },
    {
        id = "NutritionReferences",
        label = "FFC Nutrition Toolkit",
        workshopId = "3492090092 / 3690404044",
        modIds = { "twistcalories", "NutritionMakesSense" },
        prefixes = {},
        status = "reference-hook",
        embedded = false,
        scripts = 0,
        textures = 0,
        models = 0,
        translations = 0,
        notes = "Nutrition balance references for later advanced nutrition. Not embedded as hard dependencies.",
    },
    {
        id = "ColdStorageReferences",
        label = "FFC Cold Storage Toolkit",
        workshopId = "3688375772",
        modIds = { "CoolerPlus" },
        prefixes = {},
        status = "reference-hook",
        embedded = false,
        scripts = 0,
        textures = 0,
        models = 0,
        translations = 0,
        notes = "Cold-storage reference for future storage tab. FFC keeps this logic isolated.",
    },
    {
        id = "AllergyTraits",
        label = "FFC Trait Safety Toolkit",
        workshopId = "3414814170",
        modIds = { "TCAllergyTraits" },
        prefixes = {},
        status = "reference-hook",
        embedded = false,
        scripts = 0,
        textures = 0,
        models = 0,
        translations = 0,
        notes = "Trait penalty reference. Not embedded because this feature family requires an external dependency.",
    },
}

local function lower(value)
    return Utils.lower(tostring(value or ""))
end

local function sourceMatches(fullType, pack)
    if not fullType or not pack then return false end
    for _, prefix in ipairs(pack.prefixes or {}) do
        if string.sub(fullType, 1, #prefix) == prefix then
            return true
        end
    end
    return false
end

function Registry.getPacks()
    return Registry.PACKS
end

function Registry.countEmbedded()
    local count = 0
    for _, pack in ipairs(Registry.PACKS) do
        if pack.embedded == true then
            count = count + 1
        end
    end
    return count
end

function Registry.getAssetTotals()
    local totals = { scripts = 0, textures = 0, models = 0, translations = 0 }
    for _, pack in ipairs(Registry.PACKS) do
        if pack.embedded == true then
            totals.scripts = totals.scripts + (tonumber(pack.scripts) or 0)
            totals.textures = totals.textures + (tonumber(pack.textures) or 0)
            totals.models = totals.models + (tonumber(pack.models) or 0)
            totals.translations = totals.translations + (tonumber(pack.translations) or 0)
        end
    end
    return totals
end

function Registry.sourceForFullType(fullType)
    fullType = tostring(fullType or "")
    for _, pack in ipairs(Registry.PACKS) do
        if sourceMatches(fullType, pack) then
            return Branding.displaySource(pack.label, "FFC Integrated Pantry")
        end
    end

    local probe = lower(fullType)
    for _, pack in ipairs(Registry.PACKS) do
        for _, hint in ipairs(pack.hints or {}) do
            if string.find(probe, lower(hint), 1, true) then
                return Branding.displaySource(pack.label, "FFC Integrated Pantry")
            end
        end
    end

    return nil
end

function Registry.sourceForProbe(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring(select(i, ...) or "")
    end
    local probe = lower(table.concat(parts, " "))

    for _, pack in ipairs(Registry.PACKS) do
        for _, prefix in ipairs(pack.prefixes or {}) do
            local bare = string.gsub(prefix, "%.$", "")
            if bare ~= "" and string.find(probe, lower(bare), 1, true) then
                return Branding.displaySource(pack.label, "FFC Integrated Pantry")
            end
        end
        for _, hint in ipairs(pack.hints or {}) do
            if string.find(probe, lower(hint), 1, true) then
                return Branding.displaySource(pack.label, "FFC Integrated Pantry")
            end
        end
        for _, modId in ipairs(pack.modIds or {}) do
            if string.find(probe, lower(modId), 1, true) then
                return Branding.displaySource(pack.label, "FFC Integrated Pantry")
            end
        end
    end

    return nil
end

function Registry.statusLine(pack)
    if not pack then return "" end
    local mode = pack.embedded and "embedded" or tostring(pack.status or "reference")
    return tostring(Branding.displaySource(pack.label, "FFC Integrated Pantry")) .. " - " .. mode
end

return Registry
