-- Faded's Weapon Pack B42 compatibility helpers.

FWPTagCache = FWPTagCache or {}
FWPNVAPI = FWPNVAPI or { checked = false, ctrl = nil }
if FWP_DISABLE_GUNFIGHTER_HUD == nil then
    FWP_DISABLE_GUNFIGHTER_HUD = true
end
if FWP_USE_INCENDIARY_AMMO_RUNTIME == nil then
    FWP_USE_INCENDIARY_AMMO_RUNTIME = true
end

FWPAmmoTypeItemKeyMap = FWPAmmoTypeItemKeyMap or {
    ["base:bullets_22"] = "Base.Bullets22",
    ["base:bullets_223"] = "Base.223Bullets",
    ["base:bullets_308"] = "Base.308Bullets",
    ["base:bullets_357"] = "Base.Bullets357",
    ["base:bullets_38"] = "Base.Bullets38",
    ["base:bullets_44"] = "Base.Bullets44",
    ["base:bullets_45"] = "Base.Bullets45",
    ["base:bullets_556"] = "Base.556Bullets",
    ["base:bullets_9mm"] = "Base.Bullets9mm",
    ["base:shotgun_shells"] = "Base.ShotgunShells",
    ["fwp:223_bullets"] = "Base.223Bullets",
    ["fwp:bb177"] = "Base.BB177",
    ["fwp:pb68"] = "Base.PB68",
    ["fwp:bullets45_lc"] = "Base.Bullets45LC",
    ["fwp:410g_shotgun_shells"] = "Base.410gShotgunShells",
    ["fwp:bullets50_mag"] = "Base.Bullets50MAG",
    ["fwp:545x39_bullets"] = "Base.545x39Bullets",
    ["fwp:40_heround"] = "Base.40HERound",
    ["fwp:40_incround"] = "Base.40INCRound",
    ["fwp:arrow_fiberglass"] = "Base.Arrow_Fiberglass",
    ["fwp:bolt_bear"] = "Base.Bolt_Bear",
    ["fwp:sling_shot_ammo_rock"] = "Base.SlingShotAmmo_Rock",
    ["fwp:sling_shot_ammo_marble"] = "Base.SlingShotAmmo_Marble",
    ["fwp:bullets22"] = "Base.Bullets22",
    ["fwp:762x39_bullets"] = "Base.762x39Bullets",
    ["fwp:50_bmgbullets"] = "Base.50BMGBullets",
    ["fwp:flare"] = "Base.Flare",
    ["fwp:flame_fuel"] = "Base.FlameFuel",
    ["fwp:water_ammo"] = "Base.WaterAmmo",
    ["fwp:smoke"] = "Base.Smoke",
    ["fwp:20g_shotgun_shells"] = "Base.20gShotgunShells",
    ["fwp:10g_shotgun_shells"] = "Base.10gShotgunShells",
    ["fwp:3006_bullets"] = "Base.3006Bullets",
    ["fwp:bullets57"] = "Base.Bullets57",
    ["fwp:bullets380"] = "Base.Bullets380",
    ["fwp:herocket"] = "Base.HERocket",
    ["fwp:762x54r_bullets"] = "Base.762x54rBullets",
    ["fwp:4g_shotgun_shells"] = "Base.4gShotgunShells",
    ["fwp:bullets4570"] = "Base.Bullets4570",
    ["fwp:12g_incendiary_shells"] = "Base.FWP_12gIncendiaryShells"
}

FWPIncendiaryAmmoTypes = FWPIncendiaryAmmoTypes or {
    ["Base.FlameFuel"] = true,
    ["base.flamefuel"] = true,
    ["Base.FWP_12gIncendiaryShells"] = true,
    ["base.fwp_12gincendiaryshells"] = true,
    ["Base.40INCRound"] = true,
    ["base.40incround"] = true
}

local function FWPCompatGetInventory(playerOrContainer)
    if playerOrContainer == nil then
        return nil
    end
    if playerOrContainer.getInventory then
        local ok, inventory = pcall(function()
            return playerOrContainer:getInventory()
        end)
        if ok and inventory then
            return inventory
        end
    end
    return playerOrContainer
end

function FWPIsIncendiaryAmmoType(ammoType)
    local fullType = FWPGetItemFullType and FWPGetItemFullType(ammoType) or ammoType
    if fullType == nil then
        return false
    end
    local text = tostring(fullType)
    return FWPIncendiaryAmmoTypes[text] == true or FWPIncendiaryAmmoTypes[string.lower(text)] == true
end

function FWPGetReloadableAmmoItemKeys(itemOrAmmoType)
    local ammoKey = FWPGetAmmoItemKey(itemOrAmmoType)
    if ammoKey == "Base.ShotgunShells" or ammoKey == "base:shotgun_shells" then
        return { "Base.FWP_12gIncendiaryShells", "Base.ShotgunShells" }
    end
    if ammoKey == nil then
        return {}
    end
    return { ammoKey }
end

function FWPGetAvailableReloadAmmoItemKey(playerOrContainer, itemOrAmmoType)
    local inventory = FWPCompatGetInventory(playerOrContainer)
    local ammoKeys = FWPGetReloadableAmmoItemKeys(itemOrAmmoType)
    for _, ammoKey in ipairs(ammoKeys) do
        if inventory and inventory.getItemCountRecurse then
            local ok, count = pcall(function()
                return inventory:getItemCountRecurse(ammoKey)
            end)
            if ok and tonumber(count) and tonumber(count) > 0 then
                return ammoKey
            end
        elseif inventory and inventory.containsWithModule then
            local ok, hasAmmo = pcall(function()
                return inventory:containsWithModule(ammoKey)
            end)
            if ok and hasAmmo then
                return ammoKey
            end
        end
    end
    return ammoKeys[1]
end

function FWPGetReloadableAmmoCount(playerOrContainer, itemOrAmmoType, maxCount)
    local inventory = FWPCompatGetInventory(playerOrContainer)
    local remaining = tonumber(maxCount) or 0
    local total = 0
    if not inventory or remaining <= 0 then
        return 0
    end

    for _, ammoKey in ipairs(FWPGetReloadableAmmoItemKeys(itemOrAmmoType)) do
        if remaining <= 0 then break end
        if inventory.getItemCountRecurse then
            local ok, count = pcall(function()
                return inventory:getItemCountRecurse(ammoKey)
            end)
            count = ok and tonumber(count) or 0
            local take = math.min(count, remaining)
            total = total + take
            remaining = remaining - take
        end
    end
    return total
end

function FWPGetReloadableAmmoItems(playerOrContainer, itemOrAmmoType, maxCount)
    local inventory = FWPCompatGetInventory(playerOrContainer)
    local remaining = tonumber(maxCount) or 0
    local out = ArrayList and ArrayList.new() or nil
    if not inventory or remaining <= 0 or not out then
        return out
    end

    for _, ammoKey in ipairs(FWPGetReloadableAmmoItemKeys(itemOrAmmoType)) do
        if remaining <= 0 then break end
        local some = nil
        if inventory.getSomeType then
            local ok, items = pcall(function()
                return inventory:getSomeType(ammoKey, remaining)
            end)
            if ok then
                some = items
            end
        end
        if some then
            for i = 0, some:size() - 1 do
                out:add(some:get(i))
            end
            remaining = remaining - some:size()
        end
    end
    return out
end

function FWPSetSelectedReloadAmmoType(item, ammoType)
    if not (item and item.getModData) then
        return
    end
    local md = item:getModData()
    md.FWP_SelectedReloadAmmoType = ammoType
    if item.transmitModData then
        item:transmitModData()
    end
end

