require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "ISUI/ISScrollingListBox"
require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/ClientCommands"
require "CSRAdminCommandCenter/UI/Components/ACC_Draw"

CSR_ACC_PadlocksTab = ISPanel:derive("CSR_ACC_PadlocksTab")

local ACC = CSRAdminCommandCenter
local Draw = ACC.Draw

function CSR_ACC_PadlocksTab:initialise()
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

function CSR_ACC_PadlocksTab:createChildren()
    self.page = 1
    self.targetKind = "all"

    self.searchEntry = ISTextEntryBox:new("", 12, 10, 170, 24)
    self.searchEntry:initialise(); self.searchEntry:instantiate(); Draw.styleEntry(self.searchEntry); self:addChild(self.searchEntry)

    self.searchBtn = ISButton:new(190, 10, 64, 24, "Search", self, CSR_ACC_PadlocksTab.onSearch)
    self.searchBtn:initialise(); self.searchBtn:instantiate(); Draw.styleButton(self.searchBtn); self:addChild(self.searchBtn)

    self.refreshBtn = ISButton:new(262, 10, 76, 24, "Refresh", self, CSR_ACC_PadlocksTab.onRefresh)
    self.refreshBtn:initialise(); self.refreshBtn:instantiate(); Draw.styleButton(self.refreshBtn); self:addChild(self.refreshBtn)

    self.allBtn = ISButton:new(346, 10, 42, 24, "All", self, CSR_ACC_PadlocksTab.onAll)
    self.allBtn:initialise(); self.allBtn:instantiate(); Draw.styleButton(self.allBtn, true); self:addChild(self.allBtn)

    self.vehicleBtn = ISButton:new(396, 10, 68, 24, "Cars", self, CSR_ACC_PadlocksTab.onVehicles)
    self.vehicleBtn:initialise(); self.vehicleBtn:instantiate(); Draw.styleButton(self.vehicleBtn); self:addChild(self.vehicleBtn)

    self.containerBtn = ISButton:new(472, 10, 86, 24, "Containers", self, CSR_ACC_PadlocksTab.onContainers)
    self.containerBtn:initialise(); self.containerBtn:instantiate(); Draw.styleButton(self.containerBtn); self:addChild(self.containerBtn)

    self.ownerEntry = ISTextEntryBox:new("", 12, 40, 170, 24)
    self.ownerEntry:initialise(); self.ownerEntry:instantiate(); Draw.styleEntry(self.ownerEntry); self:addChild(self.ownerEntry)

    self.ownerBtn = ISButton:new(190, 40, 94, 24, "Owner Filter", self, CSR_ACC_PadlocksTab.onSearch)
    self.ownerBtn:initialise(); self.ownerBtn:instantiate(); Draw.styleButton(self.ownerBtn); self:addChild(self.ownerBtn)

    self.usePlayerBtn = ISButton:new(292, 40, 104, 24, "Use Player", self, CSR_ACC_PadlocksTab.onUseSelectedPlayer)
    self.usePlayerBtn:initialise(); self.usePlayerBtn:instantiate(); Draw.styleButton(self.usePlayerBtn, true); self:addChild(self.usePlayerBtn)

    self.prevBtn = ISButton:new(404, 40, 48, 24, "Prev", self, CSR_ACC_PadlocksTab.onPrev)
    self.prevBtn:initialise(); self.prevBtn:instantiate(); Draw.styleButton(self.prevBtn); self:addChild(self.prevBtn)

    self.nextBtn = ISButton:new(460, 40, 48, 24, "Next", self, CSR_ACC_PadlocksTab.onNext)
    self.nextBtn:initialise(); self.nextBtn:instantiate(); Draw.styleButton(self.nextBtn); self:addChild(self.nextBtn)

    self.mapBtn = ISButton:new(516, 40, 66, 24, "Track", self, CSR_ACC_PadlocksTab.onTrack)
    self.mapBtn:initialise(); self.mapBtn:instantiate(); Draw.styleButton(self.mapBtn, true); self:addChild(self.mapBtn)

    local detailW = 330
    self.list = ISScrollingListBox:new(12, 74, self.width - detailW - 34, self.height - 88)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = 24
    if self.list.setAnchorRight then self.list:setAnchorRight(true) end
    if self.list.setAnchorBottom then self.list:setAnchorBottom(true) end
    Draw.styleList(self.list)
    self.list.doDrawItem = CSR_ACC_PadlocksTab.drawRow
    self:addChild(self.list)

    local x = self.width - detailW
    self.removeBtn = ISButton:new(x, 334, 128, 24, "Remove Lock", self, CSR_ACC_PadlocksTab.onRemove)
    self.removeBtn:initialise(); self.removeBtn:instantiate(); Draw.styleButton(self.removeBtn); self:addChild(self.removeBtn)
