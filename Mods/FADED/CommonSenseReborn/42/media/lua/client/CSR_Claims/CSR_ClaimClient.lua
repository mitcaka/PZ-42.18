--[[
    CSR_ClaimClient.lua
    -------------------------------------------------------------------------
    Track B (v1.8.0) -- CLIENT-SIDE mirror of the CSR claim registry.

    Responsibilities:
      1. Listen for server broadcasts (CSR_ClaimAdded / CSR_ClaimRemoved /
         CSR_ClaimUpdated / CSR_ClaimsBundle / CSR_ClaimResult) and apply
         each mutation to a local table _claimMirror[claimId] = row.
      2. For "personal" and "faction" rows, materialize a local SafeHouse
         instance via SafeHouse.addSafeHouse() so vanilla helpers
         (isSafehouseAllowInteract, isSafehouseAllowLoot, hasSafehouse,
         getSafeHouse) keep working without the broken SafezoneClaimPacket
         round-trip.
      3. Push owner + membersCSV onto the mirrored SafeHouse so vanilla
         permission checks see the right member list.
      4. On OnGameStart (or first tick after login), request a full snapshot
         from the server via CSR_GetClaimsBundle.
      5. Expose helper request functions used by Step 4 (context menu) and
         Step 5 (claims manager panel):
             CSR_ClaimClient.requestClaim(spec)
             CSR_ClaimClient.requestRelease(id)
             CSR_ClaimClient.requestTransfer(id, newOwner)
             CSR_ClaimClient.requestSetRole(id, username, role)
             CSR_ClaimClient.requestBundle()

    Hard rules:
      * NEVER mutate the registry directly from the client. Every write
        goes through a server command.
      * SafeHouse.addSafeHouse() is called CLIENT-SIDE ONLY -- this is the
        whole point of the mirror.
      * Kahlua: no goto / ::label::. No :split() on Lua strings.
      * All Java numeric returns wrapped with tonumber(...) or 0.
--]]

require "CSR_Claims/CSR_ClaimRegistry"

CSR_ClaimClient = CSR_ClaimClient or {}

local Registry = CSR_ClaimRegistry

-- Mirror table: claimId (number) -> row (flat-primitive copy).
-- Public so other client modules (Step 5/6/7) can read it directly.
CSR_ClaimClient._claimMirror = CSR_ClaimClient._claimMirror or {}

-- Parallel table: claimId -> SafeHouse instance (the local mirror).
-- Kept so we can clean up on remove/update without re-scanning the list.
local _safehouseByClaimId = {}

local _bundleRequested = false

-- =========================================================================
-- Helpers
-- =========================================================================

local function safeUsername(player)
    if not player then return "" end
    if player.getUsername then
        local u = player:getUsername()
        if u then return tostring(u) end
    end
    return ""
end

local function localPlayer()
    if getSpecificPlayer then return getSpecificPlayer(0) end
    return nil
end

local function safehouseList()
    if not SafeHouse then return nil end
    if SafeHouse.getSafehouseList then return SafeHouse.getSafehouseList() end
    if SafeHouse.getSafeHouseList then return SafeHouse.getSafeHouseList() end
    return nil
end

local function findExistingSafehouse(x, y, w, h)
    local list = safehouseList()
    if not list or not list.size then return nil end
    local n = tonumber(list:size()) or 0
    for i = 0, n - 1 do
        local sh = list:get(i)
        if sh then
            local sx = tonumber(sh:getX()) or -1
            local sy = tonumber(sh:getY()) or -1
            local sw = tonumber(sh:getW()) or -1
            local sh2 = tonumber(sh:getH()) or -1
            if sx == x and sy == y and sw == w and sh2 == h then
                return sh
            end
        end
    end
    return nil
end

