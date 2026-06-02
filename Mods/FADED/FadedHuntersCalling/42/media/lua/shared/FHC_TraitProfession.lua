-- FHC_TraitProfession.lua
-- Shared so it runs on both client (UI shows trait) and server (XP rates).
-- Sandbox-gated. Hooks once at game/server startup.

require "FHC_Constants"
require "FHC_Sandbox"
require "FHC_Utils"

local SB = FHC.SB
local U = FHC.Utils

local function registerTrait()
    if not SB.traitHunter() then return end
    if not TraitFactory then return end
    if TraitFactory.getTrait and TraitFactory.getTrait("FHC_Hunter") then return end

    local t = TraitFactory.addTrait("FHC_Hunter",
        getText("UI_FHC_TraitHunterName"),
        4,
        getText("UI_FHC_TraitHunterDesc"),
        false, false)
    if t and t.getXPBoostMap then
        -- XP boosts: Trapping, Aiming, Tracking (if it exists in 42.18).
        if Perks and Perks.Trapping then t:addXPBoost(Perks.Trapping, 1) end
        if Perks and Perks.Aiming   then t:addXPBoost(Perks.Aiming, 1) end
        if Perks and Perks.Tracking then t:addXPBoost(Perks.Tracking, 2) end
    end
    if t and t.getFreeRecipes and t.getFreeRecipes().add then
        t:getFreeRecipes():add("FHC_CraftBushcraftSpear")
        t:getFreeRecipes():add("FHC_CraftTrappersClub")
        t:getFreeRecipes():add("FHC_HarvestSinewFromCarcass")
    end
    BaseGameCharacterDetails.SetTraitDescription(t)
    U.log("registered trait FHC_Hunter")
end

local function registerProfession()
    if not SB.profTrapper() then return end
    if not ProfessionFactory then return end
    if ProfessionFactory.getProfession and ProfessionFactory.getProfession("FHC_Trapper") then return end

    local p = ProfessionFactory.addProfession("FHC_Trapper",
        getText("UI_FHC_ProfTrapperName"),
        "Prof_FHC_Trapper",
        getText("UI_FHC_ProfTrapperDesc"))
    if p and p.addXPBoost then
        if Perks and Perks.Trapping then p:addXPBoost(Perks.Trapping, 3) end
        if Perks and Perks.Tracking then p:addXPBoost(Perks.Tracking, 1) end
        if Perks and Perks.Foraging then p:addXPBoost(Perks.Foraging, 1) end
    end
    if p and p.addFreeTrait then
        p:addFreeTrait("Outdoorsman")
    end
    U.log("registered profession FHC_Trapper")
end

local function init()
    U.safe(registerTrait, "registerTrait")
    U.safe(registerProfession, "registerProfession")
end

Events.OnGameBoot.Add(init)
Events.OnGameStart.Add(init)
if Events.OnServerStarted then
    Events.OnServerStarted.Add(init)
end
