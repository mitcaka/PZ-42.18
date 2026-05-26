require "FadedFeastcraft/FFC_Config"
require "FadedFeastcraft/FFC_Utils"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.CSR = FadedFeastcraft.CSR or {}

local CSR = FadedFeastcraft.CSR
local Utils = FadedFeastcraft.Utils

CSR.status = CSR.status or {}

local function safeFeature(methodName)
    if not CSR_FeatureFlags or type(CSR_FeatureFlags[methodName]) ~= "function" then
        return nil
    end
    local ok, result = pcall(CSR_FeatureFlags[methodName])
    if ok then return result == true end
    return nil
end

local function hasUtility(methodName)
    return type(CSR_Utils) == "table" and type(CSR_Utils[methodName]) == "function"
end

function CSR.refresh()
    local enabled = Utils.sbBool("EnableCSRIntegration", true)
    local detected, detectedId = false, nil
    local runtimeHelpers = type(CommonSenseReborn) == "table"
        or type(CSR_Config) == "table"
        or type(CSR_Utils) == "table"
        or type(CSR_FeatureFlags) == "table"
    if enabled then
        detected, detectedId = Utils.isAnyModActive(FadedFeastcraft.Config.CSR_MOD_IDS or { "CommonSenseReborn" })
        if not detected and runtimeHelpers then
            detected = true
            detectedId = "runtime-helpers"
        end
    end
    CSR.status = {
        enabled = enabled,
        detected = detected,
        detectedId = detectedId,
        bridgeLabel = "CSR Ecosystem",
        version = (CommonSenseReborn and CommonSenseReborn.VERSION)
            or (CSR_Config and CSR_Config.VERSION)
            or "unknown",
        hasUtils = type(CSR_Utils) == "table",
        hasFeatureFlags = type(CSR_FeatureFlags) == "table",
        systems = {},
    }

    if detected then
        CSR.status.systems[#CSR.status.systems + 1] = {
            key = "Food expiry sync",
            value = hasUtility("getFoodExpiryDays"),
        }
        CSR.status.systems[#CSR.status.systems + 1] = {
            key = "Freshness insight sync",
            value = hasUtility("getItemFreshnessInsight"),
        }
        CSR.status.systems[#CSR.status.systems + 1] = {
            key = "Consumable priority sync",
            value = hasUtility("compareConsumablePriority"),
        }
        CSR.status.systems[#CSR.status.systems + 1] = {
            key = "Alternate can opening",
            value = safeFeature("isAlternateCanOpeningEnabled"),
        }
        CSR.status.systems[#CSR.status.systems + 1] = {
            key = "Jar capping",
            value = safeFeature("isJarCappingEnabled"),
        }
        CSR.status.systems[#CSR.status.systems + 1] = {
            key = "Home canning",
            value = safeFeature("isHomeCanningEnabled"),
        }
        CSR.status.systems[#CSR.status.systems + 1] = {
            key = "Food expiry tooltip",
            value = safeFeature("isFoodExpiryTooltipEnabled"),
        }
        CSR.status.systems[#CSR.status.systems + 1] = {
            key = "Eat all stack",
            value = safeFeature("isEatAllStackEnabled"),
        }
        CSR.status.systems[#CSR.status.systems + 1] = {
            key = "Item insight tooltips",
            value = safeFeature("isItemInsightTooltipsEnabled"),
        }
    end

    return CSR.status
end

function CSR.getStatus()
    if not CSR.status or CSR.status.enabled == nil then
        return CSR.refresh()
    end
    return CSR.status
end

function CSR.getFoodExpiry(item)
    if CSR.getStatus().detected and CSR_Utils and type(CSR_Utils.getFoodExpiryDays) == "function" then
        local ok, result = pcall(CSR_Utils.getFoodExpiryDays, item)
        if ok and result then
            result.source = "CSR"
            return result
        end
    end

    if not Utils.isFood(item) then return nil end
    local offAgeMax = Utils.safeCall(item, "getOffAgeMax")
    if type(offAgeMax) ~= "number" or offAgeMax <= 0 then return nil end
    if offAgeMax >= 1000000 then
        return { isSealed = true, isRotten = false, roomDays = 0, fridgeDays = 0, source = "FFC" }
    end
    local age = tonumber(Utils.safeCall(item, "getAge")) or 0
    local remaining = offAgeMax - age
    if remaining <= 0 then
        return { isSealed = false, isRotten = true, roomDays = 0, fridgeDays = 0, source = "FFC" }
    end
    return { isSealed = false, isRotten = false, roomDays = remaining, fridgeDays = remaining * 5, source = "FFC" }
end

function CSR.getFreshnessInsight(item)
    if CSR.getStatus().detected and CSR_Utils and type(CSR_Utils.getItemFreshnessInsight) == "function" then
        local ok, result = pcall(CSR_Utils.getItemFreshnessInsight, item)
        if ok and result then return result end
    end
    local exp = CSR.getFoodExpiry(item)
    if not exp then return "Stable" end
    if exp.isSealed then return "Sealed" end
    if exp.isRotten then return "Rotten" end
    if type(exp.roomDays) == "number" and exp.roomDays < 1 then return "Spoils soon" end
    return "Fresh"
end

function CSR.compareConsumablePriority(a, b)
    if CSR.getStatus().detected and CSR_Utils and type(CSR_Utils.compareConsumablePriority) == "function" then
        local ok, result = pcall(CSR_Utils.compareConsumablePriority, a, b)
        if ok then return result == true end
    end
    local ar = Utils.getRemainingAmount(a) or 999999
    local br = Utils.getRemainingAmount(b) or 999999
    if ar ~= br then return ar < br end
    local aid = a and a.getID and a:getID() or 0
    local bid = b and b.getID and b:getID() or 0
    return aid < bid
end

function CSR.isFrozenBlocked(item, recipe)
    if not item or not Utils.isFood(item) then return false end
    if not (item.isFrozen and item:isFrozen()) then return false end
    if recipe and recipe.isAllowFrozenItem then
        local ok, allowed = pcall(function() return recipe:isAllowFrozenItem() end)
        if ok and allowed == true then return false end
    end
    return true
end

return CSR
