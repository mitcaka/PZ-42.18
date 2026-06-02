if isServer() then return end
if not ISPanel then
    print("[ProjectFadedCar] Dashboard skipped: ISPanel unavailable")
    return
end
require "PFC_UIScale"

PFC_Dashboard = ISPanel:derive("PFC_Dashboard")
PFC_Dashboard.instance = nil

PFC_DashboardFluidPanel = ISPanel:derive("PFC_DashboardFluidPanel")
PFC_DashboardFluidPanel.instance = nil

print("[ProjectFadedCar] Client dashboard module loaded")

local PFC = ProjectFadedCar
local Scale = PFC.UIScale or PFC_UIScale
local ENGINE_BUTTON_TEXTURE = getTexture and getTexture("media/textures/PFC_EngineBayButton.png") or nil

local function compactScale()
    Scale.refresh()
    return PFC.clamp(Scale.factor(), 0.82, 1.12)
end

local function dp(value, minValue)
    local result = math.floor((tonumber(value) or 0) * compactScale() + 0.5)
    if minValue then result = math.max(result, minValue) end
    return result
end

local function coreDashboardSize()
    local pad = dp(8)
    local button = dp(28, 24)
    local textW = math.max(dp(124), Scale.measure("Internals 100%", UIFont.Small) * 2 + dp(6))
    local width = math.min(math.max(dp(190), textW + button + pad * 3), Scale.screenW() - dp(16))
    local height = math.min(math.max(dp(62), Scale.lineH(UIFont.Small, 2) * 2 + dp(20)), Scale.screenH() - dp(16))
    return math.floor(width), math.floor(height)
end

local function fluidDashboardSize()
    local labelW = math.max(Scale.measure(PFC.text("IGUI_PFC_Fluid_TransmissionShort", "ATF") .. " 100%", UIFont.Small), dp(54))
    local width = math.min(math.max(dp(174), labelW + dp(92)), Scale.screenW() - dp(16))
    local height = math.min(math.max(dp(76), Scale.lineH(UIFont.Small, 2) * 3 + dp(18)), Scale.screenH() - dp(16))
    return math.floor(width), math.floor(height)
end

local function drawPanelBackground(panel)
    panel:drawRect(0, 0, panel.width, panel.height, 0.64, 0.012, 0.013, 0.014)
    panel:drawRect(0, 0, panel.width, 1, 0.42, 0.10, 0.11, 0.12)
    panel:drawRect(0, panel.height - 1, panel.width, 1, 0.42, 0.08, 0.09, 0.10)
    panel:drawRectBorder(0, 0, panel.width, panel.height, 0.34, 0.08, 0.09, 0.10)
end

local function conditionColor(value)
    value = PFC.clamp(value, 0, 100)
    if value < 35 then return 0.94, 0.24, 0.18 end
    if value < 65 then return 0.95, 0.68, 0.22 end
    return 0.15, 0.76, 0.46
end

local function drawMiniBar(panel, x, y, w, h, value)
    local r, g, b = conditionColor(value)
    panel:drawRect(x, y, w, h, 0.58, 0.04, 0.045, 0.050)
    panel:drawRectBorder(x, y, w, h, 0.55, 0.14, 0.15, 0.16)
    panel:drawRect(x + 1, y + 1, math.floor((w - 2) * PFC.clamp(value, 0, 100) / 100), h - 2, 0.9, r, g, b)
end

local function clampToScreen(panel)
    Scale.clampPanelToScreen(panel, 8)
end

local function beginDrag(panel)
    panel.dragging = true
    panel.dragMoved = false
    return true
end

local function dragMove(panel, dx, dy)
    if not panel.dragging then return end
    if math.abs(dx) + math.abs(dy) > 1 then
        panel.dragMoved = true
    end
    panel:setX(panel.x + dx)
    panel:setY(panel.y + dy)
    clampToScreen(panel)
end

function PFC_Dashboard:new(playerIndex)
    local width, height = coreDashboardSize()
    local x = PFC_Dashboard.savedX or math.floor((Scale.screenW() - width) / 2) - dp(94)
    local y = PFC_Dashboard.savedY or Scale.screenH() - height - dp(116)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.playerIndex = playerIndex or 0
    o.backgroundColor = { r = 0.012, g = 0.013, b = 0.014, a = 0.60 }
    o.borderColor = { r = 0.08, g = 0.09, b = 0.10, a = 0.35 }
    o.moveWithMouse = false
    o.dragging = false
    o.dragMoved = false
    o.lastInitVehicle = -1
    o.lastRequestMs = 0
    o.lastScale = compactScale()
    return o
