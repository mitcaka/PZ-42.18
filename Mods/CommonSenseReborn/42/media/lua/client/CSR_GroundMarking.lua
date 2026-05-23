-- CSR Ground Marking
-- Right-click any square to spray directional arrows or survival symbols on the floor.
-- SprayPaint marks are permanent. Crayons marks degrade on rain.

require "CSR_AA_InteropGuard"

local MODULE      = "CommonSenseReborn"
local CMD_PLACE   = "PlaceGroundMark"
local CMD_REMOVE  = "RemoveGroundMark"
local OBJECT_NAME = "CSRGroundMark"

-- Sprite names from the csr_groundmarking pack (generalSymbolsNORMAL tileset).
-- Arrow indices: E=0, S=1, W=2, N=3, NE=4, SW=5, SE=6, NW=7
-- Survival indices: Looted/check=16, Safehouse=20, Hordes=24
local SYMBOLS = {
    { id="arrow_e",   label=getText("ContextMenu_CSR_MarkEast"),      sprite="generalSymbolsNORMAL_0",  r=1.0,  g=0.95, b=0.85 },
    { id="arrow_s",   label=getText("ContextMenu_CSR_MarkSouth"),     sprite="generalSymbolsNORMAL_1",  r=1.0,  g=0.95, b=0.85 },
    { id="arrow_w",   label=getText("ContextMenu_CSR_MarkWest"),      sprite="generalSymbolsNORMAL_2",  r=1.0,  g=0.95, b=0.85 },
    { id="arrow_n",   label=getText("ContextMenu_CSR_MarkNorth"),     sprite="generalSymbolsNORMAL_3",  r=1.0,  g=0.95, b=0.85 },
    { id="arrow_ne",  label=getText("ContextMenu_CSR_MarkNortheast"), sprite="generalSymbolsNORMAL_4",  r=1.0,  g=0.95, b=0.85 },
    { id="arrow_sw",  label=getText("ContextMenu_CSR_MarkSouthwest"), sprite="generalSymbolsNORMAL_5",  r=1.0,  g=0.95, b=0.85 },
    { id="arrow_se",  label=getText("ContextMenu_CSR_MarkSoutheast"), sprite="generalSymbolsNORMAL_6",  r=1.0,  g=0.95, b=0.85 },
    { id="arrow_nw",  label=getText("ContextMenu_CSR_MarkNorthwest"), sprite="generalSymbolsNORMAL_7",  r=1.0,  g=0.95, b=0.85 },
    { id="looted",    label=getText("ContextMenu_CSR_MarkLooted"),    sprite="generalSymbolsNORMAL_16", r=1.0,  g=0.55, b=0.1  },
    { id="safe",      label=getText("ContextMenu_CSR_MarkSafe"),      sprite="generalSymbolsNORMAL_16", r=0.25, g=0.85, b=0.3  },
    { id="safehouse", label=getText("ContextMenu_CSR_MarkSafehouse"), sprite="generalSymbolsNORMAL_20", r=0.25, g=0.55, b=1.0  },
    { id="hordes",    label=getText("ContextMenu_CSR_MarkHordes"),    sprite="generalSymbolsNORMAL_24", r=0.9,  g=0.1,  b=0.1  },
}

local SYMBOL_BY_ID = {}
for _, sym in ipairs(SYMBOLS) do
    SYMBOL_BY_ID[sym.id] = sym
end

local reapplyTicks = 0

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

local function isGroundMark(obj)
    if not obj then return false end
    local md = obj.getModData and obj:getModData() or nil
    if md and md.CSRGroundMark then return true end
    return obj.getName and obj:getName() == OBJECT_NAME
end

