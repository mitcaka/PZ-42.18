--[[
    CSR_Rankings_Server.lua

    Server-side tracker + handler for "Server Rankings".

    Approach
    --------
    * Tracking is delta-based off the vanilla counters every minute, so a
      single source of truth (vanilla) drives our totals.
        - zombieKills delta from IsoPlayer:getZombieKills()
        - hours delta from IsoPlayer:getHoursSurvived()
    * Tile distance is sampled from getX/Y per tick with a per-minute cap
      (anti speed-hack) and accumulated.
    * XP delta is captured from Events.AddXP.
    * Deaths come from Events.OnPlayerDeath, with optional PvP attribution
      via :getAttackedBy() when RankingsTrackPvP is enabled.

    Persistence: ModData["CSR_Rankings_v1"] global, written through
    ModData.add + ModData.transmit on dirty ticks (every 60s when dirty).
]]

if not isServer() and not isClient() then
    -- Some hosts re-load shared/server files in unexpected contexts.
end

require "CSR_Rankings_Shared"
require "CSR_FeatureFlags"

CSR_RankingsServer = CSR_RankingsServer or {}
local Server = CSR_RankingsServer

-- Per-player session state (in-memory, not persisted).
--   { lastZombieKills, lastHours, lastX, lastY, lastSampleMs, lastXp,
--     thisMinuteDist, lastMinuteEpoch }
Server.session = Server.session or {}

-- Pending request cooldowns: usernameLower -> last request timestamp ms
Server.lastRequestMs = Server.lastRequestMs or {}

-- Dirty flag: true when we need to flush + transmit ModData.
Server.dirty = false
Server.lastFlushMs = 0

-- ---------------------------------------------------------------------
-- ModData accessors
-- ---------------------------------------------------------------------

local function nowMs()
    if getTimestampMs then return getTimestampMs() end
    return (os and os.time and os.time() * 1000) or 0
end

local function loadStore()
    local md = ModData.getOrCreate(CSR_Rankings.MODDATA_KEY)
    if type(md) ~= "table" then
        md = {}
        ModData.add(CSR_Rankings.MODDATA_KEY, md)
    end
    if md.schema == nil then md.schema = CSR_Rankings.SCHEMA_VERSION end
    if type(md.players) ~= "table" then md.players = {} end
    return md
end

local function getRow(store, username)
    local key = string.lower(CSR_Rankings.safeString(username, "?"))
    if key == "" then return nil, nil end
    local row = store.players[key]
    if not row then
        row = CSR_Rankings.newPlayerRow(username)
        store.players[key] = row
    end
    return row, key
end

local function ensureBucket(row, dateKey)
    if type(row.history) ~= "table" then row.history = {} end
    local b = row.history[dateKey]
    if type(b) ~= "table" then
        b = CSR_Rankings.newDailyBucket()
        row.history[dateKey] = b
    end
    return b
end

local function pruneOldBuckets(row)
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    local retention = math.max(7, math.floor(tonumber(sb.RankingsRetentionDays or 90) or 90))
    if type(row.history) ~= "table" then return end
    local toDelete = {}
    for dateKey, _ in pairs(row.history) do
        if not CSR_Rankings.isWithinDays(dateKey, retention) then
            table.insert(toDelete, dateKey)
        end
    end
    for i = 1, #toDelete do
        row.history[toDelete[i]] = nil
    end
end

local function markDirty()
    Server.dirty = true
end

local function flushIfDue(force)
    if not Server.dirty and not force then return end
    local store = loadStore()
    store.updatedAt = CSR_Rankings.timestamp()
    ModData.transmit(CSR_Rankings.MODDATA_KEY)
    Server.dirty = false
    Server.lastFlushMs = nowMs()
end

-- ---------------------------------------------------------------------
-- Per-player counter sampling
-- ---------------------------------------------------------------------

local function getSession(username)
    local key = string.lower(CSR_Rankings.safeString(username, "?"))
    local s = Server.session[key]
    if not s then
        s = {
            lastZombieKills = nil,
            lastHours = nil,
            lastX = nil,
            lastY = nil,
            thisMinuteDist = 0,
            lastMinuteStamp = nowMs(),
        }
        Server.session[key] = s
    end
    return s
