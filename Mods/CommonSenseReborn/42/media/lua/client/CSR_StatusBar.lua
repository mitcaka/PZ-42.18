-- CSR_StatusBar.lua
-- Horizontal status strip anchored above the player's hotbar. Each
-- enabled stat renders as a fixed-width cell with [icon][filled bar]
-- and a value overlay. When a stat enters its "affected" range (low
-- health, high pain, infection > 0, etc.) the cell border switches
-- to the stat's accent color and pulses, so warnings stand out
-- without depending on opacity.
--
-- Stat catalogue and B42 API access patterns adapted from a
-- third-party status panel mod (used with permission of its author).
-- The horizontal layout, CSR theme integration, transparency floor,
-- affected-state outline, and per-cell right-click menu are CSR
-- additions and not part of the source mod.
require "ISUI/ISPanel"
require "CSR_FeatureFlags"
require "CSR_Theme"
require "CSR_Scale"

CSR_StatusBar = CSR_StatusBar or {}

local PAD          = 4
local CELL_GAP     = 2
local DEFAULT_CELL_W = 56
local MIN_CELL_W   = 40
local MAX_CELL_W   = 96
local DEFAULT_CELL_H = 22
local MIN_CELL_H   = 16
local MAX_CELL_H   = 32
local OPACITY_MIN  = 0.25
local OPACITY_MAX  = 1.0
local CACHE_TICKS  = 6   -- ~10 Hz

local function clamp(v, mn, mx)
    if v < mn then return mn end
    if v > mx then return mx end
    return v
end

local function getPlayerScreenBounds(playerNum)
    local left = getPlayerScreenLeft and getPlayerScreenLeft(playerNum) or 0
    local top = getPlayerScreenTop and getPlayerScreenTop(playerNum) or 0
    local width = getPlayerScreenWidth and getPlayerScreenWidth(playerNum) or getCore():getScreenWidth()
    local height = getPlayerScreenHeight and getPlayerScreenHeight(playerNum) or getCore():getScreenHeight()
    return left, top, width, height
end

local function getActiveVehicleDashboard(playerNum)
    local player = getSpecificPlayer and getSpecificPlayer(playerNum or 0) or nil
    if not player or not player.getVehicle then return nil end
    local vehicle = player:getVehicle()
    if not vehicle then return nil end
    if not vehicle.isDriver or not vehicle:isDriver(player) then return nil end
    if not getPlayerVehicleDashboard then return nil end
    local dash = getPlayerVehicleDashboard(playerNum or 0)
    if not dash or not dash.vehicle then return nil end
    if dash.vehicle ~= vehicle then return nil end
    if dash.getIsVisible and not dash:getIsVisible() then return nil end
    return dash
end

-- ─────────────────────────────────────────────────────
-- B42 / B41 stat helpers (kept very defensive)
-- ─────────────────────────────────────────────────────
local function getStatVal(p, statName)
    if not p then return 0 end
    local stats = p:getStats()
    if not stats then return 0 end
    if CharacterStat and CharacterStat[statName] and stats.get then
        local ok, val = pcall(stats.get, stats, CharacterStat[statName])
        if ok and val ~= nil then return val end
    end
    local methodName = "get" .. statName:sub(1,1):upper() .. statName:sub(2):lower()
    if stats[methodName] then
        local ok, val = pcall(stats[methodName], stats)
        if ok and val ~= nil then return val end
    end
    return 0
end

local function hasCharacterStat(statName)
    return CharacterStat and CharacterStat[statName] ~= nil
end

local function getPercentStat(p, statName)
    local value = tonumber(getStatVal(p, statName)) or 0
    if value > 1 then
        value = value / 100
    end
    return clamp(value, 0, 1)
end

local function fmtPercentStat(p, statName)
    return tostring(math.floor(getPercentStat(p, statName) * 100 + 0.5)) .. "%"
end

local function getNutritionValue(p, methodName)
    if not p or not p.getNutrition then return 0 end
    local nutrition = p:getNutrition()
    if not nutrition or not nutrition[methodName] then return 0 end
    local value = nutrition[methodName](nutrition)
    return tonumber(value) or 0
end

local function getNutritionPercent(p, methodName, low, high)
    local value = getNutritionValue(p, methodName)
    local span = high - low
    if span <= 0 then return 0 end
    return clamp((value - low) / span, 0, 1)
end

local function fmtNutritionValue(p, methodName, suffix)
    local value = getNutritionValue(p, methodName)
    return tostring(math.floor(value + 0.5)) .. (suffix or "")
end

local function getThermoregulator(p)
    if not p or not p.getBodyDamage then return nil end
    local bd = p:getBodyDamage()
    if not bd or not bd.getThermoregulator then return nil end
    local ok, reg = pcall(bd.getThermoregulator, bd)
    if ok then return reg end
    return nil
end

local function getBodyDirtiness(p)
    if not p or not p.getHumanVisual then return 0 end
    if not BloodBodyPartType or not BloodBodyPartType.MAX then return 0 end
    local visual = p:getHumanVisual()
    if not visual then return 0 end
    local max = BloodBodyPartType.MAX:index()
    if not max or max <= 0 then return 0 end
    local total = 0
    for i = 0, max - 1 do
        local part = BloodBodyPartType.FromIndex(i)
        if part then
            local blood = 0
            local dirt = 0
            if visual.getBlood then
                blood = tonumber(visual:getBlood(part)) or 0
            end
            if visual.getDirt then
                dirt = tonumber(visual:getDirt(part)) or 0
            end
            total = total + blood + dirt
        end
    end
    return clamp(total / (max * 2), 0, 1)
end

local function getCarryLoadPercent(p)
    if not p or not p.getInventoryWeight or not p.getMaxWeight then return 0 end
    local max = tonumber(p:getMaxWeight()) or 0
    if max <= 0 then return 0 end
    return clamp((tonumber(p:getInventoryWeight()) or 0) / max, 0, 1)
