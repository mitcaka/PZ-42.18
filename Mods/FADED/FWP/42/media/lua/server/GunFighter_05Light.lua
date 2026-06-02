--[[			

	TRY LIGHT BEHAVIOR HERE FOR MP COMPAT

]]			

--------------------------------------------------------------------------
--  WEAPON LIGHT RUNTIME FACTOR											--
--------------------------------------------------------------------------
local function getWeaponLightRuntime()
	local	setting = (GUNFIGHTER.OPTIONS.options.dropdown145)
	if		setting == 1  then	return 0
	elseif	setting == 2  then	return 0.000001
	elseif	setting == 3  then	return 0.000005
	elseif	setting == 4  then	return 0.00001
	elseif	setting == 5  then	return 0.00005
	elseif	setting == 6  then	return 0.0001
	elseif	setting == 7  then	return 0.0005
	elseif	setting == 8  then	return 0.001
	elseif	setting == 9  then	return 0.005
	elseif	setting == 10 then	return 0.5		-- 0.01
	else						return 0
	end
end


local WeaponLight = {}
local WeaponLaser = {}


--------------------------------------------------------------------------
--  WEAPON LIGHT BEAM BEHAVIOR											--
--------------------------------------------------------------------------
local function WeaponLightBeam(attacker)

--	local attacker	= getSpecificPlayer(0)
	local weapon	= nil

	if attacker		~= nil then				-- PREVENT RESPAWN ERRORS
		weapon	= attacker:getPrimaryHandItem()
		second	= attacker:getSecondaryHandItem()
	end

	local stock	= nil
	local sling	= nil
	local scope	= nil
	local light = nil
	local laser = nil
	local Glow
	local Glow2
	local charge
	local charge2

	

	if (weapon) and (instanceof(weapon,"HandWeapon")) and (weapon:isAimedFirearm()) then
		stock	= FWPGetWeaponPart(weapon, "Stock")
		sling	= FWPGetWeaponPart(weapon, "Sling")
		scope	= FWPGetWeaponPart(weapon, "Scope")
	end

	if		(stock) and ( (string.find(stock:getType(), "Light")) or (stock:hasTag(FWPGetItemTag("Light"))) ) and
			(stock:getModData().Charge and stock:getModData().Charge > 0) then
			light = stock
			charge = light:getModData().Charge
	end
	if		(stock) and ( (string.find(stock:getType(), "Laser")) or (stock:hasTag(FWPGetItemTag("Laser"))) ) and
			(stock:getModData().Charge and stock:getModData().Charge > 0) then
			laser = stock
			charge = laser:getModData().Charge
	end
	if		(sling) and ( (string.find(sling:getType(), "Light")) or (sling:hasTag(FWPGetItemTag("Light"))) ) and
			(sling:getModData().Charge and sling:getModData().Charge > 0) then	
			light = sling
			charge2 = light:getModData().Charge
	end
	if		(sling) and ( (string.find(sling:getType(), "Laser")) or (sling:hasTag(FWPGetItemTag("Laser"))) ) and
			(sling:getModData().Charge and sling:getModData().Charge > 0) then	
			laser = sling
			charge2 = laser:getModData().Charge
	end

--	if		(sling) and (string.find(sling:getType(), "Light") or string.find(sling:getType(), "Laser")) then
--			light = sling
--	elseif	(stock) and (string.find(stock:getType(), "Light") or string.find(stock:getType(), "Laser")) then
--			light = stock
--	end

	if		WeaponLight[attacker] ~= nil then				-- ALWAYS OFF FIRST
			WeaponLight[attacker]:setActive(false)
			getCell():removeLamppost(WeaponLight[attacker])
	end
	if		WeaponLaser[attacker] ~= nil then				-- ALWAYS OFF FIRST
			WeaponLaser[attacker]:setActive(false)
			getCell():removeLamppost(WeaponLaser[attacker])
	end
	

	if		attacker:getModData().LaserFX ~= nil then		-- ALWAYS OFF FIRST
			getCell():removeLamppost(attacker:getModData().LaserFX)
			attacker:getModData().LaserFX = nil
	end
	if		attacker:getModData().LightFX ~= nil then		-- ALWAYS OFF FIRST
			getCell():removeLamppost(attacker:getModData().LightFX)
			attacker:getModData().LightFX = nil
	end
	if		attacker:getModData().Glow ~= nil then			-- ALWAYS OFF FIRST
			getCell():removeLamppost(attacker:getModData().Glow)
			attacker:getModData().Glow = nil
	end
	if		attacker:getModData().Glow2 ~= nil then			-- ALWAYS OFF FIRST
			getCell():removeLamppost(attacker:getModData().Glow2)
			attacker:getModData().Glow2 = nil
	end

	--------------------------
	--	WEAPON LASER		--
	--------------------------
	if	(laser) then
		if stock ~= nil then
			togStock = FWPCreateItem(stock:getModData().Mode_Toggle)
		end
		--------------------------
		--	SHUTDOWN IF EMPTY	--
		--------------------------		
		if	weapon:getModData().LaserOn == false and (string.find(stock:getType(), "_ON")) then
			togStock:getModData().Charge = laser:getModData().Charge			-- TRY KEEPING CHARGE
			togStock:setColorRed(laser:getColorRed())							-- TRY KEEPING COLOR
			togStock:setColorGreen(laser:getColorGreen())						-- TRY KEEPING COLOR
			togStock:setColorBlue(laser:getColorBlue())							-- TRY KEEPING COLOR
			weapon:attachWeaponPart(togStock)
