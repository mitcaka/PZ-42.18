require "FadedFeastcraft/UI/FFC_MainWindow"
require "ISUI/ISToolTip"

FadedFeastcraft = FadedFeastcraft or {}

local Utils = FadedFeastcraft.Utils
local Actions = FadedFeastcraft.SourceActionIndex

local function attachTooltip(option, description)
    if not option or not ISToolTip then return end
    local ok, tip = pcall(function()
        local created = ISToolTip:new()
        created:initialise()
        created:setVisible(false)
        created.description = description
        return created
    end)
    if ok and tip then
        option.toolTip = tip
    end
end

local function firstInventoryItem(items)
    local seen = {}

    local function visit(value)
        if not value or seen[value] then return nil end
        seen[value] = true

        if value.getFullType then return value end

        if type(value) == "table" then
            if value.items then
                for _, nested in pairs(value.items) do
                    local found = visit(nested)
                    if found then return found end
                end
            end
            for _, nested in pairs(value) do
                local found = visit(nested)
                if found then return found end
            end
        end

        if value.getItems then
            local ok, nestedItems = pcall(function() return value:getItems() end)
            if ok and nestedItems and nestedItems.size and nestedItems.get then
                for i = 0, nestedItems:size() - 1 do
                    local found = visit(nestedItems:get(i))
                    if found then return found end
                end
            end
        end

        return nil
    end

    return visit(items)
end

local function openItem(item)
    FadedFeastcraft.OpenForItem(item)
end

local function addInventoryContext(playerIndex, context, items, test)
    if test or not context then return end
    if not Utils.sbBool("GuiPrimaryMode", true) then return end
    local item = firstInventoryItem(items)
    if not item then return end

    local action = Actions and Actions.actionForItem and Actions.actionForItem(item)
    if not action and not Utils.isFood(item) then return end

    local option = context:addOption("FFC", item, openItem)
    attachTooltip(option, "Open Faded's Feastcraft for this item. Food actions run inside the GUI.")
end

if Events and Events.OnFillInventoryObjectContextMenu and not FadedFeastcraft.InventoryContextBridgeRegistered then
    FadedFeastcraft.InventoryContextBridgeRegistered = true
    Events.OnFillInventoryObjectContextMenu.Add(addInventoryContext)
end

return FadedFeastcraft
