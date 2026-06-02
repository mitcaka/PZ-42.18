if isServer() then return end

require "FAM_Core"

FAM_SymptomFX = FAM_SymptomFX or {}
FAM_SymptomFX.active = false
FAM_SymptomFX.haloCooldown = 0
FAM_SymptomFX.addedDeafTrait = false

local DEAF_TRAIT = "Deaf"

local function getLocalPlayer()
    if getPlayer then
        return getPlayer()
    end
    return nil
end

local function getSearchManagerActive(player)
    if not ISSearchManager or not ISSearchManager.players or not player then return false end
    local manager = ISSearchManager.players[player]
    return manager ~= nil and (manager.isSearchMode == true or manager.isEffectOverlay == true)
end

local function setSymptomOverlay(player, blur, darkness)
    if not getSearchMode or not player or not player.getPlayerNum then return false end
    local searchMode = getSearchMode()
    if not searchMode or not searchMode.getSearchModeForPlayer then return false end
    local playerNum = player:getPlayerNum()
    local overlay = searchMode:getSearchModeForPlayer(playerNum)
    if not overlay then return false end
    if overlay.getBlur then overlay:getBlur():setTargets(blur, blur) end
    if overlay.getDesat then overlay:getDesat():setTargets(math.min(0.32, blur * 0.65), math.min(0.32, blur * 0.65)) end
    if overlay.getDarkness then overlay:getDarkness():setTargets(darkness, darkness) end
    if overlay.getRadius then overlay:getRadius():setTargets(18, 18) end
    if overlay.getGradientWidth then overlay:getGradientWidth():setTargets(2, 2) end
    if searchMode.setEnabled then
        searchMode:setEnabled(playerNum, true)
    end
    return true
end

local function clearSymptomOverlay(player)
    if not getSearchMode or not player or not player.getPlayerNum then return end
    if getSearchManagerActive(player) then return end
    local searchMode = getSearchMode()
    local playerNum = player:getPlayerNum()
    local overlay = searchMode.getSearchModeForPlayer and searchMode:getSearchModeForPlayer(playerNum) or nil
    if overlay then
        if overlay.getBlur then overlay:getBlur():setTargets(0, 0) end
        if overlay.getDesat then overlay:getDesat():setTargets(0, 0) end
        if overlay.getDarkness then overlay:getDarkness():setTargets(0.1, 0.1) end
    end
    if searchMode.setEnabled then
        searchMode:setEnabled(playerNum, false)
    end
end

local function showSymptomHalo(player, key)
    if not player or FAM_SymptomFX.haloCooldown > 0 then return end
    FAM_SymptomFX.haloCooldown = 480
    local text = getText(key)
    if HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, text, "[br/]", HaloTextHelper.getColorRed())
    elseif player.setHaloNote then
        player:setHaloNote(text, 255, 80, 80, 240)
    end
end

local function setTemporaryDeafness(player, enabled)
    if not player or not player.getTraits or not TraitFactory or not TraitFactory.getTrait then return false end
    local trait = TraitFactory.getTrait(DEAF_TRAIT)
    local traits = player:getTraits()
    if not trait or not traits then return false end

    if enabled then
        if FAM.hasTrait(player, DEAF_TRAIT) then return false end
        if traits.add and not FAM_SymptomFX.addedDeafTrait then
            traits:add(trait)
            FAM_SymptomFX.addedDeafTrait = true
            return true
        end
    elseif FAM_SymptomFX.addedDeafTrait then
        if traits.remove then
            traits:remove(trait)
        end
        FAM_SymptomFX.addedDeafTrait = false
        return true
    end

    return false
end

local function onTick()
    local player = getLocalPlayer()
    if not player then return end
    if FAM_SymptomFX.haloCooldown > 0 then
        FAM_SymptomFX.haloCooldown = FAM_SymptomFX.haloCooldown - 1
    end

    local data = player:getModData()
    local diseaseId = FAM.getPandemicDiseaseId(player)
    local load = FAM.getPandemicLoad(player)
    local blurHours = tonumber(data.FAM_HollowVeilBlurHours) or 0
    local deafHours = tonumber(data.FAM_HollowVeilDeafHours) or 0
    local veilActive = FAM.isPandemicInfected(player) and diseaseId == FAM.CORPSE_VIRUS_DISEASE
    local blur = 0
    local darkness = 0.1

    if veilActive and (load >= 45 or blurHours > 0) then
        blur = FAM.clamp(0.16 + (load / 260), 0.18, 0.55)
        darkness = FAM.clamp(0.16 + (load / 420), 0.16, 0.36)
    end

    if blur > 0 then
        FAM_SymptomFX.active = setSymptomOverlay(player, blur, darkness)
        if blurHours > 0 then
            showSymptomHalo(player, "IGUI_FAM_Halo_HollowVeilBlur")
        end
    elseif FAM_SymptomFX.active then
        clearSymptomOverlay(player)
        FAM_SymptomFX.active = false
    end

    if veilActive and deafHours > 0 then
        setTemporaryDeafness(player, true)
        showSymptomHalo(player, "IGUI_FAM_Halo_HollowVeilDeaf")
    else
        setTemporaryDeafness(player, false)
    end
end

if Events and Events.OnTick and not FAM_SymptomFX._registered then
    FAM_SymptomFX._registered = true
    Events.OnTick.Add(onTick)
end
