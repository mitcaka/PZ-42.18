--[[ 	[Apply_Effect] handles the effects of Bayonets and Suppressors since migrating to the Vanilla
	Attachment method. Nullifies Scope range bonus while in melee mode. Handles Suppressor Effectiveness
	OPTION, and applies junkfactor to make improvised suppressors LESS effective. Applies visual Magazine
	function by assigning "Clip" slot with appropriate magazine type.

	MOST TRANSFORM FUNCTIONS ARE OBSOLETE WITH HOTKEYS, BUT REMAIN JUST IN CASE.

	***** ARSENAL[26] *****
]]

------------------------------------------------------------------
--  [CHARGE WEAPON LIGHT]										--
------------------------------------------------------------------
function Charge_Weapon_Light(items, result, player)
	local	batt = nil
	local	part = nil
	local	chargePART = 0
	local	chargeBATT = 0
	local	chargeNEED = 0

	for i=0,items:size() - 1 do
		local item = items:get(i)
		if (item ~= nil) then
			if 	item:getType() == "Battery" then
				if	round(item:getUsedDelta() * 100,1) > chargeBATT then		-- TIMES 100 TO COMPARE SAME SCALE
					batt = item
					chargeBATT = round(item:getUsedDelta() * 100,1)				-- 70
					DebugSay(2,getText("ContextMenu_FindBattery").."..."..tostring(chargeBATT))
				end				
			else part = item
			end
		end
	end

	if	result:getModData().Charge == nil then
		result:getModData().Charge = 0
	end
	
	if	part:getModData().Charge == nil then
		part:getModData().Charge = 0
	end

	if	batt ~= nil and part ~= nil then				-- HAS BATTERY
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

		result:getModData().Charge = chargePART
		batt:setUsedDelta(chargeLEFT / 100)
		DebugSay(2,getText("ContextMenu_Device").." (+"..tostring(chargeUSED).."/"..tostring(chargePART)..") "..getText("ContextMenu_Battery").." ("..tostring(chargeLEFT)..")")
	else DebugSay(2,getText("ContextMenu_NoBattery"))		-- NO BATTERY
	end
end


--------------------------------------------------
--  [CONVERT TRIGGER-GROUP]						--
--	Type 1	Semi Only							--
--	Type 2	Auto Only							--
--	Type 3	Semi / [2]Burst						--
--	Type 4	Semi / [3]Burst						--
--	Type 5	Semi / Auto							--
--	Type 6	Semi / [2]Burst / Auto				--
--	Type 7	Semi / [3]Burst / Auto				--
--	SHOULD WE EXPAND [L] [H] FIREMODE TYPES ?	--
--------------------------------------------------
function Install_Intermediate_TriggerGroup(items, result, player)
	local Gun		= nil		-- KEPT GUN
	local Part		= nil		-- NEW TRIGGER GROUP
	local Single	= nil
	local Auto		= nil
	local Burst2	= nil
	local Burst3	= nil
	local Type		= nil
	local Tool		= nil
--	local oldType	= nil
	
	if items then
		for i=0, items:size()-1 do
			local item = items:get(i)
			if	(item ~= nil) then
				if		item:hasTag(FWPGetItemTag("TriggerGroup")) then
						Part = item
				--		DebugSay(2,"PART..."..tostring(item:getDisplayName()))
				elseif	item:isAimedFirearm() then
						Gun = item
				--		DebugSay(2,"GUN..."..tostring(item:getDisplayName()))
				else	Tool = item
						result:setCondition(Tool:getCondition())
				--		DebugSay(2,"TOOL..."..tostring(item:getDisplayName()))
				end
			end
		end
	end

--[[
	----------------------------------------------
	--	GET CURRENT MODES FOR OLD TRIGGER		--
	----------------------------------------------
	local	oldModes = Gun:getFireModePossibilities()
	if	oldModes ~= nil then
		for i=0, oldModes:size()-1 do
			local oldMode = oldModes:get(i)
			if	(oldMode ~= nil) then
				if		oldMode == "Single" then
						Single = true
				elseif	oldMode == "[2]Burst" then
						Burst2 = true
				elseif	oldMode == "[3]Burst" then
						Burst3 = true
				elseif	oldMode == "Auto" then
						Auto = true
				end
			end
		end
	else DebugSay(2,"Not Select-Fire")
		if		Gun:getFireMode() == "Single" then
				Single = true
		elseif	Gun:getFireMode() == "Auto" then
				Auto = true
		end
	end
]]

	--------------------------------------
	--	GET MODES FROM NEW TRIGGER		--
	--------------------------------------
	if Part ~= nil then
		Type = Part:getModData().TriggerType
		if		Type == 1 then
				Single	= true
		elseif	Type == 2 then
				Auto	= true
		elseif	Type == 3 then
				Single	= true
				Burst2	= true
		elseif	Type == 4 then
				Single	= true
				Burst3	= true
		elseif	Type == 5 then
				Single	= true
				Auto	= true
		elseif	Type == 6 then
				Single	= true
				Burst2	= true
				Auto	= true
		elseif	Type == 7 then
				Single	= true
				Burst3	= true
				Auto	= true
		end
	end
	
	--------------------------------------
	--	ASSIGN NEW MODES TO GUN			--
	--------------------------------------
	if		(Gun ~= nil) and (Part ~= nil) and (result ~= nil) then
			local newmode 	= ArrayList.new()
			local Ammo = FWPGetAmmoItemKey(Gun)
			if		Ammo == "Base.ShotgunShells" or Ammo == "Base.308Bullets" or Ammo == "Base.762x74rBullets" or Ammo == "Base.3006Bullets" then
				if	Single == true then
					newmode:add("Single")
				end
				if	Burst2 == true then
					newmode:add("[2]Burst")
				end
				if	Burst3 == true then
					newmode:add("[3]Burst")
				end
				if	Auto == true then
					newmode:add("Auto")
				end
			elseif	Ammo == "Base.Bullets22" or Ammo == "Base.Bullets57" then
				if	Single == true then
					newmode:add("Single")
				end
				if	Burst2 == true then
					newmode:add("[2]Burst")
				end
				if	Burst3 == true then
					newmode:add("[3]Burst")
				end
				if	Auto == true then
					newmode:add("Auto")
				end			
			else
				if	Single == true then
					newmode:add("Single")
				end
				if	Burst2 == true then
					newmode:add("[2]Burst")
				end
				if	Burst3 == true then
					newmode:add("[3]Burst")
				end
				if	Auto == true then
					newmode:add("Auto")
				end
			end
			Gun:setFireModePossibilities(newmode)
			Gun:getModData().TriggerType = Type
			Gun:setJammed(false)
			------------------------------
			--	SET FIREMODE INCASE N/A	--
			------------------------------
			if		Gun:getFireModePossibilities():contains("Single") then
					Gun:setFireMode("Single")
			elseif	Gun:getFireModePossibilities():contains("[2]Burst") then
					Gun:setFireMode("[2]Burst")
			elseif	Gun:getFireModePossibilities():contains("[3]Burst") then
					Gun:setFireMode("[3]Burst")
			elseif	Gun:getFireModePossibilities():contains("Auto") then
					Gun:setFireMode("Auto")
			elseif	Gun:getFireModePossibilities():contains("Single") then
					Gun:setFireMode("Single")
			elseif	Gun:getFireModePossibilities():contains("[2]Burst") then
					Gun:setFireMode("[2]Burst")
			elseif	Gun:getFireModePossibilities():contains("[3]Burst") then
					Gun:setFireMode("[3]Burst")
			elseif	Gun:getFireModePossibilities():contains("Auto") then
					Gun:setFireMode("Auto")
			elseif	Gun:getFireModePossibilities():contains("Single") then
					Gun:setFireMode("Single")
			elseif	Gun:getFireModePossibilities():contains("[2]Burst") then
					Gun:setFireMode("[2]Burst")
			elseif	Gun:getFireModePossibilities():contains("[3]Burst") then
					Gun:setFireMode("[3]Burst")
			elseif	Gun:getFireModePossibilities():contains("Auto") then
					Gun:setFireMode("Auto")					
			end
						
			DebugSay(2,getText("ContextMenu_Type").." ("..tostring(Type)..") "..getText("ContextMenu_Trigger_Install").." - "..tostring(Gun:getDisplayName()))
	else	DebugSay(2,"Nothing Installed")
	end
	ReEquipIt(player,Gun)
end

--------------------------------------------------
--  [REMOVE TRIGGER-GROUP]						--
--------------------------------------------------
function Remove_Intermediate_TriggerGroup(items, result, player)
	local Gun		= nil		-- KEPT GUN
	local GunMode	= nil
	local Single	= nil
	local Burst2	= nil
	local Burst3	= nil
	local Auto		= nil
	local Tool		= nil
		
	if items then
		for i=0, items:size()-1 do
			local item = items:get(i)
			if	(item ~= nil) then
				if		item:isAimedFirearm() and (Gun == nil) then
						Gun = item
				--		DebugSay(2,"GUN..."..tostring(item:getDisplayName()))
				else	Tool = item
						result:setCondition(Tool:getCondition())
				--		DebugSay(2,"TOOL..."..tostring(item:getDisplayName()))
				end
			end
		end
	end

	----------------------------------------------
	--	GET FIRE MODES FOR GUN					--
	----------------------------------------------
	local	GunModes = Gun:getFireModePossibilities()
	if	GunModes ~= nil then
		for i=0, GunModes:size()-1 do
			GunMode = GunModes:get(i)
			if	(GunMode ~= nil) then
				if		GunMode == "Single" or GunMode == "Single" or GunMode == "Single" then
						Single = true
				elseif	GunMode == "[2]Burst" or GunMode == "[2]Burst" or GunMode == "[2]Burst" then
						Burst2 = true
				elseif	GunMode == "[3]Burst" or GunMode == "[3]Burst" or GunMode == "[3]Burst" then
						Burst3 = true
				elseif	GunMode == "Auto" or GunMode == "Auto" or GunMode == "Auto" then
						Auto = true
				end
			end
		end
	else DebugSay(2,"Not Select-Fire")
		GunMode = Gun:getFireMode()
		if		GunMode == "Single" or GunMode == "Single" or GunMode == "Single" then
				Single = true
		elseif	GunMode == "Auto" or GunMode == "Auto" or GunMode == "Auto" then
				Auto = true
		end
	end

	if		Single == true and Burst3 == true and Auto == true then
			Type = 7
	elseif	Single == true and Burst2 == true and Auto == true then
			Type = 6
	elseif	Single == true and Auto == true then
			Type = 5
	elseif	Single == true and Burst3 == true then
			Type = 4
	elseif	Single == true and Burst2 == true then
			Type = 3			
	elseif	Auto == true then
			Type = 2
	elseif	Single == true then
			Type = 1
	end

	result:getModData().TriggerType = Type
	
	--------------------------------------
	--	ASSIGN NULL MODE TO GUN			--
	--------------------------------------
	if		(Gun ~= nil) then
			local newmode 	= ArrayList.new()
			newmode:add("N/A")
			
			Gun:setFireModePossibilities(newmode)
			Gun:setFireMode("N/A")
			Gun:setJammed(true)
			Gun:getModData().TriggerType = 0
			DebugSay(2,getText("ContextMenu_Type").." ("..tostring(Type)..") "..getText("ContextMenu_Trigger_Remove").." - "..tostring(Gun:getDisplayName()))
	else	DebugSay(2,"Nothing Removed")
	end
	ReEquipIt(player,Gun)
end

------------------------------------------
--	CALLED ON ALL TRANSFORM / EQUIP		--
--	BECAUSE FIREMODEPOSSIBILITIES IS	--
--	NOT SAVED WHEN SCRIPT RELOADS		--
--	SO WE SAVE / RECALL FROM MODDATA	--
------------------------------------------
function Update_TriggerGroup(Gun)

	if	Gun and (not instanceof(Gun,"HandWeapon")) and not Gun:isAimedFirearm() then
		return
	end

--	local Mode		= Gun:getFireMode()
	local Single	= nil
	local Burst2	= nil
	local Burst3	= nil
	local Auto		= nil
	local Pad		= Gun:getWeaponPart("RecoilPad")
	------------------------------
	--	PAD SLOT PISTOL SWITCH	--
	------------------------------
	if	Gun:hasTag(FWPGetItemTag("StrikerFired")) then
		if		Pad and Pad:getModData().TriggerType ~= nil then
				Gun:getModData().TriggerType = Pad:getModData().TriggerType
		--		DebugSay(2,"Switch Detected...")
		else	Gun:getModData().TriggerType = 1
				Gun:setFireMode("Single")
		--		DebugSay(2,"Normal Striker...")
		end
	end

	local Type		= Gun:getModData().TriggerType

	if	Type ~= nil then
		if		Type == 0 then
				Single	= false
				Burst2	= false
				Burst3	= false
				Auto	= false	
		elseif	Type == 1 then
				Single	= true
		elseif	Type == 2 then
				Auto	= true
		elseif	Type == 3 then
				Single	= true
				Burst2	= true
		elseif	Type == 4 then
				Single	= true
				Burst3	= true
		elseif	Type == 5 then
				Single	= true
				Auto	= true
		elseif	Type == 6 then
				Single	= true
				Burst2	= true
				Auto	= true
		elseif	Type == 7 then
				Single	= true
				Burst3	= true
				Auto	= true
		end
	--	DebugSay(2,"Type("..tostring(Type)..") Trigger Group - Semi("..tostring(Single)..") Burst("..tostring(Burst)..") Auto("..tostring(Auto)..")")
	end
	
	if		(Gun ~= nil) and (Type ~= nil) then
			local	newmode 	= ArrayList.new()
			if		Type == 0 then
					newmode:add("N/A")
					Gun:setJammed(true)
					Gun:setFireMode("N/A")
			else	local Ammo = FWPGetAmmoItemKey(Gun)
					if		Ammo == "Base.ShotgunShells" or Ammo == "Base.308Bullets" or Ammo == "Base.762x74rBullets" or Ammo == "Base.3006Bullets" then
						if	Single == true then
							newmode:add("Single")
						end
						if	Burst2 == true then
							newmode:add("[2]Burst")
						end
						if	Burst3 == true then
							newmode:add("[3]Burst")
						end
						if	Auto == true then
							newmode:add("Auto")
						end
					elseif	Ammo == "Base.Bullets22" or Ammo == "Base.Bullets57" then
						if	Single == true then
							newmode:add("Single")
						end
						if	Burst2 == true then
							newmode:add("[2]Burst")
						end
						if	Burst3 == true then
							newmode:add("[3]Burst")
						end
						if	Auto == true then
							newmode:add("Auto")
						end			
					else
						if	Single == true then
							newmode:add("Single")
						end
						if	Burst2 == true then
							newmode:add("[2]Burst")
						end
						if	Burst3 == true then
							newmode:add("[3]Burst")
						end
						if	Auto == true then
							newmode:add("Auto")
						end
					end			
			end
			Gun:setFireModePossibilities(newmode)
			if	not Gun:getFireModePossibilities():contains(Gun:getFireMode()) then
				DebugSay(3,"FWP normalized missing fire mode")
				------------------------------
				--	SET FIREMODE INCASE N/A	--
				------------------------------
				if		Gun:getFireModePossibilities():contains("N/A") then
						Gun:setFireMode("N/A")				
				elseif	Gun:getFireModePossibilities():contains("Single") then
						Gun:setFireMode("Single")
				elseif	Gun:getFireModePossibilities():contains("[2]Burst") then
						Gun:setFireMode("[2]Burst")
				elseif	Gun:getFireModePossibilities():contains("[3]Burst") then
						Gun:setFireMode("[3]Burst")
				elseif	Gun:getFireModePossibilities():contains("Auto") then
						Gun:setFireMode("Auto")
				elseif	Gun:getFireModePossibilities():contains("Single") then
						Gun:setFireMode("Single")
				elseif	Gun:getFireModePossibilities():contains("[2]Burst") then
						Gun:setFireMode("[2]Burst")
				elseif	Gun:getFireModePossibilities():contains("[3]Burst") then
						Gun:setFireMode("[3]Burst")
				elseif	Gun:getFireModePossibilities():contains("Auto") then
						Gun:setFireMode("Auto")
				elseif	Gun:getFireModePossibilities():contains("Single") then
						Gun:setFireMode("Single")
				elseif	Gun:getFireModePossibilities():contains("[2]Burst") then
						Gun:setFireMode("[2]Burst")
				elseif	Gun:getFireModePossibilities():contains("[3]Burst") then
						Gun:setFireMode("[3]Burst")
				elseif	Gun:getFireModePossibilities():contains("Auto") then
						Gun:setFireMode("Auto")					
				end				
			end
