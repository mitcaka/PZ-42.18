-- Runtime charge support for weapon lights and lasers.

FWPWeaponLightCharge = FWPWeaponLightCharge or {}
FWPWeaponLightCharge.MODULE = "FWPWeaponLightCharge"
FWPWeaponLightCharge.COMMAND = "Charge"
FWPWeaponLightCharge.CONFIRM = "Confirm"
FWPWeaponLightCharge.ERROR = "Error"
FWPWeaponLightCharge.MAX_CHARGE = 100

local CHARGEABLE_TYPES = {
    ["Base.Light_Small"] = true,
    ["Base.Light_Large"] = true,
    ["Base.Light_Medium_M952V"] = true,
    ["Base.Light_Small_Socom"] = true,
    ["Base.Light_Small_Socom_ON"] = true,
    ["Base.Light_Small_TLR_7AH"] = true,
    ["Base.Light_Medium_M900"] = true,
    ["Base.Laser_Green"] = true,
    ["Base.Laser_Green_ON"] = true,
    ["Base.Laser_Red"] = true,
    ["Base.Laser_Red_ON"] = true,
    ["Base.Laser_DVAL"] = true,
    ["Base.Laser_DVAL_ON"] = true,
    ["Base.Laser_PEQ15"] = true,
    ["Base.Laser_PEQ15_ON"] = true
}

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

local function roundCharge(value)
    value = safeNumber(value, 0)
    return math.floor((value * 10) + 0.5) / 10
end

local function clampCharge(value)
    value = roundCharge(value)
    if value < 0 then return 0 end
    if value > FWPWeaponLightCharge.MAX_CHARGE then return FWPWeaponLightCharge.MAX_CHARGE end
    return value
end

local function getFullType(item)
    if not item then return nil end
    if FWPGetItemFullType then
        local ok, fullType = pcall(FWPGetItemFullType, item)
        if ok and fullType and tostring(fullType) ~= "" then
            return tostring(fullType)
        end
    end
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

local function hasChargeTag(item, tagName)
    if not (item and item.hasTag and tagName) then return false end
    local tag = FWPGetItemTag and FWPGetItemTag(tagName) or tagName
    local ok, result = pcall(function() return item:hasTag(tag) end)
    return ok and result == true
end

local function hasAnyChargeTag(item)
    return hasChargeTag(item, "Light") or hasChargeTag(item, "Laser") or hasChargeTag(item, "Multi_Laser")
end

local function isHandWeapon(item)
    if not item then return false end
    if instanceof then
        local ok, result = pcall(instanceof, item, "HandWeapon")
        if ok and result == true then return true end
    end
    return item.IsWeapon and item:IsWeapon() == true
end

local function syncItem(item)
    if item and item.transmitModData then
        pcall(item.transmitModData, item)
    end
end

local function syncWeapon(playerObj, weapon)
    if not weapon then return end
    syncItem(weapon)
    if syncHandWeaponFields and isHandWeapon(weapon) then
        pcall(syncHandWeaponFields, playerObj, weapon)
    end
    if showMag and weapon.isAimedFirearm and weapon:isAimedFirearm() then
        pcall(showMag, weapon)
    end
end

local function setBatteryCharge(playerObj, battery, charge)
    if not battery then return end
    charge = clampCharge(charge)
    safeSet(battery, "setUsedDelta", charge / 100)
    syncItem(battery)
    if sendItemStats then
        pcall(sendItemStats, battery)
        if playerObj then pcall(sendItemStats, playerObj, battery) end
    end
end

local function debugCharge(playerObj, message)
    if DebugSay then
        pcall(DebugSay, 2, message)
    elseif playerObj and playerObj.Say then
        pcall(playerObj.Say, playerObj, message)
    end
end

local function contextText(key, fallback)
    if getText then
        local ok, value = pcall(getText, key)
        if ok and value and value ~= key then return value end
    end
    return fallback
end

function FWPWeaponLightChargeGetFullType(item)
    return getFullType(item)
end

function FWPWeaponLightChargeIsBattery(item)
    if not item then return false end
    local fullType = normalizeFullType(getFullType(item))
    if fullType == "Base.Battery" then return true end
    return getType(item) == "Battery"
end

function FWPWeaponLightChargeGetBatteryCharge(item)
    if not FWPWeaponLightChargeIsBattery(item) then return 0 end
    return clampCharge(safeNumber(safeCall(item, "getUsedDelta"), 0) * 100)
end

