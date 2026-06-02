require 'Items/ProceduralDistributions'
require 'Items/SuburbsDistributions'
require 'Items/Distributions'
require "Vehicles/VehicleDistributions"
require "FadedFeastcraft/FFC_DistributionSafety"

-- Procedural Distribution items by category
local ProceduralDistribution_Category = {

    ["VFX.BananaBreadSlice"] = {
        BackstageFridge = 8,
        BakeryMisc = 6,
        CafeteriaSandwiches = 10,
        FridgeSnacks = 4,
        HospitalRoomFridge = 2,
        MotelFridge = 10,
        UniversityFridge = 4,
    },

    ["VFX.VanillaFrostingTub"] = {
        BakeryKitchenBaking = 5,
        BakeryKitchenCutlery = 5,
        BakeryKitchenStorage = 5,
        BakeryKitchenTrays = 5,
        GigamartBakingMisc = 5,
        KitchenBaking = 5,
        StoreKitchenBaking = 5,
    },

    ["VFX.FrenchVanillaCakeMix"] = {
        BakeryKitchenBaking = 5,
        BakeryKitchenStorage = 5,
        GigamartBakingMisc = 5,
        GigamartDryGoods = 6,
        GroceryStorageCrate1 = 1,
        KitchenBaking = 5,
        KitchenDryFood = 4,
        StoreKitchenBaking = 5,
    },

    ["VFX.CoffeeCreamerOriginal_2"] = {
        BreakRoomCounter = 10,
        BreakRoomShelves = 10,
        ButcherSpices = 8,
        CafeKitchenCoffee = 20,
        CafeKitchenSupplies = 10,
        CrateCoffee = 10,
        GigamartBreakfast = 10,
        GroceryStorageCrate1 = 1,
        KitchenBreakfast = 4,
        StoreKitchenCafe = 8,
    },

    ["VFX.DrinkMixLemonade"] = {
        CafeKitchenSupplies = 10,
        GigamartDryGoods = 10,
        GroceryStorageCrate1 = 10,
        KitchenDryFood = 10,
        StoreShelfCombo = 10,
    },

    ["VFX.ChocolateMilk"] = {
        CafeDiningFridge = 10,
        CafeteriaDrinks = 8,
        DaycareDesk = 1,
        FridgeSnacks = 8,
        HospitalRoomFridge = 2,
    },

    ["VFX.IcedTeaSweet"] = {
        CafeDiningFridge = 4,
        FridgeBottles = 4,
        FridgeBreakRoom = 4,
        FridgeFarmStorage = 4,
        FridgeGeneric = 4,
        FridgeOffice = 4,
        FridgeRich = 4,
        FridgeTrailerPark = 4,
        GasStorageCombo = 4,
        GigamartBottles = 4,
        GroceryStorageCrate1 = 4,
        KitchenBottles = 4,
        StoreShelfCombo = 4,
    },

    ["VFX.VanillaProteinPowder"] = {
        BreakRoomCounter = 1,
        BreakRoomShelves = 1,
        CampingLockers = 3,
        GymLockers = 5,
        UniversityFridge = 4,
        UniversitySideTable = 10,
    },

    ["VFX.SportsBerryBlast"] = {
        BandPracticeFridge = 4,
        CampingLockers = 2,
        GymLockers = 2,
        Hiker = 5,
    },

    ["VFX.CannedWorms"] = {
        CrateFishing = 10,
        CrateRandomJunk = 1,
        FishermanTools = 10,
        FishingStoreGear = 6,
        SurvivalGear = 10,
    },

    ["VFX.CannedPepperSteakStew"] = {
        ArmyBunkerKitchen = 10,
        CrateCannedFood = 6,
        CrateHumanitarian = 10,
        DerelictHouseSquatter = 10,
        GigamartCannedFood = 6,
        GroceryStorageCrate1 = 1,
        KitchenCannedFood = 4,
    },

    ["VFX.CannedPepperSteakStewBox"] = {
        CrateCannedFood = 10,
    },

    ["VFX.CannedCherryPieFilling"] = {
        ArmyBunkerKitchen = 10,
        CrateCannedFood = 6,
        CrateHumanitarian = 10,
        DerelictHouseSquatter = 10,
        GigamartCannedFood = 6,
        GroceryStorageCrate1 = 1,
        KitchenCannedFood = 4,
    },

    ["VFX.CannedCherryPieFillingBox"] = {
        CrateCannedFood = 10,
    },

    ["VFX.PBJUncrustable"] = {
        FreezerGeneric = 6,
        FreezerRich = 6,
        FreezerTrailerPark = 6,
    },

    ["VFX.WholeStrawberries"] = {
        FreezerFrozenFood = 6,
        FreezerGeneric = 6,
        FreezerRich = 6,
        FreezerTrailerPark = 6,
    },

    ["VFX.FrozenSausageRoll"] = {
        BurgerKitchenFreezer = 8,
        CafeteriaKitchenFreezer = 8,
        DeepFryKitchenFreezer = 8,
        DinerKitchenFreezer = 8,
        FreezerFrozenFood = 6,
        FreezerGarage = 4,
        FreezerGeneric = 4,
        FreezerRich = 5,
        FreezerTrailerPark = 3,
        JaysKitchenFreezer = 10,
        RestaurantKitchenFreezer = 4,
    },

    ["VFX.GroundBeefRavioli"] = {
        CafeteriaKitchenFreezer = 8,
        CafeteriaKitchenFridge = 8,
        FreezerFrozenFood = 6,
        FreezerGeneric = 6,
        FreezerRich = 6,
        FreezerTrailerPark = 6,
        FridgeGeneric = 8,
        FridgeOther = 8,
        FridgeRich = 8,
        FridgeTrailerPark = 6,
        ItalianKitchenFreezer = 6,
        ItalianKitchenFridge = 8,
        PizzaKitchenFridge = 8,
        RestaurantKitchenFreezer = 4,
        RestaurantKitchenFridge = 8,
    },

    ["VFX.WholeFrozenPieCherry"] = {
        CafeteriaKitchenFreezer = 8,
        CafeteriaKitchenFridge = 8,
        CafeDiningFridge = 10,
        FreezerFrozenFood = 6,
        FreezerGeneric = 6,
        FreezerRich = 6,
        FreezerTrailerPark = 6,
        RestaurantKitchenFreezer = 4,
        RestaurantKitchenFridge = 8,
    },

    ["VFX.Distribution_Jars"] = {
        CrateCannedFood = 4,
        GigamartSauce = 8,
        KitchenCannedFood = 4,
    },

    ["VFX.VealCutlet"] = {
        BBQCharcoalRich = 6,
        BBQPropaneRich = 6,
        ButcherFreezer = 6,
        FreezerRich = 6,
        FridgeRich = 2,
        RestaurantKitchenFreezer = 2,
        RestaurantKitchenFridge = 2,
        StoveClassy = 2,
    },

    ["VFX.PowderedSugar"] = {
        BakeryKitchenBaking = 5,
        BakeryKitchenCutlery = 5,
        BakeryKitchenStorage = 5,
        BakeryKitchenTrays = 5,
        GigamartBakingMisc = 5,
        KitchenBaking = 5,
        StoreKitchenBaking = 5,
    },

    ["VFX.Croutons"] = {
        GigamartDryGoods = 10,
        GroceryStorageCrate1 = 1,
        ItalianKitchenBaking = 2,
        KitchenDryFood = 6,
    },

    ["VFX.Allspice"] = {
        ArmyBunkerKitchen = 10,
        BBQCharcoal = 2,
        BBQCharcoalRich = 2,
        BBQPropane = 2,
        BBQPropaneRich = 2,
        GigamartDryGoods = 10,
        GroceryStorageCrate1 = 1,
        KitchenDryFood = 6,
        StoreKitchenButcher = 2,
        StoreShelfCombo = 2,
    },

    ["VFX.HoneyBBQSauce"] = {
        ArmyBunkerKitchen = 10,
        GigamartDryGoods = 10,
        GigamartSauce = 10,
        GroceryStorageCrate1 = 1,
        KitchenDryFood = 6,
        StoreKitchenButcher = 2,
        StoreShelfCombo = 2,
    },

    ["VFX.BarbequeRub"] = {
        ArmyBunkerKitchen = 10,
        BBQCharcoal = 2,
        BBQCharcoalRich = 2,
        BBQPropane = 2,
        BBQPropaneRich = 2,
        GigamartDryGoods = 10,
        GroceryStorageCrate1 = 1,
        KitchenDryFood = 6,
        StoreKitchenButcher = 2,
        StoreShelfCombo = 2,
    },

    ["VFX.PumpkinSoupSachet"] = {
        ArmyBunkerKitchen = 8,
        BreakRoomShelves = 4,
        CampingLockers = 6,
        GigamartDryGoods = 10,
        GroceryStorageCrate1 = 1,
        HuntingLockers = 6,
        KitchenDryFood = 8,
        UniversitySideTable = 10,
    },

    ["VFX.ChocolatePuddingCup"] = {
        GasStorageCombo = 2,
        GroceryStorageCrate1 = 2,
        KitchenDryFood = 2,
        StoreShelfCombo = 2,
        StoreShelfSnacks = 2,
    },

    ["VFX.RiceCakesLightlySalted"] = {
        GroceryStorageCrate1 = 2,
        KitchenDryFood = 2,
        StoreShelfCombo = 2,
        StoreShelfSnacks = 2,
        CampingLockers = 2,
        Hiker = 5,
    },

    ["VFX.ClassicTrailMix"] = {
        CampingLockers = 2,
        GasStorageCombo = 2,
        GroceryStorageCrate1 = 2,
        Hiker = 5,
        KitchenDryFood = 2,
        StoreShelfCombo = 2,
        StoreShelfSnacks = 2,
    },

    -- Sauce and Seasoning
    ["VFX.Distribution_ArenaKitchenSauce"] = {
        ArenaKitchenSauce = 10,
    },

    ["VFX.Distribution_ArenaKitchenSeasoning"] = {
        ArenaKitchenSauce = 10,
    },

    ["VFX.Distribution_BakeryKitchenBakingSauce"] = {
        BakeryKitchenBaking = 5,
    },

    ["VFX.Distribution_BakeryKitchenBakingSeasoning"] = {
        BakeryKitchenBaking = 5,
    },

    ["VFX.Distribution_BreakRoomSauce"] = {
        BreakRoomCounter = 4,
        BreakRoomShelves = 4,
    },

    ["VFX.Distribution_BreakRoomSeasoning"] = {
        BreakRoomCounter = 4,
        BreakRoomShelves = 4,
    },

    ["VFX.Distribution_BurgerKitchenSauce"] = {
        BurgerKitchenSauce = 10,
    },

    ["VFX.Distribution_BurgerKitchenSeasoning"] = {
        BurgerKitchenSauce = 10,
    },

    ["VFX.Distribution_ButcherSpicesSauce"] = {
        ButcherSpices = 8,
    },

    ["VFX.Distribution_ButcherSpicesSeasoning"] = {
        ButcherSpices = 8,
    },

    ["VFX.Distribution_CafeKitchenSuppliesSauce"] = {
        CafeKitchenSupplies = 10,
    },

    ["VFX.Distribution_CafeKitchenSuppliesSeasoning"] = {
        CafeKitchenSupplies = 10,
    },

    ["VFX.Distribution_CafeteriaSnacksSauce"] = {
        CafeteriaSnacks = 10,
    },

    ["VFX.Distribution_ChineseKitchenSauce"] = {
        ChineseKitchenSauce = 10,
    },

    ["VFX.Distribution_ChineseKitchenSeasoning"] = {
        ChineseKitchenBaking = 10,
        ChineseKitchenSauce = 10,
    },

    ["VFX.Distribution_CrepeKitchenSauce"] = {
        CrepeKitchenSauce = 10,
    },

    ["VFX.Distribution_CrepeKitchenSeasoning"] = {
        CrepeKitchenSauce = 10,
    },

    ["VFX.Distribution_FishChipsKitchenSauce"] = {
        FishChipsKitchenSauce = 10,
    },

    ["VFX.Distribution_FishChipsKitchenSeasoning"] = {
        FishChipsKitchenSauce = 10,
    },

    ["VFX.Distribution_FoodGourmetSeasoning"] = {
        FoodGourmet = 10,
    },

    ["VFX.Distribution_GigamartBakingMiscSauce"] = {
        GigamartBakingMisc = 5,
    },

    ["VFX.Distribution_GigamartBakingMiscSeasoning"] = {
        GigamartBakingMisc = 5,
    },

    ["VFX.Distribution_GigamartBBQSauce"] = {
        GigamartBBQ = 10,
    },

    ["VFX.Distribution_GigamartBBQSeasoning"] = {
        GigamartBBQ = 10,
    },

    ["VFX.Distribution_ItalianKitchenSauce"] = {
        ItalianKitchenSauce = 10,
    },

    ["VFX.Distribution_ItalianKitchenSeasoning"] = {
        ItalianKitchenButcher = 10,
        ItalianKitchenSauce = 10,
    },

    ["VFX.Distribution_JaysKitchenSauce"] = {
        JaysKitchenSauce = 10,
    },

    ["VFX.Distribution_JaysKitchenSeasoning"] = {
        JaysKitchenSauce = 10,
    },

    ["VFX.Distribution_MexicanKitchenSauce"] = {
        MexicanKitchenSauce = 10,
    },

    ["VFX.Distribution_MexicanKitchenSeasoning"] = {
        MexicanKitchenSauce = 10,
    },

    ["VFX.Distribution_PizzaKitchenSauce"] = {
        PizzaKitchenSauce = 10,
    },

    ["VFX.Distribution_PizzaKitchenSeasoning"] = {
        PizzaKitchenSauce = 10,
    },

    ["VFX.Distribution_SeafoodKitchenSauce"] = {
        SeafoodKitchenSauce = 10,
    },

    ["VFX.Distribution_SeafoodKitchenSeasoning"] = {
        SeafoodKitchenSauce = 10,
    },

    ["VFX.Distribution_WesternKitchenSauce"] = {
        WesternKitchenSauce = 10,
    },

    ["VFX.Distribution_WesternKitchenSeasoning"] = {
        WesternKitchenSauce = 10,
    },

    -- Containers

    ["VFX.PlasticPitcher"] = {
        CrateDishes = 10,
        DinerBackRoomCounter = 10,
        GigamartHousewares = 10,
        KitchenBottles = 10,
        KitchenDishes = 10,
        StoreKitchenGlasses = 10,
    },

    ["VFX.SpiceRackSmallLight"] = {
        CrateDishes = 10,
        DinerBackRoomCounter = 10,
        GigamartHousewares = 10,
        KitchenBottles = 10,
        KitchenDishes = 10,
    },

    -- Recipe Books

    ["VFX.NonnasKitchenChronicles"] = {
        BookstoreCooking = 3,
        BookstoreMisc = 1,
        ChefOutfit = 2,
        ChefTools = 2,
        CrateMagazines = 1,
        KitchenBook = 3,
        LibraryMagazines = 1,
        LivingRoomShelf = 3,
        LivingRoomShelfClassy = 3,
        LivingRoomShelfRedneck = 3,
        LivingRoomSideTable = 3,
        LivingRoomSideTableClassy = 3,
        LivingRoomSideTableRedneck = 3,
        LivingRoomWardrobe = 3,
        MagazineRackMixed = 1,
        PostOfficeMagazines = 1,
        RecRoomShelf = 3,
        ShelfGeneric = 3,
        UniversityLibraryMagazines = 1,
    },

}

