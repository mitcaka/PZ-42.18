--[[
    CSR_ClaimsManagerPanel.lua
    -------------------------------------------------------------------------
    Track B (v1.8.0) -- unified manager UI for CSR claims.

    A floating panel with three tabs (Personal / Faction / Vehicle) that
    reads directly from CSR_ClaimClient._claimMirror and dispatches every
    write through CSR_ClaimClient.requestRelease / requestTransfer /
    requestSetRole.

    The panel is registry-driven; it does NOT touch SafeHouse.* or vanilla
    safehouse helpers. Permissions:
      * Personal tab: rows where row.kind=="personal" AND
        (row.owner == me OR I am in row.membersCSV OR I am admin).
      * Faction tab: rows where row.kind=="faction" AND
        (Faction.isOwner(me) for row.factionName OR I am admin).
      * Vehicle tab: rows where row.kind=="vehicle" AND
        (row.owner == me OR I am in row.membersCSV OR I am admin).

    Hard rules:
      * Kahlua: no goto / ::label::. No :split() on Lua strings.
      * All UI text via getText(...) with English fallbacks (full keyset
        lands in Step 10).
      * Wrap every Java numeric return with tonumber(...) or 0.
      * NEVER call SafeHouse.addSafeHouse() -- read-only over the mirror.
--]]

require "CSR_FeatureFlags"
require "CSR_Claims/CSR_ClaimClient"
require "CSR_Claims/CSR_ClaimRegistry"
require "CSR_Claims/CSR_ClaimPermissions"
require "CSR_Claims/CSR_ClaimInvitesClient"
require "CSR_SafehouseOutline"

CSR_ClaimsManagerPanel = ISPanel:derive("CSR_ClaimsManagerPanel")

local Registry = CSR_ClaimRegistry
local localOutlineEligible

-- =========================================================================
-- Layout constants
-- =========================================================================

local FONT_S  = UIFont.NewSmall
local FONT_M  = UIFont.Medium
local ITEM_H  = 20
local BORDER  = 8
local BTN_H   = 22
-- v1.8.5: tabs slimmed down (was 32 / w=130, FONT_M).  Active tab is
-- still visually distinguished via the breadcrumb label below.
local TAB_H   = 22

local TAB_PERSONAL = "personal"
local TAB_FACTION  = "faction"
local TAB_VEHICLE  = "vehicle"

-- =========================================================================
-- Helpers
-- =========================================================================

local function tr(key, fallback)
    if getText then
        local s = getText(key)
        if s and s ~= key then return s end
    end
    return fallback or key
end

local function safeUsername(playerObj)
    if not playerObj or not playerObj.getUsername then return "" end
    local u = playerObj:getUsername()
    if u then return tostring(u) end
    return ""
end

local function trim(s)
    if type(s) ~= "string" then return "" end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function lower(s)
    return string.lower(tostring(s or ""))
end

local function isAdmin(playerObj)
    if not playerObj then return false end
    if not playerObj.getAccessLevel then return false end
    local access = playerObj:getAccessLevel()
    return access == "admin" or access == "Admin"
end

local function csvSet(csv)
    local set = {}
    if Registry and Registry.csvList then
        local list = Registry.csvList(csv or "")
        for i = 1, #list do
            local name = tostring(list[i] or "")
            if name ~= "" then set[name] = true end
        end
    end
    return set
end

