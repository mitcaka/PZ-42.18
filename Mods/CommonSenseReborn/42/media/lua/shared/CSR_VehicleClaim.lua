require "CSR_FeatureFlags"
require "CSR_Claims/CSR_ClaimRegistry"

--[[
    CSR_VehicleClaim.lua (shared)
    -------------------------------------------------------------------------
    Vehicle ownership helpers.

    v1.8.36+ uses the vehicle's own modData key as the identity anchor:
      * Existing stored sql:/csr: keys remain valid for old saves.
      * New claims get a csr: key stored on the vehicle before registry write.
      * Live sql ids are key candidates only.

    The registry is still the source of truth. Per-vehicle modData is only a
    mirror/recovery path for loaded vehicles and older saves. Runtime ids are
    never stored, matched, or used as vehicle-claim authority.
]]

CSR_VehicleClaim = CSR_VehicleClaim or {}

local OWNER_KEY       = "CSR_VehicleOwner"
local ALLOWED_KEY     = "CSR_VehicleAllowed"
local CLAIM_KEY       = "CSR_VehicleClaimKey"
local SQL_ID_KEY      = "CSR_VehicleSqlId"
local RUNTIME_ID_KEY  = "CSR_VehicleRuntimeId"
local VERSION_KEY     = "CSR_VehicleClaimVersion"
local RELEASED_AT_KEY = "CSR_VehicleClaimReleasedAt"
local FALLBACK_NEXT   = "CSR_VehicleClaimKeyNext"
local CLAIM_KEY_ID    = "CSR_VehicleClaimKeyId"
local CLAIM_KEY_TOKEN = "CSR_VehicleClaimKeyToken"
local CLAIM_KEY_OWNER = "CSR_VehicleClaimKeyOwnerSteamID"

local KEY_ITEM_VEHICLE_KEY = "CSR_ClaimVehicleKey"
local KEY_ITEM_TOKEN       = "CSR_ClaimKeyToken"
local KEY_ITEM_OWNER       = "CSR_ClaimKeyOwnerSteamID"

local registryRowFor

local function nowTs()
    if os and os.time then return tonumber(os.time()) or 0 end
    return 0
end

local function modDataFor(vehicle)
    if not vehicle or not vehicle.getModData then return nil end
    return vehicle:getModData()
end

local function normalizePositiveId(v)
    if v == nil then return nil end
    local s = tostring(v)
    if s == "" or s == "nil" then return nil end
    local n = tonumber(s)
    if not n or n <= 0 then return nil end
    return tostring(math.floor(n))
end

