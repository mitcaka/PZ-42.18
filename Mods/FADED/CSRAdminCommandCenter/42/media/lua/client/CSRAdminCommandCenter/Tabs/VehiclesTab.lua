require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "ISUI/ISScrollingListBox"
require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/ClientCommands"
require "CSRAdminCommandCenter/UI/Components/ACC_Draw"

CSR_ACC_VehiclesTab = ISPanel:derive("CSR_ACC_VehiclesTab")

local ACC = CSRAdminCommandCenter
local Draw = ACC.Draw
local DETAIL_W = 330

function CSR_ACC_VehiclesTab:initialise()
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

local function halo(message, r, g, b)
    local p = getPlayer and getPlayer() or nil
    if p and p.setHaloNote then p:setHaloNote(tostring(message or ""), r or 120, g or 220, b or 160, 220) end
end

function CSR_ACC_VehiclesTab:createChildren()
    self.page = 1

    self.searchEntry = ISTextEntryBox:new("", 12, 10, 170, 24)
    self.searchEntry:initialise(); self.searchEntry:instantiate(); Draw.styleEntry(self.searchEntry); self:addChild(self.searchEntry)

    self.searchBtn = ISButton:new(190, 10, 64, 24, "Search", self, CSR_ACC_VehiclesTab.onSearch)
    self.searchBtn:initialise(); self.searchBtn:instantiate(); Draw.styleButton(self.searchBtn); self:addChild(self.searchBtn)

    self.refreshBtn = ISButton:new(262, 10, 76, 24, "Refresh", self, CSR_ACC_VehiclesTab.onRefresh)
    self.refreshBtn:initialise(); self.refreshBtn:instantiate(); Draw.styleButton(self.refreshBtn); self:addChild(self.refreshBtn)

    self.ownerEntry = ISTextEntryBox:new("", 346, 10, 150, 24)
    self.ownerEntry:initialise(); self.ownerEntry:instantiate(); Draw.styleEntry(self.ownerEntry); self:addChild(self.ownerEntry)

    self.usePlayerBtn = ISButton:new(504, 10, 104, 24, "Use Player", self, CSR_ACC_VehiclesTab.onUseSelectedPlayer)
    self.usePlayerBtn:initialise(); self.usePlayerBtn:instantiate(); Draw.styleButton(self.usePlayerBtn, true); self:addChild(self.usePlayerBtn)

    self.prevBtn = ISButton:new(12, 40, 48, 24, "Prev", self, CSR_ACC_VehiclesTab.onPrev)
    self.prevBtn:initialise(); self.prevBtn:instantiate(); Draw.styleButton(self.prevBtn); self:addChild(self.prevBtn)

    self.nextBtn = ISButton:new(68, 40, 48, 24, "Next", self, CSR_ACC_VehiclesTab.onNext)
    self.nextBtn:initialise(); self.nextBtn:instantiate(); Draw.styleButton(self.nextBtn); self:addChild(self.nextBtn)

    self.trackBtn = ISButton:new(124, 40, 70, 24, "Track", self, CSR_ACC_VehiclesTab.onTrack)
    self.trackBtn:initialise(); self.trackBtn:instantiate(); Draw.styleButton(self.trackBtn, true); self:addChild(self.trackBtn)

    self.mapBtn = ISButton:new(202, 40, 86, 24, "Open Map", self, CSR_ACC_VehiclesTab.onMap)
    self.mapBtn:initialise(); self.mapBtn:instantiate(); Draw.styleButton(self.mapBtn, true); self:addChild(self.mapBtn)

    self.list = ISScrollingListBox:new(12, 74, self.width - DETAIL_W - 34, self.height - 88)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = 24
    if self.list.setAnchorRight then self.list:setAnchorRight(true) end
    if self.list.setAnchorBottom then self.list:setAnchorBottom(true) end
    Draw.styleList(self.list)
    self.list.doDrawItem = CSR_ACC_VehiclesTab.drawRow
    self:addChild(self.list)

    local x = self.width - DETAIL_W
    self.forceOwnerEntry = ISTextEntryBox:new("", x + 8, 430, DETAIL_W - 34, 24)
    self.forceOwnerEntry:initialise(); self.forceOwnerEntry:instantiate(); Draw.styleEntry(self.forceOwnerEntry); self:addChild(self.forceOwnerEntry)

    self.forceOwnerBtn = ISButton:new(x + 8, 460, 132, 24, "Force Owner", self, CSR_ACC_VehiclesTab.onForceOwner)
    self.forceOwnerBtn:initialise(); self.forceOwnerBtn:instantiate(); Draw.styleButton(self.forceOwnerBtn, true); self:addChild(self.forceOwnerBtn)

    self.releaseBtn = ISButton:new(x + 148, 460, 108, 24, "Release", self, CSR_ACC_VehiclesTab.onRelease)
    self.releaseBtn:initialise(); self.releaseBtn:instantiate(); Draw.styleButton(self.releaseBtn); self:addChild(self.releaseBtn)
