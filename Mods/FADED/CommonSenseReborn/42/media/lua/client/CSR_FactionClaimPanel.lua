require "CSR_FeatureFlags"
require "CSR_SafehouseClaim"
require "CSR_Claims/CSR_ClaimClient"
require "CSR_Claims/CSR_ClaimRegistry"

--[[
    CSR_FactionClaimPanel.lua (client, v1.8.0 -- Track B)

    A floating ISPanel that lists every faction safehouse the running player
    is entitled to see and offers per-claim actions (Release, Transfer to
    another owned faction, set member roles).

    Data model:
      * Source of truth: CSR_ClaimClient._claimMirror (Track B registry,
        filtered to row.kind == "faction").
      * Broadcasts CSR_ClaimAdded / CSR_ClaimRemoved / CSR_ClaimUpdated /
        CSR_ClaimsBundle drive a live repopulate.

    Visibility:
      * Faction owners see all of their own faction's claims.
      * Server admins see all claims across all factions (read-only marker
        plus Release/Transfer permissions on every entry).

    The panel is opened from the right-click world context menu when the
    player is a faction owner or admin (see addContextEntry below).
]]

CSR_FactionClaimPanel = ISPanel:derive("CSR_FactionClaimPanel")

local MODULE = "CommonSenseReborn"
local FONT_S = UIFont.NewSmall
local FONT_M = UIFont.Medium
local ITEM_H = 20
local BORDER = 8
local BTN_H  = 22

-- Read faction rows directly from the Track B mirror. Returned items match
-- the legacy _mirror shape so the rest of the panel can stay unchanged:
--   { factionName, x, y, w, h, id, owner, title }
local function collectFactionEntries()
    local out = {}
    local mirror = (CSR_ClaimClient and CSR_ClaimClient._claimMirror) or {}
    for _, row in pairs(mirror) do
        if type(row) == "table" and row.kind == "faction" then
            out[#out + 1] = {
                factionName = row.factionName or "",
                x = tonumber(row.x) or 0,
                y = tonumber(row.y) or 0,
                w = tonumber(row.w) or 1,
                h = tonumber(row.h) or 1,
                id    = tonumber(row.id) or 0,
                owner = row.owner or "",
                title = row.title or "",
            }
        end
    end
    return out
end

-- ----------------------------------------------------------------------------
-- Permissions: which factions does the running player own?
-- ----------------------------------------------------------------------------
local function getOwnedFactions(playerObj)
    local owned = {}
    if not playerObj then return owned end
    pcall(function()
        local factions = Faction.getFactions()
        if not factions then return end
        for i = 0, factions:size() - 1 do
            local f = factions:get(i)
            if f and f:isOwner(playerObj:getUsername()) then
                table.insert(owned, f:getName())
            end
        end
    end)
    return owned
end

local function isAdmin(playerObj)
    if not playerObj then return false end
    local ok, result = pcall(function()
        local access = playerObj:getAccessLevel()
        if access and (access == "admin" or access == "Admin") then return true end
        return playerObj:getRole():hasCapability(Capability.FactionCheat)
    end)
    return ok and result or false
end

