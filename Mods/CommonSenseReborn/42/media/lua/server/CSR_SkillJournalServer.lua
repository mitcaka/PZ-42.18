--[[
    CSR_SkillJournalServer.lua

    Server handlers for the Skill Journal feature.  Stores per-character
    snapshots of perk levels, learned recipes and read magazines under
    a single global SModData key (CSR_SkillJournal_v1).

    Wired through CSR_ServerCommands' onClientCommand dispatcher; see
    CSR_ServerCommands.handleSkillJournal at the bottom of this file.

    Defensive notes
    ---------------
    * Perks.FromString may return nil for perks that have been
      removed by other mods between save and recover -- always nil-guard.
    * player:getSteamID() returns "0" or empty in solo / offline; we fall
      back to a username + worldname slot in CSR_SkillJournal.getRowKey.
    * One row per (Steam-ID, character-slot).  No nested arrays so the
      Java SModData serializer is happy.
]]

if not isServer() and (isClient and isClient()) then
    -- file is required from server context; client require is a no-op
    return
end

require "CSR_SkillJournal"
require "CSR_FeatureFlags"

CSR_SkillJournalServer = CSR_SkillJournalServer or {}
local Server = CSR_SkillJournalServer

Server._writing = Server._writing or {}      -- per-row mutex
Server._lastReq = Server._lastReq or {}      -- per-username cooldown

local function nowMs()
    if getTimestampMs then return getTimestampMs() end
    return (os and os.time and os.time() * 1000) or 0
end

local function gameHours()
    if getGameTime and getGameTime() and getGameTime().getWorldAgeHours then
        return tonumber(getGameTime():getWorldAgeHours()) or 0
    end
    return 0
end

local function sb()
    return SandboxVars and SandboxVars.CommonSenseReborn or {}
end

local function configuredDeathPenalty()
    local n = tonumber(sb().SkillJournalDeathPenalty)
    if n == nil then n = 1 end
    n = math.floor(n)
    if n < 0 then n = -n end
    if n > 99 then n = 99 end
    return n
end

local function normalizePendingPenalty(value)
    local n = math.floor(tonumber(value) or 0)
    if n < 0 then n = -n end
    if n > 99 then n = 99 end
    return n
end

local function isAdmin(player)
    if not player then return false end
    if player.getAccessLevel then
        local lvl = tostring(player:getAccessLevel() or "")
        if lvl == "Admin" or lvl == "Moderator" or lvl == "GM" or lvl == "Overseer" then
            return true
        end
    end
    return false
end

local function loadStore()
    local md = ModData.getOrCreate(CSR_SkillJournal.MODDATA_KEY)
    if type(md) ~= "table" then
        md = {}
        ModData.add(CSR_SkillJournal.MODDATA_KEY, md)
    end
    if md.schema == nil then md.schema = CSR_SkillJournal.SCHEMA_VERSION end
    if type(md.rows) ~= "table" then md.rows = {} end
    if type(md.blacklist) ~= "table" then md.blacklist = {} end
    if type(md.blacklist.users) ~= "table" then md.blacklist.users = {} end
    if type(md.blacklist.perks) ~= "table" then md.blacklist.perks = {} end

    -- Schema v1 -> v2 migration: re-key rows from steamId::slothash to
    -- steamId::lower(userName) so Recover works after character death.
    -- The old slot hash was stamped into IsoPlayer modData which is wiped
    -- on respawn; the new key only depends on persistent identity.
    if (tonumber(md.schema) or 0) < 2 then
        print("[CSR][SkillJournal] migrating store schema v1 -> v2")
        local newRows = {}
        local migrated, dropped = 0, 0
        for oldKey, row in pairs(md.rows) do
            if type(row) == "table" then
                local steamId = tostring(row.steamId or "")
                if steamId == "0" then steamId = "" end
                local userName = tostring(row.userName or "")
                local id = (steamId ~= "") and steamId or (userName .. "/?")
                local newKey = id .. "::" .. string.lower(userName)
                local existing = newRows[newKey]
                if existing == nil
                   or (tonumber(row.lastWrite) or 0) > (tonumber(existing.lastWrite) or 0) then
                    newRows[newKey] = row
                    migrated = migrated + 1
                else
                    dropped = dropped + 1
                end
            end
        end
        md.rows = newRows
        md.schema = 2
        print(string.format("[CSR][SkillJournal] migration done: kept=%d dropped=%d",
            migrated, dropped))
        pcall(function() ModData.transmit(CSR_SkillJournal.MODDATA_KEY) end)
    end

    -- Schema v2 -> v3 migration: backfill `profession` and `lastWriteRealMs`
    -- so the profession-lock + real-world cooldown checks have safe defaults
    -- on existing rows.  Empty profession means "unlocked until next Save".
    if (tonumber(md.schema) or 0) < 3 then
        print("[CSR][SkillJournal] migrating store schema v2 -> v3")
        for _, row in pairs(md.rows) do
            if type(row) == "table" then
                if row.profession == nil then row.profession = "" end
                if row.lastWriteRealMs == nil then row.lastWriteRealMs = 0 end
            end
        end
        md.schema = 3
        pcall(function() ModData.transmit(CSR_SkillJournal.MODDATA_KEY) end)
    end

    return md
