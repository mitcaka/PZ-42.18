--[[
    CSR_ClaimInvites.lua
    -------------------------------------------------------------------------
    v1.8.35 -- server-authoritative invite system + faction-dissolution
    safeguard for the CSR claim system.

    Invite storage (flat-primitive only; survives Java serialization):
        gameModData["CSR_ClaimInv_idx"]      = monotonic counter
        gameModData["CSR_ClaimInv_<n>_id"]   = invite id
        gameModData["CSR_ClaimInv_<n>_cid"]  = claim row id
        gameModData["CSR_ClaimInv_<n>_to"]   = target username
        gameModData["CSR_ClaimInv_<n>_by"]   = inviter username
        gameModData["CSR_ClaimInv_<n>_role"] = proposed role (member by default)
        gameModData["CSR_ClaimInv_<n>_ts"]   = os.time() (for cooldown / expiry)

    Cooldowns:
        - Per-inviter: ClaimInviteCooldownMin (sandbox, default 1)
        - Auto-expire after 24h (game-real or server-real time, whichever
          we can resolve; uses os.time fallback)

    Dissolution scan:
        - Triggered EveryHours
        - Walks faction rows; if Faction.getFaction(name) == nil, executes
          ClaimDissolveAction:
              "transfer"  -- promote highest-ranked member (default)
              "release"   -- remove the row
        - Audit-logged.

    Hard rules: see CSR_ClaimServer.lua header.
--]]

require "CSR_Claims/CSR_ClaimRegistry"
require "CSR_Claims/CSR_ClaimAudit"
require "CSR_Claims/CSR_ClaimPermissions"

-- MP-only.
if not isClient and not isServer then return end
if not isClient() and not isServer() then return end

CSR_ClaimInvites = CSR_ClaimInvites or {}

local Registry    = CSR_ClaimRegistry
local Audit       = CSR_ClaimAudit
local Permissions = CSR_ClaimPermissions

local INV_PREFIX  = "CSR_ClaimInv_"
local INV_IDX_KEY = "CSR_ClaimInv_idx"
local INV_EXPIRY_SEC = 24 * 60 * 60   -- 24h

local function modRoot()
    if not getGameTime then return nil end
    local gt = getGameTime()
    if not gt or not gt.getModData then return nil end
    return gt:getModData()
end

local function nowTs()
    if os and os.time then return tonumber(os.time()) or 0 end
    return 0
end

local function safeUsername(player)
    if not player then return "" end
    if type(player) == "string" then return player end
    if player.getUsername then
        local u = player:getUsername()
        if u then return tostring(u) end
    end
    return ""
end

local function safeSteamID(player)
    if not player or not player.getSteamID then return "" end
    local sid = player:getSteamID()
    if not sid then return "" end
    local s = tostring(sid)
    if s == "" or s == "0" then return "" end
    return s
end

local function memberSteamPatch(row, username, steamID, addMember)
    local patch = {}
    if not row or not username or username == "" or not Registry then return patch end
    local ids = tostring(row.memberSteamIDsCSV or "")
    local map = tostring(row.memberSteamMapCSV or "")
    if addMember then
        if steamID and steamID ~= "" then
            if Registry.csvAdd then patch.memberSteamIDsCSV = Registry.csvAdd(ids, steamID) end
            if Registry.mapSet then patch.memberSteamMapCSV = Registry.mapSet(map, username, steamID) end
        end
    else
        local sid = Registry.mapGet and Registry.mapGet(map, username) or ""
        if sid ~= "" and Registry.csvRemove then patch.memberSteamIDsCSV = Registry.csvRemove(ids, sid) end
        if Registry.mapRemove then patch.memberSteamMapCSV = Registry.mapRemove(map, username) end
    end
    return patch
end

local function mergePatch(dst, src)
    dst = dst or {}
    if type(src) ~= "table" then return dst end
    for k, v in pairs(src) do dst[k] = v end
    return dst
end

local function isAdminPlayer(player)
    if not player or not player.getAccessLevel then return false end
    local access = player:getAccessLevel()
    return access == "admin" or access == "Admin"
