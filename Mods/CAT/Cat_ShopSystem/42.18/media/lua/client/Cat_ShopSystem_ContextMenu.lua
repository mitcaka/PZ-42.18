-- =============================================================================
-- Cat Shop System — Context Menu (Shop & Buyer Register hooks)
-- =============================================================================
if isServer() then return end

local MOD_NAME = "Cat_ShopSystem"

-- Known cash register sprite names
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

local function isCashRegister(obj)
    if not obj then return false end
    local container = obj:getContainer()
    if container and container:getType() == "cashregister" then
        return true
    end
    local sprName = getSpriteName(obj)
    if sprName and CASH_REGISTER_SPRITES[sprName] then
        return true
    end
    local modData = obj:getModData()
    if modData and modData.Cat_IsShopShelf then
        return true
    end
    return false
end

local function isShopRegister(obj)
    if not obj then return false end
    local modData = obj:getModData()
    return modData and (modData.Cat_IsShopRegister or modData.Cat_ShopId)
end

local function isBuyerRegister(obj)
    if not obj then return false end
    local modData = obj:getModData()
    return modData and (modData.Cat_IsBuyerRegister or (modData.Cat_ShopId and modData.Cat_IsBuyer))
end

local function isPlayerAdmin(player)
    if not player then return false end
    local access = player:getAccessLevel()
    if access == "admin" or access == "Admin" then return true end
    if access == "moderator" or access == "Moderator" then return true end
    if isAdmin and isAdmin() then return true end
    if isDebugEnabled and isDebugEnabled() then return true end
    return false
end

local function getLocalUsername(player)
    if not player then player = getSpecificPlayer(0) end
    if not player then return nil end
    local name = player:getUsername()
    if name and name ~= "" then return name end
    return nil
end

local function getShopRange()
    if SandboxVars.Cat_ShopSystem and SandboxVars.Cat_ShopSystem.ShopRange ~= nil then
        return SandboxVars.Cat_ShopSystem.ShopRange
    end
    return 2
end

-- Scan a specific square for cash registers
local function scanSquareForRegister(sq)
    if not sq then return nil end
    for i = 0, sq:getObjects():size() - 1 do
        local obj = sq:getObjects():get(i)
        if isCashRegister(obj) then
            return obj
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- World context menu hook
-- ---------------------------------------------------------------------------
local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    local shopObj = nil
    local buyerObj = nil
    local cashObj = nil

    -- Try worldObjects first
    if worldObjects then
        for _, obj in ipairs(worldObjects) do
            if isBuyerRegister(obj) then
                buyerObj = obj
                break
            end
            if isShopRegister(obj) then
                shopObj = obj
                break
            end
            if isCashRegister(obj) then
                cashObj = obj
            end
        end
    end

    -- Aggressive fallback: scan all squares within range of the player
    if not shopObj and not buyerObj and not cashObj then
        local psq = player:getCurrentSquare()
        if psq then
            local cell = getCell()
            local px, py, pz = psq:getX(), psq:getY(), psq:getZ()
            local range = getShopRange()
            for dx = -range, range do
                for dy = -range, range do
                    local sq = cell:getGridSquare(px + dx, py + dy, pz)
                    local found = scanSquareForRegister(sq)
                    if found then
                        cashObj = found
                        break
                    end
                end
                if cashObj then break end
            end
        end
    end

    -- Admin initialization options for unclaimed registers
    -- White register sprites = seller, black register sprites = buyer
    if not shopObj and not buyerObj and cashObj and isPlayerAdmin(player) then
        local sq = cashObj:getSquare()
        local x, y, z = sq:getX(), sq:getY(), sq:getZ()
        local sprName = getSpriteName(cashObj)
        local isBlack = sprName and (sprName == "location_shop_accessories_01_20" or sprName == "location_shop_accessories_01_21")
        local isWhite = sprName and (sprName == "location_shop_accessories_01_0" or sprName == "location_shop_accessories_01_1" or sprName == "location_shop_accessories_01_2" or sprName == "location_shop_accessories_01_3")

        if isBlack then
            context:addOption("[Admin] Initialize Buyer Register", { x = x, y = y, z = z, mode = "buyer" }, function(data)
                sendClientCommand(MOD_NAME, "initRegister", data)
            end)
        elseif isWhite then
            context:addOption("[Admin] Initialize Shop Register", { x = x, y = y, z = z, mode = "shop" }, function(data)
                sendClientCommand(MOD_NAME, "initRegister", data)
            end)
        else
            -- Unknown sprite — show both options
            local sub = context:getNew(context)
            context:addSubMenu(context:addOption("[Admin] Initialize Register"), sub)
            sub:addOption("As Shop (Seller)", { x = x, y = y, z = z, mode = "shop" }, function(data)
                sendClientCommand(MOD_NAME, "initRegister", data)
            end)
            sub:addOption("As Buyer", { x = x, y = y, z = z, mode = "buyer" }, function(data)
                sendClientCommand(MOD_NAME, "initRegister", data)
            end)
        end
        return
    end

    -- Buyer register (admin-only)
    if buyerObj then
        local sq = buyerObj:getSquare()
        local x, y, z = sq:getX(), sq:getY(), sq:getZ()
        local modData = buyerObj:getModData()
        local shopId = modData.Cat_ShopId

        if isPlayerAdmin(player) then
            context:addOption("Manage Buyer", { x = x, y = y, z = z, shopId = shopId, isBuyer = true }, function(data)
                require "Cat_ShopSystem_00_UI"
                Cat_ShopSystem.OpenShopUI(data.x, data.y, data.z, data.shopId, true)
            end)
        else
            context:addOption("Sell Items", { x = x, y = y, z = z, shopId = shopId, isBuyer = true }, function(data)
                require "Cat_ShopSystem_00_UI"
                Cat_ShopSystem.OpenShopUI(data.x, data.y, data.z, data.shopId, true)
            end)
        end
        return
    end

    -- Seller register
    if shopObj then
        local sq = shopObj:getSquare()
        local x, y, z = sq:getX(), sq:getY(), sq:getZ()
        local modData = shopObj:getModData()
        local shopId = modData.Cat_ShopId
        local owner = modData.Cat_ShopOwner
        local playerUsername = getLocalUsername(player)

        if not owner or owner == "" then
            context:addOption("Claim Shop", { x = x, y = y, z = z }, function(data)
                require "Cat_ShopSystem_00_UI"
                Cat_ShopSystem.OpenShopUI(data.x, data.y, data.z, nil)
            end)
        elseif playerUsername and owner == playerUsername then
            context:addOption("Manage Shop", { x = x, y = y, z = z, shopId = shopId }, function(data)
                require "Cat_ShopSystem_00_UI"
                Cat_ShopSystem.OpenShopUI(data.x, data.y, data.z, data.shopId)
            end)
        else
            context:addOption("Open Shop", { x = x, y = y, z = z, shopId = shopId }, function(data)
                require "Cat_ShopSystem_00_UI"
                Cat_ShopSystem.OpenShopUI(data.x, data.y, data.z, data.shopId)
            end)
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