end

local function isUserBlacklisted(store, userName)
    if not store or not userName or userName == "" then return false end
    local key = string.lower(tostring(userName))
    return store.blacklist.users[key] == true
end

local function isPerkBlacklisted(store, typeStr)
    if not store or not typeStr then return false end
    return store.blacklist.perks[tostring(typeStr)] == true
end

local function pushBlacklist(player)
    local store = loadStore()
    local users, perks = {}, {}
    for k, v in pairs(store.blacklist.users) do if v then table.insert(users, k) end end
    for k, v in pairs(store.blacklist.perks) do if v then table.insert(perks, k) end end
    table.sort(users); table.sort(perks)
    if not isClient() and CSR_SkillJournalPanel and CSR_SkillJournalPanel.blWindow
       and CSR_SkillJournalPanel.blWindow.applyLists then
        CSR_SkillJournalPanel.blWindow:applyLists(users, perks)
        return
    end
    sendServerCommand(player, "CommonSenseReborn", CSR_SkillJournal.PUSH_BLACKLIST, {
        users = users,
        perks = perks,
    })
end

local function flush()
    pcall(function() ModData.transmit(CSR_SkillJournal.MODDATA_KEY) end)
end

local function getRow(player, createIfMissing)
    local key, steamId, userName = CSR_SkillJournal.getRowKey(player)
    if not key then return nil, nil end
    local store = loadStore()
    local row = store.rows[key]
    if not row and createIfMissing then
        row = CSR_SkillJournal.newRow(steamId, userName)
        row.bornTs = gameHours()
        store.rows[key] = row
    end
    return row, key, store
end

local function sendResult(player, ok, text, extra)
    print(string.format("[CSR][SkillJournal] sendResult ok=%s text=%s", tostring(ok), tostring(text)))
    -- In SP, sendServerCommand is a no-op and Events.OnServerCommand never
    -- fires, so route the push directly into the client-side panel handler.
    if not isClient() and CSR_SkillJournalPanel then
        local UI = CSR_SkillJournalPanel
        if UI.window then UI.window.statusText = tostring(text or "") end
        if UI.blWindow then UI.blWindow.statusText = tostring(text or "") end
        return
    end
    sendServerCommand(player, "CommonSenseReborn", CSR_SkillJournal.PUSH_RESULT, {
        ok = ok and true or false,
        text = tostring(text or ""),
        extra = extra,
    })
end

