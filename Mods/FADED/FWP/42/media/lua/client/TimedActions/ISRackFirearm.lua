--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISRackFirearm = ISBaseTimedAction:derive("ISRackFirearm")

function ISRackFirearm:isValid()
	return true
end

function ISRackFirearm:start()
	if not ISReloadWeaponAction.canRack(self.gun) then
		self:forceComplete()
		return
	end
	
	-- Setup IsPerformingAction & the current anim we want (check in AnimSets LoadHandgun.xml for example)
	self:setAnimVariable("WeaponReloadType", tostring(self.gun:getWeaponReloadType()))

	-- we asked to rack, we gonna remove bullets if one is chambered or load one is no one is chambered
	-- chamber gun will need to be racked to remove bullet, otherwise we play the unload anim
	if self.gun:haveChamber() then
		self:setAnimVariable("isRacking", true)
	else
		self:setAnimVariable("isUnloading", true)
	end

	self:setAnimVariable("RackAiming", self.character:isAiming())

	self:setOverrideHandModels(self.gun, nil)
	self:setActionAnim(CharacterActionAnims.Reload)
	self.character:reportEvent("EventReloading");

	self:ejectSpentRounds()

	--------------------------------------------------
	--	ARSENAL[26]						--
	local timeOffset = (10 - self.character:getPerkLevel(Perks.Reloading))
	if self.gun:getWeaponReloadType() == "boltaction" or self.gun:getWeaponReloadType() == "boltactionnomag" then
		self.character:getModData().DelayAction = 20 + timeOffset
	else	self.character:getModData().DelayAction = 5 + timeOffset
	end
	self.character:getModData().CycleAction = self.character:getModData().DelayAction + 20
	--------------------------------------------------

	self:initVars()
end

function ISRackFirearm:update()
end

-- Rack to get a bullet (from the chamber) or unjam the gun
local function FWPGetRackAmmoPerShoot(gun)
	if gun and gun.getAmmoPerShoot then
		local okAmmo, ammoPerShoot = pcall(function() return gun:getAmmoPerShoot() end)
		if okAmmo and tonumber(ammoPerShoot) and tonumber(ammoPerShoot) > 0 then
			return tonumber(ammoPerShoot)
		end
	end
	return 1
end

function ISRackFirearm:rackBullet()
	local spentAfterShot = false
	local ammoAlreadyConsumed = false
	if self.gun.getModData then
		local md = self.gun:getModData()
		spentAfterShot = md and md.FWP_RackAfterShotSpent == true
		ammoAlreadyConsumed = md and md.FWP_RackAfterShotAmmoConsumed == true
		if spentAfterShot then
			md.FWP_RackAfterShotSpent = nil
		end
		if ammoAlreadyConsumed then
			md.FWP_RackAfterShotAmmoConsumed = nil
		end
	end

	local ammoPerShoot = FWPGetRackAmmoPerShoot(self.gun)

	-- FWP B42 rack-after-shot spent chamber bridge: racking after a shot ejects the fired casing, not a live round.
	if self.gun:haveChamber() then
		-- rack give one bullet & put another one back in the chamber
		-- don't give back bullet if jammed
		if not self.gun:isJammed() and self.gun:isRoundChambered() and not spentAfterShot then
			self:removeBullet()
		end
		self.gun:setRoundChambered(false)
		self.gun:setSpentRoundChambered(false)
		self.gun:setJammed(false)
		if self.gun:getCurrentAmmoCount() >= ammoPerShoot then
			self.gun:setRoundChambered(true)
			if not ammoAlreadyConsumed then
				self.gun:setCurrentAmmoCount(math.max(0, self.gun:getCurrentAmmoCount() - ammoPerShoot))
			end
		end
	else
		-- Manual racking returns a live round. Post-shot pump cycling consumes the fired shell.
		if not self.gun:isJammed() and self.gun:getCurrentAmmoCount() > 0 then
			if not spentAfterShot then
				self:removeBullet()
			end
			if not ammoAlreadyConsumed then
				self.gun:setCurrentAmmoCount(math.max(0, self.gun:getCurrentAmmoCount() - ammoPerShoot))
			end
		end
		self.gun:setJammed(false)
		if self.gun.setSpentRoundChambered then
			self.gun:setSpentRoundChambered(false)
		end
	end
	if syncHandWeaponFields then
		syncHandWeaponFields(self.character, self.gun)
	end
