-- CSR-side adapter for Faiths & Traditions' optional bridge API.
-- CSR never requires FTR directly; this keeps the integration soft.
CSR_FaithsTraditionsBridge = CSR_FaithsTraditionsBridge or {}

local Bridge = CSR_FaithsTraditionsBridge

local function clamp(value, minValue, maxValue)
    value = tonumber(value)
    if not value then return minValue end
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function Bridge.getAPI()
    if type(FTRBridge) == "table" then return FTRBridge end
    if type(FTR) == "table" and type(FTR.Bridge) == "table" then return FTR.Bridge end
    return nil
end

function Bridge.isAvailable()
    return Bridge.getAPI() ~= nil
end

function Bridge.getPlayerFaith(player)
    local api = Bridge.getAPI()
    if not api or type(api.getPlayerFaith) ~= "function" then return nil end

    local ok, result = pcall(api.getPlayerFaith, player)
    if ok then return result end
    return {
        ok = false,
        applies = false,
        error = tostring(result or "faithBridgeError"),
    }
end

function Bridge.getSurvivalModifier(player, request)
    local api = Bridge.getAPI()
    if not api then return nil end

    local fn = api.getCSRSurvivalModifier
    if type(fn) ~= "function" then
        fn = api.getSurvivalInfluence
    end
    if type(fn) ~= "function" then return nil end

    local ok, result = pcall(fn, player, request or {})
    if ok then return result end
    return {
        ok = false,
        applies = false,
        error = tostring(result or "survivalBridgeError"),
    }
end

function Bridge.getSurvivalBonus(player, request)
    local result = Bridge.getSurvivalModifier(player, request)
    if not result or result.ok ~= true or result.applies ~= true then
        return 0, result
    end

    local bonus = tonumber(result.flatBonusPercent) or tonumber(result.flatBonus) or 0
    return clamp(bonus, 0, 25), result
end

return Bridge
