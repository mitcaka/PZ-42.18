require "CSRAdminCommandCenter/ACC_Main"

local ACC = CSRAdminCommandCenter
ACC.AnalyticsAggregates = ACC.AnalyticsAggregates or {}

local Aggregates = ACC.AnalyticsAggregates

local function inc(tbl, key, amount)
    key = tostring(key or "")
    if key == "" then key = "unknown" end
    tbl[key] = (tonumber(tbl[key]) or 0) + (tonumber(amount) or 1)
end

local function topN(tbl, n)
    local rows = {}
    for key, count in pairs(tbl or {}) do
        rows[#rows + 1] = { key = key, count = count }
    end
    table.sort(rows, function(a, b)
        if a.count == b.count then return tostring(a.key) < tostring(b.key) end
        return a.count > b.count
    end)
    local out = {}
    local limit = math.min(tonumber(n) or 10, #rows)
    for i = 1, limit do out[#out + 1] = rows[i] end
    return out
end

function Aggregates.claims(rows)
    local summary = {
        total = 0,
        vehicle = 0,
        personal = 0,
        faction = 0,
        byOwner = {},
        byVehicleScript = {},
    }

    if type(rows) ~= "table" then return summary end
    for i = 1, #rows do
        local row = rows[i]
        if type(row) == "table" then
            summary.total = summary.total + 1
            local kind = tostring(row.kind or "unknown")
            summary[kind] = (tonumber(summary[kind]) or 0) + 1
            inc(summary.byOwner, row.owner, 1)
            if kind == "vehicle" then
                inc(summary.byVehicleScript, row.vehicleScript ~= "" and row.vehicleScript or row.title, 1)
            end
        end
    end

    summary.topOwners = topN(summary.byOwner, 8)
    summary.topVehicleScripts = topN(summary.byVehicleScript, 8)
    return summary
end

return Aggregates

