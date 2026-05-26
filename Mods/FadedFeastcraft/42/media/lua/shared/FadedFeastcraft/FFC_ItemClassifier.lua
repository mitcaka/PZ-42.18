require "FadedFeastcraft/FFC_Config"
require "FadedFeastcraft/FFC_Utils"
require "FadedFeastcraft/FFC_Branding"
require "FadedFeastcraft/FFC_SourcePackRegistry"
require "FadedFeastcraft/FFC_CSRIntegration"
require "FadedFeastcraft/FFC_MealEffects"
require "FadedFeastcraft/FFC_Preservation"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.ItemClassifier = FadedFeastcraft.ItemClassifier or {}

local Classifier = FadedFeastcraft.ItemClassifier
local Utils = FadedFeastcraft.Utils
local Branding = FadedFeastcraft.Branding
local Config = FadedFeastcraft.Config
local CSR = FadedFeastcraft.CSR
local SourcePacks = FadedFeastcraft.SourcePackRegistry
local MealEffects = FadedFeastcraft.MealEffects
local Preservation = FadedFeastcraft.Preservation

local function sourceFor(fullType)
    local source = SourcePacks and SourcePacks.sourceForFullType and SourcePacks.sourceForFullType(fullType)
    if source then return Branding.displaySource(source, "FFC Integrated Pantry") end
    for prefix, sourceLabel in pairs(Config.SOURCE_PREFIXES) do
        if string.sub(fullType, 1, #prefix) == prefix then
            return Branding.displaySource(sourceLabel, "FFC Integrated Pantry")
        end
    end
    return "FFC Integrated Pantry"
end

local function hasWord(text, word)
    return string.find(Utils.lower(text), Utils.lower(word), 1, true) ~= nil
end

local function categoryFor(item, fullType, name)
    local foodType = Utils.safeCall(item, "getFoodType")
    local script = Utils.safeCall(item, "getScriptItem")
    if not foodType and script then foodType = Utils.safeCall(script, "getFoodType") end
    local ft = Utils.lower(foodType or "")
    local probe = Utils.lower(fullType .. " " .. name .. " " .. tostring(foodType or ""))

    if hasWord(probe, "meat") or hasWord(probe, "beef") or hasWord(probe, "pork") or hasWord(probe, "steak") then return "Meat" end
    if hasWord(probe, "fish") or hasWord(probe, "seafood") or hasWord(probe, "shrimp") then return "Fish / Seafood" end
    if hasWord(ft, "vegetable") or hasWord(probe, "vegetable") or hasWord(probe, "carrot") or hasWord(probe, "potato") then return "Vegetables" end
    if hasWord(ft, "fruit") or hasWord(probe, "fruit") or hasWord(probe, "apple") or hasWord(probe, "berry") then return "Fruit" end
    if hasWord(probe, "canned") or hasWord(probe, "tin") or hasWord(probe, "ration") then return "Canned / Rations" end
    if hasWord(probe, "spice") or (item.isSpice and item:isSpice()) then return "Spices" end
    if hasWord(probe, "drink") or hasWord(probe, "water") or hasWord(probe, "beer") or hasWord(probe, "wine") then return "Drinks" end
    if hasWord(probe, "dried") or hasWord(probe, "salted") or hasWord(probe, "jerky") then return "Preserved" end
    if hasWord(probe, "mushroom") or hasWord(probe, "wild") or hasWord(probe, "forage") then return "Foraged" end
    return "Other Food"
end

function Classifier.classify(item, container, origin)
    if not Utils.isFood(item) then return nil end

    local fullType = Utils.getFullType(item)
    local name = Utils.getDisplayName(item)
    local nutrition = Utils.getNutrition(item)
    local exp = CSR.getFoodExpiry(item)
    local dangerousRaw = false
    if item.isbDangerousUncooked and item:isbDangerousUncooked() then dangerousRaw = true end
    if item.isDangerousUncooked and item:isDangerousUncooked() then dangerousRaw = true end

    local record = {
        id = item.getID and item:getID() or nil,
        item = item,
        fullType = fullType,
        name = name,
        search = Utils.lower(fullType .. " " .. name),
        textureName = Utils.getItemTextureName(item),
        source = sourceFor(fullType),
        category = categoryFor(item, fullType, name),
        origin = origin or "Inventory",
        containerType = container and container.getType and container:getType() or "",
        hunger = nutrition.hunger,
        calories = nutrition.calories,
        proteins = nutrition.proteins,
        lipids = nutrition.lipids,
        carbohydrates = nutrition.carbohydrates,
        boredom = nutrition.boredom,
        unhappy = nutrition.unhappy,
        frozen = item.isFrozen and item:isFrozen() == true or false,
        rotten = item.isRotten and item:isRotten() == true or false,
        cooked = item.isCooked and item:isCooked() == true or false,
        burnt = item.isBurnt and item:isBurnt() == true or false,
        spice = item.isSpice and item:isSpice() == true or false,
        dangerousRaw = dangerousRaw,
        freshness = CSR.getFreshnessInsight(item),
        expiry = exp,
    }

    local preservation = Preservation and Preservation.readItem and Preservation.readItem(item) or nil
    if preservation then
        record.preservation = preservation
        record.search = record.search .. " " .. Utils.lower(tostring(preservation.method or "") .. " " .. tostring(preservation.label or "") .. " preserved pantry shelf")
        record.category = "Preserved"
    end

    local effectData, effectSpec = nil, nil
    if MealEffects and MealEffects.readMealEffect then
        effectData, effectSpec = MealEffects.readMealEffect(item)
    end
    if effectData and effectSpec then
        record.effectTag = effectData.tag
        record.effectName = effectSpec.name
        record.effectDesc = effectSpec.desc
        record.cookName = effectData.cookName
        record.cookLevel = effectData.cookLevel
        record.search = record.search .. " " .. Utils.lower(tostring(effectData.tag or "") .. " " .. tostring(effectSpec.name or ""))
    end

    record.usable = not record.rotten and not record.burnt and not CSR.isFrozenBlocked(item, nil)
    if record.dangerousRaw and not record.cooked then record.usable = false end
    return record
end

return Classifier
