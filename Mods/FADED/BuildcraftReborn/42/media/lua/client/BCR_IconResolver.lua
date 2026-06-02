if isServer() then return end

require "BCR_Utils"

BCR_IconResolver = BCR_IconResolver or {}
local CACHE_VERSION = 2
if BCR_IconResolver._cacheVersion ~= CACHE_VERSION then
    BCR_IconResolver._cache = {}
    BCR_IconResolver._cacheVersion = CACHE_VERSION
else
    BCR_IconResolver._cache = BCR_IconResolver._cache or {}
end

local function cache(key, texture)
    if key and key ~= "" then
        BCR_IconResolver._cache[key] = texture or false
    end
    return texture
end

local function cached(key)
    local value = key and BCR_IconResolver._cache[key]
    if value == false then return nil end
    return value
end

local function textureFromName(name)
    if not name or name == "" or not getTexture then return nil end
    local texture = getTexture(name)
    if texture then return texture end

    if string.sub(name, 1, 5) ~= "Item_" then
        texture = getTexture("Item_" .. name)
        if texture then return texture end
    end
    return nil
end

local function scriptManager()
    if ScriptManager and ScriptManager.instance then return ScriptManager.instance end
    if getScriptManager then return getScriptManager() end
    return nil
end

local function textureFromScriptItem(scriptItem)
    if not scriptItem then return nil end
    if scriptItem.getNormalTexture then
        local texture = scriptItem:getNormalTexture()
        if texture then return texture end
    end
    if scriptItem.getTexture then
        local texture = scriptItem:getTexture()
        if texture then return texture end
    end
    if scriptItem.getIcon then
        local icon = BCR_Utils.safeString(scriptItem:getIcon(), "")
        local texture = textureFromName(icon)
        if texture then return texture end
    end
    return nil
end

local function textureFromFullType(fullType)
    fullType = BCR_Utils.safeString(fullType, "")
    if fullType == "" then return nil end

    local manager = scriptManager()
    if manager and manager.getItem then
        local scriptItem = manager:getItem(fullType)
        local texture = textureFromScriptItem(scriptItem)
        if texture then return texture end
    end

    local bareName = fullType
    local dot = string.find(fullType, "%.")
    if dot then
        bareName = string.sub(fullType, dot + 1)
    end
    return textureFromName(bareName)
end

local function textureFromOutput(output)
    if not output then return nil end
    if type(output) == "string" then
        return textureFromFullType(output)
    end
    if output.getTexture then
        local texture = output:getTexture()
        if texture then return texture end
    end
    if output.getScriptItem then
        local texture = textureFromScriptItem(output:getScriptItem())
        if texture then return texture end
    end
    if output.getFullType then
        local texture = textureFromFullType(output:getFullType())
        if texture then return texture end
    end
    if output.getItemFullType then
        local texture = textureFromFullType(output:getItemFullType())
        if texture then return texture end
    end
    return nil
end

local function textureFromOutputList(list)
    if not list then return nil end
    for index = 0, BCR_Utils.listSize(list) - 1 do
        local texture = textureFromOutput(BCR_Utils.listGet(list, index))
        if texture then return texture end
    end
    return nil
end

local function textureFromRecipe(recipe)
    if not recipe then return nil end

    if recipe.getIconTexture then
        local texture = recipe:getIconTexture()
        if texture then return texture end
    end
    if recipe.getTexture then
        local texture = recipe:getTexture()
        if texture then return texture end
    end
    if recipe.getResultItem then
        local texture = textureFromOutput(recipe:getResultItem())
        if texture then return texture end
    end
    if recipe.getResult then
        local texture = textureFromOutput(recipe:getResult())
        if texture then return texture end
    end
    if recipe.getOutput then
        local texture = textureFromOutput(recipe:getOutput())
        if texture then return texture end
    end
    if recipe.getOutputs then
        local texture = textureFromOutputList(recipe:getOutputs())
        if texture then return texture end
    end
    if recipe.getResultItems then
        local texture = textureFromOutputList(recipe:getResultItems())
        if texture then return texture end
    end

    local inputs = recipe.getInputs and recipe:getInputs() or nil
    for i = 0, BCR_Utils.listSize(inputs) - 1 do
        local input = BCR_Utils.listGet(inputs, i)
        local options = input and input.getPossibleInputItems and input:getPossibleInputItems() or nil
        for optionIndex = 0, BCR_Utils.listSize(options) - 1 do
            local texture = textureFromScriptItem(BCR_Utils.listGet(options, optionIndex))
            if texture then return texture end
        end
    end
    return nil
end

local function textureFromSprite(spriteName)
    spriteName = BCR_Utils.safeString(spriteName, "")
    if spriteName == "" then return nil end

    local sprite = nil
    if getSprite then
        sprite = getSprite(spriteName)
    end
    if not sprite and IsoSpriteManager and IsoSpriteManager.instance and IsoSpriteManager.instance.getSprite then
        sprite = IsoSpriteManager.instance:getSprite(spriteName)
    end
    if sprite and sprite.getTexture then
        local texture = sprite:getTexture()
        if texture then return texture end
    end
    return textureFromName(spriteName)
end

local function textureFromFace(face)
    if not face or not face.getTileInfo then return nil end
    local width = face.getWidth and tonumber(face:getWidth()) or 1
    local height = face.getHeight and tonumber(face:getHeight()) or 1
    local layers = face.getzLayers and tonumber(face:getzLayers()) or 1
    width = math.max(1, width or 1)
    height = math.max(1, height or 1)
    layers = math.max(1, layers or 1)

    for z = 0, layers - 1 do
        for x = 0, width - 1 do
            for y = 0, height - 1 do
                local tileInfo = face:getTileInfo(x, y, z)
                local spriteName = tileInfo and tileInfo.getSpriteName and tileInfo:getSpriteName() or nil
                local texture = textureFromSprite(spriteName)
                if texture then return texture end
            end
        end
    end
    return nil
end

local function textureFromBuildFace(info)
    if not info or not info.getFace then return nil end
    for _, faceIndex in ipairs({ 1, 0, 3, 2 }) do
        local texture = textureFromFace(info:getFace(faceIndex))
        if texture then return texture end
    end
    return nil
end

function BCR_IconResolver.textureFor(row)
    if not row then return nil end
    local key = row.key or ""
    local existing = cached(key)
    if existing then return existing end
    if BCR_IconResolver._cache[key] == false then return nil end

    local texture = nil
    if row.kind == "build" then
        texture = textureFromBuildFace(row.raw)
        if not texture then
            texture = textureFromSprite(row.sprite)
        end
        if not texture and row.raw and row.raw.getMainSpriteNameUI then
            texture = textureFromSprite(row.raw:getMainSpriteNameUI())
        end
        if not texture and row.raw and row.raw.getSpriteName then
            texture = textureFromSprite(row.raw:getSpriteName())
        end
        if not texture and row.raw and row.raw.getName then
            texture = textureFromName(row.raw:getName())
        end
    else
        texture = textureFromRecipe(row.raw)
    end
    return cache(key, texture)
end

function BCR_IconResolver.invalidate(reason)
    BCR_IconResolver._cache = {}
    if BCR_Debug and BCR_Debug.log then
        BCR_Debug.log("Icon cache invalidated" .. (reason and (": " .. tostring(reason)) or ""))
    end
end

return BCR_IconResolver
