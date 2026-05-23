if isServer() then return end

require "ISUI/ISTextEntryBox"
require "ISUI/ISButton"
require "ISUI/ISTickBox"
require "ISUI/ISCollapsableWindow"
require "ISUI/BodyParts/ISBodyPartPanel"
require "FAM_Core"
require "FAM_Scale"
require "FAM_ClientCommands"
require "FAM_PatientRecordsPanel"
require "FAM_TreatmentPlanner"

FAM_TriagePanel = ISCollapsableWindow:derive("FAM_TriagePanel")
FAM_BodyPartPanel = ISBodyPartPanel:derive("FAM_BodyPartPanel")

local COLORS = {
    bg = { a = 0.92, r = 0.015, g = 0.025, b = 0.018 },
    panel = { a = 0.78, r = 0.025, g = 0.055, b = 0.035 },
    treatmentPanel = { a = 0.9, r = 0.012, g = 0.035, b = 0.022 },
    line = { a = 0.95, r = 0.1, g = 0.9, b = 0.45 },
    lineDim = { a = 0.4, r = 0.08, g = 0.55, b = 0.25 },
    text = { a = 1, r = 0.86, g = 0.96, b = 0.88 },
    dim = { a = 0.82, r = 0.55, g = 0.72, b = 0.6 },
    danger = { a = 1, r = 0.95, g = 0.28, b = 0.22 },
    caution = { a = 1, r = 0.95, g = 0.78, b = 0.2 },
}

local TRIAGE_ICON = getTexture("media/ui/FAM/TriageIcon.png")
local BODY_STATUS_ICON = getTexture("media/ui/FAM/FAM_BodyStatusIcon.png")

local BASE_TREATMENT_BUTTON_WIDTH = 168
local BASE_TREATMENT_BUTTON_HEIGHT = 22
local BASE_TREATMENT_BUTTON_GAP = 8
local BASE_NOTE_ENTRY_HEIGHT = 78
local BASE_NOTE_BUTTON_WIDTH = 96
local BASE_NOTE_PANEL_HEIGHT = 118
local BASE_PANEL_WIDTH = 1080
local BASE_MODEL_Y = 84
local BASE_MODEL_W = 218
local BASE_MODEL_H = 430
local BASE_BODY_MAP_H = 286
local BASE_SELECTED_PART_H = 58
local BASE_PULSE_H = 68
local BASE_TAB_Y = 52
local BASE_TAB_GAP = 8
local BASE_TAB_W = 96
local BASE_TAB_H = 22
local BASE_VITAL_LEFT_LABEL_X = 18
local BASE_VITAL_LEFT_BAR_X = 132
local BASE_VITAL_LEFT_VALUE_X = 258
local BASE_VITAL_RIGHT_LABEL_X = 322
local BASE_VITAL_RIGHT_BAR_X = 452
local BASE_VITAL_RIGHT_VALUE_X = 578

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local TREATMENT_BUTTON_WIDTH = BASE_TREATMENT_BUTTON_WIDTH
local TREATMENT_BUTTON_HEIGHT = BASE_TREATMENT_BUTTON_HEIGHT
local TREATMENT_BUTTON_GAP = BASE_TREATMENT_BUTTON_GAP
local TREATMENT_BUTTONS_PER_ROW = 4
local NOTE_ENTRY_HEIGHT = BASE_NOTE_ENTRY_HEIGHT
local NOTE_BUTTON_WIDTH = BASE_NOTE_BUTTON_WIDTH
local NOTE_PANEL_HEIGHT = BASE_NOTE_PANEL_HEIGHT
local PANEL_WIDTH = BASE_PANEL_WIDTH
local CONTENT_WIDTH = BASE_PANEL_WIDTH - BASE_MODEL_W
local MODEL_X = BASE_PANEL_WIDTH - BASE_MODEL_W
local MODEL_Y = BASE_MODEL_Y
local MODEL_W = BASE_MODEL_W
local MODEL_H = BASE_MODEL_H
local BODY_MAP_H = BASE_BODY_MAP_H
local SELECTED_PART_H = BASE_SELECTED_PART_H
local PULSE_H = BASE_PULSE_H
local PULSE_FRAME_LIMIT = 80
local TAB_Y = BASE_TAB_Y
local TAB_GAP = BASE_TAB_GAP
local TAB_W = BASE_TAB_W
local TAB_H = BASE_TAB_H
local TAB_X = MODEL_X - 16 - ((TAB_W * 4) + (TAB_GAP * 3))
local VITAL_LEFT_LABEL_X = BASE_VITAL_LEFT_LABEL_X
local VITAL_LEFT_BAR_X = BASE_VITAL_LEFT_BAR_X
local VITAL_LEFT_VALUE_X = BASE_VITAL_LEFT_VALUE_X
local VITAL_RIGHT_LABEL_X = BASE_VITAL_RIGHT_LABEL_X
local VITAL_RIGHT_BAR_X = BASE_VITAL_RIGHT_BAR_X
local VITAL_RIGHT_VALUE_X = BASE_VITAL_RIGHT_VALUE_X

local PULSE_FOLDERS = {
    Fine = "fine",
    Caution = "caution",
    Critical = "critical",
    Danger = "danger",
    Poison = "poison",
    Death = "danger",
}

local PULSE_SPEEDS = {
    Fine = 200,
    Caution = 200,
    Critical = 150,
    Danger = 120,
    Poison = 200,
    Death = 9999,
}

local PULSE_TEXTURE_PATHS = {
    "42/media/ui/%s/frame_%02d.png",
    "media/ui/%s/frame_%02d.png",
}

local function px(value)
    if FAM_Scale and FAM_Scale.px then
        return FAM_Scale.px(value)
    end
    return value
end

local function clampNumber(value, minValue, maxValue)
    value = tonumber(value) or 0
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function getPanelHeight()
    if FAM_Scale and FAM_Scale.refresh then
        FAM_Scale.refresh()
    end
    local screenH = getCore():getScreenHeight()
    local target = px(840)
    local minHeight = px(650)
    return math.min(target, math.max(minHeight, screenH - px(40)))
end

local function refreshLayoutMetrics(tabCount)
    if FAM_Scale and FAM_Scale.refresh then
        FAM_Scale.refresh()
    end
    local core = getCore()
    local screenW = core and core:getScreenWidth() or BASE_PANEL_WIDTH
    local tm = getTextManager()
    FONT_HGT_SMALL = tm:getFontHeight(UIFont.Small)
    FONT_HGT_MEDIUM = tm:getFontHeight(UIFont.Medium)
    TREATMENT_BUTTON_WIDTH = px(BASE_TREATMENT_BUTTON_WIDTH)
    TREATMENT_BUTTON_HEIGHT = math.max(FONT_HGT_SMALL + px(8), px(BASE_TREATMENT_BUTTON_HEIGHT))
    TREATMENT_BUTTON_GAP = px(BASE_TREATMENT_BUTTON_GAP)
    NOTE_ENTRY_HEIGHT = px(BASE_NOTE_ENTRY_HEIGHT)
    NOTE_BUTTON_WIDTH = px(BASE_NOTE_BUTTON_WIDTH)
    NOTE_PANEL_HEIGHT = px(BASE_NOTE_PANEL_HEIGHT)
    PANEL_WIDTH = clampNumber(px(BASE_PANEL_WIDTH), px(880), math.max(px(880), screenW - px(40)))
    MODEL_W = clampNumber(px(BASE_MODEL_W), px(194), px(260))
    MODEL_X = PANEL_WIDTH - MODEL_W - px(20)
    CONTENT_WIDTH = MODEL_X - px(22)
    TREATMENT_BUTTONS_PER_ROW = math.max(2, math.min(4, math.floor((CONTENT_WIDTH - px(44) + TREATMENT_BUTTON_GAP) / (TREATMENT_BUTTON_WIDTH + TREATMENT_BUTTON_GAP))))
    MODEL_Y = px(BASE_MODEL_Y)
    MODEL_H = clampNumber(px(BASE_MODEL_H), px(360), math.max(px(360), getPanelHeight() - MODEL_Y - px(90)))
    BODY_MAP_H = clampNumber(px(BASE_BODY_MAP_H), px(230), math.max(px(230), MODEL_H - px(144)))
    SELECTED_PART_H = math.max(px(BASE_SELECTED_PART_H), FONT_HGT_SMALL * 3 + px(12))
    PULSE_H = px(BASE_PULSE_H)
    TAB_Y = px(BASE_TAB_Y)
    TAB_GAP = px(BASE_TAB_GAP)
    TAB_H = math.max(FONT_HGT_SMALL + px(8), px(BASE_TAB_H))
    tabCount = tabCount or 4
    TAB_W = clampNumber(px(BASE_TAB_W), px(80), px(108))
    local totalTabW = (TAB_W * tabCount) + (TAB_GAP * math.max(0, tabCount - 1))
    if totalTabW > MODEL_X - px(330) then
        TAB_W = math.max(px(78), math.floor((MODEL_X - px(330) - (TAB_GAP * math.max(0, tabCount - 1))) / math.max(1, tabCount)))
        totalTabW = (TAB_W * tabCount) + (TAB_GAP * math.max(0, tabCount - 1))
    end
    TAB_X = MODEL_X - px(16) - totalTabW
    VITAL_LEFT_LABEL_X = px(BASE_VITAL_LEFT_LABEL_X)
    VITAL_LEFT_BAR_X = px(BASE_VITAL_LEFT_BAR_X)
    VITAL_LEFT_VALUE_X = px(BASE_VITAL_LEFT_VALUE_X)
    VITAL_RIGHT_LABEL_X = px(BASE_VITAL_RIGHT_LABEL_X)
    VITAL_RIGHT_BAR_X = px(BASE_VITAL_RIGHT_BAR_X)
    VITAL_RIGHT_VALUE_X = px(BASE_VITAL_RIGHT_VALUE_X)
end

local function asTextInt(value)
    return tostring(math.floor(tonumber(value) or 0))
end

local function drawGlowBorder(self, x, y, w, h)
    self:drawRectBorder(x - 1, y - 1, w + 2, h + 2, 0.18, COLORS.line.r, COLORS.line.g, COLORS.line.b)
    self:drawRectBorder(x, y, w, h, COLORS.line.a, COLORS.line.r, COLORS.line.g, COLORS.line.b)
end

local function drawBar(self, x, y, w, h, value)
    local pct = FAM.clamp(value / 100, 0, 1)
    self:drawRect(x, y, w, h, 0.45, 0, 0, 0)
    self:drawRectBorder(x, y, w, h, COLORS.lineDim.a, COLORS.lineDim.r, COLORS.lineDim.g, COLORS.lineDim.b)
    if pct > 0 then
        local r = pct > 0.66 and COLORS.danger.r or (pct > 0.33 and COLORS.caution.r or COLORS.line.r)
        local g = pct > 0.66 and COLORS.danger.g or (pct > 0.33 and COLORS.caution.g or COLORS.line.g)
        local b = pct > 0.66 and COLORS.danger.b or (pct > 0.33 and COLORS.caution.b or COLORS.line.b)
        self:drawRect(x + 1, y + 1, math.max(1, (w - 2) * pct), h - 2, 0.82, r, g, b)
    end
end

local function clampRowScroll(value, totalRows, visibleRows)
    local maxOffset = math.max(0, (tonumber(totalRows) or 0) - (tonumber(visibleRows) or 0))
    value = math.floor(tonumber(value) or 0)
    if value < 0 then return 0 end
    if value > maxOffset then return maxOffset end
    return value
end

local function drawRowScrollbar(self, x, y, h, totalRows, visibleRows, offset)
    if not totalRows or not visibleRows or totalRows <= visibleRows or h <= 0 then return end
    local trackW = px(5)
    local maxOffset = math.max(1, totalRows - visibleRows)
    local thumbH = math.max(px(14), h * (visibleRows / totalRows))
    local thumbY = y + ((h - thumbH) * ((offset or 0) / maxOffset))
    self:drawRect(x, y, trackW, h, 0.28, 0, 0, 0)
    self:drawRect(x, thumbY, trackW, thumbH, 0.76, COLORS.line.r, COLORS.line.g, COLORS.line.b)
end

local hasPulseTexture

local function isREHealthStatusActive()
    if not getActivatedMods then return true end
    local mods = getActivatedMods()
    if not mods or not mods.contains then return true end
    return mods:contains("REHealthStatus") or hasPulseTexture("fine")
end

