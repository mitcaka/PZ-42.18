require "CSR_FeatureFlags"
require "CSR_SafehouseClaim"
require "CSR_Claims/CSR_ClaimClient"
require "CSR_Claims/CSR_ClaimRegistry"
require "CSR_AA_InteropGuard"

--[[
    CSR_FactionExtensions.lua (client)
    Feature: Faction Member Limit

    - Patches ISFactionAddPlayerUI.onClick to block invites when the faction is at
      or above the configured member cap (MaxFactionMembers sandbox option).
    - Patches ISFactionAddPlayerUI.populateList to grey out the Add button and show
      the current count / cap in the panel title when at the limit.
    - Patches ISFactionUI.updateButtons to grey out the Add Player button when at cap.
    - Adds an "[CSR Admin] Faction Monitor" right-click option for admins that opens
      CSR_FactionMonitorPanel — a floating panel listing all factions with member
      counts and kick controls.

    Murphy's-law guards:
      - ISFactionAddPlayerUI not yet loaded  → patch deferred to OnGameStart
      - faction:getPlayers():size() throws   → wrapped in pcall, default 0
      - changeOwnership mode                 → cap check skipped (owner transfer ≠ member add)
      - MaxFactionMembers changed mid-session → read from sandbox on every gate check
      - Feature toggled off at runtime       → patched functions are no-ops
      - Faction dissolved between open/invite → Faction.getFaction() may return nil → pcall
      - Admin panel: Faction.getFactions() nil → pcall + nil check
      - Kick while faction syncing           → removePlayer + syncFaction both pcall'd
      - Double-patch guard                   → __csr_faction_patched sentinel
]]

CSR_FactionExtensions = CSR_FactionExtensions or {}

local MODULE = "CommonSenseReborn"

-- Track B activation gate. When the CSR claims override is enabled the
-- legacy ClaimFactionSafehouse / ReleaseFactionSafehouse paths are bypassed
-- in favour of CSR_ClaimClient.requestClaim / requestRelease (kind="faction").
local function overrideOn()
    return CSR_FeatureFlags
        and CSR_FeatureFlags.isCSRClaimsOverrideEnabled
        and CSR_FeatureFlags.isCSRClaimsOverrideEnabled() == true
end

-- =============================================
-- FACTION SAFEHOUSE — client-side registry
-- Populated by FactionSafehouseRegistered / FactionSafehouseReleased events.
-- =============================================
local _factionSafehouseRegistry = {}  -- list of {factionName, x, y, w, h}
local _pendingFactionTag = nil         -- {x,y,w,h,factionName,ticksLeft}

-- =============================================
-- HELPERS
-- =============================================

--- Safely get total faction member count INCLUDING the owner.
--- faction:getPlayers() returns non-owner members only (vanilla confirms this
--- with its own comment "the owner is not count in the players list"),
--- so we add 1 for the owner to get the true headcount.
local function getFactionSize(faction)
    if not faction then return 0 end
    local ok, sz = pcall(function()
        local players = faction:getPlayers()
        if not players then return 0 end
        return players:size() + 1  -- +1 for the owner who is excluded from getPlayers()
    end)
    return (ok and sz) or 0
end

--- Read the configured member cap from sandbox every call (no caching — admin may change it).
local function getMemberCap()
    return CSR_FeatureFlags.getMaxFactionMembers()
end

--- True if the feature is active and the faction is at or over cap.
local function isAtCap(faction)
    if not CSR_FeatureFlags.isFactionMemberLimitEnabled() then return false end
    return getFactionSize(faction) >= getMemberCap()
end

-- =============================================
-- HELPERS: notify, building detect, faction safehouse actions
-- =============================================

local function notify(player, msg)
    if not player or not msg then return end
    HaloTextHelper.AddTextWithSize(player, msg, 18, 1, 0.8, 0.2)
end

local function notifyError(player, msg)
    if not player or not msg then return end
    HaloTextHelper.AddTextWithSize(player, msg, 18, 1, 0.3, 0.3)
end

-- Find the building from a list of right-clicked world objects.
local function getBuildingFromWorldObjects(objects)
    for _, obj in ipairs(objects) do
        local sq = obj:getSquare()
        if sq then
            local b = sq:getBuilding()
            if b then return b end
        end
    end
    return nil
end