-- ----------------------------------------------------------------------------
-- Panel
-- ----------------------------------------------------------------------------
function CSR_FactionClaimPanel:initialise()
    ISPanel.initialise(self)

    self.titleLabel = ISLabel:new(BORDER, BORDER, ITEM_H,
        getText("UI_CSR_FactionClaimPanelTitle"),
        1, 0.85, 0.2, 1, FONT_M, true)
    self.titleLabel:initialise(); self.titleLabel:instantiate()
    self:addChild(self.titleLabel)

    self.closeBtn = ISButton:new(self.width - 70 - BORDER, BORDER, 70, BTN_H,
        getText("UI_Close"), self, CSR_FactionClaimPanel.onClose)
    self.closeBtn:initialise(); self.closeBtn:instantiate()
    self.closeBtn.borderColor = { r=0.8, g=0.2, b=0.2, a=1 }
    self:addChild(self.closeBtn)

    self.refreshBtn = ISButton:new(self.width - 148 - BORDER, BORDER, 70, BTN_H,
        getText("UI_servers_refresh"), self, CSR_FactionClaimPanel.onRefresh)
    self.refreshBtn:initialise(); self.refreshBtn:instantiate()
    self.refreshBtn.borderColor = { r=0.4, g=0.7, b=0.4, a=1 }
    self:addChild(self.refreshBtn)

    local listY = BORDER + ITEM_H + BORDER
    local listH = self.height - listY - BTN_H * 2 - BORDER * 4
    self.list = ISScrollingListBox:new(BORDER, listY,
        self.width - BORDER * 2, listH)
    self.list:initialise(); self.list:instantiate()
    self.list.itemheight = ITEM_H
    self.list.font = FONT_S
    self.list.drawBorder = true
    self.list.doDrawItem = CSR_FactionClaimPanel.drawRow
    self:addChild(self.list)

    -- Action buttons
    local btnY = self.list:getBottom() + BORDER
    self.releaseBtn = ISButton:new(BORDER, btnY, 100, BTN_H,
        getText("UI_CSR_FactionClaimRelease"), self, CSR_FactionClaimPanel.onRelease)
    self.releaseBtn:initialise(); self.releaseBtn:instantiate()
    self.releaseBtn.borderColor = { r=0.8, g=0.3, b=0.3, a=1 }
    self.releaseBtn.enable = false
    self:addChild(self.releaseBtn)

    self.transferBtn = ISButton:new(BORDER + 110, btnY, 100, BTN_H,
        getText("UI_CSR_FactionClaimTransfer"), self, CSR_FactionClaimPanel.onTransfer)
    self.transferBtn:initialise(); self.transferBtn:instantiate()
    self.transferBtn.borderColor = { r=0.6, g=0.6, b=0.3, a=1 }
    self.transferBtn.enable = false
    self:addChild(self.transferBtn)

    self.tpBtn = ISButton:new(BORDER + 220, btnY, 100, BTN_H,
        getText("UI_CSR_FactionClaimShowMap"), self, CSR_FactionClaimPanel.onShowOnMap)
    self.tpBtn:initialise(); self.tpBtn:instantiate()
    self.tpBtn.borderColor = { r=0.4, g=0.5, b=0.7, a=1 }
    self.tpBtn.enable = false
    self:addChild(self.tpBtn)

    self:populate()
end

function CSR_FactionClaimPanel:populate()
    self.list:clear()
    self.list.selected = 0
    self.releaseBtn.enable = false
    self.transferBtn.enable = false
    self.tpBtn.enable = false

    local player = getPlayer()
    if not player then return end
    local admin = isAdmin(player)
    local owned = getOwnedFactions(player)
    local ownedSet = {}
    for _, n in ipairs(owned) do ownedSet[n] = true end

    -- Group by faction
    local byFac = {}
    local entries = collectFactionEntries()
    for _, e in ipairs(entries) do
        if admin or ownedSet[e.factionName] then
            byFac[e.factionName] = byFac[e.factionName] or {}
            table.insert(byFac[e.factionName], e)
        end
    end

    -- Stable order: owned first, then admin-only entries alphabetical
    local names = {}
    for n in pairs(byFac) do table.insert(names, n) end
    table.sort(names)

    if #names == 0 then
        self.list:addItem(getText("UI_CSR_FactionClaimNone"), { type = "empty" })
        return
    end

    local maxFac = CSR_SafehouseClaim.getMaxFactionSafehouses()
    for _, fn in ipairs(names) do
        local entries = byFac[fn]
        local atCap = #entries >= maxFac
        local header = "[" .. fn .. "]  (" .. #entries .. "/" .. maxFac .. ")"
        if not ownedSet[fn] then header = header .. "  [admin view]" end
        self.list:addItem(header, { type = "header", factionName = fn, atCap = atCap })
        for _, e in ipairs(entries) do
            local label
            if e.title and e.title ~= "" then
                label = string.format("    [%s] @ (%d, %d)  %dx%d  owner: %s",
                    e.title, e.x, e.y, e.w, e.h, e.owner or "")
            else
                label = string.format("    @ (%d, %d)  size %dx%d  owner: %s",
                    e.x, e.y, e.w, e.h, e.owner or "")
            end
            self.list:addItem(label, { type = "claim",
                id = e.id,
                factionName = fn, x = e.x, y = e.y, w = e.w, h = e.h,
                owner = e.owner, title = e.title,
                ownedByMe = ownedSet[fn] and true or false })
        end
    end