local function loadPulseFrames(folder)
    local frames = {}
    if not folder or not getTexture or not isREHealthStatusActive() then return frames end
    for i = 0, PULSE_FRAME_LIMIT do
        local texture = nil
        for pathIndex = 1, #PULSE_TEXTURE_PATHS do
            texture = getTexture(string.format(PULSE_TEXTURE_PATHS[pathIndex], folder, i))
            if texture then break end
        end
        if not texture then break end
        if texture.setMinFilter and Texture and Texture.FilterMode then
            texture:setMinFilter(Texture.FilterMode.Linear)
        end
        if texture.setMagFilter and Texture and Texture.FilterMode then
            texture:setMagFilter(Texture.FilterMode.Linear)
        end
        frames[#frames + 1] = texture
    end
    return frames
end

local function getPulseFrames(panel, state)
    panel.famPulseAnimations = panel.famPulseAnimations or {}
    local frames = panel.famPulseAnimations[state]
    if frames == nil then
        frames = loadPulseFrames(PULSE_FOLDERS[state] or PULSE_FOLDERS.Fine)
        panel.famPulseAnimations[state] = frames
    end
    return frames
end

local function getPulseState(patient)
    if not patient or not patient.isAlive or not patient:isAlive() then return "Death" end
    local bodyDamage = FAM.getBodyDamage(patient)
    if not bodyDamage then return "Fine" end

    local poisoned = false
    if bodyDamage.IsPoisoned and bodyDamage:IsPoisoned() then poisoned = true end
    local foodSick = bodyDamage.getFoodSicknessLevel and bodyDamage:getFoodSicknessLevel() or 0
    local sickLvl = bodyDamage.getSicknessLevel and bodyDamage:getSicknessLevel() or 0
    local poisonLoad = FAM.getPoisonLevel and FAM.getPoisonLevel(patient) or 0
    if poisoned or foodSick >= 20 or sickLvl >= 20 or poisonLoad >= 20 then return "Poison" end

    local health = bodyDamage.getHealth and bodyDamage:getHealth() or 100
    if health >= 90 then return "Fine" end
    if health >= 60 then return "Caution" end
    if health >= 30 then return "Critical" end
    if health > 0 then return "Danger" end
    return "Death"
end

local function getPulseColor(state)
    if state == "Danger" or state == "Death" then return COLORS.danger end
    if state == "Critical" or state == "Caution" then return COLORS.caution end
    if state == "Poison" then return { a = 1, r = 0.64, g = 0.38, b = 0.94 } end
    return COLORS.line
end

local function advancePulseFrame(panel, state, frameCount)
    if frameCount <= 1 then return 1 end
    if panel.famPulseState ~= state then
        panel.famPulseState = state
        panel.famPulseFrame = 1
        panel.famPulseTimer = 0
    end
    if state == "Death" then return 1 end

    local dt = 16
    if UIManager and UIManager.getMillisSinceLastUpdate then
        dt = UIManager.getMillisSinceLastUpdate() or dt
    end

    local speed = PULSE_SPEEDS[state] or 200
    panel.famPulseTimer = (panel.famPulseTimer or 0) + dt
    while panel.famPulseTimer >= speed do
        panel.famPulseTimer = panel.famPulseTimer - speed
        panel.famPulseFrame = ((panel.famPulseFrame or 1) % frameCount) + 1
    end
    return panel.famPulseFrame or 1
end

local function drawPulseShell(self, x, y, w, h, state, fill)
    local color = getPulseColor(state)
    if fill ~= false then
        self:drawRect(x, y, w, h, 0.5, 0.005, 0.014, 0.009)
    end
    self:drawRectBorder(x - 1, y - 1, w + 2, h + 2, 0.18, color.r, color.g, color.b)
    self:drawRectBorder(x, y, w, h, 0.82, color.r, color.g, color.b)
    self:drawRectBorder(x + 2, y + 2, w - 4, h - 4, 0.16, color.r, color.g, color.b)
end

local function drawPulseFallback(self, x, y, w, h, state)
    local color = getPulseColor(state)
    self:drawText(state:upper(), x + 8, y + 8, color.r, color.g, color.b, 0.86, UIFont.Small)
    local baseY = y + h - 16
    for i = 0, 8 do
        local barH = 4 + ((i * 7) % 22)
        self:drawRect(x + 14 + (i * 21), baseY - barH, 12, barH, 0.24, color.r, color.g, color.b)
    end
end

local function trimText(text, width, font)
    text = tostring(text or "")
    local textManager = getTextManager()
    if text == "" or textManager:MeasureStringX(font, text) <= width then
        return text
    end
    while string.len(text) > 0 and textManager:MeasureStringX(font, text .. "...") > width do
        text = string.sub(text, 1, -2)
    end
    return text .. "..."
end

local function formatText(key, ...)
    local text = getText(key)
    local values = { ... }
    for i = 1, #values do
        local value = tostring(values[i] or "")
        text = string.gsub(text, "%%" .. tostring(i) .. "%$%$", function()
            return value
        end)
        text = string.gsub(text, "%%" .. tostring(i) .. "%$", function()
            return value
        end)
        text = string.gsub(text, "%%" .. tostring(i), function()
            return value
        end)
    end
    return text
end

local function looksLikeTranslationKey(text)
    text = tostring(text or "")
    return string.find(text, "^IGUI_") ~= nil
        or string.find(text, "^Tooltip_") ~= nil
        or string.find(text, "^ContextMenu_") ~= nil
end

local function displayText(text, fallback)
    text = tostring(text or "")
    if text == "" then
        return fallback or ""
    end
    if looksLikeTranslationKey(text) then
        local translated = getText(text)
        if translated and translated ~= text and not looksLikeTranslationKey(translated) then
            return translated
        end
        return fallback or ""
    end
    return text
end

local function fallbackText(key, fallback)
    return displayText(getText(key), fallback)
end

local function getPatientSnapshot(patient)
    if FAM_ClientCommands and FAM_ClientCommands.getPatientSnapshot then
        return FAM_ClientCommands.getPatientSnapshot(patient)
    end
    return nil
end

local function snapshotMetric(snapshot, key, fallback)
    local metrics = snapshot and snapshot.metrics or nil
    if metrics and metrics[key] ~= nil then
        return tonumber(metrics[key]) or fallback
    end
    return fallback
end

local function snapshotBodyPartRow(snapshot, index)
    if not snapshot or not snapshot.bodyPartRows or not index then return nil end
    for i = 1, #snapshot.bodyPartRows do
        local row = snapshot.bodyPartRows[i]
        if tonumber(row.index) == tonumber(index) then
            return row
        end
    end
    return nil
end

function hasPulseTexture(folder)
    if not getTexture then return false end
    folder = folder or "fine"
    for pathIndex = 1, #PULSE_TEXTURE_PATHS do
        if getTexture(string.format(PULSE_TEXTURE_PATHS[pathIndex], folder, 0)) then
            return true
        end
    end
    return false
end

local function bodyPartName(bodyPart)
    if not BodyPartType or not bodyPart then return "Unknown" end
    return BodyPartType.ToString(bodyPart:getType())
end

local function getBodyPartForPrimaryAmputation(patient, bodyPart)
    if not patient or not bodyPart or not FAM.isSuppressedAmputationPart(patient, bodyPart) then
        return bodyPart
    end
    return FAM.getBodyPartByName(patient, FAM.getPrimaryAmputationName(patient, bodyPart)) or bodyPart
end

local function buildAvailableTabs()
    local tabs = {
        { id = "chart", label = getText("IGUI_FAM_TabChart") },
        { id = "providers", label = getText("IGUI_FAM_TabProviders") },
        { id = "pandemic", label = getText("IGUI_FAM_TabPandemic") },
        { id = "pathology", label = getText("IGUI_FAM_TabPathology") },
    }
    if FAM.isZVirusVaccineAvailable and FAM.isZVirusVaccineAvailable() then
        tabs[#tabs + 1] = { id = "virology", label = getText("IGUI_FAM_TabVirology") }
    end
    return tabs
end

local function itemFullType(item)
    if not item then return nil end
    if item.getFullType then return item:getFullType() end
    return item:getModule() .. "." .. item:getType()
end

local function scanContainer(container, callback, childContainers)
    if not container or not container.getItems then return end
    local items = container:getItems()
    if not items then return end
    for i = 1, items:size() do
        local item = items:get(i - 1)
        if item and item.IsInventoryContainer and item:IsInventoryContainer() then
            if childContainers then
                table.insert(childContainers, item:getInventory())
            end
        elseif item then
            callback(item)
        end
    end
end

local function forEachInventoryItem(character, callback)
    if not character or not callback then return end
    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.getContainers then
        local containers = ISInventoryPaneContextMenu.getContainers(character)
        local done = {}
        local childContainers = {}
        if containers then
            for i = 1, containers:size() do
                local container = containers:get(i - 1)
                done[container] = true
                childContainers = {}
                scanContainer(container, callback, childContainers)
                for j = 1, #childContainers do
                    local child = childContainers[j]
                    if not done[child] then
                        done[child] = true
                        scanContainer(child, callback, nil)
                    end
                end
            end
            return
        end
    end
    scanContainer(character:getInventory(), callback, nil)
end

local function findInventoryItem(character, predicate)
    local found = nil
    forEachInventoryItem(character, function(item)
        if not found and predicate(item) then
            found = item
        end
    end)
    return found
end

local function countInventoryTypes(character, types)
    local counts = {}
    forEachInventoryItem(character, function(item)
        local fullType = itemFullType(item)
        local itemType = item:getType()
        for label, typeList in pairs(types) do
            for i = 1, #typeList do
                if fullType == typeList[i] or itemType == typeList[i] then
                    counts[label] = (counts[label] or 0) + 1
                    return
                end
            end
        end
    end)
    return counts
end

local ZVV_VACCINE_TYPES = {
    "LabItems.CmpSyringeWithPlainVaccine",
    "LabItems.CmpSyringeWithQualityVaccine",
    "LabItems.CmpSyringeWithAdvancedVaccine",
    "LabItems.CmpSyringeWithCure",
    "LabItems.CmpSyringeReusableWithPlainVaccine",
    "LabItems.CmpSyringeReusableWithQualityVaccine",
    "LabItems.CmpSyringeReusableWithAdvancedVaccine",
    "LabItems.CmpSyringeReusableWithCure",
}

local ZVV_BLOOD_TYPES = {
    "LabItems.CmpSyringeWithBlood",
    "LabItems.CmpSyringeReusableWithBlood",
}

local ZVV_EMPTY_SYRINGE_TYPES = {
    "LabItems.LabSyringe",
    "LabItems.LabSyringeReusable",
}

local function itemMatchesAny(item, types)
    if not item then return false end
    local fullType = itemFullType(item)
    local itemType = item:getType()
    for i = 1, #types do
        if fullType == types[i] or itemType == types[i] then
            return true
        end
    end
    return false
end

local function syncBodyPanelSelection(panel, x, y)
    if not panel or not panel.getPartForCoordinate then return false end
    local selected = panel:getPartForCoordinate(x, y)
    if not selected or not selected.bodyPart then return false end

    if panel.setSelected then
        panel:setSelected(x, y, true)
    end
    if panel.parent and panel.parent.onBodyPartPanelSelection then
        panel.parent:onBodyPartPanelSelection(selected.bodyPart)
    end
    return true
end

local function syncBodyPartPanelPatient(panel, patient)
    if not panel or not panel.bps or not patient then return end
    local bodyDamage = FAM.getBodyDamage(patient)
    if not bodyDamage then return end
    for i = 1, #panel.bps do
        local bp = panel.bps[i]
        if bp and bp.bodyPartType then
            bp.bodyPart = bodyDamage:getBodyPart(bp.bodyPartType)
        end
    end
end

function FAM_BodyPartPanel:onMouseDown(x, y)
    if syncBodyPanelSelection(self, x, y) then
        return true
    end
    if ISBodyPartPanel.onMouseDown then
        return ISBodyPartPanel.onMouseDown(self, x, y)
    end
    return false
end

function FAM_BodyPartPanel:onMouseUp(x, y)
    if syncBodyPanelSelection(self, x, y) then
        return true
    end
    if ISBodyPartPanel.onMouseUp then
        return ISBodyPartPanel.onMouseUp(self, x, y)
    end
    return false
end

function FAM_BodyPartPanel:onRightMouseUp(x, y)
    if syncBodyPanelSelection(self, x, y) then
        if self.parent and self.parent.openBodyPartContextMenu and self.selectedBp and self.selectedBp.bodyPart then
            self.parent:openBodyPartContextMenu(self.selectedBp.bodyPart, self:getX() + x, self:getY() + y)
        end
        return true
    end
    if ISBodyPartPanel.onRightMouseUp then
        return ISBodyPartPanel.onRightMouseUp(self, x, y)
    end
    return false
end

function FAM_TriagePanel:initialise()
    ISCollapsableWindow.initialise(self)
end

function FAM_TriagePanel:createChildren()
    refreshLayoutMetrics(4)
    ISCollapsableWindow.createChildren(self)
    self.guideButton = ISButton:new(self.width - px(230), px(24), px(70), px(24), getText("IGUI_FAM_Guide"), self, FAM_TriagePanel.onGuide)
    self.guideButton:initialise()
    self:addChild(self.guideButton)
    self.refresh = ISButton:new(self.width - px(154), px(24), px(70), px(24), getText("IGUI_FAM_Refresh"), self, FAM_TriagePanel.onRefresh)
    self.refresh:initialise()
    self:addChild(self.refresh)
    self.closeButton = ISButton:new(self.width - px(78), px(24), px(58), px(24), getText("IGUI_FAM_Close"), self, FAM_TriagePanel.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)
    self.treatmentButtons = {}
    self.tabButtons = {}
    self.availableTabs = buildAvailableTabs()
    refreshLayoutMetrics(#self.availableTabs)
    local tabs = self.availableTabs
    for i = 1, #tabs do
        local tab = tabs[i]
        local button = ISButton:new(TAB_X + ((i - 1) * (TAB_W + TAB_GAP)), TAB_Y, TAB_W, TAB_H, tab.label, self, FAM_TriagePanel.onTabButton)
        button.internal = tab.id
        button:initialise()
        button:instantiate()
        button.borderColor = { r = COLORS.line.r, g = COLORS.line.g, b = COLORS.line.b, a = 0.75 }
        self:addChild(button)
        self.tabButtons[tab.id] = button
    end

    self.notesEntry = ISTextEntryBox:new("", px(22), px(520), self.width - px(210), NOTE_ENTRY_HEIGHT)
    self.notesEntry:initialise()
    self.notesEntry:instantiate()
    self.notesEntry.font = UIFont.Small
    if self.notesEntry.setMultipleLine then
        self.notesEntry:setMultipleLine(true)
    end
    if self.notesEntry.setMaxLines then
        self.notesEntry:setMaxLines(8)
    end
    if self.notesEntry.setMaxTextLength then
        self.notesEntry:setMaxTextLength(FAM.PATIENT_NOTE_MAX_LENGTH)
    end
    self.notesEntry.onTextChange = function() self:onNoteTextChanged() end
    self.notesEntry.borderColor = { r = COLORS.line.r, g = COLORS.line.g, b = COLORS.line.b, a = 0.75 }
    self.notesEntry.backgroundColor = { r = 0.01, g = 0.025, b = 0.015, a = 0.88 }
    self.notesEntry.textColor = { r = COLORS.text.r, g = COLORS.text.g, b = COLORS.text.b, a = 1 }
    self:addChild(self.notesEntry)

    self.notesSave = ISButton:new(self.width - px(176), px(520), NOTE_BUTTON_WIDTH, px(24), getText("IGUI_FAM_SubmitNotes"), self, FAM_TriagePanel.onSaveNote)
    self.notesSave:initialise()
    self.notesSave:instantiate()
    self.notesSave.borderColor = { r = COLORS.line.r, g = COLORS.line.g, b = COLORS.line.b, a = 0.85 }
    self:addChild(self.notesSave)

    self.notesRevert = ISButton:new(self.width - px(94), px(520), NOTE_BUTTON_WIDTH, px(24), getText("IGUI_FAM_RevertNote"), self, FAM_TriagePanel.onRevertNote)
    self.notesRevert:initialise()
    self.notesRevert:instantiate()
    self.notesRevert.borderColor = { r = COLORS.dim.r, g = COLORS.dim.g, b = COLORS.dim.b, a = 0.85 }
    self:addChild(self.notesRevert)

    self.autoNotesEnabled = FAM_TriagePanel.autoNotesEnabled == true
    self.autoNotesBox = ISTickBox:new(self.width - px(176), px(550), (NOTE_BUTTON_WIDTH * 2) + px(6), px(24), "", self, FAM_TriagePanel.onAutoNotesChanged)
    self.autoNotesBox:initialise()
    self.autoNotesBox:instantiate()
    self.autoNotesBox:addOption(getText("IGUI_FAM_AutoNotes"))
    self.autoNotesBox:setSelected(1, self.autoNotesEnabled)
    self.autoNotesBox.font = UIFont.Small
    self.autoNotesBox.textColor = { r = COLORS.text.r, g = COLORS.text.g, b = COLORS.text.b, a = 1 }
    self:addChild(self.autoNotesBox)

    self.notesRecords = ISButton:new(self.width - px(176), px(550), (NOTE_BUTTON_WIDTH * 2) + px(6), px(24), getText("IGUI_FAM_RecordsButton"), self, FAM_TriagePanel.onPatientRecords)
    self.notesRecords:initialise()
    self.notesRecords:instantiate()
    self.notesRecords.borderColor = { r = COLORS.line.r, g = COLORS.line.g, b = COLORS.line.b, a = 0.85 }
    self:addChild(self.notesRecords)

    self.pandemicQuarantine = ISButton:new(MODEL_X, MODEL_Y + MODEL_H + px(70), px(102), px(24), getText("IGUI_FAM_Quarantine"), self, FAM_TriagePanel.onPandemicQuarantine)
    self.pandemicQuarantine:initialise()
    self.pandemicQuarantine:instantiate()
    self.pandemicQuarantine.borderColor = { r = COLORS.line.r, g = COLORS.line.g, b = COLORS.line.b, a = 0.85 }
    self:addChild(self.pandemicQuarantine)

    self.pandemicTreat = ISButton:new(MODEL_X + px(112), MODEL_Y + MODEL_H + px(70), px(106), px(24), getText("IGUI_FAM_TreatCase"), self, FAM_TriagePanel.onPandemicTreat)
    self.pandemicTreat:initialise()
    self.pandemicTreat:instantiate()
    self.pandemicTreat.borderColor = { r = COLORS.line.r, g = COLORS.line.g, b = COLORS.line.b, a = 0.85 }
    self:addChild(self.pandemicTreat)
    self:ensureBodyPartPanel()
    self:refreshLayout()
    self:setNoteControlsVisible(false)
    self:setPandemicControlsVisible(false)
end

function FAM_TriagePanel:onRefresh()
    FAM.refreshCorpseExposureDisplay(self.patient)
    FAM_ClientCommands.requestPatientSnapshot(self.doctor, self.patient)
    FAM_ClientCommands.requestProviderStats(self.doctor)
    FAM_ClientCommands.requestPandemicStatus(self.doctor)
    FAM_ClientCommands.requestPathology(self.doctor)
    self.refreshTick = (self.refreshTick or 0) + 1
end

function FAM_TriagePanel:onGuide()
    self.guideVisible = not self.guideVisible
end

function FAM_TriagePanel:onTabButton(button)
    self.activeTab = button.internal or "chart"
    if self.activeTab == "providers" then
        FAM_ClientCommands.requestProviderStats(self.doctor)
    elseif self.activeTab == "pandemic" then
        FAM_ClientCommands.requestPandemicStatus(self.doctor)
    elseif self.activeTab == "pathology" then
        FAM_ClientCommands.requestPathology(self.doctor)
    end
    self:syncTabButtons()
end

function FAM_TriagePanel:onClose()
    self:close()
end

function FAM_TriagePanel:close()
    FAM_TriagePanel.destroyInstance(true)
end

local function shouldReceiveBodyDamageUpdates(doctor, patient)
    return isClient and isClient()
        and doctor
        and patient
        and doctor ~= patient
        and patient.isLocalPlayer
        and not patient:isLocalPlayer()
        and doctor.startReceivingBodyDamageUpdates
end

local function stopBodyDamageUpdates(panel)
    if panel
        and panel.receivingDoctor
        and panel.receivingPatient
        and panel.receivingDoctor.stopReceivingBodyDamageUpdates then
        panel.receivingDoctor:stopReceivingBodyDamageUpdates(panel.receivingPatient)
    end
    if panel then
        panel.receivingDoctor = nil
        panel.receivingPatient = nil
    end
end

local function startBodyDamageUpdates(panel, doctor, patient)
    if not panel then return end
    if panel.receivingDoctor ~= doctor or panel.receivingPatient ~= patient then
        stopBodyDamageUpdates(panel)
    end
    if shouldReceiveBodyDamageUpdates(doctor, patient) then
        doctor:startReceivingBodyDamageUpdates(patient)
        panel.receivingDoctor = doctor
        panel.receivingPatient = patient
    end
end

function FAM_TriagePanel.destroyInstance(saveNotes)
    local panel = FAM_TriagePanel.instance
    if not panel then return end
    stopBodyDamageUpdates(panel)
    panel:clearTreatmentButtons()
    panel:setNoteControlsVisible(false)
    panel.doctor = nil
    panel.patient = nil
    panel.notesPatient = nil
    panel.notesSavedText = nil
    panel.selectedBodyPartIndex = nil
    if saveNotes then
        ISCollapsableWindow.close(panel)
    else
        panel:removeFromUIManager()
    end
    FAM_TriagePanel.instance = nil
end

function FAM_TriagePanel.closeForSessionEnd()
    FAM_TriagePanel.destroyInstance(false)
end

function FAM_TriagePanel:clearTreatmentButtons()
    if not self.treatmentButtons then
        self.treatmentButtons = {}
        return
    end
    for i = 1, #self.treatmentButtons do
        self:removeChild(self.treatmentButtons[i])
    end
    self.treatmentButtons = {}
    self.treatmentButtonSignature = nil
end

function FAM_TriagePanel:syncTabButtons()
    if not self.tabButtons then return end
    local active = self.activeTab or "chart"
    for id, button in pairs(self.tabButtons) do
        local selected = id == active
        button.backgroundColor = selected and { r = 0.02, g = 0.22, b = 0.09, a = 0.85 } or { r = 0, g = 0, b = 0, a = 0.45 }
        button.textColor = selected and { r = COLORS.line.r, g = COLORS.line.g, b = COLORS.line.b, a = 1 } or { r = COLORS.text.r, g = COLORS.text.g, b = COLORS.text.b, a = 1 }
    end
end

function FAM_TriagePanel:layoutTabButtons()
    if not self.tabButtons or not self.availableTabs then return end
    refreshLayoutMetrics(#self.availableTabs)
    for i = 1, #self.availableTabs do
        local tab = self.availableTabs[i]
        local button = self.tabButtons[tab.id]
        if button then
            button:setX(TAB_X + ((i - 1) * (TAB_W + TAB_GAP)))
            button:setY(TAB_Y)
            button:setWidth(TAB_W)
            button:setHeight(TAB_H)
        end
    end
end

function FAM_TriagePanel:refreshLayout()
    self.availableTabs = self.availableTabs or buildAvailableTabs()
    refreshLayoutMetrics(#self.availableTabs)
    local targetHeight = getPanelHeight()
    if self.width ~= PANEL_WIDTH then
        self:setWidth(PANEL_WIDTH)
    end
    if self.height ~= targetHeight then
        self:setHeight(targetHeight)
    end

    if self.guideButton then
        self.guideButton:setX(self.width - px(230))
        self.guideButton:setY(px(24))
        self.guideButton:setWidth(px(70))
        self.guideButton:setHeight(px(24))
    end
    if self.refresh then
        self.refresh:setX(self.width - px(154))
        self.refresh:setY(px(24))
        self.refresh:setWidth(px(70))
        self.refresh:setHeight(px(24))
    end
    if self.closeButton then
        self.closeButton:setX(self.width - px(78))
        self.closeButton:setY(px(24))
        self.closeButton:setWidth(px(58))
        self.closeButton:setHeight(px(24))
    end
    if self.pandemicQuarantine then
        self.pandemicQuarantine:setX(MODEL_X)
        self.pandemicQuarantine:setY(MODEL_Y + MODEL_H + px(70))
        self.pandemicQuarantine:setWidth(px(102))
        self.pandemicQuarantine:setHeight(px(24))
    end
    if self.pandemicTreat then
        self.pandemicTreat:setX(MODEL_X + px(112))
        self.pandemicTreat:setY(MODEL_Y + MODEL_H + px(70))
        self.pandemicTreat:setWidth(px(106))
        self.pandemicTreat:setHeight(px(24))
    end
    self:layoutTabButtons()
end

function FAM_TriagePanel:updatePatientModel()
end

function FAM_TriagePanel:getDoctor()
    return self.doctor
end

function FAM_TriagePanel:getPatient()
    return self.patient
end

function FAM_TriagePanel:removeBodyPartPanel()
    if not self.bodyPartPanel then return end
    self.bodyPartPanel:setVisible(false)
    self:removeChild(self.bodyPartPanel)
    self.bodyPartPanel = nil
end

function FAM_TriagePanel:ensureBodyPartPanel()
    if self.bodyPartPanel and self.bodyPartPanel.player == self.patient then
        return self.bodyPartPanel
    end

    self:removeBodyPartPanel()
    if not self.patient or not FAM_BodyPartPanel then
        return nil
    end

    local panel = FAM_BodyPartPanel:new(self.patient, 0, 0, self, nil)
    panel:initialise()
    syncBodyPartPanelPatient(panel, self.patient)
    panel:instantiate()
    if panel.setAlphas then
        panel:setAlphas(0.58, 1.0, 1.0, 0.34, 0.34)
    end
    if panel.setColorScheme and Color then
        panel:setColorScheme({
            { val = 0.00, color = Color.new(0.70, 0.84, 0.74, 1) },
            { val = 0.20, color = Color.new(0.10, 0.90, 0.45, 1) },
            { val = 0.40, color = Color.new(0.95, 0.78, 0.20, 1) },
            { val = 0.60, color = Color.new(1.00, 0.45, 0.12, 1) },
            { val = 0.80, color = Color.new(0.72, 0.34, 0.92, 1) },
            { val = 1.00, color = Color.new(0.95, 0.28, 0.22, 1) },
        })
    end
    if panel.enableNodes then
        panel:enableNodes("media/ui/BodyParts/bps_node_diamond", "media/ui/BodyParts/bps_node_diamond_outline")
    end
    panel:setVisible(false)
    self:addChild(panel)
    self.bodyPartPanel = panel
    return panel
end

function FAM_TriagePanel:onBodyPartPanelSelection(bodyPart)
    if not bodyPart then return end
    bodyPart = getBodyPartForPrimaryAmputation(self.patient, bodyPart)
    self:selectBodyPartIndex(bodyPart:getIndex())
end

function FAM_TriagePanel:selectBodyPartIndex(index)
    if not index then return end
    self.selectedBodyPartIndex = index
    self.treatmentButtonSignature = nil
    self.conditionReaderScroll = 0
    self.bodyPartScroll = 0
    startBodyDamageUpdates(self, self.doctor, self.patient)
    if FAM_ClientCommands and FAM_ClientCommands.requestPatientSnapshot then
        FAM_ClientCommands.requestPatientSnapshot(self.doctor, self.patient)
    end
end

function FAM_TriagePanel:openBodyPartContextMenu(bodyPart, x, y)
    if not bodyPart or not FAMHealthPanelContext or not FAMHealthPanelContext.add then return end
    local context = nil
    if ISContextMenu and ISContextMenu.get then
        local playerNum = self.doctor and self.doctor.getPlayerNum and self.doctor:getPlayerNum() or 0
        context = ISContextMenu.get(playerNum, self:getAbsoluteX() + x, self:getAbsoluteY() + y)
    end
    FAMHealthPanelContext.add(self, bodyPart, x, y, context)
end

function FAM_TriagePanel:setPandemicControlsVisible(visible)
    if self.pandemicQuarantine then self.pandemicQuarantine:setVisible(visible) end
    if self.pandemicTreat then self.pandemicTreat:setVisible(visible) end
end

function FAM_TriagePanel:syncPandemicButtons()
    if not self.patient then return end
    local infected = FAM.isPandemicInfected(self.patient)
    local quarantined = FAM.getPandemicQuarantineHours(self.patient) > 0
    if self.pandemicQuarantine then
        self.pandemicQuarantine:setTitle(quarantined and getText("IGUI_FAM_Release") or getText("IGUI_FAM_Quarantine"))
        self.pandemicQuarantine:setEnable(infected or quarantined)
    end
    if self.pandemicTreat then
        self.pandemicTreat:setEnable(infected and (FAM.getDoctorLevel(self.doctor) >= 4 or FAM.hasAdvancedClinicalAccess(self.doctor)))
    end
end

function FAM_TriagePanel:onPandemicQuarantine()
    if not self.patient then return end
    local enabled = FAM.getPandemicQuarantineHours(self.patient) <= 0
    if FAM_ClientCommands.setPandemicQuarantine(self.doctor, self.patient, enabled) then
        FAM_ClientCommands.requestPandemicStatus(self.doctor)
        FAM_ClientCommands.requestProviderStats(self.doctor)
    end
end

function FAM_TriagePanel:onPandemicTreat()
    if not self.patient then return end
    if FAM_ClientCommands.treatPandemicCase(self.doctor, self.patient) then
        FAM_ClientCommands.requestPandemicStatus(self.doctor)
        FAM_ClientCommands.requestProviderStats(self.doctor)
    end
end

function FAM_TriagePanel:onTreatmentButton(button)
    local action = self.treatmentActions and self.treatmentActions[button.internal] or nil
    if FAM_TreatmentPlanner.perform(action) then
        self:appendAutoTreatmentNote(action)
        self:onRefresh()
    end
end

function FAM_TriagePanel:setNoteControlsVisible(visible)
    if self.notesEntry then self.notesEntry:setVisible(visible) end
    if self.notesSave then self.notesSave:setVisible(visible) end
    if self.notesRevert then self.notesRevert:setVisible(visible) end
    if self.autoNotesBox then self.autoNotesBox:setVisible(visible) end
    if self.notesRecords then self.notesRecords:setVisible(visible and FAM.hasPatientRecordAccess(self.doctor)) end
end

function FAM_TriagePanel:getNoteText()
    if not self.notesEntry then return "" end
    if self.notesEntry.getInternalText then
        return self.notesEntry:getInternalText() or ""
    end
    if self.notesEntry.getText then
        return self.notesEntry:getText() or ""
    end
    return ""
end

function FAM_TriagePanel:isNoteDirty()
    return FAM.sanitizePatientNote(self:getNoteText()) ~= (self.notesSavedText or "")
end

local function setTickBoxEnabled(tickBox, enabled)
    if not tickBox then return end
    tickBox.enable = enabled == true
    if tickBox.disableOption and tickBox.optionsIndex and tickBox.optionsIndex[1] then
        if not tickBox.disabledOptions then tickBox.disabledOptions = {} end
        tickBox:disableOption(tickBox.optionsIndex[1], not enabled)
    end
end

function FAM_TriagePanel:syncNoteButtons()
    local dirty = self:isNoteDirty()
    if self.notesSave then self.notesSave:setEnable(dirty) end
    if self.notesRevert then self.notesRevert:setEnable(dirty) end
    setTickBoxEnabled(self.autoNotesBox, self.patient ~= nil)
    if self.notesRecords then self.notesRecords:setEnable(self.patient ~= nil and FAM.hasPatientRecordAccess(self.doctor)) end
end

function FAM_TriagePanel:onNoteTextChanged()
    self:syncNoteButtons()
end

function FAM_TriagePanel:onAutoNotesChanged()
    local enabled = false
    if self.autoNotesBox then
        if self.autoNotesBox.isSelected then
            enabled = self.autoNotesBox:isSelected(1) == true
        elseif self.autoNotesBox.selected then
            enabled = self.autoNotesBox.selected[1] == true
        end
    end
    self.autoNotesEnabled = enabled
    FAM_TriagePanel.autoNotesEnabled = enabled
end

function FAM_TriagePanel:appendAutoTreatmentNote(action)
    if not self.autoNotesEnabled or not self.notesEntry or not action or not action.patient then return end
    if self.patient ~= action.patient then return end

    local patientName = "?"
    if action.patient.getDisplayName then
        patientName = action.patient:getDisplayName() or patientName
    end
    local treatmentLabel = displayText(action.label, action.id or "?")
    treatmentLabel = string.gsub(tostring(treatmentLabel or "?"), "%s+", " ")
    local partName = tostring(action.bodyPartName or "?")
    local providerName = FAM.getClinicianName(action.doctor or self.doctor)
    local line = formatText("IGUI_FAM_AutoNoteLine", FAM.getNoteTimestamp(), patientName, treatmentLabel, partName, providerName)
    local current = FAM.sanitizePatientNote(self:getNoteText())
    local nextText = line
    if FAM.trimNote(current) ~= "" then
        nextText = current .. "\n" .. line
    end
    self.notesEntry:setText(FAM.sanitizePatientNote(nextText))
    self:syncNoteButtons()
end

function FAM_TriagePanel:syncNoteFromPatient(force)
    if not self.notesEntry or not self.patient then return end
    local note = FAM.getPatientNote(self.patient)
    local patientChanged = self.notesPatient ~= self.patient
    if patientChanged then
        self.notesPatient = self.patient
        self.notesSavedText = note
        self.notesEntry:setText(note)
        FAM_ClientCommands.requestPatientNote(self.doctor, self.patient)
    elseif force or note ~= (self.notesSavedText or "") then
        local entryFocused = self.notesEntry.isFocused and self.notesEntry:isFocused()
        if not self:isNoteDirty() or not entryFocused then
            self.notesSavedText = note
            self.notesEntry:setText(note)
        end
    end
    self.notesUpdatedBy, self.notesUpdatedAt = FAM.getPatientNoteMeta(self.patient)
    self:syncNoteButtons()
end

function FAM_TriagePanel:saveNoteIfDirty()
    if not self.patient or not self.notesEntry or not self:isNoteDirty() then return false end
    local note = FAM.sanitizePatientNote(self:getNoteText())
    if not FAM_ClientCommands.savePatientNote(self.doctor, self.patient, note) then
        return false
    end
    self.notesPatient = self.patient
    self.notesSavedText = note
    self.notesUpdatedBy, self.notesUpdatedAt = FAM.getPatientNoteMeta(self.patient)
    self:syncNoteButtons()
    if FAM_PatientRecordsPanel and FAM_PatientRecordsPanel.instance and FAM_PatientRecordsPanel.instance.patient == self.patient then
        FAM_ClientCommands.requestPatientRecords(self.doctor, self.patient)
        FAM_PatientRecordsPanel.instance:onRecordsUpdated()
    end
    return true
end

function FAM_TriagePanel:onSaveNote()
    self:saveNoteIfDirty()
end

function FAM_TriagePanel:onRevertNote()
    if not self.patient or not self.notesEntry then return end
    local note = FAM.getPatientNote(self.patient)
    self.notesSavedText = note
    self.notesEntry:setText(note)
    self.notesUpdatedBy, self.notesUpdatedAt = FAM.getPatientNoteMeta(self.patient)
    self:syncNoteButtons()
end

function FAM_TriagePanel:onPatientRecords()
    if not self.patient or not self.doctor then return end
    FAM_PatientRecordsPanel.open(self.doctor, self.patient)
end

function FAM_TriagePanel:syncTreatmentButtons(actions, x, y)
    local signature = tostring(self.doctor) .. ":" .. tostring(self.patient) .. ":" .. tostring(self.selectedBodyPartIndex) .. ":" .. tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(TREATMENT_BUTTON_WIDTH) .. ":" .. tostring(TREATMENT_BUTTONS_PER_ROW)
    for i = 1, #actions do
        local action = actions[i]
        signature = signature .. "|" .. action.id .. ":" .. tostring(action.enabled) .. ":" .. tostring(action.item) .. ":" .. displayText(action.label, action.id)
    end
    if self.treatmentButtonSignature == signature then
        self.treatmentActions = actions
        return
    end

    self:clearTreatmentButtons()
    self.treatmentButtonSignature = signature
    self.treatmentActions = actions

    for i = 1, #actions do
        local col = (i - 1) % TREATMENT_BUTTONS_PER_ROW
        local row = math.floor((i - 1) / TREATMENT_BUTTONS_PER_ROW)
        local buttonLabel = displayText(actions[i].label, actions[i].id)
        local button = ISButton:new(x + (col * (TREATMENT_BUTTON_WIDTH + TREATMENT_BUTTON_GAP)), y + (row * (TREATMENT_BUTTON_HEIGHT + px(6))), TREATMENT_BUTTON_WIDTH, TREATMENT_BUTTON_HEIGHT, buttonLabel, self, FAM_TriagePanel.onTreatmentButton)
        button.internal = i
        button:initialise()
        button:instantiate()
        button:setEnable(actions[i].enabled)
        button.tooltip = actions[i].enabled and nil or displayText(actions[i].reason, "")
        if actions[i].enabled then
            if actions[i].item then
                button.backgroundColor = { r = 0.018, g = 0.105, b = 0.055, a = 0.98 }
                button.backgroundColorMouseOver = { r = 0.03, g = 0.18, b = 0.085, a = 1 }
                button.borderColor = { r = COLORS.line.r, g = COLORS.line.g, b = COLORS.line.b, a = 1 }
                button.textColor = { r = 0.92, g = 1.00, b = 0.92, a = 1 }
            else
                button.backgroundColor = { r = 0.012, g = 0.082, b = 0.044, a = 0.94 }
                button.backgroundColorMouseOver = { r = 0.025, g = 0.145, b = 0.072, a = 1 }
                button.borderColor = { r = COLORS.line.r, g = COLORS.line.g, b = COLORS.line.b, a = 0.86 }
                button.textColor = { r = COLORS.text.r, g = COLORS.text.g, b = COLORS.text.b, a = 1 }
            end
        else
            button.backgroundColor = { r = 0.018, g = 0.026, b = 0.021, a = 0.64 }
            button.backgroundColorMouseOver = { r = 0.026, g = 0.046, b = 0.033, a = 0.76 }
            button.borderColor = { r = COLORS.lineDim.r, g = COLORS.lineDim.g, b = COLORS.lineDim.b, a = 0.64 }
            button.textColor = { r = COLORS.dim.r, g = COLORS.dim.g, b = COLORS.dim.b, a = 0.86 }
        end
        if actions[i].item then
            button.itemForTexture = actions[i].item
        end
        self:addChild(button)
        table.insert(self.treatmentButtons, button)
    end
end

function FAM_TriagePanel:prerender()
    self:refreshLayout()
    ISCollapsableWindow.prerender(self)
    self:drawRect(0, 16, self.width, self.height - 16, COLORS.bg.a, COLORS.bg.r, COLORS.bg.g, COLORS.bg.b)
    drawGlowBorder(self, 8, 22, self.width - 16, self.height - 30)
    self:drawRect(MODEL_X - 8, MODEL_Y - 8, MODEL_W + 16, MODEL_H + 112, 0.58, COLORS.panel.r, COLORS.panel.g, COLORS.panel.b)
    self:drawRectBorder(MODEL_X - 8, MODEL_Y - 8, MODEL_W + 16, MODEL_H + 112, 0.42, COLORS.line.r, COLORS.line.g, COLORS.line.b)
    self:drawText(getText("IGUI_FAM_PatientVisual"), MODEL_X - 4, MODEL_Y - 28, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    self:drawRect(18, 28, 44, 44, 0.26, 0.02, 0.09, 0.04)
    self:drawRectBorder(18, 28, 44, 44, 0.65, COLORS.line.r, COLORS.line.g, COLORS.line.b)
    self:drawRectBorder(20, 30, 40, 40, 0.18, COLORS.line.r, COLORS.line.g, COLORS.line.b)
    if TRIAGE_ICON then
        self:drawTextureScaled(TRIAGE_ICON, 22, 32, 36, 36, 1, 1, 1, 1)
    end
    self:drawText(getText("IGUI_FAM_TriageTitle"), 70, 32, COLORS.text.r, COLORS.text.g, COLORS.text.b, COLORS.text.a, UIFont.Medium)
end

function FAM_TriagePanel:renderVitals(y)
    local snapshot = getPatientSnapshot(self.patient)
    local bodyDamage = FAM.getBodyDamage(self.patient)
    if not bodyDamage and not snapshot then return y end
    local health = snapshotMetric(snapshot, "health", bodyDamage and bodyDamage:getHealth() or 100)
    local traumaLoad = snapshotMetric(snapshot, "traumaLoad", FAM.clamp(100 - health, 0, 100))
    local poison = snapshotMetric(snapshot, "poison", FAM.getPoisonLevel(self.patient))
    local cold = snapshotMetric(snapshot, "cold", FAM.getColdStressPercent(self.patient))
    local sepsis = snapshotMetric(snapshot, "sepsis", tonumber(self.patient:getModData().FAM_SepsisLoad) or 0)
    local shock = snapshotMetric(snapshot, "shock", tonumber(self.patient:getModData().FAM_ShockLoad) or 0)
    local conditionLoad = snapshotMetric(snapshot, "conditionLoad", FAM.getConditionLoad(self.patient))
    local pathogen = snapshotMetric(snapshot, "pathogen", FAM.getPathogenLoad(self.patient))
    local corpseExposure = snapshotMetric(snapshot, "corpseExposure", FAM.getCorpseExposureLoad(self.patient))
    local corpseCount = snapshotMetric(snapshot, "corpseCount", FAM.getNearbyCorpseCount(self.patient))
    local sickness = snapshotMetric(snapshot, "sickness", FAM.getSicknessLevel(self.patient))
    local coreTemperature = snapshotMetric(snapshot, "coreTemperature", FAM.getCoreTemperature(self.patient))
    local temperatureRisk = snapshotMetric(snapshot, "temperatureRisk", FAM.getTemperatureDeviationPercent(self.patient))
    local sanitationHours = snapshotMetric(snapshot, "sanitationHours", tonumber(self.patient:getModData().FAM_SanitationHours) or 0)
    local fatigue = snapshotMetric(snapshot, "fatigue", FAM.getStat(self.patient, "FATIGUE", 0) * 100)
    local panic = snapshotMetric(snapshot, "panic", FAM.getStat(self.patient, "PANIC", 0))
    local csrStatus = snapshot and snapshot.csr or FAM.getCSRStatus(self.patient)
    local bloodPercent = snapshotMetric(snapshot, "bloodPercent", FAM.getBloodDisplayPercent(self.patient))
    local fluidSupport = snapshotMetric(snapshot, "fluidSupport", FAM.getFluidSupportHours(self.patient))
    local advanced = FAM.hasAdvancedClinicalAccess(self.doctor)

    self:drawText(getText("IGUI_FAM_Patient", snapshot and snapshot.displayName or self.patient:getDisplayName()), 18, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    self:drawText(getText("IGUI_FAM_DoctorLevel", asTextInt(FAM.getDoctorLevel(self.doctor))), 220, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    if csrStatus.available then
        local label = getText(csrStatus.statusKey)
        if csrStatus.hours > 0 then
            label = label .. " " .. asTextInt(csrStatus.hours) .. "h"
        end
        local color = csrStatus.crisis and COLORS.danger or COLORS.line
        self:drawText(label, 392, y, color.r, color.g, color.b, 1, UIFont.Small)
    end
    y = y + FONT_HGT_SMALL + 8
    self:drawText(advanced and getText("IGUI_FAM_ClinicalAccessAdvanced") or getText("IGUI_FAM_ClinicalAccessBasic"), 18, y, COLORS.line.r, COLORS.line.g, COLORS.line.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 8

    self:drawText(getText("IGUI_FAM_Overall"), VITAL_LEFT_LABEL_X, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    drawBar(self, VITAL_LEFT_BAR_X, y + 2, 118, 12, traumaLoad)
    self:drawText(tostring(math.floor(traumaLoad)) .. "%", VITAL_LEFT_VALUE_X, y - 1, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)

    self:drawText(getText("IGUI_FAM_ConditionLoad"), VITAL_RIGHT_LABEL_X, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    drawBar(self, VITAL_RIGHT_BAR_X, y + 2, 118, 12, conditionLoad)
    self:drawText(tostring(math.floor(conditionLoad)) .. "%", VITAL_RIGHT_VALUE_X, y - 1, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 8

    self:drawText(getText("IGUI_FAM_Toxicity"), VITAL_LEFT_LABEL_X, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    drawBar(self, VITAL_LEFT_BAR_X, y + 2, 118, 12, poison)
    self:drawText(tostring(math.floor(poison)) .. "%", VITAL_LEFT_VALUE_X, y - 1, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)

    self:drawText(getText("IGUI_FAM_SepsisLoad"), VITAL_RIGHT_LABEL_X, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    drawBar(self, VITAL_RIGHT_BAR_X, y + 2, 118, 12, sepsis)
    self:drawText(tostring(math.floor(sepsis)) .. "%", VITAL_RIGHT_VALUE_X, y - 1, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 8

    self:drawText(getText("IGUI_FAM_Cold"), VITAL_LEFT_LABEL_X, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    drawBar(self, VITAL_LEFT_BAR_X, y + 2, 118, 12, cold)
    self:drawText(tostring(math.floor(cold)) .. "%", VITAL_LEFT_VALUE_X, y - 1, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)

    self:drawText(getText("IGUI_FAM_ShockLoad"), VITAL_RIGHT_LABEL_X, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    drawBar(self, VITAL_RIGHT_BAR_X, y + 2, 118, 12, shock)
    self:drawText(tostring(math.floor(shock)) .. "%", VITAL_RIGHT_VALUE_X, y - 1, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 8

    self:drawText(getText("IGUI_FAM_Fatigue"), VITAL_LEFT_LABEL_X, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    drawBar(self, VITAL_LEFT_BAR_X, y + 2, 118, 12, fatigue)
    self:drawText(tostring(math.floor(fatigue)) .. "%", VITAL_LEFT_VALUE_X, y - 1, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)

    self:drawText(getText("IGUI_FAM_Panic"), VITAL_RIGHT_LABEL_X, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    drawBar(self, VITAL_RIGHT_BAR_X, y + 2, 118, 12, panic)
    self:drawText(tostring(math.floor(panic)) .. "%", VITAL_RIGHT_VALUE_X, y - 1, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 8

    self:drawText(getText("IGUI_FAM_Temperature"), VITAL_LEFT_LABEL_X, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    drawBar(self, VITAL_LEFT_BAR_X, y + 2, 118, 12, temperatureRisk)
    self:drawText(FAM.formatTemperature(coreTemperature), VITAL_LEFT_VALUE_X, y - 1, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)

    self:drawText(getText("IGUI_FAM_PathogenLoad"), VITAL_RIGHT_LABEL_X, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    drawBar(self, VITAL_RIGHT_BAR_X, y + 2, 118, 12, pathogen)
    self:drawText(tostring(math.floor(pathogen)) .. "%", VITAL_RIGHT_VALUE_X, y - 1, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 8

    self:drawText(getText("IGUI_FAM_CorpseExposure"), VITAL_LEFT_LABEL_X, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    drawBar(self, VITAL_LEFT_BAR_X, y + 2, 118, 12, corpseExposure)
    local exposureText = getText("IGUI_FAM_CorpseCount", asTextInt(corpseCount), asTextInt(sickness))
    if sanitationHours > 0 then
        exposureText = exposureText .. " " .. getText("IGUI_FAM_SanitationActive", asTextInt(sanitationHours))
    end
    self:drawText(exposureText, VITAL_LEFT_VALUE_X, y - 1, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)

    self:drawText(getText("IGUI_FAM_BloodReserve"), VITAL_RIGHT_LABEL_X, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    drawBar(self, VITAL_RIGHT_BAR_X, y + 2, 118, 12, 100 - bloodPercent)
    local bloodText = fluidSupport > 0 and getText("IGUI_FAM_BloodReserveSupport", asTextInt(bloodPercent), asTextInt(fluidSupport)) or getText("IGUI_FAM_BloodReserveValue", asTextInt(bloodPercent))
    self:drawText(bloodText, VITAL_RIGHT_VALUE_X, y - 1, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    return y + FONT_HGT_SMALL + 14
end

function FAM_TriagePanel:renderClinicalSummary(y)
    local snapshot = getPatientSnapshot(self.patient)
    local rows = snapshot and snapshot.clinicalSummaryRows or FAM.getClinicalSummaryRows(self.patient, self.doctor)
    local maxRows = math.min(#rows, 4)
    local panelH = FONT_HGT_SMALL + 24 + ((FONT_HGT_SMALL + 6) * math.max(1, maxRows))
    self:drawRect(14, y - 4, CONTENT_WIDTH - 28, panelH, COLORS.panel.a, COLORS.panel.r, COLORS.panel.g, COLORS.panel.b)
    self:drawRectBorder(14, y - 4, CONTENT_WIDTH - 28, panelH, 0.28, COLORS.line.r, COLORS.line.g, COLORS.line.b)
    self:drawText(getText("IGUI_FAM_ClinicalSummary"), 20, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 8

    if maxRows == 0 then
        self:drawText(getText("IGUI_FAM_NoFamConditions"), 24, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        return y + FONT_HGT_SMALL + 12
    end

    for i = 1, maxRows do
        local row = rows[i]
        local severity = tonumber(row.severity) or 0
        local color = severity >= 70 and COLORS.danger or (severity >= 35 and COLORS.caution or COLORS.dim)
        self:drawText(trimText(getText(row.labelKey), 168, UIFont.Small), 24, y, color.r, color.g, color.b, 1, UIFont.Small)
        drawBar(self, 196, y + 2, 92, 12, severity)
        self:drawText(trimText(tostring(row.valueText or ""), CONTENT_WIDTH - 326, UIFont.Small), 306, y - 1, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
        y = y + FONT_HGT_SMALL + 6
    end

    return y + 8
end

function FAM_TriagePanel:renderProtocols(y)
    self:drawRect(14, y - 4, CONTENT_WIDTH - 28, (FONT_HGT_SMALL * 3) + 30, COLORS.panel.a, COLORS.panel.r, COLORS.panel.g, COLORS.panel.b)
    self:drawText(getText("IGUI_FAM_Protocols"), 20, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    local rows = {
        {
            { treatment = "burn", x = 112 },
            { treatment = "hemostatic", x = 236 },
            { treatment = "tourniquet", x = 374 },
            { treatment = "sanitation", x = 512 },
        },
        {
            { treatment = "stumpcare", x = 112 },
            { treatment = "amputation", x = 236 },
            { treatment = "prosthetic", x = 374 },
        },
        {
            { treatment = "ivfluids", x = 112 },
            { treatment = "bloodpack", x = 236 },
            { treatment = "epinephrine", x = 374 },
        },
    }
    for rowIndex = 1, #rows do
        local rowY = y + ((rowIndex - 1) * (FONT_HGT_SMALL + 8))
        for i = 1, #rows[rowIndex] do
            local protocol = rows[rowIndex][i]
            local known = FAM.knowsProtocol(self.doctor, protocol.treatment)
            local r = known and COLORS.line.r or COLORS.dim.r
            local g = known and COLORS.line.g or COLORS.dim.g
            local b = known and COLORS.line.b or COLORS.dim.b
            local status = known and getText("IGUI_FAM_ProtocolTrained") or getText("IGUI_FAM_ProtocolLocked")
            self:drawText(trimText(FAM.protocolLabel(protocol.treatment) .. ": " .. status, px(116), UIFont.Small), protocol.x, rowY, r, g, b, 1, UIFont.Small)
        end
    end
    return y + (FONT_HGT_SMALL * 3) + 36
end

function FAM_TriagePanel:renderConditionReaders(y)
    self.conditionReaderHitRows = {}
    self.conditionReaderScrollArea = nil
    self:drawText(getText("IGUI_FAM_ConditionReaders"), 18, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 6

    local snapshot = getPatientSnapshot(self.patient)
    local rows = snapshot and snapshot.clinicalRows or FAM.getClinicalRows(self.patient, FAM.hasAdvancedClinicalAccess(self.doctor))
    if #rows == 0 then
        self:drawText(getText("IGUI_FAM_NoFamConditions"), 22, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        return y + FONT_HGT_SMALL + 8
    end

    if self.selectedBodyPartIndex then
        for i = 1, #rows do
            local bodyPart = FAM.getBodyPartByName(self.patient, rows[i].part)
            bodyPart = getBodyPartForPrimaryAmputation(self.patient, bodyPart)
            if bodyPart and bodyPart:getIndex() == self.selectedBodyPartIndex then
                if i > 1 then
                    local row = table.remove(rows, i)
                    table.insert(rows, 1, row)
                end
                break
            end
        end
    end

    local visibleRows = math.min(#rows, FAM.hasAdvancedClinicalAccess(self.doctor) and 4 or 3)
    self.conditionReaderScroll = clampRowScroll(self.conditionReaderScroll, #rows, visibleRows)
    local startIndex = (self.conditionReaderScroll or 0) + 1
    local endIndex = math.min(#rows, startIndex + visibleRows - 1)
    local listTop = y - 3
    local listHeight = visibleRows * 25
    self.conditionReaderScrollArea = { x = 14, y = listTop, w = CONTENT_WIDTH - 28, h = listHeight, total = #rows, visible = visibleRows }

    for i = startIndex, endIndex do
        local row = rows[i]
        local bodyPart = FAM.getBodyPartByName(self.patient, row.part)
        bodyPart = getBodyPartForPrimaryAmputation(self.patient, bodyPart)
        local rowIndex = bodyPart and bodyPart:getIndex() or row.index
        local selected = rowIndex and self.selectedBodyPartIndex == rowIndex
        self:drawRect(14, y - 3, CONTENT_WIDTH - 28, 22, selected and 0.9 or COLORS.panel.a, selected and 0.035 or COLORS.panel.r, selected and 0.1 or COLORS.panel.g, selected and 0.05 or COLORS.panel.b)
        if selected then
            self:drawRectBorder(14, y - 3, CONTENT_WIDTH - 28, 22, 0.78, COLORS.line.r, COLORS.line.g, COLORS.line.b)
        end
        self:drawText(row.part, 22, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
        drawBar(self, 142, y + 2, 112, 12, row.severity)
        local recommendation = displayText(row.recommendation, fallbackText("IGUI_FAM_ProcedureMonitor", "Procedure: monitor"))
        self:drawText(recommendation, 268, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        if rowIndex then
            table.insert(self.conditionReaderHitRows, { x = 14, y = y - 3, w = CONTENT_WIDTH - 28, h = 22, index = rowIndex })
        end
        y = y + 25
    end

    drawRowScrollbar(self, CONTENT_WIDTH - 20, listTop, listHeight - 3, #rows, visibleRows, self.conditionReaderScroll)
    return y + 4
end

function FAM_TriagePanel:renderSubstanceScanner(y)
    local rows = FAM.scanSubstances(self.patient)
    if #rows == 0 then
        return y
    end

    self:drawText(getText("IGUI_FAM_SubstanceScanner"), 18, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 6

    local limit = math.min(#rows, 3)
    for i = 1, limit do
        local row = rows[i]
        local label = row.labelKey and getText(row.labelKey) or row.label
        local line = getText("IGUI_FAM_SubstanceRow", label, row.valueText)
        local color = row.category == "csr" and COLORS.line or COLORS.dim
        self:drawRect(14, y - 3, CONTENT_WIDTH - 28, 22, COLORS.panel.a, COLORS.panel.r, COLORS.panel.g, COLORS.panel.b)
        self:drawText(trimText(line, CONTENT_WIDTH - 44, UIFont.Small), 22, y, color.r, color.g, color.b, 1, UIFont.Small)
        y = y + 25
    end

    if #rows > limit then
        self:drawText(getText("IGUI_FAM_SubstanceMoreRows", asTextInt(#rows - limit)), 22, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        y = y + FONT_HGT_SMALL + 6
    end
    return y + 4
end

function FAM_TriagePanel:renderAdvancedMatrix(y)
    if not FAM.hasAdvancedClinicalAccess(self.doctor) then
        return y
    end
    self:drawText(getText("IGUI_FAM_AdvancedMatrix"), 18, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 6

    local snapshot = getPatientSnapshot(self.patient)
    local rows = snapshot and snapshot.clinicalRows or FAM.getClinicalRows(self.patient, true)
    if #rows == 0 then
        self:drawText(getText("IGUI_FAM_NoFamConditions"), 22, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        return y + FONT_HGT_SMALL + 8
    end

    local limit = math.min(#rows, 5)
    for i = 1, limit do
        local row = rows[i]
        self:drawRect(14, y - 3, CONTENT_WIDTH - 28, 22, COLORS.panel.a, COLORS.panel.r, COLORS.panel.g, COLORS.panel.b)
        local text = getText("IGUI_FAM_AdvancedRow", row.part, asTextInt(row.gangrene), asTextInt(row.bulletHours), displayText(row.summary, ""))
        self:drawText(text, 22, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        y = y + 25
    end
    return y + 4
end

function FAM_TriagePanel:getBodyPartByIndex(index)
    if not self.patient or not index then return nil end
    local bodyDamage = FAM.getBodyDamage(self.patient)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    if not bodyParts then return nil end
    for i = 1, bodyParts:size() do
        local bodyPart = bodyParts:get(i - 1)
        if bodyPart:getIndex() == index then
            return bodyPart
        end
    end
    return nil
end

function FAM_TriagePanel:getDefaultBodyPart()
    if not self.patient then return nil end
    local snapshot = getPatientSnapshot(self.patient)
    if snapshot and snapshot.bodyPartRows and #snapshot.bodyPartRows > 0 then
        for i = 1, #snapshot.bodyPartRows do
            local index = tonumber(snapshot.bodyPartRows[i].index)
            local bodyPart = index and self:getBodyPartByIndex(index) or nil
            if bodyPart and not FAM.isSuppressedAmputationPart(self.patient, bodyPart) then
                return bodyPart
            end
        end
    end

    local bodyDamage = FAM.getBodyDamage(self.patient)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    if not bodyParts then return nil end
    local selected = nil
    local selectedSeverity = -1
    for i = 1, bodyParts:size() do
        local bodyPart = bodyParts:get(i - 1)
        local severity = FAM.bodyPartClinicalSeverity(self.patient, bodyPart)
        local trackable = FAM.hasVanillaVisibleBodyPartIssue(bodyPart)
            or severity > 0
            or FAM.hasTourniquet(self.patient, bodyPart)
            or FAM.hasAmputation(self.patient, bodyPart)
            or FAM.hasProsthetic(self.patient, bodyPart)
        if FAM.isSuppressedAmputationPart(self.patient, bodyPart) then
            trackable = false
        end
        if trackable then
            if severity > selectedSeverity then
                selected = bodyPart
                selectedSeverity = severity
            elseif not selected then
                selected = bodyPart
            end
        end
    end
    return selected
end

function FAM_TriagePanel:getSelectedBodyPart()
    local bodyPart = self:getBodyPartByIndex(self.selectedBodyPartIndex)
    bodyPart = getBodyPartForPrimaryAmputation(self.patient, bodyPart)
    if bodyPart then
        self.selectedBodyPartIndex = bodyPart:getIndex()
        return bodyPart
    end
    bodyPart = self:getDefaultBodyPart()
    if bodyPart then
        self.selectedBodyPartIndex = bodyPart:getIndex()
    end
    return bodyPart
end

function FAM_TriagePanel:getBodyPartVisualValue(bodyPart)
    if not self.patient or not bodyPart then return 0 end

    if FAM.isSuppressedAmputationPart(self.patient, bodyPart) then
        return 0
    end
    if FAM.hasAmputation(self.patient, bodyPart) then
        return 0.90
    end
    if FAM.isAmputationIndicated(self.patient, bodyPart) then
        return 1.00
    end
    if FAM.hasTourniquet(self.patient, bodyPart) then
        return 0.80
    end

    local severity = FAM.bodyPartClinicalSeverity(self.patient, bodyPart)
    if severity > 0 then
        return FAM.clamp(severity / 100, 0.20, 1.00)
    end

    if FAM.hasProsthetic(self.patient, bodyPart)
        or bodyPart:bandaged()
        or bodyPart:stitched()
        or bodyPart:getSplintFactor() > 0 then
        return 0.20
    end

    return 0
end

function FAM_TriagePanel:updateBodyPartPanel()
    local panel = self:ensureBodyPartPanel()
    if not panel or not self.patient then return end
    syncBodyPartPanelPatient(panel, self.patient)

    local bodyDamage = FAM.getBodyDamage(self.patient)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    if not bodyParts then return end

    for i = 1, bodyParts:size() do
        local bodyPart = bodyParts:get(i - 1)
        if bodyPart and bodyPart.getType and panel.setValue then
            panel:setValue(bodyPart:getType(), self:getBodyPartVisualValue(bodyPart))
        end
    end
end

function FAM_TriagePanel:renderBodyParts(y, availableBottom)
    self:drawText(getText("IGUI_FAM_BodyMap"), 18, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    self:drawText(getText("IGUI_FAM_BodyMapHint"), 165, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 6

    local shown = 0
    local rowHeight = px(27)
    local maxRows = FAM.hasAdvancedClinicalAccess(self.doctor) and 7 or 6
    if availableBottom then
        local roomRows = math.floor((availableBottom - y - FONT_HGT_SMALL - px(8)) / rowHeight)
        maxRows = math.max(2, math.min(maxRows, roomRows))
    end
    self.bodyPartHitRows = {}
    self.bodyPartScrollArea = nil
    local snapshot = getPatientSnapshot(self.patient)
    if snapshot and snapshot.bodyPartRows then
        local tracked = snapshot.bodyPartRows
        local visibleRows = math.min(#tracked, maxRows)
        self.bodyPartScroll = clampRowScroll(self.bodyPartScroll, #tracked, visibleRows)
        local startIndex = (self.bodyPartScroll or 0) + 1
        local endIndex = math.min(#tracked, startIndex + visibleRows - 1)
        local listTop = y - 3
        local listHeight = visibleRows * rowHeight
        if visibleRows > 0 then
            self.bodyPartScrollArea = { x = 14, y = listTop, w = CONTENT_WIDTH - 28, h = listHeight, total = #tracked, visible = visibleRows }
        end

        for i = startIndex, endIndex do
            local entry = tracked[i]
            local index = tonumber(entry.index)
            local severity = tonumber(entry.severity) or 0
            local selected = index and self.selectedBodyPartIndex == index
            self:drawRect(14, y - 3, CONTENT_WIDTH - 28, px(24), selected and 0.9 or COLORS.panel.a, selected and 0.035 or COLORS.panel.r, selected and 0.1 or COLORS.panel.g, selected and 0.05 or COLORS.panel.b)
            if selected then
                self:drawRectBorder(14, y - 3, CONTENT_WIDTH - 28, px(24), 0.78, COLORS.line.r, COLORS.line.g, COLORS.line.b)
            end
            self:drawText(tostring(entry.name or "?"), 22, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
            drawBar(self, 165, y + 2, 145, 12, severity)
            self:drawText(trimText(tostring(entry.summary or ""), CONTENT_WIDTH - 334, UIFont.Small), 326, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
            if index then
                table.insert(self.bodyPartHitRows, { x = 14, y = y - 3, w = CONTENT_WIDTH - 28, h = px(24), index = index })
            end
            y = y + rowHeight
            shown = shown + 1
        end

        if shown == 0 then
            self:drawText(getText("IGUI_FAM_NoCriticalTrauma"), 22, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
            y = y + FONT_HGT_SMALL + 8
        end
        drawRowScrollbar(self, CONTENT_WIDTH - 20, listTop, listHeight - px(3), #tracked, visibleRows, self.bodyPartScroll)
        return y
    end
    local bodyDamage = FAM.getBodyDamage(self.patient)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    if not bodyParts then
        self:drawText(getText("IGUI_FAM_NoCriticalTrauma"), 22, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        return y + FONT_HGT_SMALL + 8
    end
    local tracked = {}
    for i = 1, bodyParts:size() do
        local bodyPart = bodyParts:get(i - 1)
        if not FAM.isSuppressedAmputationPart(self.patient, bodyPart) then
            local severity = FAM.bodyPartClinicalSeverity(self.patient, bodyPart)
            local hasCondition = severity > 0
                or FAM.hasVanillaVisibleBodyPartIssue(bodyPart)
                or FAM.hasTourniquet(self.patient, bodyPart)
                or FAM.hasAmputation(self.patient, bodyPart)
                or FAM.hasProsthetic(self.patient, bodyPart)
            if hasCondition then
                local priority = severity
                if bodyPart:HasInjury() then priority = priority + 15 end
                if bodyPart:bandaged() then priority = priority + 10 end
                if bodyPart:stitched() then priority = priority + 6 end
                if bodyPart:getSplintFactor() > 0 then priority = priority + 6 end
                if FAM.hasAmputation(self.patient, bodyPart) then priority = priority + 30 end
                if FAM.hasTourniquet(self.patient, bodyPart) then priority = priority + 20 end
                if FAM.hasProsthetic(self.patient, bodyPart) then priority = priority + 8 end
                tracked[#tracked + 1] = { bodyPart = bodyPart, severity = severity, priority = priority }
            end
        end
    end
    table.sort(tracked, function(a, b)
        local aSelected = self.selectedBodyPartIndex == a.bodyPart:getIndex()
        local bSelected = self.selectedBodyPartIndex == b.bodyPart:getIndex()
        if aSelected ~= bSelected then return aSelected end
        if a.priority ~= b.priority then return a.priority > b.priority end
        return bodyPartName(a.bodyPart) < bodyPartName(b.bodyPart)
    end)

    local visibleRows = math.min(#tracked, maxRows)
    self.bodyPartScroll = clampRowScroll(self.bodyPartScroll, #tracked, visibleRows)
    local startIndex = (self.bodyPartScroll or 0) + 1
    local endIndex = math.min(#tracked, startIndex + visibleRows - 1)
    local listTop = y - 3
    local listHeight = visibleRows * rowHeight
    if visibleRows > 0 then
        self.bodyPartScrollArea = { x = 14, y = listTop, w = CONTENT_WIDTH - 28, h = listHeight, total = #tracked, visible = visibleRows }
    end

    for i = startIndex, endIndex do
        local entry = tracked[i]
        local bodyPart = entry.bodyPart
        local severity = entry.severity
        local selected = self.selectedBodyPartIndex == bodyPart:getIndex()
        self:drawRect(14, y - 3, CONTENT_WIDTH - 28, px(24), selected and 0.9 or COLORS.panel.a, selected and 0.035 or COLORS.panel.r, selected and 0.1 or COLORS.panel.g, selected and 0.05 or COLORS.panel.b)
        if selected then
            self:drawRectBorder(14, y - 3, CONTENT_WIDTH - 28, px(24), 0.78, COLORS.line.r, COLORS.line.g, COLORS.line.b)
        end
        self:drawText(bodyPartName(bodyPart), 22, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
        drawBar(self, 165, y + 2, 145, 12, severity)

        local tags = trimText(FAM.describeBodyPart(self.patient, bodyPart), CONTENT_WIDTH - 334, UIFont.Small)
        self:drawText(tags, 326, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        table.insert(self.bodyPartHitRows, { x = 14, y = y - 3, w = CONTENT_WIDTH - 28, h = px(24), index = bodyPart:getIndex() })

        y = y + rowHeight
        shown = shown + 1
    end

    if shown == 0 then
        self:drawText(getText("IGUI_FAM_NoCriticalTrauma"), 22, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        y = y + FONT_HGT_SMALL + 8
    end
    drawRowScrollbar(self, CONTENT_WIDTH - 20, listTop, listHeight - px(3), #tracked, visibleRows, self.bodyPartScroll)
    return y
end

function FAM_TriagePanel:renderTreatmentPlanner(y)
    local bodyPart = self:getSelectedBodyPart()
    self:drawText(getText("IGUI_FAM_TreatmentPlanner"), 18, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 6

    if not bodyPart then
        self:clearTreatmentButtons()
        self:drawText(getText("IGUI_FAM_NoSelectedPart"), 22, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        return y + FONT_HGT_SMALL + 8
    end

    local actions = FAM_TreatmentPlanner.getActions(self.doctor, self.patient, bodyPart)
    local buttonRows = math.max(1, math.ceil(#actions / TREATMENT_BUTTONS_PER_ROW))
    local panelHeight = FONT_HGT_SMALL + px(20) + (buttonRows * (TREATMENT_BUTTON_HEIGHT + px(6))) + px(8)
    local label = getText("IGUI_FAM_SelectedPart", bodyPartName(bodyPart))
    local snapshotRow = snapshotBodyPartRow(getPatientSnapshot(self.patient), bodyPart:getIndex())
    local summary = FAM.describeBodyPart(self.patient, bodyPart)
    summary = displayText(summary, "")
    if (not summary or summary == "") and snapshotRow and snapshotRow.summary and snapshotRow.summary ~= "" then
        summary = displayText(snapshotRow.summary, "")
    end
    if (not summary or summary == "") and snapshotRow and tonumber(snapshotRow.severity or 0) > 0 then
        summary = displayText(snapshotRow.recommendation, fallbackText("IGUI_FAM_ProcedureMonitor", "Procedure: monitor"))
    end
    self:drawRect(14, y - 3, CONTENT_WIDTH - 28, panelHeight, COLORS.treatmentPanel.a, COLORS.treatmentPanel.r, COLORS.treatmentPanel.g, COLORS.treatmentPanel.b)
    self:drawRectBorder(14, y - 3, CONTENT_WIDTH - 28, panelHeight, 0.58, COLORS.line.r, COLORS.line.g, COLORS.line.b)
    self:drawRect(16, y + FONT_HGT_SMALL + 26, CONTENT_WIDTH - 32, math.max(0, panelHeight - FONT_HGT_SMALL - 34), 0.38, 0.004, 0.018, 0.01)
    self:drawText(label, 22, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    self:drawText(trimText(summary or "", CONTENT_WIDTH - 210, UIFont.Small), 190, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)

    if #actions == 0 then
        self:clearTreatmentButtons()
        self:drawText(getText("IGUI_FAM_NoTreatments"), 22, y + FONT_HGT_SMALL + 10, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        return y + panelHeight
    end

    self:drawText(getText("IGUI_FAM_CategoryBasic"), 22, y + FONT_HGT_SMALL + 8, COLORS.line.r, COLORS.line.g, COLORS.line.b, 1, UIFont.Small)
    self:syncTreatmentButtons(actions, 98, y + FONT_HGT_SMALL + 4)
    return y + panelHeight
end

function FAM_TriagePanel:layoutNotesEditor(x, y, w)
    if not self.notesEntry then return end
    local entryW = w - (NOTE_BUTTON_WIDTH * 2) - px(20)
    local sideX = x + entryW + px(8)
    local sideW = (NOTE_BUTTON_WIDTH * 2) + px(6)
    self.notesEntry:setX(x)
    self.notesEntry:setY(y)
    self.notesEntry:setWidth(entryW)
    self.notesEntry:setHeight(NOTE_ENTRY_HEIGHT)
    self.notesSave:setX(sideX)
    self.notesSave:setY(y)
    self.notesSave:setWidth(NOTE_BUTTON_WIDTH)
    self.notesSave:setHeight(px(24))
    self.notesRevert:setX(x + entryW + NOTE_BUTTON_WIDTH + px(14))
    self.notesRevert:setY(y)
    self.notesRevert:setWidth(NOTE_BUTTON_WIDTH)
    self.notesRevert:setHeight(px(24))
    if self.autoNotesBox then
        self.autoNotesBox:setX(sideX)
        self.autoNotesBox:setY(y + px(30))
        self.autoNotesBox:setWidth(sideW)
        self.autoNotesBox:setHeight(px(22))
    end
    if self.notesRecords then
        self.notesRecords:setX(sideX)
        self.notesRecords:setY(y + px(56))
        self.notesRecords:setWidth(sideW)
        self.notesRecords:setHeight(px(24))
    end
end

function FAM_TriagePanel:renderPatientNotes(y)
    self:drawText(getText("IGUI_FAM_PatientNotes"), 18, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    local updatedBy = self.notesUpdatedBy
    local updatedAt = self.notesUpdatedAt
    if updatedBy or updatedAt then
        self:drawText(getText("IGUI_FAM_NotesUpdated", updatedBy or "?", updatedAt or "?"), 146, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    else
        self:drawText(getText("IGUI_FAM_NoNotesYet"), 146, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    end
    y = y + FONT_HGT_SMALL + 6

    self:drawRect(14, y - 3, CONTENT_WIDTH - 28, NOTE_PANEL_HEIGHT, COLORS.panel.a, COLORS.panel.r, COLORS.panel.g, COLORS.panel.b)
    self:drawRectBorder(14, y - 3, CONTENT_WIDTH - 28, NOTE_PANEL_HEIGHT, 0.32, COLORS.line.r, COLORS.line.g, COLORS.line.b)
    self:layoutNotesEditor(22, y + 6, CONTENT_WIDTH - 44)
    self:syncNoteFromPatient(false)
    self:setNoteControlsVisible(true)

    local remaining = FAM.PATIENT_NOTE_MAX_LENGTH - string.len(FAM.sanitizePatientNote(self:getNoteText()))
    self:drawText(getText("IGUI_FAM_NotesLimit", asTextInt(math.max(0, remaining))), 26, y + NOTE_ENTRY_HEIGHT + 10, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    return y + NOTE_PANEL_HEIGHT + 8
end

function FAM_TriagePanel:renderPatientPulse(y)
    local snapshot = getPatientSnapshot(self.patient)
    local state = snapshot and snapshot.pulseState or getPulseState(self.patient)
    local x = MODEL_X
    local w = MODEL_W
    local h = PULSE_H
    local frames = getPulseFrames(self, state)

    drawPulseShell(self, x, y, w, h, state, true)
    if frames and #frames > 0 then
        local frameIndex = advancePulseFrame(self, state, #frames)
        local frame = frames[frameIndex] or frames[1]
        if frame then
            self:drawTextureScaled(frame, x + 3, y + 3, w - 6, h - 6, 0.94, 1, 1, 1)
        end
    else
        drawPulseFallback(self, x, y, w, h, state)
    end
    drawPulseShell(self, x, y, w, h, state, false)

    return y + h + 12
end

function FAM_TriagePanel:renderPatientBodyMap(y)
    if BODY_STATUS_ICON then
        self:drawTextureScaled(BODY_STATUS_ICON, MODEL_X, y - 2, 18, 18, 1, 1, 1, 1)
    end
    self:drawText(getText("IGUI_FAM_BodyMap"), MODEL_X + 24, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 6

    local panel = self:ensureBodyPartPanel()
    local mapH = BODY_MAP_H
    if panel and panel.height then
        mapH = FAM.clamp((tonumber(panel.height) or BODY_MAP_H) + 12, 240, 330)
    end
    self:drawRect(MODEL_X, y, MODEL_W, mapH, 0.42, 0.008, 0.018, 0.012)
    self:drawRectBorder(MODEL_X, y, MODEL_W, mapH, 0.54, COLORS.line.r, COLORS.line.g, COLORS.line.b)
    self:drawRectBorder(MODEL_X + 2, y + 2, MODEL_W - 4, mapH - 4, 0.14, COLORS.line.r, COLORS.line.g, COLORS.line.b)

    if panel then
        self:updateBodyPartPanel()
        local panelW = tonumber(panel.width) or MODEL_W
        local panelH = tonumber(panel.height) or mapH
        local bodyX = MODEL_X + math.floor((MODEL_W - panelW) / 2)
        local bodyY = y + math.max(4, math.floor((mapH - panelH) / 2))
        panel:setX(bodyX)
        panel:setY(bodyY)
        panel:setVisible(true)
    else
        self:drawText(trimText(getText("IGUI_FAM_NoCriticalTrauma"), MODEL_W - 14, UIFont.Small), MODEL_X + 8, y + 10, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    end

    return y + mapH + 8
end

function FAM_TriagePanel:renderSelectedBodyPartSummary(y)
    local bodyPart = self:getSelectedBodyPart()
    local snapshotRow = snapshotBodyPartRow(getPatientSnapshot(self.patient), self.selectedBodyPartIndex)
    self:drawRect(MODEL_X, y, MODEL_W, SELECTED_PART_H, 0.48, COLORS.panel.r, COLORS.panel.g, COLORS.panel.b)
    self:drawRectBorder(MODEL_X, y, MODEL_W, SELECTED_PART_H, 0.40, COLORS.line.r, COLORS.line.g, COLORS.line.b)

    if not bodyPart and not snapshotRow then
        self:drawText(trimText(getText("IGUI_FAM_NoSelectedPart"), MODEL_W - 12, UIFont.Small), MODEL_X + 6, y + 8, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        return y + SELECTED_PART_H + 8
    end

    local severity = snapshotRow and tonumber(snapshotRow.severity) or FAM.bodyPartClinicalSeverity(self.patient, bodyPart)
    local name = snapshotRow and tostring(snapshotRow.name or "?") or bodyPartName(bodyPart)
    self:drawText(trimText(name, 88, UIFont.Small), MODEL_X + 6, y + 6, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    drawBar(self, MODEL_X + 96, y + 8, MODEL_W - 104, 10, severity)

    local summary = snapshotRow and tostring(snapshotRow.summary or "") or FAM.describeBodyPart(self.patient, bodyPart)
    summary = displayText(summary, "")
    if summary == "" and bodyPart then
        summary = displayText(FAM.getProcedureRecommendation(self.patient, bodyPart), fallbackText("IGUI_FAM_ProcedureMonitor", "Procedure: monitor"))
    end
    self:drawText(trimText(summary, MODEL_W - 12, UIFont.Small), MODEL_X + 6, y + 28, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)

    return y + SELECTED_PART_H + 8
end

function FAM_TriagePanel:renderPatientVisualInfo()
    if not self.patient then return end
    local y = MODEL_Y
    local snapshot = getPatientSnapshot(self.patient)
    local bodyDamage = FAM.getBodyDamage(self.patient)
    local health = snapshotMetric(snapshot, "health", bodyDamage and bodyDamage:getHealth() or 100)
    local traumaLoad = snapshotMetric(snapshot, "traumaLoad", FAM.clamp(100 - health, 0, 100))
    local conditionLoad = snapshotMetric(snapshot, "conditionLoad", FAM.getConditionLoad(self.patient))
    local pandemicLoad = snapshotMetric(snapshot, "pandemicLoad", FAM.getPandemicLoad(self.patient))
    local bloodDeficit = snapshotMetric(snapshot, "bloodDeficit", FAM.clamp(100 - FAM.getBloodDisplayPercent(self.patient), 0, 100))
    local visualBottom = MODEL_Y + MODEL_H + 96
    local quarantine = snapshotMetric(snapshot, "quarantine", FAM.getPandemicQuarantineHours(self.patient))
    local treated = snapshotMetric(snapshot, "treated", FAM.getPandemicTreatedHours(self.patient))
    local footerHeight = FONT_HGT_SMALL + 4 + (treated > 0 and (FONT_HGT_SMALL + 4) or 0)

    self:drawText(trimText(snapshot and snapshot.displayName or self.patient:getDisplayName(), MODEL_W, UIFont.Small), MODEL_X, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 10
    y = self:renderPatientBodyMap(y)
    y = self:renderSelectedBodyPartSummary(y)

    if y + PULSE_H + 12 <= visualBottom then
        y = self:renderPatientPulse(y)
    end

    local metrics = {
        { label = getText("IGUI_FAM_Overall"), value = traumaLoad },
        { label = getText("IGUI_FAM_ModelCondition"), value = conditionLoad },
        { label = getText("IGUI_FAM_BloodDeficit"), value = bloodDeficit },
        { label = getText("IGUI_FAM_SepsisLoad"), value = snapshotMetric(snapshot, "sepsis", tonumber(self.patient:getModData().FAM_SepsisLoad) or 0) },
        { label = getText("IGUI_FAM_Clinical_LocalInfection"), value = snapshotMetric(snapshot, "localInfection", FAM.getLocalInfectionLoad(self.patient)) },
        { label = getText("IGUI_FAM_ShockLoad"), value = snapshotMetric(snapshot, "shock", tonumber(self.patient:getModData().FAM_ShockLoad) or 0) },
        { label = getText("IGUI_FAM_ModelPandemic"), value = pandemicLoad },
    }

    for i = 1, #metrics do
        if y + FONT_HGT_SMALL + 20 + footerHeight > visualBottom then
            break
        end
        local metric = metrics[i]
        self:drawText(metric.label, MODEL_X, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        self:drawText(tostring(math.floor(metric.value)) .. "%", MODEL_X + MODEL_W - 34, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
        drawBar(self, MODEL_X, y + FONT_HGT_SMALL + 2, MODEL_W, 10, metric.value)
        y = y + FONT_HGT_SMALL + 20
    end

    if y + FONT_HGT_SMALL <= visualBottom then
        local pandemic = snapshot and snapshot.pandemic or nil
        if (pandemic and pandemic.infected) or FAM.isPandemicInfected(self.patient) then
            local diseaseLine = getText("IGUI_FAM_PandemicPositiveNamed", pandemic and pandemic.diseaseName or FAM.getPandemicDiseaseName(self.patient, self.doctor))
            if (pandemic and pandemic.superCarrier) or FAM.isPandemicSuperCarrier(self.patient) then
                diseaseLine = diseaseLine .. " " .. getText("IGUI_FAM_Disease_SuperCarrier")
            end
            self:drawText(trimText(diseaseLine, MODEL_W, UIFont.Small), MODEL_X, y, COLORS.danger.r, COLORS.danger.g, COLORS.danger.b, 1, UIFont.Small)
        elseif quarantine > 0 then
            self:drawText(getText("IGUI_FAM_PandemicQuarantined", asTextInt(quarantine)), MODEL_X, y, COLORS.caution.r, COLORS.caution.g, COLORS.caution.b, 1, UIFont.Small)
        else
            self:drawText(getText("IGUI_FAM_PandemicClear"), MODEL_X, y, COLORS.line.r, COLORS.line.g, COLORS.line.b, 1, UIFont.Small)
        end
        y = y + FONT_HGT_SMALL + 4
    end
    if treated > 0 and y + FONT_HGT_SMALL <= visualBottom then
        self:drawText(getText("IGUI_FAM_PandemicTreated", asTextInt(treated)), MODEL_X, y, COLORS.line.r, COLORS.line.g, COLORS.line.b, 1, UIFont.Small)
    end
end

local function makeVirologyAction(id, label, enabled, reason, item, perform)
    return {
        id = id,
        category = "virology",
        label = label,
        enabled = enabled == true,
        reason = reason,
        item = item,
        perform = perform,
    }
end

function FAM_TriagePanel:getVirologyActions()
    local actions = {}
    if not self.doctor or not self.patient or self.doctor ~= self.patient then
        return actions
    end

    local vaccine = findInventoryItem(self.doctor, function(item)
        return itemMatchesAny(item, ZVV_VACCINE_TYPES)
    end)
    local emptySyringe = findInventoryItem(self.doctor, function(item)
        return itemMatchesAny(item, ZVV_EMPTY_SYRINGE_TYPES)
    end)
    local bloodSample = findInventoryItem(self.doctor, function(item)
        return itemMatchesAny(item, ZVV_BLOOD_TYPES)
    end)
    local cotton = findInventoryItem(self.doctor, function(item)
        return item:getType() == "AlcoholedCottonBalls" or itemFullType(item) == "Base.AlcoholedCottonBalls"
    end)

    actions[#actions + 1] = makeVirologyAction(
        "zvv_inject",
        getText("IGUI_FAM_ZVV_ActionInject"),
        vaccine ~= nil and LabActionInjectVaccine ~= nil,
        vaccine and getText("IGUI_FAM_ZVV_ActionMissingRuntime") or getText("IGUI_FAM_ZVV_ActionMissingVaccine"),
        vaccine,
        function()
            if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.transferIfNeeded then
                ISInventoryPaneContextMenu.transferIfNeeded(self.doctor, vaccine)
            end
            ISTimedActionQueue.add(LabActionInjectVaccine:new(self.doctor, vaccine))
        end
    )
    actions[#actions + 1] = makeVirologyAction(
        "zvv_collect",
        getText("IGUI_FAM_ZVV_ActionCollect"),
        emptySyringe ~= nil and cotton ~= nil and LabActionCollectBlood ~= nil,
        emptySyringe and (cotton and getText("IGUI_FAM_ZVV_ActionMissingRuntime") or getText("IGUI_FAM_ZVV_ActionMissingCotton")) or getText("IGUI_FAM_ZVV_ActionMissingSyringe"),
        emptySyringe,
        function()
            if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.transferIfNeeded then
                ISInventoryPaneContextMenu.transferIfNeeded(self.doctor, emptySyringe)
            end
            ISTimedActionQueue.add(LabActionCollectBlood:new(self.doctor, emptySyringe))
        end
    )
    actions[#actions + 1] = makeVirologyAction(
        "zvv_test",
        getText("IGUI_FAM_ZVV_ActionTest"),
        bloodSample ~= nil and LabActionTestBlood ~= nil,
        bloodSample and getText("IGUI_FAM_ZVV_ActionMissingRuntime") or getText("IGUI_FAM_ZVV_ActionMissingBlood"),
        bloodSample,
        function()
            if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.transferIfNeeded then
                ISInventoryPaneContextMenu.transferIfNeeded(self.doctor, bloodSample)
            end
            ISTimedActionQueue.add(LabActionTestBlood:new(self.doctor, bloodSample))
        end
    )

    return actions
end

function FAM_TriagePanel:renderVirologyStatus(y)
    local status = FAM.getZVirusVaccineStatus(self.patient)
    local counts = countInventoryTypes(self.doctor, {
        syringes = ZVV_EMPTY_SYRINGE_TYPES,
        blood = ZVV_BLOOD_TYPES,
        vaccines = ZVV_VACCINE_TYPES,
        tubes = { "LabItems.LabTestTube", "LabItems.LabTestTubeDirty" },
        brain = { "LabItems.HumanBrainLow", "LabItems.HumanBrainMid", "LabItems.HumanBrainHigh" },
    })

    self:drawText(getText("IGUI_FAM_ZVV_Title"), 18, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Medium)
    y = y + FONT_HGT_MEDIUM + 10
    self:drawRect(14, y - 4, CONTENT_WIDTH - 28, 146, COLORS.panel.a, COLORS.panel.r, COLORS.panel.g, COLORS.panel.b)
    self:drawRectBorder(14, y - 4, CONTENT_WIDTH - 28, 146, 0.32, COLORS.line.r, COLORS.line.g, COLORS.line.b)

    local activeText = status.active and getText("IGUI_FAM_ZVV_Active") or getText("IGUI_FAM_ZVV_Inactive")
    local activeColor = status.active and COLORS.line or COLORS.caution
    self:drawText(activeText, 24, y + 4, activeColor.r, activeColor.g, activeColor.b, 1, UIFont.Small)
    self:drawText(status.professionAddon and getText("IGUI_FAM_ZVV_ProfessionReady") or getText("IGUI_FAM_ZVV_ProfessionMissing"), 260, y + 4, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)

    local infectionText = status.infected and getText("IGUI_FAM_ZVV_Infected", asTextInt(status.infectionRate)) or getText("IGUI_FAM_ZVV_Clear")
    self:drawText(infectionText, 24, y + 30, status.infected and COLORS.danger.r or COLORS.line.r, status.infected and COLORS.danger.g or COLORS.line.g, status.infected and COLORS.danger.b or COLORS.line.b, 1, UIFont.Small)
    drawBar(self, 260, y + 32, 260, 12, status.infectionRate)

    self:drawText(getText("IGUI_FAM_ZVV_Protection", asTextInt(status.vaccineQuality), asTextInt(status.vaccineStrength), asTextInt(status.vaccineTime)), 24, y + 58, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    self:drawText(getText("IGUI_FAM_ZVV_Recess", asTextInt(status.vaccineRecess), asTextInt(status.albuminDoses)), 24, y + 84, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    self:drawText(getText("IGUI_FAM_ZVV_Inventory", asTextInt(counts.syringes), asTextInt(counts.blood), asTextInt(counts.vaccines), asTextInt(counts.tubes), asTextInt(counts.brain)), 24, y + 110, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)

    y = y + 166
    self:drawText(getText("IGUI_FAM_ZVV_Workflows"), 18, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 8
    if self.doctor ~= self.patient then
        self:clearTreatmentButtons()
        self:drawText(getText("IGUI_FAM_ZVV_SelfOnly"), 24, y, COLORS.caution.r, COLORS.caution.g, COLORS.caution.b, 1, UIFont.Small)
        return
    end
    self:syncTreatmentButtons(self:getVirologyActions(), 24, y)
    y = y + TREATMENT_BUTTON_HEIGHT + 22
    self:drawText(getText("IGUI_FAM_ZVV_LabHint"), 24, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
end

function FAM_TriagePanel:renderProviderStats(y)
    self:drawText(getText("IGUI_FAM_ProviderStatsTitle"), 18, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Medium)
    y = y + FONT_HGT_MEDIUM + 10
    self:drawRect(14, y - 4, CONTENT_WIDTH - 28, self.height - y - 28, COLORS.panel.a, COLORS.panel.r, COLORS.panel.g, COLORS.panel.b)
    self:drawRectBorder(14, y - 4, CONTENT_WIDTH - 28, self.height - y - 28, 0.32, COLORS.line.r, COLORS.line.g, COLORS.line.b)

    self:drawText(getText("IGUI_FAM_ProviderRankHeader"), 24, y + 4, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 18

    local rows = FAM_ClientCommands.providerStatsRows
    if not rows or #rows == 0 then
        rows = FAM.getProviderStatsRows()
    end
    if not rows or #rows == 0 then
        self:drawText(getText("IGUI_FAM_NoProviderStats"), 24, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        return
    end

    for i = 1, math.min(#rows, 10) do
        local row = rows[i]
        local rowY = y + ((i - 1) * 34)
        self:drawRect(22, rowY - 3, CONTENT_WIDTH - 44, 28, 0.44, 0.01, 0.03, 0.018)
        self:drawText(tostring(i) .. ". " .. tostring(row.provider or "?"), 30, rowY, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
        self:drawText(formatText("IGUI_FAM_ProviderRankRow", asTextInt(row.score), asTextInt(row.peopleSaved), asTextInt(row.injuriesFixed), asTextInt(row.advancedProcedures), asTextInt(row.patientCount), asTextInt(row.pathologyStudies)), 238, rowY, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    end
end

function FAM_TriagePanel:renderPandemicStatus(y)
    local status = FAM_ClientCommands.pandemicStatus or FAM.getPandemicStatus()
    self:drawText(getText("IGUI_FAM_PandemicTitle"), 18, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Medium)
    y = y + FONT_HGT_MEDIUM + 10
    self:drawRect(14, y - 4, CONTENT_WIDTH - 28, 110, COLORS.panel.a, COLORS.panel.r, COLORS.panel.g, COLORS.panel.b)
    self:drawRectBorder(14, y - 4, CONTENT_WIDTH - 28, 110, 0.32, COLORS.line.r, COLORS.line.g, COLORS.line.b)
    self:drawText(getText("IGUI_FAM_PandemicAlert"), 24, y + 6, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    drawBar(self, 152, y + 8, 420, 14, status.alert or 0)
    self:drawText(tostring(math.floor(status.alert or 0)) .. "%", 588, y + 4, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    self:drawText(formatText("IGUI_FAM_PandemicSummary", asTextInt(status.activeCases), asTextInt(status.quarantined), asTextInt(status.treated), asTextInt(status.totalCases)), 24, y + 36, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)

    local patientLine = getText("IGUI_FAM_PandemicPatientClear")
    if self.patient and FAM.isPandemicInfected(self.patient) then
        patientLine = getText("IGUI_FAM_PandemicPatientActiveNamed", FAM.getPandemicDiseaseName(self.patient, self.doctor), asTextInt(FAM.getPandemicLoad(self.patient)), asTextInt(FAM.getPandemicContagion(self.patient)))
        if FAM.isPandemicSuperCarrier(self.patient) then
            patientLine = patientLine .. " " .. getText("IGUI_FAM_Disease_SuperCarrier")
        end
    elseif self.patient and FAM.getPandemicQuarantineHours(self.patient) > 0 then
        patientLine = getText("IGUI_FAM_PandemicPatientQuarantine", asTextInt(FAM.getPandemicQuarantineHours(self.patient)))
    end
    self:drawText(patientLine, 24, y + 62, COLORS.line.r, COLORS.line.g, COLORS.line.b, 1, UIFont.Small)
    if self.patient and FAM.isPandemicInfected(self.patient) then
        self:drawText(trimText(getText("IGUI_FAM_Disease_TreatmentLine", FAM.getPandemicTreatmentText(self.patient)), CONTENT_WIDTH - 62, UIFont.Small), 24, y + 84, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    end

    y = y + 126
    self:drawText(getText("IGUI_FAM_PandemicCases"), 18, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 8
    if not status.rows or #status.rows == 0 then
        self:drawText(getText("IGUI_FAM_PandemicNoCases"), 24, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        return
    end
    for i = 1, math.min(#status.rows, 9) do
        local row = status.rows[i]
        local rowY = y + ((i - 1) * 30)
        self:drawRect(22, rowY - 3, CONTENT_WIDTH - 44, 24, 0.44, 0.01, 0.03, 0.018)
        local state = row.active and getText("IGUI_FAM_PandemicActive") or getText("IGUI_FAM_PandemicClearShort")
        self:drawText(tostring(row.name or "?"), 30, rowY, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
        local carrier = row.superCarrier and getText("IGUI_FAM_Disease_SuperCarrierShort") or ""
        self:drawText(formatText("IGUI_FAM_PandemicCaseRow", state, asTextInt(row.load), asTextInt(row.quarantine), asTextInt(row.treated), asTextInt(row.cases), row.disease or "", asTextInt(row.contagion), carrier), 230, rowY, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    end
end

function FAM_TriagePanel:renderPathologyStatus(y)
    local provider = self.doctor or getPlayer()
    local summary = FAM_ClientCommands.pathologySummary or FAM.getPathologySummary(provider)
    local records = FAM_ClientCommands.pathologyRecords
    if not records or #records == 0 then
        records = FAM.copyPathologyRecords(provider)
    end

    self:drawText(getText("IGUI_FAM_PathologyTitle"), 18, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Medium)
    y = y + FONT_HGT_MEDIUM + 10
    self:drawRect(14, y - 4, CONTENT_WIDTH - 28, 118, COLORS.panel.a, COLORS.panel.r, COLORS.panel.g, COLORS.panel.b)
    self:drawRectBorder(14, y - 4, CONTENT_WIDTH - 28, 118, 0.32, COLORS.line.r, COLORS.line.g, COLORS.line.b)
    self:drawText(formatText("IGUI_FAM_PathologySummary", asTextInt(summary.studies), asTextInt(summary.samples), asTextInt(summary.signals), asTextInt(summary.unsafe)), 24, y + 4, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    self:drawText(summary.journal and getText("IGUI_FAM_PathologyJournalReady") or getText("IGUI_FAM_PathologyJournalMissing"), 24, y + 30, summary.journal and COLORS.line.r or COLORS.caution.r, summary.journal and COLORS.line.g or COLORS.caution.g, summary.journal and COLORS.line.b or COLORS.caution.b, 1, UIFont.Small)
    self:drawText(getText("IGUI_FAM_PathologyProviderExposure", asTextInt(summary.exposure), asTextInt(summary.pathogen)), 280, y + 30, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    self:drawText(getText("IGUI_FAM_PathologyProtocolHint"), 24, y + 58, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    if summary.updatedAt then
        self:drawText(getText("IGUI_FAM_PathologyUpdated", summary.updatedAt), 24, y + 84, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    end

    y = y + 134
    self:drawText(getText("IGUI_FAM_PathologyRecords"), 18, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
    y = y + FONT_HGT_SMALL + 8
    if not records or #records == 0 then
        self:drawText(getText("IGUI_FAM_PathologyNoRecords"), 24, y, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        return
    end

    local shown = math.min(#records, 10)
    for i = 1, shown do
        local record = records[#records - i + 1]
        local rowY = y + ((i - 1) * 34)
        local signalText = record.signal and getText("IGUI_FAM_PathologySignal") or getText("IGUI_FAM_PathologyClear")
        self:drawRect(22, rowY - 3, CONTENT_WIDTH - 44, 28, 0.44, 0.01, 0.03, 0.018)
        self:drawText(trimText(FAM.pathologyModeLabel(record.mode), 120, UIFont.Small), 30, rowY, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
        self:drawText(formatText("IGUI_FAM_PathologyRow", FAM.pathologyKindLabel(record.kind), asTextInt(record.quality), asTextInt(record.risk), asTextInt(record.xp), signalText), 160, rowY, record.signal and COLORS.caution.r or COLORS.dim.r, record.signal and COLORS.caution.g or COLORS.dim.g, record.signal and COLORS.caution.b or COLORS.dim.b, 1, UIFont.Small)
        self:drawText(trimText(record.timestamp or "?", 150, UIFont.Small), 646, rowY, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
    end
end

function FAM_TriagePanel:renderGuide()
    local x = px(112)
    local y = px(92)
    local w = px(720)
    local h = px(332)
    self:drawRect(x, y, w, h, 0.96, 0.006, 0.016, 0.01)
    self:drawRectBorder(x - 1, y - 1, w + 2, h + 2, 0.24, COLORS.line.r, COLORS.line.g, COLORS.line.b)
    self:drawRectBorder(x, y, w, h, 0.86, COLORS.line.r, COLORS.line.g, COLORS.line.b)
    self:drawText(getText("IGUI_FAM_GuideTitle"), x + 14, y + 12, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Medium)
    self:drawText(getText("IGUI_FAM_GuideCloseHint"), x + w - 196, y + 16, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)

    local lineY = y + 52
    local lines = {
        "IGUI_FAM_GuideLine01",
        "IGUI_FAM_GuideLine02",
        "IGUI_FAM_GuideLine03",
        "IGUI_FAM_GuideLine04",
        "IGUI_FAM_GuideLine05",
        "IGUI_FAM_GuideLine06",
        "IGUI_FAM_GuideLine07",
        "IGUI_FAM_GuideLine08",
    }
    for i = 1, #lines do
        self:drawText(trimText(getText(lines[i]), w - 28, UIFont.Small), x + 14, lineY, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        lineY = lineY + FONT_HGT_SMALL + 12
    end
end

function FAM_TriagePanel:selectHitRow(x, y)
    local hitRowSets = { self.conditionReaderHitRows, self.bodyPartHitRows }
    for setIndex = 1, #hitRowSets do
        local rows = hitRowSets[setIndex]
        if rows then
            for i = 1, #rows do
                local row = rows[i]
                if x >= row.x and x <= row.x + row.w and y >= row.y and y <= row.y + row.h then
                    self:selectBodyPartIndex(row.index)
                    return true
                end
            end
        end
    end
    return false
end

function FAM_TriagePanel:onMouseDown(x, y)
    if self:selectHitRow(x, y) then
        return true
    end
    if ISCollapsableWindow.onMouseDown then
        return ISCollapsableWindow.onMouseDown(self, x, y)
    end
    return false
end

function FAM_TriagePanel:onMouseUp(x, y)
    if self:selectHitRow(x, y) then
        return true
    end
    if ISCollapsableWindow.onMouseUp then
        return ISCollapsableWindow.onMouseUp(self, x, y)
    end
end

function FAM_TriagePanel:scrollRowArea(area, key, delta)
    if not area or not key or not area.total or not area.visible or area.total <= area.visible then return false end
    local mouseX = self:getMouseX()
    local mouseY = self:getMouseY()
    if mouseX < area.x or mouseX > area.x + area.w or mouseY < area.y or mouseY > area.y + area.h then
        return false
    end
    local direction = delta < 0 and 1 or -1
    local current = self[key] or 0
    local nextOffset = clampRowScroll(current + direction, area.total, area.visible)
    if nextOffset ~= current then
        self[key] = nextOffset
    end
    return true
end

function FAM_TriagePanel:onMouseWheel(delta)
    if (self.activeTab or "chart") == "chart" then
        if self:scrollRowArea(self.bodyPartScrollArea, "bodyPartScroll", delta) then return true end
        if self:scrollRowArea(self.conditionReaderScrollArea, "conditionReaderScroll", delta) then return true end
    end
    if ISCollapsableWindow.onMouseWheel then
        return ISCollapsableWindow.onMouseWheel(self, delta)
    end
    return false
end

function FAM_TriagePanel:render()
    self:refreshLayout()
    ISCollapsableWindow.render(self)
    self:syncTabButtons()
    self:updatePatientModel()
    if not self.patient or not self.doctor then
        self:clearTreatmentButtons()
        self:setNoteControlsVisible(false)
        self:setPandemicControlsVisible(false)
        if self.bodyPartPanel then
            self.bodyPartPanel:setVisible(false)
        end
        return
    end
    self:renderPatientVisualInfo()
    if (self.activeTab or "chart") == "providers" then
        self:clearTreatmentButtons()
        self:setNoteControlsVisible(false)
        self:setPandemicControlsVisible(false)
        self:renderProviderStats(86)
        if self.guideVisible then
            self:renderGuide()
        end
        return
    elseif self.activeTab == "pandemic" then
        self:clearTreatmentButtons()
        self:setNoteControlsVisible(false)
        self:setPandemicControlsVisible(true)
        self:syncPandemicButtons()
        self:renderPandemicStatus(86)
        if self.guideVisible then
            self:renderGuide()
        end
        return
    elseif self.activeTab == "pathology" then
        self:clearTreatmentButtons()
        self:setNoteControlsVisible(false)
        self:setPandemicControlsVisible(false)
        self:renderPathologyStatus(86)
        if self.guideVisible then
            self:renderGuide()
        end
        return
    elseif self.activeTab == "virology" then
        self:setNoteControlsVisible(false)
        self:setPandemicControlsVisible(false)
        self:renderVirologyStatus(86)
        if self.guideVisible then
            self:renderGuide()
        end
        return
    end
    self:setPandemicControlsVisible(false)
    local y = px(78)
    y = self:renderVitals(y)
    y = self:renderClinicalSummary(y)
    y = self:renderProtocols(y)
    y = self:renderConditionReaders(y)
    y = self:renderSubstanceScanner(y)
    local noteFootprint = NOTE_PANEL_HEIGHT + FONT_HGT_SMALL + px(24)
    local treatmentPlannerReserve = FONT_HGT_SMALL + px(126)
    y = self:renderBodyParts(y, self.height - treatmentPlannerReserve)
    y = self:renderTreatmentPlanner(y + 8)
    if y + noteFootprint + px(8) <= self.height then
        y = self:renderPatientNotes(y + 8)
    else
        self:setNoteControlsVisible(false)
    end
    if y + 140 <= self.height - 24 then
        self:renderAdvancedMatrix(y + 8)
    end
    if self.guideVisible then
        self:renderGuide()
    end
end

function FAM_TriagePanel:new(x, y, doctor, patient)
    refreshLayoutMetrics(FAM.isZVirusVaccineAvailable and FAM.isZVirusVaccineAvailable() and 5 or 4)
    local height = getPanelHeight()
    local o = ISCollapsableWindow.new(self, x, y, PANEL_WIDTH, height)
    o.doctor = doctor
    o.patient = patient
    o.activeTab = "chart"
    o.title = getText("IGUI_FAM_WindowTitle")
    o.resizable = false
    o.pin = true
    o.famPulseAnimations = {}
    o.famPulseFrame = 1
    o.famPulseTimer = 0
    o.conditionReaderScroll = 0
    o.bodyPartScroll = 0
    return o
end

function FAM_TriagePanel.open(doctor, patient)
    refreshLayoutMetrics(FAM.isZVirusVaccineAvailable and FAM.isZVirusVaccineAvailable() and 5 or 4)
    FAM.refreshCorpseExposureDisplay(patient)
    FAM_ClientCommands.requestPatientSnapshot(doctor, patient)
    FAM_ClientCommands.requestProviderStats(doctor)
    FAM_ClientCommands.requestPandemicStatus(doctor)
    FAM_ClientCommands.requestPathology(doctor)
    if FAM_TriagePanel.instance then
        FAM_TriagePanel.instance.doctor = doctor
        FAM_TriagePanel.instance.patient = patient
        FAM_TriagePanel.instance.famPulseState = nil
        FAM_TriagePanel.instance.famPulseFrame = 1
        FAM_TriagePanel.instance.famPulseTimer = 0
        FAM_TriagePanel.instance.conditionReaderScroll = 0
        FAM_TriagePanel.instance.bodyPartScroll = 0
        FAM_TriagePanel.instance.notesPatient = nil
        startBodyDamageUpdates(FAM_TriagePanel.instance, doctor, patient)
        FAM_TriagePanel.instance:updatePatientModel()
        FAM_TriagePanel.instance:setVisible(true)
        FAM_TriagePanel.instance:bringToTop()
        return FAM_TriagePanel.instance
    end

    local x = math.max(px(20), (getCore():getScreenWidth() / 2) - (PANEL_WIDTH / 2))
    local height = getPanelHeight()
    local y = math.max(px(20), (getCore():getScreenHeight() / 2) - (height / 2))
    local panel = FAM_TriagePanel:new(x, y, doctor, patient)
    panel:initialise()
    panel:addToUIManager()
    FAM_TriagePanel.instance = panel
    startBodyDamageUpdates(panel, doctor, patient)
    return panel
end

local function closeTriageForSessionEnd()
    FAM_TriagePanel.closeForSessionEnd()
end

local function closeTriageForPlayerEnd(player)
    local panel = FAM_TriagePanel.instance
    if not panel then return end
    if not player or panel.doctor == player or panel.patient == player then
        FAM_TriagePanel.closeForSessionEnd()
    end
end

if Events and not FAM_TriagePanel._sessionCleanupRegistered then
    FAM_TriagePanel._sessionCleanupRegistered = true
    if Events.OnMainMenuEnter then
        Events.OnMainMenuEnter.Add(closeTriageForSessionEnd)
    end
    if Events.OnDisconnect then
        Events.OnDisconnect.Add(closeTriageForSessionEnd)
    end
    if Events.OnGameStart then
        Events.OnGameStart.Add(closeTriageForSessionEnd)
    end
    if Events.OnPlayerDeath then
        Events.OnPlayerDeath.Add(closeTriageForPlayerEnd)
    end
end
