CSR_Antibodies = CSR_Antibodies or {}

require "CSR_FaithsTraditionsBridge"

CSR_Antibodies.MODDATA_KEY = "CSR_Antibodies_v1"
CSR_Antibodies.MODULE = "CommonSenseReborn"
CSR_Antibodies.CMD_REQUEST = "CSR_AntibodyRequest"
CSR_Antibodies.CMD_SNAPSHOT = "CSR_AntibodySnapshot"
CSR_Antibodies.CMD_RESULT = "CSR_AntibodyResult"
CSR_Antibodies.CMD_DRAW = "CSR_AntibodyDraw"
CSR_Antibodies.CMD_INJECT = "CSR_AntibodyInject"
CSR_Antibodies.ITEM_EMPTY_SYRINGE = "Base.CSR_AntibodySyringeEmpty"
CSR_Antibodies.ITEM_IMMUNE_SYRINGE = "Base.CSR_ImmuneBloodSyringe"

local function sandbox()
    return SandboxVars and SandboxVars.CommonSenseReborn or {}
end

local function clamp(v, mn, mx)
    v = tonumber(v) or 0
    if v < mn then return mn end
    if v > mx then return mx end
    return v
end

local function optNumber(name, default)
    local value = sandbox()[name]
    if type(value) ~= "number" then
        value = tonumber(value)
    end
    if value == nil then return default end
    return value
end

local function worldHours()
    local gt = getGameTime and getGameTime() or nil
    if gt and gt.getWorldAgeHours then
        local value = gt:getWorldAgeHours()
        if value then return value end
    end
    return os.time() / 3600.0
end

local function getItems(container)
    if not container or not container.getItems then return nil end
    return container:getItems()
end

local function scanContainer(container, predicate, seen)
    local items = getItems(container)
    if not items then return nil end
    seen = seen or {}

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            if predicate(item) then
                return item
            end
            if item.getInventory and not seen[item] then
                seen[item] = true
                local sub = item:getInventory()
                local found = scanContainer(sub, predicate, seen)
                if found then return found end
            end
        end
    end

    return nil
end

function CSR_Antibodies.ensureData(player)
    local md = player and player.getModData and player:getModData() or nil
    if not md then return nil end

    local data = md[CSR_Antibodies.MODDATA_KEY]
    if type(data) ~= "table" then
        data = {}
        md[CSR_Antibodies.MODDATA_KEY] = data
    end

    data.antibodyLevel = clamp(data.antibodyLevel or 0, 0, 100)
    data.immunity = clamp(data.immunity or 0, 0, 100)
    data.survivedCount = tonumber(data.survivedCount) or 0
    data.serumPower = tonumber(data.serumPower) or 0
    data.serumUntil = tonumber(data.serumUntil) or 0
    data.lastUpdateHours = tonumber(data.lastUpdateHours) or worldHours()
    data.immune = data.immune == true or data.immunity >= CSR_Antibodies.getImmunityThreshold()
    if data.immune then
        data.immunity = math.max(data.immunity, CSR_Antibodies.getImmunityThreshold())
        data.antibodyLevel = math.max(data.antibodyLevel, 100)
    end

    return data
end

function CSR_Antibodies.getImmunityThreshold()
    return clamp(optNumber("AntibodyImmunityThreshold", 100), 1, 100)
end

function CSR_Antibodies.getMedicalLevel(player)
    if not player or not player.getPerkLevel or not Perks then return 0 end
    local perk = Perks.Doctor or Perks.FirstAid
    if not perk then return 0 end
    return tonumber(player:getPerkLevel(perk)) or 0
end

local function getPerkLevel(player, perk)
    if not player or not player.getPerkLevel or not perk then return 0 end
    return tonumber(player:getPerkLevel(perk)) or 0
end

local function hasTrait(player, trait)
    if not player then return false end
    if player.HasTrait then
        local value = player:HasTrait(trait)
        if value ~= nil then return value == true end
    end
    local traits = player.getTraits and player:getTraits() or nil
    if traits and traits.contains then
        return traits:contains(trait) == true
    end
    return false
end

