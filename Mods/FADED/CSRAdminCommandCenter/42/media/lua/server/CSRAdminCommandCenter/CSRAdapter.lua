require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/CSRDetector"
require "CSRAdminCommandCenter/Utils/Time"
require "CSRAdminCommandCenter/Utils/VehicleIdentity"

local ACC = CSRAdminCommandCenter
ACC.CSRAdapter = ACC.CSRAdapter or {}

local Adapter = ACC.CSRAdapter

local function sanitizeRow(row)
    local out = ACC.copyFlat(row)
    out.id = tonumber(out.id) or 0
    out.kind = tostring(out.kind or "")
    out.owner = tostring(out.owner or "")
    out.title = tostring(out.title or "")
    out.factionName = tostring(out.factionName or "")
    out.vehicleId = ""
    out.vehicleKey = tostring(out.vehicleKey or "")
    out.vehicleSqlId = ""
    out.vehicleRuntimeId = ""
    out.vehicleScript = tostring(out.vehicleScript or "")
    out.lastVehicleX = tonumber(out.lastVehicleX) or tonumber(out.x) or 0
    out.lastVehicleY = tonumber(out.lastVehicleY) or tonumber(out.y) or 0
    out.lastVehicleZ = tonumber(out.lastVehicleZ) or tonumber(out.z) or 0
    out.createdAt = tonumber(out.createdAt) or 0
    out.lastSeen = tonumber(out.lastSeen) or 0
    out.vehicleClaimedAt = tonumber(out.vehicleClaimedAt) or 0
    return out
end

