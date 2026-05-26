--[[							
OPTION CONFIGURED MULTI-DISTRIBUTION METHOD SYSTEM DESIGNED BY ARSENAL[26].
THIS IS A WORK IN PROGRESS, AND AS SUCH… NO PERMISSION IS GRANTED FOR USE OF							
ANY PORTION OF THIS FILE FOR 3RD PARTY MODS, TWEAKS, PATCHES, OR ANYTHING OF							
THE LIKE. THAT MEANS YOU DO NOT HAVE PERMISSION TO CHANGE A FEW NUMBERS							
AROUND AND POST ANY OF THIS AS YOUR OWN MOD.

SPECIAL THANKS, KUDOS, AND CREDITS TO DETOX, FOR SUGGESTING, AND SHARING THIS
METHOD TO USE SANDBOX SETTINGS FOR THE GUNFIGHTER MOD OPTIONS.

SPECIAL THANKS, KUDOS, AND CREDITS TO DR_COX1911, FOR SUGGESTING, AND SHARING 
ADDITIONAL PROOF OF CONCEPT WHICH ALSO HELPED TO FIGURE THIS OUT.
]]

local SETTINGS;
	SETTINGS = {					
		options = {
			box0		=	true	,										-- RESERVED
			box1		=	SandboxVars.A26.BoolShowHitDamage,				-- SHOW HIT DAMAGE			(true or false)
			box2		=	SandboxVars.A26.BoolShowHitRange,				-- SHOW HIT % RANGE			(true or false)
			dropdown3	=	SandboxVars.A26.EnumShowWeaponInfo,				-- SHOW WEAPON INFO			(1 - 3)
			box4		=	SandboxVars.A26.BoolDisplayAmmoCounter,			-- DISPLAY AMMO COUNTER		(true or false)
			box5		=	SandboxVars.A26.BoolDisplayMovementGauge,		-- DISPLAY MOVEMENT GAUGE	(true or false)
			box6		=	SandboxVars.A26.BoolDynamicRecoilSystem,		-- DYNAMIC RECOIL SYSTEM	(true or false)
			dropdown7	=	SandboxVars.A26.EnumDynamicRangeSystem,			-- DYNAMIC RANGE SYSTEM		(1 - 5)
			box8		=	SandboxVars.A26.BoolResetSightPicture,			-- RESET SIGHT PICTURE		(true or false)
			dropdown9	=	SandboxVars.A26.EnumFirearmJam,					-- FIREARM JAM				(1 - 5)
			box10		=	SandboxVars.A26.BoolFireArmsNeverBreak,			-- FIREARMS NEVER BREAK		(true or false)
			dropdown11	=	SandboxVars.A26.EnumAttachementsBreakOnMelee,	-- ATTACHMENTS BREAK ON MELEE	(1 - 5)
			dropdown12	=	SandboxVars.A26.EnumAttachmentsBreakOnFire,		-- ATTACHMENTS BREAK ON FIRE	(1 - 5)
			dropdown13	=	SandboxVars.A26.EnumSoundSuppression,			-- SOUND SUPPRESSION		(1 - 6)
			dropdown14	=	SandboxVars.A26.EnumSoundLinearBase,			-- SOUND LINEAR BASE		(1 - 21)	
			dropdown15	=	SandboxVars.A26.EnumLauncherRangeMultiplier,	-- LAUNCHER RANGE MULTIPLIER	(1 - 5)	
			box16		=	SandboxVars.A26.BoolVehiclePenalty,				-- VEHICLE PENALTY			(true or false)
			dropdown17	=	SandboxVars.A26.EnumDebugLevels,				-- DEBUG LEVELS				(1 - 4)	
			box18		=	SandboxVars.A26.BoolUseVanillaShotSounds,		-- USE VANILLA SHOT SOUNDS	(true or false)
			dropdown19	=	SandboxVars.A26.EnumEjectSpentCasings,			-- EJECT SPENT CASINGS		(1 - 11)
			dropdown20	=	SandboxVars.A26.EnumTypeBOW,					-- TYPE	BOW					(1 - 11)
			dropdown21	=	SandboxVars.A26.EnumTypeFLAME,					-- TYPE	FLAME				(1 - 11)
			dropdown22	=	SandboxVars.A26.EnumTypeGREN,					-- TYPE	GRENADE / ROCKET	(1 - 11)
			dropdown23	=	SandboxVars.A26.EnumTypeMINI,					-- TYPE	MINIGUN				(1 - 11)
			dropdown24	=	SandboxVars.A26.EnumTypeLMG,					-- TYPE	LIGHT MACHINEGUN	(1 - 11)
			dropdown25	=	SandboxVars.A26.EnumTypeSEMI,					-- TYPE	SEMI AUTOMATIC		(1 - 11)
			dropdown26	=	SandboxVars.A26.EnumTypeAUTO,					-- TYPE	AUTOMATIC RIFLE		(1 - 11)
			dropdown27	=	SandboxVars.A26.EnumTypeSMG,					-- TYPE	AUTOMATIC PISTOL	(1 - 11)
			dropdown28	=	SandboxVars.A26.EnumTypeLEVER,					-- TYPE	LEVERGUN			(1 - 11)
			dropdown29	=	SandboxVars.A26.EnumTypeREV,					-- TYPE	REVOLVER			(1 - 11)
			dropdown30	=	SandboxVars.A26.EnumTypePUMP,					-- TYPE	PUMP ACTION			(1 - 11)	
			dropdown31	=	SandboxVars.A26.EnumTypeBOLT,					-- TYPE	BOLT ACTION			(1 - 11)
			dropdown32	=	SandboxVars.A26.EnumTypeBREAK,					-- TYPE	BREAK ACTION		(1 - 11)
			dropdown33	=	SandboxVars.A26.EnumOriginUSA,					-- ORIGIN (UNITED STATES)	(1 - 11)
			dropdown34	=	SandboxVars.A26.EnumOriginSOV,					-- ORIGIN (SOVIET UNION)	(1 - 11)
			dropdown35	=	SandboxVars.A26.EnumOriginKOR,					-- ORIGIN (REP KOREA)		(1 - 11)
			dropdown36	=	SandboxVars.A26.EnumOriginPAC,					-- ORIGIN (PAC RIM)			(1 - 11)
			dropdown37	=	SandboxVars.A26.EnumOriginCZE,					-- ORIGIN (CZECH REP)		(1 - 11)
			dropdown38	=	SandboxVars.A26.EnumOriginEUR,					-- ORIGIN (EUROPE)			(1 - 11)
			dropdown39	=	SandboxVars.A26.EnumOriginISR,					-- ORIGIN (ISREAL)			(1 - 11)
			dropdown40	=	SandboxVars.A26.EnumOriginREST,					-- ORIGIN (REST WORLD)		(1 - 11)
			dropdown41	=	SandboxVars.A26.EnumCaliber50BMG,				-- CALIBER (50 BMG/MAG)		(1 - 11)
			dropdown42	=	SandboxVars.A26.EnumCaliber4gShot,				-- CALIBER (4g SHOT)		(1 - 11)
			dropdown43	=	SandboxVars.A26.EnumCaliber10gShot,				-- CALIBER (10g SHOT)		(1 - 11)
			dropdown44	=	SandboxVars.A26.EnumCaliber12gShot,				-- CALIBER (12g SHOT)		(1 - 11)
			dropdown45	=	SandboxVars.A26.EnumCaliber20gShot,				-- CALIBER (20g SHOT)		(1 - 11)
			dropdown46	=	SandboxVars.A26.EnumCaliber3006SPG,				-- CALIBER (30-06 SPG)		(1 - 11)
			dropdown47	=	SandboxVars.A26.EnumCaliber308WIN,				-- CALIBER (308 WIN)		(1 - 11)
			dropdown48	=	SandboxVars.A26.EnumCaliber762x54mmR,			-- CALIBER (7.62x54mm R)	(1 - 11)
			dropdown49	=	SandboxVars.A26.EnumCaliber545x39mm,			-- CALIBER (5.45x39mm)		(1 - 11)
			dropdown50	=	SandboxVars.A26.EnumCaliber762x39mm,			-- CALIBER (7.62x39mm)		(1 - 11)
			dropdown51	=	SandboxVars.A26.EnumCaliber556x45mm,			-- CALIBER (5.56x45mm)		(1 - 11)
			dropdown52	=	SandboxVars.A26.EnumCaliber223REM,				-- CALIBER (.223 REM)		(1 - 11)
			dropdown53	=	SandboxVars.A26.EnumCaliber45LC410g,			-- CALIBER (45 COLT / 410g)	(1 - 11)
			dropdown54	=	SandboxVars.A26.EnumCaliber4570,				-- CALIBER (46-70)			(1 - 11)
			dropdown55	=	SandboxVars.A26.EnumCaliber44MAG,				-- CALIBER (44 Mag)			(1 - 11)
			dropdown56	=	SandboxVars.A26.EnumCaliber45ACP,				-- CALIBER (45 ACP)			(1 - 11)
			dropdown57	=	SandboxVars.A26.EnumCaliber38SPC,				-- CALIBER (38 SPC)			(1 - 11)
			dropdown58	=	SandboxVars.A26.EnumCaliber9mm,					-- CALIBER (9mm)			(1 - 11)
			dropdown59	=	SandboxVars.A26.EnumCaliber57x28mm,				-- CALIBER (5.7x28mm)		(1 - 11)
			dropdown60	=	SandboxVars.A26.EnumCaliber380ACP,				-- CALIBER (380 ACP)		(1 - 11)
			dropdown61	=	SandboxVars.A26.EnumCaliber22LR,				-- CALIBER (22 LR)			(1 - 11)
			dropdown62	=	SandboxVars.A26.EnumCaliber177BB,				-- CALIBER (177 BB)			(1 - 11)
			dropdown63	=	SandboxVars.A26.EnumRandomCases,				-- RANDOM CASES				(1 - 11)	
			dropdown64	=	SandboxVars.A26.EnumAttachementSuppressor,		-- ATTACHMENT SUPPRESSOR	(1 - 11)	
			dropdown65	=	SandboxVars.A26.EnumAttachementOptics,			-- ATTACHMENT OPTICS		(1 - 11)	
			dropdown66	=	SandboxVars.A26.EnumAttachementLightLaser,		-- ATTACHMENT LIGHTS / LASER	(1 - 11)
			dropdown67	=	SandboxVars.A26.EnumAttachementAllOther,		-- ATTACHMENT ALL OTHER		(1 - 11)
			dropdown68	=	SandboxVars.A26.EnumAmmoCan,					-- AMMUNITION CANISTER		(1 - 11)
			dropdown69	=	SandboxVars.A26.EnumAmmoBox,					-- AMMUNITION BOX			(1 - 11)
			dropdown70	=	SandboxVars.A26.EnumStdMag,						-- MAGAZINE STANDARD		(1 - 11)
			dropdown71	=	SandboxVars.A26.EnumExtMag,						-- MAGAZINE EXTENDED		(1 - 11)
			dropdown72	=	SandboxVars.A26.EnumDrumMag,					-- MAGAZINE DRUM			(1 - 11)
			dropdown73	=	SandboxVars.A26.EnumPolyCan,					-- POLYMER CANISTER			(1 - 11)
			dropdown74	=	SandboxVars.A26.EnumMeleeKnifeLarge,			-- MELEE KNIFE LARGE		(1 - 11)
			dropdown75	=	SandboxVars.A26.EnumMeleeKnifeSmall,			-- MELEE KNIFE SMALL		(1 - 11)
			dropdown76	=	SandboxVars.A26.EnumMeleeSword,					-- MELEE SWORD				(1 - 11)
			dropdown77	=	SandboxVars.A26.EnumMeleeAxe,					-- MELEE AXE				(1 - 11)
			dropdown78	=	SandboxVars.A26.EnumMeleeBlunt,					-- MELEE BLUNT				(1 - 11)
			dropdown79	=	SandboxVars.A26.EnumMeleeSpear,					-- MELEE SPEAR				(1 - 11)
			dropdown80	=	SandboxVars.A26.EnumArmor,						-- ARMOR (FWP / USMC)	(1 - 21)
			dropdown81	=	SandboxVars.A26.EnumPost1992Production,			-- POST 1992 PRODUCTION		(1 - 5)	
			dropdown82	=	SandboxVars.A26.EnumCIVxLEO,					-- LEO IN CIV				(1 - 5)
			dropdown83	=	SandboxVars.A26.EnumCIVxMIL,					-- MIL IN CIV				(1 - 5)	
			dropdown84	=	SandboxVars.A26.EnumLEOxCIV,					-- CIV IN LEO				(1 - 5)	
			dropdown85	=	SandboxVars.A26.EnumLEOxMIL,					-- MIL IN LEO				(1 - 5)	
			dropdown86	=	SandboxVars.A26.EnumMILxNON,					-- NON MIL IN MIL			(1 - 5)
			dropdown87	=	SandboxVars.A26.EnumSECxNON,					-- NON SEC IN SEC			(1 - 5)
			dropdown88	=	SandboxVars.A26.EnumHNTxNON,					-- NON HNT IN HNT			(1 - 5)
			dropdown89	=	SandboxVars.A26.EnumSURxNON,					-- NON SUR IN SUR			(1 - 5)
			dropdown90	=	SandboxVars.A26.EnumGUNRollGUN,					-- ROLLS GUNSTORE (GUNS)	(1 - 5)
			dropdown91	=	SandboxVars.A26.EnumGUNRollAMMO,				-- ROLLS GUNSTORE (AMMO)	(1 - 5)	
			dropdown92	=	SandboxVars.A26.EnumGUNRollPART,				-- ROLLS GUNSTORE (PARTS)	(1 - 5)
			dropdown93	=	SandboxVars.A26.EnumGUNRollARMOR,				-- ROLLS GUNSTORE (ARMOR)	(1 - 5)
			dropdown94	=	SandboxVars.A26.EnumLEORollGUN,					-- ROLLS POLICE (GUNS+++)	(1 - 5)
			dropdown95	=	SandboxVars.A26.EnumLEORollAMMO,				-- ROLLS POLICE (AMMO/MAG)	(1 - 5)	
			dropdown96	=	SandboxVars.A26.EnumLEORollPART,				-- ROLLS POLICE (NOT USED)	(1 - 5)
			dropdown97	=	SandboxVars.A26.EnumLEORollARMOR,				-- ROLLS POLICE (ARMOR)		(1 - 5)
			dropdown98	=	SandboxVars.A26.EnumMILRollGUN,					-- ROLLS MILITARY (GUNS+++)	(1 - 5)
			dropdown99	=	SandboxVars.A26.EnumMILRollAMMO,				-- ROLLS MILITARY (AMMO/MAG)(1 - 5)
			dropdown100	=	SandboxVars.A26.EnumMILRollPART,				-- ROLLS MILITARY (NOT USED)(1 - 5)
			dropdown101	=	SandboxVars.A26.EnumMILRollARMOR,				-- ROLLS MILITARY (ARMOR)	(1 - 5)
			dropdown102	=	SandboxVars.A26.EnumSECRollGUN,					-- ROLLS SECURITY (GUNS+++)	(1 - 5)
			dropdown103	=	SandboxVars.A26.EnumSECRollAMMO,				-- ROLLS SECURITY (AMMO/MAG)(1 - 5)
			dropdown104	=	SandboxVars.A26.EnumSECRollPART,				-- ROLLS SECURITY (NOT USED)(1 - 5)
			dropdown105	=	SandboxVars.A26.EnumSECRollARMOR,				-- ROLLS SECURITY (ARMOR)	(1 - 5)
			dropdown106	=	SandboxVars.A26.EnumSURRollGUN,					-- ROLLS SURPLUS (GUNS)		(1 - 5)
			dropdown107	=	SandboxVars.A26.EnumSURRollAMMO,				-- ROLLS SURPLUS (AMMO)		(1 - 5)
			dropdown108	=	SandboxVars.A26.EnumSURRollPART,				-- ROLLS SURPLUS (PARTS)	(1 - 5)
			dropdown109	=	SandboxVars.A26.EnumSURRollARMOR,				-- ROLLS SURPLUS (ARMOR)	(1 - 5)
			dropdown110	=	SandboxVars.A26.EnumHNTRollGUN,					-- ROLLS HUNTING (GUNS)		(1 - 5)
			dropdown111	=	SandboxVars.A26.EnumHNTRollAMMO,				-- ROLLS HUNTING (AMMO)		(1 - 5)
			dropdown112	=	SandboxVars.A26.EnumHNTRollPART,				-- ROLLS HUNTING (PARTS)	(1 - 5)
			dropdown113	=	SandboxVars.A26.EnumHNTRollARMOR,				-- ROLLS HUNTING (ARMOR)	(1 - 5)
			dropdown114	=	SandboxVars.A26.EnumCIVx,						-- CIVx						(1 - 21)
			dropdown115	=	SandboxVars.A26.EnumLEOx,						-- LEOx						(1 - 21)
			dropdown116	=	SandboxVars.A26.EnumMILx,						-- MILx						(1 - 31)
			dropdown117	=	SandboxVars.A26.EnumSECx,						-- SECx						(1 - 21)
			dropdown118	=	SandboxVars.A26.EnumHNTx,						-- HNTx						(1 - 21)
			dropdown119	=	SandboxVars.A26.EnumSURx,						-- SURx						(1 - 21)
			box120		=	SandboxVars.A26.BoolCIVammo,					-- CIVammo					(true or false)
			box121		=	SandboxVars.A26.BoolLEOammo,					-- LEOammo					(true or false)
			box122		=	SandboxVars.A26.BoolMILammo,					-- MILammo					(true or false)
			box123		=	SandboxVars.A26.BoolSECammo,					-- SECammo					(true or false)
			box124		=	SandboxVars.A26.BoolHNTammo,					-- HNTammo					(true or false)
			box125		=	SandboxVars.A26.BoolSURammo,					-- SURammo					(true or false)
			dropdown126	=	SandboxVars.A26.EnumMILRegion,					-- MIL REGION 				(1 to 10)
			dropdown127	=	SandboxVars.A26.EnumZombieCCW,					-- ZOMBIE CCW 				(1 to 21)
			dropdown128	=	SandboxVars.A26.EnumVLR,						-- MIL VLR 					(1 to 11)
			dropdown129	=	SandboxVars.A26.EnumPowerTool,					-- POWER TOOLS 				(1 to 11)	
			dropdown130	=	SandboxVars.A26.EnumReloadingItems,				-- RELOADING ITEMS			(1 to 11)
			box131		=	SandboxVars.A26.BoolAutoThrown,					-- AUTO THROWN				(true or false)
			dropdown132	=	SandboxVars.A26.EnumAutoMagType,				-- AUTO MAGTYPE				(1 to 3)
			dropdown133	=	SandboxVars.A26.EnumNVControl,					-- NV CONTROL 				(1 to 3)
			dropdown134	=	SandboxVars.A26.EnumEmergencyReload,			-- EMERGERNCY LOAD			(1 to 4)
			dropdown135	=	SandboxVars.A26.EnumArrowBreak,					-- ARROW BREAK				(1 to 10)
			box136		=	SandboxVars.A26.BoolVisualEffects,				-- VISUAL EFFECTS			(true or false)
			dropdown137	=	SandboxVars.A26.EnumTorchBurnTime,				-- TORCH BURN TIME			(1 to 10)
			dropdown138	=	SandboxVars.A26.EnumTorchIgniteTarget,			-- TORCH IGNITE TARGET		(1 to 11)
			box139		=	SandboxVars.A26.BoolLightSaberReal,				-- LIGHTSABER REAL			(true or false)
			box140		=	SandboxVars.A26.BoolZombieBodyParts,			-- ZOMBIE BODY PARTS		(true or false)
			dropdown141	=	SandboxVars.A26.EnumArcheryDamage,				-- ARCHERY DAMAGE			(1 to 16)
			box142		=	SandboxVars.A26.BoolSkipRemovals,				-- SKIP REMOVALS			(true or false)
			dropdown143	=	SandboxVars.A26.EnumFixedWeaponOffset,			-- FIXED WEAPON OFFSET		(1 to 11)
			dropdown144	=	SandboxVars.A26.EnumAutoToggleLaser,			-- AUTO TOGGLE LASER		(1 to 4)
			dropdown145	=	SandboxVars.A26.EnumLightRunTime,				-- LIGHT RUNTIME			(1 to 10)
			dropdown146	=	SandboxVars.A26.EnumHeavyWeaponMovement,		-- HVY WEAPON MOVE PENALTY	(1 to 5)
			dropdown147	=	SandboxVars.A26.EnumFirearmDamage,				-- FIREARM DAMAGE			(1 to 16)
			dropdown148	=	SandboxVars.A26.EnumMeleeDamage,				-- MELEE DAMAGE			(1 to 16)
		},

	--	****************************************************************
	--	********	DO NOT EDIT BELOW THIS POINT		********
	--	****************************************************************

		names = {						
		box0	 = "[RESERVED]",
		dropdown17	 = "Debug Message Level - DEBUG",				
		box142	 = "Skip Removals Lua - DEBUG",				
							
		box1	 = "Hit Damage - DISPLAY",				
		box2	 = "Range/Hit% - DISPLAY",				
		dropdown3	 = "Weapon Info - DISPLAY",				
		box4	 = "Ammunition Count - DISPLAY",				
		box5	 = "Movement Gauge - DISPLAY",				
							
		box6	 = "Dynamic Recoil System - PENALTY",				
		dropdown7	 = "Dynamic Range System - PENALTY",				
		box8	 = "Reset Sight Picture - PENALTY",				
		box16	 = "Vehicle / Gun Length - PENALTY",				
		box140	 = "Hit All Zombie Bodyparts - PENALTY",				
		dropdown146	 = "Heavy Weapon Movement - PENALTY",				
							
		dropdown9	 = "Firearm Jam Frequency - FUNCTION",				
		box10	 = "Firearms Never Break - FUNCTION",				
		dropdown11	 = "Attachment Break on Melee - FUNCTION",				
		dropdown12	 = "Attachment Break on Fire - FUNCTION",				
		dropdown135	 = "Arrow/Bolt Break on Hit - FUNCTION",				
		dropdown141	 = "Arrow/Bolt Damage Multiplier - FUNCTION",
		dropdown147	 = "Firearm Damage Multiplier - FUNCTION",
		dropdown148	 = "Melee Damage Multiplier - FUNCTION",
		dropdown15	 = "Launcher Range Multiplier - FUNCTION",				
		dropdown143	 = "Fixed Weapon Rotation Offset - FUNCTION",				
		dropdown145	 = "Weapon Light RunTime Multiplier - FUNCTION",				
		dropdown137	 = "Torch Burn-Time Multiplier - FUNCTION",				
		dropdown138	 = "Torch Set-Fire Multiplier - FUNCTION",				
	--	box139	 = "OPTION REMOVED",				
							
		box131	 = "Auto Equip Thrown Weapon - ACTION",				
		dropdown132	 = "Auto Select Magazine Type - ACTION",				
		dropdown133	 = "Auto Activate Night Vision - ACTION",				
		dropdown144	 = "Auto Activate Laser Sight - ACTION",				
		dropdown134	 = "Emergency Reload - ACTION",				
		dropdown19	 = "Eject Spent Shells - ACTION",				
		box136	 = "Firearm Visual Effects - ACTION",				
							
		dropdown13	 = "Suppression Level - SOUND",				
		dropdown14	 = "Base Sound Level - SOUND",				
		box18	 = "Use Vanilla - SOUND",				
							
		dropdown20	 = "(Bow / X-Bow / Sling-Shot) - TYPE",				
		dropdown21	 = "(Flame Thrower) - TYPE",				
		dropdown22	 = "(Grenade / Mine / Rocket) - TYPE",				
		dropdown23	 = "(Heavy Machine / Mini-Gun) - TYPE",				
		dropdown24	 = "(Light Machinegun) - TYPE",				
		dropdown25	 = "(Semi-Automatic) - TYPE",				
		dropdown26	 = "(Rifle Caliber Automatic) - TYPE",				
		dropdown27	 = "(Pistol Caliber Automatic) - TYPE",				
		dropdown28	 = "(Lever- Action) - TYPE",				
		dropdown29	 = "(Revolver) - TYPE",				
		dropdown30	 = "(Pump-Action) - TYPE",				
		dropdown31	 = "(Bolt-Action) - TYPE",				
		dropdown32	 = "(Break-Barrel / Single-Shot) - TYPE",				
							
		dropdown33	 = "(UNITED STATES) - ORIGIN",				
		dropdown34	 = "(SOVIET UNION) - ORIGIN",				
		dropdown35	 = "(REPUBLIC OF KOREA) - ORIGIN",				
		dropdown36	 = "(PACIFIC RIM) - ORIGIN",				
		dropdown37	 = "(CZECH REPUBLIC) - ORIGIN",				
		dropdown38	 = "(EUROPE) - ORIGIN",				
		dropdown39	 = "(ISRAEL) - ORIGIN",				
		dropdown40	 = "(REST OF WORLD) - ORIGIN",				
							
		dropdown41	 = "(.50 BMG/MAG) - CALIBER",				
		dropdown42	 = "(4g SHOT) - CALIBER",				
		dropdown43	 = "(10g SHOT) - CALIBER",				
		dropdown44	 = "(12g SHOT) - CALIBER",				
		dropdown45	 = "(20g SHOT) - CALIBER",				
		dropdown46	 = "(.30-06 SPG) - CALIBER",				
		dropdown47	 = "(.308 Win) - CALIBER",				
		dropdown48	 = "(7.62x54mm R) - CALIBER",				
		dropdown49	 = "(5.45x39mm) - CALIBER",				
		dropdown50	 = "(7.62x39mm) - CALIBER",				
		dropdown51	 = "(5.56x45mm) - CALIBER",				
		dropdown52	 = "(.223 REM) - CALIBER",				
		dropdown53	 = "(.45 COLT / .410g) - CALIBER",				
		dropdown54	 = "(.45-70 GOV) - CALIBER",				
		dropdown55	 = "(.44 MAG) - CALIBER",				
		dropdown56	 = "(.45 ACP) - CALIBER",				
		dropdown57	 = "(.38  Spc /.357 MAG) - CALIBER",				
		dropdown58	 = "(9x19mm LUG) - CALIBER",				
		dropdown59	 = "(5.7x28mm) - CALIBER",				
		dropdown60	 = "(.380 ACP) - CALIBER",				
		dropdown61	 = "(.22 LR) - CALIBER",				
		dropdown62	 = "(.177 BB / .68 PB) - CALIBER",				
							
		dropdown64	 = "(Suppressors) - PARTS",				
		dropdown65	 = "(Optics & Scopes) - PARTS",				
		dropdown66	 = "(Lights & Lasers) - PARTS",				
		dropdown67	 = "(ALL Other Parts) - PARTS",				
							
		dropdown68	 = "(Canister) - AMMUNITION",				
		dropdown69	 = "(Box) - AMMUNITION",				
		dropdown73	 = "(Poly Canister) - MAGAZINE",				
		dropdown70	 = "(Standard) - MAGAZINE",				
		dropdown71	 = "(Extended) - MAGAZINE",				
		dropdown72	 = "(Drum) - MAGAZINE",				
							
		dropdown74	 = "Knife (Small) - MELEE",				
		dropdown75	 = "Knife (Large) - MELEE",				
		dropdown76	 = "Sword - MELEE",				
		dropdown77	 = "Axe - MELEE",				
		dropdown78	 = "Blunt - MELEE",				
		dropdown79	 = "Spear - MELEE",				
		dropdown129	 = "Power Tool - MELEE",				
							
		dropdown80	 = "Armor (FWP / USMC Distro Override - LOOT)",				
		dropdown130	 = "Reloading (Equip / Components) - LOOT",				
		dropdown81	 = "Weapons Produced after 1992 - LOOT",				
		dropdown126	 = "Military Region - LOOT",				
		dropdown128	 = "Military / Police Vehicle - LOOT",				
		dropdown63	 = "Random Gun-Case - LOOT",				
		dropdown127	 = "Zombie CCW - LOOT",				
							
		dropdown82	 = "Police   items in CIV locations - EXCLUSION",				
		dropdown83	 = "Military items in CIV locaions - EXCLUSION",				
		dropdown84	 = "Civilian items in LEO locations - EXCLUSION",				
		dropdown85	 = "Military items in LEO locations - EXCLUSION",				
		dropdown86	 = "NON-Military items in MIL locations - EXCLUSION",				
		dropdown87	 = "NON-Security items in SEC locations - EXCLUSION",				
		dropdown88	 = "NON-Hunting items in HNT locations - EXCLUSION",				
		dropdown89	 = "NON-Surplus items in SUR locations - EXCLUSION",				
							
		dropdown90	 = "GUN-STORE Roll (GUNS)",				
		dropdown91	 = "(AMMO)",				
		dropdown92	 = "(PARTS)",				
		dropdown93	 = "(ARMOR)",				
		dropdown94	 = "POLICE Roll (GUNS / PARTS / MAGS / AMMO)",				
		dropdown95	 = "(AMMO / MAGS)",				
		dropdown96	 = "(NOT USED)",				
		dropdown97	 = "(ARMOR)",				
		dropdown98	 = "MILITARY Roll (GUNS / PARTS / MAGS / AMMO)",				
		dropdown99	 = "(AMMO / MAGS)",				
		dropdown100	 = "(NOT USED)",				
		dropdown101	 = "(ARMOR)",				
		dropdown102	 = "SECURITY Roll (GUNS / PARTS / MAGS / AMMO)",				
		dropdown103	 = "(AMMO / MAGS)",				
		dropdown104	 = "(NOT USED)",				
		dropdown105	 = "(ARMOR)",				
		dropdown106	 = "SURPLUS Roll (GUNS)",				
		dropdown107	 = "(AMMO)",				
		dropdown108	 = "(PARTS)",				
		dropdown109	 = "(ARMOR)",				
		dropdown110	 = "HUNTING Roll (GUNS)",				
		dropdown111	 = "(AMMO)",				
		dropdown112	 = "(PARTS)",				
		dropdown113	 = "(ARMOR)",				
							
		dropdown114	 = "CIV Trim (+) Increase",				
		dropdown115	 = "LEO Trim (+) Increase",				
		dropdown116	 = "MIL Trim (+) Increase",				
		dropdown117	 = "SEC Trim (+) Increase",				
		dropdown118	 = "HNT Trim (+) Increase",				
		dropdown119	 = "SUR Trim (+) Increase",				
							
		box120	 = "CIV Spawn Associated Ammo",				
		box121	 = "LEO Spawn Associated Ammo",				
		box122	 = "MIL Spawn Associated Ammo",				
		box123	 = "SEC Spawn Associated Ammo",				
		box124	 = "HNT Spawn Associated Ammo",				
		box125	 = "SUR Spawn Associated Ammo",				
		},						
		mod_id = "FWP",						
		mod_shortname= "FWP Gunfighter (Single-Player) Options",						
	}
