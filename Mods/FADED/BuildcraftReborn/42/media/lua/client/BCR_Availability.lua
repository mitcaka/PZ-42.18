if isServer() then return end

require "BCR_Utils"
require "BCR_Debug"
require "BCR_ContainerSearch"

BCR_Availability = BCR_Availability or {}
BCR_Availability._inputLabelCache = BCR_Availability._inputLabelCache or {}

local function inputAmount(input)
    if not input then return 1, false end
    if input.isItemCount and input:isItemCount() then
        if input.getIntAmount then return input:getIntAmount(), false end
        return 1, false
    end
    if input.getAmount then return input:getAmount(), true end
    return 1, false
end

local function inputMaxAmount(input)
    if not input then return 1, false end
    if input.isItemCount and input:isItemCount() then
        if input.getIntMaxAmount then return input:getIntMaxAmount(), false end
        if input.getIntAmount then return input:getIntAmount(), false end
        return 1, false
    end
    if input.getIntMaxAmount then return input:getIntMaxAmount(), true end
    if input.getAmount then return input:getAmount(), true end
    return 1, false
end

local function inputLabel(input)
    if not input or not input.getPossibleInputItems then
        return BCR_Utils.tr("UI_BCR_RequirementUnknown", "Unknown input")
    end
    if BCR_Availability._inputLabelCache[input] then
        return BCR_Availability._inputLabelCache[input]
    end

    local options = input:getPossibleInputItems()
    local names = {}
    local seen = {}
    for i = 0, BCR_Utils.listSize(options) - 1 do
        local option = BCR_Utils.listGet(options, i)
        if option then
            if option.getDisplayName then
                BCR_Utils.uniqueAppend(names, seen, BCR_Utils.displayLabel(option:getDisplayName(), ""))
            elseif option.getFullName then
                BCR_Utils.uniqueAppend(names, seen, BCR_Utils.displayLabel(option:getFullName(), ""))
            end
        end
    end

    if #names == 0 then
        local unknown = BCR_Utils.tr("UI_BCR_RequirementUnknown", "Unknown input")
        BCR_Availability._inputLabelCache[input] = unknown
        return unknown
    end
    local label = BCR_Utils.joinLimited(names, " / ", 4, BCR_Utils.tr("UI_BCR_MoreOptions", "+%1 more"))
    BCR_Availability._inputLabelCache[input] = label
    return label
end

local function addSkillReasons(recipe, player, reasons)
    if not recipe or not recipe.getRequiredSkillCount then return end
    for i = 0, recipe:getRequiredSkillCount() - 1 do
        local skill = recipe:getRequiredSkill(i)
        if skill and skill.getPerk and skill.getLevel and skill:getPerk() then
            local hasSkill = true
            if CraftRecipeManager and CraftRecipeManager.hasPlayerRequiredSkill then
                hasSkill = CraftRecipeManager.hasPlayerRequiredSkill(skill, player)
            elseif player and player.getPerkLevel then
                hasSkill = player:getPerkLevel(skill:getPerk()) >= skill:getLevel()
            end
            if not hasSkill then
                table.insert(reasons, BCR_Utils.tr("UI_BCR_MissingSkill", "Missing skill") .. ": " .. tostring(skill:getPerk():getName()) .. " " .. tostring(skill:getLevel()))
            end
        end
    end
end

local function addLearningReasons(recipe, player, reasons)
    if not recipe or not recipe.needToBeLearn or not recipe:needToBeLearn() then return end
    local learned = true
    if CraftRecipeManager and CraftRecipeManager.hasPlayerLearnedRecipe then
        learned = CraftRecipeManager.hasPlayerLearnedRecipe(recipe, player)
    end
    if not learned then
        table.insert(reasons, BCR_Utils.tr("UI_BCR_MissingUnlock", "Recipe not learned"))
    end
end

local function addLightReasons(recipe, player, reasons)
    if not recipe or not recipe.canBeDoneInDark or recipe:canBeDoneInDark() then return end
    if player and player.tooDarkToRead and player:tooDarkToRead() then
        table.insert(reasons, BCR_Utils.tr("UI_BCR_MissingLight", "Too dark"))
    end
end

