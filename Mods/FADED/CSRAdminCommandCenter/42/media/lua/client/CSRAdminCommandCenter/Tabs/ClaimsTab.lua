require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "ISUI/ISScrollingListBox"
require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/ClientCommands"
require "CSRAdminCommandCenter/UI/Components/ACC_Draw"

CSR_ACC_ClaimsTab = ISPanel:derive("CSR_ACC_ClaimsTab")

local ACC = CSRAdminCommandCenter
local Draw = ACC.Draw
local DETAIL_W = 330

function CSR_ACC_ClaimsTab:initialise()
    ISPanel.initialise(self)
end

function CSR_ACC_ClaimsTab:createChildren()
    self.kind = "all"
    self.page = 1

    self.searchEntry = ISTextEntryBox:new("", 12, 10, 188, 24)
    self.searchEntry:initialise()
    self.searchEntry:instantiate()
    Draw.styleEntry(self.searchEntry)
    self:addChild(self.searchEntry)

    self.refreshBtn = ISButton:new(208, 10, 58, 24, "Search", self, CSR_ACC_ClaimsTab.onSearch)
    self.refreshBtn:initialise(); self.refreshBtn:instantiate(); Draw.styleButton(self.refreshBtn); self:addChild(self.refreshBtn)

    self.allBtn = ISButton:new(274, 10, 42, 24, "All", self, CSR_ACC_ClaimsTab.onAll)
    self.allBtn:initialise(); self.allBtn:instantiate(); Draw.styleButton(self.allBtn); self:addChild(self.allBtn)

    self.vehicleBtn = ISButton:new(324, 10, 62, 24, "Vehicle", self, CSR_ACC_ClaimsTab.onVehicle)
    self.vehicleBtn:initialise(); self.vehicleBtn:instantiate(); Draw.styleButton(self.vehicleBtn); self:addChild(self.vehicleBtn)

    self.prevBtn = ISButton:new(394, 10, 44, 24, "Prev", self, CSR_ACC_ClaimsTab.onPrev)
    self.prevBtn:initialise(); self.prevBtn:instantiate(); Draw.styleButton(self.prevBtn); self:addChild(self.prevBtn)

    self.nextBtn = ISButton:new(446, 10, 44, 24, "Next", self, CSR_ACC_ClaimsTab.onNext)
    self.nextBtn:initialise(); self.nextBtn:instantiate(); Draw.styleButton(self.nextBtn); self:addChild(self.nextBtn)

    self.trackBtn = ISButton:new(494, 10, 56, 24, "Track", self, CSR_ACC_ClaimsTab.onTrack)
    self.trackBtn:initialise(); self.trackBtn:instantiate(); Draw.styleButton(self.trackBtn, true); self:addChild(self.trackBtn)

    self.mapBtn = ISButton:new(558, 10, 68, 24, "Map", self, CSR_ACC_ClaimsTab.onMap)
    self.mapBtn:initialise(); self.mapBtn:instantiate(); Draw.styleButton(self.mapBtn, true); self:addChild(self.mapBtn)

    self.list = ISScrollingListBox:new(12, 44, self.width - DETAIL_W - 34, self.height - 58)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = 24
    Draw.styleList(self.list)
    self.list.parentPanel = self
    self.list.doDrawItem = CSR_ACC_ClaimsTab.drawRow
    self:addChild(self.list)

    local x = self.width - DETAIL_W
    self.ownerEntry = ISTextEntryBox:new("", x + 8, 340, DETAIL_W - 34, 24)
    self.ownerEntry:initialise(); self.ownerEntry:instantiate(); Draw.styleEntry(self.ownerEntry); self:addChild(self.ownerEntry)

    self.forceOwnerBtn = ISButton:new(x + 8, 370, 148, 24, "Force Owner", self, CSR_ACC_ClaimsTab.onForceOwner)
    self.forceOwnerBtn:initialise(); self.forceOwnerBtn:instantiate(); Draw.styleButton(self.forceOwnerBtn, true); self:addChild(self.forceOwnerBtn)

    self.releaseBtn = ISButton:new(x + 164, 370, 104, 24, "Release", self, CSR_ACC_ClaimsTab.onRelease)
    self.releaseBtn:initialise(); self.releaseBtn:instantiate(); Draw.styleButton(self.releaseBtn); self:addChild(self.releaseBtn)

    self.memberEntry = ISTextEntryBox:new("", x + 8, 434, 172, 24)
    self.memberEntry:initialise(); self.memberEntry:instantiate(); Draw.styleEntry(self.memberEntry); self:addChild(self.memberEntry)

    self.roleEntry = ISTextEntryBox:new("member", x + 188, 434, DETAIL_W - 206, 24)
    self.roleEntry:initialise(); self.roleEntry:instantiate(); Draw.styleEntry(self.roleEntry); self:addChild(self.roleEntry)

    self.addMemberBtn = ISButton:new(x + 8, 464, 124, 24, "Add Member", self, CSR_ACC_ClaimsTab.onAddMember)
    self.addMemberBtn:initialise(); self.addMemberBtn:instantiate(); Draw.styleButton(self.addMemberBtn); self:addChild(self.addMemberBtn)

    self.removeMemberBtn = ISButton:new(x + 140, 464, 148, 24, "Remove Member", self, CSR_ACC_ClaimsTab.onRemoveMember)
    self.removeMemberBtn:initialise(); self.removeMemberBtn:instantiate(); Draw.styleButton(self.removeMemberBtn); self:addChild(self.removeMemberBtn)