-- Find a matching entry in the client-side faction safehouse registry.
-- When the Track B override is on, read from CSR_ClaimClient._claimMirror;
-- otherwise fall back to the legacy _factionSafehouseRegistry list.
local function findFactionEntry(x, y, w, h)
    if overrideOn() and CSR_ClaimClient and CSR_ClaimClient._claimMirror then
        for _, row in pairs(CSR_ClaimClient._claimMirror) do
            if type(row) == "table" and row.kind == "faction" then
                local rx = tonumber(row.x) or 0
                local ry = tonumber(row.y) or 0
                local rw = tonumber(row.w) or 1
                local rh = tonumber(row.h) or 1
                if not (x >= rx + rw or rx >= x + w or y >= ry + rh or ry >= y + h) then
                    return {
                        factionName = row.factionName or "",
                        x = rx, y = ry, w = rw, h = rh,
                        id = tonumber(row.id) or 0,
                    }
                end
            end
        end
        return nil
    end
    for _, e in ipairs(_factionSafehouseRegistry) do
        if not (x >= e.x + e.w or e.x >= x + w or y >= e.y + e.h or e.y >= y + h) then
            return e
        end
    end
    return nil
end

-- Count of claims belonging to a faction. Track B sources from the mirror.
local function countFactionEntries(factionName)
    if overrideOn() and CSR_ClaimClient and CSR_ClaimClient._claimMirror then
        local n = 0
        for _, row in pairs(CSR_ClaimClient._claimMirror) do
            if type(row) == "table" and row.kind == "faction"
                and row.factionName == factionName then
                n = n + 1
            end
        end
        return n
    end
    local n = 0
    for _, e in ipairs(_factionSafehouseRegistry) do
        if e.factionName == factionName then n = n + 1 end
    end
    return n
end

-- Tick callback: fires 60 ticks after FactionSafehouseClaimApproved to send the tag.
local function onTickPendingTag()
    if not _pendingFactionTag then
        Events.OnTick.Remove(onTickPendingTag)
        return
    end
    _pendingFactionTag.ticksLeft = _pendingFactionTag.ticksLeft - 1
    if _pendingFactionTag.ticksLeft <= 0 then
        Events.OnTick.Remove(onTickPendingTag)
        local tag = _pendingFactionTag
        _pendingFactionTag = nil
        local player = getPlayer()
        if player then
            sendClientCommand(player, MODULE, "FactionSafehouseTag",
                { x = tag.x, y = tag.y, w = tag.w, h = tag.h, factionName = tag.factionName })
        end
    end
end

local function onClaimFactionSafehouse(player, args)
    if overrideOn() and CSR_ClaimClient and CSR_ClaimClient.requestClaim then
        CSR_ClaimClient.requestClaim({
            kind        = "faction",
            x           = args.x, y = args.y,
            w           = args.w, h = args.h,
            factionName = args.factionName,
            title       = (args.factionName or "") .. " safehouse",
        })
        return
    end
    sendClientCommand(player, MODULE, "ClaimFactionSafehouse", args)
end

local function onReleaseFactionSafehouse(player, args)
    if overrideOn() and CSR_ClaimClient and CSR_ClaimClient.requestRelease then
        if args and args.id then
            CSR_ClaimClient.requestRelease(args.id)
            return
        end
        -- Legacy callers passed coords-only; resolve the matching row first.
        if args and CSR_ClaimClient._claimMirror then
            for _, row in pairs(CSR_ClaimClient._claimMirror) do
                if row and row.kind == "faction"
                    and tonumber(row.x) == tonumber(args.x)
                    and tonumber(row.y) == tonumber(args.y) then
                    CSR_ClaimClient.requestRelease(row.id)
                    return
                end
            end
        end
        return
    end
    sendClientCommand(player, MODULE, "ReleaseFactionSafehouse", args)
end

--- True if the running player is an admin.
local function isAdmin(playerObj)
    if not playerObj then return false end
    local ok, result = pcall(function()
        local access = playerObj:getAccessLevel()
        if access and (access == "admin" or access == "Admin") then return true end
        -- FactionCheat capability also grants admin-level faction access in vanilla
        if playerObj:getRole():hasCapability(Capability.FactionCheat) then return true end
        return false
    end)
    return ok and result or false
end

