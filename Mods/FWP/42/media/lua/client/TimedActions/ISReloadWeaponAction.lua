--***********************************************************
--**                    ROBERT JOHNSON                     **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

local FWPPreviousReloadAction = ISReloadWeaponAction
local FWPPreviousOnPressReloadButton = FWPPreviousReloadAction and FWPPreviousReloadAction.OnPressReloadButton or nil
local FWPPreviousOnPressRackButton = FWPPreviousReloadAction and FWPPreviousReloadAction.OnPressRackButton or nil
local FWPPreviousOnShoot = FWPPreviousReloadAction and FWPPreviousReloadAction.onShoot or nil
local FWPPreviousOnPlayerAttackFinished = FWPPreviousReloadAction and FWPPreviousReloadAction.OnPlayerAttackFinished or nil
local FWPPreviousAttackHook = FWPPreviousReloadAction and FWPPreviousReloadAction.attackHook or nil

ISReloadWeaponAction = ISBaseTimedAction:derive("ISReloadWeaponAction");

------------------------------------------------------------------
--	HARDCORE RELOADING SECTION by STORMTROOPER
------------------------------------------------------------------
local FWPCanFireSemi = true

local function FWPAllowFiringSemi()
	FWPCanFireSemi = true
end

function ISReloadWeaponAction.stopAfterEject()
	return false
end

ISReloadWeaponAction.addRackingAfter = function(self, player, gun)
	ISTimedActionQueue.addAfter(self, ISRackFirearm:new(player, gun))
end

function ISReloadWeaponAction.canFireSemi()
	return FWPCanFireSemi
end

function ISReloadWeaponAction.noLongerCanFire()
	FWPCanFireSemi = false
end

if Events and Events.OnMouseUp then
	Events.OnMouseUp.Add(FWPAllowFiringSemi)
end

ISReloadWeaponAction.addRacking = function(player, gun)
	ISTimedActionQueue.add(ISRackFirearm:new(player, gun))
end
------------------------------------------------------------------

function ISReloadWeaponAction:isValid()
	return self.character:getPrimaryHandItem() == self.gun
end

function ISReloadWeaponAction:update()
	local remaining = self.ammoCount - (self.gun:getCurrentAmmoCount() - self.ammoCountStart)
	self.gun:setJobDelta((self.gun:getCurrentAmmoCount() - self.ammoCountStart) / self.ammoCount)
end

ISReloadWeaponAction.canRack = function(weapon)
	if not weapon:getMagazineType() and not FWPGetAmmoItemKey(weapon) then
		return false
	end
	if weapon:isJammed() then
		return true
	end
	if weapon:haveChamber() and weapon:isRoundChambered() then
		return true
	end
	if weapon:haveChamber() and weapon:isSpentRoundChambered() then
		return true
	end
	if weapon:haveChamber() and not weapon:isRoundChambered() and weapon:getMagazineType() and weapon:getCurrentAmmoCount() > 0 then
		return true
	end
	if not weapon:haveChamber() and weapon:getCurrentAmmoCount() > 0 then
		return true
	end
	if not weapon:haveChamber() and weapon:getSpentRoundCount() > 0 then
		return true
	end
	if not weapon:getMagazineType() and weapon:getCurrentAmmoCount() >= weapon:getAmmoPerShoot() then
		return true;
	end
	return false;
end

function ISReloadWeaponAction:start()
	-- Setup IsPerformingAction & the current anim we want (check in AnimSets LoadHandgun.xml for example)
	self:setOverrideHandModels(self.gun, nil);
	self:setAnimVariable("WeaponReloadType", tostring(self.gun:getWeaponReloadType()))
	self:setAnimVariable("isLoading", true);
	self.ammoCountStart = self.gun:getCurrentAmmoCount()
	self.gun:setJobType(getText("IGUI_JobType_LoadBulletsIntoFirearm"))
	self.gun:setJobDelta(0.0)
	self:initVars();
	self:setActionAnim(CharacterActionAnims.Reload);
	
	self.character:reportEvent("EventReloading");

	self:ejectSpentRounds()

	-- no bullets were found
	if not self.bullets then
		self:forceStop();
	end
end

-- This is used by other timed actions.
function ISReloadWeaponAction.setReloadSpeed(character, rack)
	local baseReloadSpeed = 0.8;
	if rack then
		-- reloading skill has less impact on racking, panic does nothing
		baseReloadSpeed = baseReloadSpeed + (character:getPerkLevel(Perks.Reloading) * 0.04);
	else
		baseReloadSpeed = baseReloadSpeed + (character:getPerkLevel(Perks.Reloading) * 0.10);
		baseReloadSpeed = baseReloadSpeed - (character:getMoodles():getMoodleLevel(MoodleType.PANIC) * 0.05);
	end

	-- check for ammo straps
	local gun = character:getPrimaryHandItem();
	local strap = character:getWornItem(ItemBodyLocation.AMMO_STRAP);
	local reloadFastShells = character:hasEquippedTag(ItemTag.RELOAD_FAST_SHELLS) or character:hasWornTag(ItemTag.RELOAD_FAST_SHELLS);
	local reloadFastBullets = character:hasEquippedTag(ItemTag.RELOAD_FAST_BULLETS) or character:hasWornTag(ItemTag.RELOAD_FAST_BULLETS);
	local reloadFastMagazines = character:hasEquippedTag(ItemTag.RELOAD_FAST_MAGAZINES) or character:hasWornTag(ItemTag.RELOAD_FAST_MAGAZINES);
	local strapFound = false;
	if gun and (reloadFastShells or reloadFastBullets or reloadFastMagazines or (strap and strap:getClothingItem())) then
		local ammoKey = FWPGetAmmoItemKey(gun);
		local shell = type(ammoKey) == "string" and string.find(ammoKey, "ShotgunShells", 1, true) ~= nil;
		local magazine = false;
		if not shell and gun:getMagazineType() then
			magazine = true;
		end
		if magazine and reloadFastMagazines then
			strapFound = true;
		elseif shell and (reloadFastShells or (strap and strap:getClothingItemName() == "AmmoStrap_Shells")) then
			strapFound = true;
		elseif not shell and not magazine and (reloadFastBullets or (strap and strap:getClothingItemName() == "AmmoStrap_Bullets")) then
			strapFound = true;
		end
	end
	if strapFound then
		baseReloadSpeed = baseReloadSpeed * 1.15;
	end
	-- vehicles driver take bit longer to reload their weapon
	if character:getVehicle() and character:getVehicle():getDriver() == character then
		baseReloadSpeed = baseReloadSpeed * 0.8;
	end
	character:setVariable("ReloadSpeed", baseReloadSpeed);
end