--			DebugSay(2,"Modes Updated")
--	else	DebugSay(2,"Nothing Updated")
	end
end

------------------------------------------
--	TEST TO UPGRADE EQUIPPED GUN ONLY	--
--	OTHERWISE RECIPE MAY PICK WRONG GUN	--
--	IF MORE THAN ONE COMPATIBLE EXISTS	--
------------------------------------------
function Test_Install_TriggerGroup(item)
	if		item and (instanceof(item,"HandWeapon")) and item:isAimedFirearm() and item:isEquipped() and item:getModData().TriggerType == 0 then	-- GUN
			return true
	elseif	item and (not instanceof(item,"HandWeapon")) then																						-- TRIGGER
			return true
	elseif	item and (instanceof(item,"HandWeapon")) and not item:isAimedFirearm() then																-- SCREWDRIVER
			return true
	else	return false
	end
end

function Test_Remove_TriggerGroup(item)
	if		item and (instanceof(item,"HandWeapon")) and item:isAimedFirearm() and item:isEquipped() and item:getModData().TriggerType ~= 0 then	-- GUN
			return true
	elseif	item and (instanceof(item,"HandWeapon")) and not item:isAimedFirearm() then																-- SCREWDRIVER
			return true
	else	return false
	end
end


------------------------------------------------------------------
--  INSTALL / REMOVE [PAINTBALL TANK]										--
------------------------------------------------------------------
function Install_Paintball_Canister(items, result, player)
	local	Gun = nil
	local	Tool = nil
	local	Tank = nil
	local	Air = 0
	
	for i=0,items:size() - 1 do
		local item	= items:get(i)
		
		if item then
			if		(instanceof(item,"HandWeapon")) and item:isAimedFirearm() then		-- THE GUN
					Gun = item
			elseif	(instanceof(item,"HandWeapon")) then								-- THE SCREWDRIVER
					Tool = item
					result:setCondition(Tool:getCondition())
			else	Tank = item															-- THE TANK
			end
		end
	end
	
	if	Tank == nil then
		DebugSay(2,getText("ContextMenu_No_Tank"))
	else
		if isMagazine(Tank) then
			Air = Tank:getCurrentAmmoCount()
			TempCan = FWPCreateItem('Standard_PB_Can')
		else
			Air = 100
			TempCan = FWPCreateItem('CO2_Cartridge_Used')
		end
	end
			
	if	Gun == nil then
		DebugSay(2,"No Gun")			
	else
		if	TempCan then
			Gun:attachWeaponPart(TempCan)
			Gun:getModData().Air = Air
			DebugSay(2,TempCan:getDisplayName().." "..getText("ContextMenu_Install_Canister").." (" .. tostring(Air)..")")
			ReEquipIt(player,Gun)
		end
	end
end

function Remove_Paintball_Canister(items, result, player)
	local	Gun = nil
	local	Tool = nil
	local	Air = 0
	
	for i=0,items:size() - 1 do
		local item	= items:get(i)
		
		if item then
			if		(instanceof(item,"HandWeapon")) and item:isAimedFirearm() then		-- THE GUN
					Gun = item
			elseif	(instanceof(item,"HandWeapon")) then								-- THE SCREWDRIVER
					Tool = item
					result:setCondition(Tool:getCondition())
			end
		end
	end	

	if Gun ~= nil then
		local recoil	= Gun:getRecoilpad()
		if	Gun:getModData().Air ~= nil then
			Air = Gun:getModData().Air
		end
		
		if	Gun:getWeaponPart("RecoilPad") ~= nil then
			Gun:detachWeaponPart(recoil)
			if isMagazine(result) then
				result:setCurrentAmmoCount(Air)
			else Air = 0		-- CO2 CARTRIDGE DEPLETES WHEN REMOVED
			end
			Gun:getModData().Air = 0
			DebugSay(2,result:getDisplayName().." "..getText("ContextMenu_Remove_Canister").." (" .. tostring(Air)..")")
			ReEquipIt(player,Gun)
		end
	end
	
end

function Install_PB_Can_Test(item)
	if		item and (instanceof(item,"HandWeapon")) and item:isAimedFirearm() and item:getWeaponPart("RecoilPad") == nil and item:isEquipped() then		-- THE GUN
			return true
	elseif	item and (instanceof(item,"HandWeapon")) and not item:isAimedFirearm() then												-- THE SCREWDRIVER
			return true
	elseif	item and (not instanceof(item,"HandWeapon")) then																		-- THE TANK
			return true
	else	return false
	end
end

function Remove_PB_Can_Test(item)
	if		item and (instanceof(item,"HandWeapon")) and item:isAimedFirearm() and item:getWeaponPart("RecoilPad") ~= nil and item:isEquipped() then		-- THE GUN
			return true
	elseif	item and (instanceof(item,"HandWeapon")) and not item:isAimedFirearm() then												-- THE SCREWDRIVER
			return true
	else	return false
	end
end


------------------------------------------------------------------
--  [SCRAP AMMO]	RELOADING									--
------------------------------------------------------------------
function Scrap_Ammo(items, result, player)
	local	inv = player:getInventory()
	for i=0,items:size() - 1 do
		local item	= items:get(i)
		local ammo	= item:getType()

		if ammo ~= "Lyman_TMag" and ammo ~= "Lee_LoadMaster" then
			local powder	= getAmmoPowder("Base."..ammo)
			local primer	= getAmmoPrimer("Base."..ammo)
			local case	= getAmmoCase("Base."..ammo)
			local lead	= getAmmoLead("Base."..ammo)
			DebugSay(2,tostring(ammo).." / "..tostring(lead).." / "..tostring(case).." / "..tostring(powder).." / "..tostring(primer))
			inv:AddItem(primer)
			inv:AddItem(case)
			local amount	= getAmmoLeadAmount("Base."..ammo)
			if lead then
				for i=1, amount do
					inv:AddItem(lead)
				end
			end
			if powder ~= "none" then
				result:setUsedDelta(powder)
			end
		end
	end
end

------------------------------------------------------------------
--  [SWAP BARREL]	NEF, TC, etc								--
------------------------------------------------------------------
function Swap_Barrel(items, result, player)
	local Gun
	for i=0,items:size() - 1 do
		if (instanceof(items:get(i),"HandWeapon")) then
			Gun = items:get(i)
		end
	end

	local	oldBarrel = nil

	if	string.find(Gun:getType(), "308") then
		oldBarrel = FWPCreateItem('Barrel_308');
	elseif	string.find(Gun:getType(), "3006") then
		oldBarrel = FWPCreateItem('Barrel_3006');
	elseif	string.find(Gun:getType(), "4570") then
		oldBarrel = FWPCreateItem('Barrel_4570');

	elseif	string.find(Gun:getType(), "45LC") or string.find(Gun:getType(), "410") then
		if string.find(Gun:getType(), "Sawed") then
			oldBarrel = FWPCreateItem('Barrel_45LC_Short');
		else
			oldBarrel = FWPCreateItem('Barrel_45LC');
		end
	elseif	string.find(Gun:getType(), "357") or string.find(Gun:getType(), "38") then
		if string.find(Gun:getType(), "Sawed") then
			oldBarrel = FWPCreateItem('Barrel_357_Short');
		else
			oldBarrel = FWPCreateItem('Barrel_357');
		end
	end

	if oldBarrel ~= nil then
		player:getInventory():AddItem(oldBarrel)	-- ADD OLD BARREL TO INVENTORY
	end

--	======= TRANSFER CONDITION & MODE ======
	result:setCondition(Gun:getCondition());
	result:setFireMode(Gun:getFireMode());

--	====== TRANSFER AMMO MAG & CHAMBER =====
	if Gun:isContainsClip() == true then
		result:setContainsClip(true);
	end

--	====== TRANSFER MAG-TYPE =====				*** INCASE ITS USING EXTENDED MAG OPTION ***
--		result:setMagazineType(Gun:getMagazineType());
--		result:setMaxAmmo(Gun:getMaxAmmo());

--	result:setCurrentAmmoCount(Gun:getCurrentAmmoCount());

	if Gun:isRoundChambered() == true then
		result:setRoundChambered(true);
	end

--	====== TRANSFER WEAPON ATTACHMENTS SO THEY DO NOT AFFECT MELEE VERSION
	if 	(result:isAimedFirearm() and Gun:isAimedFirearm()) then		-- [GUN to GUN] LEAVE THIS ALONE
		result:attachWeaponPart(Gun:getWeaponPart("Scope"))
		result:attachWeaponPart(Gun:getWeaponPart("Canon"))
		result:attachWeaponPart(Gun:getWeaponPart("Clip"))
		result:attachWeaponPart(Gun:getWeaponPart("Stock"))
		result:attachWeaponPart(Gun:getWeaponPart("Sling"))
		result:attachWeaponPart(Gun:getWeaponPart("RecoilPad"))
	end

--	if (instanceof(result,"HandWeapon")) and result:getMaxRange() > 0 then	-- REMOVE isAimedFirearm() for BAYO (Mele)
	if (instanceof(result,"HandWeapon")) then
		player:setPrimaryHandItem(result) 
		if(result:isRequiresEquippedBothHands() or result:isTwoHandWeapon()) then
			player:setSecondaryHandItem(result)
		else	player:setSecondaryHandItem(nil)
		end
	end
end

------------------------------------------------------------------
--  [USE EXTINGUISHER]	DELTA TO AMMO IS NOT ACCURATE			--
------------------------------------------------------------------
function Equip_FireExtinguisher(items, result, player)
	for i=0,items:size() - 1 do
		Gun = items:get(i)
	end

	if (Gun) then
		local fill = Gun:getUsedDelta() * 110
		if fill >= 100 then
			fill = 100
		end
		result:setCurrentAmmoCount(fill)
		player:getInventory():DoRemoveItem(Gun)
	end

	if (instanceof(result,"HandWeapon")) then
		player:setPrimaryHandItem(result) 
		if(result:isRequiresEquippedBothHands() or result:isTwoHandWeapon()) then
			player:setSecondaryHandItem(result)
		else	player:setSecondaryHandItem(nil)
		end
	end
end

function UnEquip_FireExtinguisher(items, result, player)
	for i=0,items:size() - 1 do
		Gun = items:get(i)
	end

	if (Gun) then
		local ammo = Gun:getCurrentAmmoCount()
		local fill = 0

		if 		ammo and ammo == 100 then	-- [ ]
				fill = 1
		elseif 	ammo and ammo >= 90 then	-- [ ]
				fill = ammo / 98
		elseif 	ammo and ammo >= 80 then	-- [good]
				fill = ammo / 97
		elseif	ammo and ammo >= 70 then	-- [-1]
				fill = ammo / 96
		elseif	ammo and ammo >= 60 then	-- +2
				fill = ammo / 94
		elseif	ammo and ammo >= 50 then	-- +2
				fill = ammo / 92
		elseif	ammo and ammo >= 40 then	-- +4
				fill = ammo / 89
		elseif	ammo and ammo >= 30 then	-- [good]
				fill = ammo / 85
		elseif	ammo and ammo >= 20 then	-- +6
				fill = ammo / 79
		elseif	ammo and ammo >= 10 then	-- +2
				fill = ammo / 69
		else		fill = ammo / 50
		end			
		result:setUsedDelta(fill)
		player:getInventory():DoRemoveItem(Gun)
	end
end


------------------------------------------------------------------
--  [IMPROVISED FLAME THROWER]									--
------------------------------------------------------------------
function Improvised_FlameThrower(items, result, player)
	for i=0,items:size() - 1 do
--		if	(items:get(i):getDisplayCategory() == "GunClean") then		-- DAMN BETTER SORTING
		if	(items:get(i):getType() == "WD") then
			Gun = items:get(i)
		elseif	(items:get(i):getType() == "Lighter") then
			DebugSay(3,"LIGHT ITEM FOUND")
			Light = items:get(i)
		end
	end

	if (Light) then					-- JUST SAVE TRANSFER CURRENT LIGHTER DELTA
		DebugSay(3,"LIGHT SAVE DELTA")		-- DISPOSABLE WEAPON WILL NOT USE LIGHTER CAPACITY
		local LightFill = Light:getUsedDelta()
		result:getModData().Trajectory = LightFill	-- USE EXISTING VARIABLE
	end

	if (Gun) then
		local fill = Gun:getUsedDelta() * 30
		result:setCurrentAmmoCount(fill)
	end
end

