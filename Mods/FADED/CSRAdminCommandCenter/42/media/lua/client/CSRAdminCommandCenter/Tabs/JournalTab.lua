require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "ISUI/ISScrollingListBox"
require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/ClientCommands"
require "CSRAdminCommandCenter/UI/Components/ACC_Draw"

CSR_ACC_JournalTab = ISPanel:derive("CSR_ACC_JournalTab")

local ACC = CSRAdminCommandCenter
local Draw = ACC.Draw

function CSR_ACC_JournalTab:initialise()
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

function CSR_ACC_JournalTab:createChildren()
    self.page = 1

    self.searchEntry = ISTextEntryBox:new("", 12, 10, 180, 24)
    self.searchEntry:initialise(); self.searchEntry:instantiate(); Draw.styleEntry(self.searchEntry); self:addChild(self.searchEntry)

    self.searchBtn = ISButton:new(200, 10, 64, 24, "Search", self, CSR_ACC_JournalTab.onSearch)
    self.searchBtn:initialise(); self.searchBtn:instantiate(); Draw.styleButton(self.searchBtn); self:addChild(self.searchBtn)

    self.refreshBtn = ISButton:new(272, 10, 76, 24, "Refresh", self, CSR_ACC_JournalTab.onRefresh)
    self.refreshBtn:initialise(); self.refreshBtn:instantiate(); Draw.styleButton(self.refreshBtn); self:addChild(self.refreshBtn)

    self.usePlayerBtn = ISButton:new(356, 10, 102, 24, "Use Player", self, CSR_ACC_JournalTab.onUseSelectedPlayer)
    self.usePlayerBtn:initialise(); self.usePlayerBtn:instantiate(); Draw.styleButton(self.usePlayerBtn, true); self:addChild(self.usePlayerBtn)

    self.prevBtn = ISButton:new(466, 10, 48, 24, "Prev", self, CSR_ACC_JournalTab.onPrev)
    self.prevBtn:initialise(); self.prevBtn:instantiate(); Draw.styleButton(self.prevBtn); self:addChild(self.prevBtn)

    self.nextBtn = ISButton:new(522, 10, 48, 24, "Next", self, CSR_ACC_JournalTab.onNext)
    self.nextBtn:initialise(); self.nextBtn:instantiate(); Draw.styleButton(self.nextBtn); self:addChild(self.nextBtn)

    local detailW = 340
    self.list = ISScrollingListBox:new(12, 44, self.width - detailW - 34, self.height - 58)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = 24
    if self.list.setAnchorRight then self.list:setAnchorRight(true) end
    if self.list.setAnchorBottom then self.list:setAnchorBottom(true) end
    Draw.styleList(self.list)
    self.list.doDrawItem = CSR_ACC_JournalTab.drawRow
    self:addChild(self.list)

    local x = self.width - detailW
    self.targetEntry = ISTextEntryBox:new("", x, 284, detailW - 20, 24)
    self.targetEntry:initialise(); self.targetEntry:instantiate(); Draw.styleEntry(self.targetEntry); self:addChild(self.targetEntry)

    self.confirmEntry = ISTextEntryBox:new("", x, 314, detailW - 20, 24)
    self.confirmEntry:initialise(); self.confirmEntry:instantiate(); Draw.styleEntry(self.confirmEntry); self:addChild(self.confirmEntry)

    self.erasePlayerBtn = ISButton:new(x, 346, 292, 24, "Erase Player Journal Data", self, CSR_ACC_JournalTab.onErasePlayer)
    self.erasePlayerBtn:initialise(); self.erasePlayerBtn:instantiate(); Draw.styleButton(self.erasePlayerBtn); self:addChild(self.erasePlayerBtn)

    self.blockUserBtn = ISButton:new(x, 384, 142, 24, "Block User", self, CSR_ACC_JournalTab.onBlockUser)
    self.blockUserBtn:initialise(); self.blockUserBtn:instantiate(); Draw.styleButton(self.blockUserBtn); self:addChild(self.blockUserBtn)

    self.unblockUserBtn = ISButton:new(x + 150, 384, 142, 24, "Unblock User", self, CSR_ACC_JournalTab.onUnblockUser)
    self.unblockUserBtn:initialise(); self.unblockUserBtn:instantiate(); Draw.styleButton(self.unblockUserBtn); self:addChild(self.unblockUserBtn)

    self.perkEntry = ISTextEntryBox:new("", x, 424, detailW - 20, 24)
    self.perkEntry:initialise(); self.perkEntry:instantiate(); Draw.styleEntry(self.perkEntry); self:addChild(self.perkEntry)

    self.blockPerkBtn = ISButton:new(x, 454, 142, 24, "Block Perk", self, CSR_ACC_JournalTab.onBlockPerk)
    self.blockPerkBtn:initialise(); self.blockPerkBtn:instantiate(); Draw.styleButton(self.blockPerkBtn); self:addChild(self.blockPerkBtn)

    self.unblockPerkBtn = ISButton:new(x + 150, 454, 142, 24, "Unblock Perk", self, CSR_ACC_JournalTab.onUnblockPerk)
    self.unblockPerkBtn:initialise(); self.unblockPerkBtn:instantiate(); Draw.styleButton(self.unblockPerkBtn); self:addChild(self.unblockPerkBtn)