end

local function fmtCarryLoad(p)
    if not p or not p.getInventoryWeight or not p.getMaxWeight then return "0/0" end
    return string.format("%.1f/%.1f", tonumber(p:getInventoryWeight()) or 0, tonumber(p:getMaxWeight()) or 0)
end

local function fmtBodyWeight(p)
    if not p or not p.getNutrition then return "0.0 kg" end
    local nutrition = p:getNutrition()
    if not nutrition or not nutrition.getWeight then return "0.0 kg" end
    local suffix = ""
    if nutrition.isIncWeightLot and nutrition:isIncWeightLot() then
        suffix = " ++"
    elseif nutrition.isIncWeight and nutrition:isIncWeight() then
        suffix = " +"
    elseif nutrition.isDecWeight and nutrition:isDecWeight() then
        suffix = " -"
    end
    return string.format("%.1f kg%s", tonumber(nutrition:getWeight()) or 0, suffix)
end

local function getHeatGenerationValue(p)
    local reg = getThermoregulator(p)
    if reg and reg.getMetabolicRateReal then
        return tonumber(reg:getMetabolicRateReal()) or 0
    end
    return 0
end

local function getHeatGenerationPercent(p)
    local reg = getThermoregulator(p)
    if reg and reg.getHeatGenerationUI then
        return clamp(tonumber(reg:getHeatGenerationUI()) or 0, 0, 1)
    end
    return 0
end

local function fmtFitness(p)
    local value = math.floor((tonumber(getStatVal(p, "FITNESS")) or 0) * 100 + 0.5)
    if value > 0 then
        return "+" .. tostring(value) .. "%"
    end
    return tostring(value) .. "%"
end

local function getNicotineWithdrawalPercent(p)
    if not hasCharacterStat("NICOTINE_WITHDRAWAL") then return 0 end
    return clamp((tonumber(getStatVal(p, "NICOTINE_WITHDRAWAL")) or 0) / 0.51, 0, 1)
end

local function getMoodleType(name)
    if not MoodleType then return nil end
    if MoodleType[name] then return MoodleType[name] end
    local upper = name:upper()
    if MoodleType[upper] then return MoodleType[upper] end
    return nil
end

local function getMoodleVal(p, moodleName)
    if not p or not p:getMoodles() then return 0 end
    local mt = getMoodleType(moodleName)
    if not mt then return 0 end
    return (p:getMoodles():getMoodleLevel(mt) or 0) / 4.0
end

local function getSicknessValue(p)
    if not p then return 0 end
    local bd = p:getBodyDamage()
    local val = 0
    if bd then
        if bd.getSicknessLevel then
            local ok, s = pcall(bd.getSicknessLevel, bd)
            if ok and s and s > 0 then val = math.max(val, s / 100) end
        end
        if bd.getFoodSicknessLevel then
            local ok, fs = pcall(bd.getFoodSicknessLevel, bd)
            if ok and fs and fs > 0 then val = math.max(val, fs / 100) end
        end
    end
    val = math.max(val, getMoodleVal(p, "Sick"))
    return clamp(val, 0, 1)
end

local function getInfectionValue(p)
    if not p then return 0 end
    local val = 0
    local bd = p:getBodyDamage()
    if bd and bd.getInfectionLevel then
        local ok, s = pcall(bd.getInfectionLevel, bd)
        if ok and s then val = math.max(val, s / 100) end
    end
    return clamp(val, 0, 1)
end

local function getCoreTemp(p)
    local reg = getThermoregulator(p)
    if reg and reg.getCoreTemperature then
        local ok, val = pcall(reg.getCoreTemperature, reg)
        if ok and val then return val end
    end
    return 37
end

local function getCoreTempPercent(p)
    local reg = getThermoregulator(p)
    if reg and reg.getCoreTemperatureUI then
        return clamp(tonumber(reg:getCoreTemperatureUI()) or 0, 0, 1)
    end
    return clamp((getCoreTemp(p) - 35) / 5, 0, 1)
end

