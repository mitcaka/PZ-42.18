require "FadedFeastcraft/FFC_Config"
require "FadedFeastcraft/FFC_Utils"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.MealEffects = FadedFeastcraft.MealEffects or {}

local Effects = FadedFeastcraft.MealEffects
local Utils = FadedFeastcraft.Utils

Effects.MODDATA_KEY = "FFC_MealEffect"
Effects.ACTIVE_KEY = "FFC_MealEffectsActive"

Effects.SLOT_ORDER = { "Hearty", "Filling", "Fresh", "Sweet" }

Effects.SPECS = {
    Hearty = {
        tag = "Hearty",
        name = "Hearty Meal",
        desc = "Protein-rich food that helps fight fatigue and keeps you moving.",
        texture = "media/textures/UI/ffc_effect_hearty.png",
        components = {
            { stat = "FATIGUE", base = -0.00055 },
            { stat = "ENDURANCE", base = 0.00075 },
            { stat = "UNHAPPINESS", base = -0.0030 },
        },
    },
    Filling = {
        tag = "Filling",
        name = "Filling Meal",
        desc = "Starch-heavy food that helps hold hunger back.",
        texture = "media/textures/UI/ffc_effect_filling.png",
        components = {
            { stat = "HUNGER", base = -0.00025 },
            { stat = "FATIGUE", base = -0.00025 },
            { stat = "BOREDOM", base = -0.0030 },
        },
    },
    Fresh = {
        tag = "Fresh",
        name = "Fresh Meal",
        desc = "Fruit and vegetable-forward food that calms and refreshes.",
        texture = "media/textures/UI/ffc_effect_fresh.png",
        components = {
            { stat = "THIRST", base = -0.00025 },
            { stat = "STRESS", base = -0.00055 },
            { stat = "HEALTH", base = 0.018 },
        },
    },
    Sweet = {
        tag = "Sweet",
        name = "Sweet Treat",
        desc = "Comfort food that lifts mood and cuts boredom.",
        texture = "media/textures/UI/ffc_effect_sweet.png",
        components = {
            { stat = "STRESS", base = -0.00065 },
            { stat = "BOREDOM", base = -0.0060 },
            { stat = "UNHAPPINESS", base = -0.0060 },
        },
    },
}

local STAT_LABELS = {
    FATIGUE = "Reduces tiredness",
    ENDURANCE = "Restores stamina",
    HUNGER = "Reduces hunger",
    THIRST = "Reduces thirst",
    STRESS = "Reduces stress",
    BOREDOM = "Reduces boredom",
    UNHAPPINESS = "Lifts mood",
    HEALTH = "Heals minor wear",
}

local function hasAny(text, tokens)
    text = Utils.lower(text)
    for _, token in ipairs(tokens or {}) do
        if string.find(text, Utils.lower(token), 1, true) then return true end
    end
    return false
end

local function foodProbe(itemOrRecord)
    if not itemOrRecord then return "" end
    local fullType = itemOrRecord.fullType or Utils.getFullType(itemOrRecord)
    local name = itemOrRecord.name or Utils.getDisplayName(itemOrRecord)
    local category = itemOrRecord.category or ""
    local foodType = ""
    if itemOrRecord.getFoodType then
        foodType = Utils.safeCall(itemOrRecord, "getFoodType") or ""
    end
    local script = itemOrRecord.getScriptItem and Utils.safeCall(itemOrRecord, "getScriptItem") or nil
    if foodType == "" and script then
        foodType = Utils.safeCall(script, "getFoodType") or ""
    end
    return Utils.lower(tostring(fullType or "") .. " " .. tostring(name or "") .. " " .. tostring(category or "") .. " " .. tostring(foodType or ""))
end

local function nutrition(itemOrRecord)
    if not itemOrRecord then return {} end
    if itemOrRecord.calories or itemOrRecord.proteins or itemOrRecord.carbohydrates then
        return {
            calories = tonumber(itemOrRecord.calories) or 0,
            proteins = tonumber(itemOrRecord.proteins) or 0,
            lipids = tonumber(itemOrRecord.lipids) or 0,
            carbohydrates = tonumber(itemOrRecord.carbohydrates) or 0,
        }
    end
    return Utils.getNutrition(itemOrRecord)
end

local function addScores(scores, itemOrRecord)
    local n = nutrition(itemOrRecord)
    local probe = foodProbe(itemOrRecord)
    local calories = tonumber(n.calories) or 0
    local proteins = tonumber(n.proteins) or 0
    local lipids = tonumber(n.lipids) or 0
    local carbs = tonumber(n.carbohydrates) or 0

    scores.Hearty = scores.Hearty + proteins * 2.0 + lipids * 0.25
    scores.Filling = scores.Filling + carbs * 1.4 + math.min(calories, 1200) * 0.035
    scores.Fresh = scores.Fresh + math.max(0, 260 - math.min(calories, 260)) * 0.02
    scores.Sweet = scores.Sweet + math.max(0, carbs - proteins) * 0.45

    if hasAny(probe, { "meat", "beef", "pork", "steak", "chicken", "mutton", "venison", "rabbit", "bacon", "sausage", "fish", "seafood", "shrimp", "lobster", "egg" }) then
        scores.Hearty = scores.Hearty + 45
    end
    if hasAny(probe, { "rice", "pasta", "bread", "noodle", "ramen", "potato", "burrito", "sandwich", "pizza", "taco", "cereal", "oatmeal", "flour" }) then
        scores.Filling = scores.Filling + 45
    end
    if hasAny(probe, { "vegetable", "fruit", "fresh", "salad", "soup", "stew", "apple", "berry", "tomato", "carrot", "cabbage", "leek", "mushroom", "forage" }) then
        scores.Fresh = scores.Fresh + 45
    end
    if hasAny(probe, { "sweet", "cake", "pie", "chocolate", "candy", "cookie", "waffle", "pancake", "dessert", "sugar", "honey", "syrup", "jam", "jelly" }) then
        scores.Sweet = scores.Sweet + 55
    end