end

function PFC_DashboardFluidPanel:new(playerIndex)
    local width, height = fluidDashboardSize()
    local defaultX = math.floor((Scale.screenW() - width) / 2) + dp(110)
    local defaultY = Scale.screenH() - height - dp(116)
    local o = ISPanel:new(PFC_DashboardFluidPanel.savedX or defaultX, PFC_DashboardFluidPanel.savedY or defaultY, width, height)
    setmetatable(o, self)
    self.__index = self
    o.playerIndex = playerIndex or 0
    o.backgroundColor = { r = 0.012, g = 0.013, b = 0.014, a = 0.60 }
    o.borderColor = { r = 0.08, g = 0.09, b = 0.10, a = 0.35 }
    o.moveWithMouse = false
    o.dragging = false
    o.dragMoved = false
    o.lastScale = compactScale()
    return o
end

function PFC_Dashboard:getLayout()
    local pad = dp(8)
    local gap = dp(6)
    local button = dp(28, 24)
    local contentW = math.max(dp(104), self.width - button - pad * 3)
    local colW = math.floor((contentW - gap) / 2)
    local textY = dp(6)
    local barY = textY + Scale.fontHeight(UIFont.Small) + dp(3)
    return {
        pad = pad,
        gap = gap,
        button = button,
        buttonX = self.width - pad - button,
        buttonY = math.floor((self.height - button) / 2),
        contentW = contentW,
        colW = colW,
        textY = textY,
        barY = barY,
        barH = dp(5, 4),
        statusY = barY + dp(9),
    }
end

function PFC_DashboardFluidPanel:getLayout()
    local pad = dp(8)
    local gap = dp(5)
    local rowH = math.max(Scale.lineH(UIFont.Small, 2), dp(18))
    local labelW = math.max(dp(48), Scale.measure("ATF 100%", UIFont.Small) + dp(2))
    return {
        pad = pad,
        gap = gap,
        rowH = rowH,
        labelW = labelW,
        barX = pad + labelW + gap,
        barW = math.max(dp(70), self.width - pad * 2 - labelW - gap),
        barH = dp(5, 4),
        firstY = dp(8),
    }
end

function PFC_Dashboard:layoutControls()
    local layout = self:getLayout()
    if self.engineButton then
        Scale.setBounds(self.engineButton, layout.buttonX, layout.buttonY, layout.button, layout.button)
    end
end

function PFC_Dashboard:applyScale()
    local w, h = coreDashboardSize()
    if self.width ~= w or self.height ~= h then
        Scale.resizePanel(self, w, h)
    end
    self:layoutControls()
    clampToScreen(self)
end

function PFC_DashboardFluidPanel:applyScale()
    local w, h = fluidDashboardSize()
    if self.width ~= w or self.height ~= h then
        Scale.resizePanel(self, w, h)
    end
    clampToScreen(self)
end

function PFC_Dashboard:createChildren()
    ISPanel.createChildren(self)
    local layout = self:getLayout()
    self.engineButton = ISButton:new(layout.buttonX, layout.buttonY, layout.button, layout.button, "", self, PFC_Dashboard.onEngine)
    self.engineButton:initialise()
    self.engineButton:instantiate()
    self.engineButton.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.engineButton.backgroundColorMouseOver = { r = 0.00, g = 0.70, b = 0.82, a = 0.18 }
    self.engineButton.borderColor = { r = 0.00, g = 0.82, b = 0.92, a = 0.18 }
    if ENGINE_BUTTON_TEXTURE and self.engineButton.setImage then
        self.engineButton:setImage(ENGINE_BUTTON_TEXTURE)
    end
    self:addChild(self.engineButton)
    self:layoutControls()
end

function PFC_Dashboard:getPlayer()
    return getSpecificPlayer and getSpecificPlayer(self.playerIndex) or getPlayer()
end

function PFC_DashboardFluidPanel:getPlayer()
    return getSpecificPlayer and getSpecificPlayer(self.playerIndex) or getPlayer()
end

function PFC_Dashboard:getVehicle()
    local player = self:getPlayer()
    return player and player.getVehicle and player:getVehicle() or nil
end

