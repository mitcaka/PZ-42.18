require "CSR_FeatureFlags"
require "CSR_Utils"

--[[
    CSR_ItemRename.lua
    Adds "Rename" to the right-click context menu of any inventory item.
    Uses setCustomName(true) + setName() to persist the custom name across saves.
    Includes "Reset Name" to revert to the original script-defined name.
]]

CSR_ItemRename = CSR_ItemRename or {}

local function getFirstItem(items)
    if CSR_Utils and CSR_Utils.resolveInventorySelection then
        items = CSR_Utils.resolveInventorySelection(items)
    elseif ISInventoryPane and ISInventoryPane.getActualItems then
        items = ISInventoryPane.getActualItems(items)
    end
    if items and #items > 0 then
        return items[1]
    end
    return nil
end

local function getOriginalName(item)
    if not item then return "Item" end
    local scriptItem = item:getScriptItem()
    if scriptItem and scriptItem.getDisplayName then
        return scriptItem:getDisplayName()
    end
    return item:getName() or "Item"
end

local function getDialogText(dialog)
    if not dialog then return nil end
    if dialog.entry and dialog.entry.getText then
        return dialog.entry:getText()
    end
    if dialog.getText then
        return dialog:getText()
    end
    return nil
end

local function syncRenamedItem(item)
    if not item then return end
    if item.syncItemFields then
        item:syncItemFields()
    end
    if item.transmitModData then
        item:transmitModData()
    end
    if item.transmitCustomName then
        item:transmitCustomName()
    end
end

local function refreshInventoryWindows(player)
    if not player or not player.getPlayerNum then return end
    local pdata = getPlayerData and getPlayerData(player:getPlayerNum()) or nil
    if not pdata then return end
    if pdata.playerInventory and pdata.playerInventory.refreshBackpacks then
        pdata.playerInventory:refreshBackpacks()
    end
    if pdata.lootInventory and pdata.lootInventory.refreshBackpacks then
        pdata.lootInventory:refreshBackpacks()
    end
end

local function onRenameItem(player, item)
    if not player or not item then return end

    local currentName = item:getName() or ""
    local playerNum = player.getPlayerNum and player:getPlayerNum() or nil
    local modal = ISTextBox:new(0, 0, 280, 180, "Enter new name:", currentName, nil,
        function(target, button, obj)
            if button and button.internal == "OK" then
                obj = obj or target
                if not obj or not obj.getModData then return end
                local newName = getDialogText(button.parent)
                if newName and newName ~= "" then
                    -- Sanitize: strip leading/trailing whitespace, limit length
                    newName = string.match(newName, "^%s*(.-)%s*$") or newName
                    if #newName > 80 then
                        newName = string.sub(newName, 1, 80)
                    end
                    if #newName > 0 then
                        -- Store original name for reset
                        local modData = obj:getModData()
                        if not modData["CSR_OriginalItemName"] then
                            modData["CSR_OriginalItemName"] = getOriginalName(obj)
                        end
                        if obj.setCustomName then
                            obj:setCustomName(true)
                        end
                        obj:setName(newName)
                        -- Stamp modData so the name survives MP transmission
                        -- (vanilla setName/setCustomName do not propagate over the
                        -- network reliably; modData does).
                        modData["csrCustomName"] = newName
                        syncRenamedItem(obj)
                        refreshInventoryWindows(player)

                        -- MP sync
                        if isClient() then
                            sendClientCommand(player, "CSR_ItemRename", "rename", {
                                itemId = obj:getID(),
                                itemType = obj.getFullType and obj:getFullType() or nil,
                                newName = newName,
                            })
                        end
                    end
                end
            end
        end, playerNum, item)
    modal:setValidateFunction(nil, function(_, str)
        return str and #str > 0 and #str <= 80
    end)
    if modal.setValidateTooltipText then
        modal:setValidateTooltipText(getText("IGUI_PlayerText_ItemNameTooLong", 80))
    end
    modal.obj = item
    modal:initialise()
    modal:addToUIManager()
end

