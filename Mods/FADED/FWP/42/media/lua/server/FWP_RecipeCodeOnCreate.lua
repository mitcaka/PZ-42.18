RecipeCodeOnCreate = RecipeCodeOnCreate or {}

local function addItem(inventory, itemType, count)
    if not inventory or not itemType then
        return
    end

    count = tonumber(count) or 1
    for _ = 1, count do
        inventory:AddItem(itemType)
    end
end

local function normalizeItemType(itemType)
    if not itemType then
        return nil
    end
    itemType = tostring(itemType)
    if itemType == "" then
        return nil
    end
    if itemType:find(".", 1, true) then
        return itemType
    end
    return "Base." .. itemType
end

local function safeCall(obj, methodName, ...)
    if not obj or not methodName or not obj[methodName] then
        return nil
    end
    local ok, result = pcall(obj[methodName], obj, ...)
    if ok then
        return result
    end
    return nil
end

local function safeSet(obj, methodName, ...)
    if not obj or not methodName or not obj[methodName] then
        return false
    end
    local ok = pcall(obj[methodName], obj, ...)
    return ok == true
end

local function safeNumber(value, fallback)
    value = tonumber(value)
    if value == nil then
        return fallback or 0
    end
    return value
end

local function getItemType(item)
    if not item then
        return nil
    end
    local itemType = safeCall(item, "getType")
    if itemType ~= nil then
        return tostring(itemType)
    end
    return nil
end

local function getItemFullType(item)
    if not item then
        return nil
    end
    local fullType = safeCall(item, "getFullType")
    if fullType ~= nil and tostring(fullType) ~= "" then
        return tostring(fullType)
    end
    local moduleName = safeCall(item, "getModule") or "Base"
    local itemType = getItemType(item)
    if itemType then
        return tostring(moduleName) .. "." .. itemType
    end
    return nil
end

local function javaListSize(list)
    if not list or not list.size then
        return 0
    end
    local ok, size = pcall(list.size, list)
    if ok and size then
        return tonumber(size) or 0
    end
    return 0
end

local function javaListGet(list, index)
    if not list or not list.get then
        return nil
    end
    local ok, item = pcall(list.get, list, index)
    if ok then
        return item
    end
    return nil
end

local function isHandWeaponItem(item)
    if not item then
        return false
    end
    if instanceof then
        local ok, result = pcall(instanceof, item, "HandWeapon")
        if ok and result == true then
            return true
        end
    end
    return item.getCurrentAmmoCount ~= nil and item.getMaxAmmo ~= nil and item.getCondition ~= nil and item.setCondition ~= nil
end

local function isMagazineItem(item)
    if not item or isHandWeaponItem(item) then
        return false
    end
    if isMagazine then
        local ok, result = pcall(isMagazine, item)
        if ok and result == true then
            return true
        end
    end
    return item.getCurrentAmmoCount ~= nil and item.getMaxAmmo ~= nil and item.setCurrentAmmoCount ~= nil
end

local function findItem(list, predicate)
    local count = javaListSize(list)
    for i = 0, count - 1 do
        local item = javaListGet(list, i)
        if item and predicate(item) then
            return item
        end
    end
    return nil
end

local function findConsumedWeapon(craftRecipeData)
    if not craftRecipeData then
        return nil
    end
    return findItem(craftRecipeData:getAllConsumedItems(), isHandWeaponItem)
end

local function findCreatedWeapon(craftRecipeData)
    if not craftRecipeData then
        return nil
    end
    return findItem(craftRecipeData:getAllCreatedItems(), isHandWeaponItem)
end

local function findConsumedMagazine(craftRecipeData)
    if not craftRecipeData then
        return nil
    end
    return findItem(craftRecipeData:getAllConsumedItems(), isMagazineItem)
end

local function findCreatedAmmoContainer(craftRecipeData)
    if not craftRecipeData then
        return nil
    end
    local created = craftRecipeData:getAllCreatedItems()
    return findItem(created, isHandWeaponItem) or findItem(created, isMagazineItem)
end

local function findConsumedByTypes(craftRecipeData, types)
    if not craftRecipeData or not types then
        return nil
    end
    local wanted = {}
    for _, itemType in ipairs(types) do
        wanted[normalizeItemType(itemType)] = true
        wanted[tostring(itemType):gsub("^Base%.", "")] = true
    end
    return findItem(craftRecipeData:getAllConsumedItems(), function(item)
        return wanted[getItemFullType(item)] == true or wanted[getItemType(item)] == true
    end)
