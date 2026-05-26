--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "GunFighter_02Function"
require "TimedActions/ISBaseTimedAction"

ISInsertMagazine = ISBaseTimedAction:derive("ISInsertMagazine")

local function FWPRefreshMagazineProxy(character, gun)
	if not (gun and showMag) then
		return
	end
	if gun.isAimedFirearm and not gun:isAimedFirearm() then
		return
	end
	pcall(showMag, gun)
	if character and syncHandWeaponFields then
		pcall(syncHandWeaponFields, character, gun)
	end
end

------------------------------------------------------------------
--	HARDCORE RELOADING SECTION by STORMTROOPER
------------------------------------------------------------------
ISInsertMagazine.addRackingAfter = function(self, player, gun)
	ISTimedActionQueue.addAfter(self, ISRackFirearm:new(player, gun))
end
------------------------------------------------------------------


function ISInsertMagazine:isValid()
	if not isClient() and not self.loadFinished then
		if self.gun:isContainsClip() then return false end
		if not self.character:getInventory():contains(self.magazine) then return false end
	end
	return self.character:getPrimaryHandItem() == self.gun
end

function ISInsertMagazine:start()
	if isClient() and self.magazine then
		self.magazine = self.character:getInventory():getItemById(self.magazine:getID())
	end
	if not isClient() then
		if FWPPrepareMagazineInsert then
			FWPPrepareMagazineInsert(self.gun, self.magazine)
		elseif FWPInspectPrepareMagazineInsert then
			FWPInspectPrepareMagazineInsert(self.gun, self.magazine)
		end
	end
	self:setAnimVariable("WeaponReloadType", tostring(self.gun:getWeaponReloadType()))
	self:setAnimVariable("isLoading", true)
	self:setOverrideHandModels(self.gun, nil)
	self:setActionAnim(CharacterActionAnims.Reload)
	self.character:reportEvent("EventReloading");
	self:initVars()
end

function ISInsertMagazine:update()
	-- FIXME: jobDelta is always zero since maxTime is -1
	self.gun:setJobDelta(self:getJobDelta())
	self.magazine:setJobDelta(self:getJobDelta())
end

function ISInsertMagazine:initVars()
	ISReloadWeaponAction.setReloadSpeed(self.character, false)
end

--function ISInsertMagazine:loadAmmo()
	-- we insert a new clip only if we're in the motion of loading
--	self.character:getInventory():Remove(self.magazine)
--	self.character:removeFromHands(self.magazine)
--	self.gun:setCurrentAmmoCount(self.magazine:getCurrentAmmoCount())
--	self.gun:setContainsClip(true)
--	self.character:clearVariable("isLoading")
	-- we rack only if no round is chambered
--	if not self.gun:isRoundChambered() and self.gun:getCurrentAmmoCount() >= self.gun:getAmmoPerShoot() then
--		ISTimedActionQueue.addAfter(self, ISRackFirearm:new(self.character, self.gun))
--	end
--	self:forceComplete()
--end

function ISInsertMagazine:loadAmmo()
	if FWPPrepareMagazineInsert then
		FWPPrepareMagazineInsert(self.gun, self.magazine)
	elseif FWPInspectPrepareMagazineInsert then
		FWPInspectPrepareMagazineInsert(self.gun, self.magazine)
	end
------------------------------------------------------------------
--  Stripper Clip & Speed Loader script, Arsenal[26]		--
------------------------------------------------------------------
	local	Clip = self.gun:getModData().ClipType
	local	Mag = self.gun:getModData().MagType
	local	Current = self.gun:getCurrentAmmoCount()
	local	Max = self.gun:getMaxAmmo()

--	if 	(self.gun:getMagazineType() == Clip) then
--	if 	Clip ~= nil and self.gun:getFabricType() == "Clip" and (self.gun:getMagazineType() == Clip) then
	if 	(Clip ~= nil) and (canUseClip(self.gun)) and (self.gun:getMagazineType() == Clip) then
		local ClipAmmo = self.magazine:getCurrentAmmoCount()
		local CanFit = Max - Current
		local LeftOnClip = ClipAmmo - CanFit
		local GoIn = 0
		if LeftOnClip <= 0 then
			GoIn = ClipAmmo
		else	GoIn = ClipAmmo - LeftOnClip
		end
		local Total = Current + GoIn
		local GoBack = 0
		if LeftOnClip <= 0 then
			GoBack = 0
		else	GoBack = LeftOnClip
		end

		self.magazine:setCurrentAmmoCount(GoBack)
		self.gun:setCurrentAmmoCount(Current + GoIn)

		if	self.gun:getWeaponReloadType() == "revolver" then
			Sound = self.character:getEmitter():playSound("SpeedLoader")
			self.character:addLineChatElement("+"..tostring(GoIn).."("..tostring(Current + GoIn)..")")
			self.gun:setContainsClip(false)		-- REMOVE SO NOT INSERTED
		--	self.gun:setMagazineType(nil)			-- REMOVE WHEN DONE *** DO NOT DO FOR MANUAL REVOLVER ALT MODE
		else
			if		Current == Max then
					Sound = self.character:getEmitter():playSound("ZeroClip")
					self.character:addLineChatElement(getText("ContextMenu_ALTLoad_Full").."("..tostring(Current)..")")
			elseif	GoIn == 0 then
					Sound = self.character:getEmitter():playSound("ZeroClip")
					self.character:addLineChatElement(getText("ContextMenu_ALTLoad_ClipEmpty").."("..tostring(Current)..")")
			elseif	GoIn < 5 then
					Sound = self.character:getEmitter():playSound("PartialClip")
					self.character:addLineChatElement("+"..tostring(GoIn).."("..tostring(Current + GoIn)..")")
			elseif	GoIn >= 5 then
					Sound = self.character:getEmitter():playSound("StripClip")
					self.character:addLineChatElement("+"..tostring(GoIn).."("..tostring(Current + GoIn)..")")
			end
			self.gun:setContainsClip(true)		-- PUT BACK AFTER REMOVING FROM BEFORE
			self.gun:getModData().isStripping = nil
			if self.gun.transmitModData then
				self.gun:transmitModData()
			end
		end
	else
		-- we insert a new clip only if we're in the motion of loading
		self.character:getInventory():Remove(self.magazine)
		self.character:removeFromHands(self.magazine)
		self.gun:setCurrentAmmoCount(self.magazine:getCurrentAmmoCount())
		if FWPCopyLoadedAmmoState then
			FWPCopyLoadedAmmoState(self.magazine, self.gun)
		end
		self.gun:setContainsClip(true)
		self.character:clearVariable("isLoading")
		if sendRemoveItemFromContainer then
			 sendRemoveItemFromContainer(self.character:getInventory(), self.magazine)
		end
	end

