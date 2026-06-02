--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISManipulateFirearm = ISBaseTimedAction:derive("ISManipulateFirearm")

function ISManipulateFirearm:isValid()
	return true
end

function ISManipulateFirearm:start()
	
	self.gun:setJobType(getText("IGUI_JobType_ManipulateFirearm"))

	if (self.gun) and (instanceof(self.gun,"HandWeapon")) and (self.gun:isAimedFirearm()) then	
		self:setActionAnim("TransferItemOnSelf")
	else	self:setActionAnim("TransferItemOnSelf")
	end
	self:setAnimVariable("LootPosition", "");
	self:setAnimVariable("isUnloading", true)
	self.gun:setJobDelta(0.0)
	self:setOverrideHandModels(self.gun, nil)

	if	(self.Hotbar ~= nil) then
		if (self.slot) and (self.result) and (not self.Hotbar:isInHotbar(self.result)) and (self.Hotbar:canBeAttached(self.slot, self.result)) then
			if FWPRestoreWeaponSprite then
				FWPRestoreWeaponSprite(self.result, self.tempSprite)
			end
			self.Hotbar:removeItem(self.gun, false)
			self.Hotbar:attachItem(self.result, self.slot.def.attachments[self.result:getAttachmentType()], self.W_slot, self.slot.def, false)
		end
	end




	self:initVars()
end

function ISManipulateFirearm:update()
	self.Tiks = self.Tiks - 1
	DebugSay(3,tostring(self.Tiks))
	self.gun:setJobDelta(0.5)

	if	self.Tiks == 0 then
		if FWPRestoreWeaponSprite then
			FWPRestoreWeaponSprite(self.result, self.tempSprite)
		elseif self.result and self.result.setWeaponSprite and self.tempSprite then
			self.result:setWeaponSprite(self.tempSprite)
		end
		self:forceComplete()
		return
	end

--	if	(self.Hotbar ~= nil) and self.Tiks == 25 then
--		if (self.slot) and (self.result) and (not self.Hotbar:isInHotbar(self.result)) and (self.Hotbar:canBeAttached(self.slot, self.result)) then
--		--	self.result:setWeaponSprite("null")
--		--	self.Hotbar:removeItem(self.gun, false)
--			self.Hotbar:attachItem(self.result, self.slot.def.attachments[self.result:getAttachmentType()], self.W_slot, self.slot.def, false)
--		end
--	end
end

function ISManipulateFirearm:initVars()
	ISReloadWeaponAction.setReloadSpeed(self.character, false)
end

function ISManipulateFirearm:animEvent(event, parameter)
	if event == 'unloadFinished' then
		self.unloadFinished = true
	elseif event == 'changeWeaponSprite' then
		if parameter and parameter ~= '' then
			if parameter ~= 'original' then
				self:setOverrideHandModels(parameter, nil)
			else
				self:setOverrideHandModels(self.gun:getWeaponSprite(), nil)
			end
		end
	end
end

function ISManipulateFirearm:stop()
	if FWPRestoreWeaponSprite then
		FWPRestoreWeaponSprite(self.result, self.tempSprite)
	end
	self.gun:setJobDelta(0.0)
	self.character:clearVariable("isUnloading");
	ISBaseTimedAction.stop(self)
end

function ISManipulateFirearm:perform()
	if FWPRestoreWeaponSprite then
		FWPRestoreWeaponSprite(self.result, self.tempSprite)
	end
	self.gun:setJobDelta(0.0)
	self.character:clearVariable("isUnloading");
	ISBaseTimedAction.perform(self)
end

function ISManipulateFirearm:new(character, gun, result, time)
	local o = ISBaseTimedAction.new(self, character)
	o.stopOnAim = false
	o.stopOnWalk = false
	o.stopOnRun = false
	o.maxTime = 30
	o.Tiks = time			-- time HIGHER IS MORE OVERIDE HANDMODEL TIME FOR LESS GLITCH
	o.gun = gun
	o.result = result
	o.tempSprite = o.result:getWeaponSprite()
	if o.result and o.result.getModData then
		o.result:getModData().FWPOriginalWeaponSprite = o.tempSprite
	end
	o.Hotbar = getPlayerHotbar(character:getPlayerNum());
	o.W_slot = o.gun:getAttachedSlot()
	o.slot = o.Hotbar.availableSlot[o.W_slot]
	o.useProgressBar = false
	return o
end
