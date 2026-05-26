-- FHC_HunterGUI.lua
-- The main collapsable window. Owns the tab bar, header decoration and the panel area.

require "ISUI/ISCollapsableWindow"
require "FHC_Constants"
require "FHC_Sandbox"
require "FHC_Utils"

if isServer() then return end

FHC.UI = FHC.UI or {}

FHC_HunterGUI = ISCollapsableWindow:derive("FHC_HunterGUI")
FHC_HunterGUI.instance = nil

local U  = FHC.Utils
local SB = FHC.SB
local C  = FHC.COLOR

local W, H = 860, 660

local function drawLeather(ui, x, y, w, h)
    -- Subtle leather panel — dark brown body, lighter top, brass border.
    ui:drawRect(x, y, w, h, 1.0, C.LeatherDark.r, C.LeatherDark.g, C.LeatherDark.b)
    ui:drawRect(x, y, w, 24, 1.0, C.Leather.r, C.Leather.g, C.Leather.b)
    ui:drawRectBorder(x, y, w, h, 1.0, C.Brass.r, C.Brass.g, C.Brass.b)
end

local function drawParchment(ui, x, y, w, h)
    ui:drawRect(x, y, w, h, 1.0, C.Parchment.r, C.Parchment.g, C.Parchment.b)
    ui:drawRectBorder(x, y, w, h, 1.0, C.LeatherDark.r, C.LeatherDark.g, C.LeatherDark.b)
end

function FHC_HunterGUI:initialise()
    ISCollapsableWindow.initialise(self)
    self.hubBadge = getTexture("media/ui/FHC_HubBadge.png")
    self.hubBackground = self.hubBadge
end

