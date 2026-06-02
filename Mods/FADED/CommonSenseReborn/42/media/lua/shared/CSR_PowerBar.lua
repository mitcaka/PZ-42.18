-- CSR_PowerBar.lua — shared registry for placed PowerBar power nodes.
-- A PowerBar plugged into a powered tile creates a "power zone" of
-- Manhattan-distance reach equal to the number of ElectricWires invested.
-- Used by:
--   * CSR_RadioPlugIn  (treats radios in the zone as plugged in)
--   * CSR_EVConvert    (vehicles parked next to a charger inside the zone
--                       slowly recharge their EV battery)
-- Persistence: server-authoritative ModData via ModData.getOrCreate.
-- Flat-key serialization (no nested tables, no embedded \n) per B42 rules.
CSR_PowerBar = CSR_PowerBar or {}

CSR_PowerBar.REGISTRY_KEY    = "CSR_PowerBarRegistry"
CSR_PowerBar.MOD_NAME        = "CommonSenseReborn"
CSR_PowerBar.CMD_PLACE       = "PowerBarPlace"
CSR_PowerBar.CMD_UNPLUG      = "PowerBarUnplug"
CSR_PowerBar.CMD_ADDWIRE     = "PowerBarAddWire"
CSR_PowerBar.CMD_SYNC_REQ    = "PowerBarSyncRequest"
CSR_PowerBar.CMD_SYNC_PUSH   = "PowerBarSyncPush"
CSR_PowerBar.CMD_CABLE_CON   = "PowerBarCableConnect"
CSR_PowerBar.CMD_CABLE_DIS   = "PowerBarCableDisconnect"

-- Local in-memory mirror. Keys are integer "id"s. Each value is:
--   { id, x, y, z, wires, owner }
CSR_PowerBar.nodes = CSR_PowerBar.nodes or {}

-- Charger connections: floor-dropped CarBatteryCharger items linked to a bar.
-- Keyed by "x,y,z" string. Each value is { x, y, z, barId, wires }.
CSR_PowerBar.chargers = CSR_PowerBar.chargers or {}

local function sandbox()
    return SandboxVars and SandboxVars.CommonSenseReborn or {}
end

function CSR_PowerBar.isFeatureEnabled()
    return sandbox().EnablePowerBarCable == true
end

function CSR_PowerBar.maxWires()
    local v = tonumber(sandbox().PowerBarMaxCableLength)
    if not v or v < 1 then v = 12 end
    if v > 32 then v = 32 end
    return math.floor(v)
end

function CSR_PowerBar.returnPct()
    local v = tonumber(sandbox().PowerBarCableReturnPct)
    if not v then v = 50 end
    if v < 0 then v = 0 end
    if v > 100 then v = 100 end
    return math.floor(v)
end

function CSR_PowerBar.extendsGenerator()
    return sandbox().PowerBarExtendsGenerator ~= false
end

-- Phantom-generator mode: when ON, each placed Power Bar spawns a hidden
-- IsoGenerator at its tile that vanilla appliances (lamps/fridges/stoves)
-- read as a real power source. The phantom is auto-fueled by upstream power
-- (mains or another generator nearby); when upstream dies, phantom dies.
-- Default OFF for safety (the phantom is a real Java IsoGenerator object that
-- persists in chunk data after mod removal — see KNOWN_LIMITATIONS.md).
function CSR_PowerBar.phantomEnabled()
    return sandbox().PowerBarPhantomGenerator == true
end

-- ----------------------------------------------------------------------------
-- ModData persistence (server-side)
-- ----------------------------------------------------------------------------
local function getRegistry()
    if not ModData or not ModData.getOrCreate then return nil end
    return ModData.getOrCreate(CSR_PowerBar.REGISTRY_KEY)
end

function CSR_PowerBar.serializeAll()
    -- Returns a flat array [{id,x,y,z,wires,owner}, ...] suitable for
    -- transmission via sendServerCommand args (no nested keys).
    local out = {}
    for _, n in pairs(CSR_PowerBar.nodes) do
        if n and n.id then
            table.insert(out, {
                id = n.id, x = n.x, y = n.y, z = n.z,
                wires = n.wires, owner = n.owner or "",
            })
        end
    end
    return out