end

function CSR_ACC_JournalTab:request(page, force)
    self.page = math.max(1, tonumber(page) or self.page or 1)
    ACC.ClientCommands.requestJournal({
        page = self.page,
        query = entryText(self.searchEntry),
        force = force == true,
    })
end

function CSR_ACC_JournalTab:onSearch() self:request(1, false) end
function CSR_ACC_JournalTab:onRefresh() self:request(1, true) end
function CSR_ACC_JournalTab:onPrev() self:request((self.page or 1) - 1, false) end
function CSR_ACC_JournalTab:onNext() self:request((self.page or 1) + 1, false) end

function CSR_ACC_JournalTab:selectedRow()
    if not self.list or not self.list.items then return nil end
    local selected = self.list.items[self.list.selected or 0]
    return selected and selected.item or nil
end

function CSR_ACC_JournalTab:onUseSelectedPlayer()
    local player = ACC.ClientCommands.state.selectedPlayer
    if not player or not player.username then
        halo("Select a player in Players first", 255, 160, 90)
        return
    end
    setEntry(self.searchEntry, player.username)
    setEntry(self.targetEntry, player.username)
    self:request(1, false)
end

function CSR_ACC_JournalTab:targetFromSelection()
    local target = entryText(self.targetEntry)
    if target ~= "" then return target end
    local row = self:selectedRow() or ACC.ClientCommands.state.selectedJournalRow
    if row and row.userName and row.userName ~= "" then return tostring(row.userName) end
    return ""
end

function CSR_ACC_JournalTab:sendAction(action, extra)
    extra = extra or {}
    local row = self:selectedRow() or ACC.ClientCommands.state.selectedJournalRow
    if row then ACC.ClientCommands.setSelectedJournalRow(row) end
    extra.action = action
    extra.target = extra.target or self:targetFromSelection()
    extra.query = entryText(self.searchEntry)
    extra.page = self.page or 1
    ACC.ClientCommands.journalAction(extra)
end

function CSR_ACC_JournalTab:onClearPenalty()
    halo("CSR does not expose clear-penalty admin", 255, 160, 90)
end

function CSR_ACC_JournalTab:onEraseRow()
    halo("CSR does not expose row-specific erase", 255, 160, 90)
end

function CSR_ACC_JournalTab:onErasePlayer()
    local target = self:targetFromSelection()
    if target == "" then halo("Enter a username first", 255, 160, 90); return end
    self:sendAction("erasePlayerData", {
        target = target,
        confirm = entryText(self.confirmEntry),
    })
end

function CSR_ACC_JournalTab:onBlockUser()
    local target = self:targetFromSelection()
    if target == "" then halo("Enter a username first", 255, 160, 90); return end
    self:sendAction("blacklistUser", { target = target })
end

function CSR_ACC_JournalTab:onUnblockUser()
    local target = self:targetFromSelection()
    if target == "" then halo("Enter a username first", 255, 160, 90); return end
    self:sendAction("unblacklistUser", { target = target })
end

function CSR_ACC_JournalTab:onBlockPerk()
    local perk = entryText(self.perkEntry)
    if perk == "" then halo("Enter a perk type first", 255, 160, 90); return end
    self:sendAction("blacklistPerk", { perk = perk })
end

function CSR_ACC_JournalTab:onUnblockPerk()
    local perk = entryText(self.perkEntry)
    if perk == "" then halo("Enter a perk type first", 255, 160, 90); return end
    self:sendAction("unblacklistPerk", { perk = perk })
end

function CSR_ACC_JournalTab:refreshList()
    local page = ACC.ClientCommands.state.journalPage
    if page == self._lastPage then return end
    self._lastPage = page
    self.list:clear()
    if not page or type(page.rows) ~= "table" then return end
    self.page = tonumber(page.page) or 1
    for i = 1, #page.rows do
        local row = page.rows[i]
        local label = tostring(row.userName or "")
        if label == "" then label = tostring(row.rowKey or "") end
        self.list:addItem(label, row)
    end
end

