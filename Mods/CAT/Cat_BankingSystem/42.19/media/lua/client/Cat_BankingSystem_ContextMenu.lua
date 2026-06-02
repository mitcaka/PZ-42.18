-- =============================================================================
-- Cat Banking System — ATM Context Menu
-- =============================================================================
if isServer() then return end

local MOD_NAME = "Cat_BankingSystem"

local ATM_SPRITES = {
    ["location_business_bank_01_64"] = true,
    ["location_business_bank_01_65"] = true,
    ["location_business_bank_01_66"] = true,
    ["location_business_bank_01_67"] = true,
}

local CC_TYPES = {
    ["Base.CreditCard"] = true,
    ["Base.CreditCard_Stolen"] = true,
}

local function isATM(obj)
    if not obj then return false end
    local sprite = obj:getSprite()
    if not sprite then return false end
    local name = sprite:getName()
    return name and ATM_SPRITES[name] == true
end

local function playerHasCreditCard(player)
    local inv = player:getInventory()
    if not inv then return false end
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and CC_TYPES[item:getFullType()] then
            return true
        end
    end
    return false
end

local function playerHasDecoder(player)
    local inv = player:getInventory()
    if not inv then return false end
    return inv:contains("Base.Cat_CardDecoder")
end

local function getFirstCreditCard(player)
    local inv = player:getInventory()
    if not inv then return nil, nil end
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and CC_TYPES[item:getFullType()] then
            return item:getName(), item:getFullType()
        end
    end
    return nil, nil
end

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    local foundATM = false
    for _, obj in ipairs(worldObjects) do
        if isATM(obj) then
            foundATM = true
            break
        end
    end

    if not foundATM then
        -- Also scan nearby squares for placed moveables that might not appear in worldObjects
        local psq = player:getCurrentSquare()
        local cell = getCell()
        if psq and cell then
            for dx = -3, 3 do
                for dy = -3, 3 do
                    local sq = cell:getGridSquare(psq:getX() + dx, psq:getY() + dy, psq:getZ())
                    if sq then
                        for i = 0, sq:getObjects():size() - 1 do
                            local obj = sq:getObjects():get(i)
                            if isATM(obj) then
                                foundATM = true
                                break
                            end
                        end
                    end
                    if foundATM then break end
                end
                if foundATM then break end
            end
        end
    end

    if not foundATM then return end

    -- Banking submenu
    local bankingOption = context:addOption("Banking")
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(bankingOption, subMenu)

    subMenu:addOption("Use ATM", playerNum, function(pNum)
        require "Cat_BankingSystem_PinUI"
        Cat_ATMPinUI.Open(pNum)
    end)

    if playerHasCreditCard(player) then
        subMenu:addOption("Use Credit Card", playerNum, function(pNum)
            local cardName, cardType = getFirstCreditCard(getSpecificPlayer(pNum))
            if cardName and cardType then
                require "Cat_BankingSystem_PinUI"
                Cat_ATMPinUI.OpenCreditCard(pNum, cardName, cardType)
            end
        end)

        if playerHasDecoder(player) then
            subMenu:addOption("Hack Credit Card", playerNum, function(pNum)
                local cardName, cardType = getFirstCreditCard(getSpecificPlayer(pNum))
                if cardName and cardType then
                    require "Cat_BankingSystem_HackUI"
                    Cat_ATMHackUI.Open(cardName, cardType)
                end
            end)
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
print("[Cat_BankingSystem Client] Context menu loaded.")
