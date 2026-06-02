if isServer() then return end

require "BCR_Utils"
require "BCR_DisplaySettings"

BCR_ContainerSearch = BCR_ContainerSearch or {}

local NEARBY_RADIUS = 2
local EXPANDED_RADIUS = 8
local MAX_SCAN_CONTAINERS = 64

local function newContainerList()
    if ArrayList and ArrayList.new then
        return ArrayList.new()
    end
    return {}
end

local function addToList(list, value)
    if list and list.add then
        list:add(value)
    else
        table.insert(list, value)
    end
end

local function listCount(list)
    if not list then return 0 end
    if list.size then return list:size() end
    return #list
end

local function addContainer(list, seen, container, player)
    if not container or seen[container] then return end

    local parent = container.getParent and container:getParent() or nil
    if parent and parent.isLockedToCharacter and parent:isLockedToCharacter(player) then
        return
    end

    seen[container] = true
    addToList(list, container)
end

local function addInventoryContainers(list, seen, player)
    if not player then return end
    if player.getInventory then
        addContainer(list, seen, player:getInventory(), player)
    end

    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.getContainers then
        local vanillaContainers = ISInventoryPaneContextMenu.getContainers(player)
        for i = 0, BCR_Utils.listSize(vanillaContainers) - 1 do
            addContainer(list, seen, BCR_Utils.listGet(vanillaContainers, i), player)
        end
    end
end

local function addObjectContainers(list, seen, object, player)
    if not object then return end
    if object.getContainer then
        addContainer(list, seen, object:getContainer(), player)
    end
    if object.getContainerCount and object.getContainerByIndex then
        for i = 0, object:getContainerCount() - 1 do
            addContainer(list, seen, object:getContainerByIndex(i), player)
        end
    end
end

local function addWorldItemContainer(list, seen, worldObject, player)
    local item = worldObject and worldObject.getItem and worldObject:getItem() or nil
    if item and item.getItemContainer then
        addContainer(list, seen, item:getItemContainer(), player)
    end
end

local function sameSearchRoom(square, playerRoom)
    if not square then return false end
    if not playerRoom then return true end
    return square.getRoom and square:getRoom() == playerRoom
end

local function scanSquare(list, seen, square, player)
    if not square then return end

    local objects = square.getObjects and square:getObjects() or nil
    for i = 0, BCR_Utils.listSize(objects) - 1 do
        addObjectContainers(list, seen, BCR_Utils.listGet(objects, i), player)
        if listCount(list) >= MAX_SCAN_CONTAINERS then return end
    end

    local worldObjects = square.getWorldObjects and square:getWorldObjects() or nil
    for i = 0, BCR_Utils.listSize(worldObjects) - 1 do
        addWorldItemContainer(list, seen, BCR_Utils.listGet(worldObjects, i), player)
        if listCount(list) >= MAX_SCAN_CONTAINERS then return end
    end
end

function BCR_ContainerSearch.radius()
    if BCR_DisplaySettings and BCR_DisplaySettings.get and BCR_DisplaySettings.get("ExpandedNearbyScan") then
        return EXPANDED_RADIUS
    end
    return NEARBY_RADIUS
end

local function collectContainers(player, includeArea)
    local list = newContainerList()
    local seen = {}
    addInventoryContainers(list, seen, player)

    if includeArea ~= true then
        return list
    end

    local currentSquare = player and player.getCurrentSquare and player:getCurrentSquare() or nil
    local cell = getCell and getCell() or nil
    if not currentSquare or not cell then
        return list
    end

    local radius = BCR_ContainerSearch.radius()
    local z = currentSquare:getZ()
    local playerRoom = currentSquare.getRoom and currentSquare:getRoom() or nil
    for x = currentSquare:getX() - radius, currentSquare:getX() + radius do
        for y = currentSquare:getY() - radius, currentSquare:getY() + radius do
            local square = cell:getGridSquare(x, y, z)
            if sameSearchRoom(square, playerRoom) then
                scanSquare(list, seen, square, player)
                if listCount(list) >= MAX_SCAN_CONTAINERS then
                    return list
                end
            end
        end
    end

    return list
end

function BCR_ContainerSearch.getVisibleContainers(player)
    return collectContainers(player, false)
end

function BCR_ContainerSearch.scanAreaContainers(player)
    return collectContainers(player, true)
end

function BCR_ContainerSearch.getContainers(player, includeArea)
    return collectContainers(player, includeArea == true)
end

function BCR_ContainerSearch.count(list)
    return listCount(list)
end

return BCR_ContainerSearch
