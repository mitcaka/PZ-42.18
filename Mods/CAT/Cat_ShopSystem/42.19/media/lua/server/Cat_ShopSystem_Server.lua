-- =============================================================================
-- Cat Shop System — Server (Shop-ID based, pickup-safe)
-- =============================================================================
if not isServer() then return end

Cat_ShopSystem = Cat_ShopSystem or {}
local MOD_NAME = "Cat_ShopSystem"
local MOD_DATA_KEY = "Cat_ShopData"

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function getShopDataTable()
    return ModData.getOrCreate(MOD_DATA_KEY)
end

local function getShopKey(x, y, z)
    return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end

local CASH_REGISTER_SPRITES = {
    ["location_shop_accessories_01_0"] = true,
    ["location_shop_accessories_01_1"] = true,
    ["location_shop_accessories_01_2"] = true,
    ["location_shop_accessories_01_3"] = true,
    ["location_shop_accessories_01_20"] = true,
    ["location_shop_accessories_01_21"] = true,
}

local function getSpriteName(obj)
    if not obj then return nil end
    local spr = obj:getSprite()
    return spr and spr:getName()
end

local function isCashRegisterObj(obj)
    if not obj then return false end
    local container = obj:getContainer()
    if container and container:getType() == "cashregister" then
        return true
    end
    local sprName = getSpriteName(obj)
    if sprName and CASH_REGISTER_SPRITES[sprName] then
        return true
    end
    return false
end

local function findCashRegister(x, y, z)
    local cell = getCell()
    local sq = cell and cell:getGridSquare(x, y, z)
    if not sq then return nil end
    for i = 0, sq:getObjects():size() - 1 do
        local obj = sq:getObjects():get(i)
        if obj then
            local modData = obj:getModData()
            if modData and (modData.Cat_IsShopRegister or modData.Cat_ShopId) then
                return obj
            end
            if modData and modData.Cat_IsShopShelf then
                return obj
            end
        end
    end
    return nil
end

local function findAnyCashRegister(x, y, z)
    local cell = getCell()
    local sq = cell and cell:getGridSquare(x, y, z)
    if not sq then return nil end
    for i = 0, sq:getObjects():size() - 1 do
        local obj = sq:getObjects():get(i)
        if isCashRegisterObj(obj) then
            return obj
        end
    end
    return nil
end

local function getShopRange()
    if SandboxVars.Cat_ShopSystem and SandboxVars.Cat_ShopSystem.ShopRange ~= nil then
        return SandboxVars.Cat_ShopSystem.ShopRange
    end
    return 2
end

local function isNearObj(player, x, y, z)
    if not player then return false end
    local psq = player:getCurrentSquare()
    if not psq then return false end
    return psq:DistTo(getCell():getGridSquare(x, y, z)) <= getShopRange()
end

