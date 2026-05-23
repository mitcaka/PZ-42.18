-- CSR_PowerLineClient.lua  (v1.8.34)
-- Right-click "Start Power Line" on any powered tile, walk to paint a blue
-- trail of "extension cord", right-click destination "End Power Line Here"
-- to consume one Base.PowerBar from your inventory and convert every
-- painted square (plus the destination) to a permanent powered tile.
--
-- Battery placebo (#7): every minute, while the player stands on a
-- csr-powered square, drainable battery items (flashlights, lighters,
-- some lamps) in the player's inventory are kept topped up — as if
-- plugged into the cord. Pure cosmetic — no XP, no stats.
require "CSR_FeatureFlags"
require "CSR_PowerLine"
require "CSR_PowerLineSprites"

local PAINT_TICK_GUARD = 8 -- ticks
local _painting = false
local _paintCount = 0
local _lastPaintTick = 0
local noteOverlaySquare = nil

local function sb() return SandboxVars and SandboxVars.CommonSenseReborn or {} end
local function isEnabled() return CSR_PowerLine.isEnabled() end

local function findPowerBar(player)
    if not player or not player.getInventory then return nil end
    local inv = player:getInventory()
    if not inv then return nil end
    return inv:getFirstTypeRecurse("PowerBar")
end

local function say(player, key, fallback)
    if not player or not player.Say then return end
    pcall(function()
        local s = (getText and getText(key)) or fallback
        if s and s ~= key then player:Say(s) end
    end)
end

-- ─────────────────────────────────────────────────────
-- Paint loop — fires on OnTick while painting.
-- ─────────────────────────────────────────────────────
local function paintTick()
    if not isEnabled() or not _painting then return end
    local player = getSpecificPlayer(0)
    if not player or player:isDead() then _painting = false; return end

    local now = (getGameTime and getGameTime():getWorldAgeHours() or 0) * 3600
    if (now - _lastPaintTick) < (PAINT_TICK_GUARD / 30.0) then return end
    _lastPaintTick = now

    if not player:isMoving() or player:isSprinting() then return end

    local sq = player:getCurrentSquare()
    if not sq then return end
    if CSR_PowerLine.isPaintedTrail(sq) or CSR_PowerLine.isPaintedPowered(sq) then return end

    if _paintCount >= CSR_PowerLine.maxLineLength() then
        _painting = false
        say(player, "IGUI_CSR_PowerLine_TooLong", "Cable's run out.")
        return
    end

    -- Optimistically set client-side modData so the trail overlay
    -- shows immediately. Server is authoritative.
    CSR_PowerLine.setPaintedTrail(sq, true)
    if noteOverlaySquare then noteOverlaySquare(sq, "paint") end
    if isClient() then
        sendClientCommand(player, "CommonSenseReborn", "PowerLinePaint", {
            x = sq:getX(), y = sq:getY(), z = sq:getZ()
        })
    end
    _paintCount = _paintCount + 1
end

-- ─────────────────────────────────────────────────────
-- Start / End commands
-- ─────────────────────────────────────────────────────
local function onStart(playerNum, sourceSq)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    if not findPowerBar(player) then
        say(player, "IGUI_CSR_PowerLine_NeedBar", "I need a Power Bar.")
        return
    end
    _painting = true
    _paintCount = 0
    -- Paint the source tile immediately so it's part of the chain.
    if sourceSq then
        CSR_PowerLine.setPaintedTrail(sourceSq, true)
        if noteOverlaySquare then noteOverlaySquare(sourceSq, "paint") end
        if isClient() then
            sendClientCommand(player, "CommonSenseReborn", "PowerLinePaint", {
                x = sourceSq:getX(), y = sourceSq:getY(), z = sourceSq:getZ()
            })
        end
        _paintCount = 1
    end
    say(player, "IGUI_CSR_PowerLine_Started", "Running cord...")
end

local function onEnd(playerNum, endSq)
    local player = getSpecificPlayer(playerNum)
    if not player or not endSq then return end
    _painting = false
    if isClient() then
        sendClientCommand(player, "CommonSenseReborn", "PowerLineEnd", {
            x = endSq:getX(), y = endSq:getY(), z = endSq:getZ()
        })
    elseif CSR_ServerCommands and CSR_ServerCommands.handlePowerLineEnd then
        CSR_ServerCommands.handlePowerLineEnd(player, {
            x = endSq:getX(), y = endSq:getY(), z = endSq:getZ()
        })
    end
    _paintCount = 0
end

local function onCancel(playerNum)
    _painting = false
    _paintCount = 0
    local player = getSpecificPlayer(playerNum)
    if player and isClient() then
        sendClientCommand(player, "CommonSenseReborn", "PowerLineCancel", {})
    end
    say(player, "IGUI_CSR_PowerLine_Cancelled", "Cord stowed.")
end

-- ─────────────────────────────────────────────────────
-- Context menu
-- ─────────────────────────────────────────────────────
local function onFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    if test then return end
    if not isEnabled() then return end
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    local sq = nil
    for i = 1, #worldobjects do
        local o = worldobjects[i]
        local s = o and o.getSquare and o:getSquare() or nil
        if s then sq = s; break end
    end
    if not sq then return end

    if _painting then
        context:addOption(getText and getText("IGUI_CSR_PowerLine_End") or "End Power Line Here",
            playerNum, onEnd, sq)
        context:addOption(getText and getText("IGUI_CSR_PowerLine_Cancel") or "Cancel Power Line",
            playerNum, onCancel)
        return
    end

    -- Already-powered tile: offer "Remove Wiring" so the player can
    -- reclaim/redo a run. Removes the entire BFS-connected painted-power
    -- chain rooted at the right-clicked square.
    if CSR_PowerLine.isWiringTile and CSR_PowerLine.isWiringTile(sq) then
        -- On/Off toggle (whole connected chain). Like a generator.
        local isOff = CSR_PowerLine.isDisabled and CSR_PowerLine.isDisabled(sq) or false
        local label = isOff
            and (getText and getText("IGUI_CSR_PowerLine_TurnOn") or "Turn Wiring On")
            or  (getText and getText("IGUI_CSR_PowerLine_TurnOff") or "Turn Wiring Off")
        context:addOption(label, playerNum,
            function(pn, sqr, off)
                if isClient() then
                    sendClientCommand(getSpecificPlayer(pn), "CommonSenseReborn", "PowerLineToggle", {
                        x = sqr:getX(), y = sqr:getY(), z = sqr:getZ(), off = off
                    })
                elseif CSR_ServerCommands and CSR_ServerCommands.handlePowerLineToggle then
                    CSR_ServerCommands.handlePowerLineToggle(getSpecificPlayer(pn), {
                        x = sqr:getX(), y = sqr:getY(), z = sqr:getZ(), off = off
                    })
                end
            end, sq, not isOff)

        context:addOption(
            getText and getText("IGUI_CSR_PowerLine_Remove") or "Remove Wiring",
            playerNum,
            function()
                if isClient() then
                    sendClientCommand(player, "CommonSenseReborn", "PowerLineRemove", {
                        x = sq:getX(), y = sq:getY(), z = sq:getZ()
                    })
                else
                    -- SP: clear directly.
                    local cell = getCell(); if not cell then return end
                    local seen = {}
                    local function k(s) return s:getX()..","..s:getY()..","..s:getZ() end
                    local q = { sq }; local h = 1
                    while q[h] do
                        local cur = q[h]; h = h + 1
                        local key = k(cur)
                        if not seen[key] then
                            seen[key] = true
                            local md = cur:getModData()
                            if md and md[CSR_PowerLine.POWER_KEY] == true then
                                md[CSR_PowerLine.POWER_KEY] = nil
                                md[CSR_PowerLine.PAINT_KEY] = nil
                                if noteOverlaySquare then noteOverlaySquare(cur, nil) end
                                for dx = -1, 1 do for dy = -1, 1 do
                                    if not (dx == 0 and dy == 0) then
                                        local nb = cell:getGridSquare(cur:getX()+dx, cur:getY()+dy, cur:getZ())
                                        if nb then q[#q+1] = nb end
                                    end
                                end end
                            end
                        end
                    end
                end
            end)
    end

    -- To start, the source tile must already be powered.
    if not CSR_PowerLine.isPowered(sq) then return end
    -- And the player must carry a Power Bar.
    if not findPowerBar(player) then return end

    context:addOption(getText and getText("IGUI_CSR_PowerLine_Start") or "Start Power Line",
        playerNum, onStart, sq)
end

-- ─────────────────────────────────────────────────────
-- Battery placebo (#7) — top up drainables while standing on cord.
-- Runs once a minute, only if a powered tile is under the player.
-- ─────────────────────────────────────────────────────
local PLACEBO_TYPES = {
    ["Base.Flashlight"]            = true,
    ["Base.HandTorch_Flash"]       = true,
    ["Base.Torch_Electric"]        = true,
    ["Base.Lighter"]               = true,
    ["Base.Lantern"]               = true,
    ["Base.LanternHand"]           = true,
}

local function placeboTick()
    if not isEnabled() then return end
    if sb().EnablePowerLineBatteryPlacebo == false then return end
    local player = getSpecificPlayer(0)
    if not player or player:isDead() then return end
    local sq = player:getCurrentSquare()
    if not sq or not CSR_PowerLine.isPaintedPowered(sq) then return end

    local inv = player:getInventory()
    if not inv then return end
    local items = inv:getItems()
    if not items then return end
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it.IsDrainable and it:IsDrainable() then
            local ft = it.getFullType and it:getFullType() or ""
            -- Allowlist by type only. We previously had an `it:hasTag(...)`
            -- fallback for "Flashlight"/"Torch" tags, but hasTag isn't
            -- exposed on DrainableComboItem (e.g. Base.Battery) and would
            -- throw "No implementation found for function: hasTag" every
            -- tick. The named-type list above already covers every drainable
            -- we want to top up.
            if PLACEBO_TYPES[ft] and it.setUsedDelta then
                -- Top up to full each minute. Vanilla drain still happens
                -- between ticks so the visual indicator still ticks down a
                -- hair, but it never empties.
                it:setUsedDelta(1.0)
            end
        end
    end
end

-- ─────────────────────────────────────────────────────
-- Blue ground overlay for painted/powered squares.
--
-- Rendering strategy: UI-space screen overlay (ISPanel:render +
-- IsoUtils.XToScreen projection). The earlier IsoSprite RenderGhostTile
-- approach worked but was z-sorted into the world, so it was occluded
-- by the player's body or walls when the camera was close — players
-- complained the wiring "only shows from a distance/angle". Drawing in
-- UI space (OnPostUIDraw) puts the markers on top of the entire world
-- layer regardless of camera zoom or rotation. Same pattern as
-- CSR_PowerBarOverlay.
-- ─────────────────────────────────────────────────────
local DRAW_RADIUS_TILES = 30   -- only paint tiles within this Manhattan distance
local OVERLAY_SCAN_MS = 1000   -- rebuild cache at most once/sec
local OVERLAY_SCAN_MOVE_TILES = 6

local _plMarkers = {} -- ["x,y,z"] = { x, y, z, state="power"|"paint", disabled=bool }
local _plLastScanMs = 0
local _plScanX, _plScanY, _plScanZ = nil, nil, nil

local function nowMs()
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    if os and os.time then return os.time() * 1000 end
    return 0
end

local function markerKey(x, y, z)
    return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end

local function putMarker(x, y, z, state, disabled)
    if x == nil or y == nil or z == nil then return end
    local k = markerKey(x, y, z)
    if not state then
        _plMarkers[k] = nil
        return
    end
    local mx = tonumber(x) or 0
    local my = tonumber(y) or 0
    local mz = tonumber(z) or 0
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if player then
        local pz = math.floor(tonumber(player:getZ()) or 0)
        local limit = DRAW_RADIUS_TILES + OVERLAY_SCAN_MOVE_TILES
        if mz ~= pz
            or math.abs(mx - (tonumber(player:getX()) or 0)) > limit
            or math.abs(my - (tonumber(player:getY()) or 0)) > limit then
            return
        end
    end
    _plMarkers[k] = {
        x = mx,
        y = my,
        z = mz,
        state = state,
        disabled = disabled == true,
    }
end

noteOverlaySquare = function(sq, state, disabled)
    if not sq then return end
    if CSR_PowerLineSprites and CSR_PowerLineSprites.syncAround then
        CSR_PowerLineSprites.syncAround(sq)
        putMarker(sq:getX(), sq:getY(), sq:getZ(), nil)
        return
    end
    putMarker(sq:getX(), sq:getY(), sq:getZ(), state, disabled)
end

local function hasMarkers()
    for _ in pairs(_plMarkers) do return true end
    return false
end

local function refreshOverlayCache(player, cell, px, py, zi)
    local now = nowMs()
    local moved = (_plScanX == nil)
        or (_plScanZ ~= zi)
        or math.abs((_plScanX or 0) - px) > OVERLAY_SCAN_MOVE_TILES
        or math.abs((_plScanY or 0) - py) > OVERLAY_SCAN_MOVE_TILES
    if not moved and (now - _plLastScanMs) < OVERLAY_SCAN_MS then return end

    _plLastScanMs = now
    _plScanX, _plScanY, _plScanZ = px, py, zi

    local seen = {}
    local r = DRAW_RADIUS_TILES
    local sx = math.floor(px - r)
    local sy = math.floor(py - r)
    local ex = math.floor(px + r)
    local ey = math.floor(py + r)

    for x = sx, ex do
        for y = sy, ey do
            local sq = cell:getGridSquare(x, y, zi)
            if sq then
                local k = markerKey(x, y, zi)
                if CSR_PowerLine.isWiringTile and CSR_PowerLine.isWiringTile(sq) then
                    seen[k] = true
                    putMarker(x, y, zi, "power",
                        CSR_PowerLine.isDisabled and CSR_PowerLine.isDisabled(sq) or false)
                elseif CSR_PowerLine.isPaintedTrail and CSR_PowerLine.isPaintedTrail(sq) then
                    seen[k] = true
                    putMarker(x, y, zi, "paint", false)
                end
            end
        end
    end

    -- Prune stale cached markers in the current scan window, and drop
    -- far-away markers so MP broadcasts elsewhere do not grow this table.
    for k, marker in pairs(_plMarkers) do
        local far = marker.z ~= zi
            or math.abs(marker.x - px) > (r + OVERLAY_SCAN_MOVE_TILES)
            or math.abs(marker.y - py) > (r + OVERLAY_SCAN_MOVE_TILES)
        local staleLocal = marker.z == zi
            and math.abs(marker.x - px) <= r
            and math.abs(marker.y - py) <= r
            and not seen[k]
        if far or staleLocal then
            _plMarkers[k] = nil
        end
    end
end

local CSR_PL_OverlayPanel = ISPanel:derive("CSR_PL_OverlayPanel")

local function plDrawTileMarker(self, wx, wy, wz, sw_off, sh_off, zoom, sz, a, r, g, b)
    local sx = IsoUtils.XToScreen(wx + 0.5, wy + 0.5, wz, 0)
    local sy = IsoUtils.YToScreen(wx + 0.5, wy + 0.5, wz, 0)
    sx = (sx - sw_off) / zoom
    sy = (sy - sh_off) / zoom
    -- Flat diamond-ish rectangle, oriented like a top-down floor tile.
    self:drawRect(sx - sz * 0.5, sy - sz * 0.25, sz, sz * 0.5, a, r, g, b)
end

function CSR_PL_OverlayPanel:render()
    if not isEnabled() then return end
    local player = getSpecificPlayer(0); if not player then return end
    local cell = getCell();              if not cell   then return end
    local px, py, pz = player:getX(), player:getY(), player:getZ()
    if not px then return end
    local zi = math.floor(pz)

    local core = getCore()
    local zoom = core:getZoom(0)
    local offX = IsoCamera.getOffX()
    local offY = IsoCamera.getOffY()
    local sz   = 16 / zoom    -- tile-marker side length in pixels

    refreshOverlayCache(player, cell, px, py, zi)
    if not hasMarkers() then return end

    local r = DRAW_RADIUS_TILES
    for _, marker in pairs(_plMarkers) do
        if marker.z == zi
            and math.abs(marker.x - px) <= r
            and math.abs(marker.y - py) <= r then
            if marker.state == "power" then
                if marker.disabled then
                    -- Off: dim gray
                    plDrawTileMarker(self, marker.x, marker.y, zi, offX, offY, zoom, sz,
                                     0.55, 0.45, 0.45, 0.45)
                else
                    -- On: vivid blue
                    plDrawTileMarker(self, marker.x, marker.y, zi, offX, offY, zoom, sz,
                                     0.85, 0.20, 0.55, 1.00)
                end
            elseif marker.state == "paint" then
                -- In-progress trail: lighter blue
                plDrawTileMarker(self, marker.x, marker.y, zi, offX, offY, zoom, sz,
                                 0.70, 0.50, 0.75, 1.00)
            end
        end
    end
end

local _plPanel = nil
local function ensurePLPanel()
    if _plPanel and _plPanel.javaObject then return end
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    _plPanel = CSR_PL_OverlayPanel:new(0, 0, sw, sh)
    _plPanel.background = false
    _plPanel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    _plPanel:initialise()
    _plPanel:instantiate()
    if _plPanel.javaObject and _plPanel.javaObject.setConsumeMouseEvents then
        _plPanel.javaObject:setConsumeMouseEvents(false)
    end
end

local function drawOverlays()
    if not isEnabled() then return end
    if CSR_PowerLineSprites and CSR_PowerLineSprites.isEnabled and CSR_PowerLineSprites.isEnabled() then return end
    ensurePLPanel()
    if _plPanel and _plPanel.render then _plPanel:render() end
end

if Events then
    if Events.OnTick then Events.OnTick.Add(paintTick) end
    if Events.OnFillWorldObjectContextMenu then
        Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
    end
    if Events.OnFillInventoryObjectContextMenu then
        -- Inventory-side discoverability: right-click a Power Bar in the
        -- player's inventory to see "Start Power Line Here" (or a hint
        -- explaining why it's unavailable).
        Events.OnFillInventoryObjectContextMenu.Add(function(playerNum, context, items)
            if not isEnabled() then return end
            local player = getSpecificPlayer(playerNum)
            if not player then return end
            -- Look for a PowerBar in the right-clicked stack.
            local bar = nil
            for i = 1, #items do
                local entry = items[i]
                local it = entry
                if entry.items and entry.items[1] then it = entry.items[1] end
                if it and it.getFullType and it:getFullType() == "Base.PowerBar" then
                    bar = it; break
                end
            end
            if not bar then return end
            local sq = player:getCurrentSquare()
            local powered = sq and CSR_PowerLine.isPowered(sq)
            local label = getText and getText("IGUI_CSR_PowerLine_Start") or "Start Power Line"
            local opt
            if _painting then
                -- Already painting: offer Cancel.
                opt = context:addOption(
                    getText and getText("IGUI_CSR_PowerLine_Cancel") or "Cancel Power Line",
                    playerNum, onCancel)
            elseif powered then
                opt = context:addOption(label, playerNum, onStart, sq)
            else
                opt = context:addOption(label, playerNum, function() end)
                opt.notAvailable = true
                local tip = ISToolTip:new(); tip:initialise(); tip:setVisible(false)
                tip.description = "<RED>" .. (getText and getText("Tooltip_CSR_PowerLine_NeedPowered") or
                    "Stand on a powered tile (vanilla power, generator radius, or an existing Power Line) to start.")
                opt.toolTip = tip
            end
        end)
    end
    if Events.OnPostUIDraw
        and not (CSR_PowerLineSprites and CSR_PowerLineSprites.isEnabled and CSR_PowerLineSprites.isEnabled()) then
        Events.OnPostUIDraw.Add(drawOverlays)
    end
    if Events.EveryOneMinute then Events.EveryOneMinute.Add(placeboTick) end
    if Events.OnServerCommand then
        Events.OnServerCommand.Add(function(module, command, args)
            if module ~= "CommonSenseReborn" then return end
            if command ~= "PowerLineSquareSync" then return end
            if not args or args.x == nil or args.y == nil or args.z == nil then return end
            local cell = getWorld() and getWorld():getCell() or nil
            if not cell then return end
            local sq = cell:getGridSquare(args.x, args.y, args.z)
            if not sq or not sq.getModData then return end
            local md = sq:getModData()
            if not md then return end
            if args.clear then
                md[CSR_PowerLine.PAINT_KEY] = nil
                if args.clearPower then
                    md[CSR_PowerLine.POWER_KEY] = nil
                    md[CSR_PowerLine.DISABLED_KEY] = nil
                end
                if noteOverlaySquare then noteOverlaySquare(sq, nil) end
                return
            end
            if args.toggleOff ~= nil then
                if args.toggleOff then md[CSR_PowerLine.DISABLED_KEY] = true
                else                   md[CSR_PowerLine.DISABLED_KEY] = nil end
                if noteOverlaySquare then noteOverlaySquare(sq, "power", args.toggleOff == true) end
                return
            end
            if args.power then
                md[CSR_PowerLine.POWER_KEY] = true
                md[CSR_PowerLine.PAINT_KEY] = nil
                if noteOverlaySquare then noteOverlaySquare(sq, "power", false) end
            elseif args.paint then
                md[CSR_PowerLine.PAINT_KEY] = true
                if noteOverlaySquare then noteOverlaySquare(sq, "paint", false) end
            end
        end)
    end
end