end

local function findInputByTypes(craftRecipeData, types)
    if not craftRecipeData or not types or not craftRecipeData.getAllInputItems then
        return nil
    end
    local wanted = {}
    for _, itemType in ipairs(types) do
        wanted[normalizeItemType(itemType)] = true
        wanted[tostring(itemType):gsub("^Base%.", "")] = true
    end
    return findItem(craftRecipeData:getAllInputItems(), function(item)
        return wanted[getItemFullType(item)] == true or wanted[getItemType(item)] == true
    end)
end

local function findCreatedByTypes(craftRecipeData, types)
    if not craftRecipeData or not types then
        return nil
    end
    local wanted = {}
    for _, itemType in ipairs(types) do
        wanted[normalizeItemType(itemType)] = true
        wanted[tostring(itemType):gsub("^Base%.", "")] = true
    end
    return findItem(craftRecipeData:getAllCreatedItems(), function(item)
        return wanted[getItemFullType(item)] == true or wanted[getItemType(item)] == true
    end)
end

local function createItemObject(itemType)
    itemType = normalizeItemType(itemType)
    if not itemType then
        return nil
    end
    if FWPCreateItem then
        local ok, item = pcall(FWPCreateItem, itemType)
        if ok and item then
            return item
        end
    end
    if instanceItem then
        local ok, item = pcall(instanceItem, itemType)
        if ok and item then
            return item
        end
    end
    return nil
end

local function addItemObject(inventory, itemType)
    if not inventory then
        return nil
    end
    local item = createItemObject(itemType)
    if item then
        local ok = pcall(inventory.AddItem, inventory, item)
        if ok then
            return item
        end
    end
    local normalized = normalizeItemType(itemType)
    if normalized then
        local ok, added = pcall(inventory.AddItem, inventory, normalized)
        if ok then
            return added
        end
    end
    return nil
end

local function copyModData(source, target)
    if not source or not target or not source.getModData or not target.getModData then
        return
    end
    local sourceData = source:getModData()
    local targetData = target:getModData()
    if not sourceData or not targetData then
        return
    end
    for key, value in pairs(sourceData) do
        if type(value) ~= "function" and type(value) ~= "userdata" and type(value) ~= "thread" then
            targetData[key] = value
        end
    end
end

local function getWeaponPart(weapon, slot)
    if not weapon or not slot then
        return nil
    end
    if FWPGetWeaponPart then
        local ok, part = pcall(FWPGetWeaponPart, weapon, slot)
        if ok and part then
            return part
        end
    end
    if slot == "RecoilPad" and weapon.getRecoilpad then
        local recoil = safeCall(weapon, "getRecoilpad")
        if recoil then
            return recoil
        end
    end
    return safeCall(weapon, "getWeaponPart", slot)
end

local function copyWeaponParts(source, target, inventory, options)
    if not source or not target or not target.attachWeaponPart then
        return
    end
    options = options or {}
    local skip = options.skipParts or {}
    local slots = { "Scope", "Canon", "Clip", "Stock", "Sling", "RecoilPad" }
    for _, slot in ipairs(slots) do
        local part = getWeaponPart(source, slot)
        if part then
            if skip[slot] and inventory then
                pcall(inventory.AddItem, inventory, part)
            else
                safeSet(target, "attachWeaponPart", part)
            end
        end
    end
end

local function copyWeaponState(source, target, character, options)
    if not source or not target then
        return
    end
    copyModData(source, target)
    safeSet(target, "setCondition", safeNumber(safeCall(source, "getCondition"), safeNumber(safeCall(target, "getCondition"), 0)))
    local fireMode = safeCall(source, "getFireMode")
    if fireMode ~= nil then
        safeSet(target, "setFireMode", fireMode)
    end
    local magazineType = safeCall(source, "getMagazineType")
    if magazineType ~= nil then
        safeSet(target, "setMagazineType", magazineType)
    end
    local maxAmmo = safeCall(source, "getMaxAmmo")
    if maxAmmo ~= nil then
        safeSet(target, "setMaxAmmo", maxAmmo)
    end
    local currentAmmo = safeCall(source, "getCurrentAmmoCount")
    if currentAmmo ~= nil then
        safeSet(target, "setCurrentAmmoCount", currentAmmo)
    end
    local containsClip = safeCall(source, "isContainsClip")
    if containsClip ~= nil then
        safeSet(target, "setContainsClip", containsClip == true)
    end
    local chambered = safeCall(source, "isRoundChambered")
    if chambered ~= nil then
        safeSet(target, "setRoundChambered", chambered == true)
    end
    copyWeaponParts(source, target, character and character:getInventory() or nil, options)
