CSR_CorpseFlesh = CSR_CorpseFlesh or {}

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function eatenFraction(percent)
    local value = tonumber(percent) or 1
    return clamp(value, 0, 1)
end

local function addStat(player, stat, amount)
    if not player or not stat or not amount or amount <= 0 then
        return false
    end

    local stats = player.getStats and player:getStats() or nil
    if not stats or not stats.get or not stats.set then
        return false
    end

    local current = tonumber(stats:get(stat)) or 0
    stats:set(stat, clamp(current + amount, 0, 100))
    return true
end

local function addFoodSickness(player, amount)
    if CharacterStat and CharacterStat.FOOD_SICKNESS and addStat(player, CharacterStat.FOOD_SICKNESS, amount) then
        return
    end

    local bodyDamage = player and player.getBodyDamage and player:getBodyDamage() or nil
    if bodyDamage and bodyDamage.getFoodSicknessLevel and bodyDamage.setFoodSicknessLevel then
        local lvl = tonumber(bodyDamage:getFoodSicknessLevel()) or 0
        bodyDamage:setFoodSicknessLevel(clamp(lvl + amount, 0, 100))
    end
end

local function addNausea(player, amount)
    if CharacterStat and CharacterStat.SICKNESS then
        addStat(player, CharacterStat.SICKNESS, amount)
    end
end

local function applyCorpseFleshPenalty(player, percent, foodSickness, nausea)
    local scale = eatenFraction(percent)
    if scale <= 0 then
        return
    end

    addFoodSickness(player, foodSickness * scale)
    addNausea(player, nausea * scale)
end

function CSR_CorpseFlesh.onEatZombieRaw(food, player, percent)
    applyCorpseFleshPenalty(player, percent, 12, 3)
end

function CSR_CorpseFlesh.onEatZombieCooked(food, player, percent)
    applyCorpseFleshPenalty(player, percent, 5, 1)
end

function CSR_CorpseFlesh.onEatHumanRaw(food, player, percent)
    applyCorpseFleshPenalty(player, percent, 8, 2)
end

function CSR_CorpseFlesh.onEatHumanCooked(food, player, percent)
    applyCorpseFleshPenalty(player, percent, 3, 1)
end

return CSR_CorpseFlesh