local function getCharacterStat(player, statName)
    local stats = player and player.getStats and player:getStats() or nil
    if not stats then return 0 end

    if CharacterStat and CharacterStat[statName] and stats.get then
        local value = stats:get(CharacterStat[statName])
        if value ~= nil then return tonumber(value) or 0 end
    end

    local method = "get" .. string.upper(string.sub(statName, 1, 1)) .. string.lower(string.sub(statName, 2))
    if stats[method] then
        local value = stats[method](stats)
        if value ~= nil then return tonumber(value) or 0 end
    end

    return 0
end

local function setCharacterStat(player, statName, value)
    local stats = player and player.getStats and player:getStats() or nil
    if not stats or not CharacterStat or not CharacterStat[statName] or not stats.set then return end
    stats:set(CharacterStat[statName], value)
end

function CSR_Antibodies.getInfectionLevel(player)
    local value = getCharacterStat(player, "ZOMBIE_INFECTION")
    if value <= 1.5 then value = value * 100 end

    local bd = player and player.getBodyDamage and player:getBodyDamage() or nil
    if bd and bd.getInfectionLevel then
        local level = bd:getInfectionLevel()
        if level then
            value = math.max(value, tonumber(level) or 0)
        end
    end

    return clamp(value, 0, 100)
end

function CSR_Antibodies.isKnoxInfected(player)
    local bd = player and player.getBodyDamage and player:getBodyDamage() or nil
    if bd and bd.IsInfected then
        if bd:IsInfected() then return true end
    end
    return CSR_Antibodies.getInfectionLevel(player) > 0
end

function CSR_Antibodies.isFakeInfected(player)
    local bd = player and player.getBodyDamage and player:getBodyDamage() or nil
    if bd and bd.IsFakeInfected then
        if bd:IsFakeInfected() then return true end
    end
    return getCharacterStat(player, "ZOMBIE_FEVER") > 0
end

function CSR_Antibodies.countInfectedParts(player)
    local bd = player and player.getBodyDamage and player:getBodyDamage() or nil
    local parts = bd and bd.getBodyParts and bd:getBodyParts() or nil
    if not parts then return 0 end

    local count = 0
    for i = 0, parts:size() - 1 do
        local bp = parts:get(i)
        if bp and bp.IsInfected then
            if bp:IsInfected() then count = count + 1 end
        end
    end
    return count
end

local function bodyPartFlag(bp, name)
    if not bp or not bp[name] then return false end
    return bp[name](bp) == true
end

local function bodyPartNumber(bp, name)
    if not bp or not bp[name] then return 0 end
    return tonumber(bp[name](bp)) or 0
end

function CSR_Antibodies.getWoundSummary(player)
    local summary = {
        infected = 0,
        bites = 0,
        bleeding = 0,
        bandaged = 0,
        disinfected = 0,
        wounds = 0,
    }

    local bd = player and player.getBodyDamage and player:getBodyDamage() or nil
    local parts = bd and bd.getBodyParts and bd:getBodyParts() or nil
    if not parts then return summary end

    for i = 0, parts:size() - 1 do
        local bp = parts:get(i)
        if bp then
            if bp.IsInfected and bp:IsInfected() == true then
                summary.infected = summary.infected + 1
            end
            if bodyPartFlag(bp, "bitten") or bodyPartFlag(bp, "isBitten") then
                summary.bites = summary.bites + 1
                summary.wounds = summary.wounds + 1
            end
            if bodyPartFlag(bp, "bleeding") then
                summary.bleeding = summary.bleeding + 1
                summary.wounds = summary.wounds + 1
            end
            if bodyPartFlag(bp, "isScratched") or bodyPartFlag(bp, "scratched") then
                summary.wounds = summary.wounds + 1
            end
            if bodyPartFlag(bp, "isCut") or bodyPartFlag(bp, "cut") then
                summary.wounds = summary.wounds + 1
            end
            if bodyPartFlag(bp, "bandaged") then
                summary.bandaged = summary.bandaged + 1
            end
            if bodyPartNumber(bp, "getAlcoholLevel") > 0 then
                summary.disinfected = summary.disinfected + 1
            end
        end
    end

    return summary
end

