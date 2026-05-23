require "CSR_FeatureFlags"
require "CSR_PlayerMapTracker"
require "CSR_Theme"

--[[
    CSR_RallyPoints.lua
    Rally Point Beacon — MP-only feature.

    Right-click on the world map to set a personal rally point.
    "Share Rally Point" broadcasts the pin to all online players via the server.
    Received waypoints are drawn as a pulsing diamond on both the world map and
    minimap, with an optional dashed route line from your current position.
    The pin auto-clears once the player is within ARRIVE_DISTANCE tiles of it.

    MP only: in SP the context options are hidden (no server to broadcast through).
]]

local CSR_RallyPoints = {}

-- Tile distance at which a rally point is considered reached and auto-cleared
local ARRIVE_DISTANCE = 15

-- Pulse animation for the waypoint icon
local pulseTimer = 0

-- Active rally points received from server: { x, y, z, label, senderName }
local activeWaypoints = {}

-- The player's own pending waypoint (set locally, shared on demand)
local pendingWaypoint = nil

-- Perf: memoize label text widths (labels are short sender-name strings).
local _labelWidthCache = {}

-- =====================================================================
-- Map draw helper — diamond / pulsing pin
-- =====================================================================
local function drawWaypointPin(mapObject, uiX, uiY, label, pulse)
    if not mapObject then return end

    local size = 8 + math.floor(math.sin(pulse) * 2)
    -- v1.8.6: dark magenta (rallyPin) for high contrast on the parchment
    -- world-map background; amber was too washed out.
    local pin = CSR_Theme.getColor("rallyPin")
    local bg  = CSR_Theme.getColor("panelBg")

    -- Diamond shape via four drawRect calls (two crossed rectangles)
    if mapObject.drawRect then
        -- Outer dark border for contrast against light map
        mapObject:drawRect(uiX - 2, uiY - size - 1, 4, size * 2 + 2, 1.0, 0.0, 0.0, 0.0)
        mapObject:drawRect(uiX - size - 1, uiY - 2, size * 2 + 2, 4, 1.0, 0.0, 0.0, 0.0)
        -- Inner magenta core
        mapObject:drawRect(uiX - 1, uiY - size, 2, size * 2, 1.0, pin.r, pin.g, pin.b)
        mapObject:drawRect(uiX - size, uiY - 1, size * 2, 2, 1.0, pin.r, pin.g, pin.b)
    end

    -- Label
    if label and label ~= "" then
        local tm = getTextManager and getTextManager() or nil
        if tm and mapObject.drawText then
            local font = UIFont.Small
            local lw = _labelWidthCache[label]
            if not lw then
                lw = tm:MeasureStringX(font, label)
                _labelWidthCache[label] = lw
            end
            local tx = math.floor(uiX - lw / 2)
            local ty = math.floor(uiY + size + 2)
            local textColor = CSR_Theme.getColor("text")
            mapObject:drawText(label, tx, ty, textColor.r, textColor.g, textColor.b, 0.9, font)
        end
    end
end

-- Draw a dashed route line from (fromUIX,fromUIY) to (toUIX,toUIY)
local function drawRouteLine(mapObject, fromUIX, fromUIY, toUIX, toUIY)
    if not mapObject or not mapObject.drawRect then return end

    local dx = toUIX - fromUIX
    local dy = toUIY - fromUIY
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then return end

    local nx = dx / len
    local ny = dy / len

    local segLen  = 6   -- pixels per dash
    local gapLen  = 4   -- pixels per gap
    local stepLen = segLen + gapLen
    local steps   = math.floor(len / stepLen)

    local pin = CSR_Theme.getColor("rallyPin")

    for i = 0, steps - 1 do
        local startFrac = (i * stepLen) / len
        local endFrac   = math.min((i * stepLen + segLen) / len, 1.0)
        local x1 = math.floor(fromUIX + nx * startFrac * len)
        local y1 = math.floor(fromUIY + ny * startFrac * len)
        local x2 = math.floor(fromUIX + nx * endFrac   * len)
        local y2 = math.floor(fromUIY + ny * endFrac   * len)
        local w  = math.max(1, math.abs(x2 - x1))
        local h  = math.max(1, math.abs(y2 - y1))
        mapObject:drawRect(math.min(x1, x2), math.min(y1, y2), w, h, 0.85, pin.r, pin.g, pin.b)
    end
