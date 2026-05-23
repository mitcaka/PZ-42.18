--[[
    CSR_ClaimServer.lua
    -------------------------------------------------------------------------
    Track B (v1.8.0) -- authoritative server logic for the CSR claim system.

    Responsibilities:
      1. Receive client requests (ClaimRequest, ReleaseRequest, TransferRequest,
         SetRoleRequest, GetClaimsBundle), validate them, and mutate
         CSR_ClaimRegistry rows accordingly.
      2. Broadcast every mutation to all clients via sendServerCommand
         (CSR_ClaimAdded / CSR_ClaimRemoved / CSR_ClaimUpdated) so each client
         can mirror the row into its local SafeHouse instance.
      3. Maintain a quiet server-side SafeHouse mirror for personal/faction
         rows so Java-side systems such as LootRespawn can see CSR claims.
      4. On OnServerStarted, perform a one-shot migration that imports every
         existing vanilla SafeHouse from getSafehouseList() into the registry
         as kind="personal" rows with migratedFromVanilla=1.

    Hard rules:
      * NEVER route player/square claims through SafeHouse.addSafeHouse()
        server-side. The server mirror uses only the bounds overload
        SafeHouse.addSafeHouse(x, y, w, h, owner), which mutates the local
        SafeHouse list without the broken client-claim packet path.
      * Trust player:getUsername() for write ops. NEVER trust args.username.
      * ModData rows are flat primitives only -- enforced by the registry.
      * Kahlua: no goto / ::label::. No :split() on Lua strings.

    This module is dormant until CSR_ServerCommands.lua adds thin dispatch
    shims for it (Step 8). Hooking OnServerStarted on its own is safe -- the
    migration is idempotent and gated by a one-shot flag.
--]]

require "CSR_Claims/CSR_ClaimRegistry"
require "CSR_SafehouseClaim"
require "CSR_Claims/CSR_ClaimRespawn"
require "CSR_Claims/CSR_ClaimAudit"
require "CSR_Claims/CSR_ClaimInvites"
require "CSR_Claims/CSR_ClaimPermissions"
require "CSR_Claims/CSR_PadlockServer"
require "CSR_VehicleClaim"

CSR_ClaimServer = CSR_ClaimServer or {}

local Registry = CSR_ClaimRegistry

-- =========================================================================
-- Constants
-- =========================================================================

local MIGRATION_FLAG = "CSR_Claims_MigrationDone"
local CMD_ADDED      = "CSR_ClaimAdded"
local CMD_REMOVED    = "CSR_ClaimRemoved"
local CMD_UPDATED    = "CSR_ClaimUpdated"
local CMD_BUNDLE     = "CSR_ClaimsBundle"
local CMD_RESULT     = "CSR_ClaimResult"

local MAX_TITLE_LEN = 64
local MAX_W = 64
local MAX_H = 64
local EXPAND_COST_UNIT_TILES = 10

local VEHICLE_OWNER_KEY   = "CSR_VehicleOwner"
local VEHICLE_ALLOWED_KEY = "CSR_VehicleAllowed"
local VEHICLE_RELEASED_AT = "CSR_VehicleClaimReleasedAt"
local VEHICLE_CLAIM_KEY   = "CSR_VehicleClaimKey"
local VEHICLE_SQL_ID_KEY  = "CSR_VehicleSqlId"
local VEHICLE_RUNTIME_KEY = "CSR_VehicleRuntimeId"
local VEHICLE_VERSION_KEY = "CSR_VehicleClaimVersion"
local VEHICLE_CLAIM_KEY_ID = "CSR_VehicleClaimKeyId"
local VEHICLE_CLAIM_KEY_TOKEN = "CSR_VehicleClaimKeyToken"
local VEHICLE_CLAIM_KEY_OWNER = "CSR_VehicleClaimKeyOwnerSteamID"
local KEY_ITEM_VEHICLE_KEY = "CSR_ClaimVehicleKey"
local KEY_ITEM_TOKEN = "CSR_ClaimKeyToken"
local KEY_ITEM_OWNER = "CSR_ClaimKeyOwnerSteamID"

local _expandCooldowns = {}

-- =========================================================================
-- Internal helpers
-- =========================================================================

local function nowTs()
    if os and os.time then return tonumber(os.time()) or 0 end
    return 0
end

local function getModDataRoot()
    if not getGameTime then return nil end
    local gt = getGameTime()
    if not gt or not gt.getModData then return nil end
    return gt:getModData()
end

local function safeUsername(player)
    if not player then return "" end
    if player.getUsername then
        local u = player:getUsername()
        if u then return tostring(u) end
    end
    return ""
end

-- v1.8.14: best-effort Steam-ID lookup. Returns "" on non-Steam servers, on
-- single-player, or whenever the engine doesn't expose the getter on the
-- player object. Stored on the row as defense-in-depth metadata only --
-- ownership matching still uses the username (server-stamped at claim time).
local function safeSteamID(player)
    if not player then return "" end
    if player.getSteamID then
        local sid = player:getSteamID()
        if sid then
            local s = tostring(sid)
            if s ~= "" and s ~= "0" then return s end
        end
    end
    return ""
end

local function findOnlinePlayerByUsername(username)
    username = tostring(username or "")
    if username == "" or not getOnlinePlayers then return nil end
    local players = getOnlinePlayers()
    if not players or not players.size then return nil end
    local count = tonumber(players:size()) or 0
    for i = 0, count - 1 do
        local p = players:get(i)
        if p and p.getUsername and tostring(p:getUsername() or "") == username then
            return p
        end
    end
    return nil
end

local function steamIDForUsername(username)
    return safeSteamID(findOnlinePlayerByUsername(username))
end

local function memberSteamPatch(row, username, addMember)
    local patch = {}
    if not row or not username or username == "" or not Registry then return patch end
    local currentIDs = tostring(row.memberSteamIDsCSV or "")
    local currentMap = tostring(row.memberSteamMapCSV or "")
    if addMember then
        local sid = steamIDForUsername(username)
        if sid ~= "" then
            if Registry.csvAdd then patch.memberSteamIDsCSV = Registry.csvAdd(currentIDs, sid) end
            if Registry.mapSet then patch.memberSteamMapCSV = Registry.mapSet(currentMap, username, sid) end
        end
    else
        local sid = Registry.mapGet and Registry.mapGet(currentMap, username) or ""
        if sid ~= "" and Registry.csvRemove then
            patch.memberSteamIDsCSV = Registry.csvRemove(currentIDs, sid)
        end
        if Registry.mapRemove then
            patch.memberSteamMapCSV = Registry.mapRemove(currentMap, username)
        end
    end
    return patch
end

local function mergePatch(dst, src)
    dst = dst or {}
    if type(src) ~= "table" then return dst end
    for k, v in pairs(src) do dst[k] = v end
    return dst
end

local function sendResult(player, ok, text)
    if not player then return end
    sendServerCommand(player, "CommonSenseReborn", CMD_RESULT, {
        ok   = ok and 1 or 0,
        text = tostring(text or ""),
    })
end

-- Server-side admin check.
local function isAdminPlayer(player)
    if not player or not player.getAccessLevel then return false end
    local access = player:getAccessLevel()
    return access == "admin" or access == "Admin"
end

-- Returns true if `user` can manage `row` -- i.e. is row.owner, server admin,
-- or (for faction rows) the owner of the faction that holds the claim.
-- Mirrors viewerRights() in the client-side CSR_ClaimsManagerPanel so admin
-- and faction-owner Release/Transfer/SetRole clicks are not silently rejected.
-- v1.8.35: now also delegates to CSR_ClaimPermissions for role-based
-- coowner-tier authorisation (coowner can release / setrole, officer cannot).
local function canManage(player, row, user)
    if not row then return false end
    if user ~= "" and row.owner == user then return true end
    if isAdminPlayer(player) then return true end
    if row.kind == "faction" and row.factionName and row.factionName ~= ""
        and Faction and Faction.getFaction and user ~= "" then
        local f = Faction.getFaction(row.factionName)
        if f and f.isOwner and f:isOwner(user) then return true end
    end
    if CSR_ClaimPermissions and CSR_ClaimPermissions.canDo then
        if CSR_ClaimPermissions.canDo(row, user, "release", player) then
            return true
        end
    end
    return false
end

-- Broadcast helper -- sends to every connected client. The mutation handlers
-- below all call this after a successful registry write so every client can
-- update its local SafeHouse mirror.
local function broadcast(cmd, payload)
    sendServerCommand("CommonSenseReborn", cmd, payload)
end

-- Distance gate -- matches the pattern used elsewhere in CSR_ServerCommands.
-- A claim request must originate from a player standing inside the bounds.
local function playerInsideBounds(player, x, y, w, h)
    if not player or not x or not y then return false end
    local px = tonumber(player:getX()) or -1
    local py = tonumber(player:getY()) or -1
    local x2 = x + (w or 1)
    local y2 = y + (h or 1)
    return px >= x and px < x2 and py >= y and py < y2
end

local function clampInt(v, lo, hi)
    local n = math.floor(tonumber(v) or 0)
    if lo and n < lo then n = lo end
    if hi and n > hi then n = hi end
    return n
end

local function sanitizeTitle(s)
    if not s then return "" end
    local t = tostring(s)
    if #t > MAX_TITLE_LEN then t = string.sub(t, 1, MAX_TITLE_LEN) end
    -- Strip newlines (modData serializer can mangle them).
    t = t:gsub("[\r\n]", " ")
    return t
end

-- Sandbox gate -- defaults to enabled if the feature flag module is not yet
-- present (Step 10 adds the toggle).
local function overrideEnabled()
    if CSR_FeatureFlags and CSR_FeatureFlags.isClaimsOverrideEnabled then
        return CSR_FeatureFlags.isClaimsOverrideEnabled() == true
    end
    return true
end

local function rowHasSafehouseMirror(row)
    return row and (row.kind == "personal" or row.kind == "faction")
end

local function safehouseList()
    if not SafeHouse then return nil end
    if SafeHouse.getSafehouseList then return SafeHouse.getSafehouseList() end
    if SafeHouse.getSafeHouseList then return SafeHouse.getSafeHouseList() end
    return nil
