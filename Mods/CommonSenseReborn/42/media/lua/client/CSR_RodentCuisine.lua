-- CSR_RodentCuisine.lua — make skinned rodents proper Game-class food.
-- Sets RemoveUnhappinessWhenCooked, EvolvedRecipeName, and FoodType=Game on
-- the four vanilla rodent items. No new items, no recipes. OnGameBoot only.
local function isExternalActive()
    local mods = getActivatedMods()
    if not mods then return false end
    if mods:contains("Let Me Eat Rats and Mice") then return true end
    if mods:contains("LetMeEatRatsAndMice") then return true end
    return false
end

local function applyRodentCuisine()
    local sb = SandboxVars.CommonSenseReborn or {}
    if sb.EnableRodentCuisine == false then return end
    if isExternalActive() then return end

    local manager = getScriptManager()
    if not manager then return end

    local entries = {
        { id = "Base.DeadMouseSkinned",     name = "Mouse" },
        { id = "Base.DeadMousePupsSkinned", name = "Mouse" },
        { id = "Base.DeadRatSkinned",       name = "Rat" },
        { id = "Base.DeadRatBabySkinned",   name = "Rat" },
    }
    for i = 1, #entries do
        local e = entries[i]
        local item = manager:getItem(e.id)
        if item then
            pcall(function() item:DoParam("RemoveUnhappinessWhenCooked = true") end)
            pcall(function() item:DoParam("EvolvedRecipeName = " .. e.name) end)
            pcall(function() item:DoParam("FoodType = Game") end)
        end
    end
end

Events.OnGameBoot.Add(applyRodentCuisine)
