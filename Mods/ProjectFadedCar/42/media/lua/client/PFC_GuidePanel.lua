if isServer() then return end
if not ISPanel then
    print("[ProjectFadedCar] Guide panel skipped: ISPanel unavailable")
    return
end
require "PFC_UIScale"

PFC_GuidePanel = ISPanel:derive("PFC_GuidePanel")
PFC_GuidePanel.instance = nil

print("[ProjectFadedCar] Client guide panel module loaded")

local PFC = ProjectFadedCar
local Scale = PFC.UIScale or PFC_UIScale

local TAB_ACTIVE_BG = { r = 0.00, g = 0.45, b = 0.52, a = 0.42 }
local TAB_ACTIVE_BORDER = { r = 0.00, g = 0.90, b = 1.00, a = 0.80 }
local TAB_INACTIVE_BG = { r = 0.05, g = 0.06, b = 0.07, a = 0.55 }
local TAB_INACTIVE_BORDER = { r = 0.24, g = 0.26, b = 0.28, a = 0.70 }

local GUIDE_TABS = {
    {
        id = "overview",
        labelKey = "IGUI_PFC_GuideTab_Overview",
        fallback = "Overview",
        titleKey = "IGUI_PFC_GuideTitle_Overview",
        titleFallback = "What Project Faded Car Does",
        lines = {
            "Project Faded Car adds a deeper vehicle maintenance layer without replacing vehicle scripts.",
            "The Shop tracks virtual engine systems on the normal vehicle Engine part: cooling, oiling, ignition, belts, transmission, brake assist, steering pump, fluids, oil quality, and heat.",
            "Those values wear down while vehicles run, can affect vanilla engine condition, and are saved in vehicle part ModData.",
            "The Shop can also pull a usable engine into a Salvaged Engine item, install a stored engine into another vehicle, and rebuild supported vanilla wreck scripts back into rough drivable cars.",
            "Bad condition can cause heat, oil/coolant/ATF loss, battery drain, engine damage, stalling, service sparks, smoke, burns, or rare fire depending on sandbox settings.",
        },
    },
    {
        id = "use",
        labelKey = "IGUI_PFC_GuideTab_Use",
        fallback = "How To",
        titleKey = "IGUI_PFC_GuideTitle_Use",
        titleFallback = "How To Use The Shop",
        lines = {
            "Enter a vehicle, open vanilla mechanics near one, or right-click a supported wreck, then open The Shop from the dashboard button, floating button, or context option.",
            "Read the top diagnostics first: vanilla engine health, internal condition, weakest system, heat, oil quality, and current warning.",
            "To replace a system, carry the matching Project Faded Car service kit and press Replace on that row.",
            "Heater and Glove Box rows repair the real vehicle parts from inside The Shop; carry a Climate Control Kit or Glove Box Repair Kit and press Repair.",
            "To top up fluids, carry fresh motor oil, coolant mix, or transmission fluid and press Add.",
            "Use Tune to improve the overall engine with engine parts. Use Tow Assist to tune PFC's compatibility metadata for other vehicle systems.",
            "Use Pull with a wrench and enough Mechanics skill to store the current engine as a Salvaged Engine. Use Install with that item and two engine parts to swap it into the target vehicle.",
            "Use Restore on supported burnt or smashed vanilla wrecks when you have a welding torch, welder mask, rebuild materials, Mechanics skill, and Welding skill.",
            "If service is blocked, shut the engine off or move closer to the engine area.",
        },
    },
    {
        id = "supplies",
        labelKey = "IGUI_PFC_GuideTab_Supplies",
        fallback = "Supplies",
        titleKey = "IGUI_PFC_GuideTitle_Supplies",
        titleFallback = "Getting Parts And Fluids",
        lines = {
            "Select Base.EngineParts in inventory and use the Project Faded Car submenu to assemble service kits.",
            "Select small sheet metal to assemble a Glove Box Repair Kit.",
            "Select a water bottle to mix coolant.",
            "Fresh motor oil and transmission fluid spawn as Project Faded Car supplies in automotive loot.",
            "Engine installs consume two vanilla engine parts. Wreck restoration uses vanilla engine parts, sheet metal, small sheet metal, and electronics scrap unless that sandbox requirement is disabled.",
            "Supplies can also spawn in mechanic shops, gas stations, warehouses, car supply shelves, tool storage, farm and barn storage.",
            "Low Mechanics skill raises service failure risk, so early repairs may restore less and trigger more hazards.",
        },
    },
    {
        id = "compat",
        labelKey = "IGUI_PFC_GuideTab_Compat",
        fallback = "Mods",
        titleKey = "IGUI_PFC_GuideTitle_Compat",
        titleFallback = "When Other Mods Are Present",
        lines = {
            "Common Sense Reborn: PFC does not edit CSR. It detects CSR, keeps its dashboard compact, and writes PFC tow-assist metadata for future compatibility.",
            "IKappaID & Faded's True Real World Vehicle Physics: IKFRVP remains the physics authority. PFC shows bridge status, sends safe server-side requests, and asks IKFRVP to re-sync after engine swaps or wreck rebuilds.",
            "Vehicle packs: PFC usually works when the vehicle exposes a normal Engine part and vanilla mechanics can reach it. Engine-less trailers and custom nonstandard engine systems may be ignored.",
            "Project Summer Car: PFC declares it incompatible because this rebuild is meant to replace that style of gameplay, not run beside it.",
            "Multiplayer: real service, tuning, and physics bridge actions are validated server-side. Client UI is only a request surface.",
        },
    },
}