local function onResetName(player, item)
    if not player or not item then return end

    local modData = item:getModData()
    local origName = modData["CSR_OriginalItemName"]
    if not origName then
        origName = getOriginalName(item)
    end

    item:setName(origName)
    if item.setCustomName then
        item:setCustomName(false)
    end
    modData["CSR_OriginalItemName"] = nil
    modData["csrCustomName"] = nil
    syncRenamedItem(item)
    refreshInventoryWindows(player)

    -- MP sync
    if isClient() then
        sendClientCommand(player, "CSR_ItemRename", "reset", {
            itemId = item:getID(),
            itemType = item.getFullType and item:getFullType() or nil,
        })
    end
end

function CSR_ItemRename.addContextOption(playerNum, context, items)
    if not CSR_FeatureFlags or not CSR_FeatureFlags.isItemRenameEnabled then return end
    if not CSR_FeatureFlags.isItemRenameEnabled() then return end

    local item = getFirstItem(items)
    if not item then return end

    local player = getSpecificPlayer(playerNum)
    if not player then return end

    context:addOption(getText("ContextMenu_CSR_RenameItem") or "Rename Item", player, onRenameItem, item)

    -- Show "Reset Name" if item has a custom name
    local modData = item:getModData()
    if modData["CSR_OriginalItemName"] then
        context:addOption(getText("ContextMenu_CSR_ResetItemName") or "Reset Item Name", player, onResetName, item)
    end
end

if Events and Events.OnFillInventoryObjectContextMenu then
    Events.OnFillInventoryObjectContextMenu.Add(CSR_ItemRename.addContextOption)
end

-- ──────────────────────────────────────────────────────────────
-- MP reapply: items synced from server arrive with modData intact
-- but their live name (setName) may not have transferred. Re-stamp
-- the display name from modData.csrCustomName whenever a loot or
-- inventory window refreshes. Cheap O(visible items) per refresh.
-- ──────────────────────────────────────────────────────────────
local REAPPLY_MAX_DEPTH = 4

local function reapplyContainerNames(container, seen, depth)
    if not container or not container.getItems then return end
    seen = seen or {}
    depth = depth or 0
    if depth > REAPPLY_MAX_DEPTH or seen[container] then return end
    seen[container] = true

    local items = container:getItems()
    if not items then return end
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it.getModData then
            local md = it:getModData()
            local custom = md and md["csrCustomName"]
            if custom and custom ~= "" and it:getName() ~= custom then
                if it.setCustomName then
                    it:setCustomName(true)
                end
                it:setName(custom)
            end
            local nested = it.getInventory and it:getInventory() or nil
            if nested then
                reapplyContainerNames(nested, seen, depth + 1)
            end
        end
    end
end

local function onRefreshContainersForRename(inventoryPage, stage)
    if stage ~= "buttonsAdded" then return end
    if not inventoryPage or not inventoryPage.backpacks then return end
    for _, bp in ipairs(inventoryPage.backpacks) do
        local container = bp and bp.inventory or nil
        if container then
            reapplyContainerNames(container)
        end
    end
end

if Events and Events.OnRefreshInventoryWindowContainers then
    Events.OnRefreshInventoryWindowContainers.Add(onRefreshContainersForRename)
end

-- Server rebroadcasts after applying a rename so peers also re-stamp.
local function onServerCommand(module, command, args)
    if module ~= "CSR_ItemRename" then return end
    if not args or not args.itemId then return end
    local p = getPlayer and getPlayer() or nil
    if not p then return end
    -- Walk the player's own inventory; modData on remote items will already
    -- have csrCustomName set, the next OnRefresh will pick it up. We only
    -- need to reapply to items currently shown to *this* client.
    local inv = p:getInventory()
    if inv then reapplyContainerNames(inv) end
    local loot = getPlayerLoot and getPlayerLoot(p:getPlayerNum()) or nil
    local page = loot and (loot.inventoryPage or loot) or nil
    if page and page.backpacks then
        for _, bp in ipairs(page.backpacks) do
            local container = bp and bp.inventory or nil
            if container then reapplyContainerNames(container) end
        end
    end
end

if Events and Events.OnServerCommand then
    Events.OnServerCommand.Add(onServerCommand)
end

return CSR_ItemRename
