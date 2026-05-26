-- Client context and inspect actions for weapon light and laser charging.
if isServer() then return end

FWPWeaponLightChargeHandlesContext = true

local function normalizeSelectedItems(items)
    local result = {}
    if not items then return result end
    for _, entry in ipairs(items) do
        if type(entry) == "table" and entry.items then
            for _, item in ipairs(entry.items) do
                result[#result + 1] = item
            end
        else
            result[#result + 1] = entry
        end
    end
    return result
end

local function getItemId(item)
    return item and item.getID and item:getID() or nil
end

local function getDisplayName(item)
    if item and item.getDisplayName then
        local ok, name = pcall(function() return item:getDisplayName() end)
        if ok and name and tostring(name) ~= "" then return tostring(name) end
    end
    return "Device"
end

local function contextText(key, fallback)
    if getText then
        local ok, value = pcall(getText, key)
        if ok and value and value ~= key then return value end
    end
    return fallback
end

local function chargeLabel(target)
    return contextText("ContextMenu_AttachmentCharge", "Charge") .. " " .. getDisplayName(target)
end

local function isFirearm(item)
    return item and item.isAimedFirearm and item:isAimedFirearm()
end

local function findBestBattery(playerObj)
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    return FWPWeaponLightChargeFindBestBattery and FWPWeaponLightChargeFindBestBattery(inventory) or nil
end

local function playerHasItem(playerObj, item)
    if not (playerObj and item) then return false end
    if FWPWeaponLightChargeFindItemById then
        return FWPWeaponLightChargeFindItemById(playerObj, getItemId(item), false) ~= nil
    end
    return true
end

local function sendChargeRequest(playerObj, args)
    if not (playerObj and args) then return false end
    if isClient and isClient() and sendClientCommand then
        sendClientCommand(playerObj, FWPWeaponLightCharge.MODULE, FWPWeaponLightCharge.COMMAND, args)
        return true
    end
    if FWPWeaponLightChargeApplyByArgs then
        local ok, reason = FWPWeaponLightChargeApplyByArgs(playerObj, args)
        if not ok then print("[FWP LIGHT CHARGE][client] rejected reason=" .. tostring(reason)) end
        return ok
    end
    return false
end

function FWPWeaponLightChargeRequestSlot(playerObj, weapon, slot, battery)
    if not (playerObj and weapon and slot) then return false end
    battery = battery or findBestBattery(playerObj)
    return sendChargeRequest(playerObj, {
        targetKind = "weaponSlot",
        weaponId = getItemId(weapon),
        slot = slot,
        batteryId = getItemId(battery)
    })
end

function FWPWeaponLightChargeRequestItem(playerObj, target, battery)
    if not (playerObj and target) then return false end
    battery = battery or findBestBattery(playerObj)
    return sendChargeRequest(playerObj, {
        targetKind = "item",
        targetId = getItemId(target),
        batteryId = getItemId(battery)
    })
end

function FWPWeaponLightChargeCollectActions(playerObj, weapon)
    local actions = {}
    if not (playerObj and weapon and isFirearm(weapon)) then return actions end

    local battery = findBestBattery(playerObj)
    if not battery then return actions end

    if not FWPWeaponLightChargeCollectAttachedTargets then return actions end
    for _, target in ipairs(FWPWeaponLightChargeCollectAttachedTargets(weapon, false)) do
        actions[#actions + 1] = {
            label = chargeLabel(target.part),
            run = function()
                FWPWeaponLightChargeRequestSlot(playerObj, weapon, target.slot, battery)
            end
        }
    end

    return actions
end

local function addLoosePartOptions(playerObj, context, item, battery)
    if not (playerObj and context and item and battery) then return false end
    if not playerHasItem(playerObj, item) then return false end
    if not (FWPWeaponLightChargeNeedsCharge and FWPWeaponLightChargeNeedsCharge(item)) then return false end
    context:addOption(chargeLabel(item), item, function()
        FWPWeaponLightChargeRequestItem(playerObj, item, battery)
    end)
    return true
end

local function addBatteryOptions(playerObj, context, battery)
    if not (playerObj and context and battery and FWPWeaponLightChargeIsBattery and FWPWeaponLightChargeIsBattery(battery)) then return false end
    if not playerHasItem(playerObj, battery) then return false end
    if FWPWeaponLightChargeGetBatteryCharge and FWPWeaponLightChargeGetBatteryCharge(battery) <= 0 then return false end

    local weapon = playerObj.getPrimaryHandItem and playerObj:getPrimaryHandItem() or nil
    if not (weapon and isFirearm(weapon) and FWPWeaponLightChargeCollectAttachedTargets) then return false end

    local added = false
    for _, target in ipairs(FWPWeaponLightChargeCollectAttachedTargets(weapon, false)) do
        context:addOption(chargeLabel(target.part), weapon, function()
            FWPWeaponLightChargeRequestSlot(playerObj, weapon, target.slot, battery)
        end)
        added = true
    end

    return added
end

local function addWeaponOptions(playerObj, context, weapon, battery)
    if not (playerObj and context and weapon and battery) then return false end
    if not isFirearm(weapon) then return false end
    if not playerHasItem(playerObj, weapon) then return false end
    if not (FWPWeaponLightChargeCollectAttachedTargets and FWPWeaponLightChargeIsBattery and FWPWeaponLightChargeIsBattery(battery)) then return false end
    if FWPWeaponLightChargeGetBatteryCharge and FWPWeaponLightChargeGetBatteryCharge(battery) <= 0 then return false end

    local added = false
    for _, target in ipairs(FWPWeaponLightChargeCollectAttachedTargets(weapon, false)) do
        context:addOption(chargeLabel(target.part), weapon, function()
            FWPWeaponLightChargeRequestSlot(playerObj, weapon, target.slot, battery)
        end)
        added = true
    end

    return added
end

local function onInventoryContext(playerNum, context, items)
    local playerObj = getSpecificPlayer(playerNum)
    if not (playerObj and context) then return end

    local battery = findBestBattery(playerObj)
    for _, item in ipairs(normalizeSelectedItems(items)) do
        if item then
            if FWPWeaponLightChargeIsBattery and FWPWeaponLightChargeIsBattery(item) then
                if addBatteryOptions(playerObj, context, item) then return end
            elseif isFirearm(item) then
                if addWeaponOptions(playerObj, context, item, battery) then return end
            elseif not isFirearm(item) then
                if addLoosePartOptions(playerObj, context, item, battery) then return end
            end
        end
    end
end

local function onServerCommand(module, command, args)
    if module ~= FWPWeaponLightCharge.MODULE then return end
    if command == FWPWeaponLightCharge.ERROR then
        print("[FWP LIGHT CHARGE][client] rejected reason=" .. tostring(args and args.reason))
    end
end

if Events.OnFillInventoryObjectContextMenu then Events.OnFillInventoryObjectContextMenu.Add(onInventoryContext) end
if Events.OnServerCommand then Events.OnServerCommand.Add(onServerCommand) end
print("[FWP LIGHT CHARGE] client runtime registered")
