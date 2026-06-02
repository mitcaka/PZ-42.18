-- =============================================================================
-- Cat Vehicle Claim — Server (authority & persistence)
-- =============================================================================
if not isServer() then return end

Cat_VehicleClaim = Cat_VehicleClaim or {}

-- ---------------------------------------------------------------------------
-- ModData helpers
-- ---------------------------------------------------------------------------
local function getData()
    return ModData.getOrCreate("Cat_VehicleClaim")
end

local function getClaim(vehicleId)
    local data = getData()
    return data and data[vehicleId] or nil
end

local function setClaim(vehicleId, claim)
    local data = getData()
    if not data then return end
    data[vehicleId] = claim
end

-- ---------------------------------------------------------------------------
-- Broadcast helper
-- ---------------------------------------------------------------------------
local function broadcastSync(vehicleId)
    local claim = getClaim(vehicleId)
    local args = {
        vehicleId = vehicleId,
        owner = claim and claim.owner or nil,
        guests = claim and claim.guests or nil,
        everyone = claim and claim.everyone or nil,
        name = claim and claim.name or nil,
    }
    local players = getOnlinePlayers()
    if players then
        for i = 0, players:size() - 1 do
            local p = players:get(i)
            if p then
                sendServerCommand(p, "Cat_VehicleClaim", "syncClaim", args)
            end
        end
    end
end

local function sendHalo(player, text, isBad)
    if not player then return end
    sendServerCommand(player, "Cat_VehicleClaim", "haloText", {
        text = text,
        bad = isBad == true,
    })
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function countPlayerClaims(ownerName)
    local data = getData()
    if not data then return 0 end
    local count = 0
    for _, claim in pairs(data) do
        if claim and claim.owner == ownerName then
            count = count + 1
        end
    end
    return count
end