local function restoreMarkObject(obj)
    if not isGroundMark(obj) then return false end

    local md = obj.getModData and obj:getModData() or {}
    local def = md.symbolId and SYMBOL_BY_ID[md.symbolId] or nil
    local spriteName = md.sprite or (def and def.sprite)

    if spriteName then
        local sprite = ensureSprite(spriteName)
        if sprite and obj.setSprite then
            obj:setSprite(sprite)
        elseif obj.setSpriteFromName then
            obj:setSpriteFromName(spriteName)
        end
    end

    if obj.setName then obj:setName(OBJECT_NAME) end
    if obj.getProperties then applyGroundOverlayProps(obj:getProperties()) end
    applyTint(obj, md.r or (def and def.r) or 1.0, md.g or (def and def.g) or 1.0, md.b or (def and def.b) or 1.0)

    local square = obj.getSquare and obj:getSquare() or nil
    recalcSquare(square)
    return true
end

local function scheduleReapply(ticks)
    reapplyTicks = math.max(reapplyTicks, ticks or 120)
end

local function preloadSprites()
    for _, sym in ipairs(SYMBOLS) do
        ensureSprite(sym.sprite)
    end
    scheduleReapply(300)
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

local function findMarkingItem(player)
    if not player then return nil, false end
    local inv = player:getInventory()
    if not inv then return nil, false end

    local spray = inv:getFirstTypeRecurse("SprayPaint")
    if spray then
        local uses = nil
        if spray.getCurrentUsesFloat then
            uses = spray:getCurrentUsesFloat()
        elseif spray.getDelta then
            uses = spray:getDelta()
        end
        if uses == nil or uses > 0 then return spray, false end
    end

    local crayons = inv:getFirstTypeRecurse("Crayons")
    if crayons then
        local md = crayons:getModData()
        if md.CSRMarkUses == nil or md.CSRMarkUses > 0 then
            return crayons, true
        end
    end
    return nil, false
end

local function getTargetSquare(worldObjects, player)
    if worldObjects then
        for i = 1, #worldObjects do
            local o = worldObjects[i]
            if o and o.getSquare then
                local sq = o:getSquare()
                if sq then return sq end
            end
        end
    end
    return player and player:getCurrentSquare() or nil
end

local function sendOrRunPlace(player, args)
    if isClient and isClient() then
        sendClientCommand(player, MODULE, CMD_PLACE, args)
        return
    end
    if CSR_GroundMarkingServer and CSR_GroundMarkingServer.handlePlace then
        CSR_GroundMarkingServer.handlePlace(player, args)
    end
end

local function sendOrRunRemove(player, args)
    if isClient and isClient() then
        sendClientCommand(player, MODULE, CMD_REMOVE, args)
        return
    end
    if CSR_GroundMarkingServer and CSR_GroundMarkingServer.handleRemove then
        CSR_GroundMarkingServer.handleRemove(player, args)
    end
end

CSR_GroundMarkAction = ISBaseTimedAction:derive("CSR_GroundMarkAction")

function CSR_GroundMarkAction:new(player, item, square, sym, degradable)
    local o = ISBaseTimedAction.new(self, player)
    o.player     = player
    o.item       = item
    o.square     = square
    o.sym        = sym
    o.degradable = degradable
    o.maxTime    = 15
    return o
end

function CSR_GroundMarkAction:isValid()
    if not self.player or not self.item or not self.square or not self.sym then return false end
    return findMark(self.square) == nil
end

function CSR_GroundMarkAction:start()
    local sq = self.square
    if sq and self.character and self.character.faceLocation then
        self.character:faceLocation(sq:getX(), sq:getY())
    end
end

function CSR_GroundMarkAction:perform()
    local sq   = self.square
    local item = self.item

    if item:getType() == "SprayPaint" then
        if item.Use then item:Use() end
    else
        -- Crayons are normal items, so CSR tracks mark uses manually.
        local md   = item:getModData()
        local uses = (md.CSRMarkUses ~= nil) and md.CSRMarkUses or 20
        uses = uses - 1
        if uses <= 0 then
            self.player:getInventory():Remove(item)
        else
            md.CSRMarkUses = uses
        end
    end

    sendOrRunPlace(self.player, {
        x          = sq:getX(),
        y          = sq:getY(),
        z          = sq:getZ(),
        symbolId   = self.sym.id,
        degradable = self.degradable,
        placedBy   = self.player:getUsername(),
    })

    scheduleReapply(120)
    ISBaseTimedAction.perform(self)
