-- FHC_TabTools.lua  — Hunter melee + utility roster.
require "ISUI/FHC_TabBase"

if isServer() then return end

FHC_TabTools = FHC_TabBase:derive("FHC_TabTools")
local C = FHC.COLOR

local ROSTER = {
    { id = "FHC_HuntingKnife",   role = "blade",  desc = "FHC_Tools_HuntingKnife" },
    { id = "FHC_SkinningKnife",  role = "blade",  desc = "FHC_Tools_SkinningKnife" },
    { id = "FHC_CampHatchet",    role = "axe",    desc = "FHC_Tools_CampHatchet" },
    { id = "FHC_FieldMachete",   role = "long",   desc = "FHC_Tools_FieldMachete" },
    { id = "FHC_BushcraftSpear", role = "spear",  desc = "FHC_Tools_BushcraftSpear" },
    { id = "FHC_TrappersClub",   role = "blunt",  desc = "FHC_Tools_TrappersClub" },
}

function FHC_TabTools:createChildren()
    self:addLabel(12, 8, getText("IGUI_FHC_Tools_Title"), UIFont.Large, C.Ink)
end

function FHC_TabTools:prerender()
    FHC_TabBase.prerender(self)
    local x, y = 14, 40
    self:drawText(getText("IGUI_FHC_Tools_Header"), x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Medium); y = y + 22
    for _, t in ipairs(ROSTER) do
        local name = getItemNameFromFullType("Base." .. t.id)
        if not name or name == "" then name = t.id end
        self:drawText("  " .. name, x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Small)
        local desc = getText("IGUI_" .. t.desc)
        self:drawText("    " .. desc, x, y + 14, C.ParchmentDark.r, C.ParchmentDark.g, C.ParchmentDark.b, 1, UIFont.Small)
        y = y + 36
    end
    y = y + 8
    self:drawText(getText("IGUI_FHC_Tools_Footer"), x, y, C.ParchmentDark.r, C.ParchmentDark.g, C.ParchmentDark.b, 1, UIFont.Small)
end

FHC.UI.Tabs.tools = function(x, y, w, h, player) return FHC_TabTools:new(x, y, w, h, player) end
