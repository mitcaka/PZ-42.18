require "FadedFeastcraft/FFC_Config"
require "FadedFeastcraft/FFC_Utils"
require "FadedFeastcraft/FFC_IngredientScanner"
require "FadedFeastcraft/FFC_AutoCookPlanner"
require "FadedFeastcraft/FFC_MealEffects"
require "FadedFeastcraft/FFC_RecipeIndex"
require "FadedFeastcraft/FFC_Balance"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.CookingStation = FadedFeastcraft.CookingStation or {}

local Station = FadedFeastcraft.CookingStation
local Config = FadedFeastcraft.Config
local Utils = FadedFeastcraft.Utils
local Scanner = FadedFeastcraft.IngredientScanner
local AutoPlanner = FadedFeastcraft.AutoCookPlanner
local MealEffects = FadedFeastcraft.MealEffects
local Recipes = FadedFeastcraft.RecipeIndex
local CSR = FadedFeastcraft.CSR
local Balance = FadedFeastcraft.Balance

Station.cache = Station.cache or {
    stations = {},
    tools = {},
    candidates = {},
    stats = {},
}

local HEAT_KEYWORDS = {
    "stove",
    "oven",
    "microwave",
    "barbecue",
    "bbq",
    "grill",
    "campfire",
    "fireplace",
    "antique oven",
    "wood stove",
}

local COOKING_RECIPE_KEYWORDS = {
    "cook",
    "bake",
    "boil",
    "grill",
    "roast",
    "fry",
    "soup",
    "stew",
    "rice",
    "pasta",
    "casserole",
    "ramen",
}

local function asText(value)
    return Utils.lower(tostring(value or ""))
end

local function joinObjectText(obj)
    local parts = {}
    local function add(value)
        if value ~= nil then parts[#parts + 1] = tostring(value) end
    end
    add(Utils.safeCall(obj, "getName"))
    add(Utils.safeCall(obj, "getObjectName"))
    add(Utils.safeCall(obj, "getType"))
    local sprite = Utils.safeCall(obj, "getSprite")
    add(Utils.safeCall(sprite, "getName"))
    local props = Utils.safeCall(obj, "getProperties")
    add(Utils.safeCall(props, "Val", "CustomName"))
    add(Utils.safeCall(props, "Val", "GroupName"))
    return asText(table.concat(parts, " "))
end

local function stationKind(text)
    if string.find(text, "microwave", 1, true) then return "Microwave" end
    if string.find(text, "campfire", 1, true) then return "Campfire" end
    if string.find(text, "barbecue", 1, true) or string.find(text, "bbq", 1, true) or string.find(text, "grill", 1, true) then return "Grill" end
    if string.find(text, "oven", 1, true) then return "Oven" end
    if string.find(text, "stove", 1, true) then return "Stove" end
    if string.find(text, "fireplace", 1, true) then return "Fireplace" end
    return "Heat Source"
end

local function isHeatSourceObject(obj)
    if not obj then return false end
    local text = joinObjectText(obj)
    if text == "" then return false end
    for _, keyword in ipairs(HEAT_KEYWORDS) do
        if string.find(text, keyword, 1, true) then return true, stationKind(text), text end
    end
    return false
end

local function distance2(player, x, y)
    if not player then return 999999 end
    local dx = (player:getX() or 0) - x
    local dy = (player:getY() or 0) - y
    return dx * dx + dy * dy
end

local function stationKey(x, y, z, index)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z) .. ":" .. tostring(index)
end

local function parseStationKey(key)
    local x, y, z, index = string.match(tostring(key or ""), "^(%-?%d+):(%-?%d+):(%-?%d+):(%d+)$")
    if not x then return nil end
    return tonumber(x), tonumber(y), tonumber(z), tonumber(index)
end

local function objectAtKey(key)
    local x, y, z, index = parseStationKey(key)
    if not x or not getCell then return nil end
    local square = getCell():getGridSquare(x, y, z)
    local objects = square and square:getObjects() or nil
    if not objects or not objects.size or not objects.get then return nil end
    if index < 0 or index >= objects:size() then return nil end
    return objects:get(index), x, y, z, index
end

local function scanStations(player)
    local stations = {}
    local radius = Utils.sbNumber("IngredientScanRadius", 2, 0, 8)
    local cell = getCell and getCell() or nil
    if not player or not cell then return stations end

    local px = math.floor(player:getX())
    local py = math.floor(player:getY())
    local pz = math.floor(player:getZ())

    for x = px - radius, px + radius do
        for y = py - radius, py + radius do
            local square = cell:getGridSquare(x, y, pz)
            local objects = square and square:getObjects() or nil
            if objects then
                for i = 0, objects:size() - 1 do
                    local obj = objects:get(i)
                    local heat, kind, text = isHeatSourceObject(obj)
                    if heat then
                        stations[#stations + 1] = {
                            key = stationKey(x, y, pz, i),
                            name = kind,
                            kind = kind,
                            x = x,
                            y = y,
                            z = pz,
                            index = i,
                            distance2 = distance2(player, x + 0.5, y + 0.5),
                            detail = text,
                        }
                    end
                end
            end
        end
    end

    table.sort(stations, function(a, b)
        if a.distance2 ~= b.distance2 then return a.distance2 < b.distance2 end
        return tostring(a.name) < tostring(b.name)
    end)
    return stations