--			checkHotbar(attacker, weapon, weapon, 1)							-- NO NEED, MESSES UP WHEN FOLDING, ETC.
			ReEquipIt(attacker, weapon)
		--	DebugSay(2,"Shutdown Laser")
		end
		--------------------------
		--	AUTO WHEN AIM		--
		--------------------------
		if	(GUNFIGHTER.OPTIONS.options.dropdown144 >= 3) then
			local autotog = nil
			if weapon:getModData().LaserOn == nil then
				weapon:getModData().LaserOn = false
			end
			
			if		attacker:isAiming() and weapon:getModData().LaserOn == false and (not string.find(stock:getType(), "_ON")) and charge and charge > 0 then
					weapon:getModData().LaserOn = true
					autotog = true
				--	DebugSay(2,"Laser ON")
			elseif	not attacker:isAiming() and weapon:getModData().LaserOn == true and (string.find(stock:getType(), "_ON")) then
					weapon:getModData().LaserOn = false
					autotog = true
				--	DebugSay(2,"Laser OFF")
			end

			if	(stock) and (togStock) and (autotog == true) then
				attacker:playSound("weaponLight");
				----------------------
				--	TRANSFER CHARGE	--
				----------------------
				togStock:getModData().Charge = laser:getModData().Charge
				togStock:setColorRed(laser:getColorRed())
				togStock:setColorGreen(laser:getColorGreen())
				togStock:setColorBlue(laser:getColorBlue())
				weapon:attachWeaponPart(togStock)
