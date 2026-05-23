require "ISUI/ISInventoryPaneContextMenu"
require "Vehicles/ISUI/ISVehicleMenu"
require "TimedActions/ISDropCorpseIntoContainer"
require "TimedActions/ISGrabCorpseAction"
require "TimedActions/ISUnequipAction"
require "Vehicles/TimedActions/ISPathFindAction"
require "CSR_FeatureFlags"

CSR_CorpseTrunk = CSR_CorpseTrunk or {}

local TRUNK_PART_IDS = {
    "TruckBed", "TruckBedOpen", "TrailerTrunk", "TrailerAnimalFood",
    "Trunk", "Cargo",
}
local TRUNK_KEYWORDS = { "truckbed", "trailertrunk", "trunk", "cargo" }
local SEARCH_RADIUS = 2

local function tr(key, fallback)
    if getText then
        local value = getText(key)
        if value and value ~= key then return value end
    end
    return fallback or key
end

local function isEnabled()
    if CSR_FeatureFlags and CSR_FeatureFlags.isCorpseTrunkEnabled then
        return CSR_FeatureFlags.isCorpseTrunkEnabled()
    end
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or nil
    if not sb then return true end
    return sb.EnableCorpseTrunk ~= false
end

local function lowerContainsAny(value, keywords)
    local s = string.lower(tostring(value or ""))
    for _, keyword in ipairs(keywords) do
        if string.find(s, keyword, 1, true) then return true end
    end
    return false
end

local function isHumanCorpse(body)
    if not body or not instanceof(body, "IsoDeadBody") then return false end
    if body.isAnimal and body:isAnimal() then return false end
    if body.getStaticMovingObjectIndex and body:getStaticMovingObjectIndex() < 0 then return false end
    local square = body.getSquare and body:getSquare() or nil
    if square and square.haveFire and square:haveFire() then return false end
    return true
end

local function isCargoPart(part)
    if not part or not part.getItemContainer or not part:getItemContainer() then return false end
    return lowerContainsAny(part:getId(), TRUNK_KEYWORDS)
        or lowerContainsAny(part.getArea and part:getArea() or "", TRUNK_KEYWORDS)
end

local function getClickedSquare(worldObjects)
    local fetch = ISWorldObjectContextMenu and ISWorldObjectContextMenu.fetchVars or nil
    if fetch and fetch.clickedSquare then return fetch.clickedSquare end
    if not worldObjects then return nil end
    for _, object in ipairs(worldObjects) do
        if object and object.getSquare then
            local square = object:getSquare()
            if square then return square end
        end
    end
    return nil
end

local function considerCorpse(playerObj, body, best)
    if not isHumanCorpse(body) then return best end
    local square = body:getSquare()
    if not square then return best end
    local d = playerObj.DistToSquared and playerObj:DistToSquared(square:getX() + 0.5, square:getY() + 0.5) or 0
    if not best or d < best.distance then
        return { body = body, distance = d }
    end
    return best
end

local function scanSquareForCorpse(playerObj, square, best)
    if not square or not square.getStaticMovingObjects then return best end
    local objects = square:getStaticMovingObjects()
    if not objects then return best end
    for i = 0, objects:size() - 1 do
        best = considerCorpse(playerObj, objects:get(i), best)
    end
    return best
end

local function scanNearbyCorpses(playerObj, square, best)
    if not square or not getCell then return best end
    local z = square:getZ()
    for x = square:getX() - SEARCH_RADIUS, square:getX() + SEARCH_RADIUS do
        for y = square:getY() - SEARCH_RADIUS, square:getY() + SEARCH_RADIUS do
            local candidate = getCell():getGridSquare(x, y, z)
            best = scanSquareForCorpse(playerObj, candidate, best)
        end
    end
    return best
end

local function findCorpse(playerObj, worldObjects)
    local fetch = ISWorldObjectContextMenu and ISWorldObjectContextMenu.fetchVars or nil
    local best = nil
    if fetch and fetch.body then
        best = considerCorpse(playerObj, fetch.body, best)
    end
    if worldObjects then
        for _, object in ipairs(worldObjects) do
            best = considerCorpse(playerObj, object, best)
            if object and object.getSquare then
                best = scanSquareForCorpse(playerObj, object:getSquare(), best)
            end
        end
    end
    local clickedSquare = getClickedSquare(worldObjects)
    best = scanNearbyCorpses(playerObj, clickedSquare, best)
    best = scanNearbyCorpses(playerObj, playerObj:getSquare(), best)
    return best and best.body or nil
end

