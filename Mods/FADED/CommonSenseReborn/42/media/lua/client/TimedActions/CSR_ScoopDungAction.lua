-- CSR_ScoopDungAction.lua
-- Bink's No Stinks: Pooper Scooper - radius dung scoop timed action.
-- Plays the vanilla Dig animation; on perform, sends a server command
-- (or runs locally in SP) that scans squares within a radius around the
-- player and removes every dropped Dung_* item, adding equivalent items
-- to the player's inventory. Tool wear is applied once per action.
require "TimedActions/ISBaseTimedAction"
require "CSR_FeatureFlags"
require "CSR_Utils"

CSR_ScoopDungAction = ISBaseTimedAction:derive("CSR_ScoopDungAction")

local DUNG_TYPES = {
    "Base.Dung_Chicken", "Base.Dung_Turkey", "Base.Dung_Cow", "Base.Dung_Deer",
    "Base.Dung_Mouse", "Base.Dung_Pig", "Base.Dung_Rabbit", "Base.Dung_Raccoon",
    "Base.Dung_Rat", "Base.Dung_Sheep",
}

local function isDungFullType(ft)
    if not ft then return false end
    for i = 1, #DUNG_TYPES do
        if DUNG_TYPES[i] == ft then return true end
    end
    -- Prefix fallback for any modded vanilla-style dung items
    if string.sub(ft, 1, 5) == "Base." then
        local rest = string.sub(ft, 6)
        if string.sub(rest, 1, 5) == "Dung_" then return true end
    end
    return false
end

CSR_ScoopDungAction.isDungFullType = isDungFullType
CSR_ScoopDungAction.DUNG_TYPES = DUNG_TYPES

-- Returns array of { square, fullType, itemId } for dung items within radius.
local function findDungInRadius(player, radius)
    local results = {}
    if not player or not player.getSquare then return results end
    local origin = player:getSquare()
    if not origin then return results end
    local cell = getWorld():getCell()
    if not cell then return results end
    local ox, oy, oz = origin:getX(), origin:getY(), origin:getZ()
    for dx = -radius, radius do
        for dy = -radius, radius do
            local sq = cell:getGridSquare(ox + dx, oy + dy, oz)
            if sq and sq.getWorldObjects then
                local list = sq:getWorldObjects()
                if list and list:size() > 0 then
                    for i = 0, list:size() - 1 do
                        local wo = list:get(i)
                        if wo and instanceof(wo, "IsoWorldInventoryObject") then
                            local it = wo.getItem and wo:getItem() or nil
                            if it and it.getFullType then
                                local ft = it:getFullType()
                                if isDungFullType(ft) then
                                    results[#results + 1] = {
                                        x = sq:getX(), y = sq:getY(), z = sq:getZ(),
                                        fullType = ft,
                                        itemId = it.getID and it:getID() or nil,
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return results
end

CSR_ScoopDungAction.findDungInRadius = findDungInRadius

local function performLocalSP(action)
    -- Single-player path: remove world items and add to inventory directly.
    local player = action.character
    if not player then return end
    local cell = getWorld():getCell()
    if not cell then return end
    local inv = player:getInventory()
    local count = 0
    for _, t in ipairs(action.targets or {}) do
        if count >= action.maxPerAction then break end
        local sq = cell:getGridSquare(t.x, t.y, t.z)
        if sq and sq.getWorldObjects then
            local list = sq:getWorldObjects()
            if list then
                for i = list:size() - 1, 0, -1 do
                    local wo = list:get(i)
                    if wo and instanceof(wo, "IsoWorldInventoryObject") then
                        local it = wo.getItem and wo:getItem() or nil
                        if it and it.getFullType and it:getFullType() == t.fullType then
                            -- For SP we can use direct add then remove world tile
                            if inv then inv:AddItem(t.fullType) end
                            sq:transmitRemoveItemFromSquare(wo)
                            count = count + 1
                            break
                        end
                    end
                end
            end
        end
    end
    if action.tool and action.tool.setCondition and action.tool.getCondition then
        action.tool:setCondition(math.max(0, action.tool:getCondition() - 1))
    end
end

function CSR_ScoopDungAction:new(character, tool, targets, radius, maxPerAction)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.tool = tool
    o.toolId = tool and tool.getID and tool:getID() or nil
    o.targets = targets or {}
    o.radius = radius or 3
    o.maxPerAction = maxPerAction or 30
    o.maxTime = 100 + math.min(#o.targets, o.maxPerAction) * 20
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = false
    return o
end

function CSR_ScoopDungAction:isValid()
    if not self.character or self.character:isDead() then return false end
    if not self.tool then return false end
    if self.tool.getCondition and self.tool:getCondition() <= 0 then return false end
    return self.targets and #self.targets > 0
end

function CSR_ScoopDungAction:update()
    self.character:setMetabolicTarget(Metabolics.MediumWork)
end

function CSR_ScoopDungAction:start()
    self:setActionAnim("Dig")
    self:setOverrideHandModels(nil, self.tool)
end

function CSR_ScoopDungAction:perform()
    if isClient() then
        sendClientCommand(self.character, "CommonSenseReborn", "BinksScoopDung", {
            toolId = self.toolId,
            targets = self.targets,
            maxPerAction = self.maxPerAction,
            requestId = CSR_Utils.makeRequestId(self.character, "BinksScoopDung"),
        })
    else
        performLocalSP(self)
    end
    ISBaseTimedAction.perform(self)
end

return CSR_ScoopDungAction