end

local function safehouseBounds(sh)
    if not sh or not sh.getX or not sh.getY then return nil end
    local x = tonumber(sh:getX()) or 0
    local y = tonumber(sh:getY()) or 0
    local w = nil
    local h = nil
    if sh.getW and sh.getH then
        w = tonumber(sh:getW()) or 0
        h = tonumber(sh:getH()) or 0
    elseif sh.getX2 and sh.getY2 then
        w = (tonumber(sh:getX2()) or x) - x + 1
        h = (tonumber(sh:getY2()) or y) - y + 1
    end
    if not w or not h or w <= 0 or h <= 0 then return nil end
    return x, y, w, h
end

local function safehouseMatchesRow(sh, row)
    if not sh or not row then return false end
    local x, y, w, h = safehouseBounds(sh)
    if not x then return false end
    return x == (tonumber(row.x) or 0)
        and y == (tonumber(row.y) or 0)
        and w == (tonumber(row.w) or 1)
        and h == (tonumber(row.h) or 1)
end

local function findExactSafehouse(row)
    if not row or not SafeHouse then return nil end
    local x = tonumber(row.x) or 0
    local y = tonumber(row.y) or 0
    local w = tonumber(row.w) or 1
    local h = tonumber(row.h) or 1

    if SafeHouse.getSafeHouse then
        local sh = SafeHouse.getSafeHouse(x, y, w, h)
        if sh and safehouseMatchesRow(sh, row) then return sh end
    end

    local list = safehouseList()
    if not list or not list.size or not list.get then return nil end
    local n = tonumber(list:size()) or 0
    for i = 0, n - 1 do
        local sh = list:get(i)
        if safehouseMatchesRow(sh, row) then return sh end
    end
    return nil
end

local function applySafehouseMirrorFields(sh, row)
    if not sh or not row then return end
    local owner = tostring(row.owner or "")
    if sh.setOwner and owner ~= "" then sh:setOwner(owner) end
    if sh.setTitle and row.title and row.title ~= "" then
        sh:setTitle(tostring(row.title))
    end

    if sh.getPlayers then
        local list = sh:getPlayers()
        if list and list.clear then list:clear() end
    end
    if sh.addPlayer and Registry.csvList then
        local members = Registry.csvList(row.membersCSV or "")
        for i = 1, #members do
            if members[i] ~= "" and members[i] ~= owner then
                sh:addPlayer(members[i])
            end
        end
    end
end

local function ensureServerSafehouseMirror(row)
    if not rowHasSafehouseMirror(row) then return nil end
    if not SafeHouse or not SafeHouse.addSafeHouse then return nil end

    local sh = findExactSafehouse(row)
    if not sh then
        sh = SafeHouse.addSafeHouse(
            tonumber(row.x) or 0,
            tonumber(row.y) or 0,
            tonumber(row.w) or 1,
            tonumber(row.h) or 1,
            tostring(row.owner or "")
        )
    end
    if sh then applySafehouseMirrorFields(sh, row) end
    return sh
end

local function removeServerSafehouseMirror(row)
    if not rowHasSafehouseMirror(row) then return false end
    local sh = findExactSafehouse(row)
    if not sh then return false end
    if SafeHouse and SafeHouse.removeSafeHouse then
        SafeHouse.removeSafeHouse(sh)
        return true
    end
    local list = safehouseList()
    if list and list.remove then
        if sh.getPlayers then
            local players = sh:getPlayers()
            if players and players.clear then players:clear() end
        end
        list:remove(sh)
        return true
    end
    return false
end

local function boundsChanged(a, b)
    if not a or not b then return false end
    return (tonumber(a.x) or 0) ~= (tonumber(b.x) or 0)
        or (tonumber(a.y) or 0) ~= (tonumber(b.y) or 0)
        or (tonumber(a.w) or 1) ~= (tonumber(b.w) or 1)
        or (tonumber(a.h) or 1) ~= (tonumber(b.h) or 1)
end

local function syncServerSafehouseMirrors()
    local count = 0
    Registry.iterShards(function(row)
        if rowHasSafehouseMirror(row) and ensureServerSafehouseMirror(row) then
            count = count + 1
        end
    end)
    if count > 0 then
        print("[CSR] Synced " .. tostring(count)
            .. " server SafeHouse mirrors for loot-respawn protection.")
    end
    return count
end

-- =========================================================================
-- Mutation primitives (server-side -- registry write + broadcast)
-- =========================================================================

local function commitAdd(spec)
    -- v1.8.36+: dedupe vehicle rows by durable vehicleKey only. Runtime
    -- vehicle ids are not tracked by the claim registry.
    if spec and spec.kind == "vehicle" then
        local vehicleKey = tostring(spec.vehicleKey or "")
        local existing = nil
        if vehicleKey ~= "" and Registry.getRowByVehicleKey then
            existing = Registry.getRowByVehicleKey(vehicleKey)
        end
        if existing then
            local patch = { lastSeen = nowTs() }
            if vehicleKey ~= "" then
                patch.vehicleKey = vehicleKey
                patch.vehicleId = vehicleKey
            end
            if spec.vehicleSqlId then patch.vehicleSqlId = tostring(spec.vehicleSqlId or "") end
            patch.vehicleRuntimeId = ""
            if spec.vehicleScript then patch.vehicleScript = tostring(spec.vehicleScript or "") end
            if spec.vehicleClaimVersion then patch.vehicleClaimVersion = tonumber(spec.vehicleClaimVersion) or 2 end
            if spec.lastVehicleX then patch.lastVehicleX = tonumber(spec.lastVehicleX) or 0 end
            if spec.lastVehicleY then patch.lastVehicleY = tonumber(spec.lastVehicleY) or 0 end
            if spec.lastVehicleZ then patch.lastVehicleZ = tonumber(spec.lastVehicleZ) or 0 end
            local updated = Registry.updateRow(existing.id, patch) or existing
            broadcast(CMD_UPDATED, Registry.serializeRow(updated))
            return updated
        end
    end
    local row = Registry.makeRow(spec)
    row.id = Registry.nextId()
    if row.createdAt == 0 then row.createdAt = nowTs() end
    row.lastSeen = nowTs()
    Registry.addRow(row)
    ensureServerSafehouseMirror(row)
    broadcast(CMD_ADDED, Registry.serializeRow(row))
    return row
end

local function commitRemove(id)
    local row = Registry.getRowById(id)
    if not row then return false end
    removeServerSafehouseMirror(row)
    Registry.removeRow(id)
    broadcast(CMD_REMOVED, { id = tonumber(id) or 0 })
    -- v1.8.5: belt-and-braces broadcast for vehicle rows. Whoever has the
    -- chunk loaded will receive this and clear the legacy modData mirror,
    -- closing the gap where commitRemove on an unloaded chunk could not
    -- reach the vehicle to clear CSR_VehicleOwner / CSR_VehicleAllowed.
    if row.kind == "vehicle" then
        broadcast("CSR_VehicleClaimCleared", {
            vehicleKey       = tostring(row.vehicleKey or ""),
            vehicleSqlId     = tostring(row.vehicleSqlId or ""),
            vehicleId        = tostring(row.vehicleKey or ""),
            vehicleRuntimeId = "",
        })
        -- Server-side modData clear (best-effort) for whichever vehicle the
        -- server can resolve right now. Clients on the chunk also clear via
        -- the broadcast above; this covers the dedicated-server-only case.
        local v = nil
        if CSR_VehicleClaim and CSR_VehicleClaim.findLoadedVehicleByRow then
            v = CSR_VehicleClaim.findLoadedVehicleByRow(row)
        end
        if v and CSR_VehicleClaim and CSR_VehicleClaim.clearOwner then
            local key = tostring(row.vehicleKey or "")
            local matches = false
            if not matches and CSR_VehicleClaim.getVehicleKeyCandidates then
                local keys = CSR_VehicleClaim.getVehicleKeyCandidates(v, false)
                for i = 1, #keys do
                    if keys[i] == key then matches = true; break end
                end
            end
            if matches then
                CSR_VehicleClaim.clearOwner(v)
                if v.transmitModData then v:transmitModData() end
            end
        end
    end
    -- Best-effort cleanup of any respawn pin that referenced this row.
    if CSR_ClaimRespawn and CSR_ClaimRespawn.onClaimRemoved then
        CSR_ClaimRespawn.onClaimRemoved(id)
    end
    return true
end

local function sandbox()
    return (SandboxVars and SandboxVars.CommonSenseReborn) or {}
end

local function expansionEnabled()
    return sandbox().EnableClaimExpansion ~= false
end

local function expansionMaxWidth()
    return clampInt(sandbox().ClaimExpansionMaxWidth or 96, 1, 500)
end

local function expansionMaxHeight()
    return clampInt(sandbox().ClaimExpansionMaxHeight or 96, 1, 500)
end

local function expansionMaxAddedTiles()
    return clampInt(sandbox().ClaimExpansionMaxAddedTiles or 1024, 0, 100000)
end

local function expansionCooldownMinutes()
    return clampInt(sandbox().ClaimExpansionCooldownMinutes or 10, 0, 1440)
end

local function expansionMoneyPerUnit()
    return clampInt(sandbox().ClaimExpansionMoneyPer10Tiles or 1, 0, 10000)
end

local function expansionMaterialsPerUnit()
    return clampInt(sandbox().ClaimExpansionMaterialsPer10Tiles or 2, 0, 10000)
end

local function expansionRequiresPlayerInside()
    return sandbox().ClaimExpansionRequirePlayerInside ~= false
end

local function expansionBlocksNonMembersInside()
    return sandbox().ClaimExpansionBlockNonMembersInside ~= false
end

local function expansionRequiresArchitect()
    return sandbox().ClaimExpansionRequireArchitect == true
end

local function expansionArchitectCarpentryLevel()
    return clampInt(sandbox().ClaimExpansionArchitectCarpentryLevel or 4, 0, 10)
end