function Scrap_Improvised_FlameThrower(items, result, player)
	for i=0,items:size() - 1 do
		if	(instanceof(items:get(i),"HandWeapon")) then
			Gun = items:get(i)
		end
	end

	local RB = FWPCreateItem('RubberBand')
	local LT = FWPCreateItem('Lighter')
	local fill = Gun:getCurrentAmmoCount()/10

	result:setUsedDelta(fill)				-- WD CAN

	if (Gun:getModData().Trajectory ~= nil) then		-- USE EXISTING VARIABLE
		DebugSay(3,"LIGHT SET DELTA")
		LT:setUsedDelta(Gun:getModData().Trajectory)	-- LIGHTER
	end

	player:getInventory():AddItem(LT)
	player:getInventory():AddItem(RB)
end

------------------------------------------------------------------
--  [DON & DOFF M2A1 FUEL TANK]									--
------------------------------------------------------------------
function DOFF_M2A1_Tank(items, result, player)
	local tank
	for i=0,items:size() - 1 do
		tank = items:get(i)
	end
	local	back	= player:getClothingItem_Back()
	if (back) then
		player:setWornItem(back:canBeEquipped(), nil)
		result:setCurrentAmmoCount(tank:getCurrentAmmoCount());
	end
end
function DON_M2A1_Tank(items, result, player)
	local tank
	for i=0,items:size() - 1 do
		tank = items:get(i)
	end
	local	back	= FWPCreateItem('Bag_M2A1')
	player:setWornItem(back:canBeEquipped(), back)
	result:setCurrentAmmoCount(tank:getCurrentAmmoCount());
end

function DOFF_M2A1_Tank_Test(item)
	local	player	= getSpecificPlayer(0)
	local	back	= player:getClothingItem_Back()
	if	(back) and (back:getType() == "Bag_M2A1") then
		return true
	else	return false
	end
end
function DON_M2A1_Tank_Test(item)
	local	player	= getSpecificPlayer(0)
	local	back	= player:getClothingItem_Back()
	if	((back) and (back:getType() ~= "Bag_M2A1")) or (back == nil) then
		return true
	else	return false
	end
end

--------------------------------------------------------------
--	[CHECK M2A1 TANK] INCASE TANK IS PLACED WHILE WORN		--
--------------------------------------------------------------
function Check_M2A1_Tank()
	local	player	= getSpecificPlayer(0)
	local	inv		= player:getInventory()
	local	items	= inv:getItems()
	local	back	= player:getClothingItem_Back()
	local	hasTank	= false
	
--	if	(back) and (back:getType() == "Bag_M2A1") then
--		DebugSay(2,"Wearing Tank...")
--	end
		
	for i = 1, items:size()-1 do
		local	item = items:get(i)
		if		(item:getType() == "M2A1_Tank") then
				hasTank = true
		--		DebugSay(2,"Inventory Has Tank...")
		elseif 	(item:getType() == "M2A1") and (item:isContainsClip() == true) then
				hasTank = true
		--		DebugSay(2,"Inventory Has Loaded Tank...")
		end
	end
			
	if	(back) and (back:getType() == "Bag_M2A1") and (hasTank ~= true) then
		player:setWornItem(back:canBeEquipped(), nil)
		DebugSay(2,getText("ContextMenu_Remove_Tank"))
	end
end

Events.OnRefreshInventoryWindowContainers.Add(Check_M2A1_Tank)

------------------------------------------------------------------
--  [FILL WATERGUN]												--
------------------------------------------------------------------
function Fill_LiquidAmmo(items, result, player)
	local	Gun
	local	Fill
	local	Rate = 0

	for i=0,items:size() - 1 do
--		if	(instanceof(items:get(i),"HandWeapon")) or (items:get(i):getDisplayCategory() == "GunMag") then		-- FUCKIN BETTER SORTING
		if	(instanceof(items:get(i),"HandWeapon")) or isMagazine(items:get(i)) then
			Gun = items:get(i)
		else	Fill = items:get(i)
		end
	end

	if	string.find(Fill:getType(), "Propane") then
		Rate = 25
--	elseif	string.find(Fill:getType(), "Petrol") then
	elseif	Fill:hasTag(FWPGetItemTag("Petrol")) then
		Rate = 30
	elseif	string.find(Fill:getType(), "Water") then
		Rate = 1
	end

	if (instanceof(result,"HandWeapon")) then
	--	======= TRANSFER CONDITION & MODE ======
		result:setCondition(Gun:getCondition());
		if	Gun:isRoundChambered() == true then
			result:setRoundChambered(true);
		end
	end

	result:setCurrentAmmoCount(Gun:getCurrentAmmoCount() + Rate);
	if result:getCurrentAmmoCount() > result:getMaxAmmo() then
		result:setCurrentAmmoCount(result:getMaxAmmo())
		if	Rate == 10 then
			Sound = player:getEmitter():playSound("OverFill")
		elseif	Rate == 1 then
			Sound = player:getEmitter():playSound("waterSplash")
		end
	end

	if (instanceof(result,"HandWeapon")) then	-- REMOVE isAimedFirearm() for BAYO (Mele)
		player:setPrimaryHandItem(result) 
		if(result:isRequiresEquippedBothHands() or result:isTwoHandWeapon()) then
			player:setSecondaryHandItem(result)
		else	player:setSecondaryHandItem(nil)
		end
	end
end


------------------------------------------------------------------
--  [RECOVER ARCHERY COMPONENTS]								--
------------------------------------------------------------------
function Recover_Archery_Components(items, result, player)

	local	inv	= player:getInventory()
	local count	= 1
	Sound = player:getEmitter():playSound("Unstuckkitchenknife")
	for i=0,items:size() - 1 do
		if	(items:get(i):hasTag(FWPGetItemTag("Broken_Arrow"))) then
			if	ZombRand(2) == 0 then						-- SHAFT 50%
				if		string.find(items:get(i):getType(), "Arrow") then
						inv:AddItem("Base.Shaft_Fiberglass")
						DebugSay(2,getText("ContextMenu_Recovered_Fiber"))
				elseif	string.find(items:get(i):getType(), "Bolt") then
						inv:AddItem("Base.Shaft_Carbon")
						DebugSay(2,getText("ContextMenu_Recovered_Carbon"))
				end
			else	Sound = player:getEmitter():playSound("PZ_WoodSnap")	-- FAIL SHAFT
			end

			if	ZombRand(2)	== 0 then		-- HEAD 50%
				inv:AddItem("Base.Arrow_Head")
				DebugSay(2,getText("ContextMenu_Recovered_Head"))
			end

			if	ZombRand(2)	== 0 then		-- OTHER 2 FINS 50%
				for i=1, ZombRand(1,2) do
					inv:AddItem("Base.Arrow_Fletching")
					count = count + 1
				end
			end
			DebugSay(2,"Recovered - Arrow Fletching ("..tostring(count)..")")		-- OUTSIDE LOOP ALWAYS GET ONE
		else	DebugSay(2,getText("ContextMenu_Scrap_Arrow"))		-- FRESH NON-BROKEN
			if		string.find(items:get(i):getType(), "Arrow") then
					inv:AddItem("Base.Shaft_Fiberglass")
					DebugSay(2,getText("ContextMenu_Recovered_Fiber"))
			elseif	string.find(items:get(i):getType(), "Bolt") then
					inv:AddItem("Base.Shaft_Carbon")
					DebugSay(2,getText("ContextMenu_Recovered_Carbon"))
			end
			inv:AddItem("Base.Arrow_Head")
			DebugSay(2,getText("ContextMenu_Recovered_Head"))
			for i=1, 2 do
				inv:AddItem("Base.Arrow_Fletching")
				count = count + 1
			end
			DebugSay(2,getText("ContextMenu_Recovered_Fletch").." ("..tostring(count)..")")
		end
	end
end


------------------------------------------------------------------
--  [MELEE MODE] GENERIC FOR ANY FIREARM						--
------------------------------------------------------------------
function Universal_Melee(items, result, player)
	local Gun
	for i=0,items:size() - 1 do
		if (instanceof(items:get(i),"HandWeapon")) then
			Gun = items:get(i)
		end
	end

--	======= TRANSFER CONDITION & MODE ======
	result:setCondition(Gun:getCondition());
	result:setFireMode(Gun:getFireMode());

--	====== TRANSFER AMMO MAG & CHAMBER =====
	if	Gun:isContainsClip() == true then
		result:setContainsClip(true);
	end

--	====== TRANSFER MAG-TYPE =====
	if	Gun:getMagazineType() == nil and Gun:getModData().ClipType ~= nil then
		result:setMagazineType(Gun:getModData().ClipType);
	elseif	result:getMagazineType() == "Base.Fixed" then			-- FIXED MAG GUNS... SEEMS BACKWARDS ???
		DebugSay(2,"...")
	elseif	Gun:getMagazineType() ~= "Base.Fixed" then			-- MAG FED GUNS
		result:setMagazineType(Gun:getMagazineType());
	end

	result:setMaxAmmo(Gun:getMaxAmmo());

	result:setCurrentAmmoCount(Gun:getCurrentAmmoCount());

	if	Gun:isRoundChambered() == true then
		result:setRoundChambered(true);
	end

--	====== TRANSFER WEAPON ATTACHMENTS SO THEY DO NOT AFFECT MELEE VERSION
	if 	(result:isAimedFirearm() and Gun:isAimedFirearm()) then		-- [GUN to GUN] LEAVE THIS ALONE
		result:attachWeaponPart(Gun:getWeaponPart("Scope"))
		result:attachWeaponPart(Gun:getWeaponPart("Canon"))
		result:attachWeaponPart(Gun:getWeaponPart("Clip"))
		result:attachWeaponPart(Gun:getWeaponPart("Stock"))
		result:attachWeaponPart(Gun:getWeaponPart("Sling"))
		result:attachWeaponPart(Gun:getWeaponPart("RecoilPad"))
	end

	local scriptItem = result:getScriptItem()
--	local maxDmg	= scriptItem:getMaxDamage()
--	local minDmg	= scriptItem:getMinDamage()
	local maxRange	= scriptItem:getMaxRange()	-- USE NON-MODIFIED ONLY WHEN MELEE
	local maxDmg	= result:getMaxDamage()		-- USE MODIFIED DAMAGE
	local minDmg	= result:getMinDamage()		-- USE MODIFIED DAMAGE
	local crit	= result:getCriticalChance()
	local impact	= result:getImpactSound()
	local canon	= FWPGetWeaponPart(result, "Canon")
	local scope	= FWPGetWeaponPart(result, "Scope")
	local bayo	= 0

	if result:isAimedHandWeapon() then	-- DONT DO THIS GOING TO GUN MODE
		if canon then
			if string.find(canon:getType(), "Bayonet") then
				maxDmg	= 1.8
				minDmg	= 1.4
				crit	= 10
				bayo	= 0.4
				impact	= BladeHit
			end
		end
	--	if scope then
		local meleeRange = maxRange + bayo
		result:setMaxRange(meleeRange)
	--	end
	end

	if (instanceof(result,"HandWeapon")) then	-- REMOVE isAimedFirearm() for BAYO (Mele)
		player:setPrimaryHandItem(result) 
		if(result:isRequiresEquippedBothHands() or result:isTwoHandWeapon()) then
			player:setSecondaryHandItem(result)
		else	player:setSecondaryHandItem(nil)
		end
	end

	result:setMaxDamage(maxDmg)
	result:setMinDamage(minDmg)
	result:setCriticalChance(crit)
	result:setImpactSound(impact)
end

------------------------------------------------------------------
--  [MELEE_TEST] MAKE SURE THERE IS BAYONET ATTACHED			--
------------------------------------------------------------------
function Melee_Test(item)
	local canon = FWPGetWeaponPart(item, "Canon")
	if canon then
		if string.find(canon:getType(), "Bayonet") then
			return true
		else	return false
		end
	else	return true
	end
end


------------------------------------------------------------------
--  [INTEGRAL_BAYONET] USE WITH INTEGRAL FOLDING BAYONET ONLY	--
------------------------------------------------------------------
function Integral_Bayonet(items, result, player, action)
	local Gun
	for i=0,items:size() - 1 do
		if (instanceof(items:get(i),"HandWeapon")) then
			Gun = items:get(i)
		end
	end

--	======= TRANSFER CONDITION & MODE ======
	result:setCondition(Gun:getCondition());
	result:setFireMode(Gun:getFireMode());

--	====== TRANSFER AMMO MAG & CHAMBER =====
	if 	(Gun:isContainsClip() == true) then
		result:setContainsClip(true);
	end

--	====== TRANSFER MAG-TYPE =====				*** INCASE ITS USING EXTENDED MAG OPTION ***
		result:setMagazineType(Gun:getMagazineType());
		result:setMaxAmmo(Gun:getMaxAmmo());

	if Gun:isRoundChambered() == true then
		result:setRoundChambered(true);
	end
	result:setCurrentAmmoCount(Gun:getCurrentAmmoCount());

--	====== TRANSFER WEAPON ATTACHMENTS SO THEY DO NOT AFFECT MELEE VERSION
	if 	(result:isAimedFirearm() and Gun:isAimedFirearm()) then		-- [GUN to GUN] LEAVE THIS ALONE
		result:attachWeaponPart(Gun:getWeaponPart("Scope"))
		result:attachWeaponPart(Gun:getWeaponPart("Canon"))
		result:attachWeaponPart(Gun:getWeaponPart("Clip"))
		result:attachWeaponPart(Gun:getWeaponPart("Stock"))
		result:attachWeaponPart(Gun:getWeaponPart("Sling"))
		result:attachWeaponPart(Gun:getWeaponPart("RecoilPad"))
	end

	if result:isAimedHandWeapon() then
		local scriptItem = result:getScriptItem()
		local maxRange	= scriptItem:getMaxRange()	-- USE NON-MODIFIED ONLY WHEN MELEE
		result:setMaxRange(maxRange)
	end

	if (instanceof(result,"HandWeapon")) then	-- REMOVE isAimedFirearm() for BAYO (Mele)
		player:setPrimaryHandItem(result) 
		if(result:isRequiresEquippedBothHands() or result:isTwoHandWeapon()) then
			player:setSecondaryHandItem(result)
		else	player:setSecondaryHandItem(nil)
		end
	end
end

------------------------------------------------------------------
--  [BAYONET_TEST] MAKE SURE THERE IS NO SUPPRESSOR BLOCKING	--
------------------------------------------------------------------
function Bayonet_Test(item)
	local canon = FWPGetWeaponPart(item, "Canon")
	if canon then
		if string.find(canon:getType(), "Suppressor") then
			return false
		else	return true
		end
	else	return true
	end
end


