----------------------------------------------------------
-- 🎁 BOÎTES MYSTÈRES — version universelle
----------------------------------------------------------

SnackTimeMystery = SnackTimeMystery or {}

----------------------------------------------------------
-- 🎁 LOOT POOL NORMAL (ST_BoiteMystere)
----------------------------------------------------------
SnackTimeMystery.lootPool = {
    "SnackTime89.ST_Bounty",
    "SnackTime89.ST_Bretzels",
    "SnackTime89.ST_CapriSun",
    "SnackTime89.ST_CheetosCrunchy",
    "SnackTime89.ST_CheetosFlamingHot",
    "SnackTime89.ST_ChupaChups",
    "SnackTime89.ST_CocaCola",
    "SnackTime89.ST_Crunch",
    "SnackTime89.ST_CurlyCheese",
    "SnackTime89.ST_CurlyOriginal",
    "SnackTime89.ST_DoritosNachoCheese",
    "SnackTime89.ST_DoritosSpicy",
    "SnackTime89.ST_Fanta",
    "SnackTime89.ST_HariboMix",
    "SnackTime89.ST_KelloggsCornFlakes",
    "SnackTime89.ST_KelloggsFrostedFlakes",
    "SnackTime89.ST_KelloggsFrostiesBar",
    "SnackTime89.ST_KelloggsHoneyLoops",
    "SnackTime89.ST_KelloggsHoneyPops",
    "SnackTime89.ST_KelloggsHoneySmacks",
    "SnackTime89.ST_KelloggsRiceKrispies",
    "SnackTime89.ST_KelloggsSpecialK",
    "SnackTime89.ST_KinderBueno",
    "SnackTime89.ST_KinderCountry",
    "SnackTime89.ST_KinderDelice",
    "SnackTime89.ST_KitKat",
    "SnackTime89.ST_LUPetitEcolier",
    "SnackTime89.ST_LaysBBQ",
    "SnackTime89.ST_LaysCreamOnion",
    "SnackTime89.ST_LaysNature",
    "SnackTime89.ST_LaysPaprika",
    "SnackTime89.ST_Lion",
    "SnackTime89.ST_LiptonIceTea",
    "SnackTime89.ST_MMs",
    "SnackTime89.ST_Maltesers",
    "SnackTime89.ST_Mars",
    "SnackTime89.ST_Mikado",
    "SnackTime89.ST_MinuteMaid",
    "SnackTime89.ST_Nestea",
    "SnackTime89.ST_NestleChocapic",
    "SnackTime89.ST_NestleChocapicBar",
    "SnackTime89.ST_NestleNesquikCereal",
    "SnackTime89.ST_Nuts",
    "SnackTime89.ST_OasisTropical",
    "SnackTime89.ST_Oreo",
    "SnackTime89.ST_Pepsi",
    "SnackTime89.ST_PringlesHotSpicy",
    "SnackTime89.ST_PringlesOriginal",
    "SnackTime89.ST_SevenUp",
    "SnackTime89.ST_Skittles",
    "SnackTime89.ST_Snickers",
    "SnackTime89.ST_Sprite",
    "SnackTime89.ST_Toblerone",
    "SnackTime89.ST_TucBacon",
    "SnackTime89.ST_TucNature",
    "SnackTime89.ST_Twix",
    "SnackTime89.ST_RedBull",
    "SnackTime89.ST_MarsGlace",
    "SnackTime89.ST_SnickersGlace",
    "SnackTime89.ST_TwixGlace",
    "SnackTime89.ST_BountyGlace",
    "SnackTime89.ST_BenenutsCG",
    "SnackTime89.ST_BenenutsNC",
    "SnackTime89.ST_HariboOurs",
    "SnackTime89.ST_HariboTagada",
    "SnackTime89.ST_HariboDragibus",
    "SnackTime89.ST_HariboCroco",
    "SnackTime89.ST_HariboSchtroumpfs",
    "SnackTime89.ST_YopVanille",
    "SnackTime89.ST_YopFraise",
    "SnackTime89.ST_YopBanane",
    "SnackTime89.ST_Orangina",
    "SnackTime89.ST_OranginaR",
    "SnackTime89.ST_Chipster",
    "SnackTime89.ST_MagnumC",
    "SnackTime89.ST_MagnumA",
    "SnackTime89.ST_BalistoMA",
    "SnackTime89.ST_BalistoNR",
    "SnackTime89.ST_BalistoFR",
    "SnackTime89.ST_HariboCola",
    "SnackTime89.ST_CocaColaL",
    "SnackTime89.ST_FantaCitron",
    "SnackTime89.ST_KelloggsChocoKrisp",
    "SnackTime89.ST_Smarties",
    "SnackTime89.ST_KitKatChunky",
    "SnackTime89.ST_BNChocolat",
    "SnackTime89.ST_BNFraise",
    "SnackTime89.ST_KolaRoman",
    "SnackTime89.ST_DunkaroosV",
    "SnackTime89.ST_DunkaroosC",
    "SnackTime89.ST_MentosFruit",
    "SnackTime89.ST_MentosMint",
    "SnackTime89.ST_ST_ChipsahoyO",
    "SnackTime89.ST_ST_ChipsahoyC",
    "Base.Baguette",
    "Base.Waffles",
    "Base.BagelPlain",
    "Base.BreadDough",
    "Base.Burger",
    "Base.Burrito",
    "Base.Hotdog",
    "Base.ConeIcecreamToppings",
    "Base.Pancakes",
    "Base.Pizza",
    "Base.BagelPoppy",
    "Base.Salad",
    "Base.BaguetteSandwich",
    "Base.Sandwich",
    "Base.Tacos",
    "Base.WafflesRecipe",
    "Base.Biscuit",
    "Base.CakeSlice",
    "Base.Pie",
    "Base.CookieChocolateChip",
    "Base.HalloweenPumpkin",
    "Base.Maki",
    "Base.MuffinGeneric",
    "Base.CookiesOatmeal",
    "Base.Onigiri",
    "Base.PieDough",
    "Base.CookiesSugar",
    "Base.Baloney",
    "Base.BeefJerky",
    "Base.ChickenNuggets",
    "Base.ChickenWings",
    "Base.HamSlice",
    "Base.Hotdog_single",
    "Base.Salami",
    "Base.SalamiSlice",
    "Base.EggCarton",
    "Base.Chocolate_Butterchunkers",
    "Base.CandiedApple",
    "Base.Chocolate_GalacticDairy",
    "Base.Chocolate_RoysPBPucks",
    "Base.Chocolate_Smirkers",
    "Base.Allsorts",
    "Base.PieApple",
    "Base.Frozen_ChickenNuggets",
    "Base.Frozen_FrenchFries",
    "Base.CakeBlackForest",
    "Base.PieBlueberry",
    "Base.NoodleSoup",
    "Base.RamenBowl",
    "Base.Chocolate_HeartBox",
    "Base.Cheese",
    "Base.ChocoCakes",
    "Base.Painauchocolat",
    "Base.CakeChocolate",
    "Base.DoughnutChocolate",
    "Base.MilkChocolate_Personalsized",
    "Base.Croissant",
    "Base.Cupcake",
    "Base.Fries",
    "Base.ChickenFried",
    "Base.DoughnutFrosted",
    "Base.MuffinFruit",
    "Base.ConeIcecreamMelted",
    "Base.IcecreamSandwich",
    "Base.Popcorn",
    "Base.PieKeyLime",
    "Base.LemonBar",
    "Base.PieLemonMeringue",
    "Base.Macandcheese",
    "Base.MeatSteamBun",
    "Base.Plonkies",
    "Base.Popsicle",
    "Base.PotatoPancakes",
    "Base.PiePumpkin",
    "Base.QuaggaCakes",
    "Base.CookieJelly",
    "Base.CakeRedVelvet",
    "Base.Smore",
    "Base.SnoGlobes",
    "Base.Springroll",
    "Base.CakeStrawberryShortcake",
    "Base.TVDinner",
    "Base.Yoghurt"
}

