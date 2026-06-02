ProjectFadedCar = ProjectFadedCar or {}

local PFC = ProjectFadedCar

PFC.UIScale = PFC.UIScale or {}
PFC_UIScale = PFC.UIScale

local Scale = PFC_UIScale

local BASE_HEIGHT = 1080
local BASE_FONT_HGT = 14

local cached = {
    ready = false,
    factor = 1.0,
    screenW = 1280,
    screenH = 720,
    fontBucket = 1,
    fontHgtSmall = BASE_FONT_HGT,
}

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function readCore()
    return getCore and getCore() or nil
end

local function readSmallFontHeight()
    local tm = getTextManager and getTextManager() or nil
    local raw = tm and tm.getFontHeight and tm:getFontHeight(UIFont.Small) or nil
    if type(raw) == "number" and raw > 0 then return raw end
    return BASE_FONT_HGT
end

function Scale.refresh()
    if isServer and isServer() then return false end
    local core = readCore()
    if not core then return false end

    local screenW = core.getScreenWidth and core:getScreenWidth() or cached.screenW
    local screenH = core.getScreenHeight and core:getScreenHeight() or cached.screenH
    local fontHgtSmall = readSmallFontHeight()

    local resFactor = clamp(screenH / BASE_HEIGHT, 0.85, 1.75)
    local fontFactor = clamp(fontHgtSmall / BASE_FONT_HGT, 0.90, 1.80)
    local factor = (fontFactor * 0.65) + (resFactor * 0.35)

    local changed = not cached.ready
        or math.abs((cached.factor or 1.0) - factor) > 0.001
        or cached.screenW ~= screenW
        or cached.screenH ~= screenH
        or cached.fontHgtSmall ~= fontHgtSmall

    cached.ready = true
    cached.factor = factor
    cached.screenW = screenW
    cached.screenH = screenH
    cached.fontBucket = core.getOptionFontSize and core:getOptionFontSize() or cached.fontBucket
    cached.fontHgtSmall = fontHgtSmall

    return changed
end

function Scale.factor()
    if not cached.ready then Scale.refresh() end
    return cached.factor or 1.0
end

function Scale.screenW()
    if not cached.ready then Scale.refresh() end
    return cached.screenW or 1280
end

function Scale.screenH()
    if not cached.ready then Scale.refresh() end
    return cached.screenH or 720
end

function Scale.px(value, minValue)
    if not cached.ready then Scale.refresh() end
    local result = math.floor((tonumber(value) or 0) * Scale.factor() + 0.5)
    if minValue then result = math.max(result, minValue) end
    return result
end

function Scale.fontHeight(font)
    local tm = getTextManager and getTextManager() or nil
    local h = tm and tm.getFontHeight and tm:getFontHeight(font or UIFont.Small) or nil
    if type(h) == "number" and h > 0 then return h end
    return Scale.px(BASE_FONT_HGT)
end

function Scale.lineH(font, extra)
    return Scale.fontHeight(font or UIFont.Small) + Scale.px(extra or 4)
end

function Scale.measure(text, font)
    text = tostring(text or "")
    local tm = getTextManager and getTextManager() or nil
    local width = tm and tm.MeasureStringX and tm:MeasureStringX(font or UIFont.Small, text) or nil
    if type(width) == "number" then return width end
    return #text * Scale.px(7)
end

function Scale.trimToWidth(text, maxWidth, font)
    text = tostring(text or "")
    maxWidth = tonumber(maxWidth) or 0
    if text == "" or maxWidth <= 0 then return "" end
    if Scale.measure(text, font) <= maxWidth then return text end

    local ellipsis = "..."
    local ellipsisW = Scale.measure(ellipsis, font)
    if ellipsisW >= maxWidth then return "" end

    local low = 0
    local high = #text
    while low < high do
        local mid = math.ceil((low + high) / 2)
        local candidate = string.sub(text, 1, mid) .. ellipsis
        if Scale.measure(candidate, font) <= maxWidth then
            low = mid
        else
            high = mid - 1
        end
    end

    return string.sub(text, 1, low) .. ellipsis
