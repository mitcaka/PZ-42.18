-- Client highlight pass for CSR power-line cord sprites.
require "CSR_PowerLine"
require "CSR_PowerLineSprites"

local SCAN_TICKS = 15
local SCAN_RADIUS = 24
local _tick = 0
local _highlighted = {}

local function keyForSquare(square)
    if not square then return nil end
    return tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())
end

local function clearHighlight(obj)
    if not obj then return end
    if obj.setHighlightColor then obj:setHighlightColor(0, 0, 0, 0) end
    if obj.setHighlighted then obj:setHighlighted(false) end
end

local function colorForSquare(square)
    local state = CSR_PowerLineSprites.stateForSquare(square)
    if state == "off" then
        return 1.00, 0.22, 0.16, 0.72
    end
    if state == "paint" then
        return 0.45, 0.74, 1.00, 0.55
    end
    return 0.20, 1.00, 0.35, 0.62
end

local function setHighlight(obj, square)
    if not obj or not square then return end
    local r, g, b, a = colorForSquare(square)
    if obj.setHighlightColor then obj:setHighlightColor(r, g, b, a) end
    if obj.setHighlighted then obj:setHighlighted(true, false) end
end

local function clearMissing(seen)
    for k, obj in pairs(_highlighted) do
        if not seen[k] then
            clearHighlight(obj)
            _highlighted[k] = nil
        end
    end
end

local function scanCordHighlights()
    if not CSR_PowerLineSprites.isEnabled() then
        clearMissing({})
        return
    end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local cell = getCell and getCell() or nil
    if not player or not cell then
        clearMissing({})
        return
    end

    local px = math.floor(tonumber(player:getX()) or 0)
    local py = math.floor(tonumber(player:getY()) or 0)
    local pz = math.floor(tonumber(player:getZ()) or 0)
    local seen = {}

    for x = px - SCAN_RADIUS, px + SCAN_RADIUS do
        for y = py - SCAN_RADIUS, py + SCAN_RADIUS do
            local square = cell:getGridSquare(x, y, pz)
            if square and CSR_PowerLineSprites.isVisualSquare(square) then
                if not (isClient and isClient()) and CSR_PowerLineSprites.syncSquare then
                    CSR_PowerLineSprites.syncSquare(square)
                end
                local obj = CSR_PowerLineSprites.findCordObject(square)
                if obj then
                    local k = keyForSquare(square)
                    if k then
                        seen[k] = true
                        _highlighted[k] = obj
                        setHighlight(obj, square)
                    end
                end
            end
        end
    end

    clearMissing(seen)
end

local function onTick()
    _tick = _tick + 1
    if _tick < SCAN_TICKS then return end
    _tick = 0
    scanCordHighlights()
end

if Events and Events.OnTick and not CSR_PowerLineSprites._clientHighlightHooked then
    CSR_PowerLineSprites._clientHighlightHooked = true
    Events.OnTick.Add(onTick)
end
