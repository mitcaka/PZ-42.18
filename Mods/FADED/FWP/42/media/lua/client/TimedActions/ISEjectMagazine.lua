--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISEjectMagazine = ISBaseTimedAction:derive("ISEjectMagazine")

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

function ISEjectMagazine:isValid()
	return self.character:getPrimaryHandItem() == self.gun
end

function ISEjectMagazine:start()
	if not self.gun:isContainsClip() then
		self:forceStop()
		return
	end
	self:setAnimVariable("WeaponReloadType", tostring(self.gun:getWeaponReloadType()))
	self:setAnimVariable("isUnloading", true)
	self:setOverrideHandModels(self.gun, nil)
	self:setActionAnim(CharacterActionAnims.Reload)
	self.character:reportEvent("EventReloading");
	self:initVars()
end

function ISEjectMagazine:update()
	-- FIXME: jobDelta is always zero since maxTime is -1
	self.gun:setJobDelta(self:getJobDelta())
end

function ISEjectMagazine:initVars()
	ISReloadWeaponAction.setReloadSpeed(self.character, false)
end

function ISEjectMagazine:unloadAmmo()
	-- get back the magazine if there was one in the gun
	if self.gun:isContainsClip() then
----------------------------------------------------------------------------------
--  PREVENTS EJECTING FIXED MAG, EJECTS MAG INSTEAD OF STRIPPER IN CLIP-MODE	--
----------------------------------------------------------------------------------
		local	Clip = self.gun:getModData().ClipType
		local	Mag = self.gun:getModData().MagType
		local	Fixed = self.gun:getModData().FixedMagType
		local	newMag = nil
		
		if	self.gun:getMagazineType() == Clip then					-- IF USING CLIPS, CREATE DETACHBLE LIKE M14
			if (Mag == nil) or (Fixed ~= nil) then
				newMag = nil
			else	newMag = FWPCreateItem(Mag)
			end
		else	newMag = FWPCreateItem(self.gun:getMagazineType())	-- OTHERWISE CREATE ORIGNAL MAGTYPE
		end

		if	newMag ~= nil then
			newMag:setCurrentAmmoCount(self.gun:getCurrentAmmoCount())
			if FWPCopyLoadedAmmoState then
				FWPCopyLoadedAmmoState(self.gun, newMag)
			end
			if FWPMarkFlameFuelCanisterKnown then
				FWPMarkFlameFuelCanisterKnown(newMag, true)
			end

			self.character:getInventory():AddItem(newMag)
			self.gun:setContainsClip(false)
			self.gun:setCurrentAmmoCount(0)
			if FWPSetLoadedIncendiaryCount then
				FWPSetLoadedIncendiaryCount(self.gun, 0)
			end
			if sendAddItemToContainer then
				sendAddItemToContainer(self.character:getInventory(), newMag)
			end
			if syncHandWeaponFields then
				syncHandWeaponFields(self.character, self.gun)
			end
		else
			if Mag == nil then
				self.gun:setContainsClip(false)
				self.character:addLineChatElement(getText("ContextMenu_ALTLoad_Integral"))
			else	self.character:addLineChatElement(getText("ContextMenu_ALTLoad_Fixed"))
			end
		end
		------------------------------------------------------------------
		--	SHOW MAG CODE LOCATED IN GunFighter_Function.lua	--
		------------------------------------------------------------------
		FWPRefreshMagazineProxy(self.character, self.gun)
	end
end


function ISEjectMagazine:animEvent(event, parameter)
	if event == 'playReloadSound' then
		if parameter == 'unload' then
			if self.gun:getEjectAmmoSound() then
				self.character:playSound(self.gun:getEjectAmmoSound())
			end
		elseif parameter == 'ejectAmmoStart' then
			if self.gun:getEjectAmmoStartSound() then
				self.character:playSound(self.gun:getEjectAmmoStartSound());
			end
		end
	end
	if event == 'unloadFinished' then
		if not isClient() then
			self:unloadAmmo()
		end
		if isServer() then
			self.netAction:forceComplete()
		else
			self:forceComplete()
		end
	end
end

function ISEjectMagazine:serverStart()
	self:initVars()
	emulateAnimEventOnce(self.netAction, ISReloadWeaponAction.getReloadTime(self.character, 1200), "unloadFinished", nil)
end

function ISEjectMagazine:getDuration()
	return -1
end

function ISEjectMagazine:complete()
	return true
end
function ISEjectMagazine:stop()
	if self.gun:getEjectAmmoStopSound() then
		self.character:playSound(self.gun:getEjectAmmoStopSound());
	end
	self.gun:setJobDelta(0.0)
	self.character:clearVariable("isUnloading")
	self.character:clearVariable("WeaponReloadType")
	ISBaseTimedAction.stop(self)
end

function ISEjectMagazine:perform()
	if self.gun:getEjectAmmoStopSound() then
		self.character:playSound(self.gun:getEjectAmmoStopSound());
	end
	self.gun:setJobDelta(0.0)
	self.character:clearVariable("isUnloading")
	self.character:clearVariable("WeaponReloadType")
	if isClient() then
		FWPRefreshMagazineProxy(self.character, self.gun)
	end
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISEjectMagazine:new(character, gun)
	local o = ISBaseTimedAction.new(self, character)
	o.stopOnWalk = false
	o.stopOnRun = true
	o.stopOnAim = false
	o.maxTime = o:getDuration()
	o.gun = gun
	o.useProgressBar = false
	return o
end