function FWPGetSelectedReloadAmmoType(playerOrContainer, itemOrAmmoType)
    local md = itemOrAmmoType and itemOrAmmoType.getModData and itemOrAmmoType:getModData() or nil
    local selected = md and md.FWP_SelectedReloadAmmoType or nil
    local inventory = FWPCompatGetInventory(playerOrContainer)
    if selected and inventory and inventory.getItemCountRecurse then
        local ok, count = pcall(function()
            return inventory:getItemCountRecurse(selected)
        end)
        if ok and tonumber(count) and tonumber(count) > 0 then
            return selected
        end
    end
    return FWPGetAvailableReloadAmmoItemKey(playerOrContainer, itemOrAmmoType)
end

function FWPGetLoadedIncendiaryCount(item)
    local md = item and item.getModData and item:getModData() or nil
    return tonumber(md and md.FWP_IncendiaryLoadedCount) or 0
end

function FWPSetLoadedIncendiaryCount(item, count)
    if not (item and item.getModData) then
        return
    end
    local md = item:getModData()
    md.FWP_IncendiaryLoadedCount = math.max(0, tonumber(count) or 0)
    if md.FWP_IncendiaryLoadedCount <= 0 then
        md.FWP_IncendiaryLoadedCount = nil
    end
    if item.transmitModData then
        item:transmitModData()
    end
end

function FWPRecordLoadedAmmo(item, ammoItemOrType, count)
    local ammoType = FWPGetItemFullType and FWPGetItemFullType(ammoItemOrType) or ammoItemOrType
    if ammoType ~= "Base.FWP_12gIncendiaryShells" then
        return false
    end
    FWPSetLoadedIncendiaryCount(item, FWPGetLoadedIncendiaryCount(item) + (tonumber(count) or 1))
    return true
end

function FWPCopyLoadedAmmoState(source, target)
    if not (source and target) then
        return
    end
    FWPSetLoadedIncendiaryCount(target, FWPGetLoadedIncendiaryCount(source))
end

function FWPPeekAmmoEffectType(item)
    local ammoKey = FWPGetAmmoItemKey(item)
    if FWPIsIncendiaryAmmoType(ammoKey) then
        return ammoKey
    end
    if ammoKey == "Base.ShotgunShells" and FWPGetLoadedIncendiaryCount(item) > 0 then
        return "Base.FWP_12gIncendiaryShells"
    end
    return ammoKey
end

function FWPConsumeLoadedAmmoForShot(item, fallbackAmmoType)
    local effectAmmoType = fallbackAmmoType or FWPPeekAmmoEffectType(item)
    if effectAmmoType == "Base.FWP_12gIncendiaryShells" and FWPGetLoadedIncendiaryCount(item) > 0 then
        FWPSetLoadedIncendiaryCount(item, FWPGetLoadedIncendiaryCount(item) - 1)
    end
    return effectAmmoType
end

function FWPConsumeLoadedAmmoForUnload(item, fallbackAmmoType)
    local fallback = fallbackAmmoType or FWPGetAmmoItemKey(item)
    if fallback == "Base.ShotgunShells" and FWPGetLoadedIncendiaryCount(item) > 0 then
        FWPSetLoadedIncendiaryCount(item, FWPGetLoadedIncendiaryCount(item) - 1)
        return "Base.FWP_12gIncendiaryShells"
    end
    return fallback
end

function FWPGetItemTag(tag)
    if type(tag) ~= "string" then
        return tag
    end

    if FWPTagCache[tag] ~= nil then
        return FWPTagCache[tag]
    end

    local itemTag = nil
    if ItemTag and ResourceLocation and ItemTag.get then
        local function getTagByName(name)
            local locOk, location = pcall(function()
                return ResourceLocation.of(name)
            end)
            if locOk and location ~= nil then
                local tagOk, resolved = pcall(function()
                    return ItemTag.get(location)
                end)
                if tagOk and resolved ~= nil then
                    return resolved
                end
            end
            return nil
        end

        itemTag = getTagByName(tag)
        if itemTag == nil and not string.find(tag, ":") then
            itemTag = getTagByName("fwp:" .. string.lower(tag))
        end
        if itemTag == nil and not string.find(tag, ":") then
            itemTag = getTagByName("base:" .. string.lower(tag))
        end
        if itemTag == nil and ItemTag.register and not string.find(tag, ":") then
            local regOk, registered = pcall(function()
                return ItemTag.register("fwp:" .. string.lower(tag))
            end)
            if regOk then
                itemTag = registered
            end
        end
    end

    FWPTagCache[tag] = itemTag or tag
    return FWPTagCache[tag]
end

function FWPGetWeaponPart(weapon, partType)
    if weapon == nil or partType == nil then
        return nil
    end

    local ok, part = pcall(function()
        return weapon:getWeaponPart(partType)
    end)
    if ok then
        return part
    end

    return nil
end

function FWPGetWeaponPartType(part)
    if part == nil then
        return nil
    end

    if part.getPartType then
        local ok, partType = pcall(function()
            return part:getPartType()
        end)
        partType = ok and FWPCleanScriptPropertyValue(partType) or nil
        if partType ~= nil then
            return FWPInspectNormalizePartType and FWPInspectNormalizePartType(partType) or partType
        end
    end

    return FWPGetScriptItemProperty(part, "PartType")
end

function FWPSafeAttachWeaponPart(weapon, part, partType)
    if weapon == nil or part == nil then
        return false
    end

    partType = partType or FWPGetWeaponPartType(part)
    if weapon.attachWeaponPart then
        pcall(function()
            weapon:attachWeaponPart(part)
        end)
    end

    if partType ~= nil then
        local attached = FWPGetWeaponPart(weapon, partType)
        if attached ~= nil then
            return true
        end
    end

    if partType ~= nil and weapon.setWeaponPart then
        pcall(function()
            weapon:setWeaponPart(partType, part)
        end)
        return FWPGetWeaponPart(weapon, partType) ~= nil
    end

    return false
end

function FWPSafeDetachWeaponPart(weapon, partTypeOrPart, maybePart)
    if weapon == nil then
        return false
    end

    local partType = nil
    local part = nil
    if maybePart ~= nil then
        partType = partTypeOrPart
        part = maybePart
    else
        part = partTypeOrPart
        partType = FWPGetWeaponPartType(part)
    end

    if part ~= nil and weapon.detachWeaponPart then
        pcall(function()
            weapon:detachWeaponPart(part)
        end)
    end

    if partType ~= nil and FWPGetWeaponPart(weapon, partType) ~= nil and weapon.setWeaponPart then
        pcall(function()
            weapon:setWeaponPart(partType, nil)
        end)
    end

    if partType ~= nil then
        return FWPGetWeaponPart(weapon, partType) == nil
    end

    return true
end

function FWPInspectNormalizePartType(partType)
    if partType == nil then
        return nil
    end
    if partType == "Recoil Pad" then
        return "RecoilPad"
    end
    if partType == "Barrel" or partType == "Muzzle" then
        return "Canon"
    end
    return partType
end

function FWPInspectPartTypeMatches(part, category)
    if part == nil or category == nil or not part.getPartType then
        return false
    end

    local partType = FWPInspectNormalizePartType(part:getPartType())
    local wanted = FWPInspectNormalizePartType(category)
    return partType == wanted
end

function FWPInspectEscapeLuaPattern(value)
    return tostring(value):gsub("([^%w])", "%%%1")
end

function FWPInspectGetPartKey(part)
    if part == nil then
        return "nil"
    end
    if part.getFullType then
        local ok, value = pcall(function()
            return part:getFullType()
        end)
        if ok and value ~= nil then
            return tostring(value)
        end
    end
    if part.getName then
        local ok, value = pcall(function()
            return part:getName()
        end)
        if ok and value ~= nil then
            return tostring(value)
        end
    end
    return tostring(part)
end

