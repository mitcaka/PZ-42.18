require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "CSR_Antibodies"
require "CSR_AntibodiesClient"
require "CSR_Theme"

CSR_AntibodiesPanel = ISCollapsableWindow:derive("CSR_AntibodiesPanel")

local PANEL_W = 400
local PANEL_H = 420
local PAD = 12
local BAR_H = 12
local BUTTON_H = 24
local BUTTON_BOTTOM = 10

-- Red/orange-tinted antibody crest, used as a watermark behind the panel
-- contents and as the outline accent color.  Loaded once on first use.
local BG_TEXTURE_PATH = "media/ui/CSR_AntibodiesBg.png"
local _bgTexture = nil
local function getBgTexture()
    if _bgTexture == nil then
        _bgTexture = getTexture(BG_TEXTURE_PATH) or false
    end
    return _bgTexture or nil
end

local OUTLINE_COLOR = { a = 1.0, r = 0.86, g = 0.36, b = 0.36 }

local openPanels = {}

local function color(name)
    return CSR_Theme.colors[name] or { a = 1, r = 1, g = 1, b = 1 }
end

local function percent(value)
    return tostring(math.floor((tonumber(value) or 0) + 0.5)) .. "%"
end

local function fontHeight(font)
    local tm = getTextManager()
    if tm and tm.getFontHeight then
        return tm:getFontHeight(font)
    end
    return font == UIFont.Medium and 20 or 16
end

local function lineHeight(font, extra)
    return math.max(18, fontHeight(font) + (extra or 4))
end