local function ceilDiv(n, d)
    n = tonumber(n) or 0
    d = tonumber(d) or 1
    if n <= 0 then return 0 end
    return math.floor((n + d - 1) / d)
end

local function expansionCosts(addedTiles)
    local units = ceilDiv(addedTiles, EXPAND_COST_UNIT_TILES)
    return units * expansionMoneyPerUnit(), units * expansionMaterialsPerUnit()
end

local function playerInsideRect(player, x, y, w, h)
    if not player then return false end
    local px = tonumber(player:getX()) or -1
    local py = tonumber(player:getY()) or -1
    return px >= x and px < (x + w) and py >= y and py < (y + h)
end

local function requestCooldownKey(rowId, user)
    return tostring(rowId or 0) .. ":" .. tostring(user or "")
end

local function cooldownNowSeconds()
    if getTimestampMs then return math.floor((tonumber(getTimestampMs()) or 0) / 1000) end
    if os and os.time then return tonumber(os.time()) or 0 end
    return 0
end

local function checkExpansionCooldown(rowId, user)
    local mins = expansionCooldownMinutes()
    if mins <= 0 then return true, 0 end
    local key = requestCooldownKey(rowId, user)
    local now = cooldownNowSeconds()
    local untilTs = tonumber(_expandCooldowns[key]) or 0
    if untilTs > now then return false, untilTs - now end
    return true, 0
end

local function stampExpansionCooldown(rowId, user)
    local mins = expansionCooldownMinutes()
    if mins <= 0 then return end
    _expandCooldowns[requestCooldownKey(rowId, user)] = cooldownNowSeconds() + (mins * 60)
end

local function getProfessionName(player)
    if not player or not player.getDescriptor then return "" end
    local desc = player:getDescriptor()
    if not desc then return "" end
    local prof = ""
    if desc.getProfession then prof = tostring(desc:getProfession() or "") end
    if prof == "" then
        if desc.getCharacterProfession then
            prof = tostring(desc:getCharacterProfession() or "")
        end
    end
    return string.lower(prof or "")
end

local function getCarpentryLevel(player)
    if not player or not player.getPerkLevel or not Perks then return 0 end
    local lvl = 0
    local perk = Perks.Woodwork or (Perks.FromString and Perks.FromString("Woodwork")) or nil
    if perk then lvl = tonumber(player:getPerkLevel(perk)) or 0 end
    return lvl
end

local function hasArchitectCredentials(player)
    if not expansionRequiresArchitect() then return true end
    if isAdminPlayer(player) then return true end
    local prof = getProfessionName(player)
    if prof ~= "" then
        if string.find(prof, "architect", 1, true)
                or prof == "carpenter"
                or prof == "constructionworker"
                or prof == "engineer" then
            return true
        end
    end
    return getCarpentryLevel(player) >= expansionArchitectCarpentryLevel()
end

local MONEY_TYPES = {
    ["Base.Money"] = true,
    ["Money"] = true,
}

local RESOURCE_POINTS = {
    ["Base.Plank"] = 1,
    ["Base.SheetMetal"] = 1,
    ["Base.SmallSheetMetal"] = 1,
    ["Base.LeadPipe"] = 1,
    ["Base.MetalPipe"] = 1,
    ["Base.MetalBar"] = 1,
    ["Base.TreeBranch2"] = 1,
    ["Base.WoodenStick2"] = 1,
    ["Base.CSR_BoundPlanks5"] = 5,
    ["Base.CSR_BoundPlanks10"] = 10,
    ["Base.CSR_BoundPlanks20"] = 20,
    ["Base.CSR_BoundSheetMetal5"] = 5,
    ["Base.CSR_BoundSheetMetal10"] = 10,
    ["Base.CSR_BoundSheetMetal20"] = 20,
    ["Base.CSR_BoundSmallSheetMetal5"] = 5,
    ["Base.CSR_BoundSmallSheetMetal10"] = 10,
    ["Base.CSR_BoundSmallSheetMetal20"] = 20,
    ["Base.CSR_BoundLeadPipes5"] = 5,
    ["Base.CSR_BoundLeadPipes10"] = 10,
    ["Base.CSR_BoundLeadPipes20"] = 20,
    ["Base.CSR_BoundMetalPipes5"] = 5,
    ["Base.CSR_BoundMetalPipes10"] = 10,
    ["Base.CSR_BoundMetalPipes20"] = 20,
    ["Base.CSR_BoundMetalBars5"] = 5,
    ["Base.CSR_BoundMetalBars10"] = 10,
    ["Base.CSR_BoundMetalBars20"] = 20,
    ["Base.CSR_BoundTreeBranches5"] = 5,
    ["Base.CSR_BoundTreeBranches10"] = 10,
    ["Base.CSR_BoundTreeBranches20"] = 20,
    ["Base.CSR_BoundWoodenSticks5"] = 5,
    ["Base.CSR_BoundWoodenSticks10"] = 10,
    ["Base.CSR_BoundWoodenSticks20"] = 20,
    ["Base.CSR_MixedConstructionBundle"] = 15,
}

local function itemFullType(item)
    if not item then return "" end
    local ft = ""
    if item.getFullType then ft = tostring(item:getFullType() or "") end
    if ft ~= "" then return ft end
    if item.getType then ft = tostring(item:getType() or "") end
    return ft or ""
end

local function walkInventory(inv, fn, visited)
    if not inv or not inv.getItems or type(fn) ~= "function" then return end
    visited = visited or {}
    if visited[inv] then return end
    visited[inv] = true
    local items = inv:getItems()
    if not items or not items.size then return end
    local n = tonumber(items:size()) or 0
    for i = 0, n - 1 do
        local item = items:get(i)
        if item then
            fn(item, item.getContainer and item:getContainer() or inv)
        end
    end
    for i = 0, n - 1 do
        local item = items:get(i)
        local sub = nil
        if item and item.getInventory then
            sub = item:getInventory()
        end
        if sub then walkInventory(sub, fn, visited) end
    end
end

local function collectExpansionCostItems(player)
    local result = { money = 0, materials = 0, moneyItems = {}, materialItems = {} }
    if not player or not player.getInventory then return result end
    local inv = player:getInventory()
    if not inv then return result end
    walkInventory(inv, function(item, container)
        local ft = itemFullType(item)
        local typ = ft
        if item and item.getType then
            typ = tostring(item:getType() or ft)
        end
        if MONEY_TYPES[ft] or MONEY_TYPES[typ] then
            result.money = result.money + 1
            result.moneyItems[#result.moneyItems + 1] = {
                item = item, container = container, value = 1,
            }
        end
        local points = RESOURCE_POINTS[ft] or RESOURCE_POINTS["Base." .. tostring(typ or "")]
        if points and points > 0 then
            result.materials = result.materials + points
            result.materialItems[#result.materialItems + 1] = {
                item = item, container = container, value = points,
            }
        end
    end)
    return result
end

local function removeCostItem(entry)
    if not entry or not entry.item then return end
    local container = entry.container
    if not container and entry.item.getContainer then
        container = entry.item:getContainer()
    end
    if not container then return end
    if container.Remove then
        container:Remove(entry.item)
    elseif container.DoRemoveItem then
        container:DoRemoveItem(entry.item)
    end
    if sendRemoveItemFromContainer then
        sendRemoveItemFromContainer(container, entry.item)
    end
end

local function consumeCostList(list, needed)
    needed = tonumber(needed) or 0
    if needed <= 0 then return end
    table.sort(list, function(a, b)
        return (tonumber(a.value) or 0) < (tonumber(b.value) or 0)
    end)
    local remaining = needed
    for i = 1, #list do
        if remaining <= 0 then break end
        local entry = list[i]
        removeCostItem(entry)
        remaining = remaining - (tonumber(entry.value) or 0)
    end
end

local function chargeExpansionCosts(player, moneyCost, materialCost)
    moneyCost = tonumber(moneyCost) or 0
    materialCost = tonumber(materialCost) or 0
    if moneyCost <= 0 and materialCost <= 0 then return true, "" end
    local found = collectExpansionCostItems(player)
    if found.money < moneyCost then
        return false, "Need $" .. tostring(moneyCost) .. " Money items (have " .. tostring(found.money) .. ")"
    end
    if found.materials < materialCost then
        return false, "Need " .. tostring(materialCost) .. " construction material points (have " .. tostring(found.materials) .. ")"
    end
    consumeCostList(found.moneyItems, moneyCost)
    consumeCostList(found.materialItems, materialCost)
    if player and player.getInventory then
        local inv = player:getInventory()
        if inv then
            if inv.setDrawDirty then inv:setDrawDirty(true) end
            if inv.setDirtySlots then inv:setDirtySlots(true) end
        end
    end
    return true, ""
end

local function hasBlockedPlayerInside(row, nx, ny, nw, nh)
    if not expansionBlocksNonMembersInside() then return false, "" end
    if not getOnlinePlayers then return false, "" end
    local players = getOnlinePlayers()
    if not players or not players.size then return false, "" end
    local n = tonumber(players:size()) or 0
    for i = 0, n - 1 do
        local other = players:get(i)
        if other and not isAdminPlayer(other) then
            local insideNew = playerInsideRect(other, nx, ny, nw, nh)
            local insideOld = playerInsideRect(other, row.x, row.y, row.w, row.h)
            if insideNew and not insideOld then
                local user = safeUsername(other)
                local allowed = false
                if CSR_ClaimPermissions and CSR_ClaimPermissions.canDo then
                    allowed = CSR_ClaimPermissions.canDo(row, user, "enter", other)
                end
                if not allowed then
                    return true, user
                end
            end
        end
    end
    return false, ""
end

local function commitUpdate(id, patch)
    local prev = Registry.getRowById(id)
    if prev then prev = Registry.makeRow(prev) end
    local row = Registry.updateRow(id, patch)
    if not row then return nil end
    row.lastSeen = nowTs()
    if rowHasSafehouseMirror(prev) and not rowHasSafehouseMirror(row) then
        removeServerSafehouseMirror(prev)
    elseif rowHasSafehouseMirror(row) then
        if rowHasSafehouseMirror(prev) and boundsChanged(prev, row) then
            removeServerSafehouseMirror(prev)
        end
        ensureServerSafehouseMirror(row)
    end
    broadcast(CMD_UPDATED, Registry.serializeRow(row))
    return row
