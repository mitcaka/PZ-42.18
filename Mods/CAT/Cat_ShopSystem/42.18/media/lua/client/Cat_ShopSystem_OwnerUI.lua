-- =============================================================================
-- Cat Shop System — Owner UI
-- =============================================================================
if isServer() then return end

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISTextEntryBox"

Cat_ShopSystem = Cat_ShopSystem or {}
local MOD_NAME = "Cat_ShopSystem"

-- ============================================================================
-- Owner UI
-- ============================================================================
Cat_ShopOwnerUI = ISPanel:derive("Cat_ShopOwnerUI")

-- Owner UI layout constants
local OWNER_W = 1080
local OWNER_H = 740

local TITLE_X = 20
local TITLE_Y = 8

local DECO_X = 300
local DECO_Y = 20
local DECO_W = 480
local DECO_H = 120

local EARN_X = 820
local EARN_Y = 8
local EARN_W = 240

local COLLECT_X = 820
local COLLECT_Y = 100
local COLLECT_W = 240
local COLLECT_H = 40

local STOCK_HDR_X = 20
local STOCK_HDR_Y = 100

local STOCK_X = 20
local STOCK_Y = 160
local STOCK_W = 1040
local STOCK_H = 260
local STOCK_ROW_H = 42

local VIEW_AS_X = 20
local VIEW_AS_Y = 440
local VIEW_AS_W = 240
local VIEW_AS_H = 40

local LIST_HDR_X = 300
local LIST_HDR_Y = 440
local LIST_HDR_W = 480

local INV_X = 300
local INV_Y = 500
local INV_W = 480
local INV_H = 220
local INV_ROW_H = 36

local AMT_LBL_X = 20
local AMT_LBL_Y = 550
local PRICE_LBL_X = 160
local PRICE_LBL_Y = 550

local AMT_ENTRY_X = 20
local AMT_ENTRY_Y = 620
local AMT_ENTRY_W = 100
local AMT_ENTRY_H = 40

local PRICE_ENTRY_X = 160
local PRICE_ENTRY_Y = 620
local PRICE_ENTRY_W = 100
local PRICE_ENTRY_H = 40

local LIST_BTN_X = 20
local LIST_BTN_Y = 680
local LIST_BTN_W = 240
local LIST_BTN_H = 40

local TOGGLE_X = 80
local TOGGLE_Y = 510
local TOGGLE_W = 20
local TOGGLE_H = 20

local HIST_HDR_X = 820
local HIST_HDR_Y = 440
local HIST_HDR_W = 240

local HIST_X = 820
local HIST_Y = 500
local HIST_W = 240
local HIST_H = 220

function Cat_ShopOwnerUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = C_BG
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.coords = { x = 0, y = 0, z = 0 }
    o.shopId = nil
    o.stock = {}
    o.earnings = 0
    o.invItems = {}
    o.selectedInvIdx = 0
    o.hoverStockIdx = 0
    o.hoverInvIdx = 0
    o.stockScrollY = 0
    o.invScrollY = 0
    o.isBuyer = false
    o.alwaysBuyToggle = false
    o.moveWithMouse = true
    o:setWantKeyEvents(true)
    return o
end