end

local function equipIfWeapon(character, weapon)
    if not character or not weapon or not isHandWeaponItem(weapon) then
        return
    end
    safeSet(character, "setPrimaryHandItem", weapon)
    local twoHand = safeCall(weapon, "isRequiresEquippedBothHands") == true or safeCall(weapon, "isTwoHandWeapon") == true
    if twoHand then
        safeSet(character, "setSecondaryHandItem", weapon)
    else
        safeSet(character, "setSecondaryHandItem", nil)
    end
end

local function setAmmoCount(item, ammoCount)
    if not item then
        return
    end
    local maxAmmo = safeNumber(safeCall(item, "getMaxAmmo"), ammoCount)
    if maxAmmo > 0 and ammoCount > maxAmmo then
        ammoCount = maxAmmo
    end
    if ammoCount < 0 then
        ammoCount = 0
    end
    safeSet(item, "setCurrentAmmoCount", ammoCount)
end

local function drainUsedDelta(item, amount)
    if not item then
        return
    end
    local current = safeNumber(safeCall(item, "getUsedDelta"), 0)
    safeSet(item, "setUsedDelta", math.max(0, current - safeNumber(amount, 0)))
end

local FWP_TRIGGER_GROUP_BY_WEAPON = {}

local function registerTriggerGroupWeapons(groupItemType, names)
    for name in tostring(names):gmatch("[^/]+") do
        FWP_TRIGGER_GROUP_BY_WEAPON[name] = groupItemType
        FWP_TRIGGER_GROUP_BY_WEAPON["Base." .. name] = groupItemType
    end
end

registerTriggerGroupWeapons("Base.TriggerGroup_AR", "AR57_PDW/AR57_PDW_Fold/AR57_PDW_Long/LVOA_C/AssaultRifle/ADAR/MK47/AAC_Honey/AAC_Honey_Fold/AAC_HoneySD/AAC_HoneySD_Fold/Bush_AR15_MOE/Bush_XM15/Bush_XM15_Custom/TR1_UltraLight/MCX_Spear/MCX_Virtus/MCX_VirtusPatrol/MCX_Socom/JW3_TTI_MPX/M723/XM117/H416/AR18/AR18_Fold/Carbon15_97/CAR15SMG/CAR15_Survival/M635/M635S/M635SD/M4/M4A1/M16A1/M16A2/M16A3/ColtM16/M16Wood/M16Tape/SCARL/SCARSC_Stock/SCARSC_Fold/SCARH/SCAR20/MK18")
registerTriggerGroupWeapons("Base.TriggerGroup_AK", "Origin/Saiga12/Saiga12_Long/Saiga12_Tromix/AK12_New/RPK16/AK308/AKM_Gold/AKM_Custom/AK74_Custom/AK47/AKM/AK103/M85_Stock/M85_Fold/MD65_Stock/MD65_Fold/AKMS_Stock/AKMS_Fold/AK74/AKS74/AKS74_Fold/AKS74U/AKS74U_Fold/AK12/AK12_Fold/AK74_Alpha/AK74_Alpha_Fold/RPK74/Galil/Galil_Fold/Galil_Sniper/Galil_Sniper_Fold/Vz58/Vz58_Stock/Vz58_Fold/Vz58_Mini_Stock/Vz58_Mini_Fold")
registerTriggerGroupWeapons("Base.TriggerGroup_HK", "MP7/MP7_Stock/G3/G28/G33/G36/G36_Fold/G36C/G36C_Fold/G36KV/G36KV_Fold/MP5_Fixed/MP5_Stock/MP5_Fold/MP5SD6_Fixed/MP5SD6_Stock/MP5SD6_Fold/UMP9_Stock/UMP9_Fold/UMP45_Stock/UMP45_Fold/XM8Compact_Pistol/XM8/XM8LMG")
registerTriggerGroupWeapons("Base.TriggerGroup_FN", "FAL/FAL_PARA_Stock/FAL_PARA_Fold/FN_FNC/FN_FNC_Fold/AK5C/AK5C_Fold")

