-- =============================================================================
-- Cat Pay Per Fuel — Client (context menu hooks & payment flow)
-- =============================================================================
if isServer() then return end

require "Cat_EconomyUtils"

Cat_PayPerFuel = Cat_PayPerFuel or {}
Cat_PayPerFuel.pending = {}
Cat_PayPerFuel.nextPendingAction = nil

-- ---------------------------------------------------------------------------
-- Client pending session helpers (used by shared isValid override)
-- ---------------------------------------------------------------------------
function Cat_PayPerFuel.checkClientPending(player, fuelStation, actionType)
    if not player then return false end
    local username = player:getUsername()
    local pending = Cat_PayPerFuel.pending[username]
    if not pending then return false end
    if pending.actionType ~= actionType then return false end
    if pending.expiry < getTimestamp() then
        Cat_PayPerFuel.pending[username] = nil
        return false
    end
    if fuelStation and pending.pumpX then
        local sq = fuelStation:getSquare()
        if sq and (sq:getX() ~= pending.pumpX or sq:getY() ~= pending.pumpY or sq:getZ() ~= pending.pumpZ) then
            return false
        end
    end
    return true
end

function Cat_PayPerFuel.clearClientPending(player)
    if not player then return end
    Cat_PayPerFuel.pending[player:getUsername()] = nil
end

-- ---------------------------------------------------------------------------
-- Server response handler
-- ---------------------------------------------------------------------------
local function onServerCommand(module, command, args)
    if module ~= "Cat_PayPerFuel" then return end
    local player = getSpecificPlayer(0)
    if not player then return end
    local username = player:getUsername()

    if command == "prePayApproved" then
        local action = Cat_PayPerFuel.nextPendingAction
        Cat_PayPerFuel.nextPendingAction = nil
        if not action then return end

        Cat_PayPerFuel.pending[username] = {
            actionType = args.actionType,
            pumpX = args.pumpX,
            pumpY = args.pumpY,
            pumpZ = args.pumpZ,
            expiry = getTimestamp() + 60,
            litres = args.litres,
        }

        HaloTextHelper.addGoodText(player, "Paid $" .. tostring(args.cost) .. " for fuel.")

        if action.actionType == "take" then
            ISWorldObjectContextMenu.onTakeFuelNew_Original(
                action.worldobjects, action.fuelObject, action.fuelContainerList, action.item, action.playerNum
            )
        elseif action.actionType == "refuel" then
            ISVehiclePartMenu.onPumpGasoline_Original(action.playerObj, action.part)
        end

    elseif command == "prePayDenied" then
        Cat_PayPerFuel.nextPendingAction = nil
        HaloTextHelper.addBadText(player, args.reason or "Not enough money!")
    end
end
Events.OnServerCommand.Add(onServerCommand)

-- ---------------------------------------------------------------------------
-- Hook: Gas can from pump — menu text & remove bulk Fill All options
-- ---------------------------------------------------------------------------
local original_doFillFuelMenu = ISWorldObjectContextMenu.doFillFuelMenu
ISWorldObjectContextMenu.doFillFuelMenu = function(source, playerNum, context)
    local price = Cat_PayPerFuel.getPricePerLitre()
    local original_addOption = context.addOption
    local original_addGetUpOption = ISContextMenu.addGetUpOption
    if price > 0 then
        context.addOption = function(self, name, target, onSelect, ...)
            if name == getText("ContextMenu_TakeGasFromPump") then
                name = name .. " ($" .. price .. "/L)"
            end
            return original_addOption(self, name, target, onSelect, ...)
        end

        ISContextMenu.addGetUpOption = function(self, name, ...)
            if name == getText("ContextMenu_FillAll") then
                return nil
            end
            return original_addGetUpOption(self, name, ...)
        end
    end
    original_doFillFuelMenu(source, playerNum, context)
    context.addOption = original_addOption
    ISContextMenu.addGetUpOption = original_addGetUpOption
end

