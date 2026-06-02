require "ISUI/ISPanel"
require "CSR_Utils"
require "CSR_Theme"
require "CSR_FeatureFlags"

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local UI_BORDER_SPACING = 10

local function csrRoccoDetected()
    local mods = getActivatedMods and getActivatedMods() or nil
    if NR_CharInfoPanel ~= nil then return true end
    return mods and mods.contains and mods:contains("Neat_Rocco")
end

local function csrDrawStatRow(self, label, value, x, y, labelWidth, valueColor)
    local labelColor = CSR_Theme.getColor("textMuted")
    valueColor = valueColor or CSR_Theme.getColor("text")
    self:drawTextRight(label, x + labelWidth, y, labelColor.r, labelColor.g, labelColor.b, 1, UIFont.Small)
    self:drawText(value, x + labelWidth + UI_BORDER_SPACING, y, valueColor.r, valueColor.g, valueColor.b, 1, UIFont.Small)
end

local function csrPatchCharacterScreen()
    if not CSR_FeatureFlags.isCharacterInfoEnhancementsEnabled() then return end
    if csrRoccoDetected() then return end
    if not ISCharacterScreen or ISCharacterScreen.CSR_renderPatched then
        return
    end

    local originalRender = ISCharacterScreen.render

    function ISCharacterScreen:render()
        originalRender(self)

        local character = self.char
        if not character then
            return
        end

        local nutrition = CSR_Utils.getCharacterNutritionSummary and CSR_Utils.getCharacterNutritionSummary(character) or nil
        if not nutrition then
            return
        end

        local sectionX = 20
        local sectionY = self.height + 6
        local sectionWidth = math.max(240, self.width - (sectionX * 2))
        local rowCount = 5
        local sectionHeight = FONT_HGT_MEDIUM + (FONT_HGT_SMALL * rowCount) + UI_BORDER_SPACING * (rowCount + 2)
        local labelWidth = math.max(
            getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_char_Weight")),
            getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_CSR_WeightTrend")),
            getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_CSR_Calories")),
            getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_CSR_Protein")),
            getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_CSR_CarbsFats"))
        )

        self:setHeightAndParentHeight(sectionY + sectionHeight + UI_BORDER_SPACING)

        local bg = CSR_Theme.withAlpha(CSR_Theme.getColor("panelBg"), 0.42)
        local border = CSR_Theme.withAlpha(CSR_Theme.getColor("panelBorder"), 0.85)
        local header = CSR_Theme.getColor("accentBlue")
        self:drawRectBorder(sectionX, sectionY, sectionWidth, sectionHeight, border.a, border.r, border.g, border.b)
        self:drawRect(sectionX, sectionY, sectionWidth, sectionHeight, bg.a, bg.r, bg.g, bg.b)

        local accentBar = CSR_Theme.getColor("accentBlue")
        self:drawRect(sectionX, sectionY, 3, sectionHeight, 0.7, accentBar.r, accentBar.g, accentBar.b)

        self:drawText(getText("IGUI_CSR_Nutrition"), sectionX + UI_BORDER_SPACING, sectionY + UI_BORDER_SPACING, header.r, header.g, header.b, 1, UIFont.Medium)

        local rowY = sectionY + UI_BORDER_SPACING + FONT_HGT_MEDIUM + 4

        local weightColor = CSR_Theme.getColor("text")
        csrDrawStatRow(self, getText("IGUI_char_Weight"), nutrition.weightText, sectionX + UI_BORDER_SPACING, rowY, labelWidth, weightColor)

        rowY = rowY + FONT_HGT_SMALL + UI_BORDER_SPACING
        local trendColor
        if nutrition.trend == "Gaining fast" then
            trendColor = CSR_Theme.getColor("accentAmber")
        elseif nutrition.trend == "Gaining" then
            trendColor = { r = 0.9, g = 0.8, b = 0.3 }
        elseif nutrition.trend == "Losing" then
            trendColor = CSR_Theme.getColor("accentRed")
        else
            trendColor = CSR_Theme.getColor("accentGreen")
        end
        csrDrawStatRow(self, getText("IGUI_CSR_WeightTrend"), nutrition.trend, sectionX + UI_BORDER_SPACING, rowY, labelWidth, trendColor)

        rowY = rowY + FONT_HGT_SMALL + UI_BORDER_SPACING
        local calColor
        if nutrition.calories >= 1500 then
            calColor = CSR_Theme.getColor("accentGreen")
        elseif nutrition.calories >= 800 then
            calColor = CSR_Theme.getColor("accentAmber")
        else
            calColor = CSR_Theme.getColor("accentRed")
        end
        csrDrawStatRow(self, getText("IGUI_CSR_Calories"), nutrition.caloriesText, sectionX + UI_BORDER_SPACING, rowY, labelWidth, calColor)

        rowY = rowY + FONT_HGT_SMALL + UI_BORDER_SPACING
        local protColor
        if nutrition.proteins >= 0 then
            protColor = CSR_Theme.getColor("accentGreen")
        else
            protColor = CSR_Theme.getColor("accentRed")
        end
        csrDrawStatRow(self, getText("IGUI_CSR_Protein"), nutrition.proteinsText, sectionX + UI_BORDER_SPACING, rowY, labelWidth, protColor)

        rowY = rowY + FONT_HGT_SMALL + UI_BORDER_SPACING
        local carbFatColor = CSR_Theme.getColor("text")
        csrDrawStatRow(self, getText("IGUI_CSR_CarbsFats"), nutrition.carbsText .. " / " .. nutrition.fatsText, sectionX + UI_BORDER_SPACING, rowY, labelWidth, carbFatColor)
    end

    ISCharacterScreen.CSR_renderPatched = true
