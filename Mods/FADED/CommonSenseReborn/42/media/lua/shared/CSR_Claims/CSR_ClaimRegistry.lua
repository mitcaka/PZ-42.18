--[[
    CSR_ClaimRegistry.lua
    -------------------------------------------------------------------------
    Track B (v1.8.0) — pure data layer for the CSR claim system.

    Stores claim rows in 32 sharded global modData keys (CSR_Claims_C0 .. C31)
    so a single shard never grows unbounded. Sharding is by `claimId % 32`.

    Row schema (flat primitives only — Java's modData serializer cannot
    preserve nested Lua tables, embedded newlines or arbitrary keys):

        id                  integer (server-assigned, monotonic)
        kind                "personal" | "faction" | "vehicle"
        x, y, w, h, z       integers (z optional, default 0)
        owner               username string
        title               display string
        factionName         string (faction kind only; "" otherwise)
        vehicleId           string (vehicle kind only; legacy alias of vehicleKey)
        vehicleKey          string (vehicle kind only; durable CSR/sql key)
        vehicleSqlId        string (vehicle kind only; database sql id)
        vehicleRuntimeId    string (vehicle kind only; deprecated, always blank)
        membersCSV          comma-separated member usernames
        memberSteamIDsCSV   comma-separated Steam IDs for vehicle members
        memberSteamMapCSV   comma-separated "username=steamid" pairs
        rolesCSV            comma-separated "username:role" pairs
        createdAt           integer (server os.time)
        lastSeen            integer (server os.time)
        migratedFromVanilla 1 if imported from getSafehouseList(), 0 otherwise

    All functions are pure: they read/write modData and never call SafeHouse,
    sendServerCommand, sendClientCommand, or any vanilla claim API.

    Lua callers should treat row tables as opaque and only mutate them via
    updateRow().
--]]

CSR_ClaimRegistry = CSR_ClaimRegistry or {}

local SHARD_COUNT  = 32
local SHARD_PREFIX = "CSR_Claims_C"
local NEXT_ID_KEY  = "CSR_Claims_NextId"

-- =========================================================================
-- Internal helpers
-- =========================================================================

local function shardKeyFor(id)
    local n = tonumber(id) or 0
    if n < 0 then n = -n end
    return SHARD_PREFIX .. tostring(n % SHARD_COUNT)
end

local function getModDataRoot()
    if not getGameTime then return nil end
    local gt = getGameTime()
    if not gt or not gt.getModData then return nil end
    return gt:getModData()
end

local function getShard(shardKey)
    local root = getModDataRoot()
    if not root then return nil end
    if root[shardKey] == nil then root[shardKey] = {} end
    return root[shardKey]
end

local function trim(s)
    if type(s) ~= "string" then return "" end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function looksLikeVehicleKey(value)
    if not value or value == "" then return false end
    value = tostring(value)
    return string.sub(value, 1, 4) == "sql:" or string.sub(value, 1, 4) == "csr:"
end

local function normalizedVehicleKey(spec)
    local key = tostring((spec and spec.vehicleKey) or "")
    if looksLikeVehicleKey(key) then return key end
    local legacy = tostring((spec and spec.vehicleId) or "")
    if looksLikeVehicleKey(legacy) then return legacy end
    return ""
end

-- =========================================================================
-- ID allocation
-- =========================================================================

function CSR_ClaimRegistry.nextId()
    local root = getModDataRoot()
    if not root then return 0 end
    local n = tonumber(root[NEXT_ID_KEY]) or 0
    n = n + 1
    root[NEXT_ID_KEY] = n
    return n
end

-- =========================================================================
-- Row primitives
-- =========================================================================