end
--function ISRackFirearm:removeBullet()
--	local newBullet = FWPCreateItem(FWPGetAmmoItemKey(self.gun))
--	self.character:getInventory():AddItem(newBullet)
--end

function ISRackFirearm:removeBullet()
	local fallbackItemKey = FWPGetAmmoItemKey(self.gun)
	local itemKey = FWPConsumeLoadedAmmoForUnload and FWPConsumeLoadedAmmoForUnload(self.gun, fallbackItemKey) or fallbackItemKey
	if not itemKey then
		return
	end
	local newBullet = FWPCreateItem(itemKey)
	if newBullet and (newBullet:getType() ~= "FlameFuel") and (newBullet:getType() ~= "WaterAmmo") then
		self.character:getInventory():AddItem(newBullet)
		if sendAddItemToContainer then
			sendAddItemToContainer(self.character:getInventory(), newBullet)
		end
	end
end
function ISRackFirearm:ejectSpentRounds()
	if self.gun:getSpentRoundCount() > 0 then
		self.gun:setSpentRoundCount(0)
	elseif self.gun:isSpentRoundChambered() then
		self.gun:setSpentRoundChambered(false)
	else
		return
	end
	if self.gun:getShellFallSound() then
		self.character:getEmitter():playSound(self.gun:getShellFallSound())
	end
end


function ISRackFirearm:ejectSpentRounds()
	if self.gun:getSpentRoundCount() > 0 then
		self.gun:setSpentRoundCount(0)
	elseif self.gun:isSpentRoundChambered() then
		self.gun:setSpentRoundChambered(false)
	else
		return
	end
	if self.gun:getShellFallSound() then
		self.character:getEmitter():playSound(self.gun:getShellFallSound())
	end
end

function ISRackFirearm:initVars()
	ISReloadWeaponAction.setReloadSpeed(self.character, true)
end

function ISRackFirearm:stop()
	if self.playedEjectAmmoStartSound and self.gun:getEjectAmmoStopSound() then
		self.character:playSound(self.gun:getEjectAmmoStopSound());
	end
	self.character:clearVariable("isLoading")
	self.character:clearVariable("isRacking")
	self.character:clearVariable("isUnloading")
	self.character:clearVariable("WeaponReloadType")
	self.character:clearVariable("RackAiming")

	--------------------------------
	--	ARSENAL[26]			--
	CycleActionEnd(self.character)
	--------------------------------

	ISBaseTimedAction.stop(self)
end

function ISRackFirearm:perform()
	if self.playedEjectAmmoStartSound and self.gun:getEjectAmmoStopSound() then
		self.character:playSound(self.gun:getEjectAmmoStopSound());
	end
	self.character:clearVariable("isLoading")
	self.character:clearVariable("isRacking")
	self.character:clearVariable("isUnloading")
	self.character:clearVariable("WeaponReloadType")
	self.character:clearVariable("RackAiming")
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISRackFirearm:animEvent(event, parameter)
	if event == 'unloadFinished' then
		self:rackBullet()
		self:forceComplete()
	end
	if event == 'rackBullet' then
		self:rackBullet()
	end
	if event == 'rackingFinished' then
		-- Racking is done, we can exit out timedaction
		self:forceComplete()
	end
	if event == 'playReloadSound' then
		if parameter == 'rack' then
			if self.gun:getRackSound() then
				self.character:playSound(self.gun:getRackSound())
			end
		end
		if parameter == 'ejectAmmoStart' then
			if not self.playedEjectAmmoStartSound and self.gun:getEjectAmmoStartSound() then
				self.playedEjectAmmoStartSound = true;
				self.character:playSound(self.gun:getEjectAmmoStartSound());
			end
			return
		end
		if parameter == 'unload' then
			if self.gun:getEjectAmmoSound() then
				self.character:playSound(self.gun:getEjectAmmoSound())
			end
		end
	end
	if event == 'changeWeaponSprite' then
		if parameter and parameter ~= '' then
			if parameter ~= 'original' then
				self:setOverrideHandModels(parameter, nil)
			else
				self:setOverrideHandModels(self.gun:getWeaponSprite(), nil)
			end
		end
	end
end

function ISRackFirearm:new(character, gun)
	local o = ISBaseTimedAction.new(self, character)
	o.stopOnAim = false
	o.stopOnWalk = false
	o.stopOnRun = true
	o.maxTime = -1
	o.useProgressBar = false
	o.gun = gun
	return o
end	
