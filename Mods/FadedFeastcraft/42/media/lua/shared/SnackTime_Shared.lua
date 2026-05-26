------------------------------------------------------------
-- SnackTime '89 – Shared Functions (Build 41–42)
-- Centralisation des fonctions communes
------------------------------------------------------------

if not SnackTime89 then SnackTime89 = {} end

------------------------------------------------------------
-- Déclaration du Sandbox pour SnackTime '89
------------------------------------------------------------
SandboxVars = SandboxVars or {}
SandboxVars.SnackTime89 = SandboxVars.SnackTime89 or {}

-- Valeurs par défaut des options Sandbox
SandboxVars.SnackTime89.LootRarity          = SandboxVars.SnackTime89.LootRarity          or 2
SandboxVars.SnackTime89.ZombieLootRarity    = SandboxVars.SnackTime89.ZombieLootRarity    or 2
SandboxVars.SnackTime89.EnableMysteryBoxes  = SandboxVars.SnackTime89.EnableMysteryBoxes

if SandboxVars.SnackTime89.EnableMysteryBoxes == nil then
    SandboxVars.SnackTime89.EnableMysteryBoxes = true
end

------------------------------------------------------------
-- Fonction : getMultiplier(level)
-- Sert à ajuster la rareté du loot selon le réglage Sandbox
------------------------------------------------------------
function SnackTime89.getMultiplier(level)
    if level == 1 then return 0.10 end  -- Très rare
    if level == 2 then return 0.30 end  -- Rare (défaut)
    if level == 3 then return 0.60 end  -- Normal
    if level == 4 then return 1.20 end  -- Fréquent
    if level == 5 then return 2.40 end  -- Très fréquent
    return 1.00
end

------------------------------------------------------------
-- Fonction : log(msg)
-- Petite fonction pratique pour afficher les logs du mod
------------------------------------------------------------
function SnackTime89.log(msg)
    if FadedFeastcraft and FadedFeastcraft.Utils then
        FadedFeastcraft.Utils.debug("[FFC Snack Shelf] " .. tostring(msg))
    end
end
