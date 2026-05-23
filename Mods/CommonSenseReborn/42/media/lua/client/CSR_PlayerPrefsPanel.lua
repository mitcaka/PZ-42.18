-- CSR_PlayerPrefsPanel: floating panel for per-player CSR preference overrides.
-- Opened via the "S" (Settings) button in the Utility HUD header.
-- Each row shows the feature label and a toggle button (ON/OFF).
-- Changes persist immediately via CSR_PlayerPrefs modData storage.
-- Note: features that affect HUD widget visibility (e.g. Sound Cues, DW) take
-- effect on next HUD creation (toggle HUD off/on with the keybind).

require "CSR_FeatureFlags"
require "CSR_PlayerPrefs"
require "CSR_Scale"
require "CSR_Theme"

CSR_PlayerPrefsPanel = {}

local PrefsPanel = ISPanel:derive("CSRPrefsPanel")

local TITLE = "CSR Personal Settings"

local BASE_MIN_PANEL_W = 360
local BASE_MAX_PANEL_W = 520
local BASE_MIN_SCREEN_W = 260
local BASE_LABEL_PAD = 12
local BASE_BTN_RPAD = 14
local BASE_BTN_GAP = 18
local BASE_BOTTOM_PAD = 10
local BASE_CLOSE_SIZE = 20
local BASE_SCREEN_MARGIN = 4

local function px(value)
    if CSR_Scale and CSR_Scale.px then
        return CSR_Scale.px(value)
    end
    return math.floor((value or 0) + 0.5)
end

local function prefFont()
    if CSR_Scale and CSR_Scale.font then
        return CSR_Scale.font(14)
    end
    return UIFont.Small
end

local function tm()
    return getTextManager and getTextManager() or nil
end

local function fontHeight(font)
    local mgr = tm()
    return (mgr and mgr:getFontHeight(font)) or 16
end

