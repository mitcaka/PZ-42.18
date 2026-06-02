if isServer() then return end

require "ISUI/ISContextMenu"
require "BCR_DisplaySettings"
require "BCR_Scale"
require "BCR_Utils"
require "BCR_DisplaySettingsPanel"
require "BCR_HubWindow"
require "BCR_Hooks"
require "BCR_QuickButton"
require "BCR_RecipeIndex"
require "BCR_BuildIndex"
require "BCR_UserData"
require "BCR_Actions"
require "BCR_ContainerSearch"

BuildcraftReborn = BuildcraftReborn or {}

local MAX_CONTEXT_FAVORITES = 16

local function tr(key, fallback)
    return BCR_Utils.tr(key, fallback)
end

local function hasKeyBinding(value)
    if not keyBinding then return true end
    for _, binding in ipairs(keyBinding) do
        if binding and binding.value == value then
            return true
        end
    end
    return false
end

local function onGameBoot()
    if keyBinding and Keyboard then
        if not hasKeyBinding("[Buildcraft Reborn]") then
            table.insert(keyBinding, { value = "[Buildcraft Reborn]" })
        end
        if not hasKeyBinding("Buildcraft Craft / Build") then
            table.insert(keyBinding, { value = "Buildcraft Craft / Build", key = Keyboard.KEY_B })
        end
    end
end

local function onGameStart()
    if BuildcraftReborn.invalidateCaches then
        BuildcraftReborn.invalidateCaches("game-start")
    end
    if BCR_DisplaySettings and BCR_DisplaySettings.load then
        BCR_DisplaySettings.load()
    end
    if BCR_Scale and BCR_Scale.refresh then
        BCR_Scale.refresh()
    end
    if BCR_Hooks and BCR_Hooks.install then
        BCR_Hooks.install()
    end
    if BCR_QuickButton and BCR_QuickButton.ensure then
        BCR_QuickButton.ensure(0)
    end
end

local function openDisplaySettings()
    if BCR_DisplaySettingsPanel and BCR_DisplaySettingsPanel.toggle then
        local x = (getMouseX and getMouseX() or 100) + 12
        local y = (getMouseY and getMouseY() or 84) + 12
        BCR_DisplaySettingsPanel.toggle(x, y)
    end
end

local function openHub(targetOrPlayerIndex, maybePlayerIndex)
    local playerIndex = maybePlayerIndex
    if type(targetOrPlayerIndex) == "number" and playerIndex == nil then
        playerIndex = targetOrPlayerIndex
    end
    playerIndex = tonumber(playerIndex) or 0
    if BCR_HubWindow and BCR_HubWindow.open then
        BCR_HubWindow.open(playerIndex)
    elseif BCR_HubWindow and BCR_HubWindow.toggle then
        BCR_HubWindow.toggle(playerIndex)
    end
end

local function inventoryItemForContext(items)
    if not items then return nil end
    if ISInventoryPane and ISInventoryPane.getActualItems then
        local actual = ISInventoryPane.getActualItems(items)
        return actual and actual[1] or nil
    end
    if type(items) == "table" then
        local item = items[1]
        if item and item.items and item.items[1] then
            return item.items[1]
        end
        return item
    end
    return nil
end

local function openHubForInventoryItem(selectedItem, playerIndex)
    playerIndex = tonumber(playerIndex) or 0
    if BCR_Hooks and BCR_Hooks.openInventoryItem then
        BCR_Hooks.openInventoryItem(selectedItem, playerIndex)
    elseif BCR_HubWindow and BCR_HubWindow.toggle then
        BCR_HubWindow.toggle(playerIndex)
    end
end

local function firstWorldObject(worldobjects)
    if type(worldobjects) ~= "table" then return nil end
    for _, object in ipairs(worldobjects) do
        if object then return object end
    end
    return nil
end

local function containersForContext(player)
    if BCR_ContainerSearch and BCR_ContainerSearch.getVisibleContainers then
        return BCR_ContainerSearch.getVisibleContainers(player)
    end
    if BCR_ContainerSearch and BCR_ContainerSearch.getContainers then
        return BCR_ContainerSearch.getContainers(player)
    end
    if player and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.getContainers then
        return ISInventoryPaneContextMenu.getContainers(player)
    end
    return nil
end

local function addFavoriteItems(source, out, playerIndex)
    for _, item in ipairs(source or {}) do
        if BCR_UserData and BCR_UserData.isFavorite and BCR_UserData.isFavorite(item, playerIndex) then
            table.insert(out, item)
        end
    end
end

local function favoriteContextItems(playerIndex)
    local favorites = {}
    if BCR_BuildIndex and BCR_BuildIndex.build then
        addFavoriteItems(BCR_BuildIndex.build(false), favorites, playerIndex)
    end
    if BCR_RecipeIndex and BCR_RecipeIndex.build then
        addFavoriteItems(BCR_RecipeIndex.build(false), favorites, playerIndex)
    end
    table.sort(favorites, function(a, b)
        if (a and a.kind) ~= (b and b.kind) then
            return (a and a.kind) == "build"
        end
        local left = BCR_Utils.lower(a and a.label or "")
        local right = BCR_Utils.lower(b and b.label or "")
        if left ~= right then return left < right end
        return BCR_Utils.lower(a and a.key or "") < BCR_Utils.lower(b and b.key or "")
    end)
    return favorites
