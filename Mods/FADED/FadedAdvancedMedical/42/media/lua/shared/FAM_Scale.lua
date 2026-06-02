-- FAM_Scale.lua
-- Resolution and font-size helper for FAM custom UI.

FAM_Scale = FAM_Scale or {}

local BASE_HEIGHT = 1080
local BASE_FONT_HGT = 14

local listeners = {}
local cached = {
    factor = 1.0,
    fontBucket = 1,
    screenH = BASE_HEIGHT,
    fontHgtSmall = BASE_FONT_HGT,
}

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or 0
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function recompute()
    if isServer and isServer() then return end
    local core = getCore and getCore() or nil
    if not core then return end

    local screenH = core:getScreenHeight() or BASE_HEIGHT
    local tm = getTextManager and getTextManager() or nil
    local fontHgt = tm and tm:getFontHeight(UIFont.Small) or BASE_FONT_HGT
    if type(fontHgt) ~= "number" or fontHgt <= 0 then
        fontHgt = BASE_FONT_HGT
    end

    local resFactor = clamp(screenH / BASE_HEIGHT, 0.85, 2.0)
    local fontFactor = clamp(fontHgt / BASE_FONT_HGT, 0.9, 1.8)

    cached.factor = (fontFactor * 0.65) + (resFactor * 0.35)
    cached.fontBucket = (core.getOptionFontSize and core:getOptionFontSize()) or 1
    cached.screenH = screenH
    cached.fontHgtSmall = fontHgt
end

function FAM_Scale.factor()
    return cached.factor or 1.0
end

function FAM_Scale.px(baseline)
    return math.floor((baseline or 0) * FAM_Scale.factor() + 0.5)
end

function FAM_Scale.font(baselineHgt)
    baselineHgt = baselineHgt or BASE_FONT_HGT
    local target = baselineHgt * FAM_Scale.factor()
    local tm = getTextManager and getTextManager() or nil
    if not tm then return UIFont.Small end

    local small = tm:getFontHeight(UIFont.Small) or 12
    local medium = tm:getFontHeight(UIFont.Medium) or 16
    local large = tm:getFontHeight(UIFont.Large) or 22
    if target <= (small + medium) / 2 then return UIFont.Small end
    if target <= (medium + large) / 2 then return UIFont.Medium end
    return UIFont.Large
end

function FAM_Scale.pad()
    return FAM_Scale.px(4)
end

function FAM_Scale.lineH()
    local tm = getTextManager and getTextManager() or nil
    if not tm then return FAM_Scale.px(BASE_FONT_HGT) end
    return (tm:getFontHeight(UIFont.Small) or 12) + FAM_Scale.px(2)
end

function FAM_Scale.iconSize()
    return FAM_Scale.px(16)
end

function FAM_Scale.onChange(callback)
    if type(callback) == "function" then
        table.insert(listeners, callback)
    end
end

function FAM_Scale.refresh()
    local previous = cached.factor
    recompute()
    if math.abs((cached.factor or 1.0) - (previous or 1.0)) <= 0.001 then
        return
    end
    for i = 1, #listeners do
        listeners[i](cached.factor, cached.fontBucket, cached.screenH)
    end
end

if Events then
    if Events.OnGameStart then
        Events.OnGameStart.Add(function() FAM_Scale.refresh() end)
    end
    if Events.OnMainMenuEnter then
        Events.OnMainMenuEnter.Add(function() FAM_Scale.refresh() end)
    end
    if Events.OnResolutionChange then
        Events.OnResolutionChange.Add(function() FAM_Scale.refresh() end)
    end
end

recompute()

return FAM_Scale
