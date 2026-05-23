-- CSR Power Line world-sprite visuals.
-- Keeps CSR_PowerLine square ModData as the save-compatible source of truth.
require "CSR_PowerLine"

CSR_PowerLineSprites = CSR_PowerLineSprites or {}

local M = CSR_PowerLineSprites

M.OBJECT_NAME = "CSRPowerLineCord"
M.OBJECT_KEY = "CSRPowerLineVisual"
M.SPRITE_PREFIX = "PowerNodesTiles_Cords_"
M.BLUE_BASE = 192

local function isClientOnly()
    return isClient and isClient() and not (isServer and isServer())
end

local function canMutateWorld()
    return not isClientOnly()
end

local function setSpriteProp(props, name, value)
    if not props then return end
    if props.set then
        props:set(name, value or "", true)
    elseif props.Set then
        props:Set(name, value or "", true)
    end
end

local function applyCordProps(props)
    setSpriteProp(props, "FloorOverlay", "true")
    setSpriteProp(props, "IsFloorAttached", "true")
    setSpriteProp(props, "attachedFloor", "true")
end

local function ensureSprite(spriteName)
    if not spriteName or spriteName == "" then return nil end

    local sprite = nil
    if getSprite then
        sprite = getSprite(spriteName)
    end
    if not sprite and IsoSpriteManager and IsoSpriteManager.instance then
        sprite = IsoSpriteManager.instance:getSprite(spriteName)
        if not sprite then
            sprite = IsoSpriteManager.instance:AddSprite(spriteName)
        end
    end

    if sprite then
        if sprite.setName then sprite:setName(spriteName) end
        if sprite.getProperties then applyCordProps(sprite:getProperties()) end
    end
    return sprite
end

local function recalcSquare(square)
    if not square then return end
    if square.RecalcProperties then square:RecalcProperties() end
    if square.RecalcAllWithNeighbours then square:RecalcAllWithNeighbours(true) end
end

local function objectTextureName(obj)
    if not obj then return nil end
    if obj.getTextureName then
        local ok, tex = pcall(function() return obj:getTextureName() end)
        if ok and tex and tex ~= "" then return tex end
    end
    if obj.getSprite then
        local sprite = obj:getSprite()
        if sprite and sprite.getName then
            local ok, name = pcall(function() return sprite:getName() end)
            if ok then return name end
        end
    end
    return nil
end

local function transmitObject(obj)
    if not obj then return end
    if isServer and isServer() then
        if obj.transmitUpdatedSpriteToClients then obj:transmitUpdatedSpriteToClients() end
        if obj.transmitCompleteItemToClients then obj:transmitCompleteItemToClients() end
        if obj.transmitModData then obj:transmitModData() end
    end
end

function M.isEnabled()
    return CSR_PowerLine and CSR_PowerLine.isEnabled and CSR_PowerLine.isEnabled()
end

function M.isVisualSquare(square)
    if not square then return false end
    if CSR_PowerLine.isWiringTile and CSR_PowerLine.isWiringTile(square) then return true end
    if CSR_PowerLine.isPaintedTrail and CSR_PowerLine.isPaintedTrail(square) then return true end
    return false
end

function M.stateForSquare(square)
    if not square then return nil end
    if CSR_PowerLine.isPaintedTrail and CSR_PowerLine.isPaintedTrail(square) then
        return "paint"
    end
    if CSR_PowerLine.isWiringTile and CSR_PowerLine.isWiringTile(square) then
        if CSR_PowerLine.isDisabled and CSR_PowerLine.isDisabled(square) then
            return "off"
        end
        return "power"
    end
    return nil
end

function M.isCordObject(obj)
    if not obj then return false end
    local md = obj.getModData and obj:getModData() or nil
    if md and md[M.OBJECT_KEY] == true then return true end
    return obj.getName and obj:getName() == M.OBJECT_NAME
end

function M.findCordObject(square)
    if not square or not square.getObjects then return nil end
    local objects = square:getObjects()
    if not objects then return nil end
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if M.isCordObject(obj) then return obj end
    end
    return nil
end

local function removeCordObject(square, obj)
    if not square or not obj or not canMutateWorld() then return end
    if isServer and isServer() and square.transmitRemoveItemFromSquare then
        square:transmitRemoveItemFromSquare(obj)
    end
    if square.RemoveTileObject then
        square:RemoveTileObject(obj)
    elseif obj.removeFromSquare then
        obj:removeFromSquare()
    end
    if obj.removeFromWorld then obj:removeFromWorld() end
    recalcSquare(square)
