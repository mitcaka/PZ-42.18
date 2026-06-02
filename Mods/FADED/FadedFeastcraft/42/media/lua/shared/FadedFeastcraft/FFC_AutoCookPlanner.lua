require "FadedFeastcraft/FFC_Config"
require "FadedFeastcraft/FFC_Utils"
require "FadedFeastcraft/FFC_Balance"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.AutoCookPlanner = FadedFeastcraft.AutoCookPlanner or {}

local Planner = FadedFeastcraft.AutoCookPlanner
local Utils = FadedFeastcraft.Utils
local Config = FadedFeastcraft.Config
local Balance = FadedFeastcraft.Balance

Planner.MODES = {
    { id = "balanced", label = "Balanced", hint = "Variety, freshness, and nutrition" },
    { id = "useSoon", label = "Use Soon", hint = "Ingredients closest to spoiling" },
    { id = "preserveBest", label = "Preserve Best", hint = "Protect long-life supplies" },
    { id = "lowCalorie", label = "Low Calorie", hint = "More hunger relief per calorie" },
    { id = "highCalorie", label = "High Calorie", hint = "High-energy meals" },
    { id = "protein", label = "Protein Focus", hint = "Protein-rich ingredients" },
}

local MODE_INDEX = {}
for i, mode in ipairs(Planner.MODES) do
    MODE_INDEX[mode.id] = i
end

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function recordDays(record)
    local expiry = record and record.expiry or nil
    if expiry and expiry.isRotten then return -1 end
    if expiry and expiry.isSealed then return 999999 end
    if expiry and type(expiry.roomDays) == "number" then return expiry.roomDays end
    local freshness = Utils.lower(record and record.freshness or "")
    if string.find(freshness, "soon", 1, true) then return 0.5 end
    if string.find(freshness, "fresh", 1, true) then return 5 end
    if string.find(freshness, "sealed", 1, true) or string.find(freshness, "stable", 1, true) then return 999999 end
    return 20
end

local function nutritionValue(record, key)
    return tonumber(record and record[key]) or 0
end

local function hungerPoints(record)
    return math.abs(nutritionValue(record, "hunger") * 100)
end

local function safeName(record)
    return tostring(record and record.name or record and record.fullType or "ingredient")
end

local function isRecordSafe(record)
    if not record then return false, "missing ingredient" end
    if not record.id then return false, safeName(record) .. " has no item id" end
    if record.usable == false then return false, safeName(record) .. " is blocked" end
    if record.fullType == Config.RESULT_FIELD_MEAL then return false, safeName(record) .. " is already prepared" end
    if record.frozen then return false, safeName(record) .. " is frozen" end
    if record.rotten then return false, safeName(record) .. " is rotten" end
    if record.burnt then return false, safeName(record) .. " is burned" end
    if record.dangerousRaw and not record.cooked then return false, safeName(record) .. " is dangerous raw" end
    return true, nil
end

local function playerNutrition(player)
    local nutrition = player and player.getNutrition and player:getNutrition() or nil
    if not nutrition then return {} end
    local out = {}
    out.weight = tonumber(Utils.safeCall(nutrition, "getWeight")) or 80
    out.proteins = tonumber(Utils.safeCall(nutrition, "getProteins")) or 0
    out.lipids = tonumber(Utils.safeCall(nutrition, "getLipids")) or 0
    out.carbohydrates = tonumber(Utils.safeCall(nutrition, "getCarbohydrates")) or 0
    out.incWeight = Utils.safeCall(nutrition, "isIncWeight") == true
    out.decWeight = Utils.safeCall(nutrition, "isDecWeight") == true
    return out
end

local function allowSpice(record, usedSpices, options, nutrition)
    if not record.spice then return true end
    local maxSpices = tonumber(options.maxSpices)
    if maxSpices == nil then maxSpices = 2 end
    if maxSpices >= 0 and usedSpices >= maxSpices then return false end

    if options.smartSpices ~= false and nutrition and nutrition.weight then
        if (nutrition.weight > 84 and nutrition.incWeight) or nutrition.weight > 86 then
            return false
        end
        if (nutrition.weight < 76 and nutrition.decWeight) or nutrition.weight < 74 then
            return true
        end
    end

    return true
end

local function baseScore(record, modeId, nutrition)
    local days = recordDays(record)
    local hunger = hungerPoints(record)
    local calories = nutritionValue(record, "calories")
    local protein = nutritionValue(record, "proteins")
    local fat = nutritionValue(record, "lipids")
    local carbs = nutritionValue(record, "carbohydrates")
    local score = hunger * 0.35 + protein * 1.8 + math.min(calories, 900) * 0.015

    if days < 1 then
        score = score + 28
    elseif days < 3 then
        score = score + 14
    elseif days >= 999999 then
        score = score - 8
    end

    if record.spice then score = score + 4 end
    if record.category == "Meat" or record.category == "Fish / Seafood" then score = score + 6 end
    if record.category == "Vegetables" or record.category == "Fruit" then score = score + 5 end

    if modeId == "useSoon" then
        score = score + math.max(0, 60 - math.min(days, 60)) * 1.4
    elseif modeId == "preserveBest" then
        if days >= 999999 then score = score - 36 else score = score + math.max(0, 30 - math.min(days, 30)) * 0.9 end
    elseif modeId == "lowCalorie" then
        if calories <= 0 then
            score = score + hunger
        else
            score = score + (hunger / math.max(1, calories)) * 260
            score = score - math.max(0, calories - 350) * 0.04
        end
    elseif modeId == "highCalorie" then
        score = score + math.min(calories, 1400) * 0.08 + fat * 1.2 + carbs * 0.7
    elseif modeId == "protein" then
        score = score + protein * 5.5 - math.max(0, (fat + carbs) - protein) * 0.35
        if nutrition and nutrition.proteins and nutrition.proteins > 260 then
            score = score - protein * 2.0
        end
    end

    return score