end

function CSR_FactionClaimPanel.drawRow(self, y, item, alt)
    local data = item.item
    local a = 0.9
    if data.type == "header" then
        local r, g, b = 0.1, 0.3, 0.35
        if data.atCap then r, g, b = 0.35, 0.12, 0.12 end
        self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.6, r, g, b)
        self:drawRectBorder(0, y, self:getWidth(), self.itemheight - 1, a,
            self.borderColor.r, self.borderColor.g, self.borderColor.b)
        self:drawText(item.text, 6, y + 2, 1, 0.9, 0.3, a, self.font)
    elseif data.type == "claim" then
        if self.selected == item.index then
            self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.4, 0.2, 0.5, 0.2)
            self.parent.releaseBtn.enable  = true
            self.parent.transferBtn.enable = data.ownedByMe
            self.parent.tpBtn.enable       = true
        end
        self:drawRectBorder(0, y, self:getWidth(), self.itemheight - 1, 0.5,
            self.borderColor.r, self.borderColor.g, self.borderColor.b)
        self:drawText(item.text, 6, y + 2, 1, 1, 1, a, self.font)
    elseif data.type == "empty" then
        self:drawText(item.text, 6, y + 2, 0.6, 0.6, 0.6, a, self.font)
    end
    return y + self.itemheight
end

local function getSelectedClaim(panel)
    local idx = panel.list.selected
    if idx == 0 then return nil end
    local it = panel.list.items[idx]
    if not it or not it.item or it.item.type ~= "claim" then return nil end
    return it.item
end

function CSR_FactionClaimPanel:onRefresh(button)
    if CSR_ClaimClient and CSR_ClaimClient.requestBundle then
        pcall(function() CSR_ClaimClient.requestBundle(true) end)
    end
    self:populate()
end

function CSR_FactionClaimPanel:onClose(button)
    self:setVisible(false)
    self:removeFromUIManager()
    CSR_FactionClaimPanel.instance = nil
end

function CSR_FactionClaimPanel:onRelease(button)
    local sel = getSelectedClaim(self); if not sel then return end
    local player = getPlayer(); if not player then return end
    local panel = self
    local msg = getText("UI_CSR_FactionClaimReleaseConfirm", sel.factionName)
    local modal = ISModalDialog:new(
        getCore():getScreenWidth() / 2 - 175,
        getCore():getScreenHeight() / 2 - 75,
        350, 130, msg, true, nil,
        function(_, btn)
            if btn and btn.internal == "YES" then
                if CSR_ClaimClient and CSR_ClaimClient.requestRelease and sel.id then
                    CSR_ClaimClient.requestRelease(sel.id)
                end
                panel:populate()
            end
        end)
    modal:initialise(); modal:addToUIManager()
end