end

local function updatePlayerOnce(playerObj)
    if not playerObj or not playerObj.getUsername then return end
    if not CSR_FeatureFlags.isRankingsEnabled() then return end

    local username = tostring(playerObj:getUsername() or "")
    if username == "" then return end

    local store = loadStore()
    local row = getRow(store, username)
    if not row then return end

    -- Defensive: row.steamId, faction
    if row.steamId == "" and playerObj.getSteamID then
        local sid = nil
        local ok = pcall(function() sid = playerObj:getSteamID() end)
        if ok and sid and tostring(sid) ~= "0" then
            row.steamId = tostring(sid)
        end
    end
    if playerObj.getFaction then
        local ok, fac = pcall(function() return Faction and Faction.getPlayerFaction and Faction.getPlayerFaction(playerObj) or nil end)
        if ok and fac and fac.getName then
            row.faction = tostring(fac:getName() or "")
        end
    end

    row.lastSeen = CSR_Rankings.timestamp()

    local sess = getSession(username)
    local todayKey = CSR_Rankings.todayKey()
    local bucket = ensureBucket(row, todayKey)

    -- Zombie kills delta
    local zk = 0
    if playerObj.getZombieKills then
        zk = tonumber(playerObj:getZombieKills()) or 0
    end
    if sess.lastZombieKills == nil then
        sess.lastZombieKills = zk
    elseif zk >= sess.lastZombieKills then
        local delta = zk - sess.lastZombieKills
        if delta > 0 then
            row.zombieKills = (row.zombieKills or 0) + delta
            bucket.z = (bucket.z or 0) + delta
            row.currentStreak = (row.currentStreak or 0) + delta
            if row.currentStreak > (row.bestStreak or 0) then
                row.bestStreak = row.currentStreak
            end
            markDirty()
        end
        sess.lastZombieKills = zk
    else
        -- Counter reset (death / new char) -- snap baseline
        sess.lastZombieKills = zk
    end

    -- Hours delta
    local hrs = 0
    if playerObj.getHoursSurvived then
        hrs = tonumber(playerObj:getHoursSurvived()) or 0
    end
    if sess.lastHours == nil then
        sess.lastHours = hrs
    elseif hrs >= sess.lastHours then
        local delta = hrs - sess.lastHours
        if delta > 0 then
            row.hoursSurvived = (row.hoursSurvived or 0) + delta
            bucket.h = (bucket.h or 0) + delta
            if hrs > (row.longestLifeHours or 0) then
                row.longestLifeHours = hrs
            end
            if hrs > (row.bestHoursSurvived or 0) then
                row.bestHoursSurvived = hrs
            end
            markDirty()
        end
        sess.lastHours = hrs
    else
        sess.lastHours = hrs
    end

    -- Distance: per-tick sample, capped per minute.
    local px, py = nil, nil
    if playerObj.getX and playerObj.getY then
        px = tonumber(playerObj:getX()) or 0
        py = tonumber(playerObj:getY()) or 0
    end
    if px and py then
        if sess.lastX and sess.lastY then
            local dx = px - sess.lastX
            local dy = py - sess.lastY
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 0 and dist < 64 then -- ignore teleports / loadIns
                sess.thisMinuteDist = sess.thisMinuteDist + dist
            end
        end
        sess.lastX = px
        sess.lastY = py
    end

    -- Roll the per-minute distance in
    local now = nowMs()
    if (now - (sess.lastMinuteStamp or now)) >= 60000 then
        local clipped = math.min(sess.thisMinuteDist, CSR_Rankings.MAX_DISTANCE_PER_MIN)
        if clipped > 0 then
            row.distanceWalked = (row.distanceWalked or 0) + clipped
            bucket.dist = (bucket.dist or 0) + clipped
            markDirty()
        end
        sess.thisMinuteDist = 0
        sess.lastMinuteStamp = now
    end

    pruneOldBuckets(row)
end

-- ---------------------------------------------------------------------
-- Event hooks
-- ---------------------------------------------------------------------

