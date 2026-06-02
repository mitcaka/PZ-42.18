require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/AdminAccess"
require "CSRAdminCommandCenter/CSRAdapter"
require "CSRAdminCommandCenter/Persistence"
require "CSRAdminCommandCenter/Data/Schemas"
require "CSRAdminCommandCenter/Utils/Time"
require "CSRAdminCommandCenter/Utils/VehicleIdentity"

local ACC = CSRAdminCommandCenter
ACC.VehicleClaimAuthority = ACC.VehicleClaimAuthority or {}

local Authority = ACC.VehicleClaimAuthority

local STORE_KEY = "CSR_ACC_VehicleClaimAuthority_v1"
local STORE_SCHEMA = 1

Authority._startupPending = Authority._startupPending ~= false
Authority._minuteCounter = Authority._minuteCounter or 0

local function sandbox()
    return ACC.sandbox()
end

local function snapshotEnabled()
    return sandbox().EnableVehicleClaimAuthoritySnapshot ~= false
end

local function repairEnabled()
    return false
end

local function restoreMissingEnabled()
    return false
end

local function store()
    local md = nil
    if ModData and ModData.getOrCreate then
        local value = ModData.getOrCreate(STORE_KEY)
        if type(value) == "table" then md = value end
    end
    if not md then
        md = ACC.Persistence.stateTable(ACC.Schemas.Keys.VehicleClaimAuthorityState)
    end
    md.schema = tonumber(md.schema) or STORE_SCHEMA
    md.rows = md.rows or {}
    md.stats = md.stats or {}
    return md
end

local function markDirty()
    -- Keep the authority snapshot server-side; admin clients receive only summaries.
end

local function rowKey(row)
    return ACC.VehicleIdentity.keyForRow(row)
end

local function numberOrZero(value)
    return tonumber(value) or 0
end

local function firstNonEmpty(a, b, c)
    local values = { a, b, c }
    for i = 1, #values do
        local text = tostring(values[i] or "")
        if text ~= "" then return text end
    end
    return ""
end

local function copyRowSnapshot(row)
    local key = rowKey(row)
    if key == "" then return nil end
    local x = numberOrZero(row.lastVehicleX or row.x)
    local y = numberOrZero(row.lastVehicleY or row.y)
    local z = numberOrZero(row.lastVehicleZ or row.z)

    return {
        key = key,
        rowId = tonumber(row.id) or 0,
        kind = "vehicle",
        owner = tostring(row.owner or ""),
        ownerSteamID = tostring(row.ownerSteamID or ""),
        membersCSV = tostring(row.membersCSV or ""),
        rolesCSV = tostring(row.rolesCSV or ""),
        title = tostring(row.title or ""),
        vehicleId = "",
        vehicleKey = tostring(row.vehicleKey or ""),
        vehicleSqlId = "",
        vehicleRuntimeId = "",
        vehicleClaimVersion = tonumber(row.vehicleClaimVersion) or 1,
        vehicleScript = tostring(row.vehicleScript or ""),
        vehicleClaimedAt = tonumber(row.vehicleClaimedAt) or tonumber(row.createdAt) or 0,
        createdAt = tonumber(row.createdAt) or 0,
        lastSeen = tonumber(row.lastSeen) or 0,
        x = x,
        y = y,
        z = z,
        lastVehicleX = x,
        lastVehicleY = y,
        lastVehicleZ = z,
        snapshotAt = ACC.Time.nowSeconds(),
        releasedAt = tonumber(row.releasedAt) or 0,
        missingSince = 0,
    }
end

local function countRows(rows)
    local n = 0
    if type(rows) ~= "table" then return n end
    for _ in pairs(rows) do n = n + 1 end
    return n
end

local function indexCurrentRows(rows)
    local byKey = {}
    local byId = {}
    for i = 1, #rows do
        local row = rows[i]
        local key = rowKey(row)
        if key ~= "" then byKey[key] = row end
        if tonumber(row.id) then byId[tostring(row.id)] = row end
    end
    return byKey, byId
end

local function distanceSq(ax, ay, bx, by)
    local dx = numberOrZero(ax) - numberOrZero(bx)
    local dy = numberOrZero(ay) - numberOrZero(by)
    return dx * dx + dy * dy
end

local function loadedVehicleFor(row, snap)
    return ACC.VehicleIdentity.loadedVehicleFor(row, snap)
end

