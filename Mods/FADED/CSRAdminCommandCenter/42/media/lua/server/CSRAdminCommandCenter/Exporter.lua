require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/CSRDetector"
require "CSRAdminCommandCenter/ClaimsTracker"
require "CSRAdminCommandCenter/CleanupTracker"
require "CSRAdminCommandCenter/DebugHooks"
require "CSRAdminCommandCenter/PadlockTracker"
require "CSRAdminCommandCenter/JournalTracker"
require "CSRAdminCommandCenter/VehicleClaimAuthority"
require "CSRAdminCommandCenter/Persistence"
require "CSRAdminCommandCenter/Utils/Time"

local ACC = CSRAdminCommandCenter
ACC.Exporter = ACC.Exporter or {}

local Exporter = ACC.Exporter

function Exporter.exportDiagnostics(playerName)
    local detection = ACC.CSRDetector.detect()
    local claims = ACC.ClaimsTracker.summary()
    local cleanup = ACC.CleanupTracker.status()
    local debugState = ACC.DebugHooks.getState()
    local padlocks = ACC.PadlockTracker.summary()
    local journal = ACC.JournalTracker.summary()
    local authority = ACC.VehicleClaimAuthority.summary()

    local line = "diagnostic_bundle"
        .. " by=" .. tostring(playerName or "")
        .. " csrDetected=" .. tostring(detection.detected == true)
        .. " testBranch=" .. tostring(detection.testBranchActive == true)
        .. " claimsTotal=" .. tostring(claims.total or 0)
        .. " vehicleClaims=" .. tostring(claims.vehicle or 0)
        .. " padlocks=" .. tostring(padlocks.total or 0)
        .. " journalDetected=" .. tostring(journal.detected == true)
        .. " journalSaves=" .. tostring(journal.usage and journal.usage.save or 0)
        .. " authorityRows=" .. tostring(authority.rows or 0)
        .. " authorityRepair=" .. tostring(authority.repairEnabled == true)
        .. " authorityRestoreMissing=" .. tostring(authority.restoreMissingEnabled == true)
        .. " cleanupEnabled=" .. tostring(cleanup.config and cleanup.config.groundCleanupEnabled == true)
        .. " debugVerbose=" .. tostring(debugState.verbose == true)

    ACC.Persistence.enqueue("export", line)
    ACC.Persistence.flush()

    return {
        ok = true,
        message = "Diagnostic summary written to csr_acc_export.log",
        generatedAt = ACC.Time.stamp(),
        summary = line,
    }
end

return Exporter