end

local function moveControl(control, x, y, w, h)
    if not control then return end
    if control.setX then control:setX(x) else control.x = x end
    if control.setY then control:setY(y) else control.y = y end
    if w and control.setWidth then control:setWidth(w) elseif w then control.width = w end
    if h and control.setHeight then control:setHeight(h) elseif h then control.height = h end
end

function CSR_ACC_VehiclesTab:layoutControls()
    local x = self.width - DETAIL_W
    self._adminSectionY = 372
    self._ownerLabelY = 406
    self._ownerEntryY = 430
    self._ownerButtonY = 460
    self._resultY = 500
    moveControl(self.forceOwnerEntry, x + 8, self._ownerEntryY, DETAIL_W - 34, 24)
    moveControl(self.forceOwnerBtn, x + 8, self._ownerButtonY, 132, 24)
    moveControl(self.releaseBtn, x + 148, self._ownerButtonY, 108, 24)
end

function CSR_ACC_VehiclesTab:request(page)
    self.page = math.max(1, tonumber(page) or self.page or 1)
    ACC.ClientCommands.requestClaims({
        page = self.page,
        kind = "vehicle",
        query = entryText(self.searchEntry),
        owner = entryText(self.ownerEntry),
    })
end

function CSR_ACC_VehiclesTab:onSearch() self:request(1) end
function CSR_ACC_VehiclesTab:onRefresh() self:request(1) end
function CSR_ACC_VehiclesTab:onPrev() self:request((self.page or 1) - 1) end
function CSR_ACC_VehiclesTab:onNext() self:request((self.page or 1) + 1) end

function CSR_ACC_VehiclesTab:onUseSelectedPlayer()
    local row = ACC.ClientCommands.state.selectedPlayer
    if not row or not row.username then
        halo("Select a player in Players first", 255, 160, 90)
        return
    end
    setEntry(self.ownerEntry, row.username)
    setEntry(self.forceOwnerEntry, row.username)
    self:request(1)
end

function CSR_ACC_VehiclesTab:selectedRow()
    if not self.list or not self.list.items then return nil end
    local selected = self.list.items[self.list.selected or 0]
    return selected and selected.item or nil
end

function CSR_ACC_VehiclesTab:onTrack()
    local row = self:selectedRow()
    if not row then halo("Select a vehicle claim first", 255, 160, 90); return end
    ACC.ClientCommands.setSelectedVehicle(row)
    halo("Tracking vehicle claim #" .. tostring(row.id or "?"), 120, 255, 120)
end

function CSR_ACC_VehiclesTab:onMap()
    local row = self:selectedRow()
    if not row then halo("Select a vehicle claim first", 255, 160, 90); return end
    ACC.ClientCommands.setSelectedVehicle(row)
    if ACC.UIManager then ACC.UIManager.showMapFor(row) end
end

function CSR_ACC_VehiclesTab:sendAction(action, extra)
    local row = self:selectedRow()
    if not row then halo("Select a vehicle claim first", 255, 160, 90); return end
    extra = extra or {}
    extra.action = action
    extra.id = tonumber(row.id) or 0
    extra.page = self.page or 1
    extra.kind = "vehicle"
    extra.query = entryText(self.searchEntry)
    extra.owner = entryText(self.ownerEntry)
    ACC.ClientCommands.claimAction(extra)
end

function CSR_ACC_VehiclesTab:onForceOwner()
    self:sendAction("forceOwner", { owner = entryText(self.forceOwnerEntry) })
end

function CSR_ACC_VehiclesTab:onRelease()
    self:sendAction("release")
end

function CSR_ACC_VehiclesTab:refreshList()
    local page = ACC.ClientCommands.state.claimsPage
    if page == self._lastPage then return end
    self._lastPage = page
    self.list:clear()
    if not page or type(page.rows) ~= "table" then return end
    self.page = tonumber(page.page) or 1
    for i = 1, #page.rows do
        local row = page.rows[i]
        if row.kind == "vehicle" then self.list:addItem("#" .. tostring(row.id or "?"), row) end
    end