end

local function moveControl(control, x, y, w, h)
    if not control then return end
    if control.setX then control:setX(x) else control.x = x end
    if control.setY then control:setY(y) else control.y = y end
    if w and control.setWidth then control:setWidth(w) elseif w then control.width = w end
    if h and control.setHeight then control:setHeight(h) elseif h then control.height = h end
end

function CSR_ACC_ClaimsTab:layoutControls()
    local x = self.width - DETAIL_W
    local fieldW = DETAIL_W - 34
    self._adminSectionY = 282
    self._ownerLabelY = 316
    self._ownerEntryY = 340
    self._ownerButtonY = 370
    self._memberLabelY = 410
    self._memberEntryY = 434
    self._memberButtonY = 464
    self._resultY = 500

    moveControl(self.ownerEntry, x + 8, self._ownerEntryY, fieldW, 24)
    moveControl(self.forceOwnerBtn, x + 8, self._ownerButtonY, 148, 24)
    moveControl(self.releaseBtn, x + 164, self._ownerButtonY, 104, 24)
    moveControl(self.memberEntry, x + 8, self._memberEntryY, 172, 24)
    moveControl(self.roleEntry, x + 188, self._memberEntryY, DETAIL_W - 206, 24)
    moveControl(self.addMemberBtn, x + 8, self._memberButtonY, 124, 24)
    moveControl(self.removeMemberBtn, x + 140, self._memberButtonY, 148, 24)
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

function CSR_ACC_ClaimsTab:request(page)
    self.page = math.max(1, tonumber(page) or self.page or 1)
    ACC.ClientCommands.requestClaims({
        page = self.page,
        kind = self.kind or "all",
        query = entryText(self.searchEntry),
    })
end

function CSR_ACC_ClaimsTab:onSearch() self:request(1) end
function CSR_ACC_ClaimsTab:onAll() self.kind = "all"; self:request(1) end
function CSR_ACC_ClaimsTab:onVehicle() self.kind = "vehicle"; self:request(1) end
function CSR_ACC_ClaimsTab:onPrev() self:request((self.page or 1) - 1) end
function CSR_ACC_ClaimsTab:onNext() self:request((self.page or 1) + 1) end

local function halo(message, r, g, b)
    local p = getPlayer and getPlayer() or nil
    if p and p.setHaloNote then p:setHaloNote(tostring(message or ""), r or 120, g or 220, b or 160, 220) end
end

function CSR_ACC_ClaimsTab:selectedRow()
    if not self.list or not self.list.items then return nil end
    local selected = self.list.items[self.list.selected or 0]
    return selected and selected.item or nil
end

function CSR_ACC_ClaimsTab:onTrack()
    local row = self:selectedRow()
    if row and row.kind == "vehicle" then
        ACC.ClientCommands.setSelectedVehicle(row)
        halo("Tracking vehicle claim #" .. tostring(row.id or "?"), 120, 255, 120)
    else
        halo("Select a vehicle claim first", 255, 160, 90)
    end
end

function CSR_ACC_ClaimsTab:onMap()
    local row = self:selectedRow()
    if row and row.kind == "vehicle" and ACC.UIManager then
        ACC.ClientCommands.setSelectedVehicle(row)
        ACC.UIManager.showMapFor(row)
    else
        halo("Select a vehicle claim first", 255, 160, 90)
    end
end

function CSR_ACC_ClaimsTab:sendAction(action, extra)
    local row = self:selectedRow()
    if not row then
        halo("Select a claim first", 255, 160, 90)
        return
    end
    extra = extra or {}
    extra.action = action
    extra.id = tonumber(row.id) or 0
    extra.page = self.page or 1
    extra.kind = self.kind or "all"
    extra.query = entryText(self.searchEntry)
    ACC.ClientCommands.claimAction(extra)
