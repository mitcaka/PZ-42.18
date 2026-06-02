if isServer() then return end

require "BCR_DisplaySettings"
require "BCR_Scale"
require "BCR_Utils"

BCR_DisplaySettingsPanel = BCR_DisplaySettingsPanel or {}

local PrefsPanel = ISPanel:derive("BCR_DisplaySettingsPanel")

local PANEL_W = 360
local HEADER_H = 26
local ROW_H = 28
local BTN_W = 58
local BTN_H = 20
local STEP_W = 24
local VALUE_W = 54
local RESET_W = 54
local PAD = 10

local COLORS = {
    bg = { r = 0.04, g = 0.045, b = 0.055, a = 0.92 },
    header = { r = 0.10, g = 0.11, b = 0.13, a = 0.96 },
    border = { r = 0.50, g = 0.53, b = 0.56, a = 0.95 },
    text = { r = 0.90, g = 0.90, b = 0.86, a = 1.00 },
    muted = { r = 0.60, g = 0.62, b = 0.64, a = 1.00 },
    on = { r = 0.22, g = 0.52, b = 0.30, a = 0.95 },
    off = { r = 0.50, g = 0.22, b = 0.22, a = 0.95 },
    value = { r = 0.18, g = 0.21, b = 0.23, a = 0.95 },
}

local function tr(key, fallback)
    return BCR_Utils.tr(key, fallback)
end

local function panelHeight()
    local count = BCR_DisplaySettings and #BCR_DisplaySettings.PREFS or 0
    return HEADER_H + count * ROW_H + PAD
end

local function clampToScreen(x, y, w, h)
    local core = getCore and getCore() or nil
    local sw = core and core:getScreenWidth() or 1280
    local sh = core and core:getScreenHeight() or 768
    local margin = 4
    return math.max(margin, math.min(x, sw - w - margin)),
        math.max(margin, math.min(y, sh - h - margin))
end

local function applyButtonColor(btn, color)
    if not btn or not color then return end
    btn.backgroundColor = { r = color.r, g = color.g, b = color.b, a = color.a }
    btn.backgroundColorMouseOver = { r = math.min(color.r + 0.10, 1), g = math.min(color.g + 0.10, 1), b = math.min(color.b + 0.10, 1), a = 1 }
    btn.borderColor = { r = 0.82, g = 0.82, b = 0.82, a = 0.55 }
end

local function setButtonEnabled(btn, enabled)
    if not btn then return end
    if btn.setEnable then
        btn:setEnable(enabled == true)
    else
        btn.enable = enabled == true
    end
end

local function isNumberPref(pref)
    return pref and pref.type == "number"
end

local function percentValue(value)
    return tostring(math.floor((tonumber(value) or 1) * 100 + 0.5)) .. "%"
end

local function textWidth(font, text)
    local tm = getTextManager and getTextManager() or nil
    if not tm then return string.len(tostring(text or "")) * 7 end
    return tm:MeasureStringX(font or UIFont.Small, tostring(text or ""))
end

local function ellipsize(text, maxWidth)
    text = tostring(text or "")
    if maxWidth <= 0 then return "" end
    if textWidth(UIFont.Small, text) <= maxWidth then return text end
    local suffix = "..."
    while string.len(text) > 0 and textWidth(UIFont.Small, text .. suffix) > maxWidth do
        text = string.sub(text, 1, string.len(text) - 1)
    end
    if text == "" then return suffix end
    return text .. suffix
end

function PrefsPanel:new(x, y)
    local o = ISPanel.new(self, x, y, PANEL_W, panelHeight())
    setmetatable(o, self)
    self.__index = self
    o.dragging = false
    o.dragX = 0
    o.dragY = 0
    o.backgroundColor = COLORS.bg
    o.borderColor = COLORS.border
    return o
end

function PrefsPanel:initialise()
    ISPanel.initialise(self)
end

