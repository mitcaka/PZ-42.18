-- FHC_TabBase.lua
-- Common base used by every tab panel. Provides shared helpers and the leather/parchment look.

require "ISUI/ISPanel"
require "FHC_Constants"
require "FHC_Utils"
require "FHC_Sandbox"

if isServer() then return end

FHC.UI = FHC.UI or {}
FHC.UI.Tabs = FHC.UI.Tabs or {}

FHC_TabBase = ISPanel:derive("FHC_TabBase")

local C = FHC.COLOR

function FHC_TabBase:initialise()
    ISPanel.initialise(self)
end

function FHC_TabBase:prerender()
    ISPanel.prerender(self)
end

function FHC_TabBase:addLabel(x, y, text, font, color)
    color = color or C.Ink
    local lbl = ISLabel:new(x, y, 20, text, color.r, color.g, color.b, 1.0, font or UIFont.Medium, true)
    lbl:initialise(); lbl:instantiate()
    self:addChild(lbl)
    return lbl
end

function FHC_TabBase:addTextBtn(x, y, w, h, text, target, fn)
    local b = ISButton:new(x, y, w, h, text, target or self, fn)
    b:initialise(); b:instantiate()
    b.borderColor = { r = C.Brass.r, g = C.Brass.g, b = C.Brass.b, a = 1 }
    b.backgroundColor = { r = C.LeatherDark.r, g = C.LeatherDark.g, b = C.LeatherDark.b, a = 1 }
    b.backgroundColorMouseOver = { r = C.LeatherLight.r, g = C.LeatherLight.g, b = C.LeatherLight.b, a = 1 }
    self:addChild(b)
    return b
end

function FHC_TabBase:addTickBox(x, y, label, target, fn)
    local t = ISTickBox:new(x, y, 200, 20, label, target or self, fn)
    t:initialise(); t:instantiate()
    t:addOption(label)
    self:addChild(t)
    return t
end

function FHC_TabBase:new(x, y, w, h, player)
    local o = ISPanel.new(self, x, y, w, h)
    o.player = player
    o.background = false
    return o
end