-- ─────────────────────────────────────────────────────
-- Stat catalogue
--   id, color (RGB), icon, label key, getter (returns 0..1),
--   formatter (optional), affected (returns true when warning).
-- "affected" is the visual cue: cell border switches to the stat
-- color and pulses, regardless of overall panel opacity.
-- ─────────────────────────────────────────────────────
CSR_StatusBar.STATS = {
    { id = "health",      color = {0.86, 0.36, 0.36}, icon = "media/ui/Moodles/Moodle_Icon_Injured.png",
      label = "IGUI_CSR_StatusBar_Health",
      get = function(p) return clamp(p:getBodyDamage():getOverallBodyHealth() / 100, 0, 1) end,
      affected = function(v) return v < 0.85 end },
    { id = "hunger",      color = {0.95, 0.62, 0.20}, icon = "media/ui/Moodles/Moodle_Icon_Hungry.png",
      label = "IGUI_CSR_StatusBar_Hunger",
      get = function(p) return 1 - clamp(getStatVal(p, "HUNGER"), 0, 1) end,
      affected = function(v) return v < 0.7 end },
    { id = "thirst",      color = {0.34, 0.66, 0.96}, icon = "media/ui/Moodles/Moodle_Icon_Thirsty.png",
      label = "IGUI_CSR_StatusBar_Thirst",
      get = function(p) return 1 - clamp(getStatVal(p, "THIRST"), 0, 1) end,
      affected = function(v) return v < 0.7 end },
    { id = "fatigue",     color = {0.72, 0.58, 0.94}, icon = "media/ui/Moodles/Moodle_Icon_Tired.png",
      label = "IGUI_CSR_StatusBar_Fatigue",
      get = function(p) return clamp(getStatVal(p, "FATIGUE"), 0, 1) end,
      affected = function(v) return v > 0.4 end },
    { id = "endurance",   color = {0.95, 0.86, 0.30}, icon = "media/ui/Moodles/Moodle_Icon_Endurance.png",
      label = "IGUI_CSR_StatusBar_Endurance",
      get = function(p) return clamp(getStatVal(p, "ENDURANCE"), 0, 1) end,
      affected = function(v) return v < 0.4 end },
    { id = "stress",      color = {0.92, 0.45, 0.65}, icon = "media/ui/Moodles/Moodle_Icon_Stressed.png",
      label = "IGUI_CSR_StatusBar_Stress",
      get = function(p) return math.max(getStatVal(p, "STRESS"), getMoodleVal(p, "Stress")) end,
      affected = function(v) return v > 0.4 end },
    { id = "panic",       color = {0.86, 0.86, 0.86}, icon = "media/ui/Moodles/Moodle_Icon_Panic.png",
      label = "IGUI_CSR_StatusBar_Panic",
      get = function(p) return getPercentStat(p, "PANIC") end,
      affected = function(v) return v > 0.1 end },
    { id = "boredom",     color = {0.62, 0.78, 0.30}, icon = "media/ui/Moodles/Moodle_Icon_Bored.png",
      label = "IGUI_CSR_StatusBar_Boredom",
      get = function(p) return getPercentStat(p, "BOREDOM") end,
      affected = function(v) return v > 0.5 end },
    { id = "mood",        color = {0.95, 0.78, 0.42}, icon = "media/ui/Moodles/Moodle_Icon_Unhappy.png",
      label = "IGUI_CSR_StatusBar_Mood",
      get = function(p) return 1 - getPercentStat(p, "UNHAPPINESS") end,
      affected = function(v) return v < 0.6 end },
    { id = "pain",        color = {0.86, 0.20, 0.20}, icon = "media/ui/Moodles/Moodle_Icon_Pain.png",
      label = "IGUI_CSR_StatusBar_Pain",
      get = function(p) return getPercentStat(p, "PAIN") end,
      affected = function(v) return v > 0.15 end },
    { id = "sickness",    color = {0.42, 0.85, 0.46}, icon = "media/ui/Moodles/Moodle_Icon_Sick.png",
      label = "IGUI_CSR_StatusBar_Sickness",
      get = function(p) return getSicknessValue(p) end,
      affected = function(v) return v > 0 end },
    { id = "temperature", color = {0.34, 0.62, 0.96}, icon = "media/ui/Moodles/Moodle_Icon_Sick.png",
      label = "IGUI_CSR_StatusBar_Temperature",
      get = function(p) return getCoreTempPercent(p) end,
      fmt = function(p) return string.format("%.1f\194\176C", getCoreTemp(p)) end,
      affected = function(v) return v < 0.4 or v > 0.6 end },
    { id = "infection",   color = {0.20, 0.90, 0.42}, icon = "media/ui/Moodles/Moodle_Icon_Zombie.png",
      label = "IGUI_CSR_StatusBar_Infection",
      get = function(p) return getInfectionValue(p) end,
      affected = function(v) return v > 0 end },
    { id = "calories",    color = {0.86, 0.50, 0.18}, icon = "media/ui/Moodles/Moodle_Icon_Hungry.png",
      label = "IGUI_CSR_StatusBar_Calories",
      get = function(p) return getNutritionPercent(p, "getCalories", -2000, 3500) end,
      fmt = function(p) return fmtNutritionValue(p, "getCalories", " kcal") end,
      affected = function(v) return false end },
    { id = "weight",      color = {0.74, 0.74, 0.74}, icon = "media/ui/Moodles/Moodle_Icon_HeavyLoad.png",
      label = "IGUI_CSR_StatusBar_Weight",
      get = function(p) local w = p:getNutrition():getWeight(); return clamp((w - 40) / 90, 0, 1) end,
      fmt = function(p) return fmtBodyWeight(p) end,
      affected = function(v) return false end },
    { id = "proteins",    color = {0.92, 0.42, 0.50}, icon = "media/ui/Moodles/Moodle_Icon_Hungry.png",
      label = "IGUI_CSR_StatusBar_Proteins",
      get = function(p) return getNutritionPercent(p, "getProteins", -500, 1000) end,
      fmt = function(p) return fmtNutritionValue(p, "getProteins") end,
      affected = function(v) return false end },
    { id = "carbs",       color = {0.92, 0.82, 0.42}, icon = "media/ui/Moodles/Moodle_Icon_Hungry.png",
      label = "IGUI_CSR_StatusBar_Carbs",
      get = function(p) return getNutritionPercent(p, "getCarbohydrates", -500, 1000) end,
      fmt = function(p) return fmtNutritionValue(p, "getCarbohydrates") end,
      affected = function(v) return false end },
    { id = "lipids",      color = {0.84, 0.74, 0.22}, icon = "media/ui/Moodles/Moodle_Icon_Hungry.png",
      label = "IGUI_CSR_StatusBar_Lipids",
      get = function(p) return getNutritionPercent(p, "getLipids", -500, 1000) end,
      fmt = function(p) return fmtNutritionValue(p, "getLipids") end,
      affected = function(v) return false end },
    { id = "carry",       color = {0.74, 0.74, 0.74}, icon = "media/ui/Moodles/Moodle_Icon_HeavyLoad.png",
      label = "IGUI_CSR_StatusBar_Carry",
      get = function(p) return getCarryLoadPercent(p) end,
      fmt = function(p) return fmtCarryLoad(p) end,
      affected = function(v) return v >= 1 end },
    { id = "dirtiness",   color = {0.50, 0.38, 0.24}, icon = "media/ui/Moodles/Moodle_Icon_Sick.png",
      label = "IGUI_CSR_StatusBar_Dirtiness",
      available = function() return BloodBodyPartType and BloodBodyPartType.MAX end,
      get = function(p) return getBodyDirtiness(p) end,
      affected = function(v) return v > 0.15 end },
    { id = "heatgen",     color = {0.96, 0.46, 0.22}, icon = "media/ui/Moodles/Moodle_Icon_Hyperthermia.png",
      label = "IGUI_CSR_StatusBar_HeatGen",
      get = function(p) return getHeatGenerationPercent(p) end,
      fmt = function(p) return string.format("%.1f", getHeatGenerationValue(p)) end,
      affected = function(v) return v < 0.25 or v > 0.75 end },
    { id = "wetness",     color = {0.28, 0.70, 0.96}, icon = "media/ui/Moodles/Moodle_Icon_Wet.png",
      label = "IGUI_CSR_StatusBar_Wetness",
      available = function() return hasCharacterStat("WETNESS") end,
      get = function(p) return getPercentStat(p, "WETNESS") end,
      affected = function(v) return v > 0.2 end },
    { id = "intoxication", color = {0.70, 0.44, 0.86}, icon = "media/ui/Moodles/Moodle_Icon_Drunk.png",
      label = "IGUI_CSR_StatusBar_Intoxication",
      available = function() return hasCharacterStat("INTOXICATION") end,
      get = function(p) return getPercentStat(p, "INTOXICATION") end,
      affected = function(v) return v > 0.1 end },
    { id = "poison",      color = {0.40, 0.86, 0.34}, icon = "media/ui/Moodles/Moodle_Icon_Sick.png",
      label = "IGUI_CSR_StatusBar_Poison",
      available = function() return hasCharacterStat("POISON") end,
      get = function(p) return getPercentStat(p, "POISON") end,
      affected = function(v) return v > 0.05 end },
    { id = "food_sickness", color = {0.56, 0.86, 0.34}, icon = "media/ui/Moodles/Moodle_Icon_Sick.png",
      label = "IGUI_CSR_StatusBar_FoodSickness",
      available = function() return hasCharacterStat("FOOD_SICKNESS") end,
      get = function(p) return getPercentStat(p, "FOOD_SICKNESS") end,
      affected = function(v) return v > 0.05 end },
    { id = "zombie_infection", color = {0.20, 0.90, 0.42}, icon = "media/ui/Moodles/Moodle_Icon_Zombie.png",
      label = "IGUI_CSR_StatusBar_ZombieInfection",
      available = function() return hasCharacterStat("ZOMBIE_INFECTION") end,
      get = function(p) return getPercentStat(p, "ZOMBIE_INFECTION") end,
      affected = function(v) return v > 0 end },
    { id = "zombie_fever", color = {0.44, 0.86, 0.56}, icon = "media/ui/Moodles/Moodle_Icon_Sick.png",
      label = "IGUI_CSR_StatusBar_ZombieFever",
      available = function() return hasCharacterStat("ZOMBIE_FEVER") end,
      get = function(p) return getPercentStat(p, "ZOMBIE_FEVER") end,
      affected = function(v) return v > 0.1 end },
    { id = "nicotine",    color = {0.66, 0.62, 0.52}, icon = "media/ui/Moodles/Moodle_Icon_Stressed.png",
      label = "IGUI_CSR_StatusBar_Nicotine",
      available = function() return hasCharacterStat("NICOTINE_WITHDRAWAL") end,
      get = function(p) return getNicotineWithdrawalPercent(p) end,
      fmt = function(p) return tostring(math.floor(getNicotineWithdrawalPercent(p) * 100 + 0.5)) .. "%" end,
      affected = function(v) return v > 0.25 end },
    { id = "anger",       color = {0.88, 0.28, 0.20}, icon = "media/ui/Moodles/Moodle_Icon_Unhappy.png",
      label = "IGUI_CSR_StatusBar_Anger",
      available = function() return hasCharacterStat("ANGER") end,
      get = function(p) return getPercentStat(p, "ANGER") end,
      affected = function(v) return v > 0.1 end },
    { id = "sanity",      color = {0.44, 0.80, 0.86}, icon = "media/ui/Moodles/Moodle_Icon_Panic.png",
      label = "IGUI_CSR_StatusBar_Sanity",
      available = function() return hasCharacterStat("SANITY") end,
      get = function(p) return getPercentStat(p, "SANITY") end,
      affected = function(v) return v < 0.5 end },
    { id = "fitness",     color = {0.42, 0.82, 0.64}, icon = "media/ui/Moodles/Moodle_Icon_Endurance.png",
      label = "IGUI_CSR_StatusBar_Fitness",
      available = function() return hasCharacterStat("FITNESS") end,
      get = function(p) return clamp(((tonumber(getStatVal(p, "FITNESS")) or 0) + 1) / 2, 0, 1) end,
      fmt = function(p) return fmtFitness(p) end,
      affected = function(v) return v < 0.5 end },
    { id = "morale",      color = {0.92, 0.76, 0.30}, icon = "media/ui/Moodles/Moodle_Icon_Unhappy.png",
      label = "IGUI_CSR_StatusBar_Morale",
      available = function() return hasCharacterStat("MORALE") end,
      get = function(p) return getPercentStat(p, "MORALE") end,
      affected = function(v) return v < 0.5 end },
    { id = "discomfort",  color = {0.88, 0.42, 0.28}, icon = "media/ui/Moodles/Moodle_Icon_Pain.png",
      label = "IGUI_CSR_StatusBar_Discomfort",
      available = function() return hasCharacterStat("DISCOMFORT") end,
      get = function(p) return getPercentStat(p, "DISCOMFORT") end,
      affected = function(v) return v > 0.25 end },
    { id = "idleness",    color = {0.72, 0.74, 0.42}, icon = "media/ui/Moodles/Moodle_Icon_Bored.png",
      label = "IGUI_CSR_StatusBar_Idleness",
      available = function() return hasCharacterStat("IDLENESS") end,
      get = function(p) return getPercentStat(p, "IDLENESS") end,
      affected = function(v) return v > 0.25 end },
}