end

local function onWorldContextMenu(playerNum, context, worldObjects, test)
    if test then return end
    if CSR_AA_InteropGuard and CSR_AA_InteropGuard.isInForeignInteriorCell
            and CSR_AA_InteropGuard.isInForeignInteriorCell(playerNum) then
        return
    end
    if not CSR_FeatureFlags or not CSR_FeatureFlags.isGroundMarkingEnabled or not CSR_FeatureFlags.isGroundMarkingEnabled() then return end
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    local sq = getTargetSquare(worldObjects, player)
    if not sq then return end

    local existingMark = findMark(sq)
    if existingMark then
        restoreMarkObject(existingMark)
        local md      = existingMark:getModData() or {}
        local isOwner = (md.placedBy == player:getUsername())
        local lvl     = tostring(player:getAccessLevel() or ""):lower()
        local isAdmin = (lvl == "admin" or lvl == "moderator" or lvl == "gm" or lvl == "overseer")
        if isOwner or isAdmin then
            context:addOption(getText("ContextMenu_CSR_RemoveGroundMark") or "Remove Ground Mark", worldObjects, function()
                sendOrRunRemove(player, {
                    x = sq:getX(),
                    y = sq:getY(),
                    z = sq:getZ(),
                })
                scheduleReapply(60)
            end)
        end
        return
    end

    local item, degradable = findMarkingItem(player)
    if not item then return end

    local rootOpt = context:addOption(getText("ContextMenu_CSR_MarkGround") or "Mark Ground", worldObjects, nil)
    local sub     = context:getNew(context)
    context:addSubMenu(rootOpt, sub)

    local arrowOpt = sub:addOption(getText("ContextMenu_CSR_MarkArrows"), worldObjects, nil)
    local arrowSub = sub:getNew(sub)
    sub:addSubMenu(arrowOpt, arrowSub)

    local survOpt = sub:addOption(getText("ContextMenu_CSR_SurvivalMarkers") or "Survival Markers", worldObjects, nil)
    local survSub = sub:getNew(sub)
    sub:addSubMenu(survOpt, survSub)

    for _, sym in ipairs(SYMBOLS) do
        local dest = (sym.id:sub(1, 5) == "arrow") and arrowSub or survSub
        local s, d = sym, degradable
        dest:addOption(sym.label, worldObjects, function()
            if luautils and luautils.walkAdj then
                luautils.walkAdj(player, sq)
            end
            ISTimedActionQueue.add(CSR_GroundMarkAction:new(player, item, sq, s, d))
        end)
    end
end

local function onObjectAdded(arg1, arg2)
    restoreMarkObject(arg2 or arg1)
end

local function onLoadGridSquare(square)
    if not square then return end
    local objs = square:getObjects()
    if not objs then return end
    for i = 0, objs:size() - 1 do
        restoreMarkObject(objs:get(i))
    end
end

local function onTick()
    if reapplyTicks <= 0 then return end
    reapplyTicks = reapplyTicks - 1

    local player = getSpecificPlayer(0)
    local playerSquare = player and player:getSquare() or nil
    if not playerSquare or not getCell then return end

    local cell = getCell()
    local z = playerSquare:getZ()
    local radius = 8
    for x = playerSquare:getX() - radius, playerSquare:getX() + radius do
        for y = playerSquare:getY() - radius, playerSquare:getY() + radius do
            local square = cell:getGridSquare(x, y, z)
            if square then
                onLoadGridSquare(square)
            end
        end
    end
end

if Events and Events.OnFillWorldObjectContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(onWorldContextMenu)
end
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(preloadSprites)
end
if Events and Events.OnObjectAdded then
    Events.OnObjectAdded.Add(onObjectAdded)
end
if Events and Events.LoadGridsquare then
    Events.LoadGridsquare.Add(onLoadGridSquare)
elseif Events and Events.OnLoadGridSquare then
    Events.OnLoadGridSquare.Add(onLoadGridSquare)
end
if Events and Events.OnTick then
    Events.OnTick.Add(onTick)
end
