require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/AdminAccess"
require "CSRAdminCommandCenter/Persistence"
require "CSRAdminCommandCenter/Data/Schemas"
require "CSRAdminCommandCenter/Utils/Time"

local ACC = CSRAdminCommandCenter
ACC.JournalTracker = ACC.JournalTracker or {}

local Journal = ACC.JournalTracker
local Keys = ACC.Schemas.Keys

local function state()
    local s = ACC.Persistence.stateTable(Keys.JournalState)
    s.usage = s.usage or {
        total = 0,
        get = 0,
        save = 0,
        recover = 0,
        admin = 0,
    }
    s.byUser = s.byUser or {}
    return s
end

local function commandKind(command)
    local sj = rawget(_G, "CSR_SkillJournal")
    local getCmd = sj and sj.CMD_GET or "SkillJournalGet"
    local saveCmd = sj and sj.CMD_SAVE or "SkillJournalSave"
    local recoverCmd = sj and sj.CMD_RECOVER or "SkillJournalRecover"
    local adminCmd = sj and sj.CMD_ADMIN or "SkillJournalAdmin"

    if command == getCmd then return "get" end
    if command == saveCmd then return "save" end
    if command == recoverCmd then return "recover" end
    if command == adminCmd then return "admin" end
    return nil
end

local function safeArg(value, maxLen)
    local text = tostring(value or "")
    maxLen = tonumber(maxLen) or 64
    if string.len(text) > maxLen then
        return string.sub(text, 1, maxLen)
    end
    return text
end

local function countTable(tbl)
    local n = 0
    if type(tbl) ~= "table" then return n end
    for _ in pairs(tbl) do n = n + 1 end
    return n
end

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function csrModDataKey()
    local sj = rawget(_G, "CSR_SkillJournal")
    return tostring((type(sj) == "table" and sj.MODDATA_KEY) or "CSR_SkillJournal_v1")
end

local function ensureCSRStoreShape(md)
    if type(md) ~= "table" then return nil end
    return md
end

local function loadCSRStore()
    if not ModData then return nil, csrModDataKey() end
    local key = csrModDataKey()
    local md = nil
    if ModData.get then
        md = ModData.get(key)
    end
    return ensureCSRStoreShape(md), key
end