end

function CSR_PowerBar.serializeChargers()
    local out = {}
    for _, c in pairs(CSR_PowerBar.chargers) do
        if c and c.barId then
            table.insert(out, {
                x = c.x, y = c.y, z = c.z,
                barId = c.barId, wires = c.wires or 0,
            })
        end
    end
    return out
end

function CSR_PowerBar.applyFullSync(list)
    -- Replace local mirror with server-pushed list.
    CSR_PowerBar.nodes = {}
    if not list then return end
    for i = 1, #list do
        local n = list[i]
        if n and n.id then
            CSR_PowerBar.nodes[n.id] = {
                id = n.id, x = tonumber(n.x) or 0, y = tonumber(n.y) or 0,
                z = tonumber(n.z) or 0, wires = tonumber(n.wires) or 0,
                owner = tostring(n.owner or ""),
            }
        end
    end
end

function CSR_PowerBar.chargerKey(x, y, z)
    return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end

function CSR_PowerBar.applyChargerSync(list)
    CSR_PowerBar.chargers = {}
    if not list then return end
    for i = 1, #list do
        local c = list[i]
        if c and c.barId then
            local x = tonumber(c.x) or 0
            local y = tonumber(c.y) or 0
            local z = tonumber(c.z) or 0
            CSR_PowerBar.chargers[CSR_PowerBar.chargerKey(x, y, z)] = {
                x = x, y = y, z = z,
                barId = tonumber(c.barId) or 0,
                wires = tonumber(c.wires) or 0,
            }
        end
    end
end

-- Server-only: load from ModData into in-memory mirror at startup.
function CSR_PowerBar.serverLoad()
    local md = getRegistry()
    if not md then return end
    local count = tonumber(md.count) or 0
    CSR_PowerBar.nodes = {}
    for i = 1, count do
        local active = tonumber(md["n_" .. i .. "_a"]) or 0
        if active == 1 then
            CSR_PowerBar.nodes[i] = {
                id    = i,
                x     = tonumber(md["n_" .. i .. "_x"]) or 0,
                y     = tonumber(md["n_" .. i .. "_y"]) or 0,
                z     = tonumber(md["n_" .. i .. "_z"]) or 0,
                wires = tonumber(md["n_" .. i .. "_w"]) or 0,
                owner = tostring(md["n_" .. i .. "_o"] or ""),
            }
        end
    end
    -- Chargers (cable connections)
    CSR_PowerBar.chargers = {}
    local cgCount = tonumber(md.cgCount) or 0
    for i = 1, cgCount do
        local active = tonumber(md["cg_" .. i .. "_a"]) or 0
        if active == 1 then
            local x = tonumber(md["cg_" .. i .. "_x"]) or 0
            local y = tonumber(md["cg_" .. i .. "_y"]) or 0
            local z = tonumber(md["cg_" .. i .. "_z"]) or 0
            CSR_PowerBar.chargers[CSR_PowerBar.chargerKey(x, y, z)] = {
                x = x, y = y, z = z,
                barId = tonumber(md["cg_" .. i .. "_b"]) or 0,
                wires = tonumber(md["cg_" .. i .. "_w"]) or 0,
            }
        end
    end
end

function CSR_PowerBar.serverSaveOne(node)
    local md = getRegistry()
    if not md or not node or not node.id then return end
    local i = node.id
    md["n_" .. i .. "_x"] = tonumber(node.x) or 0
    md["n_" .. i .. "_y"] = tonumber(node.y) or 0
    md["n_" .. i .. "_z"] = tonumber(node.z) or 0
    md["n_" .. i .. "_w"] = tonumber(node.wires) or 0
    md["n_" .. i .. "_o"] = tostring(node.owner or "")
    md["n_" .. i .. "_a"] = 1
    if (tonumber(md.count) or 0) < i then md.count = i end
end

function CSR_PowerBar.serverDelete(id)
    local md = getRegistry()
    if not md or not id then return end
    md["n_" .. id .. "_a"] = 0
    CSR_PowerBar.nodes[id] = nil
