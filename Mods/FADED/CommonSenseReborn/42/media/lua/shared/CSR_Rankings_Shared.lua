--[[
    CSR_Rankings_Shared.lua

    Common types, constants and pure-function helpers for the
    "Server Rankings" feature. Loaded on both client and server.

    Clean-room implementation. Schema, naming and persistence layout are
    original to CSR -- no symbols are taken from any third-party scoreboard
    mod.

    Storage strategy
    ----------------
    All persistent rows live under one server-side global ModData key:
        CSR_Rankings_v1 = {
            schema = 1,
            players = {
                [usernameLower] = <playerRow>,
            },
            updatedAt = "YYYY-MM-DD HH:MM:SS",
        }

    Each player row carries flat scalar totals plus daily history buckets
    keyed by ISO date ("2026-04-29"). Daily buckets older than the
    retention window are pruned on write. Weekly / monthly periods are
    derived on demand from daily buckets so we never store the same fact
    twice.
]]

CSR_Rankings = CSR_Rankings or {}

CSR_Rankings.SCHEMA_VERSION = 1
CSR_Rankings.MODDATA_KEY    = "CSR_Rankings_v1"
CSR_Rankings.MOD_ID         = "CSR_Rankings"

-- Network commands
CSR_Rankings.CMD_REQUEST = "RankingsRequest"
CSR_Rankings.CMD_PUSH    = "RankingsPush"

-- Throttling
CSR_Rankings.REQUEST_COOLDOWN_MS = 15000   -- per-client cooldown
CSR_Rankings.PAYLOAD_TOP_N       = 25      -- top rows always returned
CSR_Rankings.MAX_DISTANCE_PER_MIN = 2500   -- anti speed-hack cap (tiles)

-- Weapon category buckets
CSR_Rankings.WEAPON_CATEGORIES = {
    "Axe", "LongBlade", "SmallBlade", "Spear",
    "Blunt", "SmallBlunt", "Firearm", "Unarmed", "Other"
}

-- ---------------------------------------------------------------------
-- Pure helpers
-- ---------------------------------------------------------------------

function CSR_Rankings.safeNumber(value, defaultValue)
    if value == nil then return defaultValue or 0 end
    local n = tonumber(value)
    if n == nil then return defaultValue or 0 end
    return n
end

function CSR_Rankings.safeString(value, defaultValue)
    if value == nil or value == "" then return defaultValue or "" end
    return tostring(value)
end

function CSR_Rankings.now()
    if Calendar and Calendar.getInstance then
        local cal = Calendar.getInstance()
        if cal then
            return {
                year = cal:get(Calendar.YEAR),
                month = cal:get(Calendar.MONTH) + 1,
                day = cal:get(Calendar.DAY_OF_MONTH),
                hour = cal:get(Calendar.HOUR_OF_DAY),
                min = cal:get(Calendar.MINUTE),
                sec = cal:get(Calendar.SECOND),
            }
        end
    end
    if os and os.date then
        local p = os.date("*t")
        if p then return p end
    end
    return { year = 1970, month = 1, day = 1, hour = 0, min = 0, sec = 0 }
end

function CSR_Rankings.todayKey()
    local n = CSR_Rankings.now()
    return string.format("%04d-%02d-%02d", n.year, n.month, n.day)
end

function CSR_Rankings.timestamp()
    local n = CSR_Rankings.now()
    return string.format("%04d-%02d-%02d %02d:%02d:%02d",
        n.year, n.month, n.day, n.hour, n.min, n.sec)
end

-- Format a tile distance into "X.XX km" (1 tile == 1 metre in PZ).
function CSR_Rankings.formatDistance(tiles)
    local t = math.max(CSR_Rankings.safeNumber(tiles, 0), 0)
    if t < 1000 then
        return string.format("%dm", math.floor(t))
    end
    return string.format("%.2fkm", t / 1000)
end

function CSR_Rankings.formatHours(hours)
    local h = math.max(CSR_Rankings.safeNumber(hours, 0), 0)
    local d = math.floor(h / 24)
    local rh = math.floor(h - d * 24)
    if d > 0 then return string.format("%dd %02dh", d, rh) end
    return string.format("%dh", rh)