end

local RoccoNutritionButton = ISPanel:derive("CSR_RoccoNutritionButton")

function RoccoNutritionButton:new(x, y, size, owner)
    local o = ISPanel.new(self, x, y, size, size)
    o.owner = owner
    o.background = false
    o.tooltip = nil
    return o
end

function RoccoNutritionButton:initialise()
    ISPanel.initialise(self)
    self.tex = getTexture("Item_Apple")
        or getTexture("media/textures/WorldItems/Apple.png")
end

function RoccoNutritionButton:onMouseDown(x, y)
    return true
end

function RoccoNutritionButton:onMouseUp(x, y)
    return true
end

function RoccoNutritionButton:render()
    local hovered = self:isMouseOver()
    local bg = CSR_Theme.getColor("panelBg")
    local border = CSR_Theme.getColor("accentViolet")
    local iconAlpha = hovered and 1.0 or 0.88

    self:drawRect(0, 0, self.width, self.height, hovered and 0.92 or 0.72, bg.r, bg.g, bg.b)
    self:drawRectBorder(0, 0, self.width, self.height, 1.0, border.r, border.g, border.b)

    if self.tex then
        self:drawTextureScaled(self.tex, 3, 3, self.width - 6, self.height - 6,
            iconAlpha, 1.0, 1.0, 1.0)
    else
        local red = CSR_Theme.getColor("accentRed")
        local green = CSR_Theme.getColor("accentGreen")
        local cx = math.floor(self.width / 2)
        self:drawRect(cx - 5, 7, 10, self.height - 12, 0.95, red.r, red.g, red.b)
        self:drawRect(cx - 1, 3, 2, 5, 0.95, green.r, green.g, green.b)
        self:drawRect(cx + 2, 5, 5, 3, 0.95, green.r, green.g, green.b)
    end
end

local function csrRoccoNutritionCharacter(panel)
    if panel and panel.charScreen and panel.charScreen.char then
        return panel.charScreen.char
    end
    local playerNum = panel and tonumber(panel.playerNum) or 0
    if getSpecificPlayer then
        return getSpecificPlayer(playerNum) or (getPlayer and getPlayer() or nil)
    end
    return getPlayer and getPlayer() or nil
end

local function csrRoccoNutritionTooltipLines(panel)
    local character = csrRoccoNutritionCharacter(panel)
    local nutrition = CSR_Utils.getCharacterNutritionSummary
        and CSR_Utils.getCharacterNutritionSummary(character)
        or nil

    local title = "CSR " .. getText("IGUI_CSR_Nutrition")
    if not nutrition then
        return { title, "No nutrition data" }
    end

    return {
        title,
        getText("IGUI_char_Weight") .. ": " .. nutrition.weightText,
        getText("IGUI_CSR_WeightTrend") .. ": " .. nutrition.trend,
        getText("IGUI_CSR_Calories") .. ": " .. nutrition.caloriesText,
        getText("IGUI_CSR_Protein") .. ": " .. nutrition.proteinsText,
        getText("IGUI_CSR_CarbsFats") .. ": " .. nutrition.carbsText .. " / " .. nutrition.fatsText,
    }
