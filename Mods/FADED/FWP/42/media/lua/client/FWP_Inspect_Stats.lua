if isServer() then return end
require "FWP_UIScale"

FWPInspectStats = FWPInspectStats or {}

local function FWPInspectStatsUIV(value)
    return FWPUIScale and FWPUIScale.value(value) or math.floor((tonumber(value) or 0) + 0.5)
end

local function FWPInspectStatsLine(font, fallback, extra)
    return FWPUIScale and FWPUIScale.line(font, fallback, extra) or ((tonumber(fallback) or 14) + (tonumber(extra) or 0))
end

local WEAPON_STAT_DEFS = {
    { key = "HitChance", label = "Hit Chance", getters = { "getHitChance" }, decimals = 0 },
    { key = "CriticalChance", label = "Crit Chance", getters = { "getCriticalChance" }, decimals = 0 },
    { key = "MinDamage", label = "Min Damage", getters = { "getMinDamage" }, decimals = 2 },
    { key = "MaxDamage", label = "Max Damage", getters = { "getMaxDamage" }, decimals = 2 },
    { key = "MinRange", label = "Min Range", getters = { "getMinRange" }, decimals = 1 },
    { key = "MaxRange", label = "Max Range", getters = { "getMaxRange" }, decimals = 1 },
    { key = "AimingTime", label = "Aiming Time", getters = { "getAimingTime" }, decimals = 0, lowerBetter = true },
    { key = "RecoilDelay", label = "Recoil Delay", getters = { "getRecoilDelay" }, decimals = 0, lowerBetter = true },
    { key = "ReloadTime", label = "Reload Time", getters = { "getReloadTime" }, decimals = 0, lowerBetter = true },
    { key = "SoundRadius", label = "Sound Radius", getters = { "getSoundRadius" }, decimals = 0, lowerBetter = true },
    { key = "SoundVolume", label = "Sound Volume", getters = { "getSoundVolume" }, decimals = 0, lowerBetter = true },
    { key = "MaxAmmo", label = "Max Ammo", getters = { "getMaxAmmo", "getClipSize" }, decimals = 0 },
    { key = "ProjectileCount", label = "Projectiles", getters = { "getProjectileCount", "getProjectilecount" }, decimals = 0 },
    { key = "JamGunChance", label = "Jam Chance", getters = { "getJamGunChance" }, decimals = 0, lowerBetter = true },
    { key = "MinAngle", label = "Min Angle", getters = { "getMinAngle" }, decimals = 3, lowerBetter = true },
}

local PART_STAT_DEFS = {
    { label = "Hit Chance", getters = { "getHitChance" }, decimals = 0 },
    { label = "Aiming Time", getters = { "getAimingTime" }, decimals = 0, lowerBetter = true },
    { label = "Recoil Delay", getters = { "getRecoilDelay" }, decimals = 0, lowerBetter = true },
    { label = "Reload Time", getters = { "getReloadTime" }, decimals = 0, lowerBetter = true },
    { label = "Damage", getters = { "getDamage" }, decimals = 2 },
    { label = "Max Range", getters = { "getMaxRange" }, decimals = 1 },
    { label = "Clip Size", getters = { "getClipSize" }, decimals = 0 },
    { label = "Sound Radius", getters = { "getSoundRadius" }, decimals = 0, lowerBetter = true },
    { label = "Sound Volume", getters = { "getSoundVolume" }, decimals = 0, lowerBetter = true },
    { label = "Min Angle", getters = { "getMinAngle" }, decimals = 3, lowerBetter = true },
}

local BASELINE_CACHE = {}
local DISPLAY_NAME_CACHE = {}

local TRANSFORM_VARIANT_KINDS = {
    { kind = "compatibleAmmo", label = "Ammo Variant" },
    { kind = "fold", label = "Fold Variant" },
    { kind = "fold2", label = "Alt Fold Variant" },
    { kind = "launcherMode", label = "Launcher Mode" },
    { kind = "normalFireMode", label = "Normal Fire Mode" },
    { kind = "meleeMode", label = "Melee Mode" },
}