function Cat_ShopOwnerUI:createChildren()
    ISPanel.createChildren(self)

    -- Price entry
    self.priceEntry = ISTextEntryBox:new("1", PRICE_ENTRY_X, PRICE_ENTRY_Y, PRICE_ENTRY_W, PRICE_ENTRY_H)
    self.priceEntry:initialise()
    self.priceEntry:instantiate()
    self.priceEntry.backgroundColor = C_PANEL
    self.priceEntry.borderColor = C_GREY_BD
    self.priceEntry:setFont(UIFont.Medium)
    self:addChild(self.priceEntry)

    -- Quantity entry
    self.qtyEntry = ISTextEntryBox:new("1", AMT_ENTRY_X, AMT_ENTRY_Y, AMT_ENTRY_W, AMT_ENTRY_H)
    self.qtyEntry:initialise()
    self.qtyEntry:instantiate()
    self.qtyEntry.backgroundColor = C_PANEL
    self.qtyEntry.borderColor = C_GREY_BD
    self.qtyEntry:setFont(UIFont.Medium)
    self:addChild(self.qtyEntry)

    -- Collect Earnings button (seller only)
    if not self.isBuyer then
        self.collectBtn = ISButton:new(COLLECT_X, COLLECT_Y, COLLECT_W, COLLECT_H, "Collect Earnings", self, self.onCollect)
        self.collectBtn.backgroundColor = C_GREEN
        self.collectBtn.backgroundColorMouseOver = { r = 0.24, g = 0.54, b = 0.34, a = 1 }
        self.collectBtn.borderColor = C_GREY_BD
        self.collectBtn:initialise(); self.collectBtn:instantiate(); self:addChild(self.collectBtn)
    end

    -- List Item / Add Wanted button
    local btnText = self.isBuyer and "Add Wanted" or "List Item"
    self.listBtn = ISButton:new(LIST_BTN_X, LIST_BTN_Y, LIST_BTN_W, LIST_BTN_H, btnText, self, self.onListItem)
    self.listBtn.backgroundColor = C_BLUE
    self.listBtn.backgroundColorMouseOver = { r = 0.22, g = 0.36, b = 0.52, a = 1 }
    self.listBtn.borderColor = C_GREY_BD
    self.listBtn:initialise(); self.listBtn:instantiate(); self:addChild(self.listBtn)

    -- View as Customer button
    self.previewBtn = ISButton:new(VIEW_AS_X, VIEW_AS_Y, VIEW_AS_W, VIEW_AS_H, "View as Customer", self, self.onPreviewAsCustomer)
    self.previewBtn.backgroundColor = { r = 0.25, g = 0.25, b = 0.35, a = 1 }
    self.previewBtn.backgroundColorMouseOver = { r = 0.30, g = 0.30, b = 0.42, a = 1 }
    self.previewBtn.borderColor = C_GREY_BD
    self.previewBtn:initialise(); self.previewBtn:instantiate(); self:addChild(self.previewBtn)

    -- Status label (kept for OnShopResult compatibility)
    self.statusLabel = ISLabel:new(OWNER_W / 2, 46, 16, "", 1, 1, 1, 1, UIFont.Small, true)
    self.statusLabel.center = true
    self.statusLabel:initialise(); self:addChild(self.statusLabel)

    self:refreshInventory()
end

function Cat_ShopOwnerUI:setData(stock, earnings)
    self.stock = stock or {}
    self.earnings = earnings or 0
end

function Cat_ShopOwnerUI:refreshStockList()
    -- No-op; stock drawn directly from self.stock in render()
end

function Cat_ShopOwnerUI:refreshInventory()
    self.invItems = {}
    local player = getSpecificPlayer(0)
    if not player then return end
    local inv = player:getInventory()
    local items = inv:getItems()
    local seen = {}
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            local fullType = item:getFullType()
            if fullType ~= "Base.Money" and not seen[fullType] then
                if not item:isEquipped() then
                    seen[fullType] = true
                    local name = item:getDisplayName() or fullType
                    table.insert(self.invItems, {
                        type = fullType,
                        name = name,
                        texture = item:getTex()
                    })
                end
            end
        end
    end
end

function Cat_ShopOwnerUI:onListItem()
    if self.selectedInvIdx < 1 or self.selectedInvIdx > #self.invItems then
        self.statusLabel:setName("Select an item from inventory.")
        return
    end
    local itemData = self.invItems[self.selectedInvIdx]
    local price = tonumber(self.priceEntry:getText()) or 0
    local qty = tonumber(self.qtyEntry:getText()) or 0
    if price <= 0 or qty <= 0 then
        self.statusLabel:setName("Enter valid price and quantity.")
        return
    end
    local alwaysBuy = self.isBuyer and self.alwaysBuyToggle or false
    if self.isBuyer then
        sendClientCommand(MOD_NAME, "setBuyerWanted", {
            shopId = self.shopId,
            itemType = itemData.type,
            price = price,
            qty = qty,
            alwaysBuy = alwaysBuy,
        })
    else
        sendClientCommand(MOD_NAME, "listItem", {
            x = self.coords.x,
            y = self.coords.y,
            z = self.coords.z,
            shopId = self.shopId,
            itemType = itemData.type,
            price = price,
            qty = qty,
        })
    end
