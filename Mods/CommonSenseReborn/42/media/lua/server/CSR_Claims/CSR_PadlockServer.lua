--[[
    CSR_PadlockServer.lua
    -------------------------------------------------------------------------
    v1.8.36 -- server-authoritative padlock layer for CSR claims.

    Stamps three flat modData keys on a target world object (container
    furniture or vehicle):
      csrPadlocked      = 1
      csrPadlockClaim   = <numeric claim id, defense-in-depth metadata>
      csrPadlockKeyHash = <8-char hex string>

    The matching key item carries the same csrPadlockKeyHash on its modData.
    Clients (CSR_ContainerGuard / CSR_VehicleClaimGuards) read this key and
    grant access to anyone holding the matching key item.

    Hard rules:
      * MP only. Skip on SP.
      * Flat primitives only on modData. No nested tables.
      * Original Padlock item is consumed; new Key1 is created with key hash.
      * On break: bolt cutters tool already validated client-side; server
        only validates proximity + sandbox flag.
--]]

if not isClient and not isServer then return end
if isClient and isClient() and not (isServer and isServer()) then return end

require "CSR_Claims/CSR_ClaimRegistry"
require "CSR_Claims/CSR_ClaimPermissions"
require "CSR_Claims/CSR_ClaimAudit"
require "CSR_VehicleClaim"

CSR_PadlockServer = CSR_PadlockServer or {}

local Registry = CSR_ClaimRegistry

local function flagOn()
    local sb = (SandboxVars and SandboxVars.CommonSenseReborn) or nil
    if not sb then return false end
    if sb.ClaimPadlockEnabled == false then return false end
    return true
end

local function safeUsername(player)
    if not player then return "" end
    if player.getUsername then
        local u = player:getUsername()
        if u then return tostring(u) end
    end
    return ""
end

local function isAdminOrModerator(player)
    if not player or not player.getAccessLevel then return false end
    local level = player:getAccessLevel()
    return level == "Admin" or level == "Moderator"
end

local function sendResult(player, ok, text)
    if not player then return end
    sendServerCommand(player, "CommonSenseReborn", "CSR_ClaimResult",
        { ok = ok and true or false, text = text or "" })
end

-- Eight-char hex hash, derived from rng + game time. Defense-in-depth only;
-- key matching is done by direct modData equality, so collision is not a
-- security boundary.
local function newKeyHash()
    local r1 = ZombRand and ZombRand(2147483647) or 0
    local r2 = ZombRand and ZombRand(2147483647) or 0
    local t  = (getTimestampMs and getTimestampMs()) or 0
    return string.format("%08x", (r1 + r2 + t) % 0xffffffff)
end

local function squareOf(x, y, z)
    if not getCell then return nil end
    local cell = getCell()
    if not cell or not cell.getGridSquare then return nil end
    return cell:getGridSquare(x, y, z or 0)
end

local function vehicleKeyFromArgs(args)
    if not args then return "" end
    local key = tostring(args.vehicleKey or args.vehicleId or "")
    if string.sub(key, 1, 4) == "sql:" or string.sub(key, 1, 4) == "csr:" then
        return key
    end
    return ""
end

local function normalizePositiveId(value)
    if value == nil then return nil end
    local s = tostring(value)
    if s == "" or s == "nil" then return nil end
    local n = tonumber(s)
    if not n or n <= 0 then return nil end
    return tostring(math.floor(n))
end