end

local function csrDrawRoccoNutritionTooltip(panel)
    local button = panel and panel._csrNutritionButton or nil
    local visible = button and button.isReallyVisible and button:isReallyVisible()
        or (button and button.getIsVisible and button:getIsVisible())
    if not button or not visible or not button:isMouseOver() then return end

    local lines = csrRoccoNutritionTooltipLines(panel)
    local tm = getTextManager()
    local maxW = 0
    for i = 1, #lines do
        maxW = math.max(maxW, tm:MeasureStringX(UIFont.Small, lines[i]))
    end

    local pad = 7
    local lineH = FONT_HGT_SMALL + 2
    local width = maxW + pad * 2
    local height = lineH * #lines + pad * 2
    local mx = panel:getMouseX()
    local my = panel:getMouseY()
    local tx = math.min(mx + 18, panel.width - width - 4)
    local ty = math.min(my + 18, panel.height - height - 4)
    tx = math.max(4, tx)
    ty = math.max(4, ty)

    local bg = CSR_Theme.getColor("panelBg")
    local border = CSR_Theme.getColor("accentViolet")
    local text = CSR_Theme.getColor("text")
    local muted = CSR_Theme.getColor("textMuted")

    panel:drawRect(tx - 1, ty - 1, width + 2, height + 2, 0.65, 0, 0, 0)
    panel:drawRect(tx, ty, width, height, 0.96, bg.r, bg.g, bg.b)
    panel:drawRectBorder(tx, ty, width, height, 1.0, border.r, border.g, border.b)

    for i = 1, #lines do
        local c = (i == 1) and text or muted
        panel:drawText(lines[i], tx + pad, ty + pad + (i - 1) * lineH,
            c.r, c.g, c.b, 1.0, UIFont.Small)
    end
end

local function csrInstallRoccoNutritionButton(panel)
    if not panel or panel._csrNutritionButton or not panel.tabBar then return end

    local bsz = (NR_Config and NR_Config.buttonSize) or FONT_HGT_MEDIUM
    local pad = (NR_Config and NR_Config.padding) or 4
    local tabBarH = (NR_Config and NR_Config.tabBarHeight) or (bsz + pad * 2)
    local x = pad + (tonumber(panel.tabCount) or 0) * (bsz + pad)
    local y = math.floor((tabBarH - bsz) / 2)
    local requiredW = x + bsz + pad

    if requiredW > panel.width and panel.setWidth then
        panel:setWidth(requiredW)
        if panel.tabBar and panel.tabBar.setWidth then
            panel.tabBar:setWidth(requiredW)
        end
    end

    local button = RoccoNutritionButton:new(x, y, bsz, panel)
    button:initialise()
    button:instantiate()
    panel.tabBar:addChild(button)
    panel._csrNutritionButton = button
end

local function csrPatchRoccoCharacterInfo()
    if not CSR_FeatureFlags.isCharacterInfoEnhancementsEnabled() then return end
    if not csrRoccoDetected() or not NR_CharInfoPanel then return end

    if not NR_CharInfoPanel.CSR_NutritionCreatePatched then
        local originalCreateChildren = NR_CharInfoPanel.createChildren
        function NR_CharInfoPanel:createChildren()
            originalCreateChildren(self)
            csrInstallRoccoNutritionButton(self)
        end
        NR_CharInfoPanel.CSR_NutritionCreatePatched = true
    end

    if not NR_CharInfoPanel.CSR_NutritionRenderPatched then
        local originalRender = NR_CharInfoPanel.render
        function NR_CharInfoPanel:render()
            originalRender(self)
            csrDrawRoccoNutritionTooltip(self)
        end
        NR_CharInfoPanel.CSR_NutritionRenderPatched = true
    end

    local instance = ISCharacterInfoWindow and ISCharacterInfoWindow.instance or nil
    if instance and instance.charScreen and instance.tabBar then
        csrInstallRoccoNutritionButton(instance)
    end
end

local function csrPatchCharacterInfoEnvironment()
    if csrRoccoDetected() then
        csrPatchRoccoCharacterInfo()
    else
        csrPatchCharacterScreen()
    end
end

if Events then
    if Events.OnGameStart then
        Events.OnGameStart.Add(csrPatchCharacterInfoEnvironment)
    end
    if Events.OnCreatePlayer then
        Events.OnCreatePlayer.Add(csrPatchCharacterInfoEnvironment)
    end
end
