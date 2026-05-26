require 'Foraging/forageSystem'

local function hasScriptItem(fullType)
	if not fullType or not getScriptManager then return false end
	local manager = getScriptManager()
	if not manager or not manager.FindItem then return false end
	local item = manager:FindItem(fullType)
	return item ~= nil
end

local function addForageItemDef(def)
	if not forageSystem or not forageSystem.addItemDef or not def or not hasScriptItem(def.type) then
		return false
	end
	-- Build 42.18 can log Java-side errors before Lua pcall can silence them
	-- when imported food scripts fail forage validation. Keep these foods
	-- available to FFC scanning/recipes, but do not register broken forage defs.
	return false
end

Events.onAddForageDefs.Add(function()

	local worldSprites = {
		smallTrees = {
			{ "media/textures/Foraging/worldSprites/smallTree_worldSprite.png" },
			{ "media/textures/Foraging/worldSprites/smallTree2_worldSprite.png" },
		},
		berryBushes = {
			{ "f_bushes_1_4", "f_bushes_1_68", "f_bushes_1_84" },
			{ "f_bushes_1_4", "f_bushes_1_68", "f_bushes_1_88" },
		}
	}

	local BlackCherry = {
		type = "MattSimpleAddons.MSABlack_Cherry",
		skill = 3,
		maxCount = 15,
		minCount = 5,
		xp = 15,
		snowChance = -10,
		categories = { "Fruits", "ForestGoods" },
		zones = {
			Forest      = 15,
			DeepForest  = 15,
			FarmLand    = 5,
			Farm        = 5,
		},
		months = { 5, 6, 7, 8, 9 },
		bonusMonths = { 6, 7, 8 },
		malusMonths = { 5, 9 },
		spawnFuncs = { doWildFoodSpawn },
		altWorldTexture = worldSprites.smallTrees,
		itemSizeModifier = 1.5,
	};

	local American_Plum = {
		type = "MattSimpleAddons.MSAmerican_Plumb",
		skill = 3,
		maxCount = 5,
		minCount = 1,
		xp = 15,
		snowChance = -10,
		categories = { "Fruits", "ForestGoods" },
		zones = {
			Forest      = 25,
			DeepForest  = 15,
			FarmLand    = 5,
			Farm        = 5,
		},
		months = { 5, 6, 7, 8, 9 },
		bonusMonths = { 6, 7, 8 },
		malusMonths = { 5, 9 },
		spawnFuncs = { doWildFoodSpawn },
		altWorldTexture = worldSprites.smallTrees,
		itemSizeModifier = 1.5,
	};


	local Rasberries = {
		type = "MattSimpleAddons.MSARaspberries",
		skill = 4,
		xp = 15,
		snowChance = -10,
		minCount = 6,
		maxCount = 30,
		categories = { "Berries" },
		zones = {
			Forest      = 15,
			DeepForest  = 25,
			FarmLand    = 5,
			Farm        = 5,
		},
		months = {  3, 4, 5, 6, 7, 8, 9, 10, 11 },
		bonusMonths = {  6, 7, 8, 9 },
		malusMonths = { 3,10, 11 },
		spawnFuncs = { doWildFoodSpawn, doWildCropSpawn },
		altWorldTexture = worldSprites.berryBushes,
		itemSizeModifier = 1.0,
	};

	local Blackberries = {
		type = "MattSimpleAddons.MSABlackBerries",
		skill = 6,
		xp = 15,
		snowChance = -10,
		minCount = 9,
		maxCount = 40,
		categories = { "Berries" },
		zones = {
			Forest      = 15,
			DeepForest  = 25,
			FarmLand    = 5,
			Farm        = 5,
		},
		months = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 },
		bonusMonths = { 4, 5, 6 },
		malusMonths = { 1, 2, 10, 11 },
		spawnFuncs = { doWildFoodSpawn },
		altWorldTexture = worldSprites.berryBushes,
		itemSizeModifier = 1.0,
	};

	local Mulberry = {

		type = "MattSimpleAddons.MSAMulberry",
		skill = 3,
		maxCount = 20,
		minCount = 5,
		xp = 15,
		snowChance = -10,
		categories = { "Fruits", "ForestGoods" },
		zones = {
			Forest      = 25,
			DeepForest  = 25,
			FarmLand    = 5,
			Farm        = 5,
		},
		months = { 5, 6, 7, 8, 9, 10, 11 },
		bonusMonths = {  8, 9, 10 },
		malusMonths = { 5, 6, 11 },
		spawnFuncs = { doWildFoodSpawn },
		altWorldTexture = worldSprites.smallTrees,
		itemSizeModifier = 1.5,
	};

local added = 0
if addForageItemDef(BlackCherry) then added = added + 1 end
if addForageItemDef(American_Plum) then added = added + 1 end
if addForageItemDef(Rasberries) then added = added + 1 end
if addForageItemDef(Blackberries) then added = added + 1 end
if addForageItemDef(Mulberry) then added = added + 1 end

if added > 0 and forageSystem and forageSystem.generateLootTable then
	pcall(forageSystem.generateLootTable)
end

end)
