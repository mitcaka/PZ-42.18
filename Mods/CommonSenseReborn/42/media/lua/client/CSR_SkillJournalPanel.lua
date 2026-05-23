--[[
    CSR_SkillJournalPanel.lua  --  client UI for the Skill Journal feature.

    Click the "Journal" button on the Utility HUD to toggle this panel.
    The panel queries the server for a state snapshot, lists every saved
    perk versus the current value, and exposes Save / Recover buttons.

    No per-tick cost when closed. All work happens on user click +
    server-pushed state.
]]

require "ISUI/ISCollapsableWindow"
require "CSR_FeatureFlags"
require "CSR_SkillJournal"

CSR_SkillJournalPanel = CSR_SkillJournalPanel or {}
local UI = CSR_SkillJournalPanel

local Win = ISCollapsableWindow:derive("CSR_SkillJournalWindow")
UI.Win = Win

local PANEL_W = 460
local PANEL_H = 560
local ROW_H   = 18

-- Amber-brown Skill Journal theme.
local BORDER_R, BORDER_G, BORDER_B = 0.86, 0.54, 0.20
local BORDER_DARK_R, BORDER_DARK_G, BORDER_DARK_B = 0.42, 0.24, 0.10
local BG_R, BG_G, BG_B, BG_A = 0.11, 0.075, 0.045, 0.94
local ROW_ALT_R, ROW_ALT_G, ROW_ALT_B = 0.22, 0.14, 0.07
local TEXT_R, TEXT_G, TEXT_B = 0.96, 0.86, 0.68
local MUTED_R, MUTED_G, MUTED_B = 0.74, 0.62, 0.45

local function styleButton(button, active)
    if not button then return end
    local bgBoost = active and 0.08 or 0
    button.backgroundColor = {
        r = 0.20 + bgBoost,
        g = 0.13 + bgBoost,
        b = 0.07,
        a = 1.0,
    }
    button.backgroundColorMouseOver = {
        r = 0.34,
        g = 0.22,
        b = 0.10,
        a = 1.0,
    }
    button.borderColor = {
        r = active and BORDER_R or 0.58,
        g = active and BORDER_G or 0.36,
        b = active and BORDER_B or 0.18,
        a = 1.0,
    }
end

local function getJournalTexture()
    if Win._journalTex ~= nil then return Win._journalTex end
    local tex = getTexture("media/ui/CSR_Journal.png")
    Win._journalTex = tex or false
    return Win._journalTex
end

function Win:new(x, y, w, h)
    local o = ISCollapsableWindow:new(x, y, w, h)
    setmetatable(o, self); self.__index = self
    o:setResizable(false)
    o.title = getText("IGUI_CSR_SkillJournalTitle")
    o.state = nil          -- last server state
    o.statusText = "Loading..."
    return o
end

function Win:initialise()
    ISCollapsableWindow.initialise(self)
end

function Win:createChildren()
    ISCollapsableWindow.createChildren(self)

    local th = self:titleBarHeight()
    local pad = 8
    local btnW = 110
    local btnH = 22

    self.saveBtn = ISButton:new(pad, th + pad, btnW, btnH, getText("IGUI_CSR_SkillSaveSnapshot") or "Save Snapshot", self, Win.onSave)
    self.saveBtn:initialise(); self.saveBtn:instantiate()
    self.saveBtn:setTooltip(getText("Tooltip_CSR_SkillJournalSave"))
    self:addChild(self.saveBtn)
    styleButton(self.saveBtn, true)

    self.recoverBtn = ISButton:new(pad + btnW + 6, th + pad, btnW, btnH, getText("IGUI_CSR_SkillRecover"), self, Win.onRecover)
    self.recoverBtn:initialise(); self.recoverBtn:instantiate()
    self.recoverBtn:setTooltip(getText("Tooltip_CSR_SkillJournalRecover"))
    self:addChild(self.recoverBtn)
    styleButton(self.recoverBtn, true)

    self.refreshBtn = ISButton:new(self.width - pad - 70, th + pad, 70, btnH, getText("IGUI_CSR_SkillRefresh"), self, Win.onRefresh)
    self.refreshBtn:initialise(); self.refreshBtn:instantiate()
    self:addChild(self.refreshBtn)
    styleButton(self.refreshBtn, false)

    -- Admin-only blacklist button.  Hidden for non-admins.
    self.blacklistBtn = ISButton:new(self.width - pad - 70 - 100 - 6, th + pad, 100, btnH,
        "Blacklist...", self, Win.onOpenBlacklist)
    self.blacklistBtn:initialise(); self.blacklistBtn:instantiate()
    self.blacklistBtn:setTooltip("Admin only: ban specific usernames or perks from the Skill Journal.")
    self:addChild(self.blacklistBtn)
    styleButton(self.blacklistBtn, false)
    self.blacklistBtn:setVisible(false)  -- shown after first state push if admin

    -- Scrolling perk list
    self.list = ISScrollingListBox:new(pad, th + pad + btnH + 8,
        self.width - pad * 2, self.height - (th + pad + btnH + 8 + 80))
    self.list:initialise(); self.list:instantiate()
    self.list.itemheight = ROW_H
    self.list.selected = 0
    self.list.joypadParent = self
    self.list.font = UIFont.Small
    self.list.doDrawItem = Win.drawListItem
    self.list.drawBorder = true
    self.list.backgroundColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.0 }
    self:addChild(self.list)