local function sendState(player, row)
    -- Build a small client-view payload (avoid sending everything).
    local view = {
        hasSnapshot = row ~= nil and row.lastWrite > 0,
        perks       = {},
        recipes     = 0,
        media       = 0,
        bornTs      = row and row.bornTs or 0,
        lastWrite   = row and row.lastWrite or 0,
        lastWriteRealMs = row and row.lastWriteRealMs or 0,
        profession  = row and row.profession or "",
        currentProfession = CSR_SkillJournal.getProfession(player),
        deaths      = row and row.deaths or 0,
        pendingPenalty = row and normalizePendingPenalty(row.pendingPenalty) or 0,
        gameHours   = gameHours(),
        nowMs       = nowMs(),
        cooldown    = tonumber(sb().SkillJournalSaveCooldownHours) or 24,
        realCooldown = tonumber(sb().SkillJournalRealHoursCooldown) or 24,
        deathPenalty = configuredDeathPenalty(),
        professionLock = sb().SkillJournalProfessionLock ~= false,
        minHours    = tonumber(sb().SkillJournalMinPlayHours) or 24,
        adminOnly   = sb().SkillJournalAdminOnlyRecover == true,
    }
    if row and row.perks then
        for typ, p in pairs(row.perks) do
            view.perks[typ] = { lvl = p.lvl or 0, xp = p.xp or 0 }
        end
    end
    if row and row.recipes then
        for _ in pairs(row.recipes) do view.recipes = view.recipes + 1 end
    end
    if row and row.knownMedia then
        for _ in pairs(row.knownMedia) do view.media = view.media + 1 end
    end
    print(string.format("[CSR][SkillJournal] sendState perks=%d recipes=%d media=%d hasSnapshot=%s", (function() local n=0; for _ in pairs(view.perks) do n=n+1 end; return n end)(), view.recipes, view.media, tostring(view.hasSnapshot)))
    if not isClient() and CSR_SkillJournalPanel then
        if CSR_SkillJournalPanel.window and CSR_SkillJournalPanel.window.applyState then
            CSR_SkillJournalPanel.window:applyState(view)
        end
        return
    end
    sendServerCommand(player, "CommonSenseReborn", CSR_SkillJournal.PUSH_STATE, view)
end

local function checkCooldown(player)
    local name = player and player.getUsername and player:getUsername() or "?"
    local last = Server._lastReq[name] or 0
    local now = nowMs()
    if now - last < CSR_SkillJournal.REQUEST_COOLDOWN_MS then
        return false
    end
    Server._lastReq[name] = now
    return true
end

-- ---------------------------------------------------------------------
-- Snapshot capture from a live player
-- ---------------------------------------------------------------------
local function capturePerks(player, row)
    if not player or not row then return 0 end
    local count = 0
    row.perks = {}
    if not PerkFactory or not PerkFactory.PerkList then return 0 end
    local list = PerkFactory.PerkList
    if not list or not list.size then return 0 end
    local store = loadStore()
    for i = 0, list:size() - 1 do
        local perk = list:get(i)
        if perk then
            local typeStr = perk.getType and tostring(perk:getType()) or nil
            local parent  = perk.getParent and perk:getParent() or nil
            if typeStr and parent and tostring(parent) ~= "None" and typeStr ~= "None"
               and not isPerkBlacklisted(store, typeStr) then
                local lvl = player:getPerkLevel(perk) or 0
                local xp  = player:getXp():getXP(perk) or 0
                if lvl > 0 or xp > 0 then
                    row.perks[typeStr] = { lvl = tonumber(lvl) or 0, xp = tonumber(xp) or 0 }
                    count = count + 1
                end
            end
        end
    end
    return count
end

local function captureRecipes(player, row)
    row.recipes = {}
    if not player or not player.getKnownRecipes then return 0 end
    local known = player:getKnownRecipes()
    if not known or not known.size then return 0 end
    local n = 0
    for i = 0, known:size() - 1 do
        local r = known:get(i)
        if r then
            row.recipes[tostring(r)] = true
            n = n + 1
        end
    end
    return n
end

local function captureMedia(player, row)
    row.knownMedia = {}
    if not player or not player.getKnownMediaTypes then return 0 end
    local m = player:getKnownMediaTypes()
    if not m or not m.size then return 0 end
    local n = 0
    for i = 0, m:size() - 1 do
        local id = m:get(i)
        if id then
            row.knownMedia[tostring(id)] = true
            n = n + 1
        end
    end
    return n
