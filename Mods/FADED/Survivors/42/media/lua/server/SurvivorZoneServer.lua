require "SurvivorZones"

if isClient() then return end

SurvivorZoneServer = SurvivorZoneServer or {}

local WALL_MAX_SEGMENTS = 260
local WALL_SPRITE_VERTICAL = "fencing_01_4"
local WALL_SPRITE_HORIZONTAL = "fencing_01_5"
local WALL_SPRITE_CORNER = "fencing_01_6"

local function getOrCreateSquare(x, y, z)
    local cell = getCell()
    local square = cell:getGridSquare(x, y, z)
    if not square and getWorld() and getWorld():isValidSquare(x, y, z) then
        square = cell:createNewGridSquare(x, y, z, true)
    end
    return square
end

function SurvivorZoneServer.ClearZombies(zone, margin)
    -- Survivor zones organize settlement NPCs; they must never delete world zombies.
    return 0
end

local function hasZoneWall(square, zoneId)
    if not square then return false end
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        local md = object and object.getModData and object:getModData() or nil
        if md and md.SurvivorZoneWall == zoneId then
            return true
        end
    end
    return false
end

local function canPlaceWall(square, zoneId)
    if not square then return false end
    if hasZoneWall(square, zoneId) then return false end
    if square.getBuilding and square:getBuilding() then return false end
    if square.isFree and not square:isFree(false) then return false end
    return true
end

local function placeWall(zone, sprite, x, y, z)
    local square = getOrCreateSquare(x, y, z)
    if not canPlaceWall(square, zone.id) then return false end

    local obj = IsoThumpable.new(getCell(), square, sprite, false, {})
    if not obj then return false end

    local md = obj:getModData()
    md.SurvivorZoneWall = zone.id
    md.SurvivorZoneWallBuilt = true

    square:AddTileObject(obj)
    if obj.transmitCompleteItemToClients then
        obj:transmitCompleteItemToClients()
    elseif obj.transmitCompleteItemToServer then
        obj:transmitCompleteItemToServer()
    end
    return true
end

function SurvivorZoneServer.BuildWalls(zone)
    if not zone then return false, "No survivor zone selected." end
    if zone.wallsBuilt then return false, "This survivor zone already has a wall ring." end

    local x1 = math.floor(tonumber(zone.x1) or tonumber(zone.x) or 0)
    local y1 = math.floor(tonumber(zone.y1) or tonumber(zone.y) or 0)
    local x2 = math.floor(tonumber(zone.x2) or x1)
    local y2 = math.floor(tonumber(zone.y2) or y1)
    local z = math.floor(tonumber(zone.z) or 0)
    if x2 < x1 then x1, x2 = x2, x1 end
    if y2 < y1 then y1, y2 = y2, y1 end

    local perimeter = ((x2 - x1) * 2) + ((y2 - y1) * 2)
    if perimeter > WALL_MAX_SEGMENTS then
        return false, "Zone perimeter is too large for automatic walls."
    end

    local gateX1 = math.floor(((x1 + x2) / 2) - 1)
    local gateX2 = gateX1 + 2
    local placed = 0

    for x = x1, x2 do
        if x < gateX1 or x > gateX2 then
            if placeWall(zone, WALL_SPRITE_HORIZONTAL, x, y1, z) then placed = placed + 1 end
            if placeWall(zone, WALL_SPRITE_HORIZONTAL, x, y2, z) then placed = placed + 1 end
        end
    end

    for y = y1, y2 do
        if placeWall(zone, WALL_SPRITE_VERTICAL, x1, y, z) then placed = placed + 1 end
        if placeWall(zone, WALL_SPRITE_VERTICAL, x2, y, z) then placed = placed + 1 end
    end

    if placeWall(zone, WALL_SPRITE_CORNER, x1, y1, z) then placed = placed + 1 end
    if placeWall(zone, WALL_SPRITE_CORNER, x2, y1, z) then placed = placed + 1 end
    if placeWall(zone, WALL_SPRITE_CORNER, x1, y2, z) then placed = placed + 1 end
    if placeWall(zone, WALL_SPRITE_CORNER, x2, y2, z) then placed = placed + 1 end

    if placed == 0 then
        return false, "No free perimeter tiles were found for walls."
    end

    zone.wallsBuilt = true
    zone.wallPlacedCount = placed
    SurvivorZones.Set(zone)
    SurvivorZones.Transmit()
    return true
end