end

function Effects.specForTag(tag)
    return Effects.SPECS[tostring(tag or "")]
end

function Effects.bestTagForItems(items)
    local scores = { Hearty = 0, Filling = 0, Fresh = 0, Sweet = 0 }
    for _, item in ipairs(items or {}) do
        addScores(scores, item)
    end

    local bestTag = "Filling"
    local bestScore = -999999
    for _, tag in ipairs(Effects.SLOT_ORDER) do
        if scores[tag] > bestScore then
            bestTag = tag
            bestScore = scores[tag]
        end
    end
    return bestTag, scores
end

function Effects.previewForRecords(records)
    local tag, scores = Effects.bestTagForItems(records or {})
    return {
        tag = tag,
        spec = Effects.specForTag(tag),
        scores = scores,
    }
end

function Effects.getCookLevel(player)
    local level = 0
    pcall(function()
        if player and player.getPerkLevel and Perks and Perks.Cooking then
            level = player:getPerkLevel(Perks.Cooking)
        end
    end)
    return tonumber(level) or 0
end

function Effects.getCookName(player)
    local name = nil
    pcall(function()
        if player and player.getUsername then name = player:getUsername() end
    end)
    if name and name ~= "" then return name end
    pcall(function()
        local descriptor = player and player.getDescriptor and player:getDescriptor() or nil
        if descriptor then
            name = tostring(descriptor:getForename() or "") .. " " .. tostring(descriptor:getSurname() or "")
        end
    end)
    if name and Utils.trim(name) ~= "" then return Utils.trim(name) end
    return "Unknown"
end

function Effects.magnitudeForLevel(level)
    level = tonumber(level) or 0
    if level <= 3 then return 0.8 end
    if level <= 7 then return 1.0 end
    return 1.2
end

function Effects.durationForLevel(level, portion)
    local base = Utils.sbNumber("MealEffectBaseMinutes", 5, 1, 60)
    local perLevel = Utils.sbNumber("MealEffectLevelMinutes", 1.0, 0.0, 3.0)
    local scale = Utils.sbNumber("MealEffectDurationScale", 1.0, 0.25, 4.0)
    local pct = tonumber(portion) or 1.0
    if pct < 0 then pct = 0 end
    if pct > 1 then pct = 1 end
    return (base + (tonumber(level) or 0) * perLevel) * scale * pct
end

function Effects.stampMeal(result, player, validation, options)
    if not result or not result.getModData then return nil end
    if not Utils.sbBool("EnableMealEffects", true) then return nil end

    local tag, scores = Effects.bestTagForItems(validation and validation.items or {})
    local spec = Effects.specForTag(tag)
    if not spec then return nil end

    local level = Effects.getCookLevel(player)
    local data = {
        version = 1,
        serverStamped = true,
        tag = tag,
        specKey = tag,
        name = spec.name,
        desc = spec.desc,
        cookName = Effects.getCookName(player),
        cookLevel = level,
        source = tostring(options and options.source or "ffc"),
        createdWorldAge = getGameTime and getGameTime():getWorldAgeHours() or 0,
        scoreHearty = Utils.round(scores.Hearty or 0, 1),
        scoreFilling = Utils.round(scores.Filling or 0, 1),
        scoreFresh = Utils.round(scores.Fresh or 0, 1),
        scoreSweet = Utils.round(scores.Sweet or 0, 1),
    }

    local md = result:getModData()
    md[Effects.MODDATA_KEY] = data
    md.FFC_CookName = data.cookName
    md.FFC_CookLevel = data.cookLevel
    md.FFC_EffectTag = data.tag
    return data
end

function Effects.readMealEffect(item)
    if not item or not item.getModData then return nil end
    local md = item:getModData()
    local data = md and md[Effects.MODDATA_KEY] or nil
    if type(data) ~= "table" then return nil end
    if data.serverStamped ~= true then return nil end
    local spec = Effects.specForTag(data.tag or data.specKey)
    if not spec then return nil end
    return data, spec
end

function Effects.statLabel(stat)
    return STAT_LABELS[tostring(stat or "")] or tostring(stat or "Effect")
end

function Effects.describeSpec(tag, level)
    local spec = Effects.specForTag(tag)
    if not spec then return {} end
    local mag = Effects.magnitudeForLevel(level or 0) * Utils.sbNumber("MealBuffStrength", 1.0, 0.0, 3.0)
    local lines = {
        "Meal effect: " .. tostring(spec.name),
        tostring(spec.desc),
    }
    for _, component in ipairs(spec.components or {}) do
        local perMin = (tonumber(component.base) or 0) * mag * 60
        local sign = perMin >= 0 and "+" or ""
        lines[#lines + 1] = Effects.statLabel(component.stat) .. " (" .. sign .. tostring(Utils.round(perMin, 3)) .. "/min)"
    end
    return lines
end

return Effects
