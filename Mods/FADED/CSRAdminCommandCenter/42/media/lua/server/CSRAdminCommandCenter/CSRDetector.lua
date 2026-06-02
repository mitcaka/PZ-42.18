require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/Utils/Time"

local ACC = CSRAdminCommandCenter
ACC.CSRDetector = ACC.CSRDetector or {}

local Detector = ACC.CSRDetector

local function activeMods()
    local out = {}
    if not getActivatedMods then return out end
    local mods = getActivatedMods()
    if not mods then return out end
    local size = 0
    if mods.size then size = tonumber(mods:size()) or 0 end
    for i = 0, size - 1 do
        local modId = nil
        if mods.get then modId = mods:get(i) end
        if modId then out[tostring(modId)] = true end
    end
    return out
end

local function tableHasFunction(tbl, key)
    return type(tbl) == "table" and type(tbl[key]) == "function"
end

local function csrSandbox()
    return (SandboxVars and SandboxVars.CommonSenseReborn) or nil
end

function Detector.detect()
    local mods = activeMods()
    local sv = csrSandbox()

    local modules = {
        claimRegistry = type(CSR_ClaimRegistry) == "table",
        claimServer = type(CSR_ClaimServer) == "table",
        claimAudit = type(CSR_ClaimAudit) == "table",
        vehicleClaim = type(CSR_VehicleClaim) == "table",
        padlockServer = type(CSR_PadlockServer) == "table",
        skillJournal = type(CSR_SkillJournal) == "table",
        skillJournalServer = type(CSR_SkillJournalServer) == "table",
        groundCleanup = type(CSR_GroundCleanup) == "table",
        featureFlags = type(CSR_FeatureFlags) == "table",
    }

    local api = {
        getAllClaims = tableHasFunction(CSR_ClaimRegistry, "getAllRows"),
        getVehicleClaims = tableHasFunction(CSR_ClaimRegistry, "getRowsByKind"),
        vehicleIdentity = tableHasFunction(CSR_VehicleClaim, "getVehicleIdentity"),
        vehicleOwner = tableHasFunction(CSR_VehicleClaim, "getOwner"),
        padlockRemove = tableHasFunction(CSR_PadlockServer, "handleRemove"),
        padlockBreak = tableHasFunction(CSR_PadlockServer, "handleBreak"),
        skillJournalGet = tableHasFunction(CSR_SkillJournalServer, "handleGet"),
        skillJournalSave = tableHasFunction(CSR_SkillJournalServer, "handleSave"),
        skillJournalRecover = tableHasFunction(CSR_SkillJournalServer, "handleRecover"),
        skillJournalAdmin = tableHasFunction(CSR_SkillJournalServer, "handleAdmin"),
        cleanupScan = tableHasFunction(CSR_GroundCleanup, "scan"),
        auditTail = tableHasFunction(CSR_ClaimAudit, "getTail"),
    }

    local detected = mods.CommonSenseReborn == true
        or sv ~= nil
        or modules.claimRegistry
        or modules.vehicleClaim
        or modules.groundCleanup

    local sandboxSummary = {}
    if sv then
        sandboxSummary.EnableVehicleClaim = sv.EnableVehicleClaim == true
        sandboxSummary.EnableCSRClaimsOverride = sv.EnableCSRClaimsOverride == true
        sandboxSummary.EnableVehicleClaimEnforcementStrict = sv.EnableVehicleClaimEnforcementStrict == true
        sandboxSummary.ClaimAuditLog = sv.ClaimAuditLog ~= false
        sandboxSummary.ClaimPadlockEnabled = sv.ClaimPadlockEnabled ~= false
        sandboxSummary.ClaimPadlockBreakSeconds = tonumber(sv.ClaimPadlockBreakSeconds) or 0
        sandboxSummary.EnableSkillJournal = sv.EnableSkillJournal ~= false
        sandboxSummary.SkillJournalSaveCooldownHours = tonumber(sv.SkillJournalSaveCooldownHours) or 0
        sandboxSummary.SkillJournalAdminOnlyRecover = sv.SkillJournalAdminOnlyRecover == true
        sandboxSummary.EnableGroundCleanup = sv.EnableGroundCleanup == true
        sandboxSummary.GroundCleanupMinutes = tonumber(sv.GroundCleanupMinutes) or 0
        sandboxSummary.EnableItemWipeScheduler = sv.EnableItemWipeScheduler == true
        sandboxSummary.ItemWipeIntervalMinutes = tonumber(sv.ItemWipeIntervalMinutes) or 0
    end

    return {
        detected = detected == true,
        limitedMode = detected ~= true,
        activeMod = mods.CommonSenseReborn == true,
        testBranchActive = mods.CommonSenseRebornTest == true,
        warning = detected and "" or "CSR was not detected. Admin Command Center is running in limited mode.",
        modules = modules,
        api = api,
        sandbox = sandboxSummary,
        checkedAt = ACC.Time.nowSeconds(),
        checkedAtText = ACC.Time.stamp(),
    }
end

return Detector
