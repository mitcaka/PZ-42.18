-- FHC_TrapAnimals.lua
-- Adds live-capture-friendly bait/animal entries to vanilla TrapAnimals.
-- Pure additive: does NOT remove or alter existing vanilla rows.
-- Loaded shared so it ticks on both client and dedicated server.

require "FHC_Constants"
require "FHC_Sandbox"
require "FHC_Utils"

if not FHC.SB.trapping() then
    return
end

local liveCaptureOn = FHC.SB.liveCapture()

TrapAnimals = TrapAnimals or {}

local FHC_ZONES = {
    TownZone = 70,  TrailerPark = 70,
    Vegetation = 100, Vegitation = 100,
    Forest = 100, DeepForest = 100,
    BirchForest = 100, BirchMixForest = 100,
    Farm = 100, FarmLand = 100,
    FarmForest = 100, FarmMixForest = 100,
    PRForest = 100, PHForest = 100, PHMixForest = 100,
    OrganicForest = 100,
}

local FHC_TRAPS = {
    ["Base.TrapCage"]  = 100,
    ["Base.TrapSnare"] = 100,
    ["Base.TrapBox"]   = 100,
    ["Base.TrapCrate"] = 100,
    ["Base.TrapStick"] = 100,
}

local function copy(t)
    local out = {}
    for k, v in pairs(t) do out[k] = v end
    return out
end

local function FHC_Animal(data)
    local a = {}
    a.type            = data.type
    a.strength        = data.strength or 24
    a.item            = data.item or "Base.DeadRabbit"
    a.minHour         = data.minHour or 0
    a.maxHour         = data.maxHour or 24
    a.minSize         = data.minSize or 30
    a.maxSize         = data.maxSize or 100
    a.canBeAlive      = liveCaptureOn and true or false
    a.aliveAnimals    = data.aliveAnimals or {}
    a.aliveBreed      = data.aliveBreed or {}
    a.zone            = copy(FHC_ZONES)
    a.traps           = copy(FHC_TRAPS)
    a.baits           = data.baits or {}
    a.fhcAdded        = true   -- marker for the trap board to label our rows
    return a
end

local FHC_TABLE = {
    FHC_Animal({
        type = "rabbit", strength = 24, minSize = 20, maxSize = 50,
        aliveAnimals = { "rabdoe", "rabbuck", "rabkitten" },
        aliveBreed   = { "cottontail", "swamp", "appalachian" },
        baits = {
            ["Base.WheatSheaf"] = 100, ["Base.Lettuce"] = 100, ["Base.Carrots"] = 100,
            ["Base.FHC_Sinew"] = 30,
        },
    }),
    FHC_Animal({
        type = "pig", strength = 12, minSize = 50, maxSize = 130,
        aliveAnimals = { "sow", "boar", "piglet" },
        aliveBreed   = { "landrace", "largeblack" },
        baits = {
            ["Base.Potato"] = 100, ["Base.SweetPotato"] = 100, ["Base.Apple"] = 60,
        },
    }),
    FHC_Animal({
        type = "chicken", strength = 96, minSize = 20, maxSize = 50,
        aliveAnimals = { "hen", "cockerel", "chick" },
        aliveBreed   = { "rhodeisland", "leghorn" },
        baits = {
            ["Base.Corn"] = 100, ["Base.SunflowerSeeds"] = 100, ["Base.Broccoli"] = 100,
        },
    }),
    FHC_Animal({
        type = "turkey", strength = 72, minSize = 30, maxSize = 100,
        aliveAnimals = { "turkeyhen", "gobblers", "turkeypoult" },
        aliveBreed   = { "meleagris" },
        baits = {
            ["Base.Pumpkin"] = 100, ["Base.Cabbage"] = 100, ["Base.Worm"] = 100,
        },
    }),
    FHC_Animal({
        type = "sheep", strength = 96, minSize = 30, maxSize = 100,
        aliveAnimals = { "ram", "ewe", "lamb" },
        aliveBreed   = { "suffolk", "rambouillet", "friesian" },
        baits = {
            ["Base.Strewberrie"] = 100, ["Base.BerryBlue"] = 100,
            ["Base.Watermelon"] = 100, ["Base.GrassTuft"] = 100,
        },
    }),
    FHC_Animal({
        type = "deer", strength = 12, minSize = 30, maxSize = 100,
        aliveAnimals = { "doe", "buck", "fawn" },
        aliveBreed   = { "whitetailed" },
        baits = {
            ["Base.Acorn"] = 100, ["Base.Spinach"] = 100, ["Base.Soybeans"] = 100,
            ["Base.Apple"] = 60,
        },
    }),
    FHC_Animal({
        type = "cow", strength = 12, minSize = 30, maxSize = 100,
        aliveAnimals = { "cowcalf" },
        aliveBreed   = { "angus", "simmental", "holstein" },
        baits = {
            ["Base.BarleySheaf"] = 100, ["Base.RyeSheaf"] = 100,
        },
    }),
}

local function isFhcType(t)
    if not t then return false end
    local lt = string.lower(tostring(t))
    return lt == "rabbit" or lt == "pig" or lt == "chicken" or lt == "turkey"
        or lt == "sheep" or lt == "deer" or lt == "cow"
end

-- Remove only ROWS THAT WE OWN. Never touch vanilla rows.
for i = #TrapAnimals, 1, -1 do
    local row = TrapAnimals[i]
    if row and row.fhcAdded and isFhcType(row.type) then
        table.remove(TrapAnimals, i)
    end
end

for _, a in ipairs(FHC_TABLE) do
    table.insert(TrapAnimals, a)
end

FHC.Utils.log("TrapAnimals: appended " .. #FHC_TABLE .. " hunter rows (liveCapture=" .. tostring(liveCaptureOn) .. ")")
