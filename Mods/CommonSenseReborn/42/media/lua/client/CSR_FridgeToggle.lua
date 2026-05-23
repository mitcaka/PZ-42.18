require "CSR_FeatureFlags"
require "CSR_Utils"

-- Instant timed action that sends the toggle request to the server.
CSR_FridgeToggleAction = ISBaseTimedAction:derive("CSR_FridgeToggleAction")

function CSR_FridgeToggleAction:isValid()
    return true
end

function CSR_FridgeToggleAction:update() end

function CSR_FridgeToggleAction:start()
    self.character:faceThisObject(self.object)
end

function CSR_FridgeToggleAction:stop()
    ISBaseTimedAction.stop(self)
end

function CSR_FridgeToggleAction:perform()
    sendClientCommand(self.character, "CommonSenseReborn", "FridgeToggle", {
        x = self.object:getX(),
        y = self.object:getY(),
        z = self.object:getZ(),
    })
    ISBaseTimedAction.perform(self)
end

function CSR_FridgeToggleAction:new(player, object)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character  = player
    o.stopOnWalk = false
    o.stopOnRun  = false
    o.maxTime    = 0
    o.object     = object
    return o
end

-- Returns true when obj has any fridge or freezer container (on or off).
local function hasFridgeContainer(obj)
    if not obj or not obj.getContainerCount or obj:getContainerCount() <= 0 then
        return false, false
    end
    local hasPowered, hasUnpowered = false, false
    pcall(function()
        hasPowered  = obj:getContainerByType("fridge")   ~= nil
                   or obj:getContainerByType("freezer")  ~= nil
        hasUnpowered = obj:getContainerByType("fridge_off")  ~= nil
                    or obj:getContainerByType("freezer_off") ~= nil
    end)
    return hasPowered, hasUnpowered
end

local function onWorldContextMenu(playerNum, context, worldObjects, test)
    if test then return end
    if not CSR_FeatureFlags.isFridgeToggleEnabled() then return end

    local player = getSpecificPlayer(playerNum)
    if not player or player:isAsleep() then return end

    local function doToggle(_, objPlayer, obj)
        if luautils.walkAdj(objPlayer, obj:getSquare()) then
            ISTimedActionQueue.add(CSR_FridgeToggleAction:new(objPlayer, obj))
        end
    end

    for _, obj in ipairs(worldObjects) do
        local hasPowered, hasUnpowered = hasFridgeContainer(obj)
        if hasPowered then
            context:addOption(getText("ContextMenu_TurnOff"), worldObjects, doToggle, player, obj)
            break
        elseif hasUnpowered then
            context:addOption(getText("ContextMenu_TurnOn"), worldObjects, doToggle, player, obj)
            break
        end
    end
end

-- Apply the server's synced state to the local world object.
local function applyFridgeSyncedState(x, y, z, fridgeState, freezerState)
    local ok, gridSquare = pcall(function()
        return getWorld():getCell():getGridSquare(x, y, z)
    end)
    if not ok or not gridSquare then return end

    local objects = gridSquare:getObjects()
    if not objects then return end

    local object = nil
    for i = 0, objects:size() - 1 do
        local o = objects:get(i)
        if o and o.getContainerCount and o:getContainerCount() > 0 then
            local found = false
            pcall(function()
                found = o:getContainerByType("fridge")      ~= nil
                     or o:getContainerByType("fridge_off")  ~= nil
                     or o:getContainerByType("freezer")     ~= nil
                     or o:getContainerByType("freezer_off") ~= nil
            end)
            if found then object = o; break end
        end
    end

    if not object then return end

    pcall(function()
        if fridgeState == "on" and object:getContainerByType("fridge_off") then
            object:getContainerByType("fridge_off"):setType("fridge")
        elseif fridgeState == "off" and object:getContainerByType("fridge") then
            object:getContainerByType("fridge"):setType("fridge_off")
        end
        if freezerState == "on" and object:getContainerByType("freezer_off") then
            object:getContainerByType("freezer_off"):setType("freezer")
        elseif freezerState == "off" and object:getContainerByType("freezer") then
            object:getContainerByType("freezer"):setType("freezer_off")
        end
    end)

    pcall(function() IsoGenerator.updateGenerator(object:getSquare()) end)
    pcall(function() object:checkHaveElectricity() end)

    local playerData = getPlayerData(getPlayer():getPlayerNum())
    if playerData then
        pcall(function() playerData.playerInventory:refreshBackpacks() end)
        pcall(function() playerData.lootInventory:refreshBackpacks() end)
    end
end

local function onServerCommand(module, command, args)
    if module ~= "CommonSenseReborn" or command ~= "FridgeSynced" then return end
    if not args or args.x == nil then return end
    applyFridgeSyncedState(args.x, args.y, args.z, args.fridge, args.freezer)
end

Events.OnFillWorldObjectContextMenu.Add(onWorldContextMenu)
Events.OnServerCommand.Add(onServerCommand)
