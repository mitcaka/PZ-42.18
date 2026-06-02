if isServer() then return end

require "BCR_Utils"
require "BCR_Debug"
require "BCR_Availability"

BCR_RecipeIndex = BCR_RecipeIndex or {}
BCR_RecipeIndex._items = BCR_RecipeIndex._items or nil
BCR_RecipeIndex._builtAt = BCR_RecipeIndex._builtAt or 0
BCR_RecipeIndex._buildGeneration = BCR_RecipeIndex._buildGeneration or 0
BCR_RecipeIndex._buildState = BCR_RecipeIndex._buildState or nil
if BCR_RecipeIndex._buildComplete == nil then
    BCR_RecipeIndex._buildComplete = BCR_RecipeIndex._items ~= nil
end

local DEFAULT_BUILD_BATCH_SIZE = 64

local function getScriptManagerInstance()
    if ScriptManager and ScriptManager.instance then
        return ScriptManager.instance
    end
    if getScriptManager then
        return getScriptManager()
    end
    return nil
end

local function recipeId(recipe)
    if recipe and recipe.getName then
        return BCR_Utils.safeString(recipe:getName(), "")
    end
    return ""
end

local function recipeName(recipe)
    local id = recipeId(recipe)
    if recipe and recipe.getTranslationName then
        local name = BCR_Utils.displayLabel(recipe:getTranslationName(), "")
        if name ~= "" and name ~= id then return name end
    end
    if recipe and recipe.getName then
        local name = BCR_Utils.displayLabel(recipe:getName(), "")
        if name ~= "" then return name end
    end
    return BCR_Utils.tr("UI_BCR_UnknownRecipe", "Unknown recipe")
end

local function recipeCategory(recipe)
    if recipe and recipe.getCategory then
        return BCR_Utils.displayLabel(recipe:getCategory(), BCR_Utils.tr("UI_BCR_TabCraft", "Craft"))
    end
    return BCR_Utils.tr("UI_BCR_TabCraft", "Craft")
end

local function recipeTags(recipe)
    if not recipe or not recipe.getTags then return "" end
    local tags = recipe:getTags()
    local count = BCR_Utils.listSize(tags)
    local values = {}
    for i = 0, count - 1 do
        table.insert(values, BCR_Utils.safeString(BCR_Utils.listGet(tags, i), ""))
    end
    return table.concat(values, ", ")
end

local function recipeSource(recipe)
    local module = recipe and recipe.getModule and recipe:getModule() or nil
    if module then
        local rawName = module.getName and module:getName() or (type(module) == "string" and module or nil)
        local name = BCR_Utils.displayLabel(rawName, "")
        if name ~= "" then return name end
    end
    if recipe and recipe.getModuleName then
        local name = BCR_Utils.displayLabel(recipe:getModuleName(), "")
        if name ~= "" then return name end
    end
    local id = recipeId(recipe)
    local prefix = string.match(id, "^([^%.]+)%.")
    if prefix and prefix ~= "" then
        return BCR_Utils.displayLabel(prefix, prefix)
    end
    return BCR_Utils.tr("UI_BCR_SourceUnknown", "Unknown")
end

local function outputTextFromValue(value, parts)
    if not value then return end
    if type(value) == "string" then
        table.insert(parts, value)
        return
    end
    if value.getDisplayName then table.insert(parts, BCR_Utils.safeString(value:getDisplayName(), "")) end
    if value.getFullType then table.insert(parts, BCR_Utils.safeString(value:getFullType(), "")) end
    if value.getItemFullType then table.insert(parts, BCR_Utils.safeString(value:getItemFullType(), "")) end
    if value.getFullName then table.insert(parts, BCR_Utils.safeString(value:getFullName(), "")) end
    if value.getName then table.insert(parts, BCR_Utils.safeString(value:getName(), "")) end
    -- Some B42 OutputScript-like values expose getItem(index), not getItem().
    if value.getScriptItem then outputTextFromValue(value:getScriptItem(), parts) end
end

local function outputTextFromList(list, parts)
    if not list then return end
    for index = 0, BCR_Utils.listSize(list) - 1 do
        outputTextFromValue(BCR_Utils.listGet(list, index), parts)
    end
end

local function recipeResultText(recipe)
    local parts = {}
    if not recipe then return "" end
    if recipe.getResultItem then outputTextFromValue(recipe:getResultItem(), parts) end
    if recipe.getResult then outputTextFromValue(recipe:getResult(), parts) end
    if recipe.getOutput then outputTextFromValue(recipe:getOutput(), parts) end
    if recipe.getOutputs then outputTextFromList(recipe:getOutputs(), parts) end
    if recipe.getResultItems then outputTextFromList(recipe:getResultItems(), parts) end
    return table.concat(parts, " ")
end

local function setSearchText(item, text)
    text = BCR_Utils.safeString(text, "")
    item.searchText = text
    item.searchKey = BCR_Utils.lower(text)