-- Procedural Distribution individual items by container
local ProceduralDistribution_Container = {

    ["ArmyBunkerKitchen"] = {
        ["VFX.ShelfStableMilk"] = 10,
    },

    ["BackstageFridge"] = {
        ["VFX.Brownie"] = 8,
    },

    ["BakeryKitchenFridge"] = {
        ["VFX.HeavyCream"] = 10,
        ["VFX.SoyMilk"] = 10,
    },

    ["BakeryMisc"] = {
        ["VFX.Brownie"] = 6,
    },

    ["BarCounterLiquor"] = {
        ["VFX.JarBlackOlives"] = 2,
        ["VFX.JarGreenOlives"] = 2,
        ["VFX.JarPickledEggs"] = 2,
    },

    ["BarCounterMisc"] = {
        ["VFX.JarBlackOlives"] = 4,
        ["VFX.JarGreenOlives"] = 4,
        ["VFX.JarPickledEggs"] = 4,
    },

    ["BarCounterWeapon"] = {
        ["VFX.JarBlackOlives"] = 2,
        ["VFX.JarGreenOlives"] = 2,
        ["VFX.JarPickledEggs"] = 2,
    },

    ["BreakRoomCounter"] = {
        ["VFX.ProteinShaker"] = 1,
    },

    ["BreakRoomShelves"] = {
        ["VFX.ProteinShaker"] = 1,
        ["VFX.ShelfStableMilk"] = 4,
    },

    ["CafeKitchenFridge"] = {
        ["VFX.HeavyCream"] = 10,
        ["VFX.SoyMilk"] = 10,
    },

    ["CafeteriaKitchenFridge"] = {
        ["VFX.HeavyCream"] = 8,
        ["VFX.ShelfStableMilk"] = 4,
        ["VFX.SoyMilk"] = 8,
    },

    ["CafeteriaSandwiches"] = {
        ["VFX.Brownie"] = 10,
    },

    ["CampingLockers"] = {
        ["VFX.ProteinShaker"] = 3,
    },

    ["CatfishKitchenFridge"] = {
        ["VFX.HeavyCream"] = 10,
    },

    ["CrepeKitchenFridge"] = {
        ["VFX.HeavyCream"] = 8,
        ["VFX.SoyMilk"] = 8,
    },

    ["DeepFryKitchenFridge"] = {
        ["VFX.HeavyCream"] = 8,
    },

    ["DinerKitchenFridge"] = {
        ["VFX.HeavyCream"] = 8,
        ["VFX.SoyMilk"] = 8,
    },

    ["FishChipsKitchenFridge"] = {
        ["VFX.HeavyCream"] = 8,
        ["VFX.SoyMilk"] = 8,
    },

    ["FridgeFarmStorage"] = {
        ["VFX.HeavyCream"] = 10,
        ["VFX.SoyMilk"] = 10,
    },

    ["FridgeGeneric"] = {
        ["VFX.HeavyCream"] = 8,
        ["VFX.JarPickles"] = 1,
        ["VFX.SoyMilk"] = 8,
    },

    ["FridgeOther"] = {
        ["VFX.HeavyCream"] = 10,
        ["VFX.SoyMilk"] = 10,
    },

    ["FridgeRich"] = {
        ["VFX.HeavyCream"] = 10,
        ["VFX.SoyMilk"] = 10,
    },

    ["FridgeSnacks"] = {
        ["VFX.Brownie"] = 4,
    },

    ["FridgeTrailerPark"] = {
        ["VFX.HeavyCream"] = 6,
        ["VFX.SoyMilk"] = 6,
    },

    ["GigamartDryGoods"] = {
        ["VFX.ShelfStableMilk"] = 10,
    },

    ["GroceryStorageCrate1"] = {
        ["VFX.ShelfStableMilk"] = 1,
    },

    ["GymLockers"] = {
        ["VFX.ProteinShaker"] = 5,
    },

    ["HospitalRoomFridge"] = {
        ["VFX.Brownie"] = 2,
        ["VFX.ShelfStableMilk"] = 2,
    },

    ["HotdogStandToppings"] = {
        ["VFX.JarPickledPeppers"] = 4,
        ["VFX.JarPickles"] = 4,
    },

    ["ItalianKitchenFridge"] = {
        ["VFX.HeavyCream"] = 8,
        ["VFX.JarBlackOlives"] = 2,
        ["VFX.JarGreenOlives"] = 2,
        ["VFX.JarSundriedTomatoes"] = 2,
    },

    ["JaysKitchenFridge"] = {
        ["VFX.HeavyCream"] = 8,
    },

    ["KitchenDryFood"] = {
        ["VFX.ShelfStableMilk"] = 6,
    },

    ["MexicanKitchenSauce"] = {
        ["VFX.JarPickledPeppers"] = 8,
    },

    ["MotelFridge"] = {
        ["VFX.Brownie"] = 10,
    },

    ["RestaurantKitchenFridge"] = {
        ["VFX.HeavyCream"] = 8,
        ["VFX.LambLeg"] = 2,
        ["VFX.SoyMilk"] = 8,
    },

    ["UniversityFridge"] = {
        ["VFX.Brownie"] = 4,
    },

    ["UniversitySideTable"] = {
        ["VFX.ProteinShaker"] = 10,
    },

}

-- Distribution items by category
local SuburbsDistribution_Category = {

    ["VFX.CannedPepperSteakStew"] = {
        Bag_FoodCanned = 20,
        GroceryBag1 = 1,
        GroceryBag3 = 10,
        FoodCache1FoodBox = 6,
        SurvivorCache1SurvivorCrate = 6,
        SurvivorCache2SurvivorCrate = 6,
        SurvivorCacheBigBuildingSurvivorCrate = 6,
    },

    ["VFX.CannedWorms"] = {
        Outfit_Fisherman = 10,
        Bag_ProtectiveCase_Survivalist = 10,
        Bag_ProtectiveCaseBulky_Survivalist = 10,
        Bag_ProtectiveCaseSmall_Survivalist = 20,
    },

    ["VFX.CannedPepperSteakStewBox"] = {
        FoodCache1FoodBox = 0.06,
        SurvivorCache1SurvivorCrate = 0.06,
        SurvivorCache2SurvivorCrate = 0.06,
        SurvivorCacheBigBuildingSurvivorCrate = 0.06,
    },

    ["VFX.CannedCherryPieFilling"] = {
        Bag_FoodCanned = 20,
        GroceryBag1 = 1,
        GroceryBag3 = 10,
        FoodCache1FoodBox = 6,
        SurvivorCache1SurvivorCrate = 6,
        SurvivorCache2SurvivorCrate = 6,
        SurvivorCacheBigBuildingSurvivorCrate = 6,
    },

    ["VFX.CannedCherryPieFillingBox"] = {
        FoodCache1FoodBox = 0.06,
        SurvivorCache1SurvivorCrate = 0.06,
        SurvivorCache2SurvivorCrate = 0.06,
        SurvivorCacheBigBuildingSurvivorCrate = 0.06,
    },

    ["VFX.Distribution_Jars"] = {
        GroceryBag1 = 1,
        GroceryBag2 = 1,
        GroceryBag5 = 1,
    },

    ["VFX.PowderedSugar"] = {
        GroceryBag1 = 1,
        GroceryBag4 = 50,
    },

    ["VFX.Allspice"] = {
        GroceryBagGourmet = 4,
    },

    ["VFX.BarbequeRub"] = {
        GroceryBagGourmet = 4,
    },

    ["VFX.HoneyBBQSauce"] = {
        GroceryBag1 = 0.25,
        GroceryBag5 = 50,
    },
    
    ["VFX.ClassicTrailMix"] = {
        Bag_ALICEpack = 2,
        Bag_FoodSnacks = 10,
        Bag_WorkerBag = 2,
        GroceryBag1 = 1,
        FoodCache1FoodBox = 4,
        SurvivorCache1SurvivorCrate = 4,
        SurvivorCache2SurvivorCrate = 4,
        SurvivorCacheBigBuildingSurvivorCrate = 4,
    },

    ["VFX.BananaBreadSlice"] = {
        Bag_PicnicBasket = 10,
    },

    ["VFX.FrenchVanillaCakeMix"] = {
        GroceryBag1 = 1,
        GroceryBag4 = 100,
    },

    ["VFX.IcedTeaSweet"] = {
        GroceryBag1 = 5,
    },

    ["VFX.CoffeeCreamerOriginal_2"] = {
        GroceryBag1 = 5,
    },
}

local function addProceduralDistributionLocations()
    if not ProceduralDistributions or not ProceduralDistributions.list then return end
    for distributionItem, locations in pairs(ProceduralDistribution_Category) do
        for location, weight in pairs(locations) do
            if ProceduralDistributions.list[location] and ProceduralDistributions.list[location].items then
                table.insert(ProceduralDistributions.list[location].items, distributionItem)
                table.insert(ProceduralDistributions.list[location].items, weight)
            end
        end
    end
end

local function addContainerItems()
    if not ProceduralDistributions or not ProceduralDistributions.list then return end
    for container, items in pairs(ProceduralDistribution_Container) do
        if ProceduralDistributions.list[container] and ProceduralDistributions.list[container].items then
            for item, weight in pairs(items) do
                table.insert(ProceduralDistributions.list[container].items, item)
                table.insert(ProceduralDistributions.list[container].items, weight)
            end
        end
    end
end

local function addSuburbsDistributionLocations()
    if not SuburbsDistributions or not SuburbsDistributions.list then return end
    for distributionItem, locations in pairs(SuburbsDistribution_Category) do
        for location, weight in pairs(locations) do
            if SuburbsDistributions.list[location] and SuburbsDistributions.list[location].items then
                table.insert(SuburbsDistributions.list[location].items, distributionItem)
                table.insert(SuburbsDistributions.list[location].items, weight)
            end
        end
    end
end

addProceduralDistributionLocations()
addSuburbsDistributionLocations()
addContainerItems()