end

local function sendResult(player, ok, text)
    if not player then return end
    sendServerCommand(player, "CommonSenseReborn", "CSR_ClaimResult", {
        ok = ok and 1 or 0,
        text = tostring(text or ""),
    })
end

local function sendInviteToTarget(targetUsername, payload)
    if not targetUsername or targetUsername == "" then return end
    if not getOnlinePlayers then return end
    local list = getOnlinePlayers()
    if not list or not list.size then return end
    local n = tonumber(list:size()) or 0
    for i = 0, n - 1 do
        local p = list:get(i)
        if p and p.getUsername then
            local u = p:getUsername()
            if u and tostring(u) == targetUsername then
                sendServerCommand(p, "CommonSenseReborn", "CSR_ClaimInviteReceived", payload)
                return
            end
        end
    end
end

local function broadcastInvite(payload)
    sendServerCommand("CommonSenseReborn", "CSR_ClaimInviteSync", payload)
end

-- =========================================================================
-- Invite primitives
-- =========================================================================

local function nextInviteId()
    local r = modRoot(); if not r then return 0 end
    local n = tonumber(r[INV_IDX_KEY]) or 0
    n = n + 1
    r[INV_IDX_KEY] = n
    return n
end

local function writeInvite(invId, claimId, target, by, role, ts)
    local r = modRoot(); if not r then return end
    r[INV_PREFIX .. invId .. "_id"]   = invId
    r[INV_PREFIX .. invId .. "_cid"]  = tonumber(claimId) or 0
    r[INV_PREFIX .. invId .. "_to"]   = tostring(target or "")
    r[INV_PREFIX .. invId .. "_by"]   = tostring(by or "")
    r[INV_PREFIX .. invId .. "_role"] = tostring(role or "member")
    r[INV_PREFIX .. invId .. "_ts"]   = tonumber(ts) or nowTs()
end

local function deleteInvite(invId)
    local r = modRoot(); if not r then return end
    r[INV_PREFIX .. invId .. "_id"]   = nil
    r[INV_PREFIX .. invId .. "_cid"]  = nil
    r[INV_PREFIX .. invId .. "_to"]   = nil
    r[INV_PREFIX .. invId .. "_by"]   = nil
    r[INV_PREFIX .. invId .. "_role"] = nil
    r[INV_PREFIX .. invId .. "_ts"]   = nil
end

local function readInvite(invId)
    local r = modRoot(); if not r then return nil end
    local id = tonumber(r[INV_PREFIX .. invId .. "_id"])
    if not id then return nil end
    return {
        id      = id,
        claimId = tonumber(r[INV_PREFIX .. invId .. "_cid"]) or 0,
        target  = tostring(r[INV_PREFIX .. invId .. "_to"] or ""),
        by      = tostring(r[INV_PREFIX .. invId .. "_by"] or ""),
        role    = tostring(r[INV_PREFIX .. invId .. "_role"] or "member"),
        ts      = tonumber(r[INV_PREFIX .. invId .. "_ts"]) or 0,
    }
end

local function iterateInvites(fn)
    local r = modRoot(); if not r then return end
    local maxIdx = tonumber(r[INV_IDX_KEY]) or 0
    if maxIdx <= 0 then return end
    for i = 1, maxIdx do
        local inv = readInvite(i)
        if inv and fn(inv) == true then return end
    end
end