local function getCoreTemp(player)
    local bd = player and player.getBodyDamage and player:getBodyDamage() or nil
    if bd and bd.getThermoregulator then
        local reg = bd:getThermoregulator()
        if reg and reg.getCoreTemperature then
            local temp = reg:getCoreTemperature()
            if temp then return tonumber(temp) or 37 end
        end
    end
    return 37
end

local function getSickness(player)
    local bd = player and player.getBodyDamage and player:getBodyDamage() or nil
    local value = 0
    if bd and bd.getSicknessLevel then
        local level = bd:getSicknessLevel()
        if level then value = math.max(value, (tonumber(level) or 0) / 100.0) end
    end
    if bd and bd.getFoodSicknessLevel then
        local level = bd:getFoodSicknessLevel()
        if level then value = math.max(value, (tonumber(level) or 0) / 100.0) end
    end
    return clamp(value, 0, 1)
end

local function addEffect(effects, key, value)
    value = tonumber(value) or 0
    if math.abs(value) < 0.05 then return end
    table.insert(effects.entries, {
        key = key,
        value = value,
        good = value >= 0,
    })
end

function CSR_Antibodies.getSerumPower(player)
    local data = CSR_Antibodies.ensureData(player)
    if not data then return 0 end
    local now = worldHours()
    if (tonumber(data.serumUntil) or 0) <= now then
        data.serumUntil = 0
        data.serumPower = 0
        data.serumDonor = nil
        return 0
    end
    return clamp(data.serumPower or 0, 0, 50)
end

function CSR_Antibodies.computeEffects(player)
    local effects = {
        condition = 0,
        wounds = 0,
        treatment = 0,
        serum = CSR_Antibodies.getSerumPower(player),
        total = 0,
        entries = {},
    }

    if not player then return effects end

    local fitness = getPerkLevel(player, Perks and Perks.Fitness or nil)
    local strength = getPerkLevel(player, Perks and Perks.Strength or nil)
    local fitnessEffect = (fitness - 5) * 0.8
    local strengthEffect = (strength - 5) * 0.6
    effects.condition = effects.condition + fitnessEffect + strengthEffect
    addEffect(effects, "IGUI_CSR_Antibody_Effect_Fitness", fitnessEffect)
    addEffect(effects, "IGUI_CSR_Antibody_Effect_Strength", strengthEffect)

    local hunger = clamp(getCharacterStat(player, "HUNGER"), 0, 1)
    local thirst = clamp(getCharacterStat(player, "THIRST"), 0, 1)
    local fatigue = clamp(getCharacterStat(player, "FATIGUE"), 0, 1)
    local stress = clamp(getCharacterStat(player, "STRESS"), 0, 1)
    local pain = clamp(getCharacterStat(player, "PAIN") / 100.0, 0, 1)
    local sickness = getSickness(player)
    local hungerEffect = -hunger * 7.0
    local thirstEffect = -thirst * 8.0
    local fatigueEffect = -fatigue * 6.0
    local stressEffect = -stress * 4.0
    local painEffect = -pain * 5.0
    local sicknessEffect = -sickness * 8.0
    effects.condition = effects.condition + hungerEffect + thirstEffect + fatigueEffect + stressEffect + painEffect + sicknessEffect
    addEffect(effects, "IGUI_CSR_Antibody_Effect_Hunger", hungerEffect)
    addEffect(effects, "IGUI_CSR_Antibody_Effect_Thirst", thirstEffect)
    addEffect(effects, "IGUI_CSR_Antibody_Effect_Fatigue", fatigueEffect)
    addEffect(effects, "IGUI_CSR_Antibody_Effect_Stress", stressEffect)
    addEffect(effects, "IGUI_CSR_Antibody_Effect_Pain", painEffect)
    addEffect(effects, "IGUI_CSR_Antibody_Effect_Sickness", sicknessEffect)

    local temp = getCoreTemp(player)
    local tempEffect = -math.min(8.0, math.abs(temp - 37.0) * 2.5)
    effects.condition = effects.condition + tempEffect
    addEffect(effects, "IGUI_CSR_Antibody_Effect_Temperature", tempEffect)

    local wounds = CSR_Antibodies.getWoundSummary(player)
    local woundEffect = -(wounds.infected * 4.0) - (wounds.bites * 2.5) - (wounds.bleeding * 1.5)
    local treatmentEffect = (wounds.bandaged * 0.5) + (wounds.disinfected * 1.0)
    effects.wounds = woundEffect
    effects.treatment = treatmentEffect
    addEffect(effects, "IGUI_CSR_Antibody_Effect_InfectedWounds", woundEffect)
    addEffect(effects, "IGUI_CSR_Antibody_Effect_Treatment", treatmentEffect)
    addEffect(effects, "IGUI_CSR_Antibody_Effect_Serum", effects.serum)

    effects.total = clamp(effects.condition + effects.wounds + effects.treatment + effects.serum, -60, 60)
    return effects
