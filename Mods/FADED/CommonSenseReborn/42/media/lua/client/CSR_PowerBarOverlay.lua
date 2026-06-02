-- CSR_PowerBarOverlay.lua — world-space radius indicator for placed Power Bars.
-- Renders a translucent diamond outline at the bar's tile so players can see
-- exactly how far its cable will reach. Color encodes status:
--   * cyan        = bar is energized
--   * dim grey    = bar is placed but currently has no power
-- Gated by sandbox option `EnablePowerBarRangeOverlay` (default true).
require "CSR_PowerBar"

if isServer() then return end

local CSR_PowerBarOverlay = {}

local function sandbox()
    return SandboxVars and SandboxVars.CommonSenseReborn or {}
end

local function isEnabled()
    if not CSR_PowerBar or not CSR_PowerBar.isFeatureEnabled() then return false end
    local sb = sandbox()
    if sb.EnablePowerBarRangeOverlay == false then return false end
    return true
end

-- ----------------------------------------------------------------------------
-- Render panel: covers the screen, draws diamonds for nearby bars.
-- ----------------------------------------------------------------------------
local CSR_PB_OverlayPanel = ISPanel:derive("CSR_PB_OverlayPanel")

local TILE_SIZE        = 10   -- side of each tinted square (pixels)
local DRAW_RANGE_TILES = 30   -- only draw bars within this Manhattan distance

local function nodeIsLiveLocal(n)
    if not n then return false end
    local cell = getCell(); if not cell then return false end
    local sq = cell:getGridSquare(n.x, n.y, n.z)
    if not sq then return false end
    local has = false
    pcall(function() has = sq:haveElectricity() end)
    if has then return true end
    if not pcall(function() has = (not sq:isOutside()) and getWorld():isHydroPowerOn() end) then
        return false
    end
    return has
end

local function drawTileMarker(self, wx, wy, wz, sw_off, sh_off, zoom, sz, a, r, g, b)
    local sx = IsoUtils.XToScreen(wx + 0.5, wy + 0.5, wz, 0)
    local sy = IsoUtils.YToScreen(wx + 0.5, wy + 0.5, wz, 0)
    sx = (sx - sw_off) / zoom
    sy = (sy - sh_off) / zoom
    self:drawRect(sx - sz * 0.5, sy - sz * 0.25, sz, sz * 0.5, a, r, g, b)
end

function CSR_PB_OverlayPanel:render()
    if not isEnabled() then return end
    if not CSR_PowerBar or not CSR_PowerBar.nodes then return end
    local p = getSpecificPlayer(0); if not p then return end
    local pz = p:getZ()
    local px, py = p:getX(), p:getY()

    local core = getCore()
    local zoom = core:getZoom(0)
    local offX = IsoCamera.getOffX()
    local offY = IsoCamera.getOffY()
    local sz   = TILE_SIZE / zoom

    for _, n in pairs(CSR_PowerBar.nodes) do
        if n and n.z == pz then
            local dx = math.abs(n.x - px)
            local dy = math.abs(n.y - py)
            if (dx + dy) <= DRAW_RANGE_TILES then
                local live = nodeIsLiveLocal(n)
                local r, g, b, a
                if live then
                    r, g, b, a = 0.20, 0.80, 0.95, 0.55  -- cyan
                else
                    r, g, b, a = 0.55, 0.55, 0.55, 0.40  -- grey
                end

                -- Anchor tile (slightly brighter)
                drawTileMarker(self, n.x, n.y, n.z, offX, offY, zoom, sz * 1.4,
                               math.min(1, a + 0.25), r, g, b)

                -- Diamond perimeter at radius = wires
                local w = tonumber(n.wires) or 0
                if w > 0 then
                    for k = 0, w do
                        local kk = w - k
                        drawTileMarker(self, n.x + k,  n.y + kk, n.z, offX, offY, zoom, sz, a, r, g, b)
                        drawTileMarker(self, n.x + k,  n.y - kk, n.z, offX, offY, zoom, sz, a, r, g, b)
                        drawTileMarker(self, n.x - k,  n.y + kk, n.z, offX, offY, zoom, sz, a, r, g, b)
                        drawTileMarker(self, n.x - k,  n.y - kk, n.z, offX, offY, zoom, sz, a, r, g, b)
                    end
                end
            end
        end
    end

    -- Cable lines to connected chargers: dashed dim-yellow markers per tile.
    if CSR_PowerBar.chargers then
        for _, c in pairs(CSR_PowerBar.chargers) do
            if c and c.z == pz and c.barId then
                local n = CSR_PowerBar.nodes[c.barId]
                if n and n.z == pz then
                    local mdx = math.abs(c.x - px) + math.abs(c.y - py)
                    if mdx <= DRAW_RANGE_TILES then
                        -- Walk axis-aligned from bar to charger; mark each tile.
                        local x0, y0 = n.x, n.y
                        local x1, y1 = c.x, c.y
                        local cx, cy = x0, y0
                        local stepX = (x1 > cx) and 1 or ((x1 < cx) and -1 or 0)
                        local stepY = (y1 > cy) and 1 or ((y1 < cy) and -1 or 0)
                        local guard = 0
                        while (cx ~= x1 or cy ~= y1) and guard < 32 do
                            if cx ~= x1 then cx = cx + stepX
                            else             cy = cy + stepY end
                            drawTileMarker(self, cx, cy, n.z, offX, offY, zoom, sz * 0.7,
                                           0.45, 1.0, 0.85, 0.20)
                            guard = guard + 1
                        end
                        -- Charger end (orange = energized, dim red = dead).
                        local energized = nodeIsLiveLocal(n)
                        if energized then
                            drawTileMarker(self, c.x, c.y, c.z, offX, offY, zoom, sz * 1.4,
                                           0.75, 1.0, 0.55, 0.10)
                        else
                            drawTileMarker(self, c.x, c.y, c.z, offX, offY, zoom, sz * 1.4,
                                           0.45, 0.85, 0.20, 0.20)
                        end
                    end
                end
            end
        end
    end
