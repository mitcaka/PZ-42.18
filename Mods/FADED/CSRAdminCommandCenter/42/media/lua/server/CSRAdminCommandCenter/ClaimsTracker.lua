require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/CSRAdapter"
require "CSRAdminCommandCenter/Analytics/Aggregates"
require "CSRAdminCommandCenter/Persistence"
require "CSRAdminCommandCenter/Data/Schemas"
require "CSRAdminCommandCenter/Utils/VehicleIdentity"

local ACC = CSRAdminCommandCenter
ACC.ClaimsTracker = ACC.ClaimsTracker or {}

local Claims = ACC.ClaimsTracker
local Keys = ACC.Schemas.Keys

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function rowMatches(row, args)
    if type(row) ~= "table" then return false end
    args = args or {}

    local kind = tostring(args.kind or "")
    if kind ~= "" and kind ~= "all" and row.kind ~= kind then return false end

    local owner = lower(args.owner or "")
    if owner ~= "" and not string.find(lower(row.owner), owner, 1, true) then return false end

    local query = lower(args.query or "")
    if query ~= "" then
        local haystack = lower(table.concat({
            row.id or "",
            row.kind or "",
            row.owner or "",
            row.title or "",
            row.factionName or "",
            row.vehicleKey or "",
            row.vehicleScript or "",
        }, " "))
        if not string.find(haystack, query, 1, true) then return false end
    end

    return true
end

function Claims.buildPage(args)
    args = args or {}
    local rows = ACC.CSRAdapter.getAllClaimRows()
    local filtered = {}
    for i = 1, #rows do
        if rowMatches(rows[i], args) then
            filtered[#filtered + 1] = rows[i]
        end
    end

    local sb = ACC.sandbox()
    local pageSize = ACC.clampNumber(args.pageSize or sb.MaxRowsPerPage, 10, 200, 50)
    local page = math.max(1, tonumber(args.page) or 1)
    local total = #filtered
    local totalPages = math.max(1, math.ceil(total / pageSize))
    if page > totalPages then page = totalPages end

    local startIndex = ((page - 1) * pageSize) + 1
    local endIndex = math.min(total, startIndex + pageSize - 1)
    local pageRows = {}
    for i = startIndex, endIndex do
        pageRows[#pageRows + 1] = filtered[i]
    end

    return {
        rows = pageRows,
        page = page,
        pageSize = pageSize,
        total = total,
        totalPages = totalPages,
        query = tostring(args.query or ""),
        kind = tostring(args.kind or "all"),
        owner = tostring(args.owner or ""),
    }
end

function Claims.summary(rows)
    return ACC.AnalyticsAggregates.claims(rows or ACC.CSRAdapter.getAllClaimRows())
end

function Claims.recentAudit(maxLines)
    return ACC.CSRAdapter.getAuditTail(tonumber(maxLines) or 10)
end

local function claimState()
    return ACC.Persistence.stateTable(Keys.ClaimState)
end

local function rowLogLine(action, row, extra)
    return "vehicle_claim action=" .. tostring(action or "")
        .. " id=" .. tostring(row and row.id or "")
        .. " key=" .. tostring(row and ACC.VehicleIdentity.keyForRow(row) or "")
        .. " owner=" .. tostring(row and row.owner or "")
        .. " title=" .. tostring(row and row.title or "")
        .. " script=" .. tostring(row and row.vehicleScript or "")
        .. " pos=" .. tostring(row and (row.lastVehicleX or row.x) or 0)
        .. "," .. tostring(row and (row.lastVehicleY or row.y) or 0)
        .. "," .. tostring(row and (row.lastVehicleZ or row.z) or 0)
        .. (extra and (" " .. tostring(extra)) or "")
end

function Claims.observeVehicleClaimChanges()
    local state = claimState()
    state.rows = state.rows or {}

    local seen = {}
    local rows = ACC.CSRAdapter.getVehicleClaimRows()
    for i = 1, #rows do
        local row = rows[i]
        local key = ACC.VehicleIdentity.keyForRow(row)
        if key ~= "" then
            seen[key] = true
            local prev = state.rows[key]
            if type(prev) ~= "table" then
                ACC.Persistence.enqueue("claims", rowLogLine("observed", row))
            else
                if tostring(prev.owner or "") ~= tostring(row.owner or "") then
                    ACC.Persistence.enqueue("claims", rowLogLine("owner_changed", row,
                        "previousOwner=" .. tostring(prev.owner or "")))
                end
                if tostring(prev.rowId or "") ~= tostring(row.id or "") then
                    ACC.Persistence.enqueue("claims", rowLogLine("row_id_changed", row,
                        "previousId=" .. tostring(prev.rowId or "")))
                end
            end
            state.rows[key] = {
                rowId = tostring(row.id or ""),
                owner = tostring(row.owner or ""),
                title = tostring(row.title or ""),
                script = tostring(row.vehicleScript or ""),
                x = tonumber(row.lastVehicleX) or tonumber(row.x) or 0,
                y = tonumber(row.lastVehicleY) or tonumber(row.y) or 0,
                z = tonumber(row.lastVehicleZ) or tonumber(row.z) or 0,
            }
        end
    end

    for key, prev in pairs(state.rows) do
        if not seen[key] and type(prev) == "table" then
            ACC.Persistence.enqueue("claims", "vehicle_claim action=missing key=" .. tostring(key)
                .. " previousOwner=" .. tostring(prev.owner or "")
                .. " previousId=" .. tostring(prev.rowId or ""))
            state.rows[key] = nil
        end
    end
end

return Claims