end

-- Public wrappers so other server modules (e.g. the legacy radial-menu
-- handlers in CSR_ServerCommands) can route their writes through the unified
-- registry + broadcast path without duplicating logic.
function CSR_ClaimServer.commitAdd(spec)    return commitAdd(spec) end
function CSR_ClaimServer.commitRemove(id)   return commitRemove(id) end
function CSR_ClaimServer.commitUpdate(id, p) return commitUpdate(id, p) end

local function vehicleTitle(vehicle)
    local title = ""
    if vehicle and vehicle.getScript then
        local script = vehicle:getScript()
        if script and script.getName then title = tostring(script:getName() or "") end
    end
    if title == "" then title = "Vehicle" end
    return title
end

local function vehicleModData(vehicle)
    if not vehicle or not vehicle.getModData then return nil end
    return vehicle:getModData()
end

local function allowedTableToCSV(allowed)
    local csv = ""
    if type(allowed) ~= "table" then return csv end
    for _, name in ipairs(allowed) do
        name = tostring(name or "")
        if name ~= "" then csv = Registry.csvAdd(csv, name) end
    end
    return csv
end

local function looksLikeVehicleKey(value)
    if not value or value == "" then return false end
    value = tostring(value)
    return string.sub(value, 1, 4) == "sql:" or string.sub(value, 1, 4) == "csr:"
end

local function normalizePositiveId(value)
    if value == nil then return nil end
    local s = tostring(value)
    if s == "" or s == "nil" then return nil end
    local n = tonumber(s)
    if not n or n <= 0 then return nil end
    return tostring(math.floor(n))
end

local function vehicleMatchesKey(vehicle, key)
    if not vehicle or not looksLikeVehicleKey(key) then return false end
    if not (CSR_VehicleClaim and CSR_VehicleClaim.getVehicleKeyCandidates) then
        return false
    end
    local keys = CSR_VehicleClaim.getVehicleKeyCandidates(vehicle, false)
    for i = 1, #keys do
        if keys[i] == key then return true end
    end
    return false
end

local function resolveVehicleClaimRequestVehicle(player, args)
    local key = tostring((args and (args.vehicleKey or args.vehicleId)) or "")
    if not looksLikeVehicleKey(key) then key = "" end

    local seated = player and player.getVehicle and player:getVehicle() or nil
    if key ~= "" then
        if vehicleMatchesKey(seated, key) then return seated end
        if CSR_VehicleClaim and CSR_VehicleClaim.findLoadedVehicleByKey then
            local byKey = CSR_VehicleClaim.findLoadedVehicleByKey(key)
            if byKey then return byKey end
        end
        -- Client vehicle keys can lag behind the server object after load,
        -- conversion, or registry repair. New vehicle claims are only valid
        -- while seated, so use the server's current vehicle as authority.
        if seated then return seated end
        return nil
    end

    -- New vehicle claims are initiated while the player is in the vehicle.
    -- The server object is authoritative; it will receive a CSR key before
    -- the registry row is written.
    return seated
end

function CSR_ClaimServer.touchVehicleRow(rowId, vehicle)
    if not isServer() then return nil end
    if not rowId or not vehicle then return nil end
    local row = Registry.getRowById(rowId)
    if not row or row.kind ~= "vehicle" then return nil end
    if not (CSR_VehicleClaim and CSR_VehicleClaim.getVehicleIdentity) then return row end

    local ident = CSR_VehicleClaim.getVehicleIdentity(vehicle, true)
    if not ident then return row end

    local patch = {}
    local changed = false
    local function setString(field, value)
        value = tostring(value or "")
        if value ~= "" and tostring(row[field] or "") ~= value then
            patch[field] = value
            changed = true
        end
    end
    local function setNumber(field, value)
        value = tonumber(value) or 0
        if tonumber(row[field]) ~= value then
            patch[field] = value
            changed = true
        end
    end

    setString("vehicleKey", ident.vehicleKey)
    setString("vehicleSqlId", ident.vehicleSqlId)
    setString("vehicleId", ident.vehicleKey)
    if tostring(row.vehicleRuntimeId or "") ~= "" then
        patch.vehicleRuntimeId = ""
        changed = true
    end
    setString("vehicleScript", ident.vehicleScript)
    setNumber("vehicleClaimVersion", 2)

    -- Last-known vehicle position is useful in the manager, but live vehicles
    -- can move every tick. Refresh it lazily so the MP sweep does not spam
    -- registry broadcasts while a rightful owner is driving.
    local stalePosition = (nowTs() - (tonumber(row.lastSeen) or 0)) >= 60
    if stalePosition then
        setNumber("lastVehicleX", ident.lastVehicleX)
        setNumber("lastVehicleY", ident.lastVehicleY)
        setNumber("lastVehicleZ", ident.lastVehicleZ)
    end

    if not changed then return row end
    return commitUpdate(rowId, patch)
end