-- Connecting the options to the menu, so user can change and save them.							
if ModOptions and ModOptions.getInstance then							
	ModOptions:getInstance(SETTINGS)

	local opt0 = SETTINGS.options_data.box0						
	opt0.tooltip = "IGUI_tooltip_GunFighter_option0"						
	local opt1 = SETTINGS.options_data.box1						
	opt1.tooltip = "IGUI_tooltip_GunFighter_option1"						
	local opt2 = SETTINGS.options_data.box2						
	opt2.tooltip = "IGUI_tooltip_GunFighter_option2"						
	local drop3 = SETTINGS.options_data.dropdown3						
	drop3.tooltip = "IGUI_tooltip_GunFighter_option3"						
	drop3[1]	= ("OFF")					
	drop3[2]	= ("Firearms")					
	drop3[3]	= ("Firearms + Melee")					
	local opt4 = SETTINGS.options_data.box4						
	opt4.tooltip = "IGUI_tooltip_GunFighter_option4"						
	local opt5 = SETTINGS.options_data.box5						
	opt5.tooltip = "IGUI_tooltip_GunFighter_option5"						
	local opt6 = SETTINGS.options_data.box6						
	opt6.tooltip = "IGUI_tooltip_GunFighter_option6"						
	local drop7 = SETTINGS.options_data.dropdown7						
	drop7.tooltip = "IGUI_tooltip_GunFighter_option7"						
	drop7[1]	= ("0% --- No Penalty")					
	drop7[2]	= ("25% -- Low Penalty")					
	drop7[3]	= ("50% -- Med Penalty")					
	drop7[4]	= ("75% -- High Penalty")					
	drop7[5]	= ("100% - Max Penalty")					
	local opt8 = SETTINGS.options_data.box8						
	opt8.tooltip = "IGUI_tooltip_GunFighter_option8"						
	local drop9 = SETTINGS.options_data.dropdown9						
	drop9.tooltip = "IGUI_tooltip_GunFighter_option9"						
	drop9[1]	= ("100% - Default")					
	drop9[2]	= ("75% -- Less often")					
	drop9[3]	= ("50% -- Rare")					
	drop9[4]	= ("25% -- Hardly Ever")					
	drop9[5]	= ("0% --- NEVER")					
	local opt10 = SETTINGS.options_data.box10						
	opt10.tooltip = "IGUI_tooltip_GunFighter_option10"						
	local drop11 = SETTINGS.options_data.dropdown11						
	drop11.tooltip = "IGUI_tooltip_GunFighter_option11"						
	drop11[1]	= ("100% - Default")					
	drop11[2]	= ("75% -- Less often")					
	drop11[3]	= ("50% -- Rare")					
	drop11[4]	= ("25% -- Hardly Ever")					
	drop11[5]	= ("0% --- NEVER")					
	local drop12 = SETTINGS.options_data.dropdown12						
	drop12.tooltip = "IGUI_tooltip_GunFighter_option12"						
	drop12[1]	= ("100% - Default")					
	drop12[2]	= ("75% -- Less often")					
	drop12[3]	= ("50% -- Rare")					
	drop12[4]	= ("25% -- Hardly Ever")					
	drop12[5]	= ("0% --- NEVER")					
	local drop13 = SETTINGS.options_data.dropdown13						
	drop13.tooltip = "IGUI_tooltip_GunFighter_option13"						
	drop13[1]	= ("150% - Loudest")					
	drop13[2]	= ("125% - Louder")					
	drop13[3]	= ("100% - Default")					
	drop13[4]	= ("75% -- Quiet")					
	drop13[5]	= ("50% -- Whisper")					
	drop13[6]	= ("25% -- MouseFart")					
	local drop14 = SETTINGS.options_data.dropdown14						
	drop14.tooltip = "IGUI_tooltip_GunFighter_option14"						
	drop14[1]	=  ("+0 --- No Boost")					
	drop14[2]	=  ("+10 -- Linear Adjust")					
	drop14[3]	=  ("+20 -- Linear Adjust")					
	drop14[4]	=  ("+30 -- Linear Adjust")					
	drop14[5]	=  ("+40 -- Linear Adjust")					
	drop14[6]	=  ("+50 -- Linear Adjust")					
	drop14[7]	=  ("+60 -- Linear Adjust")					
	drop14[8]	=  ("+70 -- Linear Adjust")					
	drop14[9]	=  ("+80 -- Linear Adjust")					
	drop14[10]	= ("+90 -- Linear Adjust")					
	drop14[11]	= ("+100 -- Linear Adjust")					
	drop14[12]	= ("+110 - Linear Adjust")					
	drop14[13]	= ("+120 - Linear Adjust")					
	drop14[14]	= ("+130 - Linear Adjust")					
	drop14[15]	= ("+140 - Linear Adjust")					
	drop14[16]	= ("+150 - Linear Adjust")					
	drop14[17]	= ("+160 - Linear Adjust")					
	drop14[18]	= ("+170 - Linear Adjust")					
	drop14[19]	= ("+180 - Linear Adjust")					
	drop14[20]	= ("+190 - Linear Adjust")					
	drop14[21]	= ("+200 - Linear Adjust")					
	local drop15 = SETTINGS.options_data.dropdown15						
	drop15.tooltip = "IGUI_tooltip_GunFighter_option15"						
	drop15[1]	= ("100% - Default")					
	drop15[2]	= ("150% - Farther")					
	drop15[3]	= ("200% - Farther")					
	drop15[4]	= ("250% - Farther")					
	drop15[5]	= ("300% - Farther")					
	local opt16 = SETTINGS.options_data.box16						
	opt16.tooltip = "IGUI_tooltip_GunFighter_option16"						
	local drop17 = SETTINGS.options_data.dropdown17						
	drop17.tooltip = "IGUI_tooltip_GunFighter_option17"						
	drop17[1]	= ("OFF")					
	drop17[2]	= ("Normal Info")					
	drop17[3]	= ("Debug Info")					
	drop17[4]	= ("Temp Test Info")					
	local opt18 = SETTINGS.options_data.box18						
	opt18.tooltip = "IGUI_tooltip_GunFighter_option18"						
	local drop19 = SETTINGS.options_data.dropdown19						
	drop19.tooltip = "IGUI_tooltip_GunFighter_option19"						
	drop19[1]	 = ("NONE")					
	drop19[2]	 = ("10%")					
	drop19[3]	 = ("20%")					
	drop19[4]	 = ("30%")					
	drop19[5]	 = ("40%")					
	drop19[6]	 = ("50%")					
	drop19[7]	 = ("60%")					
	drop19[8]	 = ("70%")					
	drop19[9]	 = ("80%")					
	drop19[10]	 = ("90%")					
	drop19[11]	 = ("100%")					
	drop19[12]	 = ("INVENTORY")					
	local drop20 = SETTINGS.options_data.dropdown20						
	drop20.tooltip = "IGUI_tooltip_GunFighter_option20"						
	drop20[1]	 = ("REMOVE")					
	drop20[2]	 = ("10%")					
	drop20[3]	 = ("20%")					
	drop20[4]	 = ("30%")					
	drop20[5]	 = ("40%")					
	drop20[6]	 = ("50%")					
	drop20[7]	 = ("60%")					
	drop20[8]	 = ("70%")					
	drop20[9]	 = ("80%")					
	drop20[10]	 = ("90%")					
	drop20[11]	 = ("100%")					
	local drop21 = SETTINGS.options_data.dropdown21						
	drop21.tooltip = "IGUI_tooltip_GunFighter_option21"						
	drop21[1]	 = ("REMOVE")					
	drop21[2]	 = ("10%")					
	drop21[3]	 = ("20%")					
	drop21[4]	 = ("30%")					
	drop21[5]	 = ("40%")					
	drop21[6]	 = ("50%")					
	drop21[7]	 = ("60%")					
	drop21[8]	 = ("70%")					
	drop21[9]	 = ("80%")					
	drop21[10]	 = ("90%")					
	drop21[11]	 = ("100%")					
	local drop22 = SETTINGS.options_data.dropdown22						
	drop22.tooltip = "IGUI_tooltip_GunFighter_option22"						
	drop22[1]	 = ("REMOVE")					
	drop22[2]	 = ("10%")					
	drop22[3]	 = ("20%")					
	drop22[4]	 = ("30%")					
	drop22[5]	 = ("40%")					
	drop22[6]	 = ("50%")					
	drop22[7]	 = ("60%")					
	drop22[8]	 = ("70%")					
	drop22[9]	 = ("80%")					
	drop22[10]	 = ("90%")					
	drop22[11]	 = ("100%")					
	local drop23 = SETTINGS.options_data.dropdown23						
	drop23.tooltip = "IGUI_tooltip_GunFighter_option23"						
	drop23[1]	 = ("REMOVE")					
	drop23[2]	 = ("10%")					
	drop23[3]	 = ("20%")					
	drop23[4]	 = ("30%")					
	drop23[5]	 = ("40%")					
	drop23[6]	 = ("50%")					
	drop23[7]	 = ("60%")					
	drop23[8]	 = ("70%")					
	drop23[9]	 = ("80%")					
	drop23[10]	 = ("90%")					
	drop23[11]	 = ("100%")					
	local drop24 = SETTINGS.options_data.dropdown24						
	drop24.tooltip = "IGUI_tooltip_GunFighter_option24"						
	drop24[1]	 = ("REMOVE")					
	drop24[2]	 = ("10%")					
	drop24[3]	 = ("20%")					
	drop24[4]	 = ("30%")					
	drop24[5]	 = ("40%")					
	drop24[6]	 = ("50%")					
	drop24[7]	 = ("60%")					
	drop24[8]	 = ("70%")					
	drop24[9]	 = ("80%")					
	drop24[10]	 = ("90%")					
	drop24[11]	 = ("100%")					
	local drop25 = SETTINGS.options_data.dropdown25						
	drop25.tooltip = "IGUI_tooltip_GunFighter_option25"						
	drop25[1]	 = ("REMOVE")					
	drop25[2]	 = ("10%")					
	drop25[3]	 = ("20%")					
	drop25[4]	 = ("30%")					
	drop25[5]	 = ("40%")					
	drop25[6]	 = ("50%")					
	drop25[7]	 = ("60%")					
	drop25[8]	 = ("70%")					
	drop25[9]	 = ("80%")					
	drop25[10]	 = ("90%")					
	drop25[11]	 = ("100%")					
	local drop26 = SETTINGS.options_data.dropdown26						
	drop26.tooltip = "IGUI_tooltip_GunFighter_option26"						
	drop26[1]	 = ("REMOVE")					
	drop26[2]	 = ("10%")					
	drop26[3]	 = ("20%")					
	drop26[4]	 = ("30%")					
	drop26[5]	 = ("40%")					
	drop26[6]	 = ("50%")					
	drop26[7]	 = ("60%")					
	drop26[8]	 = ("70%")					
	drop26[9]	 = ("80%")					
	drop26[10]	 = ("90%")					
	drop26[11]	 = ("100%")					
	local drop27 = SETTINGS.options_data.dropdown27						
	drop27.tooltip = "IGUI_tooltip_GunFighter_option27"						
	drop27[1]	 = ("REMOVE")					
	drop27[2]	 = ("10%")					
	drop27[3]	 = ("20%")					
	drop27[4]	 = ("30%")					
	drop27[5]	 = ("40%")					
	drop27[6]	 = ("50%")					
	drop27[7]	 = ("60%")					
	drop27[8]	 = ("70%")					
	drop27[9]	 = ("80%")					
	drop27[10]	 = ("90%")					
	drop27[11]	 = ("100%")					
	local drop28 = SETTINGS.options_data.dropdown28						
	drop28.tooltip = "IGUI_tooltip_GunFighter_option28"						
	drop28[1]	 = ("REMOVE")					
	drop28[2]	 = ("10%")					
	drop28[3]	 = ("20%")					
	drop28[4]	 = ("30%")					
	drop28[5]	 = ("40%")					
	drop28[6]	 = ("50%")					
	drop28[7]	 = ("60%")					
	drop28[8]	 = ("70%")					
	drop28[9]	 = ("80%")					
	drop28[10]	 = ("90%")					
	drop28[11]	 = ("100%")					
	local drop29 = SETTINGS.options_data.dropdown29						
	drop29.tooltip = "IGUI_tooltip_GunFighter_option29"						
	drop29[1]	 = ("REMOVE")					
	drop29[2]	 = ("10%")					
	drop29[3]	 = ("20%")					
	drop29[4]	 = ("30%")					
	drop29[5]	 = ("40%")					
	drop29[6]	 = ("50%")					
	drop29[7]	 = ("60%")					
	drop29[8]	 = ("70%")					
	drop29[9]	 = ("80%")					
	drop29[10]	 = ("90%")					
	drop29[11]	 = ("100%")					
	local drop30 = SETTINGS.options_data.dropdown30						
	drop30.tooltip = "IGUI_tooltip_GunFighter_option30"						
	drop30[1]	 = ("REMOVE")					
	drop30[2]	 = ("10%")					
	drop30[3]	 = ("20%")					
	drop30[4]	 = ("30%")					
	drop30[5]	 = ("40%")					
	drop30[6]	 = ("50%")					
	drop30[7]	 = ("60%")					
	drop30[8]	 = ("70%")					
	drop30[9]	 = ("80%")					
	drop30[10]	 = ("90%")					
	drop30[11]	 = ("100%")					
	local drop31 = SETTINGS.options_data.dropdown31						
	drop31.tooltip = "IGUI_tooltip_GunFighter_option31"						
	drop31[1]	 = ("REMOVE")					
	drop31[2]	 = ("10%")					
	drop31[3]	 = ("20%")					
	drop31[4]	 = ("30%")					
	drop31[5]	 = ("40%")					
	drop31[6]	 = ("50%")					
	drop31[7]	 = ("60%")					
	drop31[8]	 = ("70%")					
	drop31[9]	 = ("80%")					
	drop31[10]	 = ("90%")					
	drop31[11]	 = ("100%")					
	local drop32 = SETTINGS.options_data.dropdown32						
	drop32.tooltip = "IGUI_tooltip_GunFighter_option32"						
	drop32[1]	 = ("REMOVE")					
	drop32[2]	 = ("10%")					
	drop32[3]	 = ("20%")					
	drop32[4]	 = ("30%")					
	drop32[5]	 = ("40%")					
	drop32[6]	 = ("50%")					
	drop32[7]	 = ("60%")					
	drop32[8]	 = ("70%")					
	drop32[9]	 = ("80%")					
	drop32[10]	 = ("90%")					
	drop32[11]	 = ("100%")					
	local drop33 = SETTINGS.options_data.dropdown33						
	drop33.tooltip = "IGUI_tooltip_GunFighter_option33"						
	drop33[1]	 = ("REMOVE")					
	drop33[2]	 = ("10%")					
	drop33[3]	 = ("20%")					
	drop33[4]	 = ("30%")					
	drop33[5]	 = ("40%")					
	drop33[6]	 = ("50%")					
	drop33[7]	 = ("60%")					
	drop33[8]	 = ("70%")					
	drop33[9]	 = ("80%")					
	drop33[10]	 = ("90%")					
	drop33[11]	 = ("100%")					
	local drop34 = SETTINGS.options_data.dropdown34						
	drop34.tooltip = "IGUI_tooltip_GunFighter_option34"						
	drop34[1]	 = ("REMOVE")					
	drop34[2]	 = ("10%")					
	drop34[3]	 = ("20%")					
	drop34[4]	 = ("30%")					
	drop34[5]	 = ("40%")					
	drop34[6]	 = ("50%")					
	drop34[7]	 = ("60%")					
	drop34[8]	 = ("70%")					
	drop34[9]	 = ("80%")					
	drop34[10]	 = ("90%")					
	drop34[11]	 = ("100%")					
	local drop35 = SETTINGS.options_data.dropdown35						
	drop35.tooltip = "IGUI_tooltip_GunFighter_option35"						
	drop35[1]	 = ("REMOVE")					
	drop35[2]	 = ("10%")					
	drop35[3]	 = ("20%")					
	drop35[4]	 = ("30%")					
	drop35[5]	 = ("40%")					
	drop35[6]	 = ("50%")					
	drop35[7]	 = ("60%")					
	drop35[8]	 = ("70%")					
	drop35[9]	 = ("80%")					
	drop35[10]	 = ("90%")					
	drop35[11]	 = ("100%")					
	local drop36 = SETTINGS.options_data.dropdown36						
	drop36.tooltip = "IGUI_tooltip_GunFighter_option36"						
	drop36[1]	 = ("REMOVE")					
	drop36[2]	 = ("10%")					
	drop36[3]	 = ("20%")					
	drop36[4]	 = ("30%")					
	drop36[5]	 = ("40%")					
	drop36[6]	 = ("50%")					
	drop36[7]	 = ("60%")					
	drop36[8]	 = ("70%")					
	drop36[9]	 = ("80%")					
	drop36[10]	 = ("90%")					
	drop36[11]	 = ("100%")					
	local drop37 = SETTINGS.options_data.dropdown37						
	drop37.tooltip = "IGUI_tooltip_GunFighter_option37"						
	drop37[1]	 = ("REMOVE")					
	drop37[2]	 = ("10%")					
	drop37[3]	 = ("20%")					
	drop37[4]	 = ("30%")					
	drop37[5]	 = ("40%")					
	drop37[6]	 = ("50%")					
	drop37[7]	 = ("60%")					
	drop37[8]	 = ("70%")					
	drop37[9]	 = ("80%")					
	drop37[10]	 = ("90%")					
	drop37[11]	 = ("100%")					
	local drop38 = SETTINGS.options_data.dropdown38						
	drop38.tooltip = "IGUI_tooltip_GunFighter_option38"						
	drop38[1]	 = ("REMOVE")					
	drop38[2]	 = ("10%")					
	drop38[3]	 = ("20%")					
	drop38[4]	 = ("30%")					
	drop38[5]	 = ("40%")					
	drop38[6]	 = ("50%")					
	drop38[7]	 = ("60%")					
	drop38[8]	 = ("70%")					
	drop38[9]	 = ("80%")					
	drop38[10]	 = ("90%")					
	drop38[11]	 = ("100%")					
	local drop39 = SETTINGS.options_data.dropdown39						
	drop39.tooltip = "IGUI_tooltip_GunFighter_option39"						
	drop39[1]	 = ("REMOVE")					
	drop39[2]	 = ("10%")					
	drop39[3]	 = ("20%")					
	drop39[4]	 = ("30%")					
	drop39[5]	 = ("40%")					
	drop39[6]	 = ("50%")					
	drop39[7]	 = ("60%")					
	drop39[8]	 = ("70%")					
	drop39[9]	 = ("80%")					
	drop39[10]	 = ("90%")					
	drop39[11]	 = ("100%")					
	local drop40 = SETTINGS.options_data.dropdown40						
	drop40.tooltip = "IGUI_tooltip_GunFighter_option40"						
	drop40[1]	 = ("REMOVE")					
	drop40[2]	 = ("10%")					
	drop40[3]	 = ("20%")					
	drop40[4]	 = ("30%")					
	drop40[5]	 = ("40%")					
	drop40[6]	 = ("50%")					
	drop40[7]	 = ("60%")					
	drop40[8]	 = ("70%")					
	drop40[9]	 = ("80%")					
	drop40[10]	 = ("90%")					
	drop40[11]	 = ("100%")					
	local drop41 = SETTINGS.options_data.dropdown41						
	drop41.tooltip = "IGUI_tooltip_GunFighter_option41"						
	drop41[1]	 = ("REMOVE")					
	drop41[2]	 = ("10%")					
	drop41[3]	 = ("20%")					
	drop41[4]	 = ("30%")					
	drop41[5]	 = ("40%")					
	drop41[6]	 = ("50%")					
	drop41[7]	 = ("60%")					
	drop41[8]	 = ("70%")					
	drop41[9]	 = ("80%")					
	drop41[10]	 = ("90%")					
	drop41[11]	 = ("100%")					
	local drop42 = SETTINGS.options_data.dropdown42						
	drop42.tooltip = "IGUI_tooltip_GunFighter_option42"						
	drop42[1]	 = ("REMOVE")					
	drop42[2]	 = ("10%")					
	drop42[3]	 = ("20%")					
	drop42[4]	 = ("30%")					
	drop42[5]	 = ("40%")					
	drop42[6]	 = ("50%")					
	drop42[7]	 = ("60%")					
	drop42[8]	 = ("70%")					
	drop42[9]	 = ("80%")					
	drop42[10]	 = ("90%")					
	drop42[11]	 = ("100%")					
	local drop43 = SETTINGS.options_data.dropdown43						
	drop43.tooltip = "IGUI_tooltip_GunFighter_option43"						
	drop43[1]	 = ("REMOVE")					
	drop43[2]	 = ("10%")					
	drop43[3]	 = ("20%")					
	drop43[4]	 = ("30%")					
	drop43[5]	 = ("40%")					
	drop43[6]	 = ("50%")					
	drop43[7]	 = ("60%")					
	drop43[8]	 = ("70%")					
	drop43[9]	 = ("80%")					
	drop43[10]	 = ("90%")					
	drop43[11]	 = ("100%")					
	local drop44 = SETTINGS.options_data.dropdown44						
	drop44.tooltip = "IGUI_tooltip_GunFighter_option44"						
	drop44[1]	 = ("REMOVE")					
	drop44[2]	 = ("10%")					
	drop44[3]	 = ("20%")					
	drop44[4]	 = ("30%")					
	drop44[5]	 = ("40%")					
	drop44[6]	 = ("50%")					
	drop44[7]	 = ("60%")					
	drop44[8]	 = ("70%")					
	drop44[9]	 = ("80%")					
	drop44[10]	 = ("90%")					
	drop44[11]	 = ("100%")					
	local drop45 = SETTINGS.options_data.dropdown45						
	drop45.tooltip = "IGUI_tooltip_GunFighter_option45"						
	drop45[1]	 = ("REMOVE")					
	drop45[2]	 = ("10%")					
	drop45[3]	 = ("20%")					
	drop45[4]	 = ("30%")					
	drop45[5]	 = ("40%")					
	drop45[6]	 = ("50%")					
	drop45[7]	 = ("60%")					
	drop45[8]	 = ("70%")					
	drop45[9]	 = ("80%")					
	drop45[10]	 = ("90%")					
	drop45[11]	 = ("100%")					
	local drop46 = SETTINGS.options_data.dropdown46						
	drop46.tooltip = "IGUI_tooltip_GunFighter_option46"						
	drop46[1]	 = ("REMOVE")					
	drop46[2]	 = ("10%")					
	drop46[3]	 = ("20%")					
	drop46[4]	 = ("30%")					
	drop46[5]	 = ("40%")					
	drop46[6]	 = ("50%")					
	drop46[7]	 = ("60%")					
	drop46[8]	 = ("70%")					
	drop46[9]	 = ("80%")					
	drop46[10]	 = ("90%")					
	drop46[11]	 = ("100%")					
	local drop47 = SETTINGS.options_data.dropdown47						
	drop47.tooltip = "IGUI_tooltip_GunFighter_option47"						
	drop47[1]	 = ("REMOVE")					
	drop47[2]	 = ("10%")					
	drop47[3]	 = ("20%")					
	drop47[4]	 = ("30%")					
	drop47[5]	 = ("40%")					
	drop47[6]	 = ("50%")					
	drop47[7]	 = ("60%")					
	drop47[8]	 = ("70%")					
	drop47[9]	 = ("80%")					
	drop47[10]	 = ("90%")					
	drop47[11]	 = ("100%")					
	local drop48 = SETTINGS.options_data.dropdown48						
	drop48.tooltip = "IGUI_tooltip_GunFighter_option48"						
	drop48[1]	 = ("REMOVE")					
	drop48[2]	 = ("10%")					
	drop48[3]	 = ("20%")					
	drop48[4]	 = ("30%")					
	drop48[5]	 = ("40%")					
	drop48[6]	 = ("50%")					
	drop48[7]	 = ("60%")					
	drop48[8]	 = ("70%")					
	drop48[9]	 = ("80%")					
	drop48[10]	 = ("90%")					
	drop48[11]	 = ("100%")					
	local drop49 = SETTINGS.options_data.dropdown49						
	drop49.tooltip = "IGUI_tooltip_GunFighter_option49"						
	drop49[1]	 = ("REMOVE")					
	drop49[2]	 = ("10%")					
	drop49[3]	 = ("20%")					
	drop49[4]	 = ("30%")					
	drop49[5]	 = ("40%")					
	drop49[6]	 = ("50%")					
	drop49[7]	 = ("60%")					
	drop49[8]	 = ("70%")					
	drop49[9]	 = ("80%")					
	drop49[10]	 = ("90%")					
	drop49[11]	 = ("100%")					
	local drop50 = SETTINGS.options_data.dropdown50						
	drop50.tooltip = "IGUI_tooltip_GunFighter_option50"						
	drop50[1]	 = ("REMOVE")					
	drop50[2]	 = ("10%")					
	drop50[3]	 = ("20%")					
	drop50[4]	 = ("30%")					
	drop50[5]	 = ("40%")					
	drop50[6]	 = ("50%")					
	drop50[7]	 = ("60%")					
	drop50[8]	 = ("70%")					
	drop50[9]	 = ("80%")					
	drop50[10]	 = ("90%")					
	drop50[11]	 = ("100%")					
	local drop51 = SETTINGS.options_data.dropdown51						
	drop51.tooltip = "IGUI_tooltip_GunFighter_option51"						
	drop51[1]	 = ("REMOVE")					
	drop51[2]	 = ("10%")					
	drop51[3]	 = ("20%")					
	drop51[4]	 = ("30%")					
	drop51[5]	 = ("40%")					
	drop51[6]	 = ("50%")					
	drop51[7]	 = ("60%")					
	drop51[8]	 = ("70%")					
	drop51[9]	 = ("80%")					
	drop51[10]	 = ("90%")					
	drop51[11]	 = ("100%")					
	local drop52 = SETTINGS.options_data.dropdown52						
	drop52.tooltip = "IGUI_tooltip_GunFighter_option52"						
	drop52[1]	 = ("REMOVE")					
	drop52[2]	 = ("10%")					
	drop52[3]	 = ("20%")					
	drop52[4]	 = ("30%")					
	drop52[5]	 = ("40%")					
	drop52[6]	 = ("50%")					
	drop52[7]	 = ("60%")					
	drop52[8]	 = ("70%")					
	drop52[9]	 = ("80%")					
	drop52[10]	 = ("90%")					
	drop52[11]	 = ("100%")					
	local drop53 = SETTINGS.options_data.dropdown53						
	drop53.tooltip = "IGUI_tooltip_GunFighter_option53"						
	drop53[1]	 = ("REMOVE")					
	drop53[2]	 = ("10%")					
	drop53[3]	 = ("20%")					
	drop53[4]	 = ("30%")					
	drop53[5]	 = ("40%")					
	drop53[6]	 = ("50%")					
	drop53[7]	 = ("60%")					
	drop53[8]	 = ("70%")					
	drop53[9]	 = ("80%")					
	drop53[10]	 = ("90%")					
	drop53[11]	 = ("100%")					
	local drop54 = SETTINGS.options_data.dropdown54						
	drop54.tooltip = "IGUI_tooltip_GunFighter_option54"						
	drop54[1]	 = ("REMOVE")					
	drop54[2]	 = ("10%")					
	drop54[3]	 = ("20%")					
	drop54[4]	 = ("30%")					
	drop54[5]	 = ("40%")					
	drop54[6]	 = ("50%")					
	drop54[7]	 = ("60%")					
	drop54[8]	 = ("70%")					
	drop54[9]	 = ("80%")					
	drop54[10]	 = ("90%")					
	drop54[11]	 = ("100%")					
	local drop55 = SETTINGS.options_data.dropdown55						
	drop55.tooltip = "IGUI_tooltip_GunFighter_option55"						
	drop55[1]	 = ("REMOVE")					
	drop55[2]	 = ("10%")					
	drop55[3]	 = ("20%")					
	drop55[4]	 = ("30%")					
	drop55[5]	 = ("40%")					
	drop55[6]	 = ("50%")					
	drop55[7]	 = ("60%")					
	drop55[8]	 = ("70%")					
	drop55[9]	 = ("80%")					
	drop55[10]	 = ("90%")					
	drop55[11]	 = ("100%")					
	local drop56 = SETTINGS.options_data.dropdown56						
	drop56.tooltip = "IGUI_tooltip_GunFighter_option56"						
	drop56[1]	 = ("REMOVE")					
	drop56[2]	 = ("10%")					
	drop56[3]	 = ("20%")					
	drop56[4]	 = ("30%")					
	drop56[5]	 = ("40%")					
	drop56[6]	 = ("50%")					
	drop56[7]	 = ("60%")					
	drop56[8]	 = ("70%")					
	drop56[9]	 = ("80%")					
	drop56[10]	 = ("90%")					
	drop56[11]	 = ("100%")					
	local drop57 = SETTINGS.options_data.dropdown57						
	drop57.tooltip = "IGUI_tooltip_GunFighter_option57"						
	drop57[1]	 = ("REMOVE")					
	drop57[2]	 = ("10%")					
	drop57[3]	 = ("20%")					
	drop57[4]	 = ("30%")					
	drop57[5]	 = ("40%")					
	drop57[6]	 = ("50%")					
	drop57[7]	 = ("60%")					
	drop57[8]	 = ("70%")					
	drop57[9]	 = ("80%")					
	drop57[10]	 = ("90%")					
	drop57[11]	 = ("100%")					
	local drop58 = SETTINGS.options_data.dropdown58						
	drop58.tooltip = "IGUI_tooltip_GunFighter_option58"						
	drop58[1]	 = ("REMOVE")					
	drop58[2]	 = ("10%")					
	drop58[3]	 = ("20%")					
	drop58[4]	 = ("30%")					
	drop58[5]	 = ("40%")					
	drop58[6]	 = ("50%")					
	drop58[7]	 = ("60%")					
	drop58[8]	 = ("70%")					
	drop58[9]	 = ("80%")					
	drop58[10]	 = ("90%")					
	drop58[11]	 = ("100%")					
	local drop59 = SETTINGS.options_data.dropdown59						
	drop59.tooltip = "IGUI_tooltip_GunFighter_option59"						
	drop59[1]	 = ("REMOVE")					
	drop59[2]	 = ("10%")					
	drop59[3]	 = ("20%")					
	drop59[4]	 = ("30%")					
	drop59[5]	 = ("40%")					
	drop59[6]	 = ("50%")					
	drop59[7]	 = ("60%")					
	drop59[8]	 = ("70%")					
	drop59[9]	 = ("80%")					
	drop59[10]	 = ("90%")					
	drop59[11]	 = ("100%")					
	local drop60 = SETTINGS.options_data.dropdown60						
	drop60.tooltip = "IGUI_tooltip_GunFighter_option60"						
	drop60[1]	 = ("REMOVE")					
	drop60[2]	 = ("10%")					
	drop60[3]	 = ("20%")					
	drop60[4]	 = ("30%")					
	drop60[5]	 = ("40%")					
	drop60[6]	 = ("50%")					
	drop60[7]	 = ("60%")					
	drop60[8]	 = ("70%")					
	drop60[9]	 = ("80%")					
	drop60[10]	 = ("90%")					
	drop60[11]	 = ("100%")					
	local drop61 = SETTINGS.options_data.dropdown61						
	drop61.tooltip = "IGUI_tooltip_GunFighter_option61"						
	drop61[1]	 = ("REMOVE")					
	drop61[2]	 = ("10%")					
	drop61[3]	 = ("20%")					
	drop61[4]	 = ("30%")					
	drop61[5]	 = ("40%")					
	drop61[6]	 = ("50%")					
	drop61[7]	 = ("60%")					
	drop61[8]	 = ("70%")					
	drop61[9]	 = ("80%")					
	drop61[10]	 = ("90%")					
	drop61[11]	 = ("100%")					
	local drop62 = SETTINGS.options_data.dropdown62						
	drop62.tooltip = "IGUI_tooltip_GunFighter_option62"						
	drop62[1]	 = ("REMOVE")					
	drop62[2]	 = ("10%")					
	drop62[3]	 = ("20%")					
	drop62[4]	 = ("30%")					
	drop62[5]	 = ("40%")					
	drop62[6]	 = ("50%")					
	drop62[7]	 = ("60%")					
	drop62[8]	 = ("70%")					
	drop62[9]	 = ("80%")					
	drop62[10]	 = ("90%")					
	drop62[11]	 = ("100%")					
	local drop63 = SETTINGS.options_data.dropdown63						
	drop63.tooltip = "IGUI_tooltip_GunFighter_option63"						
	drop63[1]	 = ("REMOVE")					
	drop63[2]	 = ("10%")					
	drop63[3]	 = ("20%")					
	drop63[4]	 = ("30%")					
	drop63[5]	 = ("40%")					
	drop63[6]	 = ("50%")					
	drop63[7]	 = ("60%")					
	drop63[8]	 = ("70%")					
	drop63[9]	 = ("80%")					
	drop63[10]	 = ("90%")					
	drop63[11]	 = ("100%")					
	drop63[12]	 = ("110%")					
	drop63[13]	 = ("120%")					
	drop63[14]	 = ("130%")					
	drop63[15]	 = ("140%")					
	drop63[16]	 = ("150%")					
	drop63[17]	 = ("160%")					
	drop63[18]	 = ("170%")					
	drop63[19]	 = ("180%")					
	drop63[20]	 = ("190%")					
	drop63[21]	 = ("200%")					
	local drop64 = SETTINGS.options_data.dropdown64						
	drop64.tooltip = "IGUI_tooltip_GunFighter_option64"						
	drop64[1]	 = ("REMOVE")					
	drop64[2]	 = ("10%")					
	drop64[3]	 = ("20%")					
	drop64[4]	 = ("30%")					
	drop64[5]	 = ("40%")					
	drop64[6]	 = ("50%")					
	drop64[7]	 = ("60%")					
	drop64[8]	 = ("70%")					
	drop64[9]	 = ("80%")					
	drop64[10]	 = ("90%")					
	drop64[11]	 = ("100%")					
	local drop65 = SETTINGS.options_data.dropdown65						
	drop65.tooltip = "IGUI_tooltip_GunFighter_option65"						
	drop65[1]	 = ("REMOVE")					
	drop65[2]	 = ("10%")					
	drop65[3]	 = ("20%")					
	drop65[4]	 = ("30%")					
	drop65[5]	 = ("40%")					
	drop65[6]	 = ("50%")					
	drop65[7]	 = ("60%")					
	drop65[8]	 = ("70%")					
	drop65[9]	 = ("80%")					
	drop65[10]	 = ("90%")					
	drop65[11]	 = ("100%")					
	local drop66 = SETTINGS.options_data.dropdown66						
	drop66.tooltip = "IGUI_tooltip_GunFighter_option66"						
	drop66[1]	 = ("REMOVE")					
	drop66[2]	 = ("10%")					
	drop66[3]	 = ("20%")					
	drop66[4]	 = ("30%")					
	drop66[5]	 = ("40%")					
	drop66[6]	 = ("50%")					
	drop66[7]	 = ("60%")					
	drop66[8]	 = ("70%")					
	drop66[9]	 = ("80%")					
	drop66[10]	 = ("90%")					
	drop66[11]	 = ("100%")					
	local drop67 = SETTINGS.options_data.dropdown67						
	drop67.tooltip = "IGUI_tooltip_GunFighter_option67"						
	drop67[1]	 = ("REMOVE")					
	drop67[2]	 = ("10%")					
	drop67[3]	 = ("20%")					
	drop67[4]	 = ("30%")					
	drop67[5]	 = ("40%")					
	drop67[6]	 = ("50%")					
	drop67[7]	 = ("60%")					
	drop67[8]	 = ("70%")					
	drop67[9]	 = ("80%")					
	drop67[10]	 = ("90%")					
	drop67[11]	 = ("100%")					
	local drop68 = SETTINGS.options_data.dropdown68						
	drop68.tooltip = "IGUI_tooltip_GunFighter_option68"						
	drop68[1]	 = ("REMOVE")					
	drop68[2]	 = ("10%")					
	drop68[3]	 = ("20%")					
	drop68[4]	 = ("30%")					
	drop68[5]	 = ("40%")					
	drop68[6]	 = ("50%")					
	drop68[7]	 = ("60%")					
	drop68[8]	 = ("70%")					
	drop68[9]	 = ("80%")					
	drop68[10]	 = ("90%")					
	drop68[11]	 = ("100%")					
	local drop69 = SETTINGS.options_data.dropdown69						
	drop69.tooltip = "IGUI_tooltip_GunFighter_option69"						
	drop69[1]	 = ("REMOVE")					
	drop69[2]	 = ("10%")					
	drop69[3]	 = ("20%")					
	drop69[4]	 = ("30%")					
	drop69[5]	 = ("40%")					
	drop69[6]	 = ("50%")					
	drop69[7]	 = ("60%")					
	drop69[8]	 = ("70%")					
	drop69[9]	 = ("80%")					
	drop69[10]	 = ("90%")					
	drop69[11]	 = ("100%")					
	local drop70 = SETTINGS.options_data.dropdown70						
	drop70.tooltip = "IGUI_tooltip_GunFighter_option70"						
	drop70[1]	 = ("REMOVE")					
	drop70[2]	 = ("10%")					
	drop70[3]	 = ("20%")					
	drop70[4]	 = ("30%")					
	drop70[5]	 = ("40%")					
	drop70[6]	 = ("50%")					
	drop70[7]	 = ("60%")					
	drop70[8]	 = ("70%")					
	drop70[9]	 = ("80%")					
	drop70[10]	 = ("90%")					
	drop70[11]	 = ("100%")					
	local drop71 = SETTINGS.options_data.dropdown71						
	drop71.tooltip = "IGUI_tooltip_GunFighter_option71"						
	drop71[1]	 = ("REMOVE")					
	drop71[2]	 = ("10%")					
	drop71[3]	 = ("20%")					
	drop71[4]	 = ("30%")					
	drop71[5]	 = ("40%")					
	drop71[6]	 = ("50%")					
	drop71[7]	 = ("60%")					
	drop71[8]	 = ("70%")					
	drop71[9]	 = ("80%")					
	drop71[10]	 = ("90%")					
	drop71[11]	 = ("100%")					
	local drop72 = SETTINGS.options_data.dropdown72						
	drop72.tooltip = "IGUI_tooltip_GunFighter_option72"						
	drop72[1]	 = ("REMOVE")					
	drop72[2]	 = ("10%")					
	drop72[3]	 = ("20%")					
	drop72[4]	 = ("30%")					
	drop72[5]	 = ("40%")					
	drop72[6]	 = ("50%")					
	drop72[7]	 = ("60%")					
	drop72[8]	 = ("70%")					
	drop72[9]	 = ("80%")					
	drop72[10]	 = ("90%")					
	drop72[11]	 = ("100%")					
	local drop73 = SETTINGS.options_data.dropdown73						
	drop73.tooltip = "IGUI_tooltip_GunFighter_option73"						
	drop73[1]	 = ("REMOVE")					
	drop73[2]	 = ("10%")					
	drop73[3]	 = ("20%")					
	drop73[4]	 = ("30%")					
	drop73[5]	 = ("40%")					
	drop73[6]	 = ("50%")					
	drop73[7]	 = ("60%")					
	drop73[8]	 = ("70%")					
	drop73[9]	 = ("80%")					
	drop73[10]	 = ("90%")					
	drop73[11]	 = ("100%")					
	local drop74 = SETTINGS.options_data.dropdown74						
	drop74.tooltip = "IGUI_tooltip_GunFighter_option74"						
	drop74[1]	 = ("REMOVE")					
	drop74[2]	 = ("10%")					
	drop74[3]	 = ("20%")					
	drop74[4]	 = ("30%")					
	drop74[5]	 = ("40%")					
	drop74[6]	 = ("50%")					
	drop74[7]	 = ("60%")					
	drop74[8]	 = ("70%")					
	drop74[9]	 = ("80%")					
	drop74[10]	 = ("90%")					
	drop74[11]	 = ("100%")					
	local drop75 = SETTINGS.options_data.dropdown75						
	drop75.tooltip = "IGUI_tooltip_GunFighter_option75"						
	drop75[1]	 = ("REMOVE")					
	drop75[2]	 = ("10%")					
	drop75[3]	 = ("20%")					
	drop75[4]	 = ("30%")					
	drop75[5]	 = ("40%")					
	drop75[6]	 = ("50%")					
	drop75[7]	 = ("60%")					
	drop75[8]	 = ("70%")					
	drop75[9]	 = ("80%")					
	drop75[10]	 = ("90%")					
	drop75[11]	 = ("100%")					
	local drop76 = SETTINGS.options_data.dropdown76						
	drop76.tooltip = "IGUI_tooltip_GunFighter_option76"						
	drop76[1]	 = ("REMOVE")					
	drop76[2]	 = ("10%")					
	drop76[3]	 = ("20%")					
	drop76[4]	 = ("30%")					
	drop76[5]	 = ("40%")					
	drop76[6]	 = ("50%")					
	drop76[7]	 = ("60%")					
	drop76[8]	 = ("70%")					
	drop76[9]	 = ("80%")					
	drop76[10]	 = ("90%")					
	drop76[11]	 = ("100%")					
	local drop77 = SETTINGS.options_data.dropdown77						
	drop77.tooltip = "IGUI_tooltip_GunFighter_option77"						
	drop77[1]	 = ("REMOVE")					
	drop77[2]	 = ("10%")					
	drop77[3]	 = ("20%")					
	drop77[4]	 = ("30%")					
	drop77[5]	 = ("40%")					
	drop77[6]	 = ("50%")					
	drop77[7]	 = ("60%")					
	drop77[8]	 = ("70%")					
	drop77[9]	 = ("80%")					
	drop77[10]	 = ("90%")					
	drop77[11]	 = ("100%")					
	local drop78 = SETTINGS.options_data.dropdown78						
	drop78.tooltip = "IGUI_tooltip_GunFighter_option78"						
	drop78[1]	 = ("REMOVE")					
	drop78[2]	 = ("10%")					
	drop78[3]	 = ("20%")					
	drop78[4]	 = ("30%")					
	drop78[5]	 = ("40%")					
	drop78[6]	 = ("50%")					
	drop78[7]	 = ("60%")					
	drop78[8]	 = ("70%")					
	drop78[9]	 = ("80%")					
	drop78[10]	 = ("90%")					
	drop78[11]	 = ("100%")					
	local drop79 = SETTINGS.options_data.dropdown79						
	drop79.tooltip = "IGUI_tooltip_GunFighter_option79"						
	drop79[1]	 = ("REMOVE")					
	drop79[2]	 = ("10%")					
	drop79[3]	 = ("20%")					
	drop79[4]	 = ("30%")					
	drop79[5]	 = ("40%")					
	drop79[6]	 = ("50%")					
	drop79[7]	 = ("60%")					
	drop79[8]	 = ("70%")					
	drop79[9]	 = ("80%")					
	drop79[10]	 = ("90%")					
	drop79[11]	 = ("100%")					
	local drop80 = SETTINGS.options_data.dropdown80						
	drop80.tooltip = "IGUI_tooltip_GunFighter_option80"						
	drop80[1]	 = ("DO NOT OVERRIDE DISTRO")					
	drop80[2]	 = ("10%")					
	drop80[3]	 = ("20%")					
	drop80[4]	 = ("30%")					
	drop80[5]	 = ("40%")					
	drop80[6]	 = ("50%")					
	drop80[7]	 = ("60%")					
	drop80[8]	 = ("70%")					
	drop80[9]	 = ("80%")					
	drop80[10]	 = ("90%")					
	drop80[11]	 = ("100%")					
	drop80[12]	 = ("110%")					
	drop80[13]	 = ("120%")					
	drop80[14]	 = ("130%")					
	drop80[15]	 = ("140%")					
	drop80[16]	 = ("150%")					
	drop80[17]	 = ("160%")					
	drop80[18]	 = ("170%")					
	drop80[19]	 = ("180%")					
	drop80[20]	 = ("190%")					
	drop80[21]	 = ("200%")					
	local drop81 = SETTINGS.options_data.dropdown81					-- EXCLUSIONARY	
	drop81.tooltip = "IGUI_tooltip_GunFighter_option81"						
	drop81[1]	 = ("REMOVE")					
	drop81[2]	 = ("25%")					
	drop81[3]	 = ("50%")					
	drop81[4]	 = ("75%")					
	drop81[5]	 = ("ALLOW")					
	local drop82 = SETTINGS.options_data.dropdown82						
	drop82.tooltip = "IGUI_tooltip_GunFighter_option82"						
	drop82[1]	 = ("REMOVE")					
	drop82[2]	 = ("25%")					
	drop82[3]	 = ("50%")					
	drop82[4]	 = ("75%")					
	drop82[5]	 = ("ALLOW")					
	local drop83 = SETTINGS.options_data.dropdown83						
	drop83.tooltip = "IGUI_tooltip_GunFighter_option83"						
	drop83[1]	 = ("REMOVE")					
	drop83[2]	 = ("25%")					
	drop83[3]	 = ("50%")					
	drop83[4]	 = ("75%")					
	drop83[5]	 = ("ALLOW")					
	local drop84 = SETTINGS.options_data.dropdown84						
	drop84.tooltip = "IGUI_tooltip_GunFighter_option84"						
	drop84[1]	 = ("REMOVE")					
	drop84[2]	 = ("25%")					
	drop84[3]	 = ("50%")					
	drop84[4]	 = ("75%")					
	drop84[5]	 = ("ALLOW")					
	local drop85 = SETTINGS.options_data.dropdown85						
	drop85.tooltip = "IGUI_tooltip_GunFighter_option85"						
	drop85[1]	 = ("REMOVE")					
	drop85[2]	 = ("25%")					
	drop85[3]	 = ("50%")					
	drop85[4]	 = ("75%")					
	drop85[5]	 = ("ALLOW")					
	local drop86 = SETTINGS.options_data.dropdown86						
	drop86.tooltip = "IGUI_tooltip_GunFighter_option86"						
	drop86[1]	 = ("REMOVE")					
	drop86[2]	 = ("25%")					
	drop86[3]	 = ("50%")					
	drop86[4]	 = ("75%")					
	drop86[5]	 = ("ALLOW")					
	local drop87 = SETTINGS.options_data.dropdown87						
	drop87.tooltip = "IGUI_tooltip_GunFighter_option87"						
	drop87[1]	 = ("REMOVE")					
	drop87[2]	 = ("25%")					
	drop87[3]	 = ("50%")					
	drop87[4]	 = ("75%")					
	drop87[5]	 = ("ALLOW")					
	local drop88 = SETTINGS.options_data.dropdown88						
	drop88.tooltip = "IGUI_tooltip_GunFighter_option88"						
	drop88[1]	 = ("REMOVE")					
	drop88[2]	 = ("25%")					
	drop88[3]	 = ("50%")					
	drop88[4]	 = ("75%")					
	drop88[5]	 = ("ALLOW")					
	local drop89 = SETTINGS.options_data.dropdown89						
	drop89.tooltip = "IGUI_tooltip_GunFighter_option89"						
	drop89[1]	 = ("REMOVE")					
	drop89[2]	 = ("25%")					
	drop89[3]	 = ("50%")					
	drop89[4]	 = ("75%")					
	drop89[5]	 = ("ALLOW")					
	local drop90 = SETTINGS.options_data.dropdown90					-- CONTAINER ROLL MODIFIERS	
	drop90.tooltip = "IGUI_tooltip_GunFighter_option90"						
	drop90[1]	 = ("1")					
	drop90[2]	 = ("2")					
	drop90[3]	 = ("3")					
	drop90[4]	 = ("4")					
	drop90[5]	 = ("5")					
	local drop91 = SETTINGS.options_data.dropdown91						
	drop91.tooltip = "IGUI_tooltip_GunFighter_option91"						
	drop91[1]	 = ("1")					
	drop91[2]	 = ("2")					
	drop91[3]	 = ("3")					
	drop91[4]	 = ("4")					
	drop91[5]	 = ("5")					
	local drop92 = SETTINGS.options_data.dropdown92						
	drop92.tooltip = "IGUI_tooltip_GunFighter_option92"						
	drop92[1]	 = ("1")					
	drop92[2]	 = ("2")					
	drop92[3]	 = ("3")					
	drop92[4]	 = ("4")					
	drop92[5]	 = ("5")					
	local drop93 = SETTINGS.options_data.dropdown93						
	drop93.tooltip = "IGUI_tooltip_GunFighter_option93"						
	drop93[1]	 = ("1")					
	drop93[2]	 = ("2")					
	drop93[3]	 = ("3")					
	drop93[4]	 = ("4")					
	drop93[5]	 = ("5")					
	local drop94 = SETTINGS.options_data.dropdown94						
	drop94.tooltip = "IGUI_tooltip_GunFighter_option94"						
	drop94[1]	 = ("1")					
	drop94[2]	 = ("2")					
	drop94[3]	 = ("3")					
	drop94[4]	 = ("4")					
	drop94[5]	 = ("5")					
	local drop95 = SETTINGS.options_data.dropdown95						
	drop95.tooltip = "IGUI_tooltip_GunFighter_option95"						
	drop95[1]	 = ("1")					
	drop95[2]	 = ("2")					
	drop95[3]	 = ("3")					
	drop95[4]	 = ("4")					
	drop95[5]	 = ("5")					
	local drop96 = SETTINGS.options_data.dropdown96						
	drop96.tooltip = "IGUI_tooltip_GunFighter_option96"						
	drop96[1]	 = ("1")					
	drop96[2]	 = ("2")					
	drop96[3]	 = ("3")					
	drop96[4]	 = ("4")					
	drop96[5]	 = ("5")					
	local drop97 = SETTINGS.options_data.dropdown97						
	drop97.tooltip = "IGUI_tooltip_GunFighter_option97"						
	drop97[1]	 = ("1")					
	drop97[2]	 = ("2")					
	drop97[3]	 = ("3")					
	drop97[4]	 = ("4")					
	drop97[5]	 = ("5")					
	local drop98 = SETTINGS.options_data.dropdown98						
	drop98.tooltip = "IGUI_tooltip_GunFighter_option98"						
	drop98[1]	 = ("1")					
	drop98[2]	 = ("2")					
	drop98[3]	 = ("3")					
	drop98[4]	 = ("4")					
	drop98[5]	 = ("5")					
	local drop99 = SETTINGS.options_data.dropdown99						
	drop99.tooltip = "IGUI_tooltip_GunFighter_option99"						
	drop99[1]	 = ("1")					
	drop99[2]	 = ("2")					
	drop99[3]	 = ("3")					
	drop99[4]	 = ("4")					
	drop99[5]	 = ("5")					
	local drop100 = SETTINGS.options_data.dropdown100						
	drop100.tooltip = "IGUI_tooltip_GunFighter_option100"						
	drop100[1]	 = ("1")					
	drop100[2]	 = ("2")					
	drop100[3]	 = ("3")					
	drop100[4]	 = ("4")					
	drop100[5]	 = ("5")					
	local drop101 = SETTINGS.options_data.dropdown101						
	drop101.tooltip = "IGUI_tooltip_GunFighter_option101"						
	drop101[1]	 = ("1")					
	drop101[2]	 = ("2")					
	drop101[3]	 = ("3")					
	drop101[4]	 = ("4")					
	drop101[5]	 = ("5")					
	local drop102 = SETTINGS.options_data.dropdown102						
	drop102.tooltip = "IGUI_tooltip_GunFighter_option102"						
	drop102[1]	 = ("1")					
	drop102[2]	 = ("2")					
	drop102[3]	 = ("3")					
	drop102[4]	 = ("4")					
	drop102[5]	 = ("5")					
	local drop103 = SETTINGS.options_data.dropdown103						
	drop103.tooltip = "IGUI_tooltip_GunFighter_option103"						
	drop103[1]	 = ("1")					
	drop103[2]	 = ("2")					
	drop103[3]	 = ("3")					
	drop103[4]	 = ("4")					
	drop103[5]	 = ("5")					
	local drop104 = SETTINGS.options_data.dropdown104						
	drop104.tooltip = "IGUI_tooltip_GunFighter_option104"						
	drop104[1]	 = ("1")					
	drop104[2]	 = ("2")					
	drop104[3]	 = ("3")					
	drop104[4]	 = ("4")					
	drop104[5]	 = ("5")					
	local drop105 = SETTINGS.options_data.dropdown105						
	drop105.tooltip = "IGUI_tooltip_GunFighter_option105"						
	drop105[1]	 = ("1")					
	drop105[2]	 = ("2")					
	drop105[3]	 = ("3")					
	drop105[4]	 = ("4")					
	drop105[5]	 = ("5")					
	local drop106 = SETTINGS.options_data.dropdown106						
	drop106.tooltip = "IGUI_tooltip_GunFighter_option106"						
	drop106[1]	 = ("1")					
	drop106[2]	 = ("2")					
	drop106[3]	 = ("3")					
	drop106[4]	 = ("4")					
	drop106[5]	 = ("5")					
	local drop107 = SETTINGS.options_data.dropdown107						
	drop107.tooltip = "IGUI_tooltip_GunFighter_option107"						
	drop107[1]	 = ("1")					
	drop107[2]	 = ("2")					
	drop107[3]	 = ("3")					
	drop107[4]	 = ("4")					
	drop107[5]	 = ("5")					
	local drop108 = SETTINGS.options_data.dropdown108						
	drop108.tooltip = "IGUI_tooltip_GunFighter_option108"						
	drop108[1]	 = ("1")					
	drop108[2]	 = ("2")					
	drop108[3]	 = ("3")					
	drop108[4]	 = ("4")					
	drop108[5]	 = ("5")					
	local drop109 = SETTINGS.options_data.dropdown109						
	drop109.tooltip = "IGUI_tooltip_GunFighter_option109"						
	drop109[1]	 = ("1")					
	drop109[2]	 = ("2")					
	drop109[3]	 = ("3")					
	drop109[4]	 = ("4")					
	drop109[5]	 = ("5")					
	local drop110 = SETTINGS.options_data.dropdown110						
	drop110.tooltip = "IGUI_tooltip_GunFighter_option110"						
	drop110[1]	 = ("1")					
	drop110[2]	 = ("2")					
	drop110[3]	 = ("3")					
	drop110[4]	 = ("4")					
	drop110[5]	 = ("5")					
	local drop111 = SETTINGS.options_data.dropdown111						
	drop111.tooltip = "IGUI_tooltip_GunFighter_option111"						
	drop111[1]	 = ("1")					
	drop111[2]	 = ("2")					
	drop111[3]	 = ("3")					
	drop111[4]	 = ("4")					
	drop111[5]	 = ("5")					
	local drop112 = SETTINGS.options_data.dropdown112						
	drop112.tooltip = "IGUI_tooltip_GunFighter_option112"						
	drop112[1]	 = ("1")					
	drop112[2]	 = ("2")					
	drop112[3]	 = ("3")					
	drop112[4]	 = ("4")					
	drop112[5]	 = ("5")					
	local drop113 = SETTINGS.options_data.dropdown113						
	drop113.tooltip = "IGUI_tooltip_GunFighter_option113"						
	drop113[1]	 = ("1")					
	drop113[2]	 = ("2")					
	drop113[3]	 = ("3")					
	drop113[4]	 = ("4")					
	drop113[5]	 = ("5")					
	local drop114 = SETTINGS.options_data.dropdown114					-- STORE PROBABILITY TRIM	
	drop114.tooltip = "IGUI_tooltip_GunFighter_option114"						
	drop114[1]	 = ("+ 0%")					
	drop114[2]	 = ("+ 10%")					
	drop114[3]	 = ("+ 20%")					
	drop114[4]	 = ("+ 30%")					
	drop114[5]	 = ("+ 40%")					
	drop114[6]	 = ("+ 50%")					
	drop114[7]	 = ("+ 60%")					
	drop114[8]	 = ("+ 70%")					
	drop114[9]	 = ("+ 80%")					
	drop114[10]	 = ("+ 90%")					
	drop114[11]	 = ("+ 100%")					
	drop114[12]	 = ("+ 110%")					
	drop114[13]	 = ("+ 120%")					
	drop114[14]	 = ("+ 130%")					
	drop114[15]	 = ("+ 140%")					
	drop114[16]	 = ("+ 150%")					
	drop114[17]	 = ("+ 160%")					
	drop114[18]	 = ("+ 170%")					
	drop114[19]	 = ("+ 180%")					
	drop114[20]	 = ("+ 190%")					
	drop114[21]	 = ("+ 200%")					
	local drop115 = SETTINGS.options_data.dropdown115						
	drop115.tooltip = "IGUI_tooltip_GunFighter_option115"						
	drop115[1]	 = ("+ 0%")					
	drop115[2]	 = ("+ 10%")					
	drop115[3]	 = ("+ 20%")					
	drop115[4]	 = ("+ 30%")					
	drop115[5]	 = ("+ 40%")					
	drop115[6]	 = ("+ 50%")					
	drop115[7]	 = ("+ 60%")					
	drop115[8]	 = ("+ 70%")					
	drop115[9]	 = ("+ 80%")					
	drop115[10]	 = ("+ 90%")					
	drop115[11]	 = ("+ 100%")					
	drop115[12]	 = ("+ 110%")					
	drop115[13]	 = ("+ 120%")					
	drop115[14]	 = ("+ 130%")					
	drop115[15]	 = ("+ 140%")					
	drop115[16]	 = ("+ 150%")					
	drop115[17]	 = ("+ 160%")					
	drop115[18]	 = ("+ 170%")					
	drop115[19]	 = ("+ 180%")					
	drop115[20]	 = ("+ 190%")					
	drop115[21]	 = ("+ 200%")					
	local drop116 = SETTINGS.options_data.dropdown116						
	drop116.tooltip = "IGUI_tooltip_GunFighter_option116"						
	drop116[1]	 = ("+ 0%")					
	drop116[2]	 = ("+ 10%")					
	drop116[3]	 = ("+ 20%")					
	drop116[4]	 = ("+ 30%")					
	drop116[5]	 = ("+ 40%")					
	drop116[6]	 = ("+ 50%")					
	drop116[7]	 = ("+ 60%")					
	drop116[8]	 = ("+ 70%")					
	drop116[9]	 = ("+ 80%")					
	drop116[10]	 = ("+ 90%")					
	drop116[11]	 = ("+ 100%")					
	drop116[12]	 = ("+ 110%")					
	drop116[13]	 = ("+ 120%")					
	drop116[14]	 = ("+ 130%")					
	drop116[15]	 = ("+ 140%")					
	drop116[16]	 = ("+ 150%")					
	drop116[17]	 = ("+ 160%")					
	drop116[18]	 = ("+ 170%")					
	drop116[19]	 = ("+ 180%")					
	drop116[20]	 = ("+ 190%")					
	drop116[21]	 = ("+ 200%")					
	drop116[22]	 = ("+ 210%")					
	drop116[23]	 = ("+ 220%")					
	drop116[24]	 = ("+ 230%")					
	drop116[25]	 = ("+ 240%")					
	drop116[26]	 = ("+ 250%")					
	drop116[27]	 = ("+ 260%")					
	drop116[28]	 = ("+ 270%")					
	drop116[29]	 = ("+ 280%")					
	drop116[30]	 = ("+ 290%")					
	drop116[31]	 = ("+ 300%")					
	local drop117 = SETTINGS.options_data.dropdown117						
	drop117.tooltip = "IGUI_tooltip_GunFighter_option117"						
	drop117[1]	 = ("+ 0%")					
	drop117[2]	 = ("+ 10%")					
	drop117[3]	 = ("+ 20%")					
	drop117[4]	 = ("+ 30%")					
	drop117[5]	 = ("+ 40%")					
	drop117[6]	 = ("+ 50%")					
	drop117[7]	 = ("+ 60%")					
	drop117[8]	 = ("+ 70%")					
	drop117[9]	 = ("+ 80%")					
	drop117[10]	 = ("+ 90%")					
	drop117[11]	 = ("+ 100%")					
	drop117[12]	 = ("+ 110%")					
	drop117[13]	 = ("+ 120%")					
	drop117[14]	 = ("+ 130%")					
	drop117[15]	 = ("+ 140%")					
	drop117[16]	 = ("+ 150%")					
	drop117[17]	 = ("+ 160%")					
	drop117[18]	 = ("+ 170%")					
	drop117[19]	 = ("+ 180%")					
	drop117[20]	 = ("+ 190%")					
	drop117[21]	 = ("+ 200%")					
	local drop118 = SETTINGS.options_data.dropdown118						
	drop118.tooltip = "IGUI_tooltip_GunFighter_option118"						
	drop118[1]	 = ("+ 0%")					
	drop118[2]	 = ("+ 10%")					
	drop118[3]	 = ("+ 20%")					
	drop118[4]	 = ("+ 30%")					
	drop118[5]	 = ("+ 40%")					
	drop118[6]	 = ("+ 50%")					
	drop118[7]	 = ("+ 60%")					
	drop118[8]	 = ("+ 70%")					
	drop118[9]	 = ("+ 80%")					
	drop118[10]	 = ("+ 90%")					
	drop118[11]	 = ("+ 100%")					
	drop118[12]	 = ("+ 110%")					
	drop118[13]	 = ("+ 120%")					
	drop118[14]	 = ("+ 130%")					
	drop118[15]	 = ("+ 140%")					
	drop118[16]	 = ("+ 150%")					
	drop118[17]	 = ("+ 160%")					
	drop118[18]	 = ("+ 170%")					
	drop118[19]	 = ("+ 180%")					
	drop118[20]	 = ("+ 190%")					
	drop118[21]	 = ("+ 200%")					
	local drop119 = SETTINGS.options_data.dropdown119						
	drop119.tooltip = "IGUI_tooltip_GunFighter_option119"						
	drop119[1]	 = ("+ 0%")					
	drop119[2]	 = ("+ 10%")					
	drop119[3]	 = ("+ 20%")					
	drop119[4]	 = ("+ 30%")					
	drop119[5]	 = ("+ 40%")					
	drop119[6]	 = ("+ 50%")					
	drop119[7]	 = ("+ 60%")					
	drop119[8]	 = ("+ 70%")					
	drop119[9]	 = ("+ 80%")					
	drop119[10]	 = ("+ 90%")					
	drop119[11]	 = ("+ 100%")					
	drop119[12]	 = ("+ 110%")					
	drop119[13]	 = ("+ 120%")					
	drop119[14]	 = ("+ 130%")					
	drop119[15]	 = ("+ 140%")					
	drop119[16]	 = ("+ 150%")					
	drop119[17]	 = ("+ 160%")					
	drop119[18]	 = ("+ 170%")					
	drop119[19]	 = ("+ 180%")					
	drop119[20]	 = ("+ 190%")					
	drop119[21]	 = ("+ 200%")					
	local opt120 = SETTINGS.options_data.box120						
	opt120.tooltip = "IGUI_tooltip_GunFighter_option120"						
	local opt121 = SETTINGS.options_data.box121						
	opt121.tooltip = "IGUI_tooltip_GunFighter_option121"						
	local opt122 = SETTINGS.options_data.box122						
	opt122.tooltip = "IGUI_tooltip_GunFighter_option122"						
	local opt123 = SETTINGS.options_data.box123						
	opt123.tooltip = "IGUI_tooltip_GunFighter_option123"						
	local opt124 = SETTINGS.options_data.box124						
	opt124.tooltip = "IGUI_tooltip_GunFighter_option124"						
	local opt125 = SETTINGS.options_data.box125						
	opt125.tooltip = "IGUI_tooltip_GunFighter_option125"						
	local drop126 = SETTINGS.options_data.dropdown126						
	drop126.tooltip = "IGUI_tooltip_GunFighter_option126"						
	drop126[1]	 = ("United States (recommeded MIL Trim 150+)")					
	drop126[2]	 = ("Soviet Union (recommended MIL Trim 260+)")					
	drop126[3]	 = ("Czech Republic (recommended MIL Trim 280+)")					
	drop126[4]	 = ("Republic of Korea (recommended MIL Trim 180+)")					
	drop126[5]	 = ("China / Pac-Rim (recommended MIL Trim 220+)")					
	drop126[6]	 = ("European Nations (recommended MIL Trim 160+)")					
	drop126[7]	 = ("Israel (recommended MIL Trim 170+)")					
	drop126[8]	 = ("None (recommended MIL Trim 50+)")					
	drop126[9]	 = ("None (recommended MIL Trim 50+)")					
	drop126[10]	 = ("None (recommended MIL Trim 50+)")					
	local drop127 = SETTINGS.options_data.dropdown127						
	drop127.tooltip = "IGUI_tooltip_GunFighter_option127"						
	drop127[1]	 = ("REMOVE")					
	drop127[2]	 = ("10%")					
	drop127[3]	 = ("20%")					
	drop127[4]	 = ("30%")					
	drop127[5]	 = ("40%")					
	drop127[6]	 = ("50%")					
	drop127[7]	 = ("60%")					
	drop127[8]	 = ("70%")					
	drop127[9]	 = ("80%")					
	drop127[10]	 = ("90%")					
	drop127[11]	 = ("100%")					
	drop127[12]	 = ("110%")					
	drop127[13]	 = ("120%")					
	drop127[14]	 = ("130%")					
	drop127[15]	 = ("140%")					
	drop127[16]	 = ("150%")					
	drop127[17]	 = ("160%")					
	drop127[18]	 = ("170%")					
	drop127[19]	 = ("180%")					
	drop127[20]	 = ("190%")					
	drop127[21]	 = ("200%")					
	local drop128 = SETTINGS.options_data.dropdown128						
	drop128.tooltip = "IGUI_tooltip_GunFighter_option128"						
	drop128[1]	 = ("DO NOT OVERRIDE")					
	drop128[2]	 = ("5%")					
	drop128[3]	 = ("10%")					
	drop128[4]	 = ("15%")					
	drop128[5]	 = ("20%")					
	drop128[6]	 = ("25%")					
	drop128[7]	 = ("30%")					
	drop128[8]	 = ("35%")					
	drop128[9]	 = ("40%")					
	drop128[10]	 = ("45%")					
	drop128[11]	 = ("50%")
	drop128[12]	 = ("55%")
	drop128[13]	 = ("60%")
	drop128[14]	 = ("65%")
	drop128[15]	 = ("70%")
	drop128[16]	 = ("75%")
	drop128[17]	 = ("80%")
	drop128[18]	 = ("85%")
	drop128[19]	 = ("90%")
	drop128[20]	 = ("95%")
	drop128[21]	 = ("100% NO REDUCTION")
	local drop129 = SETTINGS.options_data.dropdown129						
	drop129.tooltip = "IGUI_tooltip_GunFighter_option129"						
	drop129[1]	 = ("REMOVE")					
	drop129[2]	 = ("10%")					
	drop129[3]	 = ("20%")					
	drop129[4]	 = ("30%")					
	drop129[5]	 = ("40%")					
	drop129[6]	 = ("50%")					
	drop129[7]	 = ("60%")					
	drop129[8]	 = ("70%")					
	drop129[9]	 = ("80%")					
	drop129[10]	 = ("90%")					
	drop129[11]	 = ("100%")					
	local drop130 = SETTINGS.options_data.dropdown130						
	drop130.tooltip = "IGUI_tooltip_GunFighter_option130"						
	drop130[1]	 = ("REMOVE")					
	drop130[2]	 = ("10%")					
	drop130[3]	 = ("20%")					
	drop130[4]	 = ("30%")					
	drop130[5]	 = ("40%")					
	drop130[6]	 = ("50%")					
	drop130[7]	 = ("60%")					
	drop130[8]	 = ("70%")					
	drop130[9]	 = ("80%")					
	drop130[10]	 = ("90%")					
	drop130[11]	 = ("100%")					
	local opt131 = SETTINGS.options_data.box131						
	opt131.tooltip = "IGUI_tooltip_GunFighter_option131"						
	local drop132 = SETTINGS.options_data.dropdown132						
	drop132.tooltip = "IGUI_tooltip_GunFighter_option132"						
	drop132[1]	 = ("OFF")					
	drop132[2]	 = ("Smallest First")					
	drop132[3]	 = ("Largest First")					
	local drop133 = SETTINGS.options_data.dropdown133						
	drop133.tooltip = "IGUI_tooltip_GunFighter_option133"						
	drop133[1]	 = ("OFF")					
	drop133[2]	 = ("Manual [ON] w/Aiming")					
	drop133[3]	 = ("Auto [ON] w/Aiming")					
	local drop134 = SETTINGS.options_data.dropdown134						
	drop134.tooltip = "IGUI_tooltip_GunFighter_option134"						
	drop134[1]	 = ("NEVER [Retain] Always")					
	drop134[2]	 = ("Manual [Drop] on second Press")					
	drop134[3]	 = ("Always [Drop] on Running")					
	drop134[4]	 = ("BOTH")					
	local drop135 = SETTINGS.options_data.dropdown135						
	drop135.tooltip = "IGUI_tooltip_GunFighter_option135"						
	drop135[1]	 = ("NEVER")					
	drop135[2]	 = ("1/4")					
	drop135[3]	 = ("1/6")					
	drop135[4]	 = ("1/8")					
	drop135[5]	 = ("1/10")					
	drop135[6]	 = ("1/12")					
	drop135[7]	 = ("1/14")					
	drop135[8]	 = ("1/16")					
	drop135[9]	 = ("1/18")					
	drop135[10]	 = ("1/20")					
	local opt136 = SETTINGS.options_data.box136						
	opt136.tooltip = "IGUI_tooltip_GunFighter_option136"						
	local drop137 = SETTINGS.options_data.dropdown137						
	drop137.tooltip = "IGUI_tooltip_GunFighter_option137"						
	drop137[1]	 = ("1 - Shortest")					
	drop137[2]	 = ("2")					
	drop137[3]	 = ("3")					
	drop137[4]	 = ("4")					
	drop137[5]	 = ("5")					
	drop137[6]	 = ("6")					
	drop137[7]	 = ("7")					
	drop137[8]	 = ("8")					
	drop137[9]	 = ("9")					
	drop137[10]	 = ("10 - Longest")					
	local drop138 = SETTINGS.options_data.dropdown138						
	drop138.tooltip = "IGUI_tooltip_GunFighter_option138"						
	drop138[1]	 = ("NEVER")					
	drop138[2]	 = ("1/10")					
	drop138[3]	 = ("1/9")					
	drop138[4]	 = ("1/8")					
	drop138[5]	 = ("1/7")					
	drop138[6]	 = ("1/6")					
	drop138[7]	 = ("1/5")					
	drop138[8]	 = ("1/4")					
	drop138[9]	 = ("1/3")					
	drop138[10]	 = ("1/2")					
	drop138[11]	 = ("ALWAYS")					
	local opt139 = SETTINGS.options_data.box139						
	opt139.tooltip = "IGUI_tooltip_GunFighter_option139"						
	local opt140 = SETTINGS.options_data.box140						
	opt140.tooltip = "IGUI_tooltip_GunFighter_option140"						
	local drop141 = SETTINGS.options_data.dropdown141						
	drop141.tooltip = "IGUI_tooltip_GunFighter_option141"						
	drop141[1]	 = ("50%")
	drop141[2]	 = ("60%")
	drop141[3]	 = ("70%")
	drop141[4]	 = ("80%")
	drop141[5]	 = ("90%")
	drop141[6]	 = ("100% [DEFAULT]")
	drop141[7]	 = ("110%")
	drop141[8]	 = ("120%")
	drop141[9]	 = ("130%")
	drop141[10]	 = ("140%")
	drop141[11]	 = ("150%")
	drop141[12]	 = ("160%")
	drop141[13]	 = ("170%")
	drop141[14]	 = ("180%")
	drop141[15]	 = ("190%")
	drop141[16]	 = ("200%")
	local opt142 = SETTINGS.options_data.box142						
	opt142.tooltip = "IGUI_tooltip_GunFighter_option142"						
	local drop143 = SETTINGS.options_data.dropdown143						
	drop143.tooltip = "IGUI_tooltip_GunFighter_option143"						
	drop143[1]	 = ("NONE - Not Fixed")					
	drop143[2]	 = ("0.1")					
	drop143[3]	 = ("0.2")					
	drop143[4]	 = ("0.3")					
	drop143[5]	 = ("0.4")					
	drop143[6]	 = ("0.5")					
	drop143[7]	 = ("0.6")					
	drop143[8]	 = ("0.7")					
	drop143[9]	 = ("0.8")					
	drop143[10]	 = ("0.9")					
	drop143[11]	 = ("1.0")					
	local drop144 = SETTINGS.options_data.dropdown144						
	drop144.tooltip = "IGUI_tooltip_GunFighter_option144"						
	drop144[1]	 = ("Manual [ON] w/Aiming")					
	drop144[2]	 = ("Manual [ON] w/Aiming (No-Glow)")					
	drop144[3]	 = ("Auto [ON] w/Aiming")					
	drop144[4]	 = ("Auto [ON] w/Aiming (No-Glow)")					
	local drop145 = SETTINGS.options_data.dropdown145						
	drop145.tooltip = "IGUI_tooltip_GunFighter_option145"						
	drop145[1]	 = ("INFINITE RUNTIME")					
	drop145[2]	 = ("0.000001")					
	drop145[3]	 = ("0.000005")					
	drop145[4]	 = ("0.00001")					
	drop145[5]	 = ("0.00005")					
	drop145[6]	 = ("0.0001")					
	drop145[7]	 = ("0.0005")					
	drop145[8]	 = ("0.001")					
	drop145[9]	 = ("0.005")					
	drop145[10]	 = ("FAST DRAIN (Test)")
	local drop146 = SETTINGS.options_data.dropdown146						
	drop146.tooltip = "IGUI_tooltip_GunFighter_option146"						
	drop146[1]	 = ("NO Penalty")					
	drop146[2]	 = ("Limit Overall Speed Only")					
	drop146[3]	 = ("Limit Sprinting")					
	drop146[4]	 = ("Limit Running / Sprinting")					
	drop146[5]	 = ("Limit Walking to Sneak Mode")					
	drop146[6]	 = ("ALL the Above")
	local drop147 = SETTINGS.options_data.dropdown147
	drop147.tooltip = "IGUI_tooltip_GunFighter_option147"
	drop147[1]	 = ("50%")
	drop147[2]	 = ("60%")
	drop147[3]	 = ("70%")
	drop147[4]	 = ("80%")
	drop147[5]	 = ("90%")
	drop147[6]	 = ("100% [DEFAULT]")
	drop147[7]	 = ("110%")
	drop147[8]	 = ("120%")
	drop147[9]	 = ("130%")
	drop147[10]	 = ("140%")
	drop147[11]	 = ("150%")
	drop147[12]	 = ("160%")
	drop147[13]	 = ("170%")
	drop147[14]	 = ("180%")
	drop147[15]	 = ("190%")
	drop147[16]	 = ("200%")
	local drop148 = SETTINGS.options_data.dropdown148
	drop148.tooltip = "IGUI_tooltip_GunFighter_option148"
	drop148[1]	 = ("50%")
	drop148[2]	 = ("60%")
	drop148[3]	 = ("70%")
	drop148[4]	 = ("80%")
	drop148[5]	 = ("90%")
	drop148[6]	 = ("100% [DEFAULT]")
	drop148[7]	 = ("110%")
	drop148[8]	 = ("120%")
	drop148[9]	 = ("130%")
	drop148[10]	 = ("140%")
	drop148[11]	 = ("150%")
	drop148[12]	 = ("160%")
	drop148[13]	 = ("170%")
	drop148[14]	 = ("180%")
	drop148[15]	 = ("190%")
	drop148[16]	 = ("200%")


	if isClient() then

	opt0.sandbox_path = "HIDE FROM CLIENT"						
	opt1.sandbox_path = "HIDE FROM CLIENT"					-- SHOW HIT DAMAGE       	
	opt2.sandbox_path = "HIDE FROM CLIENT"					-- SHOW HIT % RANGE     	
	drop3.sandbox_path = "HIDE FROM CLIENT"					-- SHOW WEAPON INFO     	
	opt4.sandbox_path = "HIDE FROM CLIENT"					-- DISPLAY AMMO COUNTER  	
	opt5.sandbox_path = "HIDE FROM CLIENT"					-- DISPLAY MOVEMENT GAUGE	
	opt6.sandbox_path = "HIDE FROM CLIENT"						
	drop7.sandbox_path = "HIDE FROM CLIENT"						
	opt8.sandbox_path = "HIDE FROM CLIENT"						
	drop9.sandbox_path = "HIDE FROM CLIENT"						
	opt10.sandbox_path = "HIDE FROM CLIENT"						
	drop11.sandbox_path = "HIDE FROM CLIENT"						
	drop12.sandbox_path = "HIDE FROM CLIENT"						
	drop13.sandbox_path = "HIDE FROM CLIENT"						
	drop14.sandbox_path = "HIDE FROM CLIENT"						
	drop15.sandbox_path = "HIDE FROM CLIENT"						
	opt16.sandbox_path = "HIDE FROM CLIENT"						
	drop17.sandbox_path = "HIDE FROM CLIENT"					-- DEBUG LEVELS            	
	opt18.sandbox_path = "HIDE FROM CLIENT"						
	drop19.sandbox_path = "HIDE FROM CLIENT"						
	drop20.sandbox_path = "HIDE FROM CLIENT"						
	drop21.sandbox_path = "HIDE FROM CLIENT"						
	drop22.sandbox_path = "HIDE FROM CLIENT"						
	drop23.sandbox_path = "HIDE FROM CLIENT"						
	drop24.sandbox_path = "HIDE FROM CLIENT"						
	drop25.sandbox_path = "HIDE FROM CLIENT"						
	drop26.sandbox_path = "HIDE FROM CLIENT"						
	drop27.sandbox_path = "HIDE FROM CLIENT"						
	drop28.sandbox_path = "HIDE FROM CLIENT"						
	drop29.sandbox_path = "HIDE FROM CLIENT"						
	drop30.sandbox_path = "HIDE FROM CLIENT"						
	drop31.sandbox_path = "HIDE FROM CLIENT"						
	drop32.sandbox_path = "HIDE FROM CLIENT"						
	drop33.sandbox_path = "HIDE FROM CLIENT"						
	drop34.sandbox_path = "HIDE FROM CLIENT"						
	drop35.sandbox_path = "HIDE FROM CLIENT"						
	drop36.sandbox_path = "HIDE FROM CLIENT"						
	drop37.sandbox_path = "HIDE FROM CLIENT"						
	drop38.sandbox_path = "HIDE FROM CLIENT"						
	drop39.sandbox_path = "HIDE FROM CLIENT"						
	drop40.sandbox_path = "HIDE FROM CLIENT"						
	drop41.sandbox_path = "HIDE FROM CLIENT"						
	drop42.sandbox_path = "HIDE FROM CLIENT"						
	drop43.sandbox_path = "HIDE FROM CLIENT"						
	drop44.sandbox_path = "HIDE FROM CLIENT"						
	drop45.sandbox_path = "HIDE FROM CLIENT"						
	drop46.sandbox_path = "HIDE FROM CLIENT"						
	drop47.sandbox_path = "HIDE FROM CLIENT"						
	drop48.sandbox_path = "HIDE FROM CLIENT"						
	drop49.sandbox_path = "HIDE FROM CLIENT"						
	drop50.sandbox_path = "HIDE FROM CLIENT"						
	drop51.sandbox_path = "HIDE FROM CLIENT"						
	drop52.sandbox_path = "HIDE FROM CLIENT"						
	drop53.sandbox_path = "HIDE FROM CLIENT"						
	drop54.sandbox_path = "HIDE FROM CLIENT"						
	drop55.sandbox_path = "HIDE FROM CLIENT"						
	drop56.sandbox_path = "HIDE FROM CLIENT"						
	drop57.sandbox_path = "HIDE FROM CLIENT"						
	drop58.sandbox_path = "HIDE FROM CLIENT"						
	drop59.sandbox_path = "HIDE FROM CLIENT"						
	drop60.sandbox_path = "HIDE FROM CLIENT"						
	drop61.sandbox_path = "HIDE FROM CLIENT"						
	drop62.sandbox_path = "HIDE FROM CLIENT"						
	drop63.sandbox_path = "HIDE FROM CLIENT"						
	drop64.sandbox_path = "HIDE FROM CLIENT"						
	drop65.sandbox_path = "HIDE FROM CLIENT"						
	drop66.sandbox_path = "HIDE FROM CLIENT"						
	drop67.sandbox_path = "HIDE FROM CLIENT"						
	drop68.sandbox_path = "HIDE FROM CLIENT"						
	drop69.sandbox_path = "HIDE FROM CLIENT"						
	drop70.sandbox_path = "HIDE FROM CLIENT"						
	drop71.sandbox_path = "HIDE FROM CLIENT"						
	drop72.sandbox_path = "HIDE FROM CLIENT"						
	drop73.sandbox_path = "HIDE FROM CLIENT"						
	drop74.sandbox_path = "HIDE FROM CLIENT"						
	drop75.sandbox_path = "HIDE FROM CLIENT"						
	drop76.sandbox_path = "HIDE FROM CLIENT"						
	drop77.sandbox_path = "HIDE FROM CLIENT"						
	drop78.sandbox_path = "HIDE FROM CLIENT"						
	drop79.sandbox_path = "HIDE FROM CLIENT"						
	drop80.sandbox_path = "HIDE FROM CLIENT"						
	drop81.sandbox_path = "HIDE FROM CLIENT"						
	drop82.sandbox_path = "HIDE FROM CLIENT"						
	drop83.sandbox_path = "HIDE FROM CLIENT"						
	drop84.sandbox_path = "HIDE FROM CLIENT"						
	drop85.sandbox_path = "HIDE FROM CLIENT"						
	drop86.sandbox_path = "HIDE FROM CLIENT"						
	drop87.sandbox_path = "HIDE FROM CLIENT"						
	drop88.sandbox_path = "HIDE FROM CLIENT"						
	drop89.sandbox_path = "HIDE FROM CLIENT"						
	drop90.sandbox_path = "HIDE FROM CLIENT"						
	drop91.sandbox_path = "HIDE FROM CLIENT"						
	drop92.sandbox_path = "HIDE FROM CLIENT"						
	drop93.sandbox_path = "HIDE FROM CLIENT"						
	drop94.sandbox_path = "HIDE FROM CLIENT"						
	drop95.sandbox_path = "HIDE FROM CLIENT"						
	drop96.sandbox_path = "HIDE FROM CLIENT"						
	drop97.sandbox_path = "HIDE FROM CLIENT"						
	drop98.sandbox_path = "HIDE FROM CLIENT"						
	drop99.sandbox_path = "HIDE FROM CLIENT"						
	drop100.sandbox_path = "HIDE FROM CLIENT"						
	drop101.sandbox_path = "HIDE FROM CLIENT"						
	drop102.sandbox_path = "HIDE FROM CLIENT"						
	drop103.sandbox_path = "HIDE FROM CLIENT"						
	drop104.sandbox_path = "HIDE FROM CLIENT"						
	drop105.sandbox_path = "HIDE FROM CLIENT"						
	drop106.sandbox_path = "HIDE FROM CLIENT"						
	drop107.sandbox_path = "HIDE FROM CLIENT"						
	drop108.sandbox_path = "HIDE FROM CLIENT"						
	drop109.sandbox_path = "HIDE FROM CLIENT"						
	drop110.sandbox_path = "HIDE FROM CLIENT"						
	drop111.sandbox_path = "HIDE FROM CLIENT"						
	drop112.sandbox_path = "HIDE FROM CLIENT"						
	drop113.sandbox_path = "HIDE FROM CLIENT"						
	drop114.sandbox_path = "HIDE FROM CLIENT"						
	drop115.sandbox_path = "HIDE FROM CLIENT"						
	drop116.sandbox_path = "HIDE FROM CLIENT"						
	drop117.sandbox_path = "HIDE FROM CLIENT"						
	drop118.sandbox_path = "HIDE FROM CLIENT"						
	drop119.sandbox_path = "HIDE FROM CLIENT"						
	opt120.sandbox_path = "HIDE FROM CLIENT"						
	opt121.sandbox_path = "HIDE FROM CLIENT"						
	opt122.sandbox_path = "HIDE FROM CLIENT"						
	opt123.sandbox_path = "HIDE FROM CLIENT"						
	opt124.sandbox_path = "HIDE FROM CLIENT"						
	opt125.sandbox_path = "HIDE FROM CLIENT"						
	drop126.sandbox_path = "HIDE FROM CLIENT"						
	drop127.sandbox_path = "HIDE FROM CLIENT"						
	drop128.sandbox_path = "HIDE FROM CLIENT"						
	drop129.sandbox_path = "HIDE FROM CLIENT"						
	drop130.sandbox_path = "HIDE FROM CLIENT"						
	opt131.sandbox_path = "HIDE FROM CLIENT"					-- AUTO RELOAD THROWN    	
	drop132.sandbox_path = "HIDE FROM CLIENT"					-- AUTO SELECT MAG TYPE    	
	drop133.sandbox_path = "HIDE FROM CLIENT"					-- NV CONTROL            	
	drop134.sandbox_path = "HIDE FROM CLIENT"					-- EMERGENCY RELOAD        	
	drop135.sandbox_path = "HIDE FROM CLIENT"						
	opt136.sandbox_path = "HIDE FROM CLIENT"					-- VISUAL FIREARM EFFECTS	
	drop137.sandbox_path = "HIDE FROM CLIENT"						
	drop138.sandbox_path = "HIDE FROM CLIENT"						
	opt139.sandbox_path = "HIDE FROM CLIENT"						
	opt140.sandbox_path = "HIDE FROM CLIENT"						
	drop141.sandbox_path = "HIDE FROM CLIENT"						
	opt142.sandbox_path = "HIDE FROM CLIENT"						
	drop143.sandbox_path = "HIDE FROM CLIENT"						
	drop144.sandbox_path = "HIDE FROM CLIENT"					-- AUTO TOGGLE LASER    	
	drop145.sandbox_path = "HIDE FROM CLIENT"						
	drop146.sandbox_path = "HIDE FROM CLIENT"						
	drop147.sandbox_path = "HIDE FROM CLIENT"						
	drop148.sandbox_path = "HIDE FROM CLIENT"						
	end


	function opt0:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt1:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt2:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop3:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt4:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt5:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt6:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop7:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt8:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop9:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt10:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop11:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop12:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop13:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop14:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop15:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt16:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop17:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt18:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop19:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop20:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop21:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop22:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop23:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop24:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop25:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop26:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop27:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop28:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop29:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop30:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop31:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop32:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop33:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop34:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop35:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop36:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop37:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop38:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop39:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop40:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop41:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop42:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop43:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop44:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop45:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop46:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop47:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop48:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop49:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop50:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop51OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop52OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop53OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop54OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop55:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop56:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop57:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop58:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop59:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop60:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop61:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop62:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop63:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop64:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop65:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop66:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop67:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop68:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop69:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop70:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop71:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop72:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop73:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop74:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop75:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop76:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop77:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop78:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop79:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop80:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop81:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop82:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop83:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop84:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop85:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop86:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop87:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop88:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop89:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop90:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop91:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop92:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop93:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop94:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop95:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop96:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop97:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop98:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop99:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop100:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop101:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop102:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop103:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop104:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop105:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop106:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop107:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop108:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop109:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop110:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop111:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop112:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop113:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop114:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop115:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop116:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop117:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop118:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop119:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt120:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt121:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt122:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt123:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt124:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt125:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop126:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop127:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop128:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop129:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop130:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt131:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop132:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop133:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop134:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop135:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt136:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop137:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop138:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt139:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt140:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop141:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function opt142:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop143:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop144:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop145:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end						
	function drop146:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end
	function drop147:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end	
	function drop148:OnApplyInGame(val)						
		print('Option is updated!', self.id, val)					
	end	
							
	GUNFIGHTER = {}
	GUNFIGHTER.OPTIONS = SETTINGS