------------------------------------------------------------------
--  [UNIVERSAL_STOCK] FOR SIMPLE TRANSFORMATION	(Stocks)		--
------------------------------------------------------------------
function Universal_Stock(items, result, player)
	local Gun
	for i=0,items:size() - 1 do
		if (instanceof(items:get(i),"HandWeapon")) then
			Gun = items:get(i)
		end
	end

--	======= TRANSFER CONDITION & MODE ======
	result:setCondition(Gun:getCondition());
	result:setFireMode(Gun:getFireMode());

--	====== TRANSFER AMMO MAG & CHAMBER =====
	if Gun:isContainsClip() == true then
		result:setContainsClip(true);
	end

--	====== TRANSFER MAG-TYPE =====				*** INCASE ITS USING EXTENDED MAG OPTION ***
		result:setMagazineType(Gun:getMagazineType());
		result:setMaxAmmo(Gun:getMaxAmmo());

	result:setCurrentAmmoCount(Gun:getCurrentAmmoCount());

	if Gun:isRoundChambered() == true then
		result:setRoundChambered(true);
	end

--	====== TRANSFER WEAPON ATTACHMENTS SO THEY DO NOT AFFECT MELEE VERSION
	if 	(result:isAimedFirearm() and Gun:isAimedFirearm()) then		-- [GUN to GUN] LEAVE THIS ALONE
		result:attachWeaponPart(Gun:getWeaponPart("Scope"))
		result:attachWeaponPart(Gun:getWeaponPart("Canon"))
		result:attachWeaponPart(Gun:getWeaponPart("Clip"))
		result:attachWeaponPart(Gun:getWeaponPart("Stock"))
		result:attachWeaponPart(Gun:getWeaponPart("Sling"))
		result:attachWeaponPart(Gun:getWeaponPart("RecoilPad"))
	end

--	if (instanceof(result,"HandWeapon")) and result:getMaxRange() > 0 then	-- REMOVE isAimedFirearm() for BAYO (Mele)
	if (instanceof(result,"HandWeapon")) then
		player:setPrimaryHandItem(result) 
		if(result:isRequiresEquippedBothHands() or result:isTwoHandWeapon()) then
			player:setSecondaryHandItem(result)
		else	player:setSecondaryHandItem(nil)
		end
	end
end


------------------------------------------------------------------
--  [UNIVERSAL_SAW-OFF] FOR SHOTGUN TRANSFORMATION				--
------------------------------------------------------------------
function Universal_Sawoff(items, result, player)
	local Gun
	for i=0,items:size() - 1 do
		if (instanceof(items:get(i),"HandWeapon")) then
			Gun = items:get(i)
		end
	end

--	======= TRANSFER CONDITION & MODE ======
	result:setCondition(Gun:getCondition());
	result:setFireMode(Gun:getFireMode());

--	====== TRANSFER AMMO MAG & CHAMBER =====
	if Gun:isContainsClip() == true then
		result:setContainsClip(true);
	end

--	====== TRANSFER MAG-TYPE =====				*** INCASE ITS USING EXTENDED MAG OPTION ***
		result:setMagazineType(Gun:getMagazineType());
		result:setMaxAmmo(Gun:getMaxAmmo());

	result:setCurrentAmmoCount(Gun:getCurrentAmmoCount());

	if Gun:isRoundChambered() == true then
		result:setRoundChambered(true);
	end

--	====== TRANSFER WEAPON ATTACHMENTS SO THEY DO NOT AFFECT MELEE VERSION
	if 	(result:isAimedFirearm() and Gun:isAimedFirearm()) then		-- [GUN to GUN] LEAVE THIS ALONE
		result:attachWeaponPart(Gun:getWeaponPart("Scope"))
		result:attachWeaponPart(Gun:getWeaponPart("Canon"))
		result:attachWeaponPart(Gun:getWeaponPart("Clip"))
		result:attachWeaponPart(Gun:getWeaponPart("Stock"))
		result:attachWeaponPart(Gun:getWeaponPart("Sling"))
		result:attachWeaponPart(Gun:getWeaponPart("RecoilPad"))
	end

	local canon		= FWPGetWeaponPart(Gun, "Canon")
	local recoil	= Gun:getRecoilpad()
	local sling		= FWPGetWeaponPart(Gun, "Sling")

	if	string.find(result:getType(), "Pistol") then		-- NO XFER CANON, SLING, RECOIL
--		if canon then
--			result:detachWeaponPart(canon)
--			player:getInventory():AddItem(canon)		-- ADD REPLACED MAG TO INVENTORY
--			DebugSay(3,"Muzzle attachment removed...")
--		end
		if sling then
			result:detachWeaponPart(sling)
			player:getInventory():AddItem(sling)		-- ADD REPLACED MAG TO INVENTORY
			DebugSay(3,"Sling attachment removed...")
		end
		if recoil then
			result:detachWeaponPart(recoil)
			player:getInventory():AddItem(recoil)		-- ADD REPLACED MAG TO INVENTORY
			DebugSay(3,"Recoil attachment removed...")
		end
--	elseif	string.find(result:getType(), "Sawed") then			-- NO XFER CANON
--		if canon then
--			result:detachWeaponPart(canon)
--			player:getInventory():AddItem(canon)		-- ADD REPLACED MAG TO INVENTORY
--			DebugSay(3,"Muzzle attachment removed...")
--		end	
	end

--	if (instanceof(result,"HandWeapon")) and result:getMaxRange() > 0 then	-- REMOVE isAimedFirearm() for BAYO (Mele)
	if (instanceof(result,"HandWeapon")) then
		player:setPrimaryHandItem(result) 
		if(result:isRequiresEquippedBothHands() or result:isTwoHandWeapon()) then
			player:setSecondaryHandItem(result)
		else	player:setSecondaryHandItem(nil)
		end
	end
end


------------------------------------------------------------------
--  [FIXED_MAGTYPE] INSTALLS FIXED OR DETACHABLE MAG FOR SKS	--
------------------------------------------------------------------
function Fixed_MagType(items, result, player)
	local Gun
	local NewMag
	for i=0,items:size() - 1 do
	--	if (instanceof(items:get(i),"HandWeapon")) and ((items:get(i):getMagazineType() ~= nil) or (items:get(i):getModData().FixedMagType ~= nil)) then
		if (instanceof(items:get(i),"HandWeapon")) then
			Gun = items:get(i)

	--	elseif (items:get(i):getDisplayCategory() == "GunMag") or (items:get(i):getDisplayCategory() == "FixedMag") then
		elseif isMagazine(items:get(i)) then
			NewMag = items:get(i)
		end
	end

--	======= TRANSFER CONDITION & MODE ======
	result:setCondition(Gun:getCondition());
	result:setFireMode(Gun:getFireMode());

--	====== TRANSFER AMMO MAG & CHAMBER =====
	if	Gun:getModData().FixedMagType and Gun:isContainsClip() == true then	-- DONT GIVE BACK IF INSTALLING FIXEDMAG
		local FixedMag
		local AmmoType = FWPGetAmmoItemKey(Gun)
		local FixedMagAmmo = Gun:getCurrentAmmoCount()
		FixedMag = player:getInventory():AddItem(Gun:getModData().FixedMagType)	-- ADD REPLACE FIXED MAG TO INVENTORY
		FixedMag:setCurrentAmmoCount(FixedMagAmmo)					-- FILL IT
--		for i=1, FixedMagAmmo do
--			player:getInventory():AddItem(AmmoType)					-- ADD LOOSE ROUNDS (too many)... WTF ??
--		end
	elseif	Gun:isContainsClip() == true then
		local OldMag
		local OldMagAmmo = Gun:getCurrentAmmoCount()

		local	Clip = Gun:getModData().ClipType					-- DONT GIVE CLIP WITH 30 ROUNDS BACK!!!!
		local	Mag = Gun:getModData().MagType
		if (Gun:getMagazineType() == Clip or Gun:getMagazineType() == nil) and Mag then	-- IN CASE SINGLE LOAD MODE
			Gun:setMagazineType(Mag)
		end
		OldMag = player:getInventory():AddItem(Gun:getMagazineType())			-- ADD REPLACED MAG TO INVENTORY
		OldMag:setCurrentAmmoCount(OldMagAmmo)						-- FILL IT

	end

	if Gun:isRoundChambered() == true then
		result:setRoundChambered(true)
	end
	if result:getMagazineType() ~= nil then
		result:setContainsClip(true);					-- THIS IS THE NEW MAG TYPE
	end
	result:setCurrentAmmoCount(NewMag:getCurrentAmmoCount());

--	====== TRANSFER WEAPON ATTACHMENTS ======
	result:attachWeaponPart(Gun:getWeaponPart("Scope"))
	result:attachWeaponPart(Gun:getWeaponPart("Canon"))

--	local	Ext = Gun:getModData().ExtMagType
--	if NewMag:getMaxAmmo() > Gun:getMaxAmmo() then				-- getType DIDNT WORK FOR SOME REASON
--		MagPart = FWPCreateItem('Extended_Mag');
--		if MagPart then
--			result:attachWeaponPart(MagPart)			-- OTHERWISE WILL BE BLANK FROM NEW RECIPE GUN
--			result:setMaxAmmo(NewMag:getMaxAmmo())
--			result:setMagazineType(Ext)
--		end
--	end
--	result:attachWeaponPart(Gun:getWeaponPart("Clip"))
	result:attachWeaponPart(Gun:getWeaponPart("Stock"))
	result:attachWeaponPart(Gun:getWeaponPart("Sling"))
	result:attachWeaponPart(Gun:getWeaponPart("RecoilPad"))

	if (instanceof(result,"HandWeapon")) then	-- REMOVE isAimedFirearm() for BAYO (Mele)
		player:setPrimaryHandItem(result) 
		if(result:isRequiresEquippedBothHands() or result:isTwoHandWeapon()) then
			player:setSecondaryHandItem(result)
		else	player:setSecondaryHandItem(nil)
		end
	end
end

------------------------------------------------------------------
--  [EXTENDED_MAGTYPE] HANDLES MAG TYPE SWITCH 					--
------------------------------------------------------------------
function Extended_MagType(items, result, player)
	local Gun
	for i=0,items:size() - 1 do
		if (instanceof(items:get(i),"HandWeapon")) then
			Gun = items:get(i)
		end
	end

--	======= TRANSFER CONDITION & MODE ======
	result:setCondition(Gun:getCondition());
	result:setFireMode(Gun:getFireMode());

--	====== TRANSFER AMMO MAG & CHAMBER =====
	if	Gun:getModData().FixedMagType and Gun:isContainsClip() == true then	-- DONT GIVE BACK IF INSTALLING FIXEDMAG
		local FixedMag
		local AmmoType = FWPGetAmmoItemKey(Gun)
		local FixedMagAmmo = Gun:getCurrentAmmoCount()
		FixedMag = player:getInventory():AddItem(Gun:getModData().FixedMagType)	-- ADD REPLACE FIXED MAG TO INVENTORY
		FixedMag:setCurrentAmmoCount(FixedMagAmmo)					-- FILL IT

	elseif	Gun:isContainsClip() == true then
		local OldMag
		local OldMagAmmo = Gun:getCurrentAmmoCount()

		local	Clip = Gun:getModData().ClipType					-- DONT GIVE CLIP WITH 30 ROUNDS BACK!!!!
		local	Mag = Gun:getModData().MagType
		if Gun:getMagazineType() == Clip and Mag then
			Gun:setMagazineType(Mag)
		end
		OldMag = player:getInventory():AddItem(Gun:getMagazineType())			-- ADD REPLACED MAG TO INVENTORY
		OldMag:setCurrentAmmoCount(OldMagAmmo)						-- FILL IT
	end

	if Gun:isRoundChambered() == true then
		result:setRoundChambered(true)
	end

--	==== TESTING AUTO INSERT MAG SECTION ====
--	local NewMag = player:getInventory():FindAndReturn(Gun:getModData().ExtMagType)

--	if result:getMagazineType() ~= nil then							-- DO NOT AUTO INSERT NEW MAG
--		result:setContainsClip(true);							-- THIS IS THE NEW MAG TYPE
--	end
--	result:setCurrentAmmoCount(NewMag:getCurrentAmmoCount());



--	====== TRANSFER WEAPON ATTACHMENTS ======
	result:attachWeaponPart(Gun:getWeaponPart("Scope"))
	result:attachWeaponPart(Gun:getWeaponPart("Canon"))

	local	Ext = Gun:getModData().ExtMagType
	if Ext ~= Gun:getMagazineType() then
		MagPart = FWPCreateItem('Extended_Mag');
		if MagPart then
			result:attachWeaponPart(MagPart)			-- OTHERWISE WILL BE BLANK FROM NEW RECIPE GUN
--			result:setMaxAmmo(NewMag:getMaxAmmo())
			result:setMagazineType(Ext)
		end
	end
--	result:attachWeaponPart(Gun:getWeaponPart("Clip"))
	result:attachWeaponPart(Gun:getWeaponPart("Stock"))
	result:attachWeaponPart(Gun:getWeaponPart("Sling"))
	result:attachWeaponPart(Gun:getWeaponPart("RecoilPad"))

	if (instanceof(result,"HandWeapon")) then	-- REMOVE isAimedFirearm() for BAYO (Mele)
		player:setPrimaryHandItem(result) 
		if(result:isRequiresEquippedBothHands() or result:isTwoHandWeapon()) then
			player:setSecondaryHandItem(result)
		else	player:setSecondaryHandItem(nil)
		end
	end
end

------------------------------------------------------------------
--  [DRUM_MAGTYPE] HANDLES MAG TYPE SWITCH 						--
------------------------------------------------------------------
function Drum_MagType(items, result, player)
	local Gun
	for i=0,items:size() - 1 do
		if (instanceof(items:get(i),"HandWeapon")) then
			Gun = items:get(i)
		end
	end

--	======= TRANSFER CONDITION & MODE ======
	result:setCondition(Gun:getCondition());
	result:setFireMode(Gun:getFireMode());

--	====== TRANSFER AMMO MAG & CHAMBER =====
	if	Gun:getModData().FixedMagType and Gun:isContainsClip() == true then	-- DONT GIVE BACK IF INSTALLING FIXEDMAG
		local FixedMag
		local AmmoType = FWPGetAmmoItemKey(Gun)
		local FixedMagAmmo = Gun:getCurrentAmmoCount()
		FixedMag = player:getInventory():AddItem(Gun:getModData().FixedMagType)	-- ADD REPLACE FIXED MAG TO INVENTORY
		FixedMag:setCurrentAmmoCount(FixedMagAmmo)					-- FILL IT

	elseif	Gun:isContainsClip() == true then
		local OldMag
		local OldMagAmmo = Gun:getCurrentAmmoCount()

		local	Clip = Gun:getModData().ClipType					-- DONT GIVE CLIP WITH 30 ROUNDS BACK!!!!
		local	Mag = Gun:getModData().MagType
		if (Gun:getMagazineType() == Clip or Gun:getMagazineType() == nil) and Mag then	-- IN CASE SINGLE LOAD MODE
	--	if Gun:getMagazineType() == Clip and Mag then
			Gun:setMagazineType(Mag)
		end
		OldMag = player:getInventory():AddItem(Gun:getMagazineType())			-- ADD REPLACED MAG TO INVENTORY
		OldMag:setCurrentAmmoCount(OldMagAmmo)						-- FILL IT
	end

	if Gun:isRoundChambered() == true then
		result:setRoundChambered(true)
	end

