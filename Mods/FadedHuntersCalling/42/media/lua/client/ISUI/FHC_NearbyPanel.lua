-- FHC_NearbyPanel.lua  — Always-on small HUD listing nearby known animals.
-- Driven by FHC.Scan.snapshot(); only renders when sandbox + per-player toggle allow.

require "ISUI/ISPanel"
require "FHC_Constants"
require "FHC_Sandbox"
require "FHC_Utils"

if isServer() then return end

FHC.UI = FHC.UI or {}
FHC.UI.NearbyPanel = FHC.UI.NearbyPanel or {}

FHC_NearbyPanel = ISPanel:derive("FHC_NearbyPanel")
local C  = FHC.COLOR
local U  = FHC.Utils
local SB = FHC.SB

local W, H = 200, 140
local PADDING = 6

function FHC_NearbyPanel:initialise() ISPanel.initialise(self) end

function FHC_NearbyPanel:shouldRender()
    if not SB.nearbyPanel() then return false end
    if not self.player then return false end
    return U.getToggle(self.player, FHC.TOGGLE.NearbyPanel)
end

function FHC_NearbyPanel:render() end

function FHC_NearbyPanel:prerender()
    if not self:shouldRender() then return end
    self:drawRect(0, 0, self.width, self.height, 0.65,
        C.LeatherDark.r, C.LeatherDark.g, C.LeatherDark.b)
    self:drawRectBorder(0, 0, self.width, self.height, 1.0,
        C.Brass.r, C.Brass.g, C.Brass.b)
    self:drawText(getText("IGUI_FHC_NearbyPanel_Title"),
        PADDING, 4, C.Amber.r, C.Amber.g, C.Amber.b, 1, UIFont.Small)

    local snap = FHC.Scan and FHC.Scan.snapshot() or {}
    local counts = {}
    for _, row in ipairs(snap) do
        if row.canonical then
            counts[row.canonical] = (counts[row.canonical] or 0) + 1
        end
    end

    local y = 24
    local maxLines = math.floor((self.height - 28) / 14)
    local lines = 0
    local hasCounts = false
    for _ in pairs(counts) do
        hasCounts = true
        break
    end
    if not hasCounts then
        self:drawText(getText("IGUI_FHC_NearbyPanel_NoneNearby"),
            PADDING, y, C.Parchment.r, C.Parchment.g, C.Parchment.b, 1, UIFont.Small)
    else
        for k, c in pairs(counts) do
            if lines >= maxLines then break end
            local row = FHC.ANIMALS[k]
            self:drawText((row and row.display or k) .. " x " .. tostring(c),
                PADDING, y, C.Parchment.r, C.Parchment.g, C.Parchment.b, 1, UIFont.Small)
            y = y + 14
            lines = lines + 1
        end
    end
end

function FHC_NearbyPanel:new(x, y, player)
    local o = ISPanel.new(self, x, y, W, H)
    o.player = player
    o.background = false
    o:setAlwaysOnTop(false)
    return o
end

-- Singleton: created once per player; visibility driven by toggle.
local instance = nil
function FHC.UI.NearbyPanel.ensure(player)
    if instance then return instance end
    local sw = getCore():getScreenWidth()
    instance = FHC_NearbyPanel:new(sw - W - 12, 240, player)
    instance:initialise(); instance:instantiate()
    instance:addToUIManager()
    return instance
end

function FHC.UI.NearbyPanel.applyState(player)
    FHC.UI.NearbyPanel.ensure(player)
end

local function onGameStart()
    local player = getSpecificPlayer(0)
    if not player then return end
    FHC.UI.NearbyPanel.ensure(player)
end
Events.OnGameStart.Add(onGameStart)
