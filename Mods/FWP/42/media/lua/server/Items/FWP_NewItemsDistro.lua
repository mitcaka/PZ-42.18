require "Items/ProceduralDistributions"
require "Items/SuburbsDistributions"
require "Vehicles/VehicleDistributions"

local FWPNewItemsDistroInjected = false

local function FWPAddWeighted(items, itemType, weight)
    if type(items) ~= "table" then return end
    items[#items + 1] = itemType
    items[#items + 1] = weight
end

local function FWPGetProcItems(name)
    if type(ProceduralDistributions) ~= "table" or type(ProceduralDistributions.list) ~= "table" then return nil end
    local bucket = ProceduralDistributions.list[name]
    if type(bucket) ~= "table" then return nil end
    if type(bucket.items) ~= "table" then bucket.items = {} end
    return bucket.items
end

local function FWPGetSuburbsItems(path)
    if type(SuburbsDistributions) ~= "table" then return nil end
    local dot = string.find(path, ".", 1, true)
    local bucket
    if dot then
        local first = string.sub(path, 1, dot - 1)
        local second = string.sub(path, dot + 1)
        bucket = SuburbsDistributions[first] and SuburbsDistributions[first][second]
    else
        bucket = SuburbsDistributions[path]
    end
    if type(bucket) ~= "table" then return nil end
    if type(bucket.items) ~= "table" then bucket.items = {} end
    return bucket.items
end

local function FWPGetVehicleItems(path)
    if type(VehicleDistributions) ~= "table" then return nil end
    local dot = string.find(path, ".", 1, true)
    local bucket
    if dot then
        local first = string.sub(path, 1, dot - 1)
        local second = string.sub(path, dot + 1)
        bucket = VehicleDistributions[first] and VehicleDistributions[first][second]
    else
        bucket = VehicleDistributions[path]
    end
    if type(bucket) ~= "table" then return nil end
    if type(bucket.items) ~= "table" then bucket.items = {} end
    return bucket.items
end

local function FWPInjectNewItemsDistro()
    if FWPNewItemsDistroInjected then return end

    local slingProc = {
        PoliceStorageOutfit = 1,
        PoliceLockers = 1,
        ArmyStorageOutfit = 5,
        LockerArmyBedroom = 5,
        FirearmWeapons = 2,
        PawnShopGunsSpecial = 2,
        ArmySurplusOutfit = 5,
        GunStoreShelf = 1,
        CampingStoreGear = 1,
        CampingStoreBackpacks = 1,
        WardrobeRedneck = 1,
    }
    for bucket, weight in pairs(slingProc) do
        FWPAddWeighted(FWPGetProcItems(bucket), "Base.FWP_RifleSling", weight)
    end

    local slingSuburbs = {
        ["SurvivorCache1.SurvivorCrate"] = 0.5,
        ["SurvivorCache2.SurvivorCrate"] = 0.5,
        Bag_WeaponBag = 0.5,
        Bag_SurvivorBag = 0.5,
    }
    for bucket, weight in pairs(slingSuburbs) do
        FWPAddWeighted(FWPGetSuburbsItems(bucket), "Base.FWP_RifleSling", weight)
    end

    local slingVehicles = {
        ["Police.TruckBed"] = 0.5,
        SurvivalistTruckBed = 0.5,
        HunterTruckBed = 0.5,
    }
    for bucket, weight in pairs(slingVehicles) do
        FWPAddWeighted(FWPGetVehicleItems(bucket), "Base.FWP_RifleSling", weight)
    end

    local m41Proc = {
        BedroomDresser = 0.08,
        BedroomSideTable = 0.08,
        DresserGeneric = 0.08,
        DrugLabGuns = 4,
        FirearmWeapons = 4,
        GunStoreDisplayCase = 4,
        OfficeDeskHome = 0.08,
        PawnShopGuns = 5,
        PawnShopGunsSpecial = 10,
        PlankStashGun = 5,
    }
    for bucket, weight in pairs(m41Proc) do
        local items = FWPGetProcItems(bucket)
        FWPAddWeighted(items, "Base.FWP_M41A_PulseRifle", weight)
        FWPAddWeighted(items, "Base.FWP_M41A_Magazine", weight)
    end

    local gaelSuppressors = {
        "Base.FWP_Gael_Osprey_Silencer",
        "Base.FWP_Gael_TMP_Silencer",
        "Base.FWP_Gael_SMG_Silencer",
        "Base.FWP_Gael_NST_Silencer",
        "Base.FWP_Gael_PBS1_Silencer",
        "Base.FWP_Gael_PBS4_Silencer",
        "Base.FWP_Gael_Dtkp_Silencer",
        "Base.FWP_Gael_Dtkp_Hexagon_Silencer",
        "Base.FWP_Gael_TGP_Silencer",
        "Base.FWP_Gael_Hexagon_12G_Suppressor",
        "Base.FWP_Gael_Salvo_12G_Suppressor",
        "Base.FWP_Gael_OilFilter_Silencer",
        "Base.FWP_Gael_SodaCan_Silencer",
        "Base.FWP_Gael_SprayCan_Silencer",
        "Base.FWP_Gael_Scrap_Silencer",
        "Base.FWP_Gael_scrap_pipe_suppressor",
        "Base.FWP_Gael_WaterBottle_ductaped",
    }
    local suppressorProc = {
        FirearmWeapons = 1,
        GunStoreDisplayCase = 2,
        GunStoreShelf = 2,
        PawnShopGunsSpecial = 2,
        PoliceLockers = 0.5,
        ArmyStorageOutfit = 0.5,
        ArmySurplusOutfit = 1,
    }
    for bucket, weight in pairs(suppressorProc) do
        local items = FWPGetProcItems(bucket)
        for _, itemType in ipairs(gaelSuppressors) do
            FWPAddWeighted(items, itemType, weight)
        end
    end

    local looseCasings = {
        "Base.Brass9",
        "Base.Brass45",
        "Base.Brass556",
        "Base.Brass762x39",
        "Base.Hull12g",
    }
    local casingBags = {
        "Base.Bag_Brass9",
        "Base.Bag_Brass45",
        "Base.Bag_Brass556",
        "Base.Bag_Brass762x39",
        "Base.Bag_Hull12g",
    }
    local casingProc = {
        GarageFirearms = 2,
        GunStoreShelf = 2,
        FirearmWeapons = 1.5,
        PoliceEvidence = 1.5,
        HuntingLockers = 1,
        ArmyStorageAmmunition = 2,
    }
    for bucket, weight in pairs(casingProc) do
        local items = FWPGetProcItems(bucket)
        for _, itemType in ipairs(looseCasings) do
            FWPAddWeighted(items, itemType, weight)
        end
        for _, itemType in ipairs(casingBags) do
            FWPAddWeighted(items, itemType, weight * 0.35)
        end
    end

    local incAmmoProc = {
        GunStoreAmmunition = 3,
        ArmySurplusAmmoBoxes = 1.5,
        ArmySurplusTools = 1,
        ArmySurplusBackpacks = 0.75,
        GunStoreShelf = 3,
        GunStoreDisplayCase = 2,
        PawnShopGuns = 1,
        PawnShopGunsSpecial = 1.5,
        PoliceStorageAmmunition = 1,
        ArmyStorageAmmunition = 2,
        HuntingLockers = 1,
        FirearmWeapons = 1,
        PlankStashGun = 0.75,
    }
    for bucket, weight in pairs(incAmmoProc) do
        local items = FWPGetProcItems(bucket)
        FWPAddWeighted(items, "Base.FWP_12gIncendiaryShells", weight)
        FWPAddWeighted(items, "Base.FWP_12gIncendiaryShellsBox", weight * 0.35)
    end

    local incAmmoSuburbs = {
        ["SurvivorCache1.SurvivorCrate"] = 0.35,
        ["SurvivorCache2.SurvivorCrate"] = 0.35,
        Bag_WeaponBag = 0.25,
        Bag_SurvivorBag = 0.25,
    }
    for bucket, weight in pairs(incAmmoSuburbs) do
        local items = FWPGetSuburbsItems(bucket)
        FWPAddWeighted(items, "Base.FWP_12gIncendiaryShells", weight)
        FWPAddWeighted(items, "Base.FWP_12gIncendiaryShellsBox", weight * 0.35)
    end

    local incAmmoVehicles = {
        ["Police.GloveBox"] = 0.15,
        ["Police.TruckBed"] = 0.25,
        SurvivalistTruckBed = 0.25,
        HunterTruckBed = 0.25,
    }
    for bucket, weight in pairs(incAmmoVehicles) do
        local items = FWPGetVehicleItems(bucket)
        FWPAddWeighted(items, "Base.FWP_12gIncendiaryShells", weight)
        FWPAddWeighted(items, "Base.FWP_12gIncendiaryShellsBox", weight * 0.35)
    end

    local flameFuelProc = {
        ArmyStorageAmmunition = 0.5,
        CampingStoreGear = 0.8,
        FirearmWeapons = 0.5,
        ForestFireTools = 1,
        GarageTools = 1,
        GrillAcessories = 1,
        GunStoreShelf = 0.5,
        HuntingLockers = 0.5,
        LoggingFactoryTools = 1,
    }
    for bucket, weight in pairs(flameFuelProc) do
        local items = FWPGetProcItems(bucket)
        FWPAddWeighted(items, "Base.M2A1_Can", weight)
        FWPAddWeighted(items, "Base.M2A1_Tank", weight * 0.35)
    end

    FWPNewItemsDistroInjected = true
end

local function FWPSafeInjectNewItemsDistro()
    local ok, err = pcall(FWPInjectNewItemsDistro)
    if not ok then
        print("[FWP] new item distro skipped: " .. tostring(err))
    end
end

if Events and Events.OnPreDistributionMerge then Events.OnPreDistributionMerge.Add(FWPSafeInjectNewItemsDistro) end
if Events and Events.OnInitWorld then Events.OnInitWorld.Add(FWPSafeInjectNewItemsDistro) end