function FWPInspectIsWeaponPartLike(item)
    if item == nil then
        return false
    end

    if type(instanceof) == "function" then
        local ok, result = pcall(function()
            return instanceof(item, "WeaponPart")
        end)
        if ok and result then
            return true
        end
    end

    local typeString = item.getTypeString and item:getTypeString() or nil
    local typeName = item.getType and item:getType() or nil
    local itemType = item.getItemType and item:getItemType() or nil
    local category = item.getCategory and item:getCategory() or nil

    if tostring(typeString) == "WeaponPart" or tostring(typeName) == "WeaponPart" or tostring(category) == "WeaponPart" then
        return true
    end

    if itemType ~= nil and string.find(string.lower(tostring(itemType)), "weaponpart", 1, true) ~= nil then
        return true
    end

    return item.getPartType ~= nil and item.getMountOn ~= nil
end

function FWPInspectCollectWeaponPartsRecursive(container, out, sourceContainers)
    if container == nil or out == nil or not container.getItems then
        return
    end

    local items = container:getItems()
    if items == nil then
        return
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item ~= nil then
            if FWPInspectIsWeaponPartLike(item) then
                table.insert(out, item)
                if sourceContainers ~= nil and item.getID then
                    sourceContainers[item:getID()] = container
                end
            elseif type(instanceof) == "function" and instanceof(item, "InventoryContainer") and item.getInventory then
                FWPInspectCollectWeaponPartsRecursive(item:getInventory(), out, sourceContainers)
            end
        end
    end
end

function FWPInspectAddMagazineType(out, seen, itemType)
    if out == nil or seen == nil or itemType == nil then
        return
    end

    local fullType = tostring(itemType)
    if fullType == "" or fullType == "nil" or seen[fullType] then
        return
    end

    seen[fullType] = true
    table.insert(out, fullType)
end

function FWPGetItemFullType(item)
    if item == nil then
        return nil
    end
    if type(item) == "string" then
        if item == "" or item == "nil" then
            return nil
        end
        return item
    end
    if item.getFullType then
        local ok, value = pcall(function()
            return item:getFullType()
        end)
        if ok and value ~= nil and tostring(value) ~= "" then
            return tostring(value)
        end
    end
    return nil
end

FWPFlameFuelCanisterTypes = FWPFlameFuelCanisterTypes or {
    ["Base.M2A1_Can"] = true,
    ["Base.M2A1_Tank"] = true
}

function FWPIsFlameFuelCanister(itemOrType)
    local fullType = FWPGetItemFullType(itemOrType)
    return fullType ~= nil and FWPFlameFuelCanisterTypes[tostring(fullType)] == true
end

function FWPMarkFlameFuelCanisterKnown(item, skipTransmit)
    if not (item and FWPIsFlameFuelCanister(item) and item.getModData) then
        return false
    end
    local md = item:getModData()
    md.FWP_FuelInitialized = true
    md.FWP_FlameFuelCanister = true
    if not skipTransmit and item.transmitModData then
        pcall(item.transmitModData, item)
    end
    return true
end

function FWPEnsureFlameFuelCanisterInitialized(item)
    if not (item and FWPIsFlameFuelCanister(item) and item.getModData) then
        return false
    end
    local md = item:getModData()
    if md.FWP_FuelInitialized == true then
        return false
    end

    if item.getCurrentAmmoCount and item.setCurrentAmmoCount and item.getMaxAmmo then
        local okCount, currentAmmo = pcall(function()
            return item:getCurrentAmmoCount()
        end)
        local okMax, maxAmmo = pcall(function()
            return item:getMaxAmmo()
        end)
        currentAmmo = okCount and tonumber(currentAmmo) or 0
        maxAmmo = okMax and tonumber(maxAmmo) or 0
        if currentAmmo <= 0 and maxAmmo > 0 then
            pcall(function()
                item:setCurrentAmmoCount(maxAmmo)
            end)
        end
    end

    FWPMarkFlameFuelCanisterKnown(item, false)
    return true
end

function FWPGetWeaponMagazineTypes(weapon, includeClip)
    local types = {}
    local seen = {}

    if weapon == nil then
        return types
    end

    if weapon.getMagazineType then
        local ok, magazineType = pcall(function()
            return weapon:getMagazineType()
        end)
        if ok then
            FWPInspectAddMagazineType(types, seen, magazineType)
        end
    end

    local md = weapon.getModData and weapon:getModData() or nil
    if md ~= nil then
        FWPInspectAddMagazineType(types, seen, md.MagType)
        FWPInspectAddMagazineType(types, seen, md.ExtMagType)
        FWPInspectAddMagazineType(types, seen, md.DrumMagType)
        if includeClip then
            FWPInspectAddMagazineType(types, seen, md.ClipType)
        end
    end

    local function addScriptMagazineProperty(propertyName)
        local value = nil
        if type(FWPGetScriptItemProperty) == "function" then
            value = FWPGetScriptItemProperty(weapon, propertyName)
        end
        if value == nil and weapon.getScriptItem then
            local okScript, scriptItem = pcall(function()
                return weapon:getScriptItem()
            end)
            if okScript and scriptItem and scriptItem.getProperty then
                local okProperty, propertyValue = pcall(function()
                    return scriptItem:getProperty(propertyName)
                end)
                if okProperty then
                    value = propertyValue
                end
            end
        end
        FWPInspectAddMagazineType(types, seen, value)
    end

    for _, propertyName in ipairs({ "MagazineType", "MagType", "ExtMagType", "DrumMagType" }) do
        addScriptMagazineProperty(propertyName)
    end
    if includeClip then
        addScriptMagazineProperty("ClipType")
    end

    return types
end

function FWPInspectGetMagazineTypes(weapon)
    return FWPGetWeaponMagazineTypes(weapon, false)
end

function FWPInspectCollectMagazinesRecursive(container, magazineTypes, out, sourceContainers, rootContainer)
    if container == nil or magazineTypes == nil or out == nil or not container.getItems then
        return
    end

    local wanted = {}
    for _, magazineType in ipairs(magazineTypes) do
        wanted[tostring(magazineType)] = true
    end

    local items = container:getItems()
    if items == nil then
        return
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item ~= nil then
            local fullType = item.getFullType and item:getFullType() or nil
            if fullType ~= nil and wanted[tostring(fullType)] then
                table.insert(out, item)
                if sourceContainers ~= nil and rootContainer ~= nil and container ~= rootContainer and item.getID then
                    sourceContainers[item:getID()] = container
                end
            end

            if type(instanceof) == "function" and instanceof(item, "InventoryContainer") and item.getInventory then
                FWPInspectCollectMagazinesRecursive(item:getInventory(), magazineTypes, out, sourceContainers, rootContainer)
            end
        end
    end
end

function FWPIsMagazineCompatibleWithWeapon(weapon, magazine, includeClip)
    if weapon == nil or magazine == nil then
        return false
    end

    local fullType = FWPGetItemFullType(magazine)
    if fullType == nil then
        return false
    end

    local magazineTypes = FWPGetWeaponMagazineTypes(weapon, includeClip)
    for _, magazineType in ipairs(magazineTypes) do
        if tostring(magazineType) == fullType then
            return true
        end
    end

    return false
end

function FWPFindMagazineByType(playerObj, magazineType, allowEmpty)
    if playerObj == nil or magazineType == nil or not playerObj.getInventory then
        return nil
    end

    local inventory = playerObj:getInventory()
    if inventory == nil or not inventory.getAllTypeRecurse then
        return nil
    end

    local ok, magazines = pcall(function()
        return inventory:getAllTypeRecurse(tostring(magazineType))
    end)
    if not ok or magazines == nil then
        return nil
    end

    local best = nil
    local bestAmmo = -1
    for i = 0, magazines:size() - 1 do
        local magazine = magazines:get(i)
        if FWPEnsureFlameFuelCanisterInitialized then
            FWPEnsureFlameFuelCanisterInitialized(magazine)
        end
        local ammoCount = 0
        if magazine ~= nil and magazine.getCurrentAmmoCount then
            local countOk, count = pcall(function()
                return magazine:getCurrentAmmoCount()
            end)
            if countOk and tonumber(count) ~= nil then
                ammoCount = tonumber(count)
            end
        end
        if magazine ~= nil and (allowEmpty or ammoCount > 0) and ammoCount > bestAmmo then
            best = magazine
            bestAmmo = ammoCount
        end
    end

    return best