end

function CSR_Rankings.formatCompact(value)
    local n = CSR_Rankings.safeNumber(value, 0)
    local a = math.abs(n)
    if a >= 1000000 then return string.format("%.1fM", n / 1000000) end
    if a >= 1000    then return string.format("%.1fk", n / 1000)    end
    if math.floor(n) == n then return tostring(math.floor(n)) end
    return string.format("%.1f", n)
end

function CSR_Rankings.kdRatio(kills, deaths)
    local k = math.max(CSR_Rankings.safeNumber(kills, 0), 0)
    local d = math.max(CSR_Rankings.safeNumber(deaths, 0), 0)
    if d <= 0 then return k end -- treat undeath as raw kill count
    return k / d
end

function CSR_Rankings.formatKD(kills, deaths)
    local d = math.max(CSR_Rankings.safeNumber(deaths, 0), 0)
    if d <= 0 then
        return string.format("%d.--", math.floor(CSR_Rankings.safeNumber(kills, 0)))
    end
    return string.format("%.2f", CSR_Rankings.kdRatio(kills, deaths))
end

-- ---------------------------------------------------------------------
-- ISO date arithmetic (Lua-only, no Java needed)
-- ---------------------------------------------------------------------

function CSR_Rankings.parseDateKey(key)
    local s = CSR_Rankings.safeString(key, "")
    local y, m, d = string.match(s, "^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    if not y then return nil end
    return { year = tonumber(y), month = tonumber(m), day = tonumber(d) }
end

function CSR_Rankings.shiftDateKey(key, deltaDays)
    if not os or not os.time or not os.date then
        return key
    end
    local p = CSR_Rankings.parseDateKey(key)
    if not p then return key end
    local stamp = os.time({ year = p.year, month = p.month, day = p.day,
                            hour = 12, min = 0, sec = 0 })
    if not stamp then return key end
    return os.date("%Y-%m-%d", stamp + (deltaDays * 86400))
end

-- Returns true if dateKey falls within the last `days` days (inclusive of today).
function CSR_Rankings.isWithinDays(dateKey, days)
    local p = CSR_Rankings.parseDateKey(dateKey)
    if not p or not os or not os.time then return false end
    local n = CSR_Rankings.now()
    local nowStamp  = os.time({ year = n.year, month = n.month, day = n.day,
                                hour = 12, min = 0, sec = 0 })
    local thatStamp = os.time({ year = p.year, month = p.month, day = p.day,
                                hour = 12, min = 0, sec = 0 })
    if not nowStamp or not thatStamp then return false end
    local diff = (nowStamp - thatStamp) / 86400
    return diff >= 0 and diff < days
end

-- ---------------------------------------------------------------------
-- Schema constructors
-- ---------------------------------------------------------------------

function CSR_Rankings.newPlayerRow(username)
    return {
        username = CSR_Rankings.safeString(username, "?"),
        steamId = "",
        firstSeen = CSR_Rankings.timestamp(),
        lastSeen  = CSR_Rankings.timestamp(),

        -- Lifetime totals
        zombieKills = 0,
        playerKills = 0,
        deaths = 0,
        hoursSurvived = 0,
        bestHoursSurvived = 0,
        distanceWalked = 0,
        xpGained = 0,
        currentStreak = 0,    -- zombie kills since last death
        bestStreak = 0,
        longestLifeHours = 0, -- best survived hours in any single life

        -- Per-category weapon kill counts
        categoryKills = {},   -- { Axe = 12, Firearm = 5, ... }

        -- Faction snapshot (last seen)
        faction = "",

        -- Daily history: { ["2026-04-29"] = { z=N, p=N, d=N, h=N, dist=N, xp=N }, ... }
        history = {},
    }
end

function CSR_Rankings.newDailyBucket()
    return { z = 0, p = 0, d = 0, h = 0, dist = 0, xp = 0 }
end

return CSR_Rankings