local DEFAULT_ENABLED = {
    health = true, hunger = true, thirst = true,
    fatigue = true, endurance = true, stress = true,
}
local SETTINGS_VERSION = 3

-- ─────────────────────────────────────────────────────
-- Settings persistence
-- ─────────────────────────────────────────────────────
local function defaultEnabledCells()
    local enabled = {}
    for id, v in pairs(DEFAULT_ENABLED) do
        enabled[id] = v == true
    end
    return enabled
end

local function normalizeEnabledCells(enabled)
    if type(enabled) ~= "table" then
        return defaultEnabledCells()
    end
    for _, def in ipairs(CSR_StatusBar.STATS) do
        enabled[def.id] = enabled[def.id] == true
    end
    return enabled
end

local function normalizeNumber(value, fallback, mn, mx)
    local n = tonumber(value)
    if not n then return fallback end
    return clamp(n, mn, mx)
end

local function normalizeSettings(s)
    if type(s) ~= "table" then s = {} end
    s.version = SETTINGS_VERSION
    if type(s.enabled) ~= "table" then
        s.enabled = defaultEnabledCells()
    else
        s.enabled = normalizeEnabledCells(s.enabled)
    end
    s.opacity = normalizeNumber(s.opacity, 0.92, OPACITY_MIN, OPACITY_MAX)
    s.cellW = normalizeNumber(s.cellW, CSR_Scale.px(DEFAULT_CELL_W), MIN_CELL_W, MAX_CELL_W)
    s.cellH = normalizeNumber(s.cellH, CSR_Scale.px(DEFAULT_CELL_H), MIN_CELL_H, MAX_CELL_H)
    s.gap = normalizeNumber(s.gap, CSR_Scale.px(CELL_GAP), 0, 16)
    if type(s.detached) ~= "boolean" then s.detached = false end
    if type(s.detachedX) ~= "number" then s.detachedX = nil end
    if type(s.detachedY) ~= "number" then s.detachedY = nil end
    if s.detached and (s.detachedX == nil or s.detachedY == nil) then
        s.detached = false
    end
    if type(s.vertical) ~= "boolean" then s.vertical = false end
    return s
