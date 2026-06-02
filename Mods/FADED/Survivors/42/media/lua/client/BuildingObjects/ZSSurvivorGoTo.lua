if isServer() then return end
if not ISBuildingObject then return end

ZSSurvivorGoTo = ZSSurvivorGoTo or ISBuildingObject:derive("ZSSurvivorGoTo")

function ZSSurvivorGoTo:create(x, y, z, north, sprite)
    if not self.character then return end
    if self.group then
        BanditMenu.SendGroupOrder(self.character, self.group, "goto", x, y, z)
    elseif self.bandit then
        BanditMenu.SendCompanionOrder(self.character, self.bandit, "goto", x, y, z)
    end
end

function ZSSurvivorGoTo:walkTo(x, y, z)
    return true
end

function ZSSurvivorGoTo:isValid(square)
    return square and square:TreatAsSolidFloor() and square:isFree(false)
end

function ZSSurvivorGoTo:render(x, y, z, square)
    if not ZSSurvivorGoTo.floorSprite then
        ZSSurvivorGoTo.floorSprite = IsoSprite.new()
        ZSSurvivorGoTo.floorSprite:LoadFramesNoDirPageSimple("media/ui/FloorTileCursor.png")
    end

    if self:isValid(square) then
        ZSSurvivorGoTo.floorSprite:RenderGhostTileColor(x, y, z, 0.25, 0.72, 1, 0.9)
    else
        ZSSurvivorGoTo.floorSprite:RenderGhostTileColor(x, y, z, 1, 0.2, 0.2, 0.9)
    end
end

function ZSSurvivorGoTo:new(character, bandit, group)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o:init()
    o:setSprite("")
    o:setNorthSprite("")
    o.character = character
    o.player = character:getPlayerNum()
    o.bandit = bandit
    o.group = group
    o.noNeedHammer = true
    o.skipBuildAction = true
    return o
end

return ZSSurvivorGoTo