function BCR_Availability.inputLines(recipe)
    local lines = {}
    if not recipe or not recipe.getInputs then
        return lines
    end

    local inputs = recipe:getInputs()
    for i = 0, BCR_Utils.listSize(inputs) - 1 do
        local input = BCR_Utils.listGet(inputs, i)
        local amount, uses = inputAmount(input)
        local prefix = BCR_Utils.tr("UI_BCR_RequirementConsumes", "Consumes")
        if input and input.isKeep and input:isKeep() then
            prefix = BCR_Utils.tr("UI_BCR_RequirementKeeps", "Keeps")
        elseif input and input.isTool and input:isTool() then
            prefix = BCR_Utils.tr("UI_BCR_RequirementTool", "Tool")
        end
        local unit = uses and BCR_Utils.tr("UI_BCR_RequirementUses", "uses") or BCR_Utils.tr("UI_BCR_RequirementCount", "count")
        table.insert(lines, prefix .. ": " .. tostring(amount) .. " " .. unit .. " " .. inputLabel(input))
    end
    return lines
end

function BCR_Availability.inputSearchText(recipe)
    local parts = {}
    if not recipe or not recipe.getInputs then
        return ""
    end

    local inputs = recipe:getInputs()
    for i = 0, BCR_Utils.listSize(inputs) - 1 do
        local input = BCR_Utils.listGet(inputs, i)
        table.insert(parts, inputLabel(input))
        if input and input.getPossibleInputItems then
            local options = input:getPossibleInputItems()
            for index = 0, BCR_Utils.listSize(options) - 1 do
                local option = BCR_Utils.listGet(options, index)
                if option and option.getFullName then
                    table.insert(parts, BCR_Utils.safeString(option:getFullName(), ""))
                end
            end
        end
    end
    return table.concat(parts, " ")
end

function BCR_Availability.addCraftMissingInputReasons(recipe, logic, reasons)
    if not recipe or not recipe.getInputs or not logic or not logic.isInputSatisfied then
        return
    end

    local inputs = recipe:getInputs()
    for i = 0, BCR_Utils.listSize(inputs) - 1 do
        local input = BCR_Utils.listGet(inputs, i)
        if input and not logic:isInputSatisfied(input) then
            local required, uses = inputMaxAmount(input)
            local available = 0
            if logic.getInputCount then
                available = tonumber(logic:getInputCount(input)) or 0
            elseif logic.getInputUses then
                available = tonumber(logic:getInputUses(input)) or 0
            end
            local unit = uses and BCR_Utils.tr("UI_BCR_RequirementUses", "uses") or BCR_Utils.tr("UI_BCR_RequirementCount", "count")
            table.insert(reasons, BCR_Utils.tr("UI_BCR_MissingInput", "Missing") .. ": " .. inputLabel(input) .. " " .. tostring(available) .. "/" .. tostring(required) .. " " .. unit)
        end
    end
end

local function craftInputsSatisfied(recipe, logic)
    if not recipe or not recipe.getInputs then return true end
    if not logic or not logic.isInputSatisfied then return false end

    local inputs = recipe:getInputs()
    for i = 0, BCR_Utils.listSize(inputs) - 1 do
        local input = BCR_Utils.listGet(inputs, i)
        if input and not logic:isInputSatisfied(input) then
            return false
        end
    end
    return true
end

function BCR_Availability.craftStatus(recipe, player, logic, containerCount)
    local status = {
        available = false,
        materialsAvailable = false,
        count = 0,
        reasons = {},
        unknown = false,
        containerCount = containerCount or 0,
    }
    if not recipe or not player or not logic or not logic.setRecipe then
        status.unknown = true
        table.insert(status.reasons, BCR_Utils.tr("UI_BCR_StatusUnknown", "Availability unknown"))
        return status
    end

    logic:setRecipe(recipe)
    if logic.autoPopulateInputs then
        logic:autoPopulateInputs()
    end
    status.materialsAvailable = craftInputsSatisfied(recipe, logic)
    if logic.canPerformCurrentRecipe then
        status.available = logic:canPerformCurrentRecipe() == true
    end
    if logic.getPossibleCraftCount then
        local count = logic:getPossibleCraftCount(false)
        status.count = tonumber(count) or 0
    end

    addLearningReasons(recipe, player, status.reasons)
    addSkillReasons(recipe, player, status.reasons)
    addLightReasons(recipe, player, status.reasons)

    if recipe.isAnySurfaceCraft and recipe:isAnySurfaceCraft() and not status.available then
        table.insert(status.reasons, BCR_Utils.tr("UI_BCR_MissingSurfaceOrStation", "Missing surface, station, or context"))
    end
    if not status.available and not status.materialsAvailable then
        BCR_Availability.addCraftMissingInputReasons(recipe, logic, status.reasons)
    end
    if not status.available and #status.reasons == 0 then
        table.insert(status.reasons, BCR_Utils.tr("UI_BCR_MissingCraftInputs", "Missing inputs or context"))
    end
    return status
