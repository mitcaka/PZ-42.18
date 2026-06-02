-- FHC_Constants.lua
-- Central constants, version and identifier strings. Loaded everywhere.

FHC = FHC or {}
FHC.VERSION = "1.0.0"
FHC.MOD_ID = "FadedHuntersCalling"
FHC.MODULE = "FHC"               -- network module string for sendClientCommand/OnClientCommand
FHC.LOG_PREFIX = "[FHC] "

-- ModData keys (player + world). Keep this list canonical; do not invent ad-hoc keys.
FHC.MD = {
    -- per-player toggles (saved on player modData under FHC.MD.PlayerToggles)
    PlayerToggles            = "FHC_PlayerToggles",
    PlayerJournal            = "FHC_Journal",
    PlayerLastOpenTab        = "FHC_LastTab",
    PlayerActiveScent        = "FHC_ActiveAnimalScent",
    PlayerActiveAnimalCall   = "FHC_ActiveAnimalCall",
    PlayerAnimalCallCooldown = "FHC_AnimalCallCooldown",

    -- per-item / per-object
    ItemDryingState          = "FHC_DryingState",
    ItemDryingStartedAt      = "FHC_DryingStartedAt",
    ItemDryingFinishedAt     = "FHC_DryingFinishedAt",
    ItemHideCureState        = "FHC_HideCureState",
    ItemSourceWeight         = "FHC_SourceWeight",

    -- world / shared
    GlobalKnownAnimals       = "FHC_KnownAnimals",
}

-- Per-player toggle keys (these are what GUI checkboxes flip).
-- Every networked/perf feature MUST have a key here and a default in DefaultToggles().
FHC.TOGGLE = {
    AnimalOutline    = "animalOutline",
    OutlineAlwaysOn  = "outlineAlwaysOn",
    NearbyPanel      = "nearbyPanel",
    MapMarkers       = "mapMarkers",
    TrapBoard        = "trapBoard",
    ShowKnownAnimals = "knownAnimals",
    ShowJournalTips  = "journalTips",
    DryingNotifs     = "dryingNotifs",
}

-- Default per-player toggle values. Everything that pings the server is FALSE by default.
function FHC.DefaultToggles()
    return {
        [FHC.TOGGLE.AnimalOutline]    = false,
        [FHC.TOGGLE.OutlineAlwaysOn]  = false,
        [FHC.TOGGLE.NearbyPanel]      = false,
        [FHC.TOGGLE.MapMarkers]       = false,
        [FHC.TOGGLE.TrapBoard]        = true,    -- display toggle; MP trap rows are server-authored
        [FHC.TOGGLE.ShowKnownAnimals] = true,    -- client-only journal UI
        [FHC.TOGGLE.ShowJournalTips]  = true,    -- client-only journal UI
        [FHC.TOGGLE.DryingNotifs]     = true,    -- local HaloNote only
    }
end

-- Network command names. Server validates everything.
FHC.CMD = {
    LogKill            = "logKill",
    LogHide            = "logHide",
    LogTrapSprung      = "logTrapSprung",
    FieldDressComplete = "fieldDressComplete",
    DryingComplete     = "dryingComplete",
    HideCureComplete   = "hideCureComplete",
    HubCraftComplete   = "hubCraftComplete",
    ApplyScentComplete = "applyScentComplete",
    ApplyScentResult   = "applyScentResult",
    AnimalCallComplete = "animalCallComplete",
    AnimalCallResult   = "animalCallResult",
    TrackingScanRequest = "trackingScanRequest",
    TrackingScanResult  = "trackingScanResult",
    TrapBoardRequest    = "trapBoardRequest",
    TrapBoardResult     = "trapBoardResult",
    AdminPopReport     = "adminPopReport",
    AdminPopCull       = "adminPopCull",
}