------------------------------------------------------------------
--	SHOW MAG CODE LOCATED IN GunFighter_Function.lua	--
------------------------------------------------------------------
	FWPRefreshMagazineProxy(self.character, self.gun)

	self.character:clearVariable("isLoading")


	-- we rack only if no round is chambered
------------------------------------------------------------------
--  CHECK haveChamber so it works with Revolvers, Arsenal[26]	--
------------------------------------------------------------------
	if 	not isServer() and not isClient() and self.gun:haveChamber() and not self.gun:isRoundChambered() and self.gun:getCurrentAmmoCount() >= self.gun:getAmmoPerShoot() then
--	if not self.gun:isRoundChambered() and self.gun:getCurrentAmmoCount() >= self.gun:getAmmoPerShoot() then
	------------------------------------------------------------------
	--	HARDCORE RELOADING SECTION by STORMTROOPER
	------------------------------------------------------------------
		ISInsertMagazine.addRackingAfter(self, self.character, self.gun);
	------------------------------------------------------------------
	end
	if syncHandWeaponFields then
		syncHandWeaponFields(self.character, self.gun)
	end
	self:forceComplete()

end


function ISInsertMagazine:serverStart()
	if not self.gun or not self.magazine then
		self.netAction:forceComplete()
		return
	end
	self:initVars()
	emulateAnimEventOnce(self.netAction, ISReloadWeaponAction.getReloadTime(self.character, 1500), "loadFinished", nil)
end

function ISInsertMagazine:getDuration()
	return -1
end

function ISInsertMagazine:complete()
	return true
end

function ISInsertMagazine:animEvent(event, parameter)
	-- Loading clip is done, we're moving to racking if needed
	if event == 'loadFinished' then
		self.loadFinished = true
		if not isClient() then
			local chance = 3
			local xp = 1
			if self.character:getPerkLevel(Perks.Reloading) < 5 then
				chance = 1
				xp = 4
			end
			if ZombRand(chance) == 0 then
				if addXp then
					addXp(self.character, Perks.Reloading, xp)
				else
					self.character:getXp():AddXP(Perks.Reloading, xp)
				end
			end
			self:loadAmmo()
		end
		if isServer() then
			self.netAction:forceComplete()
		elseif not isClient() then
			self:forceComplete()
		end
	end
	if event == 'playReloadSound' then
		if parameter == 'load' then
			if self.gun:getInsertAmmoSound() and self.gun:getCurrentAmmoCount() < self.gun:getMaxAmmo() then
				self.character:playSound(self.gun:getInsertAmmoSound())
			end
		elseif parameter == 'insertAmmoStart' then
			if self.gun:getInsertAmmoStartSound() then
				self.character:playSound(self.gun:getInsertAmmoStartSound());
			end
		end
	end
end

function ISInsertMagazine:stop()
	if self.gun:getInsertAmmoStopSound() then
		self.character:playSound(self.gun:getInsertAmmoStopSound());
	end
	------------------------------------------------------------------
	--	WORKAROUND FOR CLIP LOAD CANCELLING
	------------------------------------------------------------------
	if self.gun:getModData().isStripping ~= nil then
		DebugSay(3,"STRIPPING PUT CLIP BACK ON STOP")
		self.gun:setContainsClip(true)
	end

	self.gun:setJobDelta(0.0)
	self.magazine:setJobDelta(0.0)
	self.character:clearVariable("isLoading")
	self.character:clearVariable("WeaponReloadType")
	ISBaseTimedAction.stop(self)
end

function ISInsertMagazine:perform()
	if self.gun:getInsertAmmoStopSound() then
		self.character:playSound(self.gun:getInsertAmmoStopSound());
	end
	self.gun:setJobDelta(0.0)
	self.magazine:setJobDelta(0.0)
	self.character:clearVariable("isLoading")
	self.character:clearVariable("WeaponReloadType")
	if isClient() then
		FWPRefreshMagazineProxy(self.character, self.gun)
		-- we rack only if no round is chambered
		if self.gun:haveChamber() and not self.gun:isRoundChambered() and self.gun:getCurrentAmmoCount() >= self.gun:getAmmoPerShoot() then
			ISInsertMagazine.addRackingAfter(self, self.character, self.gun);
		end
	end

	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISInsertMagazine:new(character, gun, magazine)
	local o = ISBaseTimedAction.new(self, character)
	o.stopOnWalk = false
	o.stopOnRun = true
	o.stopOnAim = false
	o.maxTime = o:getDuration()
	o.useProgressBar = false
	o.gun = gun
	o.magazine = magazine
	o.loadFinished = false
	return o
end