--	==== TESTING AUTO INSERT MAG SECTION ====
--	local NewMag = player:getInventory():FindAndReturn(Gun:getModData().DrumMagType)

--	if result:getMagazineType() ~= nil then							-- DO NOT AUTO INSERT NEW MAG
--		result:setContainsClip(true);							-- THIS IS THE NEW MAG TYPE
--	end
--	result:setCurrentAmmoCount(NewMag:getCurrentAmmoCount());



--	====== TRANSFER WEAPON ATTACHMENTS ======
	result:attachWeaponPart(Gun:getWeaponPart("Scope"))
	result:attachWeaponPart(Gun:getWeaponPart("Canon"))

	local	Drum = Gun:getModData().DrumMagType
	if Drum ~= Gun:getMagazineType() then
		MagPart = FWPCreateItem('Drum_Mag');
		if MagPart then
			result:attachWeaponPart(MagPart)			-- OTHERWISE WILL BE BLANK FROM NEW RECIPE GUN
--			result:setMaxAmmo(NewMag:getMaxAmmo())
--			result:setMagazineType(result:getModData().DrumMagType)
		end
	end
--	result:attachWeaponPart(Gun:getWeaponPart("Clip"))
	result:attachWeaponPart(Gun:getWeaponPart("Stock"))
	result:attachWeaponPart(Gun:getWeaponPart("Sling"))
	result:attachWeaponPart(Gun:getWeaponPart("RecoilPad"))

	if (instanceof(result,"HandWeapon")) then	-- REMOVE isAimedFirearm() for BAYO (Mele)
		player:setPrimaryHandItem(result) 
		if(result:isRequiresEquippedBothHands() or result:isTwoHandWeapon()) then
			player:setSecondaryHandItem(result)
		else	player:setSecondaryHandItem(nil)
		end
	end
end

function Use_Drum_Test(item, player)
	if item:getSubCategory() == "Firearm" then
		local Drum = item:getModData().DrumMagType
		if Drum == nil then
			return false
		elseif item:getMagazineType() == Drum then	-- ALREADY USING EXT MAG
			return false
		elseif Drum ~= nil and not getSpecificPlayer(0):getInventory():contains(Drum) then	-- MAG NOT IN INVENTORY
			return false
		else	return true
		end
	end
end

function Use_Extended_Test(item, player)
	if item:getSubCategory() == "Firearm" then
		local Ext = item:getModData().ExtMagType
		if Ext == nil then
			return false
		elseif item:getMagazineType() == Ext then	-- ALREADY USING EXT MAG
			return false
		elseif Ext ~= nil and not getSpecificPlayer(0):getInventory():contains(Ext) then	-- MAG NOT IN INVENTORY
			return false
		else	return true
		end
	end
end

function Rem_Extended_Test(item, player)			-- DONT REQUIRE IN INVENTORY CAN ALWAYS SWITCH TO STANDARD
	if item:getSubCategory() == "Firearm" then
		local	Ext = item:getModData().ExtMagType
		local	Drum = item:getModData().DrumMagType
		if 	Ext ~= nil and item:getMagazineType() == Ext then	-- IS USING EXT MAG TYPE
			return true
		else	return false
		end
	end
end

function Rem_Drum_Test(item, player)				-- DONT REQUIRE IN INVENTORY CAN ALWAYS SWITCH TO STANDARD
	if item:getSubCategory() == "Firearm" then
		local	Drum = item:getModData().DrumMagType
		if	Drum ~= nil and item:getMagazineType() == Drum then	-- IS USING EXT MAG TYPE
			return true
		else	return false
		end
	end
end

------------------------------------------------------------------
--  Install Extended MagBase TEST (REPLACE WITH EMPTYMAG_TEST)	--
------------------------------------------------------------------
function MagBase_Test(item)
	if item:getCurrentAmmoCount() == 0 then
		return true
	else	return false
	end
end

------------------------------------------------------------------
--  Use AmmoCan on Minigun (Must be Empty)						--
------------------------------------------------------------------
function EmptyMag_Test(item)
	if item:getCurrentAmmoCount() == 0 then
		return true
	else	return false
	end
end

function EmptyCan_Test(item)
	local Can = nil
	local Contents = nil
	if instanceof(item,"InventoryContainer") then
		Can = item
		Contents = Can:getInventory()
		DebugSay(3,"CAN DEFINED")
	end

	if 	(Contents) and (Contents:getItems():size() ~= 0) then
		DebugSay(3,"Not Empty")
		return false
	else	DebugSay(3,"Empty")
		return true
	end
end

------------------------------------------------------------------
--  [TOGGLE_STRIPPERCLIP] SWITCH TO ALTERNATE LOADING METHOD	--
------------------------------------------------------------------
function Toggle_StripperClip(items, result, player)		-- FOR M14, VZ58, SKS30
	local Gun
	for i=0,items:size() - 1 do
		if (instanceof(items:get(i),"HandWeapon")) then
			Gun = items:get(i)
		end
	end

--	======= TOGGLE MAGAZINE TYPE ======
	if	Gun:isContainsClip() == true and (Gun:getMagazineType() == Gun:getModData().MagType or Gun:getMagazineType() == nil) then
		result:setMagazineType(Gun:getModData().ClipType)
		DebugSay(2,"Clip Mode...")
	--	result:setContainsClip(false)		-- PREVENT EJECTING STRIPPER CLIP... LOST MAG WHEN USE BAYO
	elseif	Gun:getMagazineType() == Gun:getModData().ClipType then
		result:setMagazineType(Gun:getModData().MagType)
		DebugSay(2,"Mag Mode...")
	--	result:setContainsClip(true)
	elseif	Gun:getMagazineType() == Gun:getModData().DrumMagType then
		DebugSay(2,"Cannot Alternate Load w/Drum...")
	else 	DebugSay(2,"Require Magazine")
	end

--	======= TRANSFER CONDITION & MODE ======
	result:setCondition(Gun:getCondition());
	result:setFireMode(Gun:getFireMode());

--	====== TRANSFER AMMO MAG & CHAMBER =====		-- JUST GIVE CLIP ALWAYS... DONT EJECT STRIPPER!!!
	if Gun:isContainsClip() == true then
		result:setContainsClip(true);
	end

	result:setCurrentAmmoCount(Gun:getCurrentAmmoCount());

	if Gun:isRoundChambered() == true then
		result:setRoundChambered(true);
	end

--	====== TRANSFER WEAPON ATTACHMENTS
	result:attachWeaponPart(Gun:getWeaponPart("Scope"))
	result:attachWeaponPart(Gun:getWeaponPart("Canon"))
	result:attachWeaponPart(Gun:getWeaponPart("Clip"))
	result:attachWeaponPart(Gun:getWeaponPart("Stock"))
	result:attachWeaponPart(Gun:getWeaponPart("Sling"))
	result:attachWeaponPart(Gun:getWeaponPart("RecoilPad"))

	if (instanceof(result,"HandWeapon")) then
		player:setPrimaryHandItem(result) 
		if(result:isRequiresEquippedBothHands() or result:isTwoHandWeapon()) then
			player:setSecondaryHandItem(result)
		else	player:setSecondaryHandItem(nil)
		end
	end
end


------------------------------------------------------------------
--  [UNIVERSAL_LAUNCHER] SWITCH PRIMARY & LAUNCHER MODES		--
------------------------------------------------------------------
function Universal_Launcher(items, result, player)
	local Gun
	for i=0,items:size() - 1 do
		if (instanceof(items:get(i),"HandWeapon")) then
			Gun = items:get(i)
		end
	end

--	======= TRANSFER CONDITION & MODE & CERTAIN ATTACHMENTS THAT SHARE BENEFIT ======
	result:setCondition(Gun:getCondition());

	result:attachWeaponPart(Gun:getWeaponPart("Canon"))		-- TEST NEW SYSTEM
	result:attachWeaponPart(Gun:getWeaponPart("Scope"))		-- TEST NEW SYSTEM
	result:attachWeaponPart(Gun:getWeaponPart("Stock"))		-- UNCOMMENT BELOW TO IGNORE 
	result:attachWeaponPart(Gun:getWeaponPart("Sling"))
	result:attachWeaponPart(Gun:getWeaponPart("Clip"))
	result:attachWeaponPart(Gun:getWeaponPart("RecoilPad"))


--	====== TRANSFER MOST WEAPON BECAUSE ITS A WHOLE DIFFERENT FIREARM WITH ITS OWN AMMO

-- 	[LAUNCHER to LAUNCHER] SAVE ATTACHMENT TO ModData.TempXXX
	if 	(Gun:isAimedFirearm() and isLauncher(Gun) and isLauncher(result)) then
		-- AMMO TYPE DATA
		result:getModData().TempFireMode		= (Gun:getModData().TempFireMode)	-- M203 TRANSFER TEMP for M16 SwitchBack
		result:getModData().TempContainsClip		= (Gun:getModData().TempContainsClip)	
		result:getModData().TempRoundChambered		= (Gun:getModData().TempRoundChambered)	
		result:getModData().TempCurrentAmmoCount	= (Gun:getModData().TempCurrentAmmoCount)	

		result:setFireMode(Gun:getFireMode())						-- M203 SET its own FROM other M203

		if Gun:isContainsClip() == true then						-- NEED FOR K11
			result:setContainsClip(true);
		end

		local Remove = Gun:getCurrentAmmoCount()					-- NOT TEMP... ACTUAL COUNT OF GUN GOING IN

		if Gun:getCurrentAmmoCount() > 0 then
			if	FWPGetAmmoItemKey(result) == "Base.40INCRound" then			-- USE AMMOTYPE INSTEAD
				for i=1, Remove do
					player:getInventory():AddItem("Base.40HERound")		-- REMOVE HE, ADD TO INVENTORY
				end
				DebugSay(2,"Removing 40HE-Round")
			else	for i=1, Remove do
					player:getInventory():AddItem("Base.40INCRound")	-- REMOVE INC, ADD TO INVENTORY
				end
				DebugSay(2,"Removing 40INC-Round")
			end
			result:setCurrentAmmoCount(0);						-- NEVER LOADED FOR [LAUNCHER to LAUNCHER]
		end

--		result:getModData().TempScope = (Gun:getModData().TempScope)			-- M203 TRANSFER TEMP for M16 Attachments
--		result:getModData().TempCanon = (Gun:getModData().TempCanon)

-- 	[GUN to LAUNCHER] SAVE ATTACHMENT TO ModData.TempXXX
	elseif 	(Gun:isAimedFirearm() and isLauncher(result)) then
		-- AMMO TYPE DATA
		result:getModData().TempFireMode		= (Gun:getFireMode())		-- M203 SET TEMP for M16 SwitchBack
		result:getModData().TempContainsClip		= (Gun:isContainsClip())	
		result:getModData().TempRoundChambered		= (Gun:isRoundChambered())	
		result:getModData().TempCurrentAmmoCount 	= (Gun:getCurrentAmmoCount())	

		if	(Gun:getModData().TempFireMode) ~= nil then
			result:setFireMode(Gun:getModData().TempFireMode)			-- M203 SET its own FROM M16 TEMP
		end
		if	(Gun:getModData().TempContainsClip) then
			result:setContainsClip(Gun:getModData().TempContainsClip)
		end
		if	(Gun:getModData().TempRoundChambered) then
			result:setRoundChambered(Gun:getModData().TempRoundChambered)
		end

		local	Remove = Gun:getModData().TempCurrentAmmoCount				-- TEMP OF THE LAST LAUNCHER BECAUSE GUN IS M16 AMMO

		if	Gun:getModData().TempAmmoType == 1 and FWPGetAmmoItemKey(result) == "Base.40INCRound" then	-- HE LOADED, [GUN to INC LAUNCHER]
			for i=1, Remove do
				player:getInventory():AddItem("Base.40HERound")					-- REMOVE HE, ADD TO INVENTORY
			end
			DebugSay(2,"Removing 40HE-Round")
			result:setCurrentAmmoCount(0);
		elseif	Gun:getModData().TempAmmoType == 2 and FWPGetAmmoItemKey(result) == "Base.40HERound" then	-- INC LOADED, [GUN to HE LAUNCHER]
			for i=1, Remove do
				player:getInventory():AddItem("Base.40INCRound")				-- REMOVE INC, ADD TO INVENTORY
			end
			DebugSay(2,"Removing 40INC-Round")
			result:setCurrentAmmoCount(0);
		elseif	(Gun:getModData().TempCurrentAmmoCount) then				-- NO CROSS SWITCH
			result:setCurrentAmmoCount(Gun:getModData().TempCurrentAmmoCount)	-- LEAVE LOADED
		end

		-- ATTACHMENTS
	--	result:getModData().TempScope = (Gun:getWeaponPart("Scope"))			-- M203 SET TEMP for M16 Attachments
	--	result:getModData().TempCanon = (Gun:getWeaponPart("Canon"))			-- These will not give bonuses to
	--	result:getModData().TempStock = (Gun:getWeaponPart("Stock"))			-- SHARD ATTACHMENT BENEFIT
	--	result:getModData().TempClip = (Gun:getWeaponPart("Clip"))			-- SHARD ATTACHMENT BENEFIT
	--	result:getModData().TempSling = (Gun:getWeaponPart("Sling"))			-- SHARD ATTACHMENT BENEFIT
	--	result:getModData().TempRecoilPad = (Gun:getWeaponPart("RecoilPad"))		-- SHARD ATTACHMENT BENEFIT

