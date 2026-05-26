-- Runtime weapon-work actions that avoid B42 craftRecipe itemMapper validation.

FWPWeaponWork = FWPWeaponWork or {}
FWPWeaponWork.MODULE = "FWPWeaponWork"
FWPWeaponWork.COMMAND = "Apply"
FWPWeaponWork.CONFIRM = "Confirm"
FWPWeaponWork.ERROR = "Error"

local TRIGGER_GROUP_BY_WEAPON = {}

local function normalizeFullType(fullType)
    if FWPNormalizeFullType then
        return FWPNormalizeFullType(fullType)
    end
    if not fullType then return nil end
    fullType = tostring(fullType)
    if fullType == "" then return nil end
    if fullType:find(".", 1, true) then return fullType end
    return "Base." .. fullType
end

local function getFullType(item)
    if not item then return nil end
    if item.getFullType then
        local ok, fullType = pcall(function() return item:getFullType() end)
        if ok and fullType and tostring(fullType) ~= "" then
            return tostring(fullType)
        end
    end
    if item.getModule and item.getType then
        return tostring(item:getModule()) .. "." .. tostring(item:getType())
    end
    return nil
end

local function getType(item)
    if not item then return nil end
    if item.getType then
        local ok, itemType = pcall(function() return item:getType() end)
        if ok and itemType then return tostring(itemType) end
    end
    local fullType = getFullType(item)
    return fullType and fullType:gsub("^.*%.", "") or nil
end

local function safeCall(obj, methodName, ...)
    if not obj or not methodName or not obj[methodName] then return nil end
    local ok, result = pcall(obj[methodName], obj, ...)
    if ok then return result end
    return nil
end

local function safeSet(obj, methodName, ...)
    if not obj or not methodName or not obj[methodName] then return false end
    return pcall(obj[methodName], obj, ...) == true
end

local function safeNumber(value, fallback)
    value = tonumber(value)
    if value == nil then return fallback or 0 end
    return value
end

local function isHandWeapon(item)
    if not item then return false end
    if instanceof then
        local ok, result = pcall(instanceof, item, "HandWeapon")
        if ok and result == true then return true end
    end
    return item.IsWeapon and item:IsWeapon() == true
end

local function createItem(fullType)
    fullType = normalizeFullType(fullType)
    if not fullType then return nil end
    if FWPCreateItem then
        local ok, item = pcall(FWPCreateItem, fullType)
        if ok and item then return item end
    end
    if instanceItem then
        local ok, item = pcall(instanceItem, fullType)
        if ok and item then return item end
    end
    return nil
end

local function addItem(container, itemOrType)
    if not container or not itemOrType then return nil end
    if not container.AddItem then return nil end
    if type(itemOrType) == "string" then
        local ok, item = pcall(container.AddItem, container, normalizeFullType(itemOrType))
        if ok then return item end
        return nil
    end
    local ok = pcall(container.AddItem, container, itemOrType)
    if ok then return itemOrType end
    return nil
end

local function removeItem(item, fallbackInventory)
    local container = item and item.getContainer and item:getContainer() or fallbackInventory
    if not container then return false end
    if container.DoRemoveItem then
        local ok = pcall(container.DoRemoveItem, container, item)
        if ok then
            if sendRemoveItemFromContainer then pcall(sendRemoveItemFromContainer, container, item) end
            return true
        end
    end
    if container.Remove then
        local ok = pcall(container.Remove, container, item)
        if ok then
            if sendRemoveItemFromContainer then pcall(sendRemoveItemFromContainer, container, item) end
            return true
        end
    end
    return false
end

local function registerTriggerGroupWeapons(groupItemType, names)
    groupItemType = normalizeFullType(groupItemType)
    for name in tostring(names):gmatch("[^/]+") do
        TRIGGER_GROUP_BY_WEAPON[name] = groupItemType
        TRIGGER_GROUP_BY_WEAPON["Base." .. name] = groupItemType
    end
end

registerTriggerGroupWeapons("Base.TriggerGroup_AR", "AR57_PDW/AR57_PDW_Fold/AR57_PDW_Long/LVOA_C/AssaultRifle/ADAR/MK47/AAC_Honey/AAC_Honey_Fold/AAC_HoneySD/AAC_HoneySD_Fold/Bush_AR15_MOE/Bush_XM15/Bush_XM15_Custom/TR1_UltraLight/MCX_Spear/MCX_Virtus/MCX_VirtusPatrol/MCX_Socom/JW3_TTI_MPX/M723/XM117/H416/AR18/AR18_Fold/Carbon15_97/CAR15SMG/CAR15_Survival/M635/M635S/M635SD/M4/M4A1/M16A1/M16A2/M16A3/ColtM16/M16Wood/M16Tape/SCARL/SCARSC_Stock/SCARSC_Fold/SCARH/SCAR20/MK18")
registerTriggerGroupWeapons("Base.TriggerGroup_AK", "Origin/Saiga12/Saiga12_Long/Saiga12_Tromix/AK12_New/RPK16/AK308/AKM_Gold/AKM_Custom/AK74_Custom/AK47/AKM/AK103/M85_Stock/M85_Fold/MD65_Stock/MD65_Fold/AKMS_Stock/AKMS_Fold/AK74/AKS74/AKS74_Fold/AKS74U/AKS74U_Fold/AK12/AK12_Fold/AK74_Alpha/AK74_Alpha_Fold/RPK74/Galil/Galil_Fold/Galil_Sniper/Galil_Sniper_Fold/Vz58/Vz58_Stock/Vz58_Fold/Vz58_Mini_Stock/Vz58_Mini_Fold")
registerTriggerGroupWeapons("Base.TriggerGroup_HK", "MP7/MP7_Stock/G3/G28/G33/G36/G36_Fold/G36C/G36C_Fold/G36KV/G36KV_Fold/MP5_Fixed/MP5_Stock/MP5_Fold/MP5SD6_Fixed/MP5SD6_Stock/MP5SD6_Fold/UMP9_Stock/UMP9_Fold/UMP45_Stock/UMP45_Fold/XM8Compact_Pistol/XM8/XM8LMG")
registerTriggerGroupWeapons("Base.TriggerGroup_FN", "FAL/FAL_PARA_Stock/FAL_PARA_Fold/FN_FNC/FN_FNC_Fold/AK5C/AK5C_Fold")

