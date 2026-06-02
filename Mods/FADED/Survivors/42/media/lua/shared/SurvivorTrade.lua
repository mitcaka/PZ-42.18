SurvivorTrade = SurvivorTrade or {}

SurvivorTrade.StockCatalog = {
    {fullType="Base.TinnedBeans", label="Canned Beans", value=4, count=3},
    {fullType="Base.CannedCorn", label="Canned Corn", value=4, count=2},
    {fullType="Base.WaterBottle", label="Water Bottle", value=4, count=2},
    {fullType="Base.Bandage", label="Bandage", value=6, count=3},
    {fullType="Base.AlcoholWipes", label="Alcohol Wipes", value=5, count=2},
    {fullType="Base.Pills", label="Painkillers", value=7, count=1},
    {fullType="Base.Screwdriver", label="Screwdriver", value=8, count=1},
    {fullType="Base.Hammer", label="Hammer", value=10, count=1},
    {fullType="Base.NailsBox", label="Box of Nails", value=12, count=1},
    {fullType="Base.Bullets9mmBox", label="Box of 9mm Rounds", value=18, count=1},
    {fullType="Base.ShotgunShellsBox", label="Box of Shotgun Shells", value=20, count=1},
}

local catalogByType = {}
for _, entry in ipairs(SurvivorTrade.StockCatalog) do
    catalogByType[entry.fullType] = entry
end

local function safeCall(target, methodName, fallback)
    if not target or not target[methodName] then return fallback end
    local ok, value = pcall(target[methodName], target)
    if not ok or value == nil then return fallback end
    return value
end

local function isInstance(item, className)
    if not item or not instanceof then return false end
    local ok, result = pcall(instanceof, item, className)
    return ok and result == true
end

local function getFullType(itemOrType)
    if type(itemOrType) == "string" then return itemOrType end
    return safeCall(itemOrType, "getFullType", nil)
end

local function conditionMultiplier(item)
    local condition = tonumber(safeCall(item, "getCondition", nil))
    local conditionMax = tonumber(safeCall(item, "getConditionMax", nil))
    if not condition or not conditionMax or conditionMax <= 0 then return 1 end
    return math.max(0.25, math.min(1, condition / conditionMax))
end

function SurvivorTrade.GetDisplayName(item, fallback)
    return tostring(safeCall(item, "getDisplayName", fallback or getFullType(item) or "Item"))
end

function SurvivorTrade.GetItemValue(itemOrType)
    local fullType = getFullType(itemOrType)
    if not fullType then return 0 end

    local catalog = catalogByType[fullType]
    local value = catalog and catalog.value or nil
    local lowerType = string.lower(fullType)

    if not value and type(itemOrType) ~= "string" then
        if isInstance(itemOrType, "HandWeapon") then
            value = safeCall(itemOrType, "isRanged", false) and 30 or 10
        elseif isInstance(itemOrType, "Food") then
            value = 4
        elseif isInstance(itemOrType, "DrainableComboItem") then
            value = 4
        elseif isInstance(itemOrType, "InventoryContainer") then
            value = 8
        end
    end

    if not value then
        if string.find(lowerType, "rifle", 1, true)
                or string.find(lowerType, "shotgun", 1, true)
                or string.find(lowerType, "pistol", 1, true)
                or string.find(lowerType, "revolver", 1, true) then
            value = 30
        elseif string.find(lowerType, "bullet", 1, true)
                or string.find(lowerType, "shell", 1, true)
                or string.find(lowerType, "ammo", 1, true) then
            value = 12
        elseif string.find(lowerType, "bandage", 1, true)
                or string.find(lowerType, "pills", 1, true)
                or string.find(lowerType, "antibiotic", 1, true)
                or string.find(lowerType, "disinfect", 1, true) then
            value = 7
        elseif string.find(lowerType, "axe", 1, true)
                or string.find(lowerType, "knife", 1, true)
                or string.find(lowerType, "hammer", 1, true)
                or string.find(lowerType, "crowbar", 1, true)
                or string.find(lowerType, "wrench", 1, true) then
            value = 10
        else
            value = math.max(1, math.ceil((tonumber(safeCall(itemOrType, "getActualWeight", 1)) or 1) * 2))
        end
    end

    return math.max(1, math.floor((tonumber(value) or 1) * conditionMultiplier(itemOrType) + 0.5))
end

function SurvivorTrade.CanOfferItem(player, item)
    if not item or not getFullType(item) then return false end
    if safeCall(item, "isFavorite", false) then return false end
    if isInstance(item, "Clothing") then return false end

    local lowerType = string.lower(getFullType(item))
    if lowerType == "base.keyring"
            or string.find(lowerType, "keyring", 1, true)
            or string.sub(lowerType, -3) == "key" then
        return false
    end

    if player then
        if safeCall(player, "getPrimaryHandItem", nil) == item then return false end
        if safeCall(player, "getSecondaryHandItem", nil) == item then return false end
    end

    if isInstance(item, "InventoryContainer") then
        local inventory = safeCall(item, "getInventory", nil)
        if inventory and not safeCall(inventory, "isEmpty", true) then return false end
    end

    return SurvivorTrade.GetItemValue(item) > 0
end

function SurvivorTrade.IsEligibleBrain(brain)
    return brain ~= nil
        and not brain.hostile
        and not brain.hostileP
        and not brain.companionDowned
end

function SurvivorTrade.EnsureStock(brain)
    if not brain then return {} end
    local gameTime = getGameTime and getGameTime() or nil
    local now = gameTime and gameTime.getWorldAgeHours and gameTime:getWorldAgeHours() or 0

    if type(brain.survivorTradeStock) ~= "table" then
        brain.survivorTradeStock = {}
        for _, catalog in ipairs(SurvivorTrade.StockCatalog) do
            brain.survivorTradeStock[catalog.fullType] = {
                fullType=catalog.fullType,
                label=catalog.label,
                value=catalog.value,
                count=catalog.count,
            }
        end
        brain.survivorTradeRestockAt = now + 24
    elseif now >= (tonumber(brain.survivorTradeRestockAt) or 0) then
        for _, catalog in ipairs(SurvivorTrade.StockCatalog) do
            local stock = brain.survivorTradeStock[catalog.fullType] or {}
            stock.fullType = catalog.fullType
            stock.label = catalog.label
            stock.value = catalog.value
            stock.count = math.max(tonumber(stock.count) or 0, catalog.count)
            brain.survivorTradeStock[catalog.fullType] = stock
        end
        brain.survivorTradeRestockAt = now + 24
    end
    return brain.survivorTradeStock
end

function SurvivorTrade.GetStockRows(stock)
    local rows = {}
    for fullType, entry in pairs(stock or {}) do
        local count = math.max(0, math.floor(tonumber(entry.count) or 0))
        if count > 0 then
            table.insert(rows, {
                fullType=tostring(entry.fullType or fullType),
                label=tostring(entry.label or fullType),
                value=math.max(1, math.floor(tonumber(entry.value) or 1)),
                count=count,
            })
        end
    end
    table.sort(rows, function(a, b)
        return tostring(a.label) < tostring(b.label)
    end)
    return rows
end

function SurvivorTrade.CreateItem(fullType)
    if BanditCompatibility and BanditCompatibility.InstanceItem then
        return BanditCompatibility.InstanceItem(fullType)
    end
    if instanceItem then return instanceItem(fullType) end
    if InventoryItemFactory and InventoryItemFactory.CreateItem then
        return InventoryItemFactory.CreateItem(fullType)
    end
end

return SurvivorTrade