local function applyMembers(safehouse, row)
    if not safehouse or not row then return end
    -- Owner first.
    if safehouse.setOwner and row.owner and row.owner ~= "" then
        safehouse:setOwner(row.owner)
    end
    if safehouse.setTitle and row.title and row.title ~= "" then
        safehouse:setTitle(row.title)
    end
    -- Members: clear the existing list (best effort) then re-add from CSV.
    if safehouse.getPlayers and safehouse.addPlayer then
        local list = safehouse:getPlayers()
        if list and list.clear then list:clear() end
        local names = Registry.csvList(row.membersCSV)
        for i = 1, #names do
            safehouse:addPlayer(names[i])
        end
    end
end

-- Materialize (or fetch) a SafeHouse mirror for this row. Vehicle claims
-- have no SafeHouse mirror -- they live in _claimMirror only.
local function materializeMirror(row)
    if not row or row.kind == "vehicle" then return nil end
    if not SafeHouse or not SafeHouse.addSafeHouse then return nil end

    local existing = _safehouseByClaimId[row.id]
        or findExistingSafehouse(row.x, row.y, row.w, row.h)

    if existing then
        applyMembers(existing, row)
        _safehouseByClaimId[row.id] = existing
        return existing
    end

    local sh = SafeHouse.addSafeHouse(row.x, row.y, row.w, row.h, row.owner)
    if sh then
        applyMembers(sh, row)
        _safehouseByClaimId[row.id] = sh
    end
    return sh
end

local function dropMirror(id)
    local sh = _safehouseByClaimId[id]
    _safehouseByClaimId[id] = nil
    if not sh then return end
    if not SafeHouse then return end
    -- Remove from vanilla list. Use the safest available API.
    if SafeHouse.removeSafeHouse then
        SafeHouse.removeSafeHouse(sh)
    else
        local list = safehouseList()
        if list and list.remove then list:remove(sh) end
    end
end

-- =========================================================================
-- Server command handlers
-- =========================================================================

-- v1.8.1: refresh the open Claims Manager panel (if any) on every mirror
-- mutation.  Without this hook, claims committed on the server while the
-- panel was already open never appeared until the user clicked Refresh.
local function refreshOpenClaimsPanel()
    local panel = rawget(_G, "CSR_ClaimsManagerPanel")
    if not panel or not panel.instance then return end
    local inst = panel.instance
    if inst.populate and inst:isVisible() then
        inst:populate()
    end
end

-- v1.8.6: ALSO write the row into the actual CSR_ClaimRegistry shards on
-- the client so vehicle-key lookups / getRowsByOwner() return immediately
-- after the broadcast arrives, instead of waiting for global modData
-- replication (which can lag tens of seconds in MP). Without this, the
-- vehicle radial menu kept showing "Claim Vehicle" after a successful
-- claim because the client's registry view was stale.
local function onClaimAdded(args)
    if type(args) ~= "table" or not args.id then return end
    local row = Registry.makeRow(args)
    CSR_ClaimClient._claimMirror[row.id] = row
    if Registry.addRow then Registry.addRow(row) end
    materializeMirror(row)
    refreshOpenClaimsPanel()
end

local function onClaimRemoved(args)
    if type(args) ~= "table" or not args.id then return end
    local id = tonumber(args.id) or 0
    if id == 0 then return end
    dropMirror(id)
    CSR_ClaimClient._claimMirror[id] = nil
    if Registry.removeRow then Registry.removeRow(id) end
    refreshOpenClaimsPanel()
end

local function onClaimUpdated(args)
    if type(args) ~= "table" or not args.id then return end
    local row = Registry.makeRow(args)
    local prev = CSR_ClaimClient._claimMirror[row.id]
    CSR_ClaimClient._claimMirror[row.id] = row
    if Registry.addRow then Registry.addRow(row) end

    -- If the bounds moved (rare; not currently exposed by handlers), rebuild
    -- the mirror from scratch.
    if prev and (prev.x ~= row.x or prev.y ~= row.y
            or prev.w ~= row.w or prev.h ~= row.h or prev.kind ~= row.kind) then
        dropMirror(row.id)
        materializeMirror(row)
        refreshOpenClaimsPanel()
        return
    end

    -- Otherwise just refresh metadata on the existing mirror.
    local sh = _safehouseByClaimId[row.id]
    if sh then
        applyMembers(sh, row)
    else
        materializeMirror(row)
    end
    refreshOpenClaimsPanel()
