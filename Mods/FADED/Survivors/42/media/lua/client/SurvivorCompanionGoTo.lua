require "BuildingObjects/ISBuildingObject"
require "BuildingObjects/ZSSurvivorGoTo"

SurvivorCompanionGoTo = SurvivorCompanionGoTo or {}

function SurvivorCompanionGoTo.Start(player, bandit, group)
    if not player or not ZSSurvivorGoTo then return end
    local cursor = ZSSurvivorGoTo:new(player, bandit, group)
    getCell():setDrag(cursor, player:getPlayerNum())
end

return SurvivorCompanionGoTo