-- ---------------------------------------------------------------------------
-- Data model
--   shops[shopId] = { owner, stock, earnings, x, y, z }
--   anchors["x,y,z"] = shopId
--   nextId = number
-- ---------------------------------------------------------------------------
local function migrateOldData(data)
    if data.migrated then return end
    -- Old format: data["x,y,z"] = { owner, stock, earnings }
    -- New format: data.shops[shopId], data.anchors["x,y,z"]
    data.shops = data.shops or {}
    data.anchors = data.anchors or {}
    data.nextId = data.nextId or 1

    local oldKeys = {}
    for key, shop in pairs(data) do
        if type(key) == "string" and key:match("^%-?%d+,%d+,%d$") and type(shop) == "table" then
            table.insert(oldKeys, key)
        end
    end

    for _, key in ipairs(oldKeys) do
        local oldShop = data[key]
        local shopId = "shop_" .. data.nextId
        data.nextId = data.nextId + 1

        local x, y, z = key:match("^(%-?%d+),(%d+),(%d)$")
        data.shops[shopId] = {
            owner = oldShop.owner,
            stock = oldShop.stock or {},
            earnings = oldShop.earnings or 0,
            x = tonumber(x),
            y = tonumber(y),
            z = tonumber(z),
        }
        data.anchors[key] = shopId

        -- Try to stamp the existing register with the new shopId
        local obj = findCashRegister(tonumber(x), tonumber(y), tonumber(z))
        if obj then
            obj:getModData().Cat_ShopId = shopId
            obj:getModData().Cat_ShopOwner = oldShop.owner
            obj:transmitModData()
        end

        data[key] = nil
    end

    data.migrated = true
    print("[Cat_ShopSystem Server] Migrated " .. #oldKeys .. " old shops to shop-ID format.")
end

local function initData()
    local data = getShopDataTable()
    data.shops = data.shops or {}
    data.anchors = data.anchors or {}
    data.nextId = data.nextId or 1
    migrateOldData(data)
    return data
end

local function getShopById(shopId)
    local data = initData()
    return data.shops[shopId]
end

local function getShopIdAt(x, y, z)
    local data = initData()
    return data.anchors[getShopKey(x, y, z)]
end

local function setShopAnchor(shopId, x, y, z)
    local data = initData()
    local shop = data.shops[shopId]
    if not shop then return end
    -- Remove old anchor
    if shop.x ~= nil then
        data.anchors[getShopKey(shop.x, shop.y, shop.z)] = nil
    end
    -- Set new anchor
    shop.x, shop.y, shop.z = x, y, z
    data.anchors[getShopKey(x, y, z)] = shopId
end

-- ---------------------------------------------------------------------------
-- Command handler
-- ---------------------------------------------------------------------------
local function onClientCommand(module, command, player, args)
    if module ~= MOD_NAME then return end

    local username = player:getUsername()
    print("[Cat_ShopSystem Server] Command: " .. tostring(command) .. " user: " .. tostring(username))
    if not username or username == "" then
        print("[Cat_ShopSystem Server] ERROR: username is nil/empty")
        return
    end

    -- -----------------------------------------------------------------------
    -- claimShelf
    -- -----------------------------------------------------------------------
    if command == "claimShelf" then
        local x, y, z = args.x, args.y, args.z
        print("[Cat_ShopSystem Server] claimShelf coords: " .. x .. "," .. y .. "," .. z)

        local obj = findCashRegister(x, y, z)
        if not obj then
            sendServerCommand(player, MOD_NAME, "shopResult", { success = false, error = "No cash register found here." })
            return
        end

        local objModData = obj:getModData()
        local existingShopId = objModData.Cat_ShopId

        -- If this register already has a shopId, reuse it (relocation)
        if existingShopId then
            local shop = getShopById(existingShopId)
            if shop then
                if shop.owner and shop.owner ~= "" and shop.owner ~= username then
                    sendServerCommand(player, MOD_NAME, "shopResult", { success = false, error = "Register already linked to another shop." })
                    return
                end
                -- Reclaim / re-anchor
                shop.owner = username
                setShopAnchor(existingShopId, x, y, z)
                objModData.Cat_ShopOwner = username
                obj:transmitModData()
                sendServerCommand(player, MOD_NAME, "shopResult", {
                    success = true,
                    message = "Shop re-anchored.",
                    shopId = existingShopId,
                    owner = username,
                    stock = shop.stock,
                    earnings = shop.earnings,
                })
                return
            end
        end

        -- Register has no shopId — check for active relocation, then orphaned shop fallback
        local data = initData()

        -- 1) Player pressed Relocate on a specific shop — reliably relink that one
        local playerModData = player:getModData()
        local relocatingShopId = playerModData.Cat_RelocatingShop
        if relocatingShopId then
            local shop = getShopById(relocatingShopId)
            if shop and shop.owner == username then
                -- Clear old anchor
                if shop.x ~= nil then
                    data.anchors[getShopKey(shop.x, shop.y, shop.z)] = nil
                    local oldObj = findCashRegister(shop.x, shop.y, shop.z)
                    if oldObj then
                        local md = oldObj:getModData()
                        md.Cat_ShopId = nil
                        md.Cat_ShopOwner = nil
                        oldObj:transmitModData()
                    end
                end
                -- Anchor here
                setShopAnchor(relocatingShopId, x, y, z)
                objModData.Cat_ShopId = relocatingShopId
                objModData.Cat_ShopOwner = username
                obj:transmitModData()
                playerModData.Cat_RelocatingShop = nil
                sendServerCommand(player, MOD_NAME, "shopResult", {
                    success = true,
                    message = "Shop relocated here.",
                    shopId = relocatingShopId,
                    owner = username,
                    stock = shop.stock,
                    earnings = shop.earnings,
                })
                return
            end
            -- Stale flag, clear it
            playerModData.Cat_RelocatingShop = nil
        end

        -- 2) Fallback: if player has exactly one orphaned shop, auto-relink it
        local orphanedShopId = nil
        for sid, shop in pairs(data.shops) do
            if shop.owner == username then
                local isOrphaned = true
                if shop.x ~= nil then
                    local objAtAnchor = findCashRegister(shop.x, shop.y, shop.z)
                    if objAtAnchor and objAtAnchor:getModData().Cat_ShopId == sid then
                        isOrphaned = false
                    end
                end
                if isOrphaned then
                    if orphanedShopId then
                        orphanedShopId = nil
                        break
                    end
                    orphanedShopId = sid
                end
            end
        end

        if orphanedShopId then
            local shop = data.shops[orphanedShopId]
            setShopAnchor(orphanedShopId, x, y, z)
            objModData.Cat_ShopId = orphanedShopId
            objModData.Cat_ShopOwner = username
            obj:transmitModData()
            sendServerCommand(player, MOD_NAME, "shopResult", {
                success = true,
                message = "Shop re-anchored.",
                shopId = orphanedShopId,
                owner = username,
                stock = shop.stock,
                earnings = shop.earnings,
            })
            return
        end

        -- Create new shop
        local shopId = "shop_" .. data.nextId
        data.nextId = data.nextId + 1
        data.shops[shopId] = {
            owner = username,
            stock = {},
            earnings = 0,
            x = x,
            y = y,
            z = z,
        }
        data.anchors[getShopKey(x, y, z)] = shopId

        objModData.Cat_ShopId = shopId
        objModData.Cat_ShopOwner = username
        obj:transmitModData()

        print("[Cat_ShopSystem Server] claimShelf success: " .. username .. " shopId=" .. shopId)
        sendServerCommand(player, MOD_NAME, "shopResult", {
            success = true,
            message = "Shop claimed.",
            shopId = shopId,
            owner = username,
            stock = {},
            earnings = 0,
        })

    -- -----------------------------------------------------------------------
    -- requestStock
    -- -----------------------------------------------------------------------
    elseif command == "requestStock" then
        local shopId = args.shopId
        local x, y, z = args.x, args.y, args.z

        if not shopId then
            sendServerCommand(player, MOD_NAME, "shopData", { success = false, error = "Invalid shop." })
            return
        end

        local shop = getShopById(shopId)
        if not shop then
            sendServerCommand(player, MOD_NAME, "shopData", { success = false, error = "Shop not found." })
            return
        end

        if not isNearObj(player, x, y, z) then
            sendServerCommand(player, MOD_NAME, "shopData", { success = false, error = "Too far from shop." })
            return
        end

        -- Verify register still has matching shopId at these coords
        local obj = findCashRegister(x, y, z)
        if obj then
            local objModData = obj:getModData()
            if objModData.Cat_ShopId == shopId then
                -- Register moved? Update anchor automatically.
                if shop.x ~= x or shop.y ~= y or shop.z ~= z then
                    setShopAnchor(shopId, x, y, z)
                end
            end
        end

        sendServerCommand(player, MOD_NAME, "shopData", {
            success = true,
            shopId = shopId,
            owner = shop.owner,
            stock = shop.stock or {},
            earnings = shop.earnings or 0,
            isBuyer = shop.isBuyer,
            x = x, y = y, z = z,
        })

    -- -----------------------------------------------------------------------
    -- listItem
    -- -----------------------------------------------------------------------
    elseif command == "listItem" then
        local shopId = args.shopId
        local x, y, z = args.x, args.y, args.z

        if not isNearObj(player, x, y, z) then
            sendServerCommand(player, MOD_NAME, "shopResult", { success = false, error = "Too far from shop." })
            return
        end

        local shop = getShopById(shopId)
        if not shop or shop.owner ~= username then
            sendServerCommand(player, MOD_NAME, "shopResult", { success = false, error = "You do not own this shop." })
            return
        end

        local itemType = args.itemType
        local price = args.price or 1
        local qty = args.qty or 1

        local inv = player:getInventory()
        local items = inv:getItemsFromType(itemType, true)
        if not items or items:size() < qty then
            sendServerCommand(player, MOD_NAME, "shopResult", { success = false, error = "Not enough items in inventory." })
            return
        end

        local removed = 0
        for i = 0, items:size() - 1 do
            if removed >= qty then break end
            local item = items:get(i)
            if item then
                local itemContainer = item:getContainer()
                if itemContainer then
                    itemContainer:Remove(item)
                    sendRemoveItemFromContainer(itemContainer, item)
                end
                removed = removed + 1
            end
        end
        if removed < qty then
            sendServerCommand(player, MOD_NAME, "shopResult", { success = false, error = "Failed to remove items." })
            return
        end

        local stock = shop.stock
        local found = false
        for _, entry in ipairs(stock) do
            if entry.item == itemType and entry.price == price then
                entry.qty = entry.qty + qty
                found = true
                break
            end
        end
        if not found then
            table.insert(stock, { item = itemType, price = price, qty = qty })
        end

        sendServerCommand(player, MOD_NAME, "shopResult", { success = true, message = "Item listed.", stock = stock, earnings = shop.earnings })

    -- -----------------------------------------------------------------------
    -- purchase (cash)
    -- -----------------------------------------------------------------------
    elseif command == "purchase" then
        local shopId = args.shopId
        local x, y, z = args.x, args.y, args.z
        local cart = args.cart or {}

        if not isNearObj(player, x, y, z) then
            sendServerCommand(player, MOD_NAME, "purchaseResult", { success = false, error = "Too far from shop." })
            return
        end

        local shop = getShopById(shopId)
        if not shop or not shop.owner or shop.owner == "" then
            sendServerCommand(player, MOD_NAME, "purchaseResult", { success = false, error = "Shop has no owner." })
            return
        end

        local stock = shop.stock
        local totalCost = 0
        for _, cartItem in ipairs(cart) do
            local found = false
            for _, stockItem in ipairs(stock) do
                if stockItem.item == cartItem.item and stockItem.price == cartItem.price then
                    if stockItem.qty < cartItem.qty then
                        sendServerCommand(player, MOD_NAME, "purchaseResult", { success = false, error = "Not enough stock for " .. cartItem.item })
                        return
                    end
                    totalCost = totalCost + (cartItem.price * cartItem.qty)
                    found = true
                    break
                end
            end
            if not found then
                sendServerCommand(player, MOD_NAME, "purchaseResult", { success = false, error = "Item no longer available: " .. cartItem.item })
                return
            end
        end

        local playerMoney = Cat_EconomyUtils.getMoneyCount(player)
        if playerMoney < totalCost then
            sendServerCommand(player, MOD_NAME, "purchaseResult", { success = false, error = "Not enough money. Need $" .. totalCost })
            return
        end

        if not Cat_EconomyUtils.removeMoney(player, totalCost) then
            sendServerCommand(player, MOD_NAME, "purchaseResult", { success = false, error = "Failed to remove money." })
            return
        end

        local inv = player:getInventory()
        for _, cartItem in ipairs(cart) do
            for i = 1, cartItem.qty do
                local item = inv:AddItem(cartItem.item)
                if item then sendAddItemToContainer(inv, item) end
            end
        end

        for _, cartItem in ipairs(cart) do
            for _, stockItem in ipairs(stock) do
                if stockItem.item == cartItem.item and stockItem.price == cartItem.price then
                    stockItem.qty = stockItem.qty - cartItem.qty
                    break
                end
            end
        end

        local newStock = {}
        for _, stockItem in ipairs(stock) do
            if stockItem.qty > 0 then
                table.insert(newStock, stockItem)
            end
        end
        shop.stock = newStock
        shop.earnings = shop.earnings + totalCost

        sendServerCommand(player, MOD_NAME, "purchaseResult", { success = true, message = "Purchase complete!", stock = newStock, earnings = shop.earnings })

    -- -----------------------------------------------------------------------
    -- purchaseBank
    -- -----------------------------------------------------------------------
    elseif command == "purchaseBank" then
        local shopId = args.shopId
        local x, y, z = args.x, args.y, args.z
        local cart = args.cart or {}

        if not isNearObj(player, x, y, z) then
            sendServerCommand(player, MOD_NAME, "purchaseResult", { success = false, error = "Too far from shop." })
            return
        end

        local shop = getShopById(shopId)
        if not shop or not shop.owner or shop.owner == "" then
            sendServerCommand(player, MOD_NAME, "purchaseResult", { success = false, error = "Shop has no owner." })
            return
        end

        local stock = shop.stock
        local totalCost = 0
        for _, cartItem in ipairs(cart) do
            local found = false
            for _, stockItem in ipairs(stock) do
                if stockItem.item == cartItem.item and stockItem.price == cartItem.price then
                    if stockItem.qty < cartItem.qty then
                        sendServerCommand(player, MOD_NAME, "purchaseResult", { success = false, error = "Not enough stock for " .. cartItem.item })
                        return
                    end
                    totalCost = totalCost + (cartItem.price * cartItem.qty)
                    found = true
                    break
                end
            end
            if not found then
                sendServerCommand(player, MOD_NAME, "purchaseResult", { success = false, error = "Item no longer available: " .. cartItem.item })
                return
            end
        end

        local bankingData = ModData.getOrCreate("Cat_BankingData")
        local accounts = bankingData.accounts or {}
        local account = accounts[username]
        if not account then
            sendServerCommand(player, MOD_NAME, "purchaseResult", { success = false, error = "No bank account. Visit an ATM to open one." })
            return
        end
        if (account.balance or 0) < totalCost then
            sendServerCommand(player, MOD_NAME, "purchaseResult", { success = false, error = "Insufficient funds in bank account. Need $" .. totalCost })
            return
        end

        account.balance = account.balance - totalCost

        local inv = player:getInventory()
        for _, cartItem in ipairs(cart) do
            for i = 1, cartItem.qty do
                local item = inv:AddItem(cartItem.item)
                if item then sendAddItemToContainer(inv, item) end
            end
        end

        for _, cartItem in ipairs(cart) do
            for _, stockItem in ipairs(stock) do
                if stockItem.item == cartItem.item and stockItem.price == cartItem.price then
                    stockItem.qty = stockItem.qty - cartItem.qty
                    break
                end
            end
        end

        local newStock = {}
        for _, stockItem in ipairs(stock) do
            if stockItem.qty > 0 then
                table.insert(newStock, stockItem)
            end
        end
        shop.stock = newStock
        shop.earnings = shop.earnings + totalCost

        sendServerCommand(player, MOD_NAME, "purchaseResult", { success = true, message = "Purchase complete! Paid from bank.", stock = newStock, earnings = shop.earnings })

    -- -----------------------------------------------------------------------
    -- collectEarnings
    -- -----------------------------------------------------------------------
    elseif command == "collectEarnings" then
        local shopId = args.shopId
        local x, y, z = args.x, args.y, args.z

        if not isNearObj(player, x, y, z) then
            sendServerCommand(player, MOD_NAME, "shopResult", { success = false, error = "Too far from shop." })
            return
        end

        local shop = getShopById(shopId)
        if not shop or shop.owner ~= username then
            sendServerCommand(player, MOD_NAME, "shopResult", { success = false, error = "You do not own this shop." })
            return
        end

        local earnings = shop.earnings or 0
        if earnings <= 0 then
            sendServerCommand(player, MOD_NAME, "shopResult", { success = false, error = "No earnings to collect." })
            return
        end

        Cat_EconomyUtils.giveMoney(player, earnings)
        shop.earnings = 0

        sendServerCommand(player, MOD_NAME, "shopResult", { success = true, message = "Collected $" .. earnings .. ".", earnings = 0 })

    -- -----------------------------------------------------------------------
    -- removeStock
    -- -----------------------------------------------------------------------
    elseif command == "removeStock" then
        local shopId = args.shopId
        local x, y, z = args.x, args.y, args.z
        local itemType = args.itemType
        local price = args.price
        local qty = args.qty or 1

        if not isNearObj(player, x, y, z) then
            sendServerCommand(player, MOD_NAME, "shopResult", { success = false, error = "Too far from shop." })
            return
        end

        local shop = getShopById(shopId)
        if not shop or shop.owner ~= username then
            sendServerCommand(player, MOD_NAME, "shopResult", { success = false, error = "You do not own this shop." })
            return
        end

        local stock = shop.stock
        local newStock = {}
        for _, stockItem in ipairs(stock) do
            if stockItem.item == itemType and stockItem.price == price then
                stockItem.qty = stockItem.qty - qty
                if stockItem.qty > 0 then
                    table.insert(newStock, stockItem)
                end
                local inv = player:getInventory()
                for i = 1, qty do
                    local item = inv:AddItem(itemType)
                    if item then sendAddItemToContainer(inv, item) end
                end
            else
                table.insert(newStock, stockItem)
            end
        end
        shop.stock = newStock

        sendServerCommand(player, MOD_NAME, "shopResult", { success = true, message = "Stock removed.", stock = newStock, earnings = shop.earnings })

    -- -----------------------------------------------------------------------
    -- initRegister  (admin initializes a placed cash register)
    -- -----------------------------------------------------------------------
    elseif command == "initRegister" then
        local x, y, z = args.x, args.y, args.z
        local mode = args.mode or "shop"

        local access = player:getAccessLevel()
        if access ~= "admin" and access ~= "Admin" and access ~= "moderator" and access ~= "Moderator" then
            sendServerCommand(player, MOD_NAME, "initRegisterResult", { success = false, error = "Admin access required." })
            return
        end

        local obj = findAnyCashRegister(x, y, z)
        if not obj then
            sendServerCommand(player, MOD_NAME, "initRegisterResult", { success = false, error = "No cash register found at these coordinates." })
            return
        end

        local md = obj:getModData()
        if mode == "buyer" then
            md.Cat_IsBuyerRegister = true
            md.Cat_IsShopRegister = true
            -- Create buyer shop entry immediately
            local data = initData()
            local shopId = "buyer_" .. data.nextId
            data.nextId = data.nextId + 1
            data.shops[shopId] = {
                owner = "SERVER",
                isBuyer = true,
                stock = {},
                earnings = 0,
                x = x,
                y = y,
                z = z,
            }
            data.anchors[getShopKey(x, y, z)] = shopId
            md.Cat_ShopId = shopId
            md.Cat_IsBuyer = true
            obj:transmitModData()
            sendServerCommand(player, MOD_NAME, "initRegisterResult", { success = true, message = "Buyer register initialized.", shopId = shopId })
        else
            md.Cat_IsShopRegister = true
            obj:transmitModData()
            sendServerCommand(player, MOD_NAME, "initRegisterResult", { success = true, message = "Shop register initialized." })
        end

    -- -----------------------------------------------------------------------
    -- setBuyerWanted  (admin sets what a buyer register wants)
    -- -----------------------------------------------------------------------
    elseif command == "setBuyerWanted" then
        local shopId = args.shopId
        local itemType = args.itemType
        local price = args.price or 1
        local qty = args.qty or 1
        local alwaysBuy = args.alwaysBuy or false

        local access = player:getAccessLevel()
        if access ~= "admin" and access ~= "Admin" and access ~= "moderator" and access ~= "Moderator" then
            sendServerCommand(player, MOD_NAME, "shopResult", { success = false, error = "Admin access required." })
            return
        end

        local shop = getShopById(shopId)
        if not shop or not shop.isBuyer then
            sendServerCommand(player, MOD_NAME, "shopResult", { success = false, error = "Buyer register not found." })
            return
        end

        local stock = shop.stock
        local found = false
        for _, entry in ipairs(stock) do
            if entry.item == itemType then
                entry.price = price
                entry.qty = qty
                entry.alwaysBuy = alwaysBuy
                found = true
                break
            end
        end
        if not found then
            table.insert(stock, { item = itemType, price = price, qty = qty, alwaysBuy = alwaysBuy })
        end

        sendServerCommand(player, MOD_NAME, "shopResult", { success = true, message = "Wanted item updated.", stock = stock, earnings = shop.earnings, isBuyer = true })

    -- -----------------------------------------------------------------------
    -- removeBuyerWanted  (admin removes a wanted item)
    -- -----------------------------------------------------------------------
    elseif command == "removeBuyerWanted" then
        local shopId = args.shopId
        local itemType = args.itemType

        local access = player:getAccessLevel()
        if access ~= "admin" and access ~= "Admin" and access ~= "moderator" and access ~= "Moderator" then
            sendServerCommand(player, MOD_NAME, "shopResult", { success = false, error = "Admin access required." })
            return
        end

        local shop = getShopById(shopId)
        if not shop or not shop.isBuyer then
            sendServerCommand(player, MOD_NAME, "shopResult", { success = false, error = "Buyer register not found." })
            return
        end

        local newStock = {}
        for _, entry in ipairs(shop.stock) do
            if entry.item ~= itemType then
                table.insert(newStock, entry)
            end
        end
        shop.stock = newStock

        sendServerCommand(player, MOD_NAME, "shopResult", { success = true, message = "Wanted item removed.", stock = newStock, earnings = shop.earnings, isBuyer = true })

    -- -----------------------------------------------------------------------
    -- sellToBuyer  (player sells items to buyer for cash)
    -- -----------------------------------------------------------------------
    elseif command == "sellToBuyer" then
        local shopId = args.shopId
        local x, y, z = args.x, args.y, args.z
        local cart = args.cart or {}

        if not isNearObj(player, x, y, z) then
            sendServerCommand(player, MOD_NAME, "sellResult", { success = false, error = "Too far from buyer." })
            return
        end

        local shop = getShopById(shopId)
        if not shop or not shop.isBuyer then
            sendServerCommand(player, MOD_NAME, "sellResult", { success = false, error = "Buyer not found." })
            return
        end

        local stock = shop.stock
        local totalEarned = 0

        -- Validate cart against wanted items and player inventory
        for _, cartItem in ipairs(cart) do
            local found = false
            for _, wanted in ipairs(stock) do
                if wanted.item == cartItem.item then
                    if not wanted.alwaysBuy and wanted.qty < cartItem.qty then
                        sendServerCommand(player, MOD_NAME, "sellResult", { success = false, error = "Buyer only wants " .. wanted.qty .. " more " .. cartItem.item })
                        return
                    end
                    totalEarned = totalEarned + (wanted.price * cartItem.qty)
                    found = true
                    break
                end
            end
            if not found then
                sendServerCommand(player, MOD_NAME, "sellResult", { success = false, error = "Buyer is not buying: " .. cartItem.item })
                return
            end
        end

        -- Verify player has items
        local inv = player:getInventory()
        for _, cartItem in ipairs(cart) do
            local items = inv:getItemsFromType(cartItem.item, true)
            if not items or items:size() < cartItem.qty then
                sendServerCommand(player, MOD_NAME, "sellResult", { success = false, error = "Not enough " .. cartItem.item .. " in inventory." })
                return
            end
        end

        -- Remove items from player inventory
        for _, cartItem in ipairs(cart) do
            local items = inv:getItemsFromType(cartItem.item, true)
            local removed = 0
            for i = 0, items:size() - 1 do
                if removed >= cartItem.qty then break end
                local item = items:get(i)
                if item then
                    local itemContainer = item:getContainer()
                    if itemContainer then
                        itemContainer:Remove(item)
                        sendRemoveItemFromContainer(itemContainer, item)
                    end
                    removed = removed + 1
                end
            end
            if removed < cartItem.qty then
                sendServerCommand(player, MOD_NAME, "sellResult", { success = false, error = "Failed to remove items." })
                return
            end
        end

        -- Deduct from buyer wanted quantities (skip for always-buy items)
        for _, cartItem in ipairs(cart) do
            for _, wanted in ipairs(stock) do
                if wanted.item == cartItem.item then
                    if not wanted.alwaysBuy then
                        wanted.qty = wanted.qty - cartItem.qty
                    end
                    break
                end
            end
        end

        -- Clean up zero-quantity entries (keep always-buy items)
        local newStock = {}
        for _, wanted in ipairs(stock) do
            if wanted.alwaysBuy or wanted.qty > 0 then
                table.insert(newStock, wanted)
            end
        end
        shop.stock = newStock

        -- Give money to player
        Cat_EconomyUtils.giveMoney(player, totalEarned)

        sendServerCommand(player, MOD_NAME, "sellResult", { success = true, message = "Sold items for $" .. totalEarned .. ".", stock = newStock, earnings = 0 })

    -- -----------------------------------------------------------------------
    -- sellToBuyerBank  (player sells items to buyer, money goes to bank)
    -- -----------------------------------------------------------------------
    elseif command == "sellToBuyerBank" then
        local shopId = args.shopId
        local x, y, z = args.x, args.y, args.z
        local cart = args.cart or {}

        if not isNearObj(player, x, y, z) then
            sendServerCommand(player, MOD_NAME, "sellResult", { success = false, error = "Too far from buyer." })
            return
        end

        local shop = getShopById(shopId)
        if not shop or not shop.isBuyer then
            sendServerCommand(player, MOD_NAME, "sellResult", { success = false, error = "Buyer not found." })
            return
        end

        local stock = shop.stock
        local totalEarned = 0

        for _, cartItem in ipairs(cart) do
            local found = false
            for _, wanted in ipairs(stock) do
                if wanted.item == cartItem.item then
                    if not wanted.alwaysBuy and wanted.qty < cartItem.qty then
                        sendServerCommand(player, MOD_NAME, "sellResult", { success = false, error = "Buyer only wants " .. wanted.qty .. " more " .. cartItem.item })
                        return
                    end
                    totalEarned = totalEarned + (wanted.price * cartItem.qty)
                    found = true
                    break
                end
            end
            if not found then
                sendServerCommand(player, MOD_NAME, "sellResult", { success = false, error = "Buyer is not buying: " .. cartItem.item })
                return
            end
        end

        local inv = player:getInventory()
        for _, cartItem in ipairs(cart) do
            local items = inv:getItemsFromType(cartItem.item, true)
            if not items or items:size() < cartItem.qty then
                sendServerCommand(player, MOD_NAME, "sellResult", { success = false, error = "Not enough " .. cartItem.item .. " in inventory." })
                return
            end
        end

        for _, cartItem in ipairs(cart) do
            local items = inv:getItemsFromType(cartItem.item, true)
            local removed = 0
            for i = 0, items:size() - 1 do
                if removed >= cartItem.qty then break end
                local item = items:get(i)
                if item then
                    local itemContainer = item:getContainer()
                    if itemContainer then
                        itemContainer:Remove(item)
                        sendRemoveItemFromContainer(itemContainer, item)
                    end
                    removed = removed + 1
                end
            end
            if removed < cartItem.qty then
                sendServerCommand(player, MOD_NAME, "sellResult", { success = false, error = "Failed to remove items." })
                return
            end
        end

        for _, cartItem in ipairs(cart) do
            for _, wanted in ipairs(stock) do
                if wanted.item == cartItem.item then
                    if not wanted.alwaysBuy then
                        wanted.qty = wanted.qty - cartItem.qty
                    end
                    break
                end
            end
        end

        local newStock = {}
        for _, wanted in ipairs(stock) do
            if wanted.alwaysBuy or wanted.qty > 0 then
                table.insert(newStock, wanted)
            end
        end
        shop.stock = newStock

        -- Deposit to bank
        local bankingData = ModData.getOrCreate("Cat_BankingData")
        local accounts = bankingData.accounts or {}
        local account = accounts[username]
        if not account then
            sendServerCommand(player, MOD_NAME, "sellResult", { success = false, error = "No bank account. Visit an ATM to open one." })
            return
        end
        account.balance = (account.balance or 0) + totalEarned

        sendServerCommand(player, MOD_NAME, "sellResult", { success = true, message = "Sold items for $" .. totalEarned .. " (deposited to bank).", stock = newStock, earnings = 0 })

    -- -----------------------------------------------------------------------
    -- relocateShop  (owner clears old anchor so they can reclaim elsewhere)
    -- -----------------------------------------------------------------------
    elseif command == "relocateShop" then
        local shopId = args.shopId
        local shop = getShopById(shopId)
        if not shop or shop.owner ~= username then
            sendServerCommand(player, MOD_NAME, "shopResult", { success = false, error = "You do not own this shop." })
            return
        end

        -- Clear old anchor, but keep shop data
        local data = initData()
        if shop.x ~= nil then
            data.anchors[getShopKey(shop.x, shop.y, shop.z)] = nil
        end
        -- Try to clear modData on old register
        local oldObj = findCashRegister(shop.x or 0, shop.y or 0, shop.z or 0)
        if oldObj then
            local md = oldObj:getModData()
            md.Cat_ShopId = nil
            md.Cat_ShopOwner = nil
            oldObj:transmitModData()
        end
        shop.x, shop.y, shop.z = nil, nil, nil

        -- Mark this shop as being relocated by this player
        local playerModData = player:getModData()
        playerModData.Cat_RelocatingShop = shopId

        sendServerCommand(player, MOD_NAME, "shopResult", { success = true, message = "Shop unanchored. Place and claim a new register to relocate." })
    end
end

Events.OnClientCommand.Add(onClientCommand)

print("[Cat_ShopSystem Server] Loaded (shop-ID based).")
