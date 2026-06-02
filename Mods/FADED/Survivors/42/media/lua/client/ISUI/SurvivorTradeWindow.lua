require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"
require "SurvivorTrade"

SurvivorTradeWindow = ISCollapsableWindow:derive("SurvivorTradeWindow")
SurvivorTradeWindow.instance = SurvivorTradeWindow.instance or nil

local function predicateAll()
    return true
end

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function screenSize()
    local core = getCore and getCore() or nil
    return core and core.getScreenWidth and core:getScreenWidth() or 1280,
        core and core.getScreenHeight and core:getScreenHeight() or 720
end

local function selectedRow(list)
    local selected = list and list.items and list.items[list.selected] or nil
    return selected and selected.item or nil
end

local function drawTradeRow(list, y, item, alt)
    local row = item and item.item or {}
    if alt then list:drawRect(0, y, list.width, list.itemheight, 0.05, 1, 1, 1) end
    if list.selected == item.index then list:drawRect(0, y, list.width, list.itemheight, 0.20, 0.28, 0.58, 0.86) end
    list:drawText(tostring(row.label or row.name or row.fullType or "Item"), 6, y + 4, 0.94, 0.96, 0.98, 1, UIFont.Small)
    if row.count then
        list:drawTextRight("x" .. tostring(row.count), list.width - 62, y + 4, 0.74, 0.80, 0.86, 1, UIFont.Small)
    end
    list:drawTextRight("V" .. tostring(row.value or 0), list.width - 6, y + 4, 0.54, 0.86, 0.62, 1, UIFont.Small)
    return y + list.itemheight
end

function SurvivorTradeWindow:new(x, y, width, height, player, zombie)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.zombie = zombie
    o.npcId = BanditUtils.GetCharacterID(zombie)
    o.npcName = (BanditBrain.Get(zombie) or {}).fullname or "Survivor"
    o.title = "Direct Survivor Trade"
    o.resizable = false
    o.stockRows = {}
    o.status = "Requesting survivor stock..."
    o.waiting = false
    return o
end

function SurvivorTradeWindow:initialise()
    ISCollapsableWindow.initialise(self)
    self:createChildren()
end

function SurvivorTradeWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local pad = 12
    local listY = 100
    local listW = math.floor((self.width - (pad * 3)) / 2)
    local listH = self.height - listY - 54

    self.playerList = ISScrollingListBox:new(pad, listY, listW, listH)
    self.playerList:initialise()
    self.playerList:instantiate()
    self.playerList.itemheight = 23
    self.playerList.doDrawItem = drawTradeRow
    self:addChild(self.playerList)

    self.stockList = ISScrollingListBox:new((pad * 2) + listW, listY, listW, listH)
    self.stockList:initialise()
    self.stockList:instantiate()
    self.stockList.itemheight = 23
    self.stockList.doDrawItem = drawTradeRow
    self:addChild(self.stockList)

    local buttonY = self.height - 38
    self.refreshButton = ISButton:new(pad, buttonY, 110, 25, "Refresh", self, SurvivorTradeWindow.onRefresh)
    self.refreshButton:initialise()
    self:addChild(self.refreshButton)

    self.tradeButton = ISButton:new(math.floor((self.width - 170) / 2), buttonY, 170, 25, "Exchange Selected", self, SurvivorTradeWindow.onTrade)
    self.tradeButton:initialise()
    self:addChild(self.tradeButton)

    self.closeButton = ISButton:new(self.width - pad - 90, buttonY, 90, 25, "Close", self, SurvivorTradeWindow.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)

    self:refreshPlayerItems()
    self:requestStock()
end

function SurvivorTradeWindow:refreshPlayerItems()
    if not self.playerList then return end
    self.playerList:clear()

    local inventory = self.player and self.player:getInventory() or nil
    if not inventory then return end

    local items = ArrayList.new()
    inventory:getAllEvalRecurse(predicateAll, items)
    local rows = {}
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if SurvivorTrade.CanOfferItem(self.player, item) and item.getID then
            table.insert(rows, {
                itemId=item:getID(),
                fullType=item:getFullType(),
                label=SurvivorTrade.GetDisplayName(item, item:getFullType()),
                value=SurvivorTrade.GetItemValue(item),
            })
        end
    end
    table.sort(rows, function(a, b)
        if tostring(a.label) == tostring(b.label) then return tonumber(a.value) < tonumber(b.value) end
        return tostring(a.label) < tostring(b.label)
    end)
    for _, row in ipairs(rows) do
        self.playerList:addItem(row.label, row)
    end
