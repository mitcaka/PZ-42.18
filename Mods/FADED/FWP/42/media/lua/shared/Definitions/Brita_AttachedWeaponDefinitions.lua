-- define weapons to be attached to zombies when creating them
-- random knives inside their neck, spear in their stomach, meatcleaver in their back...
-- this is used in IsoZombie.addRandomAttachedWeapon()

require "Definitions/AttachedWeaponDefinitions"


--------------------------------------------
--	DEFINE NEW ATTACHMENT DEFINITIONS	--
--	EMPTY LISTS OPTION CONTROLLED FROM	--
--	DISTRO FILE					--
--------------------------------------------
AttachedWeaponDefinitions.A26_handgunHolster = {
	id = "A26_handgunHolster",
	chance = 200,		-- 40
	outfit = {"Brita_Police", "Brita_Police_2", "Brita_Police_3", "Brita_Sheriff", "Brita_Sheriff_2", "Brita_Sheriff_3", "Brita_Crewman", "Brita_Crewman_2", "Brita_Ela", "Brita_Ashe", "A26_Police", "A26_Police_Vest", "A26_Police_Riot", "Police", "PoliceState", "PoliceRiot", "PrisonGuard", "PrivateMilitia"},
	weaponLocation =  {"Holster Right"},
	bloodLocations = nil,
	addHoles = false,
	daySurvived = 0,
	ensureItem = "Base.HolsterSimple",
	weapons = {
	},
}

AttachedWeaponDefinitions.A26_shotgunPolice = {
	id = "A26_shotgunPolice",
	chance = 200,		-- 20
	outfit = {"Brita_Police", "Brita_Police_2", "Brita_Police_3", "Brita_Sheriff", "Brita_Sheriff_2", "Brita_Sheriff_3", "A26_Police", "A26_Police_Vest", "A26_Police_Riot", "Police", "PoliceState", "PoliceRiot", "PrivateMilitia", "AuthenticSurvivorHazardSuit", "AuthenticSurvivorPolice", "AuthenticSurvivorRanger", "AuthenticDawnoftheDead", "AuthenticFrancis", "AuthenticEllis", "AuthenticCoach", "AuthenticNateAnderson", "AuthenticTheyLive", "AuthenticLeonKennedy"},
	weaponLocation =  {"Rifle On Back"},
	bloodLocations = nil,
	addHoles = false,
	daySurvived = 0,
	weapons = {
	},
}

AttachedWeaponDefinitions.A26_nightstick = {
	chance = 200,		-- 40
	outfit = {"Brita_Police", "Brita_Police_2", "Brita_Police_3", "Brita_Sheriff", "Brita_Sheriff_2", "Brita_Sheriff_3", "Brita_Prison_Unit", "Brita_Prison_Unit_2", "A26_Police", "A26_Police_Vest", "A26_Police_Riot", "Police", "PoliceState", "PoliceRiot", "PrisonGuard", "PrivateMilitia"},
	weaponLocation = {"Nightstick Left"},
	bloodLocations = nil,
	addHoles = false,
	daySurvived = 0,
	weapons = {
	},
}

-- assault rifle on back
AttachedWeaponDefinitions.A26_assaultRifleOnBack = {
	id = "A26_assaultRifleOnBack",
	chance = 200,		-- 30
	outfit = {"A26_Army_Green_Vest", "A26_Army_Green_Full", "Brita_ARMY", "Brita_ARMY_2", "Brita_ARMY_3", "Brita_ARMY_4", "Brita_USMC", "Brita_Gorka", "Brita_Gorka_2", "Brita_SPECOPS", "Brita_SPECOPS_2", "Brita_Wolf", "Brita_Wolf_2", "Brita_Dozer", "Brita_Bulldozer", "Brita_EOD", "PrivateMilitia","AuthenticSurvivorHazardSuit"},
	weaponLocation =  {"Rifle On Back"},
	bloodLocations = nil,
	addHoles = false,
	daySurvived = 0,
	weapons = {
	},
}

