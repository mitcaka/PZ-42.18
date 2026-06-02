-- CSR_FireTrail.lua (client surface)
-- Pour gasoline from an equipped gas can while walking to lay a
-- chain-ignitable trail; ignite any tile of the trail to cascade fire
-- through every connected painted square.
--
-- Anti-grief design notes:
--   * Bounded BFS spread (sandbox: FireTrailMaxLength, default 25).
--   * Sandbox gate FireTrailRequiresAdmin lets PvP/RP servers lock the
--     ignition step to admins.
--   * Each painted tile costs FireTrailFuelPerTile of gasoline.
--   * Painting only proceeds while the player walks (not sprints) and
--     has the gas can equipped in the primary slot.
--   * Trail tiles do not persist as world tile objects; they're tracked
--     in a per-cell modData map keyed by "x,y,z" and survive chunk
--     reload because cell modData is part of the world save.
--
-- MP server validation lives in CSR_ServerCommands.handleFireTrail*.
-- This client file handles painting cursor + ignite request.
require "CSR_FeatureFlags"
require "CSR_Utils"

CSR_FireTrail = CSR_FireTrail or {}

local PAINT_KEY        = "csrFireTrail"   -- bool flat key on grid square modData
local PAINT_TICK_GUARD = 8                 -- min ticks between paint attempts per player
local IGNITE_INTENSITY = 100
local IGNITE_LIFE      = 350
local noteOverlaySquare = nil

local function sb()
    return SandboxVars and SandboxVars.CommonSenseReborn or {}
end

local function isEnabled()
    if CSR_FeatureFlags and CSR_FeatureFlags.isFireTrailEnabled then
        return CSR_FeatureFlags.isFireTrailEnabled()
    end
    return sb().EnableFireTrail ~= false
end

local function fuelPerTile()
    return tonumber(sb().FireTrailFuelPerTile) or 0.05
end

local function maxTrailLength()
    return tonumber(sb().FireTrailMaxLength) or 25
end

local function requiresAdminToIgnite()
    return sb().FireTrailRequiresAdmin == true
end

local function isAdmin(player)
    if not player then return false end
    local lvl = player.getAccessLevel and player:getAccessLevel() or nil
    return lvl == "admin" or lvl == "Admin"
end

-- ---------- Square paint state ---------------------------------------------

local function squareKey(sq)
    if not sq then return nil end
    return tostring(sq:getX()) .. "," .. tostring(sq:getY()) .. "," .. tostring(sq:getZ())
end

local function isPainted(sq)
    if not sq or not sq.getModData then return false end
    local md = sq:getModData()
    return md and md[PAINT_KEY] == true
end

local function setPainted(sq, painted)
    if not sq or not sq.getModData then return end
    local md = sq:getModData()
    if painted then
        md[PAINT_KEY] = true
    else
        md[PAINT_KEY] = nil
    end
    if noteOverlaySquare then noteOverlaySquare(sq, painted == true) end
    -- Squares don't transmitModData individually in B42; the cell write
    -- is async-saved. We refresh visuals with the next paint poll.
    if sq.RecalcAllWithNeighbours then
        pcall(function() sq:RecalcAllWithNeighbours(true) end)
    end
end

-- ---------- Gas can helpers -------------------------------------------------

local function isGasItem(it)
    if not it then return false, nil end
    -- Type-name shortcut for vanilla petrol cans (covers PetrolCan,
    -- GasCan, EmptyPetrolCan flavours).
    local ft = it.getFullType and it:getFullType() or ""
    local nameMatch = ft:find("Petrol") or ft:find("GasCan") or ft:find("Gasoline")

    local fc = nil
    if it.hasComponent and ComponentType and ComponentType.FluidContainer
            and it:hasComponent(ComponentType.FluidContainer) then
        fc = it.getFluidContainer and it:getFluidContainer() or nil
    elseif it.getFluidContainer then
        pcall(function() fc = it:getFluidContainer() end)
    end
    if not fc then return false, nil end

    -- Try strong predicate first (contains-Petrol).
    local containsOk, hasPetrol = pcall(function()
        return Fluid and Fluid.Petrol and fc.contains and fc:contains(Fluid.Petrol)
    end)
    if containsOk and hasPetrol == true then return true, fc end

    -- Fall back to primary-fluid string match.
    local fluid = nil
    pcall(function() fluid = fc:getPrimaryFluid() end)
    if fluid and tostring(fluid):find("Petrol") then return true, fc end

    -- Last fallback: name says petrol AND container is non-empty.
    if nameMatch then
        local amt = 0
        pcall(function() amt = fc:getAmount() or 0 end)
        if amt > 0 then return true, fc end
    end

    return false, nil
