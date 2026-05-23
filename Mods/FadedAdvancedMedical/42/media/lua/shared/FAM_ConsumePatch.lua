require "FAM_Core"
require "TimedActions/ISTakePillAction"
require "TimedActions/ISEatFoodAction"

if ISTakePillAction and not FAM._patchedTakePillAction then
    FAM._patchedTakePillAction = true
    local oldComplete = ISTakePillAction.complete

    function ISTakePillAction:complete()
        local item = self.item
        local beforeUses = nil
        if item and item.getCurrentUsesFloat then
            beforeUses = item:getCurrentUsesFloat()
        end

        if item and item:getModule() == "FAM" then
            FAM.applyPill(self.character, item:getType())
        end

        local result = oldComplete(self)

        if item and item:getModule() == "FAM" and item.UseAndSync and beforeUses and item:getCurrentUsesFloat() == beforeUses then
            item:UseAndSync()
        end

        return result
    end
end

if ISEatFoodAction and not FAM._patchedEatFoodAction then
    FAM._patchedEatFoodAction = true
    local oldGetDuration = ISEatFoodAction.getDuration

    function ISEatFoodAction:getDuration()
        if self.item and self.item:getModule() == "FAM" and string.find(self.item:getType(), "Syrette", 1, true) == 1 then
            if self.character:isTimedActionInstant() then
                return 1
            end
            return 100
        end
        return oldGetDuration(self)
    end
end