local function loadedVehiclesForClaims()
    local out = {}
    if not getCell then return out end
    local cell = getCell()
    if not cell or not cell.getVehicles then return out end
    local vehicles = cell:getVehicles()
    if not vehicles or not vehicles.size or not vehicles.get then return out end
    local count = tonumber(vehicles:size()) or 0
    for i = 0, count - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then out[#out + 1] = vehicle end
    end
    return out
end

local function findVehicleRowBySqlId(sqlId)
    sqlId = normalizePositiveId(sqlId)
    if not sqlId or sqlId == "" then return nil end
    local found = nil
    Registry.iterShards(function(row)
        if found then return end
        if row.kind == "vehicle" and normalizePositiveId(row.vehicleSqlId) == sqlId then
            found = row
        end
    end)
    return found
end

local function clearVehicleHotwire(vehicle)
    if not vehicle then return false end
    local wasHotwired = vehicle.isHotwired and vehicle:isHotwired() == true
    local wasBroken = vehicle.isHotwiredBroken and vehicle:isHotwiredBroken() == true
    if not wasHotwired and not wasBroken then return false end

    if vehicle.cheatHotwire then
        vehicle:cheatHotwire(false, false)
    elseif vehicle.setHotwired then
        vehicle:setHotwired(false)
        if vehicle.setHotwiredBroken then
            vehicle:setHotwiredBroken(false)
        end
    end
    return true
end

local function reconcileVehicleMirror(vehicle, row)
    if not vehicle or not row or row.kind ~= "vehicle" then return false end
    local data = vehicleModData(vehicle)
    if not data then return false end

    local changed = false
    local function setField(key, value)
        if data[key] ~= value then
            data[key] = value
            changed = true
        end
    end

    setField(VEHICLE_OWNER_KEY, tostring(row.owner or ""))
    if tostring(row.vehicleKey or "") ~= "" then setField(VEHICLE_CLAIM_KEY, tostring(row.vehicleKey)) end
    if tostring(row.vehicleSqlId or "") ~= "" then setField(VEHICLE_SQL_ID_KEY, tostring(row.vehicleSqlId)) end
    if data[VEHICLE_RUNTIME_KEY] ~= nil then
        data[VEHICLE_RUNTIME_KEY] = nil
        changed = true
    end
    setField(VEHICLE_VERSION_KEY, 2)
    if data[VEHICLE_RELEASED_AT] ~= nil then
        data[VEHICLE_RELEASED_AT] = nil
        changed = true
    end

    if Registry.csvList then
        local nextAllowed = Registry.csvList(row.membersCSV or "")
        local same = type(data[VEHICLE_ALLOWED_KEY]) == "table"
            and #data[VEHICLE_ALLOWED_KEY] == #nextAllowed
        if same then
            for i = 1, #nextAllowed do
                if data[VEHICLE_ALLOWED_KEY][i] ~= nextAllowed[i] then same = false; break end
            end
        end
        if not same then
            data[VEHICLE_ALLOWED_KEY] = nextAllowed
            changed = true
        end
    end

    local keyId = tonumber(row.vehicleClaimKeyId) or 0
    local token = tostring(row.vehicleClaimKeyToken or "")
    if keyId > 0 and token ~= "" then
        setField(VEHICLE_CLAIM_KEY_ID, math.floor(keyId))
        setField(VEHICLE_CLAIM_KEY_TOKEN, token)
        setField(VEHICLE_CLAIM_KEY_OWNER, tostring(row.ownerSteamID or ""))
        if vehicle.getKeyId and vehicle.setKeyId then
            local cur = tonumber(vehicle:getKeyId()) or 0
            if cur ~= keyId then
                vehicle:setKeyId(keyId)
                changed = true
            end
        end
        if clearVehicleHotwire(vehicle) then
            changed = true
        end
    end

    if changed and vehicle.saveToVehicleTable then vehicle:saveToVehicleTable() end
    if changed and vehicle.transmitModData then vehicle:transmitModData() end
    return changed
end

local function randomVehicleClaimKeyId()
    if ZombRand then return ZombRand(65534) + 1 end
    return (((os and os.time and os.time()) or 1) % 65534) + 1
end

local function randomVehicleClaimKeyToken(vehicleKey)
    local ts = nowTs()
    local rnd = ZombRand and ZombRand(1000000000) or (ts % 1000000)
    return "ck:" .. tostring(ts) .. ":" .. tostring(rnd) .. ":" .. tostring(vehicleKey or "")
end

local function issueClaimKey(player, vehicle, row)
    if not player or not vehicle or not row then return false end
    local keyId = tonumber(row.vehicleClaimKeyId) or 0
    local token = tostring(row.vehicleClaimKeyToken or "")
    if keyId <= 0 or token == "" then return false end
    local inv = player.getInventory and player:getInventory() or nil
    if not inv or not inv.AddItem then return false end
    local key = inv:AddItem("Base.CarKey")
    if not key then return false end
    if key.setKeyId then key:setKeyId(keyId) end
    if key.setName then key:setName("CSR " .. vehicleTitle(vehicle) .. " Key") end
    local md = key.getModData and key:getModData() or nil
    if md then
        md[KEY_ITEM_VEHICLE_KEY] = tostring(row.vehicleKey or "")
        md[KEY_ITEM_TOKEN] = token
        md[KEY_ITEM_OWNER] = safeSteamID(player)
    end
    if key.transmitModData then key:transmitModData() end
    if inv.setDrawDirty then inv:setDrawDirty(true) end
    if syncInventoryItem then syncInventoryItem(key) end
    if syncPlayerInventory then syncPlayerInventory(player) end
    return true
end

function CSR_ClaimServer.ensureVehicleClaimKey(player, vehicle, row, rotate, issueKey)
    if not isServer() then return row end
    if not vehicle or not row or row.kind ~= "vehicle" or not row.id then return row end
    local keyId = tonumber(row.vehicleClaimKeyId) or 0
    local token = tostring(row.vehicleClaimKeyToken or "")
    if rotate or keyId <= 0 or token == "" then
        keyId = randomVehicleClaimKeyId()
        token = randomVehicleClaimKeyToken(row.vehicleKey)
        row = commitUpdate(row.id, {
            vehicleClaimKeyId = keyId,
            vehicleClaimKeyToken = token,
        }) or row
    end
    reconcileVehicleMirror(vehicle, row)
    if issueKey then issueClaimKey(player, vehicle, row) end
    return row
end

function CSR_ClaimServer.reconcileLoadedVehicleClaims()
    if not isServer() then return 0 end
    local repaired = 0
    local vehicles = loadedVehiclesForClaims()
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        local row = nil
        if CSR_VehicleClaim and CSR_VehicleClaim.getRegistryRow then
            row = CSR_VehicleClaim.getRegistryRow(vehicle)
        end
        if not row and CSR_VehicleClaim and CSR_VehicleClaim.getVehicleSqlId then
            row = findVehicleRowBySqlId(CSR_VehicleClaim.getVehicleSqlId(vehicle))
        end
        if row and row.kind == "vehicle" then
            if CSR_ClaimServer.touchVehicleRow then
                row = CSR_ClaimServer.touchVehicleRow(row.id, vehicle) or row
            end
            if reconcileVehicleMirror(vehicle, row) then repaired = repaired + 1 end
        end
    end
    return repaired
end

function CSR_ClaimServer.promoteLegacyVehicleModData(vehicle)
    if not isServer() then return nil end
    if not vehicle or not CSR_VehicleClaim or not CSR_VehicleClaim.getVehicleIdentity then return nil end
    local data = vehicleModData(vehicle)
    if not data then return nil end
    if data[VEHICLE_RELEASED_AT] then return nil end
    local owner = data[VEHICLE_OWNER_KEY]
    if not owner or tostring(owner) == "" then return nil end
    owner = tostring(owner)

    local ident = CSR_VehicleClaim.getVehicleIdentity(vehicle, true)
    if not ident or not ident.vehicleKey or ident.vehicleKey == "" then return nil end

    if Registry.getRowByVehicleKey then
        local existing = Registry.getRowByVehicleKey(ident.vehicleKey)
        if existing then return existing end
    end

    local row = commitAdd({
        kind                = "vehicle",
        x = ident.lastVehicleX, y = ident.lastVehicleY, w = 1, h = 1, z = ident.lastVehicleZ,
        owner               = owner,
        title               = vehicleTitle(vehicle),
        factionName         = "",
        vehicleId           = ident.vehicleKey,
        vehicleKey          = ident.vehicleKey,
        vehicleSqlId        = ident.vehicleSqlId,
        vehicleRuntimeId    = "",
        vehicleClaimVersion = 2,
        lastVehicleX        = ident.lastVehicleX,
        lastVehicleY        = ident.lastVehicleY,
        lastVehicleZ        = ident.lastVehicleZ,
        membersCSV          = allowedTableToCSV(data[VEHICLE_ALLOWED_KEY]),
        rolesCSV            = "",
        migratedFromVanilla = 0,
        vehicleMigratedFromLegacy = 1,
        vehicleScript       = ident.vehicleScript,
        vehicleClaimedAt    = nowTs(),
        ownerSteamID        = "",
    })
    if row and CSR_VehicleClaim.setOwner then
        CSR_VehicleClaim.setOwner(vehicle, owner, row)
        if vehicle.transmitModData then vehicle:transmitModData() end
        print(string.format("[CSR] Promoted legacy vehicle claim owner=%s key=%s.",
            tostring(owner), tostring(row.vehicleKey)))
    end
    return row
end

-- =========================================================================
-- Vanilla migration (one-shot on OnServerStarted)
-- =========================================================================

local function importVanillaSafehouse(sh)
    if not sh then return end
    local x = tonumber(sh:getX()) or 0
    local y = tonumber(sh:getY()) or 0
    local w = tonumber(sh:getW()) or 1
    local h = tonumber(sh:getH()) or 1
    if Registry.findRowAtBounds(x, y, w, h) then return end

    local owner = ""
    if sh.getOwner then
        local o = sh:getOwner()
        if o then owner = tostring(o) end
    end

    local title = ""
    if sh.getTitle then
        local t = sh:getTitle()
        if t then title = sanitizeTitle(t) end
    end
    if title == "" and owner ~= "" then title = owner .. "'s safehouse" end

    local membersCSV = ""
    if sh.getPlayers then
        local list = sh:getPlayers()
        if list and list.size then
            local n = tonumber(list:size()) or 0
            for i = 0, n - 1 do
                local u = list:get(i)
                if u and tostring(u) ~= owner then
                    membersCSV = Registry.csvAdd(membersCSV, tostring(u))
                end
            end
        end
    end

    local row = Registry.makeRow({
        kind                = "personal",
        x = x, y = y, w = clampInt(w, 1, MAX_W), h = clampInt(h, 1, MAX_H),
        z                   = 0,
        owner               = owner,
        title               = title,
        membersCSV          = membersCSV,
        createdAt           = nowTs(),
        lastSeen            = nowTs(),
        migratedFromVanilla = 1,
    })
    row.id = Registry.nextId()
    Registry.addRow(row)
end

local function runVanillaMigration()
    local root = getModDataRoot()
    if not root then return end
    if tonumber(root[MIGRATION_FLAG]) == 1 then return end

    local list = nil
    if SafeHouse and SafeHouse.getSafehouseList then
        list = SafeHouse.getSafehouseList()
    elseif getSafehouseList then
        list = getSafehouseList()
    end

    if list and list.size then
        local n = tonumber(list:size()) or 0
        for i = 0, n - 1 do
            local sh = list:get(i)
            if sh then importVanillaSafehouse(sh) end
        end
    end

    root[MIGRATION_FLAG] = 1
end

-- =========================================================================
-- Request handlers (called from CSR_ServerCommands dispatcher in Step 8)
-- =========================================================================

-- args = { x, y, w, h, kind, title, factionName, vehicleKey }
function CSR_ClaimServer.handleClaimRequest(player, args)
    if not overrideEnabled() then
        sendResult(player, false, "CSR claims override disabled"); return
    end
    if not player or not args then return end

    local user = safeUsername(player)
    if user == "" then sendResult(player, false, "No username"); return end

    local kind = tostring(args.kind or "personal")
    if kind ~= "personal" and kind ~= "faction" and kind ~= "vehicle" then
        sendResult(player, false, "Bad claim kind"); return
    end

    local vehicle = nil
    local vehicleIdentity = nil
    local x = tonumber(args.x)
    local y = tonumber(args.y)
    local w = clampInt(args.w, 1, MAX_W)
    local h = clampInt(args.h, 1, MAX_H)

    if kind == "vehicle" then
        vehicle = resolveVehicleClaimRequestVehicle(player, args)
        if not vehicle then sendResult(player, false, "Vehicle not found"); return end
        vehicleIdentity = CSR_VehicleClaim.getVehicleIdentity(vehicle, true)
        if not vehicleIdentity or vehicleIdentity.vehicleKey == "" then
            sendResult(player, false, "Vehicle has no persistent id"); return
        end
        x = vehicleIdentity.lastVehicleX
        y = vehicleIdentity.lastVehicleY
        w = 1
        h = 1
    end

    if not x or not y then sendResult(player, false, "Bad bounds"); return end

    -- Vehicle claims do not need bounds-based proximity; the vehicle object
    -- is resolved by CSR vehicleKey or by the server's seated-player state.
    if kind ~= "vehicle" then
        if not playerInsideBounds(player, x, y, w, h) then
            sendResult(player, false, "You must be inside the bounds")
            return
        end
        local existingClaim = nil
        if Registry.findFirstIntersecting then
            existingClaim = Registry.findFirstIntersecting(x, y, w, h, 0, false)
        else
            existingClaim = Registry.findRowAtBounds(x, y, w, h)
        end
        if existingClaim then
            sendResult(player, false, "Already claimed")
            return
        end
    end

    if kind == "vehicle" then
        local existingVehicleRow = nil
        if CSR_VehicleClaim and CSR_VehicleClaim.getRegistryRow then
            existingVehicleRow = CSR_VehicleClaim.getRegistryRow(vehicle)
        end
        if not existingVehicleRow and Registry.getRowByVehicleKey then
            existingVehicleRow = Registry.getRowByVehicleKey(vehicleIdentity.vehicleKey)
        end
        if existingVehicleRow then
            sendResult(player, false, "Vehicle already claimed"); return
        end
    end

    local title = sanitizeTitle(args.title or (user .. "'s safehouse"))
    if kind == "vehicle" then
        title = sanitizeTitle(args.title or vehicleTitle(vehicle))
    end
    local factionName = ""
    if kind == "faction" then
        factionName = tostring(args.factionName or "")
        if factionName == "" then sendResult(player, false, "No faction"); return end
    end

    local row = commitAdd({
        kind                = kind,
        x = x, y = y, w = w, h = h,
        z                   = tonumber(args.z) or 0,
        owner               = user,
        title               = title,
        factionName         = factionName,
        vehicleId           = (kind == "vehicle") and vehicleIdentity.vehicleKey or "",
        vehicleKey          = (kind == "vehicle") and vehicleIdentity.vehicleKey or "",
        vehicleSqlId        = (kind == "vehicle") and vehicleIdentity.vehicleSqlId or "",
        vehicleRuntimeId    = "",
        vehicleClaimVersion = (kind == "vehicle") and 2 or 0,
        lastVehicleX        = (kind == "vehicle") and vehicleIdentity.lastVehicleX or 0,
        lastVehicleY        = (kind == "vehicle") and vehicleIdentity.lastVehicleY or 0,
        lastVehicleZ        = (kind == "vehicle") and vehicleIdentity.lastVehicleZ or 0,
        membersCSV          = "",
        rolesCSV            = "",
        migratedFromVanilla = 0,
        vehicleScript       = (kind == "vehicle") and vehicleIdentity.vehicleScript or "",
        vehicleClaimedAt    = (kind == "vehicle") and nowTs() or 0,
        ownerSteamID        = safeSteamID(player),
    })
    if kind == "vehicle" and row and CSR_VehicleClaim and CSR_VehicleClaim.setOwner then
        row = CSR_ClaimServer.ensureVehicleClaimKey(player, vehicle, row, true, true) or row
        CSR_VehicleClaim.setOwner(vehicle, user, row)
        if vehicle.transmitModData then vehicle:transmitModData() end
    end
    if CSR_ClaimAudit and CSR_ClaimAudit.log then
        CSR_ClaimAudit.log("claim_create", row, player, "", { kind = kind })
    end
    sendResult(player, true, "Claimed: " .. tostring(row.id))
end

-- args = { id }
function CSR_ClaimServer.handleReleaseRequest(player, args)
    if not overrideEnabled() then
        sendResult(player, false, "CSR claims override disabled"); return
    end
    if not player or not args then return end
    local id = tonumber(args.id)
    if not id then sendResult(player, false, "Bad id"); return end

    local row = Registry.getRowById(id)
    if not row then sendResult(player, false, "Unknown claim"); return end

    local user = safeUsername(player)
    -- Owner, server admin, or faction owner (for kind=="faction" rows) may release.
    if not canManage(player, row, user) then
        sendResult(player, false, "Not allowed (need owner, admin, or faction owner)"); return
    end

    commitRemove(id)

    -- For vehicle claims, also clear the legacy per-vehicle modData mirror so
    -- pre-v1.8.0 readers (and the radial-menu fast path) reflect the release.
    if row.kind == "vehicle" then
        local vehicle = CSR_VehicleClaim and CSR_VehicleClaim.findLoadedVehicleByRow
            and CSR_VehicleClaim.findLoadedVehicleByRow(row)
            or nil
        if vehicle and CSR_VehicleClaim and CSR_VehicleClaim.clearOwner then
            CSR_VehicleClaim.clearOwner(vehicle)
            if vehicle.transmitModData then vehicle:transmitModData() end
        end
    end

    if CSR_ClaimAudit and CSR_ClaimAudit.log then
        CSR_ClaimAudit.log("claim_release", row, player, "", { kind = row.kind })
    end
    sendResult(player, true, "Released")
end

-- args = { id, x, y, w, h }
function CSR_ClaimServer.handleResizeClaimRequest(player, args)
    if not overrideEnabled() then
        sendResult(player, false, "CSR claims override disabled"); return
    end
    if not expansionEnabled() then
        sendResult(player, false, "Claim expansion disabled"); return
    end
    if not player or not args then return end

    local id = tonumber(args.id)
    if not id then sendResult(player, false, "Bad id"); return end
    local row = Registry.getRowById(id)
    if not row then sendResult(player, false, "Unknown claim"); return end
    if row.kind ~= "personal" and row.kind ~= "faction" then
        sendResult(player, false, "Only safehouse claims can be expanded"); return
    end

    local user = safeUsername(player)
    local canExpand = false
    if CSR_ClaimPermissions and CSR_ClaimPermissions.canDo then
        canExpand = CSR_ClaimPermissions.canDo(row, user, "expand", player)
    else
        canExpand = canManage(player, row, user)
    end
    if not canExpand then
        sendResult(player, false, "Not allowed to expand this claim"); return
    end

    local nx = math.floor(tonumber(args.x) or row.x)
    local ny = math.floor(tonumber(args.y) or row.y)
    local nw = math.floor(tonumber(args.w) or row.w)
    local nh = math.floor(tonumber(args.h) or row.h)
    if nw < 1 or nh < 1 then sendResult(player, false, "Bad bounds"); return end

    if nw > expansionMaxWidth() or nh > expansionMaxHeight() then
        sendResult(player, false, "Expansion exceeds server size limit"); return
    end

    if not Registry.rectContains(nx, ny, nw, nh, row.x, row.y, row.w, row.h) then
        sendResult(player, false, "Expansion must contain the current claim"); return
    end

    if expansionRequiresPlayerInside()
            and not playerInsideBounds(player, row.x, row.y, row.w, row.h) then
        sendResult(player, false, "Stand inside your current claim to expand it"); return
    end

    local oldArea = math.max(1, (tonumber(row.w) or 1) * (tonumber(row.h) or 1))
    local newArea = math.max(1, nw * nh)
    local addedTiles = newArea - oldArea
    if addedTiles <= 0 then
        sendResult(player, false, "New bounds do not expand the claim"); return
    end

    local maxAdded = expansionMaxAddedTiles()
    if maxAdded > 0 and addedTiles > maxAdded then
        sendResult(player, false, "Expansion adds too many tiles (" .. tostring(addedTiles)
            .. "/" .. tostring(maxAdded) .. ")"); return
    end

    local cdOk, cdLeft = checkExpansionCooldown(id, user)
    if not cdOk then
        sendResult(player, false, "Expansion cooldown: " .. tostring(math.ceil(cdLeft / 60)) .. " min left"); return
    end

    if not hasArchitectCredentials(player) then
        sendResult(player, false, "Need Architect credentials or Carpentry "
            .. tostring(expansionArchitectCarpentryLevel()) .. "+"); return
    end

    local overlap = nil
    if Registry.findFirstIntersecting then
        overlap = Registry.findFirstIntersecting(nx, ny, nw, nh, id, false)
    end
    if overlap then
        sendResult(player, false, "Expansion overlaps another claim"); return
    end

    local blocked, blocker = hasBlockedPlayerInside(row, nx, ny, nw, nh)
    if blocked then
        local suffix = blocker ~= "" and (" (" .. blocker .. ")") or ""
        sendResult(player, false, "A non-member player is inside the expansion area" .. suffix); return
    end

    local moneyCost, materialCost = expansionCosts(addedTiles)
    local charged, chargeErr = chargeExpansionCosts(player, moneyCost, materialCost)
    if not charged then
        sendResult(player, false, chargeErr or "Missing expansion payment"); return
    end

    local updated = commitUpdate(id, {
        x = nx,
        y = ny,
        w = nw,
        h = nh,
        z = tonumber(row.z) or 0,
    })
    if not updated then
        sendResult(player, false, "Could not update claim"); return
    end

    stampExpansionCooldown(id, user)
    if CSR_ClaimAudit and CSR_ClaimAudit.log then
        CSR_ClaimAudit.log("claim_expand", updated, player, "", {
            old = tostring(row.x) .. ":" .. tostring(row.y) .. ":" .. tostring(row.w) .. "x" .. tostring(row.h),
            new = tostring(nx) .. ":" .. tostring(ny) .. ":" .. tostring(nw) .. "x" .. tostring(nh),
            addedTiles = addedTiles,
            money = moneyCost,
            materials = materialCost,
        })
    end
    sendResult(player, true, "Expanded claim: +" .. tostring(addedTiles)
        .. " tiles, $" .. tostring(moneyCost) .. ", materials " .. tostring(materialCost))
end

-- args = { id, newOwner }
function CSR_ClaimServer.handleTransferRequest(player, args)
    if not overrideEnabled() then
        sendResult(player, false, "CSR claims override disabled"); return
    end
    if not player or not args then return end
    local id = tonumber(args.id)
    local newOwner = tostring(args.newOwner or "")
    if not id or newOwner == "" then sendResult(player, false, "Bad args"); return end

    local row = Registry.getRowById(id)
    if not row then sendResult(player, false, "Unknown claim"); return end

    local user = safeUsername(player)
    if not canManage(player, row, user) then
        sendResult(player, false, "Not allowed (need owner, admin, or faction owner)"); return
    end

    -- New owner must be a known member (or the current owner -- no-op).
    if newOwner ~= row.owner and not Registry.csvContains(row.membersCSV, newOwner) then
        sendResult(player, false, "Target is not a member"); return
    end

    -- Move old owner into membersCSV; remove new owner from membersCSV.
    local oldOwner = tostring(row.owner or "")
    local newMembers = Registry.csvRemove(row.membersCSV, newOwner)
    if oldOwner ~= "" and oldOwner ~= newOwner then
        newMembers = Registry.csvAdd(newMembers, oldOwner)
    end
    -- Update roles: drop new owner's role row (they're now owner).
    local newRoles = Registry.rolesSet(row.rolesCSV, newOwner, "")

    local patch = {
        owner      = newOwner,
        membersCSV = newMembers,
        rolesCSV   = newRoles,
    }
    if row.kind == "vehicle" then
        local ids = tostring(row.memberSteamIDsCSV or "")
        local map = tostring(row.memberSteamMapCSV or "")
        local newOwnerSid = ""
        if Registry.mapGet then newOwnerSid = Registry.mapGet(map, newOwner) end
        if newOwnerSid == "" then newOwnerSid = steamIDForUsername(newOwner) end
        if newOwnerSid ~= "" and Registry.csvRemove then ids = Registry.csvRemove(ids, newOwnerSid) end
        if Registry.mapRemove then map = Registry.mapRemove(map, newOwner) end

        local oldOwnerSid = tostring(row.ownerSteamID or "")
        if oldOwnerSid == "" then oldOwnerSid = steamIDForUsername(oldOwner) end
        if oldOwner ~= "" and oldOwner ~= newOwner and oldOwnerSid ~= "" then
            if Registry.csvAdd then ids = Registry.csvAdd(ids, oldOwnerSid) end
            if Registry.mapSet then map = Registry.mapSet(map, oldOwner, oldOwnerSid) end
        end
        patch.ownerSteamID = newOwnerSid
        patch.memberSteamIDsCSV = ids
        patch.memberSteamMapCSV = map
    end

    commitUpdate(id, patch)
    if CSR_ClaimAudit and CSR_ClaimAudit.log then
        CSR_ClaimAudit.log("claim_transfer", row, player, newOwner, {})
    end
    sendResult(player, true, "Transferred to " .. newOwner)