end

local function favoriteContextLabel(item)
    local label = item and item.label or ""
    if item and item.kind == "build" then
        return BCR_Utils.format(tr("ContextMenu_BCR_FavoritePlace", "Place: %1"), label)
    end
    return BCR_Utils.format(tr("ContextMenu_BCR_FavoriteMake", "Make: %1"), label)
end

local function showContextActionResult(player, result)
    if result and result.ok then return end
    local message = result and result.message or tr("UI_BCR_ActionFailed", "Could not start action.")
    if player and HaloTextHelper and HaloTextHelper.addTextWithArrow then
        HaloTextHelper.addTextWithArrow(player, message, false, 255, 90, 90)
    end
end

local function performFavoriteContextAction(item, playerIndex, worldobjects)
    if not item or not BCR_Actions or not BCR_Actions.perform then return end
    playerIndex = tonumber(playerIndex) or 0
    local player = getSpecificPlayer and getSpecificPlayer(playerIndex) or getPlayer()
    if not player then return end
    local isoObject = item.kind == "craft" and firstWorldObject(worldobjects) or nil
    local result = BCR_Actions.perform(playerIndex, item, {
        isoObject = isoObject,
        containers = containersForContext(player),
    })
    showContextActionResult(player, result)
    if result and result.ok and BCR_UserData then
        if BCR_UserData.addRecent then BCR_UserData.addRecent(item, playerIndex) end
        if BCR_UserData.setLastAction then BCR_UserData.setLastAction(item, playerIndex) end
    end
end

local function openFavoritesHub(target, playerIndex)
    playerIndex = tonumber(playerIndex) or 0
    if not BCR_HubWindow or not BCR_HubWindow.open then return end
    local panel = BCR_HubWindow.open(playerIndex)
    if panel and panel.setMode then
        panel:setMode("favorites")
    end
end

local function addFavoritesContextMenu(context, playerIndex, worldobjects)
    if not context or not context.addOption then return end
    local favorites = favoriteContextItems(playerIndex)
    if #favorites == 0 then return end

    local menu = context
    if ISContextMenu and ISContextMenu.getNew and context.addSubMenu then
        local parent = context:addOption(tr("ContextMenu_BCR_Favorites", "Buildcraft Favorites"), worldobjects, nil)
        local subMenu = ISContextMenu:getNew(context)
        context:addSubMenu(parent, subMenu)
        menu = subMenu
    end

    local limit = math.min(#favorites, MAX_CONTEXT_FAVORITES)
    for index = 1, limit do
        local item = favorites[index]
        menu:addOption(favoriteContextLabel(item), item, performFavoriteContextAction, playerIndex, worldobjects)
    end
    if #favorites > limit then
        menu:addOption(tr("ContextMenu_BCR_FavoritesMore", "More favorites..."), worldobjects, openFavoritesHub, playerIndex)
    end
end

function BuildcraftReborn.invalidateCaches(reason)
    if BCR_RecipeIndex and BCR_RecipeIndex.invalidate then
        BCR_RecipeIndex.invalidate(reason or "manual")
    end
    if BCR_BuildIndex and BCR_BuildIndex.invalidate then
        BCR_BuildIndex.invalidate(reason or "manual")
    end
    if BCR_IconResolver and BCR_IconResolver.invalidate then
        BCR_IconResolver.invalidate(reason or "manual")
    end
    if BCR_HubWindow and BCR_HubWindow.invalidateCaches then
        BCR_HubWindow.invalidateCaches(reason or "manual")
    elseif BCR_HubWindow and BCR_HubWindow.markDirty then
        BCR_HubWindow.markDirty(reason or "manual")
    end
end

local function onFillWorldObjectContextMenu(playerIndex, context, worldobjects, test)
    if test then return end
    if not context or not context.addOption then return end
    local player = getSpecificPlayer and getSpecificPlayer(playerIndex) or nil
    if not player then return end
    context:addOption(tr("ContextMenu_BCR_OpenHub", "Craft / Build"), worldobjects, openHub, playerIndex)
    addFavoritesContextMenu(context, playerIndex, worldobjects)
    context:addOption(tr("ContextMenu_BCR_OpenDisplaySettings", "Buildcraft Display Settings"), worldobjects, openDisplaySettings)
end

local function onFillInventoryObjectContextMenu(playerIndex, context, items)
    if not context or not context.addOption then return end
    if context.bcrHasItemSpecific or context.bcrHasRecipeLookup then return end
    local selectedItem = inventoryItemForContext(items)
    context:addOption(tr("ContextMenu_BCR_OpenHub", "Craft / Build"), selectedItem, openHubForInventoryItem, playerIndex)
end

local function onCreatePlayer(playerIndex, player)
    if BCR_QuickButton and BCR_QuickButton.ensure then
        BCR_QuickButton.ensure(playerIndex or 0)
    end
end

BuildcraftReborn.openDisplaySettings = openDisplaySettings
BuildcraftReborn.openHub = openHub
BuildcraftReborn.openHubForInventoryItem = openHubForInventoryItem

Events.OnGameBoot.Add(onGameBoot)
Events.OnGameStart.Add(onGameStart)
Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