end

local function onClaimsBundle(args)
    -- Header only; individual rows arrive as CSR_ClaimAdded broadcasts.
    -- Reset local state so a re-request gives a clean snapshot.
    for id, _ in pairs(CSR_ClaimClient._claimMirror) do
        dropMirror(id)
        CSR_ClaimClient._claimMirror[id] = nil
    end
end

local function onClaimResult(args)
    if type(args) ~= "table" then return end
    local text = tostring(args.text or "")
    local ok = (tonumber(args.ok) or 0) == 1
    if text == "" then return end
    local p = localPlayer()
    if p and p.setHaloNote then
        local r, g, b = 1.0, 1.0, 1.0
        if ok then r, g, b = 0.4, 1.0, 0.4 else r, g, b = 1.0, 0.5, 0.4 end
        p:setHaloNote(text, r * 255, g * 255, b * 255, 200)
    end
end

-- Respawn-pin info from server (current pin or empty when cleared)
CSR_ClaimClient._respawnPin = nil
local function onRespawnInfo(args)
    if type(args) ~= "table" then return end
    local cid = tonumber(args.claimId) or 0
    if cid == 0 then
        CSR_ClaimClient._respawnPin = nil
        return
    end
    CSR_ClaimClient._respawnPin = {
        claimId = cid,
        x = tonumber(args.x) or 0,
        y = tonumber(args.y) or 0,
        z = tonumber(args.z) or 0,
    }
end

-- Robust teleport: combines vanilla teleportTo with forced
-- setX/Y/Z + setLastX/Y/Z, then retries once on the next OnTick
-- so we survive any post-spawn engine override (chunk load, spawn screen
-- snap-back, etc.). Also nudges the chunk around the destination so the
-- character doesn't fall through the floor on first frame.
local function forceTeleport(x, y, z)
    local pp = localPlayer()
    if not pp then return end
    if pp.teleportTo then pp:teleportTo(x, y, z) end
    if pp.setX then pp:setX(x) end
    if pp.setY then pp:setY(y) end
    if pp.setZ then pp:setZ(z) end
    if pp.setLastX then pp:setLastX(x) end
    if pp.setLastY then pp:setLastY(y) end
    if pp.setLastZ then pp:setLastZ(z) end
    -- Nudge chunk loader so the destination square is hot when we land.
    if getCell and getCell() and getCell().getGridSquare then
        getCell():getGridSquare(x, y, z)
    end
end

local function scheduleForceTeleport(x, y, z)
    if x == 0 and y == 0 then return end
    forceTeleport(x, y, z)
    local fired = false
    local function lateTick()
        if fired then return end
        fired = true
        if Events and Events.OnTick and Events.OnTick.Remove then
            Events.OnTick.Remove(lateTick)
        end
        forceTeleport(x, y, z)
    end
    if Events and Events.OnTick and Events.OnTick.Add then
        Events.OnTick.Add(lateTick)
    end
end

local function onRespawnDo(args)
    if type(args) ~= "table" then return end
    local x, y, z = tonumber(args.x) or 0, tonumber(args.y) or 0, tonumber(args.z) or 0
    scheduleForceTeleport(x, y, z)
end

local function onAdminTeleportDo(args)
    if type(args) ~= "table" then return end
    local x = tonumber(args.x) or 0
    local y = tonumber(args.y) or 0
    local z = tonumber(args.z) or 0
    scheduleForceTeleport(x, y, z)
end

local DISPATCH = {
    CSR_ClaimAdded     = onClaimAdded,
    CSR_ClaimRemoved   = onClaimRemoved,
    CSR_ClaimUpdated   = onClaimUpdated,
    CSR_ClaimsBundle   = onClaimsBundle,
    CSR_ClaimResult    = onClaimResult,
    CSR_RespawnInfo    = onRespawnInfo,
    CSR_RespawnDo      = onRespawnDo,
    CSR_AdminTeleportDo = onAdminTeleportDo,
}