-- Add some vars we gonna use, either magazine or the bullets
-- also decide the reload speed
function ISReloadWeaponAction:initVars()
	ISReloadWeaponAction.setReloadSpeed(self.character, false)
	local maxNeeded = self.gun:getMaxAmmo() - self.gun:getCurrentAmmoCount()
	if maxNeeded <= 0 then
		return
	end
	if FWPGetReloadableAmmoCount and FWPGetReloadableAmmoItems then
		local ammoCount = FWPGetReloadableAmmoCount(self.character, self.gun, maxNeeded)
		local bullets = FWPGetReloadableAmmoItems(self.character, self.gun, ammoCount)
		if bullets and not bullets:isEmpty() then
			self.bullets = bullets
			self.ammoCount = ammoCount
		end
		return
	end
	local ammoType = FWPGetAmmoItemKey(self.gun)
	if ammoType then
		local ammoCount = self.character:getInventory():getItemCountRecurse(ammoType)
		ammoCount = math.min(ammoCount, maxNeeded)
		local bullets = self.character:getInventory():getSomeType(FWPGetAmmoItemKey(self.gun), ammoCount)
		if bullets and not bullets:isEmpty() then
			self.bullets = bullets
			self.ammoCount = ammoCount
		end
	end
end

function ISReloadWeaponAction:stop()
	if self.gun:getInsertAmmoStopSound() then
		self.character:playSound(self.gun:getInsertAmmoStopSound());
	end
	self.gun:setJobDelta(0.0)
	-- this should already be cleared from event, but who knows right?
	self.character:clearVariable("isLoading");
	self.character:clearVariable("WeaponReloadType")
	ISBaseTimedAction.stop(self);
end

function ISReloadWeaponAction:perform()
	if self.gun:getInsertAmmoStopSound() then
		self.character:playSound(self.gun:getInsertAmmoStopSound());
	end
	self.gun:setJobDelta(0.0)
	self.character:clearVariable("isLoading");
	self.character:clearVariable("WeaponReloadType")
	ISBaseTimedAction.perform(self);
end

-- Our AnimSet trigger various event, we hook them here. Check LoadHandgun.xml for example.
function ISReloadWeaponAction:animEvent(event, parameter)
	-- Loading clip is done, we're moving to racking if needed
	if event == 'loadFinished' then
		self:loadAmmo();
		local chance = 3;
		local xp = 1;
		if self.character:getPerkLevel(Perks.Reloading) < 5 then
			chance = 1;
			xp = 4;
		end
		if ZombRand(chance) == 0 then
			self.character:getXp():AddXP(Perks.Reloading, xp);
		end
	end
	if event == 'playReloadSound' then
		if parameter == 'load' then
			if self.gun:getInsertAmmoSound() and self.gun:getCurrentAmmoCount() < self.gun:getMaxAmmo() then
				self.character:playSound(self.gun:getInsertAmmoSound());
			end
		elseif parameter == 'insertAmmoStart' then
			if not self.playedInsertAmmoStartSound and self.gun:getInsertAmmoStartSound() then
				self.playedInsertAmmoStartSound = true;
				self.character:playSound(self.gun:getInsertAmmoStartSound());
			end
		end
	end
	if event == 'changeWeaponSprite' then
		if parameter and parameter ~= '' then
			if parameter ~= 'original' then
				self:setOverrideHandModels(parameter, nil)
			else
				self:setOverrideHandModels(self.gun, nil)
			end
		end
	end
end

function ISReloadWeaponAction:loadAmmo()
	-- we insert a new clip only if we're in the motion of loading
	if self.bullets then -- insert bullets one by one
		if not self.bullets:isEmpty() and self.gun:getCurrentAmmoCount() < self.gun:getMaxAmmo() then
			local bullet = self.bullets:get(0);
			self.bullets:remove(bullet);
			self.character:getInventory():Remove(bullet);
			if FWPRecordLoadedAmmo then
				FWPRecordLoadedAmmo(self.gun, bullet, 1)
			end
			self.gun:setCurrentAmmoCount(self.gun:getCurrentAmmoCount() + 1);
		end
		-- fully loaded or no more bullet, we rack
		if self.bullets:isEmpty() or self.gun:getCurrentAmmoCount() >= self.gun:getMaxAmmo() then
			self.character:clearVariable("isLoading");
			-- we rack only if no round is chambered
			------------------------------------------------------------------
			--	HARDCORE RELOADING SECTION by STORMTROOPER
			------------------------------------------------------------------
			if self.gun:haveChamber() and not self.gun:isRoundChambered() then
				ISReloadWeaponAction.addRackingAfter(self, self.character, self.gun);
			end
			------------------------------------------------------------------
			self:forceComplete();
		elseif self.gun:isInsertAllBulletsReload() then
			self:loadAmmo()
		end
	end
end

function ISReloadWeaponAction:ejectSpentRounds()
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

-- if reload is true we remove our current clip if we have one & equip a new one
-- if false we simply just remove the clip or ammos we have in our gun
function ISReloadWeaponAction:new(character, gun)
	local o = ISBaseTimedAction.new(self, character)
	o.stopOnAim = false;
	o.stopOnWalk = false;
	o.stopOnRun = true;
	o.gun = gun;
	o.reloading = true;
	o.maxTime = -1; -- we don't care about time, the anim is controlling the speed/time
	o.useProgressBar = false;
	return o;
end

local function FWPGetAutoMagTypeOption()
	if GUNFIGHTER and GUNFIGHTER.OPTIONS and GUNFIGHTER.OPTIONS.options and GUNFIGHTER.OPTIONS.options.dropdown132 then
		return GUNFIGHTER.OPTIONS.options.dropdown132
	end
	return 1
end

ISReloadWeaponAction.ReloadBestMagazine = function(playerObj, gun)
	local allowTopOff = FWPGetAutoMagTypeOption() <= 1
	local magazine = nil
	if FWPFindCompatibleMagazineForWeapon then
		magazine = FWPFindCompatibleMagazineForWeapon(playerObj, gun, false, false)
		if not magazine then
			magazine = FWPFindCompatibleMagazineForWeapon(playerObj, gun, true, false)
		end
	else
		magazine = gun:getBestMagazine(playerObj)
		if not magazine then
			magazine = playerObj:getInventory():getFirstTypeRecurse(gun:getMagazineType())
		end
	end
	if not magazine then
		return false
	end

	local currentAmmo = 0
	if magazine.getCurrentAmmoCount then
		currentAmmo = magazine:getCurrentAmmoCount()
	end
	local ammoCount = 0
	local shouldLoadMagazine = allowTopOff or currentAmmo <= 0
	if shouldLoadMagazine and currentAmmo < magazine:getMaxAmmo() then
		if FWPTransferReloadableAmmoForAction then
			ammoCount = FWPTransferReloadableAmmoForAction(playerObj, magazine, currentAmmo, magazine:getMaxAmmo())
		else
			local reloadAmmoType = FWPGetSelectedReloadAmmoType and FWPGetSelectedReloadAmmoType(playerObj, magazine) or FWPGetAmmoItemKey(magazine)
			if FWPSetSelectedReloadAmmoType then FWPSetSelectedReloadAmmoType(magazine, reloadAmmoType) end
			ammoCount = ISInventoryPaneContextMenu.transferBullets(playerObj, reloadAmmoType, currentAmmo, magazine:getMaxAmmo())
		end
		ammoCount = tonumber(ammoCount) or 0
	end
	if currentAmmo <= 0 and ammoCount == 0 then
		return false
	end
	if ISInventoryPaneContextMenu.transferIfNeeded then
		ISInventoryPaneContextMenu.transferIfNeeded(playerObj, magazine)
	end
	if ammoCount > 0 then
		ISTimedActionQueue.add(ISLoadBulletsInMagazine:new(playerObj, magazine, ammoCount))
	end
	if FWPPrepareMagazineInsert then
		FWPPrepareMagazineInsert(gun, magazine)
	end
	ISTimedActionQueue.add(ISInsertMagazine:new(playerObj, gun, magazine))
	return true