end

local function linked(square, dx, dy)
    if not square then return false end
    local cell = getCell and getCell() or nil
    if not cell and getWorld then
        local world = getWorld()
        cell = world and world:getCell() or nil
    end
    if not cell then return false end
    local nb = cell:getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
    return M.isVisualSquare(nb)
end

local function offsetForLinks(square)
    local n = linked(square, 0, -1)
    local s = linked(square, 0, 1)
    local e = linked(square, 1, 0)
    local w = linked(square, -1, 0)

    if n and s and e and w then return 9 end
    if n and s and e then return 10 end
    if n and s and w then return 7 end
    if n and e and w then return 8 end
    if s and e and w then return 6 end
    if (s or n) and not w and not e then return 3 end
    if (w or e) and not n and not s then return 0 end
    if n and w and not e and not s then return 1 end
    if n and e and not s and not w then return 5 end
    if s and w and not n and not e then return 2 end
    if s and e and not n and not w then return 4 end

    local nw = linked(square, -1, -1)
    local ne = linked(square, 1, -1)
    local sw = linked(square, -1, 1)
    local se = linked(square, 1, 1)
    local diagonals = (nw and 1 or 0) + (ne and 1 or 0) + (sw and 1 or 0) + (se and 1 or 0)
    if diagonals > 1 then return 9 end
    if nw then return 1 end
    if ne then return 5 end
    if sw then return 2 end
    if se then return 4 end

    return 0
end

function M.spriteNameForSquare(square)
    if not M.isVisualSquare(square) then return nil end
    return M.SPRITE_PREFIX .. tostring(M.BLUE_BASE + offsetForLinks(square))
end

function M.syncSquare(square)
    if not square then return nil end
    local obj = M.findCordObject(square)
    if not M.isVisualSquare(square) then
        removeCordObject(square, obj)
        return nil
    end
    if not canMutateWorld() then return obj end

    local spriteName = M.spriteNameForSquare(square)
    if not spriteName then
        removeCordObject(square, obj)
        return nil
    end

    local changed = false
    local spriteObj = ensureSprite(spriteName)
    if not obj then
        if not IsoObject then return nil end
        obj = IsoObject.new(square, spriteName, M.OBJECT_NAME, false)
        if not obj then return nil end
        if spriteObj and obj.setSprite then
            obj:setSprite(spriteObj)
        elseif obj.setSpriteFromName then
            obj:setSpriteFromName(spriteName)
        end
        if obj.setName then obj:setName(M.OBJECT_NAME) end
        if obj.getProperties then applyCordProps(obj:getProperties()) end
        square:AddTileObject(obj)
        changed = true
    elseif objectTextureName(obj) ~= spriteName then
        if spriteObj and obj.setSprite then
            obj:setSprite(spriteObj)
        elseif obj.setSpriteFromName then
            obj:setSpriteFromName(spriteName)
        end
        changed = true
    end

    if obj.setName then obj:setName(M.OBJECT_NAME) end
    if obj.getProperties then applyCordProps(obj:getProperties()) end
    local md = obj.getModData and obj:getModData() or nil
    if md then
        local state = M.stateForSquare(square)
        if md[M.OBJECT_KEY] ~= true or md.sprite ~= spriteName or md.state ~= state then
            changed = true
        end
        md[M.OBJECT_KEY] = true
        md.sprite = spriteName
        md.state = state
    end

    if changed then
        recalcSquare(square)
        transmitObject(obj)
    end
    return obj
end

function M.syncAround(square)
    if not square or not M.isEnabled() then return end
    local cell = getCell and getCell() or nil
    if not cell and getWorld then
        local world = getWorld()
        cell = world and world:getCell() or nil
    end
    if not cell then return end

    for dx = -1, 1 do
        for dy = -1, 1 do
            local sq = cell:getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
            if sq then M.syncSquare(sq) end
        end
    end
end

local function onLoadGridSquare(square)
    if not square or not M.isEnabled() then return end
    if not canMutateWorld() then return end
    if M.isVisualSquare(square) or M.findCordObject(square) then
        M.syncAround(square)
    end
end

local loadSquareEvent = Events and (Events.LoadGridsquare or Events.OnLoadGridsquare or Events.OnLoadGridSquare) or nil
if loadSquareEvent and not M._loadHooked then
    M._loadHooked = true
    loadSquareEvent.Add(onLoadGridSquare)
end

return M