local PAINTBALL_CANISTER_WEAPONS = {
    ["Base.VM_68"] = true,
    ["Base.Auto_Cocker"] = true,
    ["Base.Tippmann_SL68"] = true
}

local CO2_CANISTER_WEAPONS = {
    ["Base.UmarexSS"] = true,
    ["Base.Sheridan_PGP"] = true
}

local FLAME_FUEL_CONTAINER_TYPES = {
    ["Base.M2A1_Can"] = {
        label = "Propane Canister",
        maxAmmo = 100,
        sources = { "propane", "loose" }
    },
    ["Base.M2A1_Tank"] = {
        label = "M2A1 Tank",
        maxAmmo = 240,
        sources = { "petrol", "loose" }
    }
}

local WEAPON_CONVERSIONS_BY_SOURCE = {}
local WEAPON_CONVERSIONS_BY_ID = {}

local function addWeaponConversion(id, sourceTypes, targetType, label, opts)
    opts = opts or {}
    local def = {
        id = id,
        targetType = normalizeFullType(targetType),
        label = label,
        kind = opts.kind,
        partType = opts.partType and normalizeFullType(opts.partType) or nil,
        tool = opts.tool,
        returnBarrel = opts.returnBarrel == true,
        skipPistolParts = opts.skipPistolParts == true
    }
    WEAPON_CONVERSIONS_BY_ID[id] = def
    for _, sourceType in ipairs(sourceTypes) do
        sourceType = normalizeFullType(sourceType)
        WEAPON_CONVERSIONS_BY_SOURCE[sourceType] = WEAPON_CONVERSIONS_BY_SOURCE[sourceType] or {}
        table.insert(WEAPON_CONVERSIONS_BY_SOURCE[sourceType], def)
    end
end

addWeaponConversion("barrel_tc_308", { "Base.Thompson_Center_3006", "Base.Thompson_Center_4570" }, "Base.Thompson_Center_308", "Install .308 Barrel", { kind = "barrel", partType = "Base.Barrel_308", returnBarrel = true })
addWeaponConversion("barrel_tc_3006", { "Base.Thompson_Center_308", "Base.Thompson_Center_4570" }, "Base.Thompson_Center_3006", "Install .30-06 Barrel", { kind = "barrel", partType = "Base.Barrel_3006", returnBarrel = true })
addWeaponConversion("barrel_tc_4570", { "Base.Thompson_Center_308", "Base.Thompson_Center_3006" }, "Base.Thompson_Center_4570", "Install .45-70 Barrel", { kind = "barrel", partType = "Base.Barrel_4570", returnBarrel = true })
addWeaponConversion("barrel_nef_45lc", { "Base.NEF_Handi_38", "Base.NEF_Handi_357", "Base.NEF_Handi_38_Sawed", "Base.NEF_Handi_357_Sawed" }, "Base.NEF_Handi_45LC", "Install .45LC/.410 Barrel", { kind = "barrel", partType = "Base.Barrel_45LC", returnBarrel = true })
addWeaponConversion("barrel_nef_357", { "Base.NEF_Handi_45LC", "Base.NEF_Handi_410", "Base.NEF_Handi_45LC_Sawed", "Base.NEF_Handi_410_Sawed" }, "Base.NEF_Handi_357", "Install .38/.357 Barrel", { kind = "barrel", partType = "Base.Barrel_357", returnBarrel = true })
addWeaponConversion("barrel_nef_45lc_short", { "Base.NEF_Handi_38", "Base.NEF_Handi_357", "Base.NEF_Handi_38_Sawed", "Base.NEF_Handi_357_Sawed" }, "Base.NEF_Handi_45LC_Sawed", "Install Short .45LC/.410 Barrel", { kind = "barrel", partType = "Base.Barrel_45LC_Short", returnBarrel = true })
addWeaponConversion("barrel_nef_357_short", { "Base.NEF_Handi_45LC", "Base.NEF_Handi_410", "Base.NEF_Handi_45LC_Sawed", "Base.NEF_Handi_410_Sawed" }, "Base.NEF_Handi_357_Sawed", "Install Short .38/.357 Barrel", { kind = "barrel", partType = "Base.Barrel_357_Short", returnBarrel = true })

addWeaponConversion("sawoff_ks23", { "Base.KS23" }, "Base.KS23_S_Pistol", "Saw Off Barrel", { kind = "sawoff", tool = "saw", skipPistolParts = true })
addWeaponConversion("sawoff_coach_barrel", { "Base.Coachgun" }, "Base.Coachgun_Sawed", "Saw Off Barrel", { kind = "sawoff", tool = "saw" })
addWeaponConversion("sawoff_coach_stock", { "Base.Coachgun_Sawed" }, "Base.Coachgun_Pistol", "Saw Off Stock", { kind = "sawoff", tool = "saw", skipPistolParts = true })
addWeaponConversion("sawoff_dt11_barrel", { "Base.DT11" }, "Base.DT11_Sawed", "Saw Off Barrel", { kind = "sawoff", tool = "saw" })
addWeaponConversion("sawoff_dt11_stock", { "Base.DT11_Sawed" }, "Base.DT11_Pistol", "Saw Off Stock", { kind = "sawoff", tool = "saw", skipPistolParts = true })
addWeaponConversion("sawoff_m1887", { "Base.M1887" }, "Base.M1887_Sawed", "Saw Off Barrel", { kind = "sawoff", tool = "saw" })
addWeaponConversion("sawoff_nef_38", { "Base.NEF_Handi_38" }, "Base.NEF_Handi_38_Sawed", "Saw Off Barrel", { kind = "sawoff", tool = "saw" })
addWeaponConversion("sawoff_nef_357", { "Base.NEF_Handi_357" }, "Base.NEF_Handi_357_Sawed", "Saw Off Barrel", { kind = "sawoff", tool = "saw" })
addWeaponConversion("sawoff_nef_410", { "Base.NEF_Handi_410" }, "Base.NEF_Handi_410_Sawed", "Saw Off Barrel", { kind = "sawoff", tool = "saw" })
addWeaponConversion("sawoff_nef_45lc", { "Base.NEF_Handi_45LC" }, "Base.NEF_Handi_45LC_Sawed", "Saw Off Barrel", { kind = "sawoff", tool = "saw" })
addWeaponConversion("sawoff_mosin", { "Base.Mosin" }, "Base.MosinObrez_Pistol", "Saw Off Stock", { kind = "sawoff", tool = "saw", skipPistolParts = true })