end

local function buildAvailableSet(player)
    local result = {
        available = {},
        items = {},
    }
    if not player or not ISBuildIsoEntity or not ISBuildIsoEntity.GetBuildableEntities then
        return result
    end

    local infos, items = ISBuildIsoEntity.GetBuildableEntities(player)
    result.items = items or {}
    for _, info in ipairs(infos or {}) do
        result.available[info] = true
    end
    return result
end

local function addBuildMissingInputs(info, items, reasons)
    if not info or not info.getRecipe or not info:getRecipe() or not info:getRecipe().getCraftRecipe then
        return
    end
    local recipe = info:getRecipe():getCraftRecipe()
    if not recipe or not recipe.getInputs then return end

    local inputs = recipe:getInputs()
    for i = 0, BCR_Utils.listSize(inputs) - 1 do
        local input = BCR_Utils.listGet(inputs, i)
        local amount, uses = inputAmount(input)
        local available = 0
        if input and input.getPossibleInputItems then
            local options = input:getPossibleInputItems()
            for index = 0, BCR_Utils.listSize(options) - 1 do
                local option = BCR_Utils.listGet(options, index)
                local fullName = option and option.getFullName and option:getFullName() or nil
                local found = fullName and items and items[fullName] or nil
                if found then
                    available = available + (uses and (found.uses or 0) or (found.count or 0))
                end
            end
        end
        if available < amount then
            table.insert(reasons, BCR_Utils.tr("UI_BCR_MissingInput", "Missing") .. ": " .. inputLabel(input) .. " " .. tostring(available) .. "/" .. tostring(amount))
        end
    end
end

local function buildInputsSatisfiedFromItems(info, items)
    if not info or not info.getRecipe or not info:getRecipe() or not info:getRecipe().getCraftRecipe then
        return false
    end
    local recipe = info:getRecipe():getCraftRecipe()
    if not recipe or not recipe.getInputs then return true end

    local inputs = recipe:getInputs()
    for i = 0, BCR_Utils.listSize(inputs) - 1 do
        local input = BCR_Utils.listGet(inputs, i)
        local amount, uses = inputAmount(input)
        local available = 0
        if input and input.getPossibleInputItems then
            local options = input:getPossibleInputItems()
            for index = 0, BCR_Utils.listSize(options) - 1 do
                local option = BCR_Utils.listGet(options, index)
                local fullName = option and option.getFullName and option:getFullName() or nil
                local found = fullName and items and items[fullName] or nil
                if found then
                    available = available + (uses and (found.uses or 0) or (found.count or 0))
                end
            end
        end
        if available < amount then
            return false
        end
    end
    return true
end

function BCR_Availability.buildStatus(info, player, buildSet)
    local status = {
        available = false,
        materialsAvailable = false,
        count = 0,
        reasons = {},
        unknown = false,
    }
    if not info or not player or not buildSet then
        status.unknown = true
        table.insert(status.reasons, BCR_Utils.tr("UI_BCR_StatusUnknown", "Availability unknown"))
        return status
    end

    status.materialsAvailable = buildInputsSatisfiedFromItems(info, buildSet.items)
    status.available = buildSet.available[info] == true
    status.count = status.available and 1 or 0
    if not status.available then
        if not status.materialsAvailable then
            addBuildMissingInputs(info, buildSet.items, status.reasons)
        end
        if #status.reasons == 0 then
            table.insert(status.reasons, BCR_Utils.tr("UI_BCR_MissingBuildInputs", "Missing build inputs or context"))
        end
    end
    return status
end

