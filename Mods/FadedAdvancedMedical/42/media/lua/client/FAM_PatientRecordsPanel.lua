if isServer() then return end

require "ISUI/ISButton"
require "ISUI/ISCollapsableWindow"
require "FAM_Core"
require "FAM_ClientCommands"

FAM_PatientRecordsPanel = ISCollapsableWindow:derive("FAM_PatientRecordsPanel")

local COLORS = {
    bg = { a = 0.94, r = 0.012, g = 0.022, b = 0.016 },
    panel = { a = 0.78, r = 0.025, g = 0.055, b = 0.035 },
    line = { a = 0.95, r = 0.1, g = 0.9, b = 0.45 },
    dim = { a = 0.82, r = 0.55, g = 0.72, b = 0.6 },
    text = { a = 1, r = 0.86, g = 0.96, b = 0.88 },
    danger = { a = 1, r = 0.95, g = 0.28, b = 0.22 },
}

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

local function drawGlowBorder(self, x, y, w, h)
    self:drawRectBorder(x - 1, y - 1, w + 2, h + 2, 0.16, COLORS.line.r, COLORS.line.g, COLORS.line.b)
    self:drawRectBorder(x, y, w, h, COLORS.line.a, COLORS.line.r, COLORS.line.g, COLORS.line.b)
end

local function getPatientName(patient)
    if patient and patient.getDisplayName then
        return patient:getDisplayName()
    end
    return "?"
end

local function compactText(text, maxLength)
    text = tostring(text or "")
    text = string.gsub(text, "%s+", " ")
    if string.len(text) > maxLength then
        return string.sub(text, 1, math.max(1, maxLength - 3)) .. "..."
    end
    return text
end

local function asTextInt(value)
    return tostring(math.floor(tonumber(value) or 0))
end

local function showAccessDenied(player)
    local text = getText("IGUI_FAM_RecordsAccessDenied")
    local target = player or (getPlayer and getPlayer() or nil)
    if target and HaloTextHelper and HaloTextHelper.addBadText then
        HaloTextHelper.addBadText(target, text)
    elseif target and target.Say then
        target:Say(text)
    end
end

function FAM_PatientRecordsPanel:initialise()
    ISCollapsableWindow.initialise(self)
end

function FAM_PatientRecordsPanel:createChildren()
    ISCollapsableWindow.createChildren(self)
    self.recordsRefresh = ISButton:new(self.width - 154, 24, 70, 24, getText("IGUI_FAM_Refresh"), self, FAM_PatientRecordsPanel.onRefresh)
    self.recordsRefresh:initialise()
    self:addChild(self.recordsRefresh)

    self.closeButton = ISButton:new(self.width - 78, 24, 58, 24, getText("IGUI_FAM_Close"), self, FAM_PatientRecordsPanel.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)
end

function FAM_PatientRecordsPanel:onClose()
    self:close()
end

function FAM_PatientRecordsPanel:close()
    FAM_PatientRecordsPanel.destroyInstance()
end

function FAM_PatientRecordsPanel.destroyInstance()
    local panel = FAM_PatientRecordsPanel.instance
    if not panel then return end
    panel.doctor = nil
    panel.patient = nil
    ISCollapsableWindow.close(panel)
    FAM_PatientRecordsPanel.instance = nil
end

function FAM_PatientRecordsPanel:onRefresh()
    FAM_ClientCommands.requestPatientRecords(self.doctor, self.patient)
    self.refreshTick = (self.refreshTick or 0) + 1
end

function FAM_PatientRecordsPanel:onRecordsUpdated()
    self.refreshTick = (self.refreshTick or 0) + 1
end

function FAM_PatientRecordsPanel:prerender()
    ISCollapsableWindow.prerender(self)
    self:drawRect(0, 16, self.width, self.height - 16, COLORS.bg.a, COLORS.bg.r, COLORS.bg.g, COLORS.bg.b)
    drawGlowBorder(self, 8, 22, self.width - 16, self.height - 30)
end

