if isServer() then return end

require "BCR_Utils"
require "BCR_Debug"
require "BCR_Availability"

BCR_BuildIndex = BCR_BuildIndex or {}
BCR_BuildIndex._items = BCR_BuildIndex._items or nil
BCR_BuildIndex._builtAt = BCR_BuildIndex._builtAt or 0
BCR_BuildIndex._buildGeneration = BCR_BuildIndex._buildGeneration or 0
BCR_BuildIndex._buildState = BCR_BuildIndex._buildState or nil
if BCR_BuildIndex._buildComplete == nil then
    BCR_BuildIndex._buildComplete = BCR_BuildIndex._items ~= nil
end

local DEFAULT_BUILD_BATCH_SIZE = 64

local function craftRecipeFor(info)
    if not info or not info.getRecipe or not info:getRecipe() then return nil end
    local recipe = info:getRecipe()
    if recipe.getCraftRecipe then
        return recipe:getCraftRecipe()
    end
    return nil
end

local INTERNAL_BUILD_CATEGORIES = {
    AutoRotate = true,
    CanBeDoneInDark = true,
    CanBeDoneFromFloor = true,
    EntityRecipe = true,
    Moveable = true,
}

local function recipeCategory(recipe)
    if recipe and recipe.getCategory then
        local category = BCR_Utils.displayLabel(recipe:getCategory(), "")
        if category ~= "" then return category end
    end
    return BCR_Utils.tr("UI_BCR_TabBuild", "Build")
end

local function buildCategory(info)
    if info and info.getRecipe and info:getRecipe() and info:getRecipe().getBuildCategory then
        local rawCategory = BCR_Utils.cleanLabel(info:getRecipe():getBuildCategory(), "")
        if rawCategory ~= "" and not INTERNAL_BUILD_CATEGORIES[rawCategory] then
            return BCR_Utils.displayLabel(rawCategory, BCR_Utils.tr("UI_BCR_TabBuild", "Build"))
        end
    end
    return recipeCategory(craftRecipeFor(info))
end

local function buildName(info)
    local recipe = craftRecipeFor(info)
    if recipe and recipe.getTranslationName then
        local name = BCR_Utils.displayLabel(recipe:getTranslationName(), "")
        if name ~= "" then return name end
    end
    if recipe and recipe.getName then
        local name = BCR_Utils.displayLabel(recipe:getName(), "")
        if name ~= "" then return name end
    end
    if info and info.getName then
        local name = BCR_Utils.displayLabel(info:getName(), "")
        if name ~= "" then return name end
    end
    return BCR_Utils.tr("UI_BCR_UnknownBuildable", "Unknown buildable")
end

local function buildId(info)
    if info and info.getName then
        return BCR_Utils.safeString(info:getName(), "")
    end
    local recipe = craftRecipeFor(info)
    if recipe and recipe.getName then
        return BCR_Utils.safeString(recipe:getName(), "")
    end
    return ""
end

local function spriteName(info)
    if info and info.getMainSpriteNameUI then
        return BCR_Utils.safeString(info:getMainSpriteNameUI(), "")
    end
    return ""
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
    local id = recipe and recipe.getName and BCR_Utils.safeString(recipe:getName(), "") or ""
    local prefix = string.match(id, "^([^%.]+)%.")
    if prefix and prefix ~= "" then
        return BCR_Utils.displayLabel(prefix, prefix)
    end
    return BCR_Utils.tr("UI_BCR_SourceUnknown", "Unknown")
end

local function buildSource(info)
    local source = recipeSource(craftRecipeFor(info))
    if source ~= BCR_Utils.tr("UI_BCR_SourceUnknown", "Unknown") then
        return source
    end
    local id = buildId(info)
    local prefix = string.match(id, "^([^%.]+)%.")
    if prefix and prefix ~= "" then
        return BCR_Utils.displayLabel(prefix, prefix)
    end
    return source
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
    local source = buildSource(item.raw)
    item.source = source
    item.sourceKey = BCR_Utils.lower(source)
    item.sourceResolved = true
    if source ~= "" then
        setSearchText(item, table.concat({ item.searchText or "", source }, " "))
    end
    return item.source, item.sourceKey