addWeaponConversion("sks_a26_fixed", { "Base.SKS_A26", "Base.SKS30_A26" }, "Base.SKS_A26", "Install Fixed SKS Magazine", { kind = "fixedMag", partType = "Base.SKSFixedBox" })
addWeaponConversion("sks_a26_detachable", { "Base.SKS_A26" }, "Base.SKS30_A26", "Convert to Detachable Magazine", { kind = "fixedMag", partType = "Base.AKClip" })
addWeaponConversion("sks_fixed", { "Base.SKS", "Base.SKS30" }, "Base.SKS", "Install Fixed SKS Magazine", { kind = "fixedMag", partType = "Base.SKSFixedBox" })
addWeaponConversion("sks_detachable", { "Base.SKS" }, "Base.SKS30", "Convert to Detachable Magazine", { kind = "fixedMag", partType = "Base.AKClip" })
addWeaponConversion("sks_bayo_fixed", { "Base.SKS_Bayo", "Base.SKS30_Bayo" }, "Base.SKS_Bayo", "Install Fixed SKS Magazine", { kind = "fixedMag", partType = "Base.SKSFixedBox" })
addWeaponConversion("sks_bayo_detachable", { "Base.SKS_Bayo" }, "Base.SKS30_Bayo", "Convert to Detachable Magazine", { kind = "fixedMag", partType = "Base.AKClip" })
addWeaponConversion("sks_para_fixed", { "Base.SKS_PARA", "Base.SKS30_PARA" }, "Base.SKS_PARA", "Install Fixed SKS Magazine", { kind = "fixedMag", partType = "Base.SKSFixedBox" })
addWeaponConversion("sks_para_detachable", { "Base.SKS_PARA" }, "Base.SKS30_PARA", "Convert to Detachable Magazine", { kind = "fixedMag", partType = "Base.AKClip" })
addWeaponConversion("sks_para_bayo_fixed", { "Base.SKS_PARA_Bayo", "Base.SKS30_PARA_Bayo" }, "Base.SKS_PARA_Bayo", "Install Fixed SKS Magazine", { kind = "fixedMag", partType = "Base.SKSFixedBox" })
addWeaponConversion("sks_para_bayo_detachable", { "Base.SKS_PARA_Bayo" }, "Base.SKS30_PARA_Bayo", "Convert to Detachable Magazine", { kind = "fixedMag", partType = "Base.AKClip" })

local function eachInventoryItem(inventory, callback)
    if not inventory then return nil end
    if FWPEachInventoryItemRecursive then
        local found = nil
        FWPEachInventoryItemRecursive(inventory, function(item)
            if callback(item) then
                found = item
                return true
            end
            return false
        end)
        return found
    end
    if not inventory.getItems then return nil end
    local items = inventory:getItems()
    if not items then return nil end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if callback(item) then return item end
        if item and item.IsInventoryContainer and item:IsInventoryContainer() and item.getInventory then
            local nested = eachInventoryItem(item:getInventory(), callback)
            if nested then return nested end
        end
    end
    return nil
end

function FWPWeaponWorkGetTriggerGroupType(weapon)
    return TRIGGER_GROUP_BY_WEAPON[getFullType(weapon)] or TRIGGER_GROUP_BY_WEAPON[getType(weapon)]
end

function FWPWeaponWorkIsPaintballCanisterWeapon(weapon)
    return PAINTBALL_CANISTER_WEAPONS[getFullType(weapon)] == true
end

function FWPWeaponWorkIsCO2CanisterWeapon(weapon)
    return CO2_CANISTER_WEAPONS[getFullType(weapon)] == true
end

function FWPWeaponWorkFindItemByFullType(inventory, fullType)
    fullType = normalizeFullType(fullType)
    return eachInventoryItem(inventory, function(item)
        return getFullType(item) == fullType
    end)
end

function FWPWeaponWorkFindScrewdriver(inventory)
    if not inventory then return nil end
    if inventory.getFirstTagEvalRecurse and ItemTag and ItemTag.SCREWDRIVER then
        local ok, item = pcall(function()
            return inventory:getFirstTagEvalRecurse(ItemTag.SCREWDRIVER, function(candidate)
                return not (candidate and candidate.isBroken and candidate:isBroken())
            end)
        end)
        if ok and item then return item end
    end
    return eachInventoryItem(inventory, function(item)
        if not item then return false end
        if item.hasTag then
            local tag = FWPGetItemTag and FWPGetItemTag("base:screwdriver") or "base:screwdriver"
            local ok, has = pcall(function() return item:hasTag(tag) end)
            if ok and has then return true end
        end
        local itemType = getType(item) or ""
        return itemType == "Screwdriver"
    end)
end

function FWPWeaponWorkFindSaw(inventory)
    return eachInventoryItem(inventory, function(item)
        if not item then return false end
        if item.hasTag then
            for _, tagName in ipairs({ "base:metalsaw", "base:smallsaw", "base:saw" }) do
                local tag = FWPGetItemTag and FWPGetItemTag(tagName) or tagName
                local ok, has = pcall(function() return item:hasTag(tag) end)
                if ok and has then return true end
            end
        end
        local itemType = getType(item) or ""
        return itemType == "Saw" or itemType == "HandSaw" or itemType == "Hacksaw"
    end)
end

local function getWeaponConversions(weapon)
    return WEAPON_CONVERSIONS_BY_SOURCE[getFullType(weapon)] or WEAPON_CONVERSIONS_BY_SOURCE[normalizeFullType(getType(weapon))] or {}
end

local function conversionSourceMatches(def, weapon)
    for _, candidate in ipairs(getWeaponConversions(weapon)) do
        if candidate == def then return true end
    end
    return false
end

