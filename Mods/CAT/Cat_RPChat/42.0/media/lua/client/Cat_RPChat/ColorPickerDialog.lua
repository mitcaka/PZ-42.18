require "ISUI/ISPanelJoypad"

Cat_RPChat_ColorPickerDialog = ISPanelJoypad:derive("Cat_RPChat_ColorPickerDialog")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6

function Cat_RPChat_ColorPickerDialog:initialise()
    ISPanel.initialise(self)

    local entryWid = 55
    local labelWid = math.max(
        getTextManager():MeasureStringX(UIFont.Small, "R:"),
        getTextManager():MeasureStringX(UIFont.Small, "G:"),
        getTextManager():MeasureStringX(UIFont.Small, "B:")
    ) + 4

    local y = UI_BORDER_SPACING + FONT_HGT_SMALL + UI_BORDER_SPACING

    -- R label + entry
    self.labelR = ISLabel:new(UI_BORDER_SPACING + 1, y + (BUTTON_HGT - FONT_HGT_SMALL) / 2, FONT_HGT_SMALL, "R:", 1, 0.3, 0.3, 1, UIFont.Small, true)
    self.labelR:initialise()
    self:addChild(self.labelR)

    self.entryR = ISTextEntryBox:new(tostring(self.colorR or 255), UI_BORDER_SPACING + labelWid + 4, y, entryWid, BUTTON_HGT)
    self.entryR:initialise()
    self.entryR:instantiate()
    self.entryR:setOnlyNumbers(true)
    self:addChild(self.entryR)

    -- G label + entry
    self.labelG = ISLabel:new(self.entryR:getRight() + UI_BORDER_SPACING, y + (BUTTON_HGT - FONT_HGT_SMALL) / 2, FONT_HGT_SMALL, "G:", 0.3, 1, 0.3, 1, UIFont.Small, true)
    self.labelG:initialise()
    self:addChild(self.labelG)

    self.entryG = ISTextEntryBox:new(tostring(self.colorG or 255), self.labelG:getRight() + 4, y, entryWid, BUTTON_HGT)
    self.entryG:initialise()
    self.entryG:instantiate()
    self.entryG:setOnlyNumbers(true)
    self:addChild(self.entryG)

    -- B label + entry
    self.labelB = ISLabel:new(self.entryG:getRight() + UI_BORDER_SPACING, y + (BUTTON_HGT - FONT_HGT_SMALL) / 2, FONT_HGT_SMALL, "B:", 0.3, 0.3, 1, 1, UIFont.Small, true)
    self.labelB:initialise()
    self:addChild(self.labelB)

    self.entryB = ISTextEntryBox:new(tostring(self.colorB or 255), self.labelB:getRight() + 4, y, entryWid, BUTTON_HGT)
    self.entryB:initialise()
    self.entryB:instantiate()
    self.entryB:setOnlyNumbers(true)
    self:addChild(self.entryB)

    local totalWid = self.entryB:getRight() + UI_BORDER_SPACING + 1
    self:setWidth(totalWid)

    local buttonWid = math.max(
        getTextManager():MeasureStringX(UIFont.Small, "Ok"),
        getTextManager():MeasureStringX(UIFont.Small, "Cancel")
    ) + UI_BORDER_SPACING * 2

    self.yes = ISButton:new((self:getWidth() - UI_BORDER_SPACING) / 2 - buttonWid, self.entryR:getBottom() + UI_BORDER_SPACING, buttonWid, BUTTON_HGT, "Ok", self, Cat_RPChat_ColorPickerDialog.onButton)
    self.yes.internal = "OK"
    self.yes:initialise()
    self.yes:enableAcceptColor()
    self:addChild(self.yes)

    self.no = ISButton:new(self.yes:getRight() + UI_BORDER_SPACING, self.yes:getY(), buttonWid, BUTTON_HGT, "Cancel", self, Cat_RPChat_ColorPickerDialog.onButton)
    self.no.internal = "CANCEL"
    self.no:initialise()
    self.no:enableCancelColor()
    self:addChild(self.no)

    self:setHeight(self.yes:getBottom() + UI_BORDER_SPACING + 1)

    self:insertNewLineOfButtons(self.yes, self.no)
end

function Cat_RPChat_ColorPickerDialog:destroy()
    self:setVisible(false)
    self:removeFromUIManager()
    if JoypadState.players[self.playerNum + 1] then
        setJoypadFocus(self.playerNum, self.prevFocus)
    end
end

function Cat_RPChat_ColorPickerDialog:onButton(button)
    if button.internal == "OK" then
        local r = tonumber(self.entryR:getText()) or 255
        local g = tonumber(self.entryG:getText()) or 255
        local b = tonumber(self.entryB:getText()) or 255
        r = math.max(0, math.min(255, r))
        g = math.max(0, math.min(255, g))
        b = math.max(0, math.min(255, b))
        if self.onConfirm then
            self.onConfirm(r, g, b)
        end
    end
    self:destroy()
end

function Cat_RPChat_ColorPickerDialog:prerender()
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    self:drawTextCentre("Change Name Color", self:getWidth() / 2, UI_BORDER_SPACING, 1, 1, 1, 1, UIFont.Small)
end

-- Drag support
function Cat_RPChat_ColorPickerDialog:onMouseDown(x, y)
    if not self.moveWithMouse then return end
    self.downX = x
    self.downY = y
    self.moving = true
    self:bringToTop()
end

function Cat_RPChat_ColorPickerDialog:onMouseMove(dx, dy)
    if self.moveWithMouse and self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:bringToTop()
    end
end

function Cat_RPChat_ColorPickerDialog:onMouseMoveOutside(dx, dy)
    if self.moveWithMouse and self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:bringToTop()
    end
end

function Cat_RPChat_ColorPickerDialog:onMouseUp(x, y)
    self.moving = false
end

function Cat_RPChat_ColorPickerDialog:onMouseUpOutside(x, y)
    self.moving = false
end

function Cat_RPChat_ColorPickerDialog:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData)
    self.joypadIndexY = 1
    self.joypadIndex = 1
    self.entryR:setJoypadFocused(true)
end

function Cat_RPChat_ColorPickerDialog:onJoypadDown(button)
    ISPanelJoypad.onJoypadDown(self, button)
    if button == Joypad.BButton then
        self:onButton(self.no)
    end
end

function Cat_RPChat_ColorPickerDialog:new(x, y, currentColor, onConfirm)
    local width = 300
    local height = 130
    local player = getPlayer()
    local playerNum = player and player:getPlayerNum() or 0
    local o = ISPanelJoypad:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.playerNum = playerNum
    if y == 0 then
        o.y = getPlayerScreenTop(playerNum) + (getPlayerScreenHeight(playerNum) - height) / 2
        o:setY(o.y)
    end
    if x == 0 then
        o.x = getPlayerScreenLeft(playerNum) + (getPlayerScreenWidth(playerNum) - width) / 2
        o:setX(o.x)
    end
    o.backgroundColor = {r = 0, g = 0, b = 0, a = 0.85}
    o.borderColor = {r = 0.4, g = 0.4, b = 0.4, a = 1}
    o.width = width
    o.height = height
    o.anchorLeft = true
    o.anchorRight = true
    o.anchorTop = true
    o.anchorBottom = true
    o.colorR = currentColor and currentColor[1] or 255
    o.colorG = currentColor and currentColor[2] or 255
    o.colorB = currentColor and currentColor[3] or 255
    o.onConfirm = onConfirm
    o.moveWithMouse = true
    return o
end

return Cat_RPChat_ColorPickerDialog