local function argSqlId(args)
    if not args then return nil end
    local sql = normalizePositiveId(args.vehicleSqlId)
    if sql then return sql end
    local key = vehicleKeyFromArgs(args)
    if string.sub(key, 1, 4) == "sql:" then
        return normalizePositiveId(string.sub(key, 5))
    end
    return nil
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
        local vehicle = vehicles:get(i)
        if vehicle then out[#out + 1] = vehicle end
    end
    return out
end

local function vehicleSqlId(vehicle)
    if CSR_VehicleClaim and CSR_VehicleClaim.getVehicleSqlId then
        return normalizePositiveId(CSR_VehicleClaim.getVehicleSqlId(vehicle))
    end
    if vehicle and vehicle.getSqlId then
        return normalizePositiveId(vehicle:getSqlId())
    end
    return nil
end

local function vehicleScriptName(vehicle)
    if not vehicle or not vehicle.getScript then return "" end
    local script = vehicle:getScript()
    if not script or not script.getName then return "" end
    return tostring(script:getName() or "")
end

local function vehicleCoord(vehicle, getter)
    if not vehicle then return 0 end
    local value = 0
    if getter == "x" and vehicle.getX then value = vehicle:getX()
    elseif getter == "y" and vehicle.getY then value = vehicle:getY()
    elseif getter == "z" and vehicle.getZ then value = vehicle:getZ() end
    return math.floor(tonumber(value) or 0)
end

local function vehicleHasKey(vehicle, key)
    if not vehicle or key == "" then return false end
    if not (CSR_VehicleClaim and CSR_VehicleClaim.getVehicleKeyCandidates) then return false end
    local candidates = CSR_VehicleClaim.getVehicleKeyCandidates(vehicle, false)
    for i = 1, #candidates do
        if candidates[i] == key then return true end
    end
    return false
end

local function vehicleMatchesArgs(vehicle, args, key)
    if not vehicle then return false end
    if key ~= "" and vehicleHasKey(vehicle, key) then return true end

    local sql = argSqlId(args)
    if sql and vehicleSqlId(vehicle) == sql then return true end

    local x = args and tonumber(args.x) or nil
    local y = args and tonumber(args.y) or nil
    if not x or not y then return false end
    local z = args and tonumber(args.z) or nil
    local script = tostring(args and args.vehicleScript or "")
    if script ~= "" and vehicleScriptName(vehicle) ~= script then return false end

    local vx = vehicleCoord(vehicle, "x")
    local vy = vehicleCoord(vehicle, "y")
    local vz = vehicleCoord(vehicle, "z")
    if z and math.abs(vz - math.floor(z)) > 1 then return false end
    return math.abs(vx - math.floor(x)) <= 2 and math.abs(vy - math.floor(y)) <= 2
end

local function vehicleFromArgs(player, args)
    local key = vehicleKeyFromArgs(args)
    if key ~= "" and CSR_VehicleClaim and CSR_VehicleClaim.findLoadedVehicleByKey then
        local found = CSR_VehicleClaim.findLoadedVehicleByKey(key)
        if found then return found end
    end

    local seated = player and player.getVehicle and player:getVehicle() or nil
    if vehicleMatchesArgs(seated, args, key) then return seated end

    local vehicles = loadedVehicles()
    for i = 1, #vehicles do
        if vehicleMatchesArgs(vehicles[i], args, key) then
            return vehicles[i]
        end
    end
    return nil
end

-- Find an IsoObject on the given square with a container we can lock.
-- Prefer the first object whose getContainer() ~= nil.
local function findContainerObject(sq)
    if not sq then return nil end
    local objs = sq:getObjects()
    if not objs then return nil end
    local n = (objs.size and objs:size()) or 0
    for i = 0, n - 1 do
        local o = objs:get(i)
        if o and o.getContainer then
            local c = o:getContainer()
            if c then return o end
        end
    end
    return nil
end

local function resolveItemTag(name)
    if not name or not ItemTag then return nil end
    local tag = ItemTag[name] or ItemTag[string.upper(name)]
    if tag then return tag end
    if ItemTag.get and ResourceLocation and ResourceLocation.of then
        return ItemTag.get(ResourceLocation.of(name))
    end
    return nil
end

local function getFirstByResolvedTags(inv, names)
    if not inv or not inv.getFirstTagRecurse then return nil end
    for i = 1, #names do
        local tag = resolveItemTag(names[i])
        if tag then
            local item = inv:getFirstTagRecurse(tag)
            if item then return item end
        end
    end
    return nil
end

local function findInventoryItem(inv, predicate)
    if not inv or not inv.getAllEvalRecurse or not ArrayList then return nil end
    local found = inv:getAllEvalRecurse(predicate, ArrayList.new())
    if found and found:size() > 0 then
        return found:get(0)
    end
    return nil
end

local function isPadlockItem(item)
    if not item then return false end
    local ft = item.getFullType and tostring(item:getFullType() or "") or ""
    local typ = item.getType and tostring(item:getType() or "") or ""
    return ft == "Base.Padlock"
        or ft == "Base.CombinationPadlock"
        or typ == "Padlock"
        or typ == "CombinationPadlock"
end

local function isBoltCutterItem(item)
    if not item then return false end
    local ft = item.getFullType and tostring(item:getFullType() or "") or ""
    local typ = item.getType and tostring(item:getType() or "") or ""
    return ft == "Base.BoltCutters" or typ == "BoltCutters"
end

-- Returns the FullType ("Base.Padlock" / "Base.CombinationPadlock" / etc.)
-- of the lock item that was consumed, or nil if none found. Recurses into
-- bags / pockets so the player isn't forced to surface the lock first.
local function consumeOnePadlock(player)
    if not player or not player.getInventory then return nil end
    local inv = player:getInventory()
    if not inv then return nil end
    local lock = nil
    lock = getFirstByResolvedTags(inv, { "base:lock", "base:padlock", "Lock" })
    if not lock and inv.getFirstTypeRecurse then
        lock = inv:getFirstTypeRecurse("Base.Padlock")
            or inv:getFirstTypeRecurse("Base.CombinationPadlock")
    end
    if not lock then
        lock = findInventoryItem(inv, isPadlockItem)
    end
    if not lock then return nil end
    local ft = lock.getFullType and tostring(lock:getFullType() or "") or ""
    local container = lock.getContainer and lock:getContainer() or inv
    if container and container.Remove then
        container:Remove(lock)
    end
    if ft == "" then ft = "Base.Padlock" end
    return ft
end

local function giveKeyToPlayer(player, keyHash, label)
    if not player or not player.getInventory then return nil end
    local inv = player:getInventory()
    if not inv or not InventoryItemFactory or not InventoryItemFactory.CreateItem then return nil end
    -- Build the key with name + hash BEFORE adding to inventory so the
    -- modData is stamped at item-create time and replicates intact to the
    -- owning client.
    local key = InventoryItemFactory.CreateItem("Base.Key1")
    if not key then return nil end
    if key.setName then key:setName(label or "CSR Padlock Key") end
    if key.setCustomName then key:setCustomName(true) end
    local md = key.getModData and key:getModData() or nil
    if md then md.csrPadlockKeyHash = tostring(keyHash or "") end
    inv:AddItem(key)
    -- Also push the player's keyring if available (vanilla pattern).
    if player.getCurrentKey == nil and player.addItemToKeyring and key then
        -- no-op: keyring API differs per build; AddItem suffices for inventory.
    end
    return key
end

-- Broadcast modData to all clients (world objects only -- vehicles use
-- their own transmit path).
local function broadcastObject(obj)
    if not obj then return end
    if obj.transmitModData then
        obj:transmitModData()
    end
    if obj.getSquare then
        local sq = obj:getSquare()
        if sq and sq.transmitModdataToClients then
            sq:transmitModdataToClients()
        end
    end
end

local function stampPadlock(obj, claimId, keyHash, owner)
    if not obj or not obj.getModData then return false end
    local md = obj:getModData()
    if not md then return false end
    md.csrPadlocked      = 1
    md.csrPadlockClaim   = tonumber(claimId) or 0
    md.csrPadlockKeyHash = tostring(keyHash or "")
    md.csrPadlockOwner   = tostring(owner or "")
    return true
end

local function clearPadlock(obj)
    if not obj or not obj.getModData then return end
    local md = obj:getModData()
    if not md then return end
    md.csrPadlocked      = nil
    md.csrPadlockClaim   = nil
    md.csrPadlockKeyHash = nil
    md.csrPadlockOwner   = nil
    md.csrPadlockType    = nil
end

local function playerHasMatchingKey(player, obj)
    if not player or not player.getInventory or not obj or not obj.getModData then
        return false
    end
    local md = obj:getModData()
    if not md or md.csrPadlocked ~= 1 then return false end
    local hash = tostring(md.csrPadlockKeyHash or "")
    if hash == "" then return false end
    local inv = player:getInventory()
    return findInventoryItem(inv, function(item)
        if not item or not item.getModData then return false end
        local imd = item:getModData()
        return imd and tostring(imd.csrPadlockKeyHash or "") == hash
    end) ~= nil
end

-- args = { x, y, z } OR { vehicleKey }
function CSR_PadlockServer.handleInstall(player, args)
    if not flagOn() then sendResult(player, false, "Padlocks disabled"); return end
    if not player or not args then return end
    local user = safeUsername(player)
    if user == "" then return end

    local target, claimId, isVehicle = nil, 0, false
    if vehicleKeyFromArgs(args) ~= "" then
        local v = vehicleFromArgs(player, args)
        if not v then sendResult(player, false, "Vehicle not found"); return end
        target = v
        isVehicle = true
        if CSR_VehicleClaim and CSR_VehicleClaim.getRegistryRow then
            local row = CSR_VehicleClaim.getRegistryRow(v)
            if row and row.kind == "vehicle" then
                claimId = row.id
            end
        end
    else
        local sq = squareOf(tonumber(args.x), tonumber(args.y), tonumber(args.z))
        if not sq then sendResult(player, false, "No square"); return end
        target = findContainerObject(sq)
        if not target then sendResult(player, false, "No container here"); return end
        if CSR_ClaimRegistry and CSR_ClaimRegistry.getAllRows then
            local sx, sy = sq:getX(), sq:getY()
            for _, row in pairs(CSR_ClaimRegistry.getAllRows() or {}) do
                if row.kind ~= "vehicle" then
                    local x2 = row.x + (row.w or 1)
                    local y2 = row.y + (row.h or 1)
                    if sx >= row.x and sx < x2 and sy >= row.y and sy < y2 then
                        claimId = row.id; break
                    end
                end
            end
        end
    end

    local row = (claimId and claimId > 0) and Registry.getRowById(claimId) or nil
    if not row then
        sendResult(player, false, isVehicle and "Claim this vehicle first" or "No claim here")
        return
    end
    if not CSR_ClaimPermissions.canDo(row, user, "padlock_install", player) then
        sendResult(player, false, "Not allowed (need coowner)")
        return
    end
    -- Already padlocked?
    local md = target.getModData and target:getModData() or nil
    if md and md.csrPadlocked == 1 then
        sendResult(player, false, "Already padlocked"); return
    end
    -- Consume one Padlock item (any shipped variant)
    local consumedType = consumeOnePadlock(player)
    if not consumedType then
        sendResult(player, false, "Need a Padlock item"); return
    end
    local hash = newKeyHash()
    stampPadlock(target, claimId, hash, user)
    -- Remember which lock variant was installed so removal refunds correctly.
    do
        local md2 = target.getModData and target:getModData() or nil
        if md2 then md2.csrPadlockType = consumedType end
    end
    if isVehicle then
        if target.transmitModData then target:transmitModData() end
    else
        broadcastObject(target)
    end
    giveKeyToPlayer(player, hash, "Padlock Key")
    if row and CSR_ClaimAudit and CSR_ClaimAudit.log then
        CSR_ClaimAudit.log("padlock_install", row, player, "", { vehicle = isVehicle and 1 or 0 })
    end
    sendResult(player, true, "Padlock installed")
end

function CSR_PadlockServer.handleRemove(player, args)
    if not flagOn() then return end
    if not player or not args then return end
    local user = safeUsername(player)
    if user == "" then return end

    local target, isVehicle = nil, false
    if vehicleKeyFromArgs(args) ~= "" then
        target = vehicleFromArgs(player, args); isVehicle = true
    else
        local sq = squareOf(tonumber(args.x), tonumber(args.y), tonumber(args.z))
        if sq then target = findContainerObject(sq) end
    end
    if not target then sendResult(player, false, "No target"); return end
    local md = target.getModData and target:getModData() or nil
    if not md or md.csrPadlocked ~= 1 then
        sendResult(player, false, "Not padlocked"); return
    end
    local claimId = tonumber(md.csrPadlockClaim) or 0
    local row = claimId > 0 and Registry.getRowById(claimId) or nil
    local hasKey = playerHasMatchingKey(player, target)
    if row and not hasKey and not CSR_ClaimPermissions.canDo(row, user, "padlock_remove", player) then
        sendResult(player, false, "Not allowed (need coowner)"); return
    end
    if not row and not hasKey and not isAdminOrModerator(player) then
        sendResult(player, false, "Need matching key")
        return
    end
    -- Refund the same lock variant that was originally installed.
    local refundType = tostring(md.csrPadlockType or "Base.Padlock")
    clearPadlock(target)
    if isVehicle then
        if target.transmitModData then target:transmitModData() end
    else
        broadcastObject(target)
    end
    -- Refund the lock item.
    if player.getInventory then
        player:getInventory():AddItem(refundType)
    end
    if row and CSR_ClaimAudit and CSR_ClaimAudit.log then
        CSR_ClaimAudit.log("padlock_remove", row, player, "", { vehicle = isVehicle and 1 or 0 })
    end
    sendResult(player, true, "Padlock removed")
end

function CSR_PadlockServer.handleBreak(player, args)
    if not flagOn() then return end
    if not player or not args then return end
    local user = safeUsername(player)
    if user == "" then return end

    local target, isVehicle = nil, false
    if vehicleKeyFromArgs(args) ~= "" then
        target = vehicleFromArgs(player, args); isVehicle = true
    else
        local sq = squareOf(tonumber(args.x), tonumber(args.y), tonumber(args.z))
        if sq then target = findContainerObject(sq) end
    end
    if not target then sendResult(player, false, "No target"); return end
    local md = target.getModData and target:getModData() or nil
    if not md or md.csrPadlocked ~= 1 then
        sendResult(player, false, "Not padlocked"); return
    end
    -- Bolt-cutter break: client guarantees the timed action ran; server just
    -- validates that the player has bolt cutters in inventory now.
    local hasBC = false
    if player.getInventory then
        local inv = player:getInventory()
        local it = getFirstByResolvedTags(inv, { "base:boltcutters", "BoltCutters" })
            or findInventoryItem(inv, isBoltCutterItem)
        if it then hasBC = true end
    end
    if not hasBC then sendResult(player, false, "Need bolt cutters"); return end
    local claimId = tonumber(md.csrPadlockClaim) or 0
    local row = claimId > 0 and Registry.getRowById(claimId) or nil
    clearPadlock(target)
    if isVehicle then
        if target.transmitModData then target:transmitModData() end
    else
        broadcastObject(target)
    end
    if row and CSR_ClaimAudit and CSR_ClaimAudit.log then
        CSR_ClaimAudit.log("padlock_break", row, player, "", { vehicle = isVehicle and 1 or 0 })
    end
    sendResult(player, true, "Padlock cut")
end

CSR_PadlockServer.DISPATCH = {
    CSR_PadlockInstall = CSR_PadlockServer.handleInstall,
    CSR_PadlockRemove  = CSR_PadlockServer.handleRemove,
    CSR_PadlockBreak   = CSR_PadlockServer.handleBreak,
}

return CSR_PadlockServer