end

function CSR_ACC_ClaimsTab:onRelease()
    self:sendAction("release")
end

function CSR_ACC_ClaimsTab:onForceOwner()
    self:sendAction("forceOwner", { owner = entryText(self.ownerEntry) })
end

function CSR_ACC_ClaimsTab:onAddMember()
    self:sendAction("addMember", {
        username = entryText(self.memberEntry),
        role = entryText(self.roleEntry),
    })
end

function CSR_ACC_ClaimsTab:onRemoveMember()
    self:sendAction("removeMember", { username = entryText(self.memberEntry) })
end

function CSR_ACC_ClaimsTab:refreshList()
    local page = ACC.ClientCommands.state.claimsPage
    if page == self._lastPage then return end
    self._lastPage = page
    self.list:clear()
    if not page or type(page.rows) ~= "table" then return end
    self.page = tonumber(page.page) or 1
    for i = 1, #page.rows do
        local row = page.rows[i]
        local label = "#" .. tostring(row.id or "?") .. " " .. tostring(row.kind or "")
        self.list:addItem(label, row)
    end
end

function CSR_ACC_ClaimsTab.drawRow(list, y, item, alt)
    local row = item and item.item or {}
    if list.selected == item.index then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.35, 0.18, 0.34, 0.48)
    elseif alt then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.16, 0.16, 0.17, 0.18)
    end
    local text = "#" .. tostring(row.id or "")
        .. "  " .. tostring(row.kind or "")
        .. "  " .. tostring(row.owner or "")
        .. "  " .. tostring(row.title or "")
    list:drawText(Draw.fitText(text, 92), 6, y + 4, 0.88, 0.90, 0.90, 1, UIFont.Small)
    return y + list.itemheight
end

function CSR_ACC_ClaimsTab:prerender()
    ISPanel.prerender(self)
    Draw.background(self, 0, 0, self.width, self.height)
    Draw.neonFrame(self, 0, 0, self.width, self.height)
    self:layoutControls()
    self:refreshList()

    local page = ACC.ClientCommands.state.claimsPage or {}
    local x = self.width - DETAIL_W
    local y = 48
    Draw.glassPanel(self, x - 8, 42, 318, self.height - 56)
    Draw.text(self, "Page " .. tostring(page.page or 1) .. "/" .. tostring(page.totalPages or 1)
        .. "  Rows " .. tostring(page.total or 0), x + 4, self.height - 28, Draw.colors.muted)
    Draw.section(self, "Selected Claim", x, y, 310)
    y = y + 30
    local row = self:selectedRow()
    if not row then
        Draw.text(self, "No row selected", x + 4, y, Draw.colors.muted)
        return
    end
    Draw.labelValue(self, "ID", tostring(row.id or ""), x + 4, y, nil, 96, 28); y = y + 20
    Draw.labelValue(self, "Kind", tostring(row.kind or ""), x + 4, y, nil, 96, 28); y = y + 20
    Draw.labelValue(self, "Owner", tostring(row.owner or ""), x + 4, y, nil, 96, 28); y = y + 20
    Draw.labelValue(self, "Title", tostring(row.title or ""), x + 4, y, nil, 96, 28); y = y + 20
    Draw.labelValue(self, "Vehicle key", tostring(row.vehicleKey or ""), x + 4, y, nil, 96, 28); y = y + 20
    Draw.labelValue(self, "Script", tostring(row.vehicleScript or ""), x + 4, y, nil, 96, 28); y = y + 20
    Draw.labelValue(self, "Last X/Y/Z", tostring(row.lastVehicleX or row.x or 0) .. ", "
        .. tostring(row.lastVehicleY or row.y or 0) .. ", "
        .. tostring(row.lastVehicleZ or row.z or 0), x + 4, y, nil, 96, 28); y = y + 28

    Draw.section(self, "Admin Controls", x, self._adminSectionY, 310)
    Draw.text(self, "New owner username", x + 8, self._ownerLabelY, Draw.colors.muted)
    Draw.text(self, "Member username / role", x + 8, self._memberLabelY, Draw.colors.muted)

    local result = ACC.ClientCommands.state.claimActionResult
    if result and result.message then
        Draw.textWrapped(self, tostring(result.message), x + 8, self._resultY, 38, 2,
            result.ok and Draw.colors.good or Draw.colors.warn)
    end
end

function CSR_ACC_ClaimsTab:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    return o
end

return CSR_ACC_ClaimsTab