end

function CSR_ACC_VehiclesTab.drawRow(list, y, item, alt)
    local row = item and item.item or {}
    if list.selected == item.index then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.35, 0.18, 0.34, 0.48)
    elseif alt then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.16, 0.16, 0.17, 0.18)
    end
    local text = "#" .. tostring(row.id or "")
        .. "  " .. tostring(row.owner or "")
        .. "  " .. tostring(row.vehicleScript or row.title or "")
        .. "  key:" .. tostring(row.vehicleKey or "")
        .. "  " .. tostring(row.lastVehicleX or row.x or 0) .. "," .. tostring(row.lastVehicleY or row.y or 0)
    list:drawText(Draw.fitText(text, 92), 6, y + 4, 0.88, 0.90, 0.90, 1, UIFont.Small)
    return y + list.itemheight
end

function CSR_ACC_VehiclesTab:prerender()
    ISPanel.prerender(self)
    Draw.background(self, 0, 0, self.width, self.height)
    Draw.neonFrame(self, 0, 0, self.width, self.height)
    self:layoutControls()
    self:refreshList()

    local page = ACC.ClientCommands.state.claimsPage or {}
    local snapshot = ACC.ClientCommands.state.snapshot or {}
    local padlocks = snapshot.padlocks or {}
    local x = self.width - DETAIL_W
    local y = 48
    Draw.glassPanel(self, x - 8, 42, 318, self.height - 56)
    Draw.text(self, "Page " .. tostring(page.page or 1) .. "/" .. tostring(page.totalPages or 1)
        .. "  Rows " .. tostring(page.total or 0), x + 4, self.height - 28, Draw.colors.muted)
    Draw.section(self, "Selected Vehicle", x, y, 310)
    y = y + 30
    local row = self:selectedRow() or ACC.ClientCommands.state.selectedVehicle
    if not row then
        Draw.textWrapped(self, "Select a row. To inspect a player's vehicles, select them in Players, then press Use Player here.",
            x + 4, y, 40, 4, Draw.colors.muted)
        return
    end

    Draw.labelValue(self, "Claim ID", tostring(row.id or ""), x + 4, y, nil, 100, 28); y = y + 20
    Draw.labelValue(self, "Owner", tostring(row.owner or ""), x + 4, y, nil, 100, 28); y = y + 20
    Draw.labelValue(self, "Title", tostring(row.title or ""), x + 4, y, nil, 100, 28); y = y + 20
    Draw.labelValue(self, "Script", tostring(row.vehicleScript or ""), x + 4, y, nil, 100, 28); y = y + 20
    Draw.labelValue(self, "Vehicle key", tostring(row.vehicleKey or ""), x + 4, y, nil, 100, 28); y = y + 20
    Draw.labelValue(self, "Last X/Y/Z", tostring(row.lastVehicleX or row.x or 0) .. ", "
        .. tostring(row.lastVehicleY or row.y or 0) .. ", "
        .. tostring(row.lastVehicleZ or row.z or 0), x + 4, y, nil, 100, 28); y = y + 28

    Draw.section(self, "Tracking", x, y, 310)
    y = y + 30
    Draw.labelValue(self, "Vehicle locks", tostring(padlocks.vehicle or 0), x + 4, y, nil, 100, 28); y = y + 20
    Draw.labelValue(self, "Movement", Draw.boolText(ACC.sandbox().EnableVehicleMovementTracking == true),
        x + 4, y, Draw.boolColor(ACC.sandbox().EnableVehicleMovementTracking == true), 100, 28); y = y + 20
    Draw.labelValue(self, "Interval", tostring(ACC.sandbox().VehicleTrackingIntervalMinutes or 5) .. " minutes",
        x + 4, y, nil, 100, 28); y = y + 28

    Draw.section(self, "Admin Controls", x, self._adminSectionY, 310)
    Draw.text(self, "New owner username", x + 8, self._ownerLabelY, Draw.colors.muted)
    local result = ACC.ClientCommands.state.claimActionResult
    if result and result.message then
        Draw.textWrapped(self, tostring(result.message), x + 8, self._resultY, 38, 2,
            result.ok and Draw.colors.good or Draw.colors.warn)
    end
end

function CSR_ACC_VehiclesTab:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    return o
end

return CSR_ACC_VehiclesTab
