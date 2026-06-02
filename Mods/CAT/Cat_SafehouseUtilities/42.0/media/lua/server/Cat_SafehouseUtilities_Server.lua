-- =============================================================================
-- Cat Safehouse Utilities — Server (authority & billing)
-- =============================================================================
if not isServer() then return end

require "Cat_EconomyUtils"

Cat_SafehouseUtilities = Cat_SafehouseUtilities or {}

-- ---------------------------------------------------------------------------
-- ModData helpers
-- ---------------------------------------------------------------------------
local function getData()
    return ModData.getOrCreate("Cat_SafehouseUtilities")
end

local function getRecord(key)
    local data = getData()
    if not data[key] then
        data[key] = {}
    end
    return data[key]
end

-- ---------------------------------------------------------------------------
-- Ownership helper
-- ---------------------------------------------------------------------------
local function isSafehouseOwner(player, safehouse)
    if not player or not safehouse then return false end
    return safehouse:getOwner() == player:getUsername()
end

local function isPlayerAdmin(player)
    if not player then return false end
    local access = player:getAccessLevel()
    return access == "admin" or access == "Admin"
        or access == "moderator" or access == "Moderator"
end

-- ---------------------------------------------------------------------------
-- Safehouse iteration helpers
-- ---------------------------------------------------------------------------
local function forEachSafehouseSquare(safehouse, callback)
    local cell = getCell()
    for z = 0, 7 do
        for y = safehouse:getY(), safehouse:getY2() do
            for x = safehouse:getX(), safehouse:getX2() do
                local sq = cell:getGridSquare(x, y, z)
                if sq then
                    callback(sq)
                end
            end
        end
    end
end

