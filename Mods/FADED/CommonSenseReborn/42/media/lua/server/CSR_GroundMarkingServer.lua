-- CSR Ground Marking -- Server
-- Handles PlaceGroundMark and RemoveGroundMark client commands.

CSR_GroundMarkingServer = CSR_GroundMarkingServer or {}

local OBJECT_NAME = "CSRGroundMark"
local MAX_DIST    = 5

local SYMBOLS = {
    arrow_e   = { sprite="generalSymbolsNORMAL_0",  r=1.0,  g=0.95, b=0.85 },
    arrow_s   = { sprite="generalSymbolsNORMAL_1",  r=1.0,  g=0.95, b=0.85 },
    arrow_w   = { sprite="generalSymbolsNORMAL_2",  r=1.0,  g=0.95, b=0.85 },
    arrow_n   = { sprite="generalSymbolsNORMAL_3",  r=1.0,  g=0.95, b=0.85 },
    arrow_ne  = { sprite="generalSymbolsNORMAL_4",  r=1.0,  g=0.95, b=0.85 },
    arrow_sw  = { sprite="generalSymbolsNORMAL_5",  r=1.0,  g=0.95, b=0.85 },
    arrow_se  = { sprite="generalSymbolsNORMAL_6",  r=1.0,  g=0.95, b=0.85 },
    arrow_nw  = { sprite="generalSymbolsNORMAL_7",  r=1.0,  g=0.95, b=0.85 },
    looted    = { sprite="generalSymbolsNORMAL_16", r=1.0,  g=0.55, b=0.1  },
    safe      = { sprite="generalSymbolsNORMAL_16", r=0.25, g=0.85, b=0.3  },
    safehouse = { sprite="generalSymbolsNORMAL_20", r=0.25, g=0.55, b=1.0  },
    hordes    = { sprite="generalSymbolsNORMAL_24", r=0.9,  g=0.1,  b=0.1  },
}

local function setSpriteProp(props, name, value)
    if not props then return end
    if props.set then
        props:set(name, value or "", true)
    elseif props.Set then
        props:Set(name, value or "", true)
    end
end

local function applyGroundOverlayProps(props)
    setSpriteProp(props, "FloorOverlay", "true")
    setSpriteProp(props, "IsFloorAttached", "true")
    setSpriteProp(props, "attachedFloor", "true")
end

local function recalcSquare(square)
    if not square then return end
    if square.RecalcProperties then square:RecalcProperties() end
    if square.RecalcAllWithNeighbours then square:RecalcAllWithNeighbours(true) end
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
        if sprite.getProperties then applyGroundOverlayProps(sprite:getProperties()) end
    end
    return sprite
end

local function applyTint(obj, r, g, b)
    if not obj or not obj.getSprite or not ColorInfo then return end
    local sprite = obj:getSprite()
    if sprite and sprite.setTintMod then
        sprite:setTintMod(ColorInfo.new(r or 1.0, g or 1.0, b or 1.0, 1.0))
    end
end

local function isNear(player, x, y, z)
    if not player then return false end
    if player:getZ() ~= z then return false end
    return math.abs(player:getX() - x) <= MAX_DIST and math.abs(player:getY() - y) <= MAX_DIST
end

local function getSquare(x, y, z)
    local cell = getCell and getCell() or nil
    if not cell and getWorld then
        local world = getWorld()
        cell = world and world:getCell() or nil
    end
    return cell and cell:getGridSquare(x, y, z) or nil
end

local function isGroundMark(obj)
    if not obj then return false end
    local md = obj.getModData and obj:getModData() or nil
    if md and md.CSRGroundMark then return true end
    return obj.getName and obj:getName() == OBJECT_NAME
end

local function findMark(square)
    if not square then return nil end
    local objs = square:getObjects()
    if not objs then return nil end
    for i = 0, objs:size() - 1 do
        local obj = objs:get(i)
        if isGroundMark(obj) then return obj end
    end
    return nil
end

local function removeMarkObject(square, obj)
    if not square or not obj then return end
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

local function hasRemoveAccess(player, mark)
    if not player or not mark then return false end
    local md = mark:getModData() or {}
    if md.placedBy == player:getUsername() then return true end

    local level = tostring(player.getAccessLevel and player:getAccessLevel() or ""):lower()
    return level == "admin" or level == "moderator" or level == "gm" or level == "overseer"
end

function CSR_GroundMarkingServer.handlePlace(player, args)
    if not args or args.x == nil or args.y == nil or args.z == nil then return end

    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    if sb.EnableGroundMarking == false then return end

    local def = args.symbolId and SYMBOLS[args.symbolId] or nil
    if not def then return end

    local x, y, z = args.x, args.y, args.z
    if not isNear(player, x, y, z) then return end

    local square = getSquare(x, y, z)
    if not square then return end
    if findMark(square) then return end

    local spriteObj = ensureSprite(def.sprite)
    local obj = IsoObject.new(square, def.sprite, OBJECT_NAME, false)
    if not obj then return end

    if spriteObj and obj.setSprite then
        obj:setSprite(spriteObj)
    elseif obj.setSpriteFromName then
        obj:setSpriteFromName(def.sprite)
    end
    if obj.setName then obj:setName(OBJECT_NAME) end
    if obj.getProperties then applyGroundOverlayProps(obj:getProperties()) end

    local md         = obj:getModData()
    md.CSRGroundMark = true
    md.symbolId      = args.symbolId
    md.sprite        = def.sprite
    md.r             = def.r
    md.g             = def.g
    md.b             = def.b
    md.degradable    = (args.degradable == true)
    md.lastRainCheck = getGameTime():getWorldAgeHours()
    md.placedBy      = args.placedBy or player:getUsername()

    applyTint(obj, md.r, md.g, md.b)

    square:AddTileObject(obj)
    recalcSquare(square)

    if isServer and isServer() then
        if obj.transmitCompleteItemToClients then obj:transmitCompleteItemToClients() end
        if obj.transmitModData then obj:transmitModData() end
    end
end

function CSR_GroundMarkingServer.handleRemove(player, args)
    if not args or args.x == nil or args.y == nil or args.z == nil then return end

    local x, y, z = args.x, args.y, args.z
    if not isNear(player, x, y, z) then return end

    local square = getSquare(x, y, z)
    if not square then return end

    local obj = findMark(square)
    if not obj or not hasRemoveAccess(player, obj) then return end

    removeMarkObject(square, obj)
end

local function removeLoadedCrayonMarks()
    if isClient and isClient() then return end
    local cell = getCell and getCell() or nil
    if not cell then return end

    local objects = (cell.getObjectListForLua and cell:getObjectListForLua()) or (cell.getObjectList and cell:getObjectList()) or nil
    if not objects then return end

    for i = objects:size() - 1, 0, -1 do
        local obj = objects:get(i)
        if isGroundMark(obj) then
            local md = obj:getModData() or {}
            if md.degradable then
                local square = obj.getSquare and obj:getSquare() or nil
                removeMarkObject(square, obj)
            end
        end
    end
end

if Events and Events.OnRainStart and not CSR_GroundMarkingServer._rainHooked then
    CSR_GroundMarkingServer._rainHooked = true
    Events.OnRainStart.Add(removeLoadedCrayonMarks)
end

return CSR_GroundMarkingServer
