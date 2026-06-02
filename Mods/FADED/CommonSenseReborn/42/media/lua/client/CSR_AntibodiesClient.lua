require "CSR_Antibodies"
require "CSR_FeatureFlags"
require "TimedActions/CSR_DrawBloodAction"
require "TimedActions/CSR_InjectSerumAction"

CSR_Antibodies.Client = CSR_Antibodies.Client or {}
CSR_Antibodies.Client.snapshots = CSR_Antibodies.Client.snapshots or {}

local function snapshotKey(playerOrSnapshot)
    if not playerOrSnapshot then return nil end
    if type(playerOrSnapshot) == "table" and playerOrSnapshot.onlineID ~= nil then
        return tostring(playerOrSnapshot.onlineID)
    end
    if playerOrSnapshot.getOnlineID then
        local ok, id = pcall(playerOrSnapshot.getOnlineID, playerOrSnapshot)
        if ok and id ~= nil then return tostring(id) end
    end
    if playerOrSnapshot.username then return tostring(playerOrSnapshot.username) end
    if playerOrSnapshot.getUsername then
        local ok, name = pcall(playerOrSnapshot.getUsername, playerOrSnapshot)
        if ok and name then return tostring(name) end
    end
    return nil
end

local function showHalo(player, key, ok)
    if not player or not player.setHaloNote or not key then return end
    local text = getText and getText(key) or key
    if ok then
        player:setHaloNote(text, 120, 255, 120, 250)
    else
        player:setHaloNote(text, 255, 90, 90, 250)
    end
end

function CSR_Antibodies.Client.storeSnapshot(snapshot)
    local key = snapshotKey(snapshot)
    if key then
        CSR_Antibodies.Client.snapshots[key] = snapshot
    end
end

function CSR_Antibodies.Client.getSnapshot(player)
    local key = snapshotKey(player)
    local snapshot = key and CSR_Antibodies.Client.snapshots[key] or nil
    if snapshot then return snapshot end
    if player then
        return CSR_Antibodies.buildSnapshot(player)
    end
    return nil
end

function CSR_Antibodies.Client.requestSnapshot(subject)
    if not CSR_FeatureFlags.isAntibodySystemEnabled() then return end
    if not isClient or not isClient() then return end

    local player = getPlayer and getPlayer() or nil
    if not player then return end
    sendClientCommand(player, CSR_Antibodies.MODULE, CSR_Antibodies.CMD_REQUEST, {
        targetOnlineID = subject and subject.getOnlineID and subject:getOnlineID() or nil,
    })
end

function CSR_Antibodies.Client.queueDraw(actor, donor, emptySyringe)
    if not actor or not emptySyringe or not ISTimedActionQueue then return end
    ISTimedActionQueue.add(CSR_DrawBloodAction:new(actor, donor or actor, emptySyringe))
end

function CSR_Antibodies.Client.queueInject(actor, recipient, serum)
    if not actor or not serum or not ISTimedActionQueue then return end
    ISTimedActionQueue.add(CSR_InjectSerumAction:new(actor, recipient or actor, serum))
end

local function onServerCommand(module, command, args)
    if module ~= CSR_Antibodies.MODULE then return end

    if command == CSR_Antibodies.CMD_SNAPSHOT then
        if args and args.snapshot then
            CSR_Antibodies.Client.storeSnapshot(args.snapshot)
        end
        return
    end

    if command == CSR_Antibodies.CMD_RESULT then
        local player = getPlayer and getPlayer() or nil
        showHalo(player, args and args.key, args and args.ok)
    end
end

local function getSelectedActualItems(items)
    if ISInventoryPane and ISInventoryPane.getActualItems then
        return ISInventoryPane.getActualItems(items)
    end
    return items or {}
end

local function onFillInventoryObjectContextMenu(playerNum, context, items)
    if not CSR_FeatureFlags.isAntibodySystemEnabled() then return end

    local player = getSpecificPlayer and getSpecificPlayer(playerNum) or getPlayer()
    if not player or player:isDead() then return end

    local actualItems = getSelectedActualItems(items)
    for i = 1, #actualItems do
        local item = actualItems[i]
        local fullType = item and item.getFullType and item:getFullType() or nil
        if fullType == CSR_Antibodies.ITEM_EMPTY_SYRINGE and CSR_Antibodies.isImmune(player) then
            context:addOption(getText("ContextMenu_CSR_DrawImmuneBlood"), player, function()
                CSR_Antibodies.Client.queueDraw(player, player, item)
            end)
            return
        elseif fullType == CSR_Antibodies.ITEM_IMMUNE_SYRINGE and not CSR_Antibodies.isImmune(player) then
            context:addOption(getText("ContextMenu_CSR_InjectAntibodySerum"), player, function()
                CSR_Antibodies.Client.queueInject(player, player, item)
            end)
            return
        end
    end
end

if Events then
    if Events.OnServerCommand then Events.OnServerCommand.Add(onServerCommand) end
    if Events.OnFillInventoryObjectContextMenu then
        Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
    end
end

return CSR_Antibodies.Client
