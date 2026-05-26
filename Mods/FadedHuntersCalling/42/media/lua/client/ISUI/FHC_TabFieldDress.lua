-- FHC_TabFieldDress.lua  — manual button to field-dress nearest carcass.
require "ISUI/FHC_TabBase"
require "FHC_TimedActions"

if isServer() then return end

FHC_TabFieldDress = FHC_TabBase:derive("FHC_TabFieldDress")
local C = FHC.COLOR
local U = FHC.Utils
local SB = FHC.SB

function FHC_TabFieldDress:createChildren()
    self:addLabel(12, 8, getText("IGUI_FHC_FieldDress_Title"), UIFont.Large, C.Ink)
    self.dressBtn = self:addTextBtn(14, 80, 220, 28,
        getText("IGUI_FHC_FieldDress_DoNearest"), self, FHC_TabFieldDress.dressNearest)
    self.dryBtn = self:addTextBtn(14, 120, 220, 28,
        getText("IGUI_FHC_FieldDress_DryMeat"), self, FHC_TabFieldDress.dryNearestMeat)
    self.cureBtn = self:addTextBtn(14, 160, 220, 28,
        getText("IGUI_FHC_FieldDress_CureHide"), self, FHC_TabFieldDress.cureNearestHide)
end

local function findNearestCarcass(player)
    local cell = getCell(); if not cell then return nil end
    local best, bestD = nil, math.huge
    local plX, plY, plZ = U.objectPosition(player)
    if not plX then return nil end
    for sx = plX - 8, plX + 8 do
        for sy = plY - 8, plY + 8 do
            local okSq, sq = U.tryCall(cell, "getGridSquare", math.floor(sx), math.floor(sy), math.floor(plZ))
            if sq then
                local okMoving, moving = U.tryCall(sq, "getStaticMovingObjects")
                for j = 0, U.listSize(moving) - 1 do
                    local o = U.listGet(moving, j)
                    if U.isAnimalCorpse(o) then
                        local d = (sx - plX) ^ 2 + (sy - plY) ^ 2
                        if d < bestD then best, bestD = o, d end
                    end
                end
            end
        end
    end
    return best
end

function FHC_TabFieldDress:dressNearest()
    if not SB.fieldDress() then return end
    local player = self.player
    local carcass = findNearestCarcass(player)
    if not carcass then player:Say(getText("IGUI_FHC_NoCarcass")); return end
    local inv = player:getInventory()
    local knife = inv:getFirstTagRecurse("base:sharpknife") or inv:getFirstTagRecurse("SharpKnife")
    if not knife and SB.requireTools() then player:Say(getText("IGUI_FHC_NeedKnife")); return end
    local canonical = nil
    local okType, t = U.tryCall(carcass, "getAnimalType")
    canonical = okType and t and FHC.ANIMAL_BY_ALIAS[string.lower(tostring(t))] or nil
    ISTimedActionQueue.add(FHC_FieldDress:new(player, carcass, knife, canonical))
end

function FHC_TabFieldDress:dryNearestMeat()
    if not SB.meatDrying() then return end
    local player = self.player
    local inv = player:getInventory()
    local meat = U.findFirstRawMeat(player)
    if not meat then player:Say(getText("IGUI_FHC_NoMeat")); return end
    local salt = inv:getFirstTypeRecurse("Base.Salt")
    if not salt then player:Say(getText("IGUI_FHC_NeedSalt")); return end
    local knife = inv:getFirstTagRecurse("base:sharpknife") or inv:getFirstTagRecurse("SharpKnife")
    if not knife and SB.requireTools() then player:Say(getText("IGUI_FHC_NeedKnife")); return end
    ISTimedActionQueue.add(FHC_DryMeatTA:new(player, meat, salt, knife))
end

function FHC_TabFieldDress:cureNearestHide()
    if not SB.hideCuring() then return end
    local player = self.player
    local inv = player:getInventory()
    local hide = inv:getFirstTypeRecurse("Base.FHC_SaltedHide")
    if not hide then player:Say(getText("IGUI_FHC_NoSaltedHide")); return end
    local knife = inv:getFirstTagRecurse("base:sharpknife") or inv:getFirstTagRecurse("SharpKnife")
    if not knife and SB.requireTools() then player:Say(getText("IGUI_FHC_NeedKnife")); return end
    ISTimedActionQueue.add(FHC_CureHideTA:new(player, hide, knife))
end

function FHC_TabFieldDress:prerender()
    FHC_TabBase.prerender(self)
    local x, y = 14, 40
    self:drawText(getText("IGUI_FHC_FieldDress_Description"), x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Small)
end

FHC.UI.Tabs.field = function(x, y, w, h, player) return FHC_TabFieldDress:new(x, y, w, h, player) end