local function sortedOnlinePlayerNames(viewer, exclude)
    local out = {}
    local seen = {}
    exclude = exclude or {}
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if players and players.size and players.get then
        local count = tonumber(players:size()) or 0
        for i = 0, count - 1 do
            local p = players:get(i)
            local name = p and p.getUsername and tostring(p:getUsername() or "") or ""
            if name ~= "" and not exclude[name] and not seen[name] then
                out[#out + 1] = name
                seen[name] = true
            end
        end
    else
        local name = safeUsername(viewer or getPlayer())
        if name ~= "" and not exclude[name] then out[#out + 1] = name end
    end
    table.sort(out)
    return out
end

local function showPickerMessage(text)
    local modal = ISModalDialog:new(
        getCore():getScreenWidth() / 2 - 175,
        getCore():getScreenHeight() / 2 - 75,
        350, 130, text, false, nil, nil)
    modal:initialise()
    modal:addToUIManager()
end

local function showOnlineNamePicker(panel, title, candidates, onPick)
    if not candidates or #candidates == 0 then
        showPickerMessage(tr("UI_CSR_ClaimsNoOnlinePlayers",
            "No eligible online players found."))
        return
    end

    local cx = getCore():getScreenWidth() / 2 - 175
    local cy = getCore():getScreenHeight() / 2 - 95
    local picker = ISPanel:new(cx, cy, 350, 190)
    picker:initialise()
    picker.borderColor     = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
    picker.backgroundColor = { r = 0.05, g = 0.05, b = 0.10, a = 0.95 }
    picker.moveWithMouse   = true
    picker:addToUIManager()

    local lab = ISLabel:new(BORDER, BORDER, ITEM_H, title,
        1, 1, 1, 1, FONT_S, true)
    lab:initialise(); lab:instantiate(); picker:addChild(lab)

    local cb = ISComboBox:new(BORDER, BORDER + ITEM_H + 8,
        350 - BORDER * 2, 24)
    cb:initialise(); cb:instantiate()
    for i = 1, #candidates do cb:addOption(candidates[i]) end
    cb.selected = 1
    picker:addChild(cb)

    local okBtn = ISButton:new(BORDER, 190 - BTN_H - BORDER, 100, BTN_H,
        tr("UI_Ok", "OK"), picker, function()
            local pick = cb:getOptionText(cb.selected)
            if pick and pick ~= "" and onPick then onPick(pick) end
            picker:setVisible(false); picker:removeFromUIManager()
            if panel and panel.populate then panel:populate() end
        end)
    okBtn:initialise(); okBtn:instantiate()
    okBtn.enable = #candidates > 0
    okBtn.borderColor = { r = 0.4, g = 0.7, b = 0.4, a = 1 }
    picker:addChild(okBtn)

    local caBtn = ISButton:new(350 - 100 - BORDER, 190 - BTN_H - BORDER,
        100, BTN_H, tr("UI_Cancel", "Cancel"), picker, function()
            picker:setVisible(false); picker:removeFromUIManager()
        end)
    caBtn:initialise(); caBtn:instantiate()
    caBtn.borderColor = { r = 0.7, g = 0.3, b = 0.3, a = 1 }
    picker:addChild(caBtn)
end

local function getOwnedFactions(playerObj)
    local owned = {}
    if not playerObj or not Faction or not Faction.getFactions then return owned end
    local list = Faction.getFactions()
    if not list then return owned end
    local n = tonumber(list:size()) or 0
    local user = safeUsername(playerObj)
    for i = 0, n - 1 do
        local f = list:get(i)
        if f and f.isOwner and user ~= "" and f:isOwner(user) then
            owned[#owned + 1] = f:getName()
        end
    end
    return owned
end

local function buildOwnedFactionSet(playerObj)
    local set = {}
    local list = getOwnedFactions(playerObj)
    for i = 1, #list do set[list[i]] = true end
    return set
end

-- Sandbox cap helpers (best-effort -- defaults are conservative).
local function maxPersonalClaims()
    if SandboxVars and SandboxVars.CommonSenseReborn
        and SandboxVars.CommonSenseReborn.MaxSafehouseClaims then
        return tonumber(SandboxVars.CommonSenseReborn.MaxSafehouseClaims) or 1
    end
    return 1
end

local function maxFactionClaims()
    if SandboxVars and SandboxVars.CommonSenseReborn
        and SandboxVars.CommonSenseReborn.MaxFactionSafehouses then
        return tonumber(SandboxVars.CommonSenseReborn.MaxFactionSafehouses) or 1
    end
    return 1
end

local function claimExpansionOn()
    if CSR_FeatureFlags and CSR_FeatureFlags.isClaimExpansionEnabled then
        return CSR_FeatureFlags.isClaimExpansionEnabled()
    end
    local sb = (SandboxVars and SandboxVars.CommonSenseReborn) or {}
    return sb.EnableClaimExpansion ~= false
end

local function claimExpansionCost(addedTiles)
    addedTiles = math.max(0, tonumber(addedTiles) or 0)
    local sb = (SandboxVars and SandboxVars.CommonSenseReborn) or {}
    local moneyPer = tonumber(sb.ClaimExpansionMoneyPer10Tiles) or 1
    local materialPer = tonumber(sb.ClaimExpansionMaterialsPer10Tiles) or 2
    local units = 0
    if addedTiles > 0 then units = math.floor((addedTiles + 9) / 10) end
    return units * moneyPer, units * materialPer
end

local function claimExpansionMaxWidth()
    local sb = (SandboxVars and SandboxVars.CommonSenseReborn) or {}
    return tonumber(sb.ClaimExpansionMaxWidth) or 96
end

local function claimExpansionMaxHeight()
    local sb = (SandboxVars and SandboxVars.CommonSenseReborn) or {}
    return tonumber(sb.ClaimExpansionMaxHeight) or 96
end

local function claimExpansionMaxAdded()
    local sb = (SandboxVars and SandboxVars.CommonSenseReborn) or {}
    return tonumber(sb.ClaimExpansionMaxAddedTiles) or 1024
end

local function claimExpansionArchitectRequired()
    local sb = (SandboxVars and SandboxVars.CommonSenseReborn) or {}
    return sb.ClaimExpansionRequireArchitect == true
end

-- Rights for a given row + viewer.
local function viewerRights(row, viewer, ownedFactionSet, admin)
    if not row then return false, false end
    local user = safeUsername(viewer)
    local canSee = false
    local canManage = false
    if admin then canSee = true; canManage = true end

    if row.kind == "personal" or row.kind == "vehicle" then
        if row.owner == user then canSee = true; canManage = true
        elseif Registry.csvContains(row.membersCSV, user) then canSee = true end
    elseif row.kind == "faction" then
        if ownedFactionSet[row.factionName or ""] then
            canSee = true; canManage = true
        elseif Registry.csvContains(row.membersCSV, user) then
            canSee = true
        end
    end
    return canSee, canManage
end

-- Sort: owned-by-me first, then alphabetical by title/owner/factionName.
local function rowSortKey(row, user)
    local ownedByMe = (row.owner == user) and 0 or 1
    local label = row.title or ""
    if label == "" then
        if row.kind == "faction" then label = row.factionName or ""
        else label = row.owner or "" end
    end
    return string.format("%d|%s|%05d|%05d", ownedByMe, string.lower(label),
        tonumber(row.x) or 0, tonumber(row.y) or 0)
end

local function rowSearchText(row)
    if not row then return "" end
    local parts = {}
    local function add(v)
        if v ~= nil and v ~= "" then parts[#parts + 1] = tostring(v) end
    end
    add(row.id)
    add(row.kind)
    add(row.owner)
    add(row.title)
    add(row.factionName)
    add(row.membersCSV)
    add(row.rolesCSV)
    add(row.x)
    add(row.y)
    add(row.w)
    add(row.h)
    if row.kind == "vehicle" then
        add(row.vehicleKey)
        add(row.vehicleSqlId)
        add(row.vehicleScript)
        add(row.lastVehicleX)
        add(row.lastVehicleY)
    end
    return lower(table.concat(parts, " "))
end

local function rowMatchesSearch(row, searchText)
    searchText = trim(lower(searchText or ""))
    if searchText == "" then return true end
    local haystack = rowSearchText(row)
    for token in string.gmatch(searchText, "%S+") do
        if not string.find(haystack, token, 1, true) then return false end
    end
    return true
end

-- =========================================================================
-- Panel construction
-- =========================================================================

function CSR_ClaimsManagerPanel:new(x, y, w, h, playerObj)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.borderColor     = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
    o.backgroundColor = { r = 0.05, g = 0.05, b = 0.10, a = 0.95 }
    o.moveWithMouse   = true
    o.player          = playerObj or getPlayer()
    o.activeTab       = TAB_PERSONAL
    o.searchText      = ""
    CSR_ClaimsManagerPanel.instance = o
    return o
end

function CSR_ClaimsManagerPanel:initialise()
    ISPanel.initialise(self)

    -- Title
    self.titleLabel = ISLabel:new(BORDER, BORDER, ITEM_H,
        tr("UI_CSR_ClaimsManagerTitle", "CSR Claims Manager"),
        1, 0.85, 0.2, 1, FONT_M, true)
    self.titleLabel:initialise(); self.titleLabel:instantiate()
    self:addChild(self.titleLabel)

    -- Close
    self.closeBtn = ISButton:new(self.width - 70 - BORDER, BORDER, 70, BTN_H,
        tr("UI_Close", "Close"), self, CSR_ClaimsManagerPanel.onClose)
    self.closeBtn:initialise(); self.closeBtn:instantiate()
    self.closeBtn.borderColor = { r = 0.8, g = 0.2, b = 0.2, a = 1 }
    self:addChild(self.closeBtn)

    -- Refresh
    self.refreshBtn = ISButton:new(self.width - 148 - BORDER, BORDER, 70, BTN_H,
        tr("UI_servers_refresh", "Refresh"), self, CSR_ClaimsManagerPanel.onRefresh)
    self.refreshBtn:initialise(); self.refreshBtn:instantiate()
    self.refreshBtn.borderColor = { r = 0.4, g = 0.7, b = 0.4, a = 1 }
    self:addChild(self.refreshBtn)

    -- Tab strip (three real buttons -- avoids ISTabPanel quirks).  v1.8.1
    -- enlarges tabs and uses Medium font on the active tab so it's obvious
    -- which view is current.  A hint label sits ABOVE the tab row -- the
    -- previous "left of tabs" layout assumed the localized hint string was
    -- short, but most translations expand to a full sentence ("Click a tab
    -- to filter the claim list.") and bled behind the Personal button.
    local hintY = BORDER + ITEM_H + BORDER
    self.tabHintLabel = ISLabel:new(BORDER, hintY, ITEM_H,
        tr("UI_CSR_ClaimsTabHint", "Click a tab to filter the claim list."),
        0.95, 0.85, 0.30, 1, FONT_S, true)
    self.tabHintLabel:initialise(); self.tabHintLabel:instantiate()
    self:addChild(self.tabHintLabel)

    local tabsY = hintY + ITEM_H + 2
    local tabW  = 100
    local tabBaseX = BORDER
    self.personalTabBtn = ISButton:new(tabBaseX, tabsY, tabW, TAB_H,
        tr("UI_CSR_ClaimsTabPersonal", "Personal"),
        self, CSR_ClaimsManagerPanel.onTabPersonal)
    self.personalTabBtn:initialise(); self.personalTabBtn:instantiate()
    self.personalTabBtn.font = FONT_S
    self:addChild(self.personalTabBtn)

    self.factionTabBtn = ISButton:new(tabBaseX + tabW + 4, tabsY, tabW, TAB_H,
        tr("UI_CSR_ClaimsTabFaction", "Faction"),
        self, CSR_ClaimsManagerPanel.onTabFaction)
    self.factionTabBtn:initialise(); self.factionTabBtn:instantiate()
    self.factionTabBtn.font = FONT_S
    self:addChild(self.factionTabBtn)

    self.vehicleTabBtn = ISButton:new(tabBaseX + (tabW + 4) * 2, tabsY, tabW, TAB_H,
        tr("UI_CSR_ClaimsTabVehicle", "Vehicle"),
        self, CSR_ClaimsManagerPanel.onTabVehicle)
    self.vehicleTabBtn:initialise(); self.vehicleTabBtn:instantiate()
    self.vehicleTabBtn.font = FONT_S
    self:addChild(self.vehicleTabBtn)

    -- Counter label (right of tabs)
    self.counterLabel = ISLabel:new(tabBaseX + (tabW + 4) * 3 + 12, tabsY + 4, ITEM_H,
        "", 0.85, 0.85, 0.85, 1, FONT_S, true)
    self.counterLabel:initialise(); self.counterLabel:instantiate()
    self:addChild(self.counterLabel)

    -- Active-tab breadcrumb directly below the tab strip.  Updated in
    -- :populate() to read "Showing: <tab name> claims".
    self.activeTabLabel = ISLabel:new(BORDER, tabsY + TAB_H + 2, ITEM_H,
        "", 1.0, 0.85, 0.20, 1, FONT_S, true)
    self.activeTabLabel:initialise(); self.activeTabLabel:instantiate()
    self:addChild(self.activeTabLabel)

    -- Local claim search. It filters only the rows the current viewer can
    -- already see, so admins get a scalable lookup without extra server load.
    local searchY = tabsY + TAB_H + ITEM_H + 6
    self.searchLabel = ISLabel:new(BORDER, searchY + 2, ITEM_H,
        tr("UI_CSR_ClaimsSearch", "Search"),
        0.85, 0.85, 0.85, 1, FONT_S, true)
    self.searchLabel:initialise(); self.searchLabel:instantiate()
    self:addChild(self.searchLabel)

    local entryX = BORDER + 58
    local clearW = 70
    local entryW = self.width - entryX - clearW - BORDER * 2 - 6
    if entryW < 160 then entryW = 160 end
    self.searchEntry = ISTextEntryBox:new("", entryX, searchY, entryW, BTN_H)
    self.searchEntry:initialise(); self.searchEntry:instantiate()
    self.searchEntry.font = FONT_S
    self.searchEntry:setOnlyNumbers(false)
    if self.searchEntry.setTooltip then
        self.searchEntry:setTooltip(tr("UI_CSR_ClaimsSearchTip",
            "Filter visible claims by owner, member, title, faction, coordinates, or vehicle name/key/id."))
    end
    self.searchEntry.onTextChange = function() CSR_ClaimsManagerPanel.onSearchChanged(self) end
    self:addChild(self.searchEntry)

    self.searchClearBtn = ISButton:new(entryX + entryW + 6, searchY,
        clearW, BTN_H, tr("UI_CSR_ClaimsSearchClear", "Clear"),
        self, CSR_ClaimsManagerPanel.onClearSearch)
    self.searchClearBtn:initialise(); self.searchClearBtn:instantiate()
    self.searchClearBtn.font = FONT_S
    self:addChild(self.searchClearBtn)

    -- List
    local listY = searchY + BTN_H + BORDER
    local listH = self.height - listY - (BTN_H * 3 + BORDER * 5)
    self.list = ISScrollingListBox:new(BORDER, listY,
        self.width - BORDER * 2, listH)
    self.list:initialise(); self.list:instantiate()
    self.list.itemheight = ITEM_H
    self.list.font = FONT_S
    self.list.drawBorder = true
    self.list.parentPanel = self
    self.list.doDrawItem = CSR_ClaimsManagerPanel.drawRow
    -- Make the list background transparent so the per-tab watermark drawn
    -- by the panel's prerender shows through. Row contrast is preserved by
    -- the alt-row stripe and selection highlight drawn in drawRow().
    self.list.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self:addChild(self.list)

    -- Action buttons (row 1)
    local btnY = self.list:getBottom() + BORDER
    self.releaseBtn = ISButton:new(BORDER, btnY, 100, BTN_H,
        tr("UI_CSR_ClaimsRelease", "Release"),
        self, CSR_ClaimsManagerPanel.onRelease)
    self.releaseBtn:initialise(); self.releaseBtn:instantiate()
    self.releaseBtn.borderColor = { r = 0.8, g = 0.3, b = 0.3, a = 1 }
    self.releaseBtn.enable = false
    self:addChild(self.releaseBtn)

    self.transferBtn = ISButton:new(BORDER + 110, btnY, 100, BTN_H,
        tr("UI_CSR_ClaimsTransfer", "Transfer"),
        self, CSR_ClaimsManagerPanel.onTransfer)
    self.transferBtn:initialise(); self.transferBtn:instantiate()
    self.transferBtn.borderColor = { r = 0.6, g = 0.6, b = 0.3, a = 1 }
    self.transferBtn.enable = false
    self:addChild(self.transferBtn)

    self.roleBtn = ISButton:new(BORDER + 220, btnY, 100, BTN_H,
        tr("UI_CSR_ClaimsSetRole", "Set Role"),
        self, CSR_ClaimsManagerPanel.onSetRole)
    self.roleBtn:initialise(); self.roleBtn:instantiate()
    self.roleBtn.borderColor = { r = 0.5, g = 0.5, b = 0.7, a = 1 }
    self.roleBtn.enable = false
    self:addChild(self.roleBtn)

    self.mapBtn = ISButton:new(BORDER + 330, btnY, 110, BTN_H,
        tr("UI_CSR_ClaimsShowMap", "Show On Map"),
        self, CSR_ClaimsManagerPanel.onShowOnMap)
    self.mapBtn:initialise(); self.mapBtn:instantiate()
    self.mapBtn.borderColor = { r = 0.4, g = 0.5, b = 0.7, a = 1 }
    self.mapBtn.enable = false
    self:addChild(self.mapBtn)

    -- Admin-only Teleport button (rendered to the right of Show On Map).
    self.tpBtn = ISButton:new(BORDER + 450, btnY, 100, BTN_H,
        tr("UI_CSR_ClaimsAdminTeleport", "Teleport"),
        self, CSR_ClaimsManagerPanel.onAdminTeleport)
    self.tpBtn:initialise(); self.tpBtn:instantiate()
    self.tpBtn.borderColor = { r = 0.7, g = 0.4, b = 0.7, a = 1 }
    self.tpBtn.enable = false
    self.tpBtn:setTooltip(tr("UI_CSR_ClaimsAdminTeleportTip",
        "Admin-only: teleport to this claim."))
    -- Hide for non-admin clients.
    local lp = getPlayer()
    local lvl = lp and lp.getAccessLevel and lp:getAccessLevel() or ""
    if lvl ~= "admin" and lvl ~= "Admin" then
        self.tpBtn:setVisible(false)
    end
    self:addChild(self.tpBtn)

    local btn2Y = btnY + BTN_H + 4
    self.respawnBtn = ISButton:new(BORDER, btn2Y, 130, BTN_H,
        tr("UI_CSR_ClaimsSetRespawn", "Set Respawn"),
        self, CSR_ClaimsManagerPanel.onSetRespawn)
    self.respawnBtn:initialise(); self.respawnBtn:instantiate()
    self.respawnBtn.borderColor = { r = 0.4, g = 0.7, b = 0.5, a = 1 }
    self.respawnBtn.enable = false
    self:addChild(self.respawnBtn)

    self.clearRespawnBtn = ISButton:new(BORDER + 140, btn2Y, 130, BTN_H,
        tr("UI_CSR_ClaimsClearRespawn", "Clear Respawn"),
        self, CSR_ClaimsManagerPanel.onClearRespawn)
    self.clearRespawnBtn:initialise(); self.clearRespawnBtn:instantiate()
    self.clearRespawnBtn.borderColor = { r = 0.7, g = 0.4, b = 0.4, a = 1 }
    self:addChild(self.clearRespawnBtn)

    -- v1.8.6: vehicle-row Manage Allowed Users dialog.
    -- v1.8.7: extended to also cover personal + faction safehouse rows so
    -- safehouse owners can finally add and remove members from the Claims
    -- Manager panel without the vanilla User Panel detour.
    self.manageBtn = ISButton:new(BORDER + 280, btn2Y, 150, BTN_H,
        tr("UI_CSR_ClaimsManageMembers", "Manage Members"),
        self, CSR_ClaimsManagerPanel.onManageAllowed)
    self.manageBtn:initialise(); self.manageBtn:instantiate()
    self.manageBtn.borderColor = { r = 0.5, g = 0.5, b = 0.7, a = 1 }
    self.manageBtn.enable = false
    self:addChild(self.manageBtn)

    self.expandBtn = ISButton:new(BORDER + 440, btn2Y, 130, BTN_H,
        tr("UI_CSR_ClaimsExpand", "Expand"),
        self, CSR_ClaimsManagerPanel.onExpand)
    self.expandBtn:initialise(); self.expandBtn:instantiate()
    self.expandBtn.borderColor = { r = 0.4, g = 0.7, b = 0.8, a = 1 }
    self.expandBtn.enable = false
    self.expandBtn:setTooltip(tr("UI_CSR_ClaimsExpandTip",
        "Increase a personal or faction safehouse claim."))
    self:addChild(self.expandBtn)

    -- v1.8.35: third button row -- Invite / Kick / My Borders / Audit.
    local btn3Y = btn2Y + BTN_H + 4
    self.inviteBtn = ISButton:new(BORDER, btn3Y, 130, BTN_H,
        tr("UI_CSR_ClaimsInvitePlayer", "Invite Player"),
        self, CSR_ClaimsManagerPanel.onInvitePlayer)
    self.inviteBtn:initialise(); self.inviteBtn:instantiate()
    self.inviteBtn.borderColor = { r = 0.4, g = 0.6, b = 0.9, a = 1 }
    self.inviteBtn.enable = false
    self:addChild(self.inviteBtn)

    self.kickBtn = ISButton:new(BORDER + 140, btn3Y, 130, BTN_H,
        tr("UI_CSR_ClaimsKickPlayer", "Kick Member"),
        self, CSR_ClaimsManagerPanel.onKickMember)
    self.kickBtn:initialise(); self.kickBtn:instantiate()
    self.kickBtn.borderColor = { r = 0.8, g = 0.4, b = 0.4, a = 1 }
    self.kickBtn.enable = false
    self:addChild(self.kickBtn)

    self.hlBtn = ISButton:new(BORDER + 280, btn3Y, 150, BTN_H,
        tr("UI_CSR_ClaimsToggleHighlight", "My Borders"),
        self, CSR_ClaimsManagerPanel.onToggleHighlight)
    self.hlBtn:initialise(); self.hlBtn:instantiate()
    self.hlBtn.borderColor = { r = 0.85, g = 0.7, b = 0.3, a = 1 }
    self.hlBtn.enable = false
    if getText then
        self.hlBtn:setTooltip(getText("Tooltip_CSR_SafehouseOutlineToggle"))
    end
    self:addChild(self.hlBtn)

    self.auditBtn = ISButton:new(BORDER + 440, btn3Y, 130, BTN_H,
        tr("UI_CSR_ClaimsAuditLog", "Audit Log"),
        self, CSR_ClaimsManagerPanel.onShowAudit)
    self.auditBtn:initialise(); self.auditBtn:instantiate()
    self.auditBtn.borderColor = { r = 0.6, g = 0.6, b = 0.6, a = 1 }
    self.auditBtn.enable = false
    self:addChild(self.auditBtn)

    self.legacyRuntimeBtn = ISButton:new(BORDER + 580, btn3Y, 124, BTN_H,
        tr("UI_CSR_ClaimsPurgeLegacyRuntime", "Purge Legacy"),
        self, CSR_ClaimsManagerPanel.onPurgeLegacyRuntimeVehicles)
    self.legacyRuntimeBtn:initialise(); self.legacyRuntimeBtn:instantiate()
    self.legacyRuntimeBtn.borderColor = { r = 0.65, g = 0.35, b = 0.95, a = 1 }
    self.legacyRuntimeBtn.enable = false
    self.legacyRuntimeBtn:setTooltip(tr("UI_CSR_ClaimsPurgeLegacyRuntimeTip",
        "Admin cleanup: removes stale runtime-ID vehicle rows and clears loaded legacy vehicle owner mirrors. It does not delete or damage vehicles, and it leaves current sql:/csr: claims alone."))
    self.legacyRuntimeBtn:setVisible(false)
    self:addChild(self.legacyRuntimeBtn)

    self:populate()
end

-- =========================================================================
-- Tab selection
-- =========================================================================

function CSR_ClaimsManagerPanel:onTabPersonal(button) self:setTab(TAB_PERSONAL) end
function CSR_ClaimsManagerPanel:onTabFaction(button)  self:setTab(TAB_FACTION)  end
function CSR_ClaimsManagerPanel:onTabVehicle(button)  self:setTab(TAB_VEHICLE)  end

function CSR_ClaimsManagerPanel:setTab(tab)
    self.activeTab = tab
    self:populate()
end

function CSR_ClaimsManagerPanel:getSearchText()
    if self.searchEntry then
        local text = ""
        if self.searchEntry.getInternalText then
            text = self.searchEntry:getInternalText()
        elseif self.searchEntry.getText then
            text = self.searchEntry:getText()
        end
        return trim(text or "")
    end
    return trim(self.searchText or "")
end

function CSR_ClaimsManagerPanel:onSearchChanged()
    self.searchText = self:getSearchText()
    self:populate()
end

function CSR_ClaimsManagerPanel:onClearSearch(button)
    self.searchText = ""
    if self.searchEntry then
        self.searchEntry:setText("")
    end
    self:populate()
end

local function tintTabButton(btn, active)
    if not btn then return end
    if active then
        -- Bright gold fill so the active tab reads at a glance.
        btn.borderColor = { r = 1.0, g = 0.84, b = 0.10, a = 1 }
        btn.backgroundColor = { r = 0.55, g = 0.42, b = 0.05, a = 0.95 }
        btn.backgroundColorMouseOver = { r = 0.65, g = 0.50, b = 0.08, a = 0.95 }
    else
        btn.borderColor = { r = 0.45, g = 0.45, b = 0.45, a = 1 }
        btn.backgroundColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.85 }
        btn.backgroundColorMouseOver = { r = 0.18, g = 0.18, b = 0.22, a = 0.95 }
    end
end

-- =========================================================================
-- Populate / list rendering
-- =========================================================================

function CSR_ClaimsManagerPanel:collectRows()
    local rows = {}
    local mirror = (CSR_ClaimClient and CSR_ClaimClient._claimMirror) or {}
    local viewer = self.player or getPlayer()
    local user = safeUsername(viewer)
    local admin = isAdmin(viewer)
    local ownedFacs = buildOwnedFactionSet(viewer)
    local searchText = self:getSearchText()
    local visibleCount = 0

    for _, row in pairs(mirror) do
        if type(row) == "table" and row.kind == self.activeTab then
            local canSee, canManage = viewerRights(row, viewer, ownedFacs, admin)
            if canSee then
                visibleCount = visibleCount + 1
                if rowMatchesSearch(row, searchText) then
                    rows[#rows + 1] = {
                        row = row, canManage = canManage, ownedByMe = row.owner == user,
                    }
                end
            end
        end
    end

    table.sort(rows, function(a, b)
        return rowSortKey(a.row, user) < rowSortKey(b.row, user)
    end)
    return rows, user, admin, ownedFacs, visibleCount, searchText
end

local function describeRow(entry)
    local row = entry.row
    if row.kind == "vehicle" then
        local title = row.title
        if not title or title == "" then title = "(unnamed vehicle)" end
        local key = row.vehicleKey or ""
        return string.format("[V] %s  @ (%d, %d)  owner: %s  key: %s",
            title,
            tonumber(row.lastVehicleX or row.x) or 0,
            tonumber(row.lastVehicleY or row.y) or 0,
            row.owner or "", key)
    elseif row.kind == "faction" then
        local title = row.title
        if not title or title == "" then title = "(unnamed safehouse)" end
        return string.format("[F:%s] %s  @ (%d, %d) %dx%d  owner: %s",
            row.factionName or "", title,
            tonumber(row.x) or 0, tonumber(row.y) or 0,
            tonumber(row.w) or 0, tonumber(row.h) or 0,
            row.owner or "")
    end
    -- personal
    local title = row.title
    if not title or title == "" then title = (row.owner or "") .. "'s safehouse" end
    return string.format("[P] %s  @ (%d, %d) %dx%d  owner: %s",
        title,
        tonumber(row.x) or 0, tonumber(row.y) or 0,
        tonumber(row.w) or 0, tonumber(row.h) or 0,
        row.owner or "")
end

function CSR_ClaimsManagerPanel:populate()
    if not self.list then return end
    self.list:clear()
    self.list.selected = 0
    self.releaseBtn.enable  = false
    self.transferBtn.enable = false
    self.roleBtn.enable     = false
    self.mapBtn.enable      = false
    if self.tpBtn then self.tpBtn.enable = false end
    if self.respawnBtn then self.respawnBtn.enable = false end
    if self.manageBtn then self.manageBtn.enable = false end
    if self.expandBtn then self.expandBtn.enable = false end

    -- v1.8.35
    if self.inviteBtn then self.inviteBtn.enable = false end
    if self.kickBtn then self.kickBtn.enable = false end
    if self.hlBtn then self.hlBtn.enable = false end
    if self.auditBtn then self.auditBtn.enable = false end
    if self.legacyRuntimeBtn then self.legacyRuntimeBtn.enable = false end

    tintTabButton(self.personalTabBtn, self.activeTab == TAB_PERSONAL)
    tintTabButton(self.factionTabBtn,  self.activeTab == TAB_FACTION)
    tintTabButton(self.vehicleTabBtn,  self.activeTab == TAB_VEHICLE)

    -- v1.8.1: explicit breadcrumb so the user always sees which view is active.
    if self.activeTabLabel and self.activeTabLabel.setName then
        local name = "Personal"
        if     self.activeTab == TAB_FACTION then name = "Faction"
        elseif self.activeTab == TAB_VEHICLE then name = "Vehicle"
        end
        self.activeTabLabel:setName((tr("UI_CSR_ClaimsActiveTab",
            "Active:")) .. " " .. name)
    end

    local rows, user, admin, ownedFacs, visibleCount, searchText = self:collectRows()
    local hasSearch = trim(searchText or "") ~= ""
    local showLegacyRuntime = admin and self.activeTab == TAB_VEHICLE
    if self.legacyRuntimeBtn then
        self.legacyRuntimeBtn:setVisible(showLegacyRuntime)
        self.legacyRuntimeBtn.enable = showLegacyRuntime
    end

    -- Counter line
    if self.counterLabel and self.counterLabel.setName then
        local cap, mineCount = 0, 0
        if hasSearch then
            self.counterLabel:setName("(" .. tostring(#rows)
                .. "/" .. tostring(visibleCount or #rows) .. ")")
        elseif self.activeTab == TAB_PERSONAL then
            cap = maxPersonalClaims()
            for i = 1, #rows do
                if rows[i].ownedByMe then mineCount = mineCount + 1 end
            end
            self.counterLabel:setName(string.format("(%d/%d)", mineCount, cap))
        elseif self.activeTab == TAB_FACTION then
            cap = maxFactionClaims()
            for i = 1, #rows do
                if rows[i].ownedByMe then mineCount = mineCount + 1 end
            end
            self.counterLabel:setName(string.format("(%d/%d)", mineCount, cap))
        else
            self.counterLabel:setName("(" .. tostring(#rows) .. ")")
        end
    end

    if #rows == 0 then
        local emptyText = tr("UI_CSR_ClaimsNone", "(no claims visible to you)")
        if hasSearch then
            emptyText = tr("UI_CSR_ClaimsNoSearchResults",
                "(no matching claims)")
        end
        self.list:addItem(emptyText, { type = "empty" })
        return
    end

    for i = 1, #rows do
        local entry = rows[i]
        self.list:addItem(describeRow(entry), {
            type        = "claim",
            row         = entry.row,
            canManage   = entry.canManage,
            ownedByMe   = entry.ownedByMe,
        })
    end
end

function CSR_ClaimsManagerPanel.drawRow(self, y, item, alt)
    local data = item.item
    local a = 0.9
    if data.type == "empty" then
        self:drawText(item.text, 6, y + 2, 0.6, 0.6, 0.6, a, self.font)
        return y + self.itemheight
    end
    if self.selected == item.index then
        self:drawRect(0, y, self:getWidth(), self.itemheight - 1,
            0.4, 0.2, 0.5, 0.2)
        if self.parentPanel then
            local row = data.row
            local panel = self.parentPanel
            panel.releaseBtn.enable  = data.canManage
            panel.transferBtn.enable = data.canManage and (row.kind ~= "vehicle")
            panel.roleBtn.enable     = data.canManage and (row.kind ~= "vehicle")
            panel.mapBtn.enable      = true
            if panel.tpBtn then
                panel.tpBtn.enable = true
            end
            if panel.manageBtn then
                -- v1.8.7: enabled for any row the viewer can manage --
                -- vehicle (allowed list), personal safehouse (members),
                -- or faction safehouse (members).
                panel.manageBtn.enable = data.canManage == true
            end
            if panel.expandBtn then
                panel.expandBtn.enable = false
            end
            -- Respawn pin: only personal/faction claims, only if viewer
            -- is a member or the owner.
            local respawnEligible = (row.kind == "personal" or row.kind == "faction")
                                    and (data.ownedByMe or data.canManage or panel:isMemberOf(row))
            panel.respawnBtn.enable = respawnEligible

            -- v1.8.35: invite / kick / local border / audit gating from
            -- CSR_ClaimPermissions.viewerRights.
            if CSR_ClaimPermissions and CSR_ClaimPermissions.viewerRights then
                local lp = getPlayer()
                local rights = CSR_ClaimPermissions.viewerRights(row, lp)
                if panel.inviteBtn then panel.inviteBtn.enable = rights.canInvite == true end
                if panel.kickBtn   then panel.kickBtn.enable   = rights.canKick   == true end
                if panel.hlBtn     then panel.hlBtn.enable     = localOutlineEligible(panel, row) end
                if panel.auditBtn  then panel.auditBtn.enable  = rights.canAudit  == true end
                if panel.expandBtn then
                    panel.expandBtn.enable = claimExpansionOn()
                        and (row.kind == "personal" or row.kind == "faction")
                        and rights.canExpand == true
                end
            end
        end
    end
    self:drawRectBorder(0, y, self:getWidth(), self.itemheight - 1, 0.5,
        self.borderColor.r, self.borderColor.g, self.borderColor.b)
    local r, g, bcol = 1, 1, 1
    if data.row and data.row.kind == "faction" then r, g, bcol = 0.95, 0.85, 0.4
    elseif data.row and data.row.kind == "vehicle" then r, g, bcol = 0.6, 0.85, 1.0 end
    self:drawText(item.text, 6, y + 2, r, g, bcol, a, self.font)
    return y + self.itemheight
end

-- =========================================================================
-- Selection helpers
-- =========================================================================

local function getSelectedRow(panel)
    local idx = panel.list.selected
    if not idx or idx == 0 then return nil end
    local it = panel.list.items[idx]
    if not it or not it.item or it.item.type ~= "claim" then return nil end
    return it.item.row, it.item.canManage
end

local function localOutlineRankAllowed(row, rank)
    if not row or not CSR_ClaimPermissions or not CSR_ClaimPermissions.RANK then return false end
    if row.kind == "faction" then
        return rank <= CSR_ClaimPermissions.RANK.ally
    end
    return rank <= CSR_ClaimPermissions.RANK.member
end

localOutlineEligible = function(panel, row)
    if not row then return false end
    if row.kind ~= "personal" and row.kind ~= "faction" then return false end
    local player = (panel and panel.player) or getPlayer()
    if not player then return false end
    if panel and panel.isMemberOf and panel:isMemberOf(row) then return true end
    if CSR_ClaimPermissions and CSR_ClaimPermissions.getRank and CSR_ClaimPermissions.RANK then
        local rank = CSR_ClaimPermissions.getRank(row, player)
        return localOutlineRankAllowed(row, rank)
    end
    return false
end

-- =========================================================================
-- Action callbacks
-- =========================================================================

function CSR_ClaimsManagerPanel:onClose(button)
    self:setVisible(false)
    self:removeFromUIManager()
    CSR_ClaimsManagerPanel.instance = nil
end

function CSR_ClaimsManagerPanel:onRefresh(button)
    if CSR_ClaimClient and CSR_ClaimClient.requestBundle then
        CSR_ClaimClient.requestBundle(true)
    end
    self:populate()
end

function CSR_ClaimsManagerPanel:onRelease(button)
    local row, canManage = getSelectedRow(self)
    if not row or not canManage then return end
    local panel = self
    local label = row.title or row.owner or tostring(row.id)
    local msg = tr("UI_CSR_ClaimsReleaseConfirm",
        "Release this claim?") .. "\n[" .. tostring(label) .. "]"
    local modal = ISModalDialog:new(
        getCore():getScreenWidth() / 2 - 175,
        getCore():getScreenHeight() / 2 - 75,
        350, 130, msg, true, nil,
        function(_, btn)
            if btn and btn.internal == "YES" then
                CSR_ClaimClient.requestRelease(row.id)
                panel:populate()
            end
        end)
    modal:initialise(); modal:addToUIManager()
end

function CSR_ClaimsManagerPanel:onTransfer(button)
    local row, canManage = getSelectedRow(self)
    if not row or not canManage then return end
    if row.kind == "vehicle" then return end

    local candidates = Registry.csvList(row.membersCSV)
    if #candidates == 0 then
        local modal = ISModalDialog:new(
            getCore():getScreenWidth() / 2 - 175,
            getCore():getScreenHeight() / 2 - 75,
            350, 130,
            tr("UI_CSR_ClaimsNoTransferTarget",
                "No members to transfer to. Add members first."),
            false, nil, nil)
        modal:initialise(); modal:addToUIManager()
        return
    end

    local panel = self
    local cx = getCore():getScreenWidth() / 2 - 175
    local cy = getCore():getScreenHeight() / 2 - 100
    local picker = ISPanel:new(cx, cy, 350, 200)
    picker:initialise()
    picker.borderColor     = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
    picker.backgroundColor = { r = 0.05, g = 0.05, b = 0.10, a = 0.95 }
    picker.moveWithMouse   = true
    picker:addToUIManager()

    local lab = ISLabel:new(BORDER, BORDER, ITEM_H,
        tr("UI_CSR_ClaimsTransferPick", "Transfer to:"),
        1, 1, 1, 1, FONT_S, true)
    lab:initialise(); lab:instantiate(); picker:addChild(lab)

    local cb = ISComboBox:new(BORDER, BORDER + ITEM_H + 4,
        350 - BORDER * 2, 24)
    cb:initialise(); cb:instantiate()
    for i = 1, #candidates do cb:addOption(candidates[i]) end
    cb.selected = 1
    picker:addChild(cb)

    local okBtn = ISButton:new(BORDER, 200 - BTN_H - BORDER, 100, BTN_H,
        tr("UI_Ok", "OK"), picker, function()
            local pick = cb:getOptionText(cb.selected)
            if pick and pick ~= "" then
                CSR_ClaimClient.requestTransfer(row.id, pick)
            end
            picker:setVisible(false); picker:removeFromUIManager()
            panel:populate()
        end)
    okBtn:initialise(); okBtn:instantiate()
    okBtn.enable = #candidates > 0
    okBtn.borderColor = { r = 0.4, g = 0.7, b = 0.4, a = 1 }
    picker:addChild(okBtn)

    local caBtn = ISButton:new(350 - 100 - BORDER, 200 - BTN_H - BORDER,
        100, BTN_H,
        tr("UI_Cancel", "Cancel"), picker, function()
            picker:setVisible(false); picker:removeFromUIManager()
        end)
    caBtn:initialise(); caBtn:instantiate()
    caBtn.borderColor = { r = 0.7, g = 0.3, b = 0.3, a = 1 }
    picker:addChild(caBtn)
end

function CSR_ClaimsManagerPanel:onSetRole(button)
    local row, canManage = getSelectedRow(self)
    if not row or not canManage then return end
    if row.kind == "vehicle" then return end

    local panel = self
    local cx = getCore():getScreenWidth() / 2 - 200
    local cy = getCore():getScreenHeight() / 2 - 110
    local picker = ISPanel:new(cx, cy, 400, 220)
    picker:initialise()
    picker.borderColor     = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
    picker.backgroundColor = { r = 0.05, g = 0.05, b = 0.10, a = 0.95 }
    picker.moveWithMouse   = true
    picker:addToUIManager()

    local lab = ISLabel:new(BORDER, BORDER, ITEM_H,
        tr("UI_CSR_ClaimsSetRolePrompt", "Set role for member:"),
        1, 1, 1, 1, FONT_S, true)
    lab:initialise(); lab:instantiate(); picker:addChild(lab)

    local existing = Registry.csvList(row.membersCSV)
    local exclude = csvSet(row.membersCSV)
    exclude[tostring(row.owner or "")] = true
    local online = sortedOnlinePlayerNames(self.player or getPlayer(), exclude)
    local targets = {}
    local seen = {}
    for i = 1, #existing do
        local name = tostring(existing[i] or "")
        if name ~= "" and not seen[name] then
            targets[#targets + 1] = name
            seen[name] = true
        end
    end
    for i = 1, #online do
        local name = tostring(online[i] or "")
        if name ~= "" and not seen[name] then
            targets[#targets + 1] = name
            seen[name] = true
        end
    end

    local memCb = ISComboBox:new(BORDER, BORDER + ITEM_H + 4,
        400 - BORDER * 2, 24)
    memCb:initialise(); memCb:instantiate()
    if #targets == 0 then
        memCb:addOption(tr("UI_CSR_ClaimsNoOnlinePlayers",
            "(no eligible online players)"))
    else
        for i = 1, #targets do memCb:addOption(targets[i]) end
    end
    memCb.selected = 1
    picker:addChild(memCb)

    local lab2 = ISLabel:new(BORDER, BORDER + ITEM_H + 44, ITEM_H,
        tr("UI_CSR_ClaimsRoleLabel", "Role (blank = remove member):"),
        1, 1, 1, 1, FONT_S, true)
    lab2:initialise(); lab2:instantiate(); picker:addChild(lab2)

    local roleCb = ISComboBox:new(BORDER, BORDER + ITEM_H + 64,
        400 - BORDER * 2, 24)
    roleCb:initialise(); roleCb:instantiate()
    roleCb:addOption("") -- remove
    roleCb:addOption("member")
    roleCb:addOption("officer")
    roleCb:addOption("admin")
    roleCb.selected = 2
    picker:addChild(roleCb)

    local okBtn = ISButton:new(BORDER, 220 - BTN_H - BORDER,
        100, BTN_H, tr("UI_Ok", "OK"), picker, function()
            local who = memCb:getOptionText(memCb.selected) or ""
            who = who:gsub("^%s+", ""):gsub("%s+$", "")
            local roleText = roleCb:getOptionText(roleCb.selected) or ""
            if who ~= "" and #targets > 0 then
                CSR_ClaimClient.requestSetRole(row.id, who, roleText)
            end
            picker:setVisible(false); picker:removeFromUIManager()
            panel:populate()
        end)
    okBtn:initialise(); okBtn:instantiate()
    okBtn.enable = #targets > 0
    okBtn.borderColor = { r = 0.4, g = 0.7, b = 0.4, a = 1 }
    picker:addChild(okBtn)

    local caBtn = ISButton:new(400 - 100 - BORDER, 220 - BTN_H - BORDER,
        100, BTN_H,
        tr("UI_Cancel", "Cancel"), picker, function()
            picker:setVisible(false); picker:removeFromUIManager()
        end)
    caBtn:initialise(); caBtn:instantiate()
    caBtn.borderColor = { r = 0.7, g = 0.3, b = 0.3, a = 1 }
    picker:addChild(caBtn)
end

function CSR_ClaimsManagerPanel:onShowOnMap(button)
    local row = getSelectedRow(self)
    if not row then return end
    local cx, cy
    if row.kind == "vehicle" then
        cx = tonumber(row.lastVehicleX) or tonumber(row.x) or 0
        cy = tonumber(row.lastVehicleY) or tonumber(row.y) or 0
        local vehicleKey = tostring(row.vehicleKey or "")
        if vehicleKey ~= "" and CSR_VehicleClaim
                and CSR_VehicleClaim.findLoadedVehicleByKey then
            local v = CSR_VehicleClaim.findLoadedVehicleByKey(vehicleKey)
            if v then
                cx = tonumber(v:getX()) or cx
                cy = tonumber(v:getY()) or cy
            end
        end
    else
        cx = (tonumber(row.x) or 0) + (tonumber(row.w) or 1) / 2
        cy = (tonumber(row.y) or 0) + (tonumber(row.h) or 1) / 2
    end
    if ISWorldMap and ISWorldMap.ShowWorldMap then
        -- Vanilla signature: (playerNum, centerX, centerY, zoom).
        -- Passing coords directly avoids the post-show centerOn race
        -- where ISWorldMap_instance is sometimes nil for one frame.
        ISWorldMap.ShowWorldMap(0, cx, cy)
    end
    -- Belt-and-braces: re-center if the global is now available.
    local map = ISWorldMap_instance
    if map and map.mapAPI and map.mapAPI.centerOn then
        map.mapAPI:centerOn(cx, cy)
    end
end

function CSR_ClaimsManagerPanel:onAdminTeleport(button)
    local row = getSelectedRow(self)
    if not row then return end
    local lp = getPlayer()
    local lvl = lp and lp.getAccessLevel and lp:getAccessLevel() or ""
    if lvl ~= "admin" and lvl ~= "Admin" then return end
    if CSR_ClaimClient and CSR_ClaimClient.requestAdminTeleport then
        CSR_ClaimClient.requestAdminTeleport(row.id)
    end
end

function CSR_ClaimsManagerPanel:onPurgeLegacyRuntimeVehicles(button)
    local lp = getPlayer()
    if not isAdmin(lp) then return end
    if self.activeTab ~= TAB_VEHICLE then return end

    local panel = self
    local msg = tr("UI_CSR_ClaimsPurgeLegacyRuntimeConfirm",
        "Purge all legacy runtime-ID vehicle claim rows and loaded legacy vehicle owner mirrors?\n\nCurrent sql:/csr: vehicle claims stay intact, and vehicles are not deleted or damaged.")
    local modal = ISModalDialog:new(
        getCore():getScreenWidth() / 2 - 220,
        getCore():getScreenHeight() / 2 - 90,
        440, 160, msg, true, nil,
        function(_, btn)
            if btn and btn.internal == "YES"
                    and CSR_ClaimClient
                    and CSR_ClaimClient.requestAdminPurgeLegacyVehicles then
                CSR_ClaimClient.requestAdminPurgeLegacyVehicles()
                if CSR_ClaimClient.requestBundle then
                    CSR_ClaimClient.requestBundle(true)
                end
                panel:populate()
            end
        end)
    modal:initialise(); modal:addToUIManager()
end

local function entryInt(entry)
    if not entry then return 0 end
    local text = ""
    if entry.getInternalText then text = entry:getInternalText()
    elseif entry.getText then text = entry:getText() end
    local n = math.floor(tonumber(text) or 0)
    if n < 0 then n = 0 end
    return n
end

function CSR_ClaimsManagerPanel:onExpand(button)
    local row = getSelectedRow(self)
    if not row then return end
    if row.kind ~= "personal" and row.kind ~= "faction" then return end
    if not claimExpansionOn() then return end
    if CSR_ClaimPermissions and CSR_ClaimPermissions.viewerRights then
        local rights = CSR_ClaimPermissions.viewerRights(row, getPlayer())
        if rights.canExpand ~= true then return end
    end

    local panel = self
    local sw = (getCore and getCore():getScreenWidth()) or 800
    local sh = (getCore and getCore():getScreenHeight()) or 600
    local w, h = 460, 300
    local picker = ISPanel:new(sw / 2 - w / 2, sh / 2 - h / 2, w, h)
    picker:initialise()
    picker.borderColor     = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
    picker.backgroundColor = { r = 0.05, g = 0.05, b = 0.10, a = 0.96 }
    picker.moveWithMouse   = true
    picker:addToUIManager()

    local title = ISLabel:new(BORDER, BORDER, ITEM_H,
        tr("UI_CSR_ClaimsExpandTitle", "Expand Safezone"),
        1, 0.85, 0.2, 1, FONT_M, true)
    title:initialise(); title:instantiate(); picker:addChild(title)

    local current = string.format("%s (%d,%d) %dx%d",
        tr("UI_CSR_ClaimsExpandCurrent", "Current:"),
        tonumber(row.x) or 0, tonumber(row.y) or 0,
        tonumber(row.w) or 1, tonumber(row.h) or 1)
    local currentLabel = ISLabel:new(BORDER, BORDER + 28, ITEM_H,
        current, 0.85, 0.85, 0.85, 1, FONT_S, true)
    currentLabel:initialise(); currentLabel:instantiate(); picker:addChild(currentLabel)

    local function addBox(labelKey, fallback, x, y)
        local lab = ISLabel:new(x, y, ITEM_H, tr(labelKey, fallback),
            1, 1, 1, 1, FONT_S, true)
        lab:initialise(); lab:instantiate(); picker:addChild(lab)
        local box = ISTextEntryBox:new("0", x, y + ITEM_H + 2, 90, 22)
        box:initialise(); box:instantiate()
        box.font = FONT_S
        if box.setOnlyNumbers then box:setOnlyNumbers(true) end
        picker:addChild(box)
        return box
    end

    local westBox  = addBox("UI_CSR_ClaimsExpandWest",  "West",  BORDER,      68)
    local eastBox  = addBox("UI_CSR_ClaimsExpandEast",  "East",  BORDER + 110, 68)
    local northBox = addBox("UI_CSR_ClaimsExpandNorth", "North", BORDER + 220, 68)
    local southBox = addBox("UI_CSR_ClaimsExpandSouth", "South", BORDER + 330, 68)

    local estimate = ISLabel:new(BORDER, 126, ITEM_H, "",
        0.85, 0.95, 1.0, 1, FONT_S, true)
    estimate:initialise(); estimate:instantiate(); picker:addChild(estimate)

    local rules = ISLabel:new(BORDER, 150, ITEM_H, "",
        0.95, 0.82, 0.45, 1, FONT_S, true)
    rules:initialise(); rules:instantiate(); picker:addChild(rules)

    local function bounds()
        local west  = entryInt(westBox)
        local east  = entryInt(eastBox)
        local north = entryInt(northBox)
        local south = entryInt(southBox)
        local nx = (tonumber(row.x) or 0) - west
        local ny = (tonumber(row.y) or 0) - north
        local nw = (tonumber(row.w) or 1) + west + east
        local nh = (tonumber(row.h) or 1) + north + south
        local added = (nw * nh) - ((tonumber(row.w) or 1) * (tonumber(row.h) or 1))
        return nx, ny, nw, nh, added
    end

    local function refreshEstimate()
        local nx, ny, nw, nh, added = bounds()
        local money, mats = claimExpansionCost(added)
        local text = string.format("%s (%d,%d) %dx%d  +%d  $%d  %s %d",
            tr("UI_CSR_ClaimsExpandNew", "New:"),
            nx, ny, nw, nh, added, money,
            tr("UI_CSR_ClaimsExpandMaterials", "materials"), mats)
        local maxAdded = claimExpansionMaxAdded()
        if nw > claimExpansionMaxWidth() or nh > claimExpansionMaxHeight()
                or (maxAdded > 0 and added > maxAdded) then
            text = text .. "  " .. tr("UI_CSR_ClaimsExpandOverLimit", "(over limit)")
        end
        if estimate and estimate.setName then estimate:setName(text) end

        local ruleText = string.format("%s %dx%d",
            tr("UI_CSR_ClaimsExpandLimit", "Limit:"), claimExpansionMaxWidth(),
            claimExpansionMaxHeight())
        if maxAdded > 0 then
            ruleText = ruleText .. "  " .. tr("UI_CSR_ClaimsExpandMaxAdded", "max added:")
                .. " " .. tostring(maxAdded)
        end
        if claimExpansionArchitectRequired() then
            ruleText = ruleText .. "  " .. tr("UI_CSR_ClaimsExpandArchitect", "Architect required")
        end
        if rules and rules.setName then rules:setName(ruleText) end
    end

    local function setAll(n)
        local s = tostring(n or 0)
        westBox:setText(s); eastBox:setText(s); northBox:setText(s); southBox:setText(s)
        refreshEstimate()
    end

    local presetY = 178
    local plus5 = ISButton:new(BORDER, presetY, 80, BTN_H, "+5",
        picker, function() setAll(5) end)
    plus5:initialise(); plus5:instantiate(); picker:addChild(plus5)

    local plus10 = ISButton:new(BORDER + 90, presetY, 80, BTN_H, "+10",
        picker, function() setAll(10) end)
    plus10:initialise(); plus10:instantiate(); picker:addChild(plus10)

    local calcBtn = ISButton:new(BORDER + 180, presetY, 110, BTN_H,
        tr("UI_CSR_ClaimsExpandRecalc", "Recalculate"),
        picker, function() refreshEstimate() end)
    calcBtn:initialise(); calcBtn:instantiate(); picker:addChild(calcBtn)

    local okBtn = ISButton:new(BORDER, h - BTN_H - BORDER, 110, BTN_H,
        tr("UI_CSR_ClaimsExpandConfirm", "Expand"),
        picker, function()
            local nx, ny, nw, nh = bounds()
            if CSR_ClaimClient and CSR_ClaimClient.requestResize then
                CSR_ClaimClient.requestResize(row.id, nx, ny, nw, nh)
            end
            picker:setVisible(false); picker:removeFromUIManager()
            panel:populate()
        end)
    okBtn:initialise(); okBtn:instantiate()
    okBtn.borderColor = { r = 0.4, g = 0.8, b = 0.5, a = 1 }
    picker:addChild(okBtn)

    local cancelBtn = ISButton:new(w - 110 - BORDER, h - BTN_H - BORDER,
        110, BTN_H, tr("UI_Cancel", "Cancel"),
        picker, function()
            picker:setVisible(false); picker:removeFromUIManager()
        end)
    cancelBtn:initialise(); cancelBtn:instantiate()
    cancelBtn.borderColor = { r = 0.7, g = 0.3, b = 0.3, a = 1 }
    picker:addChild(cancelBtn)

    refreshEstimate()
end

-- =========================================================================
-- Render
-- =========================================================================

-- Per-tab watermark textures. Personal uses the solo crest, faction uses
-- the multi-figure crest. Vehicle has no watermark (yet).
local CSR_TAB_BG_PATHS = {
    personal = "media/ui/CSR_SafehouseSoloBg.png",
    faction  = "media/ui/CSR_SafehouseBg.png",
}
local _csrTabBgCache = {}
local function getTabBgTexture(tab)
    if not tab then return nil end
    local cached = _csrTabBgCache[tab]
    if cached == nil then
        local path = CSR_TAB_BG_PATHS[tab]
        cached = (path and getTexture(path)) or false
        _csrTabBgCache[tab] = cached
    end
    if cached == false then return nil end
    return cached
end

local CSR_PANEL_OUTLINE = { a = 1.0, r = 0.86, g = 0.70, b = 0.28 }

function CSR_ClaimsManagerPanel:prerender()
    self:drawRect(0, 0, self.width, self.height,
        self.backgroundColor.a, self.backgroundColor.r,
        self.backgroundColor.g, self.backgroundColor.b)

    -- Faint crest watermark drawn inside the list area (not behind the
    -- whole panel -- the list draws its own opaque background which used
    -- to completely cover the watermark).
    local tex = getTabBgTexture(self.activeTab)
    if tex and self.list then
        local boxX = tonumber(self.list:getX()) or 0
        local boxY = tonumber(self.list:getY()) or 0
        local boxW = tonumber(self.list:getWidth()) or 0
        local boxH = tonumber(self.list:getHeight()) or 0
        if boxW > 4 and boxH > 4 then
            local tw = tonumber(tex.getWidth and tex:getWidth() or boxW) or 0
            local thh = tonumber(tex.getHeight and tex:getHeight() or boxH) or 0
            if tw > 0 and thh > 0 then
                local scale = math.min(boxW / tw, boxH / thh)
                if scale > 1 then scale = 1 end
                local drawW = math.floor(tw * scale)
                local drawH = math.floor(thh * scale)
                local drawX = boxX + math.floor((boxW - drawW) / 2)
                local drawY = boxY + math.floor((boxH - drawH) / 2)
                self:drawTextureScaled(tex, drawX, drawY, drawW, drawH, 0.22,
                    CSR_PANEL_OUTLINE.r, CSR_PANEL_OUTLINE.g, CSR_PANEL_OUTLINE.b)
            end
        end
    end

    self:drawRectBorder(0, 0, self.width, self.height,
        self.borderColor.a, self.borderColor.r,
        self.borderColor.g, self.borderColor.b)
end

-- =========================================================================
-- Server broadcast hook -- repopulate when claims change while open.
-- =========================================================================

local function onServerCommand(module, command, args)
    if module ~= "CommonSenseReborn" then return end
    if command ~= "CSR_ClaimAdded" and command ~= "CSR_ClaimRemoved"
        and command ~= "CSR_ClaimUpdated" and command ~= "CSR_ClaimsBundle" then
        return
    end
    local inst = CSR_ClaimsManagerPanel.instance
    if inst and inst.populate then
        inst:populate()
    end
end

if Events and not CSR_ClaimsManagerPanel._registered then
    CSR_ClaimsManagerPanel._registered = true
    Events.OnServerCommand.Add(onServerCommand)
end

-- =========================================================================
-- Respawn-pin actions
-- =========================================================================

function CSR_ClaimsManagerPanel:isMemberOf(row)
    if not row then return false end
    local user = safeUsername(self.player or getPlayer())
    if not user or user == "" then return false end
    if row.owner == user then return true end
    if not Registry or not Registry.csvList then return false end
    local list = Registry.csvList(row.membersCSV)
    for i = 1, #list do
        if list[i] == user then return true end
    end
    return false
end

function CSR_ClaimsManagerPanel:onSetRespawn(button)
    local row = getSelectedRow(self)
    if not row then return end
    if row.kind ~= "personal" and row.kind ~= "faction" then return end
    if not self:isMemberOf(row) then return end
    if CSR_ClaimClient and CSR_ClaimClient.requestSetRespawn then
        CSR_ClaimClient.requestSetRespawn(row.id)
    end
end

function CSR_ClaimsManagerPanel:onClearRespawn(button)
    if CSR_ClaimClient and CSR_ClaimClient.requestClearRespawn then
        CSR_ClaimClient.requestClearRespawn()
    end
end

-- =========================================================================
-- v1.8.35: Invite / Kick / local border / Audit handlers.
-- =========================================================================

function CSR_ClaimsManagerPanel:onInvitePlayer(button)
    local row = getSelectedRow(self)
    if not row then return end
    local exclude = csvSet(row.membersCSV)
    exclude[tostring(row.owner or "")] = true
    exclude[safeUsername(self.player or getPlayer())] = true
    local candidates = sortedOnlinePlayerNames(self.player or getPlayer(), exclude)
    showOnlineNamePicker(self,
        tr("UI_CSR_ClaimsInvitePrompt", "Invite online player:"),
        candidates,
        function(target)
            if CSR_ClaimInvitesClient and CSR_ClaimInvitesClient.invite then
                CSR_ClaimInvitesClient.invite(row.id, target, "member")
            end
        end)
end

local function existingMemberNames(row)
    local out = Registry.csvList(row and row.membersCSV or "")
    table.sort(out)
    return out
end

function CSR_ClaimsManagerPanel:onKickMember(button)
    local row = getSelectedRow(self)
    if not row then return end
    local candidates = existingMemberNames(row)
    showOnlineNamePicker(self,
        tr("UI_CSR_ClaimsKickPrompt", "Kick member:"),
        candidates,
        function(target)
            if CSR_ClaimInvitesClient and CSR_ClaimInvitesClient.kick then
                CSR_ClaimInvitesClient.kick(row.id, target)
            end
        end)
end

function CSR_ClaimsManagerPanel:onToggleHighlight(button)
    local row = getSelectedRow(self)
    if not row then return end
    if not localOutlineEligible(self, row) then return end
    if not (CSR_SafehouseOutline and CSR_SafehouseOutline.toggle) then return end
    local enabled = CSR_SafehouseOutline.toggle()
    if CSR_SafehouseOutline.forceRefresh then
        CSR_SafehouseOutline.forceRefresh()
    end
    if CSR_SafehouseOutline.notify then
        CSR_SafehouseOutline.notify((self and self.player) or getPlayer(), enabled)
    end
end

local AuditDialog = nil

local function onAuditServerCommand(module, command, args)
    if module ~= "CommonSenseReborn" then return end
    if command ~= "CSR_ClaimAuditTail" then return end
    if not AuditDialog or not AuditDialog.entry then return end
    local text = tostring((args and args.text) or "")
    text = text:gsub("|", "\n")
    AuditDialog.entry:setText(text)
end

if Events and Events.OnServerCommand then
    Events.OnServerCommand.Add(onAuditServerCommand)
end

function CSR_ClaimsManagerPanel:onShowAudit(button)
    local row = getSelectedRow(self)
    if not row then return end
    local sw = (getCore and getCore():getScreenWidth()) or 800
    local sh = (getCore and getCore():getScreenHeight()) or 600
    local w, h = 520, 400
    AuditDialog = ISCollapsableWindow:new(sw / 2 - w / 2, sh / 2 - h / 2, w, h)
    AuditDialog:initialise()
    AuditDialog:setTitle(tr("UI_CSR_ClaimsAuditTitle", "Claim Audit Log"))
    AuditDialog:addToUIManager()
    local entry = ISTextEntryBox:new("", 8, 28, w - 16, h - 36)
    entry:initialise(); entry:instantiate()
    entry:setMultipleLine(true)
    entry:setMaxLines(2000)
    entry:setEditable(false)
    AuditDialog:addChild(entry)
    AuditDialog.entry = entry
    entry:setText(tr("UI_CSR_ClaimsAuditLoading", "Loading audit tail..."))
    if CSR_ClaimInvitesClient and CSR_ClaimInvitesClient.queryAudit then
        CSR_ClaimInvitesClient.queryAudit(200)
    end
end

-- =========================================================================
-- v1.8.6: Manage Allowed Users (vehicle rows only)
-- v1.8.7: extended to cover personal + faction safehouse rows. Dialog opens
-- a small list with the row's current members + a free-text Add field. The
-- "kind" of the row decides which server command pair to send:
--   * vehicle  -> VehicleAddAllowed   / VehicleRemoveAllowed
--   * personal -> SafehouseAddMember  / SafehouseRemoveMember
--   * faction  -> FactionAddMember    / FactionRemoveMember
-- =========================================================================
function CSR_ClaimsManagerPanel:onManageAllowed(button)
    local row, canManage = getSelectedRow(self)
    if not row or not canManage then return end

    local kind = row.kind
    local title
    -- v1.8.7: per-kind dispatcher. Personal + faction safehouses route
    -- through the existing CSR_ClaimClient.requestSetRole pipeline (which
    -- already validates owner / admin / faction-owner on the server and
    -- mirrors to the registry). Vehicles continue to use the dedicated
    -- VehicleAddAllowed / VehicleRemoveAllowed commands so the legacy
    -- per-vehicle modData mirror stays in sync.
    local sendAdd, sendRemove
    if kind == "vehicle" then
        local rowId = tonumber(row.id) or 0
        sendAdd = function(name)
            sendClientCommand(getPlayer(), "CommonSenseReborn",
                "VehicleAddAllowed",
                {
                    rowId      = rowId,
                    vehicleKey = row.vehicleKey or "",
                    targetName = name,
                })
        end
        sendRemove = function(name)
            sendClientCommand(getPlayer(), "CommonSenseReborn",
                "VehicleRemoveAllowed",
                {
                    rowId      = rowId,
                    vehicleKey = row.vehicleKey or "",
                    targetName = name,
                })
        end
        title = tr("UI_CSR_ClaimsManageAllowedTitle",
            "Allowed users for this vehicle:")
    elseif kind == "personal" then
        local rid = row.id
        if not rid then return end
        sendAdd = function(name)
            if CSR_ClaimClient and CSR_ClaimClient.requestSetRole then
                CSR_ClaimClient.requestSetRole(rid, name, "member")
            end
        end
        sendRemove = function(name)
            if CSR_ClaimClient and CSR_ClaimClient.requestSetRole then
                CSR_ClaimClient.requestSetRole(rid, name, "")
            end
        end
        title = tr("UI_CSR_ClaimsManageMembersPersonal",
            "Members of this safehouse:")
    elseif kind == "faction" then
        local rid = row.id
        if not rid then return end
        sendAdd = function(name)
            if CSR_ClaimClient and CSR_ClaimClient.requestSetRole then
                CSR_ClaimClient.requestSetRole(rid, name, "member")
            end
        end
        sendRemove = function(name)
            if CSR_ClaimClient and CSR_ClaimClient.requestSetRole then
                CSR_ClaimClient.requestSetRole(rid, name, "")
            end
        end
        title = tr("UI_CSR_ClaimsManageMembersFaction",
            "Members of this faction safehouse:")
    else
        return
    end

    local cx = getCore():getScreenWidth() / 2 - 200
    local cy = getCore():getScreenHeight() / 2 - 130
    local picker = ISPanel:new(cx, cy, 400, 260)
    picker:initialise()
    picker.borderColor     = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
    picker.backgroundColor = { r = 0.05, g = 0.05, b = 0.10, a = 0.95 }
    picker.moveWithMouse   = true
    picker:addToUIManager()

    local lab = ISLabel:new(BORDER, BORDER, ITEM_H,
        title,
        1, 1, 1, 1, FONT_S, true)
    lab:initialise(); lab:instantiate(); picker:addChild(lab)

    -- Existing list
    local existing = Registry.csvList(row.membersCSV)
    local listBox = ISScrollingListBox:new(BORDER, BORDER + ITEM_H + 4,
        400 - BORDER * 2, 110)
    listBox:initialise(); listBox:instantiate()
    listBox.itemheight = ITEM_H
    listBox.font = FONT_S
    listBox.drawBorder = true
    if #existing == 0 then
        listBox:addItem(tr("UI_CSR_ClaimsAllowedNone",
            "(no members listed)"),
            { type = "empty" })
    else
        for i = 1, #existing do
            listBox:addItem(existing[i], { type = "user", name = existing[i] })
        end
    end
    picker:addChild(listBox)

    -- Add online user
    local lab2 = ISLabel:new(BORDER, BORDER + ITEM_H + 122, ITEM_H,
        tr("UI_CSR_ClaimsAllowedAddPrompt", "Add online player:"),
        1, 1, 1, 1, FONT_S, true)
    lab2:initialise(); lab2:instantiate(); picker:addChild(lab2)

    local exclude = csvSet(row.membersCSV)
    exclude[tostring(row.owner or "")] = true
    exclude[safeUsername(self.player or getPlayer())] = true
    local onlineNames = sortedOnlinePlayerNames(self.player or getPlayer(), exclude)
    local nameCb = ISComboBox:new(BORDER, BORDER + ITEM_H + 142,
        400 - BORDER * 2, 24)
    nameCb:initialise(); nameCb:instantiate()
    if #onlineNames == 0 then
        nameCb:addOption(tr("UI_CSR_ClaimsNoOnlinePlayers",
            "(no eligible online players)"))
    else
        for i = 1, #onlineNames do nameCb:addOption(onlineNames[i]) end
    end
    nameCb.selected = 1
    picker:addChild(nameCb)

    local panel = self
    local addBtn = ISButton:new(BORDER, 260 - BTN_H - BORDER, 80, BTN_H,
        tr("UI_CSR_ClaimsAdd", "Add"), picker, function()
            local name = nameCb:getOptionText(nameCb.selected) or ""
            name = name:gsub("^%s+", ""):gsub("%s+$", "")
            if name ~= "" and #onlineNames > 0 then
                sendAdd(name)
            end
            picker:setVisible(false); picker:removeFromUIManager()
            if CSR_ClaimClient and CSR_ClaimClient.requestBundle then
                CSR_ClaimClient.requestBundle(true)
            end
            panel:populate()
        end)
    addBtn:initialise(); addBtn:instantiate()
    addBtn.enable = #onlineNames > 0
    addBtn.borderColor = { r = 0.4, g = 0.7, b = 0.4, a = 1 }
    picker:addChild(addBtn)

    local rmBtn = ISButton:new(BORDER + 90, 260 - BTN_H - BORDER, 110, BTN_H,
        tr("UI_CSR_ClaimsRemoveSelected", "Remove Selected"),
        picker, function()
            local idx = listBox.selected
            if idx and idx > 0 then
                local it = listBox.items[idx]
                if it and it.item and it.item.type == "user" then
                    sendRemove(it.item.name)
                end
            end
            picker:setVisible(false); picker:removeFromUIManager()
            if CSR_ClaimClient and CSR_ClaimClient.requestBundle then
                CSR_ClaimClient.requestBundle(true)
            end
            panel:populate()
        end)
    rmBtn:initialise(); rmBtn:instantiate()
    rmBtn.borderColor = { r = 0.7, g = 0.5, b = 0.3, a = 1 }
    picker:addChild(rmBtn)

    local caBtn = ISButton:new(400 - 80 - BORDER, 260 - BTN_H - BORDER,
        80, BTN_H,
        tr("UI_Cancel", "Cancel"), picker, function()
            picker:setVisible(false); picker:removeFromUIManager()
        end)
    caBtn:initialise(); caBtn:instantiate()
    caBtn.borderColor = { r = 0.7, g = 0.3, b = 0.3, a = 1 }
    picker:addChild(caBtn)
end

-- =========================================================================
-- Public open helper
-- =========================================================================

function CSR_ClaimsManagerPanel.open(playerObj)
    if CSR_ClaimsManagerPanel.instance
        and CSR_ClaimsManagerPanel.instance:isReallyVisible() then
        CSR_ClaimsManagerPanel.instance:setVisible(false)
        CSR_ClaimsManagerPanel.instance:removeFromUIManager()
        CSR_ClaimsManagerPanel.instance = nil
        return
    end
    local w, h = 720, 540
    local x = (tonumber(getCore():getScreenWidth())  or 1024 - w) / 2
    local y = (tonumber(getCore():getScreenHeight()) or 768  - h) / 2
    local panel = CSR_ClaimsManagerPanel:new(x, y, w, h, playerObj or getPlayer())
    panel:initialise()
    panel:addToUIManager()
    -- Fresh snapshot from the server to handle reconnects mid-session.
    if CSR_ClaimClient and CSR_ClaimClient.requestBundle then
        CSR_ClaimClient.requestBundle(true)
    end
end

return CSR_ClaimsManagerPanel
