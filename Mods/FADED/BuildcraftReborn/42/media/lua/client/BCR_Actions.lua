if isServer() then return end

require "BCR_Utils"
require "BCR_Debug"
require "BCR_ContainerSearch"

BCR_Actions = BCR_Actions or {}

local function fail(message)
    return {
        ok = false,
        message = message or BCR_Utils.tr("UI_BCR_ActionFailed", "Could not start action."),
    }
end

local function ok(message)
    return {
        ok = true,
        message = message or BCR_Utils.tr("UI_BCR_ActionStarted", "Action started."),
    }
end

local function playerForIndex(playerIndex)
    if getSpecificPlayer then
        return getSpecificPlayer(playerIndex or 0)
    end
    return getPlayer and getPlayer() or nil
end

local function containersFor(player, context)
    if context and context.containers then
        return context.containers
    end
    if player and BCR_ContainerSearch and BCR_ContainerSearch.getVisibleContainers then
        return BCR_ContainerSearch.getVisibleContainers(player)
    end
    if player and BCR_ContainerSearch and BCR_ContainerSearch.getContainers then
        return BCR_ContainerSearch.getContainers(player)
    end
    if player and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.getContainers then
        return ISInventoryPaneContextMenu.getContainers(player)
    end
    return nil
end

local function craftRecipeForBuildInfo(info)
    if not info or not info.getRecipe or not info:getRecipe() then return nil end
    local buildRecipe = info:getRecipe()
    if buildRecipe.getCraftRecipe then
        return buildRecipe:getCraftRecipe()
    end
    return nil
end

local function inputTool(inputScript, inventory)
    if not inputScript or not inventory or not inputScript.getPossibleInputItems then
        return nil
    end

    local entryItems = inputScript:getPossibleInputItems()
    for index = 0, BCR_Utils.listSize(entryItems) - 1 do
        local scriptItem = BCR_Utils.listGet(entryItems, index)
        local itemType = scriptItem and scriptItem.getFullName and scriptItem:getFullName() or nil
        if itemType and inventory.getAllTypeEvalRecurse and ISBuildIsoEntity and ISBuildIsoEntity.predicateMaterial then
            local found = inventory:getAllTypeEvalRecurse(itemType, ISBuildIsoEntity.predicateMaterial)
            if found and found.size and found:size() > 0 then
                local item = found:get(0)
                if item and item.getFullType then
                    return item:getFullType()
                end
            end
        end
    end
    return nil
end

local function inventoryItemTypeSet(item)
    local types = {}
    if not item then return types end
    if item.getFullType then
        local fullType = item:getFullType()
        if fullType and fullType ~= "" then types[fullType] = true end
    end
    if item.getFullName then
        local fullName = item:getFullName()
        if fullName and fullName ~= "" then types[fullName] = true end
    end
    if item.getType then
        local itemType = item:getType()
        if itemType and itemType ~= "" then types[itemType] = true end
    end
    return types
end

local function recipeUsesInventoryItem(recipe, inventoryItem)
    if not recipe or not recipe.getInputs or not inventoryItem then return false end
    local itemTypes = inventoryItemTypeSet(inventoryItem)
    local inputs = recipe:getInputs()
    for i = 0, BCR_Utils.listSize(inputs) - 1 do
        local input = BCR_Utils.listGet(inputs, i)
        local options = input and input.getPossibleInputItems and input:getPossibleInputItems() or nil
        for index = 0, BCR_Utils.listSize(options) - 1 do
            local option = BCR_Utils.listGet(options, index)
            local fullName = option and option.getFullName and option:getFullName() or nil
            local name = option and option.getName and option:getName() or nil
            if (fullName and itemTypes[fullName]) or (name and itemTypes[name]) then
                return true
            end
        end
    end
    return false
end

local function contextInventoryItemForRecipe(recipe, context)
    local inventoryItem = context and context.inventoryItem or nil
    if not inventoryItem then return nil end
    if context and context.recipe == recipe then
        return inventoryItem
    end
    if recipeUsesInventoryItem(recipe, inventoryItem) then
        return inventoryItem
    end
    return nil
end

local function configureCraftLogic(player, recipe, context)
    if not player or not recipe or not HandcraftLogic or not HandcraftLogic.new then
        return nil, false
    end

    local isoObject = context and context.isoObject or nil
    local logic = HandcraftLogic.new(player, nil, isoObject)
    if logic.setManualSelectInputs then
        logic:setManualSelectInputs(true)
    end
    local containers = containersFor(player, context)
    if containers and logic.setContainers then
        logic:setContainers(containers)
    end
    if not isoObject and recipe.isAnySurfaceCraft and recipe:isAnySurfaceCraft() and logic.findCraftSurface and logic.setIsoObject then
        logic:setIsoObject(logic:findCraftSurface(player, 2))
    end

    local inventoryItem = contextInventoryItemForRecipe(recipe, context)
    if inventoryItem and logic.setRecipeFromContextClick then
        logic:setRecipeFromContextClick(recipe, inventoryItem)
    elseif logic.setRecipe then
        logic:setRecipe(recipe)
    end
    if logic.autoPopulateInputs then
        logic:autoPopulateInputs()
    end
    return logic, inventoryItem ~= nil