function FWPWeaponLightChargeIsChargeable(item)
    if not item then return false end
    local fullType = normalizeFullType(getFullType(item))
    if fullType and fullType:find("LaserBeam", 1, true) then return false end
    if fullType and CHARGEABLE_TYPES[fullType] then return true end

    local itemType = getType(item) or ""
    if itemType:find("LaserBeam", 1, true) then return false end
    if itemType:find("Light_", 1, true) or itemType:find("Laser_", 1, true) then
        return true
    end

    if hasAnyChargeTag(item) then
        return true
    end

    return false
end

function FWPWeaponLightChargeGetCharge(item)
    if not item or not item.getModData then return 0 end
    local md = item:getModData()
    return clampCharge(md and md.Charge or 0)
end

local function getSavedAttachedCharge(weapon, slot)
    if not (weapon and weapon.getModData and slot) then return nil end
    local md = weapon:getModData()
    local charge = nil
    if slot == "Stock" then
        charge = md and md.Charge or nil
    elseif slot == "Sling" then
        charge = md and md.Charge2 or nil
    end
    if charge == nil then return nil end
    return clampCharge(charge)
end

local function mirrorAttachedCharge(weapon, part, slot, charge)
    charge = clampCharge(charge)
    if part and part.getModData then
        part:getModData().Charge = charge
    end
    if weapon and weapon.getModData and slot then
        local md = weapon:getModData()
        if slot == "Stock" then
            md.Charge = charge
        elseif slot == "Sling" then
            md.Charge2 = charge
        end
    end
    return charge
end

function FWPWeaponLightChargeGetAttachedCharge(weapon, part, slot)
    if not part then return 0 end
    local partCharge = FWPWeaponLightChargeGetCharge(part)
    local savedCharge = getSavedAttachedCharge(weapon, slot)
    if savedCharge ~= nil and savedCharge > partCharge then
        return mirrorAttachedCharge(weapon, part, slot, savedCharge)
    end
    if savedCharge ~= nil and partCharge > savedCharge then
        return mirrorAttachedCharge(weapon, part, slot, partCharge)
    end
    if savedCharge == nil and partCharge > 0 then
        return mirrorAttachedCharge(weapon, part, slot, partCharge)
    end
    return partCharge
end

function FWPWeaponLightChargeNeedsCharge(item)
    return FWPWeaponLightChargeIsChargeable(item) and FWPWeaponLightChargeGetCharge(item) < FWPWeaponLightCharge.MAX_CHARGE
end

function FWPWeaponLightChargeFindBestBattery(inventory)
    if not inventory then return nil, 0 end

    local best = nil
    local bestCharge = 0
    local seen = {}

    local function consider(item)
        if not item then return false end
        local itemId = item.getID and item:getID() or tostring(item)
        if seen[itemId] then return false end
        seen[itemId] = true

        local charge = FWPWeaponLightChargeGetBatteryCharge(item)
        if charge > bestCharge then
            best = item
            bestCharge = charge
        end
        return false
    end

    if FWPEachInventoryItemRecursive then
        FWPEachInventoryItemRecursive(inventory, consider)
    elseif inventory.getItems then
        local items = inventory:getItems()
        if items then
            for i = 0, items:size() - 1 do
                consider(items:get(i))
            end
        end
    end

    return best, bestCharge
end

function FWPWeaponLightChargeFindItemById(playerObj, itemId, weaponOnly)
    itemId = tonumber(itemId)
    if not (playerObj and itemId) then return nil end
    if FWPFindPlayerInventoryItemById then
        local found = FWPFindPlayerInventoryItemById(playerObj, itemId, weaponOnly)
        if found then return found end
    end

    local inventory = playerObj.getInventory and playerObj:getInventory() or nil
    if not inventory then return nil end

    local function matches(item)
        if not (item and item.getID and item:getID() == itemId) then return false end
        if weaponOnly and not isHandWeapon(item) then return false end
        return true
    end

    if FWPEachInventoryItemRecursive then
        local found = nil
        FWPEachInventoryItemRecursive(inventory, function(item)
            if matches(item) then
                found = item
                return true
            end
            return false
        end)
        return found
    end

    return nil
end

function FWPWeaponLightChargeGetWeaponPart(weapon, slot)
    if not (weapon and slot) then return nil end
    if FWPGetWeaponPart then
        local part = FWPGetWeaponPart(weapon, slot)
        if part then return part end
    end
    return safeCall(weapon, "getWeaponPart", slot)
end

function FWPWeaponLightChargeInferSlot(weapon, target)
    if not (weapon and target) then return nil end
    for _, slot in ipairs({ "Stock", "Sling" }) do
        if FWPWeaponLightChargeGetWeaponPart(weapon, slot) == target then
            return slot
        end
    end
    return nil
end

