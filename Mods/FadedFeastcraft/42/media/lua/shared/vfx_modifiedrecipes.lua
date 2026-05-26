require "FadedFeastcraft/FFC_DistributionSafety"

local function EditRecipes()
    local recipeList = {

        ["OpenCannedFood"] = {
            inputs = [[
            item 1 tags[base:canopener] mode:keep flags[MayDegradeLight],
            item 1 [Base.TinnedBeans;Base.CannedBolognese;Base.CannedCarrots2;Base.CannedChili;Base.CannedCorn;Base.CannedFruitCocktail;Base.CannedFruitBeverage;Base.CannedMilk;Base.CannedMushroomSoup;Base.CannedPeaches;Base.CannedPeas;Base.CannedPineapple;Base.CannedPotato2;Base.TinnedSoup;Base.CannedTomato2;Base.TunaTin;Base.Dogfood;VFX.CannedSavoryMince;VFX.CannedBeefRavioli;VFX.CannedSpinachRavioli;VFX.CannedMushroomRavioli;VFX.CannedSpaghettiAndMeatballs;VFX.CannedSpaghetti;VFX.CannedSloppyJoe;VFX.CannedMeatloaf;VFX.CannedVegetarianChili;VFX.CannedRedBeansAndRice;VFX.CannedClamChowder;VFX.CannedBroccoliCheddarSoup;VFX.CannedChickenNoodleSoup;VFX.CannedFrenchOnionSoup;VFX.CannedLaksaNoodleSoup;VFX.CannedLentilSoup;VFX.CannedMinestroneSoup;VFX.CannedPeaHamSoup;VFX.CannedPotatoLeekSoup;VFX.CannedPumpkinSoup;VFX.CannedTomatoSoup;VFX.CannedBeefMushroomStew;VFX.CannedPepperSteakStew;VFX.CannedIrishStew;VFX.CannedSteakOnionStew;VFX.CannedChiliBeanStew;VFX.CannedVegetableStew;VFX.CannedBlackBeans;VFX.CannedChickpeas;VFX.CannedKidneyBeans;VFX.CannedLentils;VFX.CannedWhiteBeans;VFX.CannedThreeBeanMix;VFX.CannedSlicedMushroom;VFX.CannedEdamameBeans;VFX.CannedMixedVegetableMedley;VFX.CannedGreenBeans;VFX.CannedSpinach;VFX.CannedPassionfruit;VFX.CannedAppleSlices;VFX.CannedPearSlices;VFX.CannedMangoSlices;VFX.CannedLychees;VFX.CannedApricots;VFX.CannedHam;VFX.CannedSalmon;VFX.CannedAnchovies;VFX.CannedCatFood;VFX.CannedChicken;VFX.CannedPumpkinPuree;VFX.CannedCreamCorn;VFX.CannedApplePieFilling;VFX.CannedCherryPieFilling;VFX.CannedBlueberryPieFilling;VFX.CannedStrawberryPieFilling;VFX.CannedPeachPieFilling;VFX.CannedMixedBerryPieFilling;VFX.CannedLemonCreamPieFilling;VFX.CannedBlackberryPieFilling;VFX.CannedRaspberryPieFilling;VFX.CannedCoconutMilk;VFX.CannedCoconutCream] mappers[canSorts] flags[Prop2;DontPutBack],
        ]]
        },

        ["OpenCannedFoodWithKnifeOrSharpStoneFlake"] = {
            inputs = [[
            item 1 tags[base:sharpknife] mode:keep flags[MayDegrade;IsNotDull],
            item 1 [Base.TinnedBeans;Base.CannedBolognese;Base.CannedCarrots2;Base.CannedChili;Base.CannedCorn;Base.CannedFruitCocktail;Base.CannedFruitBeverage;Base.CannedMilk;Base.CannedMushroomSoup;Base.CannedPeaches;Base.CannedPeas;Base.CannedPineapple;Base.CannedPotato2;Base.TinnedSoup;Base.CannedTomato2;Base.TunaTin;Base.Dogfood;VFX.CannedSavoryMince;VFX.CannedBeefRavioli;VFX.CannedSpinachRavioli;VFX.CannedMushroomRavioli;VFX.CannedSpaghettiAndMeatballs;VFX.CannedSpaghetti;VFX.CannedSloppyJoe;VFX.CannedMeatloaf;VFX.CannedVegetarianChili;VFX.CannedRedBeansAndRice;VFX.CannedClamChowder;VFX.CannedBroccoliCheddarSoup;VFX.CannedChickenNoodleSoup;VFX.CannedFrenchOnionSoup;VFX.CannedLaksaNoodleSoup;VFX.CannedLentilSoup;VFX.CannedMinestroneSoup;VFX.CannedPeaHamSoup;VFX.CannedPotatoLeekSoup;VFX.CannedPumpkinSoup;VFX.CannedTomatoSoup;VFX.CannedBeefMushroomStew;VFX.CannedPepperSteakStew;VFX.CannedIrishStew;VFX.CannedSteakOnionStew;VFX.CannedChiliBeanStew;VFX.CannedVegetableStew;VFX.CannedBlackBeans;VFX.CannedChickpeas;VFX.CannedKidneyBeans;VFX.CannedLentils;VFX.CannedWhiteBeans;VFX.CannedThreeBeanMix;VFX.CannedSlicedMushroom;VFX.CannedEdamameBeans;VFX.CannedMixedVegetableMedley;VFX.CannedGreenBeans;VFX.CannedSpinach;VFX.CannedPassionfruit;VFX.CannedAppleSlices;VFX.CannedPearSlices;VFX.CannedMangoSlices;VFX.CannedLychees;VFX.CannedApricots;VFX.CannedHam;VFX.CannedSalmon;VFX.CannedAnchovies;VFX.CannedCatFood;VFX.CannedChicken;VFX.CannedPumpkinPuree;VFX.CannedCreamCorn;VFX.CannedApplePieFilling;VFX.CannedCherryPieFilling;VFX.CannedBlueberryPieFilling;VFX.CannedStrawberryPieFilling;VFX.CannedPeachPieFilling;VFX.CannedMixedBerryPieFilling;VFX.CannedLemonCreamPieFilling;VFX.CannedBlackberryPieFilling;VFX.CannedRaspberryPieFilling;VFX.CannedCoconutMilk;VFX.CannedCoconutCream] mappers[foodType] flags[Prop2;DontPutBack],
        ]]
        },

        ["OpenBoxOfCannedFood"] = {
            inputs = [[
            item 1 tags[base:sharpknife] mode:keep flags[MayDegrade;IsNotDull],
            item 1 [Base.Macandcheese_Box;Base.TinnedBeans_Box;Base.CannedBolognese_Box;Base.CannedCarrots_Box;Base.CannedChili_Box;Base.CannedCornedBeef_Box;Base.CannedCorn_Box;Base.CannedFruitCocktail_Box;Base.CannedFruitBeverage_Box;Base.CannedMilk_Box;Base.CannedMushroomSoup_Box;Base.CannedPeaches_Box;Base.CannedPeas_Box;Base.CannedPineapple_Box;Base.CannedPotato_Box;Base.CannedSardines_Box;Base.TinnedSoup_Box;Base.CannedTomato_Box;Base.TunaTin_Box;Base.Dogfood_Box;Base.MysteryCan_Box;Base.DentedCan_Box;Base.WaterRationCan_Box;VFX.CannedSavoryMince_Box;VFX.CannedBeefRavioli_Box;VFX.CannedSpinachRavioli_Box;VFX.CannedMushroomRavioli_Box;VFX.CannedSpaghettiAndMeatballs_Box;VFX.CannedSpaghetti_Box;VFX.CannedSloppyJoe_Box;VFX.CannedMeatloaf_Box;VFX.CannedVegetarianChili_Box;VFX.CannedRedBeansAndRice_Box;VFX.CannedClamChowder_Box;VFX.CannedBroccoliCheddarSoup_Box;VFX.CannedChickenNoodleSoup_Box;VFX.CannedFrenchOnionSoup_Box;VFX.CannedLaksaNoodleSoup_Box;VFX.CannedLentilSoup_Box;VFX.CannedMinestroneSoup_Box;VFX.CannedPeaHamSoup_Box;VFX.CannedPotatoLeekSoup_Box;VFX.CannedPumpkinSoup_Box;VFX.CannedTomatoSoup_Box;VFX.CannedBeefMushroomStew_Box;VFX.CannedPepperSteakStew_Box;VFX.CannedIrishStew_Box;VFX.CannedSteakOnionStew_Box;VFX.CannedChiliBeanStew_Box;VFX.CannedVegetableStew_Box;VFX.CannedBlackBeans_Box;VFX.CannedChickpeas_Box;VFX.CannedKidneyBeans_Box;VFX.CannedLentils_Box;VFX.CannedWhiteBeans_Box;VFX.CannedThreeBeanMix_Box;VFX.CannedSlicedMushroom_Box;VFX.CannedEdamameBeans_Box;VFX.CannedMixedVegetableMedley_Box;VFX.CannedGreenBeans_Box;VFX.CannedSpinach_Box;VFX.CannedPassionfruit_Box;VFX.CannedAppleSlices_Box;VFX.CannedPearSlices_Box;VFX.CannedMangoSlices_Box;VFX.CannedLychees_Box;VFX.CannedApricots_Box;VFX.CannedPumpkinPuree_Box;VFX.CannedCreamCorn_Box;VFX.CannedApplePieFilling_Box;VFX.CannedCherryPieFilling_Box;VFX.CannedBlueberryPieFilling_Box;VFX.CannedStrawberryPieFilling_Box;VFX.CannedPeachPieFilling_Box;VFX.CannedMixedBerryPieFilling_Box;VFX.CannedLemonCreamPieFilling_Box;VFX.CannedBlackberryPieFilling_Box;VFX.CannedRaspberryPieFilling_Box] mappers[canSorts] flags[AllowFavorite;InheritFavorite],
        ]]
        },

        ["PackCannedFood"] = {
            inputs = [[
            item 1 tags[base:sharpknife] mode:keep flags[MayDegrade;IsNotDull],
            item 6 [Base.Macandcheese;Base.TinnedBeans;Base.CannedBolognese;Base.CannedCarrots2;Base.CannedChili;Base.CannedCornedBeef;Base.CannedCorn;Base.CannedFruitCocktail;Base.CannedFruitBeverage;Base.CannedMilk;Base.CannedMushroomSoup;Base.CannedPeaches;Base.CannedPeas;Base.CannedPineapple;Base.CannedPotato2;Base.CannedSardines;Base.TinnedSoup;Base.CannedTomato2;Base.TunaTin;Base.Dogfood;Base.MysteryCan;Base.DentedCan;Base.WaterRationCan;VFX.CannedSavoryMince;VFX.CannedBeefRavioli;VFX.CannedSpinachRavioli;VFX.CannedMushroomRavioli;VFX.CannedSpaghettiAndMeatballs;VFX.CannedSpaghetti;VFX.CannedSloppyJoe;VFX.CannedMeatloaf;VFX.CannedVegetarianChili;VFX.CannedRedBeansAndRice;VFX.CannedClamChowder;VFX.CannedBroccoliCheddarSoup;VFX.CannedChickenNoodleSoup;VFX.CannedFrenchOnionSoup;VFX.CannedLaksaNoodleSoup;VFX.CannedLentilSoup;VFX.CannedMinestroneSoup;VFX.CannedPeaHamSoup;VFX.CannedPotatoLeekSoup;VFX.CannedPumpkinSoup;VFX.CannedTomatoSoup;VFX.CannedBeefMushroomStew;VFX.CannedPepperSteakStew;VFX.CannedIrishStew;VFX.CannedSteakOnionStew;VFX.CannedChiliBeanStew;VFX.CannedVegetableStew;VFX.CannedBlackBeans;VFX.CannedChickpeas;VFX.CannedKidneyBeans;VFX.CannedLentils;VFX.CannedWhiteBeans;VFX.CannedThreeBeanMix;VFX.CannedSlicedMushroom;VFX.CannedEdamameBeans;VFX.CannedMixedVegetableMedley;VFX.CannedGreenBeans;VFX.CannedSpinach;VFX.CannedPassionfruit;VFX.CannedAppleSlices;VFX.CannedPearSlices;VFX.CannedMangoSlices;VFX.CannedLychees;VFX.CannedApricots;VFX.CannedPumpkinPuree;VFX.CannedCreamCorn;VFX.CannedApplePieFilling;VFX.CannedCherryPieFilling;VFX.CannedBlueberryPieFilling;VFX.CannedStrawberryPieFilling;VFX.CannedPeachPieFilling;VFX.CannedMixedBerryPieFilling;VFX.CannedLemonCreamPieFilling;VFX.CannedBlackberryPieFilling;VFX.CannedRaspberryPieFilling] mappers[canSorts] flags[AllowFavorite;InheritFavorite;IsExclusive],
        ]]
        },

        ["MakeJar"] = {
            inputs = [[
            item 1 tags[base:dullknife;base:sharpknife;base:meatcleaver] mode:keep flags[MayDegradeLight],
            item 1 tags[base:jar] mode:destroy flags[ItemCount],
            item 1 [Base.JarLid],
            item 6 [Base.BellPepper;5:Base.Broccoli;2:Base.Cabbage;5:Base.Carrots;3:Base.Eggplant;4:Base.Leek;3:Base.Potato;15:Base.RedRadish;4:Base.Tomato;1:Base.FishRoe;6:VFX.Apricot;6:VFX.Plum;1:VFX.BagGreenBeans;3:VFX.Beetroot;4:Base.Corn;4:Base.Peach;4:Base.Pear;12:Base.Cherry;8:Base.Greenpeas;1:Base.Squash;3:Base.Zucchini;2:Base.SweetPotato;1:Base.BrusselSprouts;1:Base.Pumpkin;4:Base.Onion;10:Base.PepperJalapeno;3:Base.Cucumber;8:Base.Garlic] mappers[veggieType] flags[InheritFood;ItemCount] mode:destroy,
            item 2.0 tags[base:vinegar],
            item 1.0 [Base.Salt;Base.SeasoningSalt],
            item 1 [*],
            -fluid 0.5 [Water],
        ]]
        },

        ["PlaceRiceInSaucepan2"] = {
            inputs = [[
            item 1 [Base.Saucepan;Base.SaucepanCopper] flags[InheritCondition;ItemCount] mappers[saucepanType] mode:destroy,
            -fluid 0.6 categories[Water] mode:mixture,
            item 10 tags[VFX:Rice],
        ]]
        },

        ["PlaceRiceInCookingPot2"] = {
            inputs = [[
            item 1 [Base.Pot;Base.PotForged] mode:destroy flags[InheritCondition;ItemCount] mappers[potType],
            -fluid 1.5 categories[Water] mode:mixture,
            item 10 tags[VFX:Rice],
        ]]
        },

        ["OpenBottleOfBeer"] = {
            inputs = [[
            item 1 tags[base:bottleopener] mode:keep,
            item 1 [Base.BeerBottle;Base.BeerImported;VFX.BottleAmericanLightLager;VFX.BottleAmericanLager;VFX.BottlePilsner;VFX.BottleViennaLager;VFX.BottlePaleAle;VFX.BottleAmberAle;VFX.BottlePorter;VFX.BottleStout;VFX.BottleAmericanWheatBeer] mode:keep flags[DontPutBack;IsSealed;Prop2;Unseal;ItemCount],
        ]]
        },
        
        ["OpenBottleOfWine"] = {
            inputs = [[
            item 1 tags[base:corkscrew] mode:keep,
            item 1 [Base.Wine;Base.Wine2;Base.WineAged;VFX.WineChardonnay;VFX.WineCabernetSauvignon;VFX.WineMerlot;VFX.WinePinotNoir;VFX.WineSauvignonBlanc;VFX.WinePinotGris;VFX.WineRiesling] mode:keep flags[DontPutBack;IsSealed;Prop2;Unseal;ItemCount],
        ]]
        },

        ["OpenPackOfBeer"] = {
            inputs = [[
            item 1 [Base.BeerPack;Base.BeerCanPack;VFX.PackAmericanLightLager;VFX.PackAmericanLager;VFX.PackPilsner;VFX.PackViennaLager;VFX.PackPaleAle;VFX.PackAmberAle;VFX.PackPorter;VFX.PackStout;VFX.PackAmericanWheatBeer;VFX.PackCanAmericanLightLager;VFX.PackCanAmericanLager;VFX.PackCanPilsner;VFX.PackCanViennaLager;VFX.PackCanPaleAle;VFX.PackCanAmberAle;VFX.PackCanPorter;VFX.PackCanStout;VFX.PackCanAmericanWheatBeer] mappers[itemType] flags[AllowFavorite;InheritFavorite],
        ]]
        },

        ["OpenBagOfFrozenFood"] = {
            inputs = [[
            item 1 [Base.Frozen_ChickenNuggets;Base.Frozen_FishFingers;Base.Frozen_FrenchFries;Base.Frozen_TatoDots;VFX.BagHashbrowns;VFX.BagWedges;VFX.BagOnionRings;VFX.BagChickenTenders;VFX.BagMozzarellaSticks] flags[AllowFrozenItem;InheritFoodAge;InheritFreezingTime;AllowRottenItem] mappers[foodType],
            ]]
        },
    }

    for recipeName, recipeDef in pairs(recipeList) do
        local recipe = getScriptManager():getCraftRecipe(recipeName)

        if recipe then
            local wrappedScript = "{"

            if recipeDef.inputs then
                recipe:getInputs():clear()
                wrappedScript = wrappedScript .. " inputs { " .. recipeDef.inputs .. " }"
            end

            if recipeDef.outputs then
                recipe:getOutputs():clear()
                wrappedScript = wrappedScript .. " outputs { " .. recipeDef.outputs .. " }"
            end

            wrappedScript = wrappedScript .. " }"

            recipe:Load(recipeName, wrappedScript)
        end
    end
end

local function EditRecipesSafe()
    if FadedFeastcraft and FadedFeastcraft.DistributionSafety then
        FadedFeastcraft.DistributionSafety.run("VFX.EditRecipes", EditRecipes)
        return
    end
    EditRecipes()
end

Events.OnInitWorld.Add(EditRecipesSafe)
