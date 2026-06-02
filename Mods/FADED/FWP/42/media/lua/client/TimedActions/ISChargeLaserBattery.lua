
--[[	This method was learned from the Original Armor Mod by NOLAN RITCHIE...	]]
--[[	This one is for STOCK SLOT weapon LIGHT / LASER attachments		]]

LaserBattery = {};

LaserBattery.init = function(_player, context, _items)

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
            LaserBattery.createMenus(player, context, item);
        end
    end
end

LaserBattery.createMenus = function(player, context, item)
	if FWPWeaponLightChargeHandlesContext then
		return
	end
	local itemType = item:getType();

	if		(instanceof(item,"HandWeapon")) and (item:isAimedFirearm()) and FWPGetWeaponPart(item, "Stock") ~= nil and ( FWPGetWeaponPart(item, "Stock"):hasTag(FWPGetItemTag("Laser")) or FWPGetWeaponPart(item, "Stock"):hasTag(FWPGetItemTag("Multi_Laser")) or FWPGetWeaponPart(item, "Stock"):hasTag(FWPGetItemTag("Light")) ) then
			local time = 10
			local text = "Charge "..tostring(FWPGetWeaponPart(item, "Stock"):getDisplayName())
			context:addOption(text, item, LaserBattery.ChargeLaserBattery, player, 10);
	end
end


LaserBattery.ChargeLaserBattery = function(item, player, time)
    if luautils.haveToBeTransfered(player, item) then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, item:getContainer(), player:getInventory()));
    end
    ISTimedActionQueue.add(ChargeLaserBatteryAction:new(player, item, time));
end

Events.OnFillInventoryObjectContextMenu.Add(LaserBattery.init);



ChargeLaserBatteryAction = ISBaseTimedAction:derive("ChargeLaserBatteryAction");

function ChargeLaserBatteryAction:isValid()
    return self.character:getInventory():contains(self.item);
end

function ChargeLaserBatteryAction:update()
    self.item:setJobDelta(self:getJobDelta());
end

function ChargeLaserBatteryAction:start()
    self.item:setJobType("Examine Armor");
    self.item:setJobDelta(0.0);
end

function ChargeLaserBatteryAction:stop()
    ISBaseTimedAction.stop(self);
    self.item:setJobDelta(0.0);
end

function ChargeLaserBatteryAction:perform()
    self.item:getContainer():setDrawDirty(true);
    self.item:setJobDelta(0.0);
    
    local player = self.character;
    local item = self.item
    
    ChargeLaserBattery(item, player)
    
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function ChargeLaserBatteryAction:new(character, item, time)
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


function ChargeLaserBattery(weapon, player)
	if FWPWeaponLightChargeRequestSlot then
		return FWPWeaponLightChargeRequestSlot(player, weapon, "Stock")
	end
	local inv	= player:getInventory()
	local items	= inv:getItems()
	local gun	= weapon
	local part	= FWPGetWeaponPart(gun, "Stock")
	local batt	= nil
	local chargeBATT	= 0
	local chargePART	= 0
	local chargeNEED	= 0

	
	if	items then
		for i=0,items:size() - 1 do
			local item = items:get(i)
			if (item ~= nil) then
				if	item:getType() == "Battery" then
					if	round(item:getUsedDelta() * 100,1) > chargeBATT then		-- TIMES 100 TO COMPARE SAME SCALE
						batt = item
						chargeBATT = round(item:getUsedDelta() * 100,1)				-- 70
						DebugSay(2,getText("ContextMenu_FindBattery").."..."..tostring(chargeBATT))
					end
				end
			end
		end
	
		if	part:getModData().Charge == nil then
			part:getModData().Charge = 0
		end
	
		if	batt ~= nil then				-- HAS BATTERY
			local chargeUSED
			local chargeLEFT
			player:playSound("LightSaber_Charge");
			chargePART = round(part:getModData().Charge,1)
			chargeNEED = round(100 - chargePART,1)					-- 100 MAX - 90 PART = 10 NEED
			if		chargeBATT - chargeNEED >= 0 then				-- 70 - 10 IS POSITIVE, SO ENOUGH
					chargeUSED = chargeNEED							-- 10	THERE IS <<< ENOUGH SO GIVE FULL NEED
			else	chargeUSED = chargeBATT							-- 70	THERE IS <<< NOT ENOUGH						
			end
						
			chargeLEFT	= round(chargeBATT - chargeUSED,1)			-- 70 - 10 = 60
			chargePART	= round(chargePART + chargeUSED,1)			-- 90 + 10 = 100
			
			part:getModData().Charge = chargePART
			gun:getModData().Charge = chargePART					-- FOR SAVE / LOAD
			batt:setUsedDelta(chargeLEFT / 100)
			DebugSay(2,getText("ContextMenu_Device").." (+"..tostring(chargeUSED).."/"..tostring(chargePART)..") "..getText("ContextMenu_Battery").." ("..tostring(chargeLEFT)..")")
		else DebugSay(2,getText("ContextMenu_NoBattery"))		-- NO BATTERY
		end
	end
end
