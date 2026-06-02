require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "ISUI/ISScrollingListBox"
require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/Config/FeatureHelpDB"
require "CSRAdminCommandCenter/ClientCommands"
require "CSRAdminCommandCenter/UI/Components/ACC_Draw"

CSR_ACC_HelpTab = ISPanel:derive("CSR_ACC_HelpTab")

local ACC = CSRAdminCommandCenter
local Draw = ACC.Draw

function CSR_ACC_HelpTab:initialise()
    ISPanel.initialise(self)
end

function CSR_ACC_HelpTab:createChildren()
    self.searchEntry = ISTextEntryBox:new("", 12, 10, 260, 24)
    self.searchEntry:initialise()
    self.searchEntry:instantiate()
    Draw.styleEntry(self.searchEntry)
    self:addChild(self.searchEntry)

    self.searchBtn = ISButton:new(280, 10, 76, 24, "Search", self, CSR_ACC_HelpTab.onSearch)
    self.searchBtn:initialise(); self.searchBtn:instantiate(); Draw.styleButton(self.searchBtn); self:addChild(self.searchBtn)

    self.list = ISScrollingListBox:new(12, 44, 270, self.height - 58)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = 24
    Draw.styleList(self.list)
    self.list.parentPanel = self
    self.list.doDrawItem = CSR_ACC_HelpTab.drawRow
    self:addChild(self.list)

    self:populate("")
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

function CSR_ACC_HelpTab:populate(query)
    if not self.list then return end
    self.list:clear()
    local rows = ACC.FeatureHelpDB.search(query or "")
    for i = 1, #rows do
        self.list:addItem(rows[i].title, rows[i])
    end
end

function CSR_ACC_HelpTab:onSearch()
    self:populate(entryText(self.searchEntry))
end

function CSR_ACC_HelpTab:selectedEntry()
    if not self.list or not self.list.items then return nil end
    local selected = self.list.items[self.list.selected or 0]
    return selected and selected.item or nil
end

function CSR_ACC_HelpTab.drawRow(list, y, item, alt)
    if list.selected == item.index then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.35, 0.18, 0.34, 0.48)
    elseif alt then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.16, 0.16, 0.17, 0.18)
    end
    list:drawText(tostring(item.text or ""), 6, y + 4, 0.88, 0.90, 0.90, 1, UIFont.Small)
    return y + list.itemheight
end

function CSR_ACC_HelpTab:drawLongText(text, x, y, maxChars, color)
    local value = tostring(text or "")
    local line = ""
    maxChars = maxChars or 88
    for word in string.gmatch(value, "%S+") do
        if string.len(line) + string.len(word) + 1 > maxChars then
            Draw.text(self, line, x, y, color or Draw.colors.text)
            y = y + 17
            line = word
        else
            if line == "" then line = word else line = line .. " " .. word end
        end
    end
    if line ~= "" then
        Draw.text(self, line, x, y, color or Draw.colors.text)
        y = y + 17
    end
    return y
end

function CSR_ACC_HelpTab:prerender()
    ISPanel.prerender(self)
    Draw.background(self, 0, 0, self.width, self.height)
    Draw.neonFrame(self, 0, 0, self.width, self.height)
    local entry = self:selectedEntry()
    local x = 304
    local y = 48
    if not entry then
        Draw.text(self, "Select a help entry", x, y, Draw.colors.muted)
        return
    end

    Draw.section(self, entry.title or "", x, y, self.width - x - 18)
    y = y + 30
    Draw.labelValue(self, "System", tostring(entry.system or ""), x + 4, y); y = y + 20
    Draw.labelValue(self, "Live safety", tostring(entry.liveSafe or ""), x + 4, y); y = y + 20
    Draw.labelValue(self, "Performance", tostring(entry.performance or ""), x + 4, y); y = y + 20
    Draw.labelValue(self, "Risk", tostring(entry.risk or ""), x + 4, y); y = y + 20
    Draw.labelValue(self, "Debug", tostring(entry.debug or ""), x + 4, y); y = y + 20
    Draw.labelValue(self, "Logs", tostring(entry.logs or ""), x + 4, y); y = y + 28

    y = self:drawLongText(entry.body or "", x + 4, y, 92, Draw.colors.text) + 10

    local snapshot = ACC.ClientCommands.state.snapshot or {}
    local population = tonumber(snapshot.population) or 0
    local rec, category = ACC.FeatureHelpDB.getRecommendation(entry, population)
    Draw.section(self, "Recommendation", x, y, self.width - x - 18)
    y = y + 30
    Draw.labelValue(self, "Population", tostring(population) .. " online (" .. tostring(category) .. ")", x + 4, y); y = y + 20
    if rec then
        y = self:drawLongText(rec.text or "", x + 4, y, 92, Draw.colors.text)
        Draw.labelValue(self, "Settings", tostring(rec.settings or ""), x + 4, y); y = y + 20
        Draw.labelValue(self, "Impact", tostring(rec.performance or ""), x + 4, y); y = y + 20
        Draw.labelValue(self, "Risk", tostring(rec.risk or ""), x + 4, y)
    end
end

function CSR_ACC_HelpTab:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    return o
end

return CSR_ACC_HelpTab