end

function FWPFindCompatibleMagazineForWeapon(playerObj, weapon, allowEmpty, includeClip)
    if playerObj == nil or weapon == nil then
        return nil
    end

    local best = nil
    local bestAmmo = -1
    local magazineTypes = FWPGetWeaponMagazineTypes(weapon, includeClip)
    for _, magazineType in ipairs(magazineTypes) do
        local magazine = FWPFindMagazineByType(playerObj, magazineType, allowEmpty)
        if magazine ~= nil then
            local ammoCount = 0
            if magazine.getCurrentAmmoCount then
                local ok, count = pcall(function()
                    return magazine:getCurrentAmmoCount()
                end)
                if ok and tonumber(count) ~= nil then
                    ammoCount = tonumber(count)
                end
            end
            if ammoCount > bestAmmo then
                best = magazine
                bestAmmo = ammoCount
            end
        end
    end

    return best
end

function FWPPrepareMagazineInsert(weapon, magazine)
    if weapon == nil or magazine == nil or not weapon.setMagazineType or not magazine.getFullType then
        return false
    end

    if FWPEnsureFlameFuelCanisterInitialized then
        FWPEnsureFlameFuelCanisterInitialized(magazine)
    end

    local fullType = FWPGetItemFullType(magazine)
    if fullType ~= nil and FWPIsMagazineCompatibleWithWeapon(weapon, magazine, true) then
        pcall(function()
            weapon:setMagazineType(fullType)
        end)
        if weapon.setMaxAmmo and magazine.getMaxAmmo then
            pcall(function()
                weapon:setMaxAmmo(magazine:getMaxAmmo())
            end)
        end
        return true
    end

    return false
end

function FWPInspectPrepareMagazineInsert(weapon, magazine)
    return FWPPrepareMagazineInsert(weapon, magazine)
end

function FWPInspectBuildPotentialAttachmentMap()
    local potential = {}

    local function addCandidate(item)
        if item == nil or not FWPInspectIsWeaponPartLike(item) then
            return
        end

        local obsolete = item.getObsolete and item:getObsolete() or false
        local hidden = item.isHidden and item:isHidden() or false
        if obsolete or hidden then
            return
        end

        local fullName = nil
        if item.getFullName then
            fullName = item:getFullName()
        elseif item.getFullType then
            fullName = item:getFullType()
        end
        if fullName ~= nil then
            potential[fullName] = true
        end
    end

    local function loadList(list)
        if list == nil then
            return false
        end

        if type(list) == "table" then
            for _, item in pairs(list) do
                addCandidate(item)
            end
            return true
        end

        if list.size and list.get then
            for i = 0, list:size() - 1 do
                addCandidate(list:get(i))
            end
            return true
        end

        return false
    end

    local loaded = false
    if type(getAllItems) == "function" then
        loaded = loadList(getAllItems())
    end

    if not loaded and type(getScriptManager) == "function" then
        local scriptManager = getScriptManager()
        if scriptManager ~= nil and scriptManager.getAllItems then
            loadList(scriptManager:getAllItems())
        end
    end

    return potential
end

function FWPInspectGetUsableMountOn(part)
    if part == nil or not part.getMountOn then
        return nil, nil
    end

    local ok, mountOn = pcall(function()
        return part:getMountOn()
    end)
    if not ok or mountOn == nil then
        return nil, nil
    end

    local text = tostring(mountOn)
    local stripped = string.lower(text):gsub("[%s%[%]{},;]", "")
    if stripped == "" or stripped == "nil" or stripped == "none" then
        return nil, nil
    end

    return mountOn, text
end

function FWPInspectMountTextContains(mountText, candidate)
    if mountText == nil or candidate == nil then
        return false
    end

    local normalized = tostring(mountText):gsub("[,;%[%]{}]", " ")
    local pattern = "%f[%w_%.]" .. FWPInspectEscapeLuaPattern(candidate) .. "%f[^%w_%.]"
    return string.find(normalized, pattern) ~= nil
end

function FWPInspectPartMountsOnWeapon(part, weapon)
    if part == nil or weapon == nil then
        return false
    end

    local mountOn, mountText = FWPInspectGetUsableMountOn(part)
    if mountOn == nil then
        return false
    end

    local fullType = weapon.getFullType and weapon:getFullType() or nil
    local shortType = weapon.getType and weapon:getType() or nil
    local candidates = { fullType, shortType }
    if shortType ~= nil then
        table.insert(candidates, "Base." .. shortType)
    end

    for _, candidate in ipairs(candidates) do
        if candidate ~= nil then
            local ok, result = pcall(function()
                return mountOn:contains(candidate)
            end)
            if ok and result then
                return true
            end
            if FWPInspectMountTextContains(mountText, tostring(candidate)) then
                return true
            end
        end
    end

    return false
end

function FWPInspectCanAttachPart(character, weapon, part, category)
    if character == nil or weapon == nil or part == nil then
        return false
    end

    if part.isBroken then
        local ok, broken = pcall(function()
            return part:isBroken()
        end)
        if ok and broken then
            return false
        end
    end

    if not FWPInspectPartTypeMatches(part, category) then
        return false
    end

    local partType = part:getPartType()
    if partType == nil or FWPGetWeaponPart(weapon, partType) ~= nil then
        return false
    end

    local mountOn = FWPInspectGetUsableMountOn(part)
    if mountOn == nil then
        return false
    end

    return FWPInspectPartMountsOnWeapon(part, weapon)
end

function FWPResolveAmmoRegistryText(ammoType)
    if ammoType == nil then
        return nil
    end

    local text = tostring(ammoType)
    if text == nil or text == "" or text == "nil" then
        return nil
    end

    if FWPAmmoTypeItemKeyMap[text] then
        return FWPAmmoTypeItemKeyMap[text]
    end

    local lowered = string.lower(text)
    if FWPAmmoTypeItemKeyMap[lowered] then
        return FWPAmmoTypeItemKeyMap[lowered]
    end

    for registryKey, itemKey in pairs(FWPAmmoTypeItemKeyMap) do
        if string.find(lowered, registryKey, 1, true) then
            return itemKey
        end
    end

    return text
end

function FWPGetAmmoItemKey(itemOrAmmoType)
    if itemOrAmmoType == nil then
        return nil
    end

    local ammoType = itemOrAmmoType
    if type(itemOrAmmoType) ~= "string" and itemOrAmmoType.getAmmoType then
        local ok, value = pcall(function()
            return itemOrAmmoType:getAmmoType()
        end)
        if not ok then
            return nil
        end
        ammoType = value
    end

    if ammoType == nil then
        return nil
    end

    if type(ammoType) == "string" then
        if FWPAmmoTypeItemKeyMap[ammoType] then
            return FWPAmmoTypeItemKeyMap[ammoType]
        end
        if string.find(ammoType, ":", 1, true) and AmmoType and ResourceLocation and AmmoType.get then
            local ok, registered = pcall(function()
                return AmmoType.get(ResourceLocation.of(ammoType))
            end)
            if ok and registered and registered.getItemKey then
                local keyOk, itemKey = pcall(function()
                    return registered:getItemKey()
                end)
                if keyOk and itemKey and itemKey ~= "" then
                    return itemKey
                end
            end
        end
        return FWPResolveAmmoRegistryText(ammoType)
    end

    if ammoType.getItemKey then
        local ok, itemKey = pcall(function()
            return ammoType:getItemKey()
        end)
        if ok and itemKey and itemKey ~= "" then
            return itemKey
        end
    end

    return FWPResolveAmmoRegistryText(ammoType)
