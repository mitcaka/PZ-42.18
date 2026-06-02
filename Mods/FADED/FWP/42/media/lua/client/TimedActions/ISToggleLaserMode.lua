
--[[	This method was learned from the Original Armor Mod by NOLAN RITCHIE...	]]


LaserMode = {};

LaserMode.init = function(_player, context, _items)

    local player = getSpecificPlayer(_player);
    local clickedItems = _items;
    
    if #clickedItems > 1 then
        return;
    end
    
    for i, item in ipairs(clickedItems) do
        if not instanceof(item, "InventoryItem") then
            item = item.items[2];
        end
        if instanceof(item, "InventoryItem") then
            LaserMode.createMenus(player, context, item);
        end
    end
end

LaserMode.createMenus = function(player, context, item)
	local itemType = item:getType();

	if	(instanceof(item,"HandWeapon")) and (item:isAimedFirearm()) and FWPGetWeaponPart(item, "Stock") ~= nil and FWPGetWeaponPart(item, "Stock"):hasTag(FWPGetItemTag("Multi_Laser")) then
		local time = 10
		local text = "Toggle Mode "..tostring(FWPGetWeaponPart(item, "Stock"):getDisplayName())
		context:addOption(text, item, LaserMode.ToggleLaserMode, player, 10);
	else
		--getSpecificPlayer(0):Say("no Laser")
	end
end


LaserMode.ToggleLaserMode = function(item, player, time)
    if luautils.haveToBeTransfered(player, item) then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, item:getContainer(), player:getInventory()));
    end
    ISTimedActionQueue.add(ToggleLaserModeAction:new(player, item, time));
end

Events.OnFillInventoryObjectContextMenu.Add(LaserMode.init);



ToggleLaserModeAction = ISBaseTimedAction:derive("ToggleLaserModeAction");

function ToggleLaserModeAction:isValid()
    return self.character:getInventory():contains(self.item);
end

function ToggleLaserModeAction:update()
    self.item:setJobDelta(self:getJobDelta());
end

function ToggleLaserModeAction:start()
    self.item:setJobType("Examine Armor");
    self.item:setJobDelta(0.0);
end

function ToggleLaserModeAction:stop()
    ISBaseTimedAction.stop(self);
    self.item:setJobDelta(0.0);
end

function ToggleLaserModeAction:perform()
    self.item:getContainer():setDrawDirty(true);
    self.item:setJobDelta(0.0);
    
    local player = self.character;
    local item = self.item
    
    ToggleLaserMode(item, player)
    
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function ToggleLaserModeAction:new(character, item, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.item = item;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.maxTime = time;
    return o
end


function ToggleLaserMode(item, player)
	local gun	= item
	local laser = FWPGetWeaponPart(gun, "Stock")

	if		laser:getColorRed() > 0 then
			laser:setColorRed(0)
			laser:setColorGreen(1)
			laser:setColorBlue(0)
			DebugSay(2,tostring(laser:getDisplayName()).." ".. getText("ContextMenu_Laser_GREEN"))
	elseif	laser:getColorGreen() > 0 then
			laser:setColorRed(1)
			laser:setColorGreen(0)
			laser:setColorBlue(0)
			DebugSay(2,tostring(laser:getDisplayName()).." ".. getText("ContextMenu_Laser_RED"))
	end
end