function PrefsPanel:createChildren()
    ISPanel.createChildren(self)

    self.closeBtn = ISButton:new(self.width - 24, 3, 20, 20, tr("UI_BCR_Setting_Close", "X"), self, self.onClose)
    self.closeBtn:initialise()
    self.closeBtn:instantiate()
    self.closeBtn.anchorRight = true
    self.closeBtn.anchorTop = true
    applyButtonColor(self.closeBtn, COLORS.off)
    self:addChild(self.closeBtn)

    self.prefButtons = {}
    self.decreaseButtons = {}
    self.increaseButtons = {}
    self.resetButtons = {}
    for index, pref in ipairs(BCR_DisplaySettings.PREFS) do
        local rowY = HEADER_H + (index - 1) * ROW_H
        local btnY = rowY + math.floor((ROW_H - BTN_H) / 2)

        if isNumberPref(pref) then
            local resetX = self.width - PAD - RESET_W
            local plusX = resetX - 6 - STEP_W
            local valueX = plusX - 2 - VALUE_W
            local minusX = valueX - 2 - STEP_W

            local minus = ISButton:new(minusX, btnY, STEP_W, BTN_H, "-", self, self.onAdjustPref)
            minus:initialise()
            minus:instantiate()
            minus.anchorRight = true
            minus.anchorTop = true
            minus.prefKey = pref.key
            minus.prefDirection = -1
            self:addChild(minus)
            self.decreaseButtons[pref.key] = minus

            local value = ISButton:new(valueX, btnY, VALUE_W, BTN_H, "", self, self.onResetPref)
            value:initialise()
            value:instantiate()
            value.anchorRight = true
            value.anchorTop = true
            value.prefKey = pref.key
            value:setTooltip(tr("UI_BCR_Tooltip_ScaleValue", "Click to reset this value."))
            self:addChild(value)
            self.prefButtons[pref.key] = value

            local plus = ISButton:new(plusX, btnY, STEP_W, BTN_H, "+", self, self.onAdjustPref)
            plus:initialise()
            plus:instantiate()
            plus.anchorRight = true
            plus.anchorTop = true
            plus.prefKey = pref.key
            plus.prefDirection = 1
            self:addChild(plus)
            self.increaseButtons[pref.key] = plus
        else
            local toggle = ISButton:new(self.width - PAD - RESET_W - 6 - BTN_W, btnY, BTN_W, BTN_H, "", self, self.onTogglePref)
            toggle:initialise()
            toggle:instantiate()
            toggle.anchorRight = true
            toggle.anchorTop = true
            toggle.prefKey = pref.key
            self:addChild(toggle)
            self.prefButtons[pref.key] = toggle
        end

        local reset = ISButton:new(self.width - PAD - RESET_W, btnY, RESET_W, BTN_H, tr("UI_BCR_Setting_Reset", "Reset"), self, self.onResetPref)
        reset:initialise()
        reset:instantiate()
        reset.anchorRight = true
        reset.anchorTop = true
        reset.prefKey = pref.key
        reset:setTooltip(tr("UI_BCR_Tooltip_Reset", "Clear the player override and use the default value."))
        self:addChild(reset)
        self.resetButtons[pref.key] = reset
    end

    self:refreshButtons()
end

function PrefsPanel:refreshButtons()
    if not self.prefButtons then return end
    for _, pref in ipairs(BCR_DisplaySettings.PREFS) do
        local btn = self.prefButtons[pref.key]
        local reset = self.resetButtons[pref.key]
        if btn and isNumberPref(pref) then
            local value = BCR_DisplaySettings.get(pref.key)
            local override = BCR_DisplaySettings.getOverride(pref.key)
            btn:setTitle(percentValue(value))
            btn:setTooltip(override ~= nil and tr("UI_BCR_Tooltip_PlayerOverride", "Player override active. Click to toggle.") or tr("UI_BCR_Tooltip_DefaultValue", "Using the default value. Click to override."))
            applyButtonColor(btn, COLORS.value)
            setButtonEnabled(self.decreaseButtons[pref.key], value > (tonumber(pref.minValue) or value))
            setButtonEnabled(self.increaseButtons[pref.key], value < (tonumber(pref.maxValue) or value))
            applyButtonColor(self.decreaseButtons[pref.key], COLORS.value)
            applyButtonColor(self.increaseButtons[pref.key], COLORS.value)
        elseif btn then
            local on = BCR_DisplaySettings.get(pref.key)
            local override = BCR_DisplaySettings.getOverride(pref.key)
            btn:setTitle(on and tr("UI_BCR_Setting_On", "ON") or tr("UI_BCR_Setting_Off", "OFF"))
            btn:setTooltip(override ~= nil and tr("UI_BCR_Tooltip_PlayerOverride", "Player override active. Click to toggle.") or tr("UI_BCR_Tooltip_DefaultValue", "Using the default value. Click to override."))
            applyButtonColor(btn, on and COLORS.on or COLORS.off)
        end
        if reset then
            setButtonEnabled(reset, BCR_DisplaySettings.getOverride(pref.key) ~= nil)
        end
    end
end

function PrefsPanel:afterPrefChanged(key)
    if key == "DisplayScale" and BCR_Scale and BCR_Scale.refresh then
        BCR_Scale.refresh()
    end
    self:refreshButtons()
end

function PrefsPanel:onTogglePref(btn)
    if not btn or not btn.prefKey then return end
    BCR_DisplaySettings.toggle(btn.prefKey)
    self:afterPrefChanged(btn.prefKey)
end

function PrefsPanel:onAdjustPref(btn)
    if not btn or not btn.prefKey then return end
    BCR_DisplaySettings.adjust(btn.prefKey, btn.prefDirection or 0)
    self:afterPrefChanged(btn.prefKey)
