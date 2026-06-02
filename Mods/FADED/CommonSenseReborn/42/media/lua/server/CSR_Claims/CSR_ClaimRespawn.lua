--[[
    CSR_ClaimRespawn.lua
    -------------------------------------------------------------------------
    v1.8.0 -- server-authoritative respawn-at-claim system, layered on top of
    the Track B claim registry (CSR_ClaimRegistry / CSR_ClaimServer).

    Design
    ------
      * Per-player respawn assignment is keyed by username and pinned to a
        single claim row from the registry. Pinning is restricted to claims
        of kind "personal" or "faction" where the caller is the owner OR a
        listed member. Vehicle claims are not eligible.
      * Persistence: a single ModData.getOrCreate("CSR_RespawnTable") map
        with FLAT primitive values only -- per-user fields live as separate
        keys "<username>_x", "<username>_y", "<username>_z", "<username>_cid",
        "<username>_p". This avoids any nested-table reload ambiguity (Java's
        modData serializer is known to coerce some nested shapes into
        HashMaps on reload). Same flat-primitives discipline as Track B
        shard rows.
      * Tier 1 -- vanilla spawn-screen flag: when assigning, we also call
        the vanilla SafeHouse:setRespawnInSafehouse(...) on the matching
        Java SafeHouse (if any) so the post-death map-spawn-select screen
        offers it as a spawn pick.
      * Tier 2 -- auto-teleport on death:
            client OnPlayerDeath  -> sends CSR_RespawnMarkPending
            client OnCreatePlayer -> sends CSR_RespawnCheck
                                     server replies CSR_RespawnDo{x,y,z}
                                     client teleports
        If the pinned claim no longer exists by the time the player respawns,
        we silently fall back to the vanilla spawn screen.

    Hard rules (carried over from CSR_ClaimServer):
      * NEVER trust args.username. Use player:getUsername() for the caller.
      * Module is gated on CSR_FeatureFlags.isClaimRespawnEnabled(); when
        OFF every handler is a no-op.
      * Kahlua: no goto, no :split().
--]]

require "CSR_Claims/CSR_ClaimRegistry"

CSR_ClaimRespawn = CSR_ClaimRespawn or {}

local Registry = CSR_ClaimRegistry

local CMD_INFO    = "CSR_RespawnInfo"   -- server -> client (current pin)
local CMD_DO      = "CSR_RespawnDo"     -- server -> client (teleport now)
local CMD_RESULT  = "CSR_ClaimResult"   -- reuse claim feedback channel

local TABLE_KEY = "CSR_RespawnTable"

-- =========================================================================
-- Helpers
-- =========================================================================

local function isEnabled()
    if CSR_FeatureFlags and CSR_FeatureFlags.isClaimRespawnEnabled then
        return CSR_FeatureFlags.isClaimRespawnEnabled()
    end
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or nil
    if not sb then return true end
    return sb.EnableClaimRespawn ~= false
end

local function safeUsername(player)
    if not player then return "" end
    if player.getUsername then
        local u = player:getUsername()
        if u then return tostring(u) end
    end
    return ""
end

local function sendResult(player, ok, text)
    if not player then return end
    sendServerCommand(player, "CommonSenseReborn", CMD_RESULT, {
        ok = ok and 1 or 0, text = tostring(text or ""),
    })
end

local function getRespawnTable()
    if not ModData or not ModData.getOrCreate then return nil end
    local t = ModData.getOrCreate(TABLE_KEY)
    return t
end

-- Flat-key accessors: every per-user field is its own primitive key under
-- the global modData root. NEVER store a sub-table.
local function readEntry(t, username)
    if not t or not username or username == "" then return nil end
    local cid = tonumber(t[username .. "_cid"])
    if not cid or cid == 0 then return nil end
    return {
        x       = tonumber(t[username .. "_x"]) or 0,
        y       = tonumber(t[username .. "_y"]) or 0,
        z       = tonumber(t[username .. "_z"]) or 0,
        claimId = cid,
        pending = tonumber(t[username .. "_p"]) or 0,
    }
end

local function writeEntry(t, username, x, y, z, claimId, pending)
    if not t or not username or username == "" then return end
    t[username .. "_x"]   = tonumber(x) or 0
    t[username .. "_y"]   = tonumber(y) or 0
    t[username .. "_z"]   = tonumber(z) or 0
    t[username .. "_cid"] = tonumber(claimId) or 0
    t[username .. "_p"]   = tonumber(pending) or 0