AttachedWeaponDefinitions.A26_huntingRifleOnBack = {
	id = "A26_huntingRifleOnBack",
	chance = 200,		-- 40
	outfit = {"Brita_Sniper", "Brita_Sniper_2", "Brita_Hunter", "Brita_Viper", "PrivateMilitia", "AuthenticSurvivorHazardSuit"},
	weaponLocation =  {"Rifle On Back"},
	bloodLocations = nil,
	addHoles = false,
	daySurvived = 0,
	weapons = {
	},
}



--[[
--------------------------------------------
--	DAYS SURVIVED TO ZERO FOR TESTING	--
--------------------------------------------
-- random knife (better quality) in the back
AttachedWeaponDefinitions.knifeBack = {
	chance = 100,
	weaponLocation = {"Knife in Back"},
	bloodLocations = {"Back"},
	addHoles = false,
	daySurvived = 0,
	weapons = {
		"Base.BreadKnife",
		"Base.KitchenKnife",
	},
}

-- Axe in the back
AttachedWeaponDefinitions.axeBack = {
	chance = 100,
	weaponLocation = {"Axe Back"},
	bloodLocations = {"Back"},
	addHoles = true,
	daySurvived = 0,
	weapons = {
		"Base.Axe",
	},
}

AttachedWeaponDefinitions.knifeLeftLeg = {
	chance = 100,
	weaponLocation = {"Knife Left Leg"},
	bloodLocations = {"UpperLeg_L"},
	addHoles = false,
	daySurvived = 0,
	weapons = {
		"Base.BreadKnife",
		"Base.KitchenKnife",
	},
}
AttachedWeaponDefinitions.knifeRightLeg = {
	chance = 100,
	weaponLocation = {"Knife Right Leg"},
	bloodLocations = {"UpperRight_L"},
	addHoles = false,
	daySurvived = 0,
	weapons = {
		"Base.BreadKnife",
		"Base.KitchenKnife",
	},
}
AttachedWeaponDefinitions.knifeShoulder = {
	chance = 100,
	weaponLocation = {"Knife Shoulder"},
	bloodLocations = {"UpperArm_L", "Torso_Upper"},
	addHoles = false,
	daySurvived = 0,
	weapons = {
		"Base.BreadKnife",
		"Base.KitchenKnife",
	},
}
AttachedWeaponDefinitions.knifeStomach = {
	chance = 100,
	weaponLocation = {"Knife Stomach"},
	bloodLocations = {"Torso_Lower", "Back"},
	addHoles = false,
	daySurvived = 0,
	weapons = {
		"Base.BreadKnife",
		"Base.KitchenKnife",
	},
}

]]



--------------------------------------------
--	REDO ZOMBIE TYPES FOR A26_LISTS	--
--	NEEDED TO CLEAR ATTACHMENT LISTS	--
--	SO OPTIONS CAN POPULATE ACCORDINGLY	--
--------------------------------------------
AttachedWeaponDefinitions.attachedWeaponCustomOutfit.PrivateMilitia = {
	chance = 50;
	maxitem = 3;
	weapons = {
		AttachedWeaponDefinitions.A26_shotgunPolice,
		AttachedWeaponDefinitions.A26_assaultRifleOnBack,
		AttachedWeaponDefinitions.A26_huntingRifleOnBack,
		AttachedWeaponDefinitions.A26_handgunHolster,
		AttachedWeaponDefinitions.knivesBelt,
		AttachedWeaponDefinitions.nightstick,
	},
}

AttachedWeaponDefinitions.attachedWeaponCustomOutfit.Bandit = {
	chance = 50;
	maxitem = 2;
	weapons = {
		AttachedWeaponDefinitions.meleeInBack,
		AttachedWeaponDefinitions.melee2InBack,
		AttachedWeaponDefinitions.hammerBelt,
		AttachedWeaponDefinitions.knivesBelt,
		AttachedWeaponDefinitions.A26_handgunHolster,
		AttachedWeaponDefinitions.bladeInBack,
	},
}

