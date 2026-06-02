-- FHC_TimedActions.lua
-- Custom ISBaseTimedAction subclasses for field-dress, meat-drying, hide-curing.
-- All are defined at file scope (MP requirement: server can't resolve in-callback classes).

require "TimedActions/ISBaseTimedAction"
require "FHC_Constants"
require "FHC_Utils"
require "FHC_Sandbox"
require "FHC_AnimalCallAttraction"

if isServer() then return end

local U  = FHC.Utils
local SB = FHC.SB

-------------------------------------------------------------------------------
-- Field Dress: player + carcass (IsoDeadBody) -> meat + raw hide + (sometimes) sinew
-------------------------------------------------------------------------------

FHC_FieldDress = ISBaseTimedAction:derive("FHC_FieldDress")

function FHC_FieldDress:isValid()
    if not self.carcass then return false end
    local okExists, exists = U.tryCall(self.carcass, "isExistInTheWorld")
    if okExists and not exists then return false end
    if SB.requireTools() then
        if not (self.knife and self.knife:getCondition() > 0) then return false end
    end
    return true
end

function FHC_FieldDress:waitToStart()
    self.character:faceThisObject(self.carcass)
    return self.character:shouldBeTurning()
end

function FHC_FieldDress:start()
    self:setActionAnim("Loot")
    self.character:reportEvent("EventLootItem")
end

function FHC_FieldDress:update()
    local x, y = U.objectPosition(self.carcass)
    if x then
        self.character:facePosition(x, y)
    end
end

function FHC_FieldDress:perform()
    local player = self.character
    local inv    = player:getInventory()

    local canonical = self.canonical
    if isClient() then
        local x, y, z = U.objectPosition(self.carcass)
        if not x then
            ISBaseTimedAction.perform(self)
            return
        end
        sendClientCommand(player, FHC.MODULE, FHC.CMD.FieldDressComplete,
            {
                x = x,
                y = y,
                z = z,
                canonical = canonical,
                knifeId = U.itemId(self.knife),
            })
        ISBaseTimedAction.perform(self)
        return
    end

    if self.knife and self.knife.setCondition then
        local cond = self.knife:getCondition()
        if cond > 0 then self.knife:setCondition(cond - 1) end
    end

    local meatType = FHC.MEAT_BY_ANIMAL[canonical or ""] or "Base.Smallanimalmeat"
    local yieldMeat = U.scaledYield(self.meatYield or 3)
    local yieldHide = U.scaledYield(self.hideYield or 1)
    local sinewChance = self.sinewChance or 30

    for i = 1, yieldMeat do
        inv:AddItem(meatType)
    end
    for i = 1, yieldHide do
        inv:AddItem("Base.FHC_RawHide")
    end
    if ZombRand(100) < sinewChance then
        inv:AddItem("Base.FHC_Sinew")
    end
    if Perks and Perks.Trapping and player.getXp then
        player:getXp():AddXP(Perks.Trapping, 5)
    end

    -- Remove the carcass from world.
    pcall(function()
        local sq = self.carcass.getSquare and self.carcass:getSquare() or nil
        if sq and sq.removeCorpse then
            sq:removeCorpse(self.carcass, false)
        else
            if self.carcass.removeFromWorld  then self.carcass:removeFromWorld() end
            if self.carcass.removeFromSquare then self.carcass:removeFromSquare() end
        end
        if self.carcass.invalidateCorpse then self.carcass:invalidateCorpse() end
    end)

    ISBaseTimedAction.perform(self)
end

function FHC_FieldDress:new(character, carcass, knife, canonical)
    local o = ISBaseTimedAction.new(self, character)
    o.character   = character
    o.carcass     = carcass
    o.knife       = knife
    o.canonical   = canonical
    o.stopOnWalk  = true
    o.stopOnRun   = true
    o.maxTime     = U.scaledTime(220)
    -- Tunables — different animals can be passed different sizes by the caller.
    o.meatYield   = 3
    o.hideYield   = 1
    o.sinewChance = 30
    return o
end

-------------------------------------------------------------------------------
-- Hide Cure: salted hide + knife -> cured hide. Mostly cosmetic timed action;
-- the actual recipe is in scripts but we offer a one-click context wrap.
-------------------------------------------------------------------------------

FHC_CureHideTA = ISBaseTimedAction:derive("FHC_CureHideTA")

function FHC_CureHideTA:isValid()
    if not self.hide then return false end
    if SB.requireTools() and not self.knife then return false end
    return self.character:getInventory():contains(self.hide)
end

function FHC_CureHideTA:start()
    self:setActionAnim("Loot")
    self.character:reportEvent("EventLootItem")
end

function FHC_CureHideTA:perform()
    local player = self.character
    local inv    = player:getInventory()

    if isClient() then
        local x, y, z = U.objectPosition(player)
        if not x then
            ISBaseTimedAction.perform(self)
            return
        end
        sendClientCommand(player, FHC.MODULE, FHC.CMD.HideCureComplete,
            {
                x = x,
                y = y,
                z = z,
                hideId = U.itemId(self.hide),
                knifeId = U.itemId(self.knife),
            })
        ISBaseTimedAction.perform(self)
        return
    end

    inv:Remove(self.hide)
    if self.knife and self.knife.setCondition then
        local cond = self.knife:getCondition()
        if cond > 0 then self.knife:setCondition(cond - 1) end
    end
    inv:AddItem("Base.FHC_CuredHide")
    if Perks and Perks.Trapping and player.getXp then
        player:getXp():AddXP(Perks.Trapping, 8)
    end
    ISBaseTimedAction.perform(self)
end

function FHC_CureHideTA:new(character, hide, knife)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.hide      = hide
    o.knife     = knife
    o.maxTime   = U.scaledTime(280)
    o.stopOnWalk = true
    o.stopOnRun  = true
    return o
end

-------------------------------------------------------------------------------
-- Dry Meat: meat + salt + knife -> dried strip. One-click wrapper around the recipe.
-------------------------------------------------------------------------------

FHC_DryMeatTA = ISBaseTimedAction:derive("FHC_DryMeatTA")

function FHC_DryMeatTA:isValid()
    return self.meat and self.salt and (self.knife or not SB.requireTools())
end

function FHC_DryMeatTA:start()
    self:setActionAnim("Loot")
    self.character:reportEvent("EventLootItem")
end

function FHC_DryMeatTA:perform()
    local player = self.character
    local inv    = player:getInventory()

    if isClient() then
        local x, y, z = U.objectPosition(player)
        if not x then
            ISBaseTimedAction.perform(self)
            return
        end
        sendClientCommand(player, FHC.MODULE, FHC.CMD.DryingComplete,
            {
                x = x,
                y = y,
                z = z,
                meatId = U.itemId(self.meat),
                saltId = U.itemId(self.salt),
                knifeId = U.itemId(self.knife),
            })
        ISBaseTimedAction.perform(self)
        return
    end

    pcall(function() inv:Remove(self.meat) end)
    pcall(function() inv:Remove(self.salt) end)
    if self.knife and self.knife.setCondition then
        local cond = self.knife:getCondition()
        if cond > 0 then self.knife:setCondition(cond - 1) end
    end
    inv:AddItem("Base.FHC_DriedMeat")
    if Perks and Perks.Trapping and player.getXp then
        player:getXp():AddXP(Perks.Trapping, 4)
    end
    ISBaseTimedAction.perform(self)
end

function FHC_DryMeatTA:new(character, meat, salt, knife)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.meat      = meat
    o.salt      = salt
    o.knife     = knife
    o.maxTime   = U.scaledTime(260)
    o.stopOnWalk = true
    o.stopOnRun  = true
    return o
end

-------------------------------------------------------------------------------
-- Hunter Hub crafting: all FHC craft recipes are launched from the hub.
-------------------------------------------------------------------------------

local function removeItemLocal(player, item)
    if not player or not item then return false end
    local inv = player:getInventory()
    local container = item.getContainer and item:getContainer() or inv
    if player.removeFromHands then
        player:removeFromHands(item)
    end
    if container and container.Remove then
        container:Remove(item)
    elseif inv then
        inv:Remove(item)
        container = inv
    end
    if container and container.setDrawDirty then
        container:setDrawDirty(true)
    end
    return true
end

local function degradeItemLocal(item)
    if not item or not item.getCondition or not item.setCondition then return end
    local cond = item:getCondition()
    if cond and cond > 0 then
        item:setCondition(cond - 1)
    end
end

local function awardRecipeXP(player, recipe)
    if not player or not recipe or not recipe.xp then return end
    local perk = U.perkByName(recipe.xp.perk)
    if perk and player.getXp and player:getXp() then
        player:getXp():AddXP(perk, recipe.xp.amount or 0)
    end
end

local function applyHubCraftLocal(player, recipe, selections)
    local bySlot = {}
    for _, selected in ipairs(selections or {}) do
        if selected and selected.slot and selected.item then
            bySlot[selected.slot] = bySlot[selected.slot] or {}
            table.insert(bySlot[selected.slot], selected.item)
        end
    end

    for slot, spec in ipairs(recipe.inputs or {}) do
        local items = bySlot[slot] or {}
        local count = tonumber(spec.count) or 1
        if #items < count then return false end
        for i = 1, count do
            local item = items[i]
            if not U.itemMatchesSpec(item, spec) then return false end
            if spec.keep then
                if spec.degrade then degradeItemLocal(item) end
            else
                removeItemLocal(player, item)
            end
        end
    end

    local inv = player and player:getInventory() or nil
    if not inv then return false end
    local outputCount = recipe.outputCount or 1
    for _ = 1, outputCount do
        inv:AddItem(recipe.output)
    end
    awardRecipeXP(player, recipe)
    return true
end

FHC_HubCraftTA = ISBaseTimedAction:derive("FHC_HubCraftTA")

function FHC_HubCraftTA:isValid()
    local recipe = FHC.HUB_CRAFTS and FHC.HUB_CRAFTS[self.recipeId]
    if not recipe or not U.recipeFeatureAllowed(recipe) then return false end
    if not U.recipeSkillAllowed(self.character, recipe) then return false end
    return U.findRecipeItems(self.character, recipe) ~= nil
end

function FHC_HubCraftTA:start()
    self:setActionAnim("Loot")
    self.character:reportEvent("EventLootItem")
end

function FHC_HubCraftTA:perform()
    local player = self.character
    local recipe = FHC.HUB_CRAFTS and FHC.HUB_CRAFTS[self.recipeId]
    local selected = recipe and U.findRecipeItems(player, recipe) or nil
    if not selected then
        ISBaseTimedAction.perform(self)
        return
    end
    if isClient() then
        local payload = {}
        for _, entry in ipairs(selected) do
            table.insert(payload, { slot = entry.slot, id = entry.id })
        end
        sendClientCommand(player, FHC.MODULE, FHC.CMD.HubCraftComplete,
            { recipeId = self.recipeId, selections = payload })
        ISBaseTimedAction.perform(self)
        return
    end

    applyHubCraftLocal(player, recipe, selected)
    ISBaseTimedAction.perform(self)
end

function FHC_HubCraftTA:new(character, recipeId, selections)
    local recipe = FHC.HUB_CRAFTS and FHC.HUB_CRAFTS[recipeId]
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.recipeId = recipeId
    o.selections = selections
    o.maxTime = U.scaledTime((recipe and recipe.time) or 120)
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end

-------------------------------------------------------------------------------
-- Apply Animal Scent: one bottle -> timed scent effect on the player.
-------------------------------------------------------------------------------

FHC_ApplyScentTA = ISBaseTimedAction:derive("FHC_ApplyScentTA")

function FHC_ApplyScentTA:isValid()
    if not self.item or not self.animalKey or not FHC.SCENT_ITEMS[self.animalKey] then return false end
    if self.item.getFullType and FHC.SCENT_BY_ITEM[self.item:getFullType()] ~= self.animalKey then return false end
    local inv = self.character and self.character:getInventory() or nil
    return inv and inv:contains(self.item)
end

function FHC_ApplyScentTA:start()
    self:setActionAnim("Loot")
    self.character:reportEvent("EventLootItem")
end

function FHC_ApplyScentTA:perform()
    local player = self.character
    if isClient() then
        sendClientCommand(player, FHC.MODULE, FHC.CMD.ApplyScentComplete,
            { animal = self.animalKey, itemId = U.itemId(self.item) })
        ISBaseTimedAction.perform(self)
        return
    end

    removeItemLocal(player, self.item)
    U.applyAnimalScent(player, self.animalKey, FHC.SCENT_DURATION_HOURS)
    if player and player.Say then player:Say(getText("IGUI_FHC_ScentApplied")) end
    ISBaseTimedAction.perform(self)
end

function FHC_ApplyScentTA:new(character, item, animalKey)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.animalKey = animalKey
    o.maxTime = U.scaledTime(80)
    o.stopOnWalk = false
    o.stopOnRun = true
    return o
end

-------------------------------------------------------------------------------
-- Animal Call: learned call -> server-authoritative short attraction pulse.
-------------------------------------------------------------------------------

FHC_AnimalCallTA = ISBaseTimedAction:derive("FHC_AnimalCallTA")

function FHC_AnimalCallTA:isValid()
    if not self.animalKey or not FHC.ANIMAL_CALLS[self.animalKey] then return false end
    if not U.playerKnowsAnimalCall(self.character, self.animalKey) then return false end
    return U.getAnimalCallCooldownRemaining(self.character, self.animalKey) <= 0
end

function FHC_AnimalCallTA:start()
    self:setActionAnim("Loot")
    self.character:reportEvent("EventLootItem")
end

function FHC_AnimalCallTA:perform()
    local player = self.character
    if isClient() then
        sendClientCommand(player, FHC.MODULE, FHC.CMD.AnimalCallComplete,
            { animal = self.animalKey })
        ISBaseTimedAction.perform(self)
        return
    end

    if U.applyAnimalCall(player, self.animalKey, FHC.ANIMAL_CALL_DURATION_HOURS) then
        U.playAnimalCallSound(player, self.animalKey)
        if FHC.AttractAnimalsForCall then
            FHC.AttractAnimalsForCall(player, self.animalKey)
        end
        if player and player.Say then
            player:Say(string.format(getText("IGUI_FHC_CallUsedFmt"),
                (FHC.ANIMALS[self.animalKey] and FHC.ANIMALS[self.animalKey].display) or self.animalKey))
        end
    end
    ISBaseTimedAction.perform(self)
end

function FHC_AnimalCallTA:new(character, animalKey)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.animalKey = animalKey
    o.maxTime = U.scaledTime(70)
    o.stopOnWalk = false
    o.stopOnRun = true
    return o
end
