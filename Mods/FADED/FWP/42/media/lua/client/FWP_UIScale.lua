-- Faded's Weapon Pack UI scaling helpers.

if isServer() then return end

FWPUIScale = FWPUIScale or {}

local BASE_SCREEN_WIDTH = 1920
local BASE_SCREEN_HEIGHT = 1080
local BASE_SMALL_FONT_HEIGHT = 14

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function rounded(value)
    value = tonumber(value) or 0
    if value >= 0 then
        return math.floor(value + 0.5)
    end
    return math.ceil(value - 0.5)
end

function FWPUIScale.get()
    local core = getCore and getCore() or nil
    local screenWidth = BASE_SCREEN_WIDTH
    local screenHeight = BASE_SCREEN_HEIGHT
    if core then
        if core.getScreenWidth then
            screenWidth = tonumber(core:getScreenWidth()) or screenWidth
        end
        if core.getScreenHeight then
            screenHeight = tonumber(core:getScreenHeight()) or screenHeight
        end
    end

    local fontHeight = BASE_SMALL_FONT_HEIGHT
    if getTextManager and UIFont and UIFont.Small then
        local manager = getTextManager()
        local measured = manager and manager.getFontHeight and manager:getFontHeight(UIFont.Small) or nil
        if tonumber(measured) then
            fontHeight = tonumber(measured)
        end
    end

    local fontScale = clamp(fontHeight / BASE_SMALL_FONT_HEIGHT, 0.90, 1.50)
    local screenScale = math.sqrt((screenWidth * screenHeight) / (BASE_SCREEN_WIDTH * BASE_SCREEN_HEIGHT))
    screenScale = clamp(screenScale, 0.90, 1.65)

    return clamp(math.max(fontScale, screenScale), 0.90, 1.65)
end

function FWPUIScale.value(value)
    return rounded((tonumber(value) or 0) * FWPUIScale.get())
end

function FWPUIScale.min(value, minimum)
    return math.max(FWPUIScale.value(value), tonumber(minimum) or 0)
end

function FWPUIScale.fontHeight(font, fallback)
    if getTextManager and font then
        local manager = getTextManager()
        local height = manager and manager.getFontHeight and manager:getFontHeight(font) or nil
        if tonumber(height) then
            return tonumber(height)
        end
    end
    return FWPUIScale.value(fallback or BASE_SMALL_FONT_HEIGHT)
end

function FWPUIScale.line(font, fallback, extra)
    return FWPUIScale.fontHeight(font, fallback or BASE_SMALL_FONT_HEIGHT) + FWPUIScale.value(extra or 0)
end

function FWPUIScale.clampRect(x, y, width, height, padding)
    local core = getCore and getCore() or nil
    local screenWidth = core and core.getScreenWidth and core:getScreenWidth() or BASE_SCREEN_WIDTH
    local screenHeight = core and core.getScreenHeight and core:getScreenHeight() or BASE_SCREEN_HEIGHT
    padding = FWPUIScale.value(padding or 8)

    width = tonumber(width) or 0
    height = tonumber(height) or 0
    local maxX = math.max(padding, screenWidth - width - padding)
    local maxY = math.max(padding, screenHeight - height - padding)

    return math.max(padding, math.min(tonumber(x) or padding, maxX)),
        math.max(padding, math.min(tonumber(y) or padding, maxY))
end

function FWPUIScale.clampToScreen(element, padding)
    if element == nil then
        return
    end
    local x, y = FWPUIScale.clampRect(element:getX(), element:getY(), element:getWidth(), element:getHeight(), padding)
    element:setX(x)
    element:setY(y)
end
