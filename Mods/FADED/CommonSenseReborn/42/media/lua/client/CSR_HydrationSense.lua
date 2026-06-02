require "CSR_FeatureFlags"
require "ISUI/ISInventoryPaneContextMenu"

CSR_HydrationSense = CSR_HydrationSense or {}

local AUTO_THRESHOLD = 0.12
local MANUAL_THRESHOLD = 0.18
local DANGEROUS_THRESHOLD = 0.85
local AUTO_COOLDOWN_MS = 45000
local REMINDER_COOLDOWN_MS = 300000
local PLAYER_DISABLED_KEY = "CSR_HydrationSenseDisabled"
local COMBAT_ZOMBIE_RADIUS_SQ = 36

local lastAutoMs = {}
local lastReminderMs = {}

local DANGEROUS_TYPE = {
    TaintedWater = true,
    Petrol = true,
    RubbingAlcohol = true,
    Cologne = true,
    Perfume = true,
    PoisonPotent = true,
    Bleach = true,
    CleaningLiquid = true,
}

local DANGEROUS_CATEGORY = {
    "Alcoholic",
    "Fuel",
    "Hazardous",
    "Industrial",
    "Medical",
    "Poisons",
}

local function tr(key, fallback)
    local s = getText and getText(key) or nil
    if not s or s == "" or s == key then return fallback end
    return s
end

local function nowMs()
    if getTimestampMs then return getTimestampMs() end
    if os and os.time then return os.time() * 1000 end
    return 0
end

local function playerKey(playerObj)
    if not playerObj then return "0" end
    if playerObj.getOnlineID then
        local id = playerObj:getOnlineID()
        if id ~= nil then return tostring(id) end
    end
    if playerObj.getUsername then
        local name = playerObj:getUsername()
        if name and name ~= "" then return tostring(name) end
    end
    if playerObj.getPlayerNum then return tostring(playerObj:getPlayerNum()) end
    return "0"
end

local function haloColor(value, fallback)
    local v = value
    if v == nil then v = fallback end
    v = tonumber(v) or 255
    if v <= 1 then
        v = v * 255
    end
    if v < 0 then return 0 end
    if v > 255 then return 255 end
    return math.floor(v + 0.5)
end

local function halo(playerObj, key, fallback, r, g, b)
    if not playerObj or not playerObj.setHaloNote then return end
    playerObj:setHaloNote(
        tr(key, fallback),
        haloColor(r, 1.0),
        haloColor(g, 0.75),
        haloColor(b, 0.25),
        250
    )
end

local function getPlayerModData(playerObj)
    if not playerObj or not playerObj.getModData then return nil end
    return playerObj:getModData()
end

function CSR_HydrationSense.isPlayerEnabled(playerObj)
    if not CSR_FeatureFlags.isHydrationSenseEnabled() then return false end
    playerObj = playerObj or (getPlayer and getPlayer() or nil)
    local md = getPlayerModData(playerObj)
    return not (md and md[PLAYER_DISABLED_KEY] == true)
end

function CSR_HydrationSense.setPlayerEnabled(playerObj, enabled, quiet)
    playerObj = playerObj or (getPlayer and getPlayer() or nil)
    local md = getPlayerModData(playerObj)
    if not md then return false end

    if enabled == false then
        md[PLAYER_DISABLED_KEY] = true
        if not quiet then
            halo(playerObj, "IGUI_CSR_HydrationSense_Off", "Hydration Sense disabled.", 1.0, 0.45, 0.25)
        end
        return false
    end

    md[PLAYER_DISABLED_KEY] = nil
    if not quiet then
        halo(playerObj, "IGUI_CSR_HydrationSense_On", "Hydration Sense enabled.", 0.45, 1.0, 0.45)
    end
    return true
end

function CSR_HydrationSense.togglePlayerEnabled(playerObj)
    playerObj = playerObj or (getPlayer and getPlayer() or nil)
    return CSR_HydrationSense.setPlayerEnabled(playerObj, not CSR_HydrationSense.isPlayerEnabled(playerObj), false)
end

local function methodTrue(obj, methodName)
    return obj and obj[methodName] and obj[methodName](obj) == true
end

local function variableTrue(playerObj, variableName)
    if not playerObj or not playerObj.getVariableBoolean then return false end
    return playerObj:getVariableBoolean(variableName) == true
end

local function hasNearbyCombatZombie(playerObj)
    if not playerObj then return false end
    local cell = getCell and getCell() or nil
    if not cell then return false end
    local objects = cell.getObjectListForLua and cell:getObjectListForLua() or nil
    if not objects then return false end

    local px = playerObj:getX()
    local py = playerObj:getY()
    local pz = math.floor(tonumber(playerObj:getZ()) or 0)
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj and instanceof(obj, "IsoZombie") and not obj:isDead() then
            local oz = math.floor(tonumber(obj:getZ()) or 0)
            if oz == pz then
                local dx = obj:getX() - px
                local dy = obj:getY() - py
                local distSq = dx * dx + dy * dy
                if distSq <= COMBAT_ZOMBIE_RADIUS_SQ then
                    if distSq <= 9 then return true end
                    if obj.getTarget and obj:getTarget() == playerObj then return true end
                end
            end
        end
    end

    return false