-- Colours used by the GUI skin. Keep here so themes are easy to swap.
FHC.COLOR = {
    Leather       = { r = 0.32, g = 0.21, b = 0.12, a = 1.0 },
    LeatherDark   = { r = 0.18, g = 0.11, b = 0.06, a = 1.0 },
    LeatherLight  = { r = 0.46, g = 0.30, b = 0.16, a = 1.0 },
    Amber         = { r = 0.92, g = 0.65, b = 0.18, a = 1.0 },
    AmberDim      = { r = 0.55, g = 0.38, b = 0.10, a = 1.0 },
    Parchment     = { r = 0.86, g = 0.78, b = 0.62, a = 1.0 },
    ParchmentDark = { r = 0.60, g = 0.54, b = 0.42, a = 1.0 },
    Brass         = { r = 0.78, g = 0.62, b = 0.30, a = 1.0 },
    Ink           = { r = 0.10, g = 0.07, b = 0.04, a = 1.0 },
    OutlineYellow = { r = 1.0,  g = 1.0,  b = 0.0,  a = 1.0 },  -- per user request
    GoodGreen     = { r = 0.45, g = 0.80, b = 0.35, a = 1.0 },
    WarnRed       = { r = 0.85, g = 0.30, b = 0.20, a = 1.0 },
}

-- Animal type table (one row per vanilla 42.18 animal). Used by Journal, Map, Outline.
FHC.ANIMALS = {
    cow      = { display = "Cow",       category = "livestock", aliases = { "cow", "bull", "cowcalf" } },
    pig      = { display = "Pig",       category = "livestock", aliases = { "pig", "sow", "boar", "piglet" } },
    sheep    = { display = "Sheep",     category = "livestock", aliases = { "sheep", "ram", "ewe", "lamb" } },
    chicken  = { display = "Chicken",   category = "livestock", aliases = { "chicken", "hen", "rooster", "cockerel", "chick" } },
    turkey   = { display = "Turkey",    category = "livestock", aliases = { "turkey", "gobbler", "gobblers", "turkeyhen", "turkeypoult" } },
    rabbit   = { display = "Rabbit",    category = "small_game", aliases = { "rabbit", "rabdoe", "rabbuck", "rabkitten" } },
    deer     = { display = "Deer",      category = "big_game",   aliases = { "deer", "doe", "buck", "fawn" } },
    raccoon  = { display = "Raccoon",   category = "small_game", aliases = { "raccoon", "racoon", "raccoonsow", "raccoonboar", "raccoonkit" } },
    rat      = { display = "Rat",       category = "vermin",     aliases = { "rat", "ratfemale", "ratbaby" } },
    mouse    = { display = "Mouse",     category = "vermin",     aliases = { "mouse", "mousefemale", "mousepups" } },
    squirrel = { display = "Squirrel",  category = "small_game", aliases = { "squirrel" } },
}

-- Map alias -> canonical animal key for quick lookups.
FHC.ANIMAL_BY_ALIAS = {}
for canonical, row in pairs(FHC.ANIMALS) do
    for _, a in ipairs(row.aliases) do
        FHC.ANIMAL_BY_ALIAS[string.lower(a)] = canonical
    end
end

-- B42.18 vanilla raw meat item IDs used by field dressing and drying.
FHC.RAW_MEAT_TYPES = {
    "Base.Beef",
    "Base.Steak",
    "Base.Pork",
    "Base.PorkChop",
    "Base.MuttonChop",
    "Base.Rabbitmeat",
    "Base.Venison",
    "Base.Smallanimalmeat",
    "Base.ChickenWhole",
    "Base.TurkeyWhole",
    "Base.FrogMeat",
    "Base.MincedMeat",
}

FHC.RAW_MEAT_SET = {}
for _, fullType in ipairs(FHC.RAW_MEAT_TYPES) do
    FHC.RAW_MEAT_SET[fullType] = true
end

FHC.HUB_CRAFT_ORDER = {
    "FHC_CraftHuntingKnife",
    "FHC_CraftSkinningKnife",
    "FHC_CraftCampHatchet",
    "FHC_CraftBushcraftSpear",
    "FHC_CraftTrappersClub",
    "FHC_CraftDryingRack",
    "FHC_CraftHideRack",
    "FHC_SaltHide",
    "FHC_CureHide",
    "FHC_DryMeatStrip",
    "FHC_HarvestSinewFromCarcass",
}

