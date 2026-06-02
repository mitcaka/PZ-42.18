if isServer() then return end

require "BCR_DisplaySettings"
require "BCR_HubWindow"
require "BCR_Utils"

BCR_Hooks = BCR_Hooks or {}
BCR_Hooks.installed = BCR_Hooks.installed or false
BCR_Hooks.originalOpenHandcraftWindow = BCR_Hooks.originalOpenHandcraftWindow or nil
BCR_Hooks.originalOpenBuildWindow = BCR_Hooks.originalOpenBuildWindow or nil
BCR_Hooks.originalBackButtonAddCommands = BCR_Hooks.originalBackButtonAddCommands or nil
BCR_Hooks.originalBackButtonOnCommand = BCR_Hooks.originalBackButtonOnCommand or nil
BCR_Hooks.originalAddNewCraftingDynamicalContextMenu = BCR_Hooks.originalAddNewCraftingDynamicalContextMenu or nil
BCR_Hooks.originalDoRecipeListForItem = BCR_Hooks.originalDoRecipeListForItem or nil
BCR_Hooks.originalDoBuildRecipeListForItem = BCR_Hooks.originalDoBuildRecipeListForItem or nil
BCR_Hooks.originalDisplayCharacterInfo = BCR_Hooks.originalDisplayCharacterInfo or nil

local function shouldUseHub()
    return BCR_HubWindow
        and BCR_HubWindow.openFor
end

local function playerIndexFor(player)
    if type(player) == "number" then
        return player
    end
    if player and player.getPlayerNum then
        return player:getPlayerNum()
    end
    return 0
end

local function toggleHub(playerIndex, mode)
    if not BCR_HubWindow or not BCR_HubWindow.toggle then return end
    local panel = BCR_HubWindow.toggle(playerIndex or 0)
    if panel and panel.setMode and mode then
        panel:setMode(mode)
    end
end

local function inventoryItemSearchText(item)
    if not item then return "" end
    local parts = {}
    if item.getDisplayName then table.insert(parts, BCR_Utils.safeString(item:getDisplayName(), "")) end
    if item.getFullType then table.insert(parts, BCR_Utils.safeString(item:getFullType(), "")) end
    if item.getFullName then table.insert(parts, BCR_Utils.safeString(item:getFullName(), "")) end
    return table.concat(parts, " ")
end

function BCR_Hooks.openInventoryItem(selectedItem, playerIndex, recipe)
    local player = getSpecificPlayer and getSpecificPlayer(playerIndex or 0) or nil
    local searchText = inventoryItemSearchText(selectedItem)
    if recipe then
        return BCR_HubWindow.openFor(player or (playerIndex or 0), "craft", recipe, searchText, {
            inventoryItem = selectedItem,
            recipe = recipe,
        })
    end
    if BCR_HubWindow.openSearch then
        return BCR_HubWindow.openSearch(playerIndex or 0, searchText, {
            inventoryItem = selectedItem,
        })
    end
    return toggleHub(playerIndex or 0, "all")
end

local function addBuildcraftWheelSlice(wheel, slices)
    table.insert(slices, {
        text = BCR_Utils.tr("UI_BCR_RadialMakeBuild", "Craft / Build"),
        texture = getTexture and getTexture("media/ui/Build_Tool.png") or nil,
        command = { BCR_Hooks.onBackButtonBuildcraft, wheel },
    })
end

function BCR_Hooks.onBackButtonBuildcraft(wheel)
    if not wheel then return end
    toggleHub(wheel.playerNum or 0, "all")
end

local function rebuildWheelSlices(wheel, slices)
    if not wheel or not wheel.clear or not wheel.addSlice then return end
    wheel:clear()
    for _, slice in ipairs(slices) do
        local command = slice.command or {}
        wheel:addSlice(slice.text, slice.texture, command[1], command[2], command[3], command[4], command[5], command[6], command[7])
    end
end

local function isCraftBuildCommand(slice)
    local command = slice and slice.command or nil
    local value = command and command[3] or nil
    return value == "Crafting" or value == "Building"
end

local function isBuildcraftKey(key)
    if not getCore or not getCore() then return false end
    return getCore():isKey("Buildcraft Craft / Build", key)
        or getCore():isKey("Buildcraft Make / Build", key)
        or getCore():isKey("Crafting UI", key)
        or getCore():isKey("Building UI", key)
end

