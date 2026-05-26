require "FadedFeastcraft/FFC_Config"
require "FadedFeastcraft/FFC_Utils"
require "FadedFeastcraft/FFC_SourcePackRegistry"
require "FadedFeastcraft/FFC_Branding"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.Compatibility = FadedFeastcraft.Compatibility or {}

local Compatibility = FadedFeastcraft.Compatibility
local Utils = FadedFeastcraft.Utils
local SourcePacks = FadedFeastcraft.SourcePackRegistry
local Branding = FadedFeastcraft.Branding

Compatibility.cache = Compatibility.cache or { built = false, rows = {}, warnings = {}, summary = {} }

local KNOWN_UI_MODS = {
    Project_Cook = "Project Cook",
    NeatUI = "NeatUI Framework",
    NeatUIB42 = "NeatUI Framework",
    NeatUI_Framework = "NeatUI Framework",
}

local function gameVersion()
    local core = getCore and getCore() or nil
    local candidates = {
        Utils.safeCall(core, "getGameVersion"),
        Utils.safeCall(core, "getVersion"),
        Utils.safeCall(core, "getVersionNumber"),
    }
    for _, value in ipairs(candidates) do
        if value ~= nil and tostring(value) ~= "" then return tostring(value) end
    end
    return "unknown"
end

local function runtimeMode()
    if isClient and isClient() then return "MP client" end
    if isServer and isServer() then return "MP server" end
    return "singleplayer/host"
end

local function addRow(rows, name, status, detail, severity)
    rows[#rows + 1] = {
        kind = "compat",
        name = name,
        status = status,
        detail = detail,
        severity = severity or "info",
        search = Utils.lower(tostring(name) .. " " .. tostring(status) .. " " .. tostring(detail)),
    }
end

local function activeModName(modIds)
    for _, modId in ipairs(modIds or {}) do
        if Utils.isModActive(modId) then return modId end
    end
    return nil
end

function Compatibility.build(force)
    if Compatibility.cache.built and not force then return Compatibility.cache end
    local rows = {}
    local warnings = {}
    local version = gameVersion()
    local mode = runtimeMode()

    addRow(rows, "Game runtime", mode, "Detected version: " .. tostring(version), "info")
    if version ~= "unknown" and not string.find(version, "42.18", 1, true) then
        warnings[#warnings + 1] = "Current runtime is not reporting 42.18; keep FFC in compatibility-watch mode after updates."
        addRow(rows, "B42.18 target", "watch", "FFC is tuned for 42.18 but will use defensive fallbacks.", "warn")
    else
        addRow(rows, "B42.18 target", "ok", "Runtime matches the current compatibility target or could not be queried.", "ok")
    end

    local duplicateCount = 0
    for _, pack in ipairs(SourcePacks.getPacks()) do
        if pack.embedded then
            local active = activeModName(pack.modIds)
            if active and active ~= "FadedFeastcraft" then
                duplicateCount = duplicateCount + 1
                local label = Branding.displaySource(pack.label, "FFC Integrated Pantry")
                warnings[#warnings + 1] = label .. " is embedded in FFC and also active as " .. active .. ". Disable the external source mod to avoid duplicate items or recipes."
                addRow(rows, label, "duplicate active", "External mod id active: " .. active, "warn")
            end
        end
    end
    if duplicateCount == 0 then
        addRow(rows, "Embedded source packs", "ok", "No active duplicate source-pack mod IDs detected.", "ok")
    end

    for modId, label in pairs(KNOWN_UI_MODS) do
        if Utils.isModActive(modId) then
            addRow(rows, label, "detected", "FFC can coexist, but its GUI remains the authoritative food workflow for FFC actions.", "info")
        end
    end

    local csrDetected = FadedFeastcraft.CSR and FadedFeastcraft.CSR.getStatus and FadedFeastcraft.CSR.getStatus().detected == true
    addRow(rows, "CSR integration", csrDetected and "detected" or "not detected", csrDetected and "Using CSR helpers defensively." or "FFC will use vanilla-safe fallbacks.", csrDetected and "ok" or "info")

    local summary = {
        version = version,
        mode = mode,
        warnings = #warnings,
        duplicateSourcePacks = duplicateCount,
        target = "42.18",
    }

    table.sort(rows, function(a, b)
        if tostring(a.severity) ~= tostring(b.severity) then return tostring(a.severity) > tostring(b.severity) end
        return tostring(a.name) < tostring(b.name)
    end)

    Compatibility.cache = {
        built = true,
        rows = rows,
        warnings = warnings,
        summary = summary,
    }
    return Compatibility.cache
end

function Compatibility.getCache()
    return Compatibility.build(false)
end

function Compatibility.refresh()
    return Compatibility.build(true)
end

return Compatibility
