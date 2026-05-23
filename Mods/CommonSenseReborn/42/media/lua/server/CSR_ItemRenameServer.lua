-- CSR_ItemRenameServer.lua
-- Server-authoritative apply for CSR_ItemRename. The client previously sent
-- a "CSR_ItemRename" module command with no listener on the server, so the
-- rename only existed on the renamer's own machine and reverted whenever
-- the item moved between containers or another player viewed it.
--
-- This module:
--   1. Receives "rename" / "reset" client commands.
--   2. Locates the item in the player's inventory or any nearby world
--      container (3-tile radius), applies setName + setCustomName + writes
--      modData.csrCustomName so the change survives MP transmission.
--   3. Pushes custom name/modData and a full container item replacement so
--      peers see the new name immediately.
--   4. Rebroadcasts via sendServerCommand so client-side reapply hooks
--      can re-stamp the display name on items they have visible.

CSR_ItemRenameServer = CSR_ItemRenameServer or {}
if CSR_ItemRenameServer.__registered then
    return CSR_ItemRenameServer
end
CSR_ItemRenameServer.__registered = true

local FIND_MAX_DEPTH = 4

local function itemMatchesId(item, itemId, expectedType)
    if not item or not item.getID or item:getID() ~= itemId then
        return false
    end
    if expectedType and item.getFullType and item:getFullType() ~= expectedType then
        return false
    end
    return true
end

local function findInContainerRecursive(container, itemId, expectedType, seen, depth)
    if not container or not container.getItems then return nil end
    depth = depth or 0
    if depth > FIND_MAX_DEPTH then return nil end
    seen = seen or {}
    if seen[container] then return nil end
    seen[container] = true

    local items = container:getItems()
    if not items then return nil end
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if itemMatchesId(it, itemId, expectedType) then return it end
        if it and it.getInventory then
            local nested = it:getInventory()
            local found = findInContainerRecursive(nested, itemId, expectedType, seen, depth + 1)
            if found then return found end
        end
    end
    return nil
end

local function findItemById(player, itemId, expectedType)
    if not player or not itemId then return nil end

    -- 1. Player's own inventory (recursive into bags)
    local inv = player:getInventory()
    if inv then
        local found = findInContainerRecursive(inv, itemId, expectedType, {}, 0)
        if found then return found end
    end

    -- 2. World containers within ~3 tiles
    local cell = getCell and getCell() or nil
    if not cell then return nil end
    local px = math.floor(player:getX())
    local py = math.floor(player:getY())
    local pz = math.floor(player:getZ())
    for dx = -3, 3 do
        for dy = -3, 3 do
            local sq = cell:getGridSquare(px + dx, py + dy, pz)
            if sq then
                local objs = sq:getObjects()
                if objs then
                    for k = 0, objs:size() - 1 do
                        local obj = objs:get(k)
                        local container = obj and obj.getContainer and obj:getContainer() or nil
                        local found = findInContainerRecursive(container, itemId, expectedType, {}, 0)
                        if found then return found end
                    end
                end
            end
        end
    end
    return nil
end

local function getOriginalName(item)
    if not item then return "Item" end
    local script = item.getScriptItem and item:getScriptItem() or nil
    if script and script.getDisplayName then
        return script:getDisplayName()
    end
    return item:getName() or "Item"
end

local function sanitizeName(newName)
    if type(newName) ~= "string" then
        return nil
    end
    newName = string.match(newName, "^%s*(.-)%s*$") or newName
    if #newName > 80 then
        newName = string.sub(newName, 1, 80)
    end
    if #newName == 0 then
        return nil
    end
    return newName
end

local function applyRename(item, newName)
    if not item then return nil end
    newName = sanitizeName(newName)
    if not newName then return nil end
    local md = item:getModData()
    if md and not md["CSR_OriginalItemName"] then
        md["CSR_OriginalItemName"] = getOriginalName(item)
    end
    if item.setCustomName then
        item:setCustomName(true)
    end
    item:setName(newName)
    if md then md["csrCustomName"] = newName end
    if item.syncItemFields then
        item:syncItemFields()
    end
    return newName
end

local function applyReset(item)
    if not item then return nil end
    local md = item:getModData()
    local orig = md and md["CSR_OriginalItemName"]
    if not orig then orig = getOriginalName(item) end
    item:setName(orig)
    if item.setCustomName then
        item:setCustomName(false)
    end
    if md then
        md["csrCustomName"] = nil
        md["CSR_OriginalItemName"] = nil
    end
    if item.syncItemFields then
        item:syncItemFields()
    end
    return orig
end

local function syncRenamedItem(item, player)
    if not item then return end
    if item.transmitModData then
        item:transmitModData()
    end
    if item.transmitCustomName then
        item:transmitCustomName()
    end

    local container = item.getContainer and item:getContainer() or nil
    if container and sendReplaceItemInContainer then
        sendReplaceItemInContainer(container, item, item)
    elseif transmitInventoryItem then
        transmitInventoryItem(item)
    elseif sendItemStats then
        sendItemStats(item)
    end

    if player and player.sendInventory then
        player:sendInventory()
    end
end

local function onClientCommand(module, command, player, args)
    if module ~= "CSR_ItemRename" then return end
    if not player or not args or not args.itemId then return end

    local item = findItemById(player, args.itemId, args.itemType)
    if not item then return end

    local appliedName = nil
    if command == "rename" then
        appliedName = applyRename(item, args.newName)
        if not appliedName then return end
    elseif command == "reset" then
        appliedName = applyReset(item)
    else
        return
    end

    -- Sync item state to all peers
    syncRenamedItem(item, player)

    -- Rebroadcast so other clients re-stamp the display name on items they
    -- already have references to (loot windows, open inventories).
    if sendServerCommand then
        sendServerCommand("CSR_ItemRename", command .. "Applied", {
            itemId = args.itemId,
            itemType = args.itemType,
            newName = appliedName,
        })
    end
end

if Events and Events.OnClientCommand then
    Events.OnClientCommand.Add(onClientCommand)
end

return CSR_ItemRenameServer