end

-- Called by ISFirearmRadialMenu.onKeyReleased()
ISReloadWeaponAction.BeginAutomaticReload = function(playerObj, gun)
	local md = gun:getModData()
	local Clip = md and md.ClipType or nil
	local Mag = md and md.MagType or nil
	local currentType = gun:getMagazineType()
	if currentType == nil and Mag ~= nil and Clip == nil then
		gun:setMagazineType(Mag)
		currentType = gun:getMagazineType()
	end

	local hasMagazineTypes = currentType ~= nil
	if not hasMagazineTypes and FWPGetWeaponMagazineTypes then
		hasMagazineTypes = #FWPGetWeaponMagazineTypes(gun, false) > 0
	end

	if hasMagazineTypes then
		local magazine = nil
		if currentType ~= nil and Clip ~= nil and currentType == Clip and FWPFindMagazineByType then
			magazine = FWPFindMagazineByType(playerObj, currentType, false)
		elseif FWPFindCompatibleMagazineForWeapon then
			magazine = FWPFindCompatibleMagazineForWeapon(playerObj, gun, false, false)
		else
			local mags = playerObj:getInventory():getAllTypeRecurse(currentType)
			for i=1,mags:size() do
				local checkmag = mags:get(i-1)
				if checkmag and checkmag:getCurrentAmmoCount() > 0 then
					magazine = checkmag
				end
			end
		end

		local Current = gun:getCurrentAmmoCount()
		local Max = gun:getMaxAmmo()

		if (magazine ~= nil) and (currentType == Clip) and (gun:isContainsClip() or Mag == nil) and (not playerObj:isRunning()) then
			gun:setContainsClip(false)
			gun:getModData().isStripping = true
			ISInventoryPaneContextMenu.transferIfNeeded(playerObj, magazine)
			ISTimedActionQueue.add(ISInsertMagazine:new(playerObj, gun, magazine))
			return
		elseif (magazine ~= nil) and currentType == Clip and not gun:isContainsClip() and Mag ~= nil then
			playerObj:addLineChatElement(getText("ContextMenu_ALTLoad_None").." ("..tostring(Current)..")")
		elseif (gun:isContainsClip()) and currentType ~= Clip then
			ISTimedActionQueue.add(ISEjectMagazine:new(playerObj, gun))
			if ISReloadWeaponAction.stopAfterEject() then
				return
			end
			local nextMagazine = nil
			if FWPFindCompatibleMagazineForWeapon then
				nextMagazine = FWPFindCompatibleMagazineForWeapon(playerObj, gun, false, false)
			else
				local mags = playerObj:getInventory():getAllTypeRecurse(currentType)
				for i=1,mags:size() do
					local checkmag = mags:get(i-1)
					if checkmag and checkmag:getCurrentAmmoCount() > 0 then
						nextMagazine = checkmag
					end
				end
			end
			if nextMagazine then
				ISInventoryPaneContextMenu.transferIfNeeded(playerObj, nextMagazine)
				ISTimedActionQueue.add(ISInsertMagazine:new(playerObj, gun, nextMagazine))
				return
			end
			ISTimedActionQueue.queueActions(playerObj, ISReloadWeaponAction.ReloadBestMagazine, gun)
			return
		elseif (currentType == Clip) and (magazine == nil) and (gun:isContainsClip() or Mag == nil) then
			gun:setMagazineType(nil)
			playerObj:addLineChatElement(getText("ContextMenu_ALTLoad_Single"))
			return
		end

		if gun:getMagazineType() and gun:getMagazineType() ~= Clip then
			local readyMagazine = magazine
			if not readyMagazine and FWPFindCompatibleMagazineForWeapon then
				readyMagazine = FWPFindCompatibleMagazineForWeapon(playerObj, gun, false, false)
			elseif not readyMagazine then
				readyMagazine = gun:getBestMagazine(playerObj)
			end
			if readyMagazine then
				if FWPPrepareMagazineInsert then
					FWPPrepareMagazineInsert(gun, readyMagazine)
				end
				ISInventoryPaneContextMenu.transferIfNeeded(playerObj, readyMagazine)
				ISTimedActionQueue.add(ISInsertMagazine:new(playerObj, gun, readyMagazine))
				return
			else
				if ISReloadWeaponAction.ReloadBestMagazine(playerObj, gun) then
					return
				end
			end
			ISReloadWeaponAction.ReloadBestMagazine(playerObj, gun)
		end
	else
		if gun:getCurrentAmmoCount() >= gun:getMaxAmmo() then
			return
		end
		if gun:isJammed() then
			return
		end
		local ammoCount = 0
		if FWPTransferReloadableAmmoForAction then
			ammoCount = FWPTransferReloadableAmmoForAction(playerObj, gun, gun:getCurrentAmmoCount(), gun:getMaxAmmo())
		else
			local reloadAmmoType = FWPGetSelectedReloadAmmoType and FWPGetSelectedReloadAmmoType(playerObj, gun) or FWPGetAmmoItemKey(gun)
			if FWPSetSelectedReloadAmmoType then FWPSetSelectedReloadAmmoType(gun, reloadAmmoType) end
			ammoCount = ISInventoryPaneContextMenu.transferBullets(playerObj, reloadAmmoType, gun:getCurrentAmmoCount(), gun:getMaxAmmo())
		end
		ammoCount = tonumber(ammoCount) or 0
		if ammoCount == 0 then
			return
		end
		ISTimedActionQueue.add(ISReloadWeaponAction:new(playerObj, gun))
	end
end

-- Called when pressing reload button when not already reloading, only called when you have an equipped weapon to reload (with available bullets or clip)
ISReloadWeaponAction.OnPressReloadButton = function(player, gun)
	if ISReloadWeaponAction.disableReloading then
		return;
	end
	
	----------------------------------
	--	TRY THIS					--
	----------------------------------
	if	player:getModData().emergencyReload == true then
		player:getModData().emergencyReload = false
		DebugSay(3,"Emergency Reload Skip Rack")
		return
	end
	
	-- If you press reloading while loading bullets, we stop and rack
	if player:getVariableBoolean("isLoading") then
		ISTimedActionQueue.clear(player);
		------------------------------------------------------------------
		--	HARDCORE RELOADING SECTION by STORMTROOPER
		------------------------------------------------------------------
		ISReloadWeaponAction.addRacking(player, gun);
		------------------------------------------------------------------
	else
		-- See ISFirearmRadialMenu.onKeyReleased()
	end