local function normalizeTriggerTypeForB42(triggerType)
    triggerType = tonumber(triggerType) or 7
    if triggerType == 0 then
        return 0
    elseif triggerType == 2 then
        return 2
    elseif triggerType == 5 or triggerType == 6 or triggerType == 7 then
        return 5
    end
    return 1
end

local function buildFireModes(triggerType)
    triggerType = normalizeTriggerTypeForB42(triggerType)
    if triggerType == 0 then
        return { "N/A" }
    elseif triggerType == 1 then
        return { "Single" }
    elseif triggerType == 2 then
        return { "Auto" }
    end
    return { "Single", "Auto" }
end

local function setTriggerModes(weapon, triggerType)
    if not weapon then
        return
    end
    local normalizedTriggerType = normalizeTriggerTypeForB42(triggerType)
    local modes = buildFireModes(normalizedTriggerType)
    if ArrayList then
        local list = ArrayList.new()
        for _, mode in ipairs(modes) do
            list:add(mode)
        end
        safeSet(weapon, "setFireModePossibilities", list)
    end
    safeSet(weapon, "setFireMode", modes[1] or "Single")
    if weapon.getModData then
        weapon:getModData().TriggerType = normalizedTriggerType
    end
end

local function inferTriggerType(weapon)
    if not weapon then
        return 0
    end
    local modData = weapon.getModData and weapon:getModData() or nil
    if modData and tonumber(modData.TriggerType) then
        return tonumber(modData.TriggerType)
    end
    local fireMode = tostring(safeCall(weapon, "getFireMode") or "")
    if fireMode == "N/A" then
        return 0
    end
    local hasSingle = fireMode:find("Single", 1, true) ~= nil
    local hasAuto = fireMode:find("Auto", 1, true) ~= nil
    local hasBurst2 = fireMode:find("[2]", 1, true) ~= nil or fireMode:find("H2", 1, true) ~= nil
    local hasBurst3 = fireMode:find("[3]", 1, true) ~= nil or fireMode:find("H3", 1, true) ~= nil
    local modes = safeCall(weapon, "getFireModePossibilities")
    for i = 0, javaListSize(modes) - 1 do
        local mode = tostring(javaListGet(modes, i) or "")
        if mode:find("Single", 1, true) then hasSingle = true end
        if mode:find("Auto", 1, true) then hasAuto = true end
        if mode:find("[2]", 1, true) or mode:find("H2", 1, true) then hasBurst2 = true end
        if mode:find("[3]", 1, true) or mode:find("H3", 1, true) then hasBurst3 = true end
    end
    if hasSingle and hasBurst3 and hasAuto then return 7 end
    if hasSingle and hasBurst2 and hasAuto then return 6 end
    if hasSingle and hasAuto then return 5 end
    if hasSingle and hasBurst3 then return 4 end
    if hasSingle and hasBurst2 then return 3 end
    if hasAuto then return 2 end
    if hasSingle then return 1 end
    return 7
end

local function triggerTypeFromPart(part)
    if not part then
        return 7
    end
    local modData = part.getModData and part:getModData() or nil
    if modData and tonumber(modData.TriggerType) then
        return tonumber(modData.TriggerType)
    end
    return 7
end

function RecipeCodeOnCreate.FWPRecoverArcheryComponents(craftRecipeData, character)
    if not craftRecipeData or not character then
        return
    end

    local inventory = character:getInventory()
    local consumed = craftRecipeData:getAllConsumedItems()
    if not inventory or not consumed then
        return
    end

    local brokenTag = "Broken_Arrow"
    if FWPGetItemTag then
        local ok, tag = pcall(FWPGetItemTag, "Broken_Arrow")
        if ok and tag then
            brokenTag = tag
        end
    end

    for i = 0, consumed:size() - 1 do
        local item = consumed:get(i)
        if item then
            local itemType = item:getType() or ""
            local isBolt = string.find(itemType, "Bolt", 1, true) ~= nil
            local isBroken = false
            if item.hasTag then
                local ok, result = pcall(function() return item:hasTag(brokenTag) end)
                isBroken = ok and result == true
            end

            if isBroken then
                if ZombRand(2) == 0 then
                    addItem(inventory, isBolt and "Base.Shaft_Carbon" or "Base.Shaft_Fiberglass", 1)
                end
                if ZombRand(2) == 0 then
                    addItem(inventory, "Base.Arrow_Head", 1)
                end
                if ZombRand(2) == 0 then
                    addItem(inventory, "Base.Arrow_Fletching", ZombRand(1, 2))
                end
            else
                addItem(inventory, isBolt and "Base.Shaft_Carbon" or "Base.Shaft_Fiberglass", 1)
                addItem(inventory, "Base.Arrow_Head", 1)
                addItem(inventory, "Base.Arrow_Fletching", 2)
            end
        end
    end