end

local function resolveSource(item)
    if not item then return "", "" end
    if item.sourceResolved then
        return item.source or "", item.sourceKey or ""
    end
    local source = recipeSource(item.raw)
    item.source = source
    item.sourceKey = BCR_Utils.lower(source)
    item.sourceResolved = true
    if source ~= "" then
        setSearchText(item, table.concat({ item.searchText or "", source }, " "))
    end
    return item.source, item.sourceKey
end

function BCR_RecipeIndex.sourceForItem(item)
    return resolveSource(item)
end

function BCR_RecipeIndex.describe(item, player, status)
    local recipe = item and item.raw or nil
    local lines = {}
    if status then
        if status.available then
            table.insert(lines, BCR_Utils.tr("UI_BCR_Status", "Status") .. ": " .. BCR_Utils.tr("UI_BCR_StatusReady", "Ready") .. " x" .. tostring(status.count or 1))
        else
            table.insert(lines, BCR_Utils.tr("UI_BCR_Status", "Status") .. ": " .. BCR_Utils.tr("UI_BCR_StatusBlocked", "Blocked"))
            for _, reason in ipairs(status.reasons or {}) do
                table.insert(lines, reason)
            end
        end
        if not status.unknown and status.materialsAvailable ~= nil then
            local materialText = status.materialsAvailable and BCR_Utils.tr("UI_BCR_MaterialsReady", "Ready") or BCR_Utils.tr("UI_BCR_MaterialsMissing", "Missing")
            table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Materials", "Materials") .. ": " .. materialText)
        end
        if status.containerCount and status.containerCount > 1 then
            table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_MaterialScope", "Material scope") .. ": " .. tostring(status.containerCount) .. " " .. BCR_Utils.tr("UI_BCR_Detail_Containers", "containers"))
        end
    end
    table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Type", "Type") .. ": " .. BCR_Utils.tr("UI_BCR_KindCraft", "Craft"))
    table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Category", "Category") .. ": " .. BCR_Utils.safeString(item and item.category, "-"))
    local source = item and resolveSource(item) or ""
    if source ~= "" then
        table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Source", "Source") .. ": " .. source)
    end
    if item and item.id and item.id ~= "" and BCR_DisplaySettings and BCR_DisplaySettings.get and BCR_DisplaySettings.get("DebugLogging") then
        table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Id", "ID") .. ": " .. item.id)
    end
    if recipe and recipe.getTime then
        local time = recipe:getTime(player or getPlayer())
        if time then
            table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Time", "Time") .. ": " .. tostring(round(time / 10, 2)) .. "s")
        end
    end
    if recipe and recipe.isAnySurfaceCraft and recipe:isAnySurfaceCraft() then
        table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Surface", "Surface") .. ": " .. BCR_Utils.tr("IGUI_Yes", "Yes"))
    end
    if recipe and recipe.isInHandCraftCraft and recipe:isInHandCraftCraft() then
        table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Surface", "Surface") .. ": " .. BCR_Utils.tr("IGUI_No", "No"))
    end
    if recipe and recipe.getRequiredSkillCount and recipe:getRequiredSkillCount() > 0 then
        for i = 0, recipe:getRequiredSkillCount() - 1 do
            local skill = recipe:getRequiredSkill(i)
            if skill and skill.getPerk and skill.getLevel and skill:getPerk() then
                table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Skill", "Skill") .. ": " .. tostring(skill:getPerk():getName()) .. " " .. tostring(skill:getLevel()))
            end
        end
    end
    local tags = recipeTags(recipe)
    if tags ~= "" then
        table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Tags", "Tags") .. ": " .. tags)
    end
    if recipe and recipe.getTooltip and recipe:getTooltip() then
        local note = BCR_Utils.displayLabel(BCR_Utils.tr(recipe:getTooltip(), recipe:getTooltip()), "")
        if note ~= "" then
            table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Note", "Note") .. ": " .. note)
        end
    end
    for _, line in ipairs(BCR_Availability.inputLines(recipe)) do
        table.insert(lines, line)
    end
    return lines
end

function BCR_RecipeIndex.deepSearchText(item)
    if not item then return "" end
    if item.deepSearchText then return item.deepSearchText end
    local inputText = BCR_Availability.inputSearchText(item.raw)
    item.deepSearchText = table.concat({ item.searchText or "", inputText }, " ")
    item.inputKey = BCR_Utils.lower(inputText)
    item.deepSearchKey = BCR_Utils.lower(item.deepSearchText)
    return item.deepSearchText
end

function BCR_RecipeIndex.invalidate(reason)
    BCR_RecipeIndex._items = nil
    BCR_RecipeIndex._builtAt = 0
    BCR_RecipeIndex._buildState = nil
    BCR_RecipeIndex._buildComplete = false
    BCR_RecipeIndex._buildGeneration = (BCR_RecipeIndex._buildGeneration or 0) + 1
    BCR_Debug.log("Recipe index invalidated" .. (reason and (": " .. tostring(reason)) or ""))
