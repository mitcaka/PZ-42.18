require "Items/ProceduralDistributions"
require "Items/SuburbsDistributions"
require "FadedFeastcraft/FFC_DistributionSafety"

FadedFeastcraft = FadedFeastcraft or {}
if FadedFeastcraft.SupplementalDistributionsInstalled then return end
FadedFeastcraft.SupplementalDistributionsInstalled = true

local Safety = FadedFeastcraft.DistributionSafety

if Safety and Safety.installProceduralFallback then
    Safety.installProceduralFallback()
end

local function hasScriptItem(fullType)
    if not fullType or not getScriptManager then return false end
    local manager = getScriptManager()
    if not manager or not manager.FindItem then return false end
    return manager:FindItem(fullType) ~= nil
end

local function proceduralItems(name)
    if Safety and Safety.ensureProceduralList then
        return Safety.ensureProceduralList(name)
    end
    if not ProceduralDistributions then return nil end
    ProceduralDistributions.list = ProceduralDistributions.list or ProceduralDistributions["list"] or {}
    ProceduralDistributions.list[name] = ProceduralDistributions.list[name] or { rolls = 1, items = {} }
    ProceduralDistributions.list[name].items = ProceduralDistributions.list[name].items or {}
    return ProceduralDistributions.list[name].items
end

local function addProcedural(name, fullType, weight)
    if not hasScriptItem(fullType) then return end
    local items = proceduralItems(name)
    if not items then return end
    table.insert(items, fullType)
    table.insert(items, weight)
end

local function addToAll(listNames, fullTypes, weight)
    for _, listName in ipairs(listNames or {}) do
        for _, fullType in ipairs(fullTypes or {}) do
            addProcedural(listName, fullType, weight)
        end
    end
end

local wildFruits = {
    "MattSimpleAddons.MSABlack_Cherry",
    "MattSimpleAddons.MSAmerican_Plumb",
    "MattSimpleAddons.MSARaspberries",
    "MattSimpleAddons.MSABlackBerries",
    "MattSimpleAddons.MSAMulberry",
}

local snackTimeShelf = {
    "SnackTime89.ST_BatonMikado",
    "SnackTime89.ST_BiscuitBNC",
    "SnackTime89.ST_BiscuitBNF",
    "SnackTime89.ST_BiscuitEcolier",
    "SnackTime89.ST_BiscuitOreo",
    "SnackTime89.ST_ChipsahoyC",
    "SnackTime89.ST_ChipsahoyChewy",
    "SnackTime89.ST_ChipsahoyO",
    "SnackTime89.ST_ChipsahoyOriginal",
    "SnackTime89.ST_HariboF",
    "SnackTime89.ST_Lollipop",
    "SnackTime89.ST_MaltesersB",
    "SnackTime89.ST_MentosCaps",
    "SnackTime89.ST_MentosCapsF",
    "SnackTime89.ST_SkittlesG",
}

local snackTimeSalty = {
    "SnackTime89.ST_BiscuitTUC",
    "SnackTime89.ST_BiscuitTUCB",
    "SnackTime89.ST_BretzelsP",
}

local popRocks = {
    "VFX.PopRocksBlueRaspberry",
    "VFX.PopRocksCherry",
    "VFX.PopRocksCottonCandy",
    "VFX.PopRocksGrape",
    "VFX.PopRocksGreenApple",
    "VFX.PopRocksStrawberry",
    "VFX.PopRocksTropicalPunch",
    "VFX.PopRocksWatermelon",
}

local tedCereals = {
    "Ted.LuckyCharmsCereal",
    "Ted.OreoCereal",
}

local mreBulkRations = {
    "MR.Compressed_Biscuit_bucket",
}

local vfxToasterStrudels = {
    "VFX.StrawberryStrudelsBox",
    "VFX.CherryStrudelsBox",
    "VFX.BlueberryStrudelsBox",
    "VFX.CookiesAndCreamStrudelsBox",
    "VFX.BrownSugarStrudelsBox",
}

addToAll({
    "GigamartFruits",
    "GroceryStorageCrate1",
    "GroceryStorageCrate2",
    "KitchenProduce",
    "ProduceStorage",
    "StoreShelfCombo",
}, wildFruits, 1.0)

addToAll({
    "CandyStoreSnacks",
    "ConvenienceStoreSnacks",
    "GigamartSnacks",
    "KitchenSnack",
    "OfficeShelfSnacks",
    "StoreShelfSnacks",
    "VendingSnacks",
}, snackTimeShelf, 2.0)

addToAll({
    "BarCounterSnacks",
    "ConvenienceStoreSnacks",
    "GigamartSnacks",
    "KitchenDryFood",
    "KitchenSnack",
    "StoreShelfSnacks",
}, snackTimeSalty, 2.0)

addToAll({
    "CandyStoreSnacks",
    "GigamartCandy",
    "GigamartSnacks",
    "KitchenSnack",
    "StoreShelfSnacks",
    "VendingSnacks",
}, popRocks, 1.5)

addToAll({
    "GigamartDryGoods",
    "KitchenDryFood",
    "StoreShelfSnacks",
}, tedCereals, 1.5)

addToAll({
    "ArmyStorageGuns",
    "GunStoreGuns",
    "PoliceStorageGuns",
    "DrugLabGuns",
    "FirearmWeapons",
    "GunStoreMagsAmmo",
    "PoliceDesk",
    "PoliceFileBox",
}, mreBulkRations, 0.5)

addToAll({
    "FreezerGeneric",
    "GigamartFrozenFood",
    "KitchenFreezer",
    "StoreKitchenFreezer",
}, vfxToasterStrudels, 1.0)

addToAll({
    "ChineseKitchenBaking",
    "GigamartDryGoods",
    "KitchenDryFood",
    "StoreKitchenButcher",
}, { "VFX.SesameSeeds" }, 2.0)

addToAll({
    "CafeKitchenCoffee",
    "CafeKitchenSupplies",
    "MexicanKitchenFridge",
}, { "AbuelitaLinda.CafeOllaRed" }, 0.5)
