if isServer() then return end
require "PFC_UIScale"

ProjectFadedCarClient = ProjectFadedCarClient or {}

local PFC = ProjectFadedCar
local Scale = PFC.UIScale or PFC_UIScale
local BUTTON_TEXTURE = getTexture and getTexture("media/textures/PFC_EngineBayButton.png") or nil
local BACKGROUND_TEXTURE = getTexture and getTexture("media/textures/PFC_EngineBayBackground.png") or nil

print("[ProjectFadedCar] Client vanilla UI skin module loaded")

local function enabled()
    return PFC and PFC.vanillaGuiSkinEnabled and PFC.vanillaGuiSkinEnabled()
end

local function styleList(list)
    if not list then return end
    list.drawBorder = true
    list.backgroundColor = { r = 0.015, g = 0.018, b = 0.020, a = 0.34 }
    list.borderColor = { r = 0.00, g = 0.72, b = 0.82, a = 0.42 }
end

local function styleButton(button)
    if not button then return end
    button.backgroundColor = { r = 0.012, g = 0.014, b = 0.016, a = 0.60 }
    button.backgroundColorMouseOver = { r = 0.00, g = 0.70, b = 0.82, a = 0.22 }
    button.borderColor = { r = 0.00, g = 0.82, b = 0.92, a = 0.68 }
    button.textColor = { r = 0.90, g = 0.96, b = 0.96, a = 1.00 }
end

local function positionEngineButton(window)
    if not window or not window.pfcEngineButton then return end
    Scale.refresh()
    local titleH = window.titleBarHeight and window:titleBarHeight() or 16
    local buttonText = PFC.text("IGUI_PFC_EngineBayShort", "Engine")
    local buttonW = math.min(math.max(Scale.buttonWidth(buttonText, 106), Scale.px(96)), math.max(Scale.px(80), window.width - Scale.px(28)))
    local buttonH = math.max(Scale.px(24, 20), Scale.fontHeight(UIFont.Small) + Scale.px(8))
    window.pfcEngineButton:setX(Scale.px(14))
    window.pfcEngineButton:setY(titleH + Scale.px(8))
    window.pfcEngineButton:setWidth(buttonW)
    window.pfcEngineButton:setHeight(buttonH)
    window.pfcEngineButton:setVisible(true)
end

local function openEngineBay(window)
    if not window or not window.vehicle then return end
    local player = window.chr or (getSpecificPlayer and getSpecificPlayer(window.playerNum)) or getPlayer()
    if ProjectFadedCarClient and ProjectFadedCarClient.openServicePanel then
        ProjectFadedCarClient.lastMechanicsVehicle = window.vehicle
        ProjectFadedCarClient.openServicePanel(player, window.vehicle)
    end
end

local function applyWindowStyle(window)
    if not window then return end
    window.backgroundColor = { r = 0.012, g = 0.014, b = 0.016, a = 0.92 }
    window.borderColor = { r = 0.00, g = 0.78, b = 0.88, a = 0.82 }
    window.partCatRGB = { r = 0.86, g = 0.95, b = 0.94, a = 1.00 }
    window.partRGB = { r = 0.78, g = 0.84, b = 0.82, a = 1.00 }
    styleList(window.listbox)
    styleList(window.bodyworklist)
    positionEngineButton(window)
end

local function ensureEngineButton(window)
    if not window or window.pfcEngineButton or not ISButton then return end
    Scale.refresh()
    local button = ISButton:new(Scale.px(14), Scale.px(30), Scale.buttonWidth(PFC.text("IGUI_PFC_EngineBayShort", "Engine"), 106), math.max(Scale.px(24, 20), Scale.fontHeight(UIFont.Small) + Scale.px(8)), PFC.text("IGUI_PFC_EngineBayShort", "Engine"), window, openEngineBay)
    button:initialise()
    button:instantiate()
    button:setTooltip(PFC.text("IGUI_PFC_EngineBayTooltip", "Open Faded Engine Bay"))
    styleButton(button)
    if BUTTON_TEXTURE then
        button.iconTexture = BUTTON_TEXTURE
        button.joypadTextureWH = Scale.px(18, 14)
    end
    window:addChild(button)
    window.pfcEngineButton = button
    positionEngineButton(window)
end