end

local function addFaithTag(tags, seen, tag)
    if not tag or seen[tag] then return end
    seen[tag] = true
    tags[#tags + 1] = tag
end

local function statPercent01(player, statName)
    local value = getCharacterStat(player, statName)
    if value > 1 then value = value / 100.0 end
    return clamp(value, 0, 1)
end

local function buildFaithSurvivalRequest(player, baseChance, infectedParts, data, effects)
    local tags = {}
    local seen = {}
    local infectionLevel = clamp(data and data.infectionLevel or CSR_Antibodies.getInfectionLevel(player), 0, 100)
    local wounds = CSR_Antibodies.getWoundSummary(player)

    addFaithTag(tags, seen, "infection")
    addFaithTag(tags, seen, "medical")

    if infectionLevel >= 55 then addFaithTag(tags, seen, "critical") end
    if infectionLevel >= 85 then
        addFaithTag(tags, seen, "death")
        addFaithTag(tags, seen, "laststand")
    end

    if (tonumber(infectedParts) or 0) > 0 or wounds.wounds > 0 then
        addFaithTag(tags, seen, "wound")
    end
    if wounds.wounds > 0 or wounds.bleeding > 0 then
        addFaithTag(tags, seen, "trauma")
    end

    if getSickness(player) > 0.05 then addFaithTag(tags, seen, "sickness") end
    if getCharacterStat(player, "PAIN") > 15 then addFaithTag(tags, seen, "pain") end
    if statPercent01(player, "FATIGUE") > 0.50 then addFaithTag(tags, seen, "exhaustion") end
    if statPercent01(player, "PANIC") > 0.10 then addFaithTag(tags, seen, "panic") end
    if effects and (tonumber(effects.total) or 0) <= -25 then addFaithTag(tags, seen, "shock") end

    return {
        event = "csr_survival_roll",
        tags = tags,
        baseChance = baseChance,
        severity = infectionLevel,
    }
end

function CSR_Antibodies.updatePlayer(player, minutesElapsed)
    local data = CSR_Antibodies.ensureData(player)
    if not data then return nil end

    local now = worldHours()
    if minutesElapsed == nil then
        local last = tonumber(data.lastUpdateHours) or now
        minutesElapsed = math.max(0, (now - last) * 60.0)
    else
        minutesElapsed = tonumber(minutesElapsed) or 0
    end
    if minutesElapsed > 0 then
        data.lastUpdateHours = now
    end

    local infectionLevel = CSR_Antibodies.getInfectionLevel(player)
    local infected = CSR_Antibodies.isKnoxInfected(player)
    local effects = CSR_Antibodies.computeEffects(player)
    local hours = clamp(minutesElapsed or 0, 0, 120) / 60.0

    if data.immune then
        data.antibodyLevel = 100
        data.immunity = math.max(data.immunity, CSR_Antibodies.getImmunityThreshold())
    elseif infected then
        local baseGrowth = optNumber("AntibodyGrowthPerHour", 18)
        local responseCurve = 0.25 + 0.75 * (infectionLevel / 100.0)
        local effectScale = clamp(1.0 + (effects.total / 100.0), 0.20, 2.00)
        data.antibodyLevel = clamp((data.antibodyLevel or 0) + baseGrowth * hours * responseCurve * effectScale, 0, 100)
    else
        local decay = optNumber("AntibodyDecayPerHour", 12)
        data.antibodyLevel = clamp((data.antibodyLevel or 0) - decay * hours, 0, 100)
    end

    if data.serumUntil and data.serumUntil > 0 and data.serumUntil <= now then
        data.serumUntil = 0
        data.serumPower = 0
        data.serumDonor = nil
    end

    data.infectionLevel = infectionLevel
    data.infectedParts = CSR_Antibodies.countInfectedParts(player)
    data.fakeInfected = CSR_Antibodies.isFakeInfected(player)
    data.effects = effects
    data.updatedAt = now
    return data
end

function CSR_Antibodies.isImmune(player)
    local data = CSR_Antibodies.ensureData(player)
    if not data then return false end
    return data.immune == true or (tonumber(data.immunity) or 0) >= CSR_Antibodies.getImmunityThreshold()
end

function CSR_Antibodies.getSurvivalModifiers(player, baseChance, infectedParts)
    local data = CSR_Antibodies.updatePlayer(player, 0) or {}
    local effects = data.effects or CSR_Antibodies.computeEffects(player)
    infectedParts = tonumber(infectedParts) or CSR_Antibodies.countInfectedParts(player)
    if infectedParts < 1 then infectedParts = 1 end

    local info = {
        baseChance = tonumber(baseChance) or 0,
        infectedParts = infectedParts,
        antibodyBonus = 0,
        immunityBonus = 0,
        serumBonus = 0,
        conditionBonus = 0,
        luckBonus = 0,
        faithBonus = 0,
        faithBridgeAvailable = false,
        faithApplies = false,
        chance = 0,
        immune = CSR_Antibodies.isImmune(player),
    }

    if info.immune then
        info.chance = 100
        data.lastChance = info.chance
        data.lastModifiers = info
        return info
    end

    info.antibodyBonus = (tonumber(data.antibodyLevel) or 0) * optNumber("AntibodyRollBonusPerPoint", 0.20)
    info.immunityBonus = (tonumber(data.immunity) or 0) * optNumber("AntibodyImmunityRollBonusPerPoint", 0.25)
    info.serumBonus = CSR_Antibodies.getSerumPower(player)
    info.conditionBonus = (tonumber(effects.total) or 0) * 0.15

    if hasTrait(player, "Lucky") then
        info.luckBonus = 5
    elseif hasTrait(player, "Unlucky") then
        info.luckBonus = -5
    end

    local preFaithChance = info.baseChance + info.antibodyBonus + info.immunityBonus + info.serumBonus + info.conditionBonus + info.luckBonus

    if CSR_FaithsTraditionsBridge and CSR_FaithsTraditionsBridge.isAvailable and CSR_FaithsTraditionsBridge.isAvailable() then
        info.faithBridgeAvailable = true
        local request = buildFaithSurvivalRequest(player, clamp(preFaithChance, 0, 99), infectedParts, data, effects)
        local bonus, faith = CSR_FaithsTraditionsBridge.getSurvivalBonus(player, request)
        if faith then
            info.faithApplies = faith.applies == true
            info.faithPath = faith.pathId
            info.faithPathName = faith.pathName
            info.faithLevel = faith.faithLevel
            info.faithMatchedTags = faith.matchedTags
            info.faithApiVersion = faith.apiVersion
            info.faithError = faith.error
        end
        info.faithBonus = bonus
    end

    info.chance = clamp(preFaithChance + info.faithBonus, 0, 99)
    data.lastChance = info.chance
    data.lastModifiers = info
    return info
end

function CSR_Antibodies.recordSurvival(player, infectedParts, infectionPct)
    local data = CSR_Antibodies.ensureData(player)
    if not data then return nil end

    infectedParts = tonumber(infectedParts) or CSR_Antibodies.countInfectedParts(player)
    if infectedParts < 1 then infectedParts = 1 end
    infectionPct = clamp(infectionPct or CSR_Antibodies.getInfectionLevel(player), 0, 100)

    local gain = optNumber("AntibodySurvivalGain", 25)
        + (infectedParts * optNumber("AntibodySurvivalGainPerPart", 5))
        + math.floor(infectionPct / 25)

    data.survivedCount = (tonumber(data.survivedCount) or 0) + 1
    data.immunity = clamp((tonumber(data.immunity) or 0) + gain, 0, 100)
    data.antibodyLevel = math.max(tonumber(data.antibodyLevel) or 0, math.min(100, 45 + data.immunity))
    data.lastSurvivalAt = worldHours()

    if data.immunity >= CSR_Antibodies.getImmunityThreshold() then
        data.immune = true
        data.immunity = CSR_Antibodies.getImmunityThreshold()
        data.antibodyLevel = 100
    end

    if player and player.transmitModData then player:transmitModData() end
    return data
end

function CSR_Antibodies.convertToFever(player, messageKey)
    local bd = player and player.getBodyDamage and player:getBodyDamage() or nil
    if not bd then return end

    local realVal = getCharacterStat(player, "ZOMBIE_INFECTION")
    setCharacterStat(player, "ZOMBIE_FEVER", realVal)
    setCharacterStat(player, "ZOMBIE_INFECTION", 0)

    if bd.setInfected then bd:setInfected(false) end
    if bd.setIsFakeInfected then bd:setIsFakeInfected(true) end

    local parts = bd.getBodyParts and bd:getBodyParts() or nil
    if parts then
        for i = 0, parts:size() - 1 do
            local bp = parts:get(i)
            if bp and bp.IsInfected and bp:IsInfected() == true and bp.setInfectedWound then
                bp:setInfectedWound(false)
            end
        end
    end

    if player.setHaloNote and getText then
        local key = messageKey or "IGUI_CSR_InfRes_Survived"
        player:setHaloNote(getText(key), 120, 255, 120, 300)
    end
end

function CSR_Antibodies.findInventoryItemById(player, itemId, expectedType)
    if not player or not itemId then return nil end
    local inv = player.getInventory and player:getInventory() or nil
    itemId = tonumber(itemId)
    return scanContainer(inv, function(item)
        if not item or not item.getID then return false end
        if tonumber(item:getID()) ~= itemId then return false end
        return not expectedType or (item.getFullType and item:getFullType() == expectedType)
    end)
end

function CSR_Antibodies.findInventoryItemByType(player, fullType)
    if not player or not fullType then return nil end
    local inv = player.getInventory and player:getInventory() or nil
    return scanContainer(inv, function(item)
        return item and item.getFullType and item:getFullType() == fullType
    end)
end

function CSR_Antibodies.findPlayerByOnlineID(onlineID)
    if onlineID == nil then return nil end
    onlineID = tonumber(onlineID)

    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if players then
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player and player.getOnlineID and tonumber(player:getOnlineID()) == onlineID then
                return player
            end
        end
    end

    local count = getNumActivePlayers and getNumActivePlayers() or 1
    for i = 0, count - 1 do
        local player = getSpecificPlayer and getSpecificPlayer(i) or nil
        if player and player.getOnlineID and tonumber(player:getOnlineID()) == onlineID then
            return player
        end
    end

    local player = getPlayer and getPlayer() or nil
    if player and player.getOnlineID and tonumber(player:getOnlineID()) == onlineID then
        return player
    end
    return nil
end

local function removeInventoryItem(item)
    if not item then return false end
    local container = item.getContainer and item:getContainer() or nil
    if not container then return false end
    if container.DoRemoveItem then
        container:DoRemoveItem(item)
    elseif container.Remove then
        container:Remove(item)
    end
    return true
end

local function addInventoryItem(player, fullType)
    local inv = player and player.getInventory and player:getInventory() or nil
    if not inv or not inv.AddItem then return nil end
    return inv:AddItem(fullType)
end

function CSR_Antibodies.distanceOK(a, b, maxDistance)
    if not a or not b then return false end
    if a == b then return true end
    maxDistance = maxDistance or 2.5
    local dx = math.abs((a.getX and a:getX() or 0) - (b.getX and b:getX() or 0))
    local dy = math.abs((a.getY and a:getY() or 0) - (b.getY and b:getY() or 0))
    local dz = math.abs((a.getZ and a:getZ() or 0) - (b.getZ and b:getZ() or 0))
    return dx <= maxDistance and dy <= maxDistance and dz < 1
end

local function modifyHealth(player, amount)
    local bd = player and player.getBodyDamage and player:getBodyDamage() or nil
    if not bd or amount == 0 then return end
    if amount < 0 and bd.ReduceGeneralHealth then
        bd:ReduceGeneralHealth(math.abs(amount))
    elseif amount > 0 and bd.AddGeneralHealth then
        bd:AddGeneralHealth(amount)
    end
end

local function addHandPain(player, minPain, maxPain)
    local bd = player and player.getBodyDamage and player:getBodyDamage() or nil
    if not bd or not BodyPartType or not BodyPartType.Hand_L or not bd.getBodyPart then return end
    local part = bd:getBodyPart(BodyPartType.Hand_L)
    if part and part.getAdditionalPain and part.setAdditionalPain then
        local pain = ZombRand and ZombRand(minPain or 4, maxPain or 12) or minPain or 4
        part:setAdditionalPain((tonumber(part:getAdditionalPain()) or 0) + pain)
    end
end

local function getHealth(player)
    local bd = player and player.getBodyDamage and player:getBodyDamage() or nil
    if bd and bd.getOverallBodyHealth then
        local value = bd:getOverallBodyHealth()
        if value then return tonumber(value) or 0 end
    end
    return 0
end

function CSR_Antibodies.applyDrawBlood(actor, donor, args)
    if not actor or not donor then return false, "IGUI_CSR_Antibody_FailInvalid" end
    if not CSR_Antibodies.distanceOK(actor, donor, 2.5) then return false, "IGUI_CSR_Antibody_FailTooFar" end
    if not CSR_Antibodies.isImmune(donor) then return false, "IGUI_CSR_Antibody_FailNeedImmuneDonor" end

    local donorData = CSR_Antibodies.ensureData(donor)
    local now = worldHours()
    local cooldown = optNumber("AntibodyDrawCooldownHours", 24)
    if donorData and donorData.lastBloodDrawAt and (now - donorData.lastBloodDrawAt) < cooldown then
        return false, "IGUI_CSR_Antibody_FailCooldown"
    end

    local minHealth = optNumber("AntibodyDrawMinHealth", 35)
    if getHealth(donor) < minHealth then return false, "IGUI_CSR_Antibody_FailWeakDonor" end

    args = args or {}
    local empty = CSR_Antibodies.findInventoryItemById(actor, args.emptySyringeId, CSR_Antibodies.ITEM_EMPTY_SYRINGE)
        or CSR_Antibodies.findInventoryItemByType(actor, CSR_Antibodies.ITEM_EMPTY_SYRINGE)
    if not empty then return false, "IGUI_CSR_Antibody_FailNeedEmptySyringe" end

    removeInventoryItem(empty)
    local sample = addInventoryItem(actor, CSR_Antibodies.ITEM_IMMUNE_SYRINGE)
    if sample and sample.getModData then
        local md = sample:getModData()
        md.CSR_AntibodySample = true
        md.CSR_AntibodyDonor = donor.getUsername and donor:getUsername() or donor:getDisplayName()
        md.CSR_AntibodyDonorName = donor.getDisplayName and donor:getDisplayName() or md.CSR_AntibodyDonor
        md.CSR_AntibodyPotency = clamp(optNumber("AntibodySerumPower", 15) + CSR_Antibodies.getMedicalLevel(actor) * 1.5, 1, 50)
        md.CSR_AntibodyCollectedAt = now
        md.CSR_AntibodyExpiresAt = now + optNumber("AntibodySampleShelfHours", 72)
        if sample.transmitModData then sample:transmitModData() end
        if transmitInventoryItem then transmitInventoryItem(sample) end
    end

    local healthCost = optNumber("AntibodyDrawHealthCost", 4)
    modifyHealth(donor, -healthCost)
    addHandPain(donor, 4, 14)
    donorData.lastBloodDrawAt = now
    if donor.transmitModData then donor:transmitModData() end
    if actor.transmitModData then actor:transmitModData() end

    return true, "IGUI_CSR_Antibody_DrawDone", sample
end

function CSR_Antibodies.applyInjectSerum(actor, recipient, args)
    if not actor or not recipient then return false, "IGUI_CSR_Antibody_FailInvalid" end
    if not CSR_Antibodies.distanceOK(actor, recipient, 2.5) then return false, "IGUI_CSR_Antibody_FailTooFar" end
    if CSR_Antibodies.isImmune(recipient) then return false, "IGUI_CSR_Antibody_FailAlreadyImmune" end

    args = args or {}
    local serum = CSR_Antibodies.findInventoryItemById(actor, args.serumId, CSR_Antibodies.ITEM_IMMUNE_SYRINGE)
        or CSR_Antibodies.findInventoryItemByType(actor, CSR_Antibodies.ITEM_IMMUNE_SYRINGE)
    if not serum then return false, "IGUI_CSR_Antibody_FailNeedSerum" end

    local sampleData = serum.getModData and serum:getModData() or {}
    local now = worldHours()
    if sampleData.CSR_AntibodyExpiresAt and now > tonumber(sampleData.CSR_AntibodyExpiresAt) then
        return false, "IGUI_CSR_Antibody_FailExpiredSample"
    end

    removeInventoryItem(serum)
    local data = CSR_Antibodies.ensureData(recipient)
    data.serumUntil = now + optNumber("AntibodySerumHours", 8)
    data.serumPower = clamp(tonumber(sampleData.CSR_AntibodyPotency) or optNumber("AntibodySerumPower", 15), 1, 50)
    data.serumDonor = sampleData.CSR_AntibodyDonorName or sampleData.CSR_AntibodyDonor
    data.antibodyLevel = clamp((tonumber(data.antibodyLevel) or 0) + optNumber("AntibodySerumImmediateBoost", 8), 0, 100)

    addHandPain(recipient, 3, 10)
    if recipient.transmitModData then recipient:transmitModData() end
    if actor.transmitModData then actor:transmitModData() end

    return true, "IGUI_CSR_Antibody_InjectDone", nil
end

function CSR_Antibodies.getStageKey(player, data)
    data = data or CSR_Antibodies.ensureData(player) or {}
    if data.immune == true or CSR_Antibodies.isImmune(player) then return "IGUI_CSR_Antibody_Stage_Immune" end
    if data.fakeInfected or CSR_Antibodies.isFakeInfected(player) then return "IGUI_CSR_Antibody_Stage_Recovery" end
    local level = tonumber(data.infectionLevel) or CSR_Antibodies.getInfectionLevel(player)
    if level <= 0 then return "IGUI_CSR_Antibody_Stage_Clear" end
    if level < 25 then return "IGUI_CSR_Antibody_Stage_Incubation" end
    if level < 55 then return "IGUI_CSR_Antibody_Stage_Systemic" end
    if level < 85 then return "IGUI_CSR_Antibody_Stage_Critical" end
    return "IGUI_CSR_Antibody_Stage_Terminal"
end

function CSR_Antibodies.buildSnapshot(player)
    local data = CSR_Antibodies.updatePlayer(player, nil) or {}
    local infectedParts = tonumber(data.infectedParts) or CSR_Antibodies.countInfectedParts(player)
    if infectedParts < 1 then infectedParts = 1 end
    local baseChance = optNumber("InfResChanceToHeal", 10) / (optNumber("InfResPenaltyMultiplier", 1.5) ^ infectedParts)
    local roll = CSR_Antibodies.getSurvivalModifiers(player, baseChance, infectedParts)
    local now = worldHours()
    local serumLeft = 0
    if data.serumUntil and data.serumUntil > now then
        serumLeft = data.serumUntil - now
    end

    return {
        username = player and player.getUsername and player:getUsername() or nil,
        onlineID = player and player.getOnlineID and player:getOnlineID() or nil,
        displayName = player and player.getDisplayName and player:getDisplayName() or nil,
        infectionLevel = clamp(data.infectionLevel or 0, 0, 100),
        antibodyLevel = clamp(data.antibodyLevel or 0, 0, 100),
        immunity = clamp(data.immunity or 0, 0, 100),
        immune = CSR_Antibodies.isImmune(player),
        survivedCount = tonumber(data.survivedCount) or 0,
        infectedParts = infectedParts,
        serumPower = clamp(data.serumPower or 0, 0, 50),
        serumHoursLeft = serumLeft,
        stageKey = CSR_Antibodies.getStageKey(player, data),
        effects = data.effects or CSR_Antibodies.computeEffects(player),
        chance = roll and roll.chance or 0,
        modifiers = roll,
    }
end

return CSR_Antibodies