FHC.HUB_CRAFTS = {
    FHC_CraftHuntingKnife = {
        time = 200,
        feature = "Enable_Bushcraft",
        output = "Base.FHC_HuntingKnife",
        skill = { perk = "MetalWelding", level = 2 },
        xp = { perk = "MetalWelding", amount = 3 },
        inputs = {
            { count = 1, types = { "Base.SmallSheetMetal" } },
            { count = 1, types = { "Base.ScrapMetal" } },
            { count = 1, types = { "Base.BlowTorch" }, keep = true, degrade = true },
            { count = 1, tags = { "base:hammer", "Hammer" }, keep = true, degrade = true },
        },
    },
    FHC_CraftSkinningKnife = {
        time = 220,
        feature = "Enable_Bushcraft",
        output = "Base.FHC_SkinningKnife",
        skill = { perk = "MetalWelding", level = 3 },
        xp = { perk = "MetalWelding", amount = 4 },
        inputs = {
            { count = 1, types = { "Base.SmallSheetMetal" } },
            { count = 1, types = { "Base.BlowTorch" }, keep = true, degrade = true },
            { count = 1, tags = { "base:hammer", "Hammer" }, keep = true, degrade = true },
        },
    },
    FHC_CraftCampHatchet = {
        time = 250,
        feature = "Enable_Bushcraft",
        output = "Base.FHC_CampHatchet",
        skill = { perk = "MetalWelding", level = 2 },
        xp = { perk = "MetalWelding", amount = 3 },
        inputs = {
            { count = 1, types = { "Base.SmallSheetMetal" } },
            { count = 1, types = { "Base.Plank" } },
            { count = 1, types = { "Base.BlowTorch" }, keep = true, degrade = true },
            { count = 1, tags = { "base:hammer", "Hammer" }, keep = true, degrade = true },
        },
    },
    FHC_CraftBushcraftSpear = {
        time = 150,
        feature = "Enable_Bushcraft",
        output = "Base.FHC_BushcraftSpear",
        xp = { perk = "Carving", amount = 3 },
        inputs = {
            { count = 1, types = { "Base.Plank" } },
            { count = 1, tags = { "base:sharpknife", "SharpKnife", "base:meatcleaver" }, keep = true, degrade = true },
            { count = 1, tags = { "base:binding", "base:rope", "FadedHuntersCalling:cordage", "Cordage" } },
        },
    },
    FHC_CraftTrappersClub = {
        time = 120,
        feature = "Enable_Bushcraft",
        output = "Base.FHC_TrappersClub",
        xp = { perk = "Woodwork", amount = 3 },
        inputs = {
            { count = 1, types = { "Base.Plank" } },
            { count = 1, tags = { "base:sharpknife", "SharpKnife", "base:meatcleaver" }, keep = true, degrade = true },
        },
    },
    FHC_CraftDryingRack = {
        time = 350,
        feature = "Enable_Bushcraft",
        output = "Base.FHC_DryingRack",
        xp = { perk = "Woodwork", amount = 5 },
        inputs = {
            { count = 4, types = { "Base.Plank" } },
            { count = 6, types = { "Base.Nails" } },
            { count = 1, tags = { "base:hammer", "Hammer" }, keep = true, degrade = true },
            { count = 1, tags = { "base:saw", "base:smallsaw", "base:crudesaw" }, keep = true, degrade = true },
        },
    },
    FHC_CraftHideRack = {
        time = 300,
        feature = "Enable_Bushcraft",
        output = "Base.FHC_HideRack",
        xp = { perk = "Woodwork", amount = 5 },
        inputs = {
            { count = 4, types = { "Base.Plank" } },
            { count = 4, types = { "Base.Nails" } },
            { count = 1, tags = { "base:binding", "base:rope", "FadedHuntersCalling:cordage", "Cordage" } },
            { count = 1, tags = { "base:hammer", "Hammer" }, keep = true, degrade = true },
        },
    },
    FHC_SaltHide = {
        time = 150,
        feature = "Enable_HideCuring",
        output = "Base.FHC_SaltedHide",
        xp = { perk = "Trapping", amount = 2 },
        inputs = {
            { count = 1, types = { "Base.FHC_RawHide" } },
            { count = 1, types = { "Base.Salt" } },
        },
    },
    FHC_CureHide = {
        time = 300,
        feature = "Enable_HideCuring",
        output = "Base.FHC_CuredHide",
        xp = { perk = "Trapping", amount = 4 },
        inputs = {
            { count = 1, types = { "Base.FHC_SaltedHide" } },
            { count = 1, tags = { "base:sharpknife", "SharpKnife", "base:scissors" }, keep = true, degrade = true },
        },
    },
    FHC_DryMeatStrip = {
        time = 280,
        feature = "Enable_MeatDrying",
        output = "Base.FHC_DriedMeat",
        xp = { perk = "Cooking", amount = 3 },
        inputs = {
            { count = 1, types = FHC.RAW_MEAT_TYPES },
            { count = 1, types = { "Base.Salt" } },
            { count = 1, tags = { "base:sharpknife", "SharpKnife", "base:meatcleaver" }, keep = true, degrade = true },
        },
    },
    FHC_HarvestSinewFromCarcass = {
        time = 120,
        feature = "Enable_Bushcraft",
        output = "Base.FHC_Sinew",
        xp = { perk = "Trapping", amount = 2 },
        inputs = {
            { count = 1, types = FHC.RAW_MEAT_TYPES },
            { count = 1, tags = { "base:sharpknife", "SharpKnife", "base:meatcleaver" }, keep = true, degrade = true },
        },
    },
}