local function drawSkinBackground(window)
    if not enabled() or window.isCollapsed then return end
    Scale.refresh()
    positionEngineButton(window)
    local titleH = window.titleBarHeight and window:titleBarHeight() or 16
    window:drawRect(0, titleH, window.width, window.height - titleH, 0.30, 0.010, 0.012, 0.014)
    if BACKGROUND_TEXTURE then
        window:drawTextureScaled(BACKGROUND_TEXTURE, Scale.px(8), titleH + Scale.px(4), window.width - Scale.px(16), window.height - titleH - Scale.px(12), 0.20, 0.88, 1.00, 1.00)
        window:drawTextureScaled(BACKGROUND_TEXTURE, Scale.px(24), titleH + Scale.px(62), Scale.px(260), Scale.px(260), 0.18, 0.80, 1.00, 1.00)
    end
    window:drawRect(Scale.px(8), titleH + Scale.px(4), window.width - Scale.px(16), window.height - titleH - Scale.px(12), 0.18, 0.020, 0.025, 0.030)
    window:drawRect(Scale.px(8), titleH + Scale.px(4), window.width - Scale.px(16), window.height - titleH - Scale.px(12), 0.36, 0.006, 0.008, 0.010)
    window:drawRectBorder(0, 0, window.width, window.height, 0.92, 0.00, 0.86, 0.96)
    window:drawRectBorder(Scale.px(2), titleH + Scale.px(2), window.width - Scale.px(4), window.height - titleH - Scale.px(4), 0.36, 0.00, 0.58, 0.68)
end

local function drawPFCStatus(window)
    if not enabled() or not window.vehicle or window.isCollapsed then return end
    if not PFC or not PFC.getSnapshot then return end
    Scale.refresh()
    local snapshot = PFC.getSnapshot(window.vehicle)
    if not snapshot then return end

    local diag = PFC.text(PFC.diagnosticLabel(snapshot.diagnosticCode), PFC.text("IGUI_PFC_Diagnostic_OK", "Nominal"))
    local text = "PFC  " ..
        PFC.text("IGUI_PFC_EngineHealth", "Engine") .. " " .. tostring(PFC.round(snapshot.engineCondition)) .. "%  " ..
        PFC.text("IGUI_PFC_AvgInternals", "Internals") .. " " .. tostring(PFC.round(snapshot.average)) .. "%  " ..
        Scale.trimToWidth(diag, Scale.px(140), UIFont.Small)
    local x = window.xCarTexOffset and window.xCarTexOffset + Scale.px(8) or Scale.px(308)
    x = math.min(x, math.max(Scale.px(22), window.width - Scale.px(220)))
    local y = (window.progressY or Scale.px(80)) - Scale.lineH(UIFont.Small, 2)
    local right = window.width - Scale.px(22)
    local maxW = math.max(Scale.px(120), right - x)
    window:drawTextRight(Scale.trimToWidth(text, maxW, UIFont.Small), right, y, 0.36, 0.88, 0.94, 1, UIFont.Small)
    window:drawRect(x, y + Scale.fontHeight(UIFont.Small) + Scale.px(2), math.max(Scale.px(24), right - x), 1, 0.42, 0.00, 0.78, 0.92)
end

local function installMechanicsSkin()
    if not ISVehicleMechanics or ISVehicleMechanics.__pfc_vanilla_skin then return end

    local originalNew = ISVehicleMechanics.new
    local originalCreateChildren = ISVehicleMechanics.createChildren
    local originalUpdateLayout = ISVehicleMechanics.updateLayout
    local originalPrerender = ISVehicleMechanics.prerender
    local originalRender = ISVehicleMechanics.render

    ISVehicleMechanics.new = function(self, x, y, character, vehicle)
        local window = originalNew(self, x, y, character, vehicle)
        if enabled() then applyWindowStyle(window) end
        return window
    end

    ISVehicleMechanics.createChildren = function(self)
        originalCreateChildren(self)
        if enabled() then
            applyWindowStyle(self)
            ensureEngineButton(self)
        end
    end

    ISVehicleMechanics.updateLayout = function(self)
        originalUpdateLayout(self)
        if enabled() then
            applyWindowStyle(self)
        elseif self.pfcEngineButton then
            self.pfcEngineButton:setVisible(false)
        end
    end

    ISVehicleMechanics.prerender = function(self)
        originalPrerender(self)
        drawSkinBackground(self)
    end

    ISVehicleMechanics.render = function(self)
        originalRender(self)
        drawPFCStatus(self)
    end

    ISVehicleMechanics.__pfc_vanilla_skin = true
    print("[ProjectFadedCar] Vanilla mechanics UI skin installed")
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(installMechanicsSkin)
end
installMechanicsSkin()