end

function RecipeCodeOnCreate.FWPMakeCO2Cartridges(craftRecipeData, character)
    local propaneTank = findInputByTypes(craftRecipeData, { "Base.PropaneTank" })
    drainUsedDelta(propaneTank, 0.03)
end

function RecipeCodeOnCreate.FWPChargeWeaponLight(craftRecipeData, character)
    if not craftRecipeData or not character then
        return
    end
    local inventory = character:getInventory()
    local sourcePart = findItem(craftRecipeData:getAllConsumedItems(), function(item)
        local itemType = getItemType(item)
        return itemType ~= "Battery" and not isHandWeaponItem(item)
    end)
    local battery = findConsumedByTypes(craftRecipeData, { "Base.Battery" })
    local outputPart = findItem(craftRecipeData:getAllCreatedItems(), function(item)
        return not isHandWeaponItem(item) and getItemType(item) ~= "Battery"
    end)
    if not sourcePart or not battery or not outputPart then
        return
    end

    copyModData(sourcePart, outputPart)
    local currentCharge = 0
    if sourcePart.getModData and sourcePart:getModData().Charge then
        currentCharge = safeNumber(sourcePart:getModData().Charge, 0)
    end
    local batteryCharge = safeNumber(safeCall(battery, "getUsedDelta"), 0) * 100
    local needed = math.max(100 - currentCharge, 0)
    local used = math.min(needed, batteryCharge)
    local chargeLeft = math.max(batteryCharge - used, 0)
    outputPart:getModData().Charge = math.min(currentCharge + used, 100)

    if chargeLeft > 0.5 and inventory then
        local leftover = addItemObject(inventory, "Base.Battery")
        if leftover then
            safeSet(leftover, "setUsedDelta", chargeLeft / 100)
        end
    end
end

function RecipeCodeOnCreate.FWPRemoveTriggerGroup(craftRecipeData, character)
    if not craftRecipeData or not character then
        return
    end
    local source = findConsumedWeapon(craftRecipeData)
    local output = findCreatedWeapon(craftRecipeData)
    if not source or not output then
        return
    end

    copyWeaponState(source, output, character)
    local groupItemType = FWP_TRIGGER_GROUP_BY_WEAPON[getItemFullType(source)] or FWP_TRIGGER_GROUP_BY_WEAPON[getItemType(source)]
    local triggerType = inferTriggerType(source)
    if groupItemType and triggerType > 0 then
        local triggerGroup = addItemObject(character:getInventory(), groupItemType)
        if triggerGroup and triggerGroup.getModData then
            triggerGroup:getModData().TriggerType = triggerType
        end
    end
    setTriggerModes(output, 0)
    safeSet(output, "setJammed", true)
    equipIfWeapon(character, output)
end

function RecipeCodeOnCreate.FWPInstallTriggerGroup(craftRecipeData, character)
    if not craftRecipeData or not character then
        return
    end
    local source = findConsumedWeapon(craftRecipeData)
    local output = findCreatedWeapon(craftRecipeData)
    local triggerGroup = findItem(craftRecipeData:getAllConsumedItems(), function(item)
        local itemType = getItemType(item) or ""
        return itemType:find("TriggerGroup", 1, true) ~= nil
    end)
    if not source or not output or not triggerGroup then
        return
    end

    copyWeaponState(source, output, character)
    setTriggerModes(output, triggerTypeFromPart(triggerGroup))
    safeSet(output, "setJammed", false)
    equipIfWeapon(character, output)
end