local function fitText(text, font, maxW)
    text = tostring(text or "")
    if maxW <= 0 then return "" end
    local tm = getTextManager()
    if not tm or tm:MeasureStringX(font, text) <= maxW then
        return text
    end
    local suffix = "..."
    local suffixW = tm:MeasureStringX(font, suffix)
    if suffixW >= maxW then return suffix end
    local trimmed = text
    while #trimmed > 0 and tm:MeasureStringX(font, trimmed .. suffix) > maxW do
        trimmed = string.sub(trimmed, 1, #trimmed - 1)
    end
    return trimmed .. suffix
end

local function keyForPlayer(player)
    if not player then return "unknown" end
    if player.getOnlineID then
        local id = player:getOnlineID()
        if id ~= nil then return tostring(id) end
    end
    if player.getUsername then
        local name = player:getUsername()
        if name then return tostring(name) end
    end
    return tostring(player)
end

function CSR_AntibodiesPanel:new(doctor, patient, x, y)
    local o = ISCollapsableWindow.new(self, x, y, PANEL_W, PANEL_H)
    o.doctor = doctor
    o.patient = patient or doctor
    o.playerNum = doctor and doctor.getPlayerNum and doctor:getPlayerNum() or 0
    o.title = getText("IGUI_CSR_Antibody_Title")
    o.resizable = false
    o.background = true
    o.backgroundColor = { a = 0.92, r = 0.08, g = 0.05, b = 0.05 }
    o.borderColor = { a = 1.0, r = OUTLINE_COLOR.r, g = OUTLINE_COLOR.g, b = OUTLINE_COLOR.b }
    o.refreshTick = 0
    o.panelKey = keyForPlayer(o.patient)
    return o
end

function CSR_AntibodiesPanel:createChildren()
    ISCollapsableWindow.createChildren(self)

    local btnY = self.height - BUTTON_H - BUTTON_BOTTOM
    local btnW = math.floor((self.width - PAD * 3) / 2)
    self.drawButton = ISButton:new(PAD, btnY, btnW, BUTTON_H, getText("IGUI_CSR_Antibody_DrawSample"), self, self.onDrawSample)
    self.drawButton:initialise()
    self:addChild(self.drawButton)
    CSR_Theme.applyButtonStyle(self.drawButton, "accentGreen", false)

    self.injectButton = ISButton:new(PAD * 2 + btnW, btnY, btnW, BUTTON_H, getText("IGUI_CSR_Antibody_InjectSerum"), self, self.onInjectSerum)
    self.injectButton:initialise()
    self:addChild(self.injectButton)
    CSR_Theme.applyButtonStyle(self.injectButton, "accentBlue", false)
end

function CSR_AntibodiesPanel:close()
    openPanels[self.panelKey] = nil
    ISCollapsableWindow.close(self)
end

function CSR_AntibodiesPanel:getSnapshot()
    return CSR_Antibodies.Client.getSnapshot(self.patient)
end

function CSR_AntibodiesPanel:prerender()
    ISCollapsableWindow.prerender(self)

    self.refreshTick = self.refreshTick + 1
    if self.refreshTick >= 120 then
        self.refreshTick = 0
        CSR_Antibodies.Client.requestSnapshot(self.patient)
    end

    local snapshot = self:getSnapshot()
    local empty = CSR_Antibodies.findInventoryItemByType(self.doctor, CSR_Antibodies.ITEM_EMPTY_SYRINGE)
    local serum = CSR_Antibodies.findInventoryItemByType(self.doctor, CSR_Antibodies.ITEM_IMMUNE_SYRINGE)
    local canDraw = snapshot and snapshot.immune and empty ~= nil
    local canInject = snapshot and not snapshot.immune and serum ~= nil

    if self.drawButton then
        self.drawButton.enable = canDraw == true
        CSR_Theme.applyButtonStyle(self.drawButton, "accentGreen", canDraw)
    end
    if self.injectButton then
        self.injectButton.enable = canInject == true
        CSR_Theme.applyButtonStyle(self.injectButton, "accentBlue", canInject)
    end
end

function CSR_AntibodiesPanel:drawBar(labelKey, value, y, colorName)
    local label = getText(labelKey)
    local text = color("text")
    local muted = color("textMuted")
    local accent = color(colorName)
    local barX = PAD
    local barW = self.width - PAD * 2
    local labelY = y
    local labelH = lineHeight(UIFont.Small, 2)
    local barY = y + labelH

    local pct = percent(value)
    local tw = getTextManager():MeasureStringX(UIFont.Small, pct)
    self:drawText(fitText(label, UIFont.Small, barW - tw - PAD), barX, labelY, text.r, text.g, text.b, 1, UIFont.Small)
    self:drawText(pct, barX + barW - tw, labelY, muted.r, muted.g, muted.b, 1, UIFont.Small)
    self:drawRect(barX, barY, barW, BAR_H, 0.75, 0.03, 0.04, 0.06)
    local fillW = math.floor(barW * math.max(0, math.min(100, tonumber(value) or 0)) / 100)
    if fillW > 0 then
        self:drawRect(barX + 1, barY + 1, fillW - 2, BAR_H - 2, 0.88, accent.r, accent.g, accent.b)
    end
    self:drawRectBorder(barX, barY, barW, BAR_H, 0.75, 0.29, 0.35, 0.42)
    return labelH + BAR_H + 10
end

function CSR_AntibodiesPanel:drawLine(label, value, y, accentName)
    local text = color(accentName or "text")
    local maxLabelW = self.width - PAD * 2
    if value then
        local muted = color("textMuted")
        local tw = getTextManager():MeasureStringX(UIFont.Small, value)
        maxLabelW = maxLabelW - tw - PAD
        self:drawText(value, self.width - PAD - tw, y, muted.r, muted.g, muted.b, 1, UIFont.Small)
    end
    self:drawText(fitText(label, UIFont.Small, maxLabelW), PAD, y, text.r, text.g, text.b, 1, UIFont.Small)
    return lineHeight(UIFont.Small, 4)
end

function CSR_AntibodiesPanel:drawEffectLine(entry, y)
    local c = entry.good and color("accentGreen") or color("accentRed")
    local label = getText(entry.key)
    local value = tonumber(entry.value) or 0
    local sign = value >= 0 and "+" or ""
    local txt = sign .. string.format("%.1f", value)
    local tw = getTextManager():MeasureStringX(UIFont.Small, txt)
    self:drawText(fitText(label, UIFont.Small, self.width - PAD * 3 - tw), PAD, y, c.r, c.g, c.b, 1, UIFont.Small)
    self:drawText(txt, self.width - PAD - tw, y, c.r, c.g, c.b, 1, UIFont.Small)
end

function CSR_AntibodiesPanel:getButtonTop()
    if self.drawButton then
        return self.drawButton.y
    end
    return self.height - BUTTON_H - BUTTON_BOTTOM
end

function CSR_AntibodiesPanel:render()
    local snapshot = self:getSnapshot()
    local th = self:titleBarHeight()
    local y = th + PAD
    local text = color("text")
    local muted = color("textMuted")

    -- Draw the antibody crest as a faint watermark behind the content,
    -- centered horizontally and anchored just below the title bar.
    local tex = getBgTexture()
    if tex then
        local maxW = self.width - PAD * 2
        local maxH = self.height - th - PAD * 2
        local tw = tex.getWidth and tex:getWidth() or maxW
        local thh = tex.getHeight and tex:getHeight() or maxH
        if tonumber(tw) and tonumber(thh) and tonumber(tw) > 0 and tonumber(thh) > 0 then
            local scale = math.min(maxW / tonumber(tw), maxH / tonumber(thh))
            if scale > 1 then scale = 1 end
            local drawW = math.floor(tonumber(tw) * scale)
            local drawH = math.floor(tonumber(thh) * scale)
            local drawX = math.floor((self.width - drawW) / 2)
            local drawY = th + math.floor((maxH - drawH) / 2)
            self:drawTextureScaled(tex, drawX, drawY, drawW, drawH, 0.18,
                OUTLINE_COLOR.r, OUTLINE_COLOR.g, OUTLINE_COLOR.b)
        end
    end

    -- Thick red outline to match the watermark accent.
    self:drawRectBorder(0, 0, self.width, self.height, 1.0,
        OUTLINE_COLOR.r, OUTLINE_COLOR.g, OUTLINE_COLOR.b)
    self:drawRectBorder(1, 1, self.width - 2, self.height - 2, 0.8,
        OUTLINE_COLOR.r * 0.7, OUTLINE_COLOR.g * 0.7, OUTLINE_COLOR.b * 0.7)

    if not snapshot then
        self:drawText(getText("IGUI_CSR_Antibody_NoData"), PAD, y, muted.r, muted.g, muted.b, 1, UIFont.Small)
        ISCollapsableWindow.render(self)
        return
    end

    local name = snapshot.displayName or getText("IGUI_CSR_Antibody_Patient")
    local stage = getText(snapshot.stageKey or "IGUI_CSR_Antibody_Stage_Clear")
    local fittedStage = fitText(stage, UIFont.Small, math.floor((self.width - PAD * 2) * 0.45))
    local sw = getTextManager():MeasureStringX(UIFont.Small, fittedStage)
    self:drawText(fitText(name, UIFont.Medium, self.width - PAD * 3 - sw), PAD, y, text.r, text.g, text.b, 1, UIFont.Medium)
    self:drawText(fittedStage, self.width - PAD - sw, y + 3, muted.r, muted.g, muted.b, 1, UIFont.Small)
    y = y + lineHeight(UIFont.Medium, 6)

    y = y + self:drawBar("IGUI_CSR_Antibody_Infection", snapshot.infectionLevel or 0, y, "accentRed")
    y = y + self:drawBar("IGUI_CSR_Antibody_Response", snapshot.antibodyLevel or 0, y, "accentBlue")
    y = y + self:drawBar("IGUI_CSR_Antibody_Immunity", snapshot.immunity or 0, y, "accentGreen")

    y = y + self:drawLine(getText("IGUI_CSR_Antibody_Survived", tostring(snapshot.survivedCount or 0)), nil, y, "text")
    y = y + self:drawLine(getText("IGUI_CSR_Antibody_Chance"), percent(snapshot.chance or 0), y, "text")
    if (snapshot.serumHoursLeft or 0) > 0 then
        y = y + self:drawLine(getText("IGUI_CSR_Antibody_SerumActive"), string.format("%.1fh", snapshot.serumHoursLeft), y, "accentBlue")
    end

    self:drawText(getText("IGUI_CSR_Antibody_Effects"), PAD, y, muted.r, muted.g, muted.b, 1, UIFont.Small)
    y = y + lineHeight(UIFont.Small, 4)

    local entries = snapshot.effects and snapshot.effects.entries or nil
    if not entries or #entries == 0 then
        if y < self:getButtonTop() - lineHeight(UIFont.Small, 4) then
            self:drawText(getText("IGUI_CSR_Antibody_NoEffects"), PAD, y, muted.r, muted.g, muted.b, 1, UIFont.Small)
        end
    else
        local effectH = lineHeight(UIFont.Small, 4)
        local maxEffects = math.max(0, math.floor((self:getButtonTop() - PAD - y) / effectH))
        local limit = math.min(#entries, maxEffects)
        for i = 1, limit do
            self:drawEffectLine(entries[i], y)
            y = y + effectH
        end
    end

    ISCollapsableWindow.render(self)
end

function CSR_AntibodiesPanel:onDrawSample()
    local empty = CSR_Antibodies.findInventoryItemByType(self.doctor, CSR_Antibodies.ITEM_EMPTY_SYRINGE)
    if empty then
        CSR_Antibodies.Client.queueDraw(self.doctor, self.patient, empty)
    end
end

function CSR_AntibodiesPanel:onInjectSerum()
    local serum = CSR_Antibodies.findInventoryItemByType(self.doctor, CSR_Antibodies.ITEM_IMMUNE_SYRINGE)
    if serum then
        CSR_Antibodies.Client.queueInject(self.doctor, self.patient, serum)
    end
end

function CSR_AntibodiesPanel.open(doctor, patient)
    if not CSR_FeatureFlags.isAntibodySystemEnabled() then return nil end
    doctor = doctor or getPlayer()
    patient = patient or doctor
    if not doctor or not patient then return nil end

    local key = keyForPlayer(patient)
    local existing = openPanels[key]
    if existing and existing:getIsVisible() then
        existing:bringToTop()
        CSR_Antibodies.Client.requestSnapshot(patient)
        return existing
    end

    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local x = math.max(10, math.floor((sw - PANEL_W) / 2))
    local y = math.max(10, math.floor((sh - PANEL_H) / 2))
    local panel = CSR_AntibodiesPanel:new(doctor, patient, x, y)
    panel:initialise()
    panel:addToUIManager()
    openPanels[key] = panel
    CSR_Antibodies.Client.requestSnapshot(patient)
    return panel
end

return CSR_AntibodiesPanel