-- =============================================
-- PATCH: ISFactionAddPlayerUI.drawPlayers
-- Vanilla re-enables addPlayer.enable=true when the user selects a name,
-- overriding our populateList patch.  This secondary patch keeps the button
-- disabled (and tooltip set) whenever the faction is at cap.
-- =============================================
local function patchDrawPlayers()
    if not ISFactionAddPlayerUI then return end
    if ISFactionAddPlayerUI.__csr_drawplayers_patched then return end
    ISFactionAddPlayerUI.__csr_drawplayers_patched = true

    local original = ISFactionAddPlayerUI.drawPlayers
    if not original then return end

    ISFactionAddPlayerUI.drawPlayers = function(self, y, item, alt)
        local result = original(self, y, item, alt)
        -- After vanilla may have set addPlayer.enable=true on selection,
        -- enforce the cap limit again.
        pcall(function()
            if not CSR_FeatureFlags.isFactionMemberLimitEnabled() then return end
            local panel = self.parent  -- self is the ISScrollingListBox; parent is ISFactionAddPlayerUI
            if not panel or not panel.addPlayer or not panel.faction then return end
            if isAtCap(panel.faction) then
                panel.addPlayer.enable = false
                local sz  = getFactionSize(panel.faction)
                local cap = getMemberCap()
                panel.addPlayer.tooltip = getText("UI_CSR_FactionAtCapShort", tostring(sz), tostring(cap))
            end
        end)
        return result
    end
end

-- =============================================
-- PATCH: ISFactionAddPlayerUI.onClick
-- Intercepts the ADDPLAYER action before sendFactionInvite fires.
-- The changeOwnership path is NOT gated — transferring ownership doesn't add a member.
-- =============================================

local function patchAddPlayerOnClick()
    if not ISFactionAddPlayerUI then return end
    if ISFactionAddPlayerUI.__csr_onclick_patched then return end
    ISFactionAddPlayerUI.__csr_onclick_patched = true

    local original = ISFactionAddPlayerUI.onClick
    ISFactionAddPlayerUI.onClick = function(self, button)
        if button.internal == "ADDPLAYER" and not self.changeOwnership then
            local blocked = false
            pcall(function()
                if CSR_FeatureFlags.isFactionMemberLimitEnabled() and isAtCap(self.faction) then
                    blocked = true
                    local cap = getMemberCap()
                    local modal = ISModalDialog:new(
                        getCore():getScreenWidth() / 2 - 175,
                        getCore():getScreenHeight() / 2 - 75,
                        350, 130,
                        getText("UI_CSR_FactionAtCap", tostring(cap)), false, nil, nil
                    )
                    modal:initialise()
                    modal:addToUIManager()
                end
            end)
            if blocked then return end
        end
        original(self, button)
    end
end

-- =============================================
-- PATCH: ISFactionAddPlayerUI.populateList
-- Appends member-count indicator to the panel's title area; disables Add button when at cap.
-- The list still populates so the owner can see who is online.
-- =============================================
local function patchPopulateList()
    if not ISFactionAddPlayerUI then return end
    if ISFactionAddPlayerUI.__csr_populate_patched then return end
    ISFactionAddPlayerUI.__csr_populate_patched = true

    local original = ISFactionAddPlayerUI.populateList
    ISFactionAddPlayerUI.populateList = function(self)
        original(self)
        pcall(function()
            if not CSR_FeatureFlags.isFactionMemberLimitEnabled() then return end
            if not self.faction or not self.addPlayer then return end
            local sz  = getFactionSize(self.faction)
            local cap = getMemberCap()
            if sz >= cap then
                -- Disable Add button and attach an explanatory tooltip
                self.addPlayer.enable = false
                self.addPlayer.tooltip = getText("UI_CSR_FactionAtCapShort", tostring(sz), tostring(cap))
            end
        end)
    end
end

-- =============================================
-- PATCH: ISFactionUI.updateButtons
-- Disables the "Add Player" button on the main faction panel when at cap.
-- =============================================
local function patchFactionUIUpdateButtons()
    if not ISFactionUI then return end
    if ISFactionUI.__csr_updatebuttons_patched then return end
    ISFactionUI.__csr_updatebuttons_patched = true

    local original = ISFactionUI.updateButtons
    if not original then return end  -- guard: method must exist

    ISFactionUI.updateButtons = function(self)
        original(self)
        pcall(function()
            if not CSR_FeatureFlags.isFactionMemberLimitEnabled() then return end
            if not self.faction or not self.addPlayer then return end
            local sz  = getFactionSize(self.faction)
            local cap = getMemberCap()
            if sz >= cap and self.isOwner then
                self.addPlayer.enable = false
                self.addPlayer.tooltip = getText("UI_CSR_FactionAtCapShort", tostring(sz), tostring(cap))
            end
        end)
    end