end

local function clearEntry(t, username)
    if not t or not username or username == "" then return end
    t[username .. "_x"]   = nil
    t[username .. "_y"]   = nil
    t[username .. "_z"]   = nil
    t[username .. "_cid"] = nil
    t[username .. "_p"]   = nil
end

local function setPending(t, username, value)
    if not t or not username or username == "" then return end
    if (tonumber(t[username .. "_cid"]) or 0) == 0 then return end
    t[username .. "_p"] = tonumber(value) or 0
end

-- Iterate every distinct username currently in the table by walking the
-- "_cid" suffix keys.
local function forEachUser(t, fn)
    if not t then return end
    -- snapshot keys first so callbacks can mutate t safely
    local users = {}
    for k, _ in pairs(t) do
        if type(k) == "string" then
            local len = #k
            if len > 4 and string.sub(k, len - 3) == "_cid" then
                users[#users + 1] = string.sub(k, 1, len - 4)
            end
        end
    end
    for i = 1, #users do
        fn(users[i])
    end
end

local function isMember(row, username)
    if not row or not username or username == "" then return false end
    if row.owner == username then return true end
    local list = Registry.csvList and Registry.csvList(row.membersCSV) or {}
    for i = 1, #list do
        if list[i] == username then return true end
    end
    return false
end

local function pickRespawnPoint(row)
    -- Personal / faction safehouse claims: centre of the rect at row.z.
    local x = (tonumber(row.x) or 0) + math.floor((tonumber(row.w) or 1) / 2)
    local y = (tonumber(row.y) or 0) + math.floor((tonumber(row.h) or 1) / 2)
    local z = tonumber(row.z) or 0
    return x, y, z
end

local function findVanillaSafeHouse(row)
    if not row or not getSafehouseList then return nil end
    local list = getSafehouseList()
    if not list then return nil end
    local rx, ry = tonumber(row.x) or 0, tonumber(row.y) or 0
    local rw, rh = tonumber(row.w) or 1, tonumber(row.h) or 1
    local cx, cy = rx + math.floor(rw / 2), ry + math.floor(rh / 2)
    -- Pass 1: exact origin match (fast path, claim made via vanilla modal).
    for i = 0, list:size() - 1 do
        local sh = list:get(i)
        if sh and sh:getX() == rx and sh:getY() == ry then
            return sh
        end
    end
    -- Pass 2: any safehouse whose footprint contains the claim's centre.
    for i = 0, list:size() - 1 do
        local sh = list:get(i)
        if sh then
            local sx = sh:getX() or 0
            local sy = sh:getY() or 0
            local sw = (sh.getW and sh:getW()) or 1
            local shh = (sh.getH and sh:getH()) or 1
            if cx >= sx and cx < sx + sw and cy >= sy and cy < sy + shh then
                return sh
            end
        end
    end
    return nil
end

-- Best-effort: clear vanilla respawn flag from every safehouse other than
-- the target. Mirrors single-active-respawn semantics.
local function syncVanillaRespawnFlag(username, targetRow, enabled)
    if not username or username == "" then return end
    if not getSafehouseList then return end
    local list = getSafehouseList()
    if not list then return end
    local target = enabled and findVanillaSafeHouse(targetRow) or nil
    for i = 0, list:size() - 1 do
        local sh = list:get(i)
        if sh then
            local on = sh.isRespawnInSafehouse and sh:isRespawnInSafehouse(username) or false
            if enabled and sh == target then
                if not on and sh.setRespawnInSafehouse then
                    sh:setRespawnInSafehouse(username, true)
                end
            else
                if on and sh.setRespawnInSafehouse then
                    sh:setRespawnInSafehouse(username, false)
                end
            end
        end
    end
end

local function sendInfo(player, entry)
    if not player then return end
    if entry then
        sendServerCommand(player, "CommonSenseReborn", CMD_INFO, {
            x       = tonumber(entry.x) or 0,
            y       = tonumber(entry.y) or 0,
            z       = tonumber(entry.z) or 0,
            claimId = tonumber(entry.claimId) or 0,
        })
    else
        sendServerCommand(player, "CommonSenseReborn", CMD_INFO, {})
    end
end

-- =========================================================================
-- Handlers
-- =========================================================================

function CSR_ClaimRespawn.handleSetRespawn(player, args)
    if not isEnabled() then
        sendResult(player, false, "Claim respawn disabled")
        return
    end
    local username = safeUsername(player)
    if username == "" then return end

    local claimId = tonumber(args and args.claimId) or 0
    local row = Registry.getRowById and Registry.getRowById(claimId) or nil
    if not row then
        sendResult(player, false, "Claim not found")
        return
    end
    if row.kind ~= "personal" and row.kind ~= "faction" then
        sendResult(player, false, "Vehicle claims cannot be respawn points")
        return
    end
    if not isMember(row, username) then
        sendResult(player, false, "Not a member of this claim")
        return
    end

    local t = getRespawnTable()
    if not t then return end
    local x, y, z = pickRespawnPoint(row)
    writeEntry(t, username, x, y, z, claimId, 0)
    syncVanillaRespawnFlag(username, row, true)
    sendInfo(player, readEntry(t, username))
    sendResult(player, true, "Respawn point set")
end

function CSR_ClaimRespawn.handleClearRespawn(player, args)
    if not isEnabled() then return end
    local username = safeUsername(player)
    if username == "" then return end
    local t = getRespawnTable()
    if not t then return end
    clearEntry(t, username)
    syncVanillaRespawnFlag(username, nil, false)
    sendInfo(player, nil)
    sendResult(player, true, "Respawn point cleared")
end

function CSR_ClaimRespawn.handleQueryRespawn(player, args)
    if not isEnabled() then
        sendInfo(player, nil)
        return
    end
    local username = safeUsername(player)
    if username == "" then return end
    local t = getRespawnTable()
    if not t then return end
    sendInfo(player, readEntry(t, username))
end

function CSR_ClaimRespawn.handleMarkPending(player, args)
    if not isEnabled() then return end
    local username = safeUsername(player)
    if username == "" then return end
    local t = getRespawnTable()
    if not t then return end
    setPending(t, username, 1)
end

function CSR_ClaimRespawn.handleCheckRespawn(player, args)
    if not isEnabled() then return end
    local username = safeUsername(player)
    if username == "" then return end
    local t = getRespawnTable()
    if not t then return end
    local entry = readEntry(t, username)
    if not entry or (tonumber(entry.pending) or 0) == 0 then return end

    -- Verify the pinned claim still exists.
    local row = Registry.getRowById and Registry.getRowById(tonumber(entry.claimId) or 0) or nil
    setPending(t, username, 0)
    if not row or (row.kind ~= "personal" and row.kind ~= "faction") then
        -- Stale pin: clear and let vanilla spawn screen handle it.
        clearEntry(t, username)
        syncVanillaRespawnFlag(username, nil, false)
        sendInfo(player, nil)
        return
    end

    sendServerCommand(player, "CommonSenseReborn", CMD_DO, {
        x = tonumber(entry.x) or 0,
        y = tonumber(entry.y) or 0,
        z = tonumber(entry.z) or 0,
    })
end

-- Called from CSR_ClaimServer when a row is removed -- best-effort cleanup
-- of any respawn pin that pointed at it.
function CSR_ClaimRespawn.onClaimRemoved(claimId)
    if not isEnabled() then return end
    local t = getRespawnTable()
    if not t then return end
    local cid = tonumber(claimId) or 0
    if cid == 0 then return end
    forEachUser(t, function(u)
        if (tonumber(t[u .. "_cid"]) or 0) == cid then
            clearEntry(t, u)
            syncVanillaRespawnFlag(u, nil, false)
        end
    end)
end

-- =========================================================================
-- DISPATCH (merged into CSR_ClaimServer's table by CSR_ClaimServer.lua)
-- =========================================================================

CSR_ClaimRespawn.DISPATCH = {
    CSR_SetRespawn         = CSR_ClaimRespawn.handleSetRespawn,
    CSR_ClearRespawn       = CSR_ClaimRespawn.handleClearRespawn,
    CSR_RespawnInfoQuery   = CSR_ClaimRespawn.handleQueryRespawn,
    CSR_RespawnMarkPending = CSR_ClaimRespawn.handleMarkPending,
    CSR_RespawnCheck       = CSR_ClaimRespawn.handleCheckRespawn,
}

return CSR_ClaimRespawn