function PFC_DashboardFluidPanel:getVehicle()
    local player = self:getPlayer()
    return player and player.getVehicle and player:getVehicle() or nil
end

function PFC_Dashboard:onEngine()
    local player = self:getPlayer()
    local vehicle = self:getVehicle()
    if ProjectFadedCarClient then
        ProjectFadedCarClient.openServicePanel(player, vehicle)
    end
end

function PFC_Dashboard:onMouseDown(x, y) return beginDrag(self) end
function PFC_Dashboard:onMouseMove(dx, dy) dragMove(self, dx, dy) end
function PFC_Dashboard:onMouseMoveOutside(dx, dy) self:onMouseMove(dx, dy) end
function PFC_Dashboard:onMouseUp(x, y)
    if not self.dragging then return end
    self.dragging = false
    PFC_Dashboard.savedX = self.x
    PFC_Dashboard.savedY = self.y
    return true
end
function PFC_Dashboard:onMouseUpOutside(x, y) self:onMouseUp(x, y) end

function PFC_DashboardFluidPanel:onMouseDown(x, y) return beginDrag(self) end
function PFC_DashboardFluidPanel:onMouseMove(dx, dy) dragMove(self, dx, dy) end
function PFC_DashboardFluidPanel:onMouseMoveOutside(dx, dy) self:onMouseMove(dx, dy) end
function PFC_DashboardFluidPanel:onMouseUp(x, y)
    if not self.dragging then return end
    self.dragging = false
    PFC_DashboardFluidPanel.savedX = self.x
    PFC_DashboardFluidPanel.savedY = self.y
    return true
end
function PFC_DashboardFluidPanel:onMouseUpOutside(x, y) self:onMouseUp(x, y) end

function PFC_Dashboard.closeAll()
    if PFC_Dashboard.instance then
        PFC_Dashboard.instance:removeFromUIManager()
        PFC_Dashboard.instance = nil
    end
    if PFC_DashboardFluidPanel.instance then
        PFC_DashboardFluidPanel.instance:removeFromUIManager()
        PFC_DashboardFluidPanel.instance = nil
    end
end

function PFC_Dashboard:update()
    ISPanel.update(self)
    if Scale.refresh() or self.lastScale ~= compactScale() then
        self.lastScale = compactScale()
        self:applyScale()
    end
    local vehicle = self:getVehicle()
    if not vehicle or not PFC.dashboardEnabled() then
        PFC_Dashboard.closeAll()
        return
    end
    clampToScreen(self)
    if vehicle:getId() ~= self.lastInitVehicle then
        self.lastInitVehicle = vehicle:getId()
        self.lastRequestMs = getTimestampMs and getTimestampMs() or 0
        if ProjectFadedCarClient then ProjectFadedCarClient.requestVehicleInit(vehicle) end
    end
end

function PFC_DashboardFluidPanel:update()
    ISPanel.update(self)
    if Scale.refresh() or self.lastScale ~= compactScale() then
        self.lastScale = compactScale()
        self:applyScale()
    end
    if not self:getVehicle() or not PFC.dashboardEnabled() then
        if PFC_DashboardFluidPanel.instance then
            PFC_DashboardFluidPanel.instance:removeFromUIManager()
            PFC_DashboardFluidPanel.instance = nil
        end
        return
    end
    clampToScreen(self)
end