end

-- ---------------------------------------------------------------------
-- Snapshot apply (recovery)
-- ---------------------------------------------------------------------
local function applyPerks(player, row, penalty)
    if not player or not row or not row.perks then return 0 end
    penalty = normalizePendingPenalty(penalty)
    local applied = 0
    local store = loadStore()
    for typeStr, snap in pairs(row.perks) do
        if isPerkBlacklisted(store, typeStr) then
            -- skip; admin disallowed restoring this perk
        else
        -- Perks.FromString returns nil only when another mod removed the
        -- perk between snapshot and recover; that is the one legitimate
        -- nil case so we test for it explicitly instead of swallowing.
        local perk = Perks.FromString(typeStr)
        if perk then
            local perkObj = PerkFactory.getPerk(perk)
            local snapLvl = tonumber(snap.lvl) or 0
            local snapXp  = tonumber(snap.xp) or 0
            local targetLvl = math.max(0, snapLvl - penalty)
            local targetXp  = snapXp
            if penalty > 0 and targetLvl < snapLvl and perkObj then
                targetXp = tonumber(perkObj:getTotalXpForLevel(targetLvl)) or 0
            end
            local curXp = player:getXp():getXP(perk) or 0
            local diff = targetXp - curXp
            if diff > 0 then
                player:getXp():AddXP(perk, diff, false, false, true)
            elseif diff < 0 then
                player:getXp():setXPToLevel(perk, targetLvl)
            end
            applied = applied + 1
        end
        end -- isPerkBlacklisted else
    end
    return applied
end

local function applyRecipes(player, row)
    if not player or not row or not row.recipes then return 0 end
    local n = 0
    for r, _ in pairs(row.recipes) do
        local has = player.isRecipeActuallyKnown
            and player:isRecipeActuallyKnown(r) == true
            or false
        if not has then
            if player.learnRecipe then
                player:learnRecipe(r)
            else
                local known = player:getKnownRecipes()
                if known and known.add then known:add(r) end
            end
            n = n + 1
        end
    end
    -- Flush recipe knowledge to the client (vanilla pattern: bitfield 0x00000001).
    if n > 0 and sendSyncPlayerFields then
        sendSyncPlayerFields(player, 0x00000001)
    end
    return n
end

local function applyMedia(player, row)
    if not player or not row or not row.knownMedia then return 0 end
    if not player.getKnownMediaTypes then return 0 end
    local set = player:getKnownMediaTypes()
    if not set or not set.contains then return 0 end
    local n = 0
    for id, _ in pairs(row.knownMedia) do
        if set:contains(id) ~= true then
            set:add(id)
            n = n + 1
        end
    end
    return n
end

-- ---------------------------------------------------------------------
-- Handlers
-- ---------------------------------------------------------------------
function Server.handleGet(player, args)
    if not CSR_FeatureFlags.isSkillJournalEnabled() then return end
    local row = select(1, getRow(player, false))
    sendState(player, row)
    if isAdmin(player) then pushBlacklist(player) end
end

