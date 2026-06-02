--[[
    CSR_ClaimPermissions.lua
    -------------------------------------------------------------------------
    v1.8.35 -- shared role hierarchy + per-action permission predicate for
    every CSR claim. Used by:
      * CSR_ClaimServer (server-authoritative gating on every mutation)
      * CSR_ClaimsManagerPanel (button enable/disable)
      * CSR_VehicleClaimGuards (drive / hotwire / smash)
      * Vanilla SafeHouse fallback hooks (build / dismantle / loot / enter)

    Role hierarchy (lower number = more rights):
        0 = owner       (implicit -- row.owner)
        1 = coowner     (full management except transfer)
        2 = officer     (invite/kick/build/dismantle/highlight, no release)
        3 = member      (build, drive, loot, unlock, enter)
        4 = ally        (enter, unlock; no build/loot)
        5 = outsider    (no access; raid window may grant build/loot)

    Permission matrix is below (`PERMS`). Admin always passes.
    Hard rules:
      * Kahlua: no goto / ::label::
      * No nested tables in the data model -- roles are stored as a flat
        CSV string on the row (rolesCSV), parsed via CSR_ClaimRegistry.rolesGet
--]]

require "CSR_Claims/CSR_ClaimRegistry"

CSR_ClaimPermissions = CSR_ClaimPermissions or {}

local Registry = CSR_ClaimRegistry

CSR_ClaimPermissions.ROLE_OWNER    = "owner"
CSR_ClaimPermissions.ROLE_COOWNER  = "coowner"
CSR_ClaimPermissions.ROLE_OFFICER  = "officer"
CSR_ClaimPermissions.ROLE_MEMBER   = "member"
CSR_ClaimPermissions.ROLE_ALLY     = "ally"
CSR_ClaimPermissions.ROLE_OUTSIDER = "outsider"

local RANK = {
    owner    = 0,
    coowner  = 1,
    officer  = 2,
    member   = 3,
    ally     = 4,
    outsider = 5,
}

CSR_ClaimPermissions.RANK = RANK

-- Permission matrix: action -> minimum required rank (i.e. role rank <= N).
-- Outsiders may unlock special actions during the raid window (handled below).
local PERMS = {
    invite       = RANK.officer,
    kick         = RANK.officer,
    transfer     = RANK.owner,
    release      = RANK.coowner,
    expand       = RANK.coowner,
    setrole      = RANK.coowner,
    setpermission = RANK.coowner,
    edit_title   = RANK.coowner,
    enter        = RANK.ally,
    build        = RANK.member,
    dismantle    = RANK.officer,
    loot         = RANK.member,
    drive        = RANK.member,
    unlock_door  = RANK.ally,
    toggle_hl    = RANK.officer,
    view_audit   = RANK.officer,
    set_respawn  = RANK.member,
    raid_unlock  = RANK.coowner,
    -- v1.8.36 container/vehicle/padlock layer
    move_furniture       = RANK.member,
    open_container       = RANK.ally,
    take_from_container  = RANK.member,
    put_in_container     = RANK.member,
    vehicle_open_trunk   = RANK.member,
    vehicle_part_take    = RANK.officer,
    vehicle_smash        = RANK.officer,
    padlock_install      = RANK.coowner,
    padlock_remove       = RANK.coowner,
    padlock_break        = RANK.outsider, -- outsiders may attempt break (gated by raid + tool)
}

CSR_ClaimPermissions.PERMS = PERMS

local function safeUsername(playerObj)
    if not playerObj then return "" end
    if type(playerObj) == "string" then return playerObj end
    if playerObj.getUsername then
        local u = playerObj:getUsername()
        if u then return tostring(u) end
    end
    return ""
end

local function isAdminPlayer(playerObj)
    if not playerObj or type(playerObj) ~= "userdata" then return false end
    if not playerObj.getAccessLevel then return false end
    local access = playerObj:getAccessLevel()
    if not access then return false end
    return access == "admin" or access == "Admin"
end

local function safeSteamID(playerObj)
    if not playerObj or type(playerObj) ~= "userdata" then return "" end
    if not playerObj.getSteamID then return "" end
    local sid = playerObj:getSteamID()
    if not sid then return "" end
    local s = tostring(sid)
    if s == "" or s == "0" then return "" end
    return s
end

-- Return true if `user` owns the faction `factionName` (vanilla Faction API).
local function userOwnsFaction(user, factionName)
    if not user or user == "" or not factionName or factionName == "" then return false end
    if not Faction or not Faction.getFaction then return false end
    local f = Faction.getFaction(factionName)
    return f and f.isOwner and f:isOwner(user) == true
end