end

-- Primary-hand-only check: the player must be holding a petrol
-- container in their main hand. (Per-user request; we deliberately
-- do NOT search the inventory.)
local function getEquippedGasCan(player)
    if not player then return nil end
    local primary = player:getPrimaryHandItem()
    local ok, fc = isGasItem(primary)
    if ok then return primary, fc end
    return nil
end

local function drainFluid(fc, amount)
    if not fc then return false end
    local cur = 0
    pcall(function() cur = fc:getAmount() or 0 end)
    if cur < amount then return false end
    -- Vanilla pattern (see ISAddFuel, ISCleanGraffiti, ISBurnCorpseAction):
    -- adjustAmount(getAmount() - delta). Single-arg removeFluid() empties
    -- the entire container, which is NOT what we want here.
    local ok = pcall(function() fc:adjustAmount(cur - amount) end)
    if not ok then
        pcall(function() fc:removeFluid(amount, false) end)
    end
    return true
end

-- ---------- Paint loop ------------------------------------------------------

local _lastPaintTick = {}

local function paintTick()
    if not isEnabled() then return end
    local player = getSpecificPlayer(0)
    if not player or player:isDead() then return end
    if not CSR_FireTrail._painting then return end

    -- Real-time tick guard (NOT game-age) — game-age stalls when the
    -- world clock is paused or running slow, which made the previous
    -- guard look like the paint loop was dead.
    local nowMs = (getTimestampMs and getTimestampMs())
        or ((os and os.time and (os.time() * 1000)) or 0)
    local last = _lastPaintTick[0] or 0
    if (nowMs - last) < 250 then return end   -- ~4 paints/sec cap
    _lastPaintTick[0] = nowMs

    if player:isSprinting() then return end

    local can, fc = getEquippedGasCan(player)
    if not can or not fc then
        CSR_FireTrail.stopPainting(player)
        return
    end

    -- Always paint the current tile (whether moving or not) so the
    -- player gets immediate feedback. Walking onto a fresh tile keeps
    -- painting; standing still on a painted tile is a no-op.
    local sq = player:getCurrentSquare()
    if not sq then return end
    if isPainted(sq) then return end
    if not drainFluid(fc, fuelPerTile()) then
        CSR_FireTrail.stopPainting(player)
        if player.Say then
            pcall(function() player:Say(getText and getText("IGUI_CSR_FireTrail_Empty") or "Can's empty.") end)
        end
        return
    end

    -- Optimistically set client-side modData so the overlay + ignite
    -- option appear immediately. Server is authoritative; if it rejects
    -- the paint the next tick will overwrite us harmlessly.
    setPainted(sq, true)
    if isClient() then
        sendClientCommand(player, "CommonSenseReborn", "FireTrailPaint", {
            x = sq:getX(), y = sq:getY(), z = sq:getZ()
        })
    end
end

function CSR_FireTrail.startPainting(player)
    if not isEnabled() then return end
    local can, fc = getEquippedGasCan(player)
    if not can or not fc then
        if player and player.Say then
            pcall(function() player:Say(getText and getText("IGUI_CSR_FireTrail_NeedGas") or "I need a gas can in hand.") end)
        end
        return
    end
    CSR_FireTrail._painting = true
    if player and player.Say then
        pcall(function() player:Say(getText and getText("IGUI_CSR_FireTrail_Started") or "Pouring fuel...") end)
    end
    -- Paint the current square immediately so the user gets visible
    -- feedback the instant they toggle Pour, even before they take a
    -- step. Drain & sync the same as a regular tick.
    local sq = player and player:getCurrentSquare() or nil
    if sq and not isPainted(sq) and drainFluid(fc, fuelPerTile()) then
        setPainted(sq, true)
        if isClient() then
            sendClientCommand(player, "CommonSenseReborn", "FireTrailPaint", {
                x = sq:getX(), y = sq:getY(), z = sq:getZ()
            })
        end
    end
