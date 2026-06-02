-- =============================================================================
-- Cat Economy Core — Shared Money Utilities
-- =============================================================================

Cat_EconomyUtils = Cat_EconomyUtils or {}

-- Denominations in descending order for greedy algorithms.
-- Base.MoneyBundle is treated as $100, new notes as their face value,
-- and Base.Money (the vanilla single bill) as $1.
local DENOMINATIONS = {
    { type = "Base.MoneyBundle", value = 100 },
    { type = "Base.MoneyFifty",  value = 50 },
    { type = "Base.MoneyTwenty", value = 20 },
    { type = "Base.MoneyTen",    value = 10 },
    { type = "Base.MoneyFive",   value = 5 },
    { type = "Base.Money",       value = 1 },
}

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

--- Count total money value a player is carrying (all denominations).
function Cat_EconomyUtils.getMoneyCount(player)
    if not player then return 0 end
    local inv = player:getInventory()
    if not inv then return 0 end
    local total = 0
    for _, denom in ipairs(DENOMINATIONS) do
        total = total + countItems(inv, denom.type) * denom.value
    end
    return total
end

--- Remove a specific amount of money from the player's inventory.
-- Uses a greedy approach, removing the largest denominations first.
-- If exact change cannot be made with available notes, a larger note or
-- bundle is broken and optimal change is given back automatically.
-- Returns true if successful, false if not enough money.
function Cat_EconomyUtils.removeMoney(player, amount)
    if not player or amount <= 0 then return true end
    local inv = player:getInventory()
    if not inv then return false end

    -- Count available money by denomination
    local counts = {}
    local totalValue = 0
    for _, denom in ipairs(DENOMINATIONS) do
        counts[denom.type] = countItems(inv, denom.type)
        totalValue = totalValue + counts[denom.type] * denom.value
    end

    if totalValue < amount then return false end

    local remaining = amount

    -- Greedily remove from largest to smallest
    for _, denom in ipairs(DENOMINATIONS) do
        while remaining >= denom.value and counts[denom.type] > 0 do
            local item = inv:RemoveOneOf(denom.type, true)
            if item then
                if isServer() then
                    sendRemoveItemFromContainer(inv, item)
                end
                remaining = remaining - denom.value
                counts[denom.type] = counts[denom.type] - 1
            else
                break
            end
        end
    end

    -- If we still need more, remove the largest available item and give change
    while remaining > 0 do
        local removed = false
        for _, denom in ipairs(DENOMINATIONS) do
            if counts[denom.type] > 0 then
                local item = inv:RemoveOneOf(denom.type, true)
                if item then
                    if isServer() then
                        sendRemoveItemFromContainer(inv, item)
                    end
                    remaining = remaining - denom.value
                    counts[denom.type] = counts[denom.type] - 1

                    -- Give back change if we overshot
                    if remaining < 0 then
                        local change = -remaining
                        for _, d in ipairs(DENOMINATIONS) do
                            local changeCount = math.floor(change / d.value)
                            for i = 1, changeCount do
                                local changeItem = inv:AddItem(d.type)
                                if changeItem then
                                    if isServer() then
                                        sendAddItemToContainer(inv, changeItem)
                                    end
                                end
                            end
                            change = change % d.value
                        end
                        remaining = 0
                    end
                    removed = true
                end
                break
            end
        end

        if not removed then
            return false
        end
    end

    return true
end

--- Give a specific amount of money to a container (e.g. a wallet).
-- Uses a greedy approach, giving the largest denominations first to keep
-- the number of items low.
function Cat_EconomyUtils.giveMoneyToContainer(container, amount)
    if not container or amount <= 0 then return end

    for _, denom in ipairs(DENOMINATIONS) do
        local count = math.floor(amount / denom.value)
        for i = 1, count do
            container:AddItem(denom.type)
        end
        amount = amount % denom.value
    end
end

--- Give a specific amount of money to the player.
-- Uses a greedy approach, giving the largest denominations first to keep
-- the number of items low. If inventory is full, drops money on the
-- ground at the player's feet.
function Cat_EconomyUtils.giveMoney(player, amount)
    if not player or amount <= 0 then return end
    local inv = player:getInventory()
    if not inv then return end

    local sq = player:getCurrentSquare()

    for _, denom in ipairs(DENOMINATIONS) do
        local count = math.floor(amount / denom.value)
        for i = 1, count do
            local item = inv:AddItem(denom.type)
            if item then
                if isServer() then
                    sendAddItemToContainer(inv, item)
                end
            elseif sq then
                sq:AddWorldInventoryItem(denom.type, 0, 0, 0)
            end
        end
        amount = amount % denom.value
    end
end

print("[Cat_EconomyCore] Shared utilities loaded.")
