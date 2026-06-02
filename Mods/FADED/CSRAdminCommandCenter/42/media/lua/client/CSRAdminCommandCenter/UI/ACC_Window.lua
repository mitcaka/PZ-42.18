require "ISUI/ISCollapsableWindow"
require "ISUI/ISTabPanel"
require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/UI/Components/ACC_Draw"
require "CSRAdminCommandCenter/Tabs/DashboardTab"
require "CSRAdminCommandCenter/Tabs/ClaimsTab"
require "CSRAdminCommandCenter/Tabs/VehiclesTab"
require "CSRAdminCommandCenter/Tabs/PlayersTab"
require "CSRAdminCommandCenter/Tabs/JournalTab"
require "CSRAdminCommandCenter/Tabs/PadlocksTab"
require "CSRAdminCommandCenter/Tabs/CleanupTab"
require "CSRAdminCommandCenter/Tabs/DebugTab"
require "CSRAdminCommandCenter/Tabs/AnalyticsTab"
require "CSRAdminCommandCenter/Tabs/MapTab"
require "CSRAdminCommandCenter/Tabs/SettingsTab"
require "CSRAdminCommandCenter/Tabs/HelpTab"

CSR_ACC_Window = ISCollapsableWindow:derive("CSR_ACC_Window")

function CSR_ACC_Window:initialise()
    ISCollapsableWindow.initialise(self)
end

function CSR_ACC_Window:createChildren()
    ISCollapsableWindow.createChildren(self)
    local tabY = 24
    self.tabs = ISTabPanel:new(8, tabY, self.width - 16, self.height - tabY - 8)
    self.tabs:initialise()
    self.tabs:instantiate()
    self.tabs:setAnchorRight(true)
    self.tabs:setAnchorBottom(true)
    self:addChild(self.tabs)

    local tabW = self.tabs.width
    local viewY = self.tabs.tabHeight or 24
    local tabH = self.tabs.height - viewY

    self.dashboardTab = CSR_ACC_DashboardTab:new(0, viewY, tabW, tabH)
    self.claimsTab = CSR_ACC_ClaimsTab:new(0, viewY, tabW, tabH)
    self.vehiclesTab = CSR_ACC_VehiclesTab:new(0, viewY, tabW, tabH)
    self.playersTab = CSR_ACC_PlayersTab:new(0, viewY, tabW, tabH)
    self.journalTab = CSR_ACC_JournalTab:new(0, viewY, tabW, tabH)
    self.padlocksTab = CSR_ACC_PadlocksTab:new(0, viewY, tabW, tabH)
    self.cleanupTab = CSR_ACC_CleanupTab:new(0, viewY, tabW, tabH)
    self.debugTab = CSR_ACC_DebugTab:new(0, viewY, tabW, tabH)
    self.analyticsTab = CSR_ACC_AnalyticsTab:new(0, viewY, tabW, tabH)
    self.mapTab = CSR_ACC_MapTab:new(0, viewY, tabW, tabH)
    self.settingsTab = CSR_ACC_SettingsTab:new(0, viewY, tabW, tabH)
    self.helpTab = CSR_ACC_HelpTab:new(0, viewY, tabW, tabH)

    self.dashboardTab:initialise(); self.dashboardTab:instantiate()
    self.claimsTab:initialise(); self.claimsTab:instantiate()
    self.vehiclesTab:initialise(); self.vehiclesTab:instantiate()
    self.playersTab:initialise(); self.playersTab:instantiate()
    self.journalTab:initialise(); self.journalTab:instantiate()
    self.padlocksTab:initialise(); self.padlocksTab:instantiate()
    self.cleanupTab:initialise(); self.cleanupTab:instantiate()
    self.debugTab:initialise(); self.debugTab:instantiate()
    self.analyticsTab:initialise(); self.analyticsTab:instantiate()
    self.mapTab:initialise(); self.mapTab:instantiate()
    self.settingsTab:initialise(); self.settingsTab:instantiate()
    self.helpTab:initialise(); self.helpTab:instantiate()

    self.tabs:addView("Dashboard", self.dashboardTab)
    self.tabs:addView("Claims", self.claimsTab)
    self.tabs:addView("Vehicles", self.vehiclesTab)
    self.tabs:addView("Players", self.playersTab)
    self.tabs:addView("Journal", self.journalTab)
    self.tabs:addView("Locks", self.padlocksTab)
    self.tabs:addView("Cleanup", self.cleanupTab)
    self.tabs:addView("Debug", self.debugTab)
    self.tabs:addView("Analytics", self.analyticsTab)
    self.tabs:addView("Map", self.mapTab)
    self.tabs:addView("Settings", self.settingsTab)
    self.tabs:addView("Help", self.helpTab)
end

function CSR_ACC_Window:prerender()
    ISCollapsableWindow.prerender(self)
    CSRAdminCommandCenter.Draw.neonFrame(self, 1, 1, self.width - 2, self.height - 2)
end

function CSR_ACC_Window:new(x, y, width, height)
    local o = ISCollapsableWindow.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = CSRAdminCommandCenter.NAME
    o.resizable = true
    o.pin = true
    o.backgroundColor = { r = 0.02, g = 0.01, b = 0.04, a = 0.82 }
    o.borderColor = { r = 0.88, g = 0.18, b = 1.00, a = 1 }
    return o
end

return CSR_ACC_Window