local function callMethod(obj, methodName)
    if obj == nil or methodName == nil then
        return nil
    end

    local okMethod, method = pcall(function()
        return obj[methodName]
    end)
    if not okMethod or type(method) ~= "function" then
        return nil
    end

    local okValue, value = pcall(method, obj)
    if okValue then
        return value
    end
    return nil
end

local function readFirstNumber(obj, getters)
    if obj == nil or getters == nil then
        return nil
    end

    for _, getter in ipairs(getters) do
        local value = callMethod(obj, getter)
        if value ~= nil then
            local numberValue = tonumber(value)
            if numberValue ~= nil then
                return numberValue
            end
        end
    end
    return nil
end

local function itemFullType(item)
    local fullType = callMethod(item, "getFullType")
    if fullType ~= nil and tostring(fullType) ~= "" then
        return tostring(fullType)
    end

    local moduleName = callMethod(item, "getModule")
    local typeName = callMethod(item, "getType")
    if moduleName ~= nil and typeName ~= nil then
        return tostring(moduleName) .. "." .. tostring(typeName)
    end
    return nil
end

local function createBaseItem(fullType)
    if fullType == nil or InventoryItemFactory == nil or InventoryItemFactory.CreateItem == nil then
        return nil
    end

    local okItem, item = pcall(function()
        return FWPCreateItem(fullType)
    end)
    if okItem then
        return item
    end
    return nil
end

local function baselineValues(weapon)
    local fullType = itemFullType(weapon)
    if fullType ~= nil and BASELINE_CACHE[fullType] ~= nil then
        return BASELINE_CACHE[fullType]
    end

    local values = {}
    local scriptItem = callMethod(weapon, "getScriptItem")
    for _, def in ipairs(WEAPON_STAT_DEFS) do
        values[def.key] = readFirstNumber(scriptItem, def.getters)
    end

    local baseItem = createBaseItem(fullType)
    if baseItem ~= nil then
        for _, def in ipairs(WEAPON_STAT_DEFS) do
            if values[def.key] == nil then
                values[def.key] = readFirstNumber(baseItem, def.getters)
            end
        end
    end

    if fullType ~= nil then
        BASELINE_CACHE[fullType] = values
    end
    return values
end

local function formatValue(value, decimals)
    if value == nil then
        return "-"
    end

    if decimals == nil or decimals <= 0 then
        return tostring(math.floor(value + 0.5))
    end
    return string.format("%." .. tostring(decimals) .. "f", value)
end

local function formatSigned(value, decimals)
    if value == nil then
        return "-"
    end

    if math.abs(value) < 0.0005 then
        return "0"
    end

    local text = formatValue(math.abs(value), decimals)
    if value > 0 then
        return "+" .. text
    end
    return "-" .. text
end

local function effectColor(def, value)
    if value == nil or math.abs(value) < 0.0005 then
        return 0.78, 0.78, 0.78, 1.0
    end

    local improves = value > 0
    if def.lowerBetter then
        improves = value < 0
    end

    if improves then
        return 0.45, 1.0, 0.45, 1.0
    end
    return 1.0, 0.48, 0.48, 1.0
end

local function trimText(text, font, maxWidth)
    if FWPInspectTrimText then
        return FWPInspectTrimText(text, font, maxWidth)
    end

    if text == nil then
        return ""
    end

    text = tostring(text)
    if getTextManager():MeasureStringX(font, text) <= maxWidth then
        return text
    end

    local suffix = "..."
    local suffixWidth = getTextManager():MeasureStringX(font, suffix)
    while string.len(text) > 0 and getTextManager():MeasureStringX(font, text) + suffixWidth > maxWidth do
        text = string.sub(text, 1, -2)
    end
    return text .. suffix
end

local function normalizeFullType(fullType)
    if FWPNormalizeFullType then
        return FWPNormalizeFullType(fullType)
    end
    if fullType == nil then
        return nil
    end
    fullType = tostring(fullType)
    if fullType == "" then
        return nil
    end
    if string.find(fullType, ".", 1, true) then
        return fullType
    end
    return "Base." .. fullType
end

