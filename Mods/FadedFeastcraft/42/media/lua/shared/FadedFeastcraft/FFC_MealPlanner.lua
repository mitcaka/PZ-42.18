require "FadedFeastcraft/FFC_Config"
require "FadedFeastcraft/FFC_Utils"
require "FadedFeastcraft/FFC_MealEffects"
require "FadedFeastcraft/FFC_Balance"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.MealPlanner = FadedFeastcraft.MealPlanner or {}

local Planner = FadedFeastcraft.MealPlanner
local Utils = FadedFeastcraft.Utils
local Config = FadedFeastcraft.Config
local MealEffects = FadedFeastcraft.MealEffects
local Balance = FadedFeastcraft.Balance

function Planner.estimate(records)
    local result = {
        count = 0,
        hunger = 0,
        calories = 0,
        proteins = 0,
        lipids = 0,
        carbohydrates = 0,
        warnings = {},
        blocked = false,
        quality = "Simple",
    }

    local categories = {}
    for _, record in ipairs(records or {}) do
        result.count = result.count + 1
        result.hunger = result.hunger + (tonumber(record.hunger) or 0)
        result.calories = result.calories + (tonumber(record.calories) or 0)
        result.proteins = result.proteins + (tonumber(record.proteins) or 0)
        result.lipids = result.lipids + (tonumber(record.lipids) or 0)
        result.carbohydrates = result.carbohydrates + (tonumber(record.carbohydrates) or 0)
        categories[record.category or "Other"] = true

        if record.frozen then result.warnings[#result.warnings + 1] = record.name .. " is frozen" end
        if record.rotten then result.warnings[#result.warnings + 1] = record.name .. " is rotten" end
        if record.burnt then result.warnings[#result.warnings + 1] = record.name .. " is burned" end
        if record.dangerousRaw and not record.cooked then result.warnings[#result.warnings + 1] = record.name .. " is dangerous raw" end
        if record.fullType == Config.RESULT_FIELD_MEAL then result.warnings[#result.warnings + 1] = record.name .. " is already prepared" end
        if not record.usable then result.blocked = true end
        if record.fullType == Config.RESULT_FIELD_MEAL then result.blocked = true end
    end

    local variety = 0
    for _ in pairs(categories) do variety = variety + 1 end
    if variety >= 4 and result.count >= 4 then
        result.quality = "Advanced"
    elseif variety >= 2 and result.count >= 2 then
        result.quality = "Balanced"
    end

    local maxIngredients = Balance and Balance.maxMealIngredients and Balance.maxMealIngredients() or Config.MAX_MEAL_INGREDIENTS
    if result.count < Config.MIN_MEAL_INGREDIENTS or result.count > maxIngredients then
        result.blocked = true
    end

    local hungerPoints = math.max(1, math.abs((result.hunger or 0) * 100))
    result.caloriesPerHunger = (result.calories or 0) / hungerPoints
    result.proteinShare = (result.proteins or 0) / math.max(1, (result.proteins or 0) + (result.lipids or 0) + (result.carbohydrates or 0))

    if MealEffects and MealEffects.previewForRecords and Utils.sbBool("EnableMealEffects", true) then
        result.effect = MealEffects.previewForRecords(records or {})
    end

    return result
end

function Planner.formatEstimate(estimate)
    if not estimate then return {} end
    local lines = {}
    lines[#lines + 1] = "Ingredients: " .. tostring(estimate.count)
    if estimate.count == 0 then
        lines[#lines + 1] = "Pick safe unfrozen foods from the left, then press Create Meal."
    end
    lines[#lines + 1] = "Meal quality: " .. tostring(estimate.quality)
    lines[#lines + 1] = "Hunger: " .. tostring(Utils.round(math.abs((estimate.hunger or 0) * 100), 1))
    lines[#lines + 1] = "Calories: " .. tostring(Utils.round(estimate.calories or 0, 0))
    lines[#lines + 1] = "Calories per hunger point: " .. tostring(Utils.round(estimate.caloriesPerHunger or 0, 1))
    lines[#lines + 1] = "Protein/Fat/Carbs: "
        .. tostring(Utils.round(estimate.proteins or 0, 1)) .. " / "
        .. tostring(Utils.round(estimate.lipids or 0, 1)) .. " / "
        .. tostring(Utils.round(estimate.carbohydrates or 0, 1))
    if estimate.proteinShare then
        lines[#lines + 1] = "Protein share: " .. tostring(Utils.round(estimate.proteinShare * 100, 0)) .. "%"
    end
    if estimate.effect and estimate.effect.spec then
        lines[#lines + 1] = "Meal effect: " .. tostring(estimate.effect.spec.name or estimate.effect.tag)
        lines[#lines + 1] = tostring(estimate.effect.spec.desc or "")
    end
    if estimate.blocked then lines[#lines + 1] = "Status: blocked until unsafe ingredients are removed" end
    for i = 1, math.min(#estimate.warnings, 6) do
        lines[#lines + 1] = "Warning: " .. estimate.warnings[i]
    end
    return lines
end

return Planner
