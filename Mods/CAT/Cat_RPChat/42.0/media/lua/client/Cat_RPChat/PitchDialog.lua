require "ISUI/ISPanelJoypad"

Cat_RPChat_PitchDialog = ISPanelJoypad:derive("Cat_RPChat_PitchDialog")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6

function Cat_RPChat_PitchDialog:initialise()
    ISPanel.initialise(self)

    local entryWid = 80
    local y = UI_BORDER_SPACING + FONT_HGT_SMALL + UI_BORDER_SPACING

    self.label = ISLabel:new(UI_BORDER_SPACING + 1, y, FONT_HGT_SMALL, "Voice Pitch (0.5 - 2.0):", 1, 1, 1, 1, UIFont.Small, true)
    self.label:initialise()
    self:addChild(self.label)

    y = self.label:getBottom() + 4

    self.entry = ISTextEntryBox:new(tostring(self.currentPitch or 1.0), UI_BORDER_SPACING + 1, y, entryWid, BUTTON_HGT)
    self.entry:initialise()
    self.entry:instantiate()
    self.entry:setText(tostring(self.currentPitch or 1.0))
    self:addChild(self.entry)

    local buttonWid = math.max(
        getTextManager():MeasureStringX(UIFont.Small, "Ok"),
        getTextManager():MeasureStringX(UIFont.Small, "Cancel")
    ) + UI_BORDER_SPACING * 2

    self.yes = ISButton:new((self:getWidth() - UI_BORDER_SPACING) / 2 - buttonWid, self.entry:getBottom() + UI_BORDER_SPACING, buttonWid, BUTTON_HGT, "Ok", self, Cat_RPChat_PitchDialog.onButton)
    self.yes.internal = "OK"
    self.yes:initialise()
    self.yes:enableAcceptColor()
    self:addChild(self.yes)

    self.no = ISButton:new(self.yes:getRight() + UI_BORDER_SPACING, self.yes:getY(), buttonWid, BUTTON_HGT, "Cancel", self, Cat_RPChat_PitchDialog.onButton)
    self.no.internal = "CANCEL"
    self.no:initialise()
    self.no:enableCancelColor()
    self:addChild(self.no)

    self:setHeight(self.yes:getBottom() + UI_BORDER_SPACING + 1)

    self:insertNewLineOfButtons(self.yes, self.no)
end

function Cat_RPChat_PitchDialog:destroy()
    self:setVisible(false)
    self:removeFromUIManager()
    if JoypadState.players[self.playerNum + 1] then
        setJoypadFocus(self.playerNum, self.prevFocus)
    end
end

function Cat_RPChat_PitchDialog:onButton(button)
    if button.internal == "OK" then
        local text = self.entry:getText():gsub("^%s*(.-)%s*$", "%1")
        local p = tonumber(text)
        if p and self.onConfirm then
            p = math.max(0.5, math.min(2.0, p))
            self.onConfirm(p)
        end
    end
    self:destroy()
end

function Cat_RPChat_PitchDialog:prerender()
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    self:drawTextCentre("Change Voice Pitch", self:getWidth() / 2, UI_BORDER_SPACING, 1, 1, 1, 1, UIFont.Small)
end

-- Drag support
function Cat_RPChat_PitchDialog:onMouseDown(x, y)
    if not self.moveWithMouse then return end
    self.downX = x
    self.downY = y
    self.moving = true
    self:bringToTop()
end

function Cat_RPChat_PitchDialog:onMouseMove(dx, dy)
    if self.moveWithMouse and self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:bringToTop()
    end
end

function Cat_RPChat_PitchDialog:onMouseMoveOutside(dx, dy)
    if self.moveWithMouse and self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:bringToTop()
    end
end

function Cat_RPChat_PitchDialog:onMouseUp(x, y)
    self.moving = false
end

function Cat_RPChat_PitchDialog:onMouseUpOutside(x, y)
    self.moving = false
end

function Cat_RPChat_PitchDialog:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData)
    self.joypadIndexY = 1
    self.joypadIndex = 1
    self.entry:setJoypadFocused(true)
end

function Cat_RPChat_PitchDialog:onJoypadDown(button)
    ISPanelJoypad.onJoypadDown(self, button)
    if button == Joypad.BButton then
        self:onButton(self.no)
    end
end

function Cat_RPChat_PitchDialog:new(x, y, currentPitch, onConfirm)
    local width = 280
    local height = 150
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
    o.currentPitch = currentPitch
    o.onConfirm = onConfirm
    o.moveWithMouse = true
    return o
end

return Cat_RPChat_PitchDialog