end

local function addRecipeItem(items, seenRaw, recipe)
    if not recipe then return false, false end
    if seenRaw[recipe] then return false, true end
    seenRaw[recipe] = true

    local label = recipeName(recipe)
    local id = recipeId(recipe)
    local category = recipeCategory(recipe)
    local tags = recipeTags(recipe)
    local resultText = recipeResultText(recipe)
    local item = {
        kind = "craft",
        label = label,
        labelKey = BCR_Utils.lower(label),
        id = id,
        key = "craft:" .. id,
        category = category,
        categoryKey = BCR_Utils.lower(category),
        source = nil,
        sourceKey = nil,
        sourceResolved = false,
        subtitle = category,
        raw = recipe,
        resultText = resultText,
        resultKey = BCR_Utils.lower(resultText),
    }
    setSearchText(item, table.concat({ label, id, category, tags, resultText }, " "))
    table.insert(items, item)
    return true, false
end

local function startBuild(force)
    if BCR_RecipeIndex._buildState and not force then
        return
    end
    if BCR_RecipeIndex._items and BCR_RecipeIndex._buildComplete and not force then
        return
    end

    local manager = getScriptManagerInstance()
    local recipes = manager and manager.getAllCraftRecipes and manager:getAllCraftRecipes() or nil
    BCR_RecipeIndex._items = {}
    BCR_RecipeIndex._builtAt = 0
    BCR_RecipeIndex._buildComplete = false
    BCR_RecipeIndex._buildState = {
        startedAt = BCR_Utils.nowMs(),
        recipes = recipes,
        count = BCR_Utils.listSize(recipes),
        index = 0,
        seenRaw = {},
        duplicateCount = 0,
    }
    BCR_RecipeIndex._buildGeneration = (BCR_RecipeIndex._buildGeneration or 0) + 1
end

function BCR_RecipeIndex.ensureStarted(force)
    startBuild(force == true)
    return BCR_RecipeIndex._items or {}
end

function BCR_RecipeIndex.peek()
    return BCR_RecipeIndex._items or {}
end

function BCR_RecipeIndex.isReady()
    return BCR_RecipeIndex._buildComplete == true
end

function BCR_RecipeIndex.isBuilding()
    return BCR_RecipeIndex._buildState ~= nil
end

function BCR_RecipeIndex.processBuild(maxRows)
    local state = BCR_RecipeIndex._buildState
    if not state then
        return 0, BCR_RecipeIndex._buildComplete == true
    end

    local limit = math.max(1, tonumber(maxRows) or DEFAULT_BUILD_BATCH_SIZE)
    local processed = 0
    while state.index < state.count and processed < limit do
        local _, duplicate = addRecipeItem(BCR_RecipeIndex._items, state.seenRaw, BCR_Utils.listGet(state.recipes, state.index))
        if duplicate then
            state.duplicateCount = state.duplicateCount + 1
        end
        state.index = state.index + 1
        processed = processed + 1
    end

    if processed > 0 then
        BCR_RecipeIndex._buildGeneration = (BCR_RecipeIndex._buildGeneration or 0) + 1
    end

    if state.index >= state.count then
        table.sort(BCR_RecipeIndex._items, BCR_Utils.sortByLabel)
        BCR_RecipeIndex._builtAt = BCR_Utils.nowMs()
        BCR_RecipeIndex._buildState = nil
        BCR_RecipeIndex._buildComplete = true
        BCR_RecipeIndex._buildGeneration = (BCR_RecipeIndex._buildGeneration or 0) + 1
        BCR_Debug.timing("Recipe index build", state.startedAt, "(" .. tostring(#(BCR_RecipeIndex._items or {})) .. " recipes, " .. tostring(state.duplicateCount or 0) .. " dupes skipped)")
    end

    return processed, BCR_RecipeIndex._buildComplete == true
end

function BCR_RecipeIndex.build(force)
    if BCR_RecipeIndex._items and BCR_RecipeIndex._buildComplete and not force then
        return BCR_RecipeIndex._items
    end

    BCR_RecipeIndex.ensureStarted(force == true)
    while BCR_RecipeIndex._buildState do
        BCR_RecipeIndex.processBuild(512)
    end
    return BCR_RecipeIndex._items or {}
end

function BCR_RecipeIndex.search(query, force)
    local source = BCR_RecipeIndex.build(force)
    local terms = BCR_Utils.queryTerms(query)
    local results = {}
    for _, item in ipairs(source) do
        if BCR_Utils.matchesQueryTermsLower(item.searchKey, terms) then
            table.insert(results, item)
        end
    end
    return results
end

return BCR_RecipeIndex