--				checkHotbar(attacker, weapon, weapon, 1)					-- NO NEED, MESSES UP WHEN FOLDING, ETC.
				ReEquipIt(attacker, weapon)
			end
		end
		
		------------------------------
		--	OPTIONAL GLOW EFFECT	--
		------------------------------
		if	(GUNFIGHTER.OPTIONS.options.dropdown144 == 1) or (GUNFIGHTER.OPTIONS.options.dropdown144 == 3) then
			if	(weapon:getModData().LaserOn == true) then
				local	flicktime = 1
				if		ZombRand(1 + weapon:getCondition()) == 0 then
						flicktime = 0
				end
				
			--	DebugSay(2,"R - "..tostring(laser:getColorRed()).."/ G - "..tostring(laser:getColorGreen()).." / B - "..tostring(laser:getColorBlue()))
				
				if		(laser:getColorRed() == 1) and (laser:getColorGreen() == 1) and (laser:getColorBlue() == 1) then		-- HAS NO COLOR ASSIGNED (1) IS MAX BRIGHT
					--	DebugSay(2,"SCRIPT COLORS")
						WeaponLaser[attacker] = IsoLightSource.new(attacker:getX(), attacker:getY(), attacker:getZ(), laser:getR(), laser:getG(), laser:getB(), (flicktime))	-- SCRIPT COLORS
				else	WeaponLaser[attacker] = IsoLightSource.new(attacker:getX(), attacker:getY(), attacker:getZ(), laser:getColorRed(), laser:getColorGreen(), laser:getColorBlue(), (flicktime))
					--	DebugSay(2,"TOGGLE SET COLORS")
				end
				getCell():addLamppost(WeaponLaser[attacker])
				attacker:getModData().LaserFX = WeaponLaser[attacker]
			end
		end
		
		--------------------------
		--	DRAIN BATTERY		--
		--------------------------
		if	weapon:getModData().LaserOn == true then
			charge = laser:getModData().Charge
			if	charge ~= nil then
				if	charge > 0 then
					laser:getModData().Charge = charge - (getWeaponLightRuntime() * laser:getModData().Runtime)
					weapon:getModData().Charge = laser:getModData().Charge
			--		DebugSay(2,"Laser Drain - "..tostring(round(getWeaponLightRuntime() * laser:getModData().Runtime * 10000,1) ) )
					---------------
					--	SHUTDOWN --
					---------------
					if	weapon:getModData().Charge <= 0 then
						DebugSay(2,"(1) No Charge")
						attacker:playSound("weaponLight")
						laser:getModData().Charge = 0		-- PREVENT NEGATIVE
						stock:getModData().Charge = 0		-- PREVENT NEGATIVE
						weapon:getModData().Charge = 0		-- PREVENT NEGATIVE
						weapon:getModData().LaserOn = false
						weapon:setActivated(false)				-- TRY ACTIVATED
						weapon:attachWeaponPart(togStock)
						ReEquipIt(attacker, weapon)
					end			
				elseif charge <= 0 then
					DebugSay(2,"(1) No Charge")
					attacker:playSound("weaponLight")
					weapon:getModData().LaserOn = false
					weapon:attachWeaponPart(togStock)
			--		checkHotbar(attacker, weapon, weapon, 1)					-- NO NEED, MESSES UP WHEN FOLDING, ETC.
					ReEquipIt(attacker, weapon)
				end
			end
		end
	end

	--------------------------
	--	WEAPON LIGHT		--
	--------------------------
	if	(weapon) and (light) and (weapon:getModData().LightOn == true) then
		if		light == stock then
				charge = stock:getModData().Charge
		elseif	light == sling then
				charge2 = sling:getModData().Charge
		end

		local	Flood = 1
		--------------------------
		--	DRAIN BATTERY		--
		--------------------------
		if	charge2 ~= nil then
			if	charge2 > 0 then
				if light == sling then
					sling:getModData().Charge = charge2 - (getWeaponLightRuntime() * sling:getModData().Runtime)
					weapon:getModData().Charge2 = sling:getModData().Charge
				--	DebugSay(2,"(2) Charge - "..tostring(round(weapon:getModData().Charge2,1) ) )
					---------------
					--	SHUTDOWN --
					---------------
					if	weapon:getModData().Charge2 <= 0 then
				--		DebugSay(2,"(2) No Charge")
						attacker:playSound("weaponLight")
						light:getModData().Charge = 0		-- PREVENT NEGATIVE
						sling:getModData().Charge = 0		-- PREVENT NEGATIVE
						weapon:getModData().Charge2 = 0		-- PREVENT NEGATIVE
						weapon:getModData().LightOn = false
						weapon:setActivated(false)				-- TRY ACTIVATED
					end
				end
			end
		elseif charge ~= nil then
			if charge > 0 then
				if light == stock then
					stock:getModData().Charge = charge - (getWeaponLightRuntime() * stock:getModData().Runtime)
					weapon:getModData().Charge = stock:getModData().Charge
				--	DebugSay(2,"(1) Charge - "..tostring(round(weapon:getModData().Charge,1) ) )
					---------------
					--	SHUTDOWN --
					---------------
					if	weapon:getModData().Charge <= 0 then
				--		DebugSay(2,"(1) No Charge")
						attacker:playSound("weaponLight")
						light:getModData().Charge = 0		-- PREVENT NEGATIVE
						stock:getModData().Charge = 0		-- PREVENT NEGATIVE
						weapon:getModData().Charge = 0		-- PREVENT NEGATIVE
						weapon:getModData().LightOn = false
						weapon:setActivated(false)				-- TRY ACTIVATED
					end					
				end
			--	DebugSay(2,"Light Drain - "..tostring(round(getWeaponLightRuntime() * laser:getModData().Runtime * 10000,1) ) )
			elseif charge <= 0 then
				weapon:getModData().LightOn = false
				weapon:setActivated(false)				-- TRY ACTIVATED
			end
		end

		weapon:setActivated(true)				-- TRY ACTIVATED

		if	attacker:isAiming() then

			weapon:setTorchCone(true)						-- THROW PATTERN
			if		(string.find(light:getType(), "Small")) then
					Flood = 1.5
					weapon:setLightDistance(10)
					weapon:setLightStrength(1.5)
			elseif	(string.find(light:getType(), "Medium")) then
					Flood = 1.0
					weapon:setLightDistance(15)
					weapon:setLightStrength(1.25)
			elseif	(string.find(light:getType(), "Large")) then
					Flood = 0.5
					weapon:setLightDistance(20)
					weapon:setLightStrength(1)
			elseif	(string.find(light:getType(), "PEQ")) then		-- SMALL LESS THAN DVAL
					Flood = 1.5
					weapon:setLightDistance(10)
					weapon:setLightStrength(1.5)
			elseif	(string.find(light:getType(), "DVAL")) then
					Flood = 1.0
					weapon:setLightDistance(15)
					weapon:setLightStrength(1.25)
			end
		else
			weapon:setTorchCone(false)						-- FLOOD PATTERN
			weapon:setLightDistance(0)						-- USE GLOW METHOD INSTEAD
			weapon:setLightStrength(0)						-- USE GLOW METHOD INSTEAD
			if		(string.find(light:getType(), "Small")) then
					Flood = 2.5
				--	weapon:setLightDistance(2.5)
				--	weapon:setLightStrength(0.5)
			elseif	(string.find(light:getType(), "Medium")) then
					Flood = 2.0
				--	weapon:setLightDistance(2.0)
				--	weapon:setLightStrength(1.0)
			elseif	(string.find(light:getType(), "Large")) then
					Flood = 1.5
				--	weapon:setLightDistance(1.5)
				--	weapon:setLightStrength(2.0)
			elseif	(string.find(light:getType(), "PEQ")) then		-- SMALL MORE THAN DVAL
					Flood = 2.5
				--	weapon:setLightDistance(2.5)
				--	weapon:setLightStrength(0.5)
			elseif	(string.find(light:getType(), "DVAL")) then
					Flood = 2.0
				--	weapon:setLightDistance(2.0)
				--	weapon:setLightStrength(1.0)
			end
		end
		
		WeaponLight[attacker] = IsoLightSource.new(attacker:getX(), attacker:getY(), attacker:getZ(), 1, 1, 1, Flood)
		getCell():addLamppost(WeaponLight[attacker])
		attacker:getModData().LightFX = WeaponLight[attacker]
			
	--------------------------
	--	NIGHT VISION		--
	--------------------------
	elseif	(scope) and (scope:hasTag(FWPGetItemTag("NVITEM"))) then				-- CHECK NV LAST SO LIGHT PREVAILS
			weapon:setTorchCone(false)
			if attacker:isAiming() then
				weapon:setLightDistance(0.01)
				weapon:setLightStrength(0.01)
			else
				weapon:setLightDistance(0)
				weapon:setLightStrength(0)
			end
	elseif	(weapon) and (instanceof(weapon,"HandWeapon")) and (weapon:isAimedFirearm()) then	-- FIX FOR NORMAL LIGHTS GETTING FORCED OFF
			weapon:setTorchCone(false)
			weapon:setLightDistance(0)
			weapon:setLightStrength(0)
			
			weapon:setActivated(false)				-- TRY ACTIVATED
			
	--------------------------
	--	LIGHT SABER	PRIMARY	--
	--------------------------
	elseif	(weapon) and (weapon:hasTag(FWPGetItemTag("LightSaber")) or weapon:hasTag(FWPGetItemTag("Torch"))) then
		if	(weapon:getCondition() >= 1) then
			local SpriteA	= weapon:getModData().SpriteA
			local SpriteB	= weapon:getModData().SpriteB
			local SpriteC	= weapon:getModData().SpriteC
			local SpriteD	= weapon:getModData().SpriteD
			local SpriteO	= weapon:getModData().SpriteOFF

			local Condition	= weapon:getCondition()
			if weapon:hasTag(FWPGetItemTag("LightSaber")) then
				Condition = Condition / 10
			elseif weapon:hasTag(FWPGetItemTag("Torch")) then
				weapon:setActivated(true)
				weapon:setTorchCone(false)
				weapon:setLightDistance(8)
				weapon:setLightStrength(0.8)
			end

