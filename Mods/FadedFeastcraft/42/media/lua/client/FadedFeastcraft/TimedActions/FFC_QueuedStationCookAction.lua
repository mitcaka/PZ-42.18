require "TimedActions/ISBaseTimedAction"
require "FadedFeastcraft/FFC_Net"

FadedFeastcraft = FadedFeastcraft or {}

FFC_QueuedStationCookAction = ISBaseTimedAction:derive("FFC_QueuedStationCookAction")

local function parseStationKey(key)
    local x, y, z = string.match(tostring(key or ""), "^(%-?%d+):(%-?%d+):(%-?%d+):%d+$")
    if not x then return nil end
    return tonumber(x), tonumber(y), tonumber(z)
end

function FFC_QueuedStationCookAction:isValid()
    return self.character ~= nil
        and (not self.character.isDead or not self.character:isDead())
        and self.context ~= nil
        and self.context.recipeId == "ffc_hot_meal"
        and type(self.context.itemIds) == "table"
        and #self.context.itemIds > 0
end

function FFC_QueuedStationCookAction:waitToStart()
    if self.stationX and self.stationY and self.character and self.character.faceLocation then
        self.character:faceLocation(self.stationX + 0.5, self.stationY + 0.5)
        return self.character.shouldBeTurning and self.character:shouldBeTurning() or false
    end
    return false
end

function FFC_QueuedStationCookAction:update()
    if self.stationX and self.stationY and self.character and self.character.faceLocation then
        self.character:faceLocation(self.stationX + 0.5, self.stationY + 0.5)
    end
    if self.character and self.character.setMetabolicTarget and Metabolics and Metabolics.LightDomestic then
        self.character:setMetabolicTarget(Metabolics.LightDomestic)
    end
end

function FFC_QueuedStationCookAction:start()
    if FadedFeastcraft.UpdateCookingStatus then
        FadedFeastcraft.UpdateCookingStatus("Cooking...", tostring(self.context.stationName or "Heat Source"))
    end
    self:setActionAnim("Craft")
    if self.character and self.character.reportEvent then
        self.character:reportEvent("EventCraft")
    end
end

function FFC_QueuedStationCookAction:stop()
    if FadedFeastcraft.CancelQueuedStationCooking then
        FadedFeastcraft.CancelQueuedStationCooking(self.context, "Cooking cancelled before the server request was sent.")
    end
    ISBaseTimedAction.stop(self)
end

function FFC_QueuedStationCookAction:perform()
    if FadedFeastcraft.SendQueuedStationCooking then
        FadedFeastcraft.SendQueuedStationCooking(self.context)
    end
    ISBaseTimedAction.perform(self)
end

function FFC_QueuedStationCookAction:getDuration()
    if self.character and self.character.isTimedActionInstant and self.character:isTimedActionInstant() then return 1 end
    local count = #(self.context and self.context.itemIds or {})
    local level = 0
    pcall(function()
        if self.character and self.character.getPerkLevel and Perks and Perks.Cooking then
            level = tonumber(self.character:getPerkLevel(Perks.Cooking)) or 0
        end
    end)
    return math.max(90, 170 + count * 18 - level * 7)
end

function FFC_QueuedStationCookAction:new(character, context)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.context = context or {}
    o.stationX, o.stationY, o.stationZ = parseStationKey(o.context.stationKey)
    o.maxTime = o:getDuration()
    o.stopOnWalk = true
    o.stopOnRun = true
    o.forceProgressBar = true
    o.caloriesModifier = 4
    return o
end

return FFC_QueuedStationCookAction
