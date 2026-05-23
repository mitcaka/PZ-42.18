--[[
    CSR_ClaimAudit.lua
    -------------------------------------------------------------------------
    v1.8.35 -- audit log writer for the CSR claims system. Captures every
    mutation to a persistent file (Logs/csr_claims_audit.txt) AND a rolling
    in-memory tail stored on the GameTime modData (CSR_Claims_AuditTail) so
    the admin / owner UI can render it without filesystem access.

    Records:
      claim_create, claim_release, claim_transfer, claim_transfer_faction,
      member_invite, member_invite_accept, member_invite_decline,
      member_kick, role_change, highlight_toggle, raid_violation,
      faction_dissolved, vehicle_violation

    Flat-line format -- safe to grep:
      [YYYY-MM-DD HH:MM:SS] [event] cid=<id> kind=<k> by=<user> sid=<steamid> target=<u> data=<csv>

    Hard rules:
      * Server-only file writes (via getFileWriter / writeln).
      * In-mem tail capped at 200 lines (oldest dropped).
      * Audit feature gated by sandbox ClaimAuditLog (default ON).
--]]

-- MP-only: skip in single-player so no audit file is created on the local game.
if not isClient and not isServer then return end
if not isClient() and not isServer() then return end

CSR_ClaimAudit = CSR_ClaimAudit or {}

local LOG_FILE  = "csr_claims_audit.txt"
local TAIL_KEY  = "CSR_Claims_AuditTail"
local TAIL_MAX  = 200

local function nowStamp()
    if os and os.date then
        local s = os.date("%Y-%m-%d %H:%M:%S")
        if s then return s end
    end
    if getGameTime then
        local gt = getGameTime()
        if gt and gt.getTimeOfDay then
            local h = math.floor(tonumber(gt:getTimeOfDay()) or 0)
            local d = (gt.getNightsSurvived and tonumber(gt:getNightsSurvived())) or 0
            return string.format("D%03d %02d:00", d, h)
        end
    end
    return "(no-time)"
end

local function modDataRoot()
    if not getGameTime then return nil end
    local gt = getGameTime()
    if not gt or not gt.getModData then return nil end
    return gt:getModData()
end

local function steamIdFor(playerObj)
    if not playerObj or type(playerObj) ~= "userdata" then return "" end
    if playerObj.getSteamID then
        local sid = playerObj:getSteamID()
        if sid then
            local s = tostring(sid)
            if s ~= "" and s ~= "0" then return s end
        end
    end
    return ""
end

local function csvify(t)
    if type(t) ~= "table" then return tostring(t or "") end
    local out = {}
    for k, v in pairs(t) do
        local key = tostring(k)
        local val = tostring(v or "")
        val = val:gsub("[\r\n,]", " ")
        out[#out + 1] = key .. "=" .. val
    end
    return table.concat(out, " ")
end

local function auditEnabled()
    local sb = (SandboxVars and SandboxVars.CommonSenseReborn) or nil
    if not sb then return true end
    if sb.ClaimAuditLog == false then return false end
    return true
end

local function appendTail(line)
    local root = modDataRoot()
    if not root then return end
    -- Stored as flat key/value pairs to survive Java serialization. The
    -- tail itself is a numbered set of strings: <KEY>_n = "line".
    local idx = tonumber(root[TAIL_KEY .. "_idx"]) or 0
    idx = idx + 1
    if idx > TAIL_MAX then idx = 1 end
    root[TAIL_KEY .. "_" .. tostring(idx)] = tostring(line)
    root[TAIL_KEY .. "_idx"] = idx
    if (tonumber(root[TAIL_KEY .. "_count"]) or 0) < TAIL_MAX then
        root[TAIL_KEY .. "_count"] = (tonumber(root[TAIL_KEY .. "_count"]) or 0) + 1
    end
end

function CSR_ClaimAudit.getTail(maxLines)
    local out = {}
    local root = modDataRoot()
    if not root then return out end
    local count = tonumber(root[TAIL_KEY .. "_count"]) or 0
    if count == 0 then return out end
    local idx = tonumber(root[TAIL_KEY .. "_idx"]) or 0
    maxLines = math.min(tonumber(maxLines) or count, count)
    -- Walk backward from idx for maxLines entries.
    for i = 0, maxLines - 1 do
        local n = idx - i
        if n <= 0 then n = n + TAIL_MAX end
        local line = root[TAIL_KEY .. "_" .. tostring(n)]
        if line then out[#out + 1] = tostring(line) end
    end
    return out
end

-- Write to disk (server-side). Best-effort: file handle errors are silent.
local function writeFile(line)
    if not isServer() then return end
    if not getFileWriter then return end
    -- Audit logging must never abort the claim mutation it is recording.
    pcall(function()
        local writer = getFileWriter(LOG_FILE, true, true)
        if writer then
            writer:write(line .. "\r\n")
            writer:close()
        end
    end)
end

-- Public API: log an event. `actor` is the player or username triggering it.
function CSR_ClaimAudit.log(event, row, actor, target, data)
    if not auditEnabled() then return end
    local actorName = ""
    local sid = ""
    if type(actor) == "string" then
        actorName = actor
    elseif type(actor) == "userdata" then
        if actor.getUsername then
            local u = actor:getUsername()
            if u then actorName = tostring(u) end
        end
        sid = steamIdFor(actor)
    end
    local cid  = (row and row.id) or ""
    local kind = (row and row.kind) or ""
    local line = string.format("[%s] [%s] cid=%s kind=%s by=%s sid=%s target=%s data=%s",
        nowStamp(),
        tostring(event or "?"),
        tostring(cid),
        tostring(kind),
        tostring(actorName or ""),
        tostring(sid or ""),
        tostring(target or ""),
        csvify(data))
    writeFile(line)
    appendTail(line)
end

-- Server-side bridge: client requests the recent tail.
function CSR_ClaimAudit.handleAuditQuery(player, args)
    if not player then return end
    local maxLines = math.min(tonumber(args and args.max) or 50, TAIL_MAX)
    local lines = CSR_ClaimAudit.getTail(maxLines)
    -- Send the tail back as a single command. Lines are concatenated with
    -- "|" -- safer than embedded newlines (modData serializer mangles them).
    -- Newlines inside individual entries are stripped at write-time so this
    -- delimiter is safe.
    sendServerCommand(player, "CommonSenseReborn", "CSR_ClaimAuditTail", {
        text = table.concat(lines, "|"),
        count = #lines,
    })
end

-- Server-side dispatch table merge target.
CSR_ClaimAudit.DISPATCH = {
    CSR_ClaimAuditQuery = CSR_ClaimAudit.handleAuditQuery,
}

return CSR_ClaimAudit