--			Glow = attacker:getModData().Glow
		--	if Glow ~= nil then
		--		getCell():removeLamppost(Glow)
		--		attacker:getModData().Glow = nil
		--	end

		--	weapon:setActivated(true)			-- TRY ACTIVATED
		--	weapon:setTorchCone(false)			-- TRY ACTIVATED
		--	weapon:setLightDistance(4)			-- TRY ACTIVATED
		--	weapon:setLightStrength(2)			-- TRY ACTIVATED

			if	ZombRand(1 + weapon:getCondition()) == 0 then	-- FLICKER
				WeaponLight[attacker] = IsoLightSource.new(attacker:getX(), attacker:getY(), attacker:getZ(),  weapon:getR(), weapon:getG(), weapon:getB(), (1 + Condition / 4))
			else
				WeaponLight[attacker] = IsoLightSource.new(attacker:getX(), attacker:getY(), attacker:getZ(),  weapon:getR(), weapon:getG(), weapon:getB(), (2 + Condition / 4))
			end
			getCell():addLamppost(WeaponLight[attacker])
			attacker:getModData().Glow = WeaponLight[attacker]
			
		--	DebugSay(2,"RGB - "..tostring(weapon:getR()).."/"..tostring(weapon:getG()).."/"..tostring(weapon:getB()) )

			if	ZombRand(4) == 0 then
				if 		weapon:getWeaponSprite() == SpriteA then
						weapon:setWeaponSprite(SpriteB)
				elseif	weapon:getWeaponSprite() == SpriteB then
						weapon:setWeaponSprite(SpriteA)
				elseif	weapon:getWeaponSprite() == SpriteC then
						weapon:setWeaponSprite(SpriteD)
				elseif	weapon:getWeaponSprite() == SpriteD then
						weapon:setWeaponSprite(SpriteC)
				else	weapon:setWeaponSprite(SpriteO)
				end
				ReEquipIt(attacker,weapon)
		--		DebugSay(2,"CHANGE - "..tostring(weapon:getWeaponSprite()))
			end
		end
		if	(weapon:hasTag(FWPGetItemTag("Torch"))) or (weapon:hasTag(FWPGetItemTag("LightSaber"))) then
			TorchCondition(attacker, weapon)
		end
