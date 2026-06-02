AdvancedDrying42 = AdvancedDrying42 or {}
AdvancedDrying42.Sandbox = AdvancedDrying42.Sandbox or {}

local Sandbox = AdvancedDrying42.Sandbox

local MIN_DRY_DAYS = 0.1
local MIN_RECIPE_TIME = 1
local MINUTES_PER_DAY = 1440 * 60

--- Временный хак: не-nil = сушка всегда столько **игровых** минут (мясо и рыба).
--- Откат: поставь nil — снова используются Sandbox MeatDryDays / FishDryDays.
local DEBUG_FIXED_DRY_GAME_MINUTES = nil

local function getModSandbox()
    if SandboxVars and SandboxVars.AdvancedDrying42 then
        return SandboxVars.AdvancedDrying42
    end

    return nil
end

local function getSandboxNumber(key, fallback)
    local vars = getModSandbox()
    if vars and vars[key] ~= nil then
        local value = tonumber(vars[key])
        if value then
            return value
        end
    end

    local ok, opt = pcall(function()
        local opts = getSandboxOptions()
        if opts and opts.getOptionByName then
            return opts:getOptionByName("AdvancedDrying42." .. key)
        end
        return nil
    end)
    if ok and opt and opt.getValue then
        local value = tonumber(opt:getValue())
        if value then
            return value
        end
    end

    return fallback
end

function Sandbox.getMeatDryDays()
    local days = getSandboxNumber("MeatDryDays", 2.0)
    return math.max(MIN_DRY_DAYS, days)
end

function Sandbox.getFishDryDays()
    local days = getSandboxNumber("FishDryDays", 1.0)
    return math.max(MIN_DRY_DAYS, days)
end

local function daysToRecipeTime(days)
    local value = math.floor((days * MINUTES_PER_DAY) + 0.5)
    return math.max(MIN_RECIPE_TIME, value)
end

local function patchCraftRecipeTime(recipeName, timeValue)
    local recipe = getScriptManager():getCraftRecipe(recipeName)
    if not recipe then
        return
    end

    local script = "{ time = " .. tostring(timeValue) .. ", }"
    recipe:Load(recipeName, script)
end

function Sandbox.applyDryingTimes()
    local meatTime
    local fishTime
    if DEBUG_FIXED_DRY_GAME_MINUTES then
        local mins = math.max(1, tonumber(DEBUG_FIXED_DRY_GAME_MINUTES) or 1)
        local t = math.max(MIN_RECIPE_TIME, math.floor(mins * 60 + 0.5))
        meatTime = t
        fishTime = t
    else
        meatTime = daysToRecipeTime(Sandbox.getMeatDryDays())
        fishTime = daysToRecipeTime(Sandbox.getFishDryDays())
    end

    patchCraftRecipeTime("DrySaltedMeat", meatTime)
    patchCraftRecipeTime("DrySaltedFish", fishTime)
    patchCraftRecipeTime("DrySaltedFishFillet", fishTime)
end

Events.OnGameStart.Add(Sandbox.applyDryingTimes)

-- OnGameStart is client-only (PZ docs). Dedicated / MP server never runs it, so drying recipes
-- stay at script time=40 while clients patch locally and show long durations — drying finishes almost instantly on server.
if isServer() and Events.OnServerStarted then
    Events.OnServerStarted.Add(Sandbox.applyDryingTimes)
end