function FWPWeaponWorkGetPossibleConversions(weapon)
    local result = {}
    if not weapon then return result end
    for _, def in ipairs(getWeaponConversions(weapon)) do
        result[#result + 1] = {
            id = def.id,
            label = def.label,
            targetType = def.targetType,
            kind = def.kind,
            partType = def.partType,
            tool = def.tool
        }
    end
    return result
end

function FWPWeaponWorkGetAvailableConversions(weapon, inventory)
    local result = {}
    if not (weapon and inventory) then return result end
    for _, def in ipairs(getWeaponConversions(weapon)) do
        local part = nil
        local allowed = true
        if def.partType then
            part = FWPWeaponWorkFindItemByFullType(inventory, def.partType)
            allowed = part ~= nil
        elseif def.tool == "saw" then
            allowed = FWPWeaponWorkFindSaw(inventory) ~= nil
        end
        if allowed then
            result[#result + 1] = {
                id = def.id,
                label = def.label,
                part = part
            }
        end
    end
    return result
end

local function normalizeTriggerType(triggerType)
    triggerType = tonumber(triggerType) or 7
    if triggerType == 0 then return 0 end
    if triggerType == 2 then return 2 end
    if triggerType == 5 or triggerType == 6 or triggerType == 7 then return 5 end
    return 1
end

local function buildFireModes(triggerType)
    triggerType = normalizeTriggerType(triggerType)
    if triggerType == 0 then return { "N/A" } end
    if triggerType == 1 then return { "Single" } end
    if triggerType == 2 then return { "Auto" } end
    return { "Single", "Auto" }
end

function FWPWeaponWorkSetTriggerModes(weapon, triggerType)
    if not weapon then return end
    local normalized = normalizeTriggerType(triggerType)
    local modes = buildFireModes(normalized)
    if ArrayList and weapon.setFireModePossibilities then
        local list = ArrayList.new()
        for _, mode in ipairs(modes) do list:add(mode) end
        safeSet(weapon, "setFireModePossibilities", list)
    end
    safeSet(weapon, "setFireMode", modes[1] or "Single")
    if weapon.getModData then
        weapon:getModData().TriggerType = normalized
    end
end

local function inferTriggerType(weapon)
    local md = weapon and weapon.getModData and weapon:getModData() or nil
    if md and tonumber(md.TriggerType) then return tonumber(md.TriggerType) end
    local fireMode = tostring(safeCall(weapon, "getFireMode") or "")
    if fireMode == "N/A" then return 0 end
    local hasSingle = fireMode:find("Single", 1, true) ~= nil
    local hasAuto = fireMode:find("Auto", 1, true) ~= nil
    local modes = safeCall(weapon, "getFireModePossibilities")
    if modes and modes.size and modes.get then
        for i = 0, modes:size() - 1 do
            local mode = tostring(modes:get(i) or "")
            if mode:find("Single", 1, true) then hasSingle = true end
            if mode:find("Auto", 1, true) then hasAuto = true end
        end
    end
    if hasSingle and hasAuto then return 5 end
    if hasAuto then return 2 end
    if hasSingle then return 1 end
    return 7
end

local function triggerTypeFromPart(part)
    local md = part and part.getModData and part:getModData() or nil
    return safeNumber(md and md.TriggerType, 7)
end

local function getCanisterPart(weapon)
    if not weapon then return nil end
    if FWPGetWeaponPart then
        local part = FWPGetWeaponPart(weapon, "RecoilPad")
        if part then return part end
    end
    return safeCall(weapon, "getWeaponPart", "RecoilPad") or safeCall(weapon, "getRecoilpad")
end

local function setAmmoCount(item, ammoCount)
    if not item then return end
    ammoCount = safeNumber(ammoCount, 0)
    local maxAmmo = safeNumber(safeCall(item, "getMaxAmmo"), ammoCount)
    if maxAmmo > 0 then ammoCount = math.min(ammoCount, maxAmmo) end
    safeSet(item, "setCurrentAmmoCount", math.max(0, ammoCount))
end

local function syncWeapon(playerObj, weapon)
    if not weapon then return end
    if weapon.transmitModData then pcall(weapon.transmitModData, weapon) end
    if syncHandWeaponFields and isHandWeapon(weapon) then pcall(syncHandWeaponFields, playerObj, weapon) end
    if showMag and isHandWeapon(weapon) and weapon.isAimedFirearm and weapon:isAimedFirearm() then pcall(showMag, weapon) end
end

local function syncInventoryItem(item)
    if not item then return end
    if item.transmitModData then pcall(item.transmitModData, item) end
    if item.transmitCompleteItemToServer then pcall(item.transmitCompleteItemToServer, item) end
    if sendItemStats then pcall(sendItemStats, item) end
end

local function hasItemTag(item, tagName)
    if not (item and item.hasTag and tagName) then return false end
    local tag = FWPGetItemTag and FWPGetItemTag(tagName) or tagName
    local ok, result = pcall(function()
        return item:hasTag(tag)
    end)
    return ok and result == true
end

local function getFlameFuelContainerType(itemOrType)
    local fullType = type(itemOrType) == "string" and normalizeFullType(itemOrType) or getFullType(itemOrType)
    if fullType and FLAME_FUEL_CONTAINER_TYPES[fullType] then
        return fullType
    end
    if type(FWPIsFlameFuelCanister) == "function" and FWPIsFlameFuelCanister(itemOrType) then
        return fullType
    end
    return nil
end

local function getFlameFuelAmount(target, containerType)
    containerType = getFlameFuelContainerType(containerType) or getFlameFuelContainerType(target)
    local def = containerType and FLAME_FUEL_CONTAINER_TYPES[containerType] or nil
    if not def then return 0, 0 end
    local maxAmmo = safeNumber(safeCall(target, "getMaxAmmo"), def.maxAmmo)
    if maxAmmo <= 0 then maxAmmo = def.maxAmmo end
    local currentAmmo = safeNumber(safeCall(target, "getCurrentAmmoCount"), 0)
    if currentAmmo > maxAmmo then currentAmmo = maxAmmo end
    return currentAmmo, maxAmmo
end