local function displayNameForType(fullType)
    fullType = normalizeFullType(fullType)
    if fullType == nil then
        return ""
    end
    if DISPLAY_NAME_CACHE[fullType] ~= nil then
        return DISPLAY_NAME_CACHE[fullType]
    end

    local item = createBaseItem(fullType)
    local displayName = callMethod(item, "getDisplayName")
    if displayName == nil or tostring(displayName) == "" then
        displayName = tostring(fullType):gsub("^Base%.", "")
    end

    DISPLAY_NAME_CACHE[fullType] = tostring(displayName)
    return DISPLAY_NAME_CACHE[fullType]
end

local function addVariantRow(rows, seen, label, target, detail, key)
    label = tostring(label or "")
    target = tostring(target or "")
    detail = detail ~= nil and tostring(detail) or ""
    if label == "" or target == "" then
        return
    end

    key = tostring(key or (label .. "|" .. target .. "|" .. detail))
    if seen[key] then
        return
    end

    seen[key] = true
    rows[#rows + 1] = {
        label = label,
        target = target,
        detail = detail
    }
end

local function addItemVariantRow(rows, seen, label, targetType, detail, key)
    targetType = normalizeFullType(targetType)
    if targetType == nil then
        return
    end

    addVariantRow(rows, seen, label, displayNameForType(targetType), detail, key or (label .. "|" .. targetType .. "|" .. tostring(detail or "")))
end

