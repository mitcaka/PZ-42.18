AdvancedDrying42 = AdvancedDrying42 or {}
AdvancedDrying42.Utils = AdvancedDrying42.Utils or {}

local Utils = AdvancedDrying42.Utils

function Utils.safeCall(fn)
    local ok, value = pcall(fn)
    if ok then
        return value
    end
    return nil
end

function Utils.safeSet(item, setterName, value)
    if not item or not item[setterName] then
        return
    end

    pcall(function()
        item[setterName](item, value)
    end)
end

function Utils.getItemWeight(item)
    if not item then
        return 0
    end
    -- Inner Food often holds real mass in B42.
    local food = Utils.getInnerFood(item)
    if food then
        local w = Utils.safeCall(function()
            return food:getActualWeight()
        end)
        if w ~= nil and w > 0 then
            return w
        end
        w = Utils.safeCall(function()
            return food:getWeight()
        end)
        if w ~= nil and w > 0 then
            return w
        end
    end
    return Utils.safeCall(function() return item:getActualWeight() end)
        or Utils.safeCall(function() return item:getWeight() end)
        or 0
end

function Utils.getNutrition(item, getter)
    if not item or not getter then
        return 0
    end
    -- Prefer inner Food; shell can have script placeholders.
    local food = Utils.getInnerFood(item)
    if food and food[getter] then
        local v = Utils.safeCall(function()
            return food[getter](food)
        end)
        if v ~= nil and v > 0 then
            return v
        end
    end
    if item[getter] then
        local v = Utils.safeCall(function()
            return item[getter](item)
        end)
        if v ~= nil then
            return v
        end
    end
    return 0
end

-- Skip JNI-unsafe hunger reads on these full types.
local HUNGER_GETTER_BLOCKED_FT = {
    ["Base.PanFriedVegetablesForged"] = true,
}

local function tryHungerFromEntity(entity)
    if not entity then
        return nil
    end
    local order = { "getHungChange", "getHungerChange", "getBaseHunger" }
    for i = 1, #order do
        local name = order[i]
        if entity[name] then
            local v = Utils.safeCall(function()
                return entity[name](entity)
            end)
            if v ~= nil then
                return v
            end
        end
    end
    return nil
end

function Utils.getHunger(item)
    if not item then
        return -1
    end
    local ft = nil
    pcall(function()
        if item.getFullType then
            ft = item:getFullType()
        end
    end)
    if ft and HUNGER_GETTER_BLOCKED_FT[ft] then
        return -1
    end
    local h = tryHungerFromEntity(item)
    if h ~= nil then
        return h
    end
    h = tryHungerFromEntity(Utils.getInnerFood(item))
    if h ~= nil then
        return h
    end
    return -1
end

local function isFoodItem(it)
    if not it or type(instanceof) ~= "function" then
        return false
    end
    local ok, v = pcall(function()
        return instanceof(it, "Food")
    end)
    return ok and v == true
end

-- Food items under inv only (vessel contents), bounded depth.
local function collectFoodUnderInventory(inv, depth, out)
    if not inv or not inv.getItems or (depth or 0) > 6 then
        return
    end
    local items = inv:getItems()
    if not items or not items.size then
        return
    end
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if isFoodItem(it) then
            out[#out + 1] = it
        elseif it and it.getInventory then
            local sub = Utils.safeCall(function()
                return it:getInventory()
            end)
            if sub then
                collectFoodUnderInventory(sub, (depth or 0) + 1, out)
            end
        end
    end
end

local function foodWeightForCompare(it)
    if not it then
        return 0
    end
    local w = Utils.safeCall(function()
        return it:getActualWeight()
    end)
    if w ~= nil and w > 0 then
        return w
    end
    w = Utils.safeCall(function()
        return it:getWeight()
    end)
    return (w ~= nil and w > 0) and w or 0
end

-- Pan/pot evolved vessel: getFood / Food in this inventory; if several, heaviest wins. No player scan.
function Utils.resolveEvolvedVesselFood(vessel)
    if not vessel then
        return nil
    end
    if isFoodItem(vessel) then
        return vessel
    end
    if vessel.getFood then
        local food = Utils.safeCall(function()
            return vessel:getFood()
        end)
        if food then
            return food
        end
    end
    if vessel.getItemFood then
        local food = Utils.safeCall(function()
            return vessel:getItemFood()
        end)
        if food then
            return food
        end
    end
    if not vessel.getInventory then
        return nil
    end
    local inv = Utils.safeCall(function()
        return vessel:getInventory()
    end)
    if not inv then
        return nil
    end
    local foods = {}
    collectFoodUnderInventory(inv, 0, foods)
    local n = #foods
    if n == 0 then
        return nil
    end
    if n == 1 then
        return foods[1]
    end
    local best, bestW = foods[1], foodWeightForCompare(foods[1])
    for i = 2, n do
        local w = foodWeightForCompare(foods[i])
        if w > bestW then
            bestW = w
            best = foods[i]
        end
    end
    return best
end

function Utils.getInnerFood(item)
    if not item then
        return nil
    end

    if item.getFood then
        local food = Utils.safeCall(function()
            return item:getFood()
        end)
        if food then
            return food
        end
    end

    if item.getItemFood then
        local food = Utils.safeCall(function()
            return item:getItemFood()
        end)
        if food then
            return food
        end
    end

    return nil
end

function Utils.getWeightForOneSaltingUnit(item)
    if not item then
        return 0
    end

    local food = Utils.getInnerFood(item)
    local w

    if food then
        w = Utils.safeCall(function()
            return food:getActualWeight()
        end) or Utils.safeCall(function()
            return food:getWeight()
        end)
    end

    if not w or w <= 0 then
        w = Utils.getItemWeight(item)
    end

    local cnt = Utils.safeCall(function()
        return item:getCount()
    end)
    cnt = cnt and tonumber(cnt) or 1
    if cnt < 1 then
        cnt = 1
    end
    if cnt > 1 then
        w = w / cnt
    end

    local delta = nil
    pcall(function()
        if item.getUsedDelta then
            delta = item:getUsedDelta()
        end
    end)
    if (not delta or delta <= 0 or delta > 1) and food then
        pcall(function()
            if food.getUsedDelta then
                delta = food:getUsedDelta()
            end
        end)
    end
    if delta and delta > 0 and delta <= 1 then
        w = w * delta
    end

    return w
end

--- Total displayed mass, one craft unit (after stack count / used delta), and nutrition scale for that unit.
function Utils.computeSaltingWeights(item)
    local aggregateW = Utils.getItemWeight(item)
    local sourceWeight = Utils.getWeightForOneSaltingUnit(item)

    local nutrScale = 1
    if aggregateW > 0 and sourceWeight > 0 then
        nutrScale = sourceWeight / aggregateW
    end

    return aggregateW, sourceWeight, nutrScale
end