end

-- =====================================================================
-- Draw hook registered in CSR_PlayerMapTracker
-- =====================================================================
local function onMapDraw(mapObject, mapAPI, panelWidth, panelHeight)
    if not CSR_FeatureFlags.isRallyPointsEnabled() then return end
    if not mapAPI or type(mapAPI.worldToUIX) ~= "function" then return end
    if #activeWaypoints == 0 then return end

    pulseTimer = pulseTimer + 0.08

    local player = getPlayer()
    local playerUIX, playerUIY
    if player then
        playerUIX = mapAPI:worldToUIX(player:getX(), player:getY())
        playerUIY = mapAPI:worldToUIY(player:getX(), player:getY())
    end

    for _, wp in ipairs(activeWaypoints) do
        local uiX = mapAPI:worldToUIX(wp.x, wp.y)
        local uiY = mapAPI:worldToUIY(wp.x, wp.y)
        if uiX and uiY then
            -- Clip to panel bounds
            local inBounds = true
            if panelWidth  and (uiX < -16 or uiX > panelWidth  + 16) then inBounds = false end
            if panelHeight and (uiY < -16 or uiY > panelHeight + 16) then inBounds = false end

            if inBounds then
                -- Route line from player to waypoint
                if playerUIX and playerUIY then
                    drawRouteLine(mapObject, playerUIX, playerUIY, uiX, uiY)
                end
                -- Pin
                local displayLabel = wp.label
                if displayLabel == "" and wp.senderName and wp.senderName ~= "" then
                    displayLabel = wp.senderName
                end
                drawWaypointPin(mapObject, uiX, uiY, displayLabel, pulseTimer)
            end
        end
    end
end

-- =====================================================================
-- Inventory checks (v1.8.5: pencil + eraser gating)
-- =====================================================================
local PENCIL_TYPES = { "Base.Pencil", "Base.Pen", "Base.RedPen", "Base.BluePen", "Base.GreenPen" }
local ERASER_TYPES = { "Base.Eraser" }

local function inventoryHasAny(player, types)
    if not player then return false end
    local inv = player:getInventory()
    if not inv then return false end
    for i = 1, #types do
        if inv:containsType(types[i]) or inv:containsTypeRecurse(types[i]) then
            return true
        end
    end
    return false
 end

local function requirePencilFlag()
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    return sb.RallyRequirePencil ~= false
end

local function hasPencil(player) return (not requirePencilFlag()) or inventoryHasAny(player, PENCIL_TYPES) end
local function hasEraser(player) return inventoryHasAny(player, ERASER_TYPES) end

-- =====================================================================
-- Context menu on the world map (right-click)
-- =====================================================================
local function onPreDrawWorldMap(panel)
    -- No-op draw hook; context is added in onPreContextMenu below
end

-- Build the recipient picker submenu (Self / Faction / Safehouse / Specific / Everyone)
local function buildShareScopeMenu(menu, parentMenu)
    local function send(scope, targetUsername)
        if not pendingWaypoint then return end
        local player = getPlayer()
        if not player then return end
        sendClientCommand(player, "CommonSenseReborn", "ShareRallyPoint", {
            x = pendingWaypoint.x,
            y = pendingWaypoint.y,
            z = pendingWaypoint.z,
            label = pendingWaypoint.label or "",
            scope = scope,
            targetUsername = targetUsername or "",
        })
    end

    menu:addOption(getText("IGUI_CSR_RallySelfOnly") or "Self only", nil, function() send("self") end)
    menu:addOption(getText("IGUI_CSR_RallyFactionMembers") or "Faction members", nil, function() send("faction") end)
    menu:addOption(getText("IGUI_CSR_RallySafehouseMembers") or "Safehouse members", nil, function() send("safehouse") end)
    menu:addOption(getText("IGUI_CSR_RallyEveryone") or "Everyone online", nil, function() send("everyone") end)

    -- Specific player submenu
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if players and players.size and players:size() > 0 then
        local specificOpt = menu:addOption(getText("IGUI_CSR_RallySpecificPlayer") or "Specific player...", nil, nil)
        local subMenu = ISContextMenu:getNew(menu)
        menu:addSubMenu(specificOpt, subMenu)
        local me = getPlayer() and getPlayer():getUsername() or ""
        for i = 0, players:size() - 1 do
            local p = players:get(i)
            local uname = p and p.getUsername and p:getUsername() or nil
            if uname and uname ~= me then
                subMenu:addOption(tostring(uname), nil, function() send("player", tostring(uname)) end)
            end
        end
    end