--	[LAUNCHER to GUN] RESTORE ATTACHMENT FROM ModData.TempXXX
	elseif 	(isLauncher(Gun) and result:isAimedFirearm()) then
		-- AMMO TYPE DATA
		result:getModData().TempFireMode		= (Gun:getFireMode())		-- M16 SET TEMP for M203 Switchback
		result:getModData().TempContainsClip		= (Gun:isContainsClip())	
		result:getModData().TempRoundChambered		= (Gun:isRoundChambered())	
		result:getModData().TempCurrentAmmoCount	= (Gun:getCurrentAmmoCount())

		if	(Gun:getModData().TempFireMode) ~= nil then
			result:setFireMode(Gun:getModData().TempFireMode)			-- M16 SET its own FROM M203 TEMP
		end
		if	(Gun:getModData().TempContainsClip) then
			result:setContainsClip(Gun:getModData().TempContainsClip)
		end
		if	(Gun:getModData().TempRoundChambered) then
			result:setRoundChambered(Gun:getModData().TempRoundChambered)
		end
		if	(Gun:getModData().TempCurrentAmmoCount) then
			result:setCurrentAmmoCount(Gun:getModData().TempCurrentAmmoCount)
		end

		if Gun:getCurrentAmmoCount() > 0 then						-- STORE GRENADE TYPE IN M16 TEMP
			if	FWPGetAmmoItemKey(Gun) == "Base.40HERound" then			-- USE AMMOTYPE INSTEAD
				result:getModData().TempAmmoType	= 1			-- INCENDIARY
			else	result:getModData().TempAmmoType	= 2			-- EXPLOSIVE
			end
		end

	--	result:setFireMode(Gun:getModData().FireMode)					-- M16 SET its own FROM M203 TEMP REDO ABOVE
	--	result:setContainsClip(Gun:getModData().ContainsClip)				-- TO PREVENT nil ERROR
	--	result:setRoundChambered(Gun:getModData().RoundChambered)		
	--	result:setCurrentAmmoCount(Gun:getModData().CurrentAmmoCount)		

		-- ATTACHMENTS									-- NOTE: WEIGHT INACCURATE IF NO ATTACH !!!
	--	result:attachWeaponPart(Gun:getModData().TempScope)				-- Attaching (to get Bonuses back)
	--	result:attachWeaponPart(Gun:getModData().TempCanon)				-- From M203 TEMP
	--	result:attachWeaponPart(Gun:getModData().TempStock)				-- SHARED ATTACHMENT BENEFIT
	--	result:attachWeaponPart(Gun:getModData().TempClip)				-- SHARED ATTACHMENT BENEFIT
	--	result:attachWeaponPart(Gun:getModData().TempSling)				-- SHARED ATTACHMENT BENEFIT
	--	result:attachWeaponPart(Gun:getModData().TempRecoilPad)				-- SHARED ATTACHMENT BENEFIT
	end

	if (instanceof(result,"HandWeapon")) then						-- REMOVE isAimedFirearm() for BAYO (Mele)
		player:setPrimaryHandItem(result) 
		if(result:isRequiresEquippedBothHands() or result:isTwoHandWeapon()) then
			player:setSecondaryHandItem(result)
		else	player:setSecondaryHandItem(nil)
		end
	end
end


function Launcher_Test(item)
	if item:getSubCategory() == "Firearm" then
		local sling = FWPGetWeaponPart(item, "Sling")
		if (sling) and (string.find(sling:getType(), "Launcher")) then
			return true
		elseif	isLauncher(item) then
			return true
		else	return false
		end
	end
end

------------------------------------------------------------------
--  [CALIBER_WEAPON]	 										--
------------------------------------------------------------------
function Caliber_Weapon(items, result, player)
	local Gun
	for i=0,items:size() - 1 do
		if (instanceof(items:get(i),"HandWeapon")) then
			Gun = items:get(i)
		end
	end

--	======= TRANSFER CONDITION & MODE ======
	result:setCondition(Gun:getCondition());
	result:setFireMode(Gun:getFireMode());

--	====== TRANSFER AMMO MAG & CHAMBER =====
	if Gun:isContainsClip() == true then
		result:setContainsClip(true);
	end

--	====== REMOVE AMMO MAG & CHAMBER =====
	local Remove	= Gun:getCurrentAmmoCount()
	local Loaded	= FWPGetAmmoItemKey(Gun)
	local Name

	if Gun:isRoundChambered() == true then
		Remove= Remove + 1
		result:setRoundChambered(false);
	end

	if Gun:getCurrentAmmoCount() > 0 then
		for i=1, Remove do
			local NewRound = FWPCreateItem(Loaded)
			player:getInventory():AddItem(NewRound)
			if NewRound then
				Name = NewRound:getDisplayName()
			end
		end
		DebugSay(2,"Removing ("..tostring(Remove)..") "..tostring(Name))
		result:setCurrentAmmoCount(0);
	end

--	====== TRANSFER WEAPON ATTACHMENTS SO THEY DO NOT AFFECT MELEE VERSION
	if 	(result:isAimedFirearm() and Gun:isAimedFirearm()) then		-- [GUN to GUN] LEAVE THIS ALONE
		result:attachWeaponPart(Gun:getWeaponPart("Scope"))
		result:attachWeaponPart(Gun:getWeaponPart("Canon"))
		result:attachWeaponPart(Gun:getWeaponPart("Clip"))
		result:attachWeaponPart(Gun:getWeaponPart("Stock"))
		result:attachWeaponPart(Gun:getWeaponPart("Sling"))
		result:attachWeaponPart(Gun:getWeaponPart("RecoilPad"))
	end

--	if (instanceof(result,"HandWeapon")) and result:getMaxRange() > 0 then	-- REMOVE isAimedFirearm() for BAYO (Mele)
	if (instanceof(result,"HandWeapon")) then
		player:setPrimaryHandItem(result) 
		if(result:isRequiresEquippedBothHands() or result:isTwoHandWeapon()) then
			player:setSecondaryHandItem(result)
		else	player:setSecondaryHandItem(nil)
		end
	end
end


------------------------------------------------------------------
--  [CALIBER_MAGTYPE] SWITCH MAGAZINE AMMO TYPE					--
------------------------------------------------------------------
function Caliber_MagType(items, result, player)
	local Mag
	for i=0,items:size() - 1 do
	--	if (items:get(i):getDisplayCategory() == "GunMag") then
		if isMagazine(items:get(i)) then
			Mag = items:get(i)
		end
	end
	local Remove	= Mag:getCurrentAmmoCount()
	local Loaded	= FWPGetAmmoItemKey(Mag)
	local Name

	if Mag:getCurrentAmmoCount() > 0 then
		for i=1, Remove do
			local NewRound = FWPCreateItem(Loaded)
			player:getInventory():AddItem(NewRound)
			if NewRound then
				Name = NewRound:getDisplayName()
			end
		end
		DebugSay(2,"Removing ("..tostring(Remove)..") "..tostring(Name))
		result:setCurrentAmmoCount(0);
	end
end


------------------------------------------------------------------
--  [LAUNCHER RANGE] USES FIREMODE TO SET MAX RANGE				--
------------------------------------------------------------------
function Launcher_Range(player,weapon)
	local multiplier = GUNFIGHTER.OPTIONS.options.dropdown15
	local factor = 1
	if 	(multiplier ~= nil) then
		if	(multiplier == 1) then
			factor = 1.0
		elseif	(multiplier == 2) then
			factor = 1.5
		elseif	(multiplier == 3) then
			factor = 2.0
		elseif	(multiplier == 4) then
			factor = 2.5
		elseif	(multiplier == 5) then
			factor = 3.0
		end
	end

	if(player:isLocalPlayer() == true) then
		if (weapon ~= nil) and (instanceof(weapon,"HandWeapon")) and (weapon:isAimedFirearm()) then
			local scriptItem	= weapon:getScriptItem()
			local baseRange		= scriptItem:getMaxRange()	-- BASERANGE FLAMER WEAPONS CAN HAVE DIFFERENT MAX RANGE

			if (isRocket(weapon)) then				-- MIGRATE OFF FIREMODE FOR THIS
				if	weapon:getModData().Trajectory == "Short" then
					weapon:setMaxRange(24 * factor)
				elseif	weapon:getModData().Trajectory == "Medium" then
					weapon:setMaxRange(36 * factor)
				elseif	weapon:getModData().Trajectory == "Long" then
					weapon:setMaxRange(48 * factor)
				end
				local timer = (weapon:getMaxRange() * 2.5)	-- FASTER THAN NADES
				weapon:setTriggerExplosionTimer(timer)

			elseif (isLauncher(weapon)) then			-- MIGRATE OFF FIREMODE FOR THIS
				if	weapon:getModData().Trajectory == "Short" then
					weapon:setMaxRange(12 * factor)
				elseif	weapon:getModData().Trajectory == "Medium" then
					weapon:setMaxRange(18 * factor)
				elseif	weapon:getModData().Trajectory == "Long" then
					weapon:setMaxRange(24 * factor)
				end
				local timer = (weapon:getMaxRange() * 4)
				weapon:setTriggerExplosionTimer(timer)

			elseif (isFlamer(weapon)) then						--	MUSK	M2A1
				if weapon:getModData().Trajectory == "Short" then
					weapon:setMaxRange(baseRange + ZombRand(1))		--	6-7	8-9
				elseif weapon:getModData().Trajectory == "Medium" then
					weapon:setMaxRange(baseRange * 1.5 + ZombRand(2))	--	9-11	12-14
				elseif weapon:getModData().Trajectory == "Long" then
					weapon:setMaxRange(baseRange * 2 + ZombRand(3))		--	12-15	16-19
				end
				local timer = (weapon:getMaxRange() * 4)
				weapon:setTriggerExplosionTimer(timer)
				weapon:setFireMode("Auto")

				if (weapon:getMagazineType() == "Base.M2A1_Tank") then
					local back		= player:getClothingItem_Back()
					local noTank		= false

					if (back) then
						DebugSay(3,tostring(back:getType()))
						if (back:getCapacity() > 0) then	-- WORKS BUT NEED BETTER CHECK
							noTank = true
						end
					else	noTank = true
						DebugSay(3,"Nothing on Back")
					end

					if	noTank == true then
						weapon:setJammed(true)
						weapon:setMaxRange(ZombRand(2,4))
						Sound = player:getEmitter():playSound("OverFill")
						DebugSay(3,"!@#!! Ignition")
					end					-- NO NEED FOR ELSE, DEFAULTS TO SCRIPTITEM VALUE
				end
			elseif (weapon:hasTag(FWPGetItemTag("Paintball"))) then
				if weapon:getModData().Trajectory == "Short" then
					weapon:setMaxRange(baseRange + ZombRand(1))
				elseif weapon:getModData().Trajectory == "Medium" then
					weapon:setMaxRange(baseRange * 1.5 + ZombRand(2))
				elseif weapon:getModData().Trajectory == "Long" then
					weapon:setMaxRange(baseRange * 2 + ZombRand(3))
				end
				local timer = (weapon:getMaxRange() * 4)
				weapon:setTriggerExplosionTimer(timer)
			end
		else	return false
		end
	end
end

Events.OnWeaponSwing.Add(Launcher_Range)	-- WONT UPDATE INFO WINDOW UNTIL FIRED, BUT WORKS IMMEDIATELY

------------------------------------------------------------------
--  [DAMAGE MULTIPLIER]	Function								--
------------------------------------------------------------------
function Damage_Multiplier(weapon)
	local scriptItem	= weapon:getScriptItem()
	local maxDmg	= scriptItem:getMaxDamage()
	local minDmg	= scriptItem:getMinDamage()
	local canon		= FWPGetWeaponPart(weapon, "Canon")
	if (GUNFIGHTER.OPTIONS.options.dropdown141 ~= 6) then
		if	weapon:hasTag(FWPGetItemTag("XBow")) then
			local XBowMult = (GUNFIGHTER.OPTIONS.options.dropdown141 + 4) / 10			-- 0.5 to 2.0
			maxDmg = maxDmg * XBowMult
			minDmg = minDmg * XBowMult
			weapon:setMaxDamage(maxDmg)
			weapon:setMinDamage(minDmg)
		--	DebugSay(2,"Archery Damage Multiplier Applied")
		end
	end
	if (GUNFIGHTER.OPTIONS.options.dropdown147 ~= 6) then
		if	instanceof(weapon,"HandWeapon") and weapon:isAimedFirearm() and weapon:isRanged() and not isBow(weapon) and not isFlamer(weapon) and not isLauncher(weapon) and not isBBGun(weapon) then
			local FirearmMult = (GUNFIGHTER.OPTIONS.options.dropdown147 + 4) / 10			-- 0.5 to 2.0
			maxDmg = maxDmg * FirearmMult
			minDmg = minDmg * FirearmMult
			weapon:setMaxDamage(maxDmg)
			weapon:setMinDamage(minDmg)
		--	DebugSay(2,"Firearm Damage Multiplier Applied")
		end
	end
	if (GUNFIGHTER.OPTIONS.options.dropdown148 ~= 6) then
		if	instanceof(weapon,"HandWeapon") and (not weapon:isAimedFirearm() or weapon:isAimedFirearm() and not weapon:isRanged()) and not isBow(weapon) and not isFlamer(weapon) and not isLauncher(weapon) and not isBBGun(weapon) then
			local MeleeMult = (GUNFIGHTER.OPTIONS.options.dropdown148 + 4) / 10			-- 0.5 to 2.0

			if weapon:isAimedHandWeapon() then	-- DONT DO THIS GOING TO GUN MODE
				if canon then
					if string.find(canon:getType(), "Bayonet") then
						maxDmg	= 1.8
						minDmg	= 1.4
					--	DebugSay(2,"Bayo Stats Applied")
					end
				end
			end

			maxDmg = maxDmg * MeleeMult
			minDmg = minDmg * MeleeMult
			weapon:setMaxDamage(maxDmg)
			weapon:setMinDamage(minDmg)
		--	DebugSay(2,"Melee Damage Multiplier Applied")
		end
	end
end

