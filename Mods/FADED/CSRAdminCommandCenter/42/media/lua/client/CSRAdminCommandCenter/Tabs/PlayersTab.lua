require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "ISUI/ISScrollingListBox"
require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/ClientCommands"
require "CSRAdminCommandCenter/UI/Components/ACC_Draw"

CSR_ACC_PlayersTab = ISPanel:derive("CSR_ACC_PlayersTab")

local ACC = CSRAdminCommandCenter
local Draw = ACC.Draw

function CSR_ACC_PlayersTab:initialise()
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

local function halo(message, r, g, b)
    local p = getPlayer and getPlayer() or nil
    if p and p.setHaloNote then p:setHaloNote(tostring(message or ""), r or 120, g or 220, b or 160, 220) end
end

function CSR_ACC_PlayersTab:createChildren()
    self.searchEntry = ISTextEntryBox:new("", 12, 10, 220, 24)
    self.searchEntry:initialise(); self.searchEntry:instantiate(); Draw.styleEntry(self.searchEntry); self:addChild(self.searchEntry)

    self.searchBtn = ISButton:new(240, 10, 70, 24, "Search", self, CSR_ACC_PlayersTab.onSearch)
    self.searchBtn:initialise(); self.searchBtn:instantiate(); Draw.styleButton(self.searchBtn); self:addChild(self.searchBtn)

    self.refreshBtn = ISButton:new(318, 10, 74, 24, "Refresh", self, CSR_ACC_PlayersTab.onRefresh)
    self.refreshBtn:initialise(); self.refreshBtn:instantiate(); Draw.styleButton(self.refreshBtn); self:addChild(self.refreshBtn)

    self.trackBtn = ISButton:new(400, 10, 86, 24, "Track", self, CSR_ACC_PlayersTab.onTrack)
    self.trackBtn:initialise(); self.trackBtn:instantiate(); Draw.styleButton(self.trackBtn, true); self:addChild(self.trackBtn)

    self.stopBtn = ISButton:new(494, 10, 92, 24, "Stop Track", self, CSR_ACC_PlayersTab.onStopTrack)
    self.stopBtn:initialise(); self.stopBtn:instantiate(); Draw.styleButton(self.stopBtn); self:addChild(self.stopBtn)

    self.mapBtn = ISButton:new(594, 10, 80, 24, "Map", self, CSR_ACC_PlayersTab.onMap)
    self.mapBtn:initialise(); self.mapBtn:instantiate(); Draw.styleButton(self.mapBtn, true); self:addChild(self.mapBtn)

    local detailW = 330
    self.list = ISScrollingListBox:new(12, 44, self.width - detailW - 34, self.height - 58)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = 24
    Draw.styleList(self.list)
    self.list.doDrawItem = CSR_ACC_PlayersTab.drawRow
    self:addChild(self.list)
end

function CSR_ACC_PlayersTab:onSearch()
    ACC.ClientCommands.requestPlayers({ query = entryText(self.searchEntry) })
end

function CSR_ACC_PlayersTab:onRefresh()
    ACC.ClientCommands.requestPlayers({ query = entryText(self.searchEntry) })
end

function CSR_ACC_PlayersTab:selectedRow()
    if not self.list or not self.list.items then return nil end
    local selected = self.list.items[self.list.selected or 0]
    return selected and selected.item or nil
end

function CSR_ACC_PlayersTab:onTrack()
    local row = self:selectedRow()
    if not row or not row.username then halo("Select an online player first", 255, 160, 90); return end
    ACC.ClientCommands.setSelectedPlayer(row)
    ACC.ClientCommands.setPlayerTracked(row.username, true)
end

function CSR_ACC_PlayersTab:onStopTrack()
    local row = self:selectedRow() or ACC.ClientCommands.state.selectedPlayer
    if not row or not row.username then halo("Select a tracked player first", 255, 160, 90); return end
    ACC.ClientCommands.setPlayerTracked(row.username, false)
end

function CSR_ACC_PlayersTab:onMap()
    local row = self:selectedRow()
    if not row or not row.username then halo("Select an online player first", 255, 160, 90); return end
    ACC.ClientCommands.setSelectedPlayer(row)
    halo("Map will follow " .. tostring(row.username), 120, 255, 120)
end

function CSR_ACC_PlayersTab:refreshList()
    local page = ACC.ClientCommands.state.playersPage
    if page == self._lastPage then return end
    self._lastPage = page
    self.list:clear()
    if not page or type(page.rows) ~= "table" then return end
    for i = 1, #page.rows do
        local row = page.rows[i]
        self.list:addItem(tostring(row.username or ""), row)
    end
end

function CSR_ACC_PlayersTab.drawRow(list, y, item, alt)
    local row = item and item.item or {}
    if list.selected == item.index then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.35, 0.18, 0.34, 0.48)
    elseif alt then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.16, 0.16, 0.17, 0.18)
    end
    local text = tostring(row.username or "")
        .. "  " .. tostring(row.access or "")
        .. "  " .. tostring(row.x or 0) .. "," .. tostring(row.y or 0)
        .. (row.inVehicle and ("  vehicle:" .. tostring(row.vehicleScript or row.vehicleId or "")) or "")
        .. (row.tracked and "  [TRACKED]" or "")
    list:drawText(Draw.fitText(text, 92), 6, y + 4, 0.88, 0.90, 0.90, 1, UIFont.Small)
    return y + list.itemheight
end

function CSR_ACC_PlayersTab:prerender()
    ISPanel.prerender(self)
    Draw.background(self, 0, 0, self.width, self.height)
    Draw.neonFrame(self, 0, 0, self.width, self.height)
    self:refreshList()

    local x = self.width - 330
    local y = 48
    Draw.glassPanel(self, x - 8, 42, 318, self.height - 56)
    Draw.section(self, "Selected Player", x, y, 310)
    y = y + 30
    local row = self:selectedRow() or ACC.ClientCommands.state.selectedPlayer
    if not row then
        Draw.text(self, "No player selected", x + 4, y, Draw.colors.muted)
        return
    end

    Draw.labelValue(self, "Username", tostring(row.username or ""), x + 4, y, nil, 100, 28); y = y + 20
    Draw.labelValue(self, "Access", tostring(row.access or ""), x + 4, y, nil, 100, 28); y = y + 20
    Draw.labelValue(self, "SteamID", tostring(row.steamID or ""), x + 4, y, nil, 100, 28); y = y + 20
    Draw.labelValue(self, "Position", tostring(row.x or 0) .. ", " .. tostring(row.y or 0) .. ", " .. tostring(row.z or 0), x + 4, y, nil, 100, 28); y = y + 20
    Draw.labelValue(self, "Tracked", Draw.boolText(row.tracked == true), x + 4, y, Draw.boolColor(row.tracked == true), 100, 28); y = y + 20
    Draw.labelValue(self, "In vehicle", Draw.boolText(row.inVehicle == true), x + 4, y, Draw.boolColor(row.inVehicle == true), 100, 28); y = y + 20
    Draw.labelValue(self, "Vehicle", tostring(row.vehicleScript or row.vehicleId or ""), x + 4, y, nil, 100, 28); y = y + 28

    Draw.section(self, "Last Action", x, y, 310)
    y = y + 30
    Draw.textWrapped(self, tostring(row.lastAction or "No tracked command yet"), x + 4, y, 42, 3, Draw.colors.text)
end

function CSR_ACC_PlayersTab:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    return o
end

return CSR_ACC_PlayersTab
