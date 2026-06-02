require "CSR_FeatureFlags"
require "CSR_SafehouseClaim"
require "CSR_Claims/CSR_ClaimClient"
require "CSR_Claims/CSR_ClaimRegistry"
require "CSR_Claims/CSR_ClaimPermissions"

--[[
    CSR_SafehouseOutline.lua (client, v1.8.0 -- Track B repoint)
    Renders a translucent floor-tile overlay over every claim the player
    is a member of (owner OR in the membersCSV).

    Architecture (ported from Better Safehouse 42.17 with CSR palette):
      - Throttled via Events.OnTick + an internal 500ms cooldown
      - Iterates inclusive bounds (x1..x2, y1..y2) of each owned/member claim
      - Calls IsoFloor:setHighlightColor(r,g,b,a) + setHighlighted(true,false)
      - Tracks applied squares by "x,y,z" key for clean removal
      - Reads from CSR_ClaimClient._claimMirror (Track B). Vehicle rows are
        skipped because they have no spatial bounds.

    Palette (CSR gold/purple):
      - Owner-of:   gold   (1.00, 0.84, 0.10, 0.45)
      - Member-of:  purple (0.55, 0.20, 0.85, 0.45)

    No pcall error-masking: guards via method-existence checks (CSR rule).
]]

CSR_SafehouseOutline = CSR_SafehouseOutline or {}

local THROTTLE_MS = 500
local Z_LIMIT     = 8     -- Project Zomboid level cap
local PREF_KEY    = "CSR_SafehouseOverlay"
local BORDER_ONLY_TILE_THRESHOLD = 1024

-- Color tuples {r,g,b,a}
local COLOR_OWNER  = { 1.00, 0.84, 0.10, 0.45 }
local COLOR_MEMBER = { 0.55, 0.20, 0.85, 0.45 }

-- State
local _appliedSquares = {}    -- ["x,y,z"] = true
local _lastApplyMs    = 0
local _enabled        = false -- toggle (per-client)

-- ============================================================
-- Helpers
-- ============================================================

local function nowMs()
    if getTimestampMs then return getTimestampMs() end
    return os.clock() * 1000
end

local function keyOf(x, y, z)
    return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end

local function readPlayerPref()
    local player = getPlayer()
    if not player or not player.getModData then return false end
    return player:getModData()[PREF_KEY] == true
end

local function writePlayerPref(flag)
    local player = getPlayer()
    if player and player.getModData then
        player:getModData()[PREF_KEY] = flag == true
    end
end

local function hasVisibleSafehouse(player)
    if not player or not player.getUsername then return false end
    if not CSR_ClaimClient or not CSR_ClaimClient._claimMirror then return false end
    local user = player:getUsername()
    if not user or user == "" then return false end
    for _, row in pairs(CSR_ClaimClient._claimMirror) do
        if type(row) == "table" and row.kind ~= "vehicle" then
            if row.owner == user then return true end
            if CSR_ClaimRegistry and CSR_ClaimRegistry.csvContains
                and CSR_ClaimRegistry.csvContains(row.membersCSV, user) then
                return true
            end
            if CSR_ClaimPermissions and CSR_ClaimPermissions.getRank
                and CSR_ClaimPermissions.RANK then
                local rank = CSR_ClaimPermissions.getRank(row, user)
                if row.kind == "faction" then
                    if rank <= CSR_ClaimPermissions.RANK.ally then return true end
                elseif rank <= CSR_ClaimPermissions.RANK.member then
                    return true
                end
            end
        end
    end
    return false
end

local function notifyOverlayState(player, enabled)
    if not player then return end
    local text = enabled and "CSR safehouse overlay shown" or "CSR safehouse overlay hidden"
    if HaloTextHelper and HaloTextHelper.addTextWithArrow then
        HaloTextHelper.addTextWithArrow(player, text, enabled == true,
            enabled and HaloTextHelper.getColorGreen() or HaloTextHelper.getColorRed())
    elseif player.Say then
        player:Say(text)
    end
end

--- True if username is owner OR a member CSV entry of the row.
local function rowHasUser(row, username)
    if not row or not username then return false end
    if row.owner == username then return true end
    if CSR_ClaimRegistry and CSR_ClaimRegistry.csvContains then
        if CSR_ClaimRegistry.csvContains(row.membersCSV, username) == true then
            return true
        end
    end
    if CSR_ClaimPermissions and CSR_ClaimPermissions.getRank
        and CSR_ClaimPermissions.RANK then
        local rank = CSR_ClaimPermissions.getRank(row, username)
        if row.kind == "faction" then
            return rank <= CSR_ClaimPermissions.RANK.ally
        end
        return rank <= CSR_ClaimPermissions.RANK.member
    end
    return false
end

