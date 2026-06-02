-- =============================================================================
-- Cat Pay Per Fuel — Server (payment authority)
-- =============================================================================
if not isServer() then return end

require "Cat_EconomyUtils"

Cat_PayPerFuel = Cat_PayPerFuel or {}
Cat_PayPerFuel.sessions = {}

-- ---------------------------------------------------------------------------
-- Session helpers
-- ---------------------------------------------------------------------------
function Cat_PayPerFuel.checkServerSession(player, fuelStation, actionType)
    if not player then return false end
    local username = player:getUsername()
    local session = Cat_PayPerFuel.sessions[username]
    if not session then return false end
    if session.actionType ~= actionType then return false end
    if (getTimestamp() - session.timestamp) > 60 then
        Cat_PayPerFuel.sessions[username] = nil
        return false
    end
    if fuelStation then
        local sq = fuelStation:getSquare()
        if sq and (sq:getX() ~= session.pumpX or sq:getY() ~= session.pumpY or sq:getZ() ~= session.pumpZ) then
            return false
        end
    end
    return true
end

function Cat_PayPerFuel.clearServerSession(player)
    if not player then return end
    Cat_PayPerFuel.sessions[player:getUsername()] = nil
end

-- ---------------------------------------------------------------------------
-- Command handler
-- ---------------------------------------------------------------------------
local function onClientCommand(module, command, player, args)
    if module ~= "Cat_PayPerFuel" then return end
    if command ~= "prePayFuel" then return end
    if not player then return end

    local username = player:getUsername()
    local price = Cat_PayPerFuel.getPricePerLitre()

    if price == 0 then
        sendServerCommand(player, "Cat_PayPerFuel", "prePayApproved", {
            actionType = args.actionType,
            pumpX = args.pumpX,
            pumpY = args.pumpY,
            pumpZ = args.pumpZ,
            litres = args.litres,
            cost = 0,
        })
        return
    end

    local cost = args.cost or 0
    local litres = args.litres or 0

    -- Verify the client-sent cost matches the expected price for the requested litres.
    if cost > 0 and cost ~= math.ceil(litres * price) then
        sendServerCommand(player, "Cat_PayPerFuel", "prePayDenied", {
            reason = "Price mismatch. Try again.",
        })
        return
    end

    if cost <= 0 then
        sendServerCommand(player, "Cat_PayPerFuel", "prePayApproved", {
            actionType = args.actionType,
            pumpX = args.pumpX,
            pumpY = args.pumpY,
            pumpZ = args.pumpZ,
            litres = args.litres,
            cost = 0,
        })
        return
    end

    local money = Cat_EconomyUtils.getMoneyCount(player)
    if money < cost then
        sendServerCommand(player, "Cat_PayPerFuel", "prePayDenied", {
            reason = "Need $" .. cost .. " for fuel!",
        })
        return
    end

    local ok = Cat_EconomyUtils.removeMoney(player, cost)
    if not ok then
        sendServerCommand(player, "Cat_PayPerFuel", "prePayDenied", {
            reason = "Payment failed. Try again.",
        })
        return
    end

    Cat_PayPerFuel.sessions[username] = {
        actionType = args.actionType,
        pumpX = args.pumpX,
        pumpY = args.pumpY,
        pumpZ = args.pumpZ,
        litres = args.litres,
        cost = cost,
        timestamp = getTimestamp(),
    }

    sendServerCommand(player, "Cat_PayPerFuel", "prePayApproved", {
        actionType = args.actionType,
        pumpX = args.pumpX,
        pumpY = args.pumpY,
        pumpZ = args.pumpZ,
        litres = args.litres,
        cost = cost,
    })
end
Events.OnClientCommand.Add(onClientCommand)

-- ---------------------------------------------------------------------------
-- Periodic cleanup of stale sessions
-- ---------------------------------------------------------------------------
local function everyTenMinutes()
    local now = getTimestamp()
    for username, session in pairs(Cat_PayPerFuel.sessions) do
        if (now - session.timestamp) > 120 then
            Cat_PayPerFuel.sessions[username] = nil
        end
    end
end
Events.EveryTenMinutes.Add(everyTenMinutes)

print("[Cat_PayPerFuel] Server authority loaded.")