end

function CSR_FireTrail.stopPainting(player)
    CSR_FireTrail._painting = false
    if player and player.Say then
        pcall(function() player:Say(getText and getText("IGUI_CSR_FireTrail_Stopped") or "Capping the can.") end)
    end
end

function CSR_FireTrail.togglePainting(player)
    if CSR_FireTrail._painting then
        CSR_FireTrail.stopPainting(player)
    else
        CSR_FireTrail.startPainting(player)
    end
end

-- ---------- Ignite request (BFS spread happens server-side) ---------------

function CSR_FireTrail.requestIgnite(player, sq)
    if not isEnabled() then return end
    if not player or not sq then return end
    if requiresAdminToIgnite() and not isAdmin(player) then
        if player.Say then
            pcall(function() player:Say(getText and getText("IGUI_CSR_FireTrail_AdminOnly") or "Server admin only.") end)
        end
        return
    end
    if not isPainted(sq) then return end
    if isClient() then
        sendClientCommand(player, "CommonSenseReborn", "FireTrailIgnite", {
            x = sq:getX(), y = sq:getY(), z = sq:getZ()
        })
    else
        CSR_FireTrail._localIgnite(sq, player)
    end
end

-- Local SP ignite (mirror of server BFS, used when isClient() is false).
function CSR_FireTrail._localIgnite(startSq, player)
    if not startSq then return end
    local cell = getCell()
    if not cell then return end
    local seen = {}
    local queue = { startSq }
    local head = 1
    local lit = 0
    local maxN = maxTrailLength()
    while queue[head] and lit < maxN do
        local sq = queue[head]; head = head + 1
        local key = squareKey(sq)
        if not seen[key] and isPainted(sq) then
            seen[key] = true
            pcall(function()
                IsoFireManager.StartFire(cell, sq, true, IGNITE_INTENSITY, IGNITE_LIFE)
            end)
            setPainted(sq, false)
            lit = lit + 1
            for dx = -1, 1 do
                for dy = -1, 1 do
                    if not (dx == 0 and dy == 0) then
                        local nb = cell:getGridSquare(sq:getX() + dx, sq:getY() + dy, sq:getZ())
                        if nb and not seen[squareKey(nb)] then
                            queue[#queue + 1] = nb
                        end
                    end
                end
            end
        end
    end
end

-- ---------- Context menu hook ---------------------------------------------

-- Timed action wrapper so igniting a fuel trail plays the lighter-flick
-- pose (LightFire_KnotchedPlank_Stood — vanilla doesn't ship a true
-- one-handed lighter anim, this is the closest "kindle a flame"
-- fixed-foot anim). Class lives at file scope so MP server can resolve
-- it via LuaManager.getFunctionObject.
CSR_IgniteFuelTrailAction = ISBaseTimedAction:derive("CSR_IgniteFuelTrailAction")

function CSR_IgniteFuelTrailAction:isValid()
    return self.character ~= nil and self.targetSq ~= nil
end

function CSR_IgniteFuelTrailAction:waitToStart()
    self.character:faceLocation(self.targetSq:getX() + 0.5, self.targetSq:getY() + 0.5)
    return self.character:shouldBeTurning()
end

function CSR_IgniteFuelTrailAction:start()
    self:setActionAnim("LightFire_KnotchedPlank_Stood")
    self:setAnimVariable("WoodWorkType", "WoodWork")
end

function CSR_IgniteFuelTrailAction:perform()
    if CSR_FireTrail and CSR_FireTrail.requestIgnite then
        CSR_FireTrail.requestIgnite(self.character, self.targetSq)
    end
    ISBaseTimedAction.perform(self)
end

function CSR_IgniteFuelTrailAction:new(character, sq)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.targetSq  = sq
    o.maxTime   = 80
    o.stopOnWalk    = true
    o.stopOnRun     = true
    o.stopOnAim     = true
    return o
end

-- B42.17: InventoryItem.hasTag(String) is not bound on every subclass
-- (Clothing, ComboItem, Padlock, etc throw
-- "No implementation found for function: hasTag"). Even with pcall the
-- engine logs the throw and floods the console, so we never call it --
-- ScriptItem.getTags():contains(tag) is bound on every subclass and
-- returns the same answer.
local function safeHasTag(it, tag)
    if not it or not tag or not it.getScriptItem then return false end
    local script = it:getScriptItem()
    if not script or not script.getTags then return false end
    local tags = script:getTags()
    if not tags or not tags.contains then return false end
    local ok, has = pcall(function() return tags:contains(tag) end)
    return ok and has == true
end

local function findLighter(player)
    if not player then return nil end
    local inv = player:getInventory()
    if not inv or not inv.getAllEvalRecurse then return nil end
    local list = inv:getAllEvalRecurse(function(it)
        if not it or not it.getFullType then return false end
        local ft = it:getFullType()
        if ft == "Base.Lighter" or ft == "Base.Matches" or ft == "Base.LightSource_Lighter" then
            return true
        end
        if safeHasTag(it, "StartFire") or safeHasTag(it, "Lighter") then return true end
        return false
    end)
    if list and list.size and list:size() > 0 then return list:get(0) end
    return nil
end

local function queueIgnite(player, sq)
    if not player or not sq then return end
    if findLighter(player) then
        ISTimedActionQueue.add(CSR_IgniteFuelTrailAction:new(player, sq))
    else
        -- No lighter: fall back to instant ignite (anim impossible
        -- without a kindle source). Player still gets the result.
        CSR_FireTrail.requestIgnite(player, sq)
    end
end

local function onFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    if test then return end
    if not isEnabled() then return end
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    -- Find a painted square under (or near) the cursor. We accept a
    -- 2-tile fuzz radius around any world object the player clicked
    -- on, since the new UI overlay paints flat tile shapes that don't
    -- visually overlap perfectly with the world tile center; players
    -- complained that re-igniting a freshly-poured trail "doesn't
    -- work" because their click landed one tile off.
    local paintedSq = nil
    local cell = getCell()
    local function pickAround(centerSq)
        if not centerSq then return nil end
        if isPainted(centerSq) then return centerSq end
        if not cell then return nil end
        local cx, cy, cz = centerSq:getX(), centerSq:getY(), centerSq:getZ()
        for dx = -2, 2 do
            for dy = -2, 2 do
                local nb = cell:getGridSquare(cx + dx, cy + dy, cz)
                if nb and isPainted(nb) then return nb end
            end
        end
        return nil
    end
    for i = 1, #worldobjects do
        local o = worldobjects[i]
        local sq = o and o.getSquare and o:getSquare() or nil
        local hit = pickAround(sq)
        if hit then paintedSq = hit; break end
    end

    if paintedSq then
        local opt = context:addOption(
            getText and getText("IGUI_CSR_FireTrail_Ignite") or "Ignite Fuel Trail",
            nil,
            function() queueIgnite(player, paintedSq) end
        )
        if opt and opt.iconTexture then opt.iconTexture = getTexture("media/ui/Fire.png") end

        -- Erase / cancel: lets the player abort an unignited trail. We unpaint
        -- the cluster of contiguous painted squares around the click so a
        -- single "Erase" call clears a small puddle without the player having
        -- to right-click each tile. Hard cap at 256 tiles for safety.
        local function eraseTrail(startSq)
            if not startSq or not isPainted(startSq) then return end
            local seen = {}
            local stack = { startSq }
            local cleared = 0
            while #stack > 0 and cleared < 256 do
                local sq = table.remove(stack)
                local k = squareKey(sq)
                if k and not seen[k] and isPainted(sq) then
                    seen[k] = true
                    setPainted(sq, false)
                    cleared = cleared + 1
                    if cell then
                        local cx, cy, cz = sq:getX(), sq:getY(), sq:getZ()
                        for dx = -1, 1 do
                            for dy = -1, 1 do
                                if not (dx == 0 and dy == 0) then
                                    local nb = cell:getGridSquare(cx + dx, cy + dy, cz)
                                    if nb and isPainted(nb) then stack[#stack + 1] = nb end
                                end
                            end
                        end
                    end
                end
            end
        end
        context:addOption(
            getText and getText("IGUI_CSR_FireTrail_Erase") or "Erase Fuel Trail",
            nil,
            function() eraseTrail(paintedSq) end
        )
    end

    -- Always offer toggle pour if a gas can is equipped.
    if getEquippedGasCan(player) then
        local label = CSR_FireTrail._painting
            and (getText and getText("IGUI_CSR_FireTrail_StopPour") or "Stop Pouring Fuel")
            or  (getText and getText("IGUI_CSR_FireTrail_StartPour") or "Pour Fuel Trail")
        context:addOption(label, nil, function() CSR_FireTrail.togglePainting(player) end)
    end
end

-- ---------- Purple ground overlay ----------------------------------------
-- Painted squares get a translucent purple tint so the trail is
-- visible (matches the source-mod convention). We render via the
-- standard IsoGridSquare render hook by attaching a per-square texture
-- through square:setOverlaySprite when the property is set; in B42
-- the cleanest path is the OnPostRender event scanning visible cells.
--
-- Rendering strategy: UI-space screen overlay (ISPanel:render +
-- IsoUtils.XToScreen projection). Same reasoning as CSR_PowerLineClient
-- — drawing in the world layer means the player's body / vehicles /
-- walls occlude the marker when the camera is close. UI layer floats
-- on top.
local PURPLE_DRAW_RADIUS = 30
local OVERLAY_SCAN_MS = 1000
local OVERLAY_SCAN_MOVE_TILES = 6
local OVERLAY_IDLE_PROBE_MS = 3000

local _ftMarkers = {} -- ["x,y,z"] = { x, y, z }
local _ftLastScanMs = 0
local _ftLastIdleProbeMs = 0
local _ftScanX, _ftScanY, _ftScanZ = nil, nil, nil

local function overlayNowMs()
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    if os and os.time then return os.time() * 1000 end
    return 0
end

local function overlayKey(x, y, z)
    return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end

local function putFTMarker(x, y, z, painted)
    if x == nil or y == nil or z == nil then return end
    local k = overlayKey(x, y, z)
    if painted ~= true then
        _ftMarkers[k] = nil
        return
    end
    local mx = tonumber(x) or 0
    local my = tonumber(y) or 0
    local mz = tonumber(z) or 0
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if player then
        local pz = math.floor(tonumber(player:getZ()) or 0)
        local limit = PURPLE_DRAW_RADIUS + OVERLAY_SCAN_MOVE_TILES
        if mz ~= pz
            or math.abs(mx - (tonumber(player:getX()) or 0)) > limit
            or math.abs(my - (tonumber(player:getY()) or 0)) > limit then
            return
        end
    end
    _ftMarkers[k] = {
        x = mx,
        y = my,
        z = mz,
    }
end

noteOverlaySquare = function(sq, painted)
    if not sq then return end
    putFTMarker(sq:getX(), sq:getY(), sq:getZ(), painted == true)
end

local function hasFTMarkers()
    for _ in pairs(_ftMarkers) do return true end
    return false
end

local function refreshFTOverlayCache(cell, px, py, zi, force)
    local now = overlayNowMs()
    local moved = (_ftScanX == nil)
        or (_ftScanZ ~= zi)
        or math.abs((_ftScanX or 0) - px) > OVERLAY_SCAN_MOVE_TILES
        or math.abs((_ftScanY or 0) - py) > OVERLAY_SCAN_MOVE_TILES
    if not force and not moved and (now - _ftLastScanMs) < OVERLAY_SCAN_MS then return end

    _ftLastScanMs = now
    _ftScanX, _ftScanY, _ftScanZ = px, py, zi

    local seen = {}
    local r = PURPLE_DRAW_RADIUS
    local sx = math.floor(px - r)
    local sy = math.floor(py - r)
    local ex = math.floor(px + r)
    local ey = math.floor(py + r)

    for x = sx, ex do
        for y = sy, ey do
            local sq = cell:getGridSquare(x, y, zi)
            if sq and isPainted(sq) then
                local k = overlayKey(x, y, zi)
                seen[k] = true
                putFTMarker(x, y, zi, true)
            end
        end
    end

    -- Prune stale markers in the current scan window, and drop far-away
    -- markers so MP broadcasts elsewhere do not grow this table.
    for k, marker in pairs(_ftMarkers) do
        local far = marker.z ~= zi
            or math.abs(marker.x - px) > (r + OVERLAY_SCAN_MOVE_TILES)
            or math.abs(marker.y - py) > (r + OVERLAY_SCAN_MOVE_TILES)
        local staleLocal = marker.z == zi
            and math.abs(marker.x - px) <= r
            and math.abs(marker.y - py) <= r
            and not seen[k]
        if far or staleLocal then
            _ftMarkers[k] = nil
        end
    end
end

local function refreshFTOverlayCacheForPlayer(force)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player then return false end
    local cell = getCell and getCell() or nil
    if not cell then return false end
    local px, py, pz = player:getX(), player:getY(), player:getZ()
    if not px then return false end
    refreshFTOverlayCache(cell, px, py, math.floor(pz or 0), force == true)
    return hasFTMarkers()
end

local CSR_FT_OverlayPanel = ISPanel:derive("CSR_FT_OverlayPanel")

local function ftDrawTileMarker(self, wx, wy, wz, sw_off, sh_off, zoom, sz, a, r, g, b)
    local sx = IsoUtils.XToScreen(wx + 0.5, wy + 0.5, wz, 0)
    local sy = IsoUtils.YToScreen(wx + 0.5, wy + 0.5, wz, 0)
    sx = (sx - sw_off) / zoom
    sy = (sy - sh_off) / zoom
    self:drawRect(sx - sz * 0.5, sy - sz * 0.25, sz, sz * 0.5, a, r, g, b)
end

function CSR_FT_OverlayPanel:render()
    if not isEnabled() then return end
    local player = getSpecificPlayer(0); if not player then return end
    local cell = getCell();              if not cell   then return end
    local px, py, pz = player:getX(), player:getY(), player:getZ()
    if not px then return end
    local pzi = math.floor(pz)
    local r = PURPLE_DRAW_RADIUS

    local core = getCore()
    local zoom = core:getZoom(0)
    local offX = IsoCamera.getOffX()
    local offY = IsoCamera.getOffY()
    local sz   = 16 / zoom

    refreshFTOverlayCache(cell, px, py, pzi, false)
    if not hasFTMarkers() then return end
    for _, marker in pairs(_ftMarkers) do
        if marker.z == pzi
            and math.abs(marker.x - px) <= r
            and math.abs(marker.y - py) <= r then
            ftDrawTileMarker(self, marker.x, marker.y, pzi, offX, offY, zoom, sz,
                             0.95, 1.00, 0.55, 0.10)
        end
    end
    do return end

    for x = sx, ex do
        for y = sy, ey do
            local sq = cell:getGridSquare(x, y, pzi)
            if sq and isPainted(sq) then
                -- Bright amber, fully opaque — a fuel slick is supposed
                -- to be obvious so the player can find it and ignite.
                ftDrawTileMarker(self, x, y, pzi, offX, offY, zoom, sz,
                                 0.95, 1.00, 0.55, 0.10)
            end
        end
    end
end

local _ftPanel = nil
local function ensureFTPanel()
    if _ftPanel and _ftPanel.javaObject then return end
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    _ftPanel = CSR_FT_OverlayPanel:new(0, 0, sw, sh)
    _ftPanel.background = false
    _ftPanel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    _ftPanel:initialise()
    _ftPanel:instantiate()
    if _ftPanel.javaObject and _ftPanel.javaObject.setConsumeMouseEvents then
        _ftPanel.javaObject:setConsumeMouseEvents(false)
    end
end

local function drawPurpleOverlays()
    if not isEnabled() then return end
    if not CSR_FireTrail._painting and not hasFTMarkers() then
        local now = overlayNowMs()
        if now - _ftLastIdleProbeMs < OVERLAY_IDLE_PROBE_MS then return end
        _ftLastIdleProbeMs = now
        if not refreshFTOverlayCacheForPlayer(true) then return end
    end
    ensureFTPanel()
    if _ftPanel and _ftPanel.render then _ftPanel:render() end
end

if Events then
    if Events.OnTick then Events.OnTick.Add(paintTick) end
    if Events.OnFillWorldObjectContextMenu then
        Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
    end
    -- Inventory-side discoverability: right-click any item in inventory;
    -- if the right-clicked stack contains a petrol-bearing container the
    -- player has equipped in primary hand, offer Start/Stop pour. This
    -- makes the feature discoverable without forcing the player to find
    -- the world-context option.
    if Events.OnFillInventoryObjectContextMenu then
        Events.OnFillInventoryObjectContextMenu.Add(function(playerNum, context, items)
            if not isEnabled() then return end
            local player = getSpecificPlayer(playerNum)
            if not player then return end

            -- Look at what the player right-clicked.
            local clickedGasCan = false
            local clickedLighter = false
            local equipped = getEquippedGasCan(player)
            for i = 1, #items do
                local entry = items[i]
                local it = entry
                if entry.items and entry.items[1] then it = entry.items[1] end
                if it then
                    if equipped and it == equipped then clickedGasCan = true end
                    if it.getFullType then
                        local ft = it:getFullType()
                        if ft == "Base.Lighter" or ft == "Base.Matches"
                           or safeHasTag(it, "StartFire") or safeHasTag(it, "Lighter") then
                            clickedLighter = true
                        end
                    end
                end
            end

            -- Pour toggle: shown when right-clicking the equipped gas can.
            if clickedGasCan then
                local label = CSR_FireTrail._painting
                    and (getText and getText("IGUI_CSR_FireTrail_StopPour") or "Stop Pouring Fuel")
                    or  (getText and getText("IGUI_CSR_FireTrail_StartPour") or "Pour Fuel Trail")
                context:addOption(label, nil, function() CSR_FireTrail.togglePainting(player) end)
            end

            -- Ignite from inventory: shown when right-clicking a lighter
            -- or matches IF a painted trail is within ~12 tiles. Saves
            -- the player from hunting the world-context menu when their
            -- click misses the overlay.
            if clickedLighter then
                local cell = getCell()
                local px, py, pz = player:getX(), player:getY(), player:getZ()
                local pzi = math.floor(pz or 0)
                local nearest = nil
                local bestD2 = 12 * 12
                if cell then
                    for dx = -12, 12 do
                        for dy = -12, 12 do
                            local sq = cell:getGridSquare(math.floor(px) + dx, math.floor(py) + dy, pzi)
                            if sq and isPainted(sq) then
                                local d2 = dx * dx + dy * dy
                                if d2 <= bestD2 then bestD2 = d2; nearest = sq end
                            end
                        end
                    end
                end
                if nearest then
                    context:addOption(
                        getText and getText("IGUI_CSR_FireTrail_Ignite") or "Ignite Fuel Trail",
                        nil,
                        function() queueIgnite(player, nearest) end)
                end
            end
        end)
    end
    if Events.OnPostUIDraw then Events.OnPostUIDraw.Add(drawPurpleOverlays) end
    if Events.OnServerCommand then
        Events.OnServerCommand.Add(function(module, command, args)
            if module ~= "CommonSenseReborn" then return end
            if command ~= "FireTrailSquareSync" then return end
            if not args or args.x == nil or args.y == nil or args.z == nil then return end
            local cell = getWorld() and getWorld():getCell() or nil
            if not cell then return end
            local sq = cell:getGridSquare(args.x, args.y, args.z)
            if not sq or not sq.getModData then return end
            local md = sq:getModData()
            if not md then return end
            if args.painted then
                md[PAINT_KEY] = true
                putFTMarker(args.x, args.y, args.z, true)
            else
                md[PAINT_KEY] = nil
                putFTMarker(args.x, args.y, args.z, false)
            end
        end)
    end
end

return CSR_FireTrail