FHC.MEAT_BY_ANIMAL = {
    cow      = "Base.Beef",
    pig      = "Base.Pork",
    sheep    = "Base.MuttonChop",
    chicken  = "Base.ChickenWhole",
    turkey   = "Base.TurkeyWhole",
    rabbit   = "Base.Rabbitmeat",
    deer     = "Base.Venison",
    raccoon  = "Base.Smallanimalmeat",
    rat      = "Base.Smallanimalmeat",
    mouse    = "Base.Smallanimalmeat",
    squirrel = "Base.Smallanimalmeat",
}

FHC.SCENT_DURATION_HOURS = 4.0
FHC.SCENT_ATTRACT_RADIUS = 45
FHC.SCENT_STOP_RADIUS = 3
FHC.SCENT_ATTRACT_INTERVAL_MS = 2000

FHC.ANIMAL_CALL_DURATION_HOURS = 0.08
FHC.ANIMAL_CALL_COOLDOWN_HOURS = 0.25
FHC.ANIMAL_CALL_RADIUS = 55
FHC.ANIMAL_CALL_STOP_RADIUS = 4
FHC.ANIMAL_CALL_ATTRACT_INTERVAL_MS = 1500

FHC.ANIMAL_CALL_ORDER = {
    "cow",
    "pig",
    "sheep",
    "chicken",
    "turkey",
    "rabbit",
    "deer",
    "raccoon",
    "rat",
    "mouse",
}