end

function FWPCreateItem(fullType)
    if fullType == nil then
        return nil
    end

    if type(fullType) ~= "string" then
        fullType = FWPGetAmmoItemKey(fullType)
    end
    if fullType == nil or fullType == "" then
        return nil
    end

    local candidates = { fullType }
    if not string.find(fullType, ".", 1, true) then
        table.insert(candidates, "Base." .. fullType)
    end

    for _, candidate in ipairs(candidates) do
        if instanceItem then
            local ok, item = pcall(instanceItem, candidate)
            if ok and item then
                return item
            end
        end
        if InventoryItemFactory and InventoryItemFactory.CreateItem then
            local ok, item = pcall(function()
                return InventoryItemFactory.CreateItem(candidate)
            end)
            if ok and item then
                return item
            end
        end
    end

    return nil
end

function FWPCleanScriptPropertyValue(value)
    if value == nil then
        return nil
    end

    local text = tostring(value)
    if text == nil then
        return nil
    end

    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    text = string.gsub(text, ",%s*$", "")

    if text == "" or text == "nil" or text == "null" then
        return nil
    end

    return text
end

function FWPGetItemFullType(item)
    if item == nil then
        return nil
    end

    if type(item) == "string" then
        return FWPCleanScriptPropertyValue(item)
    end

    if item.getFullType then
        local ok, fullType = pcall(function()
            return item:getFullType()
        end)
        fullType = ok and FWPCleanScriptPropertyValue(fullType) or nil
        if fullType ~= nil then
            return fullType
        end
    end

    if item.getModule and item.getType then
        local okModule, module = pcall(function()
            return item:getModule()
        end)
        local okType, itemType = pcall(function()
            return item:getType()
        end)
        module = okModule and FWPCleanScriptPropertyValue(module) or nil
        itemType = okType and FWPCleanScriptPropertyValue(itemType) or nil
        if module ~= nil and itemType ~= nil then
            return module .. "." .. itemType
        end
    end

    if item.getFullName then
        local ok, fullName = pcall(function()
            return item:getFullName()
        end)
        fullName = ok and FWPCleanScriptPropertyValue(fullName) or nil
        if fullName ~= nil and string.find(fullName, ".", 1, true) then
            return fullName
        end
    end

    if item.getType then
        local ok, itemType = pcall(function()
            return item:getType()
        end)
        return ok and FWPCleanScriptPropertyValue(itemType) or nil
    end

    return nil
end

function FWPGetScriptItemProperty(item, propertyName)
    if item == nil or propertyName == nil then
        return nil
    end

    local scriptItem = nil
    if item.getScriptItem then
        local ok, value = pcall(function()
            return item:getScriptItem()
        end)
        if ok then
            scriptItem = value
        end
    elseif item.getProperty then
        scriptItem = item
    end

    if scriptItem ~= nil and scriptItem.getProperty then
        local ok, value = pcall(function()
            return scriptItem:getProperty(propertyName)
        end)
        if ok then
            return FWPCleanScriptPropertyValue(value)
        end
    end

    return nil
end

FWPCompatibleAmmoTransformFallbacks = FWPCompatibleAmmoTransformFallbacks or {}

local function FWPRegisterCompatibleAmmoPair(left, right)
    if left == nil or right == nil then
        return
    end

    FWPCompatibleAmmoTransformFallbacks[left] = right
    FWPCompatibleAmmoTransformFallbacks[right] = left

    local leftShort = string.match(left, "%.([^%.]+)$")
    local rightShort = string.match(right, "%.([^%.]+)$")
    if leftShort ~= nil then
        FWPCompatibleAmmoTransformFallbacks[leftShort] = right
    end
    if rightShort ~= nil then
        FWPCompatibleAmmoTransformFallbacks[rightShort] = left
    end
end

FWPRegisterCompatibleAmmoPair("Base.Revolver_Short", "Base.Revolver_Short_357")
FWPRegisterCompatibleAmmoPair("Base.Revolver", "Base.Revolver_357")
FWPRegisterCompatibleAmmoPair("Base.Revolver_Long", "Base.Revolver_Long_357")
FWPRegisterCompatibleAmmoPair("Base.GP100_2", "Base.GP100_2_357")
FWPRegisterCompatibleAmmoPair("Base.GP100_4", "Base.GP100_4_357")
FWPRegisterCompatibleAmmoPair("Base.GP100_6", "Base.GP100_6_357")
FWPRegisterCompatibleAmmoPair("Base.K6S", "Base.K6S_357")
FWPRegisterCompatibleAmmoPair("Base.Marlin_1894", "Base.Marlin_1894_357")
FWPRegisterCompatibleAmmoPair("Base.Rhino_60DS", "Base.Rhino_60DS_357")
FWPRegisterCompatibleAmmoPair("Base.Rhino_40DS", "Base.Rhino_40DS_357")
FWPRegisterCompatibleAmmoPair("Base.Rhino_200DS", "Base.Rhino_200DS_357")
FWPRegisterCompatibleAmmoPair("Base.SW_327", "Base.SW_327_357")
FWPRegisterCompatibleAmmoPair("Base.NEF_Handi_38", "Base.NEF_Handi_357")
FWPRegisterCompatibleAmmoPair("Base.NEF_Handi_38_Sawed", "Base.NEF_Handi_357_Sawed")
FWPRegisterCompatibleAmmoPair("Base.NEF_Handi_45LC", "Base.NEF_Handi_410")
FWPRegisterCompatibleAmmoPair("Base.NEF_Handi_45LC_Sawed", "Base.NEF_Handi_410_Sawed")
FWPRegisterCompatibleAmmoPair("Base.Judge_45LC", "Base.Judge_410g")
FWPRegisterCompatibleAmmoPair("Base.Judge513_45LC", "Base.Judge513_410g")
FWPRegisterCompatibleAmmoPair("Base.Judge513_Long_45LC", "Base.Judge513_Long_410g")
FWPRegisterCompatibleAmmoPair("Base.TXS_804_45LC", "Base.TXS_804_410g")
FWPRegisterCompatibleAmmoPair("Base.SlingShot_Rock", "Base.SlingShot_Marble")
FWPRegisterCompatibleAmmoPair("Base.WristRocket_Rock", "Base.WristRocket_Marble")

function FWPGetCompatibleAmmoTransform(item)
    if item == nil then
        return nil
    end

    local md = item.getModData and item:getModData() or nil
    local comp = md and FWPCleanScriptPropertyValue(md.CompAmmo) or nil
    if comp ~= nil then
        return comp
    end

    comp = FWPGetScriptItemProperty(item, "CompAmmo")
    if comp ~= nil then
        if md ~= nil then
            md.CompAmmo = comp
        end
        return comp
    end

    local fullType = FWPGetItemFullType(item)
    comp = fullType and FWPCompatibleAmmoTransformFallbacks[fullType] or nil
    if comp == nil and fullType ~= nil then
        local shortType = string.match(fullType, "%.([^%.]+)$")
        comp = shortType and FWPCompatibleAmmoTransformFallbacks[shortType] or nil
    end

    if comp ~= nil and md ~= nil then
        md.CompAmmo = comp
    end

    return comp
end

FWPWeaponTransformModule = FWPWeaponTransformModule or "FWPWeaponTransform"
FWPWeaponTransformCommand = FWPWeaponTransformCommand or "Transform"
FWPWeaponTransformConfirmCommand = FWPWeaponTransformConfirmCommand or "TransformConfirm"
FWPWeaponTransformErrorCommand = FWPWeaponTransformErrorCommand or "TransformError"

