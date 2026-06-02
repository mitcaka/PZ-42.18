-- =============================================================================
-- Cat Shop System — Seller UI (player sells items to buyer register)
-- =============================================================================
if isServer() then return end

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISTextEntryBox"

Cat_ShopSellerUI = ISPanel:derive("Cat_ShopSellerUI")

local UI_W = 800
local UI_H = 600

function Cat_ShopSellerUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = C_BG
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.coords = { x = 0, y = 0, z = 0 }
    o.shopId = nil
    o.stock = {}
    o.cart = {}
    o.moveWithMouse = true
    o:setWantKeyEvents(true)
    return o
end

function Cat_ShopSellerUI:createChildren()
    ISPanel.createChildren(self)

    -- Sell for Cash button
    self.sellCashBtn = ISButton:new(20, UI_H - 60, 180, 40, "Sell for Cash", self, self.onSellCash)
    self.sellCashBtn.backgroundColor = C_GREEN
    self.sellCashBtn.backgroundColorMouseOver = { r = 0.24, g = 0.54, b = 0.34, a = 1 }
    self.sellCashBtn.borderColor = C_GREY_BD
    self.sellCashBtn:initialise(); self.sellCashBtn:instantiate(); self:addChild(self.sellCashBtn)

    -- Sell to Bank button
    self.sellBankBtn = ISButton:new(220, UI_H - 60, 180, 40, "Sell to Bank", self, self.onSellBank)
    self.sellBankBtn.backgroundColor = C_BLUE
    self.sellBankBtn.backgroundColorMouseOver = { r = 0.22, g = 0.36, b = 0.52, a = 1 }
    self.sellBankBtn.borderColor = C_GREY_BD
    self.sellBankBtn:initialise(); self.sellBankBtn:instantiate(); self:addChild(self.sellBankBtn)

    -- Total label
    self.totalLabel = ISLabel:new(UI_W - 220, UI_H - 50, 18, "Total: $0", 1, 1, 1, 1, UIFont.Medium, true)
    self.totalLabel:initialise(); self:addChild(self.totalLabel)

    -- Status label
    self.statusLabel = ISLabel:new(UI_W / 2, 46, 16, "", 1, 1, 1, 1, UIFont.Small, true)
    self.statusLabel.center = true
    self.statusLabel:initialise(); self:addChild(self.statusLabel)
end

function Cat_ShopSellerUI:setData(stock)
    self.stock = stock or {}
    self:updateTotal()
end

function Cat_ShopSellerUI:getInvCount(itemType)
    local player = getSpecificPlayer(0)
    if not player then return 0 end
    local inv = player:getInventory()
    local items = inv:getItemsFromType(itemType, true)
    return items and items:size() or 0
end

function Cat_ShopSellerUI:updateTotal()
    local total = 0
    for itemType, qty in pairs(self.cart) do
        for _, wanted in ipairs(self.stock) do
            if wanted.item == itemType then
                total = total + (wanted.price * qty)
                break
            end
        end
    end
    self.totalLabel:setName("Total: $" .. total)
end

function Cat_ShopSellerUI:onSellCash()
    self:doSell("sellToBuyer")
end

function Cat_ShopSellerUI:onSellBank()
    self:doSell("sellToBuyerBank")
end

function Cat_ShopSellerUI:doSell(command)
    local empty = true
    for _ in pairs(self.cart) do
        empty = false
        break
    end
    if empty then
        self.statusLabel:setName("Basket is empty.")
        return
    end

    local cartList = {}
    for itemType, qty in pairs(self.cart) do
        table.insert(cartList, { item = itemType, qty = qty })
    end

    sendClientCommand("Cat_ShopSystem", command, {
        x = self.coords.x,
        y = self.coords.y,
        z = self.coords.z,
        shopId = self.shopId,
        cart = cartList,
    })
end

function Cat_ShopSellerUI:addToCart(itemType, amount)
    local current = self.cart[itemType] or 0
    local newQty = current + amount

    -- Check buyer wants
    local maxWanted = 0
    local alwaysBuy = false
    for _, wanted in ipairs(self.stock) do
        if wanted.item == itemType then
            if wanted.alwaysBuy then
                alwaysBuy = true
                maxWanted = 999999
            else
                maxWanted = wanted.qty
            end
            break
        end
    end

    -- Check player inventory
    local invCount = self:getInvCount(itemType)
    if alwaysBuy then
        newQty = math.max(0, math.min(newQty, invCount))
    else
        newQty = math.max(0, math.min(newQty, maxWanted, invCount))
    end

    if newQty > 0 then
        self.cart[itemType] = newQty
    else
        self.cart[itemType] = nil
    end
    self:updateTotal()
