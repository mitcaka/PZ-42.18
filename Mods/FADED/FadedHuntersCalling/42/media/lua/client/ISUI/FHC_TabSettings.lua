-- FHC_TabSettings.lua  — per-player toggles + sandbox echo.
require "ISUI/FHC_TabBase"

if isServer() then return end

FHC_TabSettings = FHC_TabBase:derive("FHC_TabSettings")
local C  = FHC.COLOR
local U  = FHC.Utils
local SB = FHC.SB

function FHC_TabSettings:createChildren()
    self:addLabel(12, 8, getText("IGUI_FHC_Settings_Title"), UIFont.Large, C.Ink)

    self.tickTips  = self:addTickBox(14, 50, getText("IGUI_FHC_Settings_JournalTips"),
        self, function(t) U.setToggle(self.player, FHC.TOGGLE.ShowJournalTips, t:isSelected(1)) end)
    self.tickKnown = self:addTickBox(14, 80, getText("IGUI_FHC_Settings_ShowKnownAnimals"),
        self, function(t) U.setToggle(self.player, FHC.TOGGLE.ShowKnownAnimals, t:isSelected(1)) end)
    self.tickDryNotifs = self:addTickBox(14, 110, getText("IGUI_FHC_Settings_DryingNotifs"),
        self, function(t) U.setToggle(self.player, FHC.TOGGLE.DryingNotifs, t:isSelected(1)) end)
    self.tickTrapBoard = self:addTickBox(14, 140, getText("IGUI_FHC_Settings_TrapBoard"),
        self, function(t) U.setToggle(self.player, FHC.TOGGLE.TrapBoard, t:isSelected(1)) end)

    self.resetBtn = self:addTextBtn(14, 200, 220, 26, getText("IGUI_FHC_Settings_ResetToggles"),
        self, function()
            self.player:getModData()[FHC.MD.PlayerToggles] = FHC.DefaultToggles()
            self:refreshTicks()
        end)
    self.showBtnBtn = self:addTextBtn(14, 232, 220, 26, getText("IGUI_FHC_Settings_ShowLaunchButton"),
        self, function()
            if FHC.UI and FHC.UI.LaunchButton then
                FHC.UI.LaunchButton.ensure(self.player)
                FHC.UI.LaunchButton.show()
            end
        end)
    self:refreshTicks()
end

function FHC_TabSettings:refreshTicks()
    self.tickTips:setSelected(1, U.getToggle(self.player, FHC.TOGGLE.ShowJournalTips))
    self.tickKnown:setSelected(1, U.getToggle(self.player, FHC.TOGGLE.ShowKnownAnimals))
    self.tickDryNotifs:setSelected(1, U.getToggle(self.player, FHC.TOGGLE.DryingNotifs))
    self.tickTrapBoard:setSelected(1, U.getToggle(self.player, FHC.TOGGLE.TrapBoard))
end

function FHC_TabSettings:onShow() self:refreshTicks() end

function FHC_TabSettings:prerender()
    FHC_TabBase.prerender(self)
    local x, y = 260, 50
    self:drawText(getText("IGUI_FHC_Settings_SandboxHeader"),
        x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Medium); y = y + 22
    local lines = {
        { "Mod",              SB.enabled() },
        { "GUI",              SB.guiEnabled() },
        { "Trapping",         SB.trapping() },
        { "Live Capture",     SB.liveCapture() },
        { "Trap Board",       SB.trapBoard() },
        { "Bushcraft",        SB.bushcraft() },
        { "Field Dressing",   SB.fieldDress() },
        { "Meat Drying",      SB.meatDrying() },
        { "Hide Curing",      SB.hideCuring() },
        { "Tools",            SB.tools() },
        { "Outline",          SB.outline() },
        { "Nearby Panel",     SB.nearbyPanel() },
        { "Map Markers",      SB.mapMarkers() },
        { "Server QoL",       SB.serverQoL() },
        { "Admin Pop Ctrl",   SB.adminPop() },
        { "Strict MP Valid.", SB.strictValidation() },
        { "Debug Logging",    SB.debugLog() },
    }
    for _, row in ipairs(lines) do
        local on = row[2]
        local r, g, b = (on and C.GoodGreen or C.WarnRed).r, (on and C.GoodGreen or C.WarnRed).g, (on and C.GoodGreen or C.WarnRed).b
        local mark  = on and "[on] " or "[off]"
        self:drawText(mark .. " " .. row[1], x, y, r, g, b, 1, UIFont.Small)
        y = y + 14
    end
end

FHC.UI.Tabs.settings = function(x, y, w, h, player) return FHC_TabSettings:new(x, y, w, h, player) end