end

function CSR_HydrationSense.isAutoDrinkBlocked(playerObj)
    if not playerObj then return true end
    if methodTrue(playerObj, "isAiming") then return true end
    if methodTrue(playerObj, "isDoShove") then return true end
    if methodTrue(playerObj, "isDoStomp") then return true end
    if variableTrue(playerObj, "AttackStarted")
            or variableTrue(playerObj, "isAttacking")
            or variableTrue(playerObj, "Bashing") then
        return true
    end
    return hasNearbyCombatZombie(playerObj)
end

local function getThirst(playerObj)
    local stats = playerObj and playerObj.getStats and playerObj:getStats() or nil
    if not stats then return 0 end
    if stats.get and CharacterStat and CharacterStat.THIRST then
        return tonumber(stats:get(CharacterStat.THIRST)) or 0
    end
    if stats.getThirst then
        return tonumber(stats:getThirst()) or 0
    end
    return 0
end

local function hasQueuedAction(playerObj)
    if not ISTimedActionQueue or not ISTimedActionQueue.getTimedActionQueue then return false end
    local q = ISTimedActionQueue.getTimedActionQueue(playerObj)
    return q and q.queue and #q.queue > 0
end

local function fluidAmount(fc)
    if not fc then return 0 end
    if fc.getFluidAmount then return tonumber(fc:getFluidAmount()) or 0 end
    if fc.getAmount then return tonumber(fc:getAmount()) or 0 end
    return 0
end

local function thirstChange(fc)
    local props = fc and fc.getProperties and fc:getProperties() or nil
    if props and props.getThirstChange then
        return tonumber(props:getThirstChange()) or 0
    end
    return 0
end

local function fluidType(fluid)
    if not fluid or not fluid.getFluidTypeString then return "" end
    return tostring(fluid:getFluidTypeString() or "")
end

local function fluidIsCategory(fluid, categoryName)
    if not fluid or not fluid.isCategory or not FluidCategory then return false end
    local category = FluidCategory[categoryName]
    return category ~= nil and fluid:isCategory(category) == true
end

local function isDangerousFluid(fc, fluid)
    local ftype = fluidType(fluid)
    if DANGEROUS_TYPE[ftype] then return true end
    if Fluid and Fluid.TaintedWater and fc and fc.contains and fc:contains(Fluid.TaintedWater) then
        return true
    end
    for i = 1, #DANGEROUS_CATEGORY do
        if fluidIsCategory(fluid, DANGEROUS_CATEGORY[i]) then return true end
    end
    return false
end

local function isWater(fc, fluid)
    if fc and fc.isWaterSource and fc:isWaterSource() then return true end
    local ftype = fluidType(fluid)
    return ftype == "Water" or ftype == "CarbonatedWater"
end

local function openingRecipeFor(playerObj, item)
    if not item or not item.isSealed or not item:isSealed() then return nil end
    if not item.getOpeningRecipe then return nil end
    local recipeName = item:getOpeningRecipe()
    if not recipeName or recipeName == "" then return nil end
    if not getScriptManager then return nil end

    local recipe = getScriptManager():getCraftRecipe(recipeName)
    if not recipe or not HandcraftLogic or not ISInventoryPaneContextMenu.getContainers then
        return nil
    end

    local logic = HandcraftLogic.new(playerObj, nil, nil)
    logic:setContainers(ISInventoryPaneContextMenu.getContainers(playerObj))
    logic:setRecipeFromContextClick(recipe, item)
    if not logic:canPerformCurrentRecipe() then return nil end
    return recipe
end

local function classify(playerObj, item)
    if not item or not item.getFluidContainer then return nil end
    if item.getJobDelta and item:getJobDelta() > 0 then return nil end

    local fc = item:getFluidContainer()
    if not fc or (fc.isEmpty and fc:isEmpty()) then return nil end

    local amount = fluidAmount(fc)
    if amount <= 0 then return nil end

    local fluid = fc.getPrimaryFluid and fc:getPrimaryFluid() or nil
    if not fluid then return nil end

    local openingRecipe = openingRecipeFor(playerObj, item)
    if item.isSealed and item:isSealed() and not openingRecipe then return nil end

    local dangerous = isDangerousFluid(fc, fluid)
    local water = isWater(fc, fluid)
    local beverage = fluidIsCategory(fluid, "Beverage")
    local tChange = thirstChange(fc)
    local safe = not dangerous and (water or beverage or tChange < 0)

    local score = 50
    if safe and water then
        score = 1
    elseif safe and beverage then
        score = 2
    elseif safe then
        score = 3
    elseif dangerous then
        score = 10
    end

    return {
        item = item,
        amount = amount,
        openingRecipe = openingRecipe,
        score = score,
        safe = safe,
        dangerous = dangerous or not safe,
    }