end

function CSR_PowerBar.serverNextId()
    local md = getRegistry()
    if not md then return 1 end
    local n = (tonumber(md.count) or 0) + 1
    md.count = n
    return n
end

-- Persist all current chargers (rewrites the cg_* block).
function CSR_PowerBar.serverSaveChargers()
    local md = getRegistry()
    if not md then return end
    local oldCount = tonumber(md.cgCount) or 0
    for i = 1, oldCount do
        md["cg_" .. i .. "_a"] = 0
    end
    local i = 0
    for _, c in pairs(CSR_PowerBar.chargers) do
        if c and c.barId then
            i = i + 1
            md["cg_" .. i .. "_x"] = c.x
            md["cg_" .. i .. "_y"] = c.y
            md["cg_" .. i .. "_z"] = c.z
            md["cg_" .. i .. "_b"] = c.barId
            md["cg_" .. i .. "_w"] = c.wires or 0
            md["cg_" .. i .. "_a"] = 1
        end
    end
    md.cgCount = math.max(i, oldCount)
end

-- ----------------------------------------------------------------------------
-- Power-state queries (client + server)
-- ----------------------------------------------------------------------------
-- Cached snapshot of active generators in the area around a reference
-- square. Refreshed at most once every 2 game-seconds.
--
-- v1.8.34.1 ROOT-CAUSE FIX: the previous version called
-- cell:getObjectListForLua() and filtered by IsoGenerator, but that
-- helper returns IsoMovingObjects (zombies, animals, players) and never
-- yields IsoGenerators -- which means `_activeGens` was permanently
-- empty and any outdoor charger near a running gennie read as dead. We
-- now walk a 41x41 square box of grid squares around the reference tile
-- and call square:getGenerator() per square, which IS the documented
-- vanilla way to retrieve a generator on a tile (see ISVehicleMenu.lua,
-- ISActivateGenerator.lua). Cost is bounded (~1681 calls / 2s, called
-- only when somebody actually queries charger power).
local _activeGens = {}
local _activeGensStamp = -1
local _activeGensCenterX, _activeGensCenterY, _activeGensCenterZ = nil, nil, nil
local GEN_SCAN_RADIUS = 22  -- vanilla generator radius is ~20; +2 buffer

local function refreshActiveGens(refSq)
    local now = (getGameTime and getGameTime():getWorldAgeHours() or 0) * 3600
    -- Determine scan center.
    local cx, cy, cz
    if refSq then
        cx, cy, cz = refSq:getX(), refSq:getY(), refSq:getZ()
    else
        local p = getSpecificPlayer and getSpecificPlayer(0) or nil
        if not p then return end
        cx, cy, cz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    end
    -- Refresh only when stale OR the scan center moved far enough that
    -- we might miss a gen at the edge of the previous box.
    local moved = (not _activeGensCenterX) or
                  (_activeGensCenterZ ~= cz) or
                  (math.abs((_activeGensCenterX or 0) - cx) > 4) or
                  (math.abs((_activeGensCenterY or 0) - cy) > 4)
    if (now - _activeGensStamp) < 2 and not moved then return end
    _activeGensStamp = now
    _activeGensCenterX, _activeGensCenterY, _activeGensCenterZ = cx, cy, cz
    _activeGens = {}
    local cell = getCell and getCell() or nil
    if not cell then return end
    local r = GEN_SCAN_RADIUS
    for dx = -r, r do
        for dy = -r, r do
            local s = cell:getGridSquare(cx + dx, cy + dy, cz)
            if s then
                local g = s.getGenerator and s:getGenerator() or nil
                if g then
                    local active = g.isActivated and g:isActivated() or false
                    if active then
                        _activeGens[#_activeGens + 1] = {
                            x = g:getX(), y = g:getY(), z = g:getZ()
                        }
                    end
                end
            end
        end
    end
end