end

function SurvivorTradeWindow:refreshStock()
    if not self.stockList then return end
    self.stockList:clear()
    for _, row in ipairs(self.stockRows or {}) do
        self.stockList:addItem(tostring(row.label or row.fullType), row)
    end
end

function SurvivorTradeWindow:requestStock()
    if not self.player or not self.npcId then return end
    self.waiting = true
    self.status = "Requesting survivor stock..."
    sendClientCommand(self.player, "Commands", "SurvivorTradeRequest", {npcId=self.npcId})
end

function SurvivorTradeWindow:onRefresh()
    self:refreshPlayerItems()
    self:requestStock()
end

function SurvivorTradeWindow:onTrade()
    if self.waiting then return end
    local offer = selectedRow(self.playerList)
    local requested = selectedRow(self.stockList)
    if not offer or not requested then
        self.status = "Select one item from each column."
        return
    end
    if (tonumber(offer.value) or 0) < (tonumber(requested.value) or 0) then
        self.status = "Your offer value is too low for that item."
        return
    end

    self.waiting = true
    self.status = "Confirming barter with the survivor..."
    sendClientCommand(self.player, "Commands", "SurvivorTradeExchange", {
        npcId=self.npcId,
        offerItemId=offer.itemId,
        stockType=requested.fullType,
    })
end

function SurvivorTradeWindow:onClose()
    self:close()
end

function SurvivorTradeWindow:prerender()
    ISCollapsableWindow.prerender(self)
    self:drawText("Trading with " .. tostring(self.npcName), 12, 30, 0.94, 0.96, 0.98, 1, UIFont.Medium)
    self:drawText("Select one item to offer and one item to receive. Excess value is not returned. Stock refreshes daily.", 12, 54, 0.72, 0.78, 0.84, 1, UIFont.Small)
    self:drawText("Your Offer", 12, 80, 0.54, 0.86, 0.62, 1, UIFont.Small)
    self:drawText("Survivor Stock", math.floor(self.width / 2) + 6, 80, 0.54, 0.72, 0.96, 1, UIFont.Small)
    self:drawText(tostring(self.status or ""), 12, self.height - 58, 0.88, 0.78, 0.50, 1, UIFont.Small)
    self.tradeButton.enable = not self.waiting
    self.refreshButton.enable = not self.waiting
end

function SurvivorTradeWindow:receiveStock(args)
    if not args or tostring(args.npcId) ~= tostring(self.npcId) then return end
    self.stockRows = args.stock or {}
    self.npcName = args.npcName or self.npcName
    self.status = tostring(args.message or "Select one item from each column.")
    self.waiting = false
    self:refreshPlayerItems()
    self:refreshStock()
end

function SurvivorTradeWindow:close()
    SurvivorTradeWindow.instance = nil
    self:removeFromUIManager()
end

function SurvivorTradeWindow.show(player, zombie)
    if not player or not zombie then return end
    if SurvivorTradeWindow.instance then SurvivorTradeWindow.instance:close() end

    local sw, sh = screenSize()
    local width = math.min(760, sw - 24)
    local height = math.min(470, sh - 24)
    local x = clamp(getMouseX and getMouseX() or math.floor((sw - width) / 2), 8, math.max(8, sw - width - 8))
    local y = clamp(getMouseY and getMouseY() or math.floor((sh - height) / 2), 8, math.max(8, sh - height - 8))

    local ui = SurvivorTradeWindow:new(x, y, width, height, player, zombie)
    ui:initialise()
    ui:instantiate()
    ui:addToUIManager()
    SurvivorTradeWindow.instance = ui
    return ui
end

function SurvivorTradeWindow.receiveServerStock(args)
    if SurvivorTradeWindow.instance then
        SurvivorTradeWindow.instance:receiveStock(args)
    end
end

return SurvivorTradeWindow