-- ---------------------------------------------------------------------------
-- Hook: Vehicle refuel — menu text (radial + context)
-- ---------------------------------------------------------------------------
local original_FillPartMenu = ISVehicleMenu.FillPartMenu
ISVehicleMenu.FillPartMenu = function(playerIndex, context, slice, vehicle)
    local price = Cat_PayPerFuel.getPricePerLitre()
    local original_sliceAddSlice = slice and slice.addSlice
    local original_contextAddOption = context and context.addOption

    if price > 0 and slice then
        slice.addSlice = function(self, text, texture, onSelect, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
            if text == getText("ContextMenu_VehicleRefuelFromPump") then
                text = text .. " ($" .. price .. "/L)"
            end
            return original_sliceAddSlice(self, text, texture, onSelect, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
        end
    end

    if price > 0 and context then
        context.addOption = function(self, name, target, onSelect, ...)
            if name == getText("ContextMenu_VehicleRefuelFromPump") then
                name = name .. " ($" .. price .. "/L)"
            end
            return original_contextAddOption(self, name, target, onSelect, ...)
        end
    end

    original_FillPartMenu(playerIndex, context, slice, vehicle)

    if slice then slice.addSlice = original_sliceAddSlice end
    if context then context.addOption = original_contextAddOption end
end

-- ---------------------------------------------------------------------------
-- Hook: Gas can from pump — action (with partial-fill support)
-- ---------------------------------------------------------------------------
ISWorldObjectContextMenu.onTakeFuelNew_Original = ISWorldObjectContextMenu.onTakeFuelNew
ISWorldObjectContextMenu.onTakeFuelNew = function(worldobjects, fuelObject, fuelContainerList, fuelContainer, player)
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local price = Cat_PayPerFuel.getPricePerLitre()
    if price == 0 then
        ISWorldObjectContextMenu.onTakeFuelNew_Original(worldobjects, fuelObject, fuelContainerList, fuelContainer, player)
        return
    end

    if not fuelContainerList or #fuelContainerList == 0 then
        fuelContainerList = { fuelContainer }
    end

    local totalLitres = 0
    local totalCost = 0
    for _, item in ipairs(fuelContainerList) do
        local litres, cost = Cat_PayPerFuel.calcTakeFuelCost(fuelObject, item)
        totalLitres = totalLitres + litres
        totalCost = totalCost + cost
    end

    if totalCost <= 0 then
        ISWorldObjectContextMenu.onTakeFuelNew_Original(worldobjects, fuelObject, fuelContainerList, fuelContainer, player)
        return
    end

    local money = Cat_EconomyUtils.getMoneyCount(playerObj)
    if money < totalCost then
        -- Bulk fills require full payment; partial fill is for single containers only.
        if #fuelContainerList > 1 then
            HaloTextHelper.addBadText(playerObj, "Need $" .. totalCost .. " for fuel!")
            return
        end
        local affordableLitres = math.min(totalLitres, math.floor(money / price))
        local affordableCost = math.ceil(affordableLitres * price)
        if affordableLitres <= 0 or affordableCost <= 0 then
            HaloTextHelper.addBadText(playerObj, "Need $" .. price .. " for any fuel!")
            return
        end
        totalLitres = affordableLitres
        totalCost = affordableCost
    end

    local sq = fuelObject:getSquare()
    Cat_PayPerFuel.nextPendingAction = {
        actionType = "take",
        worldobjects = worldobjects,
        fuelObject = fuelObject,
        fuelContainerList = fuelContainerList,
        item = fuelContainer,
        playerNum = player,
    }

    sendClientCommand("Cat_PayPerFuel", "prePayFuel", {
        actionType = "take",
        litres = totalLitres,
        cost = totalCost,
        pumpX = sq and sq:getX() or 0,
        pumpY = sq and sq:getY() or 0,
        pumpZ = sq and sq:getZ() or 0,
    })
end

-- ---------------------------------------------------------------------------
-- Hook: Vehicle refuel from pump (with partial-fill support)
-- ---------------------------------------------------------------------------
ISVehiclePartMenu.onPumpGasoline_Original = ISVehiclePartMenu.onPumpGasoline
ISVehiclePartMenu.onPumpGasoline = function(playerObj, part)
    if not playerObj or not part then return end

    local price = Cat_PayPerFuel.getPricePerLitre()
    if price == 0 then
        ISVehiclePartMenu.onPumpGasoline_Original(playerObj, part)
        return
    end

    local fuelStation = ISVehiclePartMenu.getNearbyFuelPump(part:getVehicle())
    if not fuelStation then
        ISVehiclePartMenu.onPumpGasoline_Original(playerObj, part)
        return
    end

    local litres, cost = Cat_PayPerFuel.calcRefuelCost(fuelStation, part)
    if cost <= 0 then
        ISVehiclePartMenu.onPumpGasoline_Original(playerObj, part)
        return
    end

    local money = Cat_EconomyUtils.getMoneyCount(playerObj)
    if money < cost then
        local affordableLitres = math.min(litres, math.floor(money / price))
        local affordableCost = math.ceil(affordableLitres * price)
        if affordableLitres <= 0 or affordableCost <= 0 then
            HaloTextHelper.addBadText(playerObj, "Need $" .. price .. " for any fuel!")
            return
        end
        litres = affordableLitres
        cost = affordableCost
    end

    local sq = fuelStation:getSquare()
    Cat_PayPerFuel.nextPendingAction = {
        actionType = "refuel",
        playerObj = playerObj,
        part = part,
    }

    sendClientCommand("Cat_PayPerFuel", "prePayFuel", {
        actionType = "refuel",
        litres = litres,
        cost = cost,
        pumpX = sq and sq:getX() or 0,
        pumpY = sq and sq:getY() or 0,
        pumpZ = sq and sq:getZ() or 0,
    })
end

print("[Cat_PayPerFuel] Client hooks loaded.")