function CSR_FactionClaimPanel:onTransfer(button)
    local sel = getSelectedClaim(self); if not sel then return end
    local player = getPlayer(); if not player then return end
    local owned = getOwnedFactions(player)
    -- Need at least one OTHER owned faction to transfer to
    local candidates = {}
    for _, n in ipairs(owned) do
        if n ~= sel.factionName then table.insert(candidates, n) end
    end
    if #candidates == 0 then
        local modal = ISModalDialog:new(
            getCore():getScreenWidth() / 2 - 175,
            getCore():getScreenHeight() / 2 - 75,
            350, 130,
            getText("UI_CSR_FactionClaimNoTransferTarget"),
            false, nil, nil)
        modal:initialise(); modal:addToUIManager()
        return
    end

    -- Simple combobox-style modal
    local panel = self
    local cx = getCore():getScreenWidth() / 2 - 175
    local cy = getCore():getScreenHeight() / 2 - 100
    local picker = ISPanel:new(cx, cy, 350, 200)
    picker:initialise()
    picker.borderColor = { r=0.5, g=0.5, b=0.5, a=1 }
    picker.backgroundColor = { r=0.05, g=0.05, b=0.1, a=0.95 }
    picker.moveWithMouse = true

    local lab = ISLabel:new(BORDER, BORDER, ITEM_H,
        getText("UI_CSR_FactionClaimTransferPick"),
        1, 1, 1, 1, FONT_S, true)
    lab:initialise(); lab:instantiate(); picker:addChild(lab)

    local cb = ISComboBox:new(BORDER, BORDER + ITEM_H + 4, 350 - BORDER * 2, 24)
    cb:initialise(); cb:instantiate()
    for _, n in ipairs(candidates) do cb:addOption(n) end
    cb.selected = 1
    picker:addChild(cb)

    local okBtn = ISButton:new(BORDER, 200 - BTN_H - BORDER, 100, BTN_H,
        getText("UI_Ok"), picker, function()
            local pick = cb:getOptionText(cb.selected)
            if pick and sel.id then
                -- Faction-to-faction transfer is a registry-row factionName
                -- patch. Emit a dedicated request command that Step 9 wires
                -- into CSR_ClaimServer.handleTransferFactionRequest. Until
                -- that handler lands the server simply ignores the command.
                if isClient() then
                    sendClientCommand(player, MODULE,
                        "CSR_TransferFactionRequest",
                        { id = sel.id, toFaction = pick })
                elseif CSR_ClaimServer and CSR_ClaimServer.dispatch then
                    CSR_ClaimServer.dispatch(MODULE,
                        "CSR_TransferFactionRequest", player,
                        { id = sel.id, toFaction = pick })
                end
                panel:populate()
            end
            picker:setVisible(false)
            picker:removeFromUIManager()
        end)
    okBtn:initialise(); okBtn:instantiate()
    okBtn.borderColor = { r=0.4, g=0.7, b=0.4, a=1 }
    picker:addChild(okBtn)

    local caBtn = ISButton:new(350 - 100 - BORDER, 200 - BTN_H - BORDER, 100, BTN_H,
        getText("UI_Cancel"), picker, function()
            picker:setVisible(false); picker:removeFromUIManager()
        end)
    caBtn:initialise(); caBtn:instantiate()
    caBtn.borderColor = { r=0.7, g=0.3, b=0.3, a=1 }
    picker:addChild(caBtn)

    picker:addToUIManager()
end

function CSR_FactionClaimPanel:onShowOnMap(button)
    local sel = getSelectedClaim(self); if not sel then return end
    local cx = (tonumber(sel.x) or 0) + (tonumber(sel.w) or 1) / 2
    local cy = (tonumber(sel.y) or 0) + (tonumber(sel.h) or 1) / 2
    -- Best-effort: open the world map and centre on the safehouse.
    pcall(function()
        if ISWorldMap and ISWorldMap.ShowWorldMap then
            ISWorldMap.ShowWorldMap(0)
        end
        local map = ISWorldMap_instance
        if map and map.mapAPI and map.mapAPI.centerOn then
            map.mapAPI:centerOn(cx, cy)
        end
    end)
end

local SAFEHOUSE_BG_PATH = "media/ui/CSR_SafehouseBg.png"
local _safehouseBgTexture = nil
local function getSafehouseBgTexture()
    if _safehouseBgTexture == nil then
        _safehouseBgTexture = getTexture(SAFEHOUSE_BG_PATH) or false
    end
    if _safehouseBgTexture == false then return nil end
    return _safehouseBgTexture
end

local SAFEHOUSE_OUTLINE = { a = 1.0, r = 0.86, g = 0.70, b = 0.28 }