end

local function loadSettings(player)
    if not player then return nil end
    local md = player:getModData()
    md.csrStatusBar = normalizeSettings(md.csrStatusBar)
    return md.csrStatusBar
end

local function saveSettings(player)
    if not player then return end
    loadSettings(player)
    if player.transmitModData then player:transmitModData() end
end

-- ─────────────────────────────────────────────────────
-- Panel
-- ─────────────────────────────────────────────────────
CSR_StatusBarPanel = ISPanel:derive("CSR_StatusBarPanel")

function CSR_StatusBarPanel:new(playerNum)
    local o = ISPanel.new(self, 0, 0, 200, DEFAULT_CELL_H + PAD * 2)
    o.playerNum = playerNum or 0
    o.background = false
    o.cacheTick = 0
    o.cells = {}     -- list of { def, value, affected }
    o.dragging = false
    o._loaded = false
    o._suppressedForVehicle = false
    return o
end

function CSR_StatusBarPanel:initialise()
    ISPanel.initialise(self)
end

function CSR_StatusBarPanel:loadFromModData()
    local p = getSpecificPlayer(self.playerNum)
    if not p then return end
    self.settings = loadSettings(p)
end

function CSR_StatusBarPanel:saveSettings()
    local p = getSpecificPlayer(self.playerNum)
    saveSettings(p)
end

function CSR_StatusBarPanel:rebuildCells()
    self.cells = {}
    for _, def in ipairs(CSR_StatusBar.STATS) do
        local available = (not def.available) or def.available()
        if self.settings and self.settings.enabled[def.id] and available then
            table.insert(self.cells, { def = def, value = 0, affected = false })
        end
    end
end

function CSR_StatusBarPanel:refreshValues()
    local p = getSpecificPlayer(self.playerNum)
    if not p or p:isDead() then return end
    for _, cell in ipairs(self.cells) do
        local ok, v = pcall(cell.def.get, p)
        if not ok or type(v) ~= "number" then v = 0 end
        cell.value = clamp(v, 0, 1)
        local okA, a = pcall(cell.def.affected, cell.value)
        cell.affected = okA and a or false
    end
end

function CSR_StatusBarPanel:computeWidth()
    local s = self.settings
    local n = #self.cells
    if n == 0 then return 0 end
    if s.vertical then
        return PAD * 2 + s.cellW
    end
    return PAD * 2 + n * s.cellW + (n - 1) * s.gap
end

function CSR_StatusBarPanel:computeHeight()
    local s = self.settings
    local n = #self.cells
    if n == 0 then return 0 end
    if s.vertical then
        return PAD * 2 + n * s.cellH + (n - 1) * s.gap
    end
    return PAD * 2 + s.cellH
end