local function forEachObjectInSafehouse(safehouse, callback)
    forEachSafehouseSquare(safehouse, function(sq)
        local objects = sq:getObjects()
        for i = 0, objects:size() - 1 do
            callback(objects:get(i), sq)
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Utility cutoff & restore
-- ---------------------------------------------------------------------------
local function turnOffObject(obj)
    if not obj then return end
    if instanceof(obj, "IsoLightSwitch") then
        obj:switchLight(false)
    elseif obj.setActivated then
        obj:setActivated(false)
    end
    if obj.getLights then
        local lights = obj:getLights()
        if lights then
            for i = 0, lights:size() - 1 do
                local light = lights:get(i)
                if light then light:setActive(false) end
            end
        end
    end
    if obj.getLightSource then
        local ls = obj:getLightSource()
        if ls then ls:setActive(false) end
    end
end

function Cat_SafehouseUtilities.cutoffSafehouse(safehouse)
    -- Turn off all lights and light-emitting objects
    forEachObjectInSafehouse(safehouse, function(obj)
        if instanceof(obj, "IsoLightSwitch") or (obj.getLights and obj:getLights() and obj:getLights():size() > 0) or obj:getLightSource() then
            turnOffObject(obj)
        end
    end)

    -- Turn off wall-powered electronics (TVs, radios, etc.)
    forEachObjectInSafehouse(safehouse, function(obj)
        if obj.getDeviceData then
            local dd = obj:getDeviceData()
            if dd and not dd:getIsBatteryPowered() and dd:getIsTurnedOn() then
                dd:setIsTurnedOn(false)
            end
        end
    end)

    -- Drain all water fixtures
    forEachObjectInSafehouse(safehouse, function(obj)
        if obj:getFluidContainer() and obj:getFluidAmount() > 0 then
            obj:getFluidContainer():removeFluid()
            obj:transmitModData()
        end
    end)
end

function Cat_SafehouseUtilities.drainWaterInSafehouse(safehouse)
    forEachObjectInSafehouse(safehouse, function(obj)
        if obj:getFluidContainer() and obj:getFluidAmount() > 0 then
            obj:getFluidContainer():removeFluid()
            obj:transmitModData()
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Notify players inside safehouse
-- ---------------------------------------------------------------------------
function Cat_SafehouseUtilities.notifyPlayersInSafehouse(safehouse, message)
    local players = getOnlinePlayers()
    if not players then return end
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player then
            local sq = player:getCurrentSquare()
            if sq and Cat_SafehouseUtilities.isSquareInSafehouse(sq, safehouse) then
                sendServerCommand(player, "Cat_SafehouseUtilities", "haloText", {
                    text = message,
                    bad = true,
                })
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Build blocked key list for client sync
-- ---------------------------------------------------------------------------
local function buildBlockedKeys()
    local blocked = {}
    local data = getData()
    local now = getGameTime():getWorldAgeHours()
    local list = SafeHouse.getSafehouseList()
    for i = 0, list:size() - 1 do
        local sh = list:get(i)
        local key = Cat_SafehouseUtilities.getSafehouseKey(sh)
        local record = data[key]
        if record and not record.exempt and record.expires and record.expires <= now then
            table.insert(blocked, key)
        end
    end
    return blocked
end

local function syncBlockedToAll()
    local blocked = buildBlockedKeys()
    sendServerCommand("Cat_SafehouseUtilities", "syncBlocked", { keys = blocked })
end

local function syncBlockedToPlayer(player)
    local blocked = buildBlockedKeys()
    sendServerCommand(player, "Cat_SafehouseUtilities", "syncBlocked", { keys = blocked })
end

-- ---------------------------------------------------------------------------
-- Status reply
-- ---------------------------------------------------------------------------
local function sendStatus(player, key)
    local record = getRecord(key)
    local now = getGameTime():getWorldAgeHours()
    if not record.expires then
        record.expires = now + Cat_SafehouseUtilities.getGracePeriodHours()
    end
    sendServerCommand(player, "Cat_SafehouseUtilities", "statusUpdate", {
        key = key,
        expires = record.expires,
        rate = Cat_SafehouseUtilities.getCyclePrice(),
        cycle = Cat_SafehouseUtilities.getActiveBillingCycle(),
        exempt = record.exempt or false,
    })
end

-- ---------------------------------------------------------------------------
-- Command handler
-- ---------------------------------------------------------------------------
local function onClientCommand(module, command, player, args)
    if module ~= "Cat_SafehouseUtilities" then return end
    if not player then return end

    if command == "requestStatus" then
        local key = args and args.safehouseKey
        if key then
            sendStatus(player, key)
        end
        return
    end

    if command == "payBank" then
        local key = args and args.safehouseKey
        local periods = args and args.periods
        local cost = args and args.cost
        if not key or not periods or periods <= 0 then return end

        local sh = Cat_SafehouseUtilities.getSafehouseByKey(key)
        if not sh or not isSafehouseOwner(player, sh) then
            sendServerCommand(player, "Cat_SafehouseUtilities", "paymentError", {
                reason = "Only the safehouse owner can pay.",
            })
            return
        end

        local cycle = Cat_SafehouseUtilities.getActiveBillingCycle()
        local expectedRate = Cat_SafehouseUtilities.getCyclePrice()
        if expectedRate == 0 then
            -- Free utilities; just extend expiry
            local record = getRecord(key)
            local now = getGameTime():getWorldAgeHours()
            record.expires = math.max(record.expires or now, now) + (periods * Cat_SafehouseUtilities.getCycleHours())
            sendStatus(player, key)
            syncBlockedToAll()
            return
        end

        local expectedCost = periods * expectedRate
        if cost ~= expectedCost then
            sendServerCommand(player, "Cat_SafehouseUtilities", "paymentError", {
                reason = "Price mismatch.",
            })
            return
        end

        local username = player:getUsername()
        local bankData = ModData.getOrCreate("Cat_BankingData")
        if not bankData.accounts then
            bankData.accounts = {}
        end
        local account = bankData.accounts[username]
        if not account then
            sendServerCommand(player, "Cat_SafehouseUtilities", "paymentError", {
                reason = "No bank account found.",
            })
            return
        end

        if account.balance < cost then
            sendServerCommand(player, "Cat_SafehouseUtilities", "paymentError", {
                reason = "Need $" .. cost .. " in your bank account for " .. periods .. " " .. cycle:lower() .. "s.",
            })
            return
        end

        account.balance = account.balance - cost
        bankData.accounts[username] = account

        local record = getRecord(key)
        local now = getGameTime():getWorldAgeHours()
        record.expires = math.max(record.expires or now, now) + (periods * Cat_SafehouseUtilities.getCycleHours())
        record.lastPaid = now

        sendStatus(player, key)
        syncBlockedToAll()
        Cat_SafehouseUtilities.notifyPlayersInSafehouse(
            Cat_SafehouseUtilities.getSafehouseByKey(key),
            "Utilities restored."
        )
        return
    end

    if command == "redeemCard" then
        local key = args and args.safehouseKey
        local cardType = args and args.cardType
        if not key or not cardType then return end

        local sh = Cat_SafehouseUtilities.getSafehouseByKey(key)
        if not sh or not isSafehouseOwner(player, sh) then
            sendServerCommand(player, "Cat_SafehouseUtilities", "paymentError", {
                reason = "Only the safehouse owner can redeem cards.",
            })
            return
        end

        local duration = Cat_SafehouseUtilities.getCardDuration(cardType)
        if duration <= 0 then
            sendServerCommand(player, "Cat_SafehouseUtilities", "paymentError", {
                reason = "Unknown card type.",
            })
            return
        end

        local inv = player:getInventory()
        local card = inv:getFirstTypeRecurse(cardType)
        if not card then
            sendServerCommand(player, "Cat_SafehouseUtilities", "paymentError", {
                reason = "No valid pre-paid card found.",
            })
            return
        end

        inv:Remove(card)
        sendRemoveItemFromContainer(inv, card)

        local record = getRecord(key)
        local now = getGameTime():getWorldAgeHours()
        record.expires = math.max(record.expires or now, now) + duration
        record.lastPaid = now

        sendStatus(player, key)
        syncBlockedToAll()
        Cat_SafehouseUtilities.notifyPlayersInSafehouse(
            Cat_SafehouseUtilities.getSafehouseByKey(key),
            "Utilities restored via pre-paid card."
        )
        return
    end

    -- -----------------------------------------------------------------------
    -- Admin commands
    -- -----------------------------------------------------------------------
    if command == "adminAddTime" then
        if not isPlayerAdmin(player) then return end
        local key = args and args.safehouseKey
        local hours = args and args.hours
        if not key or not hours or hours <= 0 then return end

        local record = getRecord(key)
        local now = getGameTime():getWorldAgeHours()
        record.expires = math.max(record.expires or now, now) + hours
        record.exempt = false
        syncBlockedToAll()
        local sh = Cat_SafehouseUtilities.getSafehouseByKey(key)
        if sh then
            Cat_SafehouseUtilities.notifyPlayersInSafehouse(sh, "Admin restored utilities.")
        end
        return
    end

    if command == "adminDisconnect" then
        if not isPlayerAdmin(player) then return end
        local key = args and args.safehouseKey
        if not key then return end

        local record = getRecord(key)
        local now = getGameTime():getWorldAgeHours()
        record.expires = now
        record.exempt = false
        syncBlockedToAll()
        local sh = Cat_SafehouseUtilities.getSafehouseByKey(key)
        if sh then
            Cat_SafehouseUtilities.cutoffSafehouse(sh)
            Cat_SafehouseUtilities.notifyPlayersInSafehouse(sh, "Admin disconnected utilities.")
        end
        return
    end

    if command == "adminToggleExempt" then
        if not isPlayerAdmin(player) then return end
        local key = args and args.safehouseKey
        if not key then return end

        local record = getRecord(key)
        record.exempt = not record.exempt
        syncBlockedToAll()
        local sh = Cat_SafehouseUtilities.getSafehouseByKey(key)
        if sh then
            local msg = record.exempt and "Admin exempted this building from utilities." or "Admin removed utility exemption."
            Cat_SafehouseUtilities.notifyPlayersInSafehouse(sh, msg)
        end
        return
    end
end

Events.OnClientCommand.Add(onClientCommand)

-- ---------------------------------------------------------------------------
-- Billing tick
-- ---------------------------------------------------------------------------
local function billingTick()
    if not Cat_SafehouseUtilities.isEnabled() then return end
    if Cat_SafehouseUtilities.getCyclePrice() == 0 then return end

    local data = getData()
    local now = getGameTime():getWorldAgeHours()
    local grace = Cat_SafehouseUtilities.getGracePeriodHours()
    local list = SafeHouse.getSafehouseList()
    local changed = false

    for i = 0, list:size() - 1 do
        local sh = list:get(i)
        local key = Cat_SafehouseUtilities.getSafehouseKey(sh)
        if key then
            local record = data[key]
            if not record then
                -- First time seeing this safehouse: grant grace period
                record = {}
                data[key] = record
                record.expires = now + grace
                changed = true
            end

            if not record.expires then
                record.expires = now + grace
                changed = true
            end

            -- Exempt buildings never get cutoff
            if record.exempt then
                if not record._wasPaid then
                    record._wasPaid = true
                    changed = true
                end
            else
                local isPaid = record.expires > now

                if not isPaid then
                    -- Currently unpaid
                    if record._wasPaid then
                        -- Just transitioned from paid to unpaid
                        Cat_SafehouseUtilities.cutoffSafehouse(sh)
                        Cat_SafehouseUtilities.notifyPlayersInSafehouse(sh, "Utilities disconnected. Pay your bill.")
                        record._wasPaid = false
                        changed = true
                    else
                        -- Still unpaid: keep draining water and ensure lights/electronics stay off
                        Cat_SafehouseUtilities.drainWaterInSafehouse(sh)
                        Cat_SafehouseUtilities.cutoffSafehouse(sh)
                    end
                else
                    -- Currently paid
                    if not record._wasPaid then
                        record._wasPaid = true
                        changed = true
                    end
                end
            end
        end
    end

    if changed then
        syncBlockedToAll()
    end
end

Events.EveryTenMinutes.Add(billingTick)

-- ---------------------------------------------------------------------------
-- Allow clients to request a sync of blocked keys
-- ---------------------------------------------------------------------------
Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "Cat_SafehouseUtilities" and command == "requestBlockedSync" then
        syncBlockedToPlayer(player)
    end
end)

print("[Cat_SafehouseUtilities] Server authority loaded.")