local function textWidth(font, text)
    local mgr = tm()
    return (mgr and mgr:MeasureStringX(font, tostring(text or ""))) or (#tostring(text or "") * 8)
end

local function headerHeight()
    return math.max(px(28), fontHeight(prefFont()) + px(10))
end

local function rowHeight()
    return math.max(px(24), fontHeight(prefFont()) + px(6))
end

local function buttonHeight()
    return math.max(px(18), fontHeight(prefFont()) + px(4))
end

local function buttonWidth()
    return math.max(px(62), textWidth(prefFont(), "OFF >>") + px(12))
end

local function numPrefs()
    return CSR_PlayerPrefs and #CSR_PlayerPrefs.PREFS or 0
end

local function maxLabelWidth()
    local maxW = 0
    if CSR_PlayerPrefs and CSR_PlayerPrefs.PREFS then
        for _, pref in ipairs(CSR_PlayerPrefs.PREFS) do
            maxW = math.max(maxW, textWidth(prefFont(), pref.label))
        end
    end
    return maxW
end

local function panelWidth(screenW)
    local labelPad = px(BASE_LABEL_PAD)
    local btnRPad = px(BASE_BTN_RPAD)
    local btnGap = px(BASE_BTN_GAP)
    local minW = px(BASE_MIN_PANEL_W)
    local maxW = px(BASE_MAX_PANEL_W)
    local w = labelPad + maxLabelWidth() + btnGap + buttonWidth() + btnRPad
    local headerW = labelPad + textWidth(prefFont(), TITLE) + px(BASE_CLOSE_SIZE) + btnRPad + px(12)
    w = math.max(minW, w, headerW)
    if screenW then
        local availableW = math.max(px(BASE_MIN_SCREEN_W), screenW - (px(BASE_SCREEN_MARGIN) * 2))
        w = math.min(w, math.min(maxW, availableW))
    else
        w = math.min(w, maxW)
    end
    return w
end

local function panelHeight()
    return headerHeight() + numPrefs() * rowHeight() + px(BASE_BOTTOM_PAD)
end

local function shorten(text, font, maxW)
    text = tostring(text or "")
    if textWidth(font, text) <= maxW then return text end
    local suffix = "..."
    local suffixW = textWidth(font, suffix)
    local out = text
    while #out > 0 and textWidth(font, out) + suffixW > maxW do
        out = string.sub(out, 1, #out - 1)
    end
    if out == "" then return suffix end
    return out .. suffix
end

local function drawChrome(panel)
    local bg = CSR_Theme.colors.panelBg
    local header = CSR_Theme.colors.panelHeader
    local border = CSR_Theme.colors.panelBorder
    local text = CSR_Theme.colors.text
    local h = headerHeight()
    local font = prefFont()
    panel:drawRect(0, 0, panel.width, panel.height, bg.a, bg.r, bg.g, bg.b)
    panel:drawRect(0, 0, panel.width, h, header.a, header.r, header.g, header.b)
    panel:drawRectBorder(0, 0, panel.width, panel.height, border.a, border.r, border.g, border.b)
    panel:drawText(TITLE, px(BASE_LABEL_PAD), math.max(px(3), math.floor((h - fontHeight(font)) / 2)),
        text.r, text.g, text.b, 0.97, font)
end

-- -------------------------------------------------------------------------
function PrefsPanel:new(x, y, w, h)
    local o = ISPanel.new(self, x, y, w or panelWidth(), h or panelHeight())
    setmetatable(o, self)
    self.__index = self
    o.dragging = false
    o.dragX    = 0
    o.dragY    = 0
    return o
end

function PrefsPanel:initialise()
    ISPanel.initialise(self)
end

function PrefsPanel:createChildren()
    ISPanel.createChildren(self)

    -- Close button (top-right of header)
    local headerH = headerHeight()
    local closeSide = math.min(px(BASE_CLOSE_SIZE), headerH - px(6))
    self.closeBtn = ISButton:new(self.width - closeSide - px(BASE_SCREEN_MARGIN),
        math.max(px(2), math.floor((headerH - closeSide) / 2)),
        closeSide, closeSide, "X", self, self.onClose)
    self.closeBtn:initialise()
    self.closeBtn:instantiate()
    self.closeBtn.anchorRight = true
    self.closeBtn.anchorTop   = true
    self:addChild(self.closeBtn)
    CSR_Theme.applyButtonStyle(self.closeBtn, "accentRed", false)

    -- One toggle button per pref
    self.prefButtons = {}
    local rowH = rowHeight()
    local btnW = buttonWidth()
    local btnH = buttonHeight()
    for i, pref in ipairs(CSR_PlayerPrefs.PREFS) do
        local rowY = headerH + (i - 1) * rowH
        local btnY = rowY + math.floor((rowH - btnH) / 2)
        local btnX = self.width - btnW - px(BASE_BTN_RPAD)
        local btn  = ISButton:new(btnX, btnY, btnW, btnH, "", self, self.onTogglePref)
        btn:initialise()
        btn:instantiate()
        btn.anchorRight = true
        btn.anchorTop   = true
        btn.prefKey     = pref.key
        btn.prefIndex   = i
        self:addChild(btn)
        self.prefButtons[pref.key] = btn
    end

    self:reflowForDisplay()
end

-- -------------------------------------------------------------------------
function PrefsPanel:reflowForDisplay()
    local core = getCore and getCore()
    local sw = core and core:getScreenWidth() or 1280
    local sh = core and core:getScreenHeight() or 768
    local w = panelWidth(sw)
    local h = panelHeight()

    if self.setWidth then self:setWidth(w) else self.width = w end
    if self.setHeight then self:setHeight(h) else self.height = h end

    local margin = px(BASE_SCREEN_MARGIN)
    self:setX(math.max(margin, math.min(self:getX(), sw - w - margin)))
    self:setY(math.max(margin, math.min(self:getY(), sh - h - margin)))

    if self.closeBtn then
        local headerH = headerHeight()
        local closeSide = math.min(px(BASE_CLOSE_SIZE), headerH - px(6))
        if self.closeBtn.setWidth then self.closeBtn:setWidth(closeSide) else self.closeBtn.width = closeSide end
        if self.closeBtn.setHeight then self.closeBtn:setHeight(closeSide) else self.closeBtn.height = closeSide end
        self.closeBtn:setX(self.width - closeSide - margin)
        self.closeBtn:setY(math.max(px(2), math.floor((headerH - closeSide) / 2)))
    end

    self:refreshButtons()
end

-- -------------------------------------------------------------------------
function PrefsPanel:refreshButtons()
    if not self.prefButtons then return end
    local colorsOn = true
    if CSR_FeatureFlags and CSR_FeatureFlags.isColoredTogglesEnabled then
        colorsOn = CSR_FeatureFlags.isColoredTogglesEnabled()
    end
    for _, pref in ipairs(CSR_PlayerPrefs.PREFS) do
        local btn = self.prefButtons[pref.key]
        if btn then
            local rowH = rowHeight()
            local btnW = buttonWidth()
            local btnH = buttonHeight()
            local rowY = headerHeight() + ((btn.prefIndex or 1) - 1) * rowH
            if btn.setWidth then btn:setWidth(btnW) else btn.width = btnW end
            if btn.setHeight then btn:setHeight(btnH) else btn.height = btnH end
            btn:setX(self.width - btnW - px(BASE_BTN_RPAD))
            btn:setY(rowY + math.floor((rowH - btnH) / 2))

            local locked    = pref.adminLocked and pref.adminLocked()
            local effective = pref.effectiveFn()
            local override  = CSR_PlayerPrefs.getOverride(pref.key)
            local hasOver   = override ~= nil

            if locked then
                btn:setTitle(effective and "ON \187" or "OFF \187")
                btn:setTooltip(getText("Tooltip_CSR_Pref_AdminControlled"))
            elseif hasOver then
                btn:setTitle(effective and "ON" or "OFF")
                btn:setTooltip(getText("Tooltip_CSR_Pref_PlayerOverride"))
            else
                btn:setTitle(effective and "ON" or "OFF")
                btn:setTooltip(getText("Tooltip_CSR_Pref_ServerDefault"))
            end

            if colorsOn then
                -- Always solid green (ON) / red (OFF) regardless of override state.
                CSR_Theme.applyButtonStyle(btn, effective and "accentGreen" or "accentRed", true)
            else
                -- Vanilla-styled: clear any custom colors so the button renders default.
                btn.backgroundColor = nil
                btn.backgroundColorMouseOver = nil
                btn.borderColor = nil
            end
        end
    end
end

-- -------------------------------------------------------------------------
function PrefsPanel:onTogglePref(btn)
    if not btn or not btn.prefKey then return end
    local pref = CSR_PlayerPrefs._byKey[btn.prefKey]
    if not pref then return end
    if pref.adminLocked and pref.adminLocked() then return end
    CSR_PlayerPrefs.toggle(btn.prefKey)
    self:refreshButtons()
    -- Keep the standalone DW button in the HUD in sync
    if btn.prefKey == "DualWield" then
        if CSR_UtilityHud and CSR_UtilityHud.panel and CSR_UtilityHud.panel.updateDualWieldButton then
            CSR_UtilityHud.panel:updateDualWieldButton()
        end
    elseif btn.prefKey == "DualWieldEmergencySwap" then
        if CSR_UtilityHud and CSR_UtilityHud.panel and CSR_UtilityHud.panel.updateEmergencySwapButton then
            CSR_UtilityHud.panel:updateEmergencySwapButton()
        end
    elseif btn.prefKey == "SurvivorLedger" then
        if CSR_UtilityHud and CSR_UtilityHud.panel and CSR_UtilityHud.panel.updateLedgerButton then
            CSR_UtilityHud.panel:updateLedgerButton()
        end
    end
end

function PrefsPanel:onClose()
    self:setVisible(false)
    CSR_PlayerPrefsPanel.isVisible = false
end

-- -------------------------------------------------------------------------
function PrefsPanel:prerender()
    self._scalePoll = (self._scalePoll or 0) + 1
    if self._scalePoll >= 30 then
        self._scalePoll = 0
        if CSR_Scale and CSR_Scale.refresh then
            CSR_Scale.refresh()
        end
    end

    local factor = CSR_Scale and CSR_Scale.factor and CSR_Scale.factor() or 1.0
    if self._lastScaleFactor ~= factor then
        self._lastScaleFactor = factor
        self:reflowForDisplay()
    end

    ISPanel.prerender(self)
    drawChrome(self)
end

function PrefsPanel:render()
    ISPanel.render(self)
    -- Refresh button states every frame to catch live sandbox/admin changes.
    self:refreshButtons()

    if not CSR_PlayerPrefs then return end
    local hH = headerHeight()
    local rowH = rowHeight()
    local font = prefFont()
    local fH = fontHeight(font)
    local labelPad = px(BASE_LABEL_PAD)
    local maxTextW = self.width - labelPad - px(BASE_BTN_GAP) - buttonWidth() - px(BASE_BTN_RPAD)
    for i, pref in ipairs(CSR_PlayerPrefs.PREFS) do
        local rowY    = hH + (i - 1) * rowH
        local textY   = rowY + math.floor((rowH - fH) / 2)
        local locked  = pref.adminLocked and pref.adminLocked()
        local r, g, b = 0.85, 0.85, 0.85
        if locked then r, g, b = 0.55, 0.55, 0.65 end
        self:drawText(shorten(pref.label, font, maxTextW), labelPad, textY, r, g, b, 1.0, font)
    end
end

-- -------------------------------------------------------------------------
-- Drag support (header only)
function PrefsPanel:onMouseDown(x, y)
    if y <= headerHeight() then
        self.dragging = true
        self.dragX    = x
        self.dragY    = y
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
    if self.dragging then
        local mx = getMouseX and getMouseX() or self:getX()
        local my = getMouseY and getMouseY() or self:getY()
        self:setX(mx - self.dragX)
        self:setY(my - self.dragY)
        return true
    end
    return ISPanel.onMouseMoveOutside(self, dx, dy)
end

function PrefsPanel:onMouseUp(x, y)
    self.dragging = false
    return ISPanel.onMouseUp(self, x, y)
end

function PrefsPanel:onMouseUpOutside(x, y)
    self.dragging = false
    return ISPanel.onMouseUpOutside(self, x, y)
end

-- =========================================================================
-- Public API
-- =========================================================================
CSR_PlayerPrefsPanel.isVisible = false
CSR_PlayerPrefsPanel._panel    = nil

-- Toggle visibility. anchorX/anchorY is the spawn position hint (HUD position).
function CSR_PlayerPrefsPanel.toggle(anchorX, anchorY)
    if CSR_PlayerPrefsPanel._panel then
        local vis = not CSR_PlayerPrefsPanel._panel:getIsVisible()
        CSR_PlayerPrefsPanel._panel:setVisible(vis)
        CSR_PlayerPrefsPanel.isVisible = vis
        if vis then
            if CSR_Scale and CSR_Scale.refresh then
                CSR_Scale.refresh()
            end
            CSR_PlayerPrefsPanel._panel:reflowForDisplay()
        end
        return
    end

    if CSR_Scale and CSR_Scale.refresh then
        CSR_Scale.refresh()
    end

    -- Clamp to screen
    local core = getCore and getCore()
    local sw   = core and core:getScreenWidth()  or 1280
    local sh   = core and core:getScreenHeight() or 768
    local w    = panelWidth(sw)
    local h    = panelHeight()
    local margin = px(BASE_SCREEN_MARGIN)
    local x    = math.max(margin, math.min(anchorX or px(100), sw - w - margin))
    local y    = math.max(margin, math.min(anchorY or px(84),  sh - h - margin))

    local panel = PrefsPanel:new(x, y, w, h)
    panel:initialise()
    panel:instantiate()
    panel:addToUIManager()
    CSR_PlayerPrefsPanel._panel    = panel
    CSR_PlayerPrefsPanel.isVisible = true
end

function CSR_PlayerPrefsPanel.destroy()
    if CSR_PlayerPrefsPanel._panel then
        CSR_PlayerPrefsPanel._panel:removeFromUIManager()
        CSR_PlayerPrefsPanel._panel    = nil
        CSR_PlayerPrefsPanel.isVisible = false
    end
end

local function onResolutionChange()
    if CSR_Scale and CSR_Scale.refresh then
        CSR_Scale.refresh()
    end

    local panel = CSR_PlayerPrefsPanel._panel
    if panel and panel.reflowForDisplay then
        panel:reflowForDisplay()
    end
end

if Events and Events.OnResolutionChange then
    Events.OnResolutionChange.Add(onResolutionChange)
end

if CSR_Scale and CSR_Scale.onChange then
    CSR_Scale.onChange(function()
        local panel = CSR_PlayerPrefsPanel._panel
        if panel and panel.reflowForDisplay then
            panel:reflowForDisplay()
        end
    end)
end

return CSR_PlayerPrefsPanel