function Server.handleSave(player, args)
    print("[CSR][SkillJournal] handleSave: enter")
    if not CSR_FeatureFlags.isSkillJournalEnabled() then
        sendResult(player, false, "Skill Journal is disabled on this server.")
        return
    end
    if not checkCooldown(player) then
        print("[CSR][SkillJournal] handleSave: BLOCKED by request cooldown -- click ignored")
        sendResult(player, false, "Please wait a moment before pressing Save again.")
        return
    end

    local store = loadStore()
    local userName = player and player.getUsername and player:getUsername() or ""
    if isUserBlacklisted(store, userName) and not isAdmin(player) then
        sendResult(player, false, "You are blacklisted from using the Skill Journal on this server.")
        return
    end

    local key = select(2, CSR_SkillJournal.getRowKey(player))
    local rowKey = select(2, getRow(player, false))
    if rowKey and Server._writing[rowKey] then
        sendResult(player, false, "Snapshot already in progress.")
        return
    end

    -- Min-playtime gate.
    local minHours = tonumber(sb().SkillJournalMinPlayHours) or 24
    local survived = tonumber(player:getHoursSurvived()) or 0
    if survived < minHours then
        sendResult(player, false, string.format(
            "You need %d more in-game hours of survival before your first snapshot (%.1f / %d).",
            math.ceil(minHours - survived), survived, minHours))
        return
    end

    local row, k = getRow(player, true)
    if not row then
        sendResult(player, false, "Could not resolve your character slot.")
        return
    end

    -- Profession lock: once a profession is bound to the row, every
    -- subsequent Save must match.  Blocks the die->respawn-with-new-
    -- profession->resave-better-stats exploit.
    local lockProf = sb().SkillJournalProfessionLock ~= false
    local curProf  = CSR_SkillJournal.getProfession(player)
    if lockProf and row.profession and row.profession ~= "" then
        if curProf == "" then
            sendResult(player, false, "Could not read your current profession.")
            return
        end
        if curProf ~= row.profession then
            sendResult(player, false, string.format(
                "Profession mismatch: this journal is locked to '%s'. " ..
                "Recover into a matching character or ask an admin to wipe the row.",
                tostring(row.profession)))
            return
        end
    end

    -- In-game cooldown gate.
    local cooldown = tonumber(sb().SkillJournalSaveCooldownHours) or 24
    if cooldown > 0 and row.lastWrite and row.lastWrite > 0 then
        local since = gameHours() - row.lastWrite
        if since < cooldown then
            sendResult(player, false, string.format(
                "Save cooldown: %d in-game hours remaining.",
                math.max(1, math.ceil(cooldown - since))))
            return
        end
    end

    -- Real-world (wall-clock) cooldown gate.  Independent of game speed --
    -- blocks the "wait 24 in-game hours by sleeping/time-skip" loophole.
    local realCooldown = tonumber(sb().SkillJournalRealHoursCooldown) or 24
    if realCooldown > 0 and row.lastWriteRealMs and row.lastWriteRealMs > 0 then
        local elapsedH = (nowMs() - row.lastWriteRealMs) / 3600000.0
        if elapsedH < realCooldown then
            sendResult(player, false, string.format(
                "Real-world cooldown: %.1f hour(s) remaining before you can save again.",
                math.max(0.1, realCooldown - elapsedH)))
            return
        end
    end

    Server._writing[k] = true
    local pCount = capturePerks(player, row)
    local rCount = captureRecipes(player, row)
    local mCount = captureMedia(player, row)
    row.lastWrite       = gameHours()
    row.lastWriteRealMs = nowMs()
    if curProf ~= "" then row.profession = curProf end
    Server._writing[k] = nil
    flush()

    sendResult(player, true, string.format(
        "Snapshot saved (%s): %d skills, %d recipes, %d magazines.",
        row.profession ~= "" and row.profession or "no profession",
        pCount, rCount, mCount))
    sendState(player, row)
end

function Server.handleRecover(player, args)
    if not CSR_FeatureFlags.isSkillJournalEnabled() then
        sendResult(player, false, "Skill Journal is disabled on this server.")
        return
    end
    if not checkCooldown(player) then
        sendResult(player, false, "Please wait a moment before pressing Recover again.")
        return
    end

    if sb().SkillJournalAdminOnlyRecover == true and not isAdmin(player) then
        sendResult(player, false, "Recovery is admin-only on this server.")
        return
    end

    local userName0 = player and player.getUsername and player:getUsername() or ""
    if isUserBlacklisted(loadStore(), userName0) and not isAdmin(player) then
        sendResult(player, false, "You are blacklisted from using the Skill Journal on this server.")
        return
    end

    local row, k = getRow(player, false)
    if not row or row.lastWrite == 0 then
        sendResult(player, false, "No snapshot saved yet -- press Save first.")
        return
    end
    if Server._writing[k] then
        sendResult(player, false, "Snapshot busy, try again in a moment.")
        return
    end

    Server._writing[k] = true
    local penalty = normalizePendingPenalty(row.pendingPenalty)
    local applied = applyPerks(player, row, penalty)
    local recipes = applyRecipes(player, row)
    local media   = applyMedia(player, row)
    row.pendingPenalty = 0
    row.deaths         = 0
    row.perks          = {}
    row.recipes        = {}
    row.knownMedia     = {}
    row.lastWrite      = 0
    row.lastWriteRealMs = 0
    Server._writing[k] = nil
    flush()

    sendResult(player, true, string.format(
        "Recovered %d skills (-%d penalty), %d recipes, %d magazines.",
        applied, penalty, recipes, media))
    sendState(player, row)