-- Return the role string for `user` on `row`. Resolution order:
--   1. row.owner == user                         -> "owner"
--   2. faction kind + user owns the faction      -> "owner"  (faction-rooted)
--   3. rolesCSV explicit entry                   -> stored role
--   4. listed in membersCSV without role         -> "member"
--   5. otherwise                                 -> "outsider"
function CSR_ClaimPermissions.getRole(row, user)
    if not row then return "outsider" end
    user = safeUsername(user)
    if user == "" then return "outsider" end

    if row.owner and row.owner == user then return "owner" end
    if row.kind == "faction" and row.factionName and row.factionName ~= "" then
        if userOwnsFaction(user, row.factionName) then return "owner" end
    end

    local explicit = Registry.rolesGet and Registry.rolesGet(row.rolesCSV or "", user) or nil
    if explicit and explicit ~= "" and RANK[explicit] then return explicit end

    if row.membersCSV and row.membersCSV ~= ""
        and Registry.csvContains and Registry.csvContains(row.membersCSV, user) then
        return "member"
    end

    -- Faction kind: members of the faction are auto-allies.
    if row.kind == "faction" and row.factionName and row.factionName ~= "" then
        if Faction and Faction.getFaction then
            local isFactionMember = false
            local f = Faction.getFaction(row.factionName)
            if f and f.getPlayers then
                local list = f:getPlayers()
                if list and list.size then
                    local n = tonumber(list:size()) or 0
                    for i = 0, n - 1 do
                        local u = list:get(i)
                        if u and tostring(u) == user then
                            isFactionMember = true; break
                        end
                    end
                end
            end
            if isFactionMember then return "ally" end
        end
    end

    return "outsider"
end

function CSR_ClaimPermissions.getRank(row, user)
    return RANK[CSR_ClaimPermissions.getRole(row, user)] or RANK.outsider
end

-- Sandbox-driven raid-window predicate. Two integer sandbox vars:
--   ClaimRaidStart (0..23) and ClaimRaidEnd (0..23). If start <= end the
--   window is [start, end); if start > end the window wraps midnight.
--   Disabled entirely unless ClaimRaidEnabled == true.
function CSR_ClaimPermissions.isRaidActive()
    local sb = (SandboxVars and SandboxVars.CommonSenseReborn) or nil
    if not sb then return false end
    if sb.ClaimRaidEnabled ~= true then return false end
    local s = tonumber(sb.ClaimRaidStart) or 0
    local e = tonumber(sb.ClaimRaidEnd) or 0
    if s == e then return false end
    local hour = 0
    if getGameTime then
        local gt = getGameTime()
        if gt and gt.getTimeOfDay then
            hour = math.floor(tonumber(gt:getTimeOfDay()) or 0)
        end
    end
    if s <= e then
        if hour >= s and hour < e then return true end
    else
        if hour >= s or hour < e then return true end
    end
    return false
end

-- The core predicate: does `user` have permission to perform `action` on `row`?
-- `playerObj` is optional; if supplied admins always pass.
function CSR_ClaimPermissions.canDo(row, user, action, playerObj)
    if not row or not action then return false end
    if isAdminPlayer(playerObj) then return true end

    local rank = nil
    if row.kind == "vehicle" then
        local sid = safeSteamID(playerObj)
        if sid ~= "" and tostring(row.ownerSteamID or "") == sid then
            rank = RANK.owner
        elseif sid ~= "" and Registry.csvContains
                and Registry.csvContains(row.memberSteamIDsCSV or "", sid) then
            local role = Registry.rolesGet and Registry.rolesGet(row.rolesCSV or "", user) or nil
            rank = RANK[role or "member"] or RANK.member
        end
    end
    if not rank then rank = CSR_ClaimPermissions.getRank(row, user) end
    local need = PERMS[action]

    -- Raid window: outsiders may build/loot if sandbox unlocks them.
    if rank >= RANK.outsider and CSR_ClaimPermissions.isRaidActive() then
        local sb = (SandboxVars and SandboxVars.CommonSenseReborn) or {}
        if action == "build" and sb.ClaimRaidAllowBuild == true then return true end
        if action == "dismantle" and sb.ClaimRaidAllowBuild == true then return true end
        if action == "loot" and sb.ClaimRaidAllowLoot == true then return true end
        if action == "drive" and sb.ClaimRaidAllowLoot == true then return true end
    end

    if not need then return false end
    return rank <= need
end

-- Convenience: viewer rights consumed by the manager panel and context menus.
function CSR_ClaimPermissions.viewerRights(row, playerObj)
    local user = safeUsername(playerObj)
    local admin = isAdminPlayer(playerObj)
    local role = CSR_ClaimPermissions.getRole(row, user)
    local rank = RANK[role] or RANK.outsider
    return {
        user      = user,
        admin     = admin,
        role      = role,
        rank      = rank,
        canSee    = admin or rank < RANK.outsider,
        canManage = admin or rank <= RANK.coowner,
        canInvite = admin or rank <= RANK.officer,
        canKick   = admin or rank <= RANK.officer,
        canRelease = admin or rank <= RANK.coowner,
        canExpand = admin or rank <= RANK.coowner,
        canTransfer = admin or rank <= RANK.owner,
        canSetRole = admin or rank <= RANK.coowner,
        canHL     = admin or rank <= RANK.officer,
        canAudit  = admin or rank <= RANK.officer,
        canMove   = admin or rank <= RANK.member,
        canOpen   = admin or rank <= RANK.ally,
        canTake   = admin or rank <= RANK.member,
        canVTrunk = admin or rank <= RANK.member,
        canVPart  = admin or rank <= RANK.officer,
        canPadlock = admin or rank <= RANK.coowner,
    }
end

return CSR_ClaimPermissions