end

function CSR_ACC_PadlocksTab:request(page, force)
    self.page = math.max(1, tonumber(page) or self.page or 1)
    ACC.ClientCommands.requestPadlocks({
        page = self.page,
        query = entryText(self.searchEntry),
        owner = entryText(self.ownerEntry),
        targetKind = self.targetKind or "all",
        force = force == true,
    })
end

function CSR_ACC_PadlocksTab:onSearch() self:request(1, false) end
function CSR_ACC_PadlocksTab:onRefresh() self:request(1, true) end
function CSR_ACC_PadlocksTab:onPrev() self:request((self.page or 1) - 1, false) end
function CSR_ACC_PadlocksTab:onNext() self:request((self.page or 1) + 1, false) end

function CSR_ACC_PadlocksTab:onAll()
    self.targetKind = "all"
    Draw.styleButton(self.allBtn, true); Draw.styleButton(self.vehicleBtn, false); Draw.styleButton(self.containerBtn, false)
    self:request(1, false)
end

function CSR_ACC_PadlocksTab:onVehicles()
    self.targetKind = "vehicle"
    Draw.styleButton(self.allBtn, false); Draw.styleButton(self.vehicleBtn, true); Draw.styleButton(self.containerBtn, false)
    self:request(1, false)
end

function CSR_ACC_PadlocksTab:onContainers()
    self.targetKind = "container"
    Draw.styleButton(self.allBtn, false); Draw.styleButton(self.vehicleBtn, false); Draw.styleButton(self.containerBtn, true)
    self:request(1, false)
end

function CSR_ACC_PadlocksTab:onUseSelectedPlayer()
    local player = ACC.ClientCommands.state.selectedPlayer
    if not player or not player.username then
        halo("Select a player in Players first", 255, 160, 90)
        return
    end
    setEntry(self.ownerEntry, player.username)
    self:request(1, false)
end

function CSR_ACC_PadlocksTab:selectedRow()
    if not self.list or not self.list.items then return nil end
    local selected = self.list.items[self.list.selected or 0]
    return selected and selected.item or nil
end

function CSR_ACC_PadlocksTab:onTrack()
    local row = self:selectedRow()
    if not row then halo("Select a padlock first", 255, 160, 90); return end
    ACC.ClientCommands.setSelectedPadlock(row)
    halo("Map target set to padlock", 120, 255, 120)
end

function CSR_ACC_PadlocksTab:sendAction(action, username)
    local row = self:selectedRow()
    if not row then halo("Select a padlock first", 255, 160, 90); return end
    ACC.ClientCommands.setSelectedPadlock(row)
    ACC.ClientCommands.padlockAction({
        action = action,
        targetKey = tostring(row.targetKey or ""),
        username = username or "",
        page = self.page or 1,
        query = entryText(self.searchEntry),
        owner = entryText(self.ownerEntry),
        targetKind = self.targetKind or "all",
    })
end

function CSR_ACC_PadlocksTab:onGiveKey()
    halo("CSR does not expose padlock key grants", 255, 160, 90)
end

function CSR_ACC_PadlocksTab:onSetOwner()
    halo("CSR does not expose padlock owner rewrites", 255, 160, 90)
end

function CSR_ACC_PadlocksTab:onRemove()
    self:sendAction("remove")
end

