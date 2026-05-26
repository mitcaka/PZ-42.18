-- Client context menu for runtime weapon-work actions.
if isServer() then return end

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

local function getFullType(item)
    if not item then return nil end
    if item.getFullType then
        local fullType = item:getFullType()
        if fullType and tostring(fullType) ~= "" then return tostring(fullType) end
    end
    if item.getModule and item.getType then
        return tostring(item:getModule()) .. "." .. tostring(item:getType())
    end
    return nil
end

local function getCanisterPart(weapon)
    if FWPGetWeaponPart then
        local part = FWPGetWeaponPart(weapon, "RecoilPad")
        if part then return part end
    end
    return weapon and weapon.getWeaponPart and weapon:getWeaponPart("RecoilPad") or nil
end

local function getItemId(item)
    return item and item.getID and item:getID() or nil
end

function FWPWeaponWorkRequest(playerObj, op, weapon, part, extra)
    if not (playerObj and op) then return end
    local args = {
        op = op,
        weaponId = getItemId(weapon),
        partId = getItemId(part)
    }
    if extra then
        for key, value in pairs(extra) do
            args[key] = value
        end
    end
    if isClient and isClient() and sendClientCommand then
        sendClientCommand(playerObj, FWPWeaponWork.MODULE, FWPWeaponWork.COMMAND, args)
    elseif FWPWeaponWorkApplyCommand then
        FWPWeaponWorkApplyCommand(playerObj, args)
    end
end

local function sendWeaponWork(playerObj, op, weapon, part, extra)
    return FWPWeaponWorkRequest(playerObj, op, weapon, part, extra)
end