function CSR_FactionClaimPanel:prerender()
    self:drawRect(0, 0, self.width, self.height,
        self.backgroundColor.a, self.backgroundColor.r,
        self.backgroundColor.g, self.backgroundColor.b)

    -- Faint safehouse crest watermark, centered, behind list content.
    local tex = getSafehouseBgTexture()
    if tex then
        local maxW = self.width - BORDER * 2
        local maxH = self.height - BORDER * 2
        local tw = tex.getWidth and tex:getWidth() or maxW
        local thh = tex.getHeight and tex:getHeight() or maxH
        if tonumber(tw) and tonumber(thh) and tonumber(tw) > 0 and tonumber(thh) > 0 then
            local scale = math.min(maxW / tonumber(tw), maxH / tonumber(thh))
            if scale > 1 then scale = 1 end
            local drawW = math.floor(tonumber(tw) * scale)
            local drawH = math.floor(tonumber(thh) * scale)
            local drawX = math.floor((self.width - drawW) / 2)
            local drawY = math.floor((self.height - drawH) / 2)
            self:drawTextureScaled(tex, drawX, drawY, drawW, drawH, 0.18,
                SAFEHOUSE_OUTLINE.r, SAFEHOUSE_OUTLINE.g, SAFEHOUSE_OUTLINE.b)
        end
    end

    -- Double accent border in faction-gold.
    self:drawRectBorder(0, 0, self.width, self.height, 1.0,
        SAFEHOUSE_OUTLINE.r, SAFEHOUSE_OUTLINE.g, SAFEHOUSE_OUTLINE.b)
    self:drawRectBorder(1, 1, self.width - 2, self.height - 2, 0.8,
        SAFEHOUSE_OUTLINE.r * 0.7, SAFEHOUSE_OUTLINE.g * 0.7, SAFEHOUSE_OUTLINE.b * 0.7)
end

function CSR_FactionClaimPanel:new(x, y, w, h)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.borderColor = { r=0.5, g=0.5, b=0.5, a=1 }
    o.backgroundColor = { r=0.05, g=0.05, b=0.1, a=0.92 }
    o.moveWithMouse = true
    CSR_FactionClaimPanel.instance = o
    return o
end

-- ----------------------------------------------------------------------------
-- Mirror sync: subscribe to Track B claim broadcasts so the panel refreshes
-- whenever a faction claim is added / removed / mutated.
-- ----------------------------------------------------------------------------
local function onServerCommand(module, command, args)
    if module ~= MODULE then return end
    if command ~= "CSR_ClaimAdded" and command ~= "CSR_ClaimRemoved"
        and command ~= "CSR_ClaimUpdated" and command ~= "CSR_ClaimsBundle" then
        return
    end
    if CSR_FactionClaimPanel.instance and CSR_FactionClaimPanel.instance.populate then
        pcall(function() CSR_FactionClaimPanel.instance:populate() end)
    end
end

local function openPanel()
    if CSR_FactionClaimPanel.instance and CSR_FactionClaimPanel.instance:isReallyVisible() then
        CSR_FactionClaimPanel.instance:setVisible(false)
        CSR_FactionClaimPanel.instance:removeFromUIManager()
        CSR_FactionClaimPanel.instance = nil
        return
    end
    local w, h = 480, 460
    local x = (getCore():getScreenWidth()  - w) / 2
    local y = (getCore():getScreenHeight() - h) / 2
    local panel = CSR_FactionClaimPanel:new(x, y, w, h)
    panel:initialise(); panel:addToUIManager()
end

CSR_FactionClaimPanel.open = openPanel

-- Context menu entry: only shown when the player owns at least one faction
-- (or is admin) AND faction safehouse claiming is enabled.
local function addContextEntry(playerNum, context, worldobjects)
    if not isClient() then return end
    if not CSR_SafehouseClaim or not CSR_SafehouseClaim.isFactionSafehouseEnabled
       or not CSR_SafehouseClaim.isFactionSafehouseEnabled() then return end
    local player = getSpecificPlayer(playerNum); if not player then return end
    local owned = getOwnedFactions(player)
    if #owned == 0 and not isAdmin(player) then return end
    context:addOption(getText("UI_CSR_FactionClaimManage"),
        worldobjects, function() openPanel() end)
end

if Events then
    if not CSR_FactionClaimPanel._registered then
        CSR_FactionClaimPanel._registered = true
        Events.OnServerCommand.Add(onServerCommand)
        Events.OnFillWorldObjectContextMenu.Add(addContextEntry)
    end
end

return CSR_FactionClaimPanel