end

function Cat_ShopOwnerUI:onCollect()
    sendClientCommand(MOD_NAME, "collectEarnings", {
        x = self.coords.x,
        y = self.coords.y,
        z = self.coords.z,
        shopId = self.shopId,
    })
end

function Cat_ShopOwnerUI:onPreviewAsCustomer()
    self:onClose()
    if self.isBuyer then
        Cat_ShopSystem.OpenSellerUI(self.coords.x, self.coords.y, self.coords.z, self.shopId)
    else
        local player = getSpecificPlayer(0)
        local username = player and player:getUsername() or ""
        Cat_ShopSystem.OpenBuyerUI(self.coords.x, self.coords.y, self.coords.z, username, self.shopId)
    end
    sendClientCommand("Cat_ShopSystem", "requestStock", { x = self.coords.x, y = self.coords.y, z = self.coords.z, shopId = self.shopId })
end

function Cat_ShopOwnerUI:onRelocate()
    if not self.shopId then
        self.statusLabel:setName("No shop to relocate.")
        return
    end
    sendClientCommand(MOD_NAME, "relocateShop", {
        shopId = self.shopId,
    })
    self.statusLabel:setName("Shop unanchored. Pick up the register and claim a new one.")
end

function Cat_ShopOwnerUI:isKeyConsumed(key)
    return key == Keyboard.KEY_ESCAPE
end

function Cat_ShopOwnerUI:onKeyRelease(key)
    if key == Keyboard.KEY_ESCAPE then
        self:onClose()
        return true
    end
    return false
end

function Cat_ShopOwnerUI:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
    Cat_ShopSystem.ownerUI = nil
end

