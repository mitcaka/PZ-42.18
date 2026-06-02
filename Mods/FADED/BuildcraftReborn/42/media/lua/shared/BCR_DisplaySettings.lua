-- Buildcraft Reborn display settings store.
-- Adapted from the Common Sense Reborn player preference pattern.

BCR_DisplaySettings = BCR_DisplaySettings or {}

local MODDATA_PREFIX = "BCRPref_"
local SANDBOX_TABLE = "BuildcraftReborn"

BCR_DisplaySettings.PREFS = {
    {
        key = "DebugLogging",
        sandboxKey = "DebugLogging",
        labelKey = "UI_BCR_Setting_DebugLogging",
        defaultValue = false,
    },
    {
        key = "CompactMode",
        sandboxKey = "CompactMode",
        labelKey = "UI_BCR_Setting_CompactMode",
        defaultValue = true,
    },
    {
        key = "TransparencyOnMouseout",
        sandboxKey = "TransparencyOnMouseout",
        labelKey = "UI_BCR_Setting_TransparencyOnMouseout",
        defaultValue = true,
    },
    {
        key = "ExpandedNearbyScan",
        sandboxKey = "ExpandedNearbyScan",
        labelKey = "UI_BCR_Setting_ExpandedNearbyScan",
        defaultValue = false,
    },
    {
        key = "DisplayScale",
        type = "number",
        labelKey = "UI_BCR_Setting_DisplayScale",
        defaultValue = 1.00,
        minValue = 0.75,
        maxValue = 1.35,
        step = 0.05,
    },
}

BCR_DisplaySettings._byKey = {}
for _, pref in ipairs(BCR_DisplaySettings.PREFS) do
    BCR_DisplaySettings._byKey[pref.key] = pref
end

BCR_DisplaySettings._overrides = {}

local function sandbox()
    return SandboxVars and SandboxVars[SANDBOX_TABLE] or {}
end

local function getModData()
    local player = getPlayer and getPlayer() or nil
    return player and player:getModData() or nil
end

local function prefType(pref)
    return pref and pref.type or "boolean"
end

local function clampNumber(pref, value)
    value = tonumber(value) or tonumber(pref.defaultValue) or 1
    local minValue = tonumber(pref.minValue) or value
    local maxValue = tonumber(pref.maxValue) or value
    if value < minValue then value = minValue end
    if value > maxValue then value = maxValue end
    return value
end

function BCR_DisplaySettings.getDefault(key)
    local pref = BCR_DisplaySettings._byKey[key]
    if not pref then return false end
    if prefType(pref) == "number" then
        local sb = sandbox()
        if pref.sandboxKey and sb[pref.sandboxKey] ~= nil then
            return clampNumber(pref, sb[pref.sandboxKey])
        end
        return clampNumber(pref, pref.defaultValue)
    end
    local sb = sandbox()
    if pref.sandboxKey and sb[pref.sandboxKey] ~= nil then
        return sb[pref.sandboxKey] == true
    end
    return pref.defaultValue == true
end

function BCR_DisplaySettings.getOverride(key)
    return BCR_DisplaySettings._overrides[key]
end

function BCR_DisplaySettings.get(key)
    local override = BCR_DisplaySettings.getOverride(key)
    local pref = BCR_DisplaySettings._byKey[key]
    if pref and prefType(pref) == "number" then
        if override ~= nil then return clampNumber(pref, override) end
        return BCR_DisplaySettings.getDefault(key)
    end
    if override ~= nil then return override == true end
    return BCR_DisplaySettings.getDefault(key)
end

function BCR_DisplaySettings.set(key, value)
    local pref = BCR_DisplaySettings._byKey[key]
    if not pref then return end
    if value == nil then
        BCR_DisplaySettings._overrides[key] = nil
    elseif prefType(pref) == "number" then
        BCR_DisplaySettings._overrides[key] = clampNumber(pref, value)
    else
        BCR_DisplaySettings._overrides[key] = value == true
    end

    local modData = getModData()
    if not modData then return end
    if value == nil then
        modData[MODDATA_PREFIX .. key] = nil
    elseif prefType(pref) == "number" then
        modData[MODDATA_PREFIX .. key] = clampNumber(pref, value)
    else
        modData[MODDATA_PREFIX .. key] = value == true
    end
end

function BCR_DisplaySettings.toggle(key)
    local pref = BCR_DisplaySettings._byKey[key]
    if pref and prefType(pref) ~= "boolean" then return BCR_DisplaySettings.get(key) end
    local nextValue = not BCR_DisplaySettings.get(key)
    BCR_DisplaySettings.set(key, nextValue)
    return nextValue
end

function BCR_DisplaySettings.adjust(key, direction)
    local pref = BCR_DisplaySettings._byKey[key]
    if not pref or prefType(pref) ~= "number" then return BCR_DisplaySettings.get(key) end
    local step = tonumber(pref.step) or 0.05
    local nextValue = BCR_DisplaySettings.get(key) + step * (tonumber(direction) or 0)
    BCR_DisplaySettings.set(key, nextValue)
    return BCR_DisplaySettings.get(key)
end

function BCR_DisplaySettings.reset(key)
    BCR_DisplaySettings.set(key, nil)
end

function BCR_DisplaySettings.load()
    BCR_DisplaySettings._overrides = {}
    local modData = getModData()
    if not modData then return end

    for _, pref in ipairs(BCR_DisplaySettings.PREFS) do
        local stored = modData[MODDATA_PREFIX .. pref.key]
        if stored ~= nil then
            if prefType(pref) == "number" then
                BCR_DisplaySettings._overrides[pref.key] = clampNumber(pref, stored)
            else
                BCR_DisplaySettings._overrides[pref.key] = stored == true
            end
        end
    end
end

return BCR_DisplaySettings