-- ---------------------------------------------------------------------------
-- Command handlers
-- ---------------------------------------------------------------------------
local function onClientCommand(module, command, player, args)
    if module ~= "Cat_VehicleClaim" then return end
    if not player then return end
    local username = player:getUsername()
    local vehicleId = args and args.vehicleId

    if command == "claimVehicle" then
        if not vehicleId then return end
        print("[Cat_VehicleClaim] claimVehicle from " .. username .. " for " .. tostring(vehicleId))
        local existing = getClaim(vehicleId)
        if existing and existing.owner then
            print("[Cat_VehicleClaim]   -> REJECTED: already owned by " .. existing.owner)
            sendHalo(player, "This vehicle is already claimed.", true)
            return
        end
        local maxClaims = Cat_VehicleClaim.getMaxClaimsPerPlayer()
        if maxClaims > 0 then
            local currentClaims = countPlayerClaims(username)
            if currentClaims >= maxClaims then
                sendHalo(player, "You can only claim " .. maxClaims .. " vehicle(s).", true)
                return
            end
        end
        setClaim(vehicleId, {
            owner = username,
            guests = {},
            name = args.name,
        })
        broadcastSync(vehicleId)
        sendHalo(player, "Vehicle claimed successfully.", false)

    elseif command == "unclaimVehicle" then
        if not vehicleId then return end
        print("[Cat_VehicleClaim] unclaimVehicle from " .. username .. " for " .. tostring(vehicleId))
        local claim = getClaim(vehicleId)
        if not claim or claim.owner ~= username then
            sendHalo(player, "You do not own this vehicle.", true)
            return
        end
        setClaim(vehicleId, nil)
        broadcastSync(vehicleId)
        sendHalo(player, "Vehicle unclaimed.", false)

    elseif command == "transferOwnership" then
        if not vehicleId then return end
        local newOwner = args and args.newOwner
        if not newOwner or newOwner == "" then
            sendHalo(player, "Enter a valid username.", true)
            return
        end
        local claim = getClaim(vehicleId)
        if not claim or claim.owner ~= username then
            sendHalo(player, "You do not own this vehicle.", true)
            return
        end
        claim.owner = newOwner
        -- Remove new owner from guests if they were there
        if claim.guests then
            claim.guests[newOwner] = nil
        end
        setClaim(vehicleId, claim)
        broadcastSync(vehicleId)
        sendHalo(player, "Ownership transferred to " .. newOwner .. ".", false)

    elseif command == "addGuest" then
        if not vehicleId then return end
        local guestName = args and args.guestName
        if not guestName or guestName == "" then
            sendHalo(player, "Enter a valid username.", true)
            return
        end
        local claim = getClaim(vehicleId)
        if not claim or claim.owner ~= username then
            sendHalo(player, "You do not own this vehicle.", true)
            return
        end
        if not claim.guests then
            claim.guests = {}
        end
        if claim.guests[guestName] then
            sendHalo(player, guestName .. " is already a guest.", true)
            return
        end
        claim.guests[guestName] = Cat_VehicleClaim.defaultGuestPerms()
        setClaim(vehicleId, claim)
        broadcastSync(vehicleId)
        sendHalo(player, guestName .. " added as guest.", false)

    elseif command == "removeGuest" then
        if not vehicleId then return end
        local guestName = args and args.guestName
        if not guestName then return end
        local claim = getClaim(vehicleId)
        if not claim or claim.owner ~= username then
            sendHalo(player, "You do not own this vehicle.", true)
            return
        end
        if claim.guests then
            claim.guests[guestName] = nil
        end
        setClaim(vehicleId, claim)
        broadcastSync(vehicleId)
        sendHalo(player, guestName .. " removed from guests.", false)

    elseif command == "setGuestPermissions" then
        if not vehicleId then return end
        local guestName = args and args.guestName
        local perms = args and args.perms
        if not guestName or not perms then return end
        local claim = getClaim(vehicleId)
        if not claim or claim.owner ~= username then
            sendHalo(player, "You do not own this vehicle.", true)
            return
        end
        if claim.guests and claim.guests[guestName] then
            claim.guests[guestName] = {
                passenger = perms.passenger == true,
                trunk = perms.trunk == true,
                mechanics = perms.mechanics == true,
            }
            setClaim(vehicleId, claim)
            broadcastSync(vehicleId)
            sendHalo(player, "Permissions updated.", false)
        end

    elseif command == "setEveryonePermissions" then
        if not vehicleId then return end
        local perms = args and args.perms
        if not perms then return end
        local claim = getClaim(vehicleId)
        if not claim or claim.owner ~= username then
            sendHalo(player, "You do not own this vehicle.", true)
            return
        end
        claim.everyone = {
            passenger = perms.passenger == true,
            trunk = perms.trunk == true,
            mechanics = perms.mechanics == true,
        }
        setClaim(vehicleId, claim)
        broadcastSync(vehicleId)
        sendHalo(player, "Everyone permissions updated.", false)

    elseif command == "requestClaim" then
        if not vehicleId then return end
        local claim = getClaim(vehicleId)
        sendServerCommand(player, "Cat_VehicleClaim", "syncClaim", {
            vehicleId = vehicleId,
            owner = claim and claim.owner or nil,
            guests = claim and claim.guests or nil,
            everyone = claim and claim.everyone or nil,
            name = claim and claim.name or nil,
        })

    elseif command == "requestFullSync" then
        if not player then return end
        local data = getData()
        if not data then return end
        local count = 0
        for vid, claim in pairs(data) do
            sendServerCommand(player, "Cat_VehicleClaim", "syncClaim", {
                vehicleId = vid,
                owner = claim.owner,
                guests = claim.guests,
                everyone = claim.everyone,
                name = claim.name,
            })
            count = count + 1
        end
        -- Tell client the sync batch is finished (even if zero claims were sent)
        sendServerCommand(player, "Cat_VehicleClaim", "syncComplete", {})
        print("[Cat_VehicleClaim] requestFullSync from " .. player:getUsername() .. " — sent " .. count .. " claims.")
    end
end
Events.OnClientCommand.Add(onClientCommand)

-- ---------------------------------------------------------------------------
-- Periodic full broadcast — ensures late-joining / reconnecting clients stay in sync
-- ---------------------------------------------------------------------------
local function everyTenMinutes()
    local data = getData()
    if not data then return end
    local count = 0
    for vehicleId, claim in pairs(data) do
        broadcastSync(vehicleId)
        count = count + 1
    end
    if count > 0 then
        print("[Cat_VehicleClaim] Periodic broadcast sent for " .. count .. " vehicles.")
    end
end
Events.EveryTenMinutes.Add(everyTenMinutes)

print("[Cat_VehicleClaim] Server authority loaded.")