--	elseif	attacker:getModData().Glow ~= nil then		-- ALWAYS OFF IF NONE OF ABOVE
--			getCell():removeLamppost(attacker:getModData().Glow)
--			attacker:getModData().Glow = nil
	end

	------------------------------
	--	LIGHT SABER	SECONDARY	--
	------------------------------
	if	(second) and (second:hasTag(FWPGetItemTag("LightSaber")) or second:hasTag(FWPGetItemTag("Torch"))) then
		if	(second:getCondition() >= 1) then
			local SpriteA = second:getModData().SpriteNORM_S
			local SpriteB = second:getModData().SpriteB
			local SpriteE = second:getModData().SpriteREST_S
			local SpriteF = second:getModData().SpriteFLEX_S
			local SpriteO = second:getModData().SpriteOFF
			if not second:hasTag(FWPGetItemTag("Flex")) then
				SpriteA = second:getModData().SpriteA
			end

			local Condition	= second:getCondition()
			if second:hasTag(FWPGetItemTag("LightSaber")) then
				Condition = Condition / 10
			elseif second:hasTag(FWPGetItemTag("Torch")) then
				second:setActivated(true)
				second:setTorchCone(false)
				second:setLightDistance(8)
				second:setLightStrength(0.8)
			end

--			Glow2 = attacker:getModData().Glow2
		--	if Glow2 ~= nil then
		--		getCell():removeLamppost(Glow2)
		--		attacker:getModData().Glow2 = nil
		--	end

			if	ZombRand(1 + second:getCondition()) == 0 then	-- FLICKER
				WeaponLight[attacker] = IsoLightSource.new(attacker:getX(), attacker:getY(), attacker:getZ(),  second:getR(), second:getG(), second:getB(), (1 + Condition / 4))
			else
				WeaponLight[attacker] = IsoLightSource.new(attacker:getX(), attacker:getY(), attacker:getZ(),  second:getR(), second:getG(), second:getB(), (2 + Condition / 4))
			end
			getCell():addLamppost(WeaponLight[attacker])
			attacker:getModData().Glow2 = WeaponLight[attacker]

		--	DebugSay(2,"RGB - "..tostring(second:getR()).."/"..tostring(second:getG()).."/"..tostring(second:getB()) )

			if	ZombRand(4) == 0 then
				if 		second:getWeaponSprite() == SpriteA then
						second:setWeaponSprite(SpriteB)
				elseif	second:getWeaponSprite() == SpriteB then
						second:setWeaponSprite(SpriteA)
				elseif	second:getWeaponSprite() == SpriteE then
						second:setWeaponSprite(SpriteF)
				elseif	second:getWeaponSprite() == SpriteF then
						second:setWeaponSprite(SpriteE)
				else	second:setWeaponSprite(SpriteO)
				end
				attacker:setSecondaryHandItem(second)
		--		DebugSay(2,"CHANGE - "..tostring(second:getWeaponSprite()))
			end
		end
		if	(second:hasTag(FWPGetItemTag("Torch"))) or (second:hasTag(FWPGetItemTag("LightSaber"))) then
			TorchCondition(attacker, second)
		end
--	elseif	attacker:getModData().Glow2 ~= nil then		-- ALWAYS OFF IF NONE OF ABOVE
--			getCell():removeLamppost(attacker:getModData().Glow2)
--			attacker:getModData().Glow2 = nil
	end
end

Events.OnPlayerUpdate.Add(WeaponLightBeam)