end

-- =============================================
-- ADMIN MONITOR PANEL
-- =============================================

CSR_FactionMonitorPanel = ISPanel:derive("CSR_FactionMonitorPanel")

local FONT_SMALL  = UIFont.NewSmall
local FONT_MEDIUM = UIFont.Medium
local ITEM_H      = 20
local BORDER      = 8
local BTN_H       = 22

--- Build a flat list of { type, factionName, owner, size, cap, username } rows.
local function buildMonitorRows()
    local rows = {}
    local cap = getMemberCap()
    pcall(function()
        local factions = Faction.getFactions()
        if not factions then return end
        local fSz = factions:size()
        for i = 0, fSz - 1 do
            local faction = factions:get(i)
            if faction then
                local fName = faction:getName() or "?"
                local owner = faction:getOwner() or "?"
                local members = faction:getPlayers()
                local mSz = 0
                if members then
                    local ok, sz = pcall(function() return members:size() end)
                    mSz = ok and sz or 0
                end
                -- Faction header row
                table.insert(rows, {
                    type        = "header",
                    factionName = fName,
                    owner       = owner,
                    size        = mSz,
                    cap         = cap,
                    atCap       = (mSz >= cap),
                })
                -- Member rows
                for j = 0, mSz - 1 do
                    local ok2, uname = pcall(function()
                        return tostring(members:get(j))
                    end)
                    if ok2 and uname then
                        table.insert(rows, {
                            type        = "member",
                            factionName = fName,
                            username    = uname,
                            isOwner     = (uname == owner),
                        })
                    end
                end
            end
        end
    end)
    return rows
end

function CSR_FactionMonitorPanel:initialise()
    ISPanel.initialise(self)

    -- Title label
    local titleText = "CSR Faction Monitor"
    self.titleLabel = ISLabel:new(
        BORDER, BORDER,
        ITEM_H, titleText,
        1, 0.85, 0.2, 1, FONT_MEDIUM, true
    )
    self.titleLabel:initialise()
    self.titleLabel:instantiate()
    self:addChild(self.titleLabel)

    -- Close button (top-right)
    self.closeBtn = ISButton:new(
        self.width - 70 - BORDER, BORDER, 70, BTN_H,
        getText("UI_Close"), self, CSR_FactionMonitorPanel.onClose
    )
    self.closeBtn:initialise()
    self.closeBtn:instantiate()
    self.closeBtn.borderColor = { r=0.8, g=0.2, b=0.2, a=1 }
    self:addChild(self.closeBtn)

    -- Refresh button
    self.refreshBtn = ISButton:new(
        self.width - 148 - BORDER, BORDER, 70, BTN_H,
        getText("UI_servers_refresh"), self, CSR_FactionMonitorPanel.onRefresh
    )
    self.refreshBtn:initialise()
    self.refreshBtn:instantiate()
    self.refreshBtn.borderColor = { r=0.4, g=0.7, b=0.4, a=1 }
    self:addChild(self.refreshBtn)

    -- Cap label (shows current MaxFactionMembers)
    self.capLabel = ISLabel:new(
        BORDER, BORDER + ITEM_H + 4,
        ITEM_H, "", 0.7, 0.7, 0.7, 1, FONT_SMALL, true
    )
    self.capLabel:initialise()
    self.capLabel:instantiate()
    self:addChild(self.capLabel)

    -- Scrolling list
    local listY = BORDER + ITEM_H + BORDER + ITEM_H + BORDER
    local listH = self.height - listY - BTN_H - BORDER * 3
    self.memberList = ISScrollingListBox:new(
        BORDER, listY, self.width - BORDER * 2, listH
    )
    self.memberList:initialise()
    self.memberList:instantiate()
    self.memberList.itemheight = ITEM_H
    self.memberList.selected   = 0
    self.memberList.font       = FONT_SMALL
    self.memberList.doDrawItem = CSR_FactionMonitorPanel.drawRow
    self.memberList.drawBorder = true
    self.memberList.joypadParent = self
    self:addChild(self.memberList)

    -- Kick button (bottom)
    self.kickBtn = ISButton:new(
        BORDER, self.memberList:getBottom() + BORDER, 100, BTN_H,
        getText("UI_CSR_KickFromFaction"), self, CSR_FactionMonitorPanel.onKick
    )
    self.kickBtn:initialise()
    self.kickBtn:instantiate()
    self.kickBtn.borderColor = { r=0.8, g=0.3, b=0.3, a=1 }
    self.kickBtn.enable = false
    self:addChild(self.kickBtn)

    self:populateList()