function FAM_PatientRecordsPanel:renderNoteHistory(x, y, w, h)
    self:drawRect(x, y, w, h, COLORS.panel.a, COLORS.panel.r, COLORS.panel.g, COLORS.panel.b)
    self:drawRectBorder(x, y, w, h, 0.32, COLORS.line.r, COLORS.line.g, COLORS.line.b)
    self:drawText(getText("IGUI_FAM_RecordsHistory"), x + 10, y + 8, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)

    local records = FAM.copyPatientNoteRecords(self.patient)
    local rowY = y + 32
    if #records == 0 then
        self:drawText(getText("IGUI_FAM_RecordsNoNotes"), x + 12, rowY, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        return
    end

    for i = #records, 1, -1 do
        if rowY + 40 > y + h then
            break
        end
        local record = records[i]
        self:drawRect(x + 8, rowY - 2, w - 16, 38, 0.42, 0.01, 0.03, 0.018)
        self:drawText(getText("IGUI_FAM_RecordBy", record.author or "?", record.timestamp or "?"), x + 14, rowY, COLORS.line.r, COLORS.line.g, COLORS.line.b, 1, UIFont.Small)
        self:drawText(compactText(record.note, 86), x + 14, rowY + FONT_HGT_SMALL + 4, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        rowY = rowY + 44
    end
end

function FAM_PatientRecordsPanel:renderAnalytics(x, y, w, h)
    self:drawRect(x, y, w, h, COLORS.panel.a, COLORS.panel.r, COLORS.panel.g, COLORS.panel.b)
    self:drawRectBorder(x, y, w, h, 0.32, COLORS.line.r, COLORS.line.g, COLORS.line.b)
    self:drawText(getText("IGUI_FAM_RecordsAnalytics"), x + 10, y + 8, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)

    local analytics = FAM.copyPatientAnalytics(self.patient)
    local rows = FAM.getPatientAnalyticsRows(self.patient)
    local summary = getText("IGUI_FAM_RecordsAnalyticsSummary", asTextInt(analytics.observations), analytics.updatedAt or "?")
    self:drawText(summary, x + 10, y + 28, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)

    local rowY = y + 54
    if #rows == 0 then
        self:drawText(getText("IGUI_FAM_RecordsNoAnalytics"), x + 12, rowY, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        return
    end

    for i = 1, #rows do
        if rowY + 34 > y + h then
            break
        end
        local row = rows[i]
        self:drawRect(x + 8, rowY - 2, w - 16, 32, 0.42, 0.01, 0.03, 0.018)
        self:drawText(compactText(row.label, 34), x + 14, rowY, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)
        self:drawText(tostring(math.floor(row.count)), x + w - 48, rowY, COLORS.line.r, COLORS.line.g, COLORS.line.b, 1, UIFont.Small)
        self:drawText(getText("IGUI_FAM_RecordLastSeen", row.lastSeen or "?"), x + 14, rowY + FONT_HGT_SMALL + 2, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        rowY = rowY + 38
    end
end

function FAM_PatientRecordsPanel:renderClinicalTimeline(x, y, w, h)
    self:drawRect(x, y, w, h, COLORS.panel.a, COLORS.panel.r, COLORS.panel.g, COLORS.panel.b)
    self:drawRectBorder(x, y, w, h, 0.32, COLORS.line.r, COLORS.line.g, COLORS.line.b)
    self:drawText(getText("IGUI_FAM_RecordsClinicalTimeline"), x + 10, y + 8, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Small)

    local records = FAM.copyClinicalRecords(self.patient)
    local rowY = y + 32
    if #records == 0 then
        self:drawText(getText("IGUI_FAM_RecordsNoClinicalTimeline"), x + 12, rowY, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        return
    end

    for i = #records, 1, -1 do
        if rowY + 44 > y + h then
            break
        end
        local record = records[i]
        local color = (record.severity or 0) >= 70 and COLORS.danger or COLORS.line
        self:drawRect(x + 8, rowY - 2, w - 16, 40, 0.42, 0.01, 0.03, 0.018)
        self:drawText(getText("IGUI_FAM_RecordBy", record.provider or "?", record.timestamp or "?"), x + 14, rowY, color.r, color.g, color.b, 1, UIFont.Small)
        local line = getText(record.labelKey or "IGUI_FAM_ClinicalEvent_Assessment") .. ": " .. tostring(record.valueText or "")
        if record.csr == true then
            line = line .. "  " .. getText("IGUI_FAM_Clinical_CSR")
        end
        self:drawText(compactText(line, 92), x + 14, rowY + FONT_HGT_SMALL + 4, COLORS.dim.r, COLORS.dim.g, COLORS.dim.b, 1, UIFont.Small)
        rowY = rowY + 46
    end
end

function FAM_PatientRecordsPanel:render()
    ISCollapsableWindow.render(self)
    if not self.patient or not self.doctor then return end

    self:drawText(getText("IGUI_FAM_RecordsTitle", getPatientName(self.patient)), 18, 34, COLORS.text.r, COLORS.text.g, COLORS.text.b, 1, UIFont.Medium)
    if FAM.hasPatientRecordAccess(self.doctor) then
        self:drawText(getText("IGUI_FAM_RecordsAccessGranted"), 18, 34 + FONT_HGT_MEDIUM + 4, COLORS.line.r, COLORS.line.g, COLORS.line.b, 1, UIFont.Small)
    else
        self:drawText(getText("IGUI_FAM_RecordsAccessDenied"), 18, 34 + FONT_HGT_MEDIUM + 4, COLORS.danger.r, COLORS.danger.g, COLORS.danger.b, 1, UIFont.Small)
        return
    end

    self:renderNoteHistory(18, 86, 360, self.height - 116)
    self:renderAnalytics(392, 86, self.width - 410, 216)
    self:renderClinicalTimeline(392, 318, self.width - 410, self.height - 348)
end

function FAM_PatientRecordsPanel:new(x, y, doctor, patient)
    local o = ISCollapsableWindow.new(self, x, y, 920, 620)
    o.doctor = doctor
    o.patient = patient
    o.title = getText("IGUI_FAM_RecordsWindowTitle")
    o.resizable = false
    o.pin = true
    return o
end

function FAM_PatientRecordsPanel.open(doctor, patient)
    if not FAM.hasPatientRecordAccess(doctor) then
        showAccessDenied(doctor)
        return nil
    end
    if FAM_PatientRecordsPanel.instance then
        FAM_PatientRecordsPanel.instance.doctor = doctor
        FAM_PatientRecordsPanel.instance.patient = patient
        FAM_PatientRecordsPanel.instance:setVisible(true)
        FAM_PatientRecordsPanel.instance:bringToTop()
        FAM_ClientCommands.requestPatientRecords(doctor, patient)
        return FAM_PatientRecordsPanel.instance
    end

    local x = math.max(20, (getCore():getScreenWidth() / 2) - 460)
    local y = math.max(20, (getCore():getScreenHeight() / 2) - 310)
    local panel = FAM_PatientRecordsPanel:new(x, y, doctor, patient)
    panel:initialise()
    panel:addToUIManager()
    FAM_PatientRecordsPanel.instance = panel
    FAM_ClientCommands.requestPatientRecords(doctor, patient)
    return panel
end

local function closeRecordsForSessionEnd()
    FAM_PatientRecordsPanel.destroyInstance()
end

local function closeRecordsForPlayerEnd(player)
    local panel = FAM_PatientRecordsPanel.instance
    if not panel then return end
    if not player or panel.doctor == player or panel.patient == player then
        FAM_PatientRecordsPanel.destroyInstance()
    end
end

if Events and not FAM_PatientRecordsPanel._sessionCleanupRegistered then
    FAM_PatientRecordsPanel._sessionCleanupRegistered = true
    if Events.OnMainMenuEnter then
        Events.OnMainMenuEnter.Add(closeRecordsForSessionEnd)
    end
    if Events.OnDisconnect then
        Events.OnDisconnect.Add(closeRecordsForSessionEnd)
    end
    if Events.OnGameStart then
        Events.OnGameStart.Add(closeRecordsForSessionEnd)
    end
    if Events.OnPlayerDeath then
        Events.OnPlayerDeath.Add(closeRecordsForPlayerEnd)
    end
end