function CSR_StatusBarPanel:anchorToHotbar()
    local s = self.settings
    if s.detached then
        if s.detachedX then self:setX(s.detachedX) end
        if s.detachedY then self:setY(s.detachedY) end
        return
    end
    local hotbar = getPlayerHotbar and getPlayerHotbar(self.playerNum) or nil
    local totalW = self:computeWidth()
    local totalH = self:computeHeight()
    self:setWidth(totalW)
    self:setHeight(totalH)
    if hotbar and hotbar.javaObject and hotbar:getIsVisible() then
        local hx = hotbar:getX()
        local hy = hotbar:getY()
        local hw = hotbar:getWidth()
        if s.vertical then
            -- Vertical bar sits to the LEFT of the hotbar, top-aligned with its top
            self:setX(hx - totalW - 4)
            self:setY(hy - totalH + (tonumber(hotbar:getHeight()) or 0))
        else
            -- Centered above the hotbar with 4px gap
            self:setX(hx + math.floor((hw - totalW) / 2))
            self:setY(hy - self.height - 4)
        end
    else
        local sw = getCore():getScreenWidth()
        local sh = getCore():getScreenHeight()
        if s.vertical then
            self:setX(sw - totalW - 16)
            self:setY(math.floor((sh - totalH) / 2))
        else
            self:setX(math.floor((sw - totalW) / 2))
            self:setY(sh - self.height - 80)
        end
    end
end

function CSR_StatusBarPanel:restoreDefaultCells()
    if not self.settings then return end
    self.settings.enabled = {}
    for id, v in pairs(DEFAULT_ENABLED) do self.settings.enabled[id] = v end
    self:rebuildCells()
    self:saveSettings()
end

function CSR_StatusBarPanel:prerender()
    if not CSR_FeatureFlags.isStatusBarEnabled() then
        self:setVisible(false)
        return
    end
    if not self._loaded then
        self._loaded = true
        self:loadFromModData()
        self:rebuildCells()
    end
    if not self.settings then
        self:setVisible(false)
        return
    end
    if #self.cells == 0 then
        -- All cells hidden is a valid player choice. Older behavior treated
        -- it as corrupt settings and restored defaults, making the bar
        -- impossible to fully hide one cell at a time.
        self.dragging = false
        self._dragMoved = false
        self._suppressedForVehicle = false
        self:setWidth(0)
        self:setHeight(0)
        self:setVisible(true)
        return
    end
    self._suppressedForVehicle = not self.settings.detached
        and getActiveVehicleDashboard(self.playerNum) ~= nil
    if self._suppressedForVehicle then
        self.dragging = false
        self._dragMoved = false
    end
    self:setVisible(true)

    self.cacheTick = self.cacheTick + 1
    if self.cacheTick >= CACHE_TICKS then
        self.cacheTick = 0
        self:refreshValues()
    end
    if not self.dragging then
        self:anchorToHotbar()
    end
end

local function pulseAlpha(t)
    -- 1 Hz pulse between 0.55 and 1.0
    return 0.55 + 0.45 * (0.5 + 0.5 * math.sin(t * 2 * math.pi))
end

function CSR_StatusBarPanel:render()
    if not self.settings then return end
    if self._suppressedForVehicle then return end
    local s = self.settings
    local op = clamp(s.opacity or 1.0, OPACITY_MIN, OPACITY_MAX)
    local borderFloor = 0.45
    local iconFloor = 0.6
    local textFloor = 0.7

    local theme = CSR_Theme.colors
    local panelBg = theme.panelBg or { r = 0.06, g = 0.07, b = 0.09 }
    local panelBorder = theme.panelBorder or { r = 0.29, g = 0.35, b = 0.42 }

    local now = getTimestampMs and (getTimestampMs() / 1000.0) or os.clock()

    local cw = s.cellW
    local ch = s.cellH
    local gap = s.gap
    local fontH = getTextManager():getFontHeight(UIFont.Small)
    local useFont = (ch >= 18) and UIFont.Small or UIFont.Tiny

    -- Outer subtle background strip
    self:drawRect(0, 0, self.width, self.height, math.min(op, 0.55), panelBg.r, panelBg.g, panelBg.b)
    self:drawRectBorder(0, 0, self.width, self.height,
        math.max(borderFloor, op * 0.6),
        panelBorder.r, panelBorder.g, panelBorder.b)

    local vertical = s.vertical == true
    local x = PAD
    local y = PAD
    local mx, my = getMouseX(), getMouseY()
    for _, cell in ipairs(self.cells) do
        local def = cell.def
        local r, g, b = def.color[1], def.color[2], def.color[3]
        local v = cell.value or 0

        -- Cell background
        self:drawRect(x, y, cw, ch, math.min(op, 0.85), 0.05, 0.06, 0.09)

        -- Bar fill (under icon area)
        local fillW = math.floor((cw - 2) * v)
        if fillW > 0 then
            self:drawRect(x + 1, y + 1, fillW, ch - 2, math.min(op, 0.85) * 0.85, r, g, b)
        end

        -- Icon (left)
        local iconS = math.min(ch - 4, 16)
        local iconY = y + math.floor((ch - iconS) / 2)
        local iconTex = getTexture(def.icon)
        if iconTex then
            self:drawTextureScaled(iconTex, x + 2, iconY, iconS, iconS,
                math.max(iconFloor, op), 1, 1, 1)
        end

        -- Value text (right side of cell)
        local txt
        if def.fmt then
            local ok, fv = pcall(def.fmt, getSpecificPlayer(self.playerNum))
            txt = ok and fv or (math.floor(v * 100) .. "%")
        else
            txt = math.floor(v * 100) .. "%"
        end
        local tw = getTextManager():MeasureStringX(useFont, txt)
        local tx = x + cw - tw - 3
        local ty = y + math.floor((ch - fontH) / 2)
        -- 1px shadow for legibility
        self:drawText(txt, tx + 1, ty + 1, 0, 0, 0, math.min(op, 0.7), useFont)
        self:drawText(txt, tx, ty, 1, 1, 1, math.max(textFloor, op), useFont)

        -- Border: affected = stat color pulsing; fine = faint CSR border
        if cell.affected then
            local pa = pulseAlpha(now)
            self:drawRectBorder(x, y, cw, ch, pa, r, g, b)
            -- Inner glow line
            self:drawRect(x, y, cw, 1, pa * 0.45, r, g, b)
            self:drawRect(x, y + ch - 1, cw, 1, pa * 0.45, r, g, b)
        else
            self:drawRectBorder(x, y, cw, ch, math.max(borderFloor, op * 0.55),
                panelBorder.r, panelBorder.g, panelBorder.b)
        end

        -- Hover tooltip
        local ax, ay = self:getAbsoluteX() + x, self:getAbsoluteY() + y
        if mx >= ax and mx < ax + cw and my >= ay and my < ay + ch then
            self:drawRectBorder(x, y, cw, ch, 0.95, 1, 1, 1)
            self:drawCellTooltip(x, y, cw, ch, def, v)
        end

        if vertical then
            y = y + ch + gap
        else
            x = x + cw + gap
        end
    end