end

function Win:onClose()
    self:setVisible(false)
end

function Win:requestState()
    self.statusText = "Loading..."
    if isClient() then
        sendClientCommand(getPlayer(), "CommonSenseReborn", CSR_SkillJournal.CMD_GET, {})
    else
        if CSR_SkillJournalServer and CSR_SkillJournalServer.handleGet then
            -- SP path: invoke locally and consume via shared handler.
            CSR_SkillJournalServer.handleGet(getPlayer(), {})
        end
    end
end

function Win:applyState(state)
    self.state = state or {}
    self:rebuildList()
    -- Reveal admin-only blacklist button
    if self.blacklistBtn then
        local plr = getPlayer()
        local lvl = plr and plr.getAccessLevel and tostring(plr:getAccessLevel() or "") or ""
        local isAdmin = (lvl == "Admin" or lvl == "Moderator" or lvl == "GM" or lvl == "Overseer")
        self.blacklistBtn:setVisible(isAdmin)
    end
end

function Win:rebuildList()
    self.list:clear()
    if not self.state then return end
    local perks = self.state.perks or {}
    local plr = getPlayer()
    local rows = {}
    if PerkFactory and PerkFactory.PerkList and PerkFactory.PerkList.size then
        local list = PerkFactory.PerkList
        for i = 0, list:size() - 1 do
            local perk = list:get(i)
            if perk then
                local typeStr = perk.getType and tostring(perk:getType()) or nil
                local parent = perk.getParent and perk:getParent() or nil
                if typeStr and parent and tostring(parent) ~= "None" and typeStr ~= "None" then
                    local snap = perks[typeStr]
                    local cur = 0
                    if plr and plr.getPerkLevel then
                        cur = plr:getPerkLevel(perk) or 0
                    end
                    if (snap and (snap.lvl or 0) > 0) or cur > 0 then
                        local name = perk.getName and tostring(perk:getName()) or typeStr
                        table.insert(rows, {
                            name = name,
                            snapLvl = snap and (snap.lvl or 0) or 0,
                            curLvl  = cur,
                        })
                    end
                end
            end
        end
    end
    table.sort(rows, function(a, b) return a.name < b.name end)
    for _, r in ipairs(rows) do
        self.list:addItem(r.name, r)
    end
end

function Win.drawListItem(self, y, item, alt)
    local r = item.item
    if not r then return y + self.itemheight end
    local h = self.itemheight
    if alt then
        self:drawRect(0, y, self.width, h, 0.18, ROW_ALT_R, ROW_ALT_G, ROW_ALT_B)
    end
    self:drawText(r.name, 6, y + 2, TEXT_R, TEXT_G, TEXT_B, 1, UIFont.Small)
    -- Snapshot vs current
    local snapStr = "Snap: " .. tostring(r.snapLvl)
    local curStr  = "Now: " .. tostring(r.curLvl)
    local diff = r.snapLvl - r.curLvl
    local rC, gC, bC = 0.70, 0.58, 0.36
    if diff > 0 then rC, gC, bC = 0.98, 0.66, 0.24 end
    self:drawText(snapStr, self.width - 200, y + 2, rC, gC, bC, 1, UIFont.Small)
    self:drawText(curStr, self.width - 90, y + 2, MUTED_R, MUTED_G, MUTED_B, 1, UIFont.Small)
    return y + h
