require "FadedFeastcraft/FFC_Utils"
require "FadedFeastcraft/FFC_ItemClassifier"
require "FadedFeastcraft/FFC_Preservation"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.ExpiryTracker = FadedFeastcraft.ExpiryTracker or {}

local Tracker = FadedFeastcraft.ExpiryTracker
local Utils = FadedFeastcraft.Utils
local Classifier = FadedFeastcraft.ItemClassifier
local Preservation = FadedFeastcraft.Preservation

Tracker.cache = Tracker.cache or {
    records = {},
    stats = {},
    worldAgeHours = 0,
}

local function daysText(days)
    if days == nil then return "unknown" end
    if days >= 999999 then return "sealed" end
    if days < 0 then return "rotten" end
    if days < 0.05 then return "now" end
    if days < 1 then return tostring(Utils.round(days * 24, 1)) .. "h" end
    return tostring(Utils.round(days, 1)) .. "d"
end

local function expiryInfo(record)
    local preservation = record and (record.preservation or (Preservation and Preservation.readItem and Preservation.readItem(record))) or nil
    if preservation then
        local days = Preservation.remainingDays and Preservation.remainingDays(preservation) or preservation.shelfDays
        if days and days < 0 then return "Expired preserved food", -900, days, "expired" end
        return "FFC preserved", days or 999996, days, daysText(days or 999996)
    end
    local exp = record and record.expiry or nil
    if record and record.rotten then
        return "Rotten", -1000, 0, "rotten"
    end
    if exp and exp.isRotten then
        return "Rotten", -1000, 0, "rotten"
    end
    if exp and exp.isSealed then
        return "Sealed", 999999, 999999, "sealed"
    end
    if exp and type(exp.roomDays) == "number" then
        local days = exp.roomDays
        if days < 0 then return "Rotten", -1000, 0, "rotten" end
        if days < 1 then return "Expires today", days, days, daysText(days) end
        if days < 3 then return "Expires soon", days, days, daysText(days) end
        return "Fresh", days, days, daysText(days)
    end
    if record and record.freshness then
        local freshness = Utils.lower(record.freshness)
        if string.find(freshness, "soon", 1, true) then return "Expires soon", 0.75, 0.75, "<1d" end
        if string.find(freshness, "sealed", 1, true) or string.find(freshness, "stable", 1, true) then
            return "Stable", 999998, 999998, "stable"
        end
    end
    return "Unknown", 999997, nil, "unknown"
end

local function addRecord(records, stats, item, container, origin)
    local record = Classifier.classify(item, container, origin)
    if not record then return end
    record.kind = "expiry"
    record.origin = origin or record.origin or "Inventory"
    record.roomContainerType = container and container.getType and container:getType() or ""

    local status, sortKey, days, label = expiryInfo(record)
    record.expiryStatus = status
    record.expirySort = sortKey
    record.expiryDays = days
    record.expiryLabel = label
    record.search = tostring(record.search or "") .. " " .. Utils.lower(tostring(status) .. " " .. tostring(origin or "") .. " " .. tostring(record.roomContainerType or ""))

    records[#records + 1] = record
    stats.total = stats.total + 1
    stats.byStatus[status] = (stats.byStatus[status] or 0) + 1
    stats.byOrigin[record.origin] = (stats.byOrigin[record.origin] or 0) + 1
    if status == "Rotten" then
        stats.rotten = stats.rotten + 1
    elseif sortKey < 1 then
        stats.today = stats.today + 1
    elseif sortKey < 3 then
        stats.soon = stats.soon + 1
    end
end

function Tracker.scan(player, options)
    options = options or {}
    player = player or (getSpecificPlayer and getSpecificPlayer(0))
    local includeRoom = options.includeRoom == true and Utils.sbBool("EnableRoomExpiryScanning", true)
    local records = {}
    local stats = {
        total = 0,
        today = 0,
        soon = 0,
        rotten = 0,
        roomContainers = 0,
        roomItemsVisited = 0,
        inventoryItemsVisited = 0,
        byStatus = {},
        byOrigin = {},
    }

    if player and player.getInventory then
        Utils.walkInventory(player:getInventory(), function(item, container)
            stats.inventoryItemsVisited = stats.inventoryItemsVisited + 1
            addRecord(records, stats, item, container, "Inventory")
        end, Utils.sbNumber("MaxScannedItems", 350, 50, 1000))

        if includeRoom then
            local containers, visited = Utils.walkRoomContainerItems(player, function(item, container, origin)
                stats.roomItemsVisited = stats.roomItemsVisited + 1
                addRecord(records, stats, item, container, origin or "Room")
            end, {
                radius = Utils.sbNumber("ExpiryRoomScanRadius", 8, 2, 16),
                maxContainers = Utils.sbNumber("MaxScannedContainers", 24, 4, 80),
                maxItems = Utils.sbNumber("MaxScannedItems", 350, 50, 1000),
            })
            stats.roomContainers = containers
            stats.roomItemsVisited = visited
        end
    end

    table.sort(records, function(a, b)
        if a.expirySort ~= b.expirySort then return a.expirySort < b.expirySort end
        if a.origin ~= b.origin then return tostring(a.origin) < tostring(b.origin) end
        return tostring(a.name) < tostring(b.name)
    end)

    Tracker.cache = {
        records = records,
        stats = stats,
        includeRoom = includeRoom,
        worldAgeHours = getGameTime and getGameTime():getWorldAgeHours() or 0,
    }
    return Tracker.cache
end

function Tracker.getCache()
    return Tracker.cache
end

return Tracker