local function addUnique(out, seen, value)
    if not value or value == "" or seen[value] then return end
    out[#out + 1] = value
    seen[value] = true
end

local function steamIdFor(player)
    if not player or not player.getSteamID then return "" end
    local sid = player:getSteamID()
    if not sid then return "" end
    local s = tostring(sid)
    if s == "" or s == "0" then return "" end
    return s
end

function CSR_VehicleClaim.getPlayerSteamID(player)
    return steamIdFor(player)
end

local function isAdminPlayer(player)
    if not player or not player.getAccessLevel then return false end
    local access = player:getAccessLevel()
    return access == "admin" or access == "Admin"
end

local function registryCsvContains(csv, value)
    if not value or value == "" then return false end
    if CSR_ClaimRegistry and CSR_ClaimRegistry.csvContains then
        return CSR_ClaimRegistry.csvContains(csv or "", value) == true
    end
    if not csv or csv == "" then return false end
    for token in string.gmatch(csv, "[^,]+") do
        local t = tostring(token or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if t == value then return true end
    end
    return false
end

local function rowOwnerMatches(row, player)
    if not row or not player then return false end
    local sid = steamIdFor(player)
    local rowSid = tostring(row.ownerSteamID or "")
    if sid ~= "" and rowSid ~= "" then
        return sid == rowSid
    end
    local username = player.getUsername and player:getUsername() or nil
    return username ~= nil and tostring(row.owner or "") == tostring(username)
end

function CSR_VehicleClaim.rowOwnerMatches(row, player)
    return rowOwnerMatches(row, player)
end

local function rowMemberMatches(row, player)
    if not row or not player then return false end
    local sid = steamIdFor(player)
    if sid ~= "" and registryCsvContains(row.memberSteamIDsCSV or "", sid) then
        return true
    end
    local username = player.getUsername and player:getUsername() or nil
    if username and registryCsvContains(row.membersCSV or "", tostring(username)) then
        return true
    end
    return false
end

function CSR_VehicleClaim.rowMemberMatches(row, player)
    return rowMemberMatches(row, player)
end

local function liveVehicleSqlId(vehicle)
    if not vehicle then return nil end
    if vehicle.getSqlId then
        local normalized = normalizePositiveId(vehicle:getSqlId())
        if normalized then return normalized end
    end
    return nil
end

local function storedVehicleSqlId(vehicle)
    local data = modDataFor(vehicle)
    if data then
        return normalizePositiveId(data[SQL_ID_KEY] or data.SQLID)
    end
    return nil
end

function CSR_VehicleClaim.getVehicleSqlId(vehicle)
    return liveVehicleSqlId(vehicle) or storedVehicleSqlId(vehicle)
end

local function storedVehicleKey(vehicle)
    local data = modDataFor(vehicle)
    if not data then return nil end
    local key = data[CLAIM_KEY]
    if not key or key == "" then return nil end
    key = tostring(key)
    if string.sub(key, 1, 4) == "sql:" or string.sub(key, 1, 4) == "csr:" then
        return key
    end
    return nil
end

local function nextFallbackKey(vehicle)
    if not getGameTime then return nil end
    local gt = getGameTime()
    if not gt or not gt.getModData then return nil end
    local root = gt:getModData()
    if not root then return nil end
    local n = (tonumber(root[FALLBACK_NEXT]) or 0) + 1
    root[FALLBACK_NEXT] = n
    local ts = nowTs()
    return "csr:" .. tostring(ts) .. ":" .. tostring(n)
end

function CSR_VehicleClaim.getVehicleKey(vehicle, ensureFallback)
    local stored = storedVehicleKey(vehicle)
    if stored then return stored end

    if ensureFallback and not isClient() then
        local data = modDataFor(vehicle)
        local key = data and nextFallbackKey(vehicle) or nil
        if key then
            data[CLAIM_KEY] = key
            data[VERSION_KEY] = 2
            if vehicle and vehicle.transmitModData then
                vehicle:transmitModData()
            end
            return key
        end
    end

    local sqlId = CSR_VehicleClaim.getVehicleSqlId(vehicle)
    if sqlId then return "sql:" .. sqlId end
    return nil
end

function CSR_VehicleClaim.getVehicleKeyCandidates(vehicle, ensureFallback)
    local out = {}
    local seen = {}
    local stored = storedVehicleKey(vehicle)
    addUnique(out, seen, stored)
    if ensureFallback and not stored then
        addUnique(out, seen, CSR_VehicleClaim.getVehicleKey(vehicle, true))
    end
    local liveSql = liveVehicleSqlId(vehicle)
    if liveSql then addUnique(out, seen, "sql:" .. liveSql) end
    local storedSql = storedVehicleSqlId(vehicle)
    if storedSql then addUnique(out, seen, "sql:" .. storedSql) end
    if #out == 0 then
        addUnique(out, seen, CSR_VehicleClaim.getVehicleKey(vehicle, ensureFallback))
    end
    return out
end

local function vehicleScriptName(vehicle)
    if not vehicle or not vehicle.getScript then return "" end
    local sc = vehicle:getScript()
    if not sc or not sc.getName then return "" end
    return tostring(sc:getName() or "")
end

local function vehicleCoord(vehicle, getterName)
    if not vehicle then return 0 end
    local value = 0
    if getterName == "getX" and vehicle.getX then value = vehicle:getX()
    elseif getterName == "getY" and vehicle.getY then value = vehicle:getY()
    elseif getterName == "getZ" and vehicle.getZ then value = vehicle:getZ() end
    return math.floor(tonumber(value) or 0)
end

local function vehicleHasKey(vehicle, wanted)
    if not vehicle or not wanted or wanted == "" then return false end
    local keys = CSR_VehicleClaim.getVehicleKeyCandidates(vehicle, false)
    for i = 1, #keys do
        if keys[i] == wanted then return true end
    end
    return false
end

function CSR_VehicleClaim.getVehicleIdentity(vehicle, ensureFallback)
    local sqlId = CSR_VehicleClaim.getVehicleSqlId(vehicle) or ""
    local key = CSR_VehicleClaim.getVehicleKey(vehicle, ensureFallback) or ""
    return {
        vehicleKey          = key,
        vehicleSqlId        = sqlId,
        vehicleRuntimeId    = "",
        vehicleId           = key,
        vehicleClaimVersion = 2,
        vehicleScript       = vehicleScriptName(vehicle),
        lastVehicleX        = vehicleCoord(vehicle, "getX"),
        lastVehicleY        = vehicleCoord(vehicle, "getY"),
        lastVehicleZ        = vehicleCoord(vehicle, "getZ"),
    }
end

function CSR_VehicleClaim.findLoadedVehicleByKey(vehicleKey)
    if not vehicleKey or vehicleKey == "" then return nil end
    local wanted = tostring(vehicleKey)

    if not getCell then return nil end
    local cell = getCell()
    if not cell or not cell.getVehicles then return nil end
    local vehicles = cell:getVehicles()
    if not vehicles or not vehicles.size or not vehicles.get then return nil end

    local count = tonumber(vehicles:size()) or 0
    for i = 0, count - 1 do
        local vehicle = vehicles:get(i)
        if vehicleHasKey(vehicle, wanted) then
            return vehicle
        end
    end
    return nil
end

function CSR_VehicleClaim.findLoadedVehicleByRow(row)
    if not row or row.kind ~= "vehicle" then return nil end
    local vehicleKey = tostring(row.vehicleKey or "")
    if vehicleKey ~= "" then
        return CSR_VehicleClaim.findLoadedVehicleByKey(vehicleKey)
    end
    return nil
end

local function touchVehicleRow(row, vehicle)
    if not row or not row.id then return end
    if isServer() and CSR_ClaimServer and CSR_ClaimServer.touchVehicleRow then
        CSR_ClaimServer.touchVehicleRow(row.id, vehicle)
    end
end

-- Look up the unified-registry row for this vehicle. Durable keys are checked
-- first. Legacy runtime-id rows are never attached to a live vehicle because
-- the engine can reuse those ids; old per-vehicle modData can still be
-- promoted into a durable CSR/sql key by the server.
registryRowFor = function(vehicle)
    if not vehicle then return nil end
    if not CSR_ClaimRegistry then return nil end

    local candidates = CSR_VehicleClaim.getVehicleKeyCandidates(vehicle, false)
    if CSR_ClaimRegistry.getRowByVehicleKey then
        for i = 1, #candidates do
            local row = CSR_ClaimRegistry.getRowByVehicleKey(candidates[i])
            if row then
                touchVehicleRow(row, vehicle)
                return row
            end
        end
    end

    if isServer() and CSR_ClaimServer and CSR_ClaimServer.promoteLegacyVehicleModData then
        local promoted = CSR_ClaimServer.promoteLegacyVehicleModData(vehicle)
        if promoted then return promoted end
    end

    return nil
end

function CSR_VehicleClaim.getRegistryRow(vehicle)
    return registryRowFor(vehicle)
end

function CSR_VehicleClaim.getBoundClaimKeyId(vehicle)
    local row = registryRowFor(vehicle)
    local rowKeyId = row and tonumber(row.vehicleClaimKeyId) or 0
    if rowKeyId and rowKeyId > 0 then return math.floor(rowKeyId) end
    local data = modDataFor(vehicle)
    local mdKeyId = data and tonumber(data[CLAIM_KEY_ID]) or 0
    if mdKeyId and mdKeyId > 0 then return math.floor(mdKeyId) end
    return 0
end

function CSR_VehicleClaim.getBoundClaimKeyToken(vehicle)
    local row = registryRowFor(vehicle)
    local rowToken = row and tostring(row.vehicleClaimKeyToken or "") or ""
    if rowToken ~= "" then return rowToken end
    local data = modDataFor(vehicle)
    return data and tostring(data[CLAIM_KEY_TOKEN] or "") or ""
end

function CSR_VehicleClaim.isClaimKeyBound(vehicle)
    return CSR_VehicleClaim.getBoundClaimKeyId(vehicle) > 0
        and CSR_VehicleClaim.getBoundClaimKeyToken(vehicle) ~= ""
end

function CSR_VehicleClaim.playerHasClaimKey(player, vehicle)
    if not player or not vehicle then return false end
    if isAdminPlayer(player) then return true end
    if not CSR_VehicleClaim.isClaimKeyBound(vehicle) then return true end

    local row = registryRowFor(vehicle)
    local keyId = CSR_VehicleClaim.getBoundClaimKeyId(vehicle)
    local token = CSR_VehicleClaim.getBoundClaimKeyToken(vehicle)
    if keyId <= 0 or token == "" then return false end

    if vehicle.isKeysInIgnition and vehicle:isKeysInIgnition() then
        return true
    end

    local inv = player.getInventory and player:getInventory() or nil
    if not inv then return false end

    local items = inv.getItems and inv:getItems() or nil
    if not items or not items.size or not items.get then
        if inv.haveThisKeyId then return inv:haveThisKeyId(keyId) == true end
        return false
    end

    local count = tonumber(items:size()) or 0
    for i = 0, count - 1 do
        local item = items:get(i)
        if item and item.getKeyId and tonumber(item:getKeyId()) == keyId then
            local md = item.getModData and item:getModData() or nil
            if md and tostring(md[KEY_ITEM_TOKEN] or "") == token then
                return true
            end
        end
    end
    -- The vanilla inventory helper sees keys in the normal keyring path even
    -- when item modData is not visible yet. Keep token checks strict for
    -- outsiders, but let already-authorized drivers pass with the matching
    -- current key id so owners are not locked out by delayed key-token sync.
    if inv.haveThisKeyId and inv:haveThisKeyId(keyId) == true then
        if row and (rowOwnerMatches(row, player) or rowMemberMatches(row, player)) then
            return true
        end
        if CSR_VehicleClaim.isAllowed and CSR_VehicleClaim.isAllowed(vehicle, player) then
            return true
        end
    end
    return false
end

function CSR_VehicleClaim.isEnabled()
    if not isClient() and not isServer() then return false end
    if not CSR_FeatureFlags or not CSR_FeatureFlags.isVehicleClaimEnabled then return false end
    return CSR_FeatureFlags.isVehicleClaimEnabled()
end

function CSR_VehicleClaim.getOwner(vehicle)
    if not vehicle then return nil end
    local row = registryRowFor(vehicle)
    if not row or not row.owner or row.owner == "" then
        return nil
    end

    -- Durable key rows do not need script matching because the SQL/fallback
    -- key is the identity anchor and scripts can legitimately change across
    -- mod updates. The branch below exists only for defensive cleanup if an
    -- already-loaded save still has a keyless row in memory.
    if (not row.vehicleKey or row.vehicleKey == "") and vehicle.getScript then
        local liveName = vehicleScriptName(vehicle)
        if liveName ~= "" then
            local storedName = row.vehicleScript or ""
            if storedName ~= "" then
                if storedName ~= liveName then
                    if isServer() and CSR_ClaimServer
                            and CSR_ClaimServer.scrubStaleVehicleRow then
                        CSR_ClaimServer.scrubStaleVehicleRow(row.id, storedName, liveName)
                    end
                    return nil
                end
            elseif isServer() and CSR_ClaimServer
                    and CSR_ClaimServer.backfillVehicleScript then
                CSR_ClaimServer.backfillVehicleScript(row.id, liveName)
            end
        end
    end

    return row.owner
end

-- Legacy modData mirror. The registry add/remove is performed by the server.
function CSR_VehicleClaim.setOwner(vehicle, username, row)
    if not vehicle then return end
    local data = modDataFor(vehicle)
    if not data then return end
    data[OWNER_KEY] = username
    data[ALLOWED_KEY] = data[ALLOWED_KEY] or {}
    data[VERSION_KEY] = 2
    data[RELEASED_AT_KEY] = nil

    local identity = row or CSR_VehicleClaim.getVehicleIdentity(vehicle, not isClient())
    if identity then
        if identity.vehicleKey and identity.vehicleKey ~= "" then data[CLAIM_KEY] = identity.vehicleKey end
        if identity.vehicleSqlId and identity.vehicleSqlId ~= "" then data[SQL_ID_KEY] = identity.vehicleSqlId end
        data[RUNTIME_ID_KEY] = nil
    end
    if row and tonumber(row.vehicleClaimKeyId) and tonumber(row.vehicleClaimKeyId) > 0 then
        data[CLAIM_KEY_ID] = math.floor(tonumber(row.vehicleClaimKeyId) or 0)
        data[CLAIM_KEY_TOKEN] = tostring(row.vehicleClaimKeyToken or "")
        data[CLAIM_KEY_OWNER] = tostring(row.ownerSteamID or "")
    end
end

function CSR_VehicleClaim.clearOwner(vehicle)
    if not vehicle then return end
    local data = modDataFor(vehicle)
    if not data then return end
    local identity = CSR_VehicleClaim.getVehicleIdentity(vehicle, false)
    if identity.vehicleKey and identity.vehicleKey ~= "" then data[CLAIM_KEY] = identity.vehicleKey end
    if identity.vehicleSqlId and identity.vehicleSqlId ~= "" then data[SQL_ID_KEY] = identity.vehicleSqlId end
    data[RUNTIME_ID_KEY] = nil
    data[CLAIM_KEY_ID] = nil
    data[CLAIM_KEY_TOKEN] = nil
    data[CLAIM_KEY_OWNER] = nil
    data[OWNER_KEY] = nil
    data[ALLOWED_KEY] = nil
    data[VERSION_KEY] = 2
    data[RELEASED_AT_KEY] = nowTs()
end

function CSR_VehicleClaim.isClaimed(vehicle)
    return CSR_VehicleClaim.getOwner(vehicle) ~= nil
end

function CSR_VehicleClaim.isOwner(vehicle, player)
    if not vehicle or not player then return false end
    local row = registryRowFor(vehicle)
    if row then return rowOwnerMatches(row, player) end
    local owner = CSR_VehicleClaim.getOwner(vehicle)
    if not owner then return false end
    local username = player.getUsername and player:getUsername() or nil
    return username ~= nil and owner == tostring(username)
end

-- Tow-chain walker: collect this vehicle plus anything it tows or is
-- towed by (one hop in each direction is enough — vanilla does not
-- support multi-hop tow chains in B42, but if a future build adds
-- them this still produces a finite set thanks to the visited guard).
local function collectTowChain(vehicle)
    local out = { vehicle }
    if not vehicle then return out end
    local visited = { [tostring(vehicle)] = true }
    local function pushPartner(partnerFn)
        if partnerFn == nil then return end
        local partner = partnerFn()
        if not partner then return end
        local key = tostring(partner)
        if visited[key] then return end
        visited[key] = true
        out[#out + 1] = partner
    end
    pushPartner(vehicle.getVehicleTowing and function() return vehicle:getVehicleTowing() end or nil)
    pushPartner(vehicle.getVehicleTowedBy and function() return vehicle:getVehicleTowedBy() end or nil)
    return out
end

function CSR_VehicleClaim.getTowChain(vehicle)
    return collectTowChain(vehicle)
end

local function isAllowedListed(vehicle, player, username)
    local row = registryRowFor(vehicle)
    if row and rowMemberMatches(row, player) then
        return true
    end

    local data = modDataFor(vehicle)
    local allowed = data and data[ALLOWED_KEY] or {}
    if type(allowed) == "table" then
        for _, name in ipairs(allowed) do
            if name == username then return true end
        end
    end
    return false
end

function CSR_VehicleClaim.isAllowed(vehicle, player)
    if not vehicle or not player then return false end
    -- Walk the tow chain: a trailer attached to a vehicle the player
    -- is allowed on inherits that allowance, and vice versa. This
    -- means claiming the towing vehicle implicitly extends the claim
    -- to whatever trailer is attached for as long as it is attached.
    local chain = collectTowChain(vehicle)
    local username = player:getUsername()
    local access = player.getAccessLevel and player:getAccessLevel() or nil
    local isAdmin = access and (access == "admin" or access == "Admin")

    -- v1.8.34 hardening: faction-membership is NO LONGER an automatic grant.
    -- Faction members must be explicitly added via Manage Authorized Drivers.
    -- Sandbox flag VehicleClaimFactionAutoAllow (default OFF) restores the
    -- legacy permissive behaviour for servers that prefer it.
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    local autoFaction = sb.VehicleClaimFactionAutoAllow == true
    local faction = nil
    if autoFaction and Faction and Faction.getPlayerFaction then
        faction = Faction.getPlayerFaction(player)
    end

    local anyClaimedInChain = false
    for i = 1, #chain do
        local v = chain[i]
        local row = registryRowFor(v)
        local owner = row and row.owner or CSR_VehicleClaim.getOwner(v)
        if owner and owner ~= "" then
            anyClaimedInChain = true
            if row and rowOwnerMatches(row, player) then return true end
            if owner == username then return true end
            if isAdmin then return true end
            if faction then
                if faction.getOwner then
                    local fOwner = faction:getOwner()
                    if fOwner and fOwner == owner then return true end
                end
                if faction.getPlayers then
                    local members = faction:getPlayers()
                    if members and members.size then
                        for j = 0, members:size() - 1 do
                            local m = members:get(j)
                            if m and tostring(m) == owner then return true end
                        end
                    end
                end
            end
            if isAllowedListed(v, player, username) then return true end
        end
    end

    -- Nothing in the chain is owned -> vehicle is open.
    if not anyClaimedInChain then return true end
    return false
end

function CSR_VehicleClaim.addAllowed(vehicle, name)
    if not vehicle or not name then return false end
    local data = modDataFor(vehicle)
    if not data then return false end
    data[ALLOWED_KEY] = data[ALLOWED_KEY] or {}
    for _, n in ipairs(data[ALLOWED_KEY]) do
        if n == name then return false end
    end
    table.insert(data[ALLOWED_KEY], name)
    return true
end

function CSR_VehicleClaim.removeAllowed(vehicle, name)
    if not vehicle or not name then return false end
    local data = modDataFor(vehicle)
    if not data or not data[ALLOWED_KEY] then return false end
    for i, n in ipairs(data[ALLOWED_KEY]) do
        if n == name then
            table.remove(data[ALLOWED_KEY], i)
            return true
        end
    end
    return false
end

function CSR_VehicleClaim.getAllowed(vehicle)
    if not vehicle then return {} end
    local out = {}
    local seen = {}
    local row = registryRowFor(vehicle)
    if row and CSR_ClaimRegistry and CSR_ClaimRegistry.csvList then
        local names = CSR_ClaimRegistry.csvList(row.membersCSV)
        for i = 1, #names do addUnique(out, seen, names[i]) end
    end
    local data = modDataFor(vehicle)
    local allowed = data and data[ALLOWED_KEY] or {}
    if type(allowed) == "table" then
        for _, name in ipairs(allowed) do addUnique(out, seen, name) end
    end
    return out
end

function CSR_VehicleClaim.getClaimCount(username)
    if not username or username == "" then return 0 end
    if not CSR_ClaimRegistry or not CSR_ClaimRegistry.getRowsByOwner then return 0 end
    local rows = CSR_ClaimRegistry.getRowsByOwner(username) or {}
    local n = 0
    for i = 1, #rows do
        if rows[i].kind == "vehicle" then n = n + 1 end
    end
    return n
end

function CSR_VehicleClaim.getMaxClaims()
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    local max = tonumber(sb.MaxVehicleClaims) or 3
    if max < 1 then max = 1 end
    return math.floor(max)
end

return CSR_VehicleClaim
