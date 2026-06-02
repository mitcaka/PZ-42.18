require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/CSRAdapter"
require "CSRAdminCommandCenter/CSRDetector"

local ACC = CSRAdminCommandCenter
ACC.CleanupTracker = ACC.CleanupTracker or {}

local Cleanup = ACC.CleanupTracker

function Cleanup.status()
    local cfg = ACC.CSRAdapter.cleanupConfig()
    local detection = ACC.CSRDetector.detect()
    local nextKnown = false
    local nextText = "Not exposed by current CSR version"

    return {
        detected = detection.modules and detection.modules.groundCleanup == true,
        readOnly = true,
        controlsSupported = false,
        manualTriggerSupported = false,
        pauseSupported = false,
        intervalAdjustSupported = false,
        nextRunKnown = nextKnown,
        nextRunText = nextText,
        config = cfg,
        notes = "MVP reads CSR cleanup settings only. Direct control is disabled until version-specific behavior is tested.",
    }
end

return Cleanup