FHC.ANIMAL_CALLS = {
    cow      = { token = "FHC_Call_Cow",      book = "Base.FHC_AnimalCallBook_Cow",      sound = "AnimalVoiceCowIdle" },
    pig      = { token = "FHC_Call_Pig",      book = "Base.FHC_AnimalCallBook_Pig",      sound = "AnimalVoiceSowIdle" },
    sheep    = { token = "FHC_Call_Sheep",    book = "Base.FHC_AnimalCallBook_Sheep",    sound = "AnimalVoiceSheepIdle" },
    chicken  = { token = "FHC_Call_Chicken",  book = "Base.FHC_AnimalCallBook_Chicken",  sound = "AnimalVoiceChickenIdleWalk" },
    turkey   = { token = "FHC_Call_Turkey",   book = "Base.FHC_AnimalCallBook_Turkey",   sound = "AnimalVoiceTurkeyIdleWalk" },
    rabbit   = { token = "FHC_Call_Rabbit",   book = "Base.FHC_AnimalCallBook_Rabbit",   sound = "AnimalVoiceRabbitIdle" },
    deer     = { token = "FHC_Call_Deer",     book = "Base.FHC_AnimalCallBook_Deer",     sound = "AnimalVoiceDoeIdle" },
    raccoon  = { token = "FHC_Call_Raccoon",  book = "Base.FHC_AnimalCallBook_Raccoon",  sound = "AnimalVoiceRaccoonIdle" },
    rat      = { token = "FHC_Call_Rat",      book = "Base.FHC_AnimalCallBook_Rat",      sound = "AnimalVoiceRatIdle" },
    mouse    = { token = "FHC_Call_Mouse",    book = "Base.FHC_AnimalCallBook_Mouse",    sound = "AnimalVoiceMouseIdle" },
}

FHC.SCENT_ORDER = {
    "cow",
    "pig",
    "sheep",
    "chicken",
    "turkey",
    "rabbit",
    "deer",
    "raccoon",
    "rat",
    "mouse",
    "squirrel",
}

FHC.SCENT_ITEMS = {
    cow      = { item = "Base.FHC_CowScent",      short = "Cow" },
    pig      = { item = "Base.FHC_PigScent",      short = "Pig" },
    sheep    = { item = "Base.FHC_SheepScent",    short = "Sheep" },
    chicken  = { item = "Base.FHC_ChickenScent",  short = "Chicken" },
    turkey   = { item = "Base.FHC_TurkeyScent",   short = "Turkey" },
    rabbit   = { item = "Base.FHC_RabbitScent",   short = "Rabbit" },
    deer     = { item = "Base.FHC_DeerScent",     short = "Deer" },
    raccoon  = { item = "Base.FHC_RaccoonScent",  short = "Raccoon" },
    rat      = { item = "Base.FHC_RatScent",      short = "Rat" },
    mouse    = { item = "Base.FHC_MouseScent",    short = "Mouse" },
    squirrel = { item = "Base.FHC_SquirrelScent", short = "Squirrel" },
}

FHC.SCENT_BY_ITEM = {}
FHC.HUB_SCENT_CRAFT_ORDER = {}

local function FHC_recipeNameForScent(animalKey)
    return "FHC_Craft" .. string.upper(string.sub(animalKey, 1, 1)) .. string.sub(animalKey, 2) .. "Scent"
end

for _, animalKey in ipairs(FHC.SCENT_ORDER) do
    local scent = FHC.SCENT_ITEMS[animalKey]
    if scent then
        local recipeId = FHC_recipeNameForScent(animalKey)
        scent.recipeId = recipeId
        FHC.SCENT_BY_ITEM[scent.item] = animalKey
        table.insert(FHC.HUB_SCENT_CRAFT_ORDER, recipeId)
        FHC.HUB_CRAFTS[recipeId] = {
            time = 90,
            feature = "Enable_Bushcraft",
            output = scent.item,
            xp = { perk = "Trapping", amount = 1 },
            scentAnimal = animalKey,
            inputs = {
                { count = 1, types = { "Base.Cologne" } },
                { count = 1, types = { FHC.MEAT_BY_ANIMAL[animalKey] or "Base.Smallanimalmeat" } },
            },
        }
    end
end

-- Difficulty tuning. ProcessingSpeed sandbox multiplier is applied on top.
FHC.DIFFICULTY = {
    [1] = { name = "easy",     timeMul = 0.5, yieldMul = 1.25 },
    [2] = { name = "normal",   timeMul = 1.0, yieldMul = 1.0 },
    [3] = { name = "hardcore", timeMul = 1.75, yieldMul = 0.75 },
}
