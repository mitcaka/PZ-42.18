-- =============================================================================
-- Cat Shop System — Owner & Buyer UIs
-- =============================================================================
if isServer() then return end

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"

Cat_ShopSystem = Cat_ShopSystem or {}
local MOD_NAME = "Cat_ShopSystem"

local ICON_SIZE = 20
local ICON_PAD = 4
local TEXT_OFFSET = ICON_SIZE + ICON_PAD * 2

function Cat_ShopSystem.GetItemTexture(fullType)
    if not Cat_ShopSystem._textureCache then
        Cat_ShopSystem._textureCache = {}
    end
    if Cat_ShopSystem._textureCache[fullType] ~= nil then
        return Cat_ShopSystem._textureCache[fullType]
    end
    local tex = nil
    local script = ScriptManager.instance and ScriptManager.instance:getItem(fullType)
    if script then
        local icon = script:getIcon()
        local iconsForTexture = script:getIconsForTexture()
        if iconsForTexture and not iconsForTexture:isEmpty() then
            icon = iconsForTexture:get(0)
        end
        if icon then
            tex = getTexture("Item_" .. icon)
        end
    end
    Cat_ShopSystem._textureCache[fullType] = tex
    return tex
end

function Cat_ShopSystem.GetItemDisplayName(fullType)
    local name = getItemNameFromFullType and getItemNameFromFullType(fullType)
    if name and name ~= "" then
        return name
    end
    local script = ScriptManager.instance and ScriptManager.instance:getItem(fullType)
    if script then
        return script:getDisplayName() or fullType
    end
    return fullType
end