end

local function candidateList(records, player, options)
    local out = {}
    local nutrition = playerNutrition(player)
    local blocked = {}
    for _, record in ipairs(records or {}) do
        local ok, reason = isRecordSafe(record)
        if ok then
            out[#out + 1] = {
                record = record,
                score = baseScore(record, options.modeId, nutrition),
                days = recordDays(record),
                hunger = hungerPoints(record),
            }
        elseif reason and #blocked < 6 then
            blocked[#blocked + 1] = reason
        end
    end
    table.sort(out, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        if a.days ~= b.days then return a.days < b.days end
        return tostring(a.record.name) < tostring(b.record.name)
    end)
    return out, blocked, nutrition
end

function Planner.getMode(modeId)
    local index = MODE_INDEX[modeId or ""]
    if index then return Planner.MODES[index] end
    return Planner.MODES[1]
end

function Planner.nextMode(modeId)
    local index = MODE_INDEX[modeId or "balanced"] or 1
    index = index + 1
    if index > #Planner.MODES then index = 1 end
    return Planner.MODES[index]
end

function Planner.buildPlan(records, player, options)
    options = options or {}
    local mode = Planner.getMode(options.modeId)
    options.modeId = mode.id
    local maxCap = Balance and Balance.maxMealIngredients and Balance.maxMealIngredients() or Config.MAX_MEAL_INGREDIENTS or 8
    local maxItems = clamp(options.maxItems or 4, 1, maxCap)
    local maxDuplicate = clamp(options.maxDuplicate or 2, 1, maxItems)
    local candidates, blockedReasons, nutrition = candidateList(records, player, options)
    local picked = {}
    local itemIds = {}
    local categoryCounts = {}
    local typeCounts = {}
    local pickedIds = {}
    local usedSpices = 0

    for pass = 1, maxDuplicate do
        for _, candidate in ipairs(candidates) do
            if #picked >= maxItems then break end
            local record = candidate.record
            local fullType = tostring(record.fullType or "")
            local currentTypeCount = typeCounts[fullType] or 0
            local category = tostring(record.category or "Other Food")
            local recordId = tostring(record.id or "")
            if not pickedIds[recordId] and currentTypeCount < pass and allowSpice(record, usedSpices, options, nutrition) then
                local adjusted = candidate.score
                if categoryCounts[category] then adjusted = adjusted - 10 else adjusted = adjusted + 10 end
                if mode.id == "balanced" and currentTypeCount > 0 then adjusted = adjusted - 16 end
                record.__ffcPlanScore = adjusted
                picked[#picked + 1] = record
                itemIds[#itemIds + 1] = record.id
                pickedIds[recordId] = true
                typeCounts[fullType] = currentTypeCount + 1
                categoryCounts[category] = (categoryCounts[category] or 0) + 1
                if record.spice then usedSpices = usedSpices + 1 end
            end
        end
        if #picked >= maxItems then break end
    end

    local notes = {}
    notes[#notes + 1] = "Mode: " .. tostring(mode.label) .. " - " .. tostring(mode.hint)
    notes[#notes + 1] = "Suggested ingredients: " .. tostring(#picked)
    if #picked == 0 and #blockedReasons > 0 then
        notes[#notes + 1] = "Blocked sample: " .. tostring(blockedReasons[1])
    end
    if mode.id == "useSoon" then
        notes[#notes + 1] = "Priority: foods closest to stale/rotten are used first."
    elseif mode.id == "preserveBest" then
        notes[#notes + 1] = "Priority: use vulnerable food while saving sealed and long-life supplies."
    elseif mode.id == "lowCalorie" then
        notes[#notes + 1] = "Priority: hunger relief with fewer calories."
    elseif mode.id == "highCalorie" then
        notes[#notes + 1] = "Priority: dense calories for weight gain or hard travel."
    elseif mode.id == "protein" then
        notes[#notes + 1] = "Priority: protein without excessive filler."
    else
        notes[#notes + 1] = "Priority: variety with fresh food before long-life pantry items."
    end

    return {
        mode = mode,
        modeId = mode.id,
        records = picked,
        itemIds = itemIds,
        notes = notes,
        blockedReasons = blockedReasons,
        maxItems = maxItems,
    }
end

function Planner.formatPlan(plan)
    if not plan then return { "No suggestion available." } end
    local lines = {}
    for _, note in ipairs(plan.notes or {}) do
        lines[#lines + 1] = note
    end
    for i, record in ipairs(plan.records or {}) do
        local days = recordDays(record)
        local shelf = days >= 999999 and "stable" or (Utils.round(days, 1) .. "d")
        lines[#lines + 1] = tostring(i) .. ". " .. safeName(record) .. " [" .. tostring(record.category or "Food") .. ", " .. shelf .. "]"
    end
    if #lines == 0 then lines[#lines + 1] = "No safe ingredients found." end
    return lines
end

return Planner