end

function Scale.wrapToWidth(text, maxWidth, font, maxLines)
    text = tostring(text or "")
    maxWidth = tonumber(maxWidth) or 0
    if text == "" or maxWidth <= 0 then return {} end

    local lines = {}
    local line = ""
    for word in string.gmatch(text, "%S+") do
        local candidate = line == "" and word or (line .. " " .. word)
        if Scale.measure(candidate, font) <= maxWidth then
            line = candidate
        else
            if line ~= "" then
                lines[#lines + 1] = line
                if maxLines and #lines >= maxLines then return lines end
            end
            if Scale.measure(word, font) > maxWidth then
                lines[#lines + 1] = Scale.trimToWidth(word, maxWidth, font)
                line = ""
                if maxLines and #lines >= maxLines then return lines end
            else
                line = word
            end
        end
    end
    if line ~= "" and (not maxLines or #lines < maxLines) then
        lines[#lines + 1] = line
    end
    return lines
end

function Scale.buttonWidth(text, baseWidth)
    local pad = Scale.px(20)
    return math.max(Scale.px(baseWidth or 64), Scale.measure(text, UIFont.Small) + pad)
end

function Scale.windowSize(baseW, baseH, minW, minH, margin)
    margin = Scale.px(margin or 16)
    local screenW = Scale.screenW()
    local screenH = Scale.screenH()
    local maxW = math.max(Scale.px(280), screenW - (margin * 2))
    local maxH = math.max(Scale.px(220), screenH - (margin * 2))
    local w = math.min(math.max(Scale.px(baseW), math.min(minW or 320, maxW)), maxW)
    local h = math.min(math.max(Scale.px(baseH), math.min(minH or 240, maxH)), maxH)
    return math.floor(w), math.floor(h)
end

function Scale.centeredPosition(w, h, margin)
    margin = Scale.px(margin or 8)
    local x = math.max(margin, math.floor((Scale.screenW() - w) / 2))
    local y = math.max(margin, math.floor((Scale.screenH() - h) / 2))
    return x, y
end

function Scale.setBounds(control, x, y, w, h)
    if not control then return end
    if x ~= nil then control:setX(math.floor(x)) end
    if y ~= nil then control:setY(math.floor(y)) end
    if w ~= nil then
        if control.setWidth then control:setWidth(math.floor(w)) else control.width = math.floor(w) end
    end
    if h ~= nil then
        if control.setHeight then control:setHeight(math.floor(h)) else control.height = math.floor(h) end
    end
end

function Scale.clampPanelToScreen(panel, margin)
    if not panel then return end
    margin = Scale.px(margin or 8)
    local maxX = math.max(margin, Scale.screenW() - panel.width - margin)
    local maxY = math.max(margin, Scale.screenH() - panel.height - margin)
    if panel.x < margin then panel:setX(margin) end
    if panel.y < margin then panel:setY(margin) end
    if panel.x > maxX then panel:setX(maxX) end
    if panel.y > maxY then panel:setY(maxY) end
end

function Scale.resizePanel(panel, w, h)
    if not panel then return end
    if panel.setWidth then panel:setWidth(w) else panel.width = w end
    if panel.setHeight then panel:setHeight(h) else panel.height = h end
    if panel.javaObject then
        if panel.javaObject.setWidth then panel.javaObject:setWidth(w) end
        if panel.javaObject.setHeight then panel.javaObject:setHeight(h) end
    end
end

if Events then
    if Events.OnGameStart then Events.OnGameStart.Add(function() Scale.refresh() end) end
    if Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(function() Scale.refresh() end) end
    if Events.OnResolutionChange then Events.OnResolutionChange.Add(function() Scale.refresh() end) end
end

Scale.refresh()

return Scale
