--[[
    CSR_RankingsSidebar.lua

    Small floating "Server Rankings" icon button. Click to toggle the rankings
    window. Hidden when the rankings feature is disabled in sandbox.

    The button is draggable so users on different aspect ratios can park
    it wherever they like; position persists in client modData.
]]

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "CSR_Theme"
require "CSR_FeatureFlags"

CSR_RankingsSidebar = CSR_RankingsSidebar or {}
local Side = CSR_RankingsSidebar

local ICON_PATH = "media/ui/CSR_Rankings/csr_server_rankings_icon_32.png"
local PREF_KEY  = "CSR_RankingsSidebar_v1"

local Panel = ISPanel:derive("CSR_RankingsSidebarBtn")

function Panel:initialise()
    ISPanel.initialise(self)
end

function Panel:createChildren()
    self.tex = getTexture(ICON_PATH)
end

function Panel:onMouseDown(x, y)
    self.dragging = true
    self.dragOffsetX = x
    self.dragOffsetY = y
    self.dragMoved = false
end

function Panel:onMouseMove(dx, dy)
    if self.dragging then
        local mx = getMouseX()
        local my = getMouseY()
        self:setX(mx - (self.dragOffsetX or 0))
        self:setY(my - (self.dragOffsetY or 0))
        if math.abs(dx) + math.abs(dy) > 1 then self.dragMoved = true end
    end
end

function Panel:onMouseUp(x, y)
    self.dragging = false
    if not self.dragMoved then
        if CSR_RankingsUI and CSR_RankingsUI.toggle then
            CSR_RankingsUI.toggle()
        end
    else
        Side.savePosition(self.x, self.y)
    end
end

function Panel:onMouseUpOutside(x, y)
    self.dragging = false
end

function Panel:prerender()
    local hovered = self:isMouseOver()
    local border = CSR_Theme.getColor("panelBorder")
    local bg     = CSR_Theme.getColor("panelBg")
    local accent = CSR_Theme.getColor("accentRed")
    local alpha  = hovered and 0.95 or 0.75

    self:drawRect(0, 0, self.width, self.height, alpha, bg.r, bg.g, bg.b)
    self:drawRectBorder(0, 0, self.width, self.height,
        alpha, border.r, border.g, border.b)
    if self.tex then
        self:drawTextureScaled(self.tex, 2, 2, self.width - 4, self.height - 4,
            1.0, 1.0, 1.0, 1.0)
    else
        -- Fallback: red square if texture missing
        self:drawRect(4, 4, self.width - 8, self.height - 8,
            0.9, accent.r, accent.g, accent.b)
    end
    if hovered then
        local tip = getText("IGUI_CSR_Rankings_Sidebar_Tooltip")
        if tip and tip ~= "" and tip ~= "IGUI_CSR_Rankings_Sidebar_Tooltip" then
            local tm = getTextManager()
            local w = tm:MeasureStringX(UIFont.Small, tip) + 8
            local tx = self.x + self.width + 6
            local ty = self.y + math.floor(self.height / 2) - 8
            self:drawRect(tx - self.x, ty - self.y, w, 18, 0.85, 0.05, 0.06, 0.08)
            self:drawText(tip, tx - self.x + 4, ty - self.y + 1,
                1.0, 1.0, 1.0, 1.0, UIFont.Small)
        end
    end
end

function Panel:render()
end

function Side.savePosition(x, y)
    local p = getPlayer()
    if not p then return end
    local md = p:getModData()
    md[PREF_KEY] = md[PREF_KEY] or {}
    md[PREF_KEY].x = x
    md[PREF_KEY].y = y
end

function Side.loadPosition()
    local p = getPlayer()
    if not p then return nil, nil end
    local md = p:getModData()
    if md[PREF_KEY] then return md[PREF_KEY].x, md[PREF_KEY].y end
    return nil, nil
end

function Side.show()
    if Side.button and Side.button:getIsVisible() then return end
    local size = 40
    local sx, sy = Side.loadPosition()
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    if not sx or not sy then
        sx = screenW - size - 16
        sy = math.floor(screenH * 0.35)
    end
    -- Clamp to visible area
    if sx < 0 then sx = 0 end
    if sy < 0 then sy = 0 end
    if sx > screenW - size then sx = screenW - size end
    if sy > screenH - size then sy = screenH - size end

    Side.button = Panel:new(sx, sy, size, size)
    Side.button:initialise()
    Side.button:instantiate()
    Side.button:addToUIManager()
    Side.button:setVisible(true)
end

function Side.hide()
    if Side.button then
        Side.button:setVisible(false)
        Side.button:removeFromUIManager()
        Side.button = nil
    end
end

function Side.isHidden()
    local p = getPlayer()
    if not p then return true end
    local md = p:getModData()
    if not md[PREF_KEY] then return true end
    -- Default hidden: only consider visible if user explicitly toggled it on
    return md[PREF_KEY].hidden ~= false
end

function Side.setHidden(hidden)
    local p = getPlayer()
    if not p then return end
    local md = p:getModData()
    md[PREF_KEY] = md[PREF_KEY] or {}
    md[PREF_KEY].hidden = hidden and true or false
end

function Side.toggle()
    if not CSR_FeatureFlags.isRankingsEnabled() then return end
    if Side.isHidden() then
        Side.setHidden(false)
        Side.show()
    else
        Side.setHidden(true)
        Side.hide()
    end
end

local function onGameStart()
    if not CSR_FeatureFlags.isRankingsEnabled() then
        Side.hide()
        return
    end
    if Side.isHidden() then
        Side.hide()
    else
        Side.show()
    end
end

local function onKeyPressed(key)
    if key == Keyboard.KEY_RBRACKET then
        Side.toggle()
    end
end

if Events and not CSR_RankingsSidebar._registered then
    CSR_RankingsSidebar._registered = true
    Events.OnGameStart.Add(onGameStart)
    Events.OnKeyPressed.Add(onKeyPressed)
end

return CSR_RankingsSidebar