local function onPlayerUpdateTick(playerObj)
    if not CSR_FeatureFlags.isRankingsEnabled() then return end
    -- Lightweight sample: just position + counters once a second per player.
    if not playerObj or not playerObj.getUsername then return end
    local username = tostring(playerObj:getUsername() or "")
    if username == "" then return end
    local sess = getSession(username)
    local now = nowMs()
    if (now - (sess.lastSampleMs or 0)) < 1000 then return end
    sess.lastSampleMs = now
    pcall(updatePlayerOnce, playerObj)
end

local function onAddXP(owner, perk, amount)
    if not CSR_FeatureFlags.isRankingsEnabled() then return end
    if not owner or not owner.getUsername then return end
    local amt = tonumber(amount) or 0
    if amt <= 0 then return end
    local username = tostring(owner:getUsername() or "")
    if username == "" then return end
    local store = loadStore()
    local row = getRow(store, username)
    if not row then return end
    row.xpGained = (row.xpGained or 0) + amt
    local bucket = ensureBucket(row, CSR_Rankings.todayKey())
    bucket.xp = (bucket.xp or 0) + amt
    markDirty()
end

local function onPlayerDeath(playerObj)
    if not CSR_FeatureFlags.isRankingsEnabled() then return end
    if not playerObj or not playerObj.getUsername then return end
    local username = tostring(playerObj:getUsername() or "")
    if username == "" then return end

    local store = loadStore()
    local row = getRow(store, username)
    if not row then return end
    row.deaths = (row.deaths or 0) + 1
    local bucket = ensureBucket(row, CSR_Rankings.todayKey())
    bucket.d = (bucket.d or 0) + 1
    -- Reset streak on death; keep bestStreak.
    row.currentStreak = 0

    -- PvP attribution (best-effort, optional)
    if CSR_FeatureFlags.isRankingsTrackPvP() then
        local attacker = nil
        pcall(function()
            if playerObj.getAttackedBy then
                attacker = playerObj:getAttackedBy()
            end
        end)
        if attacker and attacker.getUsername and instanceof and instanceof(attacker, "IsoPlayer") then
            local aName = tostring(attacker:getUsername() or "")
            if aName ~= "" and aName ~= username then
                local arow = getRow(store, aName)
                if arow then
                    arow.playerKills = (arow.playerKills or 0) + 1
                    local abucket = ensureBucket(arow, CSR_Rankings.todayKey())
                    abucket.p = (abucket.p or 0) + 1
                end
            end
        end
    end

    -- Reset session deltas so a respawn doesn't double-count
    Server.session[string.lower(username)] = nil

    markDirty()
    flushIfDue(true)
end

-- ---------------------------------------------------------------------
-- Payload building (for client requests)
-- ---------------------------------------------------------------------

-- Build a thin row used for client transmission. Strips bulky history
-- maps unless the client asked for a specific username's detail.
local function thinRow(row, includeHistory)
    if not row then return nil end
    local out = {
        username = row.username,
        steamId = row.steamId or "",
        faction = row.faction or "",
        firstSeen = row.firstSeen,
        lastSeen = row.lastSeen,
        zombieKills = math.floor(row.zombieKills or 0),
        playerKills = math.floor(row.playerKills or 0),
        deaths = math.floor(row.deaths or 0),
        hoursSurvived = row.hoursSurvived or 0,
        bestHoursSurvived = row.bestHoursSurvived or 0,
        longestLifeHours = row.longestLifeHours or 0,
        distanceWalked = math.floor(row.distanceWalked or 0),
        xpGained = math.floor(row.xpGained or 0),
        currentStreak = math.floor(row.currentStreak or 0),
        bestStreak = math.floor(row.bestStreak or 0),
    }
    if includeHistory and type(row.history) == "table" then
        out.history = {}
        for k, v in pairs(row.history) do
            out.history[k] = {
                z = math.floor(v.z or 0),
                p = math.floor(v.p or 0),
                d = math.floor(v.d or 0),
                h = v.h or 0,
                dist = math.floor(v.dist or 0),
                xp = math.floor(v.xp or 0),
            }
        end
    end
    return out
