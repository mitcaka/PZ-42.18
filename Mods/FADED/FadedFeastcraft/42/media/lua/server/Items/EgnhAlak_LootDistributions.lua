require 'Items/SuburbsDistributions'
require 'Items/ProceduralDistributions'
require "FadedFeastcraft/FFC_DistributionSafety"

if FadedFeastcraft and FadedFeastcraft.DistributionSafety then
    FadedFeastcraft.DistributionSafety.installProceduralFallback()
end

--BandPracticeFridge
table.insert(ProceduralDistributions.list["BandPracticeFridge"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["BandPracticeFridge"].items, 8);
table.insert(ProceduralDistributions.list["BandPracticeFridge"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["BandPracticeFridge"].items, 8);
table.insert(ProceduralDistributions.list["BandPracticeFridge"].items, "Base.BeerRedHorse");
table.insert(ProceduralDistributions.list["BandPracticeFridge"].items, 4);
table.insert(ProceduralDistributions.list["BandPracticeFridge"].items, "Base.Soju");
table.insert(ProceduralDistributions.list["BandPracticeFridge"].items, 1);
table.insert(ProceduralDistributions.list["BandPracticeFridge"].items, "Base.TequilaCuervo");
table.insert(ProceduralDistributions.list["BandPracticeFridge"].items, 1);

--BarCounterLiquor
table.insert(ProceduralDistributions.list["BarCounterLiquor"].items, "Base.BrandyEmperador");
table.insert(ProceduralDistributions.list["BarCounterLiquor"].items, 4);
table.insert(ProceduralDistributions.list["BarCounterLiquor"].items, "Base.GinGinebra");
table.insert(ProceduralDistributions.list["BarCounterLiquor"].items, 4);
table.insert(ProceduralDistributions.list["BarCounterLiquor"].items, "Base.Soju");
table.insert(ProceduralDistributions.list["BarCounterLiquor"].items, 4);
table.insert(ProceduralDistributions.list["BarCounterLiquor"].items, "Base.TequilaCuervo");
table.insert(ProceduralDistributions.list["BarCounterLiquor"].items, 4);

--BarCounterWeapon
table.insert(ProceduralDistributions.list["BarCounterWeapon"].items, "Base.BrandyEmperador");
table.insert(ProceduralDistributions.list["BarCounterWeapon"].items, 4);
table.insert(ProceduralDistributions.list["BarCounterWeapon"].items, "Base.GinGinebra");
table.insert(ProceduralDistributions.list["BarCounterWeapon"].items, 4);
table.insert(ProceduralDistributions.list["BarCounterWeapon"].items, "Base.Soju");
table.insert(ProceduralDistributions.list["BarCounterWeapon"].items, 4);
table.insert(ProceduralDistributions.list["BarCounterWeapon"].items, "Base.TequilaCuervo");
table.insert(ProceduralDistributions.list["BarCounterWeapon"].items, 4);

--BarShelfLiquor
table.insert(ProceduralDistributions.list["BarShelfLiquor"].items, "Base.BrandyEmperador");
table.insert(ProceduralDistributions.list["BarShelfLiquor"].items, 4);
table.insert(ProceduralDistributions.list["BarShelfLiquor"].items, "Base.GinGinebra");
table.insert(ProceduralDistributions.list["BarShelfLiquor"].items, 4);
table.insert(ProceduralDistributions.list["BarShelfLiquor"].items, "Base.Soju");
table.insert(ProceduralDistributions.list["BarShelfLiquor"].items, 4);
table.insert(ProceduralDistributions.list["BarShelfLiquor"].items, "Base.TequilaCuervo");
table.insert(ProceduralDistributions.list["BarShelfLiquor"].items, 4);

--BeerGardenCounter
table.insert(ProceduralDistributions.list["BeerGardenCounter"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["BeerGardenCounter"].items, 15);
table.insert(ProceduralDistributions.list["BeerGardenCounter"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["BeerGardenCounter"].items, 15);
table.insert(ProceduralDistributions.list["BeerGardenCounter"].items, "Base.BeerRedHorse");
table.insert(ProceduralDistributions.list["BeerGardenCounter"].items, 10);

--BreweryBottles
table.insert(ProceduralDistributions.list["BreweryBottles"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["BreweryBottles"].items, 15);

--BreweryCans
table.insert(ProceduralDistributions.list["BreweryCans"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["BreweryCans"].items, 15);

--CrateBeer
table.insert(ProceduralDistributions.list["CrateBeer"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["CrateBeer"].items, 15);
table.insert(ProceduralDistributions.list["CrateBeer"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["CrateBeer"].items, 15);
table.insert(ProceduralDistributions.list["CrateBeer"].items, "Base.BeerRedHorse");
table.insert(ProceduralDistributions.list["CrateBeer"].items, 10);

--DerelictHouseParty
table.insert(ProceduralDistributions.list["DerelictHouseParty"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["DerelictHouseParty"].items, 8);
table.insert(ProceduralDistributions.list["DerelictHouseParty"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["DerelictHouseParty"].items, 8);
table.insert(ProceduralDistributions.list["DerelictHouseParty"].items, "Base.BeerRedHorse");
table.insert(ProceduralDistributions.list["DerelictHouseParty"].items, 1);
table.insert(ProceduralDistributions.list["DerelictHouseParty"].items, "Base.Soju");
table.insert(ProceduralDistributions.list["DerelictHouseParty"].items, 1);
table.insert(ProceduralDistributions.list["DerelictHouseParty"].items, "Base.TequilaCuervo");
table.insert(ProceduralDistributions.list["DerelictHouseParty"].items, 1);

--DrugShackDrugs
table.insert(ProceduralDistributions.list["DrugShackDrugs"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["DrugShackDrugs"].items, 8);
table.insert(ProceduralDistributions.list["DrugShackDrugs"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["DrugShackDrugs"].items, 8);
table.insert(ProceduralDistributions.list["DrugShackDrugs"].items, "Base.BeerRedHorse");
table.insert(ProceduralDistributions.list["DrugShackDrugs"].items, 1);
table.insert(ProceduralDistributions.list["DrugShackDrugs"].items, "Base.TequilaCuervo");
table.insert(ProceduralDistributions.list["DrugShackDrugs"].items, 1);

--FridgeBeer
table.insert(ProceduralDistributions.list["FridgeBeer"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["FridgeBeer"].items, 15);
table.insert(ProceduralDistributions.list["FridgeBeer"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["FridgeBeer"].items, 15);
table.insert(ProceduralDistributions.list["FridgeBeer"].items, "Base.BeerRedHorse");
table.insert(ProceduralDistributions.list["FridgeBeer"].items, 10);

--FridgeDrugLab
table.insert(ProceduralDistributions.list["FridgeDrugLab"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["FridgeDrugLab"].items, 5);
table.insert(ProceduralDistributions.list["FridgeDrugLab"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["FridgeDrugLab"].items, 5);

--FridgeFarmStorage
table.insert(ProceduralDistributions.list["FridgeFarmStorage"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["FridgeFarmStorage"].items, 5);
table.insert(ProceduralDistributions.list["FridgeFarmStorage"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["FridgeFarmStorage"].items, 5);

--FridgeGarage
table.insert(ProceduralDistributions.list["FridgeGarage"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["FridgeGarage"].items, 15);
table.insert(ProceduralDistributions.list["FridgeGarage"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["FridgeGarage"].items, 15);
table.insert(ProceduralDistributions.list["FridgeGarage"].items, "Base.BeerRedHorse");
table.insert(ProceduralDistributions.list["FridgeGarage"].items, 10);

--FridgeGeneric
table.insert(ProceduralDistributions.list["FridgeGeneric"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["FridgeGeneric"].items, 1);
table.insert(ProceduralDistributions.list["FridgeGeneric"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["FridgeGeneric"].items, 1);
table.insert(ProceduralDistributions.list["FridgeGeneric"].items, "Base.BeerRedHorse");
table.insert(ProceduralDistributions.list["FridgeGeneric"].items, 1);
table.insert(ProceduralDistributions.list["FridgeGeneric"].items, "Base.Soju");
table.insert(ProceduralDistributions.list["FridgeGeneric"].items, 1);
table.insert(ProceduralDistributions.list["FridgeGeneric"].items, "Base.TequilaCuervo");
table.insert(ProceduralDistributions.list["FridgeGeneric"].items, 1);

--FridgeHoarder
--[[
table.insert(ProceduralDistributions.list["FridgeHoarder"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["FridgeHoarder"].items, 15);
table.insert(ProceduralDistributions.list["FridgeHoarder"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["FridgeHoarder"].items, 15);
table.insert(ProceduralDistributions.list["FridgeHoarder"].items, "Base.BeerRedHorse");
table.insert(ProceduralDistributions.list["FridgeHoarder"].items, 10);
table.insert(ProceduralDistributions.list["FridgeHoarder"].items, "Base.Soju");
table.insert(ProceduralDistributions.list["FridgeHoarder"].items, 10);
table.insert(ProceduralDistributions.list["FridgeHoarder"].items, "Base.TequilaCuervo");
table.insert(ProceduralDistributions.list["FridgeHoarder"].items, 10);
]]--

--FridgeRich
table.insert(ProceduralDistributions.list["FridgeRich"].items, "Base.BeerRedHorse");
table.insert(ProceduralDistributions.list["FridgeRich"].items, 2);
table.insert(ProceduralDistributions.list["FridgeRich"].items, "Base.Soju");
table.insert(ProceduralDistributions.list["FridgeRich"].items, 2);

--FridgeTrailerPark
table.insert(ProceduralDistributions.list["FridgeTrailerPark"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["FridgeTrailerPark"].items, 2);

--KitchenBottles
table.insert(ProceduralDistributions.list["KitchenBottles"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["KitchenBottles"].items, 1);
table.insert(ProceduralDistributions.list["KitchenBottles"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["KitchenBottles"].items, 1);
table.insert(ProceduralDistributions.list["KitchenBottles"].items, "Base.BeerRedHorse");
table.insert(ProceduralDistributions.list["KitchenBottles"].items, 1);

--LiquorStoreBrandy
table.insert(ProceduralDistributions.list["LiquorStoreBrandy"].items, "Base.BrandyEmperador");
table.insert(ProceduralDistributions.list["LiquorStoreBrandy"].items, 10);
table.insert(ProceduralDistributions.list["LiquorStoreBrandy"].items, "Base.BrandyEmperador");
table.insert(ProceduralDistributions.list["LiquorStoreBrandy"].items, 10);

--LiquorStoreGin
table.insert(ProceduralDistributions.list["LiquorStoreGin"].items, "Base.GinGinebra");
table.insert(ProceduralDistributions.list["LiquorStoreGin"].items, 10);
table.insert(ProceduralDistributions.list["LiquorStoreGin"].items, "Base.GinGinebra");
table.insert(ProceduralDistributions.list["LiquorStoreGin"].items, 10);

--LiquorStoreTequila
table.insert(ProceduralDistributions.list["LiquorStoreTequila"].items, "Base.TequilaCuervo");
table.insert(ProceduralDistributions.list["LiquorStoreTequila"].items, 10);
table.insert(ProceduralDistributions.list["LiquorStoreTequila"].items, "Base.TequilaCuervo");
table.insert(ProceduralDistributions.list["LiquorStoreTequila"].items, 10);

--NolansFridge
table.insert(ProceduralDistributions.list["NolansFridge"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["NolansFridge"].items, 4);
table.insert(ProceduralDistributions.list["NolansFridge"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["NolansFridge"].items, 4);
table.insert(ProceduralDistributions.list["NolansFridge"].items, "Base.BeerRedHorse");
table.insert(ProceduralDistributions.list["NolansFridge"].items, 2);

--SafehouseBooze
table.insert(ProceduralDistributions.list["SafehouseBooze"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["SafehouseBooze"].items, 12);
table.insert(ProceduralDistributions.list["SafehouseBooze"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["SafehouseBooze"].items, 12);
table.insert(ProceduralDistributions.list["SafehouseBooze"].items, "Base.BeerRedHorse");
table.insert(ProceduralDistributions.list["SafehouseBooze"].items, 10);
table.insert(ProceduralDistributions.list["SafehouseBooze"].items, "Base.GinGinebra");
table.insert(ProceduralDistributions.list["SafehouseBooze"].items, 10);
table.insert(ProceduralDistributions.list["SafehouseBooze"].items, "Base.Soju");
table.insert(ProceduralDistributions.list["SafehouseBooze"].items, 10);
table.insert(ProceduralDistributions.list["SafehouseBooze"].items, "Base.TequilaCuervo");
table.insert(ProceduralDistributions.list["SafehouseBooze"].items, 10);

--SafehouseFood
table.insert(ProceduralDistributions.list["SafehouseFood"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["SafehouseFood"].items, 5);
table.insert(ProceduralDistributions.list["SafehouseFood"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["SafehouseFood"].items, 5);

--SafehouseFood_Mid
table.insert(ProceduralDistributions.list["SafehouseFood_Mid"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["SafehouseFood_Mid"].items, 1);
table.insert(ProceduralDistributions.list["SafehouseFood_Mid"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["SafehouseFood_Mid"].items, 1);

--SafehouseFridge
table.insert(ProceduralDistributions.list["SafehouseFridge"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["SafehouseFridge"].items, 5);
table.insert(ProceduralDistributions.list["SafehouseFridge"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["SafehouseFridge"].items, 5);
table.insert(ProceduralDistributions.list["SafehouseFridge"].items, "Base.BeerRedHorse");
table.insert(ProceduralDistributions.list["SafehouseFridge"].items, 2);
table.insert(ProceduralDistributions.list["SafehouseFridge"].items, "Base.GinGinebra");
table.insert(ProceduralDistributions.list["SafehouseFridge"].items, 1);
table.insert(ProceduralDistributions.list["SafehouseFridge"].items, "Base.Soju");
table.insert(ProceduralDistributions.list["SafehouseFridge"].items, 1);
table.insert(ProceduralDistributions.list["SafehouseFridge"].items, "Base.TequilaCuervo");
table.insert(ProceduralDistributions.list["SafehouseFridge"].items, 1);

--SafehouseFridge_Mid
table.insert(ProceduralDistributions.list["SafehouseFridge_Mid"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["SafehouseFridge_Mid"].items, 1);
table.insert(ProceduralDistributions.list["SafehouseFridge_Mid"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["SafehouseFridge_Mid"].items, 1);
table.insert(ProceduralDistributions.list["SafehouseFridge_Mid"].items, "Base.BeerRedHorse");
table.insert(ProceduralDistributions.list["SafehouseFridge_Mid"].items, 0.5);
table.insert(ProceduralDistributions.list["SafehouseFridge_Mid"].items, "Base.GinGinebra");
table.insert(ProceduralDistributions.list["SafehouseFridge_Mid"].items, 0.1);
table.insert(ProceduralDistributions.list["SafehouseFridge_Mid"].items, "Base.Soju");
table.insert(ProceduralDistributions.list["SafehouseFridge_Mid"].items, 0.1);
table.insert(ProceduralDistributions.list["SafehouseFridge_Mid"].items, "Base.TequilaCuervo");
table.insert(ProceduralDistributions.list["SafehouseFridge_Mid"].items, 0.1);

--UniversityFridge
table.insert(ProceduralDistributions.list["UniversityFridge"].items, "Base.BeerPalePilsen");
table.insert(ProceduralDistributions.list["UniversityFridge"].items, 1);
table.insert(ProceduralDistributions.list["UniversityFridge"].items, "Base.BeerCanPalePilsen");
table.insert(ProceduralDistributions.list["UniversityFridge"].items, 1);
table.insert(ProceduralDistributions.list["UniversityFridge"].items, "Base.BeerRedHorse");
table.insert(ProceduralDistributions.list["UniversityFridge"].items, 1);