-- ---------------------------------------------------------------------------
-- Server response handling (global listener)
-- ---------------------------------------------------------------------------
local function onServerCommand(module, command, args)
    if module ~= MOD_NAME then return end

    if command == "shopData" then
        if Cat_ShopSystem and Cat_ShopSystem.OnShopData then
            Cat_ShopSystem.OnShopData(args)
        end
    elseif command == "shopResult" then
        if Cat_ShopSystem and Cat_ShopSystem.OnShopResult then
            Cat_ShopSystem.OnShopResult(args)
        end
    elseif command == "purchaseResult" then
        if Cat_ShopSystem and Cat_ShopSystem.OnPurchaseResult then
            Cat_ShopSystem.OnPurchaseResult(args)
        end
    elseif command == "sellResult" then
        if Cat_ShopSystem and Cat_ShopSystem.OnSellResult then
            Cat_ShopSystem.OnSellResult(args)
        end
    elseif command == "initShopRegisterResult" or command == "initRegisterResult" then
        local p = getSpecificPlayer(0)
        if p and p.setHaloNote then
            if args and args.success then
                p:setHaloNote(args.message or "Register initialized.", 100, 255, 100, 1500)
            else
                p:setHaloNote(args and args.error or "Failed to initialize register.", 255, 100, 100, 1500)
            end
        end
    end
end
Events.OnServerCommand.Add(onServerCommand)

-- ---------------------------------------------------------------------------
-- Keybind: press 'END' to open nearest shop
-- ---------------------------------------------------------------------------
local function onKeyStartPressed(key)
    if key ~= Keyboard.KEY_END then return end

    local player = getSpecificPlayer(0)
    if not player then return end

    local psq = player:getCurrentSquare()
    if not psq then return end

    local px, py, pz = psq:getX(), psq:getY(), psq:getZ()
    local cell = getCell()
    local range = getShopRange()
    local bestDist = range + 1
    local bestObj = nil

    for dx = -range, range do
        for dy = -range, range do
            local sq = cell:getGridSquare(px + dx, py + dy, pz)
            if sq then
                for i = 0, sq:getObjects():size() - 1 do
                    local obj = sq:getObjects():get(i)
                    if obj then
                        local modData = obj:getModData()
                        if modData and modData.Cat_ShopId then
                            local dist = psq:DistTo(sq)
                            if dist < bestDist then
                                bestDist = dist
                                bestObj = obj
                            end
                        end
                    end
                end
            end
        end
    end

    if bestObj then
        local sq = bestObj:getSquare()
        local shopId = bestObj:getModData().Cat_ShopId
        local isBuyer = bestObj:getModData().Cat_IsBuyerRegister or bestObj:getModData().Cat_IsBuyer
        require "Cat_ShopSystem_00_UI"
        if isBuyer then
            Cat_ShopSystem.OpenSellerUI(sq:getX(), sq:getY(), sq:getZ(), shopId)
        else
            Cat_ShopSystem.OpenShopUI(sq:getX(), sq:getY(), sq:getZ(), shopId)
        end
        sendClientCommand(MOD_NAME, "requestStock", { x = sq:getX(), y = sq:getY(), z = sq:getZ(), shopId = shopId })
    else
        if player and player.setHaloNote then
            player:setHaloNote("No shop register nearby.", 255, 100, 100, 1000)
        end
    end
end
Events.OnKeyStartPressed.Add(onKeyStartPressed)

print("[Cat_ShopSystem Client] Context menu + keybind loaded. Press END to open nearest shop.")