local FWP_TRANSFORM_ATTACHMENT_SLOTS = {
    "Scope",
    "Canon",
    "Clip",
    "Stock",
    "Sling",
    "RecoilPad"
}

local FWP_TRANSFORM_TEMP_SLOT_KEYS = {
    Scope = "TempScope",
    Canon = "TempCanon",
    Clip = "TempClip",
    Stock = "TempStock",
    Sling = "TempSling",
    RecoilPad = "TempRecoilPad"
}

local FWP_TRANSFORM_MODDATA_EXCLUDE = {
    weaponpart = true,
    CompAmmo = true,
    Fold = true,
    Fold2 = true,
    Melee = true,
    HEMode = true,
    INCMode = true,
    Integral = true,
    Mode_Toggle = true
}

function FWPNormalizeFullType(fullType)
    fullType = FWPCleanScriptPropertyValue(fullType)
    if fullType == nil then
        return nil
    end
    if not string.find(fullType, ".", 1, true) then
        return "Base." .. fullType
    end
    return fullType
end

function FWPRestoreWeaponSprite(weapon, fallbackSprite)
    if not (weapon and weapon.getWeaponSprite and weapon.setWeaponSprite) then
        return false
    end

    local okSprite, sprite = pcall(function()
        return weapon:getWeaponSprite()
    end)
    sprite = okSprite and FWPCleanScriptPropertyValue(sprite) or nil
    if sprite ~= nil and sprite ~= "null" then
        return false
    end

    local md = weapon.getModData and weapon:getModData() or nil
    local restore = FWPCleanScriptPropertyValue(fallbackSprite)
    if restore == nil and md then
        restore = FWPCleanScriptPropertyValue(md.FWPOriginalWeaponSprite)
    end

    if restore == nil then
        local fullType = FWPGetItemFullType and FWPGetItemFullType(weapon) or nil
        if fullType and instanceItem then
            local okFresh, fresh = pcall(instanceItem, fullType)
            if okFresh and fresh and fresh.getWeaponSprite then
                local okFreshSprite, freshSprite = pcall(function()
                    return fresh:getWeaponSprite()
                end)
                restore = okFreshSprite and FWPCleanScriptPropertyValue(freshSprite) or nil
            end
        end
    end

    if restore == nil and weapon.getType then
        local okType, itemType = pcall(function()
            return weapon:getType()
        end)
        restore = okType and FWPCleanScriptPropertyValue(itemType) or nil
    end

    if restore ~= nil and restore ~= "null" then
        pcall(weapon.setWeaponSprite, weapon, restore)
        if md then
            md.FWPOriginalWeaponSprite = restore
        end
        return true
    end

    return false
end

function FWPEachInventoryItemRecursive(inventory, callback)
    if not (inventory and inventory.getItems and callback) then
        return false
    end

    local items = inventory:getItems()
    if not items then
        return false
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if callback(item) then
            return true
        end
        if item and item.IsInventoryContainer and item:IsInventoryContainer() then
            local childInv = item:getInventory()
            if childInv and FWPEachInventoryItemRecursive(childInv, callback) then
                return true
            end
        end
    end

    return false
end

function FWPFindPlayerInventoryItemById(playerObj, itemId, weaponOnly)
    itemId = tonumber(itemId)
    if not (playerObj and itemId) then
        return nil
    end

    local function matches(item)
        if not (item and item.getID and item:getID() == itemId) then
            return false
        end
        if weaponOnly and not (item.IsWeapon and item:IsWeapon()) then
            return false
        end
        return true
    end

    local primary = playerObj.getPrimaryHandItem and playerObj:getPrimaryHandItem() or nil
    if matches(primary) then
        return primary
    end

    local secondary = playerObj.getSecondaryHandItem and playerObj:getSecondaryHandItem() or nil
    if matches(secondary) then
        return secondary
    end

    local inventory = playerObj.getInventory and playerObj:getInventory() or nil
    if not inventory then
        return nil
    end

    local found = nil
    FWPEachInventoryItemRecursive(inventory, function(item)
        if found then
            return true
        end
        if matches(item) then
            found = item
            return true
        end
        return false
    end)

    return found
end

local function FWPTransformAddCandidate(candidates, value)
    value = FWPNormalizeFullType(value)
    if value ~= nil then
        candidates[value] = true
    end
end

local function FWPTransformGetProperty(weapon, propertyName)
    local md = weapon and weapon.getModData and weapon:getModData() or nil
    local value = md and md[propertyName] or nil
    if value ~= nil then
        return value
    end
    return FWPGetScriptItemProperty(weapon, propertyName)
end

local function FWPTransformGetLauncherReturnTarget(weapon)
    local md = weapon and weapon.getModData and weapon:getModData() or nil
    local target = md and md.FWPLauncherReturnType or nil
    if target ~= nil then
        return FWPNormalizeFullType(target)
    end

    return FWPNormalizeFullType(FWPGetScriptItemProperty(weapon, "Melee"))
end

function FWPWeaponTransformBuildTargetSet(weapon, kind)
    local candidates = {}
    kind = tostring(kind or "")

    if kind == "compatibleAmmo" then
        FWPTransformAddCandidate(candidates, FWPGetCompatibleAmmoTransform(weapon))
    elseif kind == "fold" then
        FWPTransformAddCandidate(candidates, FWPTransformGetProperty(weapon, "Fold"))
    elseif kind == "fold2" then
        FWPTransformAddCandidate(candidates, FWPTransformGetProperty(weapon, "Fold2"))
    elseif kind == "launcherMode" then
        FWPTransformAddCandidate(candidates, FWPTransformGetProperty(weapon, "HEMode"))
        FWPTransformAddCandidate(candidates, FWPTransformGetProperty(weapon, "INCMode"))
    elseif kind == "normalFireMode" then
        FWPTransformAddCandidate(candidates, FWPTransformGetLauncherReturnTarget(weapon))
    elseif kind == "meleeMode" then
        FWPTransformAddCandidate(candidates, FWPTransformGetProperty(weapon, "Melee"))
    end

    return candidates
end

function FWPWeaponTransformValidateTarget(weapon, targetType, kind)
    targetType = FWPNormalizeFullType(targetType)
    if not (weapon and targetType) then
        return false
    end

    local candidates = FWPWeaponTransformBuildTargetSet(weapon, kind)
    if candidates[targetType] then
        return true
    end

    return false
end

local function FWPTransformCopyModData(source, result)
    local sourceMd = source and source.getModData and source:getModData() or nil
    local resultMd = result and result.getModData and result:getModData() or nil
    if not (sourceMd and resultMd) then
        return
    end

    for key, value in pairs(sourceMd) do
        if not FWP_TRANSFORM_MODDATA_EXCLUDE[key] then
            resultMd[key] = value
        end
    end
    resultMd.weaponpart = nil
end

local function FWPTransformCopyBasicState(source, result, options)
    options = options or {}
    if source.getCondition and result.setCondition then
        pcall(function() result:setCondition(source:getCondition()) end)
    end
    if source.getHaveBeenRepaired and result.setHaveBeenRepaired then
        pcall(function() result:setHaveBeenRepaired(source:getHaveBeenRepaired()) end)
    end
    if source.isFavorite and result.setFavorite then
        pcall(function() result:setFavorite(source:isFavorite()) end)
    end
    if options.copyFireMode ~= false and source.getFireMode and result.setFireMode then
        pcall(function()
            local fireMode = source:getFireMode()
            if fireMode ~= nil then
                result:setFireMode(fireMode)
            end
        end)
    end
end