end

-- args = { id, username, role }   role = "" removes the role
function CSR_ClaimServer.handleSetRoleRequest(player, args)
    if not overrideEnabled() then
        sendResult(player, false, "CSR claims override disabled"); return
    end
    if not player or not args then return end
    local id = tonumber(args.id)
    local target = tostring(args.username or "")
    local role = tostring(args.role or "")
    if not id or target == "" then sendResult(player, false, "Bad args"); return end

    local row = Registry.getRowById(id)
    if not row then sendResult(player, false, "Unknown claim"); return end

    local user = safeUsername(player)
    if not canManage(player, row, user) then
        sendResult(player, false, "Not allowed (need owner, admin, or faction owner)"); return
    end

    if target == row.owner then
        sendResult(player, false, "Cannot set role on owner"); return
    end

    local newMembers = row.membersCSV
    if role == "" then
        -- Remove member entirely.
        newMembers = Registry.csvRemove(newMembers, target)
    else
        newMembers = Registry.csvAdd(newMembers, target)
    end
    local newRoles = Registry.rolesSet(row.rolesCSV, target, role)

    local patch = {
        membersCSV = newMembers,
        rolesCSV   = newRoles,
    }
    if row.kind == "vehicle" then
        mergePatch(patch, memberSteamPatch(row, target, role ~= ""))
    end
    commitUpdate(id, patch)

    -- v1.8.7: keep the vanilla SafeHouse.getPlayers() list in sync for
    -- personal + faction safehouse rows so the new member can actually open
    -- doors / be recognised by vanilla safehouse logic.
    if row.kind == "personal" or row.kind == "faction" then
        if CSR_SafehouseClaim and CSR_SafehouseClaim.findSafehouseAt then
            local sh = CSR_SafehouseClaim.findSafehouseAt(row.x, row.y, row.w, row.h)
            if sh and sh.getPlayers then
                local list = sh:getPlayers()
                if list then
                    local present = false
                    local n = (list.size and list:size()) or 0
                    for i = 0, n - 1 do
                        local u = list:get(i)
                        if u and tostring(u) == target then present = true; break end
                    end
                    if role == "" then
                        if present and list.remove then
                            list:remove(target)
                        end
                    else
                        if not present and list.add then
                            list:add(target)
                        end
                    end
                end
            end
        end
    end

    if CSR_ClaimAudit and CSR_ClaimAudit.log then
        local evt = (role == "") and "member_remove" or "member_setrole"
        CSR_ClaimAudit.log(evt, row, player, target, { role = role })
    end
    sendResult(player, true, (role == "") and "Removed" or ("Role: " .. role))
