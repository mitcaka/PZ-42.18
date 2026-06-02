require "CSR_FeatureFlags"

--[[
    CSR_SafehouseClaim.lua (shared)
    Safehouse claim helpers used by both client and server.
    Vanilla B42 SafeHouse API supports multiple claims per player.
    We enforce our own configurable limit.

    v1.7.5: Removed every pcall-masking wrapper plus the local
    iterSize/iterGet helpers. Vanilla B42 SafeHouse.getSafehouseList()
    returns a real ArrayList; iterate it with list:size()/list:get(i)
    behind explicit method-existence guards so any genuine API
    regression surfaces with a clear stack frame instead of silently
    swallowing the failure.
]]

CSR_SafehouseClaim = CSR_SafehouseClaim or {}

--- Fetch the safehouse list with B42 capitalization variation.
local function safehouseList()
    if not SafeHouse then return nil end
    if SafeHouse.getSafehouseList then return SafeHouse.getSafehouseList() end
    if SafeHouse.getSafeHouseList then return SafeHouse.getSafeHouseList() end
    return nil
end

--- Count safehouses owned by username.
function CSR_SafehouseClaim.getOwnerCount(username)
    if not username then return 0 end
    local list = safehouseList()
    if not list or not list.size or not list.get then return 0 end
    local count = 0
    local sz = list:size()
    for i = 0, sz - 1 do
        local sh = list:get(i)
        if sh and sh.getOwner and sh:getOwner() == username then
            count = count + 1
        end
    end
    return count
end

--- Get max allowed safehouse claims from sandbox options.
function CSR_SafehouseClaim.getMaxClaims()
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    return sb.MaxSafehouseClaims or 3
end

--- Check if feature is enabled. Disabled in singleplayer.
function CSR_SafehouseClaim.isEnabled()
    if not isClient() and not isServer() then return false end
    if not CSR_FeatureFlags or not CSR_FeatureFlags.isMultipleSafehouseEnabled then return false end
    return CSR_FeatureFlags.isMultipleSafehouseEnabled()
end

--- Inclusive (sx, sy, sw, sh) bounds for a safehouse, normalising B42's
--- W/H vs X2/Y2 API drift exactly the same way CSR_SafehouseOutline does.
local function shBounds(sh)
    if not sh then return nil end
    local x  = sh.getX  and sh:getX()
    local y  = sh.getY  and sh:getY()
    if not x or not y then return nil end
    local w, h
    if sh.getW and sh.getH then
        w = sh:getW(); h = sh:getH()
    elseif sh.getX2 and sh.getY2 then
        w = sh:getX2() - x + 1
        h = sh:getY2() - y + 1
    end
    if not w or not h then return nil end
    return x, y, w, h
end

--- Find an existing safehouse that covers a given area (rect overlap).
function CSR_SafehouseClaim.findSafehouseAt(x, y, w, h)
    local list = safehouseList()
    if not list or not list.size or not list.get then return nil end
    local sz = list:size()
    for i = 0, sz - 1 do
        local sh = list:get(i)
        if sh then
            local sx, sy, sw, sh2 = shBounds(sh)
            if sx and sy and sw and sh2 then
                if not (x >= sx + sw or x + w <= sx or y >= sy + sh2 or y + h <= sy) then
                    return sh
                end
            end
        end
    end
    return nil
end

--- Get all safehouses owned by or including this player.
function CSR_SafehouseClaim.getMySafehouses(playerObj)
    local result = {}
    if not playerObj or not playerObj.getUsername then return result end
    local username = playerObj:getUsername()
    if not username or username == "" then return result end

    local list = safehouseList()
    if not list or not list.size or not list.get then return result end
    local sz = list:size()
    for i = 0, sz - 1 do
        local sh = list:get(i)
        if sh then
            local owner = sh.getOwner and sh:getOwner() or nil
            if owner == username then
                table.insert(result, sh)
            elseif sh.getPlayers then
                local players = sh:getPlayers()
                if players and players.size and players.get then
                    local pSz = players:size()
                    for j = 0, pSz - 1 do
                        local p = players:get(j)
                        if p and tostring(p) == username then
                            table.insert(result, sh)
                            break
                        end
                    end
                end
            end
        end
    end
    return result
end

-- =============================================
-- FACTION SAFEHOUSE HELPERS
-- =============================================

--- Count faction-tagged safehouses for a given faction name.
--- Scans SafeHouse modData server-side; client uses its own registry in
--- CSR_FactionExtensions instead.
function CSR_SafehouseClaim.getFactionSafehouseCount(factionName)
    if not factionName then return 0 end
    local list = safehouseList()
    if not list or not list.size or not list.get then return 0 end
    local count = 0
    local sz = list:size()
    for i = 0, sz - 1 do
        local sh = list:get(i)
        if sh and sh.getModData then
            local md = sh:getModData()
            if md and md.csrFactionOwner == factionName then
                count = count + 1
            end
        end
    end
    return count
end

--- Max faction safehouse claims from sandbox.
function CSR_SafehouseClaim.getMaxFactionSafehouses()
    if CSR_FeatureFlags and CSR_FeatureFlags.getMaxFactionSafehouses then
        return CSR_FeatureFlags.getMaxFactionSafehouses()
    end
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    return sb.MaxFactionSafehouses or 2
end

--- True when the faction safehouse feature is enabled.
function CSR_SafehouseClaim.isFactionSafehouseEnabled()
    if CSR_FeatureFlags and CSR_FeatureFlags.isFactionSafehouseEnabled then
        return CSR_FeatureFlags.isFactionSafehouseEnabled()
    end
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    return sb.EnableFactionSafehouse ~= false
end

--- Read the faction-member role for a given username on a safehouse.
--- Returns nil when no role is set (treat as default member access).
function CSR_SafehouseClaim.getFactionRole(safehouse, username)
    if not safehouse or not username then return nil end
    if not safehouse.getModData then return nil end
    local md = safehouse:getModData()
    if not md or not md.csrFactionRoles then return nil end
    return md.csrFactionRoles[username]
end

return CSR_SafehouseClaim
