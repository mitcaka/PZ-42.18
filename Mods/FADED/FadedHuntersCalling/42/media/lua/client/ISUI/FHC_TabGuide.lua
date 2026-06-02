-- FHC_TabGuide.lua
require "ISUI/FHC_TabBase"

if isServer() then return end

FHC_TabGuide = FHC_TabBase:derive("FHC_TabGuide")
local C = FHC.COLOR

local function drawLine(ui, text, x, y, color)
    color = color or C.Ink
    ui:drawText(text, x, y, color.r, color.g, color.b, 1, UIFont.Small)
end

function FHC_TabGuide:createChildren()
    self:addLabel(12, 8, getText("IGUI_FHC_Guide_Title"), UIFont.Large, C.Ink)
end

function FHC_TabGuide:prerender()
    FHC_TabBase.prerender(self)
    local x = 16
    local y = 44
    local sections = {
        {
            title = getText("IGUI_FHC_Guide_Open_Title"),
            lines = {
                getText("IGUI_FHC_Guide_Open_1"),
                getText("IGUI_FHC_Guide_Open_2"),
            },
        },
        {
            title = getText("IGUI_FHC_Guide_Field_Title"),
            lines = {
                getText("IGUI_FHC_Guide_Field_1"),
                getText("IGUI_FHC_Guide_Field_2"),
            },
        },
        {
            title = getText("IGUI_FHC_Guide_Bushcraft_Title"),
            lines = {
                getText("IGUI_FHC_Guide_Bushcraft_1"),
                getText("IGUI_FHC_Guide_Bushcraft_2"),
            },
        },
        {
            title = getText("IGUI_FHC_Guide_Scents_Title"),
            lines = {
                getText("IGUI_FHC_Guide_Scents_1"),
                getText("IGUI_FHC_Guide_Scents_2"),
            },
        },
        {
            title = getText("IGUI_FHC_Guide_Calls_Title"),
            lines = {
                getText("IGUI_FHC_Guide_Calls_1"),
                getText("IGUI_FHC_Guide_Calls_2"),
            },
        },
        {
            title = getText("IGUI_FHC_Guide_Tracking_Title"),
            lines = {
                getText("IGUI_FHC_Guide_Tracking_1"),
                getText("IGUI_FHC_Guide_Tracking_2"),
            },
        },
        {
            title = getText("IGUI_FHC_Guide_Server_Title"),
            lines = {
                getText("IGUI_FHC_Guide_Server_1"),
                getText("IGUI_FHC_Guide_Server_2"),
            },
        },
    }

    for _, section in ipairs(sections) do
        self:drawText(section.title, x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Medium)
        y = y + 21
        for _, line in ipairs(section.lines) do
            drawLine(self, "  " .. line, x, y, C.ParchmentDark)
            y = y + 15
        end
        y = y + 9
    end
end

FHC.UI.Tabs.guide = function(x, y, w, h, player) return FHC_TabGuide:new(x, y, w, h, player) end
