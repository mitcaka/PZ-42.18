-- =============================================================================
-- Cat Shop System — Buyer UI
-- =============================================================================
if isServer() then return end

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISLabel"

Cat_ShopSystem = Cat_ShopSystem or {}
local MOD_NAME = "Cat_ShopSystem"

-- ============================================================================
-- Buyer UI
-- ============================================================================
-- ============================================================================
-- Buyer UI — dark theme, no framework dependency
-- ============================================================================
Cat_ShopBuyerUI = ISPanel:derive("Cat_ShopBuyerUI")

-- Layout
local BUYER_W = 1080
local BUYER_H = 740
local HEADER_H = 40
local STOCK_ROWS = 9
local ROW_H = 62
local ROW_GAP = 66
local STOCK_X = 20
local STOCK_W = 700
local STOCK_START_Y = HEADER_H + 14

local BASKET_X = 750
local BASKET_Y = HEADER_H + 14
local BASKET_W = 310
local BASKET_H = 430

local CART_ROW_H = 42
local CART_START_Y = BASKET_Y + 10

local TOTAL_X = BASKET_X
local TOTAL_Y = BASKET_Y + BASKET_H + 12
local TOTAL_W = BASKET_W
local TOTAL_H = 48

local PAY_Y = TOTAL_Y + TOTAL_H + 12
local PAY_H = 46
local PAY_MONEY_X = BASKET_X
local PAY_BANK_X = BASKET_X + 160
local PAY_W = 150

local PAGE_Y = STOCK_START_Y + STOCK_ROWS * ROW_GAP + 10

local CANCEL_X = BASKET_X
local CANCEL_Y = PAGE_Y
local CANCEL_W = BASKET_W
local CANCEL_H = 46

function Cat_ShopBuyerUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = C_BG
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.coords = { x = 0, y = 0, z = 0 }
    o.shopId = nil
    o.ownerName = ""
    o.stock = {}
    o.cart = {}
    o.page = 1
    o.itemsPerPage = STOCK_ROWS
    o.selectedStockIdx = 0
    o.hoverStockIdx = 0
    o.hoverCartIdx = 0
    o.cartScrollY = 0
    o.moveWithMouse = true
    o:setWantKeyEvents(true)
    return o
end

function Cat_ShopBuyerUI:createChildren()
    ISPanel.createChildren(self)

    -- Pagination arrows drawn manually in render() to avoid ISButton disabled borders

    self.payMoneyBtn = ISButton:new(PAY_MONEY_X, PAY_Y, PAY_W, PAY_H, "Cash", self, self.onPurchase)
    self.payMoneyBtn.backgroundColor = C_GREEN
    self.payMoneyBtn.backgroundColorMouseOver = { r = 0.24, g = 0.54, b = 0.34, a = 1 }
    self.payMoneyBtn.borderColor = C_GREY_BD
    self.payMoneyBtn:initialise(); self.payMoneyBtn:instantiate(); self:addChild(self.payMoneyBtn)

    self.payBankBtn = ISButton:new(PAY_BANK_X, PAY_Y, PAY_W, PAY_H, "Bank", self, self.onPurchaseBank)
    self.payBankBtn.backgroundColor = C_BLUE
    self.payBankBtn.backgroundColorMouseOver = { r = 0.22, g = 0.36, b = 0.52, a = 1 }
    self.payBankBtn.borderColor = C_GREY_BD
    self.payBankBtn:initialise(); self.payBankBtn:instantiate(); self:addChild(self.payBankBtn)

    self.cancelBtn = ISButton:new(CANCEL_X, CANCEL_Y, CANCEL_W, CANCEL_H, "Cancel and Exit", self, self.onClose)
    self.cancelBtn.backgroundColor = C_RED
    self.cancelBtn.backgroundColorMouseOver = C_RED_HOV
    self.cancelBtn.borderColor = C_GREY_BD
    self.cancelBtn:initialise(); self.cancelBtn:instantiate(); self:addChild(self.cancelBtn)

    self.statusLabel = ISLabel:new(STOCK_X + STOCK_W / 2, PAGE_Y + 52, 16, "", 1, 1, 1, 1, UIFont.Small, true)
    self.statusLabel.center = true
    self.statusLabel:initialise(); self:addChild(self.statusLabel)
end

function Cat_ShopBuyerUI:setData(stock, ownerName)
    self.stock = stock or {}
    self.ownerName = ownerName or "Unknown"
    self.page = 1
    self.selectedStockIdx = 0
    self:updatePageButtons()
end