function FWPWeaponLightChargeFindAttachedTarget(weapon, slot)
    if not weapon then return nil end
    if slot then
        local part = FWPWeaponLightChargeGetWeaponPart(weapon, slot)
        if FWPWeaponLightChargeIsChargeable(part) then
            return part, slot
        end
        return nil
    end

    for _, candidateSlot in ipairs({ "Stock", "Sling" }) do
        local part = FWPWeaponLightChargeGetWeaponPart(weapon, candidateSlot)
        if FWPWeaponLightChargeIsChargeable(part) then
            return part, candidateSlot
        end
    end

    return nil
end

function FWPWeaponLightChargeCollectAttachedTargets(weapon, includeFull)
    local result = {}
    if not weapon then return result end

    for _, slot in ipairs({ "Stock", "Sling" }) do
        local part = FWPWeaponLightChargeGetWeaponPart(weapon, slot)
        if FWPWeaponLightChargeIsChargeable(part) then
            local charge = FWPWeaponLightChargeGetAttachedCharge(weapon, part, slot)
            if includeFull or charge < FWPWeaponLightCharge.MAX_CHARGE then
                result[#result + 1] = {
                    slot = slot,
                    part = part,
                    charge = charge
                }
            end
        end
    end

    return result
end

function FWPWeaponLightChargeApply(playerObj, target, battery, weapon, slot)
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    if not FWPWeaponLightChargeIsChargeable(target) then return false, "invalid_target" end

    if not battery and inventory then
        battery = FWPWeaponLightChargeFindBestBattery(inventory)
    end
    if not FWPWeaponLightChargeIsBattery(battery) then return false, "missing_battery" end

    slot = slot or (weapon and FWPWeaponLightChargeInferSlot(weapon, target) or nil)
    local targetCharge = nil
    if weapon and slot then
        targetCharge = FWPWeaponLightChargeGetAttachedCharge(weapon, target, slot)
    else
        targetCharge = FWPWeaponLightChargeGetCharge(target)
    end
    if targetCharge >= FWPWeaponLightCharge.MAX_CHARGE then return false, "target_full" end

    local batteryCharge = FWPWeaponLightChargeGetBatteryCharge(battery)
    if batteryCharge <= 0 then return false, "battery_empty" end

    local needed = roundCharge(FWPWeaponLightCharge.MAX_CHARGE - targetCharge)
    local used = math.min(needed, batteryCharge)
    if used <= 0 then return false, "nothing_to_transfer" end

    local newTargetCharge = clampCharge(targetCharge + used)
    local newBatteryCharge = clampCharge(batteryCharge - used)

    if weapon and slot then
        mirrorAttachedCharge(weapon, target, slot, newTargetCharge)
    elseif target.getModData then
        target:getModData().Charge = newTargetCharge
    end

    setBatteryCharge(playerObj, battery, newBatteryCharge)
    syncItem(target)
    syncWeapon(playerObj, weapon)

    if playerObj and playerObj.playSound then
        pcall(playerObj.playSound, playerObj, "LightSaber_Charge")
    end

    local deviceText = contextText("ContextMenu_Device", "Device")
    local batteryText = contextText("ContextMenu_Battery", "Battery")
    debugCharge(playerObj, deviceText .. " (+" .. tostring(used) .. "/" .. tostring(newTargetCharge) .. ") " .. batteryText .. " (" .. tostring(newBatteryCharge) .. ")")

    return true, {
        used = used,
        charge = newTargetCharge,
        battery = newBatteryCharge
    }
end

function FWPWeaponLightChargeApplyByArgs(playerObj, args)
    if not (playerObj and args) then return false, "invalid_args" end
    local inventory = playerObj.getInventory and playerObj:getInventory() or nil
    if not inventory then return false, "inventory_missing" end

    local battery = FWPWeaponLightChargeFindItemById(playerObj, args.batteryId, false)
    if not battery then
        battery = FWPWeaponLightChargeFindBestBattery(inventory)
    end

    local targetKind = tostring(args.targetKind or "")
    if targetKind == "weaponSlot" then
        local weapon = FWPWeaponLightChargeFindItemById(playerObj, args.weaponId, true)
        if not weapon then return false, "weapon_missing" end
        local slot = tostring(args.slot or "")
        if slot ~= "Stock" and slot ~= "Sling" then return false, "invalid_slot" end
        local target = FWPWeaponLightChargeFindAttachedTarget(weapon, slot)
        if not target then return false, "attachment_missing" end
        return FWPWeaponLightChargeApply(playerObj, target, battery, weapon, slot)
    elseif targetKind == "item" then
        local target = FWPWeaponLightChargeFindItemById(playerObj, args.targetId, false)
        if not target then return false, "target_missing" end
        return FWPWeaponLightChargeApply(playerObj, target, battery, nil, nil)
    end

    return false, "unknown_target"
end

print("[FWP LIGHT CHARGE] shared runtime helpers registered")
