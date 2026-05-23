--[[
    CSR_FarmingMenuSafety.lua

    Vanilla ISFarmingMenu.getShovel calls
        playerInv:getFirstEvalRecurse(predicateDigPlow)
    where predicateDigPlow does `item:hasTag(ItemTag.DIG_PLOW)`.

    InventoryItem.hasTag(String) is not bound on every B42.17 subclass
    (Clothing, ComboItem, Food, Padlock, ...). When the recursion lands on
    one of those, the Java side throws "No implementation found for
    function: hasTag", which then trips Kahlua's "Cannot assign field
    callFrame because a is null" inside ReturnValues.put -- corrupting the
    surrounding ISWorldObjectContextMenu.createMenu call frame and breaking
    every claim / faction / world context menu that ran through it.

    Fix: replace getShovel with a pure Lua inventory walk that reads
    ScriptItem tags. This avoids both InventoryItem.hasTag(String) and
    B42.17's brittle getAllTagRecurse overloads inside right-click menus.
]]

local DIG_PLOW_TAGS = {
    "base:digplow",
    "digplow",
}

local function tagListContains(tags, tag)
    if not tags or not tags.contains or not tag then return false end
    local ok, has = pcall(function() return tags:contains(tag) end)
    return ok and has == true
end

local function hasDigPlowTag(item)
    if not item or not item.getScriptItem then return false end
    local scriptItem = item:getScriptItem()
    if not scriptItem or not scriptItem.getTags then return false end
    local tags = scriptItem:getTags()
    if not tags then return false end

    if ItemTag and ItemTag.DIG_PLOW and tagListContains(tags, ItemTag.DIG_PLOW) then
        return true
    end
    for i = 1, #DIG_PLOW_TAGS do
        if tagListContains(tags, DIG_PLOW_TAGS[i]) then
            return true
        end
    end
    return false
end

local function isUsableShovel(item)
    return item and item.isBroken and not item:isBroken() and hasDigPlowTag(item)
end

local function findDigPlowItem(container, visited)
    if not container or visited[container] then return nil end
    visited[container] = true

    local items = container.getItems and container:getItems() or nil
    if not items then return nil end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if isUsableShovel(item) then
            return item
        end
        local subInventory = item and item.getInventory and item:getInventory() or nil
        local found = findDigPlowItem(subInventory, visited)
        if found then return found end
    end
    return nil
end

local function safeGetShovel(player)
    if not player then return nil end
    local inv = player:getInventory()
    if not inv then return nil end

    -- Prefer the currently equipped hand item if it qualifies.
    local handItem = player:getPrimaryHandItem()
    if isUsableShovel(handItem) then
        return handItem
    end

    return findDigPlowItem(inv, {})
end

local function patchGetShovel()
    if not ISFarmingMenu then return end
    if ISFarmingMenu.__csr_get_shovel_safe then return end
    ISFarmingMenu.__csr_get_shovel_safe = true
    ISFarmingMenu.getShovel = safeGetShovel
end

patchGetShovel()
Events.OnGameStart.Add(patchGetShovel)
Events.OnCreatePlayer.Add(function() patchGetShovel() end)
Events.OnFillWorldObjectContextMenu.Add(function() patchGetShovel() end)