end

function CSR_FactionMonitorPanel:populateList()
    self.memberList:clear()
    self.memberList.selected = 0
    self.kickBtn.enable = false
    self._rows = buildMonitorRows()

    local cap = getMemberCap()
    local enabled = CSR_FeatureFlags.isFactionMemberLimitEnabled()
    if enabled then
        self.capLabel:setName(getText("UI_CSR_FactionCapLabel", tostring(cap)))
    else
        self.capLabel:setName(getText("UI_CSR_FactionLimitDisabled"))
    end

    if #self._rows == 0 then
        self.memberList:addItem(getText("UI_CSR_NoFactions"), { type = "empty" })
    else
        for _, row in ipairs(self._rows) do
            local displayText
            if row.type == "header" then
                local capStatus = enabled and (" [" .. tostring(row.size) .. "/" .. tostring(row.cap) .. "]") or ""
                displayText = "[" .. row.factionName .. "]" .. capStatus .. "  Owner: " .. row.owner
            elseif row.type == "member" then
                local ownerTag = row.isOwner and " (owner)" or ""
                displayText = "  " .. row.username .. ownerTag
            end
            self.memberList:addItem(displayText, row)
        end
    end
end

function CSR_FactionMonitorPanel.drawRow(self, y, item, alt)
    local data = item.item
    local a = 0.9

    if data.type == "header" then
        -- Faction header: dark teal background
        local r, g, b = 0.1, 0.3, 0.35
        if data.atCap then r, g, b = 0.35, 0.12, 0.12 end  -- red tint at cap
        self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.6, r, g, b)
        self:drawRectBorder(0, y, self:getWidth(), self.itemheight - 1, a,
            self.borderColor.r, self.borderColor.g, self.borderColor.b)
        self:drawText(item.text, 6, y + 2, 1, 0.9, 0.3, a, self.font)
    elseif data.type == "member" then
        if self.selected == item.index then
            local selOk = not data.isOwner  -- can only kick non-owners
            local sr, sg, sb = selOk and 0.2 or 0.25, selOk and 0.55 or 0.25, selOk and 0.2 or 0.25
            self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.4, sr, sg, sb)
            -- Enable kick only for non-owner members
            self.parent.kickBtn.enable = selOk
        end
        self:drawRectBorder(0, y, self:getWidth(), self.itemheight - 1, 0.5,
            self.borderColor.r, self.borderColor.g, self.borderColor.b)
        local tc = data.isOwner and 0.7 or 1.0
        self:drawText(item.text, 6, y + 2, tc, tc, tc, a, self.font)
    elseif data.type == "empty" then
        self:drawText(item.text, 6, y + 2, 0.6, 0.6, 0.6, a, self.font)
    end

    return y + self.itemheight
end

function CSR_FactionMonitorPanel:onRefresh(button)
    self:populateList()
end

function CSR_FactionMonitorPanel:onClose(button)
    self:setVisible(false)
    self:removeFromUIManager()
    CSR_FactionMonitorPanel.instance = nil
end

function CSR_FactionMonitorPanel:onKick(button)
    local idx = self.memberList.selected
    if idx == 0 then return end
    local item = self.memberList.items[idx]
    if not item or not item.item or item.item.type ~= "member" then return end
    local data = item.item
    if data.isOwner then return end  -- cannot kick owner via this panel

    local panel = self
    local msg = getText("UI_CSR_KickConfirm", data.username, data.factionName)
    local modal = ISModalDialog:new(
        getCore():getScreenWidth() / 2 - 175,
        getCore():getScreenHeight() / 2 - 75,
        350, 130, msg, true, nil,
        function(_, btn)
            if btn and btn.internal == "YES" then
                pcall(function()
                    local faction = Faction.getFaction(data.factionName)
                    if faction then
                        faction:removePlayer(data.username)
                        faction:syncFaction()
                    end
                end)
                panel:populateList()
            end
        end
    )
    modal:initialise()
    modal:addToUIManager()
end