function FHC_HunterGUI:createChildren()
    ISCollapsableWindow.createChildren(self)
    self.title = getText("IGUI_FHC_WindowTitle")

    local headerH = 56
    local tabH    = 28
    local bottomBtnH = 26
    local pad = 10

    -- Header (logo strip)
    self.headerY = 18
    self.headerH = headerH

    -- Tab bar
    self.tabY = self.headerY + self.headerH + pad
    self.tabH = tabH
    self.tabs = {}
    self.activeTab = "journal"

    local tabDefs = {
        { id = "journal",   label = getText("IGUI_FHC_Tab_Journal") },
        { id = "guide",     label = getText("IGUI_FHC_Tab_Guide") },
        { id = "calls",     label = getText("IGUI_FHC_Tab_Calls") },
        { id = "trapping",  label = getText("IGUI_FHC_Tab_Trapping") },
        { id = "bushcraft", label = getText("IGUI_FHC_Tab_Bushcraft") },
        { id = "field",     label = getText("IGUI_FHC_Tab_FieldDress") },
        { id = "tools",     label = getText("IGUI_FHC_Tab_Tools") },
        { id = "tracking",  label = getText("IGUI_FHC_Tab_Tracking") },
        { id = "server",    label = getText("IGUI_FHC_Tab_Server") },
        { id = "settings",  label = getText("IGUI_FHC_Tab_Settings") },
    }
    local tabW = math.floor((self:getWidth() - pad * 2) / #tabDefs)
    for i, def in ipairs(tabDefs) do
        local btn = ISButton:new(pad + (i - 1) * tabW, self.tabY, tabW, self.tabH, def.label, self, FHC_HunterGUI.onTabClick)
        btn.internal = def.id
        btn:initialise(); btn:instantiate()
        btn.borderColor = { r = C.Brass.r, g = C.Brass.g, b = C.Brass.b, a = 1 }
        btn.backgroundColor = { r = C.Leather.r, g = C.Leather.g, b = C.Leather.b, a = 1 }
        btn.backgroundColorMouseOver = { r = C.LeatherLight.r, g = C.LeatherLight.g, b = C.LeatherLight.b, a = 1 }
        btn:setFont(UIFont.Small)
        self:addChild(btn)
        table.insert(self.tabs, btn)
    end

    -- Tab content area
    self.contentX = pad
    self.contentY = self.tabY + self.tabH + pad
    self.contentW = self:getWidth() - pad * 2
    self.contentH = self:getHeight() - self.contentY - bottomBtnH - pad * 2

    -- Per-tab panel cache
    self.panels = {}
    if FHC.UI.Tabs then
        for id, ctor in pairs(FHC.UI.Tabs) do
            local panel = ctor(self.contentX, self.contentY, self.contentW, self.contentH, self.player)
            panel:initialise(); panel:instantiate(); panel:setVisible(false)
            self:addChild(panel)
            self.panels[id] = panel
        end
    end
    -- Show default
    self:showTab(self.activeTab)

    -- Footer: close
    local closeBtn = ISButton:new(self:getWidth() - 90 - pad, self:getHeight() - bottomBtnH - pad,
        90, bottomBtnH, getText("IGUI_FHC_Close"), self, function(s) s:close() end)
    closeBtn:initialise(); closeBtn:instantiate()
    closeBtn.borderColor = { r = C.Brass.r, g = C.Brass.g, b = C.Brass.b, a = 1 }
    closeBtn.backgroundColor = { r = C.LeatherDark.r, g = C.LeatherDark.g, b = C.LeatherDark.b, a = 1 }
    self:addChild(closeBtn)
end

function FHC_HunterGUI:showTab(id)
    self.activeTab = id
    for tid, panel in pairs(self.panels) do
        panel:setVisible(tid == id)
        if panel.onShow and tid == id then U.safe(function() panel:onShow() end, "tab:onShow") end
    end
    for _, btn in ipairs(self.tabs) do
        if btn.internal == id then
            btn.backgroundColor = { r = C.Amber.r, g = C.Amber.g, b = C.Amber.b, a = 1 }
        else
            btn.backgroundColor = { r = C.Leather.r, g = C.Leather.g, b = C.Leather.b, a = 1 }
        end
    end
    -- Remember
    if self.player then
        self.player:getModData()[FHC.MD.PlayerLastOpenTab] = id
    end
end

function FHC_HunterGUI:onTabClick(button)
    self:showTab(button.internal)
end

function FHC_HunterGUI:prerender()
    ISCollapsableWindow.prerender(self)
    -- Header decoration (leather + amber line)
    drawLeather(self, 6, self.headerY, self:getWidth() - 12, self.headerH)
    if self.hubBadge then
        self:drawTextureScaled(self.hubBadge, 12, self.headerY + 2, 52, 52, 1.0, 1.0, 1.0, 1.0)
    end
    self:drawText(getText("IGUI_FHC_HeaderSubtitle"),
        76, self.headerY + 8, C.Amber.r, C.Amber.g, C.Amber.b, 1, UIFont.Medium)
    self:drawText("v" .. FHC.VERSION,
        self:getWidth() - 80, self.headerY + 36, C.Brass.r, C.Brass.g, C.Brass.b, 1, UIFont.Small)
    -- Parchment behind content
    drawParchment(self, self.contentX - 4, self.contentY - 4, self.contentW + 8, self.contentH + 8)
    if self.hubBackground then
        local inset = 18
        self:drawTextureScaledAspect(self.hubBackground,
            self.contentX + inset, self.contentY + inset,
            self.contentW - inset * 2, self.contentH - inset * 2,
            0.10, 1.0, 1.0, 1.0)
    end
end

function FHC_HunterGUI:close()
    self:setVisible(false)
    self:removeFromUIManager()
    FHC_HunterGUI.instance = nil
end

function FHC_HunterGUI:new(x, y, player)
    local o = ISCollapsableWindow.new(self, x, y, W, H)
    o.player = player
    o.title  = getText("IGUI_FHC_WindowTitle")
    o.resizable = false
    o.backgroundColor = { r = 0.05, g = 0.04, b = 0.02, a = 0.95 }
    o.borderColor     = { r = C.Brass.r, g = C.Brass.g, b = C.Brass.b, a = 1 }
    return o
end

-- Singleton helpers used by ClientMain / context menus.
FHC.UI.Main = {}
function FHC.UI.Main.toggle()
    if not SB.guiEnabled() then return end
    if FHC_HunterGUI.instance and FHC_HunterGUI.instance:isVisible() then
        FHC_HunterGUI.instance:close()
        return
    end
    local player = getSpecificPlayer(0)
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local win = FHC_HunterGUI:new(math.max(0, math.floor((sw - W) / 2)), math.max(0, math.floor((sh - H) / 2)), player)
    win:initialise(); win:instantiate()
    win:addToUIManager()
    FHC_HunterGUI.instance = win
    -- Restore last tab if known
    if player then
        local last = player:getModData()[FHC.MD.PlayerLastOpenTab]
        if last and win.panels and win.panels[last] then win:showTab(last) end
    end
    -- Force a scan refresh on open so the tracking tab is current.
    if FHC.Scan then FHC.Scan.invalidate() end
end