local function onServerCommand(module, command, args)
    if module ~= "CommonSenseReborn" then return end
    local fn = DISPATCH[command]
    if fn then fn(args or {}) end
end

-- =========================================================================
-- Public request helpers (used by Step 4 / Step 5 / Step 6)
-- =========================================================================

local function send(command, args)
    local p = localPlayer()
    if isClient() then
        sendClientCommand(p, "CommonSenseReborn", command, args or {})
    else
        -- SP: dispatch directly into the server module.
        if CSR_ClaimServer and CSR_ClaimServer.dispatch then
            CSR_ClaimServer.dispatch("CommonSenseReborn", command, p, args or {})
        end
    end
end

function CSR_ClaimClient.requestClaim(spec)
    send("CSR_ClaimRequest", spec or {})
end

function CSR_ClaimClient.requestRelease(id)
    send("CSR_ReleaseRequest", { id = tonumber(id) or 0 })
end

function CSR_ClaimClient.requestResize(id, x, y, w, h)
    send("CSR_ResizeClaimRequest", {
        id = tonumber(id) or 0,
        x  = tonumber(x) or 0,
        y  = tonumber(y) or 0,
        w  = tonumber(w) or 1,
        h  = tonumber(h) or 1,
    })
end

function CSR_ClaimClient.requestTransfer(id, newOwner)
    send("CSR_TransferRequest", {
        id       = tonumber(id) or 0,
        newOwner = tostring(newOwner or ""),
    })
end

function CSR_ClaimClient.requestSetRole(id, username, role)
    send("CSR_SetRoleRequest", {
        id       = tonumber(id) or 0,
        username = tostring(username or ""),
        role     = tostring(role or ""),
    })
end

-- Throttle: prevent prerender / panel-open / context-menu paths from
-- spamming the server. Manual refresh button passes force=true to bypass.
local _lastBundleSent = 0
local BUNDLE_MIN_INTERVAL_MS = 2000

local function nowMs()
    if getTimestampMs then
        return tonumber(getTimestampMs()) or 0
    end
    return 0
end

function CSR_ClaimClient.requestBundle(force)
    local t = nowMs()
    if not force and (t - _lastBundleSent) < BUNDLE_MIN_INTERVAL_MS then
        return
    end
    _lastBundleSent = t
    send("CSR_GetClaimsBundle", {})
end

-- Respawn-pin helpers
function CSR_ClaimClient.requestSetRespawn(claimId)
    send("CSR_SetRespawn", { claimId = tonumber(claimId) or 0 })
end

function CSR_ClaimClient.requestClearRespawn()
    send("CSR_ClearRespawn", {})
end

function CSR_ClaimClient.requestRespawnInfo()
    send("CSR_RespawnInfoQuery", {})
end

function CSR_ClaimClient.requestAdminTeleport(rowId)
    send("CSR_AdminTeleportClaim", { rowId = tonumber(rowId) or 0 })
end

function CSR_ClaimClient.requestAdminForceReleaseSafehouse(x, y, z)
    send("CSR_AdminForceReleaseSafehouse", {
        x = tonumber(x) or 0,
        y = tonumber(y) or 0,
        z = tonumber(z) or 0,
    })
end

function CSR_ClaimClient.requestAdminPurgeLegacyVehicles()
    send("CSR_AdminPurgeLegacyVehicles", {})
end

function CSR_ClaimClient.getRespawnPin()
    return CSR_ClaimClient._respawnPin
end

-- =========================================================================
-- Public read helpers (read-only convenience over _claimMirror)
-- =========================================================================

function CSR_ClaimClient.getClaim(id)
    return CSR_ClaimClient._claimMirror[tonumber(id) or 0]
end