local function doDrawItemWithIcon(self, y, item, alt)
    if not item.height then item.height = self.itemheight end
    if item.height <= 0 then
        return y + item.height
    end
    if (y + self:getYScroll() + self.itemheight < 0) or (y + self:getYScroll() >= self.height) then
        return y + item.height
    end
    local textColor = item.textColor or self.textColor
    if self.selected == item.index then
        self:drawSelection(0, y, self:getWidth(), item.height - 1)
        textColor = item.selectedTextColor or self.selectedTextColor
    elseif (self.mouseoverselected == item.index) and self:isMouseOver() and not self:isMouseOverScrollBar() then
        self:drawMouseOverHighlight(0, y, self:getWidth(), item.height - 1)
    end
    self:drawRectBorder(0, y, self:getWidth(), item.height, 0.5, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    local iconY = y + (item.height - ICON_SIZE) / 2
    if item.item and item.item.texture then
        self:drawTextureScaledAspect(item.item.texture, ICON_PAD, iconY, ICON_SIZE, ICON_SIZE, 1, 1, 1, 1)
    end

    local itemPadY = self.itemPadY or (item.height - self.fontHgt) / 2
    self:drawText(item.text, TEXT_OFFSET, y + itemPadY, textColor.r, textColor.g, textColor.b, textColor.a, self.font)
    y = y + item.height
    return y
end

-- ============================================================================
-- Claim UI
-- ============================================================================
Cat_ShopClaimUI = ISPanel:derive("Cat_ShopClaimUI")

function Cat_ShopClaimUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.coords = { x = 0, y = 0, z = 0 }
    o.moveWithMouse = true
    return o
end

function Cat_ShopClaimUI:createChildren()
    ISPanel.createChildren(self)

    local title = ISLabel:new(10, 10, 20, "CLAIM SHOP", 1, 1, 1, 1, UIFont.Medium, true)
    title:initialise()
    self:addChild(title)

    local info = ISLabel:new(10, 40, 18, "This shop is unclaimed.", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    info:initialise()
    self:addChild(info)

    local claimBtn = ISButton:new(10, 70, self.width - 20, 30, "Claim Shop", self, self.onClaim)
    claimBtn.backgroundColor = { r = 0.2, g = 0.5, b = 0.2, a = 1 }
    claimBtn:initialise()
    claimBtn:instantiate()
    self:addChild(claimBtn)

    local closeBtn = ISButton:new(self.width - 70, 10, 60, 25, "X", self, self.onClose)
    closeBtn.backgroundColor = { r = 0.6, g = 0.2, b = 0.2, a = 1 }
    closeBtn:initialise()
    closeBtn:instantiate()
    self:addChild(closeBtn)

    self.statusLabel = ISLabel:new(10, self.height - 25, 18, "", 1, 1, 1, 1, UIFont.Small, true)
    self.statusLabel:initialise()
    self:addChild(self.statusLabel)
end

function Cat_ShopClaimUI:onClaim()
    sendClientCommand(MOD_NAME, "claimShelf", {
        x = self.coords.x,
        y = self.coords.y,
        z = self.coords.z,
    })
end

function Cat_ShopClaimUI:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
    Cat_ShopSystem.claimUI = nil
end

-- ---------------------------------------------------------------------------
-- Dark palette & text helpers (shared across UIs)
-- ---------------------------------------------------------------------------
C_BG       = { r = 0.04, g = 0.04, b = 0.04, a = 0.88 }
C_PANEL    = { r = 0.12, g = 0.12, b = 0.12, a = 1.0 }
C_ROW      = C_BG
C_ROW_HOV  = { r = 0.20, g = 0.20, b = 0.20, a = 1.0 }
C_ROW_SEL  = { r = 0.28, g = 0.32, b = 0.40, a = 1.0 }
C_GREY_BD  = { r = 0.22, g = 0.22, b = 0.22, a = 1.0 }
C_TEXT     = { r = 0.90, g = 0.90, b = 0.90, a = 1.0 }
C_TEXT_DIM = { r = 0.50, g = 0.50, b = 0.50, a = 1.0 }
C_GREEN    = { r = 0.20, g = 0.48, b = 0.30, a = 1.0 }
C_BLUE     = { r = 0.18, g = 0.30, b = 0.45, a = 1.0 }
C_RED      = { r = 0.55, g = 0.18, b = 0.18, a = 1.0 }
C_RED_HOV  = { r = 0.70, g = 0.22, b = 0.22, a = 1.0 }
C_ORANGE   = { r = 0.90, g = 0.55, b = 0.15, a = 1.0 }

function truncateText(text, maxWidth, font)
    local tm = getTextManager()
    if tm:MeasureStringX(font, text) <= maxWidth then
        return text
    end
    while #text > 3 do
        text = text:sub(1, #text - 1)
        if tm:MeasureStringX(font, text .. "...") <= maxWidth then
            return text .. "..."
        end
    end
    return "..."
end

function wrapTextTwoLines(text, maxWidth, font)
    local tm = getTextManager()
    if tm:MeasureStringX(font, text) <= maxWidth then
        return text, nil
    end
    local mid = math.floor(#text / 2)
    local bestSplit = nil
    for i = mid, 1, -1 do
        if text:sub(i, i) == " " then
            bestSplit = i
            break
        end
    end
    if not bestSplit then
        for i = mid + 1, #text do
            if text:sub(i, i) == " " then
                bestSplit = i
                break
            end
        end
    end
    if not bestSplit then
        return truncateText(text, maxWidth, font), nil
    end
    local line1 = text:sub(1, bestSplit - 1)
    local line2 = text:sub(bestSplit + 1)
    if tm:MeasureStringX(font, line1) > maxWidth then
        line1 = truncateText(line1, maxWidth, font)
    end
    if tm:MeasureStringX(font, line2) > maxWidth then
        line2 = truncateText(line2, maxWidth, font)
    end
    return line1, line2
end

HEADER_H = 40

-- ============================================================================
-- Global shop system functions
-- ============================================================================

function Cat_ShopSystem.OpenShopUI(x, y, z, shopId, isBuyer)
    -- Close any existing UIs
    if Cat_ShopSystem.claimUI then
        Cat_ShopSystem.claimUI:removeFromUIManager()
        Cat_ShopSystem.claimUI = nil
    end
    if Cat_ShopSystem.ownerUI then
        Cat_ShopSystem.ownerUI:removeFromUIManager()
        Cat_ShopSystem.ownerUI = nil
    end
    if Cat_ShopSystem.buyerUI then
        Cat_ShopSystem.buyerUI:removeFromUIManager()
        Cat_ShopSystem.buyerUI = nil
    end
    if Cat_ShopSystem.buyerAdminUI then
        Cat_ShopSystem.buyerAdminUI:removeFromUIManager()
        Cat_ShopSystem.buyerAdminUI = nil
    end
    if Cat_ShopSystem.sellerUI then
        Cat_ShopSystem.sellerUI:removeFromUIManager()
        Cat_ShopSystem.sellerUI = nil
    end

    -- Unclaimed register
    if not shopId then
        local ui = Cat_ShopClaimUI:new(getCore():getScreenWidth() / 2 - 125, getCore():getScreenHeight() / 2 - 80, 250, 160)
        ui.coords = { x = x, y = y, z = z }
        ui.shopId = nil
        ui:initialise()
        ui:addToUIManager()
        Cat_ShopSystem.claimUI = ui
        return
    end

    -- Buyer register — route directly without waiting for owner check
    if isBuyer then
        local player = getSpecificPlayer(0)
        local isAdmin = false
        if player then
            local access = player:getAccessLevel()
            isAdmin = (access == "admin" or access == "Admin" or access == "moderator" or access == "Moderator")
        end
        if isAdmin then
            Cat_ShopSystem.OpenBuyerAdminUI(x, y, z, shopId)
        else
            Cat_ShopSystem.OpenSellerUI(x, y, z, shopId)
        end
        sendClientCommand(MOD_NAME, "requestStock", { x = x, y = y, z = z, shopId = shopId })
        return
    end

    -- Store pending coords so OnShopData knows to open the right panel
    Cat_ShopSystem.pendingOpenCoords = { x = x, y = y, z = z, shopId = shopId }
    sendClientCommand(MOD_NAME, "requestStock", { x = x, y = y, z = z, shopId = shopId })
end

function Cat_ShopSystem.OpenOwnerUI(x, y, z, shopId)
    if Cat_ShopSystem.ownerUI then
        Cat_ShopSystem.ownerUI:removeFromUIManager()
        Cat_ShopSystem.ownerUI = nil
    end

    local ui = Cat_ShopOwnerUI:new(getCore():getScreenWidth() / 2 - 540, getCore():getScreenHeight() / 2 - 370, 1080, 740)
    ui.coords = { x = x, y = y, z = z }
    ui.shopId = shopId
    ui:initialise()
    ui:addToUIManager()
    Cat_ShopSystem.ownerUI = ui

    sendClientCommand(MOD_NAME, "requestStock", { x = x, y = y, z = z, shopId = shopId })
end

function Cat_ShopSystem.OpenBuyerUI(x, y, z, ownerName, shopId)
    if Cat_ShopSystem.buyerUI then
        Cat_ShopSystem.buyerUI:removeFromUIManager()
        Cat_ShopSystem.buyerUI = nil
    end

    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local ui = Cat_ShopBuyerUI:new(sw / 2 - 540, sh / 2 - 370, 1080, 740)
    ui.coords = { x = x, y = y, z = z }
    ui.shopId = shopId
    ui.ownerName = ownerName or "Unknown"
    ui:initialise()
    ui:addToUIManager()
    Cat_ShopSystem.buyerUI = ui

    sendClientCommand(MOD_NAME, "requestStock", { x = x, y = y, z = z, shopId = shopId })
end

function Cat_ShopSystem.OpenBuyerAdminUI(x, y, z, shopId)
    if Cat_ShopSystem.ownerUI then
        Cat_ShopSystem.ownerUI:removeFromUIManager()
        Cat_ShopSystem.ownerUI = nil
    end

    local ui = Cat_ShopOwnerUI:new(getCore():getScreenWidth() / 2 - 540, getCore():getScreenHeight() / 2 - 370, 1080, 740)
    ui.coords = { x = x, y = y, z = z }
    ui.shopId = shopId
    ui.isBuyer = true
    ui:initialise()
    ui:addToUIManager()
    Cat_ShopSystem.ownerUI = ui

    sendClientCommand(MOD_NAME, "requestStock", { x = x, y = y, z = z, shopId = shopId })
end

function Cat_ShopSystem.OpenSellerUI(x, y, z, shopId)
    if Cat_ShopSystem.sellerUI then
        Cat_ShopSystem.sellerUI:removeFromUIManager()
        Cat_ShopSystem.sellerUI = nil
    end

    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local ui = Cat_ShopSellerUI:new(sw / 2 - 400, sh / 2 - 300, 800, 600)
    ui.coords = { x = x, y = y, z = z }
    ui.shopId = shopId
    ui:initialise()
    ui:addToUIManager()
    Cat_ShopSystem.sellerUI = ui
end

function Cat_ShopSystem.OnShopData(args)
    local player = getSpecificPlayer(0)

    if not args.success then
        if player and player.setHaloNote then
            player:setHaloNote("Shop error: " .. (args.error or "Unknown"), 255, 80, 80, 3000)
        end
        print("[Cat_ShopSystem] shopData failed: " .. tostring(args.error))
        return
    end

    local px, py, pz = args.x, args.y, args.z
    local shopId = args.shopId

    -- Update owner UI (handles both seller and buyer admin modes)
    if Cat_ShopSystem.ownerUI and Cat_ShopSystem.ownerUI.shopId == shopId then
        if Cat_ShopSystem.ownerUI.isBuyer then
            Cat_ShopSystem.ownerUI:setData(args.stock)
        else
            Cat_ShopSystem.ownerUI:setData(args.stock, args.earnings)
        end
        return
    end

    -- Update seller UI
    if Cat_ShopSystem.sellerUI and Cat_ShopSystem.sellerUI.shopId == shopId then
        Cat_ShopSystem.sellerUI:setData(args.stock)
        return
    end

    local pending = Cat_ShopSystem.pendingOpenCoords
    if pending and pending.x == px and pending.y == py and pending.z == pz then
        -- First open: route to the correct UI
        Cat_ShopSystem.pendingOpenCoords = nil
        local username = player and player:getUsername() or ""
        local owner = args.owner

        if not owner or owner == "" then
            -- Unclaimed — show claim UI
            if Cat_ShopSystem.claimUI then
                Cat_ShopSystem.claimUI:removeFromUIManager()
            end
            local ui = Cat_ShopClaimUI:new(getCore():getScreenWidth() / 2 - 125, getCore():getScreenHeight() / 2 - 80, 250, 160)
            ui.coords = { x = px, y = py, z = pz }
            ui.shopId = shopId
            ui:initialise()
            ui:addToUIManager()
            Cat_ShopSystem.claimUI = ui
        elseif owner == username then
            -- Owner — show owner UI
            Cat_ShopSystem.OpenOwnerUI(px, py, pz, shopId)
            if Cat_ShopSystem.ownerUI then
                Cat_ShopSystem.ownerUI:setData(args.stock, args.earnings)
            end
        else
            -- Buyer — show buyer UI
            Cat_ShopSystem.OpenBuyerUI(px, py, pz, owner, shopId)
            if Cat_ShopSystem.buyerUI then
                Cat_ShopSystem.buyerUI:setData(args.stock, owner)
            end
        end
        return
    end

    -- Update existing UIs
    if Cat_ShopSystem.buyerUI and Cat_ShopSystem.buyerUI.shopId == shopId then
        Cat_ShopSystem.buyerUI:setData(args.stock, args.owner)
    end
end

function Cat_ShopSystem.OnShopResult(args)
    local player = getSpecificPlayer(0)
    if not args.success and player and player.setHaloNote then
        player:setHaloNote("Shop: " .. (args.error or "Error"), 255, 80, 80, 3000)
    end

    if Cat_ShopSystem.claimUI then
        Cat_ShopSystem.claimUI.statusLabel:setName(args.message or args.error or "")
        if args.success then
            local coords = Cat_ShopSystem.claimUI.coords
            local shopId = args.shopId or Cat_ShopSystem.claimUI.shopId
            Cat_ShopSystem.claimUI:onClose()
            Cat_ShopSystem.OpenOwnerUI(coords.x, coords.y, coords.z, shopId)
            if Cat_ShopSystem.ownerUI and args.stock then
                Cat_ShopSystem.ownerUI:setData(args.stock, args.earnings or 0)
            end
        end
        return
    end

    if Cat_ShopSystem.ownerUI then
        Cat_ShopSystem.ownerUI.statusLabel:setName(args.message or args.error or "")
        if args.success then
            if args.stock then
                Cat_ShopSystem.ownerUI:setData(args.stock, args.earnings or Cat_ShopSystem.ownerUI.earnings)
            end
            if args.earnings ~= nil then
                Cat_ShopSystem.ownerUI.earnings = args.earnings
            end
            Cat_ShopSystem.ownerUI:refreshInventory()
        end
    end

    if Cat_ShopSystem.ownerUI and Cat_ShopSystem.ownerUI.isBuyer then
        Cat_ShopSystem.ownerUI.statusLabel:setName(args.message or args.error or "")
        if args.success and args.stock then
            Cat_ShopSystem.ownerUI:setData(args.stock)
        end
    end
end

function Cat_ShopSystem.OnPurchaseResult(args)
    local player = getSpecificPlayer(0)
    if not args.success and player and player.setHaloNote then
        player:setHaloNote("Purchase: " .. (args.error or "Error"), 255, 80, 80, 3000)
    end

    if Cat_ShopSystem.buyerUI then
        Cat_ShopSystem.buyerUI.statusLabel:setName(args.message or args.error or "")
        if args.success then
            Cat_ShopSystem.buyerUI.cart = {}
            Cat_ShopSystem.buyerUI:updateTotal()
        end
        if args.stock then
            Cat_ShopSystem.buyerUI:setData(args.stock, Cat_ShopSystem.buyerUI.ownerName)
        end
    end
end

function Cat_ShopSystem.OnSellResult(args)
    local player = getSpecificPlayer(0)
    if not args.success and player and player.setHaloNote then
        player:setHaloNote("Sell: " .. (args.error or "Error"), 255, 80, 80, 3000)
    end

    if Cat_ShopSystem.sellerUI then
        Cat_ShopSystem.sellerUI.statusLabel:setName(args.message or args.error or "")
        if args.success then
            Cat_ShopSystem.sellerUI.cart = {}
            Cat_ShopSystem.sellerUI:updateTotal()
        end
        if args.stock then
            Cat_ShopSystem.sellerUI:setData(args.stock)
        end
    end
end

print("[Cat_ShopSystem Client] UI loaded.")
