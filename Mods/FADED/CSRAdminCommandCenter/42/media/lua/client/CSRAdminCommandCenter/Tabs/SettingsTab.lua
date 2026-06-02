require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "ISUI/ISScrollingListBox"
require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/ClientCommands"
require "CSRAdminCommandCenter/UI/Components/ACC_Draw"

CSR_ACC_SettingsTab = ISPanel:derive("CSR_ACC_SettingsTab")

local ACC = CSRAdminCommandCenter
local Draw = ACC.Draw

function CSR_ACC_SettingsTab:initialise()
    ISPanel.initialise(self)
end

local function entryText(entry)
    if not entry then return "" end
    if entry.getText then
        local text = entry:getText()
        if text then return tostring(text) end
    end
    if entry.getInternalText then
        local text = entry:getInternalText()
        if text then return tostring(text) end
    end
    return ""
end

local function setEntry(entry, text)
    if entry and entry.setText then entry:setText(tostring(text or "")) end
end

function CSR_ACC_SettingsTab:createChildren()
    self.refreshBtn = ISButton:new(12, 10, 82, 24, "Refresh", self, CSR_ACC_SettingsTab.onRefresh)
    self.refreshBtn:initialise(); self.refreshBtn:instantiate(); Draw.styleButton(self.refreshBtn, true); self:addChild(self.refreshBtn)

    self.list = ISScrollingListBox:new(12, 44, 356, self.height - 58)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = 26
    Draw.styleList(self.list)
    self.list.doDrawItem = CSR_ACC_SettingsTab.drawRow
    self:addChild(self.list)

    local x = 396
    self.valueEntry = ISTextEntryBox:new("", x, 238, 210, 24)
    self.valueEntry:initialise(); self.valueEntry:instantiate(); Draw.styleEntry(self.valueEntry); self:addChild(self.valueEntry)

    self.applyBtn = ISButton:new(x + 218, 238, 82, 24, "Apply", self, CSR_ACC_SettingsTab.onApply)
    self.applyBtn:initialise(); self.applyBtn:instantiate(); Draw.styleButton(self.applyBtn, true); self:addChild(self.applyBtn)

    self.toggleBtn = ISButton:new(x, 238, 120, 24, "Toggle", self, CSR_ACC_SettingsTab.onToggle)
    self.toggleBtn:initialise(); self.toggleBtn:instantiate(); Draw.styleButton(self.toggleBtn, true); self:addChild(self.toggleBtn)
    if self.toggleBtn.setVisible then self.toggleBtn:setVisible(false) end

    self.resetBtn = ISButton:new(x, 272, 120, 24, "Default", self, CSR_ACC_SettingsTab.onReset)
    self.resetBtn:initialise(); self.resetBtn:instantiate(); Draw.styleButton(self.resetBtn); self:addChild(self.resetBtn)

    ACC.ClientCommands.requestSettings()
end

function CSR_ACC_SettingsTab:onRefresh()
    ACC.ClientCommands.requestSettings()
end

function CSR_ACC_SettingsTab:settings()
    return ACC.ClientCommands.state.settingsState
        or (ACC.ClientCommands.state.snapshot and ACC.ClientCommands.state.snapshot.settings)
        or {}
end

function CSR_ACC_SettingsTab:refreshList()
    local settings = self:settings()
    if settings == self._lastSettings then return end
    self._lastSettings = settings
    local previousKey = self:selectedRow() and self:selectedRow().key or self._lastSelectedKey
    self.list:clear()
    local rows = settings.rows or {}
    local selectIndex = 1
    for i = 1, #rows do
        local row = rows[i]
        self.list:addItem(tostring(row.label or row.key or ""), row)
        if tostring(row.key or "") == tostring(previousKey or "") then selectIndex = i end
    end
    if #rows > 0 then self.list.selected = selectIndex end
end

function CSR_ACC_SettingsTab:selectedRow()
    if not self.list or not self.list.items then return nil end
    local selected = self.list.items[self.list.selected or 0]
    return selected and selected.item or nil
end

function CSR_ACC_SettingsTab:onApply()
    local row = self:selectedRow()
    if not row then return end
    ACC.ClientCommands.setSetting(row.key, entryText(self.valueEntry), false)
end