-------------------------------------------------------------------------
-- REVERT BACK TO CLIP MODE SEEMS TO WORK HERE
-------------------------------------------------------------------------
	if gun:getMagazineType() == nil and gun:getWeaponReloadType() ~= "revolver" then		-- ALLOW REVOLVER TO STAY IN SINGLE MODE
		local Mag = gun:getModData().MagType
		local Clip = gun:getModData().ClipType
		if 	canUseClip(gun) then
			if Clip ~= nil then
				local clips = player:getInventory():getAllTypeRecurse(Clip)
				for i=1,clips:size() do
					local gotclip = clips:get(i-1)
					if gotclip and gotclip:getCurrentAmmoCount() > 0 then
						DebugSay(2,getText("ContextMenu_ALTLoad_Clip"))
			--			playerObj:addLineChatElement(getText("ContextMenu_ALTLoad_Clip"))
						gun:setMagazineType(Clip)
					--	player:setVariable("WeaponReloadType", "boltaction")
					--	self:forceStop();
						return
					end
				end
			elseif Mag ~= nil then
				local mags = player:getInventory():getAllTypeRecurse(Mag)
				for i=1,mags:size() do
					local gotmag = mags:get(i-1)
					if gotmag and gotmag:getCurrentAmmoCount() > 0 then
						DebugSay(2,getText("ContextMenu_ALTLoad_Mag"))
			--			playerObj:addLineChatElement(getText("ContextMenu_ALTLoad_Mag"))
						gun:setMagazineType(Mag)
					--	player:setVariable("WeaponReloadType", "boltaction")
					--	self:forceStop();
						return
					end
				end
			end
		end
	end
end	