local function squareHasNativePower(sq)
    if not sq then return false end
    -- Vanilla mains/hydro grid (works indoors AND outdoors when the grid
    -- itself is energized).
    if sq.haveElectricity and sq:haveElectricity() then return true end
    -- Active generator within ~20 tiles -- explicit per-tile scan,
    -- because vanilla's `haveElectricity()` is roof-only when the
    -- world grid is offline AND the AllowExteriorGenerator sandbox
    -- option is off. The user explicitly wants chargers outdoors next
    -- to a running gennie to count as energized.
    refreshActiveGens(sq)
    if #_activeGens > 0 then
        local sx, sy, sz = sq:getX(), sq:getY(), sq:getZ()
        for i = 1, #_activeGens do
            local g = _activeGens[i]
            if g.z == sz and math.abs(g.x - sx) <= 20 and math.abs(g.y - sy) <= 20 then
                return true
            end
        end
    end
    return false
end
-- Public alias so other CSR modules (CSR_PowerLine, EV) share the
-- single source-of-truth for "is this tile energized by mains or a
-- nearby active generator".
CSR_PowerBar.squareHasNativePower = squareHasNativePower

local function nodeIsLive(node)
    if not node then return false end
    local cell = getCell()
    if not cell then return false end
    local sq = cell:getGridSquare(node.x, node.y, node.z)
    if not sq then return false end
    -- A PowerBar node only powers downstream while its anchor square has power
    -- (vanilla mains/hydro, a running generator in range, or a finished CSR
    -- Power Line). When upstream drops, the cable goes cold too.
    if squareHasNativePower(sq) then return true end
    return CSR_PowerLine and CSR_PowerLine.isPaintedPowered and CSR_PowerLine.isPaintedPowered(sq) == true
end

function CSR_PowerBar.isSquareInPoweredZone(sq)
    if not sq then return false end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    for _, n in pairs(CSR_PowerBar.nodes) do
        if n and n.z == z then
            local d = math.abs(n.x - x) + math.abs(n.y - y)
            if d <= (n.wires or 0) and nodeIsLive(n) then
                return true, n
            end
        end
    end
    return false, nil
end

function CSR_PowerBar.findNodeAtSquare(x, y, z)
    for _, n in pairs(CSR_PowerBar.nodes) do
        if n and n.x == x and n.y == y and n.z == z then return n end
    end
    return nil
end

-- True if the square has any kind of power: vanilla grid OR a CSR cable zone.
function CSR_PowerBar.isSquarePoweredAny(sq)
    if not sq then return false end
    if squareHasNativePower(sq) then return true end
    if CSR_PowerLine and CSR_PowerLine.isPaintedPowered and CSR_PowerLine.isPaintedPowered(sq) then return true end
    if not CSR_PowerBar.isFeatureEnabled() then return false end
    local hit = CSR_PowerBar.isSquareInPoweredZone(sq)
    return hit
end

-- Helper used by placement validation: anchor must be on a powered tile.
function CSR_PowerBar.canAnchorOnSquare(sq)
    if not sq then return false end
    return squareHasNativePower(sq)
        or (CSR_PowerLine and CSR_PowerLine.isPaintedPowered and CSR_PowerLine.isPaintedPowered(sq) == true)
end

-- New (relaxed) placement rule: a Power Bar may be placed on any tile that
-- is (a) adjacent to a building square, or (b) inside an active generator's
-- range, or (c) on a tile that already reads as powered (grid/hydro).
-- The bar only goes "live" when its anchor square reads as powered, but you
-- may pre-place it before the generator is running.
function CSR_PowerBar.canPlaceForUser(sq)
    if not sq then return false end
    -- (c) already powered → always OK
    if squareHasNativePower(sq) then return true end
    if CSR_PowerLine and CSR_PowerLine.isPaintedPowered and CSR_PowerLine.isPaintedPowered(sq) then return true end
    local cell = getCell()
    if not cell then return false end
    local sx, sy, sz = sq:getX(), sq:getY(), sq:getZ()
    -- (a) adjacent to a building (3x3 around)
    for dx = -1, 1 do
        for dy = -1, 1 do
            local s = cell:getGridSquare(sx + dx, sy + dy, sz)
            if s then
                local building = s.getBuilding and s:getBuilding() or nil
                if building then return true end
            end
        end
    end
    -- (b) inside a generator's range — try vanilla helper if present
    local genObj = getNearestGenerator and getNearestGenerator(sq, 16) or nil
    if genObj then
        local activated = genObj.isActivated and genObj:isActivated() or false
        if activated then return true end
    end
    return false
