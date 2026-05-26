-- @author Risky
-- Custom timed actions

require "TimedActions/ISBaseTimedAction"

FWPInspectAction = ISBaseTimedAction:derive("FWPInspectAction");

function FWPInspectAction:isValid()
    return true
end

function FWPInspectAction:update()
end

function FWPInspectAction:start()
end

function FWPInspectAction:stop()
    ISBaseTimedAction.stop(self);
end

function FWPInspectAction:perform()
    -- Init main window
    if FWPInspectWindow[self.character:getPlayerNum()] == nil or not FWPInspectWindow[self.character:getPlayerNum()]:getIsVisible() then
        FWPInspectWindow[self.character:getPlayerNum()] = FWPInspectUI:new(self.character:getModData().fwpInspectWindowPos[1], self.character:getModData().fwpInspectWindowPos[2], 0, 0, self.character)
        FWPInspectWindow[self.character:getPlayerNum()]:setTitle(getText('IGUI_FWP_INSPECT_INSPECT_WEAPON'))
        FWPInspectWindow[self.character:getPlayerNum()]:addToUIManager()
        FWPInspectWindow[self.character:getPlayerNum()].resizable = false
        FWPInspectWindow[self.character:getPlayerNum()].collapsable = false

        FWPInspectWindow[self.character:getPlayerNum()]:renderInventory()
    end

    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function FWPInspectAction:new(character, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.maxTime = time;
    return o;
end
