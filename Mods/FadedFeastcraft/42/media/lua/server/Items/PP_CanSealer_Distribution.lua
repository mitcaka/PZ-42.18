require 'Items/ProceduralDistributions'
require "FadedFeastcraft/FFC_DistributionSafety"

if FadedFeastcraft and FadedFeastcraft.DistributionSafety then
    FadedFeastcraft.DistributionSafety.installProceduralFallback()
end

table.insert(ProceduralDistributions["list"]["ArmyBunkerKitchen"].items, "ExtraCraft.TinSealer");
table.insert(ProceduralDistributions["list"]["ArmyBunkerKitchen"].items, 20.0); --25.0

table.insert(ProceduralDistributions["list"]["BreakRoomCounter"].items, "ExtraCraft.TinSealer");
table.insert(ProceduralDistributions["list"]["BreakRoomCounter"].items, 15.0); --20.0

table.insert(ProceduralDistributions["list"]["DerelictHouseSquatter"].items, "ExtraCraft.TinSealer");
table.insert(ProceduralDistributions["list"]["DerelictHouseSquatter"].items, 12.0); --18.0

table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "ExtraCraft.TinSealer");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, 25.0); --30.0

table.insert(ProceduralDistributions["list"]["KitchenDishes"].items, "ExtraCraft.TinSealer");
table.insert(ProceduralDistributions["list"]["KitchenDishes"].items, 20.0); --25.0

table.insert(ProceduralDistributions["list"]["KitchenPots"].items, "ExtraCraft.TinSealer");
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, 17.0); --22.0

table.insert(ProceduralDistributions["list"]["KitchenRandom"].items, "ExtraCraft.TinSealer");
table.insert(ProceduralDistributions["list"]["KitchenRandom"].items, 30.0); --35.0

table.insert(ProceduralDistributions["list"]["LivingRoomShelf"].items, "ExtraCraft.TinSealer");
table.insert(ProceduralDistributions["list"]["LivingRoomShelf"].items, 15.0); --15.0

table.insert(ProceduralDistributions["list"]["ShelfGeneric"].items, "ExtraCraft.TinSealer");
table.insert(ProceduralDistributions["list"]["ShelfGeneric"].items, 13.0); --18.0

table.insert(ProceduralDistributions["list"]["GarageTools"].items, "ExtraCraft.TinSealer");
table.insert(ProceduralDistributions["list"]["GarageTools"].items, 7.0); --12.0