-- Build a fresh row table from a partial spec; any missing field defaults to
-- the zero value of its type. Caller is responsible for nextId() and inserting
-- the result via addRow().
function CSR_ClaimRegistry.makeRow(spec)
    spec = spec or {}
    local vehicleKey = normalizedVehicleKey(spec)
    return {
        id                  = tonumber(spec.id) or 0,
        kind                = tostring(spec.kind or "personal"),
        x                   = tonumber(spec.x) or 0,
        y                   = tonumber(spec.y) or 0,
        w                   = tonumber(spec.w) or 1,
        h                   = tonumber(spec.h) or 1,
        z                   = tonumber(spec.z) or 0,
        owner               = tostring(spec.owner or ""),
        title               = tostring(spec.title or ""),
        factionName         = tostring(spec.factionName or ""),
        vehicleId           = vehicleKey,
        membersCSV          = tostring(spec.membersCSV or ""),
        memberSteamIDsCSV   = tostring(spec.memberSteamIDsCSV or ""),
        memberSteamMapCSV   = tostring(spec.memberSteamMapCSV or ""),
        rolesCSV            = tostring(spec.rolesCSV or ""),
        createdAt           = tonumber(spec.createdAt) or 0,
        lastSeen            = tonumber(spec.lastSeen) or 0,
        migratedFromVanilla = tonumber(spec.migratedFromVanilla) or 0,
        -- v1.8.36+: durable MP vehicle identity. vehicleId is now only a
        -- backwards-compatible alias of vehicleKey. Runtime ids are not
        -- carried by claim rows because they can be reused by the engine.
        vehicleKey          = vehicleKey,
        vehicleSqlId        = tostring(spec.vehicleSqlId or ""),
        vehicleRuntimeId    = "",
        vehicleClaimVersion = tonumber(spec.vehicleClaimVersion) or 1,
        lastVehicleX        = tonumber(spec.lastVehicleX) or 0,
        lastVehicleY        = tonumber(spec.lastVehicleY) or 0,
        lastVehicleZ        = tonumber(spec.lastVehicleZ) or 0,
        -- v1.8.14: vehicle-ID-reuse defense fields. vehicleScript is the
        -- live vehicle's full script name (e.g. "Base.PickUpVan"); when the
        -- engine recycles a vehicle id onto a different vehicle, the
        -- fingerprint mismatch lets us detect the stale row and scrub it
        -- instead of falsely transferring ownership. ownerSteamID is
        -- defense-in-depth metadata only -- not used for matching today.
        vehicleScript       = tostring(spec.vehicleScript or ""),
        vehicleClaimedAt    = tonumber(spec.vehicleClaimedAt) or 0,
        vehicleMigratedFromLegacy = tonumber(spec.vehicleMigratedFromLegacy) or 0,
        ownerSteamID        = tostring(spec.ownerSteamID or ""),
        vehicleClaimKeyId   = tonumber(spec.vehicleClaimKeyId) or 0,
        vehicleClaimKeyToken = tostring(spec.vehicleClaimKeyToken or ""),
        -- v1.8.35 legacy: per-claim "always show" flag. The Claims UI no
        -- longer mutates this; player outlines are local-only.
        showAlways          = tonumber(spec.showAlways) or 0,
    }
end

-- Returns a flat-primitive copy suitable for sending over the wire.
function CSR_ClaimRegistry.serializeRow(row)
    if type(row) ~= "table" then return nil end
    return CSR_ClaimRegistry.makeRow(row)
end

function CSR_ClaimRegistry.addRow(row)
    if type(row) ~= "table" then return nil end
    if not row.id or row.id == 0 then return nil end
    local shard = getShard(shardKeyFor(row.id))
    if not shard then return nil end
    shard[tostring(row.id)] = CSR_ClaimRegistry.makeRow(row)
    return shard[tostring(row.id)]
end

function CSR_ClaimRegistry.removeRow(id)
    if not id then return false end
    local shard = getShard(shardKeyFor(id))
    if not shard then return false end
    if shard[tostring(id)] == nil then return false end
    shard[tostring(id)] = nil
    return true
end

function CSR_ClaimRegistry.getRowById(id)
    if not id then return nil end
    local shard = getShard(shardKeyFor(id))
    if not shard then return nil end
    return shard[tostring(id)]
end

-- Apply a partial patch (only known keys are copied through makeRow defaults).
function CSR_ClaimRegistry.updateRow(id, patch)
    local row = CSR_ClaimRegistry.getRowById(id)
    if not row or type(patch) ~= "table" then return nil end
    row = CSR_ClaimRegistry.makeRow(row)
    for k, v in pairs(patch) do
        if row[k] ~= nil and k ~= "id" then row[k] = v end
    end
    -- Re-normalize through makeRow to enforce flat-primitive types.
    local fixed = CSR_ClaimRegistry.makeRow(row)
    fixed.id = row.id
    local shard = getShard(shardKeyFor(row.id))
    if shard then shard[tostring(row.id)] = fixed end
    return fixed
end

-- =========================================================================
-- Iteration / queries
-- =========================================================================

-- Calls fn(row) for every row across all shards. Stops if fn returns true.
function CSR_ClaimRegistry.iterShards(fn)
    if type(fn) ~= "function" then return end
    for i = 0, SHARD_COUNT - 1 do
        local shard = getShard(SHARD_PREFIX .. tostring(i))
        if shard then
            for _, row in pairs(shard) do
                if type(row) == "table" and row.id then
                    if fn(row) == true then return end
                end
            end
        end
    end
end

