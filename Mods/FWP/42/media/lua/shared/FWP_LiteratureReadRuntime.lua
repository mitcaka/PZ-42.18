require "TimedActions/ISReadABook"

local FWP_LITERATURE_READ = {
    ["Base.Stoner_Book"] = {},
    ["Base.Kalashnikov_Book"] = {},
    ["Base.HecklerKoch_Book"] = {},
    ["Base.FNHerstal_Book"] = {},
    ["Base.FirstBlood_Book"] = { "FWP_Craft_Arrow_Fiberglass", "FWP_Craft_Bolt_Bear", "FWP_Recover_Bolt_Components", "FWP_Recover_Arrow_Components" },
    ["Base.BeLikeWater_Book"] = { "FWP_Assemble_Steel_Nun_Chucks", "FWP_Assemble_Poly_Nun_Chucks", "FWP_Assemble_Wood_Nun_Chucks" },
    ["Base.BoyScout_Book"] = { "FWP_Create_Improvised_Flame_Thrower", "FWP_Scrap_Improvised_Flame_Thrower" },
    ["Base.Lyman49th_Manual"] = {},
}

local FWP_LITERATURE_MASTERY = {
    ["Base.Stoner_Book"] = "AR",
    ["Base.Kalashnikov_Book"] = "AK",
    ["Base.HecklerKoch_Book"] = "HK",
    ["Base.FNHerstal_Book"] = "FN",
}

local FWP_MASTERY_LABEL = {
    AR = "AR Pattern Familiarity",
    AK = "AK Pattern Familiarity",
    HK = "HK Pattern Familiarity",
    FN = "FN Pattern Familiarity",
}

local function fwpGetFullType(item)
    if not item then return nil end
    if item.getFullType then
        return item:getFullType()
    end
    if item.getModule and item.getType then
        return item:getModule() .. "." .. item:getType()
    end
    return nil
end

local function fwpLearnRecipe(character, recipe)
    if not (character and recipe) then return end
    if character.learnRecipe then
        character:learnRecipe(recipe)
        return
    end

    local knownRecipes = character.getKnownRecipes and character:getKnownRecipes() or nil
    if knownRecipes and not knownRecipes:contains(recipe) then
        knownRecipes:add(recipe)
    end
end

local function fwpSafeCall(obj, methodName, ...)
    if not obj or not methodName or not obj[methodName] then return nil end
    local ok, result = pcall(obj[methodName], obj, ...)
    if ok then return result end
    return nil
end

local function fwpSafeSet(obj, methodName, ...)
    if not obj or not methodName or not obj[methodName] then return false end
    return pcall(obj[methodName], obj, ...) == true
end

local function fwpMasteryFlag(key)
    return "FWP_Mastery_" .. tostring(key or "")
end

function FWPPlayerHasWeaponMastery(character, key)
    local md = character and character.getModData and character:getModData() or nil
    return md and md[fwpMasteryFlag(key)] == true
end

function FWPGetWeaponMasteryKey(weapon)
    local groupType = FWPWeaponWorkGetTriggerGroupType and FWPWeaponWorkGetTriggerGroupType(weapon) or nil
    if groupType == "Base.TriggerGroup_AR" then return "AR" end
    if groupType == "Base.TriggerGroup_AK" then return "AK" end
    if groupType == "Base.TriggerGroup_HK" then return "HK" end
    if groupType == "Base.TriggerGroup_FN" then return "FN" end
    return nil
end

function FWPGetWeaponMasteryLabel(character, weapon)
    local key = FWPGetWeaponMasteryKey(weapon)
    if key and FWPPlayerHasWeaponMastery(character, key) then
        return FWP_MASTERY_LABEL[key]
    end
    return nil
end

local function fwpGrantMastery(character, key)
    local md = character and character.getModData and character:getModData() or nil
    if not (md and key) then return false end
    local flag = fwpMasteryFlag(key)
    if md[flag] == true then return false end
    md[flag] = true
    return true
end

local function fwpRestoreMasteryStats(weapon, md)
    if md.FWP_MasteryBaseAimingTime ~= nil then
        fwpSafeSet(weapon, "setAimingTime", tonumber(md.FWP_MasteryBaseAimingTime) or 0)
    end
    if md.FWP_MasteryBaseReloadTime ~= nil then
        fwpSafeSet(weapon, "setReloadTime", tonumber(md.FWP_MasteryBaseReloadTime) or 0)
    end
    md.FWP_MasteryApplied = nil