local function isPropaneFuelSource(item)
    if not item then return false end
    local fullType = getFullType(item) or ""
    local itemType = getType(item) or ""
    if fullType ~= "Base.PropaneTank" and not itemType:find("Propane", 1, true) then
        return false
    end
    return safeNumber(safeCall(item, "getUsedDelta"), 0) > 0
end

local function isPetrolFuelSource(item)
    if not item then return false end
    local fullType = getFullType(item) or ""
    local itemType = getType(item) or ""
    local tagged = hasItemTag(item, "Petrol") or hasItemTag(item, "base:petrol") or hasItemTag(item, "base:gasoline")
    local named = fullType:find("Petrol", 1, true) ~= nil
        or fullType:find("GasCan", 1, true) ~= nil
        or fullType:find("Gasoline", 1, true) ~= nil
        or itemType:find("Petrol", 1, true) ~= nil
        or itemType:find("GasCan", 1, true) ~= nil
        or itemType:find("Gasoline", 1, true) ~= nil
    if not (tagged or named) then return false end

    local usedDelta = safeCall(item, "getUsedDelta")
    if usedDelta ~= nil then
        return safeNumber(usedDelta, 0) > 0
    end

    local fluidContainer = safeCall(item, "getFluidContainer")
    local amount = safeNumber(safeCall(fluidContainer, "getAmount"), safeNumber(safeCall(fluidContainer, "getCurrentAmount"), 0))
    return amount > 0
end

local function findFuelSourceByKind(inventory, kind)
    if kind == "loose" then
        return FWPWeaponWorkFindItemByFullType(inventory, "Base.FlameFuel")
    end
    if kind == "propane" then
        return eachInventoryItem(inventory, isPropaneFuelSource)
    end
    if kind == "petrol" then
        return eachInventoryItem(inventory, isPetrolFuelSource)
    end
    return nil
end

function FWPWeaponWorkIsFlameFuelContainer(itemOrType)
    return getFlameFuelContainerType(itemOrType) ~= nil
end

function FWPWeaponWorkGetFlameFuelContainerLabel(itemOrType)
    local containerType = getFlameFuelContainerType(itemOrType)
    local def = containerType and FLAME_FUEL_CONTAINER_TYPES[containerType] or nil
    return def and def.label or "Flame Fuel Container"
end

function FWPWeaponWorkNeedsFlameFuelContainer(item)
    local containerType = getFlameFuelContainerType(item)
    if not containerType then return false end
    if type(FWPEnsureFlameFuelCanisterInitialized) == "function" then
        FWPEnsureFlameFuelCanisterInitialized(item)
    end
    local currentAmmo, maxAmmo = getFlameFuelAmount(item, containerType)
    return maxAmmo > 0 and currentAmmo < maxAmmo
end

function FWPWeaponWorkFindFuelSourceForContainer(inventory, itemOrType)
    local containerType = getFlameFuelContainerType(itemOrType)
    local def = containerType and FLAME_FUEL_CONTAINER_TYPES[containerType] or nil
    if not (inventory and def) then return nil, nil end

    for _, kind in ipairs(def.sources) do
        local source = findFuelSourceByKind(inventory, kind)
        if source then
            return source, kind
        end
    end

    return nil, nil
end

function FWPWeaponWorkCanRefillFlameFuelContainer(playerObj, item)
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    if not (inventory and FWPWeaponWorkNeedsFlameFuelContainer(item)) then return false end
    local source = FWPWeaponWorkFindFuelSourceForContainer(inventory, item)
    return source ~= nil
end

function FWPWeaponWorkGetLoadedFlameFuelContainerType(weapon)
    if not weapon then return nil end
    local ammoItem = nil
    if type(FWPGetAmmoItemKey) == "function" then
        ammoItem = FWPGetAmmoItemKey(weapon)
    end
    if ammoItem and ammoItem ~= "Base.FlameFuel" and ammoItem ~= "fwp:flame_fuel" then
        return nil
    end
    if safeCall(weapon, "isContainsClip") ~= true then return nil end
    return getFlameFuelContainerType(safeCall(weapon, "getMagazineType"))
end

function FWPWeaponWorkCanRefillLoadedFlameFuel(playerObj, weapon)
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    local containerType = FWPWeaponWorkGetLoadedFlameFuelContainerType(weapon)
    if not (inventory and containerType) then return false end
    local currentAmmo, maxAmmo = getFlameFuelAmount(weapon, containerType)
    if maxAmmo <= 0 or currentAmmo >= maxAmmo then return false end
    local source = FWPWeaponWorkFindFuelSourceForContainer(inventory, containerType)
    return source ~= nil
end

local function consumeLooseFlameFuel(inventory, requested)
    local consumed = 0
    requested = math.max(0, safeNumber(requested, 0))
    while consumed < requested do
        local fuel = FWPWeaponWorkFindItemByFullType(inventory, "Base.FlameFuel")
        if not fuel then break end
        if not removeItem(fuel, inventory) then break end
        consumed = consumed + 1
    end
    return consumed
end

local function consumeUsedDeltaFuel(source, requested, fuelPerUse, deltaPerUse)
    requested = math.max(0, safeNumber(requested, 0))
    fuelPerUse = math.max(1, safeNumber(fuelPerUse, 1))
    deltaPerUse = math.max(0.001, safeNumber(deltaPerUse, 0.001))
    local usedDelta = safeNumber(safeCall(source, "getUsedDelta"), 0)
    if requested <= 0 or usedDelta <= 0 then return 0 end

    local possibleUses = math.floor((usedDelta / deltaPerUse) + 0.0001)
    if possibleUses <= 0 then possibleUses = 1 end
    local transfer = math.min(requested, possibleUses * fuelPerUse)
    local uses = math.ceil(transfer / fuelPerUse)
    local drain = math.min(usedDelta, uses * deltaPerUse)
    if not safeSet(source, "setUsedDelta", math.max(0, usedDelta - drain)) then
        return 0
    end
    syncInventoryItem(source)
    return transfer
end