function PFC_Dashboard:prerender()
    ISPanel.prerender(self)
    drawPanelBackground(self)
    local vehicle = self:getVehicle()
    if not vehicle then return end
    local layout = self:getLayout()
    local snapshot = PFC.getSnapshot(vehicle)
    if not snapshot then
        local now = getTimestampMs and getTimestampMs() or 0
        if now - (self.lastRequestMs or 0) > 1500 then
            self.lastRequestMs = now
            if ProjectFadedCarClient then ProjectFadedCarClient.requestVehicleInit(vehicle) end
        end
        self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_Syncing", "Syncing vehicle data"), layout.contentW, UIFont.Small), layout.pad, layout.textY, 0.76, 0.82, 0.80, 1, UIFont.Small)
        return
    end

    local x1 = layout.pad
    local x2 = x1 + layout.colW + layout.gap
    local engineValue = PFC.round(snapshot.engineCondition)
    local internalsValue = PFC.round(snapshot.average)
    self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_EngineHealth", "Engine") .. " " .. tostring(engineValue) .. "%", layout.colW, UIFont.Small), x1, layout.textY, 0.82, 0.88, 0.86, 1, UIFont.Small)
    self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_AvgInternals", "Internals") .. " " .. tostring(internalsValue) .. "%", layout.colW, UIFont.Small), x2, layout.textY, 0.82, 0.88, 0.86, 1, UIFont.Small)
    drawMiniBar(self, x1, layout.barY, layout.colW, layout.barH, engineValue)
    drawMiniBar(self, x2, layout.barY, layout.colW, layout.barH, internalsValue)

    local store = snapshot.store or {}
    local warning = tostring(store.warning or "")
    local status = PFC.text(PFC.diagnosticLabel(snapshot.diagnosticCode), PFC.text("IGUI_PFC_Diagnostic_OK", "Nominal"))
    local colorR, colorG, colorB = 0.62, 0.68, 0.66
    if warning ~= "" then
        status = PFC.text("IGUI_PFC_Hazard_" .. warning, status)
        colorR, colorG, colorB = 0.96, 0.30, 0.22
    elseif snapshot.csr then
        status = PFC.text("IGUI_PFC_CSRMode", "CSR mode")
        colorR, colorG, colorB = 0.42, 0.78, 0.92
    end
    self:drawText(Scale.trimToWidth(status, layout.contentW, UIFont.Small), layout.pad, layout.statusY, colorR, colorG, colorB, 1, UIFont.Small)
end

function PFC_DashboardFluidPanel:drawFluidRow(y, label, value)
    local layout = self:getLayout()
    local text = label .. " " .. tostring(PFC.round(value)) .. "%"
    self:drawText(Scale.trimToWidth(text, layout.labelW, UIFont.Small), layout.pad, y, 0.82, 0.88, 0.86, 1, UIFont.Small)
    drawMiniBar(self, layout.barX, y + math.floor(Scale.fontHeight(UIFont.Small) / 2), layout.barW, layout.barH, value)
end

function PFC_DashboardFluidPanel:prerender()
    ISPanel.prerender(self)
    drawPanelBackground(self)
    local vehicle = self:getVehicle()
    if not vehicle then return end
    local layout = self:getLayout()
    local snapshot = PFC.getSnapshot(vehicle)
    if not snapshot then
        self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_Syncing", "Syncing vehicle data"), self.width - layout.pad * 2, UIFont.Small), layout.pad, layout.firstY, 0.76, 0.82, 0.80, 1, UIFont.Small)
        return
    end
    local store = snapshot.store or {}
    self:drawFluidRow(layout.firstY, PFC.text("IGUI_PFC_Fluid_OilShort", "Oil"), store.oilLevel or 0)
    self:drawFluidRow(layout.firstY + layout.rowH, PFC.text("IGUI_PFC_Fluid_CoolantShort", "Cool"), store.coolantLevel or 0)
    self:drawFluidRow(layout.firstY + layout.rowH * 2, PFC.text("IGUI_PFC_Fluid_TransmissionShort", "ATF"), store.transmissionFluid or 0)
end

function PFC_Dashboard.open(playerIndex)
    if not PFC.dashboardEnabled() then return end
    if not PFC_Dashboard.instance then
        local ui = PFC_Dashboard:new(playerIndex or 0)
        ui:initialise()
        ui:instantiate()
        ui:addToUIManager()
        PFC_Dashboard.instance = ui
    end
    if not PFC_DashboardFluidPanel.instance then
        local fluid = PFC_DashboardFluidPanel:new(playerIndex or 0)
        fluid:initialise()
        fluid:instantiate()
        fluid:addToUIManager()
        PFC_DashboardFluidPanel.instance = fluid
    end
end

local function onEnterVehicle(character)
    if not character or not character.getPlayerNum then return end
    if not PFC.dashboardEnabled() then return end
    PFC_Dashboard.open(character:getPlayerNum())
end

local function onExitVehicle(character)
    PFC_Dashboard.closeAll()
end

local function onGameStart()
    local player = getPlayer and getPlayer() or nil
    if player and player:getVehicle() then
        PFC_Dashboard.open(player:getPlayerNum())
    end
end

if Events and Events.OnEnterVehicle then Events.OnEnterVehicle.Add(onEnterVehicle) end
if Events and Events.OnExitVehicle then Events.OnExitVehicle.Add(onExitVehicle) end
if Events and Events.OnGameStart then Events.OnGameStart.Add(onGameStart) end