function Cat_ShopBuyerUI:getPageStock()
    local startIdx = (self.page - 1) * self.itemsPerPage + 1
    local result = {}
    for i = startIdx, math.min(startIdx + self.itemsPerPage - 1, #self.stock) do
        table.insert(result, self.stock[i])
    end
    return result
end

function Cat_ShopBuyerUI:getTotalPages()
    return math.max(1, math.ceil(#self.stock / self.itemsPerPage))
end

function Cat_ShopBuyerUI:updatePageButtons()
    -- Pagination arrows are drawn conditionally in render(); no ISButton state to update
end

function Cat_ShopBuyerUI:onPrevPage()
    if self.page > 1 then
        self.page = self.page - 1
        self.selectedStockIdx = 0
        self:updatePageButtons()
    end
end

function Cat_ShopBuyerUI:onNextPage()
    if self.page < self:getTotalPages() then
        self.page = self.page + 1
        self.selectedStockIdx = 0
        self:updatePageButtons()
    end
end

function Cat_ShopBuyerUI:updateTotal()
    local total = 0
    for _, item in ipairs(self.cart) do
        total = total + (item.price * item.qty)
    end
    self.total = total
end

function Cat_ShopBuyerUI:addToCart(stockIdx)
    local pageStock = self:getPageStock()
    local stockItem = pageStock[stockIdx]
    if not stockItem then return end
    if stockItem.qty <= 0 then
        self.statusLabel:setName("Out of stock.")
        return
    end
    local found = false
    for _, cartItem in ipairs(self.cart) do
        if cartItem.item == stockItem.item and cartItem.price == stockItem.price then
            if cartItem.qty < stockItem.qty then
                cartItem.qty = cartItem.qty + 1
                found = true
            else
                self.statusLabel:setName("Cannot add more than available stock.")
                return
            end
            break
        end
    end
    if not found then
        table.insert(self.cart, { item = stockItem.item, price = stockItem.price, qty = 1 })
    end
    self:updateTotal()
    self.statusLabel:setName("")
end

function Cat_ShopBuyerUI:removeFromCart(cartIdx)
    if cartIdx >= 1 and cartIdx <= #self.cart then
        table.remove(self.cart, cartIdx)
        self:updateTotal()
    end
end

function Cat_ShopBuyerUI:onPurchase()
    if #self.cart == 0 then
        self.statusLabel:setName("Cart is empty.")
        return
    end
    local player = getSpecificPlayer(0)
    if not player then return end
    local money = Cat_EconomyUtils.getMoneyCount(player)
    if money < self.total then
        self.statusLabel:setName("Not enough cash. Need $" .. self.total)
        return
    end
    sendClientCommand(MOD_NAME, "purchase", {
        x = self.coords.x, y = self.coords.y, z = self.coords.z,
        shopId = self.shopId,
        cart = self.cart,
    })
end

function Cat_ShopBuyerUI:onPurchaseBank()
    if #self.cart == 0 then
        self.statusLabel:setName("Cart is empty.")
        return
    end
    sendClientCommand(MOD_NAME, "purchaseBank", {
        x = self.coords.x, y = self.coords.y, z = self.coords.z,
        shopId = self.shopId,
        cart = self.cart,
    })
end

function Cat_ShopBuyerUI:isKeyConsumed(key)
    return key == Keyboard.KEY_ESCAPE
end

function Cat_ShopBuyerUI:onKeyRelease(key)
    if key == Keyboard.KEY_ESCAPE then
        self:onClose()
        return true
    end
    return false
end

function Cat_ShopBuyerUI:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
    Cat_ShopSystem.buyerUI = nil
end

-- ---------------------------------------------------------------------------
-- Rendering
-- ---------------------------------------------------------------------------
function Cat_ShopBuyerUI:render()
    ISPanel.render(self)

    local mx, my = self:getMouseX(), self:getMouseY()
    self.hoverStockIdx = 0
    self.hoverCartIdx = 0

    -- Header bar (no border)
    self:drawRect(0, 0, self.width, HEADER_H, 1, 0.08, 0.08, 0.08)
    self:drawText("BROWSE SHOP", 20, 10, C_TEXT.r, C_TEXT.g, C_TEXT.b, 1, UIFont.Medium)

    -- Close text (top right)
    local closeX = BUYER_W - 80
    local closeY = 8
    local closeW = 70
    local closeH = 26
    self.closeHover = mx >= closeX and mx <= closeX + closeW and my >= closeY and my <= closeY + closeH
    local closeCol = self.closeHover and C_TEXT_DIM or C_TEXT
    self:drawText("Close", closeX, closeY, closeCol.r, closeCol.g, closeCol.b, 1, UIFont.Small)
    local ownerText = "Owner: " .. self.ownerName
    local ownerW = getTextManager():MeasureStringX(UIFont.Small, ownerText)
    self:drawText(ownerText, (self.width - ownerW) / 2, 12, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)

    -- Basket panel (subtle grey border)
    self:drawRect(BASKET_X, BASKET_Y, BASKET_W, BASKET_H, 1, C_PANEL.r, C_PANEL.g, C_PANEL.b)
    self:drawRectBorder(BASKET_X, BASKET_Y, BASKET_W, BASKET_H, 1, C_GREY_BD.r, C_GREY_BD.g, C_GREY_BD.b)

    -- Stock rows (no border, pure black bg)
    local pageStock = self:getPageStock()
    if #self.stock == 0 then
        local msg = "No items for sale."
        local msgW = getTextManager():MeasureStringX(UIFont.Medium, msg)
        self:drawText(msg, STOCK_X + (STOCK_W - msgW) / 2, STOCK_START_Y + 180, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Medium)
    end
    local nameMaxW = STOCK_W - 70 - 60 -- icon area - qty area
    for i = 1, STOCK_ROWS do
        local y = STOCK_START_Y + (i - 1) * ROW_GAP
        local item = pageStock[i]
        local rowLeft = STOCK_X
        local rowRight = STOCK_X + STOCK_W
        local isHover = mx >= rowLeft and mx <= rowRight and my >= y and my < y + ROW_H
        if isHover then self.hoverStockIdx = i end
        local isSel = (self.selectedStockIdx == i)

        if item then
            if isSel then
                self:drawRect(rowLeft, y, STOCK_W, ROW_H, 1, C_ROW_SEL.r, C_ROW_SEL.g, C_ROW_SEL.b)
            elseif isHover then
                self:drawRect(rowLeft, y, STOCK_W, ROW_H, 1, C_ROW_HOV.r, C_ROW_HOV.g, C_ROW_HOV.b)
            end

            local tex = Cat_ShopSystem.GetItemTexture(item.item)
            if tex then
                self:drawTextureScaledAspect(tex, rowLeft + 10, y + 10, 36, 36, 1, 1, 1, 1)
            end

            local name = Cat_ShopSystem.GetItemDisplayName(item.item)
            local line1, line2 = wrapTextTwoLines(name, nameMaxW, UIFont.Small)
            if line2 then
                self:drawText(line1, rowLeft + 56, y + 6, C_TEXT.r, C_TEXT.g, C_TEXT.b, 1, UIFont.Small)
                self:drawText(line2, rowLeft + 56, y + 22, C_TEXT.r, C_TEXT.g, C_TEXT.b, 1, UIFont.Small)
                self:drawText("$" .. item.price .. " each", rowLeft + 56, y + 40, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)
            else
                self:drawText(line1, rowLeft + 56, y + 10, C_TEXT.r, C_TEXT.g, C_TEXT.b, 1, UIFont.Small)
                self:drawText("$" .. item.price .. " each", rowLeft + 56, y + 30, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)
            end
            self:drawTextRight("Stock Available: " .. item.qty, rowLeft + STOCK_W - 12, y + 18, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)
        end
    end

    -- Pagination arrows (custom, no ISButton disabled-border issues)
    local prevHover = mx >= STOCK_X and mx <= STOCK_X + 60 and my >= PAGE_Y and my <= PAGE_Y + ROW_H
    local nextHover = mx >= STOCK_X + STOCK_W - 60 and mx <= STOCK_X + STOCK_W and my >= PAGE_Y and my <= PAGE_Y + ROW_H
    local fontHgt = getTextManager():getFontHeight(UIFont.Small)
    local pageBtnV = PAGE_Y + (ROW_H - fontHgt) / 2
    if self.page > 1 then
        if prevHover then
            self:drawRect(STOCK_X, PAGE_Y, 60, ROW_H, 1, C_ROW_HOV.r, C_ROW_HOV.g, C_ROW_HOV.b)
        end
        local prevW = getTextManager():MeasureStringX(UIFont.Small, "<<")
        self:drawText("<<", STOCK_X + 30 - prevW / 2, pageBtnV, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)
    end
    if self.page < self:getTotalPages() then
        if nextHover then
            self:drawRect(STOCK_X + STOCK_W - 60, PAGE_Y, 60, ROW_H, 1, C_ROW_HOV.r, C_ROW_HOV.g, C_ROW_HOV.b)
        end
        local nextW = getTextManager():MeasureStringX(UIFont.Small, ">>")
        self:drawText(">>", STOCK_X + STOCK_W - 30 - nextW / 2, pageBtnV, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)
    end

    -- Page indicator
    local pageText = "Page " .. self.page .. " / " .. self:getTotalPages()
    local pageW = getTextManager():MeasureStringX(UIFont.Small, pageText)
    self:drawText(pageText, STOCK_X + (STOCK_W - pageW) / 2, PAGE_Y + 20, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)

    -- Cart rows (scrollable, stencil-clipped to basket)
    local cartNameMaxW = BASKET_W - 115
    local visibleCartRows = math.floor((BASKET_H - 20) / CART_ROW_H)
    self.cartMaxScroll = math.max(0, (#self.cart - visibleCartRows) * CART_ROW_H)
    self.cartScrollY = math.max(0, math.min(self.cartScrollY, self.cartMaxScroll))

    for i = 1, #self.cart do
        local y = CART_START_Y + (i - 1) * CART_ROW_H - self.cartScrollY
        -- Strict clip: only draw rows fully inside basket
        if y >= BASKET_Y and y + CART_ROW_H <= BASKET_Y + BASKET_H then
            local item = self.cart[i]
            local isHover = mx >= BASKET_X + 4 and mx <= BASKET_X + BASKET_W - 4 and my >= y and my < y + CART_ROW_H
            if isHover then self.hoverCartIdx = i end

            local tex = Cat_ShopSystem.GetItemTexture(item.item)
            if tex then
                self:drawTextureScaledAspect(tex, BASKET_X + 10, y + 4, 30, 30, 1, 1, 1, 1)
            end
            local name = Cat_ShopSystem.GetItemDisplayName(item.item)
            name = truncateText(name, cartNameMaxW, UIFont.Small)
            self:drawText(name, BASKET_X + 46, y + 4, C_TEXT.r, C_TEXT.g, C_TEXT.b, 1, UIFont.Small)
            self:drawText("x" .. item.qty, BASKET_X + 46, y + 20, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)

            local lineTotal = item.price * item.qty
            self:drawTextRight("$" .. lineTotal, BASKET_X + BASKET_W - 48, y + 12, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)

            -- Remove X
            local rx = BASKET_X + BASKET_W - 38
            local hoverX = mx >= rx and mx <= rx + 28 and my >= y + 6 and my <= y + CART_ROW_H - 6
            local xCol = hoverX and C_RED_HOV or C_RED
            self:drawRect(rx, y + 7, 26, 24, 1, xCol.r, xCol.g, xCol.b)
            self:drawText("X", rx + 7, y + 9, 1, 1, 1, 1, UIFont.Small)
        end
    end

    -- Total text
    self:drawText("Total:", TOTAL_X + 16, TOTAL_Y + 10, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Medium)
    self:drawTextRight("$" .. (self.total or 0), TOTAL_X + TOTAL_W - 16, TOTAL_Y + 10, C_TEXT.r, C_TEXT.g, C_TEXT.b, 1, UIFont.Medium)

    -- Payment method label
    local payLbl = "Payment Method"
    local payLblW = getTextManager():MeasureStringX(UIFont.Small, payLbl)
    local payLblX = (PAY_MONEY_X + PAY_BANK_X + PAY_W) / 2 - payLblW / 2
    self:drawText(payLbl, payLblX, PAY_Y - 18, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)
end

function Cat_ShopBuyerUI:onMouseWheel(del)
    local mx, my = self:getMouseX(), self:getMouseY()
    if mx >= BASKET_X and mx <= BASKET_X + BASKET_W and my >= BASKET_Y and my <= BASKET_Y + BASKET_H then
        self.cartScrollY = self.cartScrollY + del * CART_ROW_H
        return true
    end
    return false
end

function Cat_ShopBuyerUI:onMouseDown(x, y)
    ISPanel.onMouseDown(self, x, y)

    -- Close click
    if x >= BUYER_W - 80 and x <= BUYER_W - 10 and y >= 8 and y <= 34 then
        self:onClose()
        return
    end

    -- Pagination clicks
    if x >= STOCK_X and x <= STOCK_X + 60 and y >= PAGE_Y and y <= PAGE_Y + ROW_H then
        if self.page > 1 then self:onPrevPage() end
        return
    end
    if x >= STOCK_X + STOCK_W - 60 and x <= STOCK_X + STOCK_W and y >= PAGE_Y and y <= PAGE_Y + ROW_H then
        if self.page < self:getTotalPages() then self:onNextPage() end
        return
    end

    -- Stock row clicks
    local pageStock = self:getPageStock()
    for i = 1, STOCK_ROWS do
        local ry = STOCK_START_Y + (i - 1) * ROW_GAP
        if x >= STOCK_X and x <= STOCK_X + STOCK_W and y >= ry and y < ry + ROW_H then
            if pageStock[i] then
                self.selectedStockIdx = i
                self:addToCart(i)
            end
            return
        end
    end

    -- Cart remove clicks (account for scroll)
    for i = 1, #self.cart do
        local ry = CART_START_Y + (i - 1) * CART_ROW_H - self.cartScrollY
        local rx = BASKET_X + BASKET_W - 38
        if x >= rx and x <= rx + 28 and y >= ry + 6 and y <= ry + CART_ROW_H - 6 then
            self:removeFromCart(i)
            return
        end
    end
end
