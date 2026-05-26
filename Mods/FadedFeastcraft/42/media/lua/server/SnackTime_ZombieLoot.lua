------------------------------------------------------------
-- SnackTime '89 – Junk Revival : Zombie Loot
------------------------------------------------------------

require "Items/SuburbsDistributions"

------------------------------------------------------------
-- Fonction principale
------------------------------------------------------------
local function SnackTime89_ZombieLootB42()

    ------------------------------------------------------------
    -- 1️⃣ Lecture du Sandbox et multiplicateur
    ------------------------------------------------------------
    local sandboxLoot = 2 -- par défaut = Rare
    local enableMysteryBoxes = true -- par défaut = activé

    -- Lecture Sandbox via API officielle (Build 42+)
    local sandboxOption = getSandboxOptions()
        and getSandboxOptions():getOptionByName("SnackTime89_ZombieLootRarity")

    if sandboxOption then
        sandboxLoot = sandboxOption:getValue()
        SnackTime89.log("[DEBUG] SandboxOption ZombieLootRarity = " .. tostring(sandboxLoot))
    elseif SandboxVars
        and SandboxVars.SnackTime89
        and SandboxVars.SnackTime89.ZombieLootRarity
    then
        sandboxLoot = SandboxVars.SnackTime89.ZombieLootRarity
        SnackTime89.log("[DEBUG] SandboxVars ZombieLootRarity = " .. tostring(sandboxLoot))
    else
        SnackTime89.log("[DEBUG] Valeur par défaut ZombieLootRarity = 2")
    end

    ------------------------------------------------------------
    -- Lecture option boîtes mystères
    ------------------------------------------------------------
    local mysteryOption = getSandboxOptions()
        and getSandboxOptions():getOptionByName("SnackTime89_EnableMysteryBoxes")

    if mysteryOption then
        enableMysteryBoxes = mysteryOption:getValue()
        SnackTime89.log("[DEBUG] SandboxOption EnableMysteryBoxes = " .. tostring(enableMysteryBoxes))
    elseif SandboxVars
        and SandboxVars.SnackTime89
        and SandboxVars.SnackTime89.EnableMysteryBoxes ~= nil
    then
        enableMysteryBoxes = SandboxVars.SnackTime89.EnableMysteryBoxes
        SnackTime89.log("[DEBUG] SandboxVars EnableMysteryBoxes = " .. tostring(enableMysteryBoxes))
    else
        SnackTime89.log("[DEBUG] Valeur par défaut EnableMysteryBoxes = true")
    end

    local catMult = SnackTime89.getMultiplier(sandboxLoot) or 1.0
    local ZOMBIE_TUNE = 0.40

    SnackTime89.log(string.format(
        "[DEBUG] Multiplicateur final : %.2f (tune %.2f)",
        catMult, ZOMBIE_TUNE
    ))

    ------------------------------------------------------------
    -- 2️⃣ Catégories d'objets
    ------------------------------------------------------------
    local snacks = {
        "SnackTime89.ST_Mars","SnackTime89.ST_Snickers","SnackTime89.ST_Twix","SnackTime89.ST_Bounty",
        "SnackTime89.ST_KitKat","SnackTime89.ST_KitKatChunky","SnackTime89.ST_Lion","SnackTime89.ST_Toblerone","SnackTime89.ST_Crunch",
        "SnackTime89.ST_Nuts","SnackTime89.ST_KinderBueno","SnackTime89.ST_KinderCountry",
        "SnackTime89.ST_KinderDelice","SnackTime89.ST_Maltesers",
        "SnackTime89.ST_Oreo","SnackTime89.ST_MMs","SnackTime89.ST_Chipster","SnackTime89.ST_BenenutsCG","SnackTime89.ST_BenenutsNC","SnackTime89.ST_Skittles"
    }

    local drinks = {
        "SnackTime89.ST_CocaCola","SnackTime89.ST_CocaColaL","SnackTime89.ST_Pepsi","SnackTime89.ST_SevenUp",
        "SnackTime89.ST_Sprite","SnackTime89.ST_Fanta","SnackTime89.ST_FantaCitron","SnackTime89.ST_LiptonIceTea",
        "SnackTime89.ST_OasisTropical","SnackTime89.ST_Orangina","SnackTime89.ST_OranginaR","SnackTime89.ST_CapriSun","SnackTime89.ST_Nestea",
        "SnackTime89.ST_KolaRoman","SnackTime89.ST_YopFraise","SnackTime89.ST_YopBanane","SnackTime89.ST_YopVanille","SnackTime89.ST_MinuteMaid"
    }

    local sweets = {
        "SnackTime89.ST_NestleChocapicBar","SnackTime89.ST_KelloggsFrostiesBar","SnackTime89.ST_Mikado","SnackTime89.ST_Smarties",
        "SnackTime89.ST_BalistoMA","SnackTime89.ST_BalistoFR","SnackTime89.ST_BalistoNR",
        "SnackTime89.ST_HariboMix","SnackTime89.ST_HariboOurs","SnackTime89.ST_HariboTagada",
        "SnackTime89.ST_HariboDragibus","SnackTime89.ST_HariboCroco","SnackTime89.ST_HariboCola","SnackTime89.ST_HariboSchtroumpfs","SnackTime89.ST_MentosFruit","SnackTime89.ST_MentosMint","SnackTime89.ST_DunkaroosC","SnackTime89.ST_DunkaroosV"
    }

    local rareDrinks = {
    	"SnackTime89.ST_RedBull"
    }

    local mysteryBoxes = {
        "SnackTime89.ST_BoiteMystere","SnackTime89.ST_BoiteMystereM"
    }

    ------------------------------------------------------------
    -- 3️⃣ Sécurisation des tables vanilla
    ------------------------------------------------------------
    SuburbsDistributions["all"] = SuburbsDistributions["all"] or {}
    SuburbsDistributions["all"]["inventorymale"]   = SuburbsDistributions["all"]["inventorymale"]   or { items = {} }
    SuburbsDistributions["all"]["inventoryfemale"] = SuburbsDistributions["all"]["inventoryfemale"] or { items = {} }

    ------------------------------------------------------------
    -- 4️⃣ Fonction d’injection
    ------------------------------------------------------------
    local function addLoot(list, baseWeight, label)
        local w = baseWeight * catMult * ZOMBIE_TUNE

        for _, item in ipairs(list) do
            table.insert(SuburbsDistributions["all"]["inventorymale"].items, item)
            table.insert(SuburbsDistributions["all"]["inventorymale"].items, w)
            table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, item)
            table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, w)
        end

        SnackTime89.log(string.format(
            "[DEBUG] Ajout %d objets (%s) – poids=%.3f",
            #list, label, w
        ))
    end

    ------------------------------------------------------------
    -- 5️⃣ Injection avec multiplicateur
    ------------------------------------------------------------
    addLoot(snacks, 0.50, "snacks")
    addLoot(drinks, 0.50, "boissons")
    addLoot(sweets, 0.50, "barres de céréales")
  addLoot(rareDrinks, 0.25, "boissons rares")

    if enableMysteryBoxes then
        addLoot(mysteryBoxes, 0.25, "boîtes mysteres")
        SnackTime89.log("[DEBUG] Boîtes mystères activées dans le loot zombie")
    else
        SnackTime89.log("[DEBUG] Boîtes mystères désactivées dans le loot zombie")
    end

    ------------------------------------------------------------
    -- 6️⃣ Reload du loot
    ------------------------------------------------------------
    if ItemPickerJava and ItemPickerJava.Parse then
        SnackTime89.log("[DEBUG] Reload ItemPickerJava.Parse()")
        ItemPickerJava.Parse()
    end

    SnackTime89.log(string.format(
        "Zombie loot injecté (sandbox=%d, mult=%.2f, tune=%.2f, mystery=%s)",
        sandboxLoot, catMult, ZOMBIE_TUNE, tostring(enableMysteryBoxes)
    ))
end

------------------------------------------------------------
-- Hook différé (MP)
------------------------------------------------------------
Events.OnInitWorld.Add(function()
    SnackTime89.log("InitWorld snack-shelf zombie loot injection")

    local ok, err = pcall(SnackTime89_ZombieLootB42)
    if not ok and err then
        SnackTime89.log("❌ Zombie loot InitWorld error: " .. tostring(err))
    end
end)