end

function CSR_StatusBarPanel:drawCellTooltip(cx, cy, cw, ch, def, v)
    local lines = {}
    local label = getText(def.label)
    if label == def.label then label = def.id end
    table.insert(lines, label)
    if def.fmt then
        local ok, fv = pcall(def.fmt, getSpecificPlayer(self.playerNum))
        if ok then table.insert(lines, fv) end
    else
        table.insert(lines, math.floor(v * 100) .. "%")
    end
    table.insert(lines, getText("IGUI_CSR_StatusBar_TipRightClick"))

    local font = CSR_Scale.font(14)
    local tm = getTextManager()
    local lh = tm:getFontHeight(font)
    local maxW = 0
    for _, l in ipairs(lines) do
        local w = tm:MeasureStringX(font, l)
        if w > maxW then maxW = w end
    end
    local pad = CSR_Scale.px(5)
    local boxW = maxW + pad * 2
    local boxH = #lines * lh + pad * 2
    local bx = cx + math.floor((cw - boxW) / 2)
    local by = cy - boxH - CSR_Scale.px(6)
    if self:getAbsoluteY() + by < 0 then by = cy + ch + CSR_Scale.px(6) end
    local screenX, screenY, screenW, screenH = getPlayerScreenBounds(self.playerNum)
    local absX = self:getAbsoluteX()
    local absY = self:getAbsoluteY()
    local minBx = screenX - absX + 2
    local maxBx = screenX + screenW - absX - boxW - 2
    local minBy = screenY - absY + 2
    local maxBy = screenY + screenH - absY - boxH - 2
    if maxBx < minBx then maxBx = minBx end
    if maxBy < minBy then maxBy = minBy end
    bx = clamp(bx, minBx, maxBx)
    by = clamp(by, minBy, maxBy)
    local bg = CSR_Theme.colors.panelBg
    local bd = CSR_Theme.colors.panelBorder
    self:drawRect(bx, by, boxW, boxH, 0.92, bg.r, bg.g, bg.b)
    self:drawRectBorder(bx, by, boxW, boxH, 0.85, bd.r, bd.g, bd.b)
    for i, l in ipairs(lines) do
        self:drawText(l, bx + pad, by + pad + (i - 1) * lh, 1, 1, 1, 1, font)
    end
end

-- ─────────────────────────────────────────────────────
-- Mouse
-- ─────────────────────────────────────────────────────
local function cellAt(self, x, y)
    local s = self.settings
    if not s then return nil end
    if s.vertical then
        if x < PAD or x > self.width - PAD then return nil end
        local cy = PAD
        for _, cell in ipairs(self.cells) do
            if y >= cy and y < cy + s.cellH then return cell end
            cy = cy + s.cellH + s.gap
        end
        return nil
    end
    if y < PAD or y > self.height - PAD then return nil end
    local cx = PAD
    for _, cell in ipairs(self.cells) do
        if x >= cx and x < cx + s.cellW then return cell end
        cx = cx + s.cellW + s.gap
    end
    return nil
end

function CSR_StatusBarPanel:onMouseDown(x, y)
    if self._suppressedForVehicle then return false end
    if self.settings then
        self.dragging = true
        self.dragOffX = x
        self.dragOffY = y
        self._dragStartX = self.x
        self._dragStartY = self.y
        self._dragMoved = false
    end
    return true
end

function CSR_StatusBarPanel:onMouseUp(x, y)
    if self._suppressedForVehicle then return false end
    self.dragging = false
    if self.settings and self._dragMoved then
        -- First real drag promotes the bar to detached mode and persists position.
        self.settings.detached = true
        self.settings.detachedX = self.x
        self.settings.detachedY = self.y
        self:saveSettings()
    end
    self._dragMoved = false
end

function CSR_StatusBarPanel:onMouseUpOutside(x, y)
    self:onMouseUp(x, y)
end

function CSR_StatusBarPanel:onMouseMove(dx, dy)
    if self._suppressedForVehicle then return false end
    if self.dragging then
        local mx = getMouseX()
        local my = getMouseY()
        local nx = clamp(mx - self.dragOffX, 0, getCore():getScreenWidth() - self.width)
        local ny = clamp(my - self.dragOffY, 0, getCore():getScreenHeight() - self.height)
        if nx ~= self._dragStartX or ny ~= self._dragStartY then
            self._dragMoved = true
        end
        self:setX(nx)
        self:setY(ny)
    end
end

function CSR_StatusBarPanel:onRightMouseUp(x, y)
    if self._suppressedForVehicle then return false end
    local cell = cellAt(self, x, y)
    self:openContextMenu(x, y, cell)
    return true
end