function CSR_ClaimRegistry.getAllRows()
    local out = {}
    CSR_ClaimRegistry.iterShards(function(row)
        out[#out + 1] = row
    end)
    return out
end

function CSR_ClaimRegistry.findRowAtBounds(x, y, w, h)
    if x == nil or y == nil then return nil end
    w = w or 1
    h = h or 1
    local found = nil
    CSR_ClaimRegistry.iterShards(function(row)
        if row.x == x and row.y == y and row.w == w and row.h == h then
            found = row
            return true
        end
    end)
    return found
end

function CSR_ClaimRegistry.rectsIntersect(ax, ay, aw, ah, bx, by, bw, bh)
    ax = tonumber(ax) or 0
    ay = tonumber(ay) or 0
    aw = tonumber(aw) or 1
    ah = tonumber(ah) or 1
    bx = tonumber(bx) or 0
    by = tonumber(by) or 0
    bw = tonumber(bw) or 1
    bh = tonumber(bh) or 1
    return ax < (bx + bw) and bx < (ax + aw)
        and ay < (by + bh) and by < (ay + ah)
end

function CSR_ClaimRegistry.rectContains(outerX, outerY, outerW, outerH, innerX, innerY, innerW, innerH)
    outerX = tonumber(outerX) or 0
    outerY = tonumber(outerY) or 0
    outerW = tonumber(outerW) or 1
    outerH = tonumber(outerH) or 1
    innerX = tonumber(innerX) or 0
    innerY = tonumber(innerY) or 0
    innerW = tonumber(innerW) or 1
    innerH = tonumber(innerH) or 1
    return innerX >= outerX and innerY >= outerY
        and (innerX + innerW) <= (outerX + outerW)
        and (innerY + innerH) <= (outerY + outerH)
end

function CSR_ClaimRegistry.findFirstIntersecting(x, y, w, h, ignoreId, includeVehicles)
    if x == nil or y == nil then return nil end
    w = w or 1
    h = h or 1
    ignoreId = tonumber(ignoreId) or 0
    local found = nil
    CSR_ClaimRegistry.iterShards(function(row)
        if row and (includeVehicles == true or row.kind ~= "vehicle")
                and (tonumber(row.id) or 0) ~= ignoreId
                and CSR_ClaimRegistry.rectsIntersect(x, y, w, h,
                    row.x, row.y, row.w, row.h) then
            found = row
            return true
        end
    end)
    return found
end

function CSR_ClaimRegistry.findRowsIntersecting(x, y, w, h, ignoreId, includeVehicles)
    local out = {}
    if x == nil or y == nil then return out end
    w = w or 1
    h = h or 1
    ignoreId = tonumber(ignoreId) or 0
    CSR_ClaimRegistry.iterShards(function(row)
        if row and (includeVehicles == true or row.kind ~= "vehicle")
                and (tonumber(row.id) or 0) ~= ignoreId
                and CSR_ClaimRegistry.rectsIntersect(x, y, w, h,
                    row.x, row.y, row.w, row.h) then
            out[#out + 1] = row
        end
    end)
    return out
end

function CSR_ClaimRegistry.getRowsByOwner(username)
    if not username or username == "" then return {} end
    local out = {}
    CSR_ClaimRegistry.iterShards(function(row)
        if row.owner == username then out[#out + 1] = row end
    end)
    return out
end

function CSR_ClaimRegistry.getRowsByFaction(factionName)
    if not factionName or factionName == "" then return {} end
    local out = {}
    CSR_ClaimRegistry.iterShards(function(row)
        if row.kind == "faction" and row.factionName == factionName then
            out[#out + 1] = row
        end
    end)
    return out
end

function CSR_ClaimRegistry.getRowsByKind(kind)
    if not kind then return {} end
    local out = {}
    CSR_ClaimRegistry.iterShards(function(row)
        if row.kind == kind then out[#out + 1] = row end
    end)
    return out
end

-- Legacy API name retained for old callers. Plain runtime ids intentionally
-- return nil; callers must use vehicleKey for ownership identity.
function CSR_ClaimRegistry.getRowByVehicleId(vehicleId)
    if not vehicleId or vehicleId == "" then return nil end
    local key = tostring(vehicleId)
    if (string.sub(key, 1, 4) == "sql:" or string.sub(key, 1, 4) == "csr:")
            and CSR_ClaimRegistry.getRowByVehicleKey then
        return CSR_ClaimRegistry.getRowByVehicleKey(key)
    end
    return nil
end

function CSR_ClaimRegistry.getRowByVehicleKey(vehicleKey)
    if not vehicleKey or vehicleKey == "" then return nil end
    local key = tostring(vehicleKey)
    local found = nil
    CSR_ClaimRegistry.iterShards(function(row)
        if row.kind == "vehicle" and row.vehicleKey == key then
            found = row
            return true
        end
    end)
    return found
end

function CSR_ClaimRegistry.getOwnerCount(username)
    if not username or username == "" then return 0 end
    local count = 0
    CSR_ClaimRegistry.iterShards(function(row)
        if row.kind == "personal" and row.owner == username then
            count = count + 1
        end
    end)
    return count
end

function CSR_ClaimRegistry.getFactionCount(factionName)
    if not factionName or factionName == "" then return 0 end
    local count = 0
    CSR_ClaimRegistry.iterShards(function(row)
        if row.kind == "faction" and row.factionName == factionName then
            count = count + 1
        end
    end)
    return count
end

-- =========================================================================
-- CSV helpers (members / roles are stored as flat strings)
-- =========================================================================

function CSR_ClaimRegistry.csvContains(csv, value)
    if not csv or csv == "" or not value or value == "" then return false end
    for token in string.gmatch(csv, "[^,]+") do
        if trim(token) == value then return true end
    end
    return false
end

function CSR_ClaimRegistry.csvAdd(csv, value)
    if not value or value == "" then return csv or "" end
    if CSR_ClaimRegistry.csvContains(csv, value) then return csv end
    if not csv or csv == "" then return value end
    return csv .. "," .. value
end

function CSR_ClaimRegistry.csvRemove(csv, value)
    if not csv or csv == "" or not value or value == "" then return csv or "" end
    local out = {}
    for token in string.gmatch(csv, "[^,]+") do
        local t = trim(token)
        if t ~= "" and t ~= value then out[#out + 1] = t end
    end
    return table.concat(out, ",")
end

function CSR_ClaimRegistry.csvList(csv)
    local out = {}
    if not csv or csv == "" then return out end
    for token in string.gmatch(csv, "[^,]+") do
        local t = trim(token)
        if t ~= "" then out[#out + 1] = t end
    end
    return out
end

-- Flat key/value CSV helpers. Format: "key=value,key=value". Used only for
-- supplemental identity metadata; usernames remain the display surface.
function CSR_ClaimRegistry.mapGet(mapCSV, key)
    if not mapCSV or mapCSV == "" or not key or key == "" then return "" end
    for token in string.gmatch(mapCSV, "[^,]+") do
        local k, v = string.match(token, "^%s*([^=]+)=(.-)%s*$")
        if k and trim(k) == key then return trim(v or "") end
    end
    return ""
end

function CSR_ClaimRegistry.mapSet(mapCSV, key, value)
    if not key or key == "" then return mapCSV or "" end
    value = tostring(value or "")
    local out = {}
    local replaced = false
    if mapCSV and mapCSV ~= "" then
        for token in string.gmatch(mapCSV, "[^,]+") do
            local k = string.match(token, "^%s*([^=]+)=")
            if k and trim(k) == key then
                if value ~= "" then out[#out + 1] = key .. "=" .. value end
                replaced = true
            else
                local t = trim(token)
                if t ~= "" then out[#out + 1] = t end
            end
        end
    end
    if not replaced and value ~= "" then
        out[#out + 1] = key .. "=" .. value
    end
    return table.concat(out, ",")
end

function CSR_ClaimRegistry.mapRemove(mapCSV, key)
    return CSR_ClaimRegistry.mapSet(mapCSV, key, "")
end

-- Roles CSV format: "user1:role1,user2:role2"
function CSR_ClaimRegistry.rolesGet(rolesCSV, username)
    if not rolesCSV or rolesCSV == "" or not username then return nil end
    for token in string.gmatch(rolesCSV, "[^,]+") do
        local user, role = string.match(token, "^%s*([^:]+):(.-)%s*$")
        if user and trim(user) == username then return trim(role or "") end
    end
    return nil
end

function CSR_ClaimRegistry.rolesSet(rolesCSV, username, role)
    if not username or username == "" then return rolesCSV or "" end
    local out = {}
    local replaced = false
    if rolesCSV and rolesCSV ~= "" then
        for token in string.gmatch(rolesCSV, "[^,]+") do
            local user = string.match(token, "^%s*([^:]+):")
            if user and trim(user) == username then
                if role and role ~= "" then
                    out[#out + 1] = username .. ":" .. role
                end
                replaced = true
            else
                local t = trim(token)
                if t ~= "" then out[#out + 1] = t end
            end
        end
    end
    if not replaced and role and role ~= "" then
        out[#out + 1] = username .. ":" .. role
    end
    return table.concat(out, ",")
end

return CSR_ClaimRegistry
