require "CSRAdminCommandCenter/ACC_Main"

local ACC = CSRAdminCommandCenter
ACC.PopulationRecommendations = ACC.PopulationRecommendations or {}

local Rec = ACC.PopulationRecommendations

Rec.categories = {
    small = { label = "Small", min = 1, max = 10 },
    medium = { label = "Medium", min = 11, max = 30 },
    large = { label = "Large", min = 31, max = 9999 },
}

Rec.byFeature = {
    cleanup = {
        small = {
            text = "Use long cleanup windows and modest scan limits unless loose items are a known issue.",
            settings = "GroundCleanupMinutes 1440, radius 40, max 250",
            risk = "Low",
            performance = "Low server cost",
        },
        medium = {
            text = "Use a moderate cleanup window and keep scan radius conservative around active players.",
            settings = "GroundCleanupMinutes 720, radius 40, max 250-500",
            risk = "Low",
            performance = "Moderate server cost during scan minute",
        },
        large = {
            text = "Prefer shorter but tighter cleanup passes over wide scans. Watch logs after changes.",
            settings = "GroundCleanupMinutes 360-720, radius 30-40, max 500",
            risk = "Medium",
            performance = "Potential spike if radius or max-per-scan is too high",
        },
    },
    vehicleTracking = {
        small = {
            text = "Frequent claimed-vehicle checks are acceptable if movement threshold is not tiny.",
            settings = "Interval 3-5 minutes, threshold 10-15 tiles",
            risk = "Low",
            performance = "Low",
        },
        medium = {
            text = "Keep tracking interval moderate and avoid live-marker spam.",
            settings = "Interval 5 minutes, threshold 20-25 tiles",
            risk = "Low",
            performance = "Low to moderate",
        },
        large = {
            text = "Track claimed vehicles only and raise thresholds to reduce log churn.",
            settings = "Interval 10 minutes, threshold 30+ tiles",
            risk = "Medium",
            performance = "Moderate if many claims exist",
        },
    },
    debug = {
        small = {
            text = "Temporary verbose sessions are usually fine for reproductions.",
            settings = "Verbose only during active troubleshooting",
            risk = "Low",
            performance = "Low unless left on",
        },
        medium = {
            text = "Prefer error-only logging until reproducing a targeted issue.",
            settings = "Error-only default, granular verbose toggle",
            risk = "Medium",
            performance = "Moderate if verbose",
        },
        large = {
            text = "Use short debug sessions and export bundles; avoid always-on verbose logs.",
            settings = "Error-only default, temporary sessions",
            risk = "Medium",
            performance = "Can grow logs quickly",
        },
    },
    map = {
        small = {
            text = "Showing a small set of claimed vehicle markers is acceptable.",
            settings = "Marker limit 25-50",
            risk = "Low",
            performance = "Low",
        },
        medium = {
            text = "Filter by owner or vehicle type before showing markers.",
            settings = "Marker limit 50",
            risk = "Low",
            performance = "Low to moderate",
        },
        large = {
            text = "Default to selected vehicle only; use filtered marker views.",
            settings = "Marker limit 50-75 with filters",
            risk = "Medium",
            performance = "Moderate if too many markers are visible",
        },
    },
}

function Rec.categoryFor(playerCount)
    local n = tonumber(playerCount) or 0
    if n <= 10 then return "small" end
    if n <= 30 then return "medium" end
    return "large"
end

function Rec.get(featureKey, playerCount)
    local category = Rec.categoryFor(playerCount)
    local feature = Rec.byFeature[featureKey] or Rec.byFeature.cleanup
    return feature[category], category
end

return Rec