local function FWPTransformCopyAmmoState(source, result, options)
    options = options or {}
    if options.copyAmmo == false then
        return
    end

    local sourceMd = source.getModData and source:getModData() or nil
    if source.isContainsClip and result.setContainsClip then
        pcall(function()
            result:setContainsClip(source:isContainsClip() == true)
        end)
    end

    if source.getMagazineType and result.getMagazineType and result.setMagazineType then
        pcall(function()
            local sourceMag = source:getMagazineType()
            local resultMag = result:getMagazineType()
            if sourceMag == nil and sourceMd and sourceMd.ClipType ~= nil then
                result:setMagazineType(sourceMd.ClipType)
            elseif resultMag == "Base.Fixed" then
                -- Keep fixed-magazine targets on their script-defined magazine.
            elseif sourceMag ~= "Base.Fixed" and sourceMag ~= nil then
                result:setMagazineType(sourceMag)
            end
        end)
    end

    if source.getMaxAmmo and result.setMaxAmmo then
        pcall(function() result:setMaxAmmo(source:getMaxAmmo()) end)
    end
    if source.getCurrentAmmoCount and result.setCurrentAmmoCount then
        pcall(function() result:setCurrentAmmoCount(source:getCurrentAmmoCount()) end)
    end
    if source.isRoundChambered and result.setRoundChambered then
        pcall(function() result:setRoundChambered(source:isRoundChambered() == true) end)
    end
    if source.isSpentRoundChambered and result.setSpentRoundChambered then
        pcall(function() result:setSpentRoundChambered(source:isSpentRoundChambered() == true) end)
    end
    if source.getSpentRoundCount and result.setSpentRoundCount then
        pcall(function() result:setSpentRoundCount(source:getSpentRoundCount()) end)
    end
end

local function FWPTransformAttachPart(result, slot, part)
    if not (result and slot and part) then
        return
    end
    if FWPSafeAttachWeaponPart then
        FWPSafeAttachWeaponPart(result, part, slot)
        return
    end
    if result.attachWeaponPart then
        pcall(function() result:attachWeaponPart(part) end)
    end
end

local function FWPTransformCopyAttachments(source, result, kind)
    if not (source and result and instanceof(source, "HandWeapon") and instanceof(result, "HandWeapon")) then
        return
    end

    local sourceIsGun = source.isAimedFirearm and source:isAimedFirearm()
    local resultIsGun = result.isAimedFirearm and result:isAimedFirearm()
    local sourceMd = source.getModData and source:getModData() or nil
    local resultMd = result.getModData and result:getModData() or nil

    for _, slot in ipairs(FWP_TRANSFORM_ATTACHMENT_SLOTS) do
        local part = nil
        if kind == "meleeMode" and (not sourceIsGun) and resultIsGun and sourceMd then
            part = sourceMd[FWP_TRANSFORM_TEMP_SLOT_KEYS[slot]]
        else
            part = source.getWeaponPart and source:getWeaponPart(slot) or nil
            if kind == "meleeMode" and sourceIsGun and (not resultIsGun) and resultMd then
                resultMd[FWP_TRANSFORM_TEMP_SLOT_KEYS[slot]] = part
            end
        end
        FWPTransformAttachPart(result, slot, part)
    end
end

local function FWPTransformApplyLauncherState(playerObj, source, result)
    local sourceMd = source and source.getModData and source:getModData() or nil
    local resultMd = result and result.getModData and result:getModData() or nil
    if not (sourceMd and resultMd) then
        return
    end

    resultMd.FWPLauncherReturnType = FWPNormalizeFullType(sourceMd.FWPLauncherReturnType) or FWPNormalizeFullType(FWPGetItemFullType(source))
    if source.getFireMode then resultMd.TempFireMode = source:getFireMode() end
    if source.isContainsClip then resultMd.TempContainsClip = source:isContainsClip() end
    if source.isRoundChambered then resultMd.TempRoundChambered = source:isRoundChambered() end
    if source.getCurrentAmmoCount then resultMd.TempCurrentAmmoCount = source:getCurrentAmmoCount() end
    if source.getMagazineType then resultMd.TempMagazineType = source:getMagazineType() end
    resultMd.TempStdMagType = sourceMd.MagType
    resultMd.TempExtMagType = sourceMd.ExtMagType
    resultMd.TempDrumMagType = sourceMd.DrumMagType
    resultMd.TempAmmoType = sourceMd.TempAmmoType

    if sourceMd.TempFireMode and result.setFireMode then pcall(function() result:setFireMode(sourceMd.TempFireMode) end) end
    if sourceMd.TempContainsClip and result.setContainsClip then pcall(function() result:setContainsClip(sourceMd.TempContainsClip) end) end
    if sourceMd.TempRoundChambered and result.setRoundChambered then pcall(function() result:setRoundChambered(sourceMd.TempRoundChambered) end) end
    if sourceMd.TempCurrentAmmoCount and result.setCurrentAmmoCount then pcall(function() result:setCurrentAmmoCount(sourceMd.TempCurrentAmmoCount) end) end
    if sourceMd.Trajectory ~= nil then resultMd.Trajectory = sourceMd.Trajectory end

    local removeCount = tonumber(sourceMd.TempCurrentAmmoCount) or 0
    if sourceMd.TempRoundChambered == true then
        removeCount = math.max(1, removeCount + 1)
    end

    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    local targetAmmo = FWPGetAmmoItemKey and FWPGetAmmoItemKey(result) or nil
    if removeCount > 0 and sourceMd.TempAmmoType == 1 and targetAmmo == "Base.40INCRound" then
        for _ = 1, removeCount do
            if inventory and inventory.AddItem then pcall(inventory.AddItem, inventory, "Base.40HERound") end
        end
        if result.setCurrentAmmoCount then pcall(function() result:setCurrentAmmoCount(0) end) end
        if result.setRoundChambered then pcall(function() result:setRoundChambered(false) end) end
    elseif removeCount > 0 and sourceMd.TempAmmoType == 2 and targetAmmo == "Base.40HERound" then
        for _ = 1, removeCount do
            if inventory and inventory.AddItem then pcall(inventory.AddItem, inventory, "Base.40INCRound") end
        end
        if result.setCurrentAmmoCount then pcall(function() result:setCurrentAmmoCount(0) end) end
        if result.setRoundChambered then pcall(function() result:setRoundChambered(false) end) end
    elseif sourceMd.TempCurrentAmmoCount and result.setCurrentAmmoCount then
        pcall(function() result:setCurrentAmmoCount(sourceMd.TempCurrentAmmoCount) end)
    end
end

local function FWPTransformApplyNormalFireState(source, result)
    local sourceMd = source and source.getModData and source:getModData() or nil
    local resultMd = result and result.getModData and result:getModData() or nil
    if not (sourceMd and resultMd) then
        return
    end

    if sourceMd.TempFireMode and result.setFireMode then pcall(function() result:setFireMode(sourceMd.TempFireMode) end) end
    if sourceMd.TempContainsClip ~= nil and result.setContainsClip then pcall(function() result:setContainsClip(sourceMd.TempContainsClip == true) end) end
    if sourceMd.TempRoundChambered ~= nil and result.setRoundChambered then pcall(function() result:setRoundChambered(sourceMd.TempRoundChambered == true) end) end
    if sourceMd.TempCurrentAmmoCount ~= nil and result.setCurrentAmmoCount then pcall(function() result:setCurrentAmmoCount(tonumber(sourceMd.TempCurrentAmmoCount) or 0) end) end
    if sourceMd.TempMagazineType and result.setMagazineType then pcall(function() result:setMagazineType(sourceMd.TempMagazineType) end) end

    resultMd.MagType = sourceMd.TempStdMagType or resultMd.MagType
    resultMd.ExtMagType = sourceMd.TempExtMagType or resultMd.ExtMagType
    resultMd.DrumMagType = sourceMd.TempDrumMagType or resultMd.DrumMagType
    resultMd.Trajectory = sourceMd.Trajectory
    resultMd.FWPLauncherReturnType = nil

    local launcherAmmoCount = 0
    if source.getCurrentAmmoCount then
        local okAmmo, ammoCount = pcall(source.getCurrentAmmoCount, source)
        if okAmmo and tonumber(ammoCount) ~= nil then
            launcherAmmoCount = tonumber(ammoCount)
        end
    end
    if launcherAmmoCount > 0 then
        local ammoType = FWPGetAmmoItemKey and FWPGetAmmoItemKey(source) or nil
        if ammoType == "Base.40HERound" then
            resultMd.TempAmmoType = 1
        elseif ammoType == "Base.40INCRound" then
            resultMd.TempAmmoType = 2
        end
    end