local function consumeFluidContainerFuel(source, requested)
    requested = math.max(0, safeNumber(requested, 0))
    local fluidContainer = safeCall(source, "getFluidContainer")
    if requested <= 0 or not fluidContainer then return 0 end

    local amount = safeNumber(safeCall(fluidContainer, "getAmount"), safeNumber(safeCall(fluidContainer, "getCurrentAmount"), 0))
    if amount <= 0 then return 0 end
    local possibleUses = math.floor((amount / 0.1) + 0.0001)
    if possibleUses <= 0 then possibleUses = 1 end
    local transfer = math.min(requested, possibleUses * 30)
    local drain = math.min(amount, math.ceil(transfer / 30) * 0.1)
    local drained = safeSet(fluidContainer, "removeFluid", drain)
        or safeSet(fluidContainer, "RemoveFluid", drain)
        or safeSet(fluidContainer, "adjustAmount", -drain)
    if not drained then return 0 end
    syncInventoryItem(source)
    return transfer
end

local function consumeFuelSource(inventory, source, kind, requested)
    if kind == "loose" then
        return consumeLooseFlameFuel(inventory, requested)
    elseif kind == "propane" then
        return consumeUsedDeltaFuel(source, requested, 25, 0.03)
    elseif kind == "petrol" then
        local consumed = consumeUsedDeltaFuel(source, requested, 30, 0.1)
        if consumed > 0 then return consumed end
        return consumeFluidContainerFuel(source, requested)
    end
    return 0
end

local function applyRefillFuelContainer(playerObj, container)
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    local containerType = getFlameFuelContainerType(container)
    if not (inventory and containerType) then return false, "invalid_fuel_container" end
    if type(FWPEnsureFlameFuelCanisterInitialized) == "function" then
        FWPEnsureFlameFuelCanisterInitialized(container)
    end

    local currentAmmo, maxAmmo = getFlameFuelAmount(container, containerType)
    if maxAmmo <= 0 or currentAmmo >= maxAmmo then return false, "fuel_full" end
    local source, kind = FWPWeaponWorkFindFuelSourceForContainer(inventory, containerType)
    if not source then return false, "missing_fuel_source" end

    local transfer = consumeFuelSource(inventory, source, kind, maxAmmo - currentAmmo)
    if transfer <= 0 then return false, "fuel_source_empty" end
    setAmmoCount(container, currentAmmo + transfer)
    if type(FWPMarkFlameFuelCanisterKnown) == "function" then
        FWPMarkFlameFuelCanisterKnown(container, true)
    end
    syncInventoryItem(container)
    return true
end

local function applyRefillLoadedFlameFuel(playerObj, weapon)
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    local containerType = FWPWeaponWorkGetLoadedFlameFuelContainerType(weapon)
    if not (inventory and weapon and containerType) then return false, "loaded_fuel_container_missing" end

    local currentAmmo, maxAmmo = getFlameFuelAmount(weapon, containerType)
    if maxAmmo <= 0 or currentAmmo >= maxAmmo then return false, "fuel_full" end
    local source, kind = FWPWeaponWorkFindFuelSourceForContainer(inventory, containerType)
    if not source then return false, "missing_fuel_source" end

    local transfer = consumeFuelSource(inventory, source, kind, maxAmmo - currentAmmo)
    if transfer <= 0 then return false, "fuel_source_empty" end
    setAmmoCount(weapon, currentAmmo + transfer)
    syncWeapon(playerObj, weapon)
    return true
end

local function applyRemoveTrigger(playerObj, weapon)
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    local groupType = FWPWeaponWorkGetTriggerGroupType(weapon)
    if not (inventory and weapon and groupType) then return false, "unsupported_weapon" end
    if not FWPWeaponWorkFindScrewdriver(inventory) then return false, "missing_screwdriver" end
    local triggerType = inferTriggerType(weapon)
    if triggerType == 0 then return false, "trigger_already_removed" end
    local part = createItem(groupType)
    if not part then return false, "trigger_create_failed" end
    if part.getModData then part:getModData().TriggerType = triggerType end
    if not addItem(inventory, part) then return false, "trigger_add_failed" end
    if sendAddItemToContainer then pcall(sendAddItemToContainer, inventory, part) end
    FWPWeaponWorkSetTriggerModes(weapon, 0)
    safeSet(weapon, "setJammed", true)
    syncWeapon(playerObj, weapon)
    return true
end

local function applyInstallTrigger(playerObj, weapon, part)
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    local groupType = FWPWeaponWorkGetTriggerGroupType(weapon)
    if not (inventory and weapon and groupType) then return false, "unsupported_weapon" end
    if not FWPWeaponWorkFindScrewdriver(inventory) then return false, "missing_screwdriver" end
    if not part then part = FWPWeaponWorkFindItemByFullType(inventory, groupType) end
    if getFullType(part) ~= groupType then return false, "missing_trigger_group" end
    local md = weapon.getModData and weapon:getModData() or nil
    if md and tonumber(md.TriggerType) and tonumber(md.TriggerType) ~= 0 then return false, "trigger_present" end
    local triggerType = triggerTypeFromPart(part)
    if not removeItem(part, inventory) then return false, "trigger_remove_failed" end
    FWPWeaponWorkSetTriggerModes(weapon, triggerType)
    safeSet(weapon, "setJammed", false)
    syncWeapon(playerObj, weapon)
    return true
end

local function applyInstallCanister(playerObj, weapon, tank)
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    if not (inventory and weapon) then return false, "invalid_args" end
    if not FWPWeaponWorkFindScrewdriver(inventory) then return false, "missing_screwdriver" end
    if getCanisterPart(weapon) then return false, "canister_present" end

    local weaponIsPaintball = FWPWeaponWorkIsPaintballCanisterWeapon(weapon)
    local weaponIsCO2 = FWPWeaponWorkIsCO2CanisterWeapon(weapon)
    local tankType = getFullType(tank)
    if weaponIsPaintball and tankType ~= "Base.M2A1_Can" then return false, "missing_m2a1_can" end
    if weaponIsCO2 and tankType ~= "Base.CO2_Cartridge" then return false, "missing_co2_cartridge" end
    if not (weaponIsPaintball or weaponIsCO2) then return false, "unsupported_weapon" end
    local partType = weaponIsPaintball and "Base.Standard_PB_Can" or "Base.CO2_Cartridge_Used"
    local part = createItem(partType)
    if not part then return false, "canister_part_create_failed" end
    if not tank or not removeItem(tank, inventory) then return false, "tank_remove_failed" end
    safeSet(weapon, "attachWeaponPart", part)

    local air = weaponIsPaintball and safeNumber(safeCall(tank, "getCurrentAmmoCount"), 100) or 100
    if air <= 0 then air = 100 end
    if weapon.getModData then weapon:getModData().Air = air end
    syncWeapon(playerObj, weapon)
    return true