end

-- ----------------------------------------------------------------------------
-- Singleton lifecycle
-- ----------------------------------------------------------------------------
local _panel = nil

local function ensurePanel()
    if _panel and _panel.javaObject then return end
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    _panel = CSR_PB_OverlayPanel:new(0, 0, sw, sh)
    _panel.background = false
    _panel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    _panel:initialise()
    _panel:instantiate()
    if _panel.javaObject and _panel.javaObject.setConsumeMouseEvents then
        _panel.javaObject:setConsumeMouseEvents(false)
    end
end

local function onPostUIDraw()
    if not isEnabled() then return end
    ensurePanel()
    if _panel and _panel.render then _panel:render() end
end

-- ----------------------------------------------------------------------------
-- Charger energization indicator: forces the vanilla hover outline on
-- floor-dropped CarBatteryCharger items and tints it green/red so the
-- player can see at a glance whether a charger is live, without having
-- to open the trunk and try to convert.
--
-- Throttled to ~1 Hz (every 30 OnTick frames). Walks a 12-tile radius
-- around the player. Cheap enough on B42.17 host hardware in MP tests.
-- ----------------------------------------------------------------------------
local _hilightTickCounter = 0
local _trackedChargers = {}   -- weak ref by Java identity to clear stale highlights

local function chargerHighlightTick()
    _hilightTickCounter = _hilightTickCounter + 1
    if (_hilightTickCounter % 30) ~= 0 then return end
    if not isEnabled() then return end
    local p = getSpecificPlayer(0); if not p then return end
    local cell = getCell();         if not cell then return end
    local px, py, pz = p:getX(), p:getY(), p:getZ()
    if not px then return end
    local pzi = math.floor(pz or 0)
    local seenNow = {}
    local R = 12
    for dx = -R, R do
        for dy = -R, R do
            local sq = cell:getGridSquare(math.floor(px) + dx, math.floor(py) + dy, pzi)
            if sq then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do
                    local o = objs:get(i)
                    if o and instanceof(o, "IsoWorldInventoryObject") then
                        local it = o.getItem and o:getItem() or nil
                        if it and it.getFullType and it:getFullType() == "Base.CarBatteryCharger" then
                            local energized = false
                            if CSR_PowerBar and CSR_PowerBar.findEnergizedChargerNear then
                                energized = CSR_PowerBar.findEnergizedChargerNear(sq, 0) ~= nil
                            end
                            if o.setHighlightColor and o.setHighlighted then
                                if energized then
                                    o:setHighlightColor(0.20, 1.00, 0.30, 0.85)
                                else
                                    o:setHighlightColor(1.00, 0.30, 0.30, 0.65)
                                end
                                o:setHighlighted(true, false)
                            end
                            seenNow[o] = true
                            _trackedChargers[o] = true
                        end
                    end
                end
            end
        end
    end
    -- Clear highlight on chargers that left our range so we don't
    -- leave a stuck green/red glow on an item the player carried away.
    for o in pairs(_trackedChargers) do
        if not seenNow[o] then
            pcall(function()
                if o.setHighlightColor then o:setHighlightColor(0, 0, 0, 0) end
                if o.setHighlighted   then o:setHighlighted(false) end
            end)
            _trackedChargers[o] = nil
        end
    end
end

Events.OnPostUIDraw.Add(onPostUIDraw)
Events.OnTick.Add(chargerHighlightTick)

_G.CSR_PowerBarOverlay = CSR_PowerBarOverlay
return CSR_PowerBarOverlay
