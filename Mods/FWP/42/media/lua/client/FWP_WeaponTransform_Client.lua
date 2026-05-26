-- Client-side completion for server-authoritative weapon transforms.
if isServer() then return end

local pendingTransforms = {}

local function getLocalPlayerForTransform(args)
    local playerObj = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not playerObj then
        return nil
    end
    if args and args.onlineId and playerObj.getOnlineID and playerObj:getOnlineID() ~= args.onlineId then
        return nil
    end
    return playerObj
end

local function findWeaponByType(playerObj, fullType)
    fullType = FWPNormalizeFullType(fullType)
    if not (playerObj and fullType) then
        return nil
    end

    local primary = playerObj.getPrimaryHandItem and playerObj:getPrimaryHandItem() or nil
    if primary and primary.getFullType and FWPNormalizeFullType(primary:getFullType()) == fullType then
        return primary
    end

    local found = nil
    local inventory = playerObj.getInventory and playerObj:getInventory() or nil
    FWPEachInventoryItemRecursive(inventory, function(item)
        if found then
            return true
        end
        if item and item.IsWeapon and item:IsWeapon() and item.getFullType and FWPNormalizeFullType(item:getFullType()) == fullType then
            found = item
            return true
        end
        return false
    end)
    return found
end

local function applyTransformConfirm(args)
    local playerObj = getLocalPlayerForTransform(args)
    if not playerObj then
        return true
    end

    local weapon = FWPFindPlayerInventoryItemById(playerObj, args and args.newId, true)
    if not weapon then
        weapon = findWeaponByType(playerObj, args and args.targetType)
    end
    if not weapon then
        return false
    end

    local oldWeapon = FWPFindPlayerInventoryItemById(playerObj, args and args.oldId, true)
    if FWPRestoreWeaponSprite then
        FWPRestoreWeaponSprite(weapon)
    end
    if checkHotbar then
        pcall(checkHotbar, playerObj, oldWeapon or weapon, weapon, tonumber(args and args.hotbarWeight) or 1)
    end
    if FWPRestoreWeaponSprite then
        FWPRestoreWeaponSprite(weapon)
    end
    if ReEquipIt then
        pcall(ReEquipIt, playerObj, weapon)
    else
        if playerObj.setPrimaryHandItem then pcall(playerObj.setPrimaryHandItem, playerObj, weapon) end
        if playerObj.setSecondaryHandItem then
            if weapon.isRequiresEquippedBothHands and weapon:isRequiresEquippedBothHands() then
                pcall(playerObj.setSecondaryHandItem, playerObj, weapon)
            elseif weapon.isTwoHandWeapon and weapon:isTwoHandWeapon() then
                pcall(playerObj.setSecondaryHandItem, playerObj, weapon)
            end
        end
    end
    if showMag and weapon.isAimedFirearm and weapon:isAimedFirearm() then
        pcall(showMag, weapon)
    end
    return true
end

local function queueTransformConfirm(args)
    table.insert(pendingTransforms, {
        args = args,
        attempts = 0
    })
end

local function onServerCommand(module, command, args)
    if module ~= FWPWeaponTransformModule then
        return
    end

    if command == FWPWeaponTransformConfirmCommand then
        if not applyTransformConfirm(args) then
            queueTransformConfirm(args)
        end
        return
    end

    if command == FWPWeaponTransformErrorCommand then
        local playerObj = getLocalPlayerForTransform(args)
        if playerObj and DebugSay then
            DebugSay(2, getText("ContextMenu_NoFunction"))
        end
    end
end

local function onTick()
    if #pendingTransforms == 0 then
        return
    end

    for i = #pendingTransforms, 1, -1 do
        local pending = pendingTransforms[i]
        pending.attempts = (pending.attempts or 0) + 1
        if applyTransformConfirm(pending.args) or pending.attempts > 120 then
            table.remove(pendingTransforms, i)
        end
    end
end

Events.OnServerCommand.Add(onServerCommand)
Events.OnTick.Add(onTick)