function CSR_ClaimClient.getAllClaims()
    local out = {}
    for _, row in pairs(CSR_ClaimClient._claimMirror) do
        out[#out + 1] = row
    end
    return out
end

function CSR_ClaimClient.getClaimAt(x, y)
    if not x or not y then return nil end
    for _, row in pairs(CSR_ClaimClient._claimMirror) do
        if row.kind ~= "vehicle" then
            local x2 = row.x + (row.w or 1)
            local y2 = row.y + (row.h or 1)
            if x >= row.x and x < x2 and y >= row.y and y < y2 then
                return row
            end
        end
    end
    return nil
end

function CSR_ClaimClient.getClaimByVehicleId(vehicleId)
    if not vehicleId or vehicleId == "" then return nil end
    vehicleId = tostring(vehicleId)
    if string.sub(vehicleId, 1, 4) == "sql:" or string.sub(vehicleId, 1, 4) == "csr:" then
        return CSR_ClaimClient.getClaimByVehicleKey(vehicleId)
    end
    return nil
end

function CSR_ClaimClient.getClaimByVehicleKey(vehicleKey)
    if not vehicleKey or vehicleKey == "" then return nil end
    vehicleKey = tostring(vehicleKey)
    for _, row in pairs(CSR_ClaimClient._claimMirror) do
        if row.kind == "vehicle" and row.vehicleKey == vehicleKey then
            return row
        end
    end
    return nil
end

function CSR_ClaimClient.getSafehouseForClaim(id)
    return _safehouseByClaimId[tonumber(id) or 0]
end

-- =========================================================================
-- Event hooks
-- =========================================================================

local function onGameStart()
    if _bundleRequested then return end
    _bundleRequested = true
    -- Defer one tick so the connection is fully established in MP.
    local fired = false
    local function tick()
        if fired then return end
        fired = true
        Events.OnTick.Remove(tick)
        CSR_ClaimClient.requestBundle()
    end
    Events.OnTick.Add(tick)
end

Events.OnServerCommand.Add(onServerCommand)
Events.OnGameStart.Add(onGameStart)

-- Respawn lifecycle: mark pending on death, request the auto-teleport on
-- first OnCreatePlayer that fires after the death cycle.
local function onPlayerDeath(player)
    if not player then return end
    local lp = localPlayer()
    if lp and player ~= lp then return end
    send("CSR_RespawnMarkPending", {})
end

local function onCreatePlayer(playerIndex, playerObj)
    local lp = localPlayer()
    if playerObj and lp and playerObj ~= lp then return end
    -- Pull the current pin so UIs (Claims Manager, etc.) can show state,
    -- and ask the server whether we owe this player an auto-teleport.
    send("CSR_RespawnInfoQuery", {})
    -- Fire CSR_RespawnCheck once immediately AND retry on the first few
    -- OnTicks. The server clears the "pending" flag on the first reply,
    -- so subsequent ticks are cheap no-ops; this guards against the case
    -- where OnCreatePlayer fires before the player object is ready to
    -- receive a teleport (chunk not loaded, animation in spawn screen,
    -- etc.) and the first send arrives but cannot land.
    send("CSR_RespawnCheck", {})
    local ticks = 0
    local sends = 0
    local function retry()
        ticks = ticks + 1
        -- Retry every ~30 ticks (~0.5s), 6 times = ~3s window. The server
        -- clears pending on first successful reply, so later sends are
        -- cheap no-ops on the server.
        if ticks % 30 == 0 then
            sends = sends + 1
            send("CSR_RespawnCheck", {})
            if sends >= 6 then
                if Events and Events.OnTick and Events.OnTick.Remove then
                    Events.OnTick.Remove(retry)
                end
            end
        end
    end
    if Events and Events.OnTick and Events.OnTick.Add then
        Events.OnTick.Add(retry)
    end
end

if Events.OnPlayerDeath  then Events.OnPlayerDeath.Add(onPlayerDeath)   end
if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(onCreatePlayer) end

return CSR_ClaimClient