end

local function toolTypeFor(item)
    local text = asText(Utils.getFullType(item) .. " " .. Utils.getDisplayName(item))
    if string.find(text, "pot", 1, true) or string.find(text, "saucepan", 1, true) or string.find(text, "fryingpan", 1, true)
        or string.find(text, "frying pan", 1, true) or string.find(text, "roastingpan", 1, true) or string.find(text, "roasting pan", 1, true)
        or string.find(text, "bakingpan", 1, true) or string.find(text, "baking pan", 1, true) or string.find(text, "bowl", 1, true) then
        return "vessel"
    end
    if string.find(text, "knife", 1, true) or string.find(text, "cleaver", 1, true) then
        return "blade"
    end
    if string.find(text, "canopener", 1, true) or string.find(text, "can opener", 1, true) or string.find(text, "tinopener", 1, true) or string.find(text, "tin opener", 1, true) then
        return "canopener"
    end
    if string.find(text, "spoon", 1, true) or string.find(text, "spatula", 1, true) or string.find(text, "fork", 1, true) then
        return "utensil"
    end
    return nil
end

local function scanTools(player, options)
    local tools = {
        vessel = {},
        blade = {},
        canopener = {},
        utensil = {},
        stats = {},
    }
    if not player then return tools end

    local maxItems = Utils.sbNumber("MaxScannedItems", 350, 50, 1000)
    local visited = 0
    local function addTool(item, origin)
        if not item or visited >= maxItems then return end
        visited = visited + 1
        local kind = toolTypeFor(item)
        if not kind then return end
        local record = {
            id = item.getID and item:getID() or nil,
            fullType = Utils.getFullType(item),
            name = Utils.getDisplayName(item),
            origin = origin or "Inventory",
        }
        tools[kind][#tools[kind] + 1] = record
        tools.stats[kind] = (tools.stats[kind] or 0) + 1
    end

    Utils.walkInventory(player:getInventory(), function(item)
        addTool(item, "Inventory")
    end, maxItems)

    if options and options.includeNearby == true and Utils.sbBool("EnableNearbyContainerScanning", true) then
        Utils.walkNearbyContainerItems(player, function(item, container, origin)
            addTool(item, origin or "Nearby")
        end, {
            radius = Utils.sbNumber("IngredientScanRadius", 2, 0, 8),
            maxContainers = Utils.sbNumber("MaxScannedContainers", 24, 4, 80),
            maxItems = math.max(0, maxItems - visited),
        })
    end

    return tools
end

local function safeFoodRecords(records)
    local out = {}
    for _, record in ipairs(records or {}) do
        if record.usable ~= false and not record.frozen and not record.rotten and not record.burnt then
            out[#out + 1] = record
        end
    end
    table.sort(out, function(a, b)
        if CSR and CSR.compareConsumablePriority and a.item and b.item then
            return CSR.compareConsumablePriority(a.item, b.item)
        end
        return tostring(a.name) < tostring(b.name)
    end)
    return out
end

local function cookingRecipeHint(recipe)
    local text = asText((recipe and recipe.name or "") .. " " .. (recipe and recipe.tags or "") .. " " .. (recipe and recipe.search or ""))
    for _, keyword in ipairs(COOKING_RECIPE_KEYWORDS) do
        if string.find(text, keyword, 1, true) then return true end
    end
    return false
end

local function buildCandidates(stations, tools, records, player, options)
    local candidates = {}
    local safeFoods = safeFoodRecords(records)
    local station = stations[1]
    local hasStation = station ~= nil
    local hasVessel = tools.vessel and #tools.vessel > 0

    local plan = AutoPlanner and AutoPlanner.buildPlan and AutoPlanner.buildPlan(safeFoods, player, {
        modeId = options and options.modeId or "balanced",
        maxItems = options and options.maxItems or math.min(6, (Balance and Balance.maxMealIngredients and Balance.maxMealIngredients()) or Config.MAX_MEAL_INGREDIENTS or 8),
        maxDuplicate = options and options.maxDuplicate or 2,
        maxSpices = options and options.maxSpices or 2,
        smartSpices = options and options.smartSpices,
    }) or nil
    local picked = plan and plan.itemIds or {}
    local planMode = plan and plan.mode and plan.mode.label or "Balanced"
    local planNotes = plan and plan.notes or {}
    local effectPreview = MealEffects and MealEffects.previewForRecords and MealEffects.previewForRecords(plan and plan.records or {}) or nil

    local blockedReason = nil
    if not hasStation then
        blockedReason = "Needs nearby stove, oven, microwave, grill, campfire, or similar heat source."
    elseif not hasVessel then
        blockedReason = "Needs a cooking vessel such as a pot, pan, saucepan, bowl, or baking pan."
    elseif #picked == 0 then
        blockedReason = "Needs at least one safe, unfrozen food ingredient."
    end

    candidates[#candidates + 1] = {
        kind = "stationRecipe",
        recipeId = "ffc_hot_meal",
        name = "FFC Hot Meal",
        source = "FFC",
        category = "Ready to Cook",
        resultType = Config.RESULT_FIELD_MEAL,
        textureName = Utils.getScriptItemTextureName and Utils.getScriptItemTextureName(Utils.getScriptItem(Config.RESULT_FIELD_MEAL)) or nil,
        stationKey = station and station.key or "",
        stationName = station and station.name or "none",
        itemIds = picked,
        plannerMode = planMode,
        plannerNotes = planNotes,
        plannerRecords = plan and plan.records or {},
        effectTag = effectPreview and effectPreview.tag or nil,
        effectName = effectPreview and effectPreview.spec and effectPreview.spec.name or nil,
        effectDesc = effectPreview and effectPreview.spec and effectPreview.spec.desc or nil,
        blocked = blockedReason ~= nil,
        blockedReason = blockedReason,
        search = "ffc hot meal cooked station stove oven pan pot food",
        detail = "Standalone Faded's Feastcraft hot meal action. Planner mode: " .. tostring(planMode) .. ". Server consumes selected safe foods after validating the heat source and vessel.",
    }

    local recipeCache = Recipes.build and Recipes.build(false) or Recipes.cache or {}
    for _, recipe in ipairs(recipeCache.recipes or {}) do
        if cookingRecipeHint(recipe) then
            candidates[#candidates + 1] = {
                kind = "stationRecipeHint",
                recipeId = "recipe_hint:" .. tostring(recipe.name or ""),
                name = tostring(recipe.name or "Cooking recipe"),
                source = tostring(recipe.source or "Recipe Index"),
                category = "Indexed Recipe",
                resultType = recipe.resultType,
                textureName = recipe.textureName,
                blocked = true,
                blockedReason = "Indexed source recipe. Direct GUI launch needs a recipe-specific adapter.",
                search = tostring(recipe.search or recipe.name or "") .. " indexed cooking recipe",
                detail = "Visible so FFC can show what the station sees before we bind this recipe family to server-safe execution.",
            }
        end
        if #candidates >= 80 then break end
    end

    table.sort(candidates, function(a, b)
        if a.blocked ~= b.blocked then return b.blocked end
        if a.category ~= b.category then return tostring(a.category) < tostring(b.category) end
        return tostring(a.name) < tostring(b.name)
    end)

    return candidates, safeFoods
end

function Station.scan(player, options)
    player = player or (getSpecificPlayer and getSpecificPlayer(0))
    options = options or {}
    local ingredientCache = Scanner.getCache()
    if not ingredientCache or not ingredientCache.records
        or (options.includeNearby == true and ingredientCache.includeNearby ~= true) then
        ingredientCache = Scanner.scan(player, { includeNearby = options.includeNearby == true })
    end

    local stations = scanStations(player)
    local tools = scanTools(player, options)
    local candidates, safeFoods = buildCandidates(stations, tools, ingredientCache.records or {}, player, options)

    Station.cache = {
        stations = stations,
        tools = tools,
        candidates = candidates,
        safeFoods = safeFoods,
        includeNearby = options.includeNearby == true,
        plannerMode = options.modeId or "balanced",
        stats = {
            stations = #stations,
            vessels = #(tools.vessel or {}),
            blades = #(tools.blade or {}),
            canOpeners = #(tools.canopener or {}),
            utensils = #(tools.utensil or {}),
            safeFoods = #safeFoods,
            candidates = #candidates,
            includeNearby = options.includeNearby == true,
        },
        worldAgeHours = getGameTime and getGameTime():getWorldAgeHours() or 0,
    }
    return Station.cache
end

function Station.getCache()
    return Station.cache
end

function Station.validateStationKey(player, key)
    local obj, x, y, z, index = objectAtKey(key)
    if not obj then return false, "Heat source no longer exists" end
    local heat, kind, text = isHeatSourceObject(obj)
    if not heat then return false, "Selected object is not a recognized heat source" end
    local radius = Utils.sbNumber("IngredientScanRadius", 2, 0, 8) + 1
    if player and distance2(player, x + 0.5, y + 0.5) > radius * radius then
        return false, "Heat source is out of range"
    end
    return true, {
        object = obj,
        key = stationKey(x, y, z, index),
        name = kind,
        kind = kind,
        x = x,
        y = y,
        z = z,
        index = index,
        detail = text,
    }
end

function Station.itemIdsToCsv(itemIds)
    local out = {}
    for _, id in ipairs(itemIds or {}) do
        if tonumber(id) then out[#out + 1] = tostring(math.floor(tonumber(id))) end
    end
    return table.concat(out, ",")
end

return Station