end

local function applyRemoveCanister(playerObj, weapon)
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    if not (inventory and weapon) then return false, "invalid_args" end
    if not FWPWeaponWorkFindScrewdriver(inventory) then return false, "missing_screwdriver" end
    local part = getCanisterPart(weapon)
    if not part then return false, "canister_missing" end

    local returnType = FWPWeaponWorkIsPaintballCanisterWeapon(weapon) and "Base.M2A1_Can" or "Base.CO2_Cartridge_Used"
    local returned = createItem(returnType)
    if not returned then return false, "return_item_create_failed" end
    if returnType == "Base.M2A1_Can" then
        local md = weapon.getModData and weapon:getModData() or nil
        setAmmoCount(returned, safeNumber(md and md.Air, safeCall(weapon, "getCurrentAmmoCount") or 0))
    end

    if weapon.detachWeaponPart then pcall(weapon.detachWeaponPart, weapon, part) end
    if weapon.getModData then weapon:getModData().Air = nil end
    if not addItem(inventory, returned) then return false, "return_item_add_failed" end
    if sendAddItemToContainer then pcall(sendAddItemToContainer, inventory, returned) end
    syncWeapon(playerObj, weapon)
    return true
end

local function copyModData(source, target)
    local sourceMd = source and source.getModData and source:getModData() or nil
    local targetMd = target and target.getModData and target:getModData() or nil
    if not (sourceMd and targetMd) then return end
    for key, value in pairs(sourceMd) do
        targetMd[key] = value
    end
    targetMd.weaponpart = nil
end

local function copyWeaponParts(source, target, inventory, skipParts)
    if not (source and target) then return end
    skipParts = skipParts or {}
    for _, slot in ipairs({ "Scope", "Canon", "Clip", "Stock", "Sling", "RecoilPad" }) do
        local part = FWPGetWeaponPart and FWPGetWeaponPart(source, slot) or safeCall(source, "getWeaponPart", slot)
        if part then
            if skipParts[slot] and inventory then
                addItem(inventory, part)
                if sendAddItemToContainer then pcall(sendAddItemToContainer, inventory, part) end
            else
                safeSet(target, "attachWeaponPart", part)
            end
        end
    end
end

local function copyWeaponState(source, target, playerObj, options)
    if not (source and target) then return end
    options = options or {}
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    copyModData(source, target)
    safeSet(target, "setCondition", safeNumber(safeCall(source, "getCondition"), safeNumber(safeCall(target, "getCondition"), 0)))
    safeSet(target, "setHaveBeenRepaired", safeNumber(safeCall(source, "getHaveBeenRepaired"), safeNumber(safeCall(target, "getHaveBeenRepaired"), 0)))
    if safeCall(source, "isFavorite") ~= nil then safeSet(target, "setFavorite", safeCall(source, "isFavorite") == true) end
    local fireMode = safeCall(source, "getFireMode")
    if fireMode ~= nil then safeSet(target, "setFireMode", fireMode) end
    if options.copyAmmo ~= false then
        local magazineType = safeCall(source, "getMagazineType")
        if magazineType ~= nil then safeSet(target, "setMagazineType", magazineType) end
        local maxAmmo = safeCall(source, "getMaxAmmo")
        if maxAmmo ~= nil then safeSet(target, "setMaxAmmo", maxAmmo) end
        local currentAmmo = safeCall(source, "getCurrentAmmoCount")
        if currentAmmo ~= nil then safeSet(target, "setCurrentAmmoCount", currentAmmo) end
        local containsClip = safeCall(source, "isContainsClip")
        if containsClip ~= nil then safeSet(target, "setContainsClip", containsClip == true) end
        local chambered = safeCall(source, "isRoundChambered")
        if chambered ~= nil then safeSet(target, "setRoundChambered", chambered == true) end
        local spentChambered = safeCall(source, "isSpentRoundChambered")
        if spentChambered ~= nil then safeSet(target, "setSpentRoundChambered", spentChambered == true) end
        local spentCount = safeCall(source, "getSpentRoundCount")
        if spentCount ~= nil then safeSet(target, "setSpentRoundCount", spentCount) end
    end
    copyWeaponParts(source, target, inventory, options.skipParts)
end

local function oldBarrelTypeForWeapon(weapon)
    local itemType = getType(weapon) or ""
    if itemType:find("308", 1, true) then
        return "Base.Barrel_308"
    elseif itemType:find("3006", 1, true) then
        return "Base.Barrel_3006"
    elseif itemType:find("4570", 1, true) then
        return "Base.Barrel_4570"
    elseif itemType:find("45LC", 1, true) or itemType:find("410", 1, true) then
        return itemType:find("Sawed", 1, true) and "Base.Barrel_45LC_Short" or "Base.Barrel_45LC"
    elseif itemType:find("357", 1, true) or itemType:find("38", 1, true) then
        return itemType:find("Sawed", 1, true) and "Base.Barrel_357_Short" or "Base.Barrel_357"
    end
    return nil
end

