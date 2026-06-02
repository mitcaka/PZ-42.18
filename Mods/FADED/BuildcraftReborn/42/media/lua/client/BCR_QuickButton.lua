if isServer() then return end

require "BCR_Utils"
require "BCR_Scale"
require "BCR_HubWindow"
require "BCR_UserData"

BCR_QuickButton = BCR_QuickButton or {}
BCR_QuickButton.buttons = BCR_QuickButton.buttons or {}

local QuickButton = ISButton:derive("BCR_QuickButtonButton")

local function px(value)
    return BCR_Scale and BCR_Scale.px and BCR_Scale.px(value) or value
end

local function labelText()
    return BCR_Utils.tr("UI_BCR_QuickButton", "Craft / Build")
end

local function labelWidth()
    local tm = getTextManager and getTextManager() or nil
    if not tm then return string.len(labelText()) * 7 end
    local font = BCR_Scale and BCR_Scale.font and BCR_Scale.font(14) or UIFont.Small
    return tm:MeasureStringX(font, labelText())
end

local function buttonWidth()
    return math.max(px(88), labelWidth() + px(18))
end

local function buttonHeight()
    return px(24)
end

local function playerIndexFor(playerIndex)
    return tonumber(playerIndex) or 0
end

local function defaultButtonPosition(playerIndex)
    local left = getPlayerScreenLeft and getPlayerScreenLeft(playerIndex) or 0
    local top = getPlayerScreenTop and getPlayerScreenTop(playerIndex) or 0
    local height = getPlayerScreenHeight and getPlayerScreenHeight(playerIndex) or 720
    return left + px(12), top + math.max(px(80), height - px(92))
end

local function clampPosition(x, y)
    if BCR_Utils and BCR_Utils.clampToScreen then
        return BCR_Utils.clampToScreen(x, y, buttonWidth(), buttonHeight())
    end
    return x, y
end

local function buttonPosition(playerIndex)
    local layout = BCR_UserData and BCR_UserData.getQuickButtonLayout and BCR_UserData.getQuickButtonLayout(playerIndex) or nil
    if layout then
        return clampPosition(layout.x, layout.y)
    end
    return defaultButtonPosition(playerIndex)
end

function QuickButton:new(x, y, playerIndex)
    local o = ISButton.new(self, x, y, buttonWidth(), buttonHeight(), labelText(), BCR_QuickButton, BCR_QuickButton.onClick)
    setmetatable(o, self)
    self.__index = self
    o.playerIndex = playerIndexFor(playerIndex)
    o.dragging = false
    o.dragMoved = false
    o.dragX = 0
    o.dragY = 0
    o.dragStartX = x
    o.dragStartY = y
    return o
end

function QuickButton:onMouseDown(x, y)
    self.dragging = true
    self.dragMoved = false
    self.dragX = x
    self.dragY = y
    self.dragStartX = self:getX()
    self.dragStartY = self:getY()
    return ISButton.onMouseDown(self, x, y)
end

function QuickButton:onMouseMove(dx, dy)
    if self.dragging then
        local mx = getMouseX and getMouseX() or self:getX()
        local my = getMouseY and getMouseY() or self:getY()
        local nx, ny = clampPosition(mx - self.dragX, my - self.dragY)
        if math.abs(nx - self.dragStartX) > 3 or math.abs(ny - self.dragStartY) > 3 then
            self.dragMoved = true
        end
        if self.dragMoved then
            self:setX(nx)
            self:setY(ny)
            return true
        end
    end
    return ISButton.onMouseMove(self, dx, dy)
end

function QuickButton:onMouseMoveOutside(dx, dy)
    return self:onMouseMove(dx, dy)
end

function QuickButton:onMouseUp(x, y)
    local moved = self.dragMoved
    self.dragging = false
    self.dragMoved = false
    if moved then
        local nx, ny = clampPosition(self:getX(), self:getY())
        self:setX(nx)
        self:setY(ny)
        if BCR_UserData and BCR_UserData.setQuickButtonLayout then
            BCR_UserData.setQuickButtonLayout(self.playerIndex or 0, nx, ny)
        end
        return true
    end
    return ISButton.onMouseUp(self, x, y)
end

function QuickButton:onMouseUpOutside(x, y)
    return self:onMouseUp(x, y)
end

function BCR_QuickButton.onClick(target, button)
    local playerIndex = button and button.playerIndex or 0
    if BCR_HubWindow and BCR_HubWindow.toggle then
        BCR_HubWindow.toggle(playerIndex)
    end
end

function BCR_QuickButton.ensure(playerIndex)
    playerIndex = playerIndexFor(playerIndex)
    local existing = BCR_QuickButton.buttons[playerIndex]
    if existing then
        local x, y = buttonPosition(playerIndex)
        existing:setX(x)
        existing:setY(y)
        existing:setWidth(buttonWidth())
        existing:setHeight(buttonHeight())
        existing.font = BCR_Scale and BCR_Scale.font and BCR_Scale.font(14) or UIFont.Small
        existing:setTitle(labelText())
        existing:setVisible(true)
        return existing
    end

    local x, y = buttonPosition(playerIndex)
    local button = QuickButton:new(x, y, playerIndex)
    button:initialise()
    button:instantiate()
    button.font = BCR_Scale and BCR_Scale.font and BCR_Scale.font(14) or UIFont.Small
    button.backgroundColor = { r = 0.12, g = 0.16, b = 0.17, a = 0.88 }
    button.backgroundColorMouseOver = { r = 0.20, g = 0.32, b = 0.36, a = 0.96 }
    button.borderColor = { r = 0.78, g = 0.78, b = 0.76, a = 0.42 }
    button:addToUIManager()
    BCR_QuickButton.buttons[playerIndex] = button
    return button
end

function BCR_QuickButton.hide(playerIndex)
    local button = BCR_QuickButton.buttons[playerIndexFor(playerIndex)]
    if button then
        button:setVisible(false)
    end
end

if BCR_Scale and BCR_Scale.onChange then
    BCR_Scale.onChange(function()
        for playerIndex, _ in pairs(BCR_QuickButton.buttons) do
            BCR_QuickButton.ensure(playerIndex)
        end
    end)
end

return BCR_QuickButton