function RecipeCodeOnCreate.FWPInstallPaintballCanister(craftRecipeData, character)
    if not craftRecipeData or not character then
        return
    end
    local source = findConsumedWeapon(craftRecipeData)
    local output = findCreatedWeapon(craftRecipeData)
    local tank = findConsumedByTypes(craftRecipeData, { "Base.M2A1_Can", "Base.CO2_Cartridge" })
    if not source or not output or not tank then
        return
    end

    copyWeaponState(source, output, character)
    local tankType = getItemType(tank) or ""
    local air = safeCall(tank, "getCurrentAmmoCount")
    if air == nil or safeNumber(air, 0) <= 0 then
        air = 100
    end
    output:getModData().Air = safeNumber(air, 100)

    local partType = tankType == "M2A1_Can" and "Base.Standard_PB_Can" or "Base.CO2_Cartridge_Used"
    local part = createItemObject(partType)
    if part then
        safeSet(output, "attachWeaponPart", part)
    end
    equipIfWeapon(character, output)
end

function RecipeCodeOnCreate.FWPRemovePaintballCanister(craftRecipeData, character)
    if not craftRecipeData or not character then
        return
    end
    local source = findConsumedWeapon(craftRecipeData)
    local output = findCreatedWeapon(craftRecipeData)
    if not source or not output then
        return
    end

    copyWeaponState(source, output, character, { skipParts = { RecoilPad = true } })
    local sourceType = getItemType(source) or ""
    local air = source.getModData and safeNumber(source:getModData().Air, safeNumber(safeCall(source, "getCurrentAmmoCount"), 0)) or 0
    local returnType = (sourceType == "VM_68" or sourceType == "Auto_Cocker" or sourceType == "Tippmann_SL68") and "Base.M2A1_Can" or "Base.CO2_Cartridge_Used"
    local returned = addItemObject(character:getInventory(), returnType)
    if returned and returnType == "Base.M2A1_Can" then
        setAmmoCount(returned, air)
    end
    if output.getModData then
        output:getModData().Air = nil
    end
    equipIfWeapon(character, output)
end

local function oldBarrelTypeForWeapon(weapon)
    local itemType = getItemType(weapon) or ""
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

function RecipeCodeOnCreate.FWPSwapBarrel(craftRecipeData, character)
    if not craftRecipeData or not character then
        return
    end
    local source = findConsumedWeapon(craftRecipeData)
    local output = findCreatedWeapon(craftRecipeData)
    if not source or not output then
        return
    end
    copyWeaponState(source, output, character)
    local oldBarrelType = oldBarrelTypeForWeapon(source)
    if oldBarrelType then
        addItemObject(character:getInventory(), oldBarrelType)
    end
    equipIfWeapon(character, output)
end

function RecipeCodeOnCreate.FWPUniversalSawoff(craftRecipeData, character)
    if not craftRecipeData or not character then
        return
    end
    local source = findConsumedWeapon(craftRecipeData)
    local output = findCreatedWeapon(craftRecipeData)
    if not source or not output then
        return
    end
    local targetType = getItemType(output) or ""
    local skipParts = {}
    if targetType:find("Pistol", 1, true) then
        skipParts.Sling = true
        skipParts.RecoilPad = true
    end
    copyWeaponState(source, output, character, { skipParts = skipParts })
    equipIfWeapon(character, output)
end

function RecipeCodeOnCreate.FWPFixedMagType(craftRecipeData, character)
    if not craftRecipeData or not character then
        return
    end
    local source = findConsumedWeapon(craftRecipeData)
    local output = findCreatedWeapon(craftRecipeData)
    local newMag = findConsumedMagazine(craftRecipeData)
    if not source or not output or not newMag then
        return
    end

    copyWeaponState(source, output, character, { skipParts = { Clip = true } })
    local oldAmmo = safeNumber(safeCall(source, "getCurrentAmmoCount"), 0)
    local oldMagType = nil
    local sourceData = source.getModData and source:getModData() or nil
    if sourceData and sourceData.FixedMagType and safeCall(source, "isContainsClip") == true then
        oldMagType = sourceData.FixedMagType
    elseif safeCall(source, "isContainsClip") == true then
        oldMagType = safeCall(source, "getMagazineType")
        if sourceData and sourceData.ClipType and sourceData.MagType and oldMagType == sourceData.ClipType then
            oldMagType = sourceData.MagType
        end
    end
    if oldMagType then
        local oldMag = addItemObject(character:getInventory(), oldMagType)
        if oldMag then
            setAmmoCount(oldMag, oldAmmo)
        end
    end

    safeSet(output, "setContainsClip", true)
    setAmmoCount(output, safeNumber(safeCall(newMag, "getCurrentAmmoCount"), 0))
    local chambered = safeCall(source, "isRoundChambered")
    if chambered ~= nil then
        safeSet(output, "setRoundChambered", chambered == true)
    end
    equipIfWeapon(character, output)