function BCR_Hooks.install()
    if BCR_Hooks.installed then return end
    if not ISEntityUI then return end
    if not ISEntityUI.OpenHandcraftWindow or not ISEntityUI.OpenBuildWindow then return end

    -- BCR_MONKEY_PATCH_JUSTIFIED: verified B42.18 UI open wrappers only; originals are preserved for development inspection.
    BCR_Hooks.originalOpenHandcraftWindow = ISEntityUI.OpenHandcraftWindow
    BCR_Hooks.originalOpenBuildWindow = ISEntityUI.OpenBuildWindow

    -- BCR_MONKEY_PATCH_JUSTIFIED: replace vanilla presentation entry points while preserving vanilla craft execution APIs.
    ISEntityUI.OpenHandcraftWindow = function(player, isoObject, queryOverride, ignoreFindSurface, recipe, itemString)
        if shouldUseHub() then
            return BCR_HubWindow.openFor(player, "craft", recipe, itemString, {
                isoObject = isoObject,
                queryOverride = queryOverride,
                ignoreFindSurface = ignoreFindSurface,
            })
        end
        return BCR_Hooks.originalOpenHandcraftWindow(player, isoObject, queryOverride, ignoreFindSurface, recipe, itemString)
    end

    -- BCR_MONKEY_PATCH_JUSTIFIED: replace vanilla presentation entry points while preserving vanilla placement/action APIs.
    ISEntityUI.OpenBuildWindow = function(player, isoObject, queryOverride, ignoreFindSurface, recipe, itemString)
        if shouldUseHub() then
            return BCR_HubWindow.openFor(player, "build", recipe, itemString, {
                isoObject = isoObject,
                queryOverride = queryOverride,
                ignoreFindSurface = ignoreFindSurface,
            })
        end
        return BCR_Hooks.originalOpenBuildWindow(player, isoObject, queryOverride, ignoreFindSurface, recipe, itemString)
    end

    if ISBackButtonWheel and ISBackButtonWheel.addCommands and ISBackButtonWheel.onCommand then
        -- BCR_MONKEY_PATCH_JUSTIFIED: B42.18 back-button wheel exposes vanilla Crafting/Building slices; replace them with one Buildcraft slice.
        BCR_Hooks.originalBackButtonAddCommands = ISBackButtonWheel.addCommands
        BCR_Hooks.originalBackButtonOnCommand = ISBackButtonWheel.onCommand

        -- BCR_MONKEY_PATCH_JUSTIFIED: replace B42.18 radial craft/build presentation slices only.
        ISBackButtonWheel.addCommands = function(wheel)
            BCR_Hooks.originalBackButtonAddCommands(wheel)
            if not shouldUseHub() or not wheel or not wheel.slices then return end
            local nextSlices = {}
            local addedBuildcraft = false
            for _, slice in ipairs(wheel.slices) do
                if isCraftBuildCommand(slice) then
                    if not addedBuildcraft then
                        addBuildcraftWheelSlice(wheel, nextSlices)
                        addedBuildcraft = true
                    end
                else
                    table.insert(nextSlices, slice)
                end
            end
            if addedBuildcraft then
                rebuildWheelSlices(wheel, nextSlices)
            end
        end

        -- BCR_MONKEY_PATCH_JUSTIFIED: route B42.18 radial craft/build commands to Buildcraft hub only.
        ISBackButtonWheel.onCommand = function(wheel, command)
            if shouldUseHub() and (command == "Crafting" or command == "Building") then
                toggleHub(wheel and wheel.playerNum or 0, "all")
                return
            end
            return BCR_Hooks.originalBackButtonOnCommand(wheel, command)
        end
    end

    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.addNewCraftingDynamicalContextMenu then
        -- BCR_MONKEY_PATCH_JUSTIFIED: keep B42.18 item-specific recipe entries intact; the generic Buildcraft entry is added by OnFillInventoryObjectContextMenu.
        BCR_Hooks.originalAddNewCraftingDynamicalContextMenu = ISInventoryPaneContextMenu.addNewCraftingDynamicalContextMenu
        ISInventoryPaneContextMenu.addNewCraftingDynamicalContextMenu = function(selectedItem, context, recipeList, player, containerList)
            return BCR_Hooks.originalAddNewCraftingDynamicalContextMenu(selectedItem, context, recipeList, player, containerList)
        end
    end

    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.doRecipeListForItem then
        -- BCR_MONKEY_PATCH_JUSTIFIED: preserve B42.18 "recipes using this item" submenus; Buildcraft remains available as a separate context option.
        BCR_Hooks.originalDoRecipeListForItem = ISInventoryPaneContextMenu.doRecipeListForItem
        ISInventoryPaneContextMenu.doRecipeListForItem = function(context, text, recipeItem, playerObj)
            return BCR_Hooks.originalDoRecipeListForItem(context, text, recipeItem, playerObj)
        end
    end

    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.doBuildRecipeListForItem then
        -- BCR_MONKEY_PATCH_JUSTIFIED: preserve B42.18 "build recipes using this item" submenus; Buildcraft remains available as a separate context option.
        BCR_Hooks.originalDoBuildRecipeListForItem = ISInventoryPaneContextMenu.doBuildRecipeListForItem
        ISInventoryPaneContextMenu.doBuildRecipeListForItem = function(context, text, recipeItem, playerObj)
            return BCR_Hooks.originalDoBuildRecipeListForItem(context, text, recipeItem, playerObj)
        end
    end

    if xpUpdate and xpUpdate.displayCharacterInfo and Events and Events.OnKeyPressed and Events.OnKeyPressed.Remove then
        -- BCR_MONKEY_PATCH_JUSTIFIED: B42.18 binds B to vanilla craft/build windows through xpUpdate; route those keys to Buildcraft.
        BCR_Hooks.originalDisplayCharacterInfo = xpUpdate.displayCharacterInfo
        Events.OnKeyPressed.Remove(xpUpdate.displayCharacterInfo)
        xpUpdate.displayCharacterInfo = function(key)
            if shouldUseHub() and isBuildcraftKey(key) then
                toggleHub(playerIndexFor(getSpecificPlayer and getSpecificPlayer(0) or 0), "all")
                return
            end
            return BCR_Hooks.originalDisplayCharacterInfo(key)
        end
        Events.OnKeyPressed.Add(xpUpdate.displayCharacterInfo)
    end

    BCR_Hooks.installed = true
end

BCR_Hooks.shouldUseHub = shouldUseHub
BCR_Hooks.toggleHub = toggleHub
BCR_Hooks.isBuildcraftKey = isBuildcraftKey

return BCR_Hooks
