-- CSR_OutfitSetsLootHandler.lua  (v1.8.34)
-- Adds a small "Outfit" button to the LootWindow header for wardrobes,
-- mirroring the approach pioneered by Yuki's "Outfit Control" mod
-- (Workshop id 3610760744 — used with permission). Reuses our shared
-- CSR_OutfitSets context-menu builder so both right-click-the-furniture
-- and click-the-button paths show the same options.
require "ISUI/LootWindow/ISLootWindowObjectControlHandler"
require "ISUI/LootWindow/ISLootWindowContainerControls"
require "CSR_OutfitSets"
require "CSR_OutfitSetsUtil"

CSR_OutfitSetsLootHandler = ISLootWindowObjectControlHandler:derive("CSR_OutfitSetsLootHandler")
local Handler = CSR_OutfitSetsLootHandler

function Handler:shouldBeVisible()
    if not CSR_OutfitSetsUtil.isEnabled() then return false end
    if not self.object then return false end
    if not (CSR_OutfitSetsUtil.isWardrobeObject(self.object)
         or (CSR_OutfitSetsUtil.isSafehouseOnly()
             and CSR_OutfitSetsUtil.isBagObject(self.object))) then
        return false
    end
    if not CSR_OutfitSetsUtil.canUseHere(self.playerObj, self.object) then return false end
    return true
end

function Handler:getControl()
    if not self.control then
        local label = (getText and getText("IGUI_CSR_OutfitSets_Root")) or "Outfit"
        if label == "IGUI_CSR_OutfitSets_Root" then label = "Outfit" end
        self.control = self:getButtonControl(label)
    end
    return self.control
end

function Handler:perform()
    if isGamePaused() then return end
    local player = self.playerObj
    local object = self.object
    if not player or not object then return end
    if not CSR_OutfitSetsUtil.canUseHere(player, object) then return end
    local container = self.container or (object.getContainer and object:getContainer())
    if not container then return end

    local x = self:getControl():getX() + (self.lootWindow and self.lootWindow:getX() or 0)
    local y = self:getControl():getY() + (self.lootWindow and self.lootWindow:getY() or 0)
              + (self:getControl():getHeight() or 0)
    if y < 0 then y = 0 end
    local context = ISContextMenu.get(player:getPlayerNum(), x, y)
    if CSR_OutfitSets_buildContext then
        CSR_OutfitSets_buildContext(context, player, object, container)
    end
end

if ISLootWindowContainerControls and ISLootWindowContainerControls.AddHandler then
    ISLootWindowContainerControls.AddHandler(CSR_OutfitSetsLootHandler)
end
