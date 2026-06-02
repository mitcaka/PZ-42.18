require "FadedFeastcraft/FFC_Utils"
require "FadedFeastcraft/FFC_ItemClassifier"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.IngredientScanner = FadedFeastcraft.IngredientScanner or {}

local Scanner = FadedFeastcraft.IngredientScanner
local Utils = FadedFeastcraft.Utils
local Classifier = FadedFeastcraft.ItemClassifier

Scanner.cache = Scanner.cache or {
    records = {},
    stats = {},
    worldAgeHours = 0,
}

local function addRecord(records, stats, item, container, origin)
    local record = Classifier.classify(item, container, origin)
    if not record then return end
    records[#records + 1] = record
    stats.total = stats.total + 1
    stats.categories[record.category] = (stats.categories[record.category] or 0) + 1
    stats.sources[record.source] = (stats.sources[record.source] or 0) + 1
    if not record.usable then stats.flagged = stats.flagged + 1 end
end

local function scanNearby(player, records, stats, options)
    if not (options and options.includeNearby == true) then return end
    if not Utils.sbBool("EnableNearbyContainerScanning", true) then return end
    local maxItems = Utils.sbNumber("MaxScannedItems", 350, 50, 1000)
    if stats.itemsVisited >= maxItems then return end

    Utils.walkNearbyContainerItems(player, function(item, container, origin)
        if stats.itemsVisited >= maxItems then return end
        stats.itemsVisited = stats.itemsVisited + 1
        addRecord(records, stats, item, container, origin)
    end, {
        radius = Utils.sbNumber("IngredientScanRadius", 2, 0, 8),
        maxContainers = Utils.sbNumber("MaxScannedContainers", 24, 4, 80),
        maxItems = maxItems - stats.itemsVisited,
    })
    stats.includeNearby = true
end

function Scanner.scan(player, options)
    player = player or (getSpecificPlayer and getSpecificPlayer(0))
    options = options or {}
    local records = {}
    local stats = {
        total = 0,
        flagged = 0,
        categories = {},
        sources = {},
        itemsVisited = 0,
        includeNearby = false,
    }

    if player and player.getInventory then
        Utils.walkInventory(player:getInventory(), function(item, container)
            stats.itemsVisited = stats.itemsVisited + 1
            addRecord(records, stats, item, container, "Inventory")
        end, Utils.sbNumber("MaxScannedItems", 350, 50, 1000))
        scanNearby(player, records, stats, options)
    end

    table.sort(records, function(a, b)
        if a.usable ~= b.usable then return a.usable end
        if a.category ~= b.category then return a.category < b.category end
        return a.name < b.name
    end)

    Scanner.cache = {
        records = records,
        stats = stats,
        includeNearby = options.includeNearby == true,
        worldAgeHours = getGameTime and getGameTime():getWorldAgeHours() or 0,
    }
    return Scanner.cache
end

function Scanner.getCache()
    return Scanner.cache
end

return Scanner