function CSR_FactionMonitorPanel:prerender()
    self:drawRect(0, 0, self.width, self.height,
        self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height,
        self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
end

function CSR_FactionMonitorPanel:new(x, y, w, h)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.borderColor      = { r=0.5, g=0.5, b=0.5, a=1 }
    o.backgroundColor  = { r=0.05, g=0.05, b=0.1, a=0.92 }
    o.moveWithMouse    = true
    CSR_FactionMonitorPanel.instance = o
    return o
end

local function openFactionMonitorPanel()
    if CSR_FactionMonitorPanel.instance and CSR_FactionMonitorPanel.instance:isReallyVisible() then
        CSR_FactionMonitorPanel.instance:setVisible(false)
        CSR_FactionMonitorPanel.instance:removeFromUIManager()
        CSR_FactionMonitorPanel.instance = nil
        return
    end
    local w, h = 460, 500
    local x = (getCore():getScreenWidth()  - w) / 2
    local y = (getCore():getScreenHeight() - h) / 2
    local panel = CSR_FactionMonitorPanel:new(x, y, w, h)
    panel:initialise()
    panel:addToUIManager()
end

-- =============================================
-- CONTEXT MENU: Faction options added via createMenu patch
-- Uses createMenu patch (not OnFillWorldObjectContextMenu) so options appear
-- regardless of whether Java's safehouseAllowInteract flag is set.
-- =============================================
local function addFactionContextOptions(playerNum, context, worldobjects)
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    -- ─── Faction safehouse options (faction owner, MP only) ──────────────────────
    if isClient() and CSR_SafehouseClaim and CSR_SafehouseClaim.isFactionSafehouseEnabled
       and CSR_SafehouseClaim.isFactionSafehouseEnabled() then
        local building = getBuildingFromWorldObjects(worldobjects)
        if not building then
            local sq = player:getCurrentSquare()
            if sq then building = sq:getBuilding() end
        end
        if building then
            local def = building:getDef()
            if def then
                local x, y, w, h = def:getX(), def:getY(), def:getW(), def:getH()
                -- Find player's faction (if they're an owner)
                local myFaction = nil
                if Faction and Faction.getFactions then
                    local factions = Faction.getFactions()
                    if factions then
                        for i = 0, factions:size() - 1 do
                            local f = factions:get(i)
                            if f and f:isOwner(player:getUsername()) then
                                myFaction = f; break
                            end
                        end
                    end
                end

                if myFaction then
                    local factionName   = myFaction:getName()
                    local registryEntry = findFactionEntry(x, y, w, h)

                    if registryEntry and registryEntry.factionName == factionName then
                        -- This is our faction's safehouse — offer release
                        context:addOption(
                            getText("UI_CSR_FactionSafehouseRelease", factionName),
                            worldobjects,
                            function(_, p, a) onReleaseFactionSafehouse(p, a) end,
                            player,
                            { id = registryEntry.id,
                              x = x, y = y, w = w, h = h, factionName = factionName }
                        )
                    elseif not registryEntry then
                        -- Not already a faction safehouse; only offer claim if unclaimed
                        local existingSh = CSR_SafehouseClaim.findSafehouseAt(x, y, w, h)
                        if not existingSh then
                            local count = countFactionEntries(factionName)
                            local max = CSR_SafehouseClaim.getMaxFactionSafehouses()
                            local label = getText("UI_CSR_FactionSafehouseClaim", factionName, count, max)
                            local opt = context:addOption(
                                label, worldobjects,
                                function(_, p, a) onClaimFactionSafehouse(p, a) end,
                                player,
                                { x = x, y = y, w = w, h = h, factionName = factionName }
                            )
                            if count >= max then
                                opt.notAvailable = true
                                local tt = ISToolTip:new()
                                tt.description = getText("UI_CSR_FactionSafehouseAtCap", max)
                                opt.toolTip = tt
                            end
                        end
                    end
                end
            end
        end
    end

    -- ─── Admin: Faction Monitor ───────────────────────────────────────────────────
    if not isAdmin(player) then return end
    if not isClient() and not isServer() then return end  -- MP only (factions are MP)

    context:addOption(
        getText("ContextMenu_CSR_FactionMonitor"),
        player,
        function() openFactionMonitorPanel() end
    )
end