AttachedWeaponDefinitions.attachedWeaponCustomOutfit.Police = {
	chance = 50;
	maxitem = 2;
	weapons = {
		AttachedWeaponDefinitions.A26_handgunHolster,
		AttachedWeaponDefinitions.A26_nightstick,
		AttachedWeaponDefinitions.A26_shotgunPolice,
	},
}

AttachedWeaponDefinitions.attachedWeaponCustomOutfit.PoliceState = {
	chance = 50;
	maxitem = 2;
	weapons = {
		AttachedWeaponDefinitions.A26_handgunHolster,
		AttachedWeaponDefinitions.A26_nightstick,
		AttachedWeaponDefinitions.A26_shotgunPolice,
	},
}

AttachedWeaponDefinitions.attachedWeaponCustomOutfit.PoliceRiot = {
	chance = 50;
	maxitem = 3;
	weapons = {
		AttachedWeaponDefinitions.A26_handgunHolster,
		AttachedWeaponDefinitions.A26_nightstick,
		AttachedWeaponDefinitions.A26_shotgunPolice,
	},
}

AttachedWeaponDefinitions.attachedWeaponCustomOutfit.PrisonGuard = {
	chance = 50;
	maxitem = 1;
	weapons = {
		AttachedWeaponDefinitions.A26_nightstick,
	},
}



--[[		EXAMPLE FOR BRITAS ARMOR PACK
AttachedWeaponDefinitions.attachedWeaponCustomOutfit.Brita_Prison_Unit = {
	chance = 50;
	maxitem = 1;		-- (1) MAY ONLY HAVE BATON
	weapons = {
		AttachedWeaponDefinitions.nightstick,
	},
}

AttachedWeaponDefinitions.attachedWeaponCustomOutfit.Brita_Sheriff = {
	chance = 50;
	maxitem = 3;		-- (3) MAY HAVE SHOTGUN / PISTOL / BATON or KNIFE
	weapons = {
		AttachedWeaponDefinitions.A26_shotgunPolice,	-- ASSAULT STYLE SHOTGUNS (NON-HUNTING)
		AttachedWeaponDefinitions.A26_handgunHolster,
		AttachedWeaponDefinitions.knivesBelt,
		AttachedWeaponDefinitions.nightstick,
	},
}

AttachedWeaponDefinitions.attachedWeaponCustomOutfit.Brita_Army = {
	chance = 50;
	maxitem = 3;		-- (3) MAY HAVE RIFLE / PISTOL / KNIFE
	weapons = {
		AttachedWeaponDefinitions.A26_assaultRifleOnBack,	-- AUTO RIFLES
		AttachedWeaponDefinitions.A26_handgunHolster,
		AttachedWeaponDefinitions.knivesBelt,
	},
}

AttachedWeaponDefinitions.attachedWeaponCustomOutfit.Brita_Sniper = {
	chance = 50;
	maxitem = 2;		-- (3) MAY HAVE HUNTING RIFLE / KNIFE
	weapons = {
		AttachedWeaponDefinitions.A26_huntingRifleOnBack,	-- HUNTING LONG GUNS
		AttachedWeaponDefinitions.knivesBelt,
	},
}
]]


--[[

--------------------------------------------------------------------------
--	NOT USED							--
--------------------------------------------------------------------------
-- table.insert(AttachedWeaponDefinitions["spearStomach"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["meatCleaverBackLowQuality"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["knifeLowQualityBack"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["knifeLowQualityLeftLeg"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["knifeLowQualityLeftLeg"].weapons, "Base.");  DOUBLE INSTANCE IN VANILLA
-- table.insert(AttachedWeaponDefinitions["knifeLowQualityShoulder"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["knifeLowQualityStomach"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["meatCleaverBack"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["weaponInStomach"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["weaponInStomach"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["weaponInStomach"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["weaponInStomach"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["crowbarBack"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["crowbarBack"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["constructionWorker"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["constructionWorkerScrewdriver"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["meleeInBack"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["melee2InBack"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["hammerBelt"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["bladeInBack"].weapons, "Base.");
-- table.insert(AttachedWeaponDefinitions["nightstick"].weapons, "Base.");

]]