end

function Win:prerender()
    -- Draw our themed background BEFORE the vanilla collapsable window so
    -- the title bar still renders on top.  We replace the default
    -- backgroundColor to make the watermark visible.
    self.backgroundColor = self.backgroundColor or {}
    self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b, self.backgroundColor.a = BG_R, BG_G, BG_B, BG_A
    ISCollapsableWindow.prerender(self)

    -- Journal watermark behind the perk list area.
    local tex = getJournalTexture()
    if tex then
        local th = self:titleBarHeight()
        local listY = th + 8 + 22 + 8
        local listH = self.height - listY - 70
        local size = math.min(listH, self.width - 16)
        if size > 64 then
            local x = (self.width - size) / 2
            local y = listY + (listH - size) / 2
            self:drawTextureScaled(tex, x, y, size, size, 0.12, BORDER_R, BORDER_G, BORDER_B)
        end
    end

    if not self._kicked then
        self._kicked = true
        self:requestState()
    end
end

function Win:render()
    ISCollapsableWindow.render(self)
    -- Amber-brown frame on top of everything.
    self:drawRectBorder(0, 0, self.width, self.height, 1.0, BORDER_R, BORDER_G, BORDER_B)
    self:drawRectBorder(1, 1, self.width - 2, self.height - 2, 0.65,
        BORDER_DARK_R, BORDER_DARK_G, BORDER_DARK_B)

    -- Footer status text.
    local s = self.state or {}
    local lines = {}
    if s.hasSnapshot then
        table.insert(lines, string.format("Snapshot: %d perks  /  %d recipes  /  %d magazines",
            self:countTbl(s.perks), s.recipes or 0, s.media or 0))
        local profStr = (s.profession ~= nil and s.profession ~= "") and s.profession or "(none)"
        table.insert(lines, string.format("Profession lock: %s  |  deaths since save: %d  |  pending penalty: -%d lvl",
            profStr, s.deaths or 0, s.pendingPenalty or 0))
        table.insert(lines, string.format("Death penalty setting: -%d lvl per death.",
            s.deathPenalty or 0))
        -- Real-world cooldown remaining.
        local realCD = tonumber(s.realCooldown) or 0
        if realCD > 0 and s.lastWriteRealMs and s.lastWriteRealMs > 0 and s.nowMs then
            local elapsedH = (s.nowMs - s.lastWriteRealMs) / 3600000.0
            local rem = realCD - elapsedH
            if rem > 0 then
                table.insert(lines, string.format("Next save unlocks in %.1f real-world hour(s).", rem))
            else
                table.insert(lines, "Save available now.")
            end
        end
    else
        table.insert(lines, getText("IGUI_CSR_SkillJournal_NoSnapshot"))
        table.insert(lines, string.format("Min play-time gate: %d in-game hours.", s.minHours or 0))
        if s.professionLock and s.currentProfession and s.currentProfession ~= "" then
            table.insert(lines, string.format("Your profession will be locked to: %s", s.currentProfession))
        end
    end
    table.insert(lines, self.statusText or "")
    local footerY = self.height - (#lines * 14) - 8
    for i, line in ipairs(lines) do
        self:drawText(line, 10, footerY + (i - 1) * 14, TEXT_R, TEXT_G, TEXT_B, 1, UIFont.Small)
    end
end

function Win:countTbl(t)
    if not t then return 0 end
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

function Win:onSave()
    self.statusText = "Saving..."
    if isClient() then
        sendClientCommand(getPlayer(), "CommonSenseReborn", CSR_SkillJournal.CMD_SAVE, {})
    elseif CSR_SkillJournalServer then
        CSR_SkillJournalServer.handleSave(getPlayer(), {})
    end
end

function Win:onRecover()
    self.statusText = "Recovering..."
    if isClient() then
        sendClientCommand(getPlayer(), "CommonSenseReborn", CSR_SkillJournal.CMD_RECOVER, {})
    elseif CSR_SkillJournalServer then
        CSR_SkillJournalServer.handleRecover(getPlayer(), {})
    end
end

function Win:onRefresh()
    self:requestState()
end

-- ---------------------------------------------------------------------
-- Admin Blacklist sub-dialog
-- ---------------------------------------------------------------------
local BL = ISCollapsableWindow:derive("CSR_SkillJournalBlacklistWin")
UI.BL = BL

local BL_W = 460
local BL_H = 460

function BL:new(x, y)
    local o = ISCollapsableWindow:new(x, y, BL_W, BL_H)
    setmetatable(o, self); self.__index = self
    o:setResizable(false)
    o.title = "CSR Skill Journal -- Admin Blacklist"
    o.users = {}
    o.perks = {}
    o.statusText = "Loading..."
    return o
end

local function sendAdmin(op, target)
    if isClient() then
        sendClientCommand(getPlayer(), "CommonSenseReborn", CSR_SkillJournal.CMD_ADMIN,
            { op = op, target = target or "" })
    elseif CSR_SkillJournalServer then
        CSR_SkillJournalServer.handleAdmin(getPlayer(), { op = op, target = target or "" })
    end
end

function BL:createChildren()
    ISCollapsableWindow.createChildren(self)
    local th = self:titleBarHeight()
    local pad = 8
    local colW = (BL_W - pad * 3) / 2

    -- Users column
    self.userEntry = ISTextEntryBox:new("", pad, th + pad + 16, colW, 22)
    self.userEntry:initialise(); self.userEntry:instantiate(); self.userEntry.tooltip = "Username (case-insensitive)"
    self:addChild(self.userEntry)
    self.userAddBtn = ISButton:new(pad, th + pad + 16 + 26, colW / 2 - 2, 22, getText("IGUI_CSR_SkillBlockUser") or "Block User", self, BL.onAddUser)
    self.userAddBtn:initialise(); self.userAddBtn:instantiate(); self:addChild(self.userAddBtn)
    styleButton(self.userAddBtn, true)
    self.userRemBtn = ISButton:new(pad + colW / 2 + 2, th + pad + 16 + 26, colW / 2 - 2, 22, "Unblock", self, BL.onRemoveUser)
    self.userRemBtn:initialise(); self.userRemBtn:instantiate(); self:addChild(self.userRemBtn)
    styleButton(self.userRemBtn, false)
    self.userList = ISScrollingListBox:new(pad, th + pad + 16 + 26 + 26, colW, BL_H - (th + pad + 16 + 26 + 26 + 50))
    self.userList:initialise(); self.userList:instantiate()
    self.userList.itemheight = 18; self.userList.font = UIFont.Small; self.userList.drawBorder = true
    self:addChild(self.userList)

    -- Perks column
    local x2 = pad + colW + pad
    self.perkEntry = ISTextEntryBox:new("", x2, th + pad + 16, colW, 22)
    self.perkEntry:initialise(); self.perkEntry:instantiate(); self.perkEntry.tooltip = "Perk type (e.g. Fitness, Strength, Aiming)"
    self:addChild(self.perkEntry)
    self.perkAddBtn = ISButton:new(x2, th + pad + 16 + 26, colW / 2 - 2, 22, getText("IGUI_CSR_SkillBlockPerk") or "Block Perk", self, BL.onAddPerk)
    self.perkAddBtn:initialise(); self.perkAddBtn:instantiate(); self:addChild(self.perkAddBtn)
    styleButton(self.perkAddBtn, true)
    self.perkRemBtn = ISButton:new(x2 + colW / 2 + 2, th + pad + 16 + 26, colW / 2 - 2, 22, "Unblock", self, BL.onRemovePerk)
    self.perkRemBtn:initialise(); self.perkRemBtn:instantiate(); self:addChild(self.perkRemBtn)
    styleButton(self.perkRemBtn, false)
    self.perkList = ISScrollingListBox:new(x2, th + pad + 16 + 26 + 26, colW, BL_H - (th + pad + 16 + 26 + 26 + 50))
    self.perkList:initialise(); self.perkList:instantiate()
    self.perkList.itemheight = 18; self.perkList.font = UIFont.Small; self.perkList.drawBorder = true
    self:addChild(self.perkList)
end

function BL:prerender()
    ISCollapsableWindow.prerender(self)
    if not self._kicked then
        self._kicked = true
        sendAdmin("bl_get", "")
    end
end

function BL:render()
    ISCollapsableWindow.render(self)
    local th = self:titleBarHeight()
    self:drawRectBorder(0, 0, self.width, self.height, 1.0, BORDER_R, BORDER_G, BORDER_B)
    self:drawText("Blacklisted Users", 8, th + 6, TEXT_R, TEXT_G, TEXT_B, 1, UIFont.Small)
    self:drawText("Blacklisted Perks", 8 + (BL_W - 16) / 2, th + 6, TEXT_R, TEXT_G, TEXT_B, 1, UIFont.Small)
    self:drawText(self.statusText or "", 8, BL_H - 22, MUTED_R, MUTED_G, MUTED_B, 1, UIFont.Small)
end

function BL:applyLists(users, perks)
    self.users = users or {}
    self.perks = perks or {}
    if self.userList then
        self.userList:clear()
        for _, u in ipairs(self.users) do self.userList:addItem(u, u) end
    end
    if self.perkList then
        self.perkList:clear()
        for _, p in ipairs(self.perks) do self.perkList:addItem(p, p) end
    end
end

function BL:onAddUser()
    local v = self.userEntry and self.userEntry:getInternalText() or ""
    if v == nil or v == "" then return end
    sendAdmin("bl_user_add", v)
    self.userEntry:setText("")
end

function BL:onRemoveUser()
    local sel = self.userList and self.userList.selected or 0
    if sel <= 0 or not self.userList.items[sel] then return end
    sendAdmin("bl_user_remove", self.userList.items[sel].text)
end

function BL:onAddPerk()
    local v = self.perkEntry and self.perkEntry:getInternalText() or ""
    if v == nil or v == "" then return end
    sendAdmin("bl_perk_add", v)
    self.perkEntry:setText("")
end

function BL:onRemovePerk()
    local sel = self.perkList and self.perkList.selected or 0
    if sel <= 0 or not self.perkList.items[sel] then return end
    sendAdmin("bl_perk_remove", self.perkList.items[sel].text)
end

function BL:onClose() self:setVisible(false) end

UI.blWindow = nil
function Win:onOpenBlacklist()
    if not UI.blWindow then
        local sw = getCore():getScreenWidth()
        local sh = getCore():getScreenHeight()
        UI.blWindow = BL:new((sw - BL_W) / 2, (sh - BL_H) / 2)
        UI.blWindow:initialise()
        UI.blWindow:addToUIManager()
    end
    UI.blWindow:setVisible(true)
    UI.blWindow._kicked = false
end

-- ---------------------------------------------------------------------
-- Singleton accessors
-- ---------------------------------------------------------------------
UI.window = nil

function UI.toggle()
    if not CSR_FeatureFlags.isSkillJournalEnabled() then return end
    if UI.window and UI.window:isVisible() then
        UI.window:setVisible(false)
        return
    end
    if not UI.window then
        local sw = getCore():getScreenWidth()
        local sh = getCore():getScreenHeight()
        UI.window = Win:new((sw - PANEL_W) / 2, (sh - PANEL_H) / 2, PANEL_W, PANEL_H)
        UI.window:initialise()
        UI.window:addToUIManager()
    end
    UI.window:setVisible(true)
    UI.window._kicked = false  -- force a re-fetch on next prerender
end

-- ---------------------------------------------------------------------
-- Server -> client push handlers
-- ---------------------------------------------------------------------
local function onServerCommand(module, command, args)
    if module ~= "CommonSenseReborn" then return end
    if command == CSR_SkillJournal.PUSH_STATE
       or command == CSR_SkillJournal.PUSH_RESULT
       or command == CSR_SkillJournal.PUSH_BLACKLIST then
        print("[CSR][SkillJournal] client received " .. tostring(command))
    end
    if command == CSR_SkillJournal.PUSH_STATE then
        if UI.window and UI.window:isVisible() then
            UI.window:applyState(args)
        end
    elseif command == CSR_SkillJournal.PUSH_RESULT then
        local text = (args and args.text) or ""
        if UI.window then UI.window.statusText = text end
        if UI.blWindow then UI.blWindow.statusText = text end
    elseif command == CSR_SkillJournal.PUSH_BLACKLIST then
        if UI.blWindow then
            UI.blWindow:applyLists(args and args.users, args and args.perks)
        end
    end
end

if Events and not UI._wired then
    UI._wired = true
    Events.OnServerCommand.Add(onServerCommand)
end

-- Module-level alias used by CSR_UtilityHud.
CSR_SkillJournalPanel.toggle = UI.toggle

return UI