local function rowsFromRegistryAPI()
    if not CSR_ClaimRegistry or not CSR_ClaimRegistry.getAllRows then return nil end
    local rows = CSR_ClaimRegistry.getAllRows()
    if type(rows) ~= "table" then return nil end
    local out = {}
    for i = 1, #rows do
        if type(rows[i]) == "table" then out[#out + 1] = sanitizeRow(rows[i]) end
    end
    return out
end

local function sortRows(rows)
    table.sort(rows, function(a, b)
        return (tonumber(a.id) or 0) > (tonumber(b.id) or 0)
    end)
end

local function refreshLiveVehiclePosition(row)
    if type(row) ~= "table" or row.kind ~= "vehicle" then return row end
    local _, ident, conflict = ACC.VehicleIdentity.loadedVehicleFor(row, row)
    if conflict ~= "" or type(ident) ~= "table" then return row end

    local rowKey = ACC.VehicleIdentity.durableKeyForRow(row)
    local identKey = ACC.VehicleIdentity.durableKeyForRow(ident)
    if rowKey ~= "" and identKey ~= "" and rowKey ~= identKey then return row end

    if ident.lastVehicleX ~= nil then row.lastVehicleX = math.floor(tonumber(ident.lastVehicleX) or row.lastVehicleX or 0) end
    if ident.lastVehicleY ~= nil then row.lastVehicleY = math.floor(tonumber(ident.lastVehicleY) or row.lastVehicleY or 0) end
    if ident.lastVehicleZ ~= nil then row.lastVehicleZ = math.floor(tonumber(ident.lastVehicleZ) or row.lastVehicleZ or 0) end
    if ident.vehicleScript and ident.vehicleScript ~= "" then row.vehicleScript = tostring(ident.vehicleScript) end
    if rowKey == "" and identKey ~= "" then row.vehicleKey = identKey end
    return row
end

function Adapter.getAllClaimRows()
    local rows = rowsFromRegistryAPI() or {}
    for i = 1, #rows do refreshLiveVehiclePosition(rows[i]) end
    sortRows(rows)
    return rows
end

function Adapter.getVehicleClaimRows()
    local rows = Adapter.getAllClaimRows()
    local out = {}
    for i = 1, #rows do
        if rows[i].kind == "vehicle" then out[#out + 1] = rows[i] end
    end
    return out
end

function Adapter.getClaimRowById(id)
    id = tonumber(id) or 0
    if id <= 0 then return nil end
    if CSR_ClaimRegistry and CSR_ClaimRegistry.getRowById then
        local row = CSR_ClaimRegistry.getRowById(id)
        if type(row) == "table" then return sanitizeRow(row) end
    end
    local rows = Adapter.getAllClaimRows()
    for i = 1, #rows do
        if tonumber(rows[i].id) == id then return rows[i] end
    end
    return nil
end

local function csvContains(csv, value)
    if not CSR_ClaimRegistry or not CSR_ClaimRegistry.csvContains then return false end
    return CSR_ClaimRegistry.csvContains(csv, value) == true
end

function Adapter.claimAction(player, args)
    args = args or {}
    local action = tostring(args.action or "")
    local id = tonumber(args.id) or 0
    if id <= 0 then return false, "Select a valid claim first" end
    if not CSR_ClaimServer then return false, "CSR claim server API not detected" end

    local row = Adapter.getClaimRowById(id)
    if not row then return false, "Claim not found" end

    if action == "release" then
        if not CSR_ClaimServer.handleReleaseRequest then return false, "CSR release request API not detected" end
        CSR_ClaimServer.handleReleaseRequest(player, { id = id })
        return true, "Release requested through CSR for claim #" .. tostring(id)
    end

    if action == "forceOwner" then
        local newOwner = tostring(args.owner or "")
        if newOwner == "" then return false, "Enter a new owner username" end
        if not CSR_ClaimServer.handleTransferRequest then return false, "CSR transfer API not detected" end
        CSR_ClaimServer.handleTransferRequest(player, { id = id, newOwner = newOwner })
        local updated = Adapter.getClaimRowById(id)
        if updated and tostring(updated.owner or "") == newOwner then
            return true, "Owner changed to " .. newOwner
        end
        return false, "CSR did not change owner; target may need to be a member first"
    end

    if action == "addMember" or action == "removeMember" then
        local target = tostring(args.username or "")
        if target == "" then return false, "Enter a member username" end
        if not CSR_ClaimServer.handleSetRoleRequest then return false, "CSR member role API not detected" end
        local role = tostring(args.role or "member")
        if action == "addMember" then
            CSR_ClaimServer.handleSetRoleRequest(player, {
                id = id,
                username = target,
                role = role ~= "" and role or "member",
            })
        else
            CSR_ClaimServer.handleSetRoleRequest(player, {
                id = id,
                username = target,
                role = "",
            })
        end
        local updated = Adapter.getClaimRowById(id)
        local hasMember = updated and csvContains(updated.membersCSV, target)
        if action == "addMember" and hasMember then return true, "Added " .. target end
        if action == "removeMember" and not hasMember then return true, "Removed " .. target end
        return false, "CSR did not change member state"
    end

    return false, "Unsupported claim action"
end

function Adapter.getAuditTail(maxLines)
    if CSR_ClaimAudit and CSR_ClaimAudit.getTail then
        local lines = CSR_ClaimAudit.getTail(tonumber(maxLines) or 50)
        if type(lines) == "table" then
            local out = {}
            for i = 1, #lines do out[#out + 1] = tostring(lines[i] or "") end
            return out
        end
    end
    return {}
end

function Adapter.onlinePopulation()
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if not players then return 0 end
    if players.size then return tonumber(players:size()) or 0 end
    return 0
end

function Adapter.cleanupConfig()
    local sv = (SandboxVars and SandboxVars.CommonSenseReborn) or {}
    return {
        csrSandboxPresent = SandboxVars and SandboxVars.CommonSenseReborn ~= nil,
        groundCleanupEnabled = sv.EnableGroundCleanup == true,
        groundCleanupMinutes = tonumber(sv.GroundCleanupMinutes) or 1440,
        groundCleanupScanRadius = tonumber(sv.GroundCleanupScanRadius) or 40,
        groundCleanupMaxZ = tonumber(sv.GroundCleanupMaxZ) or 3,
        groundCleanupMaxPerScan = tonumber(sv.GroundCleanupMaxPerScan) or 250,
        logGroundCleanup = sv.LogGroundCleanup ~= false,
        itemWipeSchedulerEnabled = sv.EnableItemWipeScheduler == true,
        itemWipeIntervalMinutes = tonumber(sv.ItemWipeIntervalMinutes) or 360,
        itemWipeWarnMinutes = tonumber(sv.ItemWipeWarnMinutes) or 60,
    }
end

return Adapter