local function drawGuideFrame(panel)
    panel:drawRect(0, 0, panel.width, panel.height, 0.94, 0.012, 0.016, 0.020)
    panel:drawRectBorder(0, 0, panel.width, panel.height, 1.0, 0.00, 0.82, 0.92)
    panel:drawRectBorder(Scale.px(2), Scale.px(2), panel.width - Scale.px(4), panel.height - Scale.px(4), 0.55, 0.02, 0.48, 0.62)
    panel:drawRect(Scale.px(12), Scale.px(52), panel.width - Scale.px(24), 1, 0.75, 0.00, 0.70, 0.82)
    panel:drawRect(Scale.px(12), panel.height - Scale.px(42), panel.width - Scale.px(24), 1, 0.45, 0.00, 0.70, 0.82)
end

local function guidePanelSize()
    Scale.refresh()
    return Scale.windowSize(720, 520, 600, 420, 16)
end

function PFC_GuidePanel:new(x, y, w, h)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.012, g = 0.016, b = 0.020, a = 0.94 }
    o.borderColor = { r = 0.00, g = 0.82, b = 0.92, a = 1.0 }
    o.moveWithMouse = true
    o.activeTab = 1
    o.tabButtons = {}
    o.lastScale = Scale.factor()
    return o
end

function PFC_GuidePanel:getLayout()
    Scale.refresh()
    local pad = Scale.px(18)
    local gap = Scale.px(6)
    local buttonH = math.max(Scale.px(24, 20), Scale.fontHeight(UIFont.Small) + Scale.px(8))
    local closeText = PFC.text("IGUI_PFC_Close", "Close")
    local closeW = Scale.buttonWidth(closeText, 60)
    local close = { x = self.width - pad - closeW, y = Scale.px(10), w = closeW, h = buttonH }
    local tabY = Scale.px(58)
    local totalW = -gap
    local widths = {}
    for index, tab in ipairs(GUIDE_TABS) do
        local label = PFC.text(tab.labelKey, tab.fallback)
        widths[index] = Scale.buttonWidth(label, 94)
        totalW = totalW + widths[index] + gap
    end
    local available = self.width - pad * 2
    if totalW > available then
        local fitW = math.floor((available - gap * (#GUIDE_TABS - 1)) / #GUIDE_TABS)
        for index = 1, #GUIDE_TABS do
            widths[index] = math.max(Scale.px(70), fitW)
        end
    end
    local tabs = {}
    local x = pad
    for index = 1, #GUIDE_TABS do
        tabs[index] = { x = x, y = tabY, w = widths[index], h = buttonH }
        x = x + widths[index] + gap
    end
    local titleY = tabY + buttonH + Scale.px(14)
    local textY = titleY + Scale.fontHeight(UIFont.Medium) + Scale.px(16)
    return {
        pad = pad,
        close = close,
        tabs = tabs,
        buttonH = buttonH,
        titleY = titleY,
        textY = textY,
        footerY = self.height - Scale.px(28),
        textW = self.width - Scale.px(56),
    }
end

function PFC_GuidePanel:layoutControls()
    local layout = self:getLayout()
    Scale.setBounds(self.closeButton, layout.close.x, layout.close.y, layout.close.w, layout.close.h)
    for index, button in ipairs(self.tabButtons) do
        local tab = layout.tabs[index]
        if tab then
            Scale.setBounds(button, tab.x, tab.y, tab.w, tab.h)
        end
    end
end

function PFC_GuidePanel:applyScale()
    local w, h = guidePanelSize()
    if self.width ~= w or self.height ~= h then
        Scale.resizePanel(self, w, h)
        local x, y = Scale.centeredPosition(w, h, 8)
        self:setX(x)
        self:setY(y)
    end
    self:layoutControls()
    Scale.clampPanelToScreen(self, 8)
end

function PFC_GuidePanel:createChildren()
    ISPanel.createChildren(self)

    local layout = self:getLayout()
    self.closeButton = ISButton:new(layout.close.x, layout.close.y, layout.close.w, layout.close.h, PFC.text("IGUI_PFC_Close", "Close"), self, PFC_GuidePanel.onClose)
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self:addChild(self.closeButton)

    for index, tab in ipairs(GUIDE_TABS) do
        local label = PFC.text(tab.labelKey, tab.fallback)
        local bounds = layout.tabs[index]
        local btn = ISButton:new(bounds.x, bounds.y, bounds.w, bounds.h, label, self, PFC_GuidePanel.onTab)
        btn.internal = index
        btn:initialise()
        btn:instantiate()
        self:addChild(btn)
        self.tabButtons[index] = btn
    end
    self:layoutControls()
end

function PFC_GuidePanel:onClose()
    self:removeFromUIManager()
    PFC_GuidePanel.instance = nil
end

function PFC_GuidePanel:onTab(button)
    self.activeTab = button and button.internal or 1
end

function PFC_GuidePanel:update()
    ISPanel.update(self)
    if Scale.refresh() or self.lastScale ~= Scale.factor() then
        self.lastScale = Scale.factor()
        self:applyScale()
    end
    for index, button in ipairs(self.tabButtons) do
        if button then
            if index == self.activeTab then
                button.backgroundColor = TAB_ACTIVE_BG
                button.borderColor = TAB_ACTIVE_BORDER
            else
                button.backgroundColor = TAB_INACTIVE_BG
                button.borderColor = TAB_INACTIVE_BORDER
            end
        end
    end
end

function PFC_GuidePanel:prerender()
    ISPanel.prerender(self)
    drawGuideFrame(self)

    local layout = self:getLayout()
    local titleW = layout.close.x - Scale.px(18) - layout.pad
    self:drawText(Scale.trimToWidth(PFC.text("IGUI_PFC_GuideTitle", "The Shop Guide"), titleW, UIFont.Medium), Scale.px(18), Scale.px(14), 0.96, 0.96, 0.90, 1, UIFont.Medium)

    local tab = GUIDE_TABS[self.activeTab] or GUIDE_TABS[1]
    local title = PFC.text(tab.titleKey, tab.titleFallback)
    self:drawText(Scale.trimToWidth(title, layout.textW, UIFont.Medium), Scale.px(22), layout.titleY, 0.90, 0.96, 0.94, 1, UIFont.Medium)

    local y = layout.textY
    local lineH = Scale.lineH(UIFont.Small, 4)
    local maxY = layout.footerY - Scale.px(10)
    for _, paragraph in ipairs(tab.lines) do
        local wrapped = Scale.wrapToWidth(paragraph, layout.textW, UIFont.Small)
        for _, line in ipairs(wrapped) do
            if y + lineH > maxY then
                self:drawText("...", Scale.px(28), y, 0.74, 0.82, 0.80, 1, UIFont.Small)
                local footer = PFC.text("IGUI_PFC_GuideFooter", "The Shop changes PFC maintenance data. Other mods keep authority over their own systems.")
                self:drawText(Scale.trimToWidth(footer, layout.textW, UIFont.Small), Scale.px(18), layout.footerY, 0.54, 0.62, 0.60, 1, UIFont.Small)
                return
            end
            self:drawText(line, Scale.px(28), y, 0.74, 0.82, 0.80, 1, UIFont.Small)
            y = y + lineH
        end
        y = y + Scale.px(8)
    end

    local footer = PFC.text("IGUI_PFC_GuideFooter", "The Shop changes PFC maintenance data. Other mods keep authority over their own systems.")
    self:drawText(Scale.trimToWidth(footer, layout.textW, UIFont.Small), Scale.px(18), layout.footerY, 0.54, 0.62, 0.60, 1, UIFont.Small)
end

function PFC_GuidePanel.open()
    if PFC_GuidePanel.instance then
        PFC_GuidePanel.instance:applyScale()
        PFC_GuidePanel.instance:setVisible(true)
        PFC_GuidePanel.instance:bringToTop()
        return
    end

    local w, h = guidePanelSize()
    local x, y = Scale.centeredPosition(w, h, 8)
    local ui = PFC_GuidePanel:new(x, y, w, h)
    ui:initialise()
    ui:instantiate()
    ui:addToUIManager()
    PFC_GuidePanel.instance = ui
end