end

function Cat_ShopSellerUI:sellAllToCart(itemType)
    local invCount = self:getInvCount(itemType)
    if invCount <= 0 then return end

    local alwaysBuy = false
    local maxWanted = 0
    for _, wanted in ipairs(self.stock) do
        if wanted.item == itemType then
            if wanted.alwaysBuy then
                alwaysBuy = true
                maxWanted = 999999
            else
                maxWanted = wanted.qty
            end
            break
        end
    end

    local qty = alwaysBuy and invCount or math.min(invCount, maxWanted)
    if qty > 0 then
        self.cart[itemType] = qty
        self:updateTotal()
    end
end

function Cat_ShopSellerUI:isKeyConsumed(key)
    return key == Keyboard.KEY_ESCAPE
end

function Cat_ShopSellerUI:onKeyRelease(key)
    if key == Keyboard.KEY_ESCAPE then
        self:onClose()
        return true
    end
    return false
end

function Cat_ShopSellerUI:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
    Cat_ShopSystem.sellerUI = nil
end

function Cat_ShopSellerUI:render()
    ISPanel.render(self)

    local mx, my = self:getMouseX(), self:getMouseY()

    -- Header bar
    self:drawRect(0, 0, self.width, HEADER_H, 1, 0.08, 0.08, 0.08)
    self:drawText("SELL ITEMS", 20, 8, C_TEXT.r, C_TEXT.g, C_TEXT.b, 1, UIFont.Medium)

    -- Close text
    local closeX = UI_W - 80
    local closeY = 8
    local closeW = 70
    local closeH = 26
    self.closeHover = mx >= closeX and mx <= closeX + closeW and my >= closeY and my <= closeY + closeH
    local closeCol = self.closeHover and C_TEXT_DIM or C_TEXT
    self:drawText("Close", closeX, closeY, closeCol.r, closeCol.g, closeCol.b, 1, UIFont.Small)

    -- Wanted items list
    local listY = 80
    local listH = UI_H - listY - 80
    self:drawRect(20, listY, UI_W - 40, listH, 1, C_PANEL.r, C_PANEL.g, C_PANEL.b)
    self:drawRectBorder(20, listY, UI_W - 40, listH, 1, C_GREY_BD.r, C_GREY_BD.g, C_GREY_BD.b)

    local rowH = 50
    local visibleRows = math.floor(listH / rowH)
    self.maxScroll = math.max(0, (#self.stock - visibleRows) * rowH)
    self.scrollY = math.max(0, math.min(self.scrollY or 0, self.maxScroll))

    for i = 1, #self.stock do
        local y = listY + (i - 1) * rowH - self.scrollY
        if y >= listY and y + rowH <= listY + listH then
            local item = self.stock[i]
            local isHover = mx >= 24 and mx <= UI_W - 24 and my >= y and my < y + rowH
            if isHover then
                self:drawRect(24, y, UI_W - 48, rowH, 1, C_ROW_HOV.r, C_ROW_HOV.g, C_ROW_HOV.b)
            end

            local tex = Cat_ShopSystem.GetItemTexture(item.item)
            if tex then
                self:drawTextureScaledAspect(tex, 34, y + 6, 36, 36, 1, 1, 1, 1)
            end

            local name = Cat_ShopSystem.GetItemDisplayName(item.item)
            name = truncateText(name, 220, UIFont.Small)
            self:drawText(name, 80, y + 4, C_TEXT.r, C_TEXT.g, C_TEXT.b, 1, UIFont.Small)
            self:drawText("$" .. item.price .. " each", 80, y + 24, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)

            local invCount = self:getInvCount(item.item)
            self:drawTextRight("You have: " .. invCount, 380, y + 14, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)
            if item.alwaysBuy then
                self:drawTextRight("Always accepting", 500, y + 14, C_GREEN.r, C_GREEN.g, C_GREEN.b, 1, UIFont.Small)
            else
                self:drawTextRight("Amount Wanted: " .. item.qty, 500, y + 14, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)
            end

            local cartQty = self.cart[item.item] or 0
            if cartQty > 0 then
                self:drawTextRight("In basket: " .. cartQty, 620, y + 14, C_ORANGE.r, C_ORANGE.g, C_ORANGE.b, 1, UIFont.Small)
            end

            -- Sell All / - / + buttons
            local btnY = y + 10
            local btnH = 28
            local allW = 44
            local allX = UI_W - 148
            local minusW = 32
            local minusX = UI_W - 96
            local plusW = 32
            local plusX = UI_W - 56

            -- Sell All button
            local hoverAll = mx >= allX and mx <= allX + allW and my >= btnY and my <= btnY + btnH
            local allCol = hoverAll and { r = 0.24, g = 0.54, b = 0.34, a = 1 } or { r = 0.18, g = 0.45, b = 0.25, a = 1 }
            self:drawRect(allX, btnY, allW, btnH, 1, allCol.r, allCol.g, allCol.b)
            local aw = getTextManager():MeasureStringX(UIFont.Small, "All")
            local mh = getTextManager():getFontHeight(UIFont.Small)
            self:drawText("All", allX + (allW - aw) / 2, btnY + (btnH - mh) / 2, 1, 1, 1, 1, UIFont.Small)

            local hoverMinus = mx >= minusX and mx <= minusX + minusW and my >= btnY and my <= btnY + btnH
            local minusCol = hoverMinus and C_RED_HOV or C_RED
            self:drawRect(minusX, btnY, minusW, btnH, 1, minusCol.r, minusCol.g, minusCol.b)
            local mw = getTextManager():MeasureStringX(UIFont.Small, "-")
            self:drawText("-", minusX + (minusW - mw) / 2, btnY + (btnH - mh) / 2, 1, 1, 1, 1, UIFont.Small)

            local hoverPlus = mx >= plusX and mx <= plusX + plusW and my >= btnY and my <= btnY + btnH
            local plusCol = hoverPlus and C_GREEN or { r = 0.18, g = 0.45, b = 0.25, a = 1 }
            self:drawRect(plusX, btnY, plusW, btnH, 1, plusCol.r, plusCol.g, plusCol.b)
            local pw = getTextManager():MeasureStringX(UIFont.Small, "+")
            self:drawText("+", plusX + (plusW - pw) / 2, btnY + (btnH - mh) / 2, 1, 1, 1, 1, UIFont.Small)
        end
    end

    if #self.stock == 0 then
        local msg = "This buyer is not purchasing any items right now."
        local msgW = getTextManager():MeasureStringX(UIFont.Medium, msg)
        self:drawText(msg, 20 + (UI_W - 40 - msgW) / 2, listY + 80, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Medium)
    end
end

function Cat_ShopSellerUI:onMouseWheel(del)
    self.scrollY = (self.scrollY or 0) + del * 50
    self.scrollY = math.max(0, math.min(self.scrollY, self.maxScroll or 0))
    return true
end

function Cat_ShopSellerUI:onMouseDown(x, y)
    ISPanel.onMouseDown(self, x, y)

    if x >= UI_W - 80 and x <= UI_W - 10 and y >= 8 and y <= 34 then
        self:onClose()
        return
    end

    local listY = 80
    local rowH = 50
    for i = 1, #self.stock do
        local ry = listY + (i - 1) * rowH - (self.scrollY or 0)
        local btnY = ry + 10
        local btnH = 28
        local allW = 44
        local allX = UI_W - 148
        local minusW = 32
        local minusX = UI_W - 96
        local plusW = 32
        local plusX = UI_W - 56

        if x >= allX and x <= allX + allW and y >= btnY and y <= btnY + btnH then
            self:sellAllToCart(self.stock[i].item)
            return
        end
        if x >= minusX and x <= minusX + minusW and y >= btnY and y <= btnY + btnH then
            self:addToCart(self.stock[i].item, -1)
            return
        end
        if x >= plusX and x <= plusX + plusW and y >= btnY and y <= btnY + btnH then
            self:addToCart(self.stock[i].item, 1)
            return
        end
    end
end

print("[Cat_ShopSystem Client] Seller UI loaded.")