------------------------------------------------------------------
--  [APPLY EFFECT] OF SUPPRESSORS AND BAYONETS					--
------------------------------------------------------------------
local function Apply_Effect(player, weapon)
	if weapon == nil then
		return
	end
	if not weapon:IsWeapon() then
		return;
	end
	------------------------------
	--	FLAME THROWER PACK		--
	------------------------------
	if	(FWPGetAmmoItemKey(weapon) == "Base.FlameFuel") and (weapon:getMagazineType() == "Base.M2A1_Tank") and (weapon:isContainsClip() == true) then
		local Cosmetic = FWPCreateItem('Bag_M2A1')
		player:getInventory():AddItem(Cosmetic)
		player:setWornItem(Cosmetic:canBeEquipped(), Cosmetic)
		player:getInventory():DoRemoveItem(Cosmetic)		-- REMOVE COSMETIC PACK
	end

	if	isLauncher(weapon) or isFlamer(weapon) then					-- PREVENT GRENADE DROPS
		if weapon:getModData().Trajectory == nil then
			weapon:getModData().Trajectory = "Medium"
	--		DebugSay(2,"Medium")								-- MEDIUM BUG ???
		end
	end

	--	BLOCK NO-LAUNCHER INSTALLED
	if (FWPGetAmmoItemKey(weapon) == "Base.40INCRound") or (FWPGetAmmoItemKey(weapon) == "Base.40HERound") then
		local launcher	= FWPGetWeaponPart(weapon, "Sling")
		local Integral	= weapon:getModData().Integral
		if	(string.find(weapon:getType(), "EX41")) or			-- NO STAND ALONE
			(string.find(weapon:getType(), "Federal")) or
			(string.find(weapon:getType(), "M32")) or
			(string.find(weapon:getType(), "GM94")) then
			DebugSay(3,"STAND ALONE LAUNCHER")
		elseif	( (launcher) and (string.find(launcher:getType(), "Launcher")) ) or
			( (Integral) and (Integral == "Launcher") ) then		-- HAS LAUNCHER
			DebugSay(3,"LAUNCHER INSTALLED")
		else	DebugSay(3,"LAUNCHER NOT INSTALLED")				-- NO LAUNCHER
			weapon:setCurrentAmmoCount(0)					-- PREVENT FIRING
			weapon:setMaxAmmo(0)						-- PREVENT LOADING
		end
	end

	local scriptItem	= weapon:getScriptItem()
	local soundVolume	= scriptItem:getSoundVolume()
	local soundRadius	= scriptItem:getSoundRadius()
	local suppressFactor	= 1
	local swingSound	= scriptItem:getSwingSound()
--	if	not weapon:isAimedHandWeapon() then			-- NOT MELEE TAKE-DOWN, ETC...
	if		(string.find(weapon:getType(), "Chainsaw")) then
			DebugSay(3,"IS CHAINSAW")
	elseif	weapon:getSubCategory() == "Firearm" then		-- NOT MELEE TAKE-DOWN, ETC...
			DebugSay(3,"IS FIREARM")
			swingSound = getShotSound(weapon,1)
	else		DebugSay(3,"NOT FIREARM")
	end

	local ammo		= FWPGetAmmoItemKey(weapon)
	local maxRange	= scriptItem:getMaxRange()
	local maxDmg	= scriptItem:getMaxDamage()
	local minDmg	= scriptItem:getMinDamage()
	local crit		= 0					-- getCriticalChance DONT WORK
	local impact	= scriptItem:getImpactSound()		-- DOES THIS EVEN MAKE A DIFFERENCE ?
	local canon		= FWPGetWeaponPart(weapon, "Canon")
--	local pad		= weapon:getRecoilpad()
	local clip		= FWPGetWeaponPart(weapon, "Clip")
	local bayo		= 0
	local suppress	= 1

	------------------------------------------
	--	SUPPRESSION DROPDOWN13 OPTION		--
	------------------------------------------
	local suppresslevel	= GUNFIGHTER.OPTIONS.options.dropdown13
	local basesoundlevel	= GUNFIGHTER.OPTIONS.options.dropdown14
--	local suppresslevel	= player:getModData().SuppressLevel

--	if player:getVehicle() ~= nil then
--		DebugSay("IN CAR")
--	else	DebugSay("ON FOOT")
--	end

--	PUT IN TRANSFORM ON EQUIP INSTEAD MAKE SURE ITEM NOT BRICKED FROM MISS CODE
	if	(weapon) and weapon:hasTag(FWPGetItemTag("Thrown")) and (weapon:getMaxHitCount() == 0) then					
		weapon:setMaxHitCount(scriptItem:getMaxHitCount())
		DebugSay(3,"UN-BRICKING WEAPON")
	end

	------------------------------------------
	--	LIGHTSABERS REAL BOX139 OPTION		--
	------------------------------------------
	if	(weapon) and weapon:hasTag(FWPGetItemTag("LightSaber")) then
		if		(GUNFIGHTER.OPTIONS.options.box139 == false) and (weapon:getMaxHitCount() ~= 0) then
				weapon:setMaxHitCount(0)
				DebugSay(3,"LIGHTSABERS ARE TOYS")
		elseif	(GUNFIGHTER.OPTIONS.options.box139 == true) and (weapon:getMaxHitCount() == 0) then
				weapon:setMaxHitCount(scriptItem:getMaxHitCount())
				DebugSay(3,"LIGHTSABERS ARE REAL")
		end
	end


	if 	(suppresslevel ~= nil) then
		if	(suppresslevel == 1) then
			suppress = 1.5
		elseif	(suppresslevel == 2) then
			suppress = 1.25
		elseif	(suppresslevel == 3) then
			suppress = 1
		elseif	(suppresslevel == 4) then
			suppress = 0.75
		elseif	(suppresslevel == 5) then
			suppress = 0.5
		elseif	(suppresslevel == 6) then
			suppress = 0.25			-- MIGHT BE TOO LOW
		end
	end

	if 	(basesoundlevel ~= nil) then
		local baseboost	= 0
		if	(basesoundlevel == 1) then
			baseboost = 0
		elseif	(basesoundlevel == 2) then
			baseboost = 10
		elseif	(basesoundlevel == 3) then
			baseboost = 20
		elseif	(basesoundlevel == 4) then
			baseboost = 30
		elseif	(basesoundlevel == 5) then
			baseboost = 40
		elseif	(basesoundlevel == 6) then
			baseboost = 50
		elseif	(basesoundlevel == 7) then
			baseboost = 60
		elseif	(basesoundlevel == 8) then
			baseboost = 70
		elseif	(basesoundlevel == 9) then
			baseboost = 80
		elseif	(basesoundlevel == 10) then
			baseboost = 90
		elseif	(basesoundlevel == 11) then
			baseboost = 100
		elseif	(basesoundlevel == 12) then
			baseboost = 110
		elseif	(basesoundlevel == 13) then
			baseboost = 120
		elseif	(basesoundlevel == 14) then
			baseboost = 130
		elseif	(basesoundlevel == 15) then
			baseboost = 140
		elseif	(basesoundlevel == 16) then
			baseboost = 150
		elseif	(basesoundlevel == 17) then
			baseboost = 160
		elseif	(basesoundlevel == 18) then
			baseboost = 170
		elseif	(basesoundlevel == 19) then
			baseboost = 180
		elseif	(basesoundlevel == 20) then
			baseboost = 190
		elseif	(basesoundlevel == 21) then
			baseboost = 200
		end
		if	not isBow(weapon) and not isBBGun(weapon) and not isFlamer(weapon) and not isLauncher(weapon) then	-- KEEP SILENT
			soundRadius = (soundRadius + baseboost)
			soundVolume = (soundVolume + baseboost)
		end
	end


	if weapon:isRanged() then	-- DONT SILENCE LAUNCHERS
		if (isSuppressed(weapon)) and (not isLauncher(weapon)) then
			swingSound = getShotSound(weapon,1)
			suppressFactor = getSuppressFactor(weapon)
			if (suppressFactor) then
				soundVolume = soundVolume * suppressFactor * suppress
				soundRadius = soundRadius * suppressFactor * suppress
			end

	--		INSERT NON-GENERIC SOUND FOR BURST MODE SITUATIONS (M4)
	--		local Alt = weapon:getModData().AltSwingSound
	--		if Alt ~= nil then
	--			swingSound = Alt
	--		end

		end
		if (scope) and (isLauncher(weapon)) then	-- NO SCOPE FOR LAUNCHER
			weapon:setMaxRange(maxRange)					-- USE NON-MODIFIED RANGE
		end
	elseif not weapon:isRanged() then						-- DONT DO THIS GOING TO GUN MODE
		if canon then
			if string.find(canon:getType(), "Bayonet") then			-- APPLY BAYONET STATS
				maxDmg = 1.8						-- BETWEEN MACHETTE/HUNTINGKNIFE SPEAR
				minDmg = 1.4						-- BETWEEN MACHETTE/HUNTINGKNIFE SPEAR
				crit = 20						-- SAME AS MOST SPEAR
				bayo = 0.4
				impact	= 'SpearMacheteHit'
				swingSound = 'SpearMacheteSwing'
			end
			weapon:setMaxDamage(maxDmg)	-- MOVE TO BAYO SEGMENT TO LET CHOKE WORK
			weapon:setMinDamage(minDmg)	-- MOVE TO BAYO SEGMENT TO LET CHOKE WORK
			weapon:setCriticalChance(crit)	-- MOVE TO BAYO SEGMENT JUST IN CASE
		end
--		if scope then								-- NO SCOPE FOR MELEE
		weapon:setMaxRange(maxRange + bayo)					-- USE NON-MODIFIED RANGE
--		end
	end

	--------------------------------------------------
	-- DAMAGE MULTIPLIER MOVE TO SEPARATE FUNCTION	--
	--------------------------------------------------
	Damage_Multiplier(weapon)
--[[
	if (GUNFIGHTER.OPTIONS.options.dropdown141 ~= 6) then
		if	weapon:hasTag(FWPGetItemTag("XBow")) then
			local XBowMult = (GUNFIGHTER.OPTIONS.options.dropdown141 + 4) / 10			-- 0.5 to 2.0
			maxDmg = maxDmg * XBowMult
			minDmg = minDmg * XBowMult
			weapon:setMaxDamage(maxDmg)
			weapon:setMinDamage(minDmg)
			DebugSay(2,"Archery Damage Multiplier Applied")
		end
	end
	if (GUNFIGHTER.OPTIONS.options.dropdown147 ~= 6) then
		if	instanceof(weapon,"HandWeapon") and weapon:isAimedFirearm() and weapon:isRanged() and not isBow(weapon) and not isFlamer(weapon) and not isLauncher(weapon) and not isBBGun(weapon) then
			local FirearmMult = (GUNFIGHTER.OPTIONS.options.dropdown147 + 4) / 10			-- 0.5 to 2.0
			maxDmg = maxDmg * FirearmMult
			minDmg = minDmg * FirearmMult
			weapon:setMaxDamage(maxDmg)
			weapon:setMinDamage(minDmg)
			DebugSay(2,"Firearm Damage Multiplier Applied")
		end
	end
	if (GUNFIGHTER.OPTIONS.options.dropdown148 ~= 6) then
		if	instanceof(weapon,"HandWeapon") and (not weapon:isAimedFirearm() or weapon:isAimedFirearm() and not weapon:isRanged()) and not isBow(weapon) and not isFlamer(weapon) and not isLauncher(weapon) and not isBBGun(weapon) then
			local MeleeMult = (GUNFIGHTER.OPTIONS.options.dropdown148 + 4) / 10			-- 0.5 to 2.0
			maxDmg = maxDmg * MeleeMult
			minDmg = minDmg * MeleeMult
			weapon:setMaxDamage(maxDmg)
			weapon:setMinDamage(minDmg)
			DebugSay(2,"Melee Damage Multiplier Applied")
		end
	end
]]

	if clip then									-- NOT NEEDED FOR ATTACHMENT
		if weapon:isContainsClip() == false then
			weapon:detachWeaponPart(weapon:getWeaponPart("Clip"))
			DebugSay(3,"No Mag... Deleting")
			theMag = nil
		elseif	(string.find(clip:getType(), "Extended_Mag")) then
			theMag	= weapon:getModData().ExtMagType
		elseif	(string.find(clip:getType(), "Drum_Mag")) then
			theMag	= weapon:getModData().DrumMagType
		elseif	(string.find(clip:getType(), "Standard_Mag")) then
			theMag	= weapon:getModData().MagazineType			-- WILL THIS WORK ??????
		end

		if theMag then
			TempPart = FWPCreateItem(theMag);		-- JUST TO GET MAXAMMO FROM TEMP ITEM
			weapon:setMagazineType(theMag)
			weapon:setMaxAmmo(TempPart:getMaxAmmo())
		end
	end


	showMag(weapon)			-- LOCATED IN GUNFIGHTER_FUNCTION.LUA ALSO CALLED FROM INSERT AND EJECT TIMED ACTIONS


	if weapon:isAimedFirearm() and weapon:isRanged() then	-- OR ATTACHMENTS RESULT IN NO RECOIL !??
		calcRecoilDelay(player, weapon)
		Update_TriggerGroup(weapon)							-- TESTING TRIGGER GROUP UPGRADE CODE
	end
--	weapon:getModData().TempRecoilDelay = weapon:getRecoilDelay()	-- WAS USING THIS
--	calcRecoilDelay(weapon)		-- PREVENT NIL SITUATIONS DAMNIT THIS BREAKS MELEE & TAKE DOWN MODES


	--------------------------------------------------------------------------	
	--  FLASHLIGHT MODULE - CREATED BETTER WEAPONLIGHT CODE IN FUNCTIONS	--
	--------------------------------------------------------------------------
--[[	local stock = FWPGetWeaponPart(weapon, "Stock")
	if (stock) and (string.find(stock:getType(), "Light")) then
		weapon:setCanBeActivated(true)				-- MAKES IT A FLASHLIGHT
	else	weapon:setCanBeActivated(false)				-- SUCKS ALWAYS STARTS ON
	end								-- DUE TO VANILLA ONEQUIP
]]

	weapon:setSoundVolume(soundVolume)
	weapon:setSoundRadius(soundRadius)
	weapon:setSwingSound(swingSound)