end

-- Find every PowerBar node whose Manhattan reach covers `sq`.
function CSR_PowerBar.findBarsCovering(sq)
    local out = {}
    if not sq then return out end
    local sx, sy, sz = sq:getX(), sq:getY(), sq:getZ()
    for _, n in pairs(CSR_PowerBar.nodes) do
        if n and n.z == sz then
            local d = math.abs(n.x - sx) + math.abs(n.y - sy)
            if d <= (n.wires or 0) then
                table.insert(out, { node = n, distance = d })
            end
        end
    end
    return out
end

-- Lookup the connection record for a charger floor item at the given square.
function CSR_PowerBar.getChargerConnection(x, y, z)
    return CSR_PowerBar.chargers[CSR_PowerBar.chargerKey(x, y, z)]
end

-- A charger is energized whenever its square is powered by ANY source:
--   * vanilla grid / hydro,
--   * an active vanilla generator within range,
--   * a live CSR PowerBar zone covering it.
-- v1.8.34: extension-cord registration is no longer required — the user
-- explicitly asked for "Battery Charger should become energized no matter
-- why as long as in powered radius of generator or if vanilla power is
-- working." Legacy connection records are still respected when present.
function CSR_PowerBar.isChargerEnergized(sq)
    if not sq then return false end
    -- Native power (grid / hydro / nearby active generator).
    if squareHasNativePower(sq) then return true end
    -- New per-tile Power Line zone (v1.8.34 cord-paint replacement).
    if CSR_PowerLine and CSR_PowerLine.isPaintedPowered and CSR_PowerLine.isPaintedPowered(sq) then
        return true
    end
    -- CSR PowerBar zone coverage.
    if CSR_PowerBar.isFeatureEnabled() and CSR_PowerBar.isSquareInPoweredZone(sq) then
        return true
    end
    -- Legacy connection record (extension cord cabling).
    local c = CSR_PowerBar.getChargerConnection(sq:getX(), sq:getY(), sq:getZ())
    if c then
        local bar = CSR_PowerBar.nodes[c.barId]
        if bar and nodeIsLive(bar) then return true end
    end
    return false
end

-- Find any energized charger within Manhattan radius `r` of square `sq`.
-- Used by the EV system to decide whether a parked vehicle can charge or convert.
-- v1.8.34: scans real CarBatteryCharger floor items in the radius and
-- accepts any whose square reads as powered, instead of only registered
-- connections. This drops the extension-cord requirement entirely.
function CSR_PowerBar.findEnergizedChargerNear(sq, r)
    if not sq then return nil end
    local sx, sy, sz = sq:getX(), sq:getY(), sq:getZ()
    r = tonumber(r) or 2
    local cell = getCell()
    local best
    if cell then
        for dx = -r, r do
            for dy = -r, r do
                local ax, ay = math.abs(dx), math.abs(dy)
                if ax + ay <= r then
                    local s = cell:getGridSquare(sx + dx, sy + dy, sz)
                    if s then
                        local hasCharger = false
                        local objs = s.getObjects and s:getObjects() or nil
                        if objs then
                            for i = 0, objs:size() - 1 do
                                local o = objs:get(i)
                                if o then
                                    -- Floor-dropped charger (IsoWorldInventoryObject).
                                    if instanceof(o, "IsoWorldInventoryObject") then
                                        local item = o.getItem and o:getItem() or nil
                                        if item and item.getFullType and item:getFullType() == "Base.CarBatteryCharger" then
                                            hasCharger = true; break
                                        end
                                    end
                                    -- Moveable-placed charger (IsoObject with the
                                    -- vanilla CustomName / sprite property). Vanilla
                                    -- pickup-and-place sets the CustomName to
                                    -- "Battery Charger" and stamps a tile property
                                    -- "Name" = "Battery Charger" on the sprite.
                                    if not hasCharger and o.getName then
                                        local nm = o:getName()
                                        if nm and (nm == "Battery Charger" or nm == "Car Battery Charger") then
                                            hasCharger = true; break
                                        end
                                    end
                                    if not hasCharger and o.getSprite then
                                        local sp = o:getSprite()
                                        local props = sp and sp.getProperties and sp:getProperties() or nil
                                        if props and props.Val then
                                            local n = props:Val("CustomName") or props:Val("Name")
                                            if n and (n == "Battery Charger" or n == "Car Battery Charger") then
                                                hasCharger = true; break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        if hasCharger and CSR_PowerBar.isChargerEnergized(s) then
                            local d = ax + ay
                            if not best or d < best.distance then
                                best = { square = s, distance = d }
                            end
                        end
                    end
                end
            end
        end
    end
    if best then return best end
    -- Fallback: legacy registered connections.
    for _, c in pairs(CSR_PowerBar.chargers) do
        if c and c.z == sz then
            local d = math.abs(c.x - sx) + math.abs(c.y - sy)
            if d <= r then
                local bar = CSR_PowerBar.nodes[c.barId]
                if bar and nodeIsLive(bar) then
                    if not best or d < best.distance then
                        best = { connection = c, bar = bar, distance = d }
                    end
                end
            end
        end
    end
    return best