function CSR_StatusBarPanel:openContextMenu(mx, my, hoveredCell)
    local context = ISContextMenu.get(self.playerNum,
        self:getAbsoluteX() + mx, self:getAbsoluteY() + my)
    if not context then return end

    if hoveredCell then
        local label = getText(hoveredCell.def.label)
        if label == hoveredCell.def.label then label = hoveredCell.def.id end
        context:addOption(getText("IGUI_CSR_StatusBar_HideThis", label), self, function(self_)
            self_.settings.enabled[hoveredCell.def.id] = false
            self_:rebuildCells()
            self_:saveSettings()
        end)
    end

    -- Submenu: enable/disable individual stats
    local submenu = ISContextMenu:getNew(context)
    local statsOpt = context:addOption(getText("IGUI_CSR_StatusBar_Stats"), self, nil)
    context:addSubMenu(statsOpt, submenu)
    for _, def in ipairs(CSR_StatusBar.STATS) do
        local available = (not def.available) or def.available()
        if available then
            local label = getText(def.label)
            if label == def.label then label = def.id end
            local enabled = self.settings.enabled[def.id] == true
            local prefix = enabled and "[X] " or "[ ] "
            submenu:addOption(prefix .. label, self, function(self_)
                self_.settings.enabled[def.id] = not enabled
                self_:rebuildCells()
                self_:saveSettings()
            end)
        end
    end

    -- Opacity submenu
    local opSubmenu = ISContextMenu:getNew(context)
    local opOpt = context:addOption(getText("IGUI_CSR_StatusBar_Opacity"), self, nil)
    context:addSubMenu(opOpt, opSubmenu)
    local opacities = { 0.25, 0.5, 0.75, 1.0 }
    for _, op in ipairs(opacities) do
        local label = string.format("%d%%", math.floor(op * 100))
        if math.abs((self.settings.opacity or 1.0) - op) < 0.01 then
            label = "[X] " .. label
        else
            label = "[ ] " .. label
        end
        opSubmenu:addOption(label, self, function(self_)
            self_.settings.opacity = op
            self_:saveSettings()
        end)
    end

    -- Cell width submenu
    local wSubmenu = ISContextMenu:getNew(context)
    local wOpt = context:addOption(getText("IGUI_CSR_StatusBar_CellWidth"), self, nil)
    context:addSubMenu(wOpt, wSubmenu)
    for _, w in ipairs({ 40, 48, 56, 72, 88 }) do
        local label = tostring(w) .. "px"
        if self.settings.cellW == w then label = "[X] " .. label else label = "[ ] " .. label end
        wSubmenu:addOption(label, self, function(self_)
            self_.settings.cellW = w
            self_:saveSettings()
        end)
    end

    -- Cell height submenu
    local hSubmenu = ISContextMenu:getNew(context)
    local hOpt = context:addOption(getText("IGUI_CSR_StatusBar_CellHeight"), self, nil)
    context:addSubMenu(hOpt, hSubmenu)
    for _, h in ipairs({ 18, 22, 26, 30 }) do
        local label = tostring(h) .. "px"
        if self.settings.cellH == h then label = "[X] " .. label else label = "[ ] " .. label end
        hSubmenu:addOption(label, self, function(self_)
            self_.settings.cellH = h
            self_:saveSettings()
        end)
    end

    -- Detached / anchored
    local dLabel = self.settings.detached and getText("IGUI_CSR_StatusBar_Anchor") or getText("IGUI_CSR_StatusBar_Detach")
    context:addOption(dLabel, self, function(self_)
        self_.settings.detached = not self_.settings.detached
        if self_.settings.detached then
            self_.settings.detachedX = self_.x
            self_.settings.detachedY = self_.y
        end
        self_:saveSettings()
    end)

    -- Orientation toggle
    local oLabel = self.settings.vertical
        and getText("IGUI_CSR_StatusBar_Horizontal")
        or  getText("IGUI_CSR_StatusBar_Vertical")
    context:addOption(oLabel, self, function(self_)
        self_.settings.vertical = not self_.settings.vertical
        -- Forget detached coords on flip so the new layout snaps to its anchor.
        self_.settings.detached  = false
        self_.settings.detachedX = nil
        self_.settings.detachedY = nil
        self_:saveSettings()
    end)

    -- Reset
    context:addOption(getText("IGUI_CSR_StatusBar_Reset"), self, function(self_)
        self_.settings.enabled = {}
        for id, v in pairs(DEFAULT_ENABLED) do self_.settings.enabled[id] = v end
        self_.settings.opacity = 0.92
        self_.settings.cellW = CSR_Scale.px(DEFAULT_CELL_W)
        self_.settings.cellH = CSR_Scale.px(DEFAULT_CELL_H)
        self_.settings.gap = CSR_Scale.px(CELL_GAP)
        self_.settings.detached = false
        self_.settings.detachedX = nil
        self_.settings.detachedY = nil
        self_.settings.vertical = false
        self_:rebuildCells()
        self_:saveSettings()
    end)
end

-- ─────────────────────────────────────────────────────
-- Lifecycle
-- ─────────────────────────────────────────────────────
local panels = {}

local function createForPlayer(playerNum)
    if panels[playerNum] then return end
    if not CSR_FeatureFlags.isStatusBarEnabled() then return end
    -- Soft-coexist with Simple Status MP if loaded; user can override via sandbox.
    if SimpleStatusPanel and not (SandboxVars.CommonSenseReborn and SandboxVars.CommonSenseReborn.EnableStatusBar) then
        return
    end
    local p = CSR_StatusBarPanel:new(playerNum)
    p:initialise()
    p:addToUIManager()
    panels[playerNum] = p
end

local function onCreatePlayer(playerNum)
    createForPlayer(playerNum or 0)
end

local function onPlayerDeath(player)
    if not player then return end
    local pn = player:getPlayerNum() or 0
    local p = panels[pn]
    if p then p:removeFromUIManager(); panels[pn] = nil end
end

if Events then
    if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(onCreatePlayer) end
    if Events.OnPlayerDeath then Events.OnPlayerDeath.Add(onPlayerDeath) end
end

return CSR_StatusBar