end

-- v1.8.14: combined "set and share" action. Captures the right-click
-- world coords, stores them as pendingWaypoint, and (for non-self
-- scopes) immediately fires ShareRallyPoint so the user only needs ONE
-- right-click cycle. Previously users had to right-click -> Set Rally
-- Point, then right-click AGAIN -> Share Rally Point -> scope submenu;
-- the share scopes now sit at the top level of the world-map context
-- menu and atomically set+share.
local function setPinAndShare(panel, capturedX, capturedY, scope, targetUsername)
    local mapAPI = panel and (panel.mapAPI or (panel.getAPIv1 and panel:getAPIv1()))
    if not mapAPI then return end
    local wx = mapAPI:uiToWorldX(capturedX, capturedY)
    local wy = mapAPI:uiToWorldY(capturedX, capturedY)
    if not wx or not wy then return end
    pendingWaypoint = { x = math.floor(wx), y = math.floor(wy), z = 0, label = "" }
    local player = getPlayer()
    if not player then return end
    -- v1.8.15: "self" scope used to silently no-op here, leaving
    -- activeWaypoints empty and the draw loop with nothing to render
    -- (no pin, no route line). Always round-trip through the server so
    -- the echo back populates activeWaypoints uniformly across every
    -- scope, matching pre-1.8.14 behaviour where self-only also drew.
    sendClientCommand(player, "CommonSenseReborn", "ShareRallyPoint", {
        x = pendingWaypoint.x,
        y = pendingWaypoint.y,
        z = pendingWaypoint.z,
        label = "",
        scope = scope,
        targetUsername = targetUsername or "",
    })
end

local function addMapContextOptions(menu, panel, clickX, clickY)
    if not CSR_FeatureFlags.isRallyPointsEnabled() then return end
    if not isClient() then return end  -- MP only

    local mapAPI = panel and (panel.mapAPI or (panel.getAPIv1 and panel:getAPIv1()))
    if not mapAPI then return end

    local player = getPlayer()
    local pencilOk = hasPencil(player)

    -- v1.8.13: capture the right-click position at hook time. Reading
    -- getMouseX()/Y() inside the option callback returns the cursor's
    -- position when the user clicks the menu entry, not the original
    -- right-click position -- which made the rally pin land on top of
    -- the menu instead of where the player clicked.
    local capturedX = clickX or getMouseX()
    local capturedY = clickY or getMouseY()

    local function notAvail(opt, reason)
        opt.notAvailable = true
        if reason and ISWorldMapSymbols_Tooltip then
            local tt = ISWorldMapSymbols_Tooltip:new()
            if tt then
                tt.description = reason
                opt.toolTip = tt
            end
        end
    end

    -- v1.8.14: scope options live at the TOP level. Each one sets the
    -- pin at the clicked coord AND fires the broadcast in a single
    -- click. "Personal pin only" is the local-only equivalent of the
    -- old "Set Rally Point" + Share -> Self only flow.
    local _needPencil = getText("IGUI_CSR_RallyNeedPencil") or "Requires a pencil or pen in your inventory."
    local setSelf = menu:addOption(getText("IGUI_CSR_RallySetPersonal") or "Set Rally Point (personal)", nil,
        function() setPinAndShare(panel, capturedX, capturedY, "self") end)
    if not pencilOk then notAvail(setSelf, _needPencil) end

    local setFaction = menu:addOption(getText("IGUI_CSR_RallyShareFaction") or "Share Rally Point with Faction", nil,
        function() setPinAndShare(panel, capturedX, capturedY, "faction") end)
    if not pencilOk then notAvail(setFaction, _needPencil) end

    local setSafehouse = menu:addOption(getText("IGUI_CSR_RallyShareSafehouse") or "Share Rally Point with Safehouse", nil,
        function() setPinAndShare(panel, capturedX, capturedY, "safehouse") end)
    if not pencilOk then notAvail(setSafehouse, _needPencil) end

    local setEveryone = menu:addOption(getText("IGUI_CSR_RallyShareEveryone") or "Share Rally Point with Everyone", nil,
        function() setPinAndShare(panel, capturedX, capturedY, "everyone") end)
    if not pencilOk then notAvail(setEveryone, _needPencil) end

    -- Specific-player picker is the only option that still needs a
    -- submenu (one entry per online player) -- by definition it can't
    -- live at the top level.
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if players and players.size and players:size() > 1 then
        local specificOpt = menu:addOption(getText("IGUI_CSR_RallyShareSpecific") or "Share Rally Point with Specific player...", nil, nil)
        local subMenu = ISContextMenu:getNew(menu)
        menu:addSubMenu(specificOpt, subMenu)
        local me = player and player:getUsername() or ""
        for i = 0, players:size() - 1 do
            local p = players:get(i)
            local uname = p and p.getUsername and p:getUsername() or nil
            if uname and uname ~= me then
                subMenu:addOption(tostring(uname), nil,
                    function() setPinAndShare(panel, capturedX, capturedY, "player", tostring(uname)) end)
            end
        end
        if not pencilOk then notAvail(specificOpt, _needPencil) end
    end

    if pendingWaypoint or #activeWaypoints > 0 then
        menu:addOption(getText("IGUI_CSR_RallyClear") or "Clear Rally Point", nil, function()
            pendingWaypoint = nil
            activeWaypoints = {}
        end)
    end