end

function PrefsPanel:onResetPref(btn)
    if not btn or not btn.prefKey then return end
    BCR_DisplaySettings.reset(btn.prefKey)
    self:afterPrefChanged(btn.prefKey)
end

function PrefsPanel:onClose()
    self:setVisible(false)
    BCR_DisplaySettingsPanel.isVisible = false
end

function PrefsPanel:prerender()
    ISPanel.prerender(self)
    self:drawRect(0, 0, self.width, self.height, COLORS.bg.a, COLORS.bg.r, COLORS.bg.g, COLORS.bg.b)
    self:drawRect(0, 0, self.width, HEADER_H, COLORS.header.a, COLORS.header.r, COLORS.header.g, COLORS.header.b)
    self:drawRectBorder(0, 0, self.width, self.height, COLORS.border.a, COLORS.border.r, COLORS.border.g, COLORS.border.b)
    self:drawText(tr("UI_BCR_DisplaySettings_Title", "Buildcraft Display Settings"), PAD, 6, COLORS.text.r, COLORS.text.g, COLORS.text.b, COLORS.text.a, UIFont.Small)
end

function PrefsPanel:render()
    ISPanel.render(self)
    self:refreshButtons()
    for index, pref in ipairs(BCR_DisplaySettings.PREFS) do
        local rowY = HEADER_H + (index - 1) * ROW_H
        local label = tr(pref.labelKey, pref.key)
        local maxLabelWidth = isNumberPref(pref) and (self.width - PAD * 2 - RESET_W - VALUE_W - STEP_W * 2 - 24) or (self.width - PAD * 2 - RESET_W - BTN_W - 24)
        self:drawText(ellipsize(label, maxLabelWidth), PAD, rowY + 7, COLORS.text.r, COLORS.text.g, COLORS.text.b, COLORS.text.a, UIFont.Small)
        if BCR_DisplaySettings.getOverride(pref.key) == nil then
            local markerX = isNumberPref(pref) and (self.width - PAD - RESET_W - STEP_W * 2 - VALUE_W - 22) or (self.width - PAD - RESET_W - 18)
            if maxLabelWidth > 0 then
                self:drawText("*", markerX, rowY + 7, COLORS.muted.r, COLORS.muted.g, COLORS.muted.b, COLORS.muted.a, UIFont.Small)
            end
        end
    end
end

function PrefsPanel:onMouseDown(x, y)
    if y <= HEADER_H then
        self.dragging = true
        self.dragX = x
        self.dragY = y
        return true
    end
    return ISPanel.onMouseDown(self, x, y)
end

function PrefsPanel:onMouseMove(dx, dy)
    if self.dragging then
        local mx = getMouseX and getMouseX() or self:getX()
        local my = getMouseY and getMouseY() or self:getY()
        self:setX(mx - self.dragX)
        self:setY(my - self.dragY)
        return true
    end
    return ISPanel.onMouseMove(self, dx, dy)
end

function PrefsPanel:onMouseMoveOutside(dx, dy)
    return self:onMouseMove(dx, dy)
end

function PrefsPanel:onMouseUp(x, y)
    self.dragging = false
    local nx, ny = clampToScreen(self:getX(), self:getY(), self.width, self.height)
    self:setX(nx)
    self:setY(ny)
    return ISPanel.onMouseUp(self, x, y)
end

function PrefsPanel:onMouseUpOutside(x, y)
    return self:onMouseUp(x, y)
end

BCR_DisplaySettingsPanel.isVisible = false
BCR_DisplaySettingsPanel._panel = nil

function BCR_DisplaySettingsPanel.toggle(anchorX, anchorY)
    if BCR_DisplaySettingsPanel._panel then
        local visible = not BCR_DisplaySettingsPanel._panel:getIsVisible()
        BCR_DisplaySettingsPanel._panel:setVisible(visible)
        BCR_DisplaySettingsPanel.isVisible = visible
        if visible then
            BCR_DisplaySettingsPanel._panel:refreshButtons()
            BCR_DisplaySettingsPanel._panel:bringToTop()
        end
        return
    end

    local x, y = clampToScreen(anchorX or 100, anchorY or 84, PANEL_W, panelHeight())
    local panel = PrefsPanel:new(x, y)
    panel:initialise()
    panel:instantiate()
    panel:addToUIManager()
    BCR_DisplaySettingsPanel._panel = panel
    BCR_DisplaySettingsPanel.isVisible = true
end

function BCR_DisplaySettingsPanel.destroy()
    if BCR_DisplaySettingsPanel._panel then
        BCR_DisplaySettingsPanel._panel:removeFromUIManager()
        BCR_DisplaySettingsPanel._panel = nil
        BCR_DisplaySettingsPanel.isVisible = false
    end
end

return BCR_DisplaySettingsPanel