end

local function FWPTransformApplyMeleeStats(result)
    if not (result and instanceof(result, "HandWeapon")) then
        return
    end

    local scriptItem = result.getScriptItem and result:getScriptItem() or nil
    local maxRange = nil
    if scriptItem and scriptItem.getMaxRange then
        local ok, value = pcall(function() return scriptItem:getMaxRange() end)
        if ok then maxRange = tonumber(value) end
    end

    local crit = result.getCriticalChance and result:getCriticalChance() or nil
    local impact = result.getImpactSound and result:getImpactSound() or nil
    local bayo = 0
    local canon = FWPGetWeaponPart and FWPGetWeaponPart(result, "Canon") or result.getWeaponPart and result:getWeaponPart("Canon") or nil
    if result.isAimedHandWeapon and result:isAimedHandWeapon() and canon and canon.getType and string.find(canon:getType(), "Bayonet") then
        crit = 10
        bayo = 0.4
        if BladeHit ~= nil then
            impact = BladeHit
        end
    end

    if maxRange and bayo > 0 and result.setMaxRange then
        pcall(function() result:setMaxRange(maxRange + bayo) end)
    end
    if crit and result.setCriticalChance then
        pcall(function() result:setCriticalChance(crit) end)
    end
    if impact and result.setImpactSound then
        pcall(function() result:setImpactSound(impact) end)
    end
    if Damage_Multiplier then
        pcall(Damage_Multiplier, result)
    end
end

local function FWPTransformRemoveItem(item, fallbackInventory)
    local container = item and item.getContainer and item:getContainer() or nil
    if container and container.Remove then
        local ok = pcall(container.Remove, container, item)
        if ok then
            if sendRemoveItemFromContainer then
                pcall(sendRemoveItemFromContainer, container, item)
            end
            return true
        end
    end
    if fallbackInventory and fallbackInventory.DoRemoveItem then
        local ok = pcall(fallbackInventory.DoRemoveItem, fallbackInventory, item)
        if ok then
            if sendRemoveItemFromContainer then
                pcall(sendRemoveItemFromContainer, fallbackInventory, item)
            end
            return true
        end
    end
    return false
end

function FWPApplyWeaponTransformLocal(playerObj, weapon, targetType, kind, args)
    args = args or {}
    targetType = FWPNormalizeFullType(targetType)
    if not (playerObj and weapon and targetType) then
        return nil, "invalid_args"
    end
    if not FWPWeaponTransformValidateTarget(weapon, targetType, kind) then
        return nil, "target_not_allowed"
    end

    local result = FWPCreateItem(targetType)
    if not result then
        return nil, "target_create_failed"
    end
    if FWPRestoreWeaponSprite then
        FWPRestoreWeaponSprite(result)
    end

    local inventory = playerObj.getInventory and playerObj:getInventory() or nil
    if not inventory then
        return nil, "inventory_missing"
    end

    FWPTransformCopyModData(weapon, result)
    FWPTransformCopyBasicState(weapon, result, { copyFireMode = kind ~= "compatibleAmmo" })
    FWPTransformCopyAmmoState(weapon, result, { copyAmmo = kind ~= "compatibleAmmo" and kind ~= "launcherMode" and kind ~= "normalFireMode" })
    FWPTransformCopyAttachments(weapon, result, kind)

    if kind == "launcherMode" then
        FWPTransformApplyLauncherState(playerObj, weapon, result)
    elseif kind == "normalFireMode" then
        FWPTransformApplyNormalFireState(weapon, result)
    elseif kind == "meleeMode" then
        FWPTransformApplyMeleeStats(result)
    end

    local wasPrimary = playerObj.getPrimaryHandItem and playerObj:getPrimaryHandItem() == weapon
    local wasSecondary = playerObj.getSecondaryHandItem and playerObj:getSecondaryHandItem() == weapon
    local oldId = weapon.getID and weapon:getID() or nil

    local added = false
    local container = weapon.getContainer and weapon:getContainer() or inventory
    if container and container.AddItem then
        local ok = pcall(container.AddItem, container, result)
        added = ok == true
    end
    if not added and inventory.AddItem then
        local ok = pcall(inventory.AddItem, inventory, result)
        added = ok == true
    end
    if not added then
        return nil, "inventory_add_failed"
    end
    if sendAddItemToContainer then
        pcall(sendAddItemToContainer, container or inventory, result)
    end

    if wasPrimary and playerObj.setPrimaryHandItem then
        pcall(playerObj.setPrimaryHandItem, playerObj, result)
    end
    if playerObj.setSecondaryHandItem then
        if result.isRequiresEquippedBothHands and result:isRequiresEquippedBothHands() then
            pcall(playerObj.setSecondaryHandItem, playerObj, result)
        elseif result.isTwoHandWeapon and result:isTwoHandWeapon() then
            pcall(playerObj.setSecondaryHandItem, playerObj, result)
        elseif wasSecondary then
            pcall(playerObj.setSecondaryHandItem, playerObj, result)
        elseif playerObj.getSecondaryHandItem and playerObj:getSecondaryHandItem() == weapon then
            pcall(playerObj.setSecondaryHandItem, playerObj, nil)
        end
    end

    FWPTransformRemoveItem(weapon, inventory)

    if showMag and instanceof(result, "HandWeapon") and result.isAimedFirearm and result:isAimedFirearm() then
        pcall(showMag, result)
    end
    if FWPRestoreWeaponSprite then
        FWPRestoreWeaponSprite(result)
    end
    if checkHotbar then
        pcall(checkHotbar, playerObj, weapon, result, tonumber(args.hotbarWeight) or 1)
    end
    if FWPRestoreWeaponSprite then
        FWPRestoreWeaponSprite(result)
    end
    if ReEquipIt and wasPrimary then
        pcall(ReEquipIt, playerObj, result)
    end
    if result.transmitModData then
        pcall(result.transmitModData, result)
    end
    if syncHandWeaponFields and instanceof(result, "HandWeapon") then
        pcall(syncHandWeaponFields, playerObj, result)
    end

    return result, nil, oldId
end

function FWPRequestWeaponTransform(playerObj, weapon, targetType, kind, args)
    args = args or {}
    targetType = FWPNormalizeFullType(targetType)
    if not (playerObj and weapon and targetType) then
        return false, "invalid_args"
    end

    if isClient and isClient() and sendClientCommand then
        sendClientCommand(playerObj, FWPWeaponTransformModule, FWPWeaponTransformCommand, {
            weaponId = weapon.getID and weapon:getID() or nil,
            targetType = targetType,
            kind = tostring(kind or ""),
            hotbarWeight = tonumber(args.hotbarWeight) or 1
        })
        return true, "sent_for_server_validation"
    end

    if not FWPWeaponTransformValidateTarget(weapon, targetType, kind) then
        return false, "target_not_allowed"
    end

    local result, err = FWPApplyWeaponTransformLocal(playerObj, weapon, targetType, kind, args)
    return result ~= nil, err, result
end

function FWPGetNVAPIController()
    if FWPNVAPI.checked then
        return FWPNVAPI.ctrl
    end

    FWPNVAPI.checked = true
    local ok, ctrl = pcall(require, "NVAPI/ctrl/instance")
    if ok then
        FWPNVAPI.ctrl = ctrl
    end

    return FWPNVAPI.ctrl
end