--- Inclusive bounds (x1, y1, x2, y2) for a Track B claim row. Rows store
--- x/y as the top-left grid corner and w/h as inclusive widths in tiles
--- (matching the legacy SafeHouse representation).
local function rowBounds(row)
    if not row then return nil end
    local x1 = tonumber(row.x) or 0
    local y1 = tonumber(row.y) or 0
    local w  = tonumber(row.w) or 1
    local h  = tonumber(row.h) or 1
    if w < 1 then w = 1 end
    if h < 1 then h = 1 end
    return x1, y1, x1 + w - 1, y1 + h - 1
end

local function shouldUseBorderOnly(x1, y1, x2, y2)
    local w = (x2 - x1) + 1
    local h = (y2 - y1) + 1
    if w < 1 or h < 1 then return false end
    return (w * h) > BORDER_ONLY_TILE_THRESHOLD
end

local function isBorderTile(x, y, x1, y1, x2, y2)
    return x == x1 or x == x2 or y == y1 or y == y2
end

local function rowZ(row)
    if row and row.z then
        local z = tonumber(row.z)
        if z then return z end
    end
    return 0
end

--- Apply a CSR-tinted highlight to a single grid square's floor tile.
local function applyHighlightToSquare(sq, color)
    if not sq then return end
    if not sq.getFloor then return end
    local floor = sq:getFloor()
    if floor and floor.setHighlightColor then
        floor:setHighlightColor(color[1], color[2], color[3], color[4])
    end
    if floor and floor.setHighlighted then
        floor:setHighlighted(true, false)
    end
    if sq.setHighlight then
        sq:setHighlight(true)
    end
end

--- Remove highlights from every previously-applied square.
local function clearApplied()
    local cell = getCell and getCell() or nil
    if not cell or not cell.getGridSquare then
        _appliedSquares = {}
        return
    end
    for k, _ in pairs(_appliedSquares) do
        local sx, sy, sz = k:match("^(%-?%d+),(%-?%d+),(%-?%d+)$")
        if sx and sy and sz then
            local x = tonumber(sx); local y = tonumber(sy); local z = tonumber(sz)
            local sq = cell:getGridSquare(x, y, z)
            if sq then
                if sq.setHighlight then sq:setHighlight(false) end
                if sq.getFloor then
                    local floor = sq:getFloor()
                    if floor then
                        -- Reset color first so the tile does not re-appear tinted
                        -- if something else calls setHighlighted(true) later.
                        if floor.setHighlightColor then
                            floor:setHighlightColor(0, 0, 0, 0)
                        end
                        if floor.setHighlighted then
                            floor:setHighlighted(false)
                        end
                    end
                end
            end
        end
    end
    _appliedSquares = {}
end

--- True when _appliedSquares has at least one entry. Avoids the global
--- `next()` lookup on the hot path; some loaders / mods can shadow `next`
--- with nil during early game state, which surfaces as the misleading
--- "Object tried to call nil in onTick" stack at this exact line.
local function hasApplied()
    for _ in pairs(_appliedSquares) do return true end
    return false
end

-- ============================================================
-- Main render pass
-- ============================================================

local function onTick()
    -- Feature gate: requires multiple-safehouse system + outline enabled.
    if not _enabled then
        if hasApplied() then clearApplied() end
        return
    end
    if not CSR_FeatureFlags or not CSR_FeatureFlags.isMultipleSafehouseEnabled then return end
    if not CSR_FeatureFlags.isMultipleSafehouseEnabled() then
        if hasApplied() then clearApplied() end
        return
    end

    local player = getPlayer()
    if not player then return end
    if not player.getUsername then return end
    local username = player:getUsername()
    if not username or username == "" then return end

    -- Throttle: only rebuild every THROTTLE_MS ms.
    local now = nowMs()
    if now - _lastApplyMs < THROTTLE_MS then return end
    _lastApplyMs = now

    local cell = getCell and getCell() or nil
    if not cell then return end

    local mirror = (CSR_ClaimClient and CSR_ClaimClient._claimMirror) or nil
    if not mirror then return end

    -- Rebuild from scratch each cycle to handle release/reclaim.
    clearApplied()

    for _, row in pairs(mirror) do
        if type(row) == "table" and row.kind ~= "vehicle"
            and rowHasUser(row, username) then
            local isOwner = row.owner == username
            local color   = isOwner and COLOR_OWNER or COLOR_MEMBER
            local x1, y1, x2, y2 = rowBounds(row)
            if x1 and y1 and x2 and y2 then
                local z = rowZ(row)
                if z >= 0 and z < Z_LIMIT then
                    local borderOnly = shouldUseBorderOnly(x1, y1, x2, y2)
                    for y = y1, y2 do
                        for x = x1, x2 do
                            if not borderOnly or isBorderTile(x, y, x1, y1, x2, y2) then
                                local k = keyOf(x, y, z)
                                if not _appliedSquares[k] then
                                    local sq = cell:getGridSquare(x, y, z)
                                    if sq then
                                        applyHighlightToSquare(sq, color)
                                        _appliedSquares[k] = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================
-- Public API (toggle via key/menu later)
-- ============================================================