-- Patches ISWorldObjectContextMenu.createMenu so our options always appear,
-- bypassing the vanilla safehouseAllowInteract gate that blocked OnFillWorldObjectContextMenu.
local function hookFactionCreateMenu()
    if not ISWorldObjectContextMenu or not ISWorldObjectContextMenu.createMenu then return end
    if ISWorldObjectContextMenu.__csr_faction_cm_patched then return end
    ISWorldObjectContextMenu.__csr_faction_cm_patched = true

    local original = ISWorldObjectContextMenu.createMenu
    ISWorldObjectContextMenu.createMenu = function(player, worldobjects, x, y, test)
        local result = original(player, worldobjects, x, y, test)
        if test then return result end
        if CSR_AA_InteropGuard and CSR_AA_InteropGuard.isInForeignInteriorCell
                and CSR_AA_InteropGuard.isInForeignInteriorCell(player) then
            return result
        end

        local context = getPlayerContextMenu(player)
        if not context then return result end
        addFactionContextOptions(player, context, worldobjects)
        return result
    end
end

-- =============================================
-- INIT
-- =============================================
local function init()
    -- Apply all patches inside OnGameStart so vanilla UI files are guaranteed loaded
    pcall(patchAddPlayerOnClick)
    pcall(patchPopulateList)    pcall(patchDrawPlayers)    pcall(patchFactionUIUpdateButtons)
    -- Patch createMenu here too so it's applied after ISWorldObjectContextMenu loads
    pcall(hookFactionCreateMenu)
end

-- =============================================
-- SERVER COMMAND HANDLER: faction safehouse events
-- =============================================
local function onServerCommand(module, command, args)
    if module ~= MODULE then return end
    local player = getPlayer()
    if not player then return end

    if command == "FactionSafehouseClaimApproved" then
        if not args or args.x == nil then return end
        -- Track B override: the client-side SafeHouse mirror is materialized
        -- by CSR_ClaimClient when the CSR_ClaimAdded broadcast arrives. Skip
        -- the legacy sendSafehouseClaim() round-trip entirely.
        if overrideOn() then
            notify(player, "Faction safehouse claimed for "
                .. (args.factionName or "faction") .. "!")
            return
        end
        local sq = getCell():getGridSquare(args.x, args.y, 0)
        if sq then
            sendSafehouseClaim(sq, player, player:getUsername())
            _pendingFactionTag = {
                x = args.x, y = args.y,
                w = args.w or 10, h = args.h or 10,
                factionName = args.factionName,
                ticksLeft = 60,
            }
            Events.OnTick.Add(onTickPendingTag)
            notify(player, "Faction safehouse claimed for " .. (args.factionName or "faction") .. "!")
        end
        return
    end

    if command == "FactionSafehouseRegistered" then
        if not args or not args.factionName then return end
        -- Replace any duplicate entry for the same coords first
        for i = #_factionSafehouseRegistry, 1, -1 do
            local e = _factionSafehouseRegistry[i]
            if e.x == args.x and e.y == args.y then
                table.remove(_factionSafehouseRegistry, i)
            end
        end
        table.insert(_factionSafehouseRegistry,
            { factionName = args.factionName, x = args.x, y = args.y, w = args.w, h = args.h })
        return
    end

    if command == "FactionSafehouseReleased" then
        if not args then return end
        for i = #_factionSafehouseRegistry, 1, -1 do
            local e = _factionSafehouseRegistry[i]
            if e.x == args.x and e.y == args.y then
                table.remove(_factionSafehouseRegistry, i)
            end
        end
        return
    end

    if command == "FactionSafehouseResult" then
        local msg     = args and args.text    or ""
        local success = args and args.success
        if success then
            notify(player, msg)
        else
            notifyError(player, msg)
        end
        return
    end
end

-- Request the full registry from the server when we connect.
local function requestFactionSafehouseRegistry()
    local player = getPlayer()
    if player and isClient() then
        sendClientCommand(player, MODULE, "GetFactionSafehouseRegistry", {})
    end
end

if Events then
    if Events.OnGameStart then
        if not CSR_FactionExtensions._onGameStartRegistered then
            CSR_FactionExtensions._onGameStartRegistered = true
            Events.OnGameStart.Add(init)
            Events.OnGameStart.Add(requestFactionSafehouseRegistry)
        end
    end
    -- Server command handler for faction safehouse events
    if not CSR_FactionExtensions._serverCmdRegistered then
        CSR_FactionExtensions._serverCmdRegistered = true
        Events.OnServerCommand.Add(onServerCommand)
    end
end

return CSR_FactionExtensions