function FWPWeaponWorkCollectActions(playerObj, weapon)
    local actions = {}
    if not (playerObj and weapon and weapon.isAimedFirearm and weapon:isAimedFirearm()) then return actions end
    local inventory = playerObj:getInventory()
    if not inventory then return actions end

    local function add(label, op, part, extra)
        actions[#actions + 1] = {
            label = label,
            op = op,
            part = part,
            extra = extra,
            run = function()
                FWPWeaponWorkRequest(playerObj, op, weapon, part, extra)
            end
        }
    end

    local screwdriver = FWPWeaponWorkFindScrewdriver and FWPWeaponWorkFindScrewdriver(inventory) or nil
    local groupType = FWPWeaponWorkGetTriggerGroupType and FWPWeaponWorkGetTriggerGroupType(weapon) or nil
    if groupType and screwdriver then
        local md = weapon.getModData and weapon:getModData() or nil
        local triggerType = tonumber(md and md.TriggerType)
        if triggerType == 0 then
            local triggerGroup = FWPWeaponWorkFindItemByFullType(inventory, groupType)
            if triggerGroup then
                add("Install Fire-Control Group", "installTrigger", triggerGroup)
            end
        else
            add("Remove Fire-Control Group", "removeTrigger")
        end
    end

    local isPaintball = FWPWeaponWorkIsPaintballCanisterWeapon and FWPWeaponWorkIsPaintballCanisterWeapon(weapon)
    local isCO2 = FWPWeaponWorkIsCO2CanisterWeapon and FWPWeaponWorkIsCO2CanisterWeapon(weapon)
    if screwdriver and (isPaintball or isCO2) then
        if getCanisterPart(weapon) then
            add(isPaintball and "Remove Paintball Canister" or "Remove CO2 Cartridge", "removeCanister")
        else
            local tankType = isPaintball and "Base.M2A1_Can" or "Base.CO2_Cartridge"
            local tank = FWPWeaponWorkFindItemByFullType(inventory, tankType)
            if tank then
                add(isPaintball and "Install Paintball Canister" or "Install CO2 Cartridge", "installCanister", tank)
            end
        end
    end

    if FWPWeaponWorkGetAvailableConversions then
        for _, conversion in ipairs(FWPWeaponWorkGetAvailableConversions(weapon, inventory)) do
            add(conversion.label, "convertWeapon", conversion.part, { conversionId = conversion.id })
        end
    end

    if FWPWeaponWorkCanRefillLoadedFlameFuel and FWPWeaponWorkCanRefillLoadedFlameFuel(playerObj, weapon) then
        local containerType = FWPWeaponWorkGetLoadedFlameFuelContainerType and FWPWeaponWorkGetLoadedFlameFuelContainerType(weapon) or nil
        local label = "Refill Loaded " .. (FWPWeaponWorkGetFlameFuelContainerLabel and FWPWeaponWorkGetFlameFuelContainerLabel(containerType) or "Fuel Container")
        add(label, "refillLoadedFlameFuel")
    end

    if FWPWeaponLightChargeCollectActions then
        for _, action in ipairs(FWPWeaponLightChargeCollectActions(playerObj, weapon)) do
            actions[#actions + 1] = action
        end
    end

    return actions
end

local function addWeaponOptions(playerObj, context, weapon)
    if not (playerObj and context and weapon and weapon.isAimedFirearm and weapon:isAimedFirearm()) then return false end
    local added = false
    for _, action in ipairs(FWPWeaponWorkCollectActions(playerObj, weapon)) do
        context:addOption(action.label, weapon, action.run)
        added = true
    end

    return added
end

local function addPartOptions(playerObj, context, item)
    if not (playerObj and context and item) then return false end
    local primary = playerObj.getPrimaryHandItem and playerObj:getPrimaryHandItem() or nil
    if not (primary and primary.isAimedFirearm and primary:isAimedFirearm()) then return false end

    local fullType = getFullType(item)
    local groupType = FWPWeaponWorkGetTriggerGroupType and FWPWeaponWorkGetTriggerGroupType(primary) or nil
    if fullType and groupType and fullType == groupType then
        local md = primary.getModData and primary:getModData() or nil
        if tonumber(md and md.TriggerType) == 0 then
            context:addOption("Install Fire-Control Group", primary, function()
                sendWeaponWork(playerObj, "installTrigger", primary, item)
            end)
            return true
        end
    end

    if fullType == "Base.M2A1_Can" and FWPWeaponWorkIsPaintballCanisterWeapon(primary) and not getCanisterPart(primary) then
        context:addOption("Install Paintball Canister", primary, function()
            sendWeaponWork(playerObj, "installCanister", primary, item)
        end)
        return true
    elseif fullType == "Base.CO2_Cartridge" and FWPWeaponWorkIsCO2CanisterWeapon(primary) and not getCanisterPart(primary) then
        context:addOption("Install CO2 Cartridge", primary, function()
            sendWeaponWork(playerObj, "installCanister", primary, item)
        end)
        return true
    end

    if FWPWeaponWorkGetAvailableConversions then
        local inventory = playerObj:getInventory()
        for _, conversion in ipairs(FWPWeaponWorkGetAvailableConversions(primary, inventory)) do
            if conversion.part == item then
                context:addOption(conversion.label, primary, function()
                    sendWeaponWork(playerObj, "convertWeapon", primary, item, { conversionId = conversion.id })
                end)
                return true
            end
        end
    end

    return false
end

local function addFlameFuelContainerOptions(playerObj, context, item)
    if not (playerObj and context and item) then return false end
    if not (FWPWeaponWorkIsFlameFuelContainer and FWPWeaponWorkIsFlameFuelContainer(item)) then return false end
    if not (FWPWeaponWorkCanRefillFlameFuelContainer and FWPWeaponWorkCanRefillFlameFuelContainer(playerObj, item)) then return false end

    local label = "Refill " .. (FWPWeaponWorkGetFlameFuelContainerLabel and FWPWeaponWorkGetFlameFuelContainerLabel(item) or "Fuel Container")
    context:addOption(label, item, function()
        FWPWeaponWorkRequest(playerObj, "refillFuelContainer", nil, item)
    end)
    return true
end

local function onInventoryContext(playerNum, context, items)
    local playerObj = getSpecificPlayer(playerNum)
    if not (playerObj and context) then return end
    for _, item in ipairs(normalizeSelectedItems(items)) do
        if item then
            if addWeaponOptions(playerObj, context, item) then return end
            local added = false
            if addPartOptions(playerObj, context, item) then added = true end
            if addFlameFuelContainerOptions(playerObj, context, item) then added = true end
            if added then return end
        end
    end
end

local function onServerCommand(module, command, args)
    if module ~= FWPWeaponWork.MODULE then return end
    if command == FWPWeaponWork.ERROR then
        print("[FWP WEAPONWORK][client] rejected: " .. tostring(args and args.reason))
    end
end

if Events.OnServerCommand then Events.OnServerCommand.Add(onServerCommand) end
print("[FWP WEAPONWORK] inspect runtime registered")
