if isServer() then return end

BCR_UserData = BCR_UserData or {}

local FAVORITES_KEY = "BCR_Favorites"
local HUB_LAYOUT_KEY = "BCR_HubLayout"
local QUICK_BUTTON_LAYOUT_KEY = "BCR_QuickButtonLayout"
local RECENTS_KEY = "BCR_RecentOpened"
local LAST_ACTION_KEY = "BCR_LastAction"
local MAX_RECENTS = 30

local function playerForIndex(playerIndex)
    if getSpecificPlayer then
        return getSpecificPlayer(playerIndex or 0)
    end
    return getPlayer and getPlayer() or nil
end

local function modDataFor(playerIndex)
    local player = playerForIndex(playerIndex)
    return player and player:getModData() or nil
end

function BCR_UserData.itemKey(item)
    if not item or not item.kind or not item.id or item.id == "" then
        return nil
    end
    return tostring(item.kind) .. ":" .. tostring(item.id)
end

function BCR_UserData.favorites(playerIndex)
    local modData = modDataFor(playerIndex)
    if not modData then return {} end
    if type(modData[FAVORITES_KEY]) ~= "table" then
        modData[FAVORITES_KEY] = {}
    end
    return modData[FAVORITES_KEY]
end

function BCR_UserData.isFavorite(item, playerIndex)
    local key = BCR_UserData.itemKey(item)
    if not key then return false end
    return BCR_UserData.favorites(playerIndex)[key] == true
end

function BCR_UserData.setFavorite(item, playerIndex, value)
    local key = BCR_UserData.itemKey(item)
    if not key then return false end
    local favorites = BCR_UserData.favorites(playerIndex)
    if value == true then
        favorites[key] = true
    else
        favorites[key] = nil
    end
    return favorites[key] == true
end

function BCR_UserData.toggleFavorite(item, playerIndex)
    return BCR_UserData.setFavorite(item, playerIndex, not BCR_UserData.isFavorite(item, playerIndex))
end

function BCR_UserData.recents(playerIndex)
    local modData = modDataFor(playerIndex)
    if not modData then return {} end
    if type(modData[RECENTS_KEY]) ~= "table" then
        modData[RECENTS_KEY] = {}
    end
    return modData[RECENTS_KEY]
end

function BCR_UserData.addRecent(item, playerIndex)
    local key = BCR_UserData.itemKey(item)
    if not key then return end
    local recents = BCR_UserData.recents(playerIndex)
    local nextRecents = { key }
    for _, existing in ipairs(recents) do
        if existing ~= key and #nextRecents < MAX_RECENTS then
            table.insert(nextRecents, existing)
        end
    end
    local modData = modDataFor(playerIndex)
    if modData then
        modData[RECENTS_KEY] = nextRecents
    end
end

function BCR_UserData.setLastAction(item, playerIndex)
    local key = BCR_UserData.itemKey(item)
    if not key then return end
    local modData = modDataFor(playerIndex)
    if modData then
        modData[LAST_ACTION_KEY] = key
    end
end

function BCR_UserData.lastActionKey(playerIndex)
    local modData = modDataFor(playerIndex)
    local key = modData and modData[LAST_ACTION_KEY] or nil
    if type(key) == "string" and key ~= "" then
        return key
    end
    return nil
end

function BCR_UserData.getHubLayout(playerIndex)
    local modData = modDataFor(playerIndex)
    local layout = modData and modData[HUB_LAYOUT_KEY] or nil
    if type(layout) ~= "table" then return nil end
    local width = tonumber(layout.width)
    local height = tonumber(layout.height)
    local x = tonumber(layout.x)
    local y = tonumber(layout.y)
    if not width or not height or width < 300 or height < 240 then
        return nil
    end
    return {
        x = x or 120,
        y = y or 90,
        width = width,
        height = height,
    }
end

function BCR_UserData.setHubLayout(playerIndex, x, y, width, height)
    local modData = modDataFor(playerIndex)
    if not modData then return end
    modData[HUB_LAYOUT_KEY] = {
        x = math.floor(tonumber(x) or 120),
        y = math.floor(tonumber(y) or 90),
        width = math.floor(tonumber(width) or 840),
        height = math.floor(tonumber(height) or 540),
    }
end

function BCR_UserData.getQuickButtonLayout(playerIndex)
    local modData = modDataFor(playerIndex)
    local layout = modData and modData[QUICK_BUTTON_LAYOUT_KEY] or nil
    if type(layout) ~= "table" then return nil end
    local x = tonumber(layout.x)
    local y = tonumber(layout.y)
    if not x or not y then return nil end
    return {
        x = x,
        y = y,
    }
end

function BCR_UserData.setQuickButtonLayout(playerIndex, x, y)
    local modData = modDataFor(playerIndex)
    if not modData then return end
    modData[QUICK_BUTTON_LAYOUT_KEY] = {
        x = math.floor(tonumber(x) or 12),
        y = math.floor(tonumber(y) or 80),
    }
end

return BCR_UserData
