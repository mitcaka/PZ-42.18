-- FHC_TabAnimalCalls.lua
-- Learned animal calls and call activation.

require "ISUI/FHC_TabBase"
require "FHC_TimedActions"

if isServer() then return end

FHC_TabAnimalCalls = FHC_TabBase:derive("FHC_TabAnimalCalls")
local C = FHC.COLOR
local U = FHC.Utils

local ROW_H = 32
local START_Y = 52

local function callLabel(animalKey)
    local key = "IGUI_FHC_AnimalCall_" .. tostring(animalKey)
    local label = getText(key)
    if label ~= key then return label end
    local animal = FHC.ANIMALS and FHC.ANIMALS[animalKey]
    return ((animal and animal.display) or tostring(animalKey)) .. " Call"
end

local function statusText(player, animalKey)
    if not U.playerKnowsAnimalCall(player, animalKey) then
        return getText("IGUI_FHC_CallLocked"), C.WarnRed, false
    end
    local remaining = U.getAnimalCallCooldownRemaining(player, animalKey)
    if remaining > 0 then
        local minutes = math.max(1, math.ceil(remaining * 60))
        return string.format(getText("IGUI_FHC_CallCooldownMinutesFmt"), minutes), C.AmberDim, false
    end
    return getText("IGUI_FHC_CallReady"), C.GoodGreen, true
end

function FHC_TabAnimalCalls:createChildren()
    self:addLabel(12, 8, getText("IGUI_FHC_Calls_Title"), UIFont.Large, C.Ink)
    self.buttons = {}
    for index, animalKey in ipairs(FHC.ANIMAL_CALL_ORDER or {}) do
        local y = START_Y + ((index - 1) * ROW_H)
        local btn = self:addTextBtn(self:getWidth() - 136, y - 2, 112, 24,
            getText("IGUI_FHC_CallUse"), self, FHC_TabAnimalCalls.onCallPressed)
        btn.internal = animalKey
        if btn.setFont then btn:setFont(UIFont.Small) end
        self.buttons[animalKey] = btn
    end
end

function FHC_TabAnimalCalls:onCallPressed(button)
    local animalKey = button and button.internal
    if not animalKey then return end
    if not U.playerKnowsAnimalCall(self.player, animalKey) then
        self.player:Say(getText("IGUI_FHC_CallLocked"))
        return
    end
    if U.getAnimalCallCooldownRemaining(self.player, animalKey) > 0 then
        self.player:Say(getText("IGUI_FHC_CallCooldown"))
        return
    end
    ISTimedActionQueue.add(FHC_AnimalCallTA:new(self.player, animalKey))
end

function FHC_TabAnimalCalls:prerender()
    FHC_TabBase.prerender(self)
    self:drawText(getText("IGUI_FHC_Calls_Header"), 14, 32,
        C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Small)

    for index, animalKey in ipairs(FHC.ANIMAL_CALL_ORDER or {}) do
        local y = START_Y + ((index - 1) * ROW_H)
        local text, color, canUse = statusText(self.player, animalKey)
        self:drawText(callLabel(animalKey), 18, y + 3, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Medium)
        self:drawText(text, 260, y + 6, color.r, color.g, color.b, 1, UIFont.Small)

        local btn = self.buttons and self.buttons[animalKey]
        if btn then
            if btn.setEnable then btn:setEnable(canUse) else btn.enable = canUse end
            btn.notAvailable = not canUse
            btn.tooltip = canUse and getText("IGUI_FHC_CallTooltipReady") or text
            if canUse then
                btn.backgroundColor = { r = C.Leather.r, g = C.Leather.g, b = C.Leather.b, a = 1 }
            else
                btn.backgroundColor = { r = C.LeatherDark.r, g = C.LeatherDark.g, b = C.LeatherDark.b, a = 1 }
            end
        end
    end
end

FHC.UI.Tabs.calls = function(x, y, w, h, player) return FHC_TabAnimalCalls:new(x, y, w, h, player) end
