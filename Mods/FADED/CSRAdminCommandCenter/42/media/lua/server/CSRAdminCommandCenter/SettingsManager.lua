require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/AdminAccess"
require "CSRAdminCommandCenter/Persistence"
require "CSRAdminCommandCenter/Data/Schemas"
require "CSRAdminCommandCenter/Utils/Time"

local ACC = CSRAdminCommandCenter
ACC.SettingsManager = ACC.SettingsManager or {}

local Settings = ACC.SettingsManager
local Keys = ACC.Schemas.Keys

Settings.definitions = {
    { key = "EnableCommandCenter", category = "Main", label = "Enable command center", type = "boolean", default = true, live = true,
        description = "Allows command-ranked players to open and use ACC." },
    { key = "MinimumAccessLevel", category = "Main", label = "Minimum command rank", type = "enum", default = 4, live = true,
        values = { [1] = "Admin only", [2] = "Moderator and above", [3] = "Overseer and above", [4] = "GM and above", [5] = "Observer and above" },
        description = "Lowest command rank allowed to control ACC." },
    { key = "AllowObserverReadOnly", category = "Main", label = "Observer read-only", type = "boolean", default = false, live = true,
        description = "Allows Observer accounts to view ACC without control/export actions." },
    { key = "MaxRowsPerPage", category = "Main", label = "Rows per page", type = "integer", min = 10, max = 200, default = 50, live = true,
        description = "Maximum claim rows returned to clients per page." },

    { key = "EnableVehicleMovementTracking", category = "Tracking", label = "Vehicle movement tracking", type = "boolean", default = false, live = true,
        description = "Enables throttled claimed-vehicle movement logging." },
    { key = "VehicleTrackingIntervalMinutes", category = "Tracking", label = "Vehicle tracking interval", type = "integer", min = 1, max = 60, default = 5, live = true,
        description = "Minutes between movement tracking checks." },
    { key = "VehicleMovementThresholdTiles", category = "Tracking", label = "Movement threshold tiles", type = "integer", min = 1, max = 1000, default = 25, live = true,
        description = "Minimum tile distance before movement is logged." },
    { key = "PadlockScanTileCap", category = "Tracking", label = "Padlock scan tile cap", type = "integer", min = 100, max = 20000, default = 2500, live = true,
        description = "Maximum loaded claim-area tiles scanned for CSR padlocks." },
    { key = "PadlockScanMaxZ", category = "Tracking", label = "Padlock scan max Z", type = "integer", min = 0, max = 7, default = 3, live = true,
        description = "Highest Z level checked for CSR padlocked containers." },

    { key = "EnableVehicleClaimAuthoritySnapshot", category = "Authority", label = "Claim authority snapshot", type = "boolean", default = true, live = true,
        description = "Stores server-side snapshots of CSR vehicle claim rows." },

    { key = "DebugLogMaxEntries", category = "Debug", label = "Debug tail max entries", type = "integer", min = 50, max = 5000, default = 500, live = true,
        description = "Maximum recent debug entries kept in memory." },
    { key = "MaxMapMarkers", category = "Map", label = "Map marker cap", type = "integer", min = 5, max = 250, default = 50, live = true,
        description = "Maximum claimed vehicle markers for future marker rendering." },
}

Settings.definitionMap = Settings.definitionMap or nil

local function definitionMap()
    if Settings.definitionMap then return Settings.definitionMap end
    local map = {}
    for i = 1, #Settings.definitions do
        map[Settings.definitions[i].key] = Settings.definitions[i]
    end
    Settings.definitionMap = map
    return map
end

local function state()
    local s = ACC.Persistence.stateTable(Keys.SettingsState)
    s.values = s.values or {}
    return s
end

local function sandbox()
    if SandboxVars then
        SandboxVars.CSRAdminCommandCenter = SandboxVars.CSRAdminCommandCenter or {}
        return SandboxVars.CSRAdminCommandCenter
    end
    return {}
end

local function boolValue(value)
    if value == false or value == 0 or value == "false" or value == "0" or value == "No" or value == "no" then
        return false
    end
    return true
end

local function enumValue(def, value)
    local n = tonumber(value)
    if n and def.values[n] then return n end
    local text = string.lower(tostring(value or ""))
    if text == "" then return tonumber(def.default) or 1 end
    for key, label in pairs(def.values or {}) do
        local labelText = string.lower(tostring(label or ""))
        if text == labelText or string.find(labelText, text, 1, true) then return tonumber(key) or def.default end
    end
    return tonumber(def.default) or 1
end

local function normalize(def, value)
    if not def then return nil end
    if def.type == "boolean" then return boolValue(value) end
    if def.type == "enum" then return enumValue(def, value) end
    if def.type == "integer" then
        return math.floor(ACC.clampNumber(value, def.min, def.max, def.default))
    end
    return tostring(value or "")
end

local function currentValue(def)
    local sv = sandbox()
    if sv[def.key] ~= nil then return normalize(def, sv[def.key]) end
    return normalize(def, def.default)
end

local function valueText(def, value)
    if def.type == "boolean" then return value and "On" or "Off" end
    if def.type == "enum" then return tostring(value) .. " - " .. tostring(def.values and def.values[value] or "") end
    return tostring(value)
end

local function optionRow(def)
    local value = currentValue(def)
    return {
        key = def.key,
        category = def.category,
        label = def.label,
        type = def.type,
        value = value,
        valueText = valueText(def, value),
        default = def.default,
        defaultText = valueText(def, normalize(def, def.default)),
        min = def.min,
        max = def.max,
        values = def.values,
        description = def.description,
        live = def.live == true,
    }
end

function Settings.snapshot()
    local rows = {}
    for i = 1, #Settings.definitions do
        rows[#rows + 1] = optionRow(Settings.definitions[i])
    end
    local s = state()
    return {
        rows = rows,
        updatedBy = tostring(s.updatedBy or ""),
        updatedAt = tonumber(s.updatedAt) or 0,
        updatedAtText = tostring(s.updatedAtText or ""),
        persisted = s.values or {},
    }
end

function Settings.applyPersisted()
    local s = state()
    local sv = sandbox()
    local defs = definitionMap()
    for key, value in pairs(s.values or {}) do
        local def = defs[key]
        if def then sv[key] = normalize(def, value) end
    end
end

function Settings.set(player, args)
    args = args or {}
    local key = tostring(args.key or "")
    local defs = definitionMap()
    local def = defs[key]
    if not def then return false, "Unknown ACC setting" end

    local value = args.reset == true and def.default or args.value
    local normalized = normalize(def, value)
    local sv = sandbox()
    sv[key] = normalized

    local s = state()
    s.values[key] = normalized
    s.updatedBy = ACC.AdminAccess.usernameFor(player)
    s.updatedAt = ACC.Time.nowSeconds()
    s.updatedAtText = ACC.Time.stamp()

    ACC.Persistence.enqueue("settings",
        "setting_changed key=" .. tostring(key)
        .. " value=" .. tostring(valueText(def, normalized))
        .. " by=" .. tostring(s.updatedBy or "")
        .. " reset=" .. tostring(args.reset == true))

    return true, tostring(def.label or key) .. " set to " .. valueText(def, normalized)
end

return Settings