function Cat_ShopOwnerUI:render()
    ISPanel.render(self)

    local mx, my = self:getMouseX(), self:getMouseY()
    self.hoverStockIdx = 0
    self.hoverInvIdx = 0

    -- Header bar
    self:drawRect(0, 0, self.width, HEADER_H, 1, 0.08, 0.08, 0.08)

    -- Title
    local titleText = self.isBuyer and "MANAGE BUYER" or "MANAGE SHOP"
    self:drawText(titleText, TITLE_X, TITLE_Y, C_TEXT.r, C_TEXT.g, C_TEXT.b, 1, UIFont.Medium)

    -- Close text (top right)
    local closeX = OWNER_W - 80
    local closeY = 8
    local closeW = 70
    local closeH = 26
    self.closeHover = mx >= closeX and mx <= closeX + closeW and my >= closeY and my <= closeY + closeH
    local closeCol = self.closeHover and C_TEXT_DIM or C_TEXT
    self:drawText("Close", closeX, closeY, closeCol.r, closeCol.g, closeCol.b, 1, UIFont.Small)

    -- Earnings (seller only)
    if not self.isBuyer then
        local earnText = "Earnings: $" .. tostring(self.earnings)
        local earnCol = (self.earnings > 0) and C_ORANGE or C_TEXT_DIM
        local earnW = getTextManager():MeasureStringX(UIFont.Medium, earnText)
        self:drawText(earnText, COLLECT_X + (COLLECT_W - earnW) / 2, COLLECT_Y - 28, earnCol.r, earnCol.g, earnCol.b, 1, UIFont.Medium)
    end

    -- Section header
    local stockHdr = self.isBuyer and "Wanted Items:" or "Current Inventory:"
    self:drawText(stockHdr, STOCK_HDR_X, STOCK_HDR_Y + 6, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Medium)

    -- Stock list panel
    self:drawRect(STOCK_X, STOCK_Y, STOCK_W, STOCK_H, 1, C_PANEL.r, C_PANEL.g, C_PANEL.b)
    self:drawRectBorder(STOCK_X, STOCK_Y, STOCK_W, STOCK_H, 1, C_GREY_BD.r, C_GREY_BD.g, C_GREY_BD.b)

    -- Stock rows
    local stockNameMaxW = STOCK_W - 280
    local visibleStockRows = math.floor(STOCK_H / STOCK_ROW_H)
    self.stockMaxScroll = math.max(0, (#self.stock - visibleStockRows) * STOCK_ROW_H)
    self.stockScrollY = math.max(0, math.min(self.stockScrollY or 0, self.stockMaxScroll))

    for i = 1, #self.stock do
        local y = STOCK_Y + (i - 1) * STOCK_ROW_H - self.stockScrollY
        if y >= STOCK_Y and y + STOCK_ROW_H <= STOCK_Y + STOCK_H then
            local item = self.stock[i]
            local isHover = mx >= STOCK_X + 4 and mx <= STOCK_X + STOCK_W - 4 and my >= y and my < y + STOCK_ROW_H
            if isHover then self.hoverStockIdx = i end

            if isHover then
                self:drawRect(STOCK_X + 4, y, STOCK_W - 8, STOCK_ROW_H, 1, C_ROW_HOV.r, C_ROW_HOV.g, C_ROW_HOV.b)
            end

            local tex = Cat_ShopSystem.GetItemTexture(item.item)
            if tex then
                self:drawTextureScaledAspect(tex, STOCK_X + 14, y + 4, 30, 30, 1, 1, 1, 1)
            end

            local name = Cat_ShopSystem.GetItemDisplayName(item.item)
            name = truncateText(name, stockNameMaxW, UIFont.Small)
            self:drawText(name, STOCK_X + 52, y + 4, C_TEXT.r, C_TEXT.g, C_TEXT.b, 1, UIFont.Small)
            self:drawText("$" .. item.price .. " each", STOCK_X + 52, y + 22, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)

            if item.alwaysBuy then
                self:drawTextRight("Always", STOCK_X + STOCK_W - 58, y + 12, C_GREEN.r, C_GREEN.g, C_GREEN.b, 1, UIFont.Small)
            else
                self:drawTextRight("x" .. item.qty, STOCK_X + STOCK_W - 58, y + 12, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)
            end

            -- Remove X button (centered in row)
            local BOX_W = 26
            local BOX_H = 26
            local rx = STOCK_X + STOCK_W - 46
            local ry = y + (STOCK_ROW_H - BOX_H) / 2
            local hoverX = mx >= rx and mx <= rx + BOX_W and my >= ry and my <= ry + BOX_H
            local xCol = hoverX and C_RED_HOV or C_RED
            self:drawRect(rx, ry, BOX_W, BOX_H, 1, xCol.r, xCol.g, xCol.b)
            local xTextW = getTextManager():MeasureStringX(UIFont.Small, "X")
            local xTextH = getTextManager():getFontHeight(UIFont.Small)
            self:drawText("X", rx + (BOX_W - xTextW) / 2, ry + (BOX_H - xTextH) / 2, 1, 1, 1, 1, UIFont.Small)
        end
    end

    if #self.stock == 0 then
        local msg = self.isBuyer and "No wanted items set." or "No items in stock."
        local msgW = getTextManager():MeasureStringX(UIFont.Medium, msg)
        self:drawText(msg, STOCK_X + (STOCK_W - msgW) / 2, STOCK_Y + 100, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Medium)
    end

    -- Section headers for bottom area
    local listHdrText = self.isBuyer and "Add Wanted Item" or "List New Item"
    local listHdrW = getTextManager():MeasureStringX(UIFont.Medium, listHdrText)
    self:drawText(listHdrText, LIST_HDR_X + (LIST_HDR_W - listHdrW) / 2, LIST_HDR_Y + 6, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Medium)
    if not self.isBuyer then
        local histHdrW = getTextManager():MeasureStringX(UIFont.Medium, "Sale History")
        self:drawText("Sale History", HIST_HDR_X + (HIST_HDR_W - histHdrW) / 2, HIST_HDR_Y + 6, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Medium)
    end

    -- Player inventory panel
    self:drawRect(INV_X, INV_Y, INV_W, INV_H, 1, C_PANEL.r, C_PANEL.g, C_PANEL.b)
    self:drawRectBorder(INV_X, INV_Y, INV_W, INV_H, 1, C_GREY_BD.r, C_GREY_BD.g, C_GREY_BD.b)

    -- Inventory rows
    local invNameMaxW = INV_W - 60
    local visibleInvRows = math.floor(INV_H / INV_ROW_H)
    self.invMaxScroll = math.max(0, (#self.invItems - visibleInvRows) * INV_ROW_H)
    self.invScrollY = math.max(0, math.min(self.invScrollY or 0, self.invMaxScroll))

    for i = 1, #self.invItems do
        local y = INV_Y + (i - 1) * INV_ROW_H - self.invScrollY
        if y >= INV_Y and y + INV_ROW_H <= INV_Y + INV_H then
            local item = self.invItems[i]
            local isHover = mx >= INV_X + 4 and mx <= INV_X + INV_W - 4 and my >= y and my < y + INV_ROW_H
            if isHover then self.hoverInvIdx = i end

            local isSel = (self.selectedInvIdx == i)
            if isSel then
                self:drawRect(INV_X + 4, y, INV_W - 8, INV_ROW_H, 1, C_ROW_SEL.r, C_ROW_SEL.g, C_ROW_SEL.b)
            elseif isHover then
                self:drawRect(INV_X + 4, y, INV_W - 8, INV_ROW_H, 1, C_ROW_HOV.r, C_ROW_HOV.g, C_ROW_HOV.b)
            end

            if item.texture then
                self:drawTextureScaledAspect(item.texture, INV_X + 10, y + 2, 30, 30, 1, 1, 1, 1)
            end

            local name = truncateText(item.name, invNameMaxW, UIFont.Small)
            self:drawText(name, INV_X + 46, y + 8, C_TEXT.r, C_TEXT.g, C_TEXT.b, 1, UIFont.Small)
        end
    end

    if #self.invItems == 0 then
        local msg = "No items to list."
        local msgW = getTextManager():MeasureStringX(UIFont.Small, msg)
        self:drawText(msg, INV_X + (INV_W - msgW) / 2, INV_Y + 80, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)
    end

    -- Sale History panel (placeholder, seller only)
    if not self.isBuyer then
        self:drawRect(HIST_X, HIST_Y, HIST_W, HIST_H, 1, C_PANEL.r, C_PANEL.g, C_PANEL.b)
        self:drawRectBorder(HIST_X, HIST_Y, HIST_W, HIST_H, 1, C_GREY_BD.r, C_GREY_BD.g, C_GREY_BD.b)
        local histMsgW = getTextManager():MeasureStringX(UIFont.Small, "Sale history")
        self:drawText("Sale history", HIST_X + (HIST_W - histMsgW) / 2, HIST_Y + 80, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)
        local soonW = getTextManager():MeasureStringX(UIFont.Small, "coming soon...")
        self:drawText("coming soon...", HIST_X + (HIST_W - soonW) / 2, HIST_Y + 100, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)
    end

    -- Labels for price/qty (centered within their columns)
    local amtW = getTextManager():MeasureStringX(UIFont.Medium, "Amount:")
    local priceW = getTextManager():MeasureStringX(UIFont.Medium, "Price:")
    self:drawText("Amount:", AMT_LBL_X + (AMT_ENTRY_W - amtW) / 2, AMT_LBL_Y + 6, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Medium)
    self:drawText("Price:", PRICE_LBL_X + (PRICE_ENTRY_W - priceW) / 2, PRICE_LBL_Y + 6, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Medium)

    -- Always Buying toggle (buyer only)
    if self.isBuyer then
        local tCol = self.alwaysBuyToggle and C_GREEN or C_PANEL
        self:drawRect(TOGGLE_X, TOGGLE_Y, TOGGLE_W, TOGGLE_H, 1, tCol.r, tCol.g, tCol.b)
        self:drawRectBorder(TOGGLE_X, TOGGLE_Y, TOGGLE_W, TOGGLE_H, 1, C_GREY_BD.r, C_GREY_BD.g, C_GREY_BD.b)
        if self.alwaysBuyToggle then
            local checkW = getTextManager():MeasureStringX(UIFont.Small, "X")
            local checkH = getTextManager():getFontHeight(UIFont.Small)
            self:drawText("X", TOGGLE_X + (TOGGLE_W - checkW) / 2, TOGGLE_Y + (TOGGLE_H - checkH) / 2, C_TEXT.r, C_TEXT.g, C_TEXT.b, 1, UIFont.Small)
        end
        self:drawText("Always Buying", TOGGLE_X + TOGGLE_W + 8, TOGGLE_Y + 1, C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1, UIFont.Small)
    end
end

function Cat_ShopOwnerUI:onMouseWheel(del)
    local mx, my = self:getMouseX(), self:getMouseY()

    if mx >= STOCK_X and mx <= STOCK_X + STOCK_W and my >= STOCK_Y and my <= STOCK_Y + STOCK_H then
        self.stockScrollY = (self.stockScrollY or 0) + del * STOCK_ROW_H
        return true
    end

    if mx >= INV_X and mx <= INV_X + INV_W and my >= INV_Y and my <= INV_Y + INV_H then
        self.invScrollY = (self.invScrollY or 0) + del * INV_ROW_H
        return true
    end

    return false
end

function Cat_ShopOwnerUI:onMouseDown(x, y)
    ISPanel.onMouseDown(self, x, y)

    -- Close click
    if x >= OWNER_W - 80 and x <= OWNER_W - 10 and y >= 8 and y <= 34 then
        self:onClose()
        return
    end

    -- Stock remove clicks
    local BOX_W = 26
    local BOX_H = 26
    for i = 1, #self.stock do
        local ry = STOCK_Y + (i - 1) * STOCK_ROW_H - (self.stockScrollY or 0)
        local rx = STOCK_X + STOCK_W - 46
        local rby = ry + (STOCK_ROW_H - BOX_H) / 2
        if x >= rx and x <= rx + BOX_W and y >= rby and y <= rby + BOX_H then
            self:removeStock(i)
            return
        end
    end

    -- Inventory selection clicks
    for i = 1, #self.invItems do
        local ry = INV_Y + (i - 1) * INV_ROW_H - (self.invScrollY or 0)
        if x >= INV_X + 4 and x <= INV_X + INV_W - 4 and y >= ry and y < ry + INV_ROW_H then
            self.selectedInvIdx = i
            return
        end
    end

    -- Always Buying toggle click
    if self.isBuyer then
        if x >= TOGGLE_X and x <= TOGGLE_X + TOGGLE_W and y >= TOGGLE_Y and y <= TOGGLE_Y + TOGGLE_H then
            self.alwaysBuyToggle = not self.alwaysBuyToggle
            return
        end
    end
end

function Cat_ShopOwnerUI:removeStock(idx)
    if idx < 1 or idx > #self.stock then return end
    local item = self.stock[idx]
    if self.isBuyer then
        sendClientCommand(MOD_NAME, "removeBuyerWanted", {
            shopId = self.shopId,
            itemType = item.item,
        })
    else
        sendClientCommand(MOD_NAME, "removeStock", {
            x = self.coords.x,
            y = self.coords.y,
            z = self.coords.z,
            shopId = self.shopId,
            itemType = item.item,
            price = item.price,
            qty = item.qty,
        })
    end
end