end

local function aggregatePeriod(row, days)
    local agg = { z = 0, p = 0, d = 0, h = 0, dist = 0, xp = 0 }
    if type(row.history) ~= "table" then return agg end
    for dateKey, b in pairs(row.history) do
        if CSR_Rankings.isWithinDays(dateKey, days) then
            agg.z    = agg.z    + (b.z    or 0)
            agg.p    = agg.p    + (b.p    or 0)
            agg.d    = agg.d    + (b.d    or 0)
            agg.h    = agg.h    + (b.h    or 0)
            agg.dist = agg.dist + (b.dist or 0)
            agg.xp   = agg.xp   + (b.xp   or 0)
        end
    end
    return agg
end

local function buildPayload(requesterUsername, focusUsername)
    local store = loadStore()
    local rows = {}
    for _, row in pairs(store.players) do
        local isFocus = focusUsername and string.lower(row.username) == string.lower(focusUsername)
        local thin = thinRow(row, isFocus == true)
        if thin then
            thin.daily   = aggregatePeriod(row, 1)
            thin.weekly  = aggregatePeriod(row, 7)
            thin.monthly = aggregatePeriod(row, 30)
            table.insert(rows, thin)
        end
    end
    return {
        schema = CSR_Rankings.SCHEMA_VERSION,
        updatedAt = store.updatedAt or CSR_Rankings.timestamp(),
        rows = rows,
        requester = requesterUsername or "",
    }
end

-- ---------------------------------------------------------------------
-- Client request handler
-- ---------------------------------------------------------------------

function CSR_RankingsServer.handleRequest(player, args)
    if not CSR_FeatureFlags.isRankingsEnabled() then return end
    if not player or not player.getUsername then return end
    local username = tostring(player:getUsername() or "")
    if username == "" then return end

    -- Anonymous-view gating
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    if sb.RankingsAllowAnonymousView == false then
        local accessLevel = ""
        pcall(function() accessLevel = tostring(player:getAccessLevel() or "") end)
        if accessLevel ~= "Admin" and accessLevel ~= "Moderator" then
            sendServerCommand(player, "CommonSenseReborn", CSR_Rankings.CMD_PUSH, {
                schema = CSR_Rankings.SCHEMA_VERSION,
                rows = {},
                denied = true,
                requester = username,
            })
            return
        end
    end

    -- Cooldown
    local key = string.lower(username)
    local last = Server.lastRequestMs[key] or 0
    local now = nowMs()
    if (now - last) < CSR_Rankings.REQUEST_COOLDOWN_MS then return end
    Server.lastRequestMs[key] = now

    local focus = args and args.focus and tostring(args.focus) or username
    local payload = buildPayload(username, focus)
    sendServerCommand(player, "CommonSenseReborn", CSR_Rankings.CMD_PUSH, payload)
end

-- ---------------------------------------------------------------------
-- Wire-up
-- ---------------------------------------------------------------------

local function onEveryOneMinute()
    if not CSR_FeatureFlags.isRankingsEnabled() then return end
    local online = getOnlinePlayers and getOnlinePlayers() or nil
    if online and online.size then
        for i = 0, online:size() - 1 do
            local p = online:get(i)
            pcall(updatePlayerOnce, p)
        end
    end
    flushIfDue(false)
end

local function onServerStart()
    if Events.EveryOneMinute then Events.EveryOneMinute.Add(onEveryOneMinute) end
    if Events.OnPlayerUpdate then Events.OnPlayerUpdate.Add(onPlayerUpdateTick) end
    if Events.AddXP          then Events.AddXP.Add(onAddXP) end
    if Events.OnPlayerDeath  then Events.OnPlayerDeath.Add(onPlayerDeath) end
end

if Events and not CSR_RankingsServer._registered then
    CSR_RankingsServer._registered = true
    if Events.OnServerStarted then Events.OnServerStarted.Add(onServerStart) end
    if Events.OnGameStart     then Events.OnGameStart.Add(onServerStart)     end
end

return CSR_RankingsServer