--	weapon:setMaxDamage(maxDmg)		-- MOVE TO BAYO SEGMENT TO LET CHOKE WORK
--	weapon:setMinDamage(minDmg)		-- MOVE TO BAYO SEGMENT TO LET CHOKE WORK
--	weapon:setCriticalChance(crit)		-- MOVE TO BAYO SEGMENT JUST IN CASE
	weapon:setImpactSound(impact)

	----------------------
	--  OPTIONS BOX 3   --
	----------------------
	if (GUNFIGHTER.OPTIONS.options.dropdown3) >= 2 then
		local ShowItem	=	weapon:getType()
		local ShowMaxD	=	round(weapon:getMaxDamage(),1)
		local ShowMinD	=	round(weapon:getMinDamage(),1)
		local ShowMaxR	=	round(weapon:getMaxRange(),1)
		local ShowMinR	=	round(weapon:getMinRange(),1)
		local ShowWt	=	round(getLoadedWeight(weapon),1)
		local ShowCrit	=	round(weapon:getCriticalChance(),1)
		local ShowAng	=	round(weapon:getMinAngle(),1)
		local ShowKnok	=	weapon:isKnockBackOnNoDeath()
		local ShowKick	=	round(weapon:getKnockdownMod(),1)
		local ShowPush	=	round(weapon:getPushBackMod(),1)

		if	weapon:isAimedFirearm() then
			if weapon:isRanged() then
				calcRecoilDelay(player, weapon)
				weapon:getModData().TempHitChance = weapon:getHitChance()

				local ShowHit	=	weapon:getModData().TempHitChance
				local ShowRec	=	round(weapon:getRecoilDelay(),1)
				local ShowAim	=	70 - weapon:getAimingTime()
				local ShowRel	=	round(weapon:getReloadTime(),1)
				local ShowVol	=	round(weapon:getSoundRadius(),1)

			--[[	local ITM = "TEST"	-- tostring(weapon:getType())
				local HIT = "TEST"	-- tostring(weapon:getModData().TempHitChance)
				local REC = "TEST"	-- tostring(weapon:getRecoilDelay())
				local AIM = "TEST"	-- tostring(70 - weapon:getAimingTime())
				local REL = "TEST"	-- tostring(round(weapon:getReloadTime(),1))
				local DMG = "TEST"	-- tostring(round(weapon:getMaxDamage(),1))
				local RNG = "TEST"	-- tostring(round(weapon:getMaxRange(),1))
				local WGT = "TEST"	-- tostring(round(getLoadedWeight(weapon),1))
				local SND = "TEST"	-- tostring(weapon:getSoundRadius())

				local r2 =	1.0
				local g2 =	1.0
				local b2 = 	1.0

				getTextManager():DrawString(UIFont.Small, 100, 190, ITM, r2, g2, b2, 1.0);
				getTextManager():DrawString(UIFont.Small, 100, 200, HIT, r2, g2, b2, 1.0);
				getTextManager():DrawString(UIFont.Small, 100, 210, REC, r2, g2, b2, 1.0);
				getTextManager():DrawString(UIFont.Small, 100, 220, AIM, r2, g2, b2, 1.0);
				getTextManager():DrawString(UIFont.Small, 100, 230, REL, r2, g2, b2, 1.0);
				getTextManager():DrawString(UIFont.Small, 100, 240, DMG, r2, g2, b2, 1.0);
				getTextManager():DrawString(UIFont.Small, 100, 250, RNG, r2, g2, b2, 1.0);
				getTextManager():DrawString(UIFont.Small, 100, 260, WGT, r2, g2, b2, 1.0);
				getTextManager():DrawString(UIFont.Small, 100, 270, SND, r2, g2, b2, 1.0);
			]]


				DebugSay(3,
					"NoD - "..tostring(ShowKnok)..
					"\n".."Kck - "..tostring(ShowKick)..
					"\n".."Psh - "..tostring(ShowPush)
					)
				DebugSay(1,
		--			"Firearm Mode"..
					tostring(ShowItem)..
					"\n".."Hit - "..tostring(ShowHit)..
					"\n".."Rec - "..tostring(ShowRec)..
					"\n".."Aim - "..tostring(ShowAim)..
					"\n".."Dmg - "..tostring(ShowMaxD).." / "..tostring(ShowMinD)..
					"\n".."Rng - "..tostring(ShowMaxR).." / "..tostring(ShowMinR)
					)
				DebugSay(1,
					"Rel - "..tostring(ShowRel)..
					"\n".."Ang - "..tostring(ShowAng)..
					"\n".."Crt - "..tostring(ShowCrit)..
					"\n".."Wt - "..tostring(ShowWt)..
					"\n".."Vol - "..tostring(ShowVol)
					)

			elseif	(GUNFIGHTER.OPTIONS.options.dropdown3) >= 3 then
				DebugSay(1,
		--			"Melee Mode"..
					tostring(ShowItem)..
					"\n".."Dmg - "..tostring(ShowMaxD).." / "..tostring(ShowMinD)..
					"\n".."Rng - "..tostring(ShowMaxR).." / "..tostring(ShowMinR)..
					"\n".."Ang - "..tostring(ShowAng)..
					"\n".."Crt - "..tostring(ShowCrit)..
					"\n".."Wt - "..tostring(ShowWt)
					)
			end
		elseif	(GUNFIGHTER.OPTIONS.options.dropdown3) >= 3 then
			DebugSay(1,
		--		"Melee Weapon"..
				tostring(ShowItem)..
				"\n".."Dmg - "..tostring(ShowMaxD).." / "..tostring(ShowMinD)..
				"\n".."Rng - "..tostring(ShowMaxR).." / "..tostring(ShowMinR)..
				"\n".."Ang - "..tostring(ShowAng)..
				"\n".."Crt - "..tostring(ShowCrit)..
				"\n".."Wt - "..tostring(ShowWt)
				)
		end
	end

--[[
	if getActivatedMods():contains("BetterSortCC_A26C") then
		DebugSay(1,
			"[BETTER SORTING COMPATIBILITY MOD]\n"..
			"IS *NOT* COMPATIBLE. DISABLE IT!!"
		)
	end
]]

end

Events.OnEquipPrimary.Add(Apply_Effect);

Events.OnGameStart.Add(function()
	local player = getPlayer()
	Apply_Effect(player, player:getPrimaryHandItem())
end)





--[[
--------------------------------------------------------------------------
--  IS WEAPON HAS LIGHT													--
--------------------------------------------------------------------------
function initWeaponLight(weapon)

	if getSpecificPlayer(0) == nil then return end			-- Good Lookin out go2008to

	local attacker	= getSpecificPlayer(0)
--	local weapon	= attacker:getPrimaryHandItem()
	local stock		= nil
	local sling		= nil
	local hasLaser	= nil
	local hasLight	= nil
	local charge	= nil

	if	(weapon) and (instanceof(weapon,"HandWeapon")) and (weapon:isAimedFirearm()) then
		stock	= FWPGetWeaponPart(weapon, "Stock")
		sling	= FWPGetWeaponPart(weapon, "Sling")
		if	(stock) and ( (string.find(stock:getType(), "Light")) or (stock:hasTag(FWPGetItemTag("Light"))) ) then
			hasLight = stock
			charge = hasLight:getModData().Charge
		end
		if	(sling) and ( (string.find(sling:getType(), "Light")) or (sling:hasTag(FWPGetItemTag("Light"))) ) then
			hasLight = sling
			charge = hasLight:getModData().Charge
		end
	end
	
	if		hasLight ~= nil then
			DebugSay(2,"Weapon Light Found... INIT")
			weapon:setTorchCone(false)
			weapon:setLightDistance(1)
			weapon:setLightStrength(1)
	end
end
]]







------------------------------------------------------------------
--  		OBSOLETE SCRIPT FOR REFERENCE						--
--  [UNIVERSAL_TRANSFORM] USE WHEN RECLAIMING ITEM IS REQUIRED	--
------------------------------------------------------------------
function Universal_Transform(items, result, player, action)
	local Gun
	for i=0,items:size() - 1 do
		if (instanceof(items:get(i),"HandWeapon")) then
			Gun = items:get(i)
		end
	end

	if (Gun:isAimedFirearm()) then
		if 	(Gun:getModData().TransformType == "Pistol") then	-- ADD SUPPRESSOR TYPES HERE
			player:getInventory():AddItem("Base.PistolSuppressor")
		elseif	(Gun:getModData().TransformType == "Rifle") then
			player:getInventory():AddItem("Base.RifleSuppressor")
		elseif	(Gun:getModData().TransformType == "Large") then
			player:getInventory():AddItem("Base.LargeSuppressor")
		end
	else
		if	(Gun:getModData().TransformType == "Bayonet") then	-- ADD BAYONET TYPES HERE
			player:getInventory():AddItem("Base.Bayonet")
		elseif	(Gun:getModData().TransformType == "AKBayonet") then
			player:getInventory():AddItem("Base.AKBayonet")
		elseif	(Gun:getModData().TransformType == "M1917Bayonet") then
			player:getInventory():AddItem("Base.M1917Bayonet")
		end
	end


--	======= TRANSFER CONDITION & MODE ======
	result:setCondition(Gun:getCondition());
	result:setFireMode(Gun:getFireMode());

--	====== TRANSFER AMMO MAG & CHAMBER =====
	if 	(Gun:isContainsClip() == true) then
		result:setContainsClip(true);
	end
	if Gun:isRoundChambered() == true then
		result:setRoundChambered(true);
	end
	result:setCurrentAmmoCount(Gun:getCurrentAmmoCount());

--	====== TRANSFER WEAPON ATTACHMENTS SO THEY DO NOT AFFECT MELEE VERSION
	if 	(result:isAimedFirearm() and Gun:isAimedFirearm()) then		-- [GUN to GUN] LEAVE THIS ALONE
		result:attachWeaponPart(Gun:getWeaponPart("Scope"))
		result:attachWeaponPart(Gun:getWeaponPart("Canon"))
		result:attachWeaponPart(Gun:getWeaponPart("Clip"))
		result:attachWeaponPart(Gun:getWeaponPart("Stock"))
		result:attachWeaponPart(Gun:getWeaponPart("Sling"))
		result:attachWeaponPart(Gun:getWeaponPart("RecoilPad"))
	elseif 	(not Gun:isAimedFirearm() and result:isAimedFirearm()) then	-- [MELEE to GUN] RESTORE ATTACHMENT FROM ModData.TempXXX
		result:attachWeaponPart(Gun:getModData().TempScope)
		result:attachWeaponPart(Gun:getModData().TempCanon)
		result:attachWeaponPart(Gun:getModData().TempClip)
		result:attachWeaponPart(Gun:getModData().TempStock)
		result:attachWeaponPart(Gun:getModData().TempSling)
		result:attachWeaponPart(Gun:getModData().TempRecoilPad)
	elseif 	(Gun:isAimedFirearm() and not result:isAimedFirearm()) then	-- [GUN to MELEE] SAVE ATTACHMENT TO ModData.TempXXX
		result:getModData().TempScope = (Gun:getWeaponPart("Scope"))
		result:getModData().TempCanon = (Gun:getWeaponPart("Canon"))
		result:getModData().TempClip  = (Gun:getWeaponPart("Clip"))
		result:getModData().TempStock = (Gun:getWeaponPart("Stock"))
		result:getModData().TempSling = (Gun:getWeaponPart("Sling"))
		result:getModData().TempRecoilPad = (Gun:getWeaponPart("RecoilPad"))
	end

	if (instanceof(result,"HandWeapon")) then	-- REMOVE isAimedFirearm() for BAYO (Mele)
		player:setPrimaryHandItem(result) 
		if(result:isRequiresEquippedBothHands() or result:isTwoHandWeapon()) then
			player:setSecondaryHandItem(result)
		else	player:setSecondaryHandItem(nil)
		end
	end
end


------------------------------------------------------------------
--  		OBSOLETE SCRIPT FOR REFERENCE						--
--  [UNIVERSAL_STRIPPERCLIP] USE VIA CONTEXT MENU (OBSOLETE)	--
------------------------------------------------------------------
function Universal_StripperClip(items, result, player)
	local Gun
	local Clip
	local ClipAmmo
	local Sound
	for i=0,items:size() - 1 do
		if (instanceof(items:get(i),"HandWeapon")) and (items:get(i):isAimedFirearm()) then
			Gun = items:get(i)
		elseif (items:get(i):getDisplayCategory() == "GunMag") and (items:get(i):getCurrentAmmoCount() > 0) then
			Clip = items:get(i)
		end
	end

	local LoadedGun = player:getInventory():AddItem(Gun)		-- ADD REPLACED GUN TO INVENTORY
	local Current = Gun:getCurrentAmmoCount()
	local Max = Gun:getMaxAmmo()
	if Clip then
		ClipAmmo = Clip:getCurrentAmmoCount()
	else	ClipAmmo = 0
	end

	if	((Gun:getMagazineType() ~= nil) and (Gun:isContainsClip() == false)) then
		player:Say("No Magazine...")
	        Sound = player:getEmitter():playSound("ZeroClip")
		result:setCurrentAmmoCount(ClipAmmo)			-- RETURN ALL AMMO
	elseif 	(Clip == nil) then
		player:Say("Clip Empty("..tostring(Current)..")")
	        Sound = player:getEmitter():playSound("ZeroClip")
	else								-- MATH
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

		result:setCurrentAmmoCount(GoBack)
		LoadedGun:setCurrentAmmoCount(Current + GoIn);

		if	Current == Max then					-- CAN MAKE AS DETAILED AS YOU WANT
		        Sound = player:getEmitter():playSound("ZeroClip")	-- EXAMPLE SHOWS (3) DIFFERENT RESULTS
			player:Say("Mag Full("..tostring(Current)..")")
		elseif	GoIn == 0 then
		        Sound = player:getEmitter():playSound("ZeroClip")
			player:Say("Clip Empty("..tostring(Current)..")")
		elseif	GoIn < 5 then
		        Sound = player:getEmitter():playSound("PartialClip")
			player:Say("+"..tostring(GoIn).."("..tostring(Current + GoIn)..")")
		elseif	GoIn >= 5 then
		        Sound = player:getEmitter():playSound("StripClip")
			player:Say("+"..tostring(GoIn).."("..tostring(Current + GoIn)..")")
		end
	end

        local radius = 5							-- NOT EVEN SURE IF LOADING SHOULD ATTRACT ZOMBIES
        addSound(player, player:getX(), player:getY(), player:getZ(), radius, radius)

	if (instanceof(LoadedGun,"HandWeapon")) then
		player:setPrimaryHandItem(LoadedGun) 
		if(LoadedGun:isRequiresEquippedBothHands() or result:isTwoHandWeapon()) then
			player:setSecondaryHandItem(LoadedGun)
		else	player:setSecondaryHandItem(nil)
		end
	end
end

------------------------------------------------------------------
--  		OBSOLETE SCRIPT FOR REFERENCE						--
--  [LAUNCHER_MAGTYPE] OBSOLETE	USE CALIBER_MAGTYPE INSTEAD		--
------------------------------------------------------------------
function Launcher_MagType(items, result, player)
	local Mag
	for i=0,items:size() - 1 do
		if (items:get(i):getDisplayCategory() == "GunMag") then
			Mag = items:get(i)
		end
	end
		local Remove = Mag:getCurrentAmmoCount()

	if Mag:getCurrentAmmoCount() > 0 then
		if	result:getModData().TransformType == "INC" then			-- WITH ONLY 2 TYPES, ALWAYS UNLOAD
			for i=1, Remove do
				player:getInventory():AddItem("Base.40HERound")		-- REMOVE HE, ADD TO INVENTORY
			end
			player:Say("Removing 40HE-Round")
		else	for i=1, Remove do
				player:getInventory():AddItem("Base.40INCRound")	-- REMOVE INC, ADD TO INVENTORY
			end
			player:Say("Removing 40INC-Round")
		end
		result:setCurrentAmmoCount(0);						-- NEVER LOADED FOR [LAUNCHER to LAUNCHER]
	end
end
