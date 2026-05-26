require "FadedFeastcraft/FFC_Config"
require "FadedFeastcraft/FFC_Utils"
require "FadedFeastcraft/FFC_Balance"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.Preservation = FadedFeastcraft.Preservation or {}

local Preservation = FadedFeastcraft.Preservation
local Utils = FadedFeastcraft.Utils
local Balance = FadedFeastcraft.Balance

local METHOD_WORDS = {
    dried = { "dry", "dried", "jerky" },
    canned = { "can", "canned", "tin" },
    jarred = { "jar", "jarred" },
    pickled = { "pickl", "relish" },
    salted = { "salt", "salted" },
    smoked = { "smok", "smoked" },
    packed = { "pack", "ration", "mre" },
}

local function hasAny(text, words)
    text = Utils.lower(text)
    for _, word in ipairs(words or {}) do
        if string.find(text, word, 1, true) then return true end
    end
    return false
end

function Preservation.enabled()
    return Utils.sbBool("EnablePreservationSystem", true)
end

function Preservation.methodForProbe(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring(select(i, ...) or "")
    end
    local text = table.concat(parts, " ")
    for method, words in pairs(METHOD_WORDS) do
        if hasAny(text, words) then return method end
    end
    return "preserved"
end

function Preservation.isPreservationAction(actionOrOperation)
    if not actionOrOperation then return false end
    local probe = tostring(actionOrOperation.family or "")
        .. " " .. tostring(actionOrOperation.familyLabel or "")
        .. " " .. tostring(actionOrOperation.actionType or "")
        .. " " .. tostring(actionOrOperation.label or "")
        .. " " .. tostring(actionOrOperation.name or "")
        .. " " .. tostring(actionOrOperation.source or "")
        .. " " .. tostring(actionOrOperation.id or "")
    if hasAny(probe, { "preserv", "canning bench", "jarred", "dry storage", "dry", "dried", "pickl", "salt", "smok", "ration", "mre", "seal can", "open preserved jar" }) then
        return true
    end
    return false
end

local function baseShelfDays(method)
    if method == "canned" or method == "jarred" then return 45 end
    if method == "dried" or method == "smoked" or method == "salted" then return 28 end
    if method == "pickled" then return 35 end
    if method == "packed" then return 14 end
    return 21
end

function Preservation.balanceShelfDays(method, player)
    local mode = tonumber(Utils.getSandbox().PreserveFoodBalanceMode) or 2
    local days = baseShelfDays(method)
    if mode <= 1 then
        days = days * 0.65
    elseif mode >= 3 then
        days = days * 1.4
    end
    local bonus = Balance.freshnessBonusDays(player, "preservation")
    return math.max(1, Utils.round(days + bonus, 1))
end

function Preservation.stampItem(item, player, options)
    if not item or not item.getModData or not Preservation.enabled() then return nil end
    options = options or {}
    local method = options.method or Preservation.methodForProbe(options.source, options.label, Utils.getFullType(item), Utils.getDisplayName(item))
    local shelfDays = tonumber(options.shelfDays) or Preservation.balanceShelfDays(method, player)
    local now = getGameTime and getGameTime():getWorldAgeHours() or 0
    Utils.safeSet(item, "setAge", 0)
    local md = item:getModData()
    md.FFC_Preservation = {
        version = 1,
        method = method,
        label = tostring(options.label or method),
        source = tostring(options.source or "FFC"),
        shelfDays = shelfDays,
        createdWorldAge = now,
        sealed = options.sealed ~= false,
    }
    return md.FFC_Preservation
end

function Preservation.readItem(itemOrRecord)
    if not itemOrRecord then return nil end
    if itemOrRecord.preservation then return itemOrRecord.preservation end
    local item = itemOrRecord.item or itemOrRecord
    if not item.getModData then return nil end
    local md = item:getModData()
    local data = md and md.FFC_Preservation or nil
    if type(data) ~= "table" then return nil end
    return data
end

function Preservation.remainingDays(data)
    if type(data) ~= "table" then return nil end
    local shelfDays = tonumber(data.shelfDays)
    local created = tonumber(data.createdWorldAge)
    if not shelfDays or not created or not getGameTime then return shelfDays end
    local elapsedDays = (getGameTime():getWorldAgeHours() - created) / 24.0
    return shelfDays - elapsedDays
end

function Preservation.describe(data)
    if type(data) ~= "table" then return {} end
    local days = Preservation.remainingDays(data)
    local daysText = days and (tostring(Utils.round(days, 1)) .. "d") or "unknown"
    return {
        "FFC preservation: " .. tostring(data.label or data.method or "preserved"),
        "Method: " .. tostring(data.method or "preserved"),
        "Remaining pantry estimate: " .. daysText,
        "Sealed by FFC: " .. tostring(data.sealed == true),
    }
end

return Preservation