end

-- =====================================================================
-- Server response handler
-- =====================================================================
local function onRallyPointReceived(args)
    if not args then return end
    local x = tonumber(args.x)
    local y = tonumber(args.y)
    if not x or not y then return end

    -- Replace any existing waypoint from the same sender
    local senderName = tostring(args.senderName or "")
    for i, wp in ipairs(activeWaypoints) do
        if wp.senderName == senderName then
            table.remove(activeWaypoints, i)
            break
        end
    end

    table.insert(activeWaypoints, {
        x = x,
        y = y,
        z = tonumber(args.z) or 0,
        label = tostring(args.label or ""),
        senderName = senderName,
    })

    -- Also set as personal pending so we can see it on our own map
    if pendingWaypoint == nil then
        pendingWaypoint = { x = x, y = y, z = tonumber(args.z) or 0, label = tostring(args.label or "") }
    end
end

-- =====================================================================
-- Auto-clear when player arrives
-- =====================================================================
local function onPlayerUpdate()
    if #activeWaypoints == 0 then return end
    local player = getPlayer()
    if not player then return end
    local px = player:getX()
    local py = player:getY()

    local i = #activeWaypoints
    while i >= 1 do
        local wp = activeWaypoints[i]
        local dx = px - wp.x
        local dy = py - wp.y
        if math.sqrt(dx * dx + dy * dy) <= ARRIVE_DISTANCE then
            table.remove(activeWaypoints, i)
            if pendingWaypoint and pendingWaypoint.x == wp.x and pendingWaypoint.y == wp.y then
                pendingWaypoint = nil
            end
        end
        i = i - 1
    end
end