-- Called when pressing rack (if you rack while having a clip/bullets, we simply remove it and don't reload a new one)
ISReloadWeaponAction.OnPressRackButton = function(player, gun)
	if ISReloadWeaponAction.disableReloading then
		return;
	end
	if not ISReloadWeaponAction.canRack(gun) then
		return;
	end
	-- if you press rack while loading bullets, we stop and rack
	if player:getVariableBoolean("isLoading") and not gun:isRoundChambered() then
		ISTimedActionQueue.clear(player);
	end
--------------------------------------------------------------------------
--  CHANGE WeaponReloadType ANIMATION.... DONT WORK, TRY IN ONRACK	--
--------------------------------------------------------------------------
	local	Clip = gun:getModData().ClipType
	local	Mag = gun:getModData().MagType
	if gun:getMagazineType() == Clip then
		player:setVariable("WeaponReloadType", "boltactionnomag")
	end
	ISTimedActionQueue.add(ISRackFirearm:new(player, gun));
end

ISReloadWeaponAction.canShoot = function(player, weapon)
	if weapon == nil then
		weapon = player
		player = nil
	end
	if weapon == nil then
		return false
	end
	if player ~= nil then
		local okUnlimited, unlimited = pcall(function() return player:isUnlimitedAmmo() end)
		if okUnlimited and unlimited then
			return true
		end
	end
	if getDebug() and getDebugOptions():getBoolean("Cheat.Player.UnlimitedAmmo") then
		return true;
	end
	if weapon:isJammed() then
		return false;
	end
	if weapon:haveChamber() and not weapon:isRoundChambered() then
		return false;
	end
	if not weapon:haveChamber() and weapon:getCurrentAmmoCount() <= 0 then
		return false;
	end
	return true;
end

local FWP_B42_ARCHERY_WEAPONS = {
	BowTechSR_350 = true,
	HoytSpectra_1000 = true,
	Genesis_X_Bow = true,
	Genesis_Bow = true,
	Genesis_Mini_Bow = true,
	HZRedback_RTS = true,
	TenPointVaporRS_470 = true,
	MissionMXB_400 = true,
	TenPointTurbo_XLT = true,
	TAC15 = true,
	HortonScout_125 = true,
	SlingShot_Rock = true,
	SlingShot_Marble = true,
	WristRocket_Rock = true,
	WristRocket_Marble = true,
}

local function FWPIsB42ArcheryWeapon(weapon)
	if not weapon then
		return false
	end
	local okType, itemType = pcall(function() return weapon:getType() end)
	if okType and itemType and FWP_B42_ARCHERY_WEAPONS[tostring(itemType)] then
		return true
	end
	if weapon.getFullType then
		local okFull, fullType = pcall(function() return weapon:getFullType() end)
		if okFull and fullType then
			local shortType = tostring(fullType):match("([^.]+)$")
			if shortType and FWP_B42_ARCHERY_WEAPONS[shortType] then
				return true
			end
		end
	end
	return false
end

local function FWPCanShootB42Archery(character, weapon)
	if not weapon then
		return false
	end
	if character and character.isUnlimitedAmmo then
		local okUnlimited, unlimited = pcall(function() return character:isUnlimitedAmmo() end)
		if okUnlimited and unlimited then
			return true
		end
	end
	if weapon.isJammed and weapon:isJammed() then
		return false
	end
	local ammoCount = 0
	if weapon.getCurrentAmmoCount then
		local okAmmo, value = pcall(function() return weapon:getCurrentAmmoCount() end)
		if okAmmo and tonumber(value) then
			ammoCount = tonumber(value)
		end
	end
	if ammoCount > 0 then
		return true
	end
	if weapon.haveChamber and weapon.isRoundChambered and weapon:haveChamber() and weapon:isRoundChambered() then
		return true
	end
	return false
end

local FWP_B42_LAUNCHER_AMMO_ITEMS = {
	["Base.40HERound"] = true,
	["Base.40INCRound"] = true,
	["Base.HERocket"] = true,
	["base.40heround"] = true,
	["base.40incround"] = true,
	["base.herocket"] = true,
}

local function FWPIsB42LauncherRuntimeWeapon(weapon)
	if not weapon then
		return false
	end
	local ammoItem = nil
	if FWPGetAmmoItemKey then
		local okAmmo, resolvedAmmo = pcall(function() return FWPGetAmmoItemKey(weapon) end)
		if okAmmo then
			ammoItem = resolvedAmmo
		end
	elseif weapon.getAmmoType then
		local okAmmo, resolvedAmmo = pcall(function() return weapon:getAmmoType() end)
		if okAmmo then
			ammoItem = resolvedAmmo
		end
	end
	local ammoText = ammoItem and tostring(ammoItem) or nil
	if ammoText and (FWP_B42_LAUNCHER_AMMO_ITEMS[ammoText] or FWP_B42_LAUNCHER_AMMO_ITEMS[string.lower(ammoText)]) then
		return true
	end
	return false
end

local function FWPCanShootB42LauncherRuntime(character, weapon)
	if not weapon then
		return false
	end
	if character and character.isUnlimitedAmmo then
		local okUnlimited, unlimited = pcall(function() return character:isUnlimitedAmmo() end)
		if okUnlimited and unlimited then
			return true
		end
	end
	if weapon.isJammed and weapon:isJammed() then
		return false
	end
	local ammoCount = 0
	if weapon.getCurrentAmmoCount then
		local okAmmo, value = pcall(function() return weapon:getCurrentAmmoCount() end)
		if okAmmo and tonumber(value) then
			ammoCount = tonumber(value)
		end
	end
	if ammoCount > 0 then
		return true
	end
	if weapon.haveChamber and weapon.isRoundChambered and weapon:haveChamber() and weapon:isRoundChambered() then
		return true
	end
	return false
end

local function FWPIsB42ShotgunWeapon(weapon)
	if not weapon then
		return false
	end
	if not isShotgun then
		return false
	end
	local ok, result = pcall(isShotgun, weapon)
	return ok and result == true
end

local function FWPIsB42FlameFuelWeapon(weapon)
	if not (weapon and weapon.isRanged and weapon:isRanged()) then
		return false
	end
	if FWPGetAmmoItemKey then
		local ammoItem = FWPGetAmmoItemKey(weapon)
		if ammoItem == "Base.FlameFuel" then
			return true
		end
	end
	if weapon.getFullType then
		local fullType = weapon:getFullType()
		if fullType == "Base.WD_Flame" or fullType == "Base.Musk" or fullType == "Base.M2A1" then
			return true
		end
	end
	return false
end

local function FWPHasUnlimitedAmmo(player)
	if getDebug and getDebugOptions and getDebug() and getDebugOptions():getBoolean("Cheat.Player.UnlimitedAmmo") then
		return true
	end
	if player and player.isUnlimitedAmmo then
		local ok, unlimited = pcall(function() return player:isUnlimitedAmmo() end)
		return ok and unlimited == true
	end
	return false
end

local function FWPMarkB42FirePending(weapon)
	if not (weapon and weapon.isRanged and weapon:isRanged()) then
		return
	end
	if weapon.getModData then
		local md = weapon:getModData()
		md.FWP_B42FirePending = true
		md.FWP_B42PendingAmmoEffect = FWPPeekAmmoEffectType and FWPPeekAmmoEffectType(weapon) or nil
		if weapon.getCurrentAmmoCount then
			local okAmmo, ammoCount = pcall(function() return weapon:getCurrentAmmoCount() end)
			md.FWP_B42AmmoBefore = okAmmo and tonumber(ammoCount) or nil
		else
			md.FWP_B42AmmoBefore = nil
		end
	end
end

local function FWPClearB42FirePending(weapon)
	if weapon and weapon.getModData then
		local md = weapon:getModData()
		md.FWP_B42FirePending = nil
		md.FWP_B42AmmoBefore = nil
		md.FWP_B42PendingAmmoEffect = nil
		md.FWP_B42SyntheticChamber = nil
	end
end

local function FWPGetB42AmmoCount(weapon)
	if weapon and weapon.getCurrentAmmoCount then
		local okAmmo, ammoCount = pcall(function() return weapon:getCurrentAmmoCount() end)
		if okAmmo and tonumber(ammoCount) then
			return tonumber(ammoCount)
		end
	end
	return 0
end

local function FWPCanShootB42FlameFuelWeapon(player, weapon)
	if not FWPIsB42FlameFuelWeapon(weapon) then
		return false
	end
	if FWPHasUnlimitedAmmo(player) then
		return true
	end
	if weapon.isJammed and weapon:isJammed() then
		return false
	end
	return FWPGetB42AmmoCount(weapon) > 0
end

local FWP_B42_FLAME_FUEL_PER_BURST = 5
local FWP_B42_FLAME_MIN_INTERVAL_MS = 1000

local function FWPGetB42TimestampMs()
	if getTimestampMs then
		local value = getTimestampMs()
		if tonumber(value) then
			return tonumber(value)
		end
	end
	return math.floor((os.clock and os.clock() or 0) * 1000)
end

local function FWPDebugB42Flame(weapon, message, force)
	local now = FWPGetB42TimestampMs()
	local md = weapon and weapon.getModData and weapon:getModData() or nil
	if (not force) and md and md.FWP_B42FlameDebugLastMs and (now - tonumber(md.FWP_B42FlameDebugLastMs)) < 2000 then
		return
	end
	if md then
		md.FWP_B42FlameDebugLastMs = now
	end
	print("[FWP FLAME] " .. tostring(message))
end

local function FWPEnsureB42ShotgunChamberForTrigger(weapon)
	if not FWPIsB42ShotgunWeapon(weapon) then
		return
	end
	if weapon.isRackAfterShoot and weapon:isRackAfterShoot() then
		return
	end
	if weapon.haveChamber and weapon.isRoundChambered and weapon.setRoundChambered and weapon:haveChamber() and not weapon:isRoundChambered() and FWPGetB42AmmoCount(weapon) > 0 then
		weapon:setRoundChambered(true)
		if weapon.setSpentRoundChambered then
			weapon:setSpentRoundChambered(false)
		end
		if weapon.getModData then
			weapon:getModData().FWP_B42SyntheticChamber = true
		end
	end
end

local function FWPGetB42AmmoPerShoot(weapon)
	if weapon and weapon.getAmmoPerShoot then
		local okAmmo, ammoPerShoot = pcall(function() return weapon:getAmmoPerShoot() end)
		if okAmmo and tonumber(ammoPerShoot) and tonumber(ammoPerShoot) > 0 then
			return tonumber(ammoPerShoot)
		end
	end
	return 1
end

local function FWPClampB42ShotgunFireMode(weapon)
	if not FWPIsB42ShotgunWeapon(weapon) then
		return
	end
	if weapon.setFireMode then
		pcall(function() weapon:setFireMode("Single") end)
	end
	if weapon.setFireModePossibilities and ArrayList then
		pcall(function()
			local list = ArrayList.new()
			list:add("Single")
			weapon:setFireModePossibilities(list)
		end)
	end
	if weapon.getModData then
		weapon:getModData().TriggerType = 1
	end
end

local function FWPCanShootB42Shotgun(player, weapon)
	if not FWPIsB42ShotgunWeapon(weapon) then
		return false
	end
	FWPClampB42ShotgunFireMode(weapon)
	if FWPHasUnlimitedAmmo(player) then
		return true
	end
	if weapon.isJammed and weapon:isJammed() then
		return false
	end
	FWPEnsureB42ShotgunChamberForTrigger(weapon)
	if weapon.haveChamber and weapon.isRoundChambered and weapon:haveChamber() and weapon:isRoundChambered() then
		return true
	end
	return FWPGetB42AmmoCount(weapon) > 0
end

local function FWPIsLegacyB42BurstMode(mode)
	local text = tostring(mode or "")
	return text:find("Burst", 1, true) ~= nil or text:find("[2]", 1, true) ~= nil or text:find("[3]", 1, true) ~= nil or text:find("H2", 1, true) ~= nil or text:find("H3", 1, true) ~= nil or text:find("L2", 1, true) ~= nil or text:find("L3", 1, true) ~= nil
end

local function FWPIsAutoFireMode(mode)
	return tostring(mode or ""):find("Auto", 1, true) ~= nil
end

local function FWPSetB42SafeFireModes(weapon, hasAuto)
	if not weapon then
		return
	end
	if weapon.setFireModePossibilities and ArrayList then
		pcall(function()
			local list = ArrayList.new()
			list:add("Single")
			if hasAuto then
				list:add("Auto")
			end
			weapon:setFireModePossibilities(list)
		end)
	end
	local currentMode = weapon.getFireMode and tostring(weapon:getFireMode() or "") or ""
	if weapon.setFireMode then
		if hasAuto and FWPIsAutoFireMode(currentMode) then
			pcall(function() weapon:setFireMode("Auto") end)
		else
			pcall(function() weapon:setFireMode("Single") end)
		end
	end
	if weapon.getModData then
		weapon:getModData().TriggerType = hasAuto and 5 or 1
	end
end

local function FWPNormalizeB42LegacyFireMode(weapon)
	if not (weapon and weapon.isRanged and weapon:isRanged()) then
		return
	end
	if FWPIsB42ShotgunWeapon(weapon) then
		FWPClampB42ShotgunFireMode(weapon)
		return
	end

	local hasLegacyBurst = false
	local hasAuto = false
	local md = weapon.getModData and weapon:getModData() or nil
	local triggerType = md and tonumber(md.TriggerType) or nil
	if triggerType == 3 or triggerType == 4 or triggerType == 6 or triggerType == 7 then
		hasLegacyBurst = true
		if triggerType == 6 or triggerType == 7 then
			hasAuto = true
		end
	end
	local currentMode = weapon.getFireMode and tostring(weapon:getFireMode() or "") or ""
	if FWPIsLegacyB42BurstMode(currentMode) then
		hasLegacyBurst = true
	end
	if FWPIsAutoFireMode(currentMode) then
		hasAuto = true
	end

	local modes = weapon.getFireModePossibilities and weapon:getFireModePossibilities() or nil
	if modes then
		for i = 0, modes:size() - 1 do
			local mode = tostring(modes:get(i) or "")
			if FWPIsLegacyB42BurstMode(mode) then
				hasLegacyBurst = true
			end
			if FWPIsAutoFireMode(mode) then
				hasAuto = true
			end
		end
	end

	if hasLegacyBurst then
		FWPSetB42SafeFireModes(weapon, hasAuto)
	end
end

local function FWPIsWeaponSuppressed(weapon)
	if not isSuppressed then
		return false
	end
	local okSuppressed, suppressed = pcall(isSuppressed, weapon)
	return okSuppressed and suppressed == true
end

local function FWPIsB42BBGunLegacy(weapon)
	if type(isBBGun) ~= "function" then
		return false
	end
	local ok, result = pcall(isBBGun, weapon)
	return ok and result == true
end

local function FWPIsB42FlamerLegacy(weapon)
	if type(isFlamer) ~= "function" then
		return false
	end
	local ok, result = pcall(isFlamer, weapon)
	return ok and result == true
end

local function FWPIsB42BowLegacy(weapon)
	if type(isBow) ~= "function" then
		return false
	end
	local ok, result = pcall(isBow, weapon)
	return ok and result == true
end

local function FWPStartB42MuzzleFlash(character)
	if character and character.startMuzzleFlash then
		pcall(character.startMuzzleFlash, character)
	end
end

local function FWPGetB42SuppressFactor(weapon)
	if not getSuppressFactor then
		return nil
	end
	local okFactor, factor = pcall(getSuppressFactor, weapon)
	if okFactor and tonumber(factor) then
		return tonumber(factor)
	end
	return nil
end

local function FWPResolveB42ShotSound(weapon)
	local shotSound = nil
	if getShotSound then
		local okSound, valueSound = pcall(getShotSound, weapon)
		if okSound and valueSound ~= nil then
			shotSound = tostring(valueSound)
		end
	end
	if (shotSound == nil or shotSound == "" or shotSound == "null" or shotSound == "nil") and weapon and weapon.getSwingSound then
		local okSwing, swingSound = pcall(function()
			return weapon:getSwingSound()
		end)
		if okSwing and swingSound ~= nil then
			shotSound = tostring(swingSound)
		end
	end
	if shotSound == nil or shotSound == "" or shotSound == "null" or shotSound == "nil" then
		return "???"
	end
	return shotSound
end

local function FWPApplyB42FlamethrowerBurst(player, weapon)
	if not (player and weapon and FWPIsB42FlameFuelWeapon(weapon)) then
		return false
	end
	if weapon.isJammed and weapon:isJammed() then
		FWPDebugB42Flame(weapon, "blocked: weapon is jammed")
		return false
	end

	local md = weapon.getModData and weapon:getModData() or nil
	local now = FWPGetB42TimestampMs()
	if md and md.FWP_B42FlameBurstLastMs and (now - tonumber(md.FWP_B42FlameBurstLastMs)) < FWP_B42_FLAME_MIN_INTERVAL_MS then
		return true
	end

	local currentAmmo = FWPGetB42AmmoCount(weapon)
	local unlimited = FWPHasUnlimitedAmmo(player)
	if not unlimited and currentAmmo <= 0 then
		local magazineType = weapon.getMagazineType and tostring(weapon:getMagazineType() or "nil") or "nil"
		local containsClip = weapon.isContainsClip and tostring(weapon:isContainsClip()) or "nil"
		FWPDebugB42Flame(weapon, "blocked: no fuel in weapon ammo count; magazineType=" .. magazineType .. " containsClip=" .. containsClip)
		return false
	end

	local fuelSpent = FWP_B42_FLAME_FUEL_PER_BURST
	local serverAuthoritative = isClient and isClient()
	if not unlimited then
		fuelSpent = math.min(FWP_B42_FLAME_FUEL_PER_BURST, currentAmmo)
		if (not serverAuthoritative) and weapon.setCurrentAmmoCount then
			weapon:setCurrentAmmoCount(math.max(0, currentAmmo - fuelSpent))
		end
	end

	if md then
		md.FWP_B42FlameBurstLastMs = now
		md.FWP_LastFiredAmmoType = "Base.FlameFuel"
		md.FWP_B42FirePending = nil
		md.FWP_B42AmmoBefore = nil
		md.FWP_B42PendingAmmoEffect = nil
	end

	local sound = FWPResolveB42ShotSound(weapon)
	if sound == "???" and weapon.getSwingSound then
		sound = weapon:getSwingSound()
	end
	if sound == nil or sound == "" or sound == "???" then
		sound = "Flame_Fire"
	end
	player:playSound(sound)

	if player.addWorldSoundUnlessInvisible then
		local radius = weapon.getSoundRadius and weapon:getSoundRadius() or 10
		local volume = weapon.getSoundVolume and weapon:getSoundVolume() or 10
		player:addWorldSoundUnlessInvisible(radius, volume, true)
	end

	if FWPOnFlameFuelBurst then
		FWPDebugB42Flame(weapon, "burst: fuelSpent=" .. tostring(fuelSpent) .. " ammoBefore=" .. tostring(currentAmmo) .. " serverAuthoritative=" .. tostring(serverAuthoritative))
		FWPOnFlameFuelBurst(player, weapon, fuelSpent, serverAuthoritative)
	elseif FWPOnAmmoEffectFired then
		FWPDebugB42Flame(weapon, "burst: using ammo-effect fallback fuelSpent=" .. tostring(fuelSpent) .. " ammoBefore=" .. tostring(currentAmmo) .. " serverAuthoritative=" .. tostring(serverAuthoritative))
		FWPOnAmmoEffectFired(player, weapon, "Base.FlameFuel")
	else
		FWPDebugB42Flame(weapon, "blocked: no flame ammo runtime registered")
	end
	if weapon.transmitModData then
		weapon:transmitModData()
	end
	if (not serverAuthoritative) and syncHandWeaponFields then
		syncHandWeaponFields(player, weapon)
	end
	return true
end

local function FWPApplyB42ShotAmmo(player, weapon)
	if not (weapon and weapon.isRanged and weapon:isRanged()) then
		return false
	end
	if FWPHasUnlimitedAmmo(player) then
		local firedAmmoType = weapon.getModData and weapon:getModData().FWP_B42PendingAmmoEffect or nil
		if firedAmmoType == nil and FWPPeekAmmoEffectType then
			firedAmmoType = FWPPeekAmmoEffectType(weapon)
		end
		if weapon.getModData then
			local md = weapon:getModData()
			md.FWP_LastFiredAmmoType = firedAmmoType
			md.FWP_B42PendingAmmoEffect = nil
		end
		if FWPOnAmmoEffectFired then
			FWPOnAmmoEffectFired(player, weapon, firedAmmoType)
		end
		FWPClearB42FirePending(weapon)
		return false
	end

	local ammoPerShoot = FWPGetB42AmmoPerShoot(weapon)
	local currentAmmo = FWPGetB42AmmoCount(weapon)
	local rackAfterShoot = weapon.isRackAfterShoot and weapon:isRackAfterShoot()
	local haveChamber = weapon.haveChamber and weapon:haveChamber()
	local md = weapon.getModData and weapon:getModData() or nil
	local pendingAmmoEffect = md and md.FWP_B42PendingAmmoEffect or nil
	local syntheticChamber = md and md.FWP_B42SyntheticChamber == true
	local roundChamberedBefore = haveChamber and weapon.isRoundChambered and weapon:isRoundChambered()
	local consumedCurrentAmmo = false
	local firedShot = false
	if md then
		md.FWP_B42SyntheticChamber = nil
	end

	if weapon:haveChamber() then
		weapon:setRoundChambered(false);
		weapon:setSpentRoundChambered(true)
	end
	local shouldConsumeCurrentAmmo = currentAmmo >= ammoPerShoot
	if rackAfterShoot and haveChamber and roundChamberedBefore and not syntheticChamber then
		shouldConsumeCurrentAmmo = false
	end
	if shouldConsumeCurrentAmmo then
		if (not rackAfterShoot) and haveChamber then
			weapon:setRoundChambered(true);
		end
		weapon:setCurrentAmmoCount(currentAmmo - ammoPerShoot)
		consumedCurrentAmmo = true
	end
	if roundChamberedBefore or consumedCurrentAmmo then
		firedShot = true
		local firedAmmoType = FWPConsumeLoadedAmmoForShot and FWPConsumeLoadedAmmoForShot(weapon, pendingAmmoEffect) or pendingAmmoEffect
		if weapon.getModData then
			local md = weapon:getModData()
			md.FWP_LastFiredAmmoType = firedAmmoType
			md.FWP_B42PendingAmmoEffect = nil
		end
		if FWPOnAmmoEffectFired then
			FWPOnAmmoEffectFired(player, weapon, firedAmmoType)
		end
		if (weapon:getJamGunChance() > 0) then
			weapon:checkJam(player, false)
		end
	end

	if rackAfterShoot then
		if weapon.getModData then
			local md = weapon:getModData()
			md.FWP_RackAfterShotSpent = true
			md.FWP_RackAfterShotAmmoConsumed = consumedCurrentAmmo
		end
		if player and player.getModData then
			player:getModData().DelayAction = 60
			player:getModData().CycleAction = player:getModData().DelayAction + 20
		end
	else
		if not weapon:isManuallyRemoveSpentRounds() then
			weapon:setSpentRoundChambered(false)
			if player and weapon:getShellFallSound() then
				player:getEmitter():playSound(weapon:getShellFallSound())
			end
		end
	end
	if weapon:isManuallyRemoveSpentRounds() then
		weapon:setSpentRoundCount(weapon:getSpentRoundCount() + ammoPerShoot)
	end

	if syncHandWeaponFields then
		syncHandWeaponFields(player, weapon)
	end
	return firedShot
end

local function FWPApplyPendingB42Fire(player, weapon)
	local md = weapon and weapon.getModData and weapon:getModData() or nil
	if not (md and md.FWP_B42FirePending == true) then
		return false
	end
	md.FWP_B42FirePending = nil
	local ammoBefore = tonumber(md.FWP_B42AmmoBefore)
	md.FWP_B42AmmoBefore = nil
	if ammoBefore and FWPGetB42AmmoCount(weapon) < ammoBefore then
		md.FWP_B42SyntheticChamber = nil
		if weapon and weapon.isRackAfterShoot and weapon:isRackAfterShoot() and weapon.getModData then
			md.FWP_RackAfterShotSpent = true
			md.FWP_RackAfterShotAmmoConsumed = true
		end
		local firedAmmoType = FWPConsumeLoadedAmmoForShot and FWPConsumeLoadedAmmoForShot(weapon, md.FWP_B42PendingAmmoEffect) or md.FWP_B42PendingAmmoEffect
		md.FWP_LastFiredAmmoType = firedAmmoType
		md.FWP_B42PendingAmmoEffect = nil
		if FWPOnAmmoEffectFired then
			FWPOnAmmoEffectFired(player, weapon, firedAmmoType)
		end
		return false
	end
	return FWPApplyB42ShotAmmo(player, weapon)
end

-- can we attack?
-- need a chambered round
ISReloadWeaponAction.attackHook = function(character, chargeDelta, weapon)
	ISTimedActionQueue.clear(character)
	if not weapon then return; end
	if character:isAttackStarted() then return; end
	local fwpArcheryWeapon = FWPIsB42ArcheryWeapon(weapon)
	local fwpLauncherWeapon = FWPIsB42LauncherRuntimeWeapon(weapon)
	local fwpShotgunWeapon = FWPIsB42ShotgunWeapon(weapon)
	local fwpFlameFuelWeapon = FWPIsB42FlameFuelWeapon(weapon)
	if instanceof(character, "IsoPlayer") and not character:isAuthorizeMeleeAction() and not fwpArcheryWeapon and not fwpLauncherWeapon and not fwpFlameFuelWeapon then
		return;
	end
	if weapon:isRanged() and not character:isDoShove() then
		FWPNormalizeB42LegacyFireMode(weapon)
		local canShoot = false
		if fwpArcheryWeapon then
			canShoot = FWPCanShootB42Archery(character, weapon)
		elseif fwpLauncherWeapon then
			canShoot = FWPCanShootB42LauncherRuntime(character, weapon)
		elseif fwpShotgunWeapon then
			canShoot = FWPCanShootB42Shotgun(character, weapon) and ISReloadWeaponAction.canFireSemi()
		elseif fwpFlameFuelWeapon then
			canShoot = FWPCanShootB42FlameFuelWeapon(character, weapon)
		else
			canShoot = ISReloadWeaponAction.canShoot(character, weapon) and ISReloadWeaponAction.canFireSemi()
		end

		if canShoot and fwpFlameFuelWeapon then
			FWPApplyB42FlamethrowerBurst(character, weapon)
			return
		end

		if canShoot then
			if (not fwpArcheryWeapon) and (not fwpLauncherWeapon) then
				local fireMode = weapon:getFireMode()
				if not fireMode or (fireMode ~= "Auto" and fireMode ~= "Auto[H]" and fireMode ~= "Auto[L]" and fireMode ~= "[6]Rotary") then
					ISReloadWeaponAction.noLongerCanFire();
				end

				local shotSound = FWPResolveB42ShotSound(weapon)
				local attackLoop = (shotSound or "???").."FullAuto"
				local fireModeText = weapon:getFireMode()
				if (fireModeText == "Auto" or fireModeText == "Auto[H]" or fireModeText == "Auto[L]" or fireModeText == "[6]Rotary") and (getScriptManager():getGameSound(attackLoop) ~= nil) then
					if not character:isPlayingAttackLoopSound(attackLoop) then
						character:startAttackLoopSound(attackLoop);
					end
				else
					character:playRangedWeaponShootSound(shotSound);
				end

				local radius = weapon:getSoundRadius();
				local volume = weapon:getSoundVolume();
				local suppressed = FWPIsWeaponSuppressed(weapon)
				if getSandboxOptions and getSandboxOptions():getOptionByName("FirearmNoiseMultiplier") then
					radius = radius * getSandboxOptions():getOptionByName("FirearmNoiseMultiplier"):getValue();
				end
				if not character:isOutside() then
					radius = radius * 0.5
				end
				if suppressed then
					local suppressFactor = FWPGetB42SuppressFactor(weapon)
					if suppressFactor and suppressFactor > 0 then
						radius = radius * suppressFactor
						volume = math.max(1, volume * suppressFactor)
					end
				end
				character:addWorldSoundUnlessInvisible(radius, volume, true);
				FWPMarkB42FirePending(weapon)
				if (not suppressed) and (not FWPIsB42BBGunLegacy(weapon)) and (not FWPIsB42FlamerLegacy(weapon)) then
					FWPStartB42MuzzleFlash(character)
				end
				character:DoAttack(0);
			else
				if not weapon:getFireMode() or weapon:getFireMode() == "Single" then
					ISReloadWeaponAction.noLongerCanFire();
				end
				character:playSound(weapon:getSwingSound());
				local radius = weapon:getSoundRadius();
				character:addWorldSoundUnlessInvisible(radius, weapon:getSoundVolume(), false);
				if (not FWPIsWeaponSuppressed(weapon)) and (not FWPIsB42BowLegacy(weapon)) and (not FWPIsB42BBGunLegacy(weapon)) and (not FWPIsB42FlamerLegacy(weapon)) then
					FWPStartB42MuzzleFlash(character)
				else
					DebugSay(3,"No Muzzle Flash...")
				end
				FWPMarkB42FirePending(weapon)
				character:DoAttack(0);
			end
		elseif fwpFlameFuelWeapon then
			character:DoAttack(0);
			character:setRangedWeaponEmpty(true);
		elseif ISReloadWeaponAction.canFireSemi() then
			ISReloadWeaponAction.noLongerCanFire();
			character:DoAttack(0);
			character:setRangedWeaponEmpty(true);
		end
	elseif (not character:getVehicle() or character:isDoShove()) then
		ISTimedActionQueue.clear(character)
		if(chargeDelta == nil) then
			character:DoAttack(0);
		else
			character:DoAttack(chargeDelta);
		end
	end
end

-- shoot shoot bang bang
-- B42 can call this once per hit/projectile, so ammo is guarded at attack-finished instead.
ISReloadWeaponAction.onShoot = function(player, weapon)
	if not weapon or not weapon.isRanged or not weapon:isRanged() then return; end
end

local function FWPB42ShotgunPlayerUpdate(player)
	if not player or not player.getPrimaryHandItem then
		return
	end
	local weapon = player:getPrimaryHandItem()
	if weapon and weapon.isRanged and weapon:isRanged() and FWPIsB42ShotgunWeapon(weapon) then
		FWPClampB42ShotgunFireMode(weapon)
	end
end

local function FWPIsB42FlameTriggerDown(player)
	local joypad = -1
	if player and player.getJoypadBind then
		joypad = player:getJoypadBind()
	end
	if joypad ~= nil and joypad ~= -1 and isJoypadRTPressed then
		return isJoypadRTPressed(joypad) == true
	end
	if isMouseButtonDown then
		return isMouseButtonDown(0) == true
	end
	return false
end

local function FWPB42FlamethrowerPlayerUpdate(player)
	if not (player and player.getPrimaryHandItem) then
		return
	end
	if player.isDead and player:isDead() then
		return
	end
	if player.isAiming and not player:isAiming() then
		return
	end
	if not FWPIsB42FlameTriggerDown(player) then
		return
	end
	local weapon = player:getPrimaryHandItem()
	if not FWPIsB42FlameFuelWeapon(weapon) then
		return
	end
	FWPApplyB42FlamethrowerBurst(player, weapon)
end

Events.OnPlayerUpdate.Add(FWPB42ShotgunPlayerUpdate)
Events.OnPlayerUpdate.Add(FWPB42FlamethrowerPlayerUpdate)
ISReloadWeaponAction.OnPlayerAttackFinished = function(playerObj, weapon)
	if not playerObj or playerObj:isDead() then return end
	if FWPHasUnlimitedAmmo(playerObj) then
		if weapon and weapon:isRanged() then
			FWPApplyPendingB42Fire(playerObj, weapon)
		end
		return;
	end
	if weapon and weapon:isRanged() then
		FWPApplyPendingB42Fire(playerObj, weapon)
	end
	if weapon and weapon:isRanged() and weapon:isRackAfterShoot() then
		------------------------------------------------------------------
		--	HARDCORE RELOADING SECTION by STORMTROOPER
		------------------------------------------------------------------
		ISReloadWeaponAction.addRacking(playerObj, weapon);
		------------------------------------------------------------------
	end
end

local function FWPRemovePreviousEventHandler(event, handler)
	if event and handler and event.Remove then
		pcall(event.Remove, handler)
	end
end

FWPRemovePreviousEventHandler(Events.OnPressReloadButton, FWPPreviousOnPressReloadButton)
FWPRemovePreviousEventHandler(Events.OnPressRackButton, FWPPreviousOnPressRackButton)
FWPRemovePreviousEventHandler(Events.OnWeaponSwingHitPoint, FWPPreviousOnShoot)
FWPRemovePreviousEventHandler(Events.OnPlayerAttackFinished, FWPPreviousOnPlayerAttackFinished)
if Hook and Hook.Attack and Hook.Attack.Remove and FWPPreviousAttackHook then
	pcall(Hook.Attack.Remove, FWPPreviousAttackHook)
end

Events.OnPressReloadButton.Add(ISReloadWeaponAction.OnPressReloadButton);
Events.OnPressRackButton.Add(ISReloadWeaponAction.OnPressRackButton);
Events.OnWeaponSwingHitPoint.Add(ISReloadWeaponAction.onShoot);
Events.OnPlayerAttackFinished.Add(ISReloadWeaponAction.OnPlayerAttackFinished);
Hook.Attack.Add(ISReloadWeaponAction.attackHook);



---------------------------------- PREVENT INSERT FROM INVENTORY CONTEXT MENUS --------------------------------------
ISInventoryPaneContextMenu.onInsertMagazine = function(playerObj, weapon, magazine)
	local	Clip = weapon:getModData().ClipType
	local	Mag = weapon:getModData().MagType
	if 	Clip == nil or weapon:getMagazineType() ~= Clip then
		ISInventoryPaneContextMenu.transferIfNeeded(playerObj, magazine)
		ISInventoryPaneContextMenu.equipWeapon(weapon, true, false, playerObj:getPlayerNum())
		ISTimedActionQueue.add(ISInsertMagazine:new(playerObj, weapon, magazine));
	end
end