function CSR_ACC_SettingsTab:onToggle()
    local row = self:selectedRow()
    if not row or row.type ~= "boolean" then return end
    ACC.ClientCommands.setSetting(row.key, row.value ~= true, false)
end

function CSR_ACC_SettingsTab:onReset()
    local row = self:selectedRow()
    if not row then return end
    ACC.ClientCommands.setSetting(row.key, "", true)
end

function CSR_ACC_SettingsTab:updateControls(row)
    if not row then return end
    local key = tostring(row.key or "")
    if key ~= self._lastSelectedKey then
        self._lastSelectedKey = key
        setEntry(self.valueEntry, tostring(row.value or ""))
    end
    local isBool = row.type == "boolean"
    if self.valueEntry.setVisible then self.valueEntry:setVisible(not isBool) end
    if self.applyBtn.setVisible then self.applyBtn:setVisible(not isBool) end
    if self.toggleBtn.setVisible then self.toggleBtn:setVisible(isBool) end
    if isBool then
        self.toggleBtn:setTitle(row.value == true and "Turn Off" or "Turn On")
        Draw.styleButton(self.toggleBtn, row.value ~= true)
    end
end

function CSR_ACC_SettingsTab.drawRow(list, y, item, alt)
    local row = item and item.item or {}
    if list.selected == item.index then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.35, 0.18, 0.34, 0.48)
    elseif alt then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.16, 0.16, 0.17, 0.18)
    end
    local left = tostring(row.category or "") .. "  " .. tostring(row.label or row.key or "")
    local right = tostring(row.valueText or row.value or "")
    local valueX = math.max(214, list:getWidth() - 132)
    list:drawText(Draw.fitText(left, 32), 6, y + 4, 0.88, 0.90, 0.90, 1, UIFont.Small)
    list:drawText(Draw.fitText(right, 18), valueX, y + 4, 0.38, 1.00, 0.26, 1, UIFont.Small)
    return y + list.itemheight
end

local function enumLines(values)
    local lines = {}
    if type(values) ~= "table" then return lines end
    for i = 1, 8 do
        if values[i] then lines[#lines + 1] = tostring(i) .. " = " .. tostring(values[i]) end
    end
    return lines
end

function CSR_ACC_SettingsTab:prerender()
    ISPanel.prerender(self)
    Draw.background(self, 0, 0, self.width, self.height)
    Draw.neonFrame(self, 0, 0, self.width, self.height)
    self:refreshList()

    local row = self:selectedRow()
    local x = 396
    local y = 48
    if not row then
        Draw.text(self, "No ACC settings received", x, y, Draw.colors.warn)
        return
    end
    self:updateControls(row)

    Draw.section(self, tostring(row.label or row.key or ""), x, y, self.width - x - 18)
    y = y + 32
    Draw.labelValue(self, "Key", tostring(row.key or ""), x + 4, y, nil, 126, 46); y = y + 20
    Draw.labelValue(self, "Category", tostring(row.category or ""), x + 4, y, nil, 126, 46); y = y + 20
    Draw.labelValue(self, "Type", tostring(row.type or ""), x + 4, y, nil, 126, 46); y = y + 20
    Draw.labelValue(self, "Current", tostring(row.valueText or row.value or ""), x + 4, y, Draw.colors.good, 126, 46); y = y + 20
    Draw.labelValue(self, "Default", tostring(row.defaultText or row.default or ""), x + 4, y, nil, 126, 46); y = y + 28

    y = Draw.textWrapped(self, tostring(row.description or ""), x + 4, y, 78, 3, Draw.colors.text) + 12
    if row.type == "integer" then
        Draw.labelValue(self, "Range", tostring(row.min or "") .. " - " .. tostring(row.max or ""), x + 4, y, nil, 126, 46)
    elseif row.type == "enum" then
        local lines = enumLines(row.values)
        for i = 1, #lines do
            Draw.text(self, lines[i], x + 4, y, Draw.colors.muted)
            y = y + 18
        end
    end

    local result = ACC.ClientCommands.state.settingsResult
    if result and result.message then
        Draw.textWrapped(self, tostring(result.message), x + 4, self.height - 54, 76, 2,
            result.ok and Draw.colors.good or Draw.colors.warn)
    end
end

function CSR_ACC_SettingsTab:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    return o
end

return CSR_ACC_SettingsTab