function CSR_ClaimInvites.findByTarget(target)
    local out = {}
    if not target or target == "" then return out end
    iterateInvites(function(inv)
        if inv.target == target then out[#out + 1] = inv end
    end)
    return out
end

function CSR_ClaimInvites.findByClaimAndTarget(claimId, target)
    local found = nil
    iterateInvites(function(inv)
        if inv.claimId == claimId and inv.target == target then
            found = inv; return true
        end
    end)
    return found
end

local function inviteCooldownSec()
    local sb = (SandboxVars and SandboxVars.CommonSenseReborn) or nil
    local mins = (sb and tonumber(sb.ClaimInviteCooldownMin)) or 1
    if mins < 0 then mins = 0 end
    return mins * 60
end

local function cleanupExpired()
    local cutoff = nowTs() - INV_EXPIRY_SEC
    iterateInvites(function(inv)
        if (inv.ts or 0) > 0 and inv.ts < cutoff then
            deleteInvite(inv.id)
        end
    end)
end

-- =========================================================================
-- Request handlers
-- =========================================================================

-- args = { id (claim row id), target, role }
function CSR_ClaimInvites.handleInviteRequest(player, args)
    if not player or not args then return end
    cleanupExpired()
    local cid = tonumber(args.id) or 0
    local target = tostring(args.target or "")
    local role = tostring(args.role or "member")
    if cid == 0 or target == "" then
        sendResult(player, false, "Bad invite args"); return
    end
    local row = Registry.getRowById(cid)
    if not row then sendResult(player, false, "Unknown claim"); return end

    local user = safeUsername(player)
    if not Permissions.canDo(row, user, "invite", player) then
        sendResult(player, false, "Not allowed to invite"); return
    end

    if row.owner == target or Registry.csvContains(row.membersCSV, target) then
        sendResult(player, false, target .. " is already a member"); return
    end

    -- Cooldown: refuse if same inviter sent any invite within window.
    local cd = inviteCooldownSec()
    if cd > 0 then
        local lastTs = 0
        iterateInvites(function(inv)
            if inv.by == user and inv.ts > lastTs then lastTs = inv.ts end
        end)
        if lastTs > 0 and (nowTs() - lastTs) < cd then
            sendResult(player, false, "Invite cooldown active"); return
        end
    end

    -- Dedupe: if a pending invite already exists for (claim, target), refresh ts.
    local existing = CSR_ClaimInvites.findByClaimAndTarget(cid, target)
    if existing then
        writeInvite(existing.id, cid, target, user, role, nowTs())
        Audit.log("member_invite_resent", row, player, target, { role = role })
        sendResult(player, true, "Invite refreshed")
        sendInviteToTarget(target, {
            id = existing.id, claimId = cid,
            fromUser = user, role = role,
            title = row.title or "", kind = row.kind or "",
            factionName = row.factionName or "",
        })
        return
    end

    local invId = nextInviteId()
    writeInvite(invId, cid, target, user, role, nowTs())
    Audit.log("member_invite", row, player, target, { role = role })
    sendResult(player, true, "Invite sent")
    sendInviteToTarget(target, {
        id = invId, claimId = cid,
        fromUser = user, role = role,
        title = row.title or "", kind = row.kind or "",
        factionName = row.factionName or "",
    })
end

-- args = { id (invite id) }
function CSR_ClaimInvites.handleInviteAccept(player, args)
    if not player or not args then return end
    local invId = tonumber(args.id) or 0
    if invId == 0 then sendResult(player, false, "Bad invite id"); return end
    local inv = readInvite(invId)
    if not inv then sendResult(player, false, "Invite expired"); return end

    local user = safeUsername(player)
    if user ~= inv.target then sendResult(player, false, "Not your invite"); return end

    local row = Registry.getRowById(inv.claimId)
    if not row then
        deleteInvite(invId)
        sendResult(player, false, "Claim no longer exists"); return
    end

    -- Already a member? Just clear and acknowledge.
    if row.owner == user or Registry.csvContains(row.membersCSV, user) then
        deleteInvite(invId)
        sendResult(player, true, "Already a member")
        return
    end

    local newMembers = Registry.csvAdd(row.membersCSV, user)
    local newRoles   = (inv.role and inv.role ~= "" and inv.role ~= "member")
        and Registry.rolesSet(row.rolesCSV, user, inv.role)
        or row.rolesCSV

    if CSR_ClaimServer and CSR_ClaimServer.commitUpdate then
        local patch = {
            membersCSV = newMembers,
            rolesCSV   = newRoles,
        }
        if row.kind == "vehicle" then
            mergePatch(patch, memberSteamPatch(row, user, safeSteamID(player), true))
        end
        CSR_ClaimServer.commitUpdate(row.id, patch)
    end

    -- Sync vanilla SafeHouse list (best effort).
    if (row.kind == "personal" or row.kind == "faction")
        and CSR_SafehouseClaim and CSR_SafehouseClaim.findSafehouseAt then
        local sh = CSR_SafehouseClaim.findSafehouseAt(row.x, row.y, row.w, row.h)
        if sh and sh.addPlayer then sh:addPlayer(user) end
    end

    deleteInvite(invId)
    Audit.log("member_invite_accept", row, player, user, { role = inv.role })
    sendResult(player, true, "Joined " .. (row.title or ""))
end

-- args = { id }
function CSR_ClaimInvites.handleInviteDecline(player, args)
    if not player or not args then return end
    local invId = tonumber(args.id) or 0
    if invId == 0 then sendResult(player, false, "Bad invite id"); return end
    local inv = readInvite(invId)
    if not inv then sendResult(player, false, "Invite expired"); return end
    local user = safeUsername(player)
    if user ~= inv.target and not isAdminPlayer(player) then
        sendResult(player, false, "Not your invite"); return
    end
    local row = Registry.getRowById(inv.claimId)
    deleteInvite(invId)
    Audit.log("member_invite_decline", row, player, user, {})
    sendResult(player, true, "Invite declined")
end

-- args = {}  -- requesting client wants its pending invites
function CSR_ClaimInvites.handleInviteListQuery(player, args)
    if not player then return end
    local user = safeUsername(player)
    if user == "" then return end
    cleanupExpired()
    local pending = CSR_ClaimInvites.findByTarget(user)
    -- Send each one as a CSR_ClaimInviteReceived (client treats them the same).
    for _, inv in ipairs(pending) do
        local row = Registry.getRowById(inv.claimId)
        sendServerCommand(player, "CommonSenseReborn", "CSR_ClaimInviteReceived", {
            id = inv.id, claimId = inv.claimId,
            fromUser = inv.by, role = inv.role,
            title = (row and row.title) or "",
            kind  = (row and row.kind) or "",
            factionName = (row and row.factionName) or "",
        })
    end
end

-- =========================================================================
-- Faction dissolution scan (server-side, runs EveryHours)
-- =========================================================================

local function dissolveAction()
    local sb = (SandboxVars and SandboxVars.CommonSenseReborn) or nil
    local act = sb and tostring(sb.ClaimDissolveAction or "transfer") or "transfer"
    if act ~= "release" and act ~= "transfer" then act = "transfer" end
    return act
end

local function highestRankedMember(row)
    if not row or not row.membersCSV or row.membersCSV == "" then return "" end
    local best, bestRank = "", 99
    local list = Registry.csvList(row.membersCSV)
    for i = 1, #list do
        local user = list[i]
        local rank = Permissions.RANK[Registry.rolesGet(row.rolesCSV or "", user) or "member"] or 99
        if rank < bestRank then best, bestRank = user, rank end
    end
    return best
end

function CSR_ClaimInvites.scanDissolved()
    if not isServer() then return end
    local action = dissolveAction()
    local rows = Registry.getAllRows() or {}
    for _, row in ipairs(rows) do
        if row.kind == "faction" and row.factionName and row.factionName ~= "" then
            local exists = false
            if Faction and Faction.getFaction then
                local f = Faction.getFaction(row.factionName)
                if f then exists = true end
            else
                exists = true   -- can't verify; skip
            end
            if not exists then
                if action == "transfer" then
                    local promote = highestRankedMember(row)
                    if promote ~= "" and CSR_ClaimServer and CSR_ClaimServer.commitUpdate then
                        local newMembers = Registry.csvRemove(row.membersCSV, promote)
                        if row.owner and row.owner ~= "" and row.owner ~= promote then
                            newMembers = Registry.csvAdd(newMembers, row.owner)
                        end
                        local newRoles = Registry.rolesSet(row.rolesCSV, promote, "")
                        CSR_ClaimServer.commitUpdate(row.id, {
                            kind        = "personal",
                            owner       = promote,
                            factionName = "",
                            membersCSV  = newMembers,
                            rolesCSV    = newRoles,
                        })
                        Audit.log("faction_dissolved_transfer", row, "[server]", promote, {
                            faction = row.factionName,
                        })
                    elseif CSR_ClaimServer and CSR_ClaimServer.commitRemove then
                        CSR_ClaimServer.commitRemove(row.id)
                        Audit.log("faction_dissolved_release", row, "[server]", "", {
                            faction = row.factionName,
                        })
                    end
                else
                    if CSR_ClaimServer and CSR_ClaimServer.commitRemove then
                        CSR_ClaimServer.commitRemove(row.id)
                        Audit.log("faction_dissolved_release", row, "[server]", "", {
                            faction = row.factionName,
                        })
                    end
                end
            end
        end
    end
end

-- Member kick (officer+) -- consolidated helper around setRole("")
-- =========================================================================

-- args = { id, target }
function CSR_ClaimInvites.handleMemberKick(player, args)
    if not player or not args then return end
    local cid = tonumber(args.id) or 0
    local target = tostring(args.target or "")
    if cid == 0 or target == "" then sendResult(player, false, "Bad args"); return end
    local row = Registry.getRowById(cid)
    if not row then sendResult(player, false, "Unknown claim"); return end
    local user = safeUsername(player)
    if not Permissions.canDo(row, user, "kick", player) then
        sendResult(player, false, "Not allowed to kick"); return
    end
    if target == row.owner then sendResult(player, false, "Cannot kick owner"); return end
    -- An officer cannot kick another officer/coowner; only coowner+ can.
    local targetRole = Permissions.getRole(row, target)
    local kickerRole = Permissions.getRole(row, user)
    if Permissions.RANK[targetRole] <= Permissions.RANK[kickerRole]
        and Permissions.RANK[kickerRole] > Permissions.RANK.owner
        and not isAdminPlayer(player) then
        sendResult(player, false, "Cannot kick equal/higher rank"); return
    end
    local newMembers = Registry.csvRemove(row.membersCSV, target)
    local newRoles   = Registry.rolesSet(row.rolesCSV, target, "")
    if CSR_ClaimServer and CSR_ClaimServer.commitUpdate then
        local patch = {
            membersCSV = newMembers,
            rolesCSV   = newRoles,
        }
        if row.kind == "vehicle" then
            mergePatch(patch, memberSteamPatch(row, target, "", false))
        end
        CSR_ClaimServer.commitUpdate(cid, patch)
    end
    if (row.kind == "personal" or row.kind == "faction")
        and CSR_SafehouseClaim and CSR_SafehouseClaim.findSafehouseAt then
        local sh = CSR_SafehouseClaim.findSafehouseAt(row.x, row.y, row.w, row.h)
        local list = sh and sh.getPlayers and sh:getPlayers() or nil
        if list and list.remove then
            list:remove(target)
        end
    end
    Audit.log("member_kick", row, player, target, {})
    sendResult(player, true, "Kicked: " .. target)
end

-- =========================================================================
-- Dispatch table consumed by CSR_ClaimServer.dispatch merger
-- =========================================================================

CSR_ClaimInvites.DISPATCH = {
    CSR_ClaimInviteRequest    = CSR_ClaimInvites.handleInviteRequest,
    CSR_ClaimInviteAccept     = CSR_ClaimInvites.handleInviteAccept,
    CSR_ClaimInviteDecline    = CSR_ClaimInvites.handleInviteDecline,
    CSR_ClaimInviteListQuery  = CSR_ClaimInvites.handleInviteListQuery,
    CSR_ClaimMemberKick       = CSR_ClaimInvites.handleMemberKick,
}

-- =========================================================================
-- Event hooks
-- =========================================================================

local function onEveryHours()
    if not isServer() then return end
    CSR_ClaimInvites.scanDissolved()
    cleanupExpired()
end

if Events and Events.EveryHours then Events.EveryHours.Add(onEveryHours) end

return CSR_ClaimInvites