end

-- ----------------------------------------------------------------------------
-- Phantom generator (server-only). One real IsoGenerator object per node,
-- sprite-swapped to the small PowerBar item so it doesn't read as a giant
-- yellow generator. Activated/silenced/auto-fueled while upstream is live.
-- The OVERLAY radius is the placebo (overlay reads node.wires); the real
-- engine radius is always vanilla (~20 tiles).
-- ----------------------------------------------------------------------------

-- Find any IsoGenerator currently sitting on the given square.
local function findGeneratorOnSquare(sq)
    if not sq then return nil end
    local g = sq.getGenerator and sq:getGenerator() or nil
    if g then return g end
    -- Fallback: scan special objects.
    local objs = sq.getSpecialObjects and sq:getSpecialObjects() or nil
    if objs then
        for i = 0, objs:size() - 1 do
            local o = objs:get(i)
            if o and instanceof(o, "IsoGenerator") then g = o; break end
        end
    end
    return g
end

-- True if the square has upstream power that is NOT coming from our phantom
-- here. We disambiguate by briefly toggling the local phantom off.
function CSR_PowerBar.squareHasUpstreamPower(sq)
    if not sq then return false end
    local phantom = findGeneratorOnSquare(sq)
    local restoreActive = nil
    if phantom then
        local md = phantom.getModData and phantom:getModData() or nil
        if md and md.csrPhantom then
            local act = phantom.isActivated and phantom:isActivated() or false
            restoreActive = act
            phantom:setActivated(false)
        end
    end
    local has = sq.haveElectricity and sq:haveElectricity() or false
    if not has and CSR_PowerLine and CSR_PowerLine.isPaintedPowered then
        has = CSR_PowerLine.isPaintedPowered(sq) == true
    end
    -- If we toggled it off and nothing else lit the tile, the upstream is dead.
    if restoreActive ~= nil and not has then
        -- Restore for safety; tick will set the correct state next.
        phantom:setActivated(restoreActive)
    end
    return has
end

