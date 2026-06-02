------------------------------------------------------------
-- SnackTime '89 – Junk Revival : World Loot Distributions (B42)
------------------------------------------------------------

require "Items/Distributions"
require "Items/ProceduralDistributions"

------------------------------------------------------------
--  Fonction principale : distribution sécurisée
------------------------------------------------------------
local function ST_SafeDistribute()
    if not ProceduralDistributions or not ProceduralDistributions.list then return end

    ------------------------------------------------------------
    -- Application réelle (appelée au bon moment)
    ------------------------------------------------------------
    local function ST_Apply()

        ------------------------------------------------------------
        -- 1️⃣ Lecture du Sandbox et multiplicateur
        ------------------------------------------------------------
        local sandboxLoot = 2 -- par défaut = Rare

        local sandboxOption = getSandboxOptions()
            and getSandboxOptions():getOptionByName("SnackTime89_LootRarity")

        if sandboxOption then
            sandboxLoot = sandboxOption:getValue()
            SnackTime89.log("[DEBUG] SandboxOption LootRarity = " .. tostring(sandboxLoot))
        elseif SandboxVars
            and SandboxVars.SnackTime89
            and SandboxVars.SnackTime89.LootRarity
        then
            sandboxLoot = SandboxVars.SnackTime89.LootRarity
            SnackTime89.log("[DEBUG] SandboxVars LootRarity = " .. tostring(sandboxLoot))
        else
            SnackTime89.log("[DEBUG] Valeur par défaut LootRarity = 2")
        end

        local catMult = SnackTime89.getMultiplier(sandboxLoot) or 1.0
        local WORLD_TUNE = 0.30

        SnackTime89.log(string.format(
            "[B42][WorldLoot] Sandbox=%s | Mult=%.2f | Tune=%.2f",
            tostring(sandboxLoot), catMult, WORLD_TUNE
        ))

        local function ensureProcList(name, defaultRolls)
            if not ProceduralDistributions.list[name] then
                ProceduralDistributions.list[name] = { rolls = defaultRolls or 1, items = {} }
            elseif not ProceduralDistributions.list[name].items then
                ProceduralDistributions.list[name].items = {}
            end
            return ProceduralDistributions.list[name].items
        end

        local function insertItems(container, list, rolls)
            -- sécurité : pas de glaces hors freezer
            if list == icecreams and not string.find(container, "Freezer") then
                return
            end

            local t = ensureProcList(container, rolls)
            for i = 1, #list, 2 do
                local fullType = list[i]
                local baseWeight = list[i + 1]
                local w = baseWeight * catMult * WORLD_TUNE
                table.insert(t, fullType)
                table.insert(t, w)
            end
        end

        ------------------------------------------------------------
        -- 3️⃣ Catégories d’objets
        ------------------------------------------------------------
        local drinks = {
            "SnackTime89.ST_CocaCola",10,"SnackTime89.ST_CocaColaL",10,"SnackTime89.ST_Pepsi",10,"SnackTime89.ST_SevenUp",8,
            "SnackTime89.ST_Sprite",8,"SnackTime89.ST_Fanta",8,"SnackTime89.ST_FantaCitron",8,"SnackTime89.ST_LiptonIceTea",6,
            "SnackTime89.ST_OasisTropical",6,"SnackTime89.ST_CapriSun",6,"SnackTime89.ST_Nestea",5,
            "SnackTime89.ST_MinuteMaid",5,"SnackTime89.ST_YopVanille",3,"SnackTime89.ST_YopFraise",3,
            "SnackTime89.ST_YopBanane",3,"SnackTime89.ST_Orangina",6,"SnackTime89.ST_OranginaR",6,"SnackTime89.ST_KolaRoman",6,"SnackTime89.ST_RedBull",2,
        }

        local sweets = {
            "SnackTime89.ST_Mars",8,"SnackTime89.ST_Snickers",8,"SnackTime89.ST_Twix",8,"SnackTime89.ST_Bounty",7,
            "SnackTime89.ST_KitKat",8,"SnackTime89.ST_KitKatChunky",8,"SnackTime89.ST_Lion",7,"SnackTime89.ST_Smarties",7,
            "SnackTime89.ST_Toblerone",7,"SnackTime89.ST_Crunch",7,"SnackTime89.ST_Nuts",7,
            "SnackTime89.ST_KinderBueno",7,"SnackTime89.ST_KinderCountry",7,"SnackTime89.ST_KinderDelice",7,
            "SnackTime89.ST_LUPetitEcolier",7,"SnackTime89.ST_BNChocolat",7,"SnackTime89.ST_BNFraise",7,
            "SnackTime89.ST_Maltesers",6,"SnackTime89.ST_Oreo",6,"SnackTime89.ST_Mikado",6,
            "SnackTime89.ST_BalistoMA",6,"SnackTime89.ST_BalistoFR",6,"SnackTime89.ST_BalistoNR",6,
            "SnackTime89.ST_MMs",6,"SnackTime89.ST_Skittles",6,"SnackTime89.ST_ChupaChups",5,
            "SnackTime89.ST_HariboMix",5,"SnackTime89.ST_HariboOurs",5,"SnackTime89.ST_HariboTagada",5,
            "SnackTime89.ST_HariboDragibus",5,"SnackTime89.ST_HariboCroco",5,"SnackTime89.ST_HariboSchtroumpfs",5,
            "SnackTime89.ST_HariboCola",5,"SnackTime89.ST_MentosFruit",5,"SnackTime89.ST_MentosMint",5,"SnackTime89.ST_DunkaroosV",5,
            "SnackTime89.ST_DunkaroosC",5,"SnackTime89.ST_NestleChocapicBar",5,"SnackTime89.ST_KelloggsFrostiesBar",5,
            "SnackTime89.ST_ST_ChipsahoyO",4,"SnackTime89.ST_ST_ChipsahoyC",4,
        }

        local salty = {
            "SnackTime89.ST_TucNature",6,"SnackTime89.ST_TucBacon",6,"SnackTime89.ST_LaysNature",6,
            "SnackTime89.ST_LaysPaprika",6,"SnackTime89.ST_LaysCreamOnion",6,"SnackTime89.ST_MonsterMunch",6,
            "SnackTime89.ST_MonsterMunchK",6,"SnackTime89.ST_LaysBBQ",6,"SnackTime89.ST_DoritosNachoCheese",6,
            "SnackTime89.ST_DoritosSpicy",6,"SnackTime89.ST_CheetosCrunchy",6,"SnackTime89.ST_CheetosFlamingHot",6,
            "SnackTime89.ST_PringlesOriginal",5,"SnackTime89.ST_PringlesHotSpicy",5,"SnackTime89.ST_CurlyCheese",5,
            "SnackTime89.ST_CurlyOriginal",5,"SnackTime89.ST_Chipster",5,"SnackTime89.ST_Bretzels",5,
            "SnackTime89.ST_BenenutsCG",5,"SnackTime89.ST_BenenutsNC",5,
        }

        local cereals = {
            "SnackTime89.ST_KelloggsFrostedFlakes",4,"SnackTime89.ST_NestleNesquikCereal",4,
            "SnackTime89.ST_KelloggsHoneyPops",4,"SnackTime89.ST_KelloggsHoneySmacks",4,
            "SnackTime89.ST_KelloggsSpecialK",4,"SnackTime89.ST_KelloggsCornFlakes",4,
            "SnackTime89.ST_NestleChocapic",4,"SnackTime89.ST_KelloggsHoneyLoops",4,
            "SnackTime89.ST_KelloggsChocoKrisp",4,"SnackTime89.ST_KelloggsRiceKrispies",4,
        }

        local icecreams = {
            "SnackTime89.ST_PotGlaceChocolat",2,"SnackTime89.ST_PotGlaceFraise",2,"SnackTime89.ST_PotGlaceVanille",2,
            "SnackTime89.ST_MarsGlace",5,"SnackTime89.ST_SnickersGlace",5,"SnackTime89.ST_TwixGlace",5,
            "SnackTime89.ST_MagnumA",3,"SnackTime89.ST_MagnumC",3,"SnackTime89.ST_BountyGlace",5,
        }

        ------------------------------------------------------------
        -- 4️⃣ Conteneurs & injection
        ------------------------------------------------------------
        for _, c in ipairs({
            "VendingPop","GigamartBeverage","FridgeGeneric","FridgeSmall","OfficeFridge","BarShelf",
            "ConvenienceStoreFridge","RestaurantKitchenFridge","TrailerParkKitchen","TrailerParkFridge",
            "CarGloveBox","CarTrunkFood","BreakRoomFridge","FactoryBreakRoom","ClinicCounter","HotelMiniFridge",
            "HospitalCafeteria","SchoolLockers","SchoolCafeteria","PoliceLockers","FireStationLockers",
            "BarCounterBottles","DinerKitchenFridge","RestaurantStorageFridge","SpiffoFridge","GasStorageFridge",
            "WarehouseBreakRoomFridge","MovieTheatreSnackFridge","CafeFridge","PrisonKitchenFridge","TruckStopFridge"
        }) do insertItems(c, drinks, 1) end

        for _, c in ipairs({
            "VendingSnacks","GigamartSnacks","StoreShelfSnacks","ConvenienceStoreSnacks","KitchenSnack",
            "BreakRoomCounter","OfficeShelfSnacks","OfficeDeskHome","SchoolDesk","SchoolLockers",
            "CafeteriaSnacks","HospitalCafeteria","ClinicDrawer","HotelDresser","BedroomDresser","WardrobeChild",
            "SpiffoCounter","DinerCounter","CafeCounter","GasStorageCounter","BookstoreCounter",
            "WarehouseBreakRoomCounter","FactoryBreakRoomCounter","TrailerParkCounter","BarCounterMisc",
            "PrisonCafeteria","MovieTheatreSnackCounter","TruckStopCounter"
        }) do insertItems(c, sweets, 1) end

        for _, c in ipairs({
            "KitchenDryFood","GigamartFoodDry","StoreShelfSnacks","BarCounterSnacks","BarCounterMisc",
            "GasStorageShelves","ConvenienceStoreShelf","FactoryBreakRoom","TrailerParkKitchen",
            "GasStorageCounter","DinerKitchenShelves","SpiffoCounter","WarehouseBreakRoomCounter",
            "SchoolCafeteria","CafeCounter","RestaurantKitchenShelf","PrisonCafeteria",
            "MovieTheatreSnackShelf","TruckStopShelf"
        }) do insertItems(c, salty, 1) end

        for _, c in ipairs({
            "GigamartCereal","StoreShelfCereal","KitchenDryFood","ConvenienceStoreShelf","TrailerParkKitchen",
            "SchoolCafeteria","WarehouseBreakRoomShelves","FactoryBreakRoomShelf","DinerKitchenShelf",
            "PrisonKitchenShelf","SpiffoPantry","CafeStorage","RestaurantStorageShelf","TruckStopShelf"
        }) do insertItems(c, cereals, 1) end

        for _, c in ipairs({
            "FreezerGeneric","GigamartFreezer","ConvenienceStoreFreezer","RestaurantKitchenFreezer",
            "TrailerParkFreezer","BarFreezer","FactoryBreakRoomFreezer","WarehouseBreakRoomFreezer","TruckStopFreezer"
        }) do insertItems(c, icecreams, 1) end

        SnackTime89.log("Extended Build 42 snack-shelf world loot loaded.")
    end

    local ok, err = pcall(ST_Apply)
    if not ok and err then
        SnackTime89.log(" World loot distribution error: " .. tostring(err))
    end
end

------------------------------------------------------------
-- Hook Build 42 / Serveur
------------------------------------------------------------
Events.OnInitWorld.Add(ST_SafeDistribute)
