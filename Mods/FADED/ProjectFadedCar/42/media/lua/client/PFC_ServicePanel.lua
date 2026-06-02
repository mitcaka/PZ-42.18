if isServer() then return end
if not ISPanel then
    print("[ProjectFadedCar] Service panel skipped: ISPanel unavailable")
    return
end
require "PFC_UIScale"

PFC_ServicePanel = ISPanel:derive("PFC_ServicePanel")
PFC_ServicePanel.instance = nil

print("[ProjectFadedCar] Client service panel module loaded")

local PFC = ProjectFadedCar
local Scale = PFC.UIScale or PFC_UIScale
local ENGINE_BAY_BACKGROUND = getTexture and getTexture("media/textures/PFC_EngineBayBackground.png") or nil

local function repairableVehicleParts()
    return PFC.REPAIRABLE_VEHICLE_PARTS or {}
end

local function shopPartCount()
    return #PFC.PARTS + #repairableVehicleParts()
end

local function shopPartAt(index)
    if index <= #PFC.PARTS then
        return PFC.PARTS[index], "engine"
    end
    return repairableVehicleParts()[index - #PFC.PARTS], "vehicle"
end

local function supplyCount()
    return #PFC.SUPPLIES
end

local function supplyAt(index)
    return PFC.SUPPLIES[index]
end

local function conditionColor(value)
    value = PFC.clamp(value, 0, 100)
    if value < 35 then return 0.94, 0.24, 0.18 end
    if value < 65 then return 0.95, 0.68, 0.22 end
    return 0.15, 0.76, 0.46
end

local function drawValueBar(panel, x, y, w, h, value)
    local r, g, b = conditionColor(value)
    panel:drawRect(x, y, w, h, 0.62, 0.035, 0.04, 0.045)
    panel:drawRectBorder(x, y, w, h, 0.75, 0.20, 0.22, 0.24)
    panel:drawRect(x + 1, y + 1, math.floor((w - 2) * PFC.clamp(value, 0, 100) / 100), h - 2, 0.92, r, g, b)
end

local function drawSectionLine(panel, y, title)
    local pad = Scale.px(18)
    panel:drawRect(pad, y, panel.width - (pad * 2), 1, 0.85, 0.00, 0.78, 0.92)
    panel:drawText(Scale.trimToWidth(title, panel.width - (pad * 2), UIFont.Small), pad + Scale.px(2), y + Scale.px(8), 0.96, 0.96, 0.90, 1, UIFont.Small)
end

local function drawNeonFrame(panel)
    panel:drawRectBorder(0, 0, panel.width, panel.height, 1.0, 0.00, 0.92, 1.00)
    panel:drawRectBorder(1, 1, panel.width - 2, panel.height - 2, 0.85, 0.02, 0.62, 0.82)
    panel:drawRectBorder(3, 3, panel.width - 6, panel.height - 6, 0.45, 0.00, 0.38, 0.52)
    panel:drawRect(0, 0, panel.width, 2, 0.22, 0.00, 0.92, 1.00)
    panel:drawRect(0, panel.height - 2, panel.width, 2, 0.18, 0.00, 0.92, 1.00)
    panel:drawRect(0, 0, 2, panel.height, 0.18, 0.00, 0.92, 1.00)
    panel:drawRect(panel.width - 2, 0, 2, panel.height, 0.18, 0.00, 0.92, 1.00)
end

local function drawPanelBackground(panel)
    local layout = panel.getLayout and panel:getLayout() or nil
    local inset = Scale.px(8)
    local bodyY = layout and layout.bodyY or Scale.px(102)
    local bodyBottom = layout and layout.bodyBottom or Scale.px(86)
    if ENGINE_BAY_BACKGROUND then
        panel:drawTextureScaled(ENGINE_BAY_BACKGROUND, 0, 0, panel.width, panel.height, 0.34, 1, 1, 1)
        local accent = Scale.px(330)
        panel:drawTextureScaled(ENGINE_BAY_BACKGROUND, panel.width - accent - Scale.px(50), Scale.px(92), accent, accent, 0.30, 0.86, 1, 1)
    end
    panel:drawRect(inset, inset, panel.width - (inset * 2), panel.height - (inset * 2), 0.40, 0.018, 0.024, 0.030)
    panel:drawRect(Scale.px(12), bodyY, panel.width - Scale.px(24), math.max(Scale.px(40), panel.height - bodyY - bodyBottom), 0.24, 0.018, 0.022, 0.026)
end

local function servicePanelSize()
    Scale.refresh()
    return Scale.windowSize(920, 730, 760, 620, 16)
end

function PFC_ServicePanel:new(x, y, w, h, playerIndex, vehicle)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.playerIndex = playerIndex or 0
    o.vehicle = vehicle
    o.backgroundColor = { r = 0.012, g = 0.016, b = 0.020, a = 0.94 }
    o.borderColor = { r = 0.00, g = 0.92, b = 1.00, a = 1.0 }
    o.moveWithMouse = true
    o.partButtons = {}
    o.vehiclePartButtons = {}
    o.fluidButtons = {}
    o.supplyButtons = {}
    o.mode = "service"
    o.lastRequestMs = 0
    o.lastScale = Scale.factor()
    return o
end

function PFC_ServicePanel:getLayout()
    Scale.refresh()
    local partRows = math.ceil(shopPartCount() / 2)
    local supplyRows = math.ceil(supplyCount() / 2)
    local pad = Scale.px(20)
    local gap = Scale.px(8)
    local buttonH = math.max(Scale.px(22, 20), Scale.fontHeight(UIFont.Small) + Scale.px(8))
    local contentX = pad
    local contentRight = self.width - pad
    local contentW = math.max(Scale.px(240), contentRight - contentX)
    local colGap = Scale.px(16)
    local partColW = math.floor((contentW - colGap) / 2)
    local headerBottom = math.max(Scale.px(102), Scale.px(84) + Scale.fontHeight(UIFont.Small) + Scale.px(16))
    local partTop = headerBottom + Scale.px(20)
    local partRowH = math.max(buttonH + Scale.px(4), Scale.lineH(UIFont.Small, 8))
    local fluidTop = partTop + (partRows * partRowH) + Scale.px(36)
    local fluidRowH = partRowH
    local minTuneTop = fluidTop + (#PFC.FLUIDS * fluidRowH) + Scale.px(34)
    local tuneTop = math.max(minTuneTop, self.height - Scale.px(124))
    local physicsTop = math.max(tuneTop + Scale.px(52), self.height - Scale.px(68))

    local topY = Scale.px(10)
    local topGap = Scale.px(8)
    local topRight = self.width - Scale.px(16)
    local topButtons = {}
    local function takeTop(name, text, baseW)
        local w = Scale.buttonWidth(text, baseW)
        topRight = topRight - w
        topButtons[name] = { x = topRight, y = topY, w = w, h = buttonH }
        topRight = topRight - topGap
    end
    takeTop("close", PFC.text("IGUI_PFC_Close", "Close"), 60)
    takeTop("guide", PFC.text("IGUI_PFC_GuideButton", "Guide"), 66)
    takeTop("restore", PFC.text("IGUI_PFC_RestoreWreck", "Restore"), 84)
    takeTop("install", PFC.text("IGUI_PFC_InstallEngine", "Install"), 82)
    takeTop("pull", PFC.text("IGUI_PFC_PullEngine", "Pull"), 76)
    takeTop("craft", PFC.text("IGUI_PFC_Craft", "Craft"), 74)
    takeTop("tune", PFC.text("IGUI_PFC_Tune", "Tune"), 70)

    local towButtonW = Scale.buttonWidth("+5", 46)
    local towButtonX = contentRight - towButtonW * 2 - gap

    local physicsTopRight = contentRight
    local physicsButtons = {}
    local function takePhysics(name, text, baseW)
        local w = Scale.buttonWidth(text, baseW)
        physicsTopRight = physicsTopRight - w
        physicsButtons[name] = { x = physicsTopRight, y = physicsTop, w = w, h = buttonH }
        physicsTopRight = physicsTopRight - gap
    end
    takePhysics("safe", PFC.text("IGUI_PFC_PhysicsSafeButton", "Safe Reset"), 96)
    takePhysics("retune", PFC.text("IGUI_PFC_PhysicsRetuneButton", "Retune"), 68)
    takePhysics("sync", PFC.text("IGUI_PFC_PhysicsSyncButton", "Sync"), 54)
    takePhysics("status", PFC.text("IGUI_PFC_PhysicsStatusButton", "Status"), 74)

    return {
        pad = pad,
        gap = gap,
        contentX = contentX,
        contentRight = contentRight,
        contentW = contentW,
        bodyY = headerBottom,
        bodyBottom = Scale.px(86),
        labelX = contentX,
        buttonX = contentRight - Scale.buttonWidth(PFC.text("IGUI_PFC_Add", "Add"), 100),
        buttonW = Scale.buttonWidth(PFC.text("IGUI_PFC_Add", "Add"), 100),
        buttonH = buttonH,
        topButtons = topButtons,
        partTop = partTop,
        partRowH = partRowH,
        partRows = partRows,
        supplyTop = partTop,
        supplyRowH = partRowH,
        supplyRows = supplyRows,
        partColW = partColW,
        partColGap = colGap,
        partButtonW = math.max(Scale.buttonWidth(PFC.text("IGUI_PFC_Replace", "Replace"), 68), Scale.buttonWidth(PFC.text("IGUI_PFC_Repair", "Repair"), 68)),
        fluidButtonW = Scale.buttonWidth(PFC.text("IGUI_PFC_Add", "Add"), 100),
        valueW = Scale.measure("100%", UIFont.Small) + Scale.px(8),
        partStatusW = math.max(math.max(Scale.measure(PFC.text("IGUI_PFC_Ready", "Ready"), UIFont.Small), Scale.measure(PFC.text("IGUI_PFC_NeedItem", "Need"), UIFont.Small)), Scale.measure(PFC.text("IGUI_PFC_MissingPart", "Missing part"), UIFont.Small)) + Scale.px(8),
        fluidStatusW = math.max(Scale.measure(PFC.text("IGUI_PFC_Ready", "Ready"), UIFont.Small), Scale.measure(PFC.text("IGUI_PFC_MissingItem", "Missing item"), UIFont.Small)) + Scale.px(8),
        supplyStatusW = math.max(math.max(Scale.measure(PFC.text("IGUI_PFC_Ready", "Ready"), UIFont.Small), Scale.measure(PFC.text("IGUI_PFC_NeedMaterials", "Need materials"), UIFont.Small)), Scale.measure(PFC.text("IGUI_PFC_NeedMechanics", "Need skill"), UIFont.Small)) + Scale.px(8),
        fluidTop = fluidTop,
        fluidRowH = fluidRowH,
        tuneTop = tuneTop,
        physicsTop = physicsTop,
        towButtonW = towButtonW,
        towButtonX = towButtonX,
        physicsButtons = physicsButtons,
        physicsTextRight = physicsTopRight,
    }
end

function PFC_ServicePanel:getPartRow(index)
    local layout = self:getLayout()
    local column = math.floor((index - 1) / layout.partRows)
    local row = (index - 1) % layout.partRows
    local x = layout.contentX + (column * (layout.partColW + layout.partColGap))
    local y = layout.partTop + (row * layout.partRowH)
    local buttonW = layout.partButtonW
    local buttonX = x + layout.partColW - buttonW
    local statusW = layout.partStatusW
    local valueW = layout.valueW
    local statusX = buttonX - statusW - layout.gap
    local valueX = statusX - valueW - layout.gap
    local labelW = math.max(Scale.px(78), math.min(Scale.px(132), math.floor(layout.partColW * 0.30)))
    local barX = x + labelW + layout.gap
    local barW = valueX - barX - layout.gap
    if barW < Scale.px(70) then
        labelW = math.max(Scale.px(62), labelW - (Scale.px(70) - barW))
        barX = x + labelW + layout.gap
        barW = math.max(Scale.px(48), valueX - barX - layout.gap)
    end
    return {
        labelX = x,
        labelW = math.max(Scale.px(24), barX - x - layout.gap),
        barX = barX,
        barW = barW,
        valueX = valueX,
        valueW = valueW,
        statusX = statusX,
        statusW = statusW,
        buttonX = buttonX,
        buttonW = buttonW,
        y = y,
    }
end

function PFC_ServicePanel:getSupplyRow(index)
    local layout = self:getLayout()
    local column = math.floor((index - 1) / layout.supplyRows)
    local row = (index - 1) % layout.supplyRows
    local x = layout.contentX + (column * (layout.partColW + layout.partColGap))
    local y = layout.supplyTop + (row * layout.supplyRowH)
    local buttonW = Scale.buttonWidth(PFC.text("IGUI_PFC_Craft", "Craft"), 74)
    local buttonX = x + layout.partColW - buttonW
    local statusW = layout.supplyStatusW
    local statusX = buttonX - statusW - layout.gap
    local labelW = math.max(Scale.px(110), math.floor(layout.partColW * 0.42))
    local reqX = x + labelW + layout.gap
    local reqW = math.max(Scale.px(58), statusX - reqX - layout.gap)
    return {
        labelX = x,
        labelW = math.max(Scale.px(60), labelW),
        reqX = reqX,
        reqW = reqW,
        statusX = statusX,
        statusW = statusW,
        buttonX = buttonX,
        buttonW = buttonW,
        y = y,
    }
end

function PFC_ServicePanel:getFluidRow(index)
    local layout = self:getLayout()
    local y = layout.fluidTop + ((index - 1) * layout.fluidRowH)
    local buttonW = layout.fluidButtonW
    local buttonX = layout.contentRight - buttonW
    local statusW = layout.fluidStatusW
    local valueW = layout.valueW
    local statusX = buttonX - statusW - layout.gap
    local valueX = statusX - valueW - layout.gap
    local labelW = math.max(Scale.px(142), Scale.measure(PFC.text("IGUI_PFC_Fluid_Transmission", "Transmission Fluid"), UIFont.Small) + Scale.px(8))
    local barX = layout.contentX + labelW + layout.gap
    local barW = math.max(Scale.px(90), valueX - barX - layout.gap)
    return {
        labelX = layout.labelX,
        labelW = labelW,
        barX = barX,
        barW = barW,
        valueX = valueX,
        valueW = valueW,
        statusX = statusX,
        statusW = statusW,
        buttonX = buttonX,
        buttonW = buttonW,
        y = y,
    }
end

function PFC_ServicePanel:getPlayer()
    return getSpecificPlayer and getSpecificPlayer(self.playerIndex) or getPlayer()
end

function PFC_ServicePanel:layoutControls()
    local layout = self:getLayout()
    local top = layout.topButtons or {}
    Scale.setBounds(self.closeButton, top.close and top.close.x, top.close and top.close.y, top.close and top.close.w, top.close and top.close.h)
    Scale.setBounds(self.guideButton, top.guide and top.guide.x, top.guide and top.guide.y, top.guide and top.guide.w, top.guide and top.guide.h)
    Scale.setBounds(self.restoreWreckButton, top.restore and top.restore.x, top.restore and top.restore.y, top.restore and top.restore.w, top.restore and top.restore.h)
    Scale.setBounds(self.installEngineButton, top.install and top.install.x, top.install and top.install.y, top.install and top.install.w, top.install and top.install.h)
    Scale.setBounds(self.pullEngineButton, top.pull and top.pull.x, top.pull and top.pull.y, top.pull and top.pull.w, top.pull and top.pull.h)
    Scale.setBounds(self.craftButton, top.craft and top.craft.x, top.craft and top.craft.y, top.craft and top.craft.w, top.craft and top.craft.h)
    Scale.setBounds(self.tuneButton, top.tune and top.tune.x, top.tune and top.tune.y, top.tune and top.tune.w, top.tune and top.tune.h)

    for index = 1, shopPartCount() do
        local spec, kind = shopPartAt(index)
        local row = self:getPartRow(index)
        local button = kind == "vehicle" and self.vehiclePartButtons[spec.id] or self.partButtons[spec.id]
        Scale.setBounds(button, row.buttonX, row.y - Scale.px(2), row.buttonW, layout.buttonH)
    end
    for index, spec in ipairs(PFC.FLUIDS) do
        local row = self:getFluidRow(index)
        Scale.setBounds(self.fluidButtons[spec.id], row.buttonX, row.y - Scale.px(2), row.buttonW, layout.buttonH)
    end
    for index, spec in ipairs(PFC.SUPPLIES) do
        local row = self:getSupplyRow(index)
        Scale.setBounds(self.supplyButtons[spec.id], row.buttonX, row.y - Scale.px(2), row.buttonW, layout.buttonH)
    end

    Scale.setBounds(self.towDownButton, layout.towButtonX, layout.tuneTop + Scale.px(28), layout.towButtonW, layout.buttonH)
    Scale.setBounds(self.towUpButton, layout.towButtonX + layout.towButtonW + layout.gap, layout.tuneTop + Scale.px(28), layout.towButtonW, layout.buttonH)

    local physics = layout.physicsButtons or {}
    Scale.setBounds(self.physicsStatusButton, physics.status and physics.status.x, physics.status and physics.status.y, physics.status and physics.status.w, physics.status and physics.status.h)
    Scale.setBounds(self.physicsSyncButton, physics.sync and physics.sync.x, physics.sync and physics.sync.y, physics.sync and physics.sync.w, physics.sync and physics.sync.h)
    Scale.setBounds(self.physicsRetuneButton, physics.retune and physics.retune.x, physics.retune and physics.retune.y, physics.retune and physics.retune.w, physics.retune and physics.retune.h)
    Scale.setBounds(self.physicsSafeButton, physics.safe and physics.safe.x, physics.safe and physics.safe.y, physics.safe and physics.safe.w, physics.safe and physics.safe.h)
end

function PFC_ServicePanel:applyScale()
    local w, h = servicePanelSize()
    if self.width ~= w or self.height ~= h then
        Scale.resizePanel(self, w, h)
        local x, y = Scale.centeredPosition(w, h, 8)
        self:setX(x)
        self:setY(y)
    end
    self:layoutControls()
    Scale.clampPanelToScreen(self, 8)
end

function PFC_ServicePanel:createChildren()
    ISPanel.createChildren(self)

    local layout = self:getLayout()
    local top = layout.topButtons

    self.closeButton = ISButton:new(top.close.x, top.close.y, top.close.w, top.close.h, PFC.text("IGUI_PFC_Close", "Close"), self, PFC_ServicePanel.onClose)
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self:addChild(self.closeButton)

    self.guideButton = ISButton:new(top.guide.x, top.guide.y, top.guide.w, top.guide.h, PFC.text("IGUI_PFC_GuideButton", "Guide"), self, PFC_ServicePanel.onGuide)
    self.guideButton:initialise()
    self.guideButton:instantiate()
    self:addChild(self.guideButton)

    self.restoreWreckButton = ISButton:new(top.restore.x, top.restore.y, top.restore.w, top.restore.h, PFC.text("IGUI_PFC_RestoreWreck", "Restore"), self, PFC_ServicePanel.onRestoreWreck)
    self.restoreWreckButton:initialise()
    self.restoreWreckButton:instantiate()
    self:addChild(self.restoreWreckButton)

    self.installEngineButton = ISButton:new(top.install.x, top.install.y, top.install.w, top.install.h, PFC.text("IGUI_PFC_InstallEngine", "Install"), self, PFC_ServicePanel.onInstallEngine)
    self.installEngineButton:initialise()
    self.installEngineButton:instantiate()
    self:addChild(self.installEngineButton)

    self.pullEngineButton = ISButton:new(top.pull.x, top.pull.y, top.pull.w, top.pull.h, PFC.text("IGUI_PFC_PullEngine", "Pull"), self, PFC_ServicePanel.onPullEngine)
    self.pullEngineButton:initialise()
    self.pullEngineButton:instantiate()
    self:addChild(self.pullEngineButton)

    self.craftButton = ISButton:new(top.craft.x, top.craft.y, top.craft.w, top.craft.h, PFC.text("IGUI_PFC_Craft", "Craft"), self, PFC_ServicePanel.onCraftToggle)
    self.craftButton:initialise()
    self.craftButton:instantiate()
    self:addChild(self.craftButton)

    self.tuneButton = ISButton:new(top.tune.x, top.tune.y, top.tune.w, top.tune.h, PFC.text("IGUI_PFC_Tune", "Tune"), self, PFC_ServicePanel.onTune)
    self.tuneButton:initialise()
    self.tuneButton:instantiate()
    self:addChild(self.tuneButton)

    for index = 1, shopPartCount() do
        local spec, kind = shopPartAt(index)
        local row = self:getPartRow(index)
        local label = kind == "vehicle" and PFC.text("IGUI_PFC_Repair", "Repair") or PFC.text("IGUI_PFC_Replace", "Replace")
        local btn = ISButton:new(row.buttonX, row.y - Scale.px(2), row.buttonW, layout.buttonH, label, self, PFC_ServicePanel.onReplacePart)
        btn.internal = spec.id
        btn.pfcKind = kind
        btn:initialise()
        btn:instantiate()
        self:addChild(btn)
        if kind == "vehicle" then
            self.vehiclePartButtons[spec.id] = btn
        else
            self.partButtons[spec.id] = btn
        end
    end

    for index, spec in ipairs(PFC.FLUIDS) do
        local row = self:getFluidRow(index)
        local btn = ISButton:new(row.buttonX, row.y - Scale.px(2), row.buttonW, layout.buttonH, PFC.text("IGUI_PFC_Add", "Add"), self, PFC_ServicePanel.onAddFluid)
        btn.internal = spec.id
        btn:initialise()
        btn:instantiate()
        self:addChild(btn)
        self.fluidButtons[spec.id] = btn
    end

    for index, spec in ipairs(PFC.SUPPLIES) do
        local row = self:getSupplyRow(index)
        local btn = ISButton:new(row.buttonX, row.y - Scale.px(2), row.buttonW, layout.buttonH, PFC.text("IGUI_PFC_Craft", "Craft"), self, PFC_ServicePanel.onCraftSupply)
        btn.internal = spec.id
        btn:initialise()
        btn:instantiate()
        if btn.setVisible then btn:setVisible(false) end
        self:addChild(btn)
        self.supplyButtons[spec.id] = btn
    end

    self.towDownButton = ISButton:new(layout.towButtonX, layout.tuneTop + Scale.px(28), layout.towButtonW, layout.buttonH, "-5", self, PFC_ServicePanel.onTowDown)
    self.towDownButton:initialise()
    self.towDownButton:instantiate()
    self:addChild(self.towDownButton)

    self.towUpButton = ISButton:new(layout.towButtonX + layout.towButtonW + layout.gap, layout.tuneTop + Scale.px(28), layout.towButtonW, layout.buttonH, "+5", self, PFC_ServicePanel.onTowUp)
    self.towUpButton:initialise()
    self.towUpButton:instantiate()
    self:addChild(self.towUpButton)

    local physics = layout.physicsButtons
    self.physicsStatusButton = ISButton:new(physics.status.x, physics.status.y, physics.status.w, physics.status.h, PFC.text("IGUI_PFC_PhysicsStatusButton", "Status"), self, PFC_ServicePanel.onPhysicsStatus)
    self.physicsStatusButton:initialise()
    self.physicsStatusButton:instantiate()
    self:addChild(self.physicsStatusButton)

    self.physicsSyncButton = ISButton:new(physics.sync.x, physics.sync.y, physics.sync.w, physics.sync.h, PFC.text("IGUI_PFC_PhysicsSyncButton", "Sync"), self, PFC_ServicePanel.onPhysicsSync)
    self.physicsSyncButton:initialise()
    self.physicsSyncButton:instantiate()
    self:addChild(self.physicsSyncButton)

    self.physicsRetuneButton = ISButton:new(physics.retune.x, physics.retune.y, physics.retune.w, physics.retune.h, PFC.text("IGUI_PFC_PhysicsRetuneButton", "Retune"), self, PFC_ServicePanel.onPhysicsRetune)
    self.physicsRetuneButton:initialise()
    self.physicsRetuneButton:instantiate()
    self:addChild(self.physicsRetuneButton)

    self.physicsSafeButton = ISButton:new(physics.safe.x, physics.safe.y, physics.safe.w, physics.safe.h, PFC.text("IGUI_PFC_PhysicsSafeButton", "Safe Reset"), self, PFC_ServicePanel.onPhysicsSafe)
    self.physicsSafeButton:initialise()
    self.physicsSafeButton:instantiate()
    self:addChild(self.physicsSafeButton)
    self:layoutControls()
end

function PFC_ServicePanel:onClose()
    self:removeFromUIManager()
    PFC_ServicePanel.instance = nil
end

function PFC_ServicePanel:onGuide()
    if PFC_GuidePanel and PFC_GuidePanel.open then
        PFC_GuidePanel.open()
    end
end

local function setButtonTitle(button, title)
    if not button then return end
    if button.setTitle then
        button:setTitle(title)
    else
        button.title = title
    end
end

function PFC_ServicePanel:onCraftToggle()
    self.mode = self.mode == "craft" and "service" or "craft"
    if self.craftButton then
        local key = self.mode == "craft" and "IGUI_PFC_Service" or "IGUI_PFC_Craft"
        local fallback = self.mode == "craft" and "Service" or "Craft"
        setButtonTitle(self.craftButton, PFC.text(key, fallback))
    end
end

function PFC_ServicePanel:onCraftSupply(button)
    local player = self:getPlayer()
    if ProjectFadedCarClient and button and button.internal then
        ProjectFadedCarClient.requestCraftSupply(player, button.internal)
    end
end

function PFC_ServicePanel:onTune()
    local player = self:getPlayer()
    if ProjectFadedCarClient then
        ProjectFadedCarClient.queueService(player, self.vehicle, "tuneEngine", "engine", 210)
    end
end

function PFC_ServicePanel:onPullEngine()
    local player = self:getPlayer()
    if ProjectFadedCarClient then
        ProjectFadedCarClient.queueService(player, self.vehicle, "pullEngine", "engine", 420)
    end
end

function PFC_ServicePanel:onInstallEngine()
    local player = self:getPlayer()
    if ProjectFadedCarClient then
        ProjectFadedCarClient.queueService(player, self.vehicle, "installEngine", "engine", 360)
    end
end

function PFC_ServicePanel:onRestoreWreck()
    local player = self:getPlayer()
    if ProjectFadedCarClient then
        ProjectFadedCarClient.queueService(player, self.vehicle, "restoreWreck", "vehicle", 820)
    end
end

function PFC_ServicePanel:onReplacePart(button)
    local player = self:getPlayer()
    if ProjectFadedCarClient then
        if button.pfcKind == "vehicle" then
            ProjectFadedCarClient.queueService(player, self.vehicle, "repairVehiclePart", button.internal, 210)
            return
        end
        ProjectFadedCarClient.queueService(player, self.vehicle, "replacePart", button.internal, 240)
    end
end

function PFC_ServicePanel:onAddFluid(button)
    local player = self:getPlayer()
    if ProjectFadedCarClient then
        ProjectFadedCarClient.queueService(player, self.vehicle, "addFluid", button.internal, 120)
    end
end

function PFC_ServicePanel:getTowAssist()
    local snapshot = PFC.getSnapshot(self.vehicle)
    local store = snapshot and snapshot.store or nil
    PFC.ensureStoreDefaults(store)
    return store and store.tuning and store.tuning.towAssist or 100
end

function PFC_ServicePanel:requestTowAssist(value)
    local blocked = PFC.serviceBlocked and PFC.serviceBlocked(self.vehicle)
    if blocked then return end
    local player = self:getPlayer()
    if ProjectFadedCarClient then
        ProjectFadedCarClient.requestTune(player, self.vehicle, "towAssist", PFC.clamp(value, 75, 125))
    end
end

function PFC_ServicePanel:onTowDown()
    self:requestTowAssist(self:getTowAssist() - 5)
end

function PFC_ServicePanel:onTowUp()
    self:requestTowAssist(self:getTowAssist() + 5)
end

function PFC_ServicePanel:requestPhysics(action)
    local player = self:getPlayer()
    if ProjectFadedCarClient and ProjectFadedCarClient.requestPhysicsBridge then
        ProjectFadedCarClient.requestPhysicsBridge(action, player, self.vehicle)
    end
end

function PFC_ServicePanel:onPhysicsStatus()
    self:requestPhysics("status")
end

function PFC_ServicePanel:onPhysicsSync()
    self:requestPhysics("syncVehicle")
end

function PFC_ServicePanel:onPhysicsRetune()
    self:requestPhysics("retune")
end

function PFC_ServicePanel:onPhysicsSafe()
    self:requestPhysics("safeHandling")
end

function PFC_ServicePanel:update()
    ISPanel.update(self)
    if Scale.refresh() or self.lastScale ~= Scale.factor() then
        self.lastScale = Scale.factor()
        self:applyScale()
    end
    if not self.vehicle or not PFC.engineBayEnabled() then
        self:onClose()
        return
    end
    local snapshot = PFC.getSnapshot(self.vehicle)
    if not snapshot then
        local now = getTimestampMs and getTimestampMs() or 0
        if now - (self.lastRequestMs or 0) > 1500 then
            self.lastRequestMs = now
            if ProjectFadedCarClient then ProjectFadedCarClient.requestVehicleInit(self.vehicle) end
        end
    end

    local player = self:getPlayer()
    local blocked = PFC.serviceBlocked and PFC.serviceBlocked(self.vehicle)
    local store = snapshot and snapshot.store or nil
    local serviceMode = self.mode ~= "craft"
    for _, spec in ipairs(PFC.PARTS) do
        local btn = self.partButtons[spec.id]
        if btn then
            if btn.setVisible then btn:setVisible(serviceMode) end
            local hasItem = ProjectFadedCarClient and ProjectFadedCarClient.hasServiceItem(player, spec)
            local value = store and store.parts and PFC.clamp(store.parts[spec.id] or 0, 0, 100) or 100
            btn.enable = serviceMode and hasItem == true and not blocked and value < 100
        end
    end
    for _, spec in ipairs(repairableVehicleParts()) do
        local btn = self.vehiclePartButtons[spec.id]
        if btn then
            if btn.setVisible then btn:setVisible(serviceMode) end
            local canRepair = PFC.canRepairVehiclePart and PFC.canRepairVehiclePart(player, self.vehicle, spec.id) == true
            btn.enable = serviceMode and canRepair == true
        end
    end
    for _, spec in ipairs(PFC.FLUIDS) do
        local btn = self.fluidButtons[spec.id]
        if btn then
            if btn.setVisible then btn:setVisible(serviceMode) end
            local hasItem = PFC.hasFluidItem and PFC.hasFluidItem(player, spec)
            local value = store and PFC.clamp(store[spec.id] or 0, 0, 100) or 100
            btn.enable = serviceMode and hasItem == true and not blocked and value < 100
        end
    end
    for _, spec in ipairs(PFC.SUPPLIES) do
        local btn = self.supplyButtons[spec.id]
        if btn then
            if btn.setVisible then btn:setVisible(not serviceMode) end
            local canCraft = PFC.canCraftSupply and PFC.canCraftSupply(player, spec.id) == true
            btn.enable = not serviceMode and canCraft == true
        end
    end
    if self.tuneButton then
        local hasEngineParts = false
        if ProjectFadedCarClient then
            hasEngineParts = ProjectFadedCarClient.hasItem(player, "Base.EngineParts") or ProjectFadedCarClient.hasItem(player, "EngineParts")
        end
        self.tuneButton.enable = hasEngineParts == true and PFC.getEnginePart(self.vehicle) ~= nil and not blocked and (not snapshot or snapshot.average < 100 or snapshot.engineCondition < 100)
    end
    if self.pullEngineButton then
        self.pullEngineButton.enable = PFC.canPullEngine and PFC.canPullEngine(player, self.vehicle) == true
    end
    if self.installEngineButton then
        self.installEngineButton.enable = PFC.canInstallEngine and PFC.canInstallEngine(player, self.vehicle) == true
    end
    if self.restoreWreckButton then
        self.restoreWreckButton.enable = PFC.canRestoreWreck and PFC.canRestoreWreck(player, self.vehicle) == true
    end
    if self.towDownButton and self.towUpButton then
        local tow = self:getTowAssist()
        self.towDownButton.enable = not blocked and tow > 75
        self.towUpButton.enable = not blocked and tow < 125
    end
    if self.physicsStatusButton and self.physicsSyncButton and self.physicsRetuneButton and self.physicsSafeButton then
        local physics = PFC.IKFRVPBridge and PFC.IKFRVPBridge.status(self.vehicle) or nil
        local active = physics and physics.active == true
        local loaded = physics and physics.loaded == true
        local admin = PFC.IKFRVPBridge and PFC.IKFRVPBridge.hasAdminAccess(player) or false
        self.physicsStatusButton.enable = active
        self.physicsSyncButton.enable = loaded and self.vehicle ~= nil
        self.physicsRetuneButton.enable = loaded and admin
        self.physicsSafeButton.enable = loaded and admin
    end
end

function PFC_ServicePanel:drawHeader(snapshot)
    local layout = self:getLayout()
    local titleRight = layout.topButtons and layout.topButtons.tune and (layout.topButtons.tune.x - layout.gap) or (self.width - layout.pad)
    self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_EngineBay", "The Shop"), titleRight - Scale.px(18), UIFont.Medium), Scale.px(18), Scale.px(12), 0.96, 0.96, 0.90, 1, UIFont.Medium)
    if not snapshot then return end

    local label = Scale.trimToWidth(snapshot.vehicleLabel or PFC.getVehicleLabel(self.vehicle), layout.contentW, UIFont.Small)
    self:drawText(label, layout.contentX, Scale.px(40), 0.70, 0.76, 0.75, 1, UIFont.Small)

    local diag = PFC.text(PFC.diagnosticLabel(snapshot.diagnosticCode), PFC.text("IGUI_PFC_Diagnostic_OK", "Nominal"))
    local weakest = snapshot.worstPart and PFC.text(snapshot.worstPart.labelKey, snapshot.worstPart.id) or PFC.text("IGUI_PFC_None", "None")
    local speed = PFC.round(PFC.vehicleSpeed(self.vehicle))
    local heat = PFC.round(snapshot.store and snapshot.store.engineHeat or 70)
    local oilQuality = PFC.round(snapshot.store and snapshot.store.oilQuality or 0)

    local gap = layout.gap
    local x = layout.contentX
    local statY = Scale.px(64)
    local statW1 = math.floor(layout.contentW * 0.18)
    local statW2 = math.floor(layout.contentW * 0.20)
    local statW3 = layout.contentW - statW1 - statW2 - gap * 2
    local engineText = PFC.text("IGUI_PFC_EngineHealth", "Engine") .. ": " .. tostring(PFC.round(snapshot.engineCondition)) .. "%"
    local internalText = PFC.text("IGUI_PFC_AvgInternals", "Internals") .. ": " .. tostring(PFC.round(snapshot.average)) .. "%"
    local diagText = PFC.text("IGUI_PFC_Diagnostic", "Diagnostic") .. ": " .. diag
    self:drawText(Scale.trimToWidth(engineText, statW1, UIFont.Small), x, statY, 0.76, 0.82, 0.80, 1, UIFont.Small)
    self:drawText(Scale.trimToWidth(internalText, statW2, UIFont.Small), x + statW1 + gap, statY, 0.76, 0.82, 0.80, 1, UIFont.Small)
    self:drawText(Scale.trimToWidth(diagText, statW3, UIFont.Small), x + statW1 + statW2 + gap * 2, statY, 0.76, 0.82, 0.80, 1, UIFont.Small)

    local infoY = Scale.px(84)
    local weakestW = math.floor(layout.contentW * 0.32)
    local oilW = math.floor(layout.contentW * 0.18)
    local heatW = math.floor(layout.contentW * 0.13)
    local speedW = math.floor(layout.contentW * 0.16)
    local warningW = layout.contentW - weakestW - oilW - heatW - speedW - gap * 4
    local infoX = layout.contentX
    self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_Weakest", "Weakest") .. ": " .. weakest .. " " .. tostring(PFC.round(snapshot.worstValue)) .. "%", weakestW, UIFont.Small), infoX, infoY, 0.62, 0.68, 0.66, 1, UIFont.Small)
    infoX = infoX + weakestW + gap
    self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_OilQuality", "Oil quality") .. ": " .. tostring(oilQuality) .. "%", oilW, UIFont.Small), infoX, infoY, 0.62, 0.68, 0.66, 1, UIFont.Small)
    infoX = infoX + oilW + gap
    self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_Heat", "Heat") .. ": " .. tostring(heat) .. "C", heatW, UIFont.Small), infoX, infoY, 0.62, 0.68, 0.66, 1, UIFont.Small)
    infoX = infoX + heatW + gap
    self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_Speed", "Speed") .. ": " .. tostring(speed) .. " km/h", speedW, UIFont.Small), infoX, infoY, 0.62, 0.68, 0.66, 1, UIFont.Small)

    if PFC.requireEngineOff() and self.vehicle.isEngineRunning and self.vehicle:isEngineRunning() then
        infoX = infoX + speedW + gap
        self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_EngineMustBeOff", "Engine must be off for service"), warningW, UIFont.Small), infoX, infoY, 0.94, 0.38, 0.28, 1, UIFont.Small)
    end
end

function PFC_ServicePanel:drawServiceRows(snapshot)
    local layout = self:getLayout()
    local store = snapshot.store
    local player = self:getPlayer()

    drawSectionLine(self, layout.partTop - Scale.px(24), PFC.text("IGUI_PFC_Systems", "Systems"))
    for index = 1, shopPartCount() do
        local spec, kind = shopPartAt(index)
        local row = self:getPartRow(index)
        local y = row.y
        local value = 100
        local missingPart = false
        if kind == "vehicle" then
            value = PFC.vehiclePartConditionPercent and PFC.vehiclePartConditionPercent(self.vehicle, spec.id) or nil
            missingPart = value == nil
            value = value or 100
        else
            value = PFC.clamp(store.parts and store.parts[spec.id] or 0, 0, 100)
        end
        local hasItem = ProjectFadedCarClient and ProjectFadedCarClient.hasServiceItem(player, spec)
        self:drawText(Scale.trimToWidth(PFC.text(spec.labelKey, spec.id), row.labelW, UIFont.Small), row.labelX, y, 0.90, 0.92, 0.88, 1, UIFont.Small)
        drawValueBar(self, row.barX, y, row.barW, Scale.px(18, 12), value)
        self:drawText(tostring(PFC.round(value)) .. "%", row.valueX, y + 1, 0.90, 0.92, 0.88, 1, UIFont.Small)
        if missingPart then
            self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_MissingPart", "Missing part"), row.statusW, UIFont.Small), row.statusX, y + 1, 0.78, 0.46, 0.36, 1, UIFont.Small)
        elseif hasItem then
            self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_Ready", "Ready"), row.statusW, UIFont.Small), row.statusX, y + 1, 0.44, 0.78, 0.54, 1, UIFont.Small)
        else
            self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_NeedItem", "Need"), row.statusW, UIFont.Small), row.statusX, y + 1, 0.78, 0.46, 0.36, 1, UIFont.Small)
        end
    end

    drawSectionLine(self, layout.fluidTop - Scale.px(28), PFC.text("IGUI_PFC_Fluids", "Fluids"))
    for index, spec in ipairs(PFC.FLUIDS) do
        local row = self:getFluidRow(index)
        local y = row.y
        local value = PFC.clamp(store[spec.id] or 0, 0, 100)
        local hasItem = PFC.hasFluidItem and PFC.hasFluidItem(player, spec)
        self:drawText(Scale.trimToWidth(PFC.text(spec.labelKey, spec.id), row.labelW, UIFont.Small), row.labelX, y, 0.90, 0.92, 0.88, 1, UIFont.Small)
        drawValueBar(self, row.barX, y, row.barW, Scale.px(18, 12), value)
        self:drawText(tostring(PFC.round(value)) .. "%", row.valueX, y + 1, 0.90, 0.92, 0.88, 1, UIFont.Small)
        if hasItem then
            self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_Ready", "Ready"), row.statusW, UIFont.Small), row.statusX, y + 1, 0.44, 0.78, 0.54, 1, UIFont.Small)
        else
            self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_MissingItem", "Missing item"), row.statusW, UIFont.Small), row.statusX, y + 1, 0.78, 0.46, 0.36, 1, UIFont.Small)
        end
    end
end

function PFC_ServicePanel:drawCraftRows()
    local layout = self:getLayout()
    local player = self:getPlayer()

    drawSectionLine(self, layout.supplyTop - Scale.px(24), PFC.text("IGUI_PFC_Crafting", "Crafting"))
    for index = 1, supplyCount() do
        local spec = supplyAt(index)
        local row = self:getSupplyRow(index)
        local y = row.y
        local canCraft, reason = false, "missing-item"
        if PFC.canCraftSupply then
            canCraft, reason = PFC.canCraftSupply(player, spec.id)
        end
        local label = PFC.text(spec.labelKey, spec.id)
        local requirements = PFC.supplyRequirementText and PFC.supplyRequirementText(spec) or ""
        self:drawText(Scale.trimToWidth(label, row.labelW, UIFont.Small), row.labelX, y, 0.90, 0.92, 0.88, 1, UIFont.Small)
        self:drawText(Scale.trimToWidth(requirements, row.reqW, UIFont.Small), row.reqX, y + 1, 0.62, 0.68, 0.66, 1, UIFont.Small)
        if canCraft then
            self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_Ready", "Ready"), row.statusW, UIFont.Small), row.statusX, y + 1, 0.44, 0.78, 0.54, 1, UIFont.Small)
        elseif reason == "low-mechanics" then
            self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_NeedMechanics", "Need skill"), row.statusW, UIFont.Small), row.statusX, y + 1, 0.78, 0.46, 0.36, 1, UIFont.Small)
        else
            self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_NeedMaterials", "Need materials"), row.statusW, UIFont.Small), row.statusX, y + 1, 0.78, 0.46, 0.36, 1, UIFont.Small)
        end
    end
end

function PFC_ServicePanel:drawTuning(snapshot)
    local layout = self:getLayout()
    local store = snapshot.store
    PFC.ensureStoreDefaults(store)
    local tow = store.tuning and store.tuning.towAssist or 100
    local effectiveTow = store.csrBridge and store.csrBridge.effectiveTowAssist or tow
    local csrStatus = snapshot.csr and PFC.text("IGUI_PFC_CSRDetected", "CSR detected") or PFC.text("IGUI_PFC_CSRStandby", "CSR standby")
    local bridge = PFC.text("IGUI_PFC_CSRBridge", "CSR bridge") .. ": " .. csrStatus

    drawSectionLine(self, layout.tuneTop - Scale.px(16), PFC.text("IGUI_PFC_Tuning", "Tuning"))
    local tuneY = layout.tuneTop + Scale.px(28)
    local tuneTextRight = layout.towButtonX - layout.gap
    local tuneTextW = math.max(Scale.px(120), tuneTextRight - layout.contentX)
    local towW = math.floor(tuneTextW * 0.48)
    local bridgeX = layout.contentX + towW + layout.gap
    local bridgeW = tuneTextRight - bridgeX
    self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_TowAssist", "Tow assist") .. ": " .. tostring(tow) .. "% / " .. tostring(effectiveTow) .. "%", towW, UIFont.Small), layout.contentX, tuneY, 0.90, 0.92, 0.88, 1, UIFont.Small)
    self:drawText(Scale.trimToWidth(bridge, bridgeW, UIFont.Small), bridgeX, tuneY, 0.62, 0.68, 0.66, 1, UIFont.Small)

    local physics = PFC.IKFRVPBridge and PFC.IKFRVPBridge.status(self.vehicle) or nil
    local physicsLabel = PFC.text("IGUI_PFC_PhysicsBridge", "Physics bridge")
    local physicsText = PFC.text("IGUI_PFC_PhysicsMissing", "IKFRVP not detected")
    local physicsDetail = ""
    if physics and physics.active and not physics.loaded then
        physicsText = PFC.text("IGUI_PFC_PhysicsWaiting", "IKFRVP detected, bridge waiting")
    elseif physics and physics.loaded then
        local mode = physics.profileTuning and PFC.text("IGUI_PFC_PhysicsRoster", "roster") or PFC.text("IGUI_PFC_PhysicsGeneric", "generic")
        if not physics.profileTuning and not physics.genericTuning then
            mode = PFC.text("IGUI_PFC_PhysicsReadOnly", "read-only")
        end
        local profile = physics.profileId ~= "" and physics.profileId or PFC.text("IGUI_PFC_PhysicsUnknownProfile", "unknown")
        physicsText = PFC.text("IGUI_PFC_PhysicsActive", "IKFRVP active") .. " / " .. mode .. " / " .. profile
        physicsDetail = PFC.text("IGUI_PFC_PhysicsPower", "Power") .. " " .. PFC.formatPhysicsNumber(physics.powerScale)
            .. "  " .. PFC.text("IGUI_PFC_PhysicsTorque", "Torque") .. " " .. PFC.formatPhysicsNumber(physics.engineTorqueMult)
            .. "  " .. PFC.text("IGUI_PFC_PhysicsMass", "Mass") .. " " .. PFC.formatPhysicsNumber(physics.massScale)
            .. "  " .. PFC.text("IGUI_PFC_PhysicsBrake", "Brake") .. " " .. PFC.formatPhysicsNumber(physics.brakeBaseRetain)
            .. "  " .. PFC.text("IGUI_PFC_PhysicsTrunk", "Trunk") .. " " .. PFC.formatPhysicsNumber(physics.trunkCapacityMult)
        if physics.glitchTripped then
            physicsDetail = PFC.text("IGUI_PFC_PhysicsGlitchGuardTripped", "Glitch guard tripped") .. ": " .. tostring(physics.tripReason or "")
        elseif physics.handlingPhysics then
            physicsDetail = physicsDetail .. "  " .. PFC.text("IGUI_PFC_PhysicsAdvancedHandling", "Advanced handling")
        end
    end
    local physicsTextRight = (layout.physicsButtons and layout.physicsButtons.status and layout.physicsButtons.status.x or layout.contentRight) - layout.gap
    local physicsTextW = math.max(Scale.px(120), physicsTextRight - layout.contentX)
    self:drawText(Scale.trimToWidth(physicsLabel .. ": " .. physicsText, physicsTextW, UIFont.Small), layout.contentX, layout.physicsTop + Scale.px(2), 0.78, 0.84, 0.82, 1, UIFont.Small)
    if physicsDetail ~= "" then
        self:drawText(Scale.trimToWidth(physicsDetail, physicsTextW, UIFont.Small), layout.contentX, layout.physicsTop + Scale.px(26), 0.56, 0.64, 0.62, 1, UIFont.Small)
    end

    local last = store.history and store.history[1] or nil
    if last then
        local text = PFC.text("IGUI_PFC_LastService", "Last service") .. ": " .. tostring(last.action) .. " " .. tostring(last.target) .. " @" .. tostring(last.hour) .. "h"
        self:drawText(Scale.trimToWidth(text, layout.contentW, UIFont.Small), Scale.px(18), self.height - Scale.lineH(UIFont.Small, 2), 0.62, 0.68, 0.66, 1, UIFont.Small)
    end
end

function PFC_ServicePanel:prerender()
    ISPanel.prerender(self)
    drawPanelBackground(self)
    drawNeonFrame(self)
    local snapshot = PFC.getSnapshot(self.vehicle)
    if not snapshot then
        local layout = self:getLayout()
        self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_EngineBay", "The Shop"), layout.contentW, UIFont.Medium), Scale.px(18), Scale.px(12), 0.96, 0.96, 0.90, 1, UIFont.Medium)
        self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_Syncing", "Syncing vehicle data"), layout.contentW, UIFont.Small), Scale.px(18), Scale.px(48), 0.76, 0.82, 0.80, 1, UIFont.Small)
        return
    end

    self:drawHeader(snapshot)
    if self.mode == "craft" then
        self:drawCraftRows()
    else
        self:drawServiceRows(snapshot)
    end
    self:drawTuning(snapshot)
end

function PFC_ServicePanel.open(playerIndex, vehicle)
    if PFC_ServicePanel.instance then
        PFC_ServicePanel.instance:removeFromUIManager()
        PFC_ServicePanel.instance = nil
    end
    if not vehicle then return end
    local w, h = servicePanelSize()
    local x, y = Scale.centeredPosition(w, h, 8)
    local ui = PFC_ServicePanel:new(x, y, w, h, playerIndex, vehicle)
    ui:initialise()
    ui:instantiate()
    ui:addToUIManager()
    PFC_ServicePanel.instance = ui
end