end

-- args = { id, toFaction }
-- Faction-to-faction reassignment for a kind=="faction" row. Requester must
-- own both the source and the destination faction (or be admin).
function CSR_ClaimServer.handleTransferFactionRequest(player, args)
    if not overrideEnabled() then
        sendResult(player, false, "CSR claims override disabled"); return
    end
    if not player or not args then return end

    local id = tonumber(args.id)
    local toFaction = tostring(args.toFaction or "")
    if not id or toFaction == "" then sendResult(player, false, "Bad args"); return end

    local row = Registry.getRowById(id)
    if not row then sendResult(player, false, "Unknown claim"); return end
    if row.kind ~= "faction" then
        sendResult(player, false, "Not a faction claim"); return
    end
    if row.factionName == toFaction then
        sendResult(player, false, "Already that faction"); return
    end

    local user = safeUsername(player)
    local isAdmin = false
    if player.getAccessLevel then
        local access = player:getAccessLevel()
        if access and (access == "admin" or access == "Admin") then isAdmin = true end
    end

    -- Faction ownership check (server-authoritative -- consult Faction).
    local ownsSource, ownsTarget = false, false
    if Faction and Faction.getFaction then
        local fSrc = Faction.getFaction(row.factionName or "")
        if fSrc and fSrc.isOwner and user ~= "" and fSrc:isOwner(user) then
            ownsSource = true
        end
        local fDst = Faction.getFaction(toFaction)
        if fDst and fDst.isOwner and user ~= "" and fDst:isOwner(user) then
            ownsTarget = true
        end
    end
    if not isAdmin and not (ownsSource and ownsTarget) then
        sendResult(player, false, "Must own both factions"); return
    end

    commitUpdate(id, { factionName = toFaction })
    sendResult(player, true, "Transferred to " .. toFaction)
end

-- args = {}   (client requesting full snapshot, e.g. on login)
function CSR_ClaimServer.handleGetClaimsBundle(player, args)
    if not player then return end
    local rows = Registry.getAllRows()
    -- Send count + each row as a discrete command. The bundle command itself
    -- carries the count so the client knows how many rows to expect; rows
    -- arrive as individual CMD_ADDED messages so the same client-side handler
    -- handles login snapshot and live additions.
    sendServerCommand(player, "CommonSenseReborn", CMD_BUNDLE, {
        count = #rows,
    })
    for i = 1, #rows do
        sendServerCommand(player, "CommonSenseReborn", CMD_ADDED,
            Registry.serializeRow(rows[i]))
    end
end

-- =========================================================================
-- Admin-only: teleport requesting player to a CSR claim by row id.
-- Replies with CSR_AdminTeleportDo {x,y,z} which the client acts on.
-- =========================================================================
function CSR_ClaimServer.handleAdminTeleportClaim(player, args)
    if not player then return end
    if not isAdminPlayer(player) then
        sendResult(player, false, "Admin only.")
        return
    end
    local id = tonumber(args and args.rowId) or 0
    local row = id > 0 and Registry.getRowById(id) or nil
    if not row then
        sendResult(player, false, "Claim not found.")
        return
    end
    local x, y, z
    if row.kind == "vehicle" then
        x = tonumber(row.x) or 0
        y = tonumber(row.y) or 0
        z = tonumber(row.z) or 0
    else
        x = (tonumber(row.x) or 0) + math.floor((tonumber(row.w) or 1) / 2)
        y = (tonumber(row.y) or 0) + math.floor((tonumber(row.h) or 1) / 2)
        z = tonumber(row.z) or 0
    end
    sendServerCommand(player, "CommonSenseReborn", "CSR_AdminTeleportDo", {
        x = x, y = y, z = z,
    })
end

-- =========================================================================
-- Admin-only: force-release the vanilla SafeHouse(s) covering the given
-- world tile, plus any matching CSR registry rows.
-- =========================================================================
function CSR_ClaimServer.handleAdminForceReleaseSafehouse(player, args)
    if not player then return end
    if not isAdminPlayer(player) then
        sendResult(player, false, "Admin only.")
        return
    end
    local x = tonumber(args and args.x) or 0
    local y = tonumber(args and args.y) or 0
    local removedSh = 0
    local removedRows = 0
    if SafeHouse and SafeHouse.getSafehouseList then
        local list = SafeHouse.getSafehouseList()
        if list and list.size then
            local matches = {}
            for i = 0, list:size() - 1 do
                local sh = list:get(i)
                if sh and sh.getX and sh.getY and sh.getW and sh.getH then
                    local sx = sh:getX()
                    local sy = sh:getY()
                    local sw = sh:getW()
                    local shh = sh:getH()
                    if x >= sx and x < sx + sw and y >= sy and y < sy + shh then
                        table.insert(matches, sh)
                    end
                end
            end
            for _, sh in ipairs(matches) do
                SafeHouse.removeSafeHouse(sh)
                removedSh = removedSh + 1
            end
        end
    end
    local rows = Registry.getAllRows() or {}
    for _, row in ipairs(rows) do
        if row.kind ~= "vehicle" then
            local rx = tonumber(row.x) or 0
            local ry = tonumber(row.y) or 0
            local rw = tonumber(row.w) or 1
            local rh = tonumber(row.h) or 1
            if x >= rx and x < rx + rw and y >= ry and y < ry + rh then
                if commitRemove(row.id) then
                    removedRows = removedRows + 1
                end
            end
        end
    end
    sendResult(player, true, string.format(
        "Force-released %d safehouse(s) and %d CSR claim(s) at (%d,%d).",
        removedSh, removedRows, x, y))
end

local function isLegacyRuntimeVehicleRow(row)
    if type(row) ~= "table" or row.kind ~= "vehicle" then return false end

    if tonumber(row.vehicleMigratedFromLegacy) == 1 then return true end

    local key = tostring(row.vehicleKey or "")
    local legacyId = tostring(row.vehicleId or "")

    if tostring(row.vehicleRuntimeId or "") ~= "" then return true end
    if (tonumber(row.vehicleClaimVersion) or 0) > 0
            and (tonumber(row.vehicleClaimVersion) or 0) < 2 then
        return true
    end

    -- Old rows can have a durable vehicleKey after promotion while still
    -- carrying the old numeric vehicleId side field. Treat that as legacy so
    -- the admin purge actually removes the promoted runtime claim.
    if key ~= "" and not looksLikeVehicleKey(key) then return true end
    if legacyId ~= "" and not looksLikeVehicleKey(legacyId) then return true end

    if looksLikeVehicleKey(key) or looksLikeVehicleKey(legacyId) then
        return false
    end
    return false
end