local SET_DISTRIBUTIONS = {

    -- Meat and Seafood
        ["Base.Steak"] = {
            items = {
                ["Base.Steak"] = 10,
                ["VFX.BeefBrisket"] = 10,
                ["VFX.BeefShortRibs"] = 10,
                ["VFX.BeefShank"] = 10,
            },
        },

        ["Base.Chicken"] = {
            items = {
                ["Base.Chicken"] = 10,
                ["VFX.ChickenThighs"] = 10,
                ["VFX.ChickenDrumsticks"] = 10,
            },
        },

        ["Base.PorkChop"] = {
            items = {
                ["Base.PorkChop"] = 10,
                ["VFX.PorkBelly"] = 10,
                ["VFX.PorkRibs"] = 10,
            },
        },

        ["Base.MuttonChop"] = {
            items = {
                ["Base.MuttonChop"] = 10,
                ["VFX.LambLeg"] = 10,
            },
        },

        ["Base.MincedMeat"] = {
            items = {
                ["Base.MincedMeat"] = 10,
                ["VFX.GroundChicken"] = 10,
                ["VFX.GroundPork"] = 10,
                ["VFX.GroundLamb"] = 10,
                ["VFX.GroundTurkey"] = 10,

                ["VFX.BeefMeatball"] = 10,
                ["VFX.PorkMeatball"] = 10,
                ["VFX.VealMeatball"] = 10,
                ["VFX.TurkeyMeatball"] = 10,
                ["VFX.ChickenMeatball"] = 10,

                ["VFX.BeefMeatballsBag"] = 5,
                ["VFX.PorkMeatballsBag"] = 5,
                ["VFX.VealMeatballsBag"] = 5,
                ["VFX.TurkeyMeatballsBag"] = 5,
                ["VFX.ChickenMeatballsBag"] = 5,
            },
        },

        ["Base.Salmon"] = {
            items = {
                ["Base.Salmon"] = 10,
                ["VFX.SmokedSalmon"] = 10,
            },
        },

        ["Base.Shrimp"] = {
            items = {
                ["Base.Shrimp"] = 10,
                ["VFX.ImitationCrab"] = 10,
            },
        },

        ["VFX.VealCutlet"] = {
            items = {
                ["VFX.VealCutlet"] = 10,
                ["VFX.DuckBreast"] = 10,
                ["VFX.BlackPudding"] = 5,
            },
        },

        ["Base.Sausage"] = {
            items = {
                ["VFX.PorkSausage"] = 10,
                ["VFX.BeefSausage"] = 10,
                ["VFX.BeefPorkSausage"] = 10,
                ["VFX.ChickenSausage"] = 10,
                ["VFX.SmokedSausage"] = 10,
                ["VFX.SpicySausage"] = 10,
                ["VFX.Chorizo"] = 10,
                ["VFX.CheeseSausage"] = 10,
                ["VFX.PorkSausagePack"] = 5,
                ["VFX.BeefSausagePack"] = 5,
                ["VFX.BeefPorkSausagePack"] = 5,
                ["VFX.ChickenSausagePack"] = 5,
                ["VFX.SmokedSausagePack"] = 5,
                ["VFX.SpicySausagePack"] = 5,
                ["VFX.ChorizoPack"] = 5,
                ["VFX.CheeseSausagePack"] = 5,
            },
        },

    -- Fridge
        ["Base.Cheese"] = {
            items = {
                ["Base.Cheese"] = 10,
                ["VFX.CottageCheese"] = 10,
                ["VFX.CreamCheese"] = 10,
                ["VFX.MozzarellaCheese"] = 10,
                ["VFX.SwissCheese"] = 10,
                ["VFX.BrieCheese"] = 10,
                ["VFX.CamembertCheese"] = 10,
                ["VFX.ParmesanCheese"] = 10,
                ["VFX.GoatCheese"] = 5,
                ["VFX.BlueCheese"] = 5,
            },
        },

        ["Base.Yoghurt"] = {
            items = {
                ["Base.Yoghurt"] = 10,
                ["VFX.VanillaYogurtPot"] = 5,
                ["VFX.StrawberryYogurt"] = 10,
                ["VFX.StrawberryYogurtPot"] = 5,
                ["VFX.BlueberryYogurt"] = 10,
                ["VFX.BlueberryYogurtPot"] = 5,
                ["VFX.PeachYogurt"] = 10,
                ["VFX.PeachYogurtPot"] = 5,
                ["VFX.RaspberryYogurt"] = 10,
                ["VFX.RaspberryYogurtPot"] = 5,
                ["VFX.MixedBerryYogurt"] = 10,
                ["VFX.MixedBerryYogurtPot"] = 5,
                ["VFX.BananaYogurt"] = 10,
                ["VFX.BananaYogurtPot"] = 5,
            },
        },

        ["Base.Dip_Ranch"] = {
            items = {
                ["Base.Dip_Ranch"] = 10,
                ["VFX.Hummus"] = 10,
                ["VFX.BuffaloDip"] = 10,
                ["VFX.FrenchOnionDip"] = 10,
                ["VFX.SpinachArtichokeDip"] = 10,
                ["VFX.BaconCheddarDip"] = 10,
            },
        },

        ["VFX.GroundBeefRavioli"] = {
            items = {
                ["VFX.GroundBeefRavioli"] = 10,
                ["VFX.SpinachRicottaRavioli"] = 10,
                ["VFX.ThreeCheeseRavioli"] = 10,
                ["VFX.PumpkinRavioli"] = 10,
                ["VFX.LobsterRavioli"] = 10,
                ["VFX.ChickenMushroomRavioli"] = 10,
                ["VFX.FourCheeseTortellini"] = 10,
                ["VFX.PepperedPorkTortellini"] = 10,
                ["VFX.SpinachRicottaTortellini"] = 10,
                ["VFX.GroundBeefTortellini"] = 10,
            },
        },

    -- Freezer
        ["Base.PizzaWhole"] = {
            items = {
                ["Base.PizzaWhole"] = 10,
                ["VFX.FrozenCheesePizza"] = 10,
                ["VFX.FrozenThreeMeatPizza"] = 10,
                ["VFX.FrozenPepperoniPizza"] = 10,
                ["VFX.FrozenBuffaloChickenPizza"] = 10,
                ["VFX.FrozenSupremePizza"] = 10,
            },
        },

        ["Base.Pizza"] = {
            items = {
                ["Base.Pizza"] = 10,
                ["VFX.CheesePizzaSlice"] = 10,
                ["VFX.ThreeMeatPizzaSlice"] = 10,
                ["VFX.PepperoniPizzaSlice"] = 10,
                ["VFX.BuffaloChickenPizzaSlice"] = 10,
                ["VFX.SupremePizzaSlice"] = 10,
            },
        },

        ["Base.Frozen_FrenchFries"] = {
            items = {
                ["Base.Frozen_FrenchFries"] = 10,
                ["VFX.BagHashbrowns"] = 10,
                ["VFX.BagWedges"] = 10,
                ["VFX.BagOnionRings"] = 10,
            },
        },

        ["Base.Fries"] = {
            items = {
                ["Base.Fries"] = 10,
                ["VFX.Hashbrowns"] = 10,
                ["VFX.Wedges"] = 10,
            },
        },

        ["Base.Frozen_ChickenNuggets"] = {
            items = {
                ["Base.Frozen_ChickenNuggets"] = 10,
                ["VFX.BagChickenTenders"] = 10,
            },
        },

        ["Base.ChickenNuggets"] = {
            items = {
                ["Base.ChickenNuggets"] = 10,
                ["VFX.FrozenChickenTenders"] = 10,
            },
        },

        ["Base.Burrito"] = {
            items = {
                ["Base.Burrito"] = 10,
                ["VFX.FrozenBeefBurrito"] = 10,
                ["VFX.FrozenChickenBurrito"] = 10,
                ["VFX.FrozenBeanBurrito"] = 10,
            },
        },

        ["Base.MixedVegetables"] = {
            items = {
                ["Base.MixedVegetables"] = 10,
                ["VFX.PackagedBroccoli"] = 10,
                ["VFX.PackagedCauliflower"] = 10,
                ["VFX.PackagedPumpkin"] = 10,
            },
        },

        ["Base.CornFrozen"] = {
            items = {
                ["Base.CornFrozen"] = 10,
                ["VFX.PackagedCarrot"] = 10,
                ["VFX.PackagedPeas"] = 10,
                ["VFX.PackagedBeans"] = 10,
            },
        },

        ["Base.TVDinner"] = {
            items = {
                ["Base.TVDinner"] = 10,
                ["VFX.SpaghettiMeatballsFrozenMeal"] = 10,
                ["VFX.CottagePieFrozenMeal"] = 10,
                ["VFX.ChickenPotPieFrozenMeal"] = 10,
                ["VFX.MacNCheeseFrozenMeal"] = 10,
                ["VFX.SalisburySteakFrozenMeal"] = 10,
                ["VFX.RoastTurkeyFrozenMeal"] = 10,
                ["VFX.MeatloafFrozenMeal"] = 10,
            },
        },

        ["Base.Popsicle"] = {
            items = {
                ["Base.Popsicle"] = 10,
                ["VFX.CherryPopsicle"] = 10,
                ["VFX.GrapePopsicle"] = 10,
                ["VFX.OrangePopsicle"] = 10,
                ["VFX.LimePopsicle"] = 10,
                ["VFX.StrawberryPopsicle"] = 10,
                ["VFX.TropicalPopsicle"] = 10,
                ["VFX.BananaPopsicle"] = 10,
            },
        },

        ["Base.Icecream"] = {
            items = {
                ["Base.Icecream"] = 10,
                ["VFX.ChocolateIceCream"] = 10,
                ["VFX.ChocolateChipIceCream"] = 10,
                ["VFX.StrawberryIceCream"] = 10,
                ["VFX.NeapolitanIceCream"] = 10,
                ["VFX.ButterPecanIceCream"] = 10,
                ["VFX.MintChocolateChipIceCream"] = 10,
                ["VFX.CookiesAndCreamIceCream"] = 10,
                ["VFX.RockyRoadIceCream"] = 10,
                ["VFX.PistachioIceCream"] = 10,
            },
        },

        ["VFX.FrozenSausageRoll"] = {
            items = {
                ["VFX.FrozenSausageRoll"] = 10,
                ["VFX.FrozenMeatPie"] = 10,

                ["VFX.BagMozzarellaSticks"] = 5,
                ["VFX.FrozenMozzarellaSticks"] = 10,
                ["VFX.FrozenEggRoll"] = 10,

                ["VFX.CheesePizzaRoll_Box"] = 5,
                ["VFX.CheesePizzaRoll"] = 10,
                ["VFX.PepperoniPizzaRoll_Box"] = 5,
                ["VFX.PepperoniPizzaRoll"] = 10,
                ["VFX.SupremePizzaRoll_Box"] = 5,
                ["VFX.SupremePizzaRoll"] = 10,
                ["VFX.MeatLoversPizzaRoll_Box"] = 5,
                ["VFX.MeatLoversPizzaRoll"] = 10,
            },
        },

        ["VFX.PBJUncrustable"] = {
            items = {
                ["VFX.PBJUncrustable_Box"] = 5,
                ["VFX.PBJUncrustable"] = 10,
                ["VFX.PBFUncrustable_Box"] = 5,
                ["VFX.PBFUncrustable"] = 10,
                ["VFX.CSUncrustable_Box"] = 5,
                ["VFX.CSUncrustable"] = 10,
                ["VFX.CHUncrustable_Box"] = 5,
                ["VFX.CHUncrustable"] = 10,
                ["VFX.SECBreakfastSandwich_Box"] = 5,
                ["VFX.SECBreakfastSandwich"] = 10,
                ["VFX.BECBreakfastSandwich_Box"] = 5,
                ["VFX.BECBreakfastSandwich"] = 10,
                ["VFX.TECBreakfastSandwich_Box"] = 5,
                ["VFX.TECBreakfastSandwich"] = 10,
                ["VFX.ECBreakfastSandwich_Box"] = 5,
                ["VFX.ECBreakfastSandwich"] = 10,
            },
        },

        ["VFX.WholeStrawberries"] = {
            items = {
                ["VFX.WholeStrawberries"] = 10,
                ["VFX.PineappleChunks"] = 10,
                ["VFX.Blueberries"] = 10,
                ["VFX.MangoChunks"] = 10,
                ["VFX.SlicedStrawberries"] = 10,
                ["VFX.SlicedBananas"] = 10,
                ["VFX.Raspberries"] = 10,
                ["VFX.DarkSweetCherries"] = 10,
                ["VFX.RedTartCherries"] = 10,
                ["VFX.Blackberries"] = 10,
                ["VFX.MixedFruit"] = 10,
                ["VFX.BerryMedley"] = 10,
                ["VFX.StrawberryBananaBlend"] = 10,
            },
        },

        ["VFX.WholeFrozenPieCherry"] = {
            items = {
                ["VFX.WholeFrozenPieCherry"] = 10,
                ["VFX.WholeFrozenPieApple"] = 10,
                ["VFX.WholeFrozenPieBlueberry"] = 10,
                ["VFX.WholeFrozenPieStrawberry"] = 10,
                ["VFX.WholeFrozenPiePeach"] = 10,
                ["VFX.WholeFrozenPieMixedBerry"] = 10,
                ["VFX.WholeFrozenPieLemonCream"] = 10,
                ["VFX.WholeFrozenPieBlackberry"] = 10,
                ["VFX.WholeFrozenPieRaspberry"] = 10,
            },
        },

    -- Cans
        ["Base.CannedBellPepper"] = {
            items = {
                ["Base.CannedBellPepper"] = 10,
                ["VFX.JarApricots"] = 10,
                ["VFX.JarBeetroot"] = 10,
            },
        },

        ["Base.CannedBroccoli"] = {
            items = {
                ["Base.CannedBroccoli"] = 10,
                ["VFX.JarBrusselSprouts"] = 10,
                ["VFX.JarCherry"] = 10,
            },
        },

        ["Base.CannedCabbage"] = {
            items = {
                ["Base.CannedCabbage"] = 10,
                ["VFX.JarCucumber"] = 10,
                ["VFX.JarGarlic"] = 10,
            },
        },

        ["Base.CannedCarrots"] = {
            items = {
                ["Base.CannedCarrots"] = 10,
                ["VFX.JarGreenBeans"] = 10,
                ["VFX.JarOnion"] = 10,
                
            },
        },

        ["Base.CannedEggplant"] = {
            items = {
                ["Base.CannedCarrots"] = 10,
                ["VFX.JarPeach"] = 10,
                ["VFX.JarPear"] = 10,
            },
        },

        ["Base.CannedLeek"] = {
            items = {
                ["Base.CannedLeek"] = 10,
                ["VFX.JarGreenPeas"] = 10,
                ["VFX.JarPepperJalapeno"] = 10,
            },
        },

        ["Base.CannedPotato"] = {
            items = {
                ["Base.CannedLeek"] = 10,
                ["VFX.JarPlums"] = 10,
                ["VFX.JarPumpkin"] = 10,
            },
        },

        ["Base.CannedRedRadish"] = {
            items = {
                ["Base.CannedLeek"] = 10,
                ["VFX.JarSquash"] = 10,
                ["VFX.JarCorn"] = 10,
            },
        },

        ["Base.CannedTomato"] = {
            items = {
                ["Base.CannedLeek"] = 10,
                ["VFX.JarSweetPotato"] = 10,
                ["VFX.JarZucchini"] = 10,
            },
        },

        ["Base.CannedBolognese"] = {
            items = {
                ["Base.CannedBolognese"] = 10,
                ["VFX.CannedSavoryMince"] = 10,
                ["VFX.CannedBeefRavioli"] = 10,
                ["VFX.CannedSpinachRavioli"] = 10,
                ["VFX.CannedMushroomRavioli"] = 10,
                ["VFX.CannedSpaghettiAndMeatballs"] = 10,
                ["VFX.CannedSpaghetti"] = 10,
            },
        },

        ["Base.CannedBolognese_Box"] = {
            items = {
                ["Base.CannedBolognese_Box"] = 10,
                ["VFX.CannedSavoryMince_Box"] = 10,
                ["VFX.CannedBeefRavioli_Box"] = 10,
                ["VFX.CannedSpinachRavioli_Box"] = 10,
                ["VFX.CannedMushroomRavioli_Box"] = 10,
                ["VFX.CannedSpaghettiAndMeatballs_Box"] = 10,
                ["VFX.CannedSpaghettiBox"] = 10,
            },
        },

        ["Base.CannedChili"] = {
            items = {
                ["Base.CannedChili"] = 10,
                ["VFX.CannedSloppyJoe"] = 10,
                ["VFX.CannedMeatloaf"] = 10,
                ["VFX.CannedVegetarianChili"] = 10,
                ["VFX.CannedRedBeansAndRice"] = 10,
                ["VFX.CannedClamChowder"] = 10,
            },
        },

        ["Base.CannedChili_Box"] = {
            items = {
                ["Base.CannedChili"] = 10,
                ["VFX.CannedSloppyJoe_Box"] = 10,
                ["VFX.CannedMeatloaf_Box"] = 10,
                ["VFX.CannedVegetarianChili_Box"] = 10,
                ["VFX.CannedRedBeansAndRice_Box"] = 10,
                ["VFX.CannedClamChowder_Box"] = 10,
            },
        },

        ["Base.CannedMushroomSoup"] = {
            items = {
                ["Base.CannedMushroomSoup"] = 10,
                ["VFX.CannedBroccoliCheddarSoup"] = 10,
                ["VFX.CannedChickenNoodleSoup"] = 10,
                ["VFX.CannedFrenchOnionSoup"] = 10,
                ["VFX.CannedLaksaNoodleSoup"] = 10,
                ["VFX.CannedLentilSoup"] = 10,
            },
        },

        ["Base.CannedMushroomSoup_Box"] = {
            items = {
                ["Base.CannedMushroomSoup_Box"] = 10,
                ["VFX.CannedBroccoliCheddarSoupBox"] = 10,
                ["VFX.CannedChickenNoodleSoupBox"] = 10,
                ["VFX.CannedFrenchOnionSoupBox"] = 10,
                ["VFX.CannedLaksaNoodleSoupBox"] = 10,
                ["VFX.CannedLentilSoupBox"] = 10,
            },
        },

        ["Base.TinnedSoup"] = {
            items = {
                ["Base.TinnedSoup"] = 10,
                ["VFX.CannedMinestroneSoup"] = 10,
                ["VFX.CannedPeaHamSoup"] = 10,
                ["VFX.CannedPotatoLeekSoup"] = 10,
                ["VFX.CannedPumpkinSoup"] = 10,
                ["VFX.CannedTomatoSoup"] = 10,
            },
        },

        ["Base.TinnedSoup_Box"] = {
            items = {
                ["Base.TinnedSoup_Box"] = 10,
                ["VFX.CannedMinestroneSoupBox"] = 10,
                ["VFX.CannedPeaHamSoupBox"] = 10,
                ["VFX.CannedPotatoLeekSoupBox"] = 10,
                ["VFX.CannedPumpkinSoupBox"] = 10,
                ["VFX.CannedTomatoSoupBox"] = 10,
            },
        },

        ["Base.CannedCarrots2"] = {
            items = {
                ["Base.CannedCarrots2"] = 10,
                ["VFX.CannedSlicedMushroom"] = 10,
                ["VFX.CannedMixedVegetableMedley"] = 10,
                ["VFX.CannedPumpkinPuree"] = 10,
                ["VFX.CannedEdamameBeans"] = 5,
            },
        },

        ["Base.CannedCarrots_Box"] = {
            items = {
                ["Base.CannedCarrots_Box"] = 10,
                ["VFX.CannedSlicedMushroomBox"] = 10,
                ["VFX.CannedMixedVegetableMedleyBox"] = 10,
                ["VFX.CannedPumpkinPuree_Box"] = 10,
                ["VFX.CannedEdamameBeansBox"] = 5,
            },
        },

        ["Base.CannedCorn"] = {
            items = {
                ["Base.CannedCorn"] = 10,
                ["VFX.CannedGreenBeans"] = 10,
                ["VFX.CannedSpinach"] = 10,
                ["VFX.CannedCreamCorn"] = 10,
            },
        },

        ["Base.CannedCorn_Box"] = {
            items = {
                ["Base.CannedCorn_Box"] = 10,
                ["VFX.CannedGreenBeansBox"] = 10,
                ["VFX.CannedSpinachBox"] = 10,
                ["VFX.CannedCreamCornOpen_Box"] = 10,
            },
        },

        ["Base.TinnedBeans"] = {
            items = {
                ["Base.TinnedBeans"] = 10,
                ["VFX.CannedBlackBeans"] = 10,
                ["VFX.CannedChickpeas"] = 10,
                ["VFX.CannedKidneyBeans"] = 10,
                ["VFX.CannedLentils"] = 10,
                ["VFX.CannedWhiteBeans"] = 10,
                ["VFX.CannedThreeBeanMix"] = 10,
                ["VFX.CannedCoconutMilk"] = 10,
                ["VFX.CannedCoconutCream"] = 10,
            },
        },

        ["Base.TinnedBeans_Box"] = {
            items = {
                ["Base.TinnedBeans_Box"] = 10,
                ["VFX.CannedBlackBeans_Box"] = 10,
                ["VFX.CannedChickpeas_Box"] = 10,
                ["VFX.CannedKidneyBeans_Box"] = 10,
                ["VFX.CannedLentils_Box"] = 10,
                ["VFX.CannedWhiteBeans_Box"] = 10,
                ["VFX.CannedThreeBeanMix_Box"] = 10,
            },
        },

        ["Base.CannedCornedBeef"] = {
            items = {
                ["Base.CannedCornedBeef"] = 10,
                ["VFX.CannedHam"] = 10,
                ["VFX.CannedCatFood"] = 10,
                ["VFX.CannedChicken"] = 10,
            },
        },

        ["Base.CannedCornedBeef_Box"] = {
            items = {
                ["Base.CannedCornedBeef"] = 10,
                ["VFX.CannedHamBox"] = 10,
                ["VFX.CannedCatFoodBox"] = 10,
                ["VFX.CannedChickenBox"] = 10,
            },
        },

        ["Base.TunaTin"] = {
            items = {
                ["Base.TunaTin"] = 10,
                ["VFX.CannedSalmon"] = 10,
            },
        },

        ["Base.TunaTin_Box"] = {
            items = {
                ["Base.TunaTin_Box"] = 10,
                ["VFX.CannedSalmonBox"] = 10,
            },
        },

        ["Base.CannedSardines"] = {
            items = {
                ["Base.CannedSardines"] = 10,
                ["VFX.CannedAnchovies"] = 10,
            },
        },

        ["Base.CannedSardines_Box"] = {
            items = {
                ["Base.CannedSardines_Box"] = 10,
                ["VFX.CannedAnchoviesBox"] = 10,
            },
        },

        ["Base.CannedFruitCocktail"] = {
            items = {
                ["Base.CannedFruitCocktail"] = 10,
                ["VFX.CannedAppleSlices"] = 10,
                ["VFX.CannedPearSlices"] = 10,
            },
        },

        ["Base.CannedFruitCocktail_Box"] = {
            items = {
                ["Base.CannedFruitCocktail_Box"] = 10,
                ["VFX.CannedAppleSlicesBox"] = 10,
                ["VFX.CannedPearSlicesBox"] = 10,
            },
        },

        ["Base.CannedPeaches"] = {
            items = {
                ["Base.CannedPeaches"] = 10,
                ["VFX.CannedPassionfruit"] = 10,
                ["VFX.CannedLychees"] = 10,
            },
        },

        ["Base.CannedPeaches_Box"] = {
            items = {
                ["Base.CannedPeaches_Box"] = 10,
                ["VFX.CannedPassionfruitBox"] = 10,
                ["VFX.CannedLycheesBox"] = 10,
            },
        },

        ["Base.CannedPineapple"] = {
            items = {
                ["Base.CannedPineapple"] = 10,
                ["VFX.CannedMangoSlices"] = 10,
                ["VFX.CannedApricots"] = 10,
            },
        },

        ["Base.CannedPineapple_Box"] = {
            items = {
                ["Base.CannedPineapple_Box"] = 10,
                ["VFX.CannedMangoSlicesBox"] = 10,
                ["VFX.CannedApricotsBox"] = 10,
            },
        },

        ["VFX.CannedPepperSteakStew"] = {
            items = {
                ["VFX.CannedPepperSteakStew"] = 10,
                ["VFX.CannedBeefMushroomStew"] = 10,
                ["VFX.CannedIrishStew"] = 10,
                ["VFX.CannedSteakOnionStew"] = 10,
                ["VFX.CannedChiliBeanStew"] = 10,
                ["VFX.CannedVegetableStew"] = 10,
            },
        },

        ["VFX.CannedPepperSteakStewBox"] = {
            items = {
                ["VFX.CannedPepperSteakStewBox"] = 10,
                ["VFX.CannedBeefMushroomStewBox"] = 10,
                ["VFX.CannedIrishStewBox"] = 10,
                ["VFX.CannedSteakOnionStewBox"] = 10,
                ["VFX.CannedChiliBeanStewBox"] = 10,
                ["VFX.CannedVegetableStewBox"] = 10,
            },
        },

        ["VFX.CannedWorms"] = {
            items = {
                ["VFX.CannedCrickets"] = 10,
                ["VFX.CannedSnails"] = 10,
                ["VFX.CannedWorms"] = 10,
            },
        },

        ["VFX.CannedCherryPieFilling"] = {
            items = {
                ["VFX.CannedCherryPieFilling"] = 10,
                ["VFX.CannedApplePieFilling"] = 10,
                ["VFX.CannedBlueberryPieFilling"] = 10,
                ["VFX.CannedStrawberryPieFilling"] = 10,
                ["VFX.CannedPeachPieFilling"] = 10,
                ["VFX.CannedMixedBerryPieFilling"] = 10,
                ["VFX.CannedLemonCreamPieFilling"] = 10,
                ["VFX.CannedBlackberryPieFilling"] = 10,
                ["VFX.CannedRaspberryPieFilling"] = 10,
            },
        },

        ["VFX.CannedCherryPieFillingBox"] = {
            items = {
                ["VFX.CannedCherryPieFilling_Box"] = 10,
                ["VFX.CannedApplePieFilling_Box"] = 10,
                ["VFX.CannedBlueberryPieFilling_Box"] = 10,
                ["VFX.CannedStrawberryPieFilling_Box"] = 10,
                ["VFX.CannedPeachPieFilling_Box"] = 10,
                ["VFX.CannedMixedBerryPieFilling_Box"] = 10,
                ["VFX.CannedLemonCreamPieFilling_Box"] = 10,
                ["VFX.CannedBlackberryPieFilling_Box"] = 10,
                ["VFX.CannedRaspberryPieFilling_Box"] = 10,
            },
        },

    -- Jars
        ["VFX.Distribution_Jars"] = {
            items = {
                ["VFX.JarBlackOlives"] = 10,
                ["VFX.JarGreenOlives"] = 10,
                ["VFX.JarSundriedTomatoes"] = 8,
                ["VFX.JarPickledPeppers"] = 10,
                ["VFX.JarPickledEggs"] = 6,
                ["VFX.JarPickles"] = 12,
            },
        },

    -- Pantry
        ["Base.JamFruit"] = {
            items = {
                ["Base.JamFruit"] = 10,
                ["VFX.ApricotJam"] = 10,
                ["VFX.GrapeJam"] = 10,
                ["VFX.RaspberryJam"] = 10,
                ["VFX.PeachJam"] = 10,
                ["VFX.HazelnutSpread"] = 10,
                ["VFX.AppleButter"] = 10,
                ["VFX.CheeseSpread"] = 10,
                
            },
        },

        ["Base.JamMarmalade"] = {
            items = {
                ["Base.JamMarmalade"] = 10,
                ["VFX.StrawberryJam"] = 10,
                ["VFX.BlackberryJam"] = 10,
                ["VFX.BlueberryJam"] = 10,
                ["VFX.LemonMarmalade"] = 10,
                ["VFX.CinnamonButter"] = 10,
                ["VFX.MapleButter"] = 10,
                ["VFX.LiverSpread"] = 10,
            },
        },

        ["Base.BouillonCube"] = {
            items = {
                ["Base.BouillonCube"] = 10,
                ["VFX.BoxChickenBouillonCube"] = 10,
                ["VFX.BeefBouillonCube"] = 10,
                ["VFX.BoxBeefBouillonCube"] = 10,
                ["VFX.FishBouillonCube"] = 10,
                ["VFX.BoxFishBouillonCube"] = 10,
                ["VFX.VegetableBouillonCube"] = 10,
                ["VFX.BoxVegetableBouillonCube"] = 10,
            },
        },

        ["Base.Marinara"] = {
            items = {
                ["Base.Marinara"] = 10,
                ["VFX.SpicyMarinara"] = 10,
                ["VFX.MeatSauce"] = 10,
                ["VFX.BasilPestoSauce"] = 10,
                ["VFX.AlfredoSauce"] = 10,
                ["VFX.BechamelSauce"] = 10,
            },
        },

        ["Base.Rice"] = {
            items = {
                ["Base.Rice"] = 10,
                ["VFX.BrownRice"] = 10,
                ["VFX.JasmineRice"] = 10,
                ["VFX.BasmatiRice"] = 10,
                ["VFX.ArborioRice"] = 10,
            },
        },

        ["Base.Pasta"] = {
            items = {
                ["Base.Pasta"] = 10,
                ["VFX.LasagnaSheets"] = 10,
                ["VFX.Fettuccine"] = 10,
            },
        },

        ["Base.Macaroni"] = {
            items = {
                ["VFX.Macaroni"] = 10,
                ["VFX.Penne"] = 10,
                ["VFX.Gnocchi"] = 10,
            },
        },

        ["Base.Ramen"] = {
            items = {
                ["VFX.BoxChickenRamen"] = 5,
                ["VFX.ChickenRamen"] = 10,
                ["VFX.BoxBeefRamen"] = 5,
                ["VFX.BeefRamen"] = 10,
                ["VFX.BoxShrimpRamen"] = 5,
                ["VFX.ShrimpRamen"] = 10,
                ["VFX.BoxPorkRamen"] = 5,
                ["VFX.PorkRamen"] = 10,
                ["VFX.BoxHotAndSpicyRamen"] = 5,
                ["VFX.HotAndSpicyRamen"] = 10,
                ["VFX.BoxSoySauceRamen"] = 5,
                ["VFX.SoySauceRamen"] = 10,
            },
        },

        ["Base.Macandcheese"] = {
            items = {
                ["Base.Macandcheese"] = 10,
                ["VFX.PMCheddarBroccoli"] = 10,
                ["VFX.PMParmesan"] = 10,
                ["VFX.PMCreamyChicken"] = 10,
                ["VFX.PMCreamyPesto"] = 10,
                ["VFX.PMAlfredo"] = 10,
                ["VFX.PMMacCheese"] = 10,
                ["VFX.RMChicken"] = 10,
                ["VFX.RMMexican"] = 10,
                ["VFX.RMMedley"] = 10,
                ["VFX.RMFried"] = 10,
            },
        },

        ["Base.Cereal"] = {
            items = {
                ["Base.Cereal"] = 10,
                ["VFX.OatyOs"] = 10,
                ["VFX.HoneyOatyOs"] = 10,
                ["VFX.RiceKrisps"] = 10,
                ["VFX.FrostyCrunch"] = 10,
                ["VFX.FruityLoops"] = 10,
                ["VFX.UnluckyCharms"] = 10,
                ["VFX.AdmiralChomp"] = 10,
                ["VFX.CocoaPuffs"] = 10,
                ["VFX.Wheaties"] = 10,
                ["VFX.HoneyOatsGranola"] = 10,
                ["VFX.FruitNutGranola"] = 10,
                ["VFX.MaplePecanGranola"] = 10,
                ["VFX.CoconutAlmondGranola"] = 10,
                ["VFX.ChocolateChipGranola"] = 10,
            },
        },

        ["VFX.PowderedSugar"] = {
            items = {
                ["VFX.PowderedSugar"] = 10,
                ["VFX.VanillaExtract"] = 10,
                ["VFX.Sprinkles"] = 10,
                ["VFX.BakingPowder"] = 10,
                ["VFX.Breadcrumbs"] = 10,
            },
        },

        ["VFX.Allspice"] = {
            items = {
                ["VFX.Allspice"] = 10,
                ["VFX.BayLeaves"] = 10,
                ["VFX.Cardamom"] = 10,
                ["VFX.CayennePepper"] = 10,
                ["VFX.CelerySalt"] = 10,
                ["VFX.ChiliFlakes"] = 10,
                ["VFX.CinnamonSugar"] = 10,
                ["VFX.Cloves"] = 10,
                ["VFX.Cumin"] = 10,
                ["VFX.CurryPowder"] = 10,
                ["VFX.Dill"] = 10,
                ["VFX.FennelSeeds"] = 10,
                ["VFX.GaramMasala"] = 10,
                ["VFX.GarlicSalt"] = 10,
                ["VFX.GroundChili"] = 10,
                ["VFX.GroundGinger"] = 10,
                ["VFX.MustardPowder"] = 10,
                ["VFX.Nutmeg"] = 10,
                ["VFX.OnionFlakes"] = 10,
                ["VFX.Paprika"] = 10,
                ["VFX.SmokedPaprika"] = 10,
                ["VFX.WhitePepper"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.BarbequeRub"] = {
            items = {
                ["VFX.BarbequeRub"] = 10,
                ["VFX.CajunSeasoning"] = 10,
                ["VFX.ChineseFiveSpice"] = 10,
                ["VFX.ItalianHerbsSeasoning"] = 10,
                ["VFX.LemonPepperSeasoning"] = 10,
                ["VFX.MemphisBarbequeRub"] = 10,
                ["VFX.OldBaySeasoning"] = 10,
                ["VFX.PoultrySeasoning"] = 10,
                ["VFX.PumpkinSpiceSeasoning"] = 10,
                ["VFX.RanchSeasoning"] = 10,
                ["VFX.SteakhouseSeasoning"] = 10,
                ["VFX.TexMexSeasoning"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.HoneyBBQSauce"] = {
            items = {
                ["VFX.HoneyBBQSauce"] = 10,
                ["VFX.Aioli"] = 10,
                ["VFX.Ranch"] = 10,
                ["VFX.ChipotleSauce"] = 10,
                ["VFX.BuffaloSauce"] = 10,
                ["VFX.SweetChiliSauce"] = 10,
                ["VFX.TartarSauce"] = 10,
                ["VFX.CocktailSauce"] = 10,
                ["VFX.AppleSauce"] = 10,
                ["VFX.CranberrySauce"] = 10,
                ["VFX.Horseradish"] = 10,
                ["VFX.DijonMustard"] = 10,
                ["VFX.SpicyBrownMustard"] = 10,
                ["VFX.HoneyMustard"] = 10,
                ["VFX.SweetOnionRelish"] = 10,
                ["VFX.TomatoRelish"] = 10,
                ["VFX.PickleRelish"] = 10,
                ["VFX.LemonJuice"] = 10,
                ["VFX.LimeJuice"] = 10,
                ["VFX.CaesarSaladDressing"] = 10,
                ["VFX.ColeslawDressing"] = 10,
                ["VFX.Vinaigrette"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },    

        ["VFX.PumpkinSoupSachet"] = {
            items = {
                ["VFX.BoxPumpkinSoupSachets"] = 5,
                ["VFX.PumpkinSoupSachet"] = 10,
                ["VFX.BoxPeaAndHamSoupSachets"] = 5,
                ["VFX.PeaAndHamSoupSachet"] = 10,
                ["VFX.BoxChickenNoodleSoupSachets"] = 5,
                ["VFX.ChickenNoodleSoupSachet"] = 10,
                ["VFX.BoxTomatoSoupSachets"] = 5,
                ["VFX.TomatoSoupSachet"] = 10,
            },
        },

        ["VFX.Croutons"] = {
            items = {
                ["VFX.Croutons"] = 10,
                ["VFX.CroutonsGarlic"] = 10,
                ["VFX.CroutonsHerbButter"] = 10,
                ["VFX.CroutonsCheddar"] = 10,
            },
        },

    -- Snacks

        ["Base.Crisps"] = {
            items = {
                ["Base.Crisps"] = 10,
                ["VFX.HoneyBarbecueChips"] = 10,
            },
        },

        ["Base.Crisps2"] = {
            items = {
                ["Base.Crisps2"] = 10,
                ["VFX.CheddarChips"] = 10,
            },
        },

        ["Base.Crisps3"] = {
            items = {
                ["Base.Crisps3"] = 10,
                ["VFX.DillPickleChips"] = 10,
            },
        },

        ["Base.Crisps4"] = {
            items = {
                ["Base.Crisps4"] = 10,
                ["VFX.RanchChips"] = 10,
            },
        },

        ["Base.Crackers"] = {
            items = {
                ["Base.Crackers"] = 10,
                ["VFX.RitzCrackers"] = 10,
                ["VFX.WheatThins"] = 10,
                ["VFX.CheezItz"] = 10,
                ["VFX.Goldfish"] = 10,
            },
        },

        ["Base.Peanuts"] = {
            items = {
                ["Base.Peanuts"] = 10,
                ["VFX.MixedNuts"] = 10,
                ["VFX.Almonds"] = 10,
                ["VFX.Cashews"] = 10,
                ["VFX.Hazelnuts"] = 10,
                ["VFX.Pecans"] = 10,
                ["VFX.Pistachios"] = 10,
                ["VFX.Walnuts"] = 10,
                ["VFX.PineNuts"] = 10,
            },
        },

        ["Base.GranolaBar"] = {
            items = {
                ["Base.GranolaBar"] = 10,
                ["VFX.OatGranolaBar"] = 10,
                ["VFX.ChocolateChipGranolaBar"] = 10,
                ["VFX.NuttyGranolaBar"] = 10,
                ["VFX.AlmondGranolaBar"] = 10,
                ["VFX.AlmondGranolaBarBox"] = 5,
                ["VFX.ChocolateChipGranolaBarBox"] = 5,
                ["VFX.NuttyGranolaBarBox"] = 5,
                ["VFX.OatGranolaBarBox"] = 5,
                ["VFX.PeanutButterGranolaBarBox"] = 5,
            },
        },

        ["Base.ChocoCakes"] = {
            items = {
                ["Base.ChocoCakes"] = 10,
                ["VFX.ZebraCakesBox"] = 5,
                ["VFX.ZebraCake"] = 10,
            },
        },

        ["Base.HiHis"] = {
            items = {
                ["Base.HiHis"] = 10,
                ["VFX.SwissRollsBox"] = 5,
                ["VFX.SwissRoll"] = 10,
            },
        },

        ["Base.Plonkies"] = {
            items = {
                ["Base.Plonkies"] = 10,
                ["VFX.FudgeRoundsBox"] = 5,
                ["VFX.FudgeRound"] = 10,
            },
        },

        ["Base.QuaggaCakes"] = {
            items = {
                ["Base.QuaggaCakes"] = 10,
                ["VFX.CoffeeCakesBox"] = 5,
                ["VFX.CoffeeCake"] = 10,
                ["VFX.OatmealCremePiesBox"] = 5,
                ["VFX.OatmealCremePie"] = 10,
            },
        },

        ["Base.SnoGlobes"] = {
            items = {
                ["Base.SnoGlobes"] = 10,
                ["VFX.CosmicBrowniesBox"] = 5,
                ["VFX.CosmicBrownie"] = 10,
            },
        },

        ["Base.DriedApricots"] = {
            items = {
                ["Base.DriedApricots"] = 10,
                ["VFX.DriedAppleSlices"] = 10,
                ["VFX.DriedSultanas"] = 10,
                ["VFX.DriedDates"] = 10,
                ["VFX.DriedApricots"] = 10,
                ["VFX.DriedCranberries"] = 10,
                ["VFX.DriedMangoSlices"] = 10,
                ["VFX.DriedPrunes"] = 10,
                ["VFX.DriedPineapple"] = 10,
                ["VFX.DriedBananaChips"] = 10,
            },
        },

        ["VFX.RiceCakesLightlySalted"] = {
            items = {
                ["VFX.RiceCakesLightlySalted"] = 10,
                ["VFX.RiceCakesCheddar"] = 10,
                ["VFX.RiceCakesRanch"] = 10,
                ["VFX.RiceCakesAppleCinnamon"] = 10,
            },
        },

        ["VFX.ChocolatePuddingCup"] = {
            items = {
                ["VFX.ChocolatePuddingBox"] = 5,
                ["VFX.VanillaPuddingBox"] = 5,
                ["VFX.CustardPuddingBox"] = 5,
                ["VFX.StrawberryPuddingBox"] = 5,
                ["VFX.BananaCreamPuddingBox"] = 5,
                ["VFX.StrawberryJelloBox"] = 5,
                ["VFX.LemonLimeJelloBox"] = 5,
                ["VFX.OrangeJelloBox"] = 5,
                ["VFX.CherryJelloBox"] = 5,
                ["VFX.PineappleJelloBox"] = 5,
                ["VFX.BerryBlueJelloBox"] = 5,
                ["VFX.RaspberryJelloBox"] = 5,
                ["VFX.LimeJelloBox"] = 5,
                ["VFX.PeachJelloBox"] = 5,
                ["VFX.GrapeJelloBox"] = 5,
                ["VFX.LemonJelloBox"] = 5,
                ["VFX.PeachSyrupFruitBox"] = 5,
                ["VFX.PeachJellyFruitBox"] = 5,
                ["VFX.PearSyrupFruitBox"] = 5,
                ["VFX.PearJellyFruitBox"] = 5,
                ["VFX.FruitSaladSyrupFruitBox"] = 5,
                ["VFX.FruitSaladJellyFruitBox"] = 5,
                ["VFX.MandarinSyrupFruitBox"] = 5,
                ["VFX.MandarinJellyFruitBox"] = 5,
                ["VFX.PineappleSyrupFruitBox"] = 5,
                ["VFX.PineappleJellyFruitBox"] = 5,
                ["VFX.TropicalSyrupFruitBox"] = 5,
                ["VFX.TropicalJellyFruitBox"] = 5,
                ["VFX.ChocolatePuddingCup"] = 10,
                ["VFX.VanillaPuddingCup"] = 10,
                ["VFX.CustardPuddingCup"] = 10,
                ["VFX.StrawberryPuddingCup"] = 10,
                ["VFX.BananaCreamPuddingCup"] = 10,
                ["VFX.StrawberryJelloCup"] = 10,
                ["VFX.LemonLimeJelloCup"] = 10,
                ["VFX.OrangeJelloCup"] = 10,
                ["VFX.CherryJelloCup"] = 10,
                ["VFX.PineappleJelloCup"] = 10,
                ["VFX.BerryBlueJelloCup"] = 10,
                ["VFX.RaspberryJelloCup"] = 10,
                ["VFX.LimeJelloCup"] = 10,
                ["VFX.PeachJelloCup"] = 10,
                ["VFX.GrapeJelloCup"] = 10,
                ["VFX.LemonJelloCup"] = 10,
                ["VFX.PeachSyrupFruitCup"] = 10,
                ["VFX.PeachJellyFruitCup"] = 10,
                ["VFX.PearSyrupFruitCup"] = 10,
                ["VFX.PearJellyFruitCup"] = 10,
                ["VFX.FruitSaladSyrupFruitCup"] = 10,
                ["VFX.FruitSaladJellyFruitCup"] = 10,
                ["VFX.MandarinSyrupFruitCup"] = 10,
                ["VFX.MandarinJellyFruitCup"] = 10,
                ["VFX.PineappleSyrupFruitCup"] = 10,
                ["VFX.PineappleJellyFruitCup"] = 10,
                ["VFX.TropicalSyrupFruitCup"] = 10,
                ["VFX.TropicalJellyFruitCup"] = 10,
            },
        },

        ["VFX.ClassicTrailMix"] = {
            items = {
                ["VFX.ClassicTrailMix"] = 10,
                ["VFX.CandyCrunchTrailMix"] = 10,
                ["VFX.TropicalTrailMix"] = 10,
                ["VFX.MountainTrailMix"] = 10,
                ["VFX.EnergyTrailMix"] = 10,
                ["VFX.BreakfastTrailMix"] = 10,
            },
        },

    -- Baking
        ["Base.MuffinFruit"] = {
        items = {
            ["Base.MuffinFruit"] = 10,
            ["VFX.AppleCinnamonMuffin"] = 10,
            ["VFX.BlueberryMuffin"] = 10,
            ["VFX.LemonPoppyMuffin"] = 10,
            
            },
        },

        ["Base.MuffinGeneric"] = {
            items = {
                ["Base.MuffinGeneric"] = 10,
                ["VFX.ChocolateChipMuffin"] = 10,
                ["VFX.DoubleChocolateMuffin"] = 10,
                ["VFX.CornMuffin"] = 10,
                ["VFX.BranMuffin"] = 10,
            },
        },

        ["Base.CakeSlice"] = {
            items = {
                ["Base.CakeSlice"] = 10,
                ["VFX.FrenchVanillaCakeSlice"] = 10,
                ["VFX.CaramelCakeSlice"] = 10,
                ["VFX.OrangePoppyseedCakeSlice"] = 10,
                ["VFX.ConfettiCakeSlice"] = 10,
                ["VFX.SpiceCakeSlice"] = 10,
                ["VFX.YellowCakeSlice"] = 10,
            },
        },

        ["Base.Biscuit"] = {
            items = {
                ["Base.Biscuit"] = 10,
                ["VFX.CheddarBiscuit"] = 10,
                ["VFX.HomestyleBiscuit"] = 10,
            },
        },

        ["Base.CookiesOatmeal"] = {
            items = {
                ["Base.CookiesOatmeal"] = 10,
                ["VFX.CookiesPeanutButter"] = 10,
            },
        },

        ["Base.CookiesShortbread"] = {
            items = {
                ["Base.CookiesShortbread"] = 10,
                ["VFX.CookiesGingerbread"] = 10,
            },
        },

        ["Base.CookiesChocolate"] = {
            items = {
                ["Base.CookiesChocolate"] = 10,
                ["VFX.CookiesSnickerdoodle"] = 10,
            },
        },

        ["Base.CakeBatter"] = {
            items = {
                ["Base.CakeBatter"] = 10,
                ["VFX.FrenchVanillaCakeBatter"] = 10,
                ["VFX.CarrotCakeBatter"] = 10,
                ["VFX.ChocolateCakeBatter"] = 10,
                ["VFX.RedVelvetCakeBatter"] = 10,
                ["VFX.StrawberryCakeBatter"] = 10,
                ["VFX.CaramelCakeBatter"] = 10,
                ["VFX.OrangePoppyseedCakeBatter"] = 10,
                ["VFX.ConfettiCakeBatter"] = 10,
                ["VFX.SpiceCakeBatter"] = 10,
                ["VFX.YellowCakeBatter"] = 10,
            },
        },

        ["Base.Icing"] = {
            items = {
                ["VFX.VanillaFrostingTub"] = 10,
            },
        },

        ["VFX.BananaBreadSlice"] = {
            items = {
                ["VFX.BananaBreadSlice"] = 10,
                ["VFX.PumpkinBreadSlice"] = 10,
                ["VFX.ChocolateSwirlBreadSlice"] = 10,
                ["VFX.CinnamonSwirlBreadSlice"] = 10,
                ["VFX.CranberryBreadSlice"] = 10,
            },
        },

        ["VFX.VanillaFrostingTub"] = {
            items = {
                ["VFX.VanillaFrostingTub"] = 10,
                ["VFX.CaramelFrostingTub"] = 10,
                ["VFX.ChocolateFrostingTub"] = 10,
                ["VFX.LemonFrostingTub"] = 10,
                ["VFX.StrawberryFrostingTub"] = 10,
                ["VFX.CreamCheeseFrostingTub"] = 10,
                ["VFX.ConfettiFrostingTub"] = 10,
            },
        },

        ["VFX.FrenchVanillaCakeMix"] = {
            items = {
                ["VFX.FrenchVanillaCakeMix"] = 10,
                ["VFX.CarrotCakeMix"] = 10,
                ["VFX.ChocolateCakeMix"] = 10,
                ["VFX.RedVelvetCakeMix"] = 10,
                ["VFX.StrawberryCakeMix"] = 10,
                ["VFX.CaramelCakeMix"] = 10,
                ["VFX.OrangePoppyseedCakeMix"] = 10,
                ["VFX.ConfettiCakeMix"] = 10,
                ["VFX.SpiceCakeMix"] = 10,
                ["VFX.YellowCakeMix"] = 10,
                ["VFX.AppleCinnamonMuffinMix"] = 10,
                ["VFX.BlueberryMuffinMix"] = 10,
                ["VFX.ChocolateChipMuffinMix"] = 10,
                ["VFX.DoubleChocolateMuffinMix"] = 10,
                ["VFX.CornMuffinMix"] = 10,
                ["VFX.LemonPoppyMuffinMix"] = 10,
                ["VFX.BranMuffinMix"] = 10,
                ["VFX.BrownieMix"] = 10,
                ["VFX.ChocolateChipCookieMix"] = 10,
                ["VFX.ChocolateCookieMix"] = 10,
                ["VFX.OatmealCookieMix"] = 10,
                ["VFX.SugarCookieMix"] = 10,
                ["VFX.ShortbreadCookieMix"] = 10,
                ["VFX.PeanutButterCookieMix"] = 10,
                ["VFX.GingerbreadCookieMix"] = 10,
                ["VFX.SnickerdoodleCookieMix"] = 10,
                ["VFX.BananaBreadMix"] = 10,
                ["VFX.PumpkinBreadMix"] = 10,
                ["VFX.ChocolateSwirlBreadMix"] = 10,
                ["VFX.CinnamonSwirlBreadMix"] = 10,
                ["VFX.CranberryBreadMix"] = 10,
                ["VFX.CheddarBiscuitMix"] = 10,
                ["VFX.HomestyleBiscuitMix"] = 10,
                ["VFX.VanillaPuddingMix"] = 10,
                ["VFX.CustardPuddingMix"] = 10,
                ["VFX.BananaCreamPuddingMix"] = 10,
                ["VFX.ButterscotchPuddingMix"] = 10,
                ["VFX.PistachioPuddingMix"] = 10,
                ["VFX.ChocolateMousseMix"] = 10,
            },
        },

    -- Fruit and Vegetables
        ["Base.Apple"] = {
            items = {
                ["Base.Apple"] = 10,
                ["VFX.Apricot"] = 10,
            },
        },

        ["Base.Banana"] = {
            items = {
                ["Base.Banana"] = 10,
                ["VFX.PunnetBlackberries"] = 10,
            },
        },

        ["Base.Cherry"] = {
            items = {
                ["Base.Cherry"] = 10,
                ["VFX.PunnetBlueberries"] = 10,
            },
        },

        ["Base.Grapefruit"] = {
            items = {
                ["Base.Grapefruit"] = 10,
                ["VFX.Pomegranate"] = 10,
            },
        },

        ["Base.Grapes"] = {
            items = {
                ["Base.Grapes"] = 10,
                ["VFX.Cranberries"] = 10,
            },
        },

        ["Base.Mango"] = {
            items = {
                ["Base.Mango"] = 10,
                ["VFX.Papaya"] = 10,
            },
        },

        ["Base.Orange"] = {
            items = {
                ["Base.Orange"] = 10,
                ["VFX.Nectarines"] = 10,
                ["VFX.Tangerines"] = 10,
            },
        },

        ["Base.Peach"] = {
            items = {
                ["Base.Peach"] = 10,
                ["VFX.GreenKiwi"] = 10,
                ["VFX.GoldKiwi"] = 10,
            },
        },

        ["Base.Pear"] = {
            items = {
                ["Base.Pear"] = 10,
                ["VFX.Plum"] = 10,
            },
        },

        ["Base.Pineapple"] = {
            items = {
                ["Base.Pineapple"] = 10,
                ["VFX.Figs"] = 10,
            },
        },

        ["Base.Strewberrie"] = {
            items = {
                ["Base.Strewberrie"] = 10,
                ["VFX.PunnetRaspberries"] = 10,
            },
        },

        ["Base.Carrots"] = {
            items = {
                ["Base.Carrots"] = 10,
                ["VFX.BagGreenBeans"] = 10,
            },
        },

        ["Base.Cucumber"] = {
            items = {
                ["Base.Cucumber"] = 10,
                ["VFX.Asparagus"] = 10,
            },
        },

        ["Base.Greenpeas"] = {
            items = {
                ["Base.Greenpeas"] = 10,
                ["VFX.SnowPeas"] = 10,
            },
        },

        ["Base.RedRadish"] = {
            items = {
                ["Base.RedRadish"] = 10,
                ["VFX.Beetroot"] = 10,
            },
        },

        ["Base.Cabbage"] = {
            items = {
                ["Base.Cabbage"] = 10,
                ["VFX.RedCabbage"] = 10,
            },
        },

        ["Base.BrusselSprouts"] = {
            items = {
                ["Base.BrusselSprouts"] = 10,
                ["VFX.BokChoy"] = 10,
            },
        },

    -- Beverages
        ["Base.Wine"] = {
            items = {
                ["VFX.WineChardonnay"] = 10,
                ["VFX.WineCabernetSauvignon"] = 10,
                ["VFX.WineMerlot"] = 10,
                ["VFX.WinePinotNoir"] = 10,
                ["VFX.WineSauvignonBlanc"] = 10,
                ["VFX.WinePinotGris"] = 10,
                ["VFX.WineRiesling"] = 10,
            },
        },

        ["Base.Wine2"] = {
            items = {
                ["VFX.WineChardonnay"] = 10,
                ["VFX.WineCabernetSauvignon"] = 10,
                ["VFX.WineMerlot"] = 10,
                ["VFX.WinePinotNoir"] = 10,
                ["VFX.WineSauvignonBlanc"] = 10,
                ["VFX.WinePinotGris"] = 10,
                ["VFX.WineRiesling"] = 10,
            },
        },

        ["Base.WineAged"] = {
            items = {
                ["VFX.WineChardonnay"] = 10,
                ["VFX.WineCabernetSauvignon"] = 10,
                ["VFX.WineMerlot"] = 10,
                ["VFX.WinePinotNoir"] = 10,
                ["VFX.WineSauvignonBlanc"] = 10,
                ["VFX.WinePinotGris"] = 10,
                ["VFX.WineRiesling"] = 10,
            },
        },

        ["Base.WineWhite_Boxed"] = {
            items = {
                ["VFX.WineBoxChardonnay"] = 10,
                ["VFX.WineBoxCabernetSauvignon"] = 10,
                ["VFX.WineBoxPinotNoir"] = 10,
                ["VFX.WineBoxMerlot"] = 10,
                ["VFX.WineBoxSauvignonBlanc"] = 10,
                ["VFX.WineBoxPinotGris"] = 10,
                ["VFX.WineBoxRiesling"] = 10,
            },
        },

        ["Base.WineRed_Boxed"] = {
            items = {
                ["VFX.WineBoxChardonnay"] = 10,
                ["VFX.WineBoxCabernetSauvignon"] = 10,
                ["VFX.WineBoxPinotNoir"] = 10,
                ["VFX.WineBoxMerlot"] = 10,
                ["VFX.WineBoxSauvignonBlanc"] = 10,
                ["VFX.WineBoxPinotGris"] = 10,
                ["VFX.WineBoxRiesling"] = 10,
            },
        },

        ["Base.WineBox"] = {
            items = {
                ["VFX.WineBoxChardonnay"] = 10,
                ["VFX.WineBoxCabernetSauvignon"] = 10,
                ["VFX.WineBoxPinotNoir"] = 10,
                ["VFX.WineBoxMerlot"] = 10,
                ["VFX.WineBoxSauvignonBlanc"] = 10,
                ["VFX.WineBoxPinotGris"] = 10,
                ["VFX.WineBoxRiesling"] = 10,
            },
        },
        
        ["Base.BeerBottle"] = {
            items = {
                ["VFX.BottleAmericanLightLager"] = 10,
                ["VFX.BottleAmericanLager"] = 10,
                ["VFX.BottlePilsner"] = 10,
                ["VFX.BottleViennaLager"] = 10,
                ["VFX.BottlePaleAle"] = 10,
                ["VFX.BottleAmberAle"] = 10,
                ["VFX.BottlePorter"] = 10,
                ["VFX.BottleStout"] = 10,
                ["VFX.BottleAmericanWheatBeer"] = 10,
            },
        },

        ["Base.BeerCan"] = {
            items = {
                ["VFX.CanAmericanLightLager"] = 10,
                ["VFX.CanAmericanLager"] = 10,
                ["VFX.CanPilsner"] = 10,
                ["VFX.CanViennaLager"] = 10,
                ["VFX.CanPaleAle"] = 10,
                ["VFX.CanAmberAle"] = 10,
                ["VFX.CanPorter"] = 10,
                ["VFX.CanStout"] = 10,
                ["VFX.CanAmericanWheatBeer"] = 10,
            },
        },

        ["Base.BeerPack"] = {
            items = {
                ["VFX.PackAmericanLightLager"] = 10,
                ["VFX.PackAmericanLager"] = 10,
                ["VFX.PackPilsner"] = 10,
                ["VFX.PackViennaLager"] = 10,
                ["VFX.PackPaleAle"] = 10,
                ["VFX.PackAmberAle"] = 10,
                ["VFX.PackPorter"] = 10,
                ["VFX.PackStout"] = 10,
                ["VFX.PackAmericanWheatBeer"] = 10,
            },
        },

        ["Base.BeerCanPack"] = {
            items = {
                ["VFX.PackCanAmericanLightLager"] = 10,
                ["VFX.PackCanAmberAle"] = 10,
                ["VFX.PackCanAmericanLager"] = 10,
                ["VFX.PackCanAmericanWheatBeer"] = 10,
                ["VFX.PackCanPaleAle"] = 10,
                ["VFX.PackCanPilsner"] = 10,
                ["VFX.PackCanPorter"] = 10,
                ["VFX.PackCanStout"] = 10,
                ["VFX.PackCanViennaLager"] = 10,
            },
        },

        ["Base.PopBottle"] = {
            items = {
                ["Base.PopBottle"] = 10,
                ["VFX.CreamSodaBottle"] = 10,
                ["VFX.LemonSodaBottle"] = 10,
                ["VFX.LemonLimeSodaBottle"] = 10,
                ["VFX.OrangeSodaBottle"] = 10,
            },
        },

        ["Base.PopBottleRare"] = {
            items = {
                ["Base.PopBottleRare"] = 10,
                ["VFX.VanillaColaBottle"] = 10,
                ["VFX.CherryColaBottle"] = 10,
                ["VFX.RootBeerBottle"] = 10,
            },
        },

        ["Base.SodaCan"] = {
            items = {
                ["Base.SodaCan"] = 10,
                ["VFX.CreamSodaCan"] = 10,
                ["VFX.LemonSodaCan"] = 10,
                ["VFX.LemonLimeSodaCan"] = 10,
                ["VFX.OrangeSodaCan"] = 10,
                ["VFX.VanillaColaCan"] = 10,
                ["VFX.CherryColaCan"] = 10,
                ["VFX.RootBeerCan"] = 10,
            },
        },

        ["Base.JuiceOrange"] = {
            items = {
                ["Base.JuiceOrange"] = 10,
                ["VFX.TropicalJuice"] = 10,
                ["VFX.PineappleJuice"] = 10,
            },
        },

        ["Base.JuiceGrape"] = {
            items = {
                ["Base.JuiceGrape"] = 10,
                ["VFX.GrapefruitJuice"] = 10,
            },
        },

        ["Base.JuiceCranberry"] = {
            items = {
                ["Base.JuiceCranberry"] = 10,
                ["VFX.PruneJuice"] = 10,
            },
        },

        ["Base.JuiceBox"] = {
            items = {
                ["Base.JuiceBox"] = 10,
                ["VFX.JuiceBoxGrapefruit"] = 10,
            },
        },

        ["Base.JuiceBoxApple"] = {
            items = {
                ["Base.JuiceBoxApple"] = 10,
                ["VFX.JuiceBoxPineapple"] = 10,
            },
        },

        ["Base.JuiceBoxFruitpunch"] = {
            items = {
                ["Base.JuiceBoxFruitpunch"] = 10,
                ["VFX.JuiceBoxTropical"] = 10,
            },
        },

        ["Base.JuiceBoxOrange"] = {
            items = {
                ["Base.JuiceBoxOrange"] = 10,
                ["VFX.JuiceBoxCranberry"] = 10,
            },
        },

        ["Base.Teabag2"] = {
            items = {
                ["Base.Teabag2"] = 10,
                ["VFX.GreenTeaBag_2"] = 10,
                ["VFX.BreakfastTeaBag_2"] = 10,
                ["VFX.EarlGrayTeaBag_2"] = 10,
                ["VFX.ChamomileTeaBag_2"] = 10,
                ["VFX.PeppermintTeaBag_2"] = 10,
                ["VFX.GingerTeaBag_2"] = 10,
                ["VFX.LemonTeaBag_2"] = 10,
                ["VFX.BlackTeaBox"] = 5,
                ["VFX.GreenTeaBox"] = 5,
                ["VFX.BreakfastTeaBox"] = 5,
                ["VFX.EarlGrayTeaBox"] = 5,
                ["VFX.ChamomileTeaBox"] = 5,
                ["VFX.PeppermintTeaBox"] = 5,
                ["VFX.GingerTeaBox"] = 5,
                ["VFX.LemonTeaBox"] = 5,
            },
        },

        ["VFX.IcedTeaSweet"] = {
            items = {
                ["VFX.IcedTeaSweet"] = 10,
                ["VFX.IcedTeaLemon"] = 10,
                ["VFX.IcedTeaGreen"] = 10,
                ["VFX.IcedTeaPeach"] = 10,
                ["VFX.IcedTeaRaspberry"] = 10,
            },
        },

        ["VFX.DrinkMixLemonade"] = {
            items = {
                ["VFX.DrinkMixLemonade"] = 10,
                ["VFX.DrinkMixPinkLemonade"] = 10,
                ["VFX.DrinkMixCherry"] = 10,
                ["VFX.DrinkMixFruitPunch"] = 10,
                ["VFX.DrinkMixGrape"] = 10,
                ["VFX.DrinkMixSweetTea"] = 10,
            },
        },

        ["VFX.CoffeeCreamerOriginal_2"] = {
            items = {
                ["VFX.CoffeeCreamerOriginal_2"] = 10,
                ["VFX.CoffeeCreamerFrenchVanilla_2"] = 10,
                ["VFX.CoffeeCreamerHazelnut_2"] = 10,
                ["VFX.CoffeeCreamerIrishCream_2"] = 10,
                ["VFX.CoffeeCreamerAlmond_2"] = 10,
            },
        },

        ["VFX.ChocolateMilk"] = {
            items = {
                ["VFX.ChocolateMilk"] = 10,
                ["VFX.StrawberryMilk"] = 10,
                ["VFX.BananaMilk"] = 10,
            },
        },

        ["VFX.VanillaProteinPowder"] = {
            items = {
                ["VFX.VanillaProteinPowder"] = 10,
                ["VFX.ChocolateProteinPowder"] = 10,
                ["VFX.StrawberryProteinPowder"] = 10,
                ["VFX.BananaProteinPowder"] = 10,
            },
        },

        ["VFX.SportsBerryBlast"] = {
            items = {
                ["VFX.SportsBerryBlast"] = 10,
                ["VFX.SportsFruitPunch"] = 10,
                ["VFX.SportsGrape"] = 10,
                ["VFX.SportsLemonLime"] = 10,
                ["VFX.SportsOrange"] = 10,
                ["VFX.SportsMelon"] = 10,
                ["VFX.SportsWhiteCherry"] = 10,
            },
        },

    -- Sauce and Seasoning
        ["VFX.Distribution_ArenaKitchenSeasoning"] = {
            items = {
                ["VFX.GarlicSalt"] = 10,
                ["VFX.GroundChili"] = 10,
                ["VFX.OnionFlakes"] = 10,
                ["VFX.Paprika"] = 10,
                ["VFX.SmokedPaprika"] = 10,
                ["VFX.BarbequeRub"] = 10,
                ["VFX.CajunSeasoning"] = 10,
                ["VFX.LemonPepperSeasoning"] = 10,
                ["VFX.RanchSeasoning"] = 10,
                ["VFX.SteakhouseSeasoning"] = 10,
                ["VFX.TexMexSeasoning"] = 10,
                ["VFX.PoultrySeasoning"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_ArenaKitchenSauce"] = {
            items = {
                ["VFX.BuffaloSauce"] = 10,
                ["VFX.ChipotleSauce"] = 10,
                ["VFX.HoneyBBQSauce"] = 10,
                ["VFX.HoneyMustard"] = 10,
                ["VFX.PickleRelish"] = 10,
                ["VFX.Ranch"] = 10,
                ["VFX.SpicyBrownMustard"] = 10,
                ["VFX.SweetChiliSauce"] = 10,
                ["VFX.SweetOnionRelish"] = 10,
                ["VFX.TomatoRelish"] = 10,
                ["VFX.Aioli"] = 10,
                ["VFX.CaesarSaladDressing"] = 10,
                ["VFX.ColeslawDressing"] = 10,
                ["VFX.DijonMustard"] = 10,
                ["VFX.TartarSauce"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_BakeryKitchenBakingSeasoning"] = {
            items = {
                ["VFX.CinnamonSugar"] = 10,
                ["VFX.Cloves"] = 10,
                ["VFX.GroundGinger"] = 10,
                ["VFX.Nutmeg"] = 10,
                ["VFX.PumpkinSpiceSeasoning"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_BakeryKitchenBakingSauce"] = {
            items = {
                ["VFX.AppleSauce"] = 10,
                ["VFX.LemonJuice"] = 10,
                ["VFX.LimeJuice"] = 10,
                ["VFX.CranberrySauce"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_BreakRoomSeasoning"] = {
            items = {
                ["VFX.GarlicSalt"] = 10,
                ["VFX.OnionFlakes"] = 10,
                ["VFX.ItalianHerbsSeasoning"] = 10,
                ["VFX.LemonPepperSeasoning"] = 10,
                ["VFX.RanchSeasoning"] = 10,
                ["VFX.CinnamonSugar"] = 10,
                ["VFX.GroundChili"] = 10,
                ["VFX.Paprika"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_BreakRoomSauce"] = {
            items = {
                ["VFX.HoneyMustard"] = 10,
                ["VFX.Ranch"] = 10,
                ["VFX.SpicyBrownMustard"] = 10,
                ["VFX.TomatoRelish"] = 10,
                ["VFX.Aioli"] = 10,
                ["VFX.BuffaloSauce"] = 10,
                ["VFX.ColeslawDressing"] = 10,
                ["VFX.PickleRelish"] = 10,
                ["VFX.SweetOnionRelish"] = 10,
                ["VFX.Vinaigrette"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_BurgerKitchenSeasoning"] = {
            items = {
                ["VFX.GarlicSalt"] = 10,
                ["VFX.OnionFlakes"] = 10,
                ["VFX.Paprika"] = 10,
                ["VFX.SmokedPaprika"] = 10,
                ["VFX.BarbequeRub"] = 10,
                ["VFX.CajunSeasoning"] = 10,
                ["VFX.LemonPepperSeasoning"] = 10,
                ["VFX.RanchSeasoning"] = 10,
                ["VFX.SteakhouseSeasoning"] = 10,
                ["VFX.TexMexSeasoning"] = 10,
                ["VFX.OldBaySeasoning"] = 10,
                ["VFX.MemphisBarbequeRub"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_BurgerKitchenSauce"] = {
            items = {
                ["VFX.Aioli"] = 10,
                ["VFX.BuffaloSauce"] = 10,
                ["VFX.ChipotleSauce"] = 10,
                ["VFX.HoneyBBQSauce"] = 10,
                ["VFX.HoneyMustard"] = 10,
                ["VFX.PickleRelish"] = 10,
                ["VFX.Ranch"] = 10,
                ["VFX.SpicyBrownMustard"] = 10,
                ["VFX.SweetChiliSauce"] = 10,
                ["VFX.SweetOnionRelish"] = 10,
                ["VFX.TomatoRelish"] = 10,
                ["VFX.ColeslawDressing"] = 10,
                ["VFX.DijonMustard"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_ButcherSpicesSeasoning"] = {
            items = {
                ["VFX.GarlicSalt"] = 10,
                ["VFX.OnionFlakes"] = 10,
                ["VFX.Paprika"] = 10,
                ["VFX.SmokedPaprika"] = 10,
                ["VFX.CayennePepper"] = 10,
                ["VFX.ChiliFlakes"] = 10,
                ["VFX.GroundChili"] = 10,
                ["VFX.Allspice"] = 10,
                ["VFX.BayLeaves"] = 10,
                ["VFX.Cloves"] = 10,
                ["VFX.FennelSeeds"] = 10,
                ["VFX.BarbequeRub"] = 10,
                ["VFX.CajunSeasoning"] = 10,
                ["VFX.ItalianHerbsSeasoning"] = 10,
                ["VFX.PoultrySeasoning"] = 10,
                ["VFX.SteakhouseSeasoning"] = 10,
                ["VFX.LemonPepperSeasoning"] = 10,
                ["VFX.MemphisBarbequeRub"] = 10,
                ["VFX.OldBaySeasoning"] = 10,
                ["VFX.TexMexSeasoning"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_ButcherSpicesSauce"] = {
            items = {
                ["VFX.HoneyBBQSauce"] = 10,
                ["VFX.SpicyBrownMustard"] = 10,
                ["VFX.ChipotleSauce"] = 10,
                ["VFX.Ranch"] = 10,
                ["VFX.AppleSauce"] = 10,
                ["VFX.CranberrySauce"] = 10,
                ["VFX.TartarSauce"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_CafeKitchenSuppliesSeasoning"] = {
            items = {
                ["VFX.CinnamonSugar"] = 10,
                ["VFX.Nutmeg"] = 10,
                ["VFX.PumpkinSpiceSeasoning"] = 10,
            },
            minQty = 1,
            maxQty = 1,
        },

        ["VFX.Distribution_CafeKitchenSuppliesSauce"] = {
            items = {
                ["VFX.AppleSauce"] = 10,
                ["VFX.CranberrySauce"] = 10,
            },
            minQty = 1,
            maxQty = 1,
        },

        ["VFX.Distribution_CafeteriaSnacksSauce"] = {
            items = {
                ["VFX.HoneyMustard"] = 10,
                ["VFX.Ranch"] = 10,
                ["VFX.ColeslawDressing"] = 10,
                ["VFX.Vinaigrette"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_ChineseKitchenSeasoning"] = {
            items = {
                ["VFX.ChiliFlakes"] = 10,
                ["VFX.GarlicSalt"] = 10,
                ["VFX.GroundChili"] = 10,
                ["VFX.OnionFlakes"] = 10,
                ["VFX.ChineseFiveSpice"] = 10,
                ["VFX.CurryPowder"] = 10,
                ["VFX.CayennePepper"] = 10,
                ["VFX.Cumin"] = 10,
                ["VFX.FennelSeeds"] = 10,
                ["VFX.GroundGinger"] = 10,
                ["VFX.GaramMasala"] = 10,
                ["VFX.BayLeaves"] = 10,
                ["VFX.Cardamom"] = 10,
                ["VFX.Cloves"] = 10,
                ["VFX.Dill"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_ChineseKitchenSauce"] = {
            items = {
                ["VFX.SweetChiliSauce"] = 10,
            },
            minQty = 1,
            maxQty = 1,
        },

        ["VFX.Distribution_FishChipsKitchenSeasoning"] = {
            items = {
                ["VFX.GarlicSalt"] = 10,
                ["VFX.OnionFlakes"] = 10,
                ["VFX.Paprika"] = 10,
                ["VFX.LemonPepperSeasoning"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_FishChipsKitchenSauce"] = {
            items = {
                ["VFX.Aioli"] = 10,
                ["VFX.ColeslawDressing"] = 10,
                ["VFX.LemonJuice"] = 10,
                ["VFX.TartarSauce"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_GigamartBakingMiscSeasoning"] = {
            items = {
                ["VFX.Allspice"] = 10,
                ["VFX.CinnamonSugar"] = 10,
                ["VFX.Cloves"] = 10,
                ["VFX.GroundGinger"] = 10,
                ["VFX.Nutmeg"] = 10,
                ["VFX.PumpkinSpiceSeasoning"] = 10,
                ["VFX.Cardamom"] = 10,
                ["VFX.FennelSeeds"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_GigamartBakingMiscSauce"] = {
            items = {
                ["VFX.AppleSauce"] = 10,
                ["VFX.LemonJuice"] = 10,
                ["VFX.LimeJuice"] = 10,
                ["VFX.CranberrySauce"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_GigamartBBQSeasoning"] = {
            items = {
                ["VFX.GarlicSalt"] = 10,
                ["VFX.OnionFlakes"] = 10,
                ["VFX.Paprika"] = 10,
                ["VFX.SmokedPaprika"] = 10,
                ["VFX.BarbequeRub"] = 10,
                ["VFX.CajunSeasoning"] = 10,
                ["VFX.LemonPepperSeasoning"] = 10,
                ["VFX.MemphisBarbequeRub"] = 10,
                ["VFX.SteakhouseSeasoning"] = 10,
                ["VFX.TexMexSeasoning"] = 10,
                ["VFX.ChiliFlakes"] = 10,
                ["VFX.GroundChili"] = 10,
                ["VFX.ItalianHerbsSeasoning"] = 10,
                ["VFX.OldBaySeasoning"] = 10,
                ["VFX.PoultrySeasoning"] = 10,
                ["VFX.RanchSeasoning"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_GigamartBBQSauce"] = {
            items = {
                ["VFX.BuffaloSauce"] = 10,
                ["VFX.ChipotleSauce"] = 10,
                ["VFX.HoneyBBQSauce"] = 10,
                ["VFX.HoneyMustard"] = 10,
                ["VFX.Ranch"] = 10,
                ["VFX.SpicyBrownMustard"] = 10,
                ["VFX.SweetChiliSauce"] = 10,
                ["VFX.TomatoRelish"] = 10,
                ["VFX.Aioli"] = 10,
                ["VFX.ColeslawDressing"] = 10,
                ["VFX.PickleRelish"] = 10,
                ["VFX.SweetOnionRelish"] = 10,
                ["VFX.TartarSauce"] = 10,
                ["VFX.LemonJuice"] = 10,
                ["VFX.LimeJuice"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_ItalianKitchenSeasoning"] = {
            items = {
                ["VFX.GarlicSalt"] = 10,
                ["VFX.OnionFlakes"] = 10,
                ["VFX.Paprika"] = 10,
                ["VFX.ItalianHerbsSeasoning"] = 10,
                ["VFX.LemonPepperSeasoning"] = 10,
                ["VFX.SteakhouseSeasoning"] = 10,
                ["VFX.BayLeaves"] = 10,
                ["VFX.ChiliFlakes"] = 10,
                ["VFX.GroundChili"] = 10,
                ["VFX.Nutmeg"] = 10,
                ["VFX.SmokedPaprika"] = 10,
                ["VFX.WhitePepper"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_ItalianKitchenSauce"] = {
            items = {
                ["VFX.CaesarSaladDressing"] = 10,
                ["VFX.Vinaigrette"] = 10,
            },
            minQty = 1,
            maxQty = 1,
        },

        ["VFX.Distribution_JaysKitchenSeasoning"] = {
            items = {
                ["VFX.GarlicSalt"] = 10,
                ["VFX.OnionFlakes"] = 10,
                ["VFX.Paprika"] = 10,
                ["VFX.SmokedPaprika"] = 10,
                ["VFX.BarbequeRub"] = 10,
                ["VFX.CajunSeasoning"] = 10,
                ["VFX.LemonPepperSeasoning"] = 10,
                ["VFX.PoultrySeasoning"] = 10,
                ["VFX.RanchSeasoning"] = 10,
                ["VFX.SteakhouseSeasoning"] = 10,
                ["VFX.TexMexSeasoning"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_JaysKitchenSauce"] = {
            items = {
                ["VFX.BuffaloSauce"] = 10,
                ["VFX.ChipotleSauce"] = 10,
                ["VFX.HoneyBBQSauce"] = 10,
                ["VFX.HoneyMustard"] = 10,
                ["VFX.Ranch"] = 10,
                ["VFX.SpicyBrownMustard"] = 10,
                ["VFX.SweetChiliSauce"] = 10,
                ["VFX.TomatoRelish"] = 10,
                ["VFX.Aioli"] = 10,
                ["VFX.ColeslawDressing"] = 10,
                ["VFX.PickleRelish"] = 10,
                ["VFX.SweetOnionRelish"] = 10,
                ["VFX.TartarSauce"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_MexicanKitchenSeasoning"] = {
            items = {
                ["VFX.ChiliFlakes"] = 10,
                ["VFX.Cumin"] = 10,
                ["VFX.GarlicSalt"] = 10,
                ["VFX.GroundChili"] = 10,
                ["VFX.OnionFlakes"] = 10,
                ["VFX.Paprika"] = 10,
                ["VFX.SmokedPaprika"] = 10,
                ["VFX.CajunSeasoning"] = 10,
                ["VFX.TexMexSeasoning"] = 10,
                ["VFX.CayennePepper"] = 10,
                ["VFX.CurryPowder"] = 10,
                ["VFX.WhitePepper"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_MexicanKitchenSauce"] = {
            items = {
                ["VFX.ChipotleSauce"] = 10,
                ["VFX.LimeJuice"] = 10,
                ["VFX.PickleRelish"] = 10,
                ["VFX.SpicyBrownMustard"] = 10,
                ["VFX.SweetChiliSauce"] = 10,
                ["VFX.TomatoRelish"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_PizzaKitchenSeasoning"] = {
            items = {
                ["VFX.GarlicSalt"] = 10,
                ["VFX.OnionFlakes"] = 10,
                ["VFX.Paprika"] = 10,
                ["VFX.ItalianHerbsSeasoning"] = 10,
                ["VFX.LemonPepperSeasoning"] = 10,
                ["VFX.SteakhouseSeasoning"] = 10,
                ["VFX.BayLeaves"] = 10,
                ["VFX.ChiliFlakes"] = 10,
                ["VFX.GroundChili"] = 10,
                ["VFX.Nutmeg"] = 10,
                ["VFX.SmokedPaprika"] = 10,
                ["VFX.WhitePepper"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_PizzaKitchenSauce"] = {
            items = {
                ["VFX.CaesarSaladDressing"] = 10,
                ["VFX.Vinaigrette"] = 10,
            },
            minQty = 1,
            maxQty = 1,
        },

        ["VFX.Distribution_SeafoodKitchenSeasoning"] = {
            items = {
                ["VFX.Dill"] = 10,
                ["VFX.GarlicSalt"] = 10,
                ["VFX.OnionFlakes"] = 10,
                ["VFX.Paprika"] = 10,
                ["VFX.WhitePepper"] = 10,
                ["VFX.LemonPepperSeasoning"] = 10,
                ["VFX.OldBaySeasoning"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_SeafoodKitchenSauce"] = {
            items = {
                ["VFX.Aioli"] = 10,
                ["VFX.ColeslawDressing"] = 10,
                ["VFX.LemonJuice"] = 10,
                ["VFX.TartarSauce"] = 10,
                ["VFX.TomatoRelish"] = 10,
                ["VFX.CocktailSauce"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_WesternKitchenSeasoning"] = {
            items = {
                ["VFX.CinnamonSugar"] = 10,
                ["VFX.GarlicSalt"] = 10,
                ["VFX.OnionFlakes"] = 10,
                ["VFX.Paprika"] = 10,
                ["VFX.BarbequeRub"] = 10,
                ["VFX.PoultrySeasoning"] = 10,
                ["VFX.RanchSeasoning"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_WesternKitchenSauce"] = {
            items = {
                ["VFX.HoneyBBQSauce"] = 10,
                ["VFX.HoneyMustard"] = 10,
                ["VFX.Ranch"] = 10,
                ["VFX.TomatoRelish"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

        ["VFX.Distribution_CrepeKitchenSeasoning"] = {
            items = {
                ["VFX.CinnamonSugar"] = 10,
                ["VFX.Nutmeg"] = 10,
                ["VFX.PumpkinSpiceSeasoning"] = 10,
            },
            minQty = 1,
            maxQty = 1,
        },

        ["VFX.Distribution_CrepeKitchenSauce"] = {
            items = {
                ["VFX.AppleSauce"] = 10,
                ["VFX.CranberrySauce"] = 10,
            },
            minQty = 1,
            maxQty = 1,
        },

        ["VFX.Distribution_FoodGourmetSeasoning"] = {
            items = {
                ["VFX.Cardamom"] = 10,
                ["VFX.Cloves"] = 10,
                ["VFX.Cumin"] = 10,
                ["VFX.FennelSeeds"] = 10,
                ["VFX.Nutmeg"] = 10,
                ["VFX.WhitePepper"] = 10,
                ["VFX.Allspice"] = 10,
                ["VFX.BayLeaves"] = 10,
                ["VFX.CayennePepper"] = 10,
                ["VFX.CurryPowder"] = 10,
                ["VFX.Dill"] = 10,
                ["VFX.GroundGinger"] = 10,
                ["VFX.SmokedPaprika"] = 10,
                ["VFX.ChiliFlakes"] = 10,
                ["VFX.GarlicSalt"] = 10,
                ["VFX.GroundChili"] = 10,
                ["VFX.OnionFlakes"] = 10,
                ["VFX.Paprika"] = 10,
                ["VFX.ChineseFiveSpice"] = 10,
                ["VFX.GaramMasala"] = 10,
                ["VFX.ItalianHerbsSeasoning"] = 10,
                ["VFX.PumpkinSpiceSeasoning"] = 10,
            },
            minQty = 1,
            maxQty = 3,
        },

    -- Recipe Books
        ["VFX.NonnasKitchenChronicles"] = {
            items = {
                ["VFX.NonnasKitchenChronicles"] = 10,
                ["VFX.CurryMastersManual"] = 10,
                ["VFX.JollyPubsRecipes"] = 10,
            },
            minQty = 1,
            maxQty = 1,
        },

    -- Fluid Containers
        ["VFX.PlasticPitcher"] = {
            items = {
                ["VFX.PlasticPitcher"] = 10,
                ["VFX.ProteinShaker"] = 10,
                ["VFX.MilkshakeGlass"] = 10,
            },
            minQty = 1,
            maxQty = 1,
        },

    -- Candy
        ["Base.Gum"] = {
            items = {
                ["Base.Gum"] = 10,
                ["VFX.GumPeppermint"] = 10,
                ["VFX.GumSpearmint"] = 10,
                ["VFX.GumPinkBubblegum"] = 10,
                ["VFX.GumGreenApple"] = 10,
                ["VFX.GumWatermelon"] = 10,
                ["VFX.GumTuttiFruity"] = 10,
                ["VFX.GumCinnamon"] = 10,
                ["VFX.BubblegumTapePink"] = 10,
                ["VFX.BubblegumTapeGrape"] = 10,
                ["VFX.BubblegumTapeStrawberry"] = 10,
                ["VFX.BubblegumTapeSourBlueRaspberry"] = 10,
                ["VFX.BubblegumTapeSourApple"] = 10,
                ["VFX.BubblegumTapeTangyTropical"] = 10,
                ["VFX.GumBallStrawberry"] = 10,
                ["VFX.GumBallPineapple"] = 10,
                ["VFX.GumBallBlueberry"] = 10,
                ["VFX.GumBallLemonLime"] = 10,
                ["VFX.GumBallOrange"] = 10,
                ["VFX.GumBallCherry"] = 10,
                ["VFX.GumBallBanana"] = 10,
                ["VFX.GumBallGrape"] = 10,
                ["VFX.JawBreaker"] = 10,
            },
        },

        ["Base.Chocolate_Butterchunkers"] = {
            items = {
                ["Base.Chocolate_Butterchunkers"] = 10,
                ["VFX.ChocolateBarDark"] = 10,
            },
        },

        ["Base.Chocolate_Crackle"] = {
            items = {
                ["Base.Chocolate_Crackle"] = 10,
                ["VFX.ChocolateBarWhite"] = 10,
            },
        },

        ["Base.Chocolate_Deux"] = {
            items = {
                ["Base.Chocolate_Deux"] = 10,
                ["VFX.ChocolateBarAlmond"] = 10,
            },
        },

        ["Base.Chocolate_GalacticDairy"] = {
            items = {
                ["Base.Chocolate_GalacticDairy"] = 10,
                ["VFX.ChocolateBarCookiesAndCream"] = 10,
            },
        },

        ["Base.Chocolate_RoysPBPucks"] = {
            items = {
                ["Base.Chocolate_RoysPBPucks"] = 10,
                ["VFX.ChocolateBarPorkie"] = 10,
            },
        },

        ["Base.Chocolate"] = {
            items = {
                ["Base.Chocolate"] = 10,
                ["VFX.ChocolateKisses"] = 10,
                ["VFX.ChocolateAlmonds"] = 10,
                ["VFX.ChocolateSeniorMints"] = 10,
                ["VFX.ChocolateCaramelDuds"] = 10,
                ["VFX.ChocolateMaltBalls"] = 10,
                ["VFX.ChocolateCandyPeanut"] = 10,
            },
        },

        ["Base.Lollipop"] = {
            items = {
                ["Base.Lollipop"] = 10,
                ["VFX.LollipopCherry"] = 10,
                ["VFX.LollipopGrape"] = 10,
                ["VFX.LollipopStrawberry"] = 10,
                ["VFX.LollipopOrange"] = 10,
                ["VFX.LollipopLemon"] = 10,
                ["VFX.LollipopLime"] = 10,
                ["VFX.LollipopGreenApple"] = 10,
                ["VFX.LollipopBlueRaspberry"] = 10,
                ["VFX.LollipopWatermelon"] = 10,
                ["VFX.LollipopWildBerry"] = 10,
                ["VFX.LollipopCola"] = 10,
                ["VFX.LollipopCreamSoda"] = 10,
                ["VFX.LollipopButterscotch"] = 10,
                ["VFX.GiantLollipopCherry"] = 10,
                ["VFX.GiantLollipopGrape"] = 10,
                ["VFX.GiantLollipopStrawberry"] = 10,
                ["VFX.GiantLollipopOrange"] = 10,
                ["VFX.GiantLollipopLemon"] = 10,
                ["VFX.GiantLollipopLime"] = 10,
                ["VFX.GiantLollipopGreenApple"] = 10,
                ["VFX.GiantLollipopBlueRaspberry"] = 10,
                ["VFX.GiantLollipopWatermelon"] = 10,
                ["VFX.GiantLollipopWildBerry"] = 10,
                ["VFX.GiantLollipopCola"] = 10,
                ["VFX.GiantLollipopCreamSoda"] = 10,
                ["VFX.GiantLollipopButterscotch"] = 10,
                ["VFX.RainbowLollipop"] = 10,
            },
        },

        ["Base.CandyNovapops"] = {
            items = {
                ["Base.CandyNovapops"] = 10,
                ["VFX.RingPopTropical"] = 10,
                ["VFX.RingPopCitrus"] = 10,
                ["VFX.RingPopGrape"] = 10,
                ["VFX.RingPopBerry"] = 10,
                ["VFX.RingPopBlueRaspberry"] = 10,
                ["VFX.RingPopFruitPunch"] = 10,
                ["VFX.RingPopSourCherry"] = 10,
                ["VFX.RingPopWatermelon"] = 10,
            },
        },

        ["Base.CandyFruitSlices"] = {
            items = {
                ["Base.CandyFruitSlices"] = 10,
                ["VFX.PushPopStrawberry"] = 10,
                ["VFX.PushPopWatermelon"] = 10,
                ["VFX.PushPopCola"] = 10,
                ["VFX.PushPopFruitFrenzy"] = 10,
                ["VFX.PushPopRainbowSherbet"] = 10,
                ["VFX.PushPopGrape"] = 10,
                ["VFX.PushPopCherry"] = 10,
            },
        },

        ["Base.HardCandies"] = {
            items = {
                ["Base.HardCandies"] = 10,
                ["VFX.FunDipCherry"] = 10,
                ["VFX.FunDipApple"] = 10,
                ["VFX.FunDipGrape"] = 10,
                ["VFX.FunDipStrawberry"] = 10,
                ["VFX.FunDipWatermelon"] = 10,
                ["VFX.FunDipOrange"] = 10,
            },
        },

        ["Base.Jujubes"] = {
            items = {
                ["Base.Jujubes"] = 10,
                ["VFX.FruitChewLemon"] = 10,
                ["VFX.FruitChewCherry"] = 10,
                ["VFX.FruitChewGrape"] = 10,
                ["VFX.FruitChewOrange"] = 10,
                ["VFX.FruitChewWatermelon"] = 10,
                ["VFX.FruitChewStrawberry"] = 10,
            },
        },

        ["Base.CandyGummyfish"] = {
            items = {
                ["Base.CandyGummyfish"] = 10,
                ["VFX.GummyPeachRings"] = 10,
                ["VFX.GummyCola"] = 10,
                ["VFX.BagGummyFish"] = 10,
                ["VFX.BagPeachRings"] = 10,
                ["VFX.BagColaGummies"] = 10,
            },
        },

        ["Base.GummyBears"] = {
            items = {
                ["Base.GummyBears"] = 10,
                ["VFX.GummySourBears"] = 10,
                ["VFX.BagGummyBears"] = 10,
                ["VFX.BagSourGummyBears"] = 10,
            },
        },

        ["Base.GummyWorms"] = {
            items = {
                ["Base.GummyWorms"] = 10,
                ["VFX.GummySourWorms"] = 10,
                ["VFX.BagGummyWorms"] = 10,
                ["VFX.BagSourGummyWorms"] = 10,
            },
        },

        ["Base.JellyBeans"] = {
            items = {
                ["Base.JellyBeans"] = 10,
                ["VFX.FunnyTaffyBlueRaspberry"] = 10,
                ["VFX.FunnyTaffyOrange"] = 10,
                ["VFX.FunnyTaffyBanana"] = 10,
                ["VFX.FunnyTaffyCherry"] = 10,
                ["VFX.FunnyTaffyStrawberry"] = 10,
                ["VFX.FunnyTaffyGrape"] = 10,
                ["VFX.FunnyTaffyWatermelon"] = 10,
                ["VFX.FunnyTaffyFruitPunch"] = 10,
            },
        },

        ["Base.MintCandy"] = {
            items = {
                ["Base.MintCandy"] = 10,
                ["VFX.Geeks"] = 10,
                ["VFX.CandyNecklace"] = 10,
                ["VFX.Rushers"] = 10,
                ["VFX.BottleTops"] = 10,
            },
        },

        ["Base.Allsorts"] = {
            items = {
                ["Base.Allsorts"] = 10,
                ["VFX.ToffeeBites"] = 10,
                ["VFX.SaltwaterTaffy"] = 10,
                ["VFX.SourStraws"] = 10,
                ["VFX.SourStraps"] = 10,
            },
        },

        ["Base.CandyCaramels"] = {
            items = {
                ["Base.CandyCaramels"] = 10,
                ["VFX.FairySticks"] = 10,
                ["VFX.CandyCigarettes"] = 10,
                ["VFX.Fudge"] = 10,
                ["VFX.Cheeps"] = 10,
            },
        },

        ["Base.Chocolate_Candy"] = {
            items = {
                ["Base.Chocolate_Candy"] = 10,
                ["VFX.ChocolateCoins"] = 10,
                ["VFX.ChocolatePretzels"] = 10,
            },
        },

        ["Base.CandiedApple"] = {
            items = {
                ["Base.CandiedApple"] = 10,
                ["VFX.RedCandiedApple"] = 10,
            },
        },
    
    -- Pie Slices
        ["Base.PieApple"] = {
            items = {
                ["VFX.SlicePieApple"] = 10,
                ["VFX.SlicePieCherry"] = 10,
                ["VFX.SlicePieStrawberry"] = 10,
            },
        },

        ["Base.PieBlueberry"] = {
            items = {
                ["VFX.SlicePieBlueberry"] = 10,
                ["VFX.SlicePiePeach"] = 10,
                ["VFX.SlicePieMixedBerry"] = 10,
            },
        },

        ["Base.PieKeyLime"] = {
            items = {
                ["Base.PieKeyLime"] = 10,
                ["VFX.SlicePieLemonCream"] = 10,
            },
        },

        ["Base.PieLemonMeringue"] = {
            items = {
                ["Base.PieLemonMeringue"] = 10,
                ["VFX.SlicePieBlackberry"] = 10,
                ["VFX.SlicePieRaspberry"] = 10,
            },
        },

        ["Base.PiePumpkin"] = {
            items = {
                ["VFX.SlicePiePumpkin"] = 10,
                ["VFX.SlicePieSweetPotato"] = 10,
                ["VFX.SlicePiePecan"] = 10,
            },
        },

    -- Spice Rack
        ["VFX.SpiceRackSmallLight"] = {
            items = {
                ["VFX.SpiceRackSmallLight"] = 10,
                ["VFX.SpiceRackSmallDark"] = 10,
                ["VFX.SpiceRackLargeLight"] = 10,
                ["VFX.SpiceRackLargeDark"] = 10,
            },
        },

}

local function getRandomItemFromDistribution(distributionData)
    local totalWeight = 0
    for _, weight in pairs(distributionData.items) do
        totalWeight = totalWeight + weight
    end

    local pick = ZombRand(totalWeight) + 1
    local cumulative = 0
    for itemType, weight in pairs(distributionData.items) do
        cumulative = cumulative + weight
        if pick <= cumulative then
            return itemType
        end
    end
end

local function replaceDistributionItems(itemContainer)
    if not instanceof(itemContainer, "ItemContainer") then
        return
    end

    local items = itemContainer:getItems()
    for i = items:size() - 1, 0, -1 do
        local item = items:get(i)
        local fullType = item:getFullType()
        
        local distributionData = SET_DISTRIBUTIONS[fullType]
        if distributionData then
            itemContainer:Remove(item)
            
            if distributionData.minQty and distributionData.maxQty then
                local quantity = ZombRand(distributionData.maxQty - distributionData.minQty + 1) + distributionData.minQty
                
                for j = 1, quantity do
                    local replacementType = getRandomItemFromDistribution(distributionData)
                    if replacementType then
                        local vfxItem = itemContainer:AddItem(replacementType)
                        if vfxItem and instanceof(vfxItem, "Food") then
                            vfxItem:setAutoAge()
                        end
                    end
                end
            else
                local replacementType = getRandomItemFromDistribution(distributionData)
                if replacementType then
                    local vfxItem = itemContainer:AddItem(replacementType)
                    if vfxItem and instanceof(vfxItem, "Food") then
                        vfxItem:setAutoAge()
                    end
                end
            end
        end
    end
end

local function onFillContainerHandler(roomName, containerType, itemContainer)
    if not instanceof(itemContainer, "ItemContainer") then
        return
    end

    replaceDistributionItems(itemContainer)
end

local function onFillContainerHandlerSafe(roomName, containerType, itemContainer)
    if FadedFeastcraft and FadedFeastcraft.DistributionSafety then
        FadedFeastcraft.DistributionSafety.run("VFX.onFillContainer", function()
            onFillContainerHandler(roomName, containerType, itemContainer)
        end)
        return
    end
    onFillContainerHandler(roomName, containerType, itemContainer)
end

Events.OnFillContainer.Add(onFillContainerHandlerSafe)