function CSR_ACC_PadlocksTab:refreshList()
    local page = ACC.ClientCommands.state.padlocksPage
    if page == self._lastPage then return end
    self._lastPage = page
    self.list:clear()
    if not page or type(page.rows) ~= "table" then return end
    self.page = tonumber(page.page) or 1
    for i = 1, #page.rows do
        local row = page.rows[i]
        self.list:addItem("#" .. tostring(row.claimId or "?") .. " " .. tostring(row.targetKind or ""), row)
    end
end

function CSR_ACC_PadlocksTab.drawRow(list, y, item, alt)
    local row = item and item.item or {}
    if list.selected == item.index then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.35, 0.18, 0.34, 0.48)
    elseif alt then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.16, 0.16, 0.17, 0.18)
    end
    local text = tostring(row.targetKind or "")
        .. "  claim #" .. tostring(row.claimId or "")
        .. "  owner:" .. tostring(row.claimOwner or "")
        .. "  lock:" .. tostring(row.padlockOwner or "")
        .. "  " .. tostring(row.objectName or row.vehicleScript or "")
        .. "  " .. tostring(row.x or 0) .. "," .. tostring(row.y or 0)
    list:drawText(Draw.fitText(text, 92), 6, y + 4, 0.88, 0.90, 0.90, 1, UIFont.Small)
    return y + list.itemheight
end

function CSR_ACC_PadlocksTab:prerender()
    ISPanel.prerender(self)
    Draw.background(self, 0, 0, self.width, self.height)
    Draw.neonFrame(self, 0, 0, self.width, self.height)
    self:refreshList()

    local page = ACC.ClientCommands.state.padlocksPage or {}
    local x = self.width - 330
    local y = 48
    Draw.text(self, "Page " .. tostring(page.page or 1) .. "/" .. tostring(page.totalPages or 1)
        .. "  Rows " .. tostring(page.total or 0), x, 15, Draw.colors.muted)
    Draw.glassPanel(self, x - 8, 42, 318, self.height - 56)
    Draw.section(self, "Selected Padlock", x, y, 310)
    y = y + 30

    local row = self:selectedRow() or ACC.ClientCommands.state.selectedPadlock
    if not row then
        Draw.text(self, "No padlock selected", x + 4, y, Draw.colors.muted)
        return
    end

    Draw.labelValue(self, "Target", tostring(row.targetKind or ""), x + 4, y, nil, 98, 28); y = y + 20
    Draw.labelValue(self, "Claim", "#" .. tostring(row.claimId or ""), x + 4, y, nil, 98, 28); y = y + 20
    Draw.labelValue(self, "Claim owner", tostring(row.claimOwner or ""), x + 4, y, nil, 98, 28); y = y + 20
    Draw.labelValue(self, "Lock owner", tostring(row.padlockOwner or ""), x + 4, y, nil, 98, 28); y = y + 20
    Draw.labelValue(self, "Object", tostring(row.objectName or row.vehicleScript or ""), x + 4, y, nil, 98, 30); y = y + 20
    Draw.labelValue(self, "Lock type", tostring(row.lockType or ""), x + 4, y, nil, 98, 30); y = y + 20
    Draw.labelValue(self, "Key tail", tostring(row.keyTail or ""), x + 4, y, nil, 98, 16); y = y + 20
    Draw.labelValue(self, "X/Y/Z", tostring(row.x or 0) .. ", " .. tostring(row.y or 0) .. ", " .. tostring(row.z or 0),
        x + 4, y, nil, 98, 28); y = y + 28

    Draw.section(self, "Command Controls", x, y, 310)
    y = y + 30
    Draw.textWrapped(self, "Remove Lock requests CSR's padlock removal handler. ACC does not rewrite padlock owners or create keys.",
        x + 4, y, 38, 3, Draw.colors.text)
    y = y + 64

    local result = ACC.ClientCommands.state.padlockActionResult
    if result and result.message then
        Draw.textWrapped(self, tostring(result.message), x + 4, y, 40, 2,
            result.ok and Draw.colors.good or Draw.colors.warn)
    end
end

function CSR_ACC_PadlocksTab:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    return o
end

return CSR_ACC_PadlocksTab