function CSR_ACC_JournalTab.drawRow(list, y, item, alt)
    local row = item and item.item or {}
    if list.selected == item.index then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.35, 0.18, 0.34, 0.48)
    elseif alt then
        list:drawRect(0, y, list:getWidth(), list.itemheight, 0.16, 0.16, 0.17, 0.18)
    end
    local text = tostring(row.userName or "")
        .. "  steam:" .. tostring(row.steamId or "")
        .. "  prof:" .. tostring(row.profession or "")
        .. "  perks:" .. tostring(row.perks or 0)
        .. "  rec:" .. tostring(row.recipes or 0)
        .. "  media:" .. tostring(row.media or 0)
        .. "  penalty:" .. tostring(row.pendingPenalty or 0)
        .. (row.hasSnapshot and "  [SAVED]" or "")
    list:drawText(Draw.fitText(text, 100), 6, y + 4, 0.88, 0.90, 0.90, 1, UIFont.Small)
    return y + list.itemheight
end

local function csvPreview(tbl, maxRows)
    if type(tbl) ~= "table" or #tbl == 0 then return "None" end
    local out = {}
    maxRows = tonumber(maxRows) or 4
    for i = 1, math.min(maxRows, #tbl) do out[#out + 1] = tostring(tbl[i] or "") end
    local suffix = #tbl > maxRows and (" +" .. tostring(#tbl - maxRows)) or ""
    return table.concat(out, ", ") .. suffix
end

function CSR_ACC_JournalTab:prerender()
    ISPanel.prerender(self)
    Draw.background(self, 0, 0, self.width, self.height)
    Draw.neonFrame(self, 0, 0, self.width, self.height)
    self:refreshList()

    local page = ACC.ClientCommands.state.journalPage or {}
    local store = page.store or {}
    local x = self.width - 340
    local y = 48
    Draw.text(self, "Page " .. tostring(page.page or 1) .. "/" .. tostring(page.totalPages or 1)
        .. "  Rows " .. tostring(page.total or 0), x, 15, Draw.colors.muted)
    Draw.glassPanel(self, x - 8, 42, 328, self.height - 56)

    Draw.section(self, "Journal Store", x, y, 318)
    y = y + 30
    Draw.labelValue(self, "ModData", tostring(page.modDataKey or store.modDataKey or ""), x + 4, y, nil, 92, 28); y = y + 20
    Draw.labelValue(self, "Snapshots", tostring(store.snapshots or 0), x + 4, y, nil, 92, 24); y = y + 20
    Draw.labelValue(self, "User blocks", tostring(store.blacklistUsers or 0), x + 4, y, nil, 92, 24); y = y + 20
    Draw.labelValue(self, "Perk blocks", tostring(store.blacklistPerks or 0), x + 4, y, nil, 92, 24); y = y + 28

    local row = self:selectedRow() or ACC.ClientCommands.state.selectedJournalRow
    Draw.section(self, "Selected Row", x, y, 318)
    y = y + 30
    if not row then
        Draw.text(self, "No journal row selected", x + 4, y, Draw.colors.muted)
        y = y + 84
    else
        Draw.labelValue(self, "Username", tostring(row.userName or ""), x + 4, y, nil, 98, 28); y = y + 20
        Draw.labelValue(self, "SteamID", tostring(row.steamId or ""), x + 4, y, nil, 98, 28); y = y + 20
        Draw.labelValue(self, "Profession", tostring(row.profession or ""), x + 4, y, nil, 98, 26); y = y + 20
        Draw.labelValue(self, "Snapshot", Draw.boolText(row.hasSnapshot == true), x + 4, y, Draw.boolColor(row.hasSnapshot == true), 98, 20); y = y + 20
        Draw.labelValue(self, "Perks/R/M", tostring(row.perks or 0) .. "/" .. tostring(row.recipes or 0) .. "/" .. tostring(row.media or 0),
            x + 4, y, nil, 98, 24); y = y + 20
        Draw.labelValue(self, "Deaths/Pen", tostring(row.deaths or 0) .. "/" .. tostring(row.pendingPenalty or 0), x + 4, y, nil, 98, 24); y = y + 20
        Draw.labelValue(self, "Row key", tostring(row.rowKey or ""), x + 4, y, nil, 98, 24); y = y + 28
    end

    Draw.section(self, "Controls", x, 250, 318)
    Draw.text(self, "Target username", x + 4, 268, Draw.colors.muted)
    Draw.text(self, "Type ERASE before deleting data", x + 4, 338, Draw.colors.bad)

    local result = ACC.ClientCommands.state.journalActionResult
    if result and result.message then
        Draw.textWrapped(self, tostring(result.message), x + 4, 516, 42, 2,
            result.ok and Draw.colors.good or Draw.colors.warn)
    end

    local blacklist = page.blacklist or {}
    Draw.section(self, "Blacklists", x, 552, 318)
    Draw.textWrapped(self, "Users: " .. csvPreview(blacklist.users, 4), x + 4, 580, 44, 2, Draw.colors.muted)
    Draw.textWrapped(self, "Perks: " .. csvPreview(blacklist.perks, 4), x + 4, 612, 44, 2, Draw.colors.muted)
end

function CSR_ACC_JournalTab:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    return o
end

return CSR_ACC_JournalTab