function CSR_SafehouseOutline.setEnabled(flag)
    _enabled = (flag == true)
    writePlayerPref(_enabled)
    if not _enabled then clearApplied() end
end

function CSR_SafehouseOutline.isEnabled()
    return _enabled
end

function CSR_SafehouseOutline.toggle()
    CSR_SafehouseOutline.setEnabled(not _enabled)
    return _enabled
end

function CSR_SafehouseOutline.forceRefresh()
    _lastApplyMs = 0
end

function CSR_SafehouseOutline.notify(player, enabled)
    notifyOverlayState(player or getPlayer(), enabled == true)
end

-- ============================================================
-- Hook
-- ============================================================

local function onGameStart()
    -- Clear any visual highlights from a prior session BEFORE resetting the
    -- tracking table so clearApplied() can iterate the old square keys.
    clearApplied()
    _lastApplyMs = 0
    _enabled     = readPlayerPref()
end

local function onContextMenu(playerNum, context, worldobjects, test)
    if test or not context then return end
    if not CSR_FeatureFlags or not CSR_FeatureFlags.isMultipleSafehouseEnabled then return end
    if not CSR_FeatureFlags.isMultipleSafehouseEnabled() then return end
    local player = getSpecificPlayer and getSpecificPlayer(playerNum) or getPlayer()
    if not hasVisibleSafehouse(player) then return end
    local label = _enabled and "Hide CSR Safehouse Overlay" or "Show CSR Safehouse Overlay"
    context:addOption(label, worldobjects, function()
        local enabled = CSR_SafehouseOutline.toggle()
        notifyOverlayState(player, enabled)
    end)
end

Events.OnGameStart.Add(onGameStart)
Events.OnTick.Add(onTick)
Events.OnFillWorldObjectContextMenu.Add(onContextMenu)

-- ============================================================
-- ISSafehouseUI button: in-window toggle so users can flip the
-- overlay from the Safehouse menu (mirrors Generator Info pattern).
-- ============================================================

local function csrOverlayBtnLabel()
    if _enabled then
        return "CSR Overlay: ON"
    end
    return "CSR Overlay: OFF"
end

local function csrOnClickOverlayBtn(self)
    local enabled = CSR_SafehouseOutline.toggle()
    if self and self.csrOverlayBtn and self.csrOverlayBtn.setTitle then
        self.csrOverlayBtn:setTitle(csrOverlayBtnLabel())
    end
    local player = (self and self.player) or getPlayer()
    notifyOverlayState(player, enabled)
end

local _origInit = ISSafehouseUI and ISSafehouseUI.initialise
if _origInit then
    function ISSafehouseUI:initialise()
        _origInit(self)
        if not (CSR_FeatureFlags and CSR_FeatureFlags.isMultipleSafehouseEnabled
                and CSR_FeatureFlags.isMultipleSafehouseEnabled()) then
            return
        end
        if not (self.no and self.no.getX) then return end
        local pad   = 10
        local btnH  = self.no:getHeight() or 22
        local btnW  = 140
        local btnY  = self.no:getY()
        local btnX  = self.no:getX() - btnW - pad
        local b = ISButton:new(btnX, btnY, btnW, btnH, csrOverlayBtnLabel(),
                               self, csrOnClickOverlayBtn)
        b.internal = "CSR_OVERLAY_TOGGLE"
        b:initialise()
        b:instantiate()
        b.borderColor = self.buttonBorderColor
        b:setTooltip(getText("Tooltip_CSR_SafehouseOutlineToggle"))
        self:addChild(b)
        self.csrOverlayBtn = b

        -- Second CSR button: open the unified Claims Manager so users who
        -- reach the vanilla UI from the User Panel / Safehouse List still
        -- have a one-click route into the CSR experience.
        local mgrBtnW = 180
        local mgrBtnX = btnX - mgrBtnW - pad
        local mgr = ISButton:new(mgrBtnX, btnY, mgrBtnW, btnH,
            getText("IGUI_CSR_SafehouseClaimsManagerBtn"), self, function(uiSelf)
                if CSR_ClaimsManagerPanel and CSR_ClaimsManagerPanel.open then
                    pcall(function()
                        CSR_ClaimsManagerPanel.open((uiSelf and uiSelf.player) or getPlayer())
                    end)
                end
            end)
        mgr.internal = "CSR_CLAIMS_MANAGER_OPEN"
        mgr:initialise()
        mgr:instantiate()
        mgr.borderColor = self.buttonBorderColor
        mgr:setTooltip(getText("Tooltip_CSR_ClaimsManagerOpen"))
        self:addChild(mgr)
        self.csrClaimsMgrBtn = mgr
    end
end

local _origRender = ISSafehouseUI and ISSafehouseUI.render
if _origRender then
    function ISSafehouseUI:render()
        _origRender(self)
        if self.csrOverlayBtn and self.csrOverlayBtn.setTitle then
            self.csrOverlayBtn:setTitle(csrOverlayBtnLabel())
        end
    end
end