end

local function addRecipeAtHandItems(logic, items, itemsToReturn)
    if not logic or not logic.isUsingRecipeAtHandBenefit or not logic:isUsingRecipeAtHandBenefit() then
        return
    end
    if not logic.getUsingRecipeAtHandItem then
        return
    end
    local item = logic:getUsingRecipeAtHandItem()
    if item then
        if items and items.add then
            items:add(item)
        end
        if itemsToReturn and itemsToReturn.add then
            itemsToReturn:add(item)
        end
    end
end

local function transferCraftInputs(player, logic)
    local returnToContainer = {}
    local movedItems = false
    if not player or not logic or not logic.getRecipeData or not logic:getRecipeData() then
        return returnToContainer, movedItems
    end

    local recipe = logic.getRecipe and logic:getRecipe() or nil
    if recipe and recipe.isCanBeDoneFromFloor and recipe:isCanBeDoneFromFloor() then
        return returnToContainer, movedItems
    end

    local recipeData = logic:getRecipeData()
    if not recipeData.getAllInputItems or not recipeData.getAllPutBackInputItems then
        return returnToContainer, movedItems
    end

    local items = recipeData:getAllInputItems()
    local itemsToReturn = recipeData:getAllPutBackInputItems()
    addRecipeAtHandItems(logic, items, itemsToReturn)

    if not items or not items.size then
        return returnToContainer, movedItems
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item and item.getContainer and player.getInventory and item:getContainer() ~= player:getInventory() then
            if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.transferIfNeeded then
                ISInventoryPaneContextMenu.transferIfNeeded(player, item)
            end
            movedItems = true
            if itemsToReturn and itemsToReturn.contains and itemsToReturn:contains(item) then
                table.insert(returnToContainer, item)
            end
        end
    end
    return returnToContainer, movedItems
end

local function onCraftActionStart(logic, action)
    if logic and logic.startCraftAction then
        logic:startCraftAction(action)
    end
end

local function onCraftActionComplete(logic)
    if logic and logic.stopCraftAction then
        logic:stopCraftAction()
    end
end

local function onCraftActionCancelled(logic)
    if logic and logic.stopCraftAction then
        logic:stopCraftAction()
    end
end

function BCR_Actions.performCraft(playerIndex, item, context)
    local player = playerForIndex(playerIndex)
    local recipe = item and item.raw or nil
    if not player or not recipe then
        return fail(BCR_Utils.tr("UI_BCR_ActionNoRecipe", "No recipe selected."))
    end
    if not ISEntityUI or (not ISEntityUI.HandcraftStartMultiple and not ISEntityUI.HandcraftStart) then
        return fail(BCR_Utils.tr("UI_BCR_ActionMissingVanilla", "Vanilla action API missing."))
    end

    local logic, usedContextItem = configureCraftLogic(player, recipe, context)
    if not logic then
        return fail(BCR_Utils.tr("UI_BCR_ActionMissingVanilla", "Vanilla action API missing."))
    end
    if logic.canPerformCurrentRecipe and not logic:canPerformCurrentRecipe() then
        return fail(BCR_Utils.tr("UI_BCR_ActionBlocked", "Requirements are not met."))
    end

    local returnToContainer, movedItems = transferCraftInputs(player, logic)
    if movedItems then
        local refreshedLogic, refreshedUsedContextItem = configureCraftLogic(player, recipe, context)
        if refreshedLogic then
            logic = refreshedLogic
            usedContextItem = refreshedUsedContextItem
        end
    end
    if logic.updateManualInputAllowedItemTypes then
        logic:updateManualInputAllowedItemTypes()
    end

    if usedContextItem and ISEntityUI.HandcraftStart then
        local action = ISEntityUI.HandcraftStart(player, logic, false, true, context and context.eatPercentage or nil)
        if not action then
            return fail(BCR_Utils.tr("UI_BCR_ActionFailed", "Could not start action."))
        end
        if action.setOnComplete then action:setOnComplete(onCraftActionComplete, logic) end
        if action.setOnCancel then action:setOnCancel(onCraftActionCancelled, logic) end
        onCraftActionStart(logic, action)
        if ISCraftingUI and ISCraftingUI.ReturnItemsToOriginalContainer then
            ISCraftingUI.ReturnItemsToOriginalContainer(player, returnToContainer)
        end
        return ok(BCR_Utils.tr("UI_BCR_ActionCraftQueued", "Craft queued."))
    end

    if not ISEntityUI.HandcraftStartMultiple then
        return fail(BCR_Utils.tr("UI_BCR_ActionMissingVanilla", "Vanilla action API missing."))
    end

    local actions = ISEntityUI.HandcraftStartMultiple(player, logic, false, 1, false)
    if not actions then
        return fail(BCR_Utils.tr("UI_BCR_ActionFailed", "Could not start action."))
    end

    local queued = 0
    for _, action in ipairs(actions) do
        if action then
            if action.setOnStart then action:setOnStart(onCraftActionStart, logic) end
            if action.setOnComplete then action:setOnComplete(onCraftActionComplete, logic) end
            if action.setOnCancel then action:setOnCancel(onCraftActionCancelled, logic) end
            if ISTimedActionQueue and ISTimedActionQueue.add then
                ISTimedActionQueue.add(action)
                queued = queued + 1
            end
        end
    end

    if queued == 0 then
        return fail(BCR_Utils.tr("UI_BCR_ActionFailed", "Could not start action."))
    end
    if ISCraftingUI and ISCraftingUI.ReturnItemsToOriginalContainer then
        ISCraftingUI.ReturnItemsToOriginalContainer(player, returnToContainer)
    end
    return ok(BCR_Utils.tr("UI_BCR_ActionCraftQueued", "Craft queued."))
