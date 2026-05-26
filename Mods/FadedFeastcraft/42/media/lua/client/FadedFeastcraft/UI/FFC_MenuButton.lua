require "ISUI/ISPanel"
require "FadedFeastcraft/FFC_Boot"
require "FadedFeastcraft/UI/FFC_Theme"

FadedFeastcraft = FadedFeastcraft or {}

local Theme = FadedFeastcraft.Theme

FFC_MenuButton = ISPanel:derive("FFC_MenuButton")
FFC_MenuButton.instance = nil

local function loadIcon()
    if not getTexture then return nil end
    local ok, texture = pcall(getTexture, "media/ui/FFC_CookingIcon.png")
    if ok then return texture end
    return nil
end

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function screenBounds(width, height)
    local core = getCore and getCore() or nil
    local screenW = core and core:getScreenWidth() or 1280
    local screenH = core and core:getScreenHeight() or 720
    return math.max(0, screenW - width), math.max(0, screenH - height)
end

local function playerModData()
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or not player.getModData then return nil end
    return player:getModData()
end

local function savedPosition()
    local md = playerModData()
    if not md then return nil, nil end
    local x = tonumber(md.FFC_MenuButtonX)
    local y = tonumber(md.FFC_MenuButtonY)
    if x == nil or y == nil then return nil, nil end
    return x, y
end

local function savePosition(x, y)
    local md = playerModData()
    if not md then return end
    md.FFC_MenuButtonX = math.floor(tonumber(x) or 12)
    md.FFC_MenuButtonY = math.floor(tonumber(y) or 96)
end

function FFC_MenuButton:new(x, y)
    local o = ISPanel:new(x, y, 44, 44)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    o.borderColor = { r = 0, g = 0.72, b = 1, a = 0.85 }
    o.moveWithMouse = false
    o.hovered = false
    o.dragging = false
    o.dragMoved = false
    o.dragDistance = 0
    o.icon = loadIcon()
    return o
end

function FFC_MenuButton:moveBy(dx, dy)
    dx = tonumber(dx) or 0
    dy = tonumber(dy) or 0
    if dx == 0 and dy == 0 then return end
    local maxX, maxY = screenBounds(self.width, self.height)
    local newX = clamp((self.x or 0) + dx, 0, maxX)
    local newY = clamp((self.y or 0) + dy, 0, maxY)
    self:setX(newX)
    self:setY(newY)
    self.dragDistance = (self.dragDistance or 0) + math.abs(dx) + math.abs(dy)
    if self.dragDistance > 4 then
        self.dragMoved = true
    end
end

function FFC_MenuButton:applySavedPosition()
    local x, y = savedPosition()
    if x == nil or y == nil then return false end
    local maxX, maxY = screenBounds(self.width, self.height)
    self:setX(clamp(x, 0, maxX))
    self:setY(clamp(y, 0, maxY))
    self.loadedPlayerPosition = true
    return true
end

function FFC_MenuButton:prerender()
    local bg = Theme.colors.bg
    local glow = self.hovered and 0.95 or 0.62
    self:drawRect(0, 0, self.width, self.height, 0.78, bg.r, bg.g, bg.b)
    self:drawRectBorder(0, 0, self.width, self.height, glow, 0.18, 0.82, 1.0)
    self:drawRectBorder(1, 1, self.width - 2, self.height - 2, 0.18, 0.18, 0.82, 1.0)
end

function FFC_MenuButton:render()
    if not self.icon then self.icon = loadIcon() end
    if self.icon and self.drawTextureScaled then
        self:drawTextureScaled(self.icon, 6, 6, 32, 32, 1, 1, 1, 1)
    else
        local c = Theme.colors.cyan
        self:drawText("FFC", 9, 14, c.r, c.g, c.b, 1, UIFont.Small)
    end
end

function FFC_MenuButton:onMouseMove(dx, dy)
    self.hovered = true
    if self.dragging then
        self:moveBy(dx, dy)
        return true
    end
end

function FFC_MenuButton:onMouseUp(x, y)
    if self.dragging then
        self.dragging = false
        if self.dragMoved then
            savePosition(self.x, self.y)
            return true
        end
    end
    if FadedFeastcraft and FadedFeastcraft.ToggleWindow then
        FadedFeastcraft.ToggleWindow()
    end
    return true
end

function FFC_MenuButton:onMouseUpOutside(x, y)
    if self.dragging then
        self.dragging = false
        if self.dragMoved then
            savePosition(self.x, self.y)
        end
    end
    self.hovered = false
    return true
end

function FFC_MenuButton:onMouseMoveOutside(dx, dy)
    if self.dragging then
        self:moveBy(dx, dy)
        return true
    end
    self.hovered = false
end

function FFC_MenuButton:onMouseDown(x, y)
    self.dragging = true
    self.dragMoved = false
    self.dragDistance = 0
    self.hovered = true
    return true
end

function FadedFeastcraft.EnsureMenuButton()
    if FFC_MenuButton.instance and FFC_MenuButton.instance:getIsVisible() == true then
        if not FFC_MenuButton.instance.loadedPlayerPosition then
            FFC_MenuButton.instance:applySavedPosition()
        end
        return FFC_MenuButton.instance
    end
    local screenH = getCore and getCore():getScreenHeight() or 720
    local x = 12
    local y = math.max(96, math.floor(screenH * 0.42))
    local savedX, savedY = savedPosition()
    if savedX ~= nil and savedY ~= nil then
        local maxX, maxY = screenBounds(44, 44)
        x = clamp(savedX, 0, maxX)
        y = clamp(savedY, 0, maxY)
    end
    local button = FFC_MenuButton:new(x, y)
    button.loadedPlayerPosition = savedX ~= nil and savedY ~= nil
    button:initialise()
    button:instantiate()
    button:addToUIManager()
    button:setVisible(true)
    FFC_MenuButton.instance = button
    return button
end

local function ensureMenuButton()
    if FadedFeastcraft and FadedFeastcraft.EnsureMenuButton then
        FadedFeastcraft.EnsureMenuButton()
    end
end

if Events and Events.OnCreatePlayer and not FadedFeastcraft.MenuButtonCreatePlayerRegistered then
    FadedFeastcraft.MenuButtonCreatePlayerRegistered = true
    Events.OnCreatePlayer.Add(function(playerIndex, player)
        if playerIndex == 0 then ensureMenuButton() end
    end)
end

if Events and Events.OnGameStart and not FadedFeastcraft.MenuButtonGameStartRegistered then
    FadedFeastcraft.MenuButtonGameStartRegistered = true
    Events.OnGameStart.Add(ensureMenuButton)
end

return FFC_MenuButton
