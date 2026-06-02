-- =============================================================================
-- Cat Economy Core — Shared Money Utilities
-- =============================================================================

Cat_EconomyUtils = Cat_EconomyUtils or {}

local MONEY_TYPE = "Base.Money"
local BUNDLE_TYPE = "Base.MoneyBundle"
local BUNDLE_VALUE = 100

--- Count how many of a specific item type are in the inventory.
local function countItems(inv, itemType)
    if not inv then return 0 end
    local count = 0
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item:getFullType() == itemType then
            count = count + 1
        end
    end
    return count
end

--- Count total money value a player is carrying (loose notes + bundles).
function Cat_EconomyUtils.getMoneyCount(player)
    if not player then return 0 end
    local inv = player:getInventory()
    if not inv then return 0 end
    local loose = countItems(inv, MONEY_TYPE)
    local bundles = countItems(inv, BUNDLE_TYPE)
    return loose + (bundles * BUNDLE_VALUE)
end

--- Remove a specific amount of money from the player's inventory.
-- Uses full bundles first, then loose notes. Breaks a bundle if needed
-- to make exact change, giving back loose notes automatically.
-- Returns true if successful, false if not enough money.
function Cat_EconomyUtils.removeMoney(player, amount)
    if not player or amount <= 0 then return true end
    local inv = player:getInventory()
    if not inv then return false end

    local looseCount = countItems(inv, MONEY_TYPE)
    local bundleCount = countItems(inv, BUNDLE_TYPE)
    local totalValue = looseCount + (bundleCount * BUNDLE_VALUE)

    if totalValue < amount then return false end

    local bundlesNeeded = math.floor(amount / BUNDLE_VALUE)
    local looseNeeded = amount % BUNDLE_VALUE

    -- If we need loose notes but don't have enough, break one bundle
    local changeToGive = 0
    if looseNeeded > 0 and looseCount < looseNeeded then
        bundlesNeeded = bundlesNeeded + 1
        changeToGive = BUNDLE_VALUE - looseNeeded
        looseNeeded = 0
    end

    if bundleCount < bundlesNeeded then
        return false
    end

    -- Remove bundles
    for i = 1, bundlesNeeded do
        local item = inv:RemoveOneOf(BUNDLE_TYPE, true)
        if item and isServer() then
            sendRemoveItemFromContainer(inv, item)
        end
    end

    -- Remove loose notes (only if we didn't break a bundle for them)
    if looseNeeded > 0 then
        for i = 1, looseNeeded do
            local item = inv:RemoveOneOf(MONEY_TYPE, true)
            if item and isServer() then
                sendRemoveItemFromContainer(inv, item)
            end
        end
    end

    -- Give back change from broken bundle
    if changeToGive > 0 then
        for i = 1, changeToGive do
            local item = inv:AddItem(MONEY_TYPE)
            if item and isServer() then
                sendAddItemToContainer(inv, item)
            end
        end
    end

    return true
end

--- Give a specific amount of money to the player.
-- Prefers giving MoneyBundle items for every 100, then loose notes.
-- If inventory is full, drops money on the ground at the player's feet.
function Cat_EconomyUtils.giveMoney(player, amount)
    if not player or amount <= 0 then return end
    local inv = player:getInventory()
    if not inv then return end

    local sq = player:getCurrentSquare()
    local bundlesToGive = math.floor(amount / BUNDLE_VALUE)
    local looseToGive = amount % BUNDLE_VALUE

    -- Give bundles
    for i = 1, bundlesToGive do
        local item = inv:AddItem(BUNDLE_TYPE)
        if item then
            if isServer() then
                sendAddItemToContainer(inv, item)
            end
        elseif sq then
            sq:AddWorldInventoryItem(BUNDLE_TYPE, 0, 0, 0)
        end
    end

    -- Give loose notes
    for i = 1, looseToGive do
        local item = inv:AddItem(MONEY_TYPE)
        if item then
            if isServer() then
                sendAddItemToContainer(inv, item)
            end
        elseif sq then
            sq:AddWorldInventoryItem(MONEY_TYPE, 0, 0, 0)
        end
    end
end

print("[Cat_EconomyCore] Shared utilities loaded.")
