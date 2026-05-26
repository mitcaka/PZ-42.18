-- FHC_TabTracking.lua  — Animal outline (yellow), nearby panel, map markers toggles.
-- Each toggle stores per-player state via FHC.Utils.setToggle; the runtime
-- systems read the flag and ONLY then start pinging the world / server.
require "ISUI/FHC_TabBase"

if isServer() then return end

FHC_TabTracking = FHC_TabBase:derive("FHC_TabTracking")
local C  = FHC.COLOR
local U  = FHC.Utils
local SB = FHC.SB

function FHC_TabTracking:createChildren()
    self:addLabel(12, 8, getText("IGUI_FHC_Tracking_Title"), UIFont.Large, C.Ink)

    self.tickOutline = self:addTickBox(14, 50, getText("IGUI_FHC_Tracking_YellowOutline"),
        self, FHC_TabTracking.onTickOutline)
    self.tickAlwaysOn = self:addTickBox(14, 80, getText("IGUI_FHC_Tracking_OutlineAlwaysOn"),
        self, FHC_TabTracking.onTickAlwaysOn)
    self.tickNearby  = self:addTickBox(14, 110, getText("IGUI_FHC_Tracking_NearbyPanel"),
        self, FHC_TabTracking.onTickNearby)
    self.tickMap     = self:addTickBox(14, 140, getText("IGUI_FHC_Tracking_MapMarkers"),
        self, FHC_TabTracking.onTickMap)

    self.knownBtn = self:addTextBtn(14, 180, 220, 26, getText("IGUI_FHC_Tracking_RescanNow"),
        self, function() if FHC.Scan then FHC.Scan.invalidate() end end)

    self:refreshTicks()
end

function FHC_TabTracking:refreshTicks()
    if not self.player then return end
    self.tickOutline:setSelected(1, U.getToggle(self.player, FHC.TOGGLE.AnimalOutline))
    self.tickAlwaysOn:setSelected(1, U.getToggle(self.player, FHC.TOGGLE.OutlineAlwaysOn))
    self.tickNearby:setSelected(1, U.getToggle(self.player, FHC.TOGGLE.NearbyPanel))
    self.tickMap:setSelected(1, U.getToggle(self.player, FHC.TOGGLE.MapMarkers))
    -- Disable rows whose sandbox option is off (so the player understands why they can't toggle them).
    self.tickOutline:setVisible(SB.outline())
    self.tickAlwaysOn:setVisible(SB.outline() and SB.outlineAlwaysOnAllowed())
    self.tickNearby:setVisible(SB.nearbyPanel())
    self.tickMap:setVisible(SB.mapMarkers())
end

function FHC_TabTracking:onShow() self:refreshTicks() end

local function tickSelected(fallbackTickBox, index, selected)
    if selected ~= nil then return selected and true or false end
    local tick = fallbackTickBox
    if tick and tick.isSelected then
        return tick:isSelected(index or 1) and true or false
    end
    return false
end

function FHC_TabTracking:onTickOutline(index, selected)
    U.setToggle(self.player, FHC.TOGGLE.AnimalOutline, tickSelected(self.tickOutline, index, selected))
end
function FHC_TabTracking:onTickAlwaysOn(index, selected)
    U.setToggle(self.player, FHC.TOGGLE.OutlineAlwaysOn, tickSelected(self.tickAlwaysOn, index, selected))
end
function FHC_TabTracking:onTickNearby(index, selected)
    U.setToggle(self.player, FHC.TOGGLE.NearbyPanel, tickSelected(self.tickNearby, index, selected))
    if FHC.UI and FHC.UI.NearbyPanel then FHC.UI.NearbyPanel.applyState(self.player) end
end
function FHC_TabTracking:onTickMap(index, selected)
    U.setToggle(self.player, FHC.TOGGLE.MapMarkers, tickSelected(self.tickMap, index, selected))
end

function FHC_TabTracking:prerender()
    FHC_TabBase.prerender(self)
    local x, y = 250, 50
    self:drawText(getText("IGUI_FHC_Tracking_NearbyHeader"), x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Medium); y = y + 22
    local snap = FHC.Scan and FHC.Scan.snapshot() or {}
    local counts = {}
    for _, row in ipairs(snap) do
        if row.canonical then counts[row.canonical] = (counts[row.canonical] or 0) + 1 end
    end
    local hasCounts = false
    for _ in pairs(counts) do
        hasCounts = true
        break
    end
    if not hasCounts then
        self:drawText("  " .. getText("IGUI_FHC_Tracking_NoneNearby"),
            x, y, C.ParchmentDark.r, C.ParchmentDark.g, C.ParchmentDark.b, 1, UIFont.Small)
    else
        for k, c in pairs(counts) do
            local row = FHC.ANIMALS[k]
            self:drawText("  " .. (row and row.display or k) .. " x " .. tostring(c),
                x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Small)
            y = y + 16
        end
    end

    -- Footer hint
    self:drawText(getText("IGUI_FHC_Tracking_GateHint"),
        14, self:getHeight() - 24, C.ParchmentDark.r, C.ParchmentDark.g, C.ParchmentDark.b, 1, UIFont.Small)
end

FHC.UI.Tabs.tracking = function(x, y, w, h, player) return FHC_TabTracking:new(x, y, w, h, player) end