end

local function initGunFighterSandboxOptions()
	SETTINGS = {					
		options = {
			box0		=	true	,										-- RESERVED
			box1		=	SandboxVars.A26.BoolShowHitDamage,				-- SHOW HIT DAMAGE			(true or false)
			box2		=	SandboxVars.A26.BoolShowHitRange,				-- SHOW HIT % RANGE			(true or false)
			dropdown3	=	SandboxVars.A26.EnumShowWeaponInfo,				-- SHOW WEAPON INFO			(1 - 3)
			box4		=	SandboxVars.A26.BoolDisplayAmmoCounter,			-- DISPLAY AMMO COUNTER		(true or false)
			box5		=	SandboxVars.A26.BoolDisplayMovementGauge,		-- DISPLAY MOVEMENT GAUGE	(true or false)
			box6		=	SandboxVars.A26.BoolDynamicRecoilSystem,		-- DYNAMIC RECOIL SYSTEM	(true or false)
			dropdown7	=	SandboxVars.A26.EnumDynamicRangeSystem,			-- DYNAMIC RANGE SYSTEM		(1 - 5)
			box8		=	SandboxVars.A26.BoolResetSightPicture,			-- RESET SIGHT PICTURE		(true or false)
			dropdown9	=	SandboxVars.A26.EnumFirearmJam,					-- FIREARM JAM				(1 - 5)
			box10		=	SandboxVars.A26.BoolFireArmsNeverBreak,			-- FIREARMS NEVER BREAK		(true or false)
			dropdown11	=	SandboxVars.A26.EnumAttachementsBreakOnMelee,	-- ATTACHMENTS BREAK ON MELEE	(1 - 5)
			dropdown12	=	SandboxVars.A26.EnumAttachmentsBreakOnFire,		-- ATTACHMENTS BREAK ON FIRE	(1 - 5)
			dropdown13	=	SandboxVars.A26.EnumSoundSuppression,			-- SOUND SUPPRESSION		(1 - 6)
			dropdown14	=	SandboxVars.A26.EnumSoundLinearBase,			-- SOUND LINEAR BASE		(1 - 21)	
			dropdown15	=	SandboxVars.A26.EnumLauncherRangeMultiplier,	-- LAUNCHER RANGE MULTIPLIER	(1 - 5)	
			box16		=	SandboxVars.A26.BoolVehiclePenalty,				-- VEHICLE PENALTY			(true or false)
			dropdown17	=	SandboxVars.A26.EnumDebugLevels,				-- DEBUG LEVELS				(1 - 4)	
			box18		=	SandboxVars.A26.BoolUseVanillaShotSounds,		-- USE VANILLA SHOT SOUNDS	(true or false)
			dropdown19	=	SandboxVars.A26.EnumEjectSpentCasings,			-- EJECT SPENT CASINGS		(1 - 11)
			dropdown20	=	SandboxVars.A26.EnumTypeBOW,					-- TYPE	BOW					(1 - 11)
			dropdown21	=	SandboxVars.A26.EnumTypeFLAME,					-- TYPE	FLAME				(1 - 11)
			dropdown22	=	SandboxVars.A26.EnumTypeGREN,					-- TYPE	GRENADE / ROCKET	(1 - 11)
			dropdown23	=	SandboxVars.A26.EnumTypeMINI,					-- TYPE	MINIGUN				(1 - 11)
			dropdown24	=	SandboxVars.A26.EnumTypeLMG,					-- TYPE	LIGHT MACHINEGUN	(1 - 11)
			dropdown25	=	SandboxVars.A26.EnumTypeSEMI,					-- TYPE	SEMI AUTOMATIC		(1 - 11)
			dropdown26	=	SandboxVars.A26.EnumTypeAUTO,					-- TYPE	AUTOMATIC RIFLE		(1 - 11)
			dropdown27	=	SandboxVars.A26.EnumTypeSMG,					-- TYPE	AUTOMATIC PISTOL	(1 - 11)
			dropdown28	=	SandboxVars.A26.EnumTypeLEVER,					-- TYPE	LEVERGUN			(1 - 11)
			dropdown29	=	SandboxVars.A26.EnumTypeREV,					-- TYPE	REVOLVER			(1 - 11)
			dropdown30	=	SandboxVars.A26.EnumTypePUMP,					-- TYPE	PUMP ACTION			(1 - 11)	
			dropdown31	=	SandboxVars.A26.EnumTypeBOLT,					-- TYPE	BOLT ACTION			(1 - 11)
			dropdown32	=	SandboxVars.A26.EnumTypeBREAK,					-- TYPE	BREAK ACTION		(1 - 11)
			dropdown33	=	SandboxVars.A26.EnumOriginUSA,					-- ORIGIN (UNITED STATES)	(1 - 11)
			dropdown34	=	SandboxVars.A26.EnumOriginSOV,					-- ORIGIN (SOVIET UNION)	(1 - 11)
			dropdown35	=	SandboxVars.A26.EnumOriginKOR,					-- ORIGIN (REP KOREA)		(1 - 11)
			dropdown36	=	SandboxVars.A26.EnumOriginPAC,					-- ORIGIN (PAC RIM)			(1 - 11)
			dropdown37	=	SandboxVars.A26.EnumOriginCZE,					-- ORIGIN (CZECH REP)		(1 - 11)
			dropdown38	=	SandboxVars.A26.EnumOriginEUR,					-- ORIGIN (EUROPE)			(1 - 11)
			dropdown39	=	SandboxVars.A26.EnumOriginISR,					-- ORIGIN (ISREAL)			(1 - 11)
			dropdown40	=	SandboxVars.A26.EnumOriginREST,					-- ORIGIN (REST WORLD)		(1 - 11)
			dropdown41	=	SandboxVars.A26.EnumCaliber50BMG,				-- CALIBER (50 BMG/MAG)		(1 - 11)
			dropdown42	=	SandboxVars.A26.EnumCaliber4gShot,				-- CALIBER (4g SHOT)		(1 - 11)
			dropdown43	=	SandboxVars.A26.EnumCaliber10gShot,				-- CALIBER (10g SHOT)		(1 - 11)
			dropdown44	=	SandboxVars.A26.EnumCaliber12gShot,				-- CALIBER (12g SHOT)		(1 - 11)
			dropdown45	=	SandboxVars.A26.EnumCaliber20gShot,				-- CALIBER (20g SHOT)		(1 - 11)
			dropdown46	=	SandboxVars.A26.EnumCaliber3006SPG,				-- CALIBER (30-06 SPG)		(1 - 11)
			dropdown47	=	SandboxVars.A26.EnumCaliber308WIN,				-- CALIBER (308 WIN)		(1 - 11)
			dropdown48	=	SandboxVars.A26.EnumCaliber762x54mmR,			-- CALIBER (7.62x54mm R)	(1 - 11)
			dropdown49	=	SandboxVars.A26.EnumCaliber545x39mm,			-- CALIBER (5.45x39mm)		(1 - 11)
			dropdown50	=	SandboxVars.A26.EnumCaliber762x39mm,			-- CALIBER (7.62x39mm)		(1 - 11)
			dropdown51	=	SandboxVars.A26.EnumCaliber556x45mm,			-- CALIBER (5.56x45mm)		(1 - 11)
			dropdown52	=	SandboxVars.A26.EnumCaliber223REM,				-- CALIBER (.223 REM)		(1 - 11)
			dropdown53	=	SandboxVars.A26.EnumCaliber45LC410g,			-- CALIBER (45 COLT / 410g)	(1 - 11)
			dropdown54	=	SandboxVars.A26.EnumCaliber4570,				-- CALIBER (46-70)			(1 - 11)
			dropdown55	=	SandboxVars.A26.EnumCaliber44MAG,				-- CALIBER (44 Mag)			(1 - 11)
			dropdown56	=	SandboxVars.A26.EnumCaliber45ACP,				-- CALIBER (45 ACP)			(1 - 11)
			dropdown57	=	SandboxVars.A26.EnumCaliber38SPC,				-- CALIBER (38 SPC)			(1 - 11)
			dropdown58	=	SandboxVars.A26.EnumCaliber9mm,					-- CALIBER (9mm)			(1 - 11)
			dropdown59	=	SandboxVars.A26.EnumCaliber57x28mm,				-- CALIBER (5.7x28mm)		(1 - 11)
			dropdown60	=	SandboxVars.A26.EnumCaliber380ACP,				-- CALIBER (380 ACP)		(1 - 11)
			dropdown61	=	SandboxVars.A26.EnumCaliber22LR,				-- CALIBER (22 LR)			(1 - 11)
			dropdown62	=	SandboxVars.A26.EnumCaliber177BB,				-- CALIBER (177 BB)			(1 - 11)
			dropdown63	=	SandboxVars.A26.EnumRandomCases,				-- RANDOM CASES				(1 - 11)	
			dropdown64	=	SandboxVars.A26.EnumAttachementSuppressor,		-- ATTACHMENT SUPPRESSOR	(1 - 11)	
			dropdown65	=	SandboxVars.A26.EnumAttachementOptics,			-- ATTACHMENT OPTICS		(1 - 11)	
			dropdown66	=	SandboxVars.A26.EnumAttachementLightLaser,		-- ATTACHMENT LIGHTS / LASER	(1 - 11)
			dropdown67	=	SandboxVars.A26.EnumAttachementAllOther,		-- ATTACHMENT ALL OTHER		(1 - 11)
			dropdown68	=	SandboxVars.A26.EnumAmmoCan,					-- AMMUNITION CANISTER		(1 - 11)
			dropdown69	=	SandboxVars.A26.EnumAmmoBox,					-- AMMUNITION BOX			(1 - 11)
			dropdown70	=	SandboxVars.A26.EnumStdMag,						-- MAGAZINE STANDARD		(1 - 11)
			dropdown71	=	SandboxVars.A26.EnumExtMag,						-- MAGAZINE EXTENDED		(1 - 11)
			dropdown72	=	SandboxVars.A26.EnumDrumMag,					-- MAGAZINE DRUM			(1 - 11)
			dropdown73	=	SandboxVars.A26.EnumPolyCan,					-- POLYMER CANISTER			(1 - 11)
			dropdown74	=	SandboxVars.A26.EnumMeleeKnifeLarge,			-- MELEE KNIFE LARGE		(1 - 11)
			dropdown75	=	SandboxVars.A26.EnumMeleeKnifeSmall,			-- MELEE KNIFE SMALL		(1 - 11)
			dropdown76	=	SandboxVars.A26.EnumMeleeSword,					-- MELEE SWORD				(1 - 11)
			dropdown77	=	SandboxVars.A26.EnumMeleeAxe,					-- MELEE AXE				(1 - 11)
			dropdown78	=	SandboxVars.A26.EnumMeleeBlunt,					-- MELEE BLUNT				(1 - 11)
			dropdown79	=	SandboxVars.A26.EnumMeleeSpear,					-- MELEE SPEAR				(1 - 11)
			dropdown80	=	SandboxVars.A26.EnumArmor,						-- ARMOR (FWP / USMC)	(1 - 21)
			dropdown81	=	SandboxVars.A26.EnumPost1992Production,			-- POST 1992 PRODUCTION		(1 - 5)	
			dropdown82	=	SandboxVars.A26.EnumCIVxLEO,					-- LEO IN CIV				(1 - 5)
			dropdown83	=	SandboxVars.A26.EnumCIVxMIL,					-- MIL IN CIV				(1 - 5)	
			dropdown84	=	SandboxVars.A26.EnumLEOxCIV,					-- CIV IN LEO				(1 - 5)	
			dropdown85	=	SandboxVars.A26.EnumLEOxMIL,					-- MIL IN LEO				(1 - 5)	
			dropdown86	=	SandboxVars.A26.EnumMILxNON,					-- NON MIL IN MIL			(1 - 5)
			dropdown87	=	SandboxVars.A26.EnumSECxNON,					-- NON SEC IN SEC			(1 - 5)
			dropdown88	=	SandboxVars.A26.EnumHNTxNON,					-- NON HNT IN HNT			(1 - 5)
			dropdown89	=	SandboxVars.A26.EnumSURxNON,					-- NON SUR IN SUR			(1 - 5)
			dropdown90	=	SandboxVars.A26.EnumGUNRollGUN,					-- ROLLS GUNSTORE (GUNS)	(1 - 5)
			dropdown91	=	SandboxVars.A26.EnumGUNRollAMMO,				-- ROLLS GUNSTORE (AMMO)	(1 - 5)	
			dropdown92	=	SandboxVars.A26.EnumGUNRollPART,				-- ROLLS GUNSTORE (PARTS)	(1 - 5)
			dropdown93	=	SandboxVars.A26.EnumGUNRollARMOR,				-- ROLLS GUNSTORE (ARMOR)	(1 - 5)
			dropdown94	=	SandboxVars.A26.EnumLEORollGUN,					-- ROLLS POLICE (GUNS+++)	(1 - 5)
			dropdown95	=	SandboxVars.A26.EnumLEORollAMMO,				-- ROLLS POLICE (AMMO/MAG)	(1 - 5)	
			dropdown96	=	SandboxVars.A26.EnumLEORollPART,				-- ROLLS POLICE (NOT USED)	(1 - 5)
			dropdown97	=	SandboxVars.A26.EnumLEORollARMOR,				-- ROLLS POLICE (ARMOR)		(1 - 5)
			dropdown98	=	SandboxVars.A26.EnumMILRollGUN,					-- ROLLS MILITARY (GUNS+++)	(1 - 5)
			dropdown99	=	SandboxVars.A26.EnumMILRollAMMO,				-- ROLLS MILITARY (AMMO/MAG)(1 - 5)
			dropdown100	=	SandboxVars.A26.EnumMILRollPART,				-- ROLLS MILITARY (NOT USED)(1 - 5)
			dropdown101	=	SandboxVars.A26.EnumMILRollARMOR,				-- ROLLS MILITARY (ARMOR)	(1 - 5)
			dropdown102	=	SandboxVars.A26.EnumSECRollGUN,					-- ROLLS SECURITY (GUNS+++)	(1 - 5)
			dropdown103	=	SandboxVars.A26.EnumSECRollAMMO,				-- ROLLS SECURITY (AMMO/MAG)(1 - 5)
			dropdown104	=	SandboxVars.A26.EnumSECRollPART,				-- ROLLS SECURITY (NOT USED)(1 - 5)
			dropdown105	=	SandboxVars.A26.EnumSECRollARMOR,				-- ROLLS SECURITY (ARMOR)	(1 - 5)
			dropdown106	=	SandboxVars.A26.EnumSURRollGUN,					-- ROLLS SURPLUS (GUNS)		(1 - 5)
			dropdown107	=	SandboxVars.A26.EnumSURRollAMMO,				-- ROLLS SURPLUS (AMMO)		(1 - 5)
			dropdown108	=	SandboxVars.A26.EnumSURRollPART,				-- ROLLS SURPLUS (PARTS)	(1 - 5)
			dropdown109	=	SandboxVars.A26.EnumSURRollARMOR,				-- ROLLS SURPLUS (ARMOR)	(1 - 5)
			dropdown110	=	SandboxVars.A26.EnumHNTRollGUN,					-- ROLLS HUNTING (GUNS)		(1 - 5)
			dropdown111	=	SandboxVars.A26.EnumHNTRollAMMO,				-- ROLLS HUNTING (AMMO)		(1 - 5)
			dropdown112	=	SandboxVars.A26.EnumHNTRollPART,				-- ROLLS HUNTING (PARTS)	(1 - 5)
			dropdown113	=	SandboxVars.A26.EnumHNTRollARMOR,				-- ROLLS HUNTING (ARMOR)	(1 - 5)
			dropdown114	=	SandboxVars.A26.EnumCIVx,						-- CIVx						(1 - 21)
			dropdown115	=	SandboxVars.A26.EnumLEOx,						-- LEOx						(1 - 21)
			dropdown116	=	SandboxVars.A26.EnumMILx,						-- MILx						(1 - 31)
			dropdown117	=	SandboxVars.A26.EnumSECx,						-- SECx						(1 - 21)
			dropdown118	=	SandboxVars.A26.EnumHNTx,						-- HNTx						(1 - 21)
			dropdown119	=	SandboxVars.A26.EnumSURx,						-- SURx						(1 - 21)
			box120		=	SandboxVars.A26.BoolCIVammo,					-- CIVammo					(true or false)
			box121		=	SandboxVars.A26.BoolLEOammo,					-- LEOammo					(true or false)
			box122		=	SandboxVars.A26.BoolMILammo,					-- MILammo					(true or false)
			box123		=	SandboxVars.A26.BoolSECammo,					-- SECammo					(true or false)
			box124		=	SandboxVars.A26.BoolHNTammo,					-- HNTammo					(true or false)
			box125		=	SandboxVars.A26.BoolSURammo,					-- SURammo					(true or false)
			dropdown126	=	SandboxVars.A26.EnumMILRegion,					-- MIL REGION 				(1 to 10)
			dropdown127	=	SandboxVars.A26.EnumZombieCCW,					-- ZOMBIE CCW 				(1 to 21)
			dropdown128	=	SandboxVars.A26.EnumVLR,						-- MIL VLR 					(1 to 11)
			dropdown129	=	SandboxVars.A26.EnumPowerTool,					-- POWER TOOLS 				(1 to 11)	
			dropdown130	=	SandboxVars.A26.EnumReloadingItems,				-- RELOADING ITEMS			(1 to 11)
			box131		=	SandboxVars.A26.BoolAutoThrown,					-- AUTO THROWN				(true or false)
			dropdown132	=	SandboxVars.A26.EnumAutoMagType,				-- AUTO MAGTYPE				(1 to 3)
			dropdown133	=	SandboxVars.A26.EnumNVControl,					-- NV CONTROL 				(1 to 3)
			dropdown134	=	SandboxVars.A26.EnumEmergencyReload,			-- EMERGERNCY LOAD			(1 to 4)
			dropdown135	=	SandboxVars.A26.EnumArrowBreak,					-- ARROW BREAK				(1 to 10)
			box136		=	SandboxVars.A26.BoolVisualEffects,				-- VISUAL EFFECTS			(true or false)
			dropdown137	=	SandboxVars.A26.EnumTorchBurnTime,				-- TORCH BURN TIME			(1 to 10)
			dropdown138	=	SandboxVars.A26.EnumTorchIgniteTarget,			-- TORCH IGNITE TARGET		(1 to 11)
			box139		=	SandboxVars.A26.BoolLightSaberReal,				-- LIGHTSABER REAL			(true or false)
			box140		=	SandboxVars.A26.BoolZombieBodyParts,			-- ZOMBIE BODY PARTS		(true or false)
			dropdown141	=	SandboxVars.A26.EnumArcheryDamage,				-- ARCHERY DAMAGE			(1 to 16)
			box142		=	SandboxVars.A26.BoolSkipRemovals,				-- SKIP REMOVALS			(true or false)
			dropdown143	=	SandboxVars.A26.EnumFixedWeaponOffset,			-- FIXED WEAPON OFFSET		(1 to 11)
			dropdown144	=	SandboxVars.A26.EnumAutoToggleLaser,			-- AUTO TOGGLE LASER		(1 to 4)
			dropdown145	=	SandboxVars.A26.EnumLightRunTime,				-- LIGHT RUNTIME			(1 to 10)
			dropdown146	=	SandboxVars.A26.EnumHeavyWeaponMovement,		-- HVY WEAPON MOVE PENALTY	(1 to 5)
			dropdown147	=	SandboxVars.A26.EnumFirearmDamage,				-- FIREARM DAMAGE			(1 to 16)
			dropdown148	=	SandboxVars.A26.EnumMeleeDamage,				-- MELEE DAMAGE			(1 to 16)
		},

		names = {						
		box0	 = "[RESERVED]",
		dropdown17	 = "Debug Message Level - DEBUG",				
		box142	 = "Skip Removals Lua - DEBUG",				
							
		box1	 = "Hit Damage - DISPLAY",				
		box2	 = "Range/Hit% - DISPLAY",				
		dropdown3	 = "Weapon Info - DISPLAY",				
		box4	 = "Ammunition Count - DISPLAY",				
		box5	 = "Movement Gauge - DISPLAY",				
							
		box6	 = "Dynamic Recoil System - PENALTY",				
		dropdown7	 = "Dynamic Range System - PENALTY",				
		box8	 = "Reset Sight Picture - PENALTY",				
		box16	 = "Vehicle / Gun Length - PENALTY",				
		box140	 = "Hit All Zombie Bodyparts - PENALTY",				
		dropdown146	 = "Heavy Weapon Movement - PENALTY",
							
		dropdown9	 = "Firearm Jam Frequency - FUNCTION",				
		box10	 = "Firearms Never Break - FUNCTION",				
		dropdown11	 = "Attachment Break on Melee - FUNCTION",				
		dropdown12	 = "Attachment Break on Fire - FUNCTION",				
		dropdown135	 = "Arrow/Bolt Break on Hit - FUNCTION",				
		dropdown141	 = "Arrow/Bolt Damage Multiplier - FUNCTION",				
		dropdown147	 = "Firearm Damage Multiplier - FUNCTION",				
		dropdown148	 = "Melee Damage Multiplier - FUNCTION",				
		dropdown15	 = "Launcher Range Multiplier - FUNCTION",				
		dropdown143	 = "Fixed Weapon Rotation Offset - FUNCTION",				
		dropdown145	 = "Weapon Light RunTime Multiplier - FUNCTION",				
		dropdown137	 = "Torch Burn-Time Multiplier - FUNCTION",				
		dropdown138	 = "Torch Set-Fire Multiplier - FUNCTION",				
	--	box139	 = "OPTION REMOVED",				
							
		box131	 = "Auto Equip Thrown Weapon - ACTION",				
		dropdown132	 = "Auto Select Magazine Type - ACTION",				
		dropdown133	 = "Auto Activate Night Vision - ACTION",				
		dropdown144	 = "Auto Activate Laser Sight - ACTION",				
		dropdown134	 = "Emergency Reload - ACTION",				
		dropdown19	 = "Eject Spent Shells - ACTION",				
		box136	 = "Firearm Visual Effects - ACTION",				
							
		dropdown13	 = "Suppression Level - SOUND",				
		dropdown14	 = "Base Sound Level - SOUND",				
		box18	 = "Use Vanilla - SOUND",				
							
		dropdown20	 = "(Bow / X-Bow / Sling-Shot) - TYPE",				
		dropdown21	 = "(Flame Thrower) - TYPE",				
		dropdown22	 = "(Grenade / Mine / Rocket) - TYPE",				
		dropdown23	 = "(Heavy Machine / Mini-Gun) - TYPE",				
		dropdown24	 = "(Light Machinegun) - TYPE",				
		dropdown25	 = "(Semi-Automatic) - TYPE",				
		dropdown26	 = "(Rifle Caliber Automatic) - TYPE",				
		dropdown27	 = "(Pistol Caliber Automatic) - TYPE",				
		dropdown28	 = "(Lever- Action) - TYPE",				
		dropdown29	 = "(Revolver) - TYPE",				
		dropdown30	 = "(Pump-Action) - TYPE",				
		dropdown31	 = "(Bolt-Action) - TYPE",				
		dropdown32	 = "(Break-Barrel / Single-Shot) - TYPE",				
							
		dropdown33	 = "(UNITED STATES) - ORIGIN",				
		dropdown34	 = "(SOVIET UNION) - ORIGIN",				
		dropdown35	 = "(REPUBLIC OF KOREA) - ORIGIN",				
		dropdown36	 = "(PACIFIC RIM) - ORIGIN",				
		dropdown37	 = "(CZECH REPUBLIC) - ORIGIN",				
		dropdown38	 = "(EUROPE) - ORIGIN",				
		dropdown39	 = "(ISRAEL) - ORIGIN",				
		dropdown40	 = "(REST OF WORLD) - ORIGIN",				
							
		dropdown41	 = "(.50 BMG/MAG) - CALIBER",				
		dropdown42	 = "(4g SHOT) - CALIBER",				
		dropdown43	 = "(10g SHOT) - CALIBER",				
		dropdown44	 = "(12g SHOT) - CALIBER",				
		dropdown45	 = "(20g SHOT) - CALIBER",				
		dropdown46	 = "(.30-06 SPG) - CALIBER",				
		dropdown47	 = "(.308 Win) - CALIBER",				
		dropdown48	 = "(7.62x54mm R) - CALIBER",				
		dropdown49	 = "(5.45x39mm) - CALIBER",				
		dropdown50	 = "(7.62x39mm) - CALIBER",				
		dropdown51	 = "(5.56x45mm) - CALIBER",				
		dropdown52	 = "(.223 REM) - CALIBER",				
		dropdown53	 = "(.45 COLT / .410g) - CALIBER",				
		dropdown54	 = "(.45-70 GOV) - CALIBER",				
		dropdown55	 = "(.44 MAG) - CALIBER",				
		dropdown56	 = "(.45 ACP) - CALIBER",				
		dropdown57	 = "(.38  Spc /.357 MAG) - CALIBER",				
		dropdown58	 = "(9x19mm LUG) - CALIBER",				
		dropdown59	 = "(5.7x28mm) - CALIBER",				
		dropdown60	 = "(.380 ACP) - CALIBER",				
		dropdown61	 = "(.22 LR) - CALIBER",				
		dropdown62	 = "(.177 BB / .68 PB) - CALIBER",				
							
		dropdown64	 = "(Suppressors) - PARTS",				
		dropdown65	 = "(Optics & Scopes) - PARTS",				
		dropdown66	 = "(Lights & Lasers) - PARTS",				
		dropdown67	 = "(ALL Other Parts) - PARTS",				
							
		dropdown68	 = "(Canister) - AMMUNITION",				
		dropdown69	 = "(Box) - AMMUNITION",				
		dropdown73	 = "(Poly Canister) - MAGAZINE",				
		dropdown70	 = "(Standard) - MAGAZINE",				
		dropdown71	 = "(Extended) - MAGAZINE",				
		dropdown72	 = "(Drum) - MAGAZINE",				
							
		dropdown74	 = "Knife (Small) - MELEE",				
		dropdown75	 = "Knife (Large) - MELEE",				
		dropdown76	 = "Sword - MELEE",				
		dropdown77	 = "Axe - MELEE",				
		dropdown78	 = "Blunt - MELEE",				
		dropdown79	 = "Spear - MELEE",				
		dropdown129	 = "Power Tool - MELEE",				
							
		dropdown80	 = "Armor (FWP / USMC Distro Override - LOOT)",				
		dropdown130	 = "Reloading (Equip / Components) - LOOT",				
		dropdown81	 = "Weapons Produced after 1992 - LOOT",				
		dropdown126	 = "Military Region - LOOT",				
		dropdown128	 = "Military / Police Vehicle - LOOT",				
		dropdown63	 = "Random Gun-Case - LOOT",				
		dropdown127	 = "Zombie CCW - LOOT",				
							
		dropdown82	 = "Police   items in CIV locations - EXCLUSION",				
		dropdown83	 = "Military items in CIV locaions - EXCLUSION",				
		dropdown84	 = "Civilian items in LEO locations - EXCLUSION",				
		dropdown85	 = "Military items in LEO locations - EXCLUSION",				
		dropdown86	 = "NON-Military items in MIL locations - EXCLUSION",				
		dropdown87	 = "NON-Security items in SEC locations - EXCLUSION",				
		dropdown88	 = "NON-Hunting items in HNT locations - EXCLUSION",				
		dropdown89	 = "NON-Surplus items in SUR locations - EXCLUSION",				
							
		dropdown90	 = "GUN-STORE Roll (GUNS)",				
		dropdown91	 = "(AMMO)",				
		dropdown92	 = "(PARTS)",				
		dropdown93	 = "(ARMOR)",				
		dropdown94	 = "POLICE Roll (GUNS / PARTS / MAGS / AMMO)",				
		dropdown95	 = "(AMMO / MAGS)",				
		dropdown96	 = "(NOT USED)",				
		dropdown97	 = "(ARMOR)",				
		dropdown98	 = "MILITARY Roll (GUNS / PARTS / MAGS / AMMO)",				
		dropdown99	 = "(AMMO / MAGS)",				
		dropdown100	 = "(NOT USED)",				
		dropdown101	 = "(ARMOR)",				
		dropdown102	 = "SECURITY Roll (GUNS / PARTS / MAGS / AMMO)",				
		dropdown103	 = "(AMMO / MAGS)",				
		dropdown104	 = "(NOT USED)",				
		dropdown105	 = "(ARMOR)",				
		dropdown106	 = "SURPLUS Roll (GUNS)",				
		dropdown107	 = "(AMMO)",				
		dropdown108	 = "(PARTS)",				
		dropdown109	 = "(ARMOR)",				
		dropdown110	 = "HUNTING Roll (GUNS)",				
		dropdown111	 = "(AMMO)",				
		dropdown112	 = "(PARTS)",				
		dropdown113	 = "(ARMOR)",				
							
		dropdown114	 = "CIV Trim (+) Increase",				
		dropdown115	 = "LEO Trim (+) Increase",				
		dropdown116	 = "MIL Trim (+) Increase",				
		dropdown117	 = "SEC Trim (+) Increase",				
		dropdown118	 = "HNT Trim (+) Increase",				
		dropdown119	 = "SUR Trim (+) Increase",				
							
		box120	 = "CIV Spawn Associated Ammo",				
		box121	 = "LEO Spawn Associated Ammo",				
		box122	 = "MIL Spawn Associated Ammo",				
		box123	 = "SEC Spawn Associated Ammo",				
		box124	 = "HNT Spawn Associated Ammo",				
		box125	 = "SUR Spawn Associated Ammo",				
		},						
		mod_id = "FWP",						
		mod_shortname= "FWP Gunfighter Options",						
	}
	GUNFIGHTER = {}
	GUNFIGHTER.OPTIONS = SETTINGS
	
	local OPTIONS = GUNFIGHTER.OPTIONS
	
	print("*******************************************")
	print("** SANDBOXVARS TRANSFERED TO MOD OPTIONS **")
	print("*******************************************")
	print("Show Hit Damage = ",	GUNFIGHTER.OPTIONS.options.box1)
	print("Show Range/Hit% = ",	GUNFIGHTER.OPTIONS.options.box2)
	print("Show Weapon Info = ",	GUNFIGHTER.OPTIONS.options.dropdown3)
	print("Show Ammunition = ",	GUNFIGHTER.OPTIONS.options.box4)
	print("Movement Gauge = ",	GUNFIGHTER.OPTIONS.options.box5)
	print("Dynamic Recoil System = ",	GUNFIGHTER.OPTIONS.options.box6)
	print("Dynamic Range System = ",	GUNFIGHTER.OPTIONS.options.dropdown7)
	print("Reset Sight Picture = ",	GUNFIGHTER.OPTIONS.options.box8)
	print("Firearm Jamm = ",	GUNFIGHTER.OPTIONS.options.dropdown9)
	print("Firearms never Break = ",	GUNFIGHTER.OPTIONS.options.box10)
	print("Attachements break on melee = ",	GUNFIGHTER.OPTIONS.options.dropdown11)
	print("attachements break on fire = ",	GUNFIGHTER.OPTIONS.options.dropdown12)
	print("Supression Level = ",	GUNFIGHTER.OPTIONS.options.dropdown13)
	print("Bass sound Level = ",	GUNFIGHTER.OPTIONS.options.dropdown14)
	print("Luncher range multiplier = ",	GUNFIGHTER.OPTIONS.options.dropdown15)
	print("Vehicule penalty = ",	GUNFIGHTER.OPTIONS.options.box16)
	print("Debug Confirmation level = ",	GUNFIGHTER.OPTIONS.options.dropdown17)
	print("Use vanilla shot sound = ",	GUNFIGHTER.OPTIONS.options.box18)
	print("Eject Spend shells  = ",	GUNFIGHTER.OPTIONS.options.dropdown19)
	print("Type (Bow / Crossbow) = ",	GUNFIGHTER.OPTIONS.options.dropdown20)
	print("Type (Flame Thrower) = ",	GUNFIGHTER.OPTIONS.options.dropdown21)
	print("dropdown22 = ",	GUNFIGHTER.OPTIONS.options.dropdown22)
	print("dropdown23 = ",	GUNFIGHTER.OPTIONS.options.dropdown23)
	print("dropdown24 = ",	GUNFIGHTER.OPTIONS.options.dropdown24)
	print("dropdown25 = ",	GUNFIGHTER.OPTIONS.options.dropdown25)
	print("dropdown26 = ",	GUNFIGHTER.OPTIONS.options.dropdown26)
	print("dropdown27 = ",	GUNFIGHTER.OPTIONS.options.dropdown27)
	print("dropdown28 = ",	GUNFIGHTER.OPTIONS.options.dropdown28)
	print("dropdown29 = ",	GUNFIGHTER.OPTIONS.options.dropdown29)
	print("dropdown30 = ",	GUNFIGHTER.OPTIONS.options.dropdown30)
	print("dropdown31 = ",	GUNFIGHTER.OPTIONS.options.dropdown31)
	print("dropdown32 = ",	GUNFIGHTER.OPTIONS.options.dropdown32)
	print("dropdown33 = ",	GUNFIGHTER.OPTIONS.options.dropdown33)
	print("dropdown34 = ",	GUNFIGHTER.OPTIONS.options.dropdown34)
	print("dropdown35 = ",	GUNFIGHTER.OPTIONS.options.dropdown35)
	print("dropdown36 = ",	GUNFIGHTER.OPTIONS.options.dropdown36)
	print("dropdown37 = ",	GUNFIGHTER.OPTIONS.options.dropdown37)
	print("dropdown38 = ",	GUNFIGHTER.OPTIONS.options.dropdown38)
	print("dropdown39 = ",	GUNFIGHTER.OPTIONS.options.dropdown39)
	print("dropdown40 = ",	GUNFIGHTER.OPTIONS.options.dropdown40)
	print("dropdown41 = ",	GUNFIGHTER.OPTIONS.options.dropdown41)
	print("dropdown42 = ",	GUNFIGHTER.OPTIONS.options.dropdown42)
	print("dropdown43 = ",	GUNFIGHTER.OPTIONS.options.dropdown43)
	print("dropdown44 = ",	GUNFIGHTER.OPTIONS.options.dropdown44)
	print("dropdown45 = ",	GUNFIGHTER.OPTIONS.options.dropdown45)
	print("dropdown46 = ",	GUNFIGHTER.OPTIONS.options.dropdown46)
	print("dropdown47 = ",	GUNFIGHTER.OPTIONS.options.dropdown47)
	print("dropdown48 = ",	GUNFIGHTER.OPTIONS.options.dropdown48)
	print("dropdown49 = ",	GUNFIGHTER.OPTIONS.options.dropdown49)
	print("dropdown50 = ",	GUNFIGHTER.OPTIONS.options.dropdown50)
	print("dropdown51 = ",	GUNFIGHTER.OPTIONS.options.dropdown51)
	print("dropdown52 = ",	GUNFIGHTER.OPTIONS.options.dropdown52)
	print("dropdown53 = ",	GUNFIGHTER.OPTIONS.options.dropdown53)
	print("dropdown54 = ",	GUNFIGHTER.OPTIONS.options.dropdown54)
	print("dropdown55 = ",	GUNFIGHTER.OPTIONS.options.dropdown55)
	print("dropdown56 = ",	GUNFIGHTER.OPTIONS.options.dropdown56)
	print("dropdown57 = ",	GUNFIGHTER.OPTIONS.options.dropdown57)
	print("dropdown58 = ",	GUNFIGHTER.OPTIONS.options.dropdown58)
	print("dropdown59 = ",	GUNFIGHTER.OPTIONS.options.dropdown59)
	print("dropdown60 = ",	GUNFIGHTER.OPTIONS.options.dropdown60)
	print("dropdown61 = ",	GUNFIGHTER.OPTIONS.options.dropdown61)
	print("dropdown62 = ",	GUNFIGHTER.OPTIONS.options.dropdown62)
	print("dropdown63 = ",	GUNFIGHTER.OPTIONS.options.dropdown63)
	print("dropdown64 = ",	GUNFIGHTER.OPTIONS.options.dropdown64)
	print("dropdown65 = ",	GUNFIGHTER.OPTIONS.options.dropdown65)
	print("dropdown66 = ",	GUNFIGHTER.OPTIONS.options.dropdown66)
	print("dropdown67 = ",	GUNFIGHTER.OPTIONS.options.dropdown67)
	print("dropdown68 = ",	GUNFIGHTER.OPTIONS.options.dropdown68)
	print("dropdown69 = ",	GUNFIGHTER.OPTIONS.options.dropdown69)
	print("dropdown70 = ",	GUNFIGHTER.OPTIONS.options.dropdown70)
	print("dropdown71 = ",	GUNFIGHTER.OPTIONS.options.dropdown71)
	print("dropdown72 = ",	GUNFIGHTER.OPTIONS.options.dropdown72)
	print("dropdown73 = ",	GUNFIGHTER.OPTIONS.options.dropdown73)
	print("dropdown74 = ",	GUNFIGHTER.OPTIONS.options.dropdown74)
	print("dropdown75 = ",	GUNFIGHTER.OPTIONS.options.dropdown75)
	print("dropdown76 = ",	GUNFIGHTER.OPTIONS.options.dropdown74)
	print("dropdown77 = ",	GUNFIGHTER.OPTIONS.options.dropdown76)
	print("dropdown78 = ",	GUNFIGHTER.OPTIONS.options.dropdown78)
	print("dropdown79 = ",	GUNFIGHTER.OPTIONS.options.dropdown79)
	print("dropdown80 = ",	GUNFIGHTER.OPTIONS.options.dropdown80)
	print("dropdown81 = ",	GUNFIGHTER.OPTIONS.options.dropdown81)
	print("dropdown82 = ",	GUNFIGHTER.OPTIONS.options.dropdown82)
	print("dropdown83 = ",	GUNFIGHTER.OPTIONS.options.dropdown83)
	print("dropdown84 = ",	GUNFIGHTER.OPTIONS.options.dropdown84)
	print("dropdown85 = ",	GUNFIGHTER.OPTIONS.options.dropdown85)
	print("dropdown86 = ",	GUNFIGHTER.OPTIONS.options.dropdown86)
	print("dropdown87 = ",	GUNFIGHTER.OPTIONS.options.dropdown87)
	print("dropdown88 = ",	GUNFIGHTER.OPTIONS.options.dropdown88)
	print("dropdown89 = ",	GUNFIGHTER.OPTIONS.options.dropdown89)
	print("dropdown90 = ",	GUNFIGHTER.OPTIONS.options.dropdown90)
	print("dropdown91 = ",	GUNFIGHTER.OPTIONS.options.dropdown91)
	print("dropdown92 = ",	GUNFIGHTER.OPTIONS.options.dropdown92)
	print("dropdown93 = ",	GUNFIGHTER.OPTIONS.options.dropdown93)
	print("dropdown94 = ",	GUNFIGHTER.OPTIONS.options.dropdown94)
	print("dropdown95 = ",	GUNFIGHTER.OPTIONS.options.dropdown95)
	print("dropdown96 = ",	GUNFIGHTER.OPTIONS.options.dropdown96)
	print("dropdown97 = ",	GUNFIGHTER.OPTIONS.options.dropdown97)
	print("dropdown98 = ",	GUNFIGHTER.OPTIONS.options.dropdown98)
	print("dropdown99 = ",	GUNFIGHTER.OPTIONS.options.dropdown99)
	print("dropdown100 = ",	GUNFIGHTER.OPTIONS.options.dropdown100)
	print("dropdown101 = ",	GUNFIGHTER.OPTIONS.options.dropdown101)
	print("dropdown102 = ",	GUNFIGHTER.OPTIONS.options.dropdown102)
	print("dropdown103 = ",	GUNFIGHTER.OPTIONS.options.dropdown103)
	print("dropdown104 = ",	GUNFIGHTER.OPTIONS.options.dropdown104)
	print("dropdown105 = ",	GUNFIGHTER.OPTIONS.options.dropdown105)
	print("dropdown106 = ",	GUNFIGHTER.OPTIONS.options.dropdown106)
	print("dropdown107 = ",	GUNFIGHTER.OPTIONS.options.dropdown107)
	print("dropdown108 = ",	GUNFIGHTER.OPTIONS.options.dropdown108)
	print("dropdown109 = ",	GUNFIGHTER.OPTIONS.options.dropdown109)
	print("dropdown110 = ",	GUNFIGHTER.OPTIONS.options.dropdown110)
	print("dropdown111 = ",	GUNFIGHTER.OPTIONS.options.dropdown111)
	print("dropdown112 = ",	GUNFIGHTER.OPTIONS.options.dropdown112)
	print("dropdown113 = ",	GUNFIGHTER.OPTIONS.options.dropdown113)
	print("dropdown114 = ",	GUNFIGHTER.OPTIONS.options.dropdown114)
	print("dropdown115 = ",	GUNFIGHTER.OPTIONS.options.dropdown115)
	print("dropdown116 = ",	GUNFIGHTER.OPTIONS.options.dropdown116)
	print("dropdown117 = ",	GUNFIGHTER.OPTIONS.options.dropdown117)
	print("dropdown118 = ",	GUNFIGHTER.OPTIONS.options.dropdown118)
	print("dropdown119 = ",	GUNFIGHTER.OPTIONS.options.dropdown119)
	print("checkbox120 = ",	GUNFIGHTER.OPTIONS.options.box120)
	print("checkbox121 = ",	GUNFIGHTER.OPTIONS.options.box121)
	print("checkbox122 = ",	GUNFIGHTER.OPTIONS.options.box122)
	print("checkbox123 = ",	GUNFIGHTER.OPTIONS.options.box123)
	print("checkbox124 = ",	GUNFIGHTER.OPTIONS.options.box124)
	print("checkbox125 = ",	GUNFIGHTER.OPTIONS.options.box125)
	print("dropdown126 = ",	GUNFIGHTER.OPTIONS.options.dropdown126)
	print("ZOMBIE CCW LOOT = ",		GUNFIGHTER.OPTIONS.options.dropdown127)
	print("VEHICLE LOOT = ",		GUNFIGHTER.OPTIONS.options.dropdown128)
	print("POWERTOOLS = ",			GUNFIGHTER.OPTIONS.options.dropdown129)
	print("RELOADING ITEMS = ",		GUNFIGHTER.OPTIONS.options.dropdown130)	
	print("AUTO EQUIP THROWN = ",	GUNFIGHTER.OPTIONS.options.box131)
	print("AUTO SELECT MAG = ",		GUNFIGHTER.OPTIONS.options.dropdown132)
	print("AUTO ACTIVATE NV = ",	GUNFIGHTER.OPTIONS.options.dropdown133)
	print("EMERGENCY RELOAD = ",	GUNFIGHTER.OPTIONS.options.dropdown134)
	print("ARROW BREAKAGE = ",		GUNFIGHTER.OPTIONS.options.dropdown135)
	print("VISUAL EFFECTS = ",		GUNFIGHTER.OPTIONS.options.box136)
	print("BURN TIME = ",			GUNFIGHTER.OPTIONS.options.dropdown137)
	print("IGNITE TARGET = ",		GUNFIGHTER.OPTIONS.options.dropdown138)
	print("HIT ALL BODY PARTS = ",	GUNFIGHTER.OPTIONS.options.box140)
	print("ARCHERY DAMAGE = ",		GUNFIGHTER.OPTIONS.options.dropdown141)
	print("SKIP REMOVALS = ",		GUNFIGHTER.OPTIONS.options.box142)
	print("FIXED ROTATION = ",		GUNFIGHTER.OPTIONS.options.dropdown143)
	print("AUTO ACTIVATE LASER = ",	GUNFIGHTER.OPTIONS.options.dropdown144)
	print("WEAPONLIGHT RUNTIME = ",	GUNFIGHTER.OPTIONS.options.dropdown145)
	print("HVY WEAPON MOVEMENT = ",	GUNFIGHTER.OPTIONS.options.dropdown146)
	print("FIREARM DAMAGE = ",		GUNFIGHTER.OPTIONS.options.dropdown147)
	print("MELEE DAMAGE = ",		GUNFIGHTER.OPTIONS.options.dropdown148)