end

function BCR_BuildIndex.sourceForItem(item)
    return resolveSource(item)
end

function BCR_BuildIndex.describe(item, player, status)
    local info = item and item.raw or nil
    local recipe = craftRecipeFor(info)
    local lines = {}
    if status then
        if status.available then
            table.insert(lines, BCR_Utils.tr("UI_BCR_Status", "Status") .. ": " .. BCR_Utils.tr("UI_BCR_StatusReady", "Ready"))
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
    table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Type", "Type") .. ": " .. BCR_Utils.tr("UI_BCR_KindBuild", "Build"))
    table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Category", "Category") .. ": " .. BCR_Utils.safeString(item and item.category, "-"))
    local source = item and resolveSource(item) or ""
    if source ~= "" then
        table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Source", "Source") .. ": " .. source)
    end
    if item and item.id and item.id ~= "" and BCR_DisplaySettings and BCR_DisplaySettings.get and BCR_DisplaySettings.get("DebugLogging") then
        table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Id", "ID") .. ": " .. item.id)
    end
    local sprite = spriteName(info)
    if sprite ~= "" and BCR_DisplaySettings and BCR_DisplaySettings.get and BCR_DisplaySettings.get("DebugLogging") then
        table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Sprite", "Sprite") .. ": " .. sprite)
    end
    if recipe and recipe.getTranslationName then
        local name = BCR_Utils.displayLabel(recipe:getTranslationName(), "")
        if name ~= "" then
            table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Recipe", "Recipe") .. ": " .. name)
        end
    end
    if recipe and recipe.getTime then
        local time = recipe:getTime(player or getPlayer())
        if time then
            table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Time", "Time") .. ": " .. tostring(round(time / 10, 2)) .. "s")
        end
    end
    if recipe and recipe.getRequiredSkillCount and recipe:getRequiredSkillCount() > 0 then
        for i = 0, recipe:getRequiredSkillCount() - 1 do
            local skill = recipe:getRequiredSkill(i)
            if skill and skill.getPerk and skill.getLevel and skill:getPerk() then
                table.insert(lines, BCR_Utils.tr("UI_BCR_Detail_Skill", "Skill") .. ": " .. tostring(skill:getPerk():getName()) .. " " .. tostring(skill:getLevel()))
            end
        end
    end
    for _, line in ipairs(BCR_Availability.inputLines(recipe)) do
        table.insert(lines, line)
    end
    return lines
end

function BCR_BuildIndex.deepSearchText(item)
    if not item then return "" end
    if item.deepSearchText then return item.deepSearchText end
    local inputText = BCR_Availability.inputSearchText(craftRecipeFor(item.raw))
    item.deepSearchText = table.concat({ item.searchText or "", inputText }, " ")
    item.inputKey = BCR_Utils.lower(inputText)
    item.deepSearchKey = BCR_Utils.lower(item.deepSearchText)
    return item.deepSearchText
end

function BCR_BuildIndex.invalidate(reason)
    BCR_BuildIndex._items = nil
    BCR_BuildIndex._builtAt = 0
    BCR_BuildIndex._buildState = nil
    BCR_BuildIndex._buildComplete = false
    BCR_BuildIndex._buildGeneration = (BCR_BuildIndex._buildGeneration or 0) + 1
    BCR_Debug.log("Buildable index invalidated" .. (reason and (": " .. tostring(reason)) or ""))
end

local function addBuildItem(items, seenRaw, info)
    if not info then return false, false end
    if seenRaw[info] then return false, true end
    seenRaw[info] = true

    local label = buildName(info)
    local id = buildId(info)
    local category = buildCategory(info)
    local sprite = spriteName(info)
    local resultText = recipeResultText(craftRecipeFor(info))
    local item = {
        kind = "build",
        label = label,
        labelKey = BCR_Utils.lower(label),
        id = id,
        key = "build:" .. id,
        category = category,
        categoryKey = BCR_Utils.lower(category),
        source = nil,
        sourceKey = nil,
        sourceResolved = false,
        subtitle = category,
        raw = info,
        sprite = sprite,
        resultText = resultText,
        resultKey = BCR_Utils.lower(resultText),
    }
    setSearchText(item, table.concat({ label, id, category, sprite, resultText }, " "))
    table.insert(items, item)
    return true, false