-- Spawn a hidden IsoGenerator at the bar's tile if one isn't already there.
-- SP and MP constructors differ; mirrors the working pattern used by the
-- IndustrialWorks workshop mod (verified against B42.17).
function CSR_PowerBar.serverSpawnPhantom(node)
    if isClient() then return end
    if not node then return end
    if not CSR_PowerBar.phantomEnabled() then return end
    local cell = getCell(); if not cell then return end
    local sq = cell:getGridSquare(node.x, node.y, node.z); if not sq then return end

    -- Already a phantom here? Nothing to do.
    local existing = findGeneratorOnSquare(sq)
    if existing then
        local md = existing.getModData and existing:getModData() or nil
        if md and md.csrPhantom then
            node._phantom = existing
            return
        end
        -- A real (non-phantom) generator is already here; don't stack.
        return
    end

    local item = instanceItem("Base.Generator")
    if not item then return end

    local gen = nil
    -- Keep this contained: B42 exposes different IsoGenerator constructors
    -- between SP and MP, and phantom power is optional cleanup support.
    local okSpawn = pcall(function()
        if not isMultiplayer() then
            gen = IsoGenerator.new(item, cell, sq)
        else
            gen = IsoGenerator.new(cell)
            gen:setSquare(sq)
            gen:setInfoFromItem(item)
            sq:AddSpecialObject(gen)
        end
    end)
    if not okSpawn or not gen then return end

    -- Sprite swap: use the PowerBar item's small mesh by clearing the sprite.
    -- We can't fully hide the IsoGenerator (it has a Java tile entity), but
    -- a nil sprite render-pass is invisible enough that the only thing the
    -- player sees on the tile is the dropped Base.PowerBar floor item.
    if gen.setSprite then gen:setSprite(nil) end

    gen:setCondition(100)
    gen:setFuel(100)
    gen:setConnected(true)
    gen:setActivated(false)  -- tick will turn on if upstream is live
    local md = gen:getModData()
    if md then
        md.csrPhantom = true
        md.csrBarId = node.id
    end
    gen:transmitCompleteItemToClients()

    -- Keep building toxic-fume flag clean — the phantom doesn't actually burn fuel.
    local b = sq.getBuilding and sq:getBuilding() or nil
    if b then b:setToxic(false) end

    node._phantom = gen
end

-- Despawn the phantom for a node, if one exists. Safe to call repeatedly.
function CSR_PowerBar.serverDespawnPhantom(node)
    if isClient() then return end
    if not node then return end
    local cell = getCell(); if not cell then return end
    local sq = cell:getGridSquare(node.x, node.y, node.z); if not sq then return end

    local gen = node._phantom or findGeneratorOnSquare(sq)
    if not gen then return end
    local md = gen.getModData and gen:getModData() or nil
    if not (md and md.csrPhantom) then
        -- Refuse to remove a real player-placed generator.
        node._phantom = nil
        return
    end
    gen:setActivated(false)
    if sq.transmitRemoveItemFromSquare then sq:transmitRemoveItemFromSquare(gen) end
    if sq.RemoveTileObject then sq:RemoveTileObject(gen) end
    node._phantom = nil
end

-- Per-tick state update: ensure phantoms exist for every node when the mode
-- is enabled, top them up while upstream is live, and silence their emitter
-- so they don't attract zombies. Called from server EveryTenMinutes.
function CSR_PowerBar.serverTickPhantoms()
    if isClient() then return end
    local cell = getCell(); if not cell then return end
    local enabled = CSR_PowerBar.phantomEnabled()

    for _, n in pairs(CSR_PowerBar.nodes) do
        if n then
            local sq = cell:getGridSquare(n.x, n.y, n.z)
            if sq then
                if not enabled then
                    -- Mode toggled off: clean up any phantom we previously spawned.
                    CSR_PowerBar.serverDespawnPhantom(n)
                else
                    -- Ensure we have a phantom here.
                    if not n._phantom then
                        CSR_PowerBar.serverSpawnPhantom(n)
                    end
                    local gen = n._phantom or findGeneratorOnSquare(sq)
                    if gen then
                        local md = gen.getModData and gen:getModData() or nil
                        if md and md.csrPhantom then
                            local upstream = CSR_PowerBar.squareHasUpstreamPower(sq)
                            gen:setCondition(100)
                            gen:setFuel(100)
                            gen:setConnected(true)
                            gen:setActivated(upstream)
                            -- Silence: kill any audio emitter every tick.
                            local emitter = gen.getEmitter and gen:getEmitter() or nil
                            if emitter then emitter:stopAll() end
                            local b = sq.getBuilding and sq:getBuilding() or nil
                            if b then b:setToxic(false) end
                            n._phantom = gen
                        end
                    end
                end
            end
        end
    end
end