end

		----------------------------------
		--	MULTI-PLAYER MODE			--
		--	LOCAL HOST = CLIENT	TRUE	--
		--	DEDICATED = SERVER TRUE		--
		--	SINGLE-PLAYER BOTH false	--
		----------------------------------
if		isServer() or isClient() then
		print("MULTI-PLAYER ADD OPTIONS ON EVENT")
		Events.OnGameStart.Add(initGunFighterSandboxOptions)
		Events.OnServerStartSaving.Add(initGunFighterSandboxOptions)
		Events.OnPreDistributionMerge.Add(initGunFighterSandboxOptions)
		Events.OnDistributionMerge.Add(initGunFighterSandboxOptions)
		Events.OnPostDistributionMerge.Add(initGunFighterSandboxOptions)
		Events.OnServerFinishSaving.Add(initGunFighterSandboxOptions)
--		Events.OnInitWorld.Add(initGunFighterSandboxOptions)
--		Events.OnLoadMapZones.Add(initGunFighterSandboxOptions)
--		Events.OnPostMapLoad.Add(initGunFighterSandboxOptions)
--		Events.OnPreMapLoad.Add(initGunFighterSandboxOptions)
--		Events.OnLoad.Add(initGunFighterSandboxOptions)
--		Events.OnSpawnRegionsLoaded.Add(initGunFighterSandboxOptions)
--		Events.OnLoadedTileDefinitions.Add(initGunFighterSandboxOptions)
--		Events.onLoadModDataFromServer.Add(initGunFighterSandboxOptions)
-- 		Events.OnNewGame.Add(initGunFighterSandboxOptions)
else	print("SINGLE-PLAYER... USING SANDBOX OPTIONS")
		initGunFighterSandboxOptions()
end