end

local function prefer(a, b)
    if not a then return b end
    if not b then return a end
    if b.score ~= a.score then
        return b.score < a.score and b or a
    end
    return b.amount > a.amount and b or a
end

local function findBestDrink(playerObj, allowDangerous)
    local inv = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    if not inv or not inv.getAllEvalRecurse or not ArrayList then return nil end

    local candidates = inv:getAllEvalRecurse(function(item)
        return item and item.getFluidContainer and item:getFluidContainer() ~= nil
    end, ArrayList.new())
    if not candidates then return nil end

    local bestSafe = nil
    local bestDanger = nil
    for i = 0, candidates:size() - 1 do
        local candidate = classify(playerObj, candidates:get(i))
        if candidate then
            if candidate.safe then
                bestSafe = prefer(bestSafe, candidate)
            else
                bestDanger = prefer(bestDanger, candidate)
            end
        end
    end

    if bestSafe then return bestSafe end
    if allowDangerous then return bestDanger end
    return nil
end

local function drinkPercent(playerObj, candidate)
    local thirst = getThirst(playerObj)
    if candidate and candidate.dangerous then
        return 0.10
    end
    local amount = candidate and candidate.amount or 0
    if amount <= 0 then return 1.0 end
    local percent = (thirst * 2) / amount
    if percent < 0.05 then percent = 0.05 end
    if percent > 1.0 then percent = 1.0 end
    return percent
end

function CSR_HydrationSense.drinkNow(playerObj, quiet)
    if not CSR_FeatureFlags.isHydrationSenseEnabled() then return false end
    playerObj = playerObj or (getPlayer and getPlayer() or nil)
    if not playerObj or playerObj:isDead() then return false end
    if hasQueuedAction(playerObj) then return false end

    local thirst = getThirst(playerObj)
    local allowDangerous = CSR_FeatureFlags.isDangerousThirstEnabled()
        and thirst >= DANGEROUS_THRESHOLD
    local candidate = findBestDrink(playerObj, allowDangerous)
    if not candidate then
        if not quiet then
            halo(playerObj, "IGUI_CSR_HydrationSense_NoDrink", "No drink found.", 1.0, 0.35, 0.25)
        end
        return false
    end

    ISInventoryPaneContextMenu.onDrinkFluid(
        candidate.item,
        drinkPercent(playerObj, candidate),
        playerObj,
        candidate.openingRecipe,
        candidate.openingRecipe and candidate.item or nil
    )
    return true
end

local function autoDrink(playerObj)
    if not CSR_HydrationSense.isPlayerEnabled(playerObj) then return end
    if CSR_FeatureFlags.getHydrationSenseMode
            and CSR_FeatureFlags.getHydrationSenseMode() ~= "auto" then return end
    if CSR_HydrationSense.isAutoDrinkBlocked(playerObj) then return end

    local thirst = getThirst(playerObj)
    if thirst < AUTO_THRESHOLD then return end
    if hasQueuedAction(playerObj) then return end

    local key = playerKey(playerObj)
    local now = nowMs()
    if lastAutoMs[key] and (now - lastAutoMs[key]) < AUTO_COOLDOWN_MS then return end
    lastAutoMs[key] = now

    CSR_HydrationSense.drinkNow(playerObj, true)
end

local function manualReminder(playerObj)
    if not CSR_HydrationSense.isPlayerEnabled(playerObj) then return end

    local thirst = getThirst(playerObj)
    if thirst < MANUAL_THRESHOLD then return end

    local key = playerKey(playerObj)
    local now = nowMs()
    if lastReminderMs[key] and (now - lastReminderMs[key]) < REMINDER_COOLDOWN_MS then return end
    lastReminderMs[key] = now

    halo(playerObj, "IGUI_CSR_HydrationSense_Thirsty", "You are thirsty.", 1.0, 0.72, 0.25)
end

local function onEveryOneMinute()
    if not CSR_FeatureFlags.isHydrationSenseEnabled() then return end
    local count = getNumActivePlayers and getNumActivePlayers() or 1
    for i = 0, count - 1 do
        local playerObj = getSpecificPlayer and getSpecificPlayer(i) or getPlayer()
        if playerObj and not playerObj:isDead() then
            if not CSR_HydrationSense.isPlayerEnabled(playerObj) then
                -- Player-local toggle is off; sandbox option remains unchanged.
            elseif CSR_FeatureFlags.getHydrationSenseMode() == "manual" then
                manualReminder(playerObj)
            else
                autoDrink(playerObj)
            end
        end
    end
end

if Events and Events.EveryOneMinute and not CSR_HydrationSense._registered then
    CSR_HydrationSense._registered = true
    Events.EveryOneMinute.Add(onEveryOneMinute)
end

return CSR_HydrationSense
