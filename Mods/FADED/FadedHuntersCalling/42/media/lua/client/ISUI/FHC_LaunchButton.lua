-- FHC_LaunchButton.lua
-- Small floating on-screen button that opens the Hunter Hub.
-- Draggable; position persists per-player in modData.
-- Uses an external PNG icon if present (media/ui/FHC_LaunchButton.png),
-- otherwise falls back to a leather-amber square with "FHC" text.

require "ISUI/ISPanel"
require "FHC_Constants"
require "FHC_Sandbox"
require "FHC_Utils"

if isServer() then return end

FHC.UI = FHC.UI or {}

FHC_LaunchButton = ISPanel:derive("FHC_LaunchButton")

local C  = FHC.COLOR
local U  = FHC.Utils
local SB = FHC.SB

local BTN_SIZE = 56
local MD_KEY_POS = "FHC_LaunchBtnPos"

local function loadTexture()
    -- User-supplied Hunter Hub icon.
    local tex = getTexture("media/ui/FHC_LaunchButton.png")
    return tex
end

function FHC_LaunchButton:initialise()
    ISPanel.initialise(self)
    self.icon = loadTexture()
end

function FHC_LaunchButton:prerender()
    -- Background plate (leather + brass border).
    self:drawRect(0, 0, self.width, self.height, 0.85,
        C.LeatherDark.r, C.LeatherDark.g, C.LeatherDark.b)
    self:drawRectBorder(0, 0, self.width, self.height, 1.0,
        C.Brass.r, C.Brass.g, C.Brass.b)

    if self.icon then
        self:drawTextureScaled(self.icon, 3, 3,
            self.width - 6, self.height - 6, 1.0, 1.0, 1.0, 1.0)
    else
        -- Placeholder: amber hub mark centred.
        self:drawText("HUB", 7, 15,
            C.Amber.r, C.Amber.g, C.Amber.b, 1.0, UIFont.Medium)
    end

    if self.mouseOver then
        self:drawRectBorder(0, 0, self.width, self.height, 1.0,
            C.Amber.r, C.Amber.g, C.Amber.b)
    end
end

function FHC_LaunchButton:onMouseMove(dx, dy)
    self.mouseOver = true
    if self.dragging then
        self:setX(self:getX() + dx)
        self:setY(self:getY() + dy)
    end
end

function FHC_LaunchButton:onMouseMoveOutside()
    self.mouseOver = false
    if self.dragging then
        local mx, my = getMouseX(), getMouseY()
        self:setX(mx - math.floor(self.width / 2))
        self:setY(my - math.floor(self.height / 2))
    end
end

function FHC_LaunchButton:onMouseDown(x, y)
    self.dragStartX = x
    self.dragStartY = y
    self.pressedAt = getTimestampMs and getTimestampMs() or 0
end

function FHC_LaunchButton:onMouseUp(x, y)
    local now = getTimestampMs and getTimestampMs() or 0
    local heldMs = now - (self.pressedAt or 0)
    local movedFar = self.dragging
    self.dragging = false
    self.pressedAt = nil
    if not movedFar and heldMs < 400 then
        -- Treat as a click.
        if FHC.UI.Main then FHC.UI.Main.toggle() end
    end
    self:savePos()
end

function FHC_LaunchButton:onMouseUpOutside(x, y)
    self.dragging = false
    self.pressedAt = nil
    self:savePos()
end

-- Right-click hides the button until next session (player can re-enable in Settings tab).
function FHC_LaunchButton:onRightMouseUp(x, y)
    self:setVisible(false)
end

function FHC_LaunchButton:onMouseDownOutside(x, y) end

-- Hold + drag detection: switches into drag mode once the cursor moves a few pixels.
function FHC_LaunchButton:update()
    if self.pressedAt and not self.dragging then
        local mx, my = getMouseX(), getMouseY()
        local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
        local localX = mx - ax
        local localY = my - ay
        if math.abs(localX - (self.dragStartX or 0)) > 4
            or math.abs(localY - (self.dragStartY or 0)) > 4 then
            self.dragging = true
        end
    end
end

function FHC_LaunchButton:savePos()
    if not self.player then return end
    self.player:getModData()[MD_KEY_POS] = { x = self:getX(), y = self:getY() }
end

function FHC_LaunchButton:new(x, y, player)
    local o = ISPanel.new(self, x, y, BTN_SIZE, BTN_SIZE)
    o.player = player
    o.background = false
    o.moveWithMouse = false
    o:setAlwaysOnTop(true)
    return o
end

-- Singleton helpers
local instance = nil

FHC.UI.LaunchButton = FHC.UI.LaunchButton or {}

function FHC.UI.LaunchButton.ensure(player)
    if instance then return instance end
    if not SB.guiEnabled() then return end
    local md = player and player:getModData() or {}
    local pos = md[MD_KEY_POS]
    local sw = getCore():getScreenWidth()
    local defaultX, defaultY = sw - BTN_SIZE - 16, 220
    local x = (pos and tonumber(pos.x)) or defaultX
    local y = (pos and tonumber(pos.y)) or defaultY
    instance = FHC_LaunchButton:new(x, y, player)
    instance:initialise(); instance:instantiate()
    instance:addToUIManager()
    return instance
end

function FHC.UI.LaunchButton.show()
    if instance then instance:setVisible(true) end
end

local function onGameStart()
    local player = getSpecificPlayer(0)
    if not player then return end
    FHC.UI.LaunchButton.ensure(player)
end
Events.OnGameStart.Add(onGameStart)
