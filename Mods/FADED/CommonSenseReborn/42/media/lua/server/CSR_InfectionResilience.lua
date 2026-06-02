if isClient and isClient() then
    return
end

require "CSR_FeatureFlags"
require "CSR_Antibodies"

CSR_InfectionResilience = CSR_InfectionResilience or {}

local function sb()
    return SandboxVars and SandboxVars.CommonSenseReborn or {}
end

local function getChanceToHeal()
    return tonumber(sb().InfResChanceToHeal) or 10
end

local function getPenalty()
    return tonumber(sb().InfResPenaltyMultiplier) or 1.5
end

local function getThresholdMin()
    return tonumber(sb().InfResThresholdMin) or 70
end

local function getThresholdMax()
    return tonumber(sb().InfResThresholdMax) or 95
end

local function getOrAssignThreshold(player)
    local md = player:getModData()
    if md.CSR_IR_Threshold then
        return md.CSR_IR_Threshold
    end

    local lo = getThresholdMin()
    local hi = getThresholdMax()
    if hi <= lo then hi = lo + 1 end
    local threshold = ZombRand(lo, hi + 1)
    md.CSR_IR_Threshold = threshold
    return threshold
end

local function clearModData(player)
    local md = player:getModData()
    md.CSR_IR_Threshold = nil
    md.CSR_IR_Doomed = nil
end

local function getInfectionPct(player)
    local stats = player and player.getStats and player:getStats() or nil
    if stats and CharacterStat and CharacterStat.ZOMBIE_INFECTION and stats.get then
        local ok, value = pcall(stats.get, stats, CharacterStat.ZOMBIE_INFECTION)
        if ok and value then
            value = tonumber(value) or 0
            if value <= 1.5 then value = value * 100 end
            return value
        end
    end
    return CSR_Antibodies.getInfectionLevel(player)
end

local function forEachPlayer(callback)
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if players then
        for p = 0, players:size() - 1 do
            callback(players:get(p))
        end
        return
    end

    local count = getNumActivePlayers and getNumActivePlayers() or 1
    for p = 0, count - 1 do
        local player = getSpecificPlayer and getSpecificPlayer(p) or getPlayer()
        callback(player)
    end
end

local function onEveryOneMinute()
    if not CSR_FeatureFlags.isInfectionResilienceEnabled() then return end

    forEachPlayer(function(player)
        if not player or player:isDead() then return end

        local bd = player:getBodyDamage()
        if not bd or not bd:IsInfected() then
            clearModData(player)
            return
        end

        local md = player:getModData()
        if md.CSR_IR_Doomed then
            return
        end

        if CSR_FeatureFlags.isAntibodySystemEnabled() and CSR_Antibodies.isImmune(player) then
            CSR_Antibodies.convertToFever(player, "IGUI_CSR_Antibody_ImmuneBlocked")
            clearModData(player)
            return
        end

        local threshold = getOrAssignThreshold(player)
        local pct = getInfectionPct(player)
        if pct < threshold then
            return
        end

        local infectedParts = CSR_Antibodies.countInfectedParts(player)
        if infectedParts < 1 then infectedParts = 1 end

        local baseChance = getChanceToHeal() / (getPenalty() ^ infectedParts)
        local chance = baseChance
        if CSR_FeatureFlags.isAntibodySystemEnabled() then
            local rollInfo = CSR_Antibodies.getSurvivalModifiers(player, baseChance, infectedParts)
            chance = rollInfo and rollInfo.chance or baseChance
        end

        local roll = ZombRand(0, 100)
        if roll < chance then
            if CSR_FeatureFlags.isAntibodySystemEnabled() then
                CSR_Antibodies.recordSurvival(player, infectedParts, pct)
            end
            CSR_Antibodies.convertToFever(player, "IGUI_CSR_InfRes_Survived")
            clearModData(player)
        else
            md.CSR_IR_Doomed = true
        end
    end)
end

if not _G.__CSR_InfectionResilience_evRegistered then
    _G.__CSR_InfectionResilience_evRegistered = true
    Events.EveryOneMinute.Add(onEveryOneMinute)
end