end

function Server.handleAdmin(player, args)
    if not isAdmin(player) then
        sendResult(player, false, "Admin only.")
        return
    end
    args = args or {}
    local op = tostring(args.op or "")
    local target = tostring(args.target or "")
    local store = loadStore()

    if op == "wipe" then
        local removed = 0
        for k, row in pairs(store.rows) do
            if row.userName == target then
                store.rows[k] = nil
                removed = removed + 1
            end
        end
        flush()
        sendResult(player, true, string.format("Wiped %d row(s) for %s.", removed, target))
    elseif op == "view" then
        local hits = {}
        for k, row in pairs(store.rows) do
            if row.userName == target then
                table.insert(hits, string.format(
                    "  %s : last=%dh born=%dh deaths=%d penalty=%d",
                    k, row.lastWrite or 0, row.bornTs or 0,
                    row.deaths or 0, row.pendingPenalty or 0))
            end
        end
        if #hits == 0 then
            sendResult(player, true, "No journal rows for " .. target .. ".")
        else
            sendResult(player, true, "Rows for " .. target .. ":\n" .. table.concat(hits, "\n"))
        end
    elseif op == "bl_get" then
        pushBlacklist(player)
    elseif op == "bl_user_add" then
        if target == "" then sendResult(player, false, "Username required."); return end
        store.blacklist.users[string.lower(target)] = true
        flush(); pushBlacklist(player)
        sendResult(player, true, "Blacklisted user: " .. target)
    elseif op == "bl_user_remove" then
        store.blacklist.users[string.lower(target)] = nil
        flush(); pushBlacklist(player)
        sendResult(player, true, "Removed user from blacklist: " .. target)
    elseif op == "bl_perk_add" then
        if target == "" then sendResult(player, false, "Perk type required."); return end
        store.blacklist.perks[target] = true
        flush(); pushBlacklist(player)
        sendResult(player, true, "Blacklisted perk: " .. target)
    elseif op == "bl_perk_remove" then
        store.blacklist.perks[target] = nil
        flush(); pushBlacklist(player)
        sendResult(player, true, "Removed perk from blacklist: " .. target)
    else
        sendResult(player, false, "Unknown admin op: " .. op)
    end
end

-- ---------------------------------------------------------------------
-- Death penalty hook
-- ---------------------------------------------------------------------
local function onPlayerDeath(player)
    if not CSR_FeatureFlags.isSkillJournalEnabled() then return end
    if not player then return end
    local row = select(1, getRow(player, false))
    if not row or row.lastWrite == 0 then return end
    local penalty = configuredDeathPenalty()
    row.deaths = (row.deaths or 0) + 1
    row.pendingPenalty = math.min(99, normalizePendingPenalty(row.pendingPenalty) + penalty)
    flush()
end

-- ---------------------------------------------------------------------
-- Wire-up
-- ---------------------------------------------------------------------
local function onServerStart()
    if Events.OnPlayerDeath then
        Events.OnPlayerDeath.Add(onPlayerDeath)
        print("[CSR][SkillJournal] OnPlayerDeath hook registered -- death penalty active")
    else
        print("[CSR][SkillJournal] WARNING: Events.OnPlayerDeath not found -- death penalty will not apply")
    end
end

if Events and not Server._registered then
    Server._registered = true
    if Events.OnServerStarted then Events.OnServerStarted.Add(onServerStart) end
    if Events.OnGameStart     then Events.OnGameStart.Add(onServerStart)     end
end

return Server