end

local function fwpApplyMasteryStats(character, weapon)
    if not (character and weapon and weapon.IsWeapon and weapon:IsWeapon() and weapon.isRanged and weapon:isRanged()) then
        return
    end

    local md = weapon.getModData and weapon:getModData() or nil
    if not md then return end

    local key = FWPGetWeaponMasteryKey(weapon)
    local hasMastery = key and FWPPlayerHasWeaponMastery(character, key)
    if md.FWP_MasteryApplied ~= nil and not hasMastery then
        fwpRestoreMasteryStats(weapon, md)
    end
    if not hasMastery then
        return
    end
    if md.FWP_MasteryApplied == key then
        return
    end

    fwpRestoreMasteryStats(weapon, md)
    local aim = tonumber(fwpSafeCall(weapon, "getAimingTime"))
    local reload = tonumber(fwpSafeCall(weapon, "getReloadTime"))
    if aim ~= nil then
        md.FWP_MasteryBaseAimingTime = aim
        fwpSafeSet(weapon, "setAimingTime", math.max(0, aim - 1))
    end
    if reload ~= nil then
        md.FWP_MasteryBaseReloadTime = reload
        fwpSafeSet(weapon, "setReloadTime", math.max(0, reload - 1))
    end
    md.FWP_MasteryApplied = key
    if weapon.transmitModData then pcall(weapon.transmitModData, weapon) end
    if syncHandWeaponFields then pcall(syncHandWeaponFields, character, weapon) end
end

local function fwpApplyMasteryForPlayer(character)
    if not character then return end
    fwpApplyMasteryStats(character, character.getPrimaryHandItem and character:getPrimaryHandItem() or nil)
    local secondary = character.getSecondaryHandItem and character:getSecondaryHandItem() or nil
    if secondary ~= (character.getPrimaryHandItem and character:getPrimaryHandItem() or nil) then
        fwpApplyMasteryStats(character, secondary)
    end
end

local function fwpMarkLiteratureRead(character, item)
    local fullType = fwpGetFullType(item)
    local recipes = fullType and FWP_LITERATURE_READ[fullType] or nil
    if not (character and item and recipes) then return end

    local modData = item.getModData and item:getModData() or nil
    if modData then
        modData.literatureTitle = fullType
        if item.transmitModData then
            item:transmitModData()
        end
    end

    if character.addReadLiterature then
        character:addReadLiterature(fullType)
    end

    local alreadyRead = character.getAlreadyReadBook and character:getAlreadyReadBook() or nil
    if alreadyRead and not alreadyRead:contains(fullType) then
        alreadyRead:add(fullType)
    end

    for i = 1, #recipes do
        fwpLearnRecipe(character, recipes[i])
    end

    local masteryKey = FWP_LITERATURE_MASTERY[fullType]
    if masteryKey and fwpGrantMastery(character, masteryKey) then
        fwpApplyMasteryForPlayer(character)
    end

    if item.getNumberOfPages and item.setAlreadyReadPages then
        local pages = item:getNumberOfPages()
        if pages and pages > 0 then
            item:setAlreadyReadPages(pages)
            if character.setAlreadyReadPages then
                character:setAlreadyReadPages(fullType, pages)
            end
        end
    end

    if sendSyncPlayerFields then
        sendSyncPlayerFields(character, 0x00000007)
    end
    if syncItemFields then
        syncItemFields(character, item)
    end
end

if ISReadABook and ISReadABook.complete and not ISReadABook.fwpReadStatePatched then
    local originalComplete = ISReadABook.complete
    function ISReadABook:complete()
        local result = originalComplete(self)
        if result ~= false and not self.forceStopped then
            fwpMarkLiteratureRead(self.character, self.item)
        end
        return result
    end
    ISReadABook.fwpReadStatePatched = true
end

if Events and Events.OnPlayerUpdate and not FWP_LITERATURE_MASTERY_UPDATE_REGISTERED then
    Events.OnPlayerUpdate.Add(fwpApplyMasteryForPlayer)
    FWP_LITERATURE_MASTERY_UPDATE_REGISTERED = true
end

print("[FWP LITERATURE] B42 read-state runtime registered")
