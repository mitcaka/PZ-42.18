--[[	v1.6									
AS OF 41.78.4 SINGLE PLAYER WONT READ FROM 'ITEMS' FOLDER ANYMORE... STRANGE…										
MP NEEDS TO CALL VIA EVENT FROM MAIN DISTRO FILE.										
]]										
										
if	not isServer() then									
	if	(ModOptions and ModOptions.getInstance) and (GUNFIGHTER.OPTIONS.options.dropdown128 == 1) then								
		print ("SINGLE-PLAYER VLR DISABLED...")								
--	elseif	isServer() and (SandboxVars.A26.EnumVLR == 1) then								
--		print ("MULTI-PLAYER VLR DISABLED...")								
	else	print ("VLR ENABLED...")								
										
	local distributionTable = VehicleDistributions[1]									
										
	VehicleDistributions.A26Military = {									
		M998Trunk = VehicleDistributions.A26Military_Trunk;								-- FILIBUSTER
		TruckBed = VehicleDistributions.A26Military_Trunk;								
		TruckbedOpen = VehicleDistributions.A26Military_Trunk;								
	--	P19ABigTrunkCompartment0 = VehicleDistributions.bigTrunk;								
	--	P19ASmallTrunkCompartment1 = VehicleDistributions.A26Military_Trunk;								
		P19ASmallTrunkCompartment2 = VehicleDistributions.A26Military_Trunk;								-- KI5 OSHKOSH
		P19ASmallTrunkCompartment3 = VehicleDistributions.A26Military_Trunk;								-- KI5 OSHKOSH
		M101A3Trunk = VehicleDistributions.A26Military_Trunk;								-- FILIBUSTER
	}									
										
	VehicleDistributions.A26SWAT = {									
		TruckBed = VehicleDistributions.A26SWAT_Trunk;								
		FR_VehicleArmory = VehicleDistributions.A26SWAT_Trunk;								-- FILIBUSTER
		FR_VehicleArmory2 = VehicleDistributions.A26SWAT_Trunk;								-- FILIBUSTER
	}									
										
	------------------------------------------------									
	-- KI5 MILITARY VEHICLES --									
	------------------------------------------------									
	distributionTable["92amgeneralM998"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["83amgeneralM923"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["86oshkoshUSMC"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["86oshkoshFRTR55"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["TrailerM1082"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["TrailerM101A3cargo"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["67commando"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["67commandoT50"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["67commandoPolice"] = { Normal = VehicleDistributions.A26SWAT; }									
	------------------------------------------------									
	-- FILIBUSTER MILITARY VEHICLES --									
	------------------------------------------------									
	distributionTable["hmmwvht"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["hmmwvtr"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["m35a2bed"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["m35a2covered"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["m151canvas"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["chevystepvanswat"] = { Normal = VehicleDistributions.A26SWAT; }									
	------------------------------------------------									
	-- KKSHUNP MILITARY VEHICLES --									
	------------------------------------------------									
	distributionTable["k311"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["k131"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["k511"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["k511_2"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["korando_rokmp"] = { Normal = VehicleDistributions.A26Military; }									
	------------------------------------------------									
	-- NYPH MILITARY VEHICLES --									
	------------------------------------------------									
	distributionTable["kamaz5350"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["kamaztyphoon"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["gaztigr"] = { Normal = VehicleDistributions.A26Military; }									
	------------------------------------------------									
	-- CYT MILITARY VEHICLES --									
	------------------------------------------------									
	distributionTable["XM93Desert"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["XM93Woodland"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["BRDM2"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["IFAV"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["Int4700Arm"] = { Normal = VehicleDistributions.A26SWAT; }									
	------------------------------------------------									
	-- HANSKAFFEE MILITARY VEHICLES --									
	------------------------------------------------									
	distributionTable["WZ551"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["WZ531_APC"] = { Normal = VehicleDistributions.A26Military; }									
	------------------------------------------------									
	-- BRITA MILITARY VEHICLES --									
	------------------------------------------------									
	distributionTable["k153"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["k153turret"] = { Normal = VehicleDistributions.A26Military; }									
	distributionTable["k153police"] = { Normal = VehicleDistributions.A26SWAT; }									
	distributionTable["k153emer"] = distributionTable["PickUpTruckLightsFire"]									
	end									
end										