local function newEvaluationContext(player, isoObject, containers)
    local startedAt = BCR_Utils.nowMs()
    containers = containers
        or (BCR_ContainerSearch and BCR_ContainerSearch.getVisibleContainers and BCR_ContainerSearch.getVisibleContainers(player))
        or (BCR_ContainerSearch and BCR_ContainerSearch.getContainers and BCR_ContainerSearch.getContainers(player))
        or nil
    local context = {
        containers = containers,
        containerCount = BCR_ContainerSearch and BCR_ContainerSearch.count and BCR_ContainerSearch.count(containers) or 0,
        craftLogic = nil,
        buildLogic = nil,
        buildSet = nil,
    }

    if player and HandcraftLogic and HandcraftLogic.new then
        context.craftLogic = HandcraftLogic.new(player, nil, isoObject)
        if containers and context.craftLogic.setContainers then
            context.craftLogic:setContainers(containers)
        end
    end

    if player and BuildLogic and BuildLogic.new then
        context.buildLogic = BuildLogic.new(player, nil, isoObject)
        if containers and context.buildLogic.setContainers then
            context.buildLogic:setContainers(containers)
        end
    end

    if not context.buildLogic then
        context.buildSet = buildAvailableSet(player)
    end
    BCR_Debug.timing("Availability context", startedAt, "(" .. tostring(context.containerCount or 0) .. " containers)")
    return context
end

function BCR_Availability.newContext(player, isoObject, containers)
    return newEvaluationContext(player, isoObject, containers)
end

local function craftRecipeForBuildInfo(info)
    if not info or not info.getRecipe or not info:getRecipe() then return nil end
    local buildRecipe = info:getRecipe()
    if buildRecipe.getCraftRecipe then
        return buildRecipe:getCraftRecipe()
    end
    return nil
end

local function buildStatusWithLogic(info, player, logic, containerCount)
    local status = {
        available = false,
        materialsAvailable = false,
        count = 0,
        reasons = {},
        unknown = false,
        containerCount = containerCount or 0,
    }
    local craftRecipe = craftRecipeForBuildInfo(info)
    if not info or not player or not logic or not craftRecipe or not logic.setRecipe then
        status.unknown = true
        table.insert(status.reasons, BCR_Utils.tr("UI_BCR_StatusUnknown", "Availability unknown"))
        return status
    end

    logic:setRecipe(craftRecipe)
    if logic.autoPopulateInputs then
        logic:autoPopulateInputs()
    end
    status.materialsAvailable = craftInputsSatisfied(craftRecipe, logic)
    if logic.canPerformCurrentRecipe then
        status.available = logic:canPerformCurrentRecipe() == true
    end
    if player.isBuildCheat and player:isBuildCheat() then
        status.available = true
    end
    if logic.isCraftActionInProgress and logic:isCraftActionInProgress() then
        status.available = false
    end

    status.count = status.available and 1 or 0
    if not status.available and not status.materialsAvailable then
        BCR_Availability.addCraftMissingInputReasons(craftRecipe, logic, status.reasons)
    end
    if not status.available then
        if #status.reasons == 0 then
            table.insert(status.reasons, BCR_Utils.tr("UI_BCR_MissingBuildInputs", "Missing build inputs or context"))
        end
    end
    return status
end

function BCR_Availability.evaluateItem(item, player, isoObject, context)
    if not item then return nil end
    context = context or newEvaluationContext(player, isoObject)
    if item.kind == "craft" then
        return BCR_Availability.craftStatus(item.raw, player, context.craftLogic, context.containerCount)
    end
    if item.kind == "build" then
        local status = context.buildLogic and buildStatusWithLogic(item.raw, player, context.buildLogic, context.containerCount)
            or BCR_Availability.buildStatus(item.raw, player, context.buildSet)
        if status then
            status.containerCount = status.containerCount or context.containerCount
        end
        return status
    end
    return nil
end

function BCR_Availability.evaluate(player, craftItems, buildItems, isoObject)
    local startedAt = BCR_Utils.nowMs()
    local result = {
        craft = {},
        build = {},
        readyCraft = 0,
        readyBuild = 0,
    }

    local context = newEvaluationContext(player, isoObject)

    for _, item in ipairs(craftItems or {}) do
        local status = BCR_Availability.evaluateItem(item, player, isoObject, context)
        result.craft[item.raw] = status
        if status.available then
            result.readyCraft = result.readyCraft + 1
        end
    end

    for _, item in ipairs(buildItems or {}) do
        local status = BCR_Availability.evaluateItem(item, player, isoObject, context)
        result.build[item.raw] = status
        if status.available then
            result.readyBuild = result.readyBuild + 1
        end
    end

    BCR_Debug.timing("Availability evaluation", startedAt, "(" .. tostring(result.readyCraft) .. " craft, " .. tostring(result.readyBuild) .. " build ready)")
    return result
end

return BCR_Availability