local function addResultToInventory(playerObj, oldWeapon, result, hotbarWeight)
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    if not (inventory and oldWeapon and result) then return false, "invalid_args" end
    local wasPrimary = playerObj.getPrimaryHandItem and playerObj:getPrimaryHandItem() == oldWeapon
    local wasSecondary = playerObj.getSecondaryHandItem and playerObj:getSecondaryHandItem() == oldWeapon
    local container = oldWeapon.getContainer and oldWeapon:getContainer() or inventory
    local added = addItem(container, result)
    if not added and container ~= inventory then
        added = addItem(inventory, result)
        container = inventory
    end
    if not added then return false, "inventory_add_failed" end
    if sendAddItemToContainer then pcall(sendAddItemToContainer, container, result) end
    if wasPrimary and playerObj.setPrimaryHandItem then pcall(playerObj.setPrimaryHandItem, playerObj, result) end
    if playerObj.setSecondaryHandItem then
        local twoHand = safeCall(result, "isRequiresEquippedBothHands") == true or safeCall(result, "isTwoHandWeapon") == true
        if twoHand or wasSecondary then
            pcall(playerObj.setSecondaryHandItem, playerObj, result)
        elseif playerObj.getSecondaryHandItem and playerObj:getSecondaryHandItem() == oldWeapon then
            pcall(playerObj.setSecondaryHandItem, playerObj, nil)
        end
    end
    if not removeItem(oldWeapon, inventory) then return false, "weapon_remove_failed" end
    if checkHotbar then pcall(checkHotbar, playerObj, oldWeapon, result, hotbarWeight or 1) end
    if ReEquipIt and wasPrimary then pcall(ReEquipIt, playerObj, result) end
    syncWeapon(playerObj, result)
    return true
end

local function applyWeaponConversion(playerObj, weapon, conversionId, part)
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    local def = WEAPON_CONVERSIONS_BY_ID[tostring(conversionId or "")]
    if not (inventory and weapon and def) then return false, "invalid_args" end
    if not conversionSourceMatches(def, weapon) then return false, "unsupported_weapon" end

    if def.partType then
        if getFullType(part) ~= def.partType then
            part = FWPWeaponWorkFindItemByFullType(inventory, def.partType)
        end
        if getFullType(part) ~= def.partType then return false, "missing_part" end
    elseif def.tool == "saw" and not FWPWeaponWorkFindSaw(inventory) then
        return false, "missing_saw"
    end

    local result = createItem(def.targetType)
    if not result then return false, "target_create_failed" end

    local returnItem = nil
    if def.returnBarrel then
        local oldBarrelType = oldBarrelTypeForWeapon(weapon)
        if oldBarrelType then
            returnItem = createItem(oldBarrelType)
            if not returnItem then return false, "return_barrel_create_failed" end
        end
    end

    local oldMag = nil
    local partAmmo = part and safeNumber(safeCall(part, "getCurrentAmmoCount"), 0) or 0
    if def.kind == "fixedMag" then
        local oldAmmo = safeNumber(safeCall(weapon, "getCurrentAmmoCount"), 0)
        local oldMagType = nil
        local sourceData = weapon.getModData and weapon:getModData() or nil
        if sourceData and sourceData.FixedMagType and safeCall(weapon, "isContainsClip") == true then
            oldMagType = sourceData.FixedMagType
        elseif safeCall(weapon, "isContainsClip") == true then
            oldMagType = safeCall(weapon, "getMagazineType")
            if sourceData and sourceData.ClipType and sourceData.MagType and oldMagType == sourceData.ClipType then
                oldMagType = sourceData.MagType
            end
        end
        oldMagType = normalizeFullType(oldMagType)
        if oldMagType and oldMagType ~= "Base.Fixed" then
            oldMag = createItem(oldMagType)
            if oldMag then setAmmoCount(oldMag, oldAmmo) end
        end
    end

    if def.partType and not removeItem(part, inventory) then return false, "part_remove_failed" end

    local skipParts = nil
    if def.kind == "fixedMag" then
        skipParts = { Clip = true }
    elseif def.skipPistolParts and tostring(def.targetType):find("Pistol", 1, true) then
        skipParts = { Sling = true, RecoilPad = true }
    end
    copyWeaponState(weapon, result, playerObj, { skipParts = skipParts })

    if def.kind == "fixedMag" then
        safeSet(result, "setContainsClip", true)
        setAmmoCount(result, partAmmo)
        local chambered = safeCall(weapon, "isRoundChambered")
        if chambered ~= nil then safeSet(result, "setRoundChambered", chambered == true) end
    end

    local ok, err = addResultToInventory(playerObj, weapon, result, def.kind == "sawoff" and 10 or 30)
    if not ok then return false, err end

    if returnItem then
        if not addItem(inventory, returnItem) then return false, "return_barrel_add_failed" end
        if sendAddItemToContainer then pcall(sendAddItemToContainer, inventory, returnItem) end
    end
    if oldMag then
        if not addItem(inventory, oldMag) then return false, "old_mag_add_failed" end
        if sendAddItemToContainer then pcall(sendAddItemToContainer, inventory, oldMag) end
    end

    return true
end

function FWPWeaponWorkApplyCommand(playerObj, args)
    if not (playerObj and args) then return false, "invalid_args" end
    local inventory = playerObj.getInventory and playerObj:getInventory() or nil
    if not inventory then return false, "inventory_missing" end

    local op = tostring(args.op or "")
    if op == "refillFuelContainer" then
        local container = FWPFindPlayerInventoryItemById and FWPFindPlayerInventoryItemById(playerObj, args.partId, false) or nil
        return applyRefillFuelContainer(playerObj, container)
    end

    local weapon = FWPFindPlayerInventoryItemById and FWPFindPlayerInventoryItemById(playerObj, args.weaponId, true) or nil
    if not weapon then return false, "weapon_missing" end

    if op == "removeTrigger" then
        return applyRemoveTrigger(playerObj, weapon)
    elseif op == "installTrigger" then
        local part = FWPFindPlayerInventoryItemById and FWPFindPlayerInventoryItemById(playerObj, args.partId, false) or nil
        return applyInstallTrigger(playerObj, weapon, part)
    elseif op == "installCanister" then
        local tank = FWPFindPlayerInventoryItemById and FWPFindPlayerInventoryItemById(playerObj, args.partId, false) or nil
        return applyInstallCanister(playerObj, weapon, tank)
    elseif op == "removeCanister" then
        return applyRemoveCanister(playerObj, weapon)
    elseif op == "refillLoadedFlameFuel" then
        return applyRefillLoadedFlameFuel(playerObj, weapon)
    elseif op == "convertWeapon" then
        local part = FWPFindPlayerInventoryItemById and FWPFindPlayerInventoryItemById(playerObj, args.partId, false) or nil
        return applyWeaponConversion(playerObj, weapon, args.conversionId, part)
    end

    return false, "unknown_op"
end

print("[FWP WEAPONWORK] runtime helpers registered")