local function setPatchIfDifferent(patch, row, key, value)
    if value == nil then return end
    if tostring(row[key] or "") ~= tostring(value or "") then
        patch[key] = value
    end
end

local function setNumberPatchIfDifferent(patch, row, key, value)
    local n = tonumber(value)
    if not n then return end
    if numberOrZero(row[key]) ~= n then
        patch[key] = n
    end
end

local function patchHasValues(patch)
    for _ in pairs(patch) do return true end
    return false
end

function Authority.snapshotCurrentRows(reason)
    if not snapshotEnabled() then return 0 end
    local s = store()
    local rows = ACC.CSRAdapter.getVehicleClaimRows()
    local seen = {}
    local now = ACC.Time.nowSeconds()

    for i = 1, #rows do
        local snap = copyRowSnapshot(rows[i])
        if snap then
            s.rows[snap.key] = snap
            seen[snap.key] = true
        end
    end

    for key, snap in pairs(s.rows) do
        if type(snap) == "table" and not seen[key] then
            if not snap.missingSince or tonumber(snap.missingSince) == 0 then
                snap.missingSince = now
                ACC.Persistence.enqueue("authority",
                    "vehicle_claim_authority action=missing_snapshot"
                    .. " key=" .. tostring(key)
                    .. " owner=" .. tostring(snap.owner or ""))
            end
        end
    end

    s.stats.snapshots = (tonumber(s.stats.snapshots) or 0) + 1
    s.stats.lastSnapshotAt = now
    s.stats.rowCount = countRows(s.rows)
    markDirty()
    return #rows
end

function Authority.runRepairPass(reason)
    local s = store()
    s.stats.repairDisabled = true
    s.stats.lastRepairPassAt = ACC.Time.nowSeconds()
    markDirty()
    return 0, 0
end

local function applyReleaseMarker(s, snap, reason, player, id, source)
    if type(s) ~= "table" or type(snap) ~= "table" then return false end
    local wasReleased = tonumber(snap.releasedAt) and tonumber(snap.releasedAt) > 0
    snap.releasedAt = ACC.Time.nowSeconds()
    snap.releasedReason = tostring(reason or "")
    snap.releasedBy = ACC.AdminAccess.usernameFor(player)
    if not wasReleased then
        s.stats.released = (tonumber(s.stats.released) or 0) + 1
    end
    ACC.Persistence.enqueue("authority",
        "vehicle_claim_authority action=release_marker"
        .. " reason=" .. tostring(reason or "")
        .. " id=" .. tostring(id or snap.rowId or "")
        .. " key=" .. tostring(snap.key or "")
        .. " owner=" .. tostring(snap.owner or "")
        .. " by=" .. tostring(snap.releasedBy or "")
        .. " source=" .. tostring(source or ""))
    markDirty()
    return true
end

local function snapshotByDurableKey(s, vehicleKey)
    vehicleKey = tostring(vehicleKey or "")
    if vehicleKey == "" then return nil end
    local snap = s.rows[vehicleKey]
    if type(snap) == "table" then return snap end
    for _, row in pairs(s.rows) do
        if type(row) == "table" and ACC.VehicleIdentity.durableKeyForRow(row) == vehicleKey then
            return row
        end
    end
    return nil
end

function Authority.markReleased(row, reason, player)
    if not snapshotEnabled() or type(row) ~= "table" then return false end
    local snap = copyRowSnapshot(row)
    if not snap then return false end
    local s = store()
    local existing = s.rows[snap.key]
    if type(existing) == "table" then
        for k, v in pairs(snap) do existing[k] = v end
        snap = existing
    else
        s.rows[snap.key] = snap
    end
    return applyReleaseMarker(s, snap, reason, player, row.id, "row")
end

function Authority.markReleasedByVehicleKey(vehicleKey, reason, player)
    if not snapshotEnabled() or not ACC.VehicleIdentity.isDurableKey(vehicleKey) then return false end
    local s = store()
    local snap = snapshotByDurableKey(s, vehicleKey)
    if type(snap) ~= "table" then return false end
    return applyReleaseMarker(s, snap, reason, player, snap.rowId, "vehicleKey")
end

local function rowByDurableKey(vehicleKey)
    vehicleKey = tostring(vehicleKey or "")
    if vehicleKey == "" then return nil end
    if CSR_ClaimRegistry and CSR_ClaimRegistry.getRowByVehicleKey then
        local row = CSR_ClaimRegistry.getRowByVehicleKey(vehicleKey)
        if type(row) == "table" and row.kind == "vehicle" then return row end
    end
    local rows = ACC.CSRAdapter.getVehicleClaimRows()
    for i = 1, #rows do
        local row = rows[i]
        if ACC.VehicleIdentity.durableKeyForRow(row) == vehicleKey then
            return row
        end
    end
    return nil