end

function RecipeCodeOnCreate.FWPEquipFireExtinguisher(craftRecipeData, character)
    local source = findConsumedByTypes(craftRecipeData, { "Base.Extinguisher" })
    local output = findCreatedByTypes(craftRecipeData, { "Base.FireExtinguisher" })
    if not source or not output then
        return
    end
    local fill = math.min(safeNumber(safeCall(source, "getUsedDelta"), 0) * 110, 100)
    setAmmoCount(output, fill)
    equipIfWeapon(character, output)
end

function RecipeCodeOnCreate.FWPUnEquipFireExtinguisher(craftRecipeData, character)
    local source = findConsumedByTypes(craftRecipeData, { "Base.FireExtinguisher" })
    local output = findCreatedByTypes(craftRecipeData, { "Base.Extinguisher" })
    if not source or not output then
        return
    end
    local ammo = safeNumber(safeCall(source, "getCurrentAmmoCount"), 0)
    local fill
    if ammo >= 90 then
        fill = ammo / 110
    elseif ammo >= 50 then
        fill = ammo / 69
    else
        fill = ammo / 50
    end
    safeSet(output, "setUsedDelta", math.max(0, math.min(fill, 1)))
end

function RecipeCodeOnCreate.FWPImprovisedFlameThrower(craftRecipeData, character)
    local wd = findConsumedByTypes(craftRecipeData, { "Base.WD" })
    local lighter = findConsumedByTypes(craftRecipeData, { "Base.Lighter" })
    local output = findCreatedByTypes(craftRecipeData, { "Base.WD_Flame" })
    if not wd or not output then
        return
    end
    setAmmoCount(output, safeNumber(safeCall(wd, "getUsedDelta"), 0) * 30)
    if lighter and output.getModData then
        output:getModData().Trajectory = safeNumber(safeCall(lighter, "getUsedDelta"), 0)
    end
    equipIfWeapon(character, output)
end

function RecipeCodeOnCreate.FWPScrapImprovisedFlameThrower(craftRecipeData, character)
    if not craftRecipeData or not character then
        return
    end
    local source = findConsumedWeapon(craftRecipeData)
    local output = findCreatedByTypes(craftRecipeData, { "Base.WD" })
    if not source or not output then
        return
    end
    safeSet(output, "setUsedDelta", math.max(0, math.min(safeNumber(safeCall(source, "getCurrentAmmoCount"), 0) / 10, 1)))
    local lighter = addItemObject(character:getInventory(), "Base.Lighter")
    if lighter and source.getModData and source:getModData().Trajectory then
        safeSet(lighter, "setUsedDelta", math.max(0, math.min(safeNumber(source:getModData().Trajectory, 0), 1)))
    end
    addItemObject(character:getInventory(), "Base.RubberBand")
end

local function refillAmmoContainer(craftRecipeData, character, rate)
    if not craftRecipeData or not character then
        return
    end
    local source = findConsumedWeapon(craftRecipeData) or findConsumedMagazine(craftRecipeData)
    local output = findCreatedAmmoContainer(craftRecipeData)
    if not source or not output then
        return
    end
    if isHandWeaponItem(source) and isHandWeaponItem(output) then
        copyWeaponState(source, output, character)
    end
    local currentAmmo = safeNumber(safeCall(source, "getCurrentAmmoCount"), 0)
    setAmmoCount(output, currentAmmo + safeNumber(rate, 0))
    equipIfWeapon(character, output)
end

function RecipeCodeOnCreate.FWPRefillM2A1Canister(craftRecipeData, character)
    refillAmmoContainer(craftRecipeData, character, 25)
    drainUsedDelta(findInputByTypes(craftRecipeData, { "Base.PropaneTank" }), 0.03)
end

function RecipeCodeOnCreate.FWPRefillM2A1Tank(craftRecipeData, character)
    refillAmmoContainer(craftRecipeData, character, 30)
end

function RecipeCodeOnCreate.FWPRefillSS2000(craftRecipeData, character)
    refillAmmoContainer(craftRecipeData, character, 1)
end

function RecipeCodeOnCreate.FWPRefillPetrolTool(craftRecipeData, character)
    refillAmmoContainer(craftRecipeData, character, 30)
end