local function pushVehicle(vehicle, out, seen)
    if not vehicle or seen[vehicle] then return end
    seen[vehicle] = true
    out[#out + 1] = vehicle
end

local function scanSquareForVehicle(square, out, seen)
    if square and square.getVehicleContainer then
        pushVehicle(square:getVehicleContainer(), out, seen)
    end
end

local function scanNearbyVehicles(square, out, seen)
    if not square or not getCell then return end
    local z = square:getZ()
    for x = square:getX() - SEARCH_RADIUS, square:getX() + SEARCH_RADIUS do
        for y = square:getY() - SEARCH_RADIUS, square:getY() + SEARCH_RADIUS do
            scanSquareForVehicle(getCell():getGridSquare(x, y, z), out, seen)
        end
    end
end

local function collectVehicles(playerObj, worldObjects, corpse)
    local vehicles = {}
    local seen = {}
    local clickedSquare = getClickedSquare(worldObjects)

    scanNearbyVehicles(clickedSquare, vehicles, seen)
    if corpse and corpse.getSquare then
        scanNearbyVehicles(corpse:getSquare(), vehicles, seen)
    end
    scanNearbyVehicles(playerObj:getSquare(), vehicles, seen)

    if worldObjects then
        for _, object in ipairs(worldObjects) do
            if object and instanceof(object, "BaseVehicle") then
                pushVehicle(object, vehicles, seen)
            elseif object and object.getSquare then
                scanSquareForVehicle(object:getSquare(), vehicles, seen)
            end
        end
    end

    if playerObj.getUseableVehicle then pushVehicle(playerObj:getUseableVehicle(), vehicles, seen) end
    if playerObj.getNearVehicle then pushVehicle(playerObj:getNearVehicle(), vehicles, seen) end

    return vehicles
end

local function cargoFromContainer(container)
    if not container or not container.getVehiclePart then return nil, nil, nil end
    local part = container:getVehiclePart()
    if not isCargoPart(part) then return nil, nil, nil end
    return part:getVehicle(), part, container
end

local function findCargoPart(vehicle)
    if not vehicle then return nil, nil end

    for _, partId in ipairs(TRUNK_PART_IDS) do
        local part = vehicle.getPartById and vehicle:getPartById(partId) or nil
        if isCargoPart(part) then
            return part, part:getItemContainer()
        end
    end

    if not vehicle.getPartCount then return nil, nil end
    for i = 0, vehicle:getPartCount() - 1 do
        local part = vehicle:getPartByIndex(i)
        if isCargoPart(part) then
            return part, part:getItemContainer()
        end
    end

    return nil, nil
end

local function collectSuitableDraggedContainers(playerObj, worldObjects, out, seen)
    if not (playerObj and playerObj.isDraggingCorpse and playerObj:isDraggingCorpse()) then return end

    local function addList(list)
        if not list then return end
        for i = 0, list:size() - 1 do
            local vehicle, part, container = cargoFromContainer(list:get(i))
            if vehicle and part and container and not seen[container] then
                seen[container] = true
                out[#out + 1] = { vehicle = vehicle, part = part, container = container }
            end
        end
    end

    if playerObj.getContextWorldSuitableContainersToDropCorpseInObjects then
        addList(playerObj:getContextWorldSuitableContainersToDropCorpseInObjects(worldObjects))
    end
    local clickedSquare = getClickedSquare(worldObjects)
    if clickedSquare and playerObj.getSuitableContainersToDropCorpseInSquare then
        addList(playerObj:getSuitableContainersToDropCorpseInSquare(clickedSquare))
    end
end

local function findTrunkTarget(playerObj, worldObjects, corpse)
    local targets = {}
    local seenContainers = {}
    collectSuitableDraggedContainers(playerObj, worldObjects, targets, seenContainers)
    if #targets > 0 then return targets[1] end

    local vehicles = collectVehicles(playerObj, worldObjects, corpse)
    for _, vehicle in ipairs(vehicles) do
        local part, container = findCargoPart(vehicle)
        if part and container then
            return { vehicle = vehicle, part = part, container = container }
        end
    end

    return nil
end

local function addTooltip(option, description)
    if not option or not description then return end
    local tooltip = ISToolTip:new()
    tooltip:initialise()
    tooltip:setVisible(false)
    tooltip.description = description
    option.toolTip = tooltip
end

local function vehicleClaimAllows(playerObj, vehicle)
    if CSR_VehicleClaim and CSR_VehicleClaim.isAllowed then
        return CSR_VehicleClaim.isAllowed(vehicle, playerObj) == true
    end
    return true
end

local function validateTarget(playerObj, corpse, target)
    if not target or not target.vehicle or not target.container then
        return false, "<RED>" .. tr("Tooltip_CSR_CorpseTrunk_NoTrunk", "No vehicle trunk nearby.")
    end
    if playerObj:getVehicle() then
        return false, "<RED>" .. tr("Tooltip_CSR_CorpseTrunk_ExitVehicle", "Exit the vehicle first.")
    end
    if not vehicleClaimAllows(playerObj, target.vehicle) then
        return false, "<RED>" .. tr("Tooltip_CSR_CorpseTrunk_NotAuthorized", "You are not authorized to use this vehicle.")
    end

    local container = target.container
    local doorNeedsOpening = container.doesVehicleDoorNeedOpening and container:doesVehicleDoorNeedOpening()
    if doorNeedsOpening and container.canCharacterUnlockVehicleDoor
            and not container:canCharacterUnlockVehicleDoor(playerObj) then
        return false, "<RED>" .. tr("Tooltip_CSR_CorpseTrunk_Locked", "The trunk is locked.")
    end

    if playerObj.canAccessContainer and not doorNeedsOpening
            and not playerObj:canAccessContainer(container) then
        return false, "<RED>" .. tr("Tooltip_CSR_CorpseTrunk_CannotAccess", "Cannot access this trunk.")
    end

    if corpse and corpse.getItem and container.canItemFit then
        local item = corpse:getItem()
        if item and not container:canItemFit(item) then
            return false, "<RED>" .. tr("Tooltip_CSR_CorpseTrunk_NoRoom", "Not enough room in the trunk.")
        end
    end

    return true, tr("Tooltip_CSR_CorpseTrunk_Ready", "Stores the corpse in the vehicle cargo container using the game's corpse item, so clothing and carried equipment stay with it.")
end

local function openContainerVehicleDoor(playerObj, container)
    if not container or not container.getVehicleSeatDoorPart then return false end
    local part = container:getVehicleSeatDoorPart()
    if not part then return false end
    ISVehicleMenu.onOpenDoor(playerObj, part)
    return true
end

local function closeContainerVehicleDoor(playerObj, container)
    if not container or not container.getVehicleSeatDoorPart then return false end
    local part = container:getVehicleSeatDoorPart()
    if not part then return false end
    ISVehicleMenu.onCloseDoor(playerObj, part)
    return true
end

local function queueDropIntoContainer(playerNum, playerObj, container)
    if not luautils.walkToContainer(container, playerNum) then return false end

    local doorNeedsOpening = container.doesVehicleDoorNeedOpening and container:doesVehicleDoorNeedOpening()
    if doorNeedsOpening then
        openContainerVehicleDoor(playerObj, container)
    end

    ISTimedActionQueue.add(ISDropCorpseIntoContainer:new(playerObj, container))

    if doorNeedsOpening then
        closeContainerVehicleDoor(playerObj, container)
    end

    return true
end

local function queueGrabCorpse(playerObj, corpse)
    if not corpse then return false end
    if playerObj:isSitOnGround() then
        playerObj:setVariable("forceGetUp", true)
    end
    ISTimedActionQueue.add(ISPathFindAction:pathToGrabCorpse(playerObj, corpse))
    if playerObj:getPrimaryHandItem() then
        ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getPrimaryHandItem(), 50))
    end
    if playerObj:getSecondaryHandItem() and playerObj:getSecondaryHandItem() ~= playerObj:getPrimaryHandItem() then
        ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getSecondaryHandItem(), 50))
    end
    ISTimedActionQueue.add(ISGrabCorpseAction:new(playerObj, corpse))
    return true
end

local function onPutCorpseInTrunk(playerNum, corpse, target)
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj or not target or not target.container then return end

    if not (playerObj.isDraggingCorpse and playerObj:isDraggingCorpse()) then
        if not queueGrabCorpse(playerObj, corpse) then return end
    end

    queueDropIntoContainer(playerNum, playerObj, target.container)
end

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    if test == true then return true end
    if not isEnabled() then return end

    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end

    local dragging = playerObj.isDraggingCorpse and playerObj:isDraggingCorpse()
    local corpse = dragging and nil or findCorpse(playerObj, worldObjects)
    if not dragging and not corpse then return end

    local target = findTrunkTarget(playerObj, worldObjects, corpse)
    if not target then return end

    local option = context:addOptionOnTop(tr("ContextMenu_CSR_PutCorpseInTrunk", "Put Corpse in Trunk"), playerNum, onPutCorpseInTrunk, corpse, target)
    local ok, tooltip = validateTarget(playerObj, corpse, target)
    if not ok then option.notAvailable = true end
    addTooltip(option, tooltip)
end

if Events and Events.OnFillWorldObjectContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
end

return CSR_CorpseTrunk
