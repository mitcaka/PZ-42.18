require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/CSRAdapter"
require "CSRAdminCommandCenter/Analytics/Aggregates"

local ACC = CSRAdminCommandCenter
ACC.AnalyticsTracker = ACC.AnalyticsTracker or {}

local Analytics = ACC.AnalyticsTracker

function Analytics.build(rows)
    rows = rows or ACC.CSRAdapter.getAllClaimRows()
    local claims = ACC.AnalyticsAggregates.claims(rows)
    return {
        claims = claims,
        population = ACC.CSRAdapter.onlinePopulation(),
    }
end

return Analytics