local function addFireModeRows(rows, seen, weapon)
    local modes = {}
    local modeSeen = {}
    local currentMode = callMethod(weapon, "getFireMode")
    local modeList = callMethod(weapon, "getFireModePossibilities")

    local function addMode(mode)
        mode = mode ~= nil and tostring(mode) or ""
        if mode == "" or modeSeen[mode] then
            return
        end
        modeSeen[mode] = true
        modes[#modes + 1] = mode
    end

    if modeList ~= nil and modeList.size and modeList.get then
        local okSize, size = pcall(function()
            return modeList:size()
        end)
        if okSize and tonumber(size) ~= nil then
            for i = 0, tonumber(size) - 1 do
                local okMode, mode = pcall(function()
                    return modeList:get(i)
                end)
                if okMode then
                    addMode(mode)
                end
            end
        end
    elseif type(modeList) == "table" then
        for _, mode in ipairs(modeList) do
            addMode(mode)
        end
    end

    addMode(currentMode)

    if #modes > 0 then
        local detail = currentMode ~= nil and tostring(currentMode) ~= "" and ("Current: " .. tostring(currentMode)) or ""
        addVariantRow(rows, seen, "Fire Modes", table.concat(modes, " / "), detail, "fireModes|" .. table.concat(modes, "/"))
    end
end

local function addTransformRows(rows, seen, weapon)
    if FWPWeaponTransformBuildTargetSet == nil then
        return
    end

    for _, def in ipairs(TRANSFORM_VARIANT_KINDS) do
        local okTargets, targets = pcall(FWPWeaponTransformBuildTargetSet, weapon, def.kind)
        if okTargets and targets ~= nil then
            local targetList = {}
            for targetType, enabled in pairs(targets) do
                if enabled then
                    targetList[#targetList + 1] = targetType
                end
            end
            table.sort(targetList)
            for _, targetType in ipairs(targetList) do
                addItemVariantRow(rows, seen, def.label, targetType, "", def.kind .. "|" .. tostring(targetType))
            end
        end
    end
end

local function addWeaponWorkRows(rows, seen, weapon)
    if FWPWeaponWorkGetTriggerGroupType then
        local groupType = FWPWeaponWorkGetTriggerGroupType(weapon)
        if groupType ~= nil then
            addItemVariantRow(rows, seen, "Fire-Control Group", groupType, "Uses screwdriver", "triggerGroup|" .. tostring(groupType))
        end
    end

    if FWPWeaponWorkIsPaintballCanisterWeapon and FWPWeaponWorkIsPaintballCanisterWeapon(weapon) then
        addItemVariantRow(rows, seen, "Paintball Canister", "Base.M2A1_Can", "Uses screwdriver", "paintballCanister")
    end
    if FWPWeaponWorkIsCO2CanisterWeapon and FWPWeaponWorkIsCO2CanisterWeapon(weapon) then
        addItemVariantRow(rows, seen, "CO2 Cartridge", "Base.CO2_Cartridge", "Uses screwdriver", "co2Canister")
    end

    if FWPWeaponWorkGetPossibleConversions then
        for _, conversion in ipairs(FWPWeaponWorkGetPossibleConversions(weapon)) do
            local detail = ""
            if conversion.partType then
                detail = "Requires: " .. displayNameForType(conversion.partType)
            elseif conversion.tool == "saw" then
                detail = "Requires: Saw"
            end
            addItemVariantRow(rows, seen, conversion.label or "Conversion", conversion.targetType, detail, "conversion|" .. tostring(conversion.id or conversion.targetType))
        end
    end
end

function FWPInspectCollectWeaponVariants(weapon)
    local rows = {}
    if weapon == nil then
        return rows
    end

    local seen = {}
    addFireModeRows(rows, seen, weapon)
    addTransformRows(rows, seen, weapon)
    addWeaponWorkRows(rows, seen, weapon)
    return rows
end

function FWPInspectGetWeaponVariantPanelHeight(weapon, width)
    local rows = FWPInspectCollectWeaponVariants(weapon)
    if #rows == 0 then
        return 0
    end

    local u = FWPInspectStatsUIV
    local rowHeight = FWPInspectStatsLine(UIFont.Small, 14, 2)
    local headerHeight = math.max(u(31), FWPInspectStatsLine(UIFont.Small, 14, 17))
    return headerHeight + (#rows * rowHeight) + u(8)
end

function FWPInspectDrawWeaponVariants(panel, weapon, x, y, width)
    if panel == nil or weapon == nil then
        return 0
    end

    local rows = FWPInspectCollectWeaponVariants(weapon)
    if #rows == 0 then
        return 0
    end

    local u = FWPInspectStatsUIV
    local panelWidth = math.max(u(500), width or u(500))
    local rowHeight = FWPInspectStatsLine(UIFont.Small, 14, 2)
    local headerHeight = math.max(u(31), FWPInspectStatsLine(UIFont.Small, 14, 17))
    local panelHeight = headerHeight + (#rows * rowHeight) + u(8)
    local targetX = x + u(160)
    local detailX = x + panelWidth - u(168)
    local labelMaxWidth = math.max(u(120), targetX - x - u(16))
    local targetMaxWidth = math.max(u(120), detailX - targetX - u(8))
    local detailMaxWidth = math.max(u(120), panelWidth - (detailX - x) - u(8))

    panel:drawRect(x, y, panelWidth, panelHeight, 0.58, 0.02, 0.02, 0.02)
    panel:drawRectBorder(x, y, panelWidth, panelHeight, 0.62, 0.76, 0.76, 0.76)
    panel:drawText("Modes and Variants", x + u(8), y + u(6), 1.0, 1.0, 1.0, 1.0, UIFont.Small)
    panel:drawText("Target", targetX, y + u(18), 0.68, 0.82, 1.0, 1.0, UIFont.Small)
    panel:drawText("Requirement", detailX, y + u(18), 0.68, 0.82, 1.0, 1.0, UIFont.Small)

    for i, row in ipairs(rows) do
        local rowY = y + headerHeight + ((i - 1) * rowHeight)
        panel:drawText(trimText(row.label, UIFont.Small, labelMaxWidth), x + u(8), rowY, 0.92, 0.92, 0.92, 1.0, UIFont.Small)
        panel:drawText(trimText(row.target, UIFont.Small, targetMaxWidth), targetX, rowY, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
        if row.detail ~= nil and row.detail ~= "" then
            panel:drawText(trimText(row.detail, UIFont.Small, detailMaxWidth), detailX, rowY, 0.72, 0.95, 0.78, 1.0, UIFont.Small)
        end
    end

    return panelHeight
end

function FWPInspectCollectWeaponStats(weapon)
    local rows = {}
    if weapon == nil then
        return rows
    end

    local base = baselineValues(weapon)
    for _, def in ipairs(WEAPON_STAT_DEFS) do
        local current = readFirstNumber(weapon, def.getters)
        local baseValue = base[def.key]
        if current ~= nil or baseValue ~= nil then
            if current == nil then
                current = baseValue
            end

            table.insert(rows, {
                label = def.label,
                base = baseValue,
                current = current,
                delta = (current ~= nil and baseValue ~= nil) and (current - baseValue) or nil,
                decimals = def.decimals,
                lowerBetter = def.lowerBetter == true,
            })
        end
    end
    return rows
end

function FWPInspectDrawWeaponStats(panel, weapon, x, y, width)
    if panel == nil or weapon == nil then
        return
    end

    local rows = FWPInspectCollectWeaponStats(weapon)
    if #rows == 0 then
        return
    end

    local u = FWPInspectStatsUIV
    local panelWidth = math.max(u(500), width or u(500))
    local rowHeight = FWPInspectStatsLine(UIFont.Small, 14, 1)
    local headerHeight = math.max(u(31), FWPInspectStatsLine(UIFont.Small, 14, 17))
    local panelHeight = headerHeight + (#rows * rowHeight) + u(8)
    local baseX = x + panelWidth - u(252)
    local currentX = x + panelWidth - u(156)
    local deltaX = x + panelWidth - u(66)

    panel:drawRect(x, y, panelWidth, panelHeight, 0.58, 0.02, 0.02, 0.02)
    panel:drawRectBorder(x, y, panelWidth, panelHeight, 0.62, 0.76, 0.76, 0.76)
    panel:drawText("Weapon Stats", x + u(8), y + u(6), 1.0, 1.0, 1.0, 1.0, UIFont.Small)
    panel:drawText("Base", baseX, y + u(18), 0.68, 0.82, 1.0, 1.0, UIFont.Small)
    panel:drawText("Current", currentX, y + u(18), 0.68, 0.82, 1.0, 1.0, UIFont.Small)
    panel:drawText("Change", deltaX, y + u(18), 0.68, 0.82, 1.0, 1.0, UIFont.Small)

    for i, row in ipairs(rows) do
        local rowY = y + headerHeight + ((i - 1) * rowHeight)
        local r, g, b, a = effectColor(row, row.delta)
        panel:drawText(row.label, x + u(8), rowY, 0.92, 0.92, 0.92, 1.0, UIFont.Small)
        panel:drawText(formatValue(row.base, row.decimals), baseX, rowY, 0.9, 0.9, 0.9, 1.0, UIFont.Small)
        panel:drawText(formatValue(row.current, row.decimals), currentX, rowY, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
        panel:drawText(formatSigned(row.delta, row.decimals), deltaX, rowY, r, g, b, a, UIFont.Small)
    end
end

function FWPInspectCollectAttachmentStatLines(part)
    local rows = {}
    if part == nil then
        return rows
    end

    for _, def in ipairs(PART_STAT_DEFS) do
        local value = readFirstNumber(part, def.getters)
        if value ~= nil and math.abs(value) >= 0.0005 then
            table.insert(rows, {
                label = def.label,
                value = value,
                decimals = def.decimals,
                lowerBetter = def.lowerBetter == true,
            })
        end
    end
    return rows
end

function FWPInspectDrawAttachmentStatLines(panel, part, x, y, maxWidth)
    if panel == nil or part == nil then
        return
    end

    local rows = FWPInspectCollectAttachmentStatLines(part)
    if #rows == 0 then
        panel:drawText("No listed stat changes", x, y, 0.68, 0.68, 0.68, 1.0, UIFont.Small)
        return
    end

    panel:drawText("Effects", x, y, 0.68, 0.82, 1.0, 1.0, UIFont.Small)
    local maxRows = math.min(#rows, 6)
    for i = 1, maxRows do
        local row = rows[i]
        local r, g, b, a = effectColor(row, row.value)
        local text = row.label .. ": " .. formatSigned(row.value, row.decimals)
        if FWPInspectTrimText then
            text = FWPInspectTrimText(text, UIFont.Small, maxWidth or FWPInspectStatsUIV(260))
        end
        panel:drawText(text, x, y + FWPInspectStatsLine(UIFont.Small, 14, 1) + ((i - 1) * FWPInspectStatsLine(UIFont.Small, 14, 1)), r, g, b, a, UIFont.Small)
    end
end