local function sortedKeys(tbl)
    local rows = {}
    if type(tbl) ~= "table" then return rows end
    for key, enabled in pairs(tbl) do
        if enabled == true then rows[#rows + 1] = tostring(key or "") end
    end
    table.sort(rows)
    return rows
end

local function rowCounts(row)
    return {
        perks = countTable(row and row.perks),
        recipes = countTable(row and row.recipes),
        media = countTable(row and row.knownMedia),
    }
end

local function sanitizeRow(rowKey, row)
    row = row or {}
    local counts = rowCounts(row)
    return {
        rowKey = tostring(rowKey or ""),
        userName = tostring(row.userName or ""),
        steamId = tostring(row.steamId or ""),
        profession = tostring(row.profession or ""),
        bornTs = tonumber(row.bornTs) or 0,
        lastWrite = tonumber(row.lastWrite) or 0,
        lastWriteRealMs = tonumber(row.lastWriteRealMs) or 0,
        deaths = tonumber(row.deaths) or 0,
        pendingPenalty = tonumber(row.pendingPenalty) or 0,
        version = tonumber(row.version) or 0,
        hasSnapshot = (tonumber(row.lastWrite) or 0) > 0,
        perks = counts.perks,
        recipes = counts.recipes,
        media = counts.media,
    }
end

local function rowMatchesTarget(rowKey, row, target)
    target = lower(trim(target))
    if target == "" then return false end
    if lower(rowKey) == target then return true end
    if lower(row and row.userName) == target then return true end
    if lower(row and row.steamId) == target then return true end
    return false
end

local function clearUsageForNames(names)
    if type(names) ~= "table" then return end
    local s = state()
    if type(s.byUser) ~= "table" then return end
    local lowered = {}
    for name, _ in pairs(names) do
        lowered[lower(name)] = true
    end
    for name, _ in pairs(s.byUser) do
        if lowered[lower(name)] == true then
            s.byUser[name] = nil
        end
    end
end

local function auditAdmin(action, actor, target, changed, detail)
    ACC.Persistence.enqueue("journal",
        "admin_journal action=" .. tostring(action or "")
        .. " actor=" .. tostring(actor or "")
        .. " target=" .. tostring(target or "")
        .. " changed=" .. tostring(tonumber(changed) or 0)
        .. (detail and detail ~= "" and (" " .. tostring(detail)) or ""))
end

local function csrJournalAdmin(player, op, target)
    local server = rawget(_G, "CSR_SkillJournalServer")
    if type(server) ~= "table" or not server.handleAdmin then
        return false, "CSR Skill Journal admin API not detected"
    end
    server.handleAdmin(player, { op = tostring(op or ""), target = tostring(target or "") })
    return true, ""
end

local function topUsers(byUser, maxRows)
    local rows = {}
    if type(byUser) ~= "table" then return rows end
    for user, info in pairs(byUser) do
        if type(info) == "table" then
            rows[#rows + 1] = {
                username = tostring(user or ""),
                total = tonumber(info.total) or 0,
                lastAction = tostring(info.lastAction or ""),
                lastAt = tonumber(info.lastAt) or 0,
            }
        end
    end
    table.sort(rows, function(a, b)
        return (tonumber(a.total) or 0) > (tonumber(b.total) or 0)
    end)
    local out = {}
    maxRows = tonumber(maxRows) or 6
    for i = 1, math.min(maxRows, #rows) do out[#out + 1] = rows[i] end
    return out
end

function Journal.observeClientCommand(module, command, player, args)
    if module ~= "CommonSenseReborn" then return false end
    local kind = commandKind(command)
    if not kind then return false end

    args = args or {}
    local s = state()
    local usage = s.usage
    usage.total = (tonumber(usage.total) or 0) + 1
    usage[kind] = (tonumber(usage[kind]) or 0) + 1
    usage.lastAction = kind
    usage.lastAt = ACC.Time.nowSeconds()

    local user = ACC.AdminAccess.usernameFor(player)
    if user == "" then user = "unknown" end
    local byUser = s.byUser
    byUser[user] = byUser[user] or { total = 0 }
    local row = byUser[user]
    row.total = (tonumber(row.total) or 0) + 1
    row[kind] = (tonumber(row[kind]) or 0) + 1
    row.lastAction = kind
    row.lastAt = usage.lastAt
    row.access = ACC.AdminAccess.accessLevelFor(player)

    local op = safeArg(args.op or "", 48)
    local target = safeArg(args.target or "", 64)
    ACC.Persistence.enqueue("journal",
        "skill_journal action=" .. tostring(kind)
        .. " user=" .. tostring(user)
        .. " steam=" .. tostring(ACC.AdminAccess.steamIdFor(player))
        .. " access=" .. tostring(row.access or "")
        .. (op ~= "" and (" op=" .. op) or "")
        .. (target ~= "" and (" target=" .. target) or ""))
    return true
end

local function readCSRStore()
    local out = {
        modDataKey = "",
        rows = 0,
        snapshots = 0,
        blacklistUsers = 0,
        blacklistPerks = 0,
        latestWrite = 0,
    }

    local md, key = loadCSRStore()
    out.modDataKey = tostring(key or "")
    if type(md) ~= "table" then return out end

    if type(md.rows) == "table" then
        for _, row in pairs(md.rows) do
            if type(row) == "table" then
                out.rows = out.rows + 1
                if tonumber(row.lastWrite) and tonumber(row.lastWrite) > 0 then
                    out.snapshots = out.snapshots + 1
                    if tonumber(row.lastWrite) > out.latestWrite then
                        out.latestWrite = tonumber(row.lastWrite)
                    end
                end
            end
        end
    end

    if type(md.blacklist) == "table" then
        out.blacklistUsers = countTable(md.blacklist.users)
        out.blacklistPerks = countTable(md.blacklist.perks)
    end

    return out
end

function Journal.buildPage(args)
    args = args or {}
    local md, key = loadCSRStore()
    local query = lower(trim(args.query))
    local allRows = {}

    if type(md) == "table" and type(md.rows) == "table" then
        for rowKey, row in pairs(md.rows) do
            if type(row) == "table" then
                local safe = sanitizeRow(rowKey, row)
                local haystack = lower(safe.rowKey .. " " .. safe.userName .. " "
                    .. safe.steamId .. " " .. safe.profession)
                if query == "" or string.find(haystack, query, 1, true) then
                    allRows[#allRows + 1] = safe
                end
            end
        end
    end

    table.sort(allRows, function(a, b)
        local au = lower(a.userName)
        local bu = lower(b.userName)
        if au == bu then return tostring(a.rowKey or "") < tostring(b.rowKey or "") end
        return au < bu
    end)

    local pageSize = ACC.clampNumber(args.pageSize, 8, 40, 18)
    local total = #allRows
    local totalPages = math.max(1, math.ceil(total / pageSize))
    local page = ACC.clampNumber(args.page, 1, totalPages, 1)
    local startIndex = ((page - 1) * pageSize) + 1
    local rows = {}
    for i = startIndex, math.min(total, startIndex + pageSize - 1) do
        rows[#rows + 1] = allRows[i]
    end

    local blacklist = (type(md) == "table" and md.blacklist) or {}
    return {
        rows = rows,
        total = total,
        page = page,
        totalPages = totalPages,
        pageSize = pageSize,
        query = tostring(args.query or ""),
        modDataKey = tostring(key or ""),
        store = readCSRStore(),
        blacklist = {
            users = sortedKeys(blacklist.users),
            perks = sortedKeys(blacklist.perks),
        },
    }
end

local function matchingRowKeys(store, args)
    local rows = {}
    if type(store) ~= "table" or type(store.rows) ~= "table" then return rows end
    args = args or {}
    local rowKey = trim(args.rowKey)
    if rowKey ~= "" and type(store.rows[rowKey]) == "table" then
        rows[#rows + 1] = rowKey
        return rows
    end

    local target = trim(args.target or args.username)
    if target == "" then return rows end
    for key, row in pairs(store.rows) do
        if type(row) == "table" and rowMatchesTarget(key, row, target) then
            rows[#rows + 1] = key
        end
    end
    table.sort(rows)
    return rows
end

function Journal.isEraseAction(action)
    action = tostring(action or "")
    return action == "erasePlayerData" or action == "eraseRow"
end

function Journal.action(player, args)
    args = args or {}
    local action = tostring(args.action or "")
    local target = trim(args.target or args.username)
    local actor = ACC.AdminAccess.usernameFor(player)

    if Journal.isEraseAction(action) then
        if not ACC.AdminAccess.hasDataErase(player) then
            return false, "Admin data erase access required"
        end
        if trim(args.confirm) ~= "ERASE" then
            return false, "Type ERASE in the confirmation box first"
        end
    elseif not ACC.AdminAccess.hasControl(player) then
        return false, "Control access required"
    end

    if action == "erasePlayerData" then
        if target == "" then return false, "Enter a username" end
        local lowered = lower(target)
        if lowered == "*" or lowered == "all" then return false, "Bulk erase is not available from the UI" end
        local ok, msg = csrJournalAdmin(player, "wipe", target)
        if not ok then return false, msg end
        clearUsageForNames({ [target] = true })
        auditAdmin(action, actor, target, 1, "delegated=csr")
        return true, "CSR journal wipe requested for " .. target
    end

    if action == "eraseRow" then
        return false, "CSR does not expose row-specific journal erase; use CSR player wipe instead"
    end

    if action == "clearPenalty" then
        return false, "CSR does not expose clear-penalty journal admin; no direct ModData edit performed"
    end

    if action == "blacklistUser" then
        if target == "" then return false, "Enter a username" end
        local ok, msg = csrJournalAdmin(player, "bl_user_add", target)
        if not ok then return false, msg end
        auditAdmin(action, actor, target, 1)
        return true, "Blacklisted journal user: " .. target
    end

    if action == "unblacklistUser" then
        if target == "" then return false, "Enter a username" end
        local ok, msg = csrJournalAdmin(player, "bl_user_remove", target)
        if not ok then return false, msg end
        auditAdmin(action, actor, target, 1)
        return true, "Removed journal user blacklist: " .. target
    end

    if action == "blacklistPerk" then
        local perk = trim(args.perk or args.target)
        if perk == "" then return false, "Enter a perk type" end
        local ok, msg = csrJournalAdmin(player, "bl_perk_add", perk)
        if not ok then return false, msg end
        auditAdmin(action, actor, perk, 1)
        return true, "Blacklisted journal perk: " .. perk
    end

    if action == "unblacklistPerk" then
        local perk = trim(args.perk or args.target)
        if perk == "" then return false, "Enter a perk type" end
        local ok, msg = csrJournalAdmin(player, "bl_perk_remove", perk)
        if not ok then return false, msg end
        auditAdmin(action, actor, perk, 1)
        return true, "Removed journal perk blacklist: " .. perk
    end

    return false, "Unsupported journal action"
end

function Journal.summary()
    local s = state()
    local csrSandbox = (SandboxVars and SandboxVars.CommonSenseReborn) or {}
    return {
        detected = type(rawget(_G, "CSR_SkillJournal")) == "table",
        server = type(rawget(_G, "CSR_SkillJournalServer")) == "table",
        enabled = csrSandbox.EnableSkillJournal ~= false,
        saveCooldownHours = tonumber(csrSandbox.SkillJournalSaveCooldownHours) or 24,
        recoverAdminOnly = csrSandbox.SkillJournalAdminOnlyRecover == true,
        usage = s.usage or {},
        topUsers = topUsers(s.byUser, 6),
        store = readCSRStore(),
        recent = ACC.Persistence.tail("journal", 8),
    }
end

return Journal