local function loadedVehicles()
    local out = {}
    if not getCell then return out end
    local cell = getCell()
    if not cell or not cell.getVehicles then return out end
    local vehicles = cell:getVehicles()
    if not vehicles or not vehicles.size or not vehicles.get then return out end
    local count = tonumber(vehicles:size()) or 0
    for i = 0, count - 1 do
        local v = vehicles:get(i)
        if v then out[#out + 1] = v end
    end
    return out
end

local function hasLegacyVehicleMirror(vehicle)
    local data = vehicleModData(vehicle)
    if not data then return false end
    local owner = tostring(data[VEHICLE_OWNER_KEY] or "")
    if owner == "" then return false end

    local key = tostring(data[VEHICLE_CLAIM_KEY] or "")
    local sql = tostring(data[VEHICLE_SQL_ID_KEY] or data.SQLID or "")
    local runtime = tostring(data[VEHICLE_RUNTIME_KEY] or "")
    local version = tonumber(data[VEHICLE_VERSION_KEY]) or 0

    if runtime ~= "" then return true end
    if version > 0 and version < 2 then return true end
    if not looksLikeVehicleKey(key) and sql == "" then return true end
    return false
end

local function addLegacyVehicleRowKeys(row, keys, sqls)
    if not row then return end
    local key = tostring(row.vehicleKey or "")
    local legacyId = tostring(row.vehicleId or "")
    local sqlId = normalizePositiveId(row.vehicleSqlId)

    if looksLikeVehicleKey(key) then
        keys[key] = true
        if string.sub(key, 1, 4) == "sql:" then
            local fromKey = normalizePositiveId(string.sub(key, 5))
            if fromKey then sqls[fromKey] = true end
        end
    end
    if looksLikeVehicleKey(legacyId) then
        keys[legacyId] = true
        if string.sub(legacyId, 1, 4) == "sql:" then
            local fromId = normalizePositiveId(string.sub(legacyId, 5))
            if fromId then sqls[fromId] = true end
        end
    else
        local fromLegacyId = normalizePositiveId(legacyId)
        if fromLegacyId then sqls[fromLegacyId] = true end
    end
    if sqlId then sqls[sqlId] = true end
end

local function vehicleMatchesLegacyRow(vehicle, keys, sqls)
    local data = vehicleModData(vehicle)
    if data then
        local key = tostring(data[VEHICLE_CLAIM_KEY] or "")
        if key ~= "" and keys[key] then return true end
        local sql = normalizePositiveId(data[VEHICLE_SQL_ID_KEY] or data.SQLID)
        if sql and sqls[sql] then return true end
    end
    if CSR_VehicleClaim and CSR_VehicleClaim.getVehicleKeyCandidates then
        local candidates = CSR_VehicleClaim.getVehicleKeyCandidates(vehicle, false)
        for i = 1, #candidates do
            if keys[candidates[i]] then return true end
        end
    end
    if CSR_VehicleClaim and CSR_VehicleClaim.getVehicleSqlId then
        local sql = normalizePositiveId(CSR_VehicleClaim.getVehicleSqlId(vehicle))
        if sql and sqls[sql] then return true end
    end
    return false
end

local function clearLegacyVehicleMirror(vehicle)
    local data = vehicleModData(vehicle)
    if not data then return false end
    data[VEHICLE_OWNER_KEY] = nil
    data[VEHICLE_ALLOWED_KEY] = nil
    data[VEHICLE_RUNTIME_KEY] = nil
    data[VEHICLE_CLAIM_KEY] = nil
    data[VEHICLE_SQL_ID_KEY] = nil
    data[VEHICLE_VERSION_KEY] = 2
    data[VEHICLE_RELEASED_AT] = nowTs()
    if vehicle and vehicle.transmitModData then vehicle:transmitModData() end
    return true
end

-- Admin-only: purge vehicle claim rows that were stored under the old runtime
-- identity model, plus loaded per-vehicle legacy owner mirrors that would
-- otherwise re-promote into durable rows on the next claim read.
function CSR_ClaimServer.handleAdminPurgeLegacyVehicleClaims(player, args)
    if not player then return end
    if not isAdminPlayer(player) then
        sendResult(player, false, "Admin only.")
        return
    end

    local ids = {}
    local legacyKeys = {}
    local legacySqlIds = {}
    Registry.iterShards(function(row)
        if isLegacyRuntimeVehicleRow(row) then
            local id = tonumber(row.id) or 0
            if id > 0 then ids[#ids + 1] = id end
            addLegacyVehicleRowKeys(row, legacyKeys, legacySqlIds)
        end
    end)

    local removed = 0
    for i = 1, #ids do
        if commitRemove(ids[i]) then
            removed = removed + 1
        end
    end

    local mirrorsCleared = 0
    local vehicles = loadedVehicles()
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        if (hasLegacyVehicleMirror(vehicle)
                or vehicleMatchesLegacyRow(vehicle, legacyKeys, legacySqlIds))
                and clearLegacyVehicleMirror(vehicle) then
            mirrorsCleared = mirrorsCleared + 1
        end
    end

    sendResult(player, true, string.format(
        "Purged %d legacy runtime vehicle claim(s); cleared %d loaded legacy vehicle mirror(s).",
        removed, mirrorsCleared))
end

-- =========================================================================
-- Generic dispatcher (used by the shim in CSR_ServerCommands -- Step 8)
-- =========================================================================

local DISPATCH = {
    CSR_ClaimRequest               = CSR_ClaimServer.handleClaimRequest,
    CSR_ReleaseRequest             = CSR_ClaimServer.handleReleaseRequest,
    CSR_ResizeClaimRequest         = CSR_ClaimServer.handleResizeClaimRequest,
    CSR_TransferRequest            = CSR_ClaimServer.handleTransferRequest,
    CSR_TransferFactionRequest     = CSR_ClaimServer.handleTransferFactionRequest,
    CSR_SetRoleRequest             = CSR_ClaimServer.handleSetRoleRequest,
    CSR_GetClaimsBundle            = CSR_ClaimServer.handleGetClaimsBundle,
    CSR_AdminTeleportClaim         = CSR_ClaimServer.handleAdminTeleportClaim,
    CSR_AdminForceReleaseSafehouse = CSR_ClaimServer.handleAdminForceReleaseSafehouse,
    CSR_AdminPurgeLegacyVehicles   = CSR_ClaimServer.handleAdminPurgeLegacyVehicleClaims,
}

-- Merge respawn handlers (CSR_SetRespawn / CSR_ClearRespawn /
-- CSR_RespawnInfoQuery / CSR_RespawnMarkPending / CSR_RespawnCheck).
if CSR_ClaimRespawn and CSR_ClaimRespawn.DISPATCH then
    for k, v in pairs(CSR_ClaimRespawn.DISPATCH) do
        DISPATCH[k] = v
    end
end

-- v1.8.35: merge invite + audit handlers (invite request/accept/decline,
-- member kick, highlight toggle, audit query).
if CSR_ClaimInvites and CSR_ClaimInvites.DISPATCH then
    for k, v in pairs(CSR_ClaimInvites.DISPATCH) do
        DISPATCH[k] = v
    end
end
if CSR_ClaimAudit and CSR_ClaimAudit.DISPATCH then
    for k, v in pairs(CSR_ClaimAudit.DISPATCH) do
        DISPATCH[k] = v
    end
end
-- v1.8.36: padlock install / remove / break
if CSR_PadlockServer and CSR_PadlockServer.DISPATCH then
    for k, v in pairs(CSR_PadlockServer.DISPATCH) do
        DISPATCH[k] = v
    end
end

function CSR_ClaimServer.dispatch(module, command, player, args)
    if module ~= "CommonSenseReborn" then return false end
    local fn = DISPATCH[command]
    if not fn then return false end
    fn(player, args or {})
    return true
end

-- =========================================================================
-- Event hooks
-- =========================================================================

local function onServerStarted()
    -- Migration runs only on dedicated/co-op host. Single-player has no
    -- vanilla safehouse list to import in the same sense, but the call is
    -- still safe (the list will just be empty).
    runVanillaMigration()
    syncServerSafehouseMirrors()
    -- v1.8.13: orphan vehicle-claim scrub REMOVED from startup.
    -- v1.8.37: runtime-id matching is also removed from normal claim reads.
    -- Durable vehicle keys are the only ownership identity; if a claimed
    -- vehicle is unloaded, its row remains harmlessly in storage until the
    -- same keyed vehicle is loaded again.
end

Events.OnServerStarted.Add(onServerStarted)
-- v1.8.13: removed redundant Events.OnGameStart hook.
-- CSR_ClaimServer.lua lives in server/, not shared/, so the project
-- "hook both" convention does not apply -- and the duplicate hook was
-- firing the migration + scrub a second time on every server start.

-- =========================================================================
-- v1.8.14 public helpers -- vehicle-ID-reuse defense
-- =========================================================================

-- Called from CSR_VehicleClaim.getOwner the first time a legacy row (no
-- vehicleScript fingerprint) is read against a live vehicle. Backfills the
-- field via commitUpdate so the next read can use fast-path verification.
function CSR_ClaimServer.backfillVehicleScript(rowId, scriptName)
    if not isServer() then return end
    if not rowId or not scriptName or scriptName == "" then return end
    local row = Registry.getRowById(rowId)
    if not row or row.kind ~= "vehicle" then return end
    if row.vehicleScript and row.vehicleScript ~= "" then return end
    commitUpdate(rowId, { vehicleScript = scriptName })
end

-- Called from CSR_VehicleClaim.getOwner when a row's stored vehicleScript
-- does NOT match the live vehicle's script -- meaning the engine reused the
-- integer vehicle id onto a different vehicle, so the row has nothing to
-- do with the live vehicle anymore. Removes the stale row + logs.
function CSR_ClaimServer.scrubStaleVehicleRow(rowId, storedScript, liveScript)
    if not isServer() then return end
    if not rowId then return end
    local row = Registry.getRowById(rowId)
    if not row or row.kind ~= "vehicle" then return end
    print(string.format(
        "[CSR] Stale vehicle claim row %s (vid=%s, owner=%s): script mismatch stored=%s live=%s -- removing.",
        tostring(rowId), tostring(row.vehicleId), tostring(row.owner),
        tostring(storedScript), tostring(liveScript)))
    commitRemove(rowId)
end

return CSR_ClaimServer