--[[

--------------------------------------------------------------------------
--  WEAPON LIGHT BEAM BEHAVIOR			BACK UP							--
--------------------------------------------------------------------------
local function WeaponLightBeam()

	local attacker	= getSpecificPlayer(0)
	local weapon	= nil

	if attacker		~= nil then				-- PREVENT RESPAWN ERRORS
		weapon	= attacker:getPrimaryHandItem()
		second	= attacker:getSecondaryHandItem()
	end

	local stock	= nil
	local sling	= nil
	local scope	= nil
	local light = nil
	local laser = nil
	local Glow
	local Glow2
	local charge

	if (weapon) and (instanceof(weapon,"HandWeapon")) and (weapon:isAimedFirearm()) then
		stock	= FWPGetWeaponPart(weapon, "Stock")
		sling	= FWPGetWeaponPart(weapon, "Sling")
		scope	= FWPGetWeaponPart(weapon, "Scope")
	end

	if		(stock) and ( (string.find(stock:getType(), "Light")) or (stock:hasTag(FWPGetItemTag("Light"))) ) then
			light = stock
			charge = light:getModData().Charge
	end
	if		(stock) and ( (string.find(stock:getType(), "Laser")) or (stock:hasTag(FWPGetItemTag("Laser"))) ) then
			laser = stock
			charge = laser:getModData().Charge
	end
	if		(sling) and ( (string.find(sling:getType(), "Light")) or (sling:hasTag(FWPGetItemTag("Light"))) ) then
			light = sling
			charge = light:getModData().Charge
	end
	if		(sling) and ( (string.find(sling:getType(), "Laser")) or (sling:hasTag(FWPGetItemTag("Laser"))) ) then
			laser = sling
			charge = laser:getModData().Charge
	end

--	if		(sling) and (string.find(sling:getType(), "Light") or string.find(sling:getType(), "Laser")) then
--			light = sling
--	elseif	(stock) and (string.find(stock:getType(), "Light") or string.find(stock:getType(), "Laser")) then
--			light = stock
--	end

	if		attacker:getModData().Glow ~= nil then		-- ALWAYS OFF FIRST
			getCell():removeLamppost(attacker:getModData().Glow)
			attacker:getModData().Glow = nil
	end
	if		attacker:getModData().Glow2 ~= nil then		-- ALWAYS OFF FIRST
			getCell():removeLamppost(attacker:getModData().Glow2)
			attacker:getModData().Glow2 = nil
	end

	--------------------------
	--	WEAPON LASER		--
	--------------------------
	if	(laser) then
		if stock ~= nil then
			togStock = FWPCreateItem(stock:getModData().Mode_Toggle)
		end
		--------------------------
		--	SHUTDOWN IF EMPTY	--
		--------------------------		
		if	weapon:getModData().LaserOn == false and (string.find(stock:getType(), "_ON")) then
			togStock:getModData().Charge = laser:getModData().Charge			-- TRY KEEPING CHARGE
			togStock:setColorRed(laser:getColorRed())							-- TRY KEEPING COLOR
			togStock:setColorGreen(laser:getColorGreen())						-- TRY KEEPING COLOR
			togStock:setColorBlue(laser:getColorBlue())							-- TRY KEEPING COLOR
			weapon:attachWeaponPart(togStock)
--			checkHotbar(attacker, weapon, weapon, 1)							-- NO NEED, MESSES UP WHEN FOLDING, ETC.
			ReEquipIt(attacker, weapon)
		--	DebugSay(2,"Shutdown Laser")
		end
		--------------------------
		--	AUTO WHEN AIM		--
		--------------------------
		if	(GUNFIGHTER.OPTIONS.options.dropdown144 >= 3) then
			local autotog = nil
			if weapon:getModData().LaserOn == nil then
				weapon:getModData().LaserOn = false
			end
			
			if		attacker:isAiming() and weapon:getModData().LaserOn == false and (not string.find(stock:getType(), "_ON")) and charge and charge > 0 then
					weapon:getModData().LaserOn = true
					autotog = true
				--	DebugSay(2,"Laser ON")
			elseif	not attacker:isAiming() and weapon:getModData().LaserOn == true and (string.find(stock:getType(), "_ON")) then
					weapon:getModData().LaserOn = false
					autotog = true
				--	DebugSay(2,"Laser OFF")
			end

			if	(stock) and (togStock) and (autotog == true) then
				attacker:playSound("weaponLight");
				----------------------
				--	TRANSFER CHARGE	--
				----------------------
				togStock:getModData().Charge = laser:getModData().Charge
				togStock:setColorRed(laser:getColorRed())
				togStock:setColorGreen(laser:getColorGreen())
				togStock:setColorBlue(laser:getColorBlue())
				weapon:attachWeaponPart(togStock)
--				checkHotbar(attacker, weapon, weapon, 1)					-- NO NEED, MESSES UP WHEN FOLDING, ETC.
				ReEquipIt(attacker, weapon)
			end
		end
		
		------------------------------
		--	OPTIONAL GLOW EFFECT	--
		------------------------------
		if	(GUNFIGHTER.OPTIONS.options.dropdown144 == 1) or (GUNFIGHTER.OPTIONS.options.dropdown144 == 3) then
			if	(weapon:getModData().LaserOn == true) then
				local	flicktime = 1
				if		ZombRand(1 + weapon:getCondition()) == 0 then
						flicktime = 0
				end
				
			--	DebugSay(2,"R - "..tostring(laser:getColorRed()).."/ G - "..tostring(laser:getColorGreen()).." / B - "..tostring(laser:getColorBlue()))
				
				if		(laser:getColorRed() == 1) and (laser:getColorGreen() == 1) and (laser:getColorBlue() == 1) then		-- HAS NO COLOR ASSIGNED (1) IS MAX BRIGHT
					--	DebugSay(2,"SCRIPT COLORS")
						Glow = IsoLightSource.new(attacker:getX(), attacker:getY(), attacker:getZ(),  laser:getR(), laser:getG(), laser:getB(), (flicktime))	-- SCRIPT COLOR
				else	Glow = IsoLightSource.new(attacker:getX(), attacker:getY(), attacker:getZ(),  laser:getColorRed(), laser:getColorGreen(), laser:getColorBlue(), (flicktime))
					--	DebugSay(2,"TOGGLE SET COLORS")
				end
				getCell():addLamppost(Glow)
				attacker:getModData().Glow = Glow
			end
		end
		
		--------------------------
		--	DRAIN BATTERY		--
		--------------------------
		if	weapon:getModData().LaserOn == true then
			charge = laser:getModData().Charge
			if	charge ~= nil then
				if	charge > 0 then
					laser:getModData().Charge = charge - (getWeaponLightRuntime() * laser:getModData().Runtime)
					weapon:getModData().Charge = laser:getModData().Charge
			--		DebugSay(2,"Laser Drain - "..tostring(round(getWeaponLightRuntime() * laser:getModData().Runtime * 10000,1) ) )
				elseif charge <= 0 then
					weapon:getModData().LaserOn = false
				end
			end
		end
	end

	--------------------------
	--	WEAPON LIGHT		--
	--------------------------
	if	(weapon) and (light) and (weapon:getModData().LightOn == true) then
		charge = light:getModData().Charge
		--------------------------
		--	DRAIN BATTERY		--
		--------------------------
		if	charge ~= nil then
			if	charge > 0 then
				light:getModData().Charge = charge - (getWeaponLightRuntime() * light:getModData().Runtime)
				weapon:getModData().Charge = light:getModData().Charge
		--		DebugSay(2,"Light Drain - "..tostring(round(getWeaponLightRuntime() * laser:getModData().Runtime * 10000,1) ) )
			elseif charge <= 0 then
				weapon:getModData().LightOn = false
			end
		end

		if	attacker:isAiming() then
			weapon:setTorchCone(true)						-- THROW PATTERN
			if		(string.find(light:getType(), "Small")) then
					weapon:setLightDistance(10)
					weapon:setLightStrength(1.5)
			elseif	(string.find(light:getType(), "Medium")) then
					weapon:setLightDistance(15)
					weapon:setLightStrength(1.25)
			elseif	(string.find(light:getType(), "Large")) then
					weapon:setLightDistance(20)
					weapon:setLightStrength(1)
			elseif	(string.find(light:getType(), "PEQ")) then		-- SMALL LESS THAN DVAL
					weapon:setLightDistance(10)
					weapon:setLightStrength(1.5)
			elseif	(string.find(light:getType(), "DVAL")) then
					weapon:setLightDistance(15)
					weapon:setLightStrength(1.25)
			end
		else	weapon:setTorchCone(false)						-- FLOOD PATTERN
			if		(string.find(light:getType(), "Small")) then
					weapon:setLightDistance(2.5)
					weapon:setLightStrength(0.5)
			elseif	(string.find(light:getType(), "Medium")) then
					weapon:setLightDistance(2.0)
					weapon:setLightStrength(1)
			elseif	(string.find(light:getType(), "Large")) then
					weapon:setLightDistance(1.5)
					weapon:setLightStrength(2)
			elseif	(string.find(light:getType(), "PEQ")) then		-- SMALL MORE THAN DVAL
					weapon:setLightDistance(2.5)
					weapon:setLightStrength(0.5)
			elseif	(string.find(light:getType(), "DVAL")) then
					weapon:setLightDistance(2.0)
					weapon:setLightStrength(1)
			end
		end
	--------------------------
	--	NIGHT VISION		--
	--------------------------
	elseif	(scope) and (scope:hasTag(FWPGetItemTag("NVITEM"))) then				-- CHECK NV LAST SO LIGHT PREVAILS
			weapon:setTorchCone(false)
			if attacker:isAiming() then
				weapon:setLightDistance(0.01)
				weapon:setLightStrength(0.01)
			else
				weapon:setLightDistance(0)
				weapon:setLightStrength(0)
			end
	elseif	(weapon) and (instanceof(weapon,"HandWeapon")) and (weapon:isAimedFirearm()) then	-- FIX FOR NORMAL LIGHTS GETTING FORCED OFF
			weapon:setTorchCone(false)
			weapon:setLightDistance(0)
			weapon:setLightStrength(0)
	--------------------------
	--	LIGHT SABER	PRIMARY	--
	--------------------------
	elseif	(weapon) and (weapon:hasTag(FWPGetItemTag("LightSaber")) or weapon:hasTag(FWPGetItemTag("Torch"))) then
		if	(weapon:getCondition() >= 1) then
			local SpriteA	= weapon:getModData().SpriteA
			local SpriteB	= weapon:getModData().SpriteB
			local SpriteC	= weapon:getModData().SpriteC
			local SpriteD	= weapon:getModData().SpriteD
			local SpriteO	= weapon:getModData().SpriteOFF

			local Condition	= weapon:getCondition()
			if weapon:hasTag(FWPGetItemTag("LightSaber")) then
				Condition = Condition / 10
			end

--			Glow = attacker:getModData().Glow
		--	if Glow ~= nil then
		--		getCell():removeLamppost(Glow)
		--		attacker:getModData().Glow = nil
		--	end

			if	ZombRand(1 + weapon:getCondition()) == 0 then	-- FLICKER
				Glow = IsoLightSource.new(attacker:getX(), attacker:getY(), attacker:getZ(),  weapon:getR(), weapon:getG(), weapon:getB(), (1 + Condition / 4))
			else
				Glow = IsoLightSource.new(attacker:getX(), attacker:getY(), attacker:getZ(),  weapon:getR(), weapon:getG(), weapon:getB(), (2 + Condition / 4))
			end
			getCell():addLamppost(Glow)
			attacker:getModData().Glow = Glow
			
		--	DebugSay(2,"RGB - "..tostring(weapon:getR()).."/"..tostring(weapon:getG()).."/"..tostring(weapon:getB()) )

			if	ZombRand(4) == 0 then
				if 		weapon:getWeaponSprite() == SpriteA then
						weapon:setWeaponSprite(SpriteB)
				elseif	weapon:getWeaponSprite() == SpriteB then
						weapon:setWeaponSprite(SpriteA)
				elseif	weapon:getWeaponSprite() == SpriteC then
						weapon:setWeaponSprite(SpriteD)
				elseif	weapon:getWeaponSprite() == SpriteD then
						weapon:setWeaponSprite(SpriteC)
				else	weapon:setWeaponSprite(SpriteO)
				end
				ReEquipIt(attacker,weapon)
		--		DebugSay(2,"CHANGE - "..tostring(weapon:getWeaponSprite()))
			end
		end
		if	(weapon:hasTag(FWPGetItemTag("Torch"))) or (weapon:hasTag(FWPGetItemTag("LightSaber"))) then
			TorchCondition(attacker, weapon)
		end
--	elseif	attacker:getModData().Glow ~= nil then		-- ALWAYS OFF IF NONE OF ABOVE
--			getCell():removeLamppost(attacker:getModData().Glow)
--			attacker:getModData().Glow = nil
	end

	------------------------------
	--	LIGHT SABER	SECONDARY	--
	------------------------------
	if	(second) and (second:hasTag(FWPGetItemTag("LightSaber")) or second:hasTag(FWPGetItemTag("Torch"))) then
		if	(second:getCondition() >= 1) then
			local SpriteA = second:getModData().SpriteNORM_S
			local SpriteB = second:getModData().SpriteB
			local SpriteE = second:getModData().SpriteREST_S
			local SpriteF = second:getModData().SpriteFLEX_S
			local SpriteO = second:getModData().SpriteOFF
			if not second:hasTag(FWPGetItemTag("Flex")) then
				SpriteA = second:getModData().SpriteA
			end

			local Condition	= second:getCondition()
			if second:hasTag(FWPGetItemTag("LightSaber")) then
				Condition = Condition / 10
			end

--			Glow2 = attacker:getModData().Glow2
		--	if Glow2 ~= nil then
		--		getCell():removeLamppost(Glow2)
		--		attacker:getModData().Glow2 = nil
		--	end
			if	ZombRand(1 + second:getCondition()) == 0 then	-- FLICKER
				Glow2 = IsoLightSource.new(attacker:getX(), attacker:getY(), attacker:getZ(),  second:getR(), second:getG(), second:getB(), (1 + Condition / 4))
			else
				Glow2 = IsoLightSource.new(attacker:getX(), attacker:getY(), attacker:getZ(),  second:getR(), second:getG(), second:getB(), (2 + Condition / 4))
			end
			getCell():addLamppost(Glow2)
			attacker:getModData().Glow2 = Glow2

		--	DebugSay(2,"RGB - "..tostring(second:getR()).."/"..tostring(second:getG()).."/"..tostring(second:getB()) )

			if	ZombRand(4) == 0 then
				if 		second:getWeaponSprite() == SpriteA then
						second:setWeaponSprite(SpriteB)
				elseif	second:getWeaponSprite() == SpriteB then
						second:setWeaponSprite(SpriteA)
				elseif	second:getWeaponSprite() == SpriteE then
						second:setWeaponSprite(SpriteF)
				elseif	second:getWeaponSprite() == SpriteF then
						second:setWeaponSprite(SpriteE)
				else	second:setWeaponSprite(SpriteO)
				end
				attacker:setSecondaryHandItem(second)
		--		DebugSay(2,"CHANGE - "..tostring(second:getWeaponSprite()))
			end
		end
		if	(second:hasTag(FWPGetItemTag("Torch"))) or (second:hasTag(FWPGetItemTag("LightSaber"))) then
			TorchCondition(attacker, second)
		end
--	elseif	attacker:getModData().Glow2 ~= nil then		-- ALWAYS OFF IF NONE OF ABOVE
--			getCell():removeLamppost(attacker:getModData().Glow2)
--			attacker:getModData().Glow2 = nil
	end
end

Events.OnPlayerUpdate.Add(WeaponLightBeam)

]]