end

local function startBuild(force)
    if BCR_BuildIndex._buildState and not force then
        return
    end
    if BCR_BuildIndex._items and BCR_BuildIndex._buildComplete and not force then
        return
    end

    local infos = nil
    if ISBuildIsoEntity and ISBuildIsoEntity.GetAllBuildableEntities then
        infos = ISBuildIsoEntity.GetAllBuildableEntities()
    end

    BCR_BuildIndex._items = {}
    BCR_BuildIndex._builtAt = 0
    BCR_BuildIndex._buildComplete = false
    BCR_BuildIndex._buildState = {
        startedAt = BCR_Utils.nowMs(),
        infos = infos,
        count = BCR_Utils.listSize(infos),
        index = 0,
        seenRaw = {},
        duplicateCount = 0,
    }
    BCR_BuildIndex._buildGeneration = (BCR_BuildIndex._buildGeneration or 0) + 1
end

function BCR_BuildIndex.ensureStarted(force)
    startBuild(force == true)
    return BCR_BuildIndex._items or {}
end

function BCR_BuildIndex.peek()
    return BCR_BuildIndex._items or {}
end

function BCR_BuildIndex.isReady()
    return BCR_BuildIndex._buildComplete == true
end

function BCR_BuildIndex.isBuilding()
    return BCR_BuildIndex._buildState ~= nil
end

function BCR_BuildIndex.processBuild(maxRows)
    local state = BCR_BuildIndex._buildState
    if not state then
        return 0, BCR_BuildIndex._buildComplete == true
    end

    local limit = math.max(1, tonumber(maxRows) or DEFAULT_BUILD_BATCH_SIZE)
    local processed = 0
    while state.index < state.count and processed < limit do
        local _, duplicate = addBuildItem(BCR_BuildIndex._items, state.seenRaw, BCR_Utils.listGet(state.infos, state.index))
        if duplicate then
            state.duplicateCount = state.duplicateCount + 1
        end
        state.index = state.index + 1
        processed = processed + 1
    end

    if processed > 0 then
        BCR_BuildIndex._buildGeneration = (BCR_BuildIndex._buildGeneration or 0) + 1
    end

    if state.index >= state.count then
        table.sort(BCR_BuildIndex._items, BCR_Utils.sortByLabel)
        BCR_BuildIndex._builtAt = BCR_Utils.nowMs()
        BCR_BuildIndex._buildState = nil
        BCR_BuildIndex._buildComplete = true
        BCR_BuildIndex._buildGeneration = (BCR_BuildIndex._buildGeneration or 0) + 1
        BCR_Debug.timing("Buildable index build", state.startedAt, "(" .. tostring(#(BCR_BuildIndex._items or {})) .. " buildables, " .. tostring(state.duplicateCount or 0) .. " dupes skipped)")
    end

    return processed, BCR_BuildIndex._buildComplete == true
end

function BCR_BuildIndex.build(force)
    if BCR_BuildIndex._items and BCR_BuildIndex._buildComplete and not force then
        return BCR_BuildIndex._items
    end

    BCR_BuildIndex.ensureStarted(force == true)
    while BCR_BuildIndex._buildState do
        BCR_BuildIndex.processBuild(512)
    end
    return BCR_BuildIndex._items or {}
end

function BCR_BuildIndex.search(query, force)
    local source = BCR_BuildIndex.build(force)
    local terms = BCR_Utils.queryTerms(query)
    local results = {}
    for _, item in ipairs(source) do
        if BCR_Utils.matchesQueryTermsLower(item.searchKey, terms) then
            table.insert(results, item)
        end
    end
    return results
end

return BCR_BuildIndex