end

function BCR_Actions.performBuild(playerIndex, item, context)
    local player = playerForIndex(playerIndex)
    local info = item and item.raw or nil
    if not player or not info then
        return fail(BCR_Utils.tr("UI_BCR_ActionNoBuildable", "No buildable selected."))
    end
    if not ISBuildIsoEntity or not ISBuildIsoEntity.new or not getCell then
        return fail(BCR_Utils.tr("UI_BCR_ActionMissingVanilla", "Vanilla action API missing."))
    end

    local containers = containersFor(player, context)
    local logic = nil
    if BuildLogic and BuildLogic.new then
        logic = BuildLogic.new(player, nil, context and context.isoObject or nil)
        if containers and logic.setContainers then
            logic:setContainers(containers)
        end
        local craftRecipe = craftRecipeForBuildInfo(info)
        if craftRecipe and logic.setRecipe then
            logic:setRecipe(craftRecipe)
        end
        if logic.autoPopulateInputs then
            logic:autoPopulateInputs()
        end
    end

    local selectedInfo = info

    local buildEntity = ISBuildIsoEntity:new(player, selectedInfo, 1, containers, logic)
    if not buildEntity then
        return fail(BCR_Utils.tr("UI_BCR_ActionFailed", "Could not start action."))
    end

    if player.getPlayerNum then
        buildEntity.player = player:getPlayerNum()
    end
    buildEntity.dragNilAfterPlace = false
    buildEntity.blockAfterPlace = true

    local recipe = craftRecipeForBuildInfo(selectedInfo)
    local inventory = player.getInventory and player:getInventory() or nil
    if recipe and inventory then
        if recipe.getToolBoth then buildEntity.equipBothHandItem = inputTool(recipe:getToolBoth(), inventory) end
        if recipe.getToolRight then buildEntity.firstItem = inputTool(recipe:getToolRight(), inventory) end
        if recipe.getToolLeft then buildEntity.secondItem = inputTool(recipe:getToolLeft(), inventory) end
    end

    local canBuild = true
    if logic and logic.canPerformCurrentRecipe then
        canBuild = logic:canPerformCurrentRecipe() == true
        if player.isBuildCheat and player:isBuildCheat() then
            canBuild = true
        end
    end
    if logic and logic.isCraftActionInProgress and logic:isCraftActionInProgress() then
        canBuild = false
    end
    if not canBuild then
        return fail(BCR_Utils.tr("UI_BCR_ActionBlocked", "Requirements are not met."))
    end
    buildEntity.blockBuild = not canBuild

    local cell = getCell and getCell() or nil
    if cell and player.getPlayerNum then
        cell:setDrag(buildEntity, player:getPlayerNum())
    else
        return fail(BCR_Utils.tr("UI_BCR_ActionFailed", "Could not start action."))
    end
    local result = ok(BCR_Utils.tr("UI_BCR_ActionBuildCursor", "Placement cursor started."))
    result.buildEntity = buildEntity
    return result
end

function BCR_Actions.perform(playerIndex, item, context)
    if not item then
        return fail(BCR_Utils.tr("UI_BCR_ActionNoSelection", "No entry selected."))
    end
    if item.kind == "craft" then
        return BCR_Actions.performCraft(playerIndex, item, context)
    end
    if item.kind == "build" then
        return BCR_Actions.performBuild(playerIndex, item, context)
    end
    return fail(BCR_Utils.tr("UI_BCR_ActionNoSelection", "No entry selected."))
end

return BCR_Actions
