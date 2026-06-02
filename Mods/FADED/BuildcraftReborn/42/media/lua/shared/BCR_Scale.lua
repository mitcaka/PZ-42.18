-- Resolution and font-size helper adapted from Common Sense Reborn's CSR_Scale.

require "BCR_DisplaySettings"

BCR_Scale = BCR_Scale or {}

local BASE_HEIGHT = 1080
local BASE_FONT_HGT = 14

local listeners = {}
local cached = {
    factor = 1.0,
    fontBucket = 1,
    screenH = BASE_HEIGHT,
    fontHgtSmall = BASE_FONT_HGT,
}

local function recompute()
    if isServer and isServer() then return end
    local core = getCore and getCore() or nil
    if not core then return end

    local screenH = core:getScreenHeight() or BASE_HEIGHT
    local tm = getTextManager and getTextManager() or nil
    local fhSmallRaw = tm and tm:getFontHeight(UIFont.Small)
    local fhSmall = (type(fhSmallRaw) == "number" and fhSmallRaw > 0) and fhSmallRaw or BASE_FONT_HGT

    local resFactor = screenH / BASE_HEIGHT
    if resFactor < 0.85 then resFactor = 0.85 end
    if resFactor > 2.0 then resFactor = 2.0 end

    local fontFactor = fhSmall / BASE_FONT_HGT
    if fontFactor < 0.9 then fontFactor = 0.9 end
    if fontFactor > 1.8 then fontFactor = 1.8 end

    local displayScale = 1.0
    if BCR_DisplaySettings and BCR_DisplaySettings.get then
        displayScale = tonumber(BCR_DisplaySettings.get("DisplayScale")) or 1.0
    end

    cached.factor = ((fontFactor * 0.65) + (resFactor * 0.35)) * displayScale
    if cached.factor < 0.65 then cached.factor = 0.65 end
    if cached.factor > 2.4 then cached.factor = 2.4 end
    cached.fontBucket = (core.getOptionFontSize and core:getOptionFontSize()) or 1
    cached.screenH = screenH
    cached.fontHgtSmall = fhSmall
end

function BCR_Scale.factor()
    return cached.factor or 1.0
end

function BCR_Scale.px(baseline)
    return math.floor((baseline or 0) * (cached.factor or 1.0) + 0.5)
end

function BCR_Scale.font(baselineHgt)
    baselineHgt = baselineHgt or BASE_FONT_HGT
    local target = baselineHgt * (cached.factor or 1.0)
    local tm = getTextManager and getTextManager() or nil
    if not tm then return UIFont.Small end

    local hSmall = tm:getFontHeight(UIFont.Small) or 12
    local hMedium = tm:getFontHeight(UIFont.Medium) or 16
    local hLarge = tm:getFontHeight(UIFont.Large) or 22

    if target <= (hSmall + hMedium) / 2 then return UIFont.Small end
    if target <= (hMedium + hLarge) / 2 then return UIFont.Medium end
    return UIFont.Large
end

function BCR_Scale.pad()
    return BCR_Scale.px(4)
end

function BCR_Scale.lineH()
    local tm = getTextManager and getTextManager() or nil
    if not tm then return BCR_Scale.px(BASE_FONT_HGT) end
    return (tm:getFontHeight(UIFont.Small) or 12) + BCR_Scale.px(2)
end

function BCR_Scale.iconSize()
    return BCR_Scale.px(16)
end

function BCR_Scale.onChange(callback)
    if type(callback) ~= "function" then return end
    table.insert(listeners, callback)
end

function BCR_Scale.refresh()
    local prev = cached.factor
    recompute()
    if math.abs((cached.factor or 1.0) - (prev or 1.0)) <= 0.001 then return end

    for i = 1, #listeners do
        listeners[i](cached.factor, cached.fontBucket, cached.screenH)
    end
end

if Events then
    if Events.OnGameStart then
        Events.OnGameStart.Add(function() BCR_Scale.refresh() end)
    end
    if Events.OnMainMenuEnter then
        Events.OnMainMenuEnter.Add(function() BCR_Scale.refresh() end)
    end
    if Events.OnResolutionChange then
        Events.OnResolutionChange.Add(function() BCR_Scale.refresh() end)
    end
end

recompute()

return BCR_Scale
