-- FHC_TabJournal.lua
require "ISUI/FHC_TabBase"

if isServer() then return end

FHC_TabJournal = FHC_TabBase:derive("FHC_TabJournal")
local C = FHC.COLOR
local U = FHC.Utils

function FHC_TabJournal:createChildren()
    self:addLabel(12, 8, getText("IGUI_FHC_Journal_Title"), UIFont.Large, C.Ink)
    self.refreshBtn = self:addTextBtn(self:getWidth() - 110, 6, 100, 22,
        getText("IGUI_FHC_Refresh"), self, FHC_TabJournal.onRefresh)
end

function FHC_TabJournal:onRefresh() self:refreshData() end

function FHC_TabJournal:refreshData()
    self.journal = U.getJournal(self.player) or {}
end

function FHC_TabJournal:onShow()
    self:refreshData()
end

function FHC_TabJournal:prerender()
    FHC_TabBase.prerender(self)
    local j = self.journal or {}
    local x, y = 14, 40
    self:drawText(getText("IGUI_FHC_Journal_KillsHeader"), x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Medium)
    y = y + 22
    local total = 0
    for k, c in pairs(j.kills or {}) do
        local row = FHC.ANIMALS[k]
        local label = row and row.display or k
        self:drawText("  " .. label .. " x " .. tostring(c), x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Small)
        total = total + c
        y = y + 16
    end
    if total == 0 then
        self:drawText("  " .. getText("IGUI_FHC_Journal_NoKills"), x, y, C.ParchmentDark.r, C.ParchmentDark.g, C.ParchmentDark.b, 1, UIFont.Small)
        y = y + 16
    end
    y = y + 12
    self:drawText(getText("IGUI_FHC_Journal_Stats"), x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Medium)
    y = y + 22
    self:drawText("  " .. getText("IGUI_FHC_Journal_Hides") .. ": " .. tostring(j.hides or 0),
        x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Small); y = y + 16
    self:drawText("  " .. getText("IGUI_FHC_Journal_TrapsSprung") .. ": " .. tostring(j.trapsSprung or 0),
        x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Small); y = y + 16
    self:drawText("  " .. getText("IGUI_FHC_Journal_TotalKills") .. ": " .. tostring(total),
        x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Small); y = y + 24

    if U.getToggle(self.player, FHC.TOGGLE.ShowJournalTips) then
        self:drawText(getText("IGUI_FHC_Journal_TipsHeader"), x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Medium); y = y + 22
        self:drawText("  - " .. getText("IGUI_FHC_Tip_FieldDress"), x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Small); y = y + 16
        self:drawText("  - " .. getText("IGUI_FHC_Tip_TrapBait"),   x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Small); y = y + 16
        self:drawText("  - " .. getText("IGUI_FHC_Tip_OutlineYellow"), x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Small); y = y + 16
    end
end

FHC.UI.Tabs.journal = function(x, y, w, h, player) return FHC_TabJournal:new(x, y, w, h, player) end
