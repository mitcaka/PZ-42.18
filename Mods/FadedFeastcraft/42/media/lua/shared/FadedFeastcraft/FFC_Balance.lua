require "FadedFeastcraft/FFC_Config"
require "FadedFeastcraft/FFC_Utils"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.Balance = FadedFeastcraft.Balance or {}

local Balance = FadedFeastcraft.Balance
local Utils = FadedFeastcraft.Utils
local Config = FadedFeastcraft.Config

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function Balance.getCookLevel(player)
    local level = 0
    pcall(function()
        if player and player.getPerkLevel and Perks and Perks.Cooking then
            level = player:getPerkLevel(Perks.Cooking)
        end
    end)
    return clamp(level, 0, 10)
end

function Balance.maxMealIngredients()
    local fallback = Config.MAX_MEAL_INGREDIENTS or 8
    return clamp(Utils.sbNumber("MealIngredientLimit", fallback, 2, 12), 2, 12)
end

function Balance.maxBatchOperations()
    return clamp(Utils.sbNumber("MaxBatchOperations", 10, 1, 40), 1, 40)
end

function Balance.nutritionScale(player, source)
    local level = Balance.getCookLevel(player)
    local scale = 1.0 + (level * 0.015)
    if source == "station" then
        scale = scale + 0.04
    elseif source == "preservation" then
        scale = scale + 0.02
    end
    return scale, level
end

function Balance.weightScale(player)
    local level = Balance.getCookLevel(player)
    return 1.0 - math.min(0.15, level * 0.012), level
end

function Balance.freshnessBonusDays(player, source)
    local level = Balance.getCookLevel(player)
    local bonus = level * 0.20
    if source == "station" then bonus = bonus + 0.75 end
    if source == "preservation" then bonus = bonus + 2.0 end
    return Utils.round(bonus, 2), level
end

local function sourceLabel(source)
    if source == "station" then return "hot meal" end
    if source == "builder" then return "field meal" end
    if source == "packed" then return "packed meal" end
    if source == "preservation" then return "preserved ration" end
    return tostring(source or "meal")
end

function Balance.applyMealTuning(result, player, totals, options)
    if not result then return nil end
    options = options or {}
    local source = tostring(options.source or "builder")
    local nutritionScale, level = Balance.nutritionScale(player, source)
    local weightScale = Balance.weightScale(player)
    local freshnessBonus = Balance.freshnessBonusDays(player, source)
    local variety = tonumber(options.variety) or 1
    local boredomBonus = math.min(8, math.max(0, variety - 1) * 1.5 + level * 0.25)
    local unhappyBonus = math.min(8, math.max(0, variety - 1) * 1.5 + level * 0.25)

    totals = totals or {}
    Utils.safeSet(result, "setCalories", math.max(1, (tonumber(totals.calories) or 1) * nutritionScale))
    Utils.safeSet(result, "setProteins", math.max(0, (tonumber(totals.proteins) or 0) * nutritionScale))
    Utils.safeSet(result, "setLipids", math.max(0, (tonumber(totals.lipids) or 0) * nutritionScale))
    Utils.safeSet(result, "setCarbohydrates", math.max(0, (tonumber(totals.carbohydrates) or 0) * nutritionScale))
    Utils.safeSet(result, "setBoredomChange", (tonumber(totals.boredom) or 0) - boredomBonus)
    Utils.safeSet(result, "setUnhappyChange", (tonumber(totals.unhappy) or 0) - unhappyBonus)

    local baseWeight = tonumber(Utils.safeCall(result, "getActualWeight")) or tonumber(Utils.safeCall(result, "getWeight")) or nil
    if baseWeight and baseWeight > 0 then
        Utils.safeSet(result, "setActualWeight", math.max(0.05, baseWeight * weightScale))
        Utils.safeSet(result, "setWeight", math.max(0.05, baseWeight * weightScale))
    end
    Utils.safeSet(result, "setAge", 0)

    local md = result:getModData()
    md.FFC_Balance = {
        version = 1,
        source = source,
        sourceLabel = sourceLabel(source),
        cookLevel = level,
        nutritionScale = Utils.round(nutritionScale, 3),
        weightScale = Utils.round(weightScale, 3),
        freshnessBonusDays = freshnessBonus,
        variety = variety,
    }
    return md.FFC_Balance
end

function Balance.describeMealTuning(data)
    if type(data) ~= "table" then return {} end
    return {
        "Cooking skill tuning: " .. tostring(data.sourceLabel or data.source or "meal"),
        "Cook level: " .. tostring(data.cookLevel or 0),
        "Nutrition retained: x" .. tostring(data.nutritionScale or 1),
        "Packed weight: x" .. tostring(data.weightScale or 1),
        "Freshness bonus: +" .. tostring(data.freshnessBonusDays or 0) .. "d",
    }
end

return Balance
