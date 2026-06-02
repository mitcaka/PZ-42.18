CSR_MassageUtils = CSR_MassageUtils or {}

local STIFFNESS_SYNC_FLAGS = 0x00570188

local ARM_STRAIN_SETTERS = {
    "setLeftArmMuscleStrain",
    "setRightArmMuscleStrain",
}

local function removeFitnessStiffness(player, bodyPart)
    if not player or not bodyPart or not player.getFitness then return end
    local fitness = player:getFitness()
    if not fitness or not fitness.removeStiffnessValue then return end
    if not BodyPartType or not BodyPartType.ToString then return end
    if not bodyPart.getType then return end

    local partName = BodyPartType.ToString(bodyPart:getType())
    if partName then
        fitness:removeStiffnessValue(partName)
    end
end

local function clearBodyPartStiffness(player, bodyPart, doSync)
    if not bodyPart then return false end

    local changed = false
    if bodyPart.getStiffness and bodyPart.setStiffness then
        local stiffness = tonumber(bodyPart:getStiffness()) or 0
        if stiffness > 0 then changed = true end
        bodyPart:setStiffness(0)
    end

    removeFitnessStiffness(player, bodyPart)

    if doSync and syncBodyPart then
        syncBodyPart(bodyPart, STIFFNESS_SYNC_FLAGS)
    end

    return changed
end

local function clearKnownPlayerPools(player)
    local cleared = false
    if not player then return false end

    for i = 1, #ARM_STRAIN_SETTERS do
        local methodName = ARM_STRAIN_SETTERS[i]
        local method = player[methodName]
        if method then
            method(player, 0)
            cleared = true
        end
    end

    return cleared
end

function CSR_MassageUtils.clearAllMuscleStrain(player, doSync)
    if not player or not player.getBodyDamage then return false end

    local changed = clearKnownPlayerPools(player)
    local bd = player:getBodyDamage()
    local bodyParts = bd and bd.getBodyParts and bd:getBodyParts() or nil
    if bodyParts then
        for i = 0, bodyParts:size() - 1 do
            if clearBodyPartStiffness(player, bodyParts:get(i), doSync) then
                changed = true
            end
        end
        return changed
    end

    if bd and bd.getBodyPart and BodyPartType and BodyPartType.MAX and BodyPartType.FromIndex then
        local maxIdx = BodyPartType.MAX:index()
        for i = 0, maxIdx - 1 do
            if clearBodyPartStiffness(player, bd:getBodyPart(BodyPartType.FromIndex(i)), doSync) then
                changed = true
            end
        end
    end

    return changed
end

function CSR_MassageUtils.hasAnyStrain(player)
    if not player or not player.getBodyDamage then return false end
    local bd = player:getBodyDamage()
    local bodyParts = bd and bd.getBodyParts and bd:getBodyParts() or nil
    if not bodyParts then return false end

    for i = 0, bodyParts:size() - 1 do
        local part = bodyParts:get(i)
        if part and part.getStiffness then
            local stiffness = part:getStiffness()
            if (tonumber(stiffness) or 0) > 0 then
                return true
            end
        end
    end

    return false
end

function CSR_MassageUtils.hasStrain(bodyPart)
    if not bodyPart or not bodyPart.getStiffness then return false end
    local stiffness = bodyPart:getStiffness()
    return (tonumber(stiffness) or 0) > 0
end

return CSR_MassageUtils
