FWPAmmoManufacture = FWPAmmoManufacture or {}

FWPAmmoManufacture.MODULE = "FWPAmmoManufacture"
FWPAmmoManufacture.COMMAND_CRAFT = "Craft"
FWPAmmoManufacture.POWDER_ITEM = "Base.GunPowder"
FWPAmmoManufacture.POWDER_UNIT = 0.005

FWPAmmoManufacture.PRESS_TYPES = {
    "Base.Lyman_TMag",
    "Base.Lee_LoadMaster",
}

FWPAmmoManufacture.RECIPES = {
    { id = "bullets57", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_57", output = "Base.Bullets57", outputCount = 50, casing = "Base.Brass57", casingBag = "Base.Bag_Brass57", casingCount = 50, casingBagSize = 100, projectile = "Base.Lead57_Pack", primer = "Base.PrimerSM_Pack", powder = 16, skill = 1, xp = 8 },
    { id = "bullets380", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_380", output = "Base.Bullets380", outputCount = 50, casing = "Base.Brass380", casingBag = "Base.Bag_Brass380", casingCount = 50, casingBagSize = 100, projectile = "Base.Lead9_Pack", primer = "Base.PrimerSM_Pack", powder = 14, skill = 1, xp = 8 },
    { id = "bullets9mm", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_9MM", output = "Base.Bullets9mm", outputCount = 50, casing = "Base.Brass9", casingBag = "Base.Bag_Brass9", casingCount = 50, casingBagSize = 100, projectile = "Base.Lead9_Pack", primer = "Base.PrimerSM_Pack", powder = 16, skill = 1, xp = 8 },
    { id = "bullets38", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_38", output = "Base.Bullets38", outputCount = 50, casing = "Base.Brass38", casingBag = "Base.Bag_Brass38", casingCount = 50, casingBagSize = 100, projectile = "Base.Lead38_Pack", primer = "Base.PrimerSM_Pack", powder = 16, skill = 2, xp = 9 },
    { id = "bullets357", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_357", output = "Base.Bullets357", outputCount = 50, casing = "Base.Brass357", casingBag = "Base.Bag_Brass357", casingCount = 50, casingBagSize = 100, projectile = "Base.Lead38_Pack", primer = "Base.PrimerSM_Pack", powder = 20, skill = 2, xp = 10 },
    { id = "bullets45", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_45", output = "Base.Bullets45", outputCount = 50, casing = "Base.Brass45", casingBag = "Base.Bag_Brass45", casingCount = 50, casingBagSize = 100, projectile = "Base.Lead45_Pack", primer = "Base.PrimerLG_Pack", powder = 20, skill = 2, xp = 10 },
    { id = "bullets45lc", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_45LC", output = "Base.Bullets45LC", outputCount = 50, casing = "Base.Brass45LC", casingBag = "Base.Bag_Brass45LC", casingCount = 50, casingBagSize = 100, projectile = "Base.Lead45_Pack", primer = "Base.PrimerLG_Pack", powder = 22, skill = 2, xp = 10 },
    { id = "bullets44", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_44", output = "Base.Bullets44", outputCount = 50, casing = "Base.Brass44", casingBag = "Base.Bag_Brass44", casingCount = 50, casingBagSize = 100, projectile = "Base.Lead44_Pack", primer = "Base.PrimerLG_Pack", powder = 24, skill = 2, xp = 11 },
    { id = "bullets4570", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_4570", output = "Base.Bullets4570", outputCount = 20, casing = "Base.Brass4570", casingBag = "Base.Bag_Brass4570", casingCount = 20, casingBagSize = 100, projectile = "Base.Lead50_Pack", primer = "Base.PrimerLG_Pack", powder = 28, skill = 4, xp = 12 },
    { id = "bullets50mag", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_50MAG", output = "Base.Bullets50MAG", outputCount = 20, casing = "Base.Brass50MAG", casingBag = "Base.Bag_Brass50MAG", casingCount = 20, casingBagSize = 100, projectile = "Base.Lead50_Pack", primer = "Base.PrimerLG_Pack", powder = 26, skill = 4, xp = 12 },
    { id = "bullets223", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_223", output = "Base.223Bullets", outputCount = 20, casing = "Base.Brass223", casingBag = "Base.Bag_Brass223", casingCount = 20, casingBagSize = 100, projectile = "Base.Lead556_Pack", primer = "Base.PrimerSM_Pack", powder = 20, skill = 3, xp = 11 },
    { id = "bullets556", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_556", output = "Base.556Bullets", outputCount = 20, casing = "Base.Brass556", casingBag = "Base.Bag_Brass556", casingCount = 20, casingBagSize = 100, projectile = "Base.Lead556_Pack", primer = "Base.PrimerSM_Pack", powder = 22, skill = 3, xp = 11 },
    { id = "bullets545x39", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_545", output = "Base.545x39Bullets", outputCount = 20, casing = "Base.Brass545x39", casingBag = "Base.Bag_Brass545x39", casingCount = 20, casingBagSize = 100, projectile = "Base.Lead545_Pack", primer = "Base.PrimerSM_Pack", powder = 22, skill = 3, xp = 11 },
    { id = "bullets762x39", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_762X39", output = "Base.762x39Bullets", outputCount = 20, casing = "Base.Brass762x39", casingBag = "Base.Bag_Brass762x39", casingCount = 20, casingBagSize = 100, projectile = "Base.Lead30_Pack", primer = "Base.PrimerLG_Pack", powder = 24, skill = 3, xp = 12 },
    { id = "bullets308", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_308", output = "Base.308Bullets", outputCount = 20, casing = "Base.Brass308", casingBag = "Base.Bag_Brass308", casingCount = 20, casingBagSize = 100, projectile = "Base.Lead30_Pack", primer = "Base.PrimerLG_Pack", powder = 26, skill = 4, xp = 12 },
    { id = "bullets762x51", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_762X51", output = "Base.762x51Bullets", outputCount = 20, casing = "Base.Brass762x51", casingBag = "Base.Bag_Brass762x51", casingCount = 20, casingBagSize = 100, projectile = "Base.Lead30_Pack", primer = "Base.PrimerLG_Pack", powder = 26, skill = 4, xp = 12 },
    { id = "bullets762x54r", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_762X54R", output = "Base.762x54rBullets", outputCount = 20, casing = "Base.Brass762x54r", casingBag = "Base.Bag_Brass762x54r", casingCount = 20, casingBagSize = 100, projectile = "Base.Lead30_Pack", primer = "Base.PrimerLG_Pack", powder = 28, skill = 4, xp = 13 },
    { id = "bullets3006", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_3006", output = "Base.3006Bullets", outputCount = 20, casing = "Base.Brass3006", casingBag = "Base.Bag_Brass3006", casingCount = 20, casingBagSize = 100, projectile = "Base.Lead30_Pack", primer = "Base.PrimerLG_Pack", powder = 28, skill = 4, xp = 13 },
    { id = "bullets50bmg", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_50BMG", output = "Base.50BMGBullets", outputCount = 10, casing = "Base.Brass50BMG", casingBag = "Base.Bag_Brass50BMG", casingCount = 10, casingBagSize = 50, projectile = "Base.Lead50_Pack", primer = "Base.PrimerLG_Pack", powder = 42, skill = 6, xp = 16 },
    { id = "shells410", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_410", output = "Base.410gShotgunShells", outputCount = 25, casing = "Base.Hull410g", casingBag = "Base.Bag_Hull410g", casingCount = 25, casingBagSize = 25, projectile = "Base.Lead00Buck_Pack", primer = "Base.PrimerSG_Pack", powder = 20, skill = 2, xp = 10 },
    { id = "shells20", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_20G", output = "Base.20gShotgunShells", outputCount = 25, casing = "Base.Hull20g", casingBag = "Base.Bag_Hull20g", casingCount = 25, casingBagSize = 25, projectile = "Base.Lead00Buck_Pack", primer = "Base.PrimerSG_Pack", powder = 24, skill = 2, xp = 10 },
    { id = "shells12", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_12G", output = "Base.ShotgunShells", outputCount = 25, casing = "Base.Hull12g", casingBag = "Base.Bag_Hull12g", casingCount = 25, casingBagSize = 25, projectile = "Base.Lead00Buck_Pack", primer = "Base.PrimerSG_Pack", powder = 26, skill = 2, xp = 11 },
    { id = "shells12inc", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_12G_INC", output = "Base.FWP_12gIncendiaryShells", outputCount = 10, casing = "Base.Hull12g", casingBag = "Base.Bag_Hull12g", casingCount = 10, casingBagSize = 25, projectile = "Base.40INCRound", primer = "Base.PrimerSG_Pack", powder = 18, skill = 4, xp = 13 },
    { id = "shells10", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_10G", output = "Base.10gShotgunShells", outputCount = 25, casing = "Base.Hull10g", casingBag = "Base.Bag_Hull10g", casingCount = 25, casingBagSize = 25, projectile = "Base.Lead00Buck_Pack", primer = "Base.PrimerSG_Pack", powder = 30, skill = 3, xp = 12 },
    { id = "shells4", nameKey = "IGUI_FWP_AMMO_MANUFACTURE_4G", output = "Base.4gShotgunShells", outputCount = 10, casing = "Base.Hull4g", casingBag = "Base.Bag_Hull4g", casingCount = 10, casingBagSize = 10, projectile = "Base.Lead00Buck_Pack", primer = "Base.PrimerSG_Pack", powder = 34, skill = 4, xp = 14 },
}

FWPAmmoManufacture.RECIPE_BY_ID = {}
for _, recipe in ipairs(FWPAmmoManufacture.RECIPES) do
    FWPAmmoManufacture.RECIPE_BY_ID[recipe.id] = recipe
end

local function normalizeType(itemType)
    if not itemType then return nil end
    itemType = tostring(itemType)
    if itemType == "" then return nil end
    if itemType:find(".", 1, true) then return itemType end
    return "Base." .. itemType
end

local function shortType(itemType)
    itemType = normalizeType(itemType)
    if not itemType then return nil end
    return itemType:gsub("^.-%.", "")
end

local function safeCall(obj, methodName, ...)
    if not obj or not methodName or not obj[methodName] then return nil end
    local ok, result = pcall(obj[methodName], obj, ...)
    if ok then return result end
    return nil
end

local function safeSet(obj, methodName, ...)
    if not obj or not methodName or not obj[methodName] then return false end
    local ok = pcall(obj[methodName], obj, ...)
    return ok == true
end

local function collectItems(inventory, itemType)
    local found = {}
    if not inventory or not itemType then return found end
    local wantedFull = normalizeType(itemType)
    local wantedShort = shortType(itemType)
    local lists = {}

    if inventory.getAllTypeRecurse then
        local okFull, listFull = pcall(function() return inventory:getAllTypeRecurse(wantedFull) end)
        if okFull and listFull then lists[#lists + 1] = listFull end
        local okShort, listShort = pcall(function() return inventory:getAllTypeRecurse(wantedShort) end)
        if okShort and listShort then lists[#lists + 1] = listShort end
    end
    if #lists == 0 and inventory.FindAll then
        local ok, list = pcall(function() return inventory:FindAll(wantedShort) end)
        if ok and list then lists[#lists + 1] = list end
    end

    local seen = {}
    for _, list in ipairs(lists) do
        local size = list and list.size and list:size() or 0
        for i = 0, size - 1 do
            local item = list:get(i)
            if item and not seen[item] then
                local fullType = safeCall(item, "getFullType")
                local itemShort = safeCall(item, "getType")
                if fullType == wantedFull or itemShort == wantedShort then
                    found[#found + 1] = item
                    seen[item] = true
                end
            end
        end
    end
    return found
end

local function addItems(inventory, itemType, count)
    if not inventory or not itemType then return end
    for _ = 1, math.max(tonumber(count) or 0, 0) do
        pcall(inventory.AddItem, inventory, normalizeType(itemType))
    end
end

local function removeItemObject(inventory, item)
    if not item then return false end
    local container = safeCall(item, "getContainer") or inventory
    if container and container.Remove then
        local ok = pcall(container.Remove, container, item)
        return ok == true
    end
    return false
end

local function removeItems(inventory, itemType, count)
    local items = collectItems(inventory, itemType)
    local removed = 0
    for i = 1, #items do
        if removed >= count then break end
        if removeItemObject(inventory, items[i]) then
            removed = removed + 1
        end
    end
    return removed
end

function FWPAmmoManufacture.countItems(inventory, itemType)
    return #collectItems(inventory, itemType)
end

function FWPAmmoManufacture.countPowderUnits(inventory)
    local total = 0
    for _, item in ipairs(collectItems(inventory, FWPAmmoManufacture.POWDER_ITEM)) do
        local delta = tonumber(safeCall(item, "getUsedDelta")) or 1
        total = total + math.floor((delta / FWPAmmoManufacture.POWDER_UNIT) + 0.0001)
    end
    return total
end

function FWPAmmoManufacture.hasPress(inventory)
    for _, itemType in ipairs(FWPAmmoManufacture.PRESS_TYPES) do
        if FWPAmmoManufacture.countItems(inventory, itemType) > 0 then return true end
    end
    return false
end

local function getReloadingLevel(player)
    if not player or not player.getPerkLevel or not Perks or not Perks.Reloading then return 0 end
    local ok, level = pcall(player.getPerkLevel, player, Perks.Reloading)
    if ok then return tonumber(level) or 0 end
    return 0
end

function FWPAmmoManufacture.getRecipe(recipeId)
    return FWPAmmoManufacture.RECIPE_BY_ID[tostring(recipeId or "")]
end

function FWPAmmoManufacture.getStatus(player, recipe)
    local inventory = player and player.getInventory and player:getInventory() or nil
    local status = {
        press = inventory and FWPAmmoManufacture.hasPress(inventory) or false,
        reloading = getReloadingLevel(player),
        requiredSkill = recipe and recipe.skill or 0,
        primer = 0,
        projectile = 0,
        casing = 0,
        casingRequired = recipe and recipe.casingCount or 0,
        powder = 0,
        powderRequired = recipe and recipe.powder or 0,
    }
    if not inventory or not recipe then return status end
    status.primer = FWPAmmoManufacture.countItems(inventory, recipe.primer)
    status.projectile = FWPAmmoManufacture.countItems(inventory, recipe.projectile)
    local loose = FWPAmmoManufacture.countItems(inventory, recipe.casing)
    local bagCount = recipe.casingBag and FWPAmmoManufacture.countItems(inventory, recipe.casingBag) or 0
    status.casing = loose + (bagCount * (recipe.casingBagSize or recipe.casingCount or 1))
    status.powder = FWPAmmoManufacture.countPowderUnits(inventory)
    return status
end

function FWPAmmoManufacture.canCraft(player, recipe)
    local status = FWPAmmoManufacture.getStatus(player, recipe)
    if not recipe then return false, status, "recipe" end
    if not status.press then return false, status, "press" end
    if status.reloading < (recipe.skill or 0) then return false, status, "skill" end
    if status.primer < 1 then return false, status, "primer" end
    if status.projectile < 1 then return false, status, "projectile" end
    if status.casing < (recipe.casingCount or 0) then return false, status, "casing" end
    if status.powder < (recipe.powder or 0) then return false, status, "powder" end
    return true, status, nil
end

local function consumeCasings(inventory, recipe)
    local remaining = recipe.casingCount or 0
    local looseRemoved = removeItems(inventory, recipe.casing, remaining)
    remaining = remaining - looseRemoved
    while remaining > 0 and recipe.casingBag do
        local bagRemoved = removeItems(inventory, recipe.casingBag, 1)
        if bagRemoved <= 0 then break end
        local bagSize = recipe.casingBagSize or recipe.casingCount or remaining
        local leftover = math.max(bagSize - remaining, 0)
        if leftover > 0 then addItems(inventory, recipe.casing, leftover) end
        remaining = 0
    end
    return remaining <= 0
end

local function consumePowder(inventory, units)
    local remaining = tonumber(units) or 0
    for _, item in ipairs(collectItems(inventory, FWPAmmoManufacture.POWDER_ITEM)) do
        if remaining <= 0 then break end
        local delta = tonumber(safeCall(item, "getUsedDelta")) or 1
        local itemUnits = math.floor((delta / FWPAmmoManufacture.POWDER_UNIT) + 0.0001)
        local take = math.min(itemUnits, remaining)
        delta = math.max(delta - (take * FWPAmmoManufacture.POWDER_UNIT), 0)
        if delta <= FWPAmmoManufacture.POWDER_UNIT * 0.5 then
            removeItemObject(inventory, item)
        else
            safeSet(item, "setUsedDelta", delta)
        end
        remaining = remaining - take
    end
    return remaining <= 0
end

local function awardReloadingXp(player, amount)
    if not player or not player.getXp or not Perks or not Perks.Reloading then return end
    local xp = player:getXp()
    if xp and xp.AddXP then pcall(xp.AddXP, xp, Perks.Reloading, tonumber(amount) or 0) end
end

function FWPAmmoManufacture.performCraft(player, recipeId)
    local recipe = FWPAmmoManufacture.getRecipe(recipeId)
    local ok = FWPAmmoManufacture.canCraft(player, recipe)
    if not ok then return false end
    local inventory = player and player.getInventory and player:getInventory() or nil
    if not inventory then return false end

    if removeItems(inventory, recipe.primer, 1) < 1 then return false end
    if removeItems(inventory, recipe.projectile, 1) < 1 then return false end
    if not consumeCasings(inventory, recipe) then return false end
    if not consumePowder(inventory, recipe.powder or 0) then return false end
    addItems(inventory, recipe.output, recipe.outputCount or 1)
    awardReloadingXp(player, recipe.xp or 0)
    return true
end