end

local function addReleaseKey(out, seen, vehicleKey)
    vehicleKey = tostring(vehicleKey or "")
    if not ACC.VehicleIdentity.isDurableKey(vehicleKey) or seen[vehicleKey] then return end
    out[#out + 1] = vehicleKey
    seen[vehicleKey] = true
end

local function releaseRowForArgs(args)
    args = args or {}
    local releaseKeys = {}
    local seenKeys = {}

    local argKey = tostring(args.vehicleKey or "")
    if ACC.VehicleIdentity.isDurableKey(argKey) then
        addReleaseKey(releaseKeys, seenKeys, argKey)
        local row = rowByDurableKey(argKey)
        if row then return row, releaseKeys, "" end
        return nil, releaseKeys, "no_current_row_for_vehicle_key"
    end

    if args.rowId and CSR_ClaimRegistry and CSR_ClaimRegistry.getRowById then
        local row = CSR_ClaimRegistry.getRowById(tonumber(args.rowId))
        if type(row) == "table" and row.kind == "vehicle" then
            local rowKey = ACC.VehicleIdentity.durableKeyForRow(row)
            if rowKey ~= "" then
                addReleaseKey(releaseKeys, seenKeys, rowKey)
                return row, releaseKeys, ""
            end
        end
    end

    if type(args.row) == "table" and args.row.kind == "vehicle"
            and ACC.VehicleIdentity.durableKeyForRow(args.row) ~= "" then
        addReleaseKey(releaseKeys, seenKeys, ACC.VehicleIdentity.durableKeyForRow(args.row))
        return args.row, releaseKeys, ""
    end

    return nil, releaseKeys, "no_durable_release_key"
end

function Authority.observeCSRCommand(module, command, player, args)
    if module ~= "CommonSenseReborn" then return false end
    if command ~= "UnclaimVehicle" then return false end
    args = args or {}
    local row, releaseKeys, skipReason = releaseRowForArgs(args)
    local marked = false
    if row then
        marked = Authority.markReleased(row, "csr_unclaim_vehicle", player) == true
    end

    releaseKeys = releaseKeys or {}
    local rowKey = ACC.VehicleIdentity.durableKeyForRow(row)
    for i = 1, #releaseKeys do
        if releaseKeys[i] ~= rowKey then
            marked = Authority.markReleasedByVehicleKey(releaseKeys[i], "csr_unclaim_vehicle", player) or marked
        end
    end

    if not marked then
        ACC.Persistence.enqueue("authority",
            "vehicle_claim_authority action=release_marker_skipped"
            .. " reason=" .. tostring(skipReason or "no_durable_identity")
            .. " command=" .. tostring(command or "")
            .. " vehicleKey=" .. tostring(args.vehicleKey or "")
            .. " rowId=" .. tostring(args.rowId or ""))
    end
    return true
end

function Authority.onServerStarted()
    Authority._startupPending = false
    Authority._minuteCounter = 0
    if snapshotEnabled() then
        ACC.Persistence.enqueue("authority",
            "vehicle_claim_authority action=startup_ready"
            .. " repair=" .. tostring(repairEnabled())
            .. " restoreMissing=" .. tostring(restoreMissingEnabled()))
    end
end

function Authority.tick()
    -- Intentionally idle: claim authority work is event/admin-request driven.
end

function Authority.summary()
    local s = store()
    local rows = s.rows or {}
    local missing = 0
    local released = 0
    for _, snap in pairs(rows) do
        if type(snap) == "table" then
            if tonumber(snap.missingSince) and tonumber(snap.missingSince) > 0 then missing = missing + 1 end
            if tonumber(snap.releasedAt) and tonumber(snap.releasedAt) > 0 then released = released + 1 end
        end
    end

    return {
        enabled = snapshotEnabled(),
        repairEnabled = repairEnabled(),
        restoreMissingEnabled = restoreMissingEnabled(),
        startupPending = Authority._startupPending == true,
        rows = countRows(rows),
        missing = missing,
        released = released,
        stats = s.stats or {},
        recent = ACC.Persistence.tail("authority", 8),
    }
end

return Authority
