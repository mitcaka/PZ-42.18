-- =============================================================================
-- Cat Vehicle Claim — Shared (helpers & permission checks)
-- =============================================================================

Cat_VehicleClaim = Cat_VehicleClaim or {}
Cat_VehicleClaim.claims = Cat_VehicleClaim.claims or {}

-- ---------------------------------------------------------------------------
-- Vehicle identifier (persistent across restarts)
-- ---------------------------------------------------------------------------
function Cat_VehicleClaim.getVehicleIdentifier(vehicle)
    if not vehicle then return nil end
    -- getKeyId() is unique per spawned vehicle and persists across restarts
    local keyId = vehicle:getKeyId()
    if keyId and keyId > 0 then
        return "key_" .. tostring(keyId)
    end
    -- Fallback for vehicles without keys (trailers, burnt cars, etc.)
    return "id_" .. tostring(vehicle:getId())
end

-- ---------------------------------------------------------------------------
-- Admin check
-- ---------------------------------------------------------------------------
function Cat_VehicleClaim.isAdmin(player)
    if not player then return false end
    local access = player:getAccessLevel()
    return access == "admin" or access == "Admin"
        or access == "moderator" or access == "Moderator"
end

-- ---------------------------------------------------------------------------
-- Get claim record for a vehicle
-- ---------------------------------------------------------------------------
function Cat_VehicleClaim.getClaim(vehicleId)
    if isServer() then
        local data = ModData.getOrCreate("Cat_VehicleClaim")
        return data and data[vehicleId] or nil
    else
        return Cat_VehicleClaim.claims[vehicleId]
    end
end

-- ---------------------------------------------------------------------------
-- Check if a vehicle is claimed
-- ---------------------------------------------------------------------------
function Cat_VehicleClaim.isClaimed(vehicleId)
    local claim = Cat_VehicleClaim.getClaim(vehicleId)
    return claim ~= nil and claim.owner ~= nil
end

-- ---------------------------------------------------------------------------
-- Check if player is the owner
-- ---------------------------------------------------------------------------
function Cat_VehicleClaim.isOwner(player, vehicleId)
    if not player then return false end
    local claim = Cat_VehicleClaim.getClaim(vehicleId)
    if not claim then return false end
    return claim.owner == player:getUsername()
end

-- ---------------------------------------------------------------------------
-- Check guest permissions
-- ---------------------------------------------------------------------------
function Cat_VehicleClaim.getGuestPerms(vehicleId, username)
    local claim = Cat_VehicleClaim.getClaim(vehicleId)
    if not claim or not claim.guests then return nil end
    return claim.guests[username]
end

function Cat_VehicleClaim.hasGuestPerm(vehicleId, username, perm)
    local perms = Cat_VehicleClaim.getGuestPerms(vehicleId, username)
    if not perms then return false end
    return perms[perm] == true
end

-- ---------------------------------------------------------------------------
-- Unified permission checks
-- ---------------------------------------------------------------------------
function Cat_VehicleClaim.canEnter(player, vehicle)
    if not player or not vehicle then return true end
    local vid = Cat_VehicleClaim.getVehicleIdentifier(vehicle)
    local claim = Cat_VehicleClaim.getClaim(vid)
    if claim == nil then
        if not isServer() and Cat_VehicleClaim._initialSyncComplete == false then
            return false
        end
        return true
    end
    if not claim.owner then return true end
    if Cat_VehicleClaim.isAdmin(player) then return true end
    if Cat_VehicleClaim.isOwner(player, vid) then return true end
    if Cat_VehicleClaim.hasGuestPerm(vid, player:getUsername(), "passenger") then return true end
    if claim.everyone and claim.everyone.passenger then return true end
    return false
end

function Cat_VehicleClaim.canUseMechanics(player, vehicle)
    if not player or not vehicle then return true end
    local vid = Cat_VehicleClaim.getVehicleIdentifier(vehicle)
    local claim = Cat_VehicleClaim.getClaim(vid)
    if claim == nil then
        if not isServer() and Cat_VehicleClaim._initialSyncComplete == false then
            return false
        end
        return true
    end
    if not claim.owner then return true end
    if Cat_VehicleClaim.isAdmin(player) then return true end
    if Cat_VehicleClaim.isOwner(player, vid) then return true end
    if Cat_VehicleClaim.hasGuestPerm(vid, player:getUsername(), "mechanics") then return true end
    if claim.everyone and claim.everyone.mechanics then return true end
    return false
end

function Cat_VehicleClaim.canUseTrunk(player, vehicle)
    if not player or not vehicle then return true end
    local vid = Cat_VehicleClaim.getVehicleIdentifier(vehicle)
    local claim = Cat_VehicleClaim.getClaim(vid)
    if claim == nil then
        if not isServer() and Cat_VehicleClaim._initialSyncComplete == false then
            return false
        end
        return true
    end
    if not claim.owner then return true end
    if Cat_VehicleClaim.isAdmin(player) then return true end
    if Cat_VehicleClaim.isOwner(player, vid) then return true end
    if Cat_VehicleClaim.hasGuestPerm(vid, player:getUsername(), "trunk") then return true end
    if claim.everyone and claim.everyone.trunk then return true end
    return false
end

-- ---------------------------------------------------------------------------
-- Default guest permissions
-- ---------------------------------------------------------------------------
function Cat_VehicleClaim.defaultGuestPerms()
    return { passenger = true, trunk = false, mechanics = false }
end

-- ---------------------------------------------------------------------------
-- Sandbox: max claims per player (0 = unlimited)
-- ---------------------------------------------------------------------------
function Cat_VehicleClaim.getMaxClaimsPerPlayer()
    if SandboxVars.Cat_VehicleClaim and SandboxVars.Cat_VehicleClaim.MaxClaimsPerPlayer ~= nil then
        return SandboxVars.Cat_VehicleClaim.MaxClaimsPerPlayer
    end
    return 3
end

print("[Cat_VehicleClaim] Shared utilities loaded.")