----------------------------------------------------------
-- 🎁 LOOT POOL MENU (ST_BoiteMystereM)
-- ➤ Chaque entrée = un MENU COMPLET
----------------------------------------------------------
SnackTimeMystery.lootPoolM = {

    -- MENU 1 : Kebab Demi Lune + Coca + Frites + Cookie Chocolate Chip
    {
        "SnackTime89.ST_Kebab",
        "SnackTime89.ST_CocaCola",
        "Base.Fries",
        "Base.CookieChocolateChip"
    },

    -- MENU 2 : Kebab Galette + Coca + Frites + Cookie Chocolate Chip
    {
        "SnackTime89.ST_KebabGal",
        "SnackTime89.ST_Fanta",
        "Base.Fries",
        "Base.DoughnutChocolate"
    },

    -- MENU 3 : Bucket Mix + Pepsi + Corn + Cookie Chocolate Chip
    {
        "SnackTime89.ST_KFCBucketMix",
        "SnackTime89.ST_Pepsi",
        "Base.Corn",
        "Base.CookieChocolateChip"
    },

    -- MENU 4 : Burger + Pepsi + Frites + Cookie Chocolate Chip
    {
        "Base.Burger",
        "SnackTime89.ST_Pepsi",
        "Base.Fries",
        "Base.CookieChocolateChip"
    },

    -- MENU 5 : Tacos + 7Up + Chipster + Cup cake
    {
        "Base.Taco",
        "SnackTime89.ST_SevenUp",
        "SnackTime89.ST_Chipster",
        "Base.Cupcake"
    },

    -- MENU 6 : Hotdog + Orangina + Bretzels + Donut Chocolate
    {
        "Base.Hotdog",
        "SnackTime89.ST_Orangina",
        "SnackTime89.ST_Bretzels",
        "Base.DoughnutChocolate"
    },

    -- MENU 7 : BigMac + Coca Ligt + Frites + Donut Chocolate
    {
        "SnackTime89.ST_BigMac",
        "Base.Fries",
        "SnackTime89.ST_CocaColaL",
        "Base.Cupcake"
    },

    -- MENU 8 : Whopper + Fanta citron + Frites + Brownie
    {
        "SnackTime89.ST_Whopper",
        "Base.Fries",
        "SnackTime89.ST_FantaCitron",
        "Base.DoughnutFrosted"
    },

    -- MENU 9 : Pizza + Sprite + Pringles Original + Brownie
    {
        "Base.Pizza",
        "SnackTime89.ST_Sprite",
        "SnackTime89.ST_PringlesOriginal",
        "Base.DoughnutFrosted"
    }
}