-- =====================================================================
-- ISWorldMap context menu hook
-- v1.8.5: Hook onRightMouseUp (not onRightMouseDown) so vanilla's admin
-- TeleportHere option (added in onRightMouseUp) survives and is reachable.
-- We APPEND to the menu vanilla just built rather than creating our own
-- ISContextMenu instance (which would clobber the singleton).
-- v1.8.6: ISContextMenu.lastInstance does NOT exist in vanilla (verified
-- against ISContextMenu.lua) -- the v1.8.5 lookup was always nil and the
-- fallback ISContextMenu.get(0,...) silently CALLED :clear() on the
-- singleton, wiping vanilla's just-built admin menu (TeleportHere included).
-- The admin teleport regression came from this. Correct API is
-- getPlayerContextMenu(player) which returns the singleton WITHOUT clearing.
-- =====================================================================
local function patchWorldMapContextMenu()
    if not ISWorldMap or ISWorldMap.__csr_rally_ctx then return end
    ISWorldMap.__csr_rally_ctx = true

    -- v1.8.16 drag-vs-click guard: PZ uses right-click-drag to pan the
    -- world map. Without a guard, every drag's mouse-up still ran the
    -- menu append below, which (a) produced a duplicate "Set Rally
    -- Point" entry stacked on the singleton and (b) was repeatable
    -- infinitely by dragging again before clicking the menu away.
    -- Track press coords and only append menu options when the cursor
    -- has not moved beyond a small dead-zone, i.e. an actual click.
    local DRAG_DEADZONE_SQ = 6 * 6
    local origMouseDown = ISWorldMap.onRightMouseDown
    function ISWorldMap:onRightMouseDown(x, y)
        self.__csr_rally_downX = x or 0
        self.__csr_rally_downY = y or 0
        if origMouseDown then return origMouseDown(self, x, y) end
    end

    -- Defensive: remove any prior CSR rally entries from the singleton
    -- before we re-append. Prevents stacking if vanilla rebuilt the
    -- menu without clearing the prior frame's options.
    local CSR_RALLY_OPTS = {
        "Set Rally Point (personal)",
        "Share Rally Point with Faction",
        "Share Rally Point with Safehouse",
        "Share Rally Point with Everyone",
        "Share Rally Point with Specific player...",
        "Clear Rally Point",
    }
    local function purgePriorRallyOptions(menu)
        if not menu or not menu.removeOptionByName then return end
        for _, name in ipairs(CSR_RALLY_OPTS) do
            menu:removeOptionByName(name)
        end
    end

    local origMouseUp = ISWorldMap.onRightMouseUp
    if origMouseUp then
        function ISWorldMap:onRightMouseUp(x, y)
            local r = origMouseUp(self, x, y)
            local localX = x or 0
            local localY = y or 0
            local downX  = self.__csr_rally_downX
            local downY  = self.__csr_rally_downY
            self.__csr_rally_downX = nil
            self.__csr_rally_downY = nil
            if downX ~= nil and downY ~= nil then
                local dx = localX - downX
                local dy = localY - downY
                if (dx * dx + dy * dy) > DRAG_DEADZONE_SQ then
                    -- Treat as a pan-drag, not a click. Do not touch
                    -- the context menu (vanilla didn't open one for
                    -- the same reason).
                    return r
                end
            end
            local screenX = getMouseX()
            local screenY = getMouseY()
            local menu = nil
            if getPlayerContextMenu then
                menu = getPlayerContextMenu(0)
            end
            local visible = menu and menu.getIsVisible and menu:getIsVisible()
            if not menu or not visible then
                menu = ISContextMenu.get(0, screenX, screenY)
            end
            if menu then
                purgePriorRallyOptions(menu)
                addMapContextOptions(menu, self, localX, localY)
            end
            return r
        end
    end
end

-- =====================================================================
-- Wire up hooks
-- =====================================================================
local function onGameStart()
    -- Register draw hooks with CSR_PlayerMapTracker
    if CSR_PlayerMapTracker then
        table.insert(CSR_PlayerMapTracker.worldMapDrawHooks, onMapDraw)
        table.insert(CSR_PlayerMapTracker.miniMapDrawHooks,  onMapDraw)
    end
    patchWorldMapContextMenu()
end

-- Idempotent event registration: prevent duplicate callbacks on world reload
if Events and not CSR_RallyPoints._evRegistered then
    CSR_RallyPoints._evRegistered = true
    if Events.OnServerCommand then
        Events.OnServerCommand.Add(function(module, command, args)
            if module ~= "CommonSenseReborn" then return end
            if command == "RallyPointReceived" then
                onRallyPointReceived(args)
            end
        end)
    end
    if Events.OnGameStart    then Events.OnGameStart.Add(onGameStart) end
    if Events.OnPlayerUpdate then Events.OnPlayerUpdate.Add(onPlayerUpdate) end
end

return CSR_RallyPoints
