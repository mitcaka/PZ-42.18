-- FHC_MapMarkers.lua  — World map overlay: pin all known animal positions while map is open.
-- Hooks ISWorldMap (vanilla map UI). Renders only if sandbox + per-player toggle agree.

require "FHC_Constants"
require "FHC_Sandbox"
require "FHC_Utils"

if isServer() then return end

local U  = FHC.Utils
local SB = FHC.SB
local C  = FHC.COLOR

local function tryHook()
    if not ISWorldMap then return end
    if ISWorldMap.fhcHooked then return end
    ISWorldMap.fhcHooked = true

    local _origRender = ISWorldMap.render
    function ISWorldMap:render(...)
        _origRender(self, ...)
        local player = getSpecificPlayer(self.playerNum or 0)
        if not player then return end
        if not SB.mapMarkers() then return end
        if not U.getToggle(player, FHC.TOGGLE.MapMarkers) then return end
        local mapAPI = self.mapAPI
        if not mapAPI then return end
        local snap = FHC.Scan and FHC.Scan.snapshot() or {}
        for _, row in ipairs(snap) do
            local sx, sy = mapAPI:worldToUIPixel(row.x + 0.5, row.y + 0.5)
            if sx and sy then
                -- Draw a yellow ring with a black centre dot.
                self:drawRect(sx - 4, sy - 4, 8, 8, 0.8,
                    C.OutlineYellow.r, C.OutlineYellow.g, C.OutlineYellow.b)
                self:drawRectBorder(sx - 4, sy - 4, 8, 8, 1.0, 0, 0, 0)
            end
        end
    end
end

Events.OnGameStart.Add(tryHook)
