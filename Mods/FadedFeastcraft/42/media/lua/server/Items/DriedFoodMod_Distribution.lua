require "Items/SuburbsDistributions"
require "Items/ProceduralDistributions"
require "FadedFeastcraft/FFC_DistributionSafety"

if FadedFeastcraft and FadedFeastcraft.DistributionSafety then
    FadedFeastcraft.DistributionSafety.installProceduralFallback()
end

local function addDriedFoodItemToDistributions(itemName, probability)
    local distributions = {
        "CrateCannedFood",
        "GigamartBakingMisc",
        "GigamartCannedFood",
        "GroceryStorageCrate1",
        "GroceryStorageCrate2",
        "KitchenCannedFood",
        "Hunter",
        "HuntingLockers",
        "LockerArmyBedroom",
        "SurvivalGear",
        "CrateHumanitarian",
        "DerelictHouseSquatter",
        "FoodGourmet",
        "FridgeRich",
        "Homesteading",
        "SafehouseFood",
        "SafehouseFood_Mid",
        "SafehouseFridge_Mid",
        "SafehouseFridge_Late",
        "ArmyBunkerKitchen"
    }
    
    for _, distribution in ipairs(distributions) do
        table.insert(ProceduralDistributions["list"][distribution].items, itemName)
        table.insert(ProceduralDistributions["list"][distribution].items, probability)
    end
end

-- Function calls to add items
addDriedFoodItemToDistributions("DriedFoodMod.FDriedFoodCan", 10)
