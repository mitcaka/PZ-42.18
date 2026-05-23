if isServer() then return end

require "ISUI/ISButton"
require "FAM_TriagePanel"

FAM_ScreenButton = FAM_ScreenButton or {}
FAM_ScreenButton.SIZE = 42
FAM_ScreenButton.MARGIN = 8
FAM_ScreenButton.position = FAM_ScreenButton.position or nil

local function getLocalPlayer()
    if getSpecificPlayer then
        local player = getSpecificPlayer(0)
        if player then return player end
    end
    return getPlayer and getPlayer() or nil
end

local function clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

function FAM_ScreenButton.clampPosition(x, y)
    local size = FAM_ScreenButton.SIZE
    local margin = FAM_ScreenButton.MARGIN
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    return clamp(x, margin, math.max(margin, screenW - size - margin)),
        clamp(y, margin, math.max(margin, screenH - size - margin))
end

function FAM_ScreenButton.defaultPosition()
    local size = FAM_ScreenButton.SIZE
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    return FAM_ScreenButton.clampPosition(screenW - size - 24, screenH - size - 140)
end

function FAM_ScreenButton.getPosition()
    if FAM_ScreenButton.position then
        return FAM_ScreenButton.clampPosition(FAM_ScreenButton.position.x, FAM_ScreenButton.position.y)
    end
    return FAM_ScreenButton.defaultPosition()
end

function FAM_ScreenButton.savePosition(button)
    if not button then return end
    local x, y = FAM_ScreenButton.clampPosition(button:getX(), button:getY())
    FAM_ScreenButton.position = { x = x, y = y }
    button:setX(x)
    button:setY(y)
end

function FAM_ScreenButton.openChart()
    local player = getLocalPlayer()
    if player then
        FAM_TriagePanel.open(player, player)
    end
end

function FAM_ScreenButton.attachDrag(button)
    button.famDragging = false
    button.famDragMoved = false

    button.onMouseDown = function(buttonSelf, x, y)
        buttonSelf.famDragging = true
        buttonSelf.famDragMoved = false
        buttonSelf.famDragStartX = buttonSelf:getX()
        buttonSelf.famDragStartY = buttonSelf:getY()
        return true
    end

    local function moveButton(buttonSelf, dx, dy)
        if not buttonSelf.famDragging then
            return false
        end
        local x, y = FAM_ScreenButton.clampPosition(buttonSelf:getX() + dx, buttonSelf:getY() + dy)
        buttonSelf:setX(x)
        buttonSelf:setY(y)
        if math.abs(x - (buttonSelf.famDragStartX or x)) + math.abs(y - (buttonSelf.famDragStartY or y)) > 3 then
            buttonSelf.famDragMoved = true
        end
        FAM_ScreenButton.position = { x = x, y = y }
        return true
    end

    button.onMouseMove = function(buttonSelf, dx, dy)
        return moveButton(buttonSelf, dx, dy)
    end

    button.onMouseMoveOutside = function(buttonSelf, dx, dy)
        return moveButton(buttonSelf, dx, dy)
    end

    button.onMouseUp = function(buttonSelf, x, y)
        local moved = buttonSelf.famDragMoved == true
        buttonSelf.famDragging = false
        FAM_ScreenButton.savePosition(buttonSelf)
        if not moved then
            FAM_ScreenButton.openChart()
        end
        return true
    end

    button.onMouseUpOutside = function(buttonSelf, x, y)
        buttonSelf.famDragging = false
        FAM_ScreenButton.savePosition(buttonSelf)
        return true
    end
end

function FAM_ScreenButton.ensure()
    if FAM_ScreenButton.instance then
        return FAM_ScreenButton.instance
    end
    if not getLocalPlayer() then
        return nil
    end

    local size = FAM_ScreenButton.SIZE
    local x, y = FAM_ScreenButton.getPosition()
    local button = ISButton:new(x, y, size, size, "", nil, nil)
    button.internal = "FAM_SCREEN_CHART"
    button:initialise()
    button:instantiate()
    button.iconTexture = getTexture("media/ui/FAM/TriageIcon.png")
    button.joypadTextureWH = 32
    button.tooltip = getText("IGUI_FAM_OpenPatientChart")
    button.backgroundColor = { r = 0.02, g = 0.12, b = 0.05, a = 0.86 }
    button.backgroundColorMouseOver = { r = 0.04, g = 0.24, b = 0.1, a = 0.95 }
    button.borderColor = { r = 0.1, g = 0.9, b = 0.45, a = 0.9 }
    FAM_ScreenButton.attachDrag(button)
    button:addToUIManager()
    button:bringToTop()
    FAM_ScreenButton.instance = button
    return button
end

function FAM_ScreenButton.remove()
    if FAM_ScreenButton.instance then
        FAM_ScreenButton.savePosition(FAM_ScreenButton.instance)
        FAM_ScreenButton.instance:removeFromUIManager()
        FAM_ScreenButton.instance = nil
    end
end

local function ensureScreenButton()
    FAM_ScreenButton.ensure()
end

local function removeScreenButton()
    FAM_ScreenButton.remove()
end

if Events and not FAM_ScreenButton._registered then
    FAM_ScreenButton._registered = true
    if Events.OnCreatePlayer then
        Events.OnCreatePlayer.Add(ensureScreenButton)
    end
    if Events.OnGameStart then
        Events.OnGameStart.Add(ensureScreenButton)
    end
    if Events.OnTick then
        Events.OnTick.Add(ensureScreenButton)
    end
    if Events.OnMainMenuEnter then
        Events.OnMainMenuEnter.Add(removeScreenButton)
    end
end
