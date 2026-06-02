-- FHC_TabServer.lua  — Admin-only QoL: population report + culling.
require "ISUI/FHC_TabBase"

if isServer() then return end

FHC_TabServer = FHC_TabBase:derive("FHC_TabServer")
local C  = FHC.COLOR
local U  = FHC.Utils
local SB = FHC.SB

local function isAdmin(player)
    if not player then return false end
    if player.getAccessLevel then
        local lvl = player:getAccessLevel()
        if lvl == "Admin" or lvl == "GM" or lvl == "Overseer" or lvl == "Moderator" then
            return true
        end
    end
    return false
end

function FHC_TabServer:createChildren()
    self:addLabel(12, 8, getText("IGUI_FHC_Server_Title"), UIFont.Large, C.Ink)
    self.reportBtn = self:addTextBtn(14, 50, 220, 26, getText("IGUI_FHC_Server_RequestReport"),
        self, FHC_TabServer.requestReport)
    self.cullBtn = self:addTextBtn(14, 90, 220, 26, getText("IGUI_FHC_Server_CullChickens5"),
        self, FHC_TabServer.cullChickens)
end

function FHC_TabServer:isAdminCheck()
    if not isAdmin(self.player) then
        self.player:Say(getText("IGUI_FHC_Server_NotAdmin"))
        return false
    end
    if not SB.adminPop() then
        self.player:Say(getText("IGUI_FHC_Server_AdminDisabled"))
        return false
    end
    return true
end

function FHC_TabServer:requestReport()
    if not self:isAdminCheck() then return end
    sendClientCommand(self.player, FHC.MODULE, FHC.CMD.AdminPopReport, {})
end

function FHC_TabServer:cullChickens()
    if not self:isAdminCheck() then return end
    sendClientCommand(self.player, FHC.MODULE, FHC.CMD.AdminPopCull, { animalType = "chicken", maxCount = 5 })
end

function FHC_TabServer:prerender()
    FHC_TabBase.prerender(self)
    local x, y = 14, 130
    if not isAdmin(self.player) then
        self:drawText(getText("IGUI_FHC_Server_AdminOnly"),
            x, y, C.WarnRed.r, C.WarnRed.g, C.WarnRed.b, 1, UIFont.Medium)
        return
    end
    local counts = FHC.Client and FHC.Client.adminData and FHC.Client.adminData.popCounts or nil
    self:drawText(getText("IGUI_FHC_Server_LastReport"), x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Medium); y = y + 22
    if not counts then
        self:drawText("  " .. getText("IGUI_FHC_Server_NoReportYet"),
            x, y, C.ParchmentDark.r, C.ParchmentDark.g, C.ParchmentDark.b, 1, UIFont.Small)
    else
        for k, c in pairs(counts) do
            self:drawText("  " .. tostring(k) .. ": " .. tostring(c),
                x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Small)
            y = y + 16
        end
    end
    local last = FHC.Client and FHC.Client.adminData and FHC.Client.adminData.lastCullResult or nil
    if last then
        y = y + 12
        self:drawText(string.format(getText("IGUI_FHC_Server_CullResult"),
            last.culled or 0, tostring(last.animalType)),
            x, y, C.GoodGreen.r, C.GoodGreen.g, C.GoodGreen.b, 1, UIFont.Small)
    end
end

FHC.UI.Tabs.server = function(x, y, w, h, player) return FHC_TabServer:new(x, y, w, h, player) end
