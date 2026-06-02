-- Server-authoritative item-ID transforms for weapon modes that replace the weapon item.
if not isServer() then return end

local function transformLog(message)
    print("[FWP TRANSFORM][server] " .. tostring(message))
end

local function sendTransformCommand(command, playerObj, args)
    if not sendServerCommand then
        return
    end
    args = args or {}
    args.onlineId = playerObj and playerObj.getOnlineID and playerObj:getOnlineID() or nil
    sendServerCommand(FWPWeaponTransformModule, command, args)
end

local function handleTransformCommand(playerObj, args)
    if not (playerObj and args) then
        return
    end

    local weaponId = tonumber(args.weaponId)
    local targetType = FWPNormalizeFullType(args.targetType)
    local kind = tostring(args.kind or "")
    local weapon = FWPFindPlayerInventoryItemById(playerObj, weaponId, true)

    if not weapon then
        transformLog("rejected: weapon missing id=" .. tostring(weaponId))
        sendTransformCommand(FWPWeaponTransformErrorCommand, playerObj, {
            weaponId = weaponId,
            targetType = targetType,
            kind = kind,
            reason = "weapon_missing"
        })
        return
    end

    if not FWPWeaponTransformValidateTarget(weapon, targetType, kind) then
        transformLog("rejected: target not allowed weapon=" .. tostring(weapon.getFullType and weapon:getFullType() or weapon:getType()) ..
            " target=" .. tostring(targetType) .. " kind=" .. tostring(kind))
        sendTransformCommand(FWPWeaponTransformErrorCommand, playerObj, {
            weaponId = weaponId,
            targetType = targetType,
            kind = kind,
            reason = "target_not_allowed"
        })
        return
    end

    local result, err, oldId = FWPApplyWeaponTransformLocal(playerObj, weapon, targetType, kind, {
        hotbarWeight = tonumber(args.hotbarWeight) or 1
    })
    if not result then
        transformLog("failed: " .. tostring(err) .. " target=" .. tostring(targetType) .. " kind=" .. tostring(kind))
        sendTransformCommand(FWPWeaponTransformErrorCommand, playerObj, {
            weaponId = weaponId,
            targetType = targetType,
            kind = kind,
            reason = tostring(err)
        })
        return
    end

    local newId = result.getID and result:getID() or nil
    transformLog("success oldId=" .. tostring(oldId or weaponId) .. " newId=" .. tostring(newId) ..
        " target=" .. tostring(targetType) .. " kind=" .. tostring(kind))
    sendTransformCommand(FWPWeaponTransformConfirmCommand, playerObj, {
        oldId = oldId or weaponId,
        newId = newId,
        targetType = targetType,
        kind = kind,
        hotbarWeight = tonumber(args.hotbarWeight) or 1
    })
end

local function onClientCommand(module, command, playerObj, args)
    if module ~= FWPWeaponTransformModule or command ~= FWPWeaponTransformCommand then
        return
    end
    handleTransformCommand(playerObj, args)
end

Events.OnClientCommand.Add(onClientCommand)
