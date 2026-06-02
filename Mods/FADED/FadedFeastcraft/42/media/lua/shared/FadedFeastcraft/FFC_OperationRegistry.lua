require "FadedFeastcraft/FFC_Config"
require "FadedFeastcraft/FFC_Utils"
require "FadedFeastcraft/FFC_Branding"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.OperationRegistry = FadedFeastcraft.OperationRegistry or {}

local Registry = FadedFeastcraft.OperationRegistry
local Utils = FadedFeastcraft.Utils
local Branding = FadedFeastcraft.Branding

Registry.static = Registry.static or {}

local function copyList(list)
    local out = {}
    for _, value in ipairs(list or {}) do
        out[#out + 1] = value
    end
    return out
end

local function itemTypeExists(fullType)
    if not fullType or fullType == "" then return false end
    if not getScriptManager then return true end
    local scriptManager = getScriptManager()
    if not scriptManager or not scriptManager.FindItem then return true end
    local ok, result = pcall(function() return scriptManager:FindItem(fullType) end)
    return ok and result ~= nil
end

local function sourceFor(fullType, fallback)
    if FadedFeastcraft.SourcePackRegistry and FadedFeastcraft.SourcePackRegistry.sourceForFullType then
        return Branding.displaySource(FadedFeastcraft.SourcePackRegistry.sourceForFullType(fullType), fallback or "FFC Integrated Pantry")
    end
    return Branding.displaySource(fallback or fullType, "FFC Integrated Pantry")
end

local function operation(inputFullType, id, label, opts)
    opts = opts or {}
    local op = {
        id = id,
        label = label,
        input = inputFullType,
        outputs = copyList(opts.outputs),
        randomOutputs = copyList(opts.randomOutputs),
        emptyCan = opts.emptyCan == true,
        source = Branding.displaySource(opts.source or sourceFor(inputFullType), "FFC Integrated Pantry"),
        toolGroup = opts.toolGroup,
        toolLabel = opts.toolLabel,
        inheritFoodAge = opts.inheritFoodAge == true,
        rejectFrozen = opts.rejectFrozen ~= false,
        rejectRotten = opts.rejectRotten == true,
        rejectBurned = opts.rejectBurned ~= false,
        consumeUse = opts.consumeUse == true,
    }
    Registry.static[inputFullType] = op
    return op
end

local function addSimpleOutput(inputFullType, outputFullType, label, opts)
    opts = opts or {}
    opts.outputs = { outputFullType }
    opts.source = opts.source or sourceFor(inputFullType)
    return operation(inputFullType, "convert:" .. inputFullType, label or "Prepare", opts)
end

local function addMultiOutput(inputFullType, outputEntries, label, opts)
    opts = opts or {}
    opts.outputs = {}
    for _, entry in ipairs(outputEntries or {}) do
        local count = tonumber(entry.count) or 1
        for _ = 1, count do
            opts.outputs[#opts.outputs + 1] = entry.fullType
        end
    end
    opts.source = opts.source or sourceFor(inputFullType)
    return operation(inputFullType, "convert:" .. inputFullType, label or "Prepare", opts)
end

local function addCan(inputFullType, outputFullType, opts)
    opts = opts or {}
    opts.toolGroup = opts.toolGroup or "can_or_sharp"
    opts.toolLabel = opts.toolLabel or "Can opener or sharp tool"
    opts.emptyCan = opts.emptyCan ~= false
    return addSimpleOutput(inputFullType, outputFullType, opts.label or "Open can", opts)
end

local function addUnpack(inputFullType, outputFullType, opts)
    opts = opts or {}
    opts.rejectFrozen = opts.rejectFrozen ~= false
    opts.rejectBurned = opts.rejectBurned ~= false
    return addSimpleOutput(inputFullType, outputFullType, opts.label or "Unpack serving", opts)
end

local function addSnack(inputName, outputName)
    addUnpack("SnackTime89." .. inputName, "SnackTime89." .. outputName, {
        source = "FFC Snack Shelf",
        label = "Unpack snack",
        rejectRotten = false,
        consumeUse = true,
    })
end

local function outputsFor(fullType, count, extras)
    local out = {}
    for _ = 1, tonumber(count) or 1 do
        out[#out + 1] = fullType
    end
    for _, extra in ipairs(extras or {}) do
        for _ = 1, tonumber(extra.count) or 1 do
            out[#out + 1] = extra.fullType
        end
    end
    return out
end

local function outputsExist(outputs)
    for _, fullType in ipairs(outputs or {}) do
        if not itemTypeExists(fullType) then return false end
    end
    return true
end

local function addMappedOperation(inputFullType, outputFullType, label, opts)
    opts = opts or {}
    local outputs = outputsFor(outputFullType, opts.outputCount or 1, opts.extraOutputs)
    return operation(inputFullType, "recipe:" .. inputFullType .. ":" .. tostring(outputFullType), label or "Prepare", {
        outputs = outputs,
        source = opts.source or sourceFor(inputFullType),
        toolGroup = opts.toolGroup,
        toolLabel = opts.toolLabel,
        rejectFrozen = opts.rejectFrozen,
        rejectRotten = opts.rejectRotten,
        rejectBurned = opts.rejectBurned,
        inheritFoodAge = opts.inheritFoodAge,
        consumeUse = opts.consumeUse,
    })
end

local function addMappedOperations(map, label, opts)
    for inputFullType, outputFullType in pairs(map or {}) do
        addMappedOperation(inputFullType, outputFullType, label, opts)
    end
end

local function installStaticOperations()
    if Registry.installed then return end
    Registry.installed = true

    operation("DriedFoodMod.FDriedFoodCan", "open_random:DriedFoodMod.FDriedFoodCan", "Open dried food can", {
        source = "FFC Dry Storage",
        randomOutputs = {
            "DriedFoodMod.FDriedSteak",
            "DriedFoodMod.FDriedChicken",
            "DriedFoodMod.FDriedPorkChop",
        },
        toolGroup = "can_or_sharp",
        toolLabel = "Can opener or sharp tool",
        emptyCan = true,
        rejectRotten = false,
    })

    addSnack("ST_ChupaChups", "ST_Lollipop")
    addSnack("ST_LUPetitEcolier", "ST_BiscuitEcolier")
    addSnack("ST_BNChocolat", "ST_BiscuitBNC")
    addSnack("ST_BNFraise", "ST_BiscuitBNF")
    addSnack("ST_Oreo", "ST_BiscuitOreo")
    addSnack("ST_TucNature", "ST_BiscuitTUC")
    addSnack("ST_TucBacon", "ST_BiscuitTUCB")
    addSnack("ST_Mikado", "ST_BatonMikado")
    addSnack("ST_MentosFruit", "ST_MentosCapsF")
    addSnack("ST_MentosMint", "ST_MentosCaps")
    addSnack("ST_BenenutsCG", "ST_BenenutsC")
    addSnack("ST_BenenutsNC", "ST_BenenutsN")
    addSnack("ST_Bretzels", "ST_BretzelsP")
    addSnack("ST_HariboCroco", "ST_HariboC")
    addSnack("ST_HariboCola", "ST_HariboCo")
    addSnack("ST_HariboOurs", "ST_HariboO")
    addSnack("ST_HariboTagada", "ST_HariboF")
    addSnack("ST_HariboSchtroumpfs", "ST_HariboSc")
    addSnack("ST_HariboDragibus", "ST_HariboD")
    addSnack("ST_HariboMix", "ST_HariboM")
    addSnack("ST_Maltesers", "ST_MaltesersB")
    addSnack("ST_MMs", "ST_MM")
    addSnack("ST_Skittles", "ST_SkittlesG")
    addSnack("ST_ChipsahoyO", "ST_ChipsahoyOriginal")
    addSnack("ST_ChipsahoyC", "ST_ChipsahoyChewy")

    addMultiOutput("AbuelitaLinda.CocadaSmall", { { fullType = "AbuelitaLinda.CocadaBall", count = 10 } }, "Open package", { source = "FFC Cocina Pantry" })
    addMultiOutput("AbuelitaLinda.CocadaBig", { { fullType = "AbuelitaLinda.CocadaSingle", count = 6 } }, "Open package", { source = "FFC Cocina Pantry" })
    addMultiOutput("AbuelitaLinda.ObleasCajetaBag", { { fullType = "AbuelitaLinda.ObleasCajeta", count = 8 } }, "Open package", { source = "FFC Cocina Pantry" })
    addMultiOutput("AbuelitaLinda.DulceTamarindo", { { fullType = "AbuelitaLinda.DulceTamarindoSingle", count = 10 } }, "Open package", { source = "FFC Cocina Pantry" })
    addMultiOutput("AbuelitaLinda.GloriaBag", { { fullType = "AbuelitaLinda.Gloria", count = 10 } }, "Open package", { source = "FFC Cocina Pantry" })

    addMultiOutput("Base.CanOfBellPeppers", { { fullType = "Base.BellPepper", count = 12 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfBroccolis", { { fullType = "Base.Broccoli", count = 11 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfCabbages", { { fullType = "Base.Cabbage", count = 8 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfCarrots", { { fullType = "Base.Carrots", count = 12 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfEggplants", { { fullType = "Base.Eggplant", count = 6 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfLeeks", { { fullType = "Base.Leek", count = 8 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfPotatoes", { { fullType = "Base.Potato", count = 5 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfRadishes", { { fullType = "Base.RedRadish", count = 33 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfTomatoes", { { fullType = "Base.Tomato", count = 8 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfCauliflowers", { { fullType = "Base.Cauliflower", count = 11 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfCorns", { { fullType = "Base.Corn", count = 7 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfCucumbers", { { fullType = "Base.Cucumber", count = 10 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfKales", { { fullType = "Base.Kale", count = 12 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfSpinaches", { { fullType = "Base.Spinach", count = 10 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfSweetPotatoes", { { fullType = "Base.SweetPotato", count = 5 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfTurnips", { { fullType = "Base.Turnip", count = 5 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfZucchinis", { { fullType = "Base.Zucchini", count = 10 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfOnions", { { fullType = "Base.Onion", count = 20 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })
    addMultiOutput("Base.CanOfSoybeans", { { fullType = "Base.Soybeans", count = 20 }, { fullType = "Base.EmptyJar", count = 1 } }, "Open preserved jar", { source = "FFC Jarred Pantry", rejectRotten = true, inheritFoodAge = true })

    addCan("Base.TinnedBeans", "Base.OpenBeans", { source = "FFC Vanilla Pantry" })
    addCan("Base.CannedBolognese", "Base.CannedBologneseOpen", { source = "FFC Vanilla Pantry" })
    addCan("Base.CannedCarrots2", "Base.CannedCarrotsOpen", { source = "FFC Vanilla Pantry" })
    addCan("Base.CannedChili", "Base.CannedChiliOpen", { source = "FFC Vanilla Pantry" })
    addCan("Base.CannedCornedBeef", "Base.CannedCornedBeefOpen", { source = "FFC Vanilla Pantry" })
    addCan("Base.CannedCorn", "Base.CannedCornOpen", { source = "FFC Vanilla Pantry" })
    addCan("Base.CannedFruitCocktail", "Base.CannedFruitCocktailOpen", { source = "FFC Vanilla Pantry" })
    addCan("Base.CannedFruitBeverage", "Base.CannedFruitBeverageOpen", { source = "FFC Vanilla Pantry" })
    addCan("Base.CannedMilk", "Base.CannedMilkOpen", { source = "FFC Vanilla Pantry" })
    addCan("Base.CannedMushroomSoup", "Base.CannedMushroomSoupOpen", { source = "FFC Vanilla Pantry" })
    addCan("Base.CannedPeaches", "Base.CannedPeachesOpen", { source = "FFC Vanilla Pantry" })
    addCan("Base.CannedPeas", "Base.CannedPeasOpen", { source = "FFC Vanilla Pantry" })
    addCan("Base.CannedPineapple", "Base.CannedPineappleOpen", { source = "FFC Vanilla Pantry" })
    addCan("Base.CannedPotato2", "Base.CannedPotatoOpen", { source = "FFC Vanilla Pantry" })
    addCan("Base.TinnedSoup", "Base.TinnedSoupOpen", { source = "FFC Vanilla Pantry" })
    addCan("Base.CannedTomato2", "Base.CannedTomatoOpen", { source = "FFC Vanilla Pantry" })
    addCan("Base.TunaTin", "Base.TunaTinOpen", { source = "FFC Vanilla Pantry" })
    addCan("Base.Dogfood", "Base.DogfoodOpen", { source = "FFC Vanilla Pantry" })

    addMappedOperations({
        ["VFX.CannedWorms"] = "Base.Worm",
        ["VFX.CannedSnails"] = "Base.Snail",
        ["VFX.CannedCrickets"] = "Base.Cricket",
    }, "Open insect can", { source = "FFC Expanded Pantry", outputCount = 6, extraOutputs = { { fullType = "VFX.SmallTinCanEmpty" } }, rejectFrozen = true, rejectBurned = true })

    addMappedOperations({
        ["VFX.JarBlackOlives"] = "VFX.JarBlackOlivesOpen",
        ["VFX.JarGreenOlives"] = "VFX.JarGreenOlivesOpen",
        ["VFX.JarSundriedTomatoes"] = "VFX.JarSundriedTomatoesOpen",
        ["VFX.JarPickledPeppers"] = "VFX.JarPickledPeppersOpen",
        ["VFX.JarPickledEggs"] = "VFX.JarPickledEggsOpen",
    }, "Open jar", { source = "FFC Expanded Pantry", extraOutputs = { { fullType = "Base.JarLid" } }, rejectFrozen = true, rejectBurned = true, inheritFoodAge = true })
    addMappedOperation("VFX.JarPickles", "VFX.JarPickleJuiceOpen", "Open pickle jar", { source = "FFC Expanded Pantry", extraOutputs = { { fullType = "Base.Pickles", count = 5 } }, rejectFrozen = true, rejectBurned = true, inheritFoodAge = true })

    addMappedOperations({
        ["VFX.BoxPumpkinSoupSachets"] = "VFX.PumpkinSoupSachet",
        ["VFX.BoxPeaAndHamSoupSachets"] = "VFX.PeaAndHamSoupSachet",
        ["VFX.BoxChickenNoodleSoupSachets"] = "VFX.ChickenNoodleSoupSachet",
        ["VFX.BoxTomatoSoupSachets"] = "VFX.TomatoSoupSachet",
    }, "Open soup box", { source = "FFC Expanded Pantry", outputCount = 4, rejectFrozen = true })

    addMappedOperations({
        ["VFX.BoxChickenRamen"] = "VFX.ChickenRamen",
        ["VFX.BoxBeefRamen"] = "VFX.BeefRamen",
        ["VFX.BoxShrimpRamen"] = "VFX.ShrimpRamen",
        ["VFX.BoxPorkRamen"] = "VFX.PorkRamen",
        ["VFX.BoxHotAndSpicyRamen"] = "VFX.HotAndSpicyRamen",
        ["VFX.BoxSoySauceRamen"] = "VFX.SoySauceRamen",
    }, "Open ramen box", { source = "FFC Expanded Pantry", outputCount = 5, rejectFrozen = true })
    addMappedOperations({
        ["VFX.ChickenRamen"] = "VFX.ChickenRamenFlavourSachet",
        ["VFX.BeefRamen"] = "VFX.BeefRamenFlavourSachet",
        ["VFX.ShrimpRamen"] = "VFX.ShrimpRamenFlavourSachet",
        ["VFX.PorkRamen"] = "VFX.PorkRamenFlavourSachet",
        ["VFX.HotAndSpicyRamen"] = "VFX.HotAndSpicyRamenFlavourSachet",
        ["VFX.SoySauceRamen"] = "VFX.SoySauceRamenFlavourSachet",
    }, "Open ramen packet", { source = "FFC Expanded Pantry", extraOutputs = { { fullType = "Base.Ramen" } }, rejectFrozen = true })

    addMappedOperations({
        ["VFX.ZebraCakesBox"] = "VFX.ZebraCake",
        ["VFX.SwissRollsBox"] = "VFX.SwissRoll",
        ["VFX.FudgeRoundsBox"] = "VFX.FudgeRound",
        ["VFX.CoffeeCakesBox"] = "VFX.CoffeeCake",
        ["VFX.CosmicBrowniesBox"] = "VFX.CosmicBrownie",
        ["VFX.OatmealCremePiesBox"] = "VFX.OatmealCremePie",
        ["VFX.StrawberryStrudelsBox"] = "VFX.PackagedStrawberryStrudel",
        ["VFX.CherryStrudelsBox"] = "VFX.PackagedCherryStrudel",
        ["VFX.BlueberryStrudelsBox"] = "VFX.PackagedBlueberryStrudel",
        ["VFX.CookiesAndCreamStrudelsBox"] = "VFX.PackagedCookiesAndCreamStrudel",
        ["VFX.BrownSugarStrudelsBox"] = "VFX.PackagedBrownSugarStrudel",
        ["VFX.AlmondGranolaBarBox"] = "VFX.AlmondGranolaBar",
        ["VFX.ChocolateChipGranolaBarBox"] = "VFX.ChocolateChipGranolaBar",
        ["VFX.NuttyGranolaBarBox"] = "VFX.NuttyGranolaBar",
        ["VFX.OatGranolaBarBox"] = "VFX.OatGranolaBar",
        ["VFX.PeanutButterGranolaBarBox"] = "Base.GranolaBar",
    }, "Open snack box", { source = "FFC Expanded Pantry", outputCount = 5, rejectFrozen = true })
    addMappedOperations({
        ["VFX.PackagedStrawberryStrudel"] = "VFX.StrawberryToasterStrudel",
        ["VFX.PackagedCherryStrudel"] = "VFX.CherryToasterStrudel",
        ["VFX.PackagedBlueberryStrudel"] = "VFX.BlueberryToasterStrudel",
        ["VFX.PackagedCookiesAndCreamStrudel"] = "VFX.CookiesAndCreamToasterStrudel",
        ["VFX.PackagedBrownSugarStrudel"] = "VFX.BrownSugarToasterStrudel",
    }, "Open packaged strudel", { source = "FFC Expanded Pantry", rejectFrozen = true, inheritFoodAge = true })

    addMappedOperations({
        ["VFX.ChocolatePuddingBox"] = "VFX.ChocolatePuddingCup",
        ["VFX.VanillaPuddingBox"] = "VFX.VanillaPuddingCup",
        ["VFX.CustardPuddingBox"] = "VFX.CustardPuddingCup",
        ["VFX.StrawberryPuddingBox"] = "VFX.StrawberryPuddingCup",
        ["VFX.BananaCreamPuddingBox"] = "VFX.BananaCreamPuddingCup",
        ["VFX.StrawberryJelloBox"] = "VFX.StrawberryJelloCup",
        ["VFX.LemonLimeJelloBox"] = "VFX.LemonLimeJelloCup",
        ["VFX.OrangeJelloBox"] = "VFX.OrangeJelloCup",
        ["VFX.CherryJelloBox"] = "VFX.CherryJelloCup",
        ["VFX.PineappleJelloBox"] = "VFX.PineappleJelloCup",
        ["VFX.BerryBlueJelloBox"] = "VFX.BerryBlueJelloCup",
        ["VFX.RaspberryJelloBox"] = "VFX.RaspberryJelloCup",
        ["VFX.LimeJelloBox"] = "VFX.LimeJelloCup",
        ["VFX.PeachJelloBox"] = "VFX.PeachJelloCup",
        ["VFX.GrapeJelloBox"] = "VFX.GrapeJelloCup",
        ["VFX.LemonJelloBox"] = "VFX.LemonJelloCup",
    }, "Open dessert box", { source = "FFC Expanded Pantry", outputCount = 4, rejectFrozen = true })

    addMappedOperations({
        ["VFX.PBJUncrustable_Box"] = "VFX.PBJUncrustable",
        ["VFX.PBFUncrustable_Box"] = "VFX.PBFUncrustable",
        ["VFX.CSUncrustable_Box"] = "VFX.CSUncrustable",
        ["VFX.CHUncrustable_Box"] = "VFX.CHUncrustable",
    }, "Open frozen sandwich box", { source = "FFC Expanded Pantry", outputCount = 5, rejectFrozen = false, inheritFoodAge = true })
    addMappedOperations({
        ["VFX.CheesePizzaRoll_Box"] = "VFX.CheesePizzaRoll",
        ["VFX.PepperoniPizzaRoll_Box"] = "VFX.PepperoniPizzaRoll",
        ["VFX.SupremePizzaRoll_Box"] = "VFX.SupremePizzaRoll",
        ["VFX.MeatLoversPizzaRoll_Box"] = "VFX.MeatLoversPizzaRoll",
        ["VFX.SECBreakfastSandwich_Box"] = "VFX.SECBreakfastSandwich",
        ["VFX.BECBreakfastSandwich_Box"] = "VFX.BECBreakfastSandwich",
        ["VFX.TECBreakfastSandwich_Box"] = "VFX.TECBreakfastSandwich",
        ["VFX.ECBreakfastSandwich_Box"] = "VFX.ECBreakfastSandwich",
    }, "Open frozen meal box", { source = "FFC Expanded Pantry", outputCount = 4, rejectFrozen = false, inheritFoodAge = true })
    addMappedOperations({
        ["VFX.PorkSausagePack"] = "VFX.PorkSausage",
        ["VFX.BeefSausagePack"] = "VFX.BeefSausage",
        ["VFX.BeefPorkSausagePack"] = "VFX.BeefPorkSausage",
        ["VFX.ChickenSausagePack"] = "VFX.ChickenSausage",
        ["VFX.SmokedSausagePack"] = "VFX.SmokedSausage",
        ["VFX.SpicySausagePack"] = "VFX.SpicySausage",
        ["VFX.ChorizoPack"] = "VFX.Chorizo",
        ["VFX.CheeseSausagePack"] = "VFX.CheeseSausage",
    }, "Open sausage pack", { source = "FFC Expanded Pantry", outputCount = 4, rejectFrozen = false, inheritFoodAge = true })
    addMappedOperations({
        ["VFX.BeefMeatballsBag"] = "VFX.BeefMeatball",
        ["VFX.PorkMeatballsBag"] = "VFX.PorkMeatball",
        ["VFX.VealMeatballsBag"] = "VFX.VealMeatball",
        ["VFX.TurkeyMeatballsBag"] = "VFX.TurkeyMeatball",
        ["VFX.ChickenMeatballsBag"] = "VFX.ChickenMeatball",
    }, "Open meatball bag", { source = "FFC Expanded Pantry", outputCount = 12, rejectFrozen = false, inheritFoodAge = true })

    addMappedOperations({
        ["VFX.BagGummyBears"] = "Base.GummyBears",
        ["VFX.BagSourGummyBears"] = "VFX.GummySourBears",
        ["VFX.BagGummyFish"] = "Base.CandyGummyfish",
        ["VFX.BagGummyWorms"] = "Base.GummyWorms",
        ["VFX.BagSourGummyWorms"] = "VFX.GummySourWorms",
        ["VFX.BagPeachRings"] = "VFX.GummyPeachRings",
        ["VFX.BagColaGummies"] = "VFX.GummyCola",
    }, "Open candy bag", { source = "FFC Expanded Pantry", outputCount = 5, rejectFrozen = true })

    addMappedOperations({
        ["Base.OpenBeans"] = "Base.TinnedBeans",
        ["Base.CannedBologneseOpen"] = "Base.CannedBolognese",
        ["Base.CannedCarrotsOpen"] = "Base.CannedCarrots2",
        ["Base.CannedChiliOpen"] = "Base.CannedChili",
        ["Base.CannedCornedBeefOpen"] = "Base.CannedCornedBeef",
        ["Base.CannedCornOpen"] = "Base.CannedCorn",
        ["Base.CannedFruitCocktailOpen"] = "Base.CannedFruitCocktail",
        ["Base.CannedFruitBeverageOpen"] = "Base.CannedFruitBeverage",
        ["Base.CannedMilkOpen"] = "Base.CannedMilk",
        ["Base.CannedMushroomSoupOpen"] = "Base.CannedMushroomSoup",
        ["Base.CannedPeachesOpen"] = "Base.CannedPeaches",
        ["Base.CannedPeasOpen"] = "Base.CannedPeas",
        ["Base.CannedPineappleOpen"] = "Base.CannedPineapple",
        ["Base.CannedPotatoOpen"] = "Base.CannedPotato2",
        ["Base.CannedSardinesOpen"] = "Base.CannedSardines",
        ["Base.TinnedSoupOpen"] = "Base.TinnedSoup",
        ["Base.CannedTomatoOpen"] = "Base.CannedTomato2",
        ["Base.TunaTinOpen"] = "Base.TunaTin",
        ["Base.DogfoodOpen"] = "Base.Dogfood",
        ["ExtraCraft.CannedCarrotsOpen"] = "ExtraCraft.CannedCarrots",
        ["ExtraCraft.CannedTomatosOpen"] = "ExtraCraft.CannedTomatos",
        ["ExtraCraft.CannedPotatosOpen"] = "ExtraCraft.CannedPotatos",
        ["ExtraCraft.CannedPeachesOpen"] = "ExtraCraft.CannedPeaches",
        ["ExtraCraft.CannedPineapplesOpen"] = "ExtraCraft.CannedPineapples",
        ["ExtraCraft.CannedFishFilletOpen"] = "ExtraCraft.CannedFishFillet",
        ["ExtraCraft.CannedBassOpen"] = "ExtraCraft.CannedBass",
        ["ExtraCraft.CannedBluegillOpen"] = "ExtraCraft.CannedBluegill",
        ["ExtraCraft.CannedCatfishOpen"] = "ExtraCraft.CannedCatfish",
        ["ExtraCraft.CannedPerchOpen"] = "ExtraCraft.CannedPerch",
        ["ExtraCraft.CannedSaugerOpen"] = "ExtraCraft.CannedSauger",
        ["ExtraCraft.CannedSunfishOpen"] = "ExtraCraft.CannedSunfish",
        ["ExtraCraft.CannedWalleyeOpen"] = "ExtraCraft.CannedWalleye",
    }, "Seal can", { source = "FFC Canning Bench", toolGroup = "tin_sealer", toolLabel = "Tin sealer", rejectFrozen = true, rejectRotten = true, rejectBurned = true, inheritFoodAge = true })
end

local function endsWith(value, suffix)
    return string.sub(value, -string.len(suffix)) == suffix
end

local function inferredCanOperation(fullType, outputFullType, sourceLabel)
    if not itemTypeExists(outputFullType) then return nil end
    return {
        id = "open_can:" .. fullType,
        label = "Open can",
        input = fullType,
        outputs = { outputFullType },
        emptyCan = true,
        source = Branding.displaySource(sourceLabel or sourceFor(fullType), "FFC Integrated Pantry"),
        toolGroup = "can_or_sharp",
        toolLabel = "Can opener or sharp tool",
        rejectFrozen = true,
        rejectRotten = false,
        rejectBurned = true,
    }
end

local function inferredJarOperation(fullType, outputFullType, sourceLabel)
    if not itemTypeExists(outputFullType) then return nil end
    return {
        id = "open_jar:" .. fullType,
        label = "Open jar",
        input = fullType,
        outputs = { outputFullType },
        emptyCan = false,
        source = Branding.displaySource(sourceLabel or sourceFor(fullType), "FFC Integrated Pantry"),
        rejectFrozen = true,
        rejectRotten = false,
        rejectBurned = true,
    }
end

local BOX_OUTPUT_OVERRIDES = {
    ["Base.CannedCarrots_Box"] = "Base.CannedCarrots2",
    ["Base.CannedPotato_Box"] = "Base.CannedPotato2",
    ["Base.CannedTomato_Box"] = "Base.CannedTomato2",
}

local function repeatedOutputs(outputFullType, count)
    local out = {}
    for _ = 1, tonumber(count) or 1 do
        out[#out + 1] = outputFullType
    end
    return out
end

local function inferredBoxOperation(fullType, outputFullType, sourceLabel, count)
    if not itemTypeExists(outputFullType) then return nil end
    return {
        id = "open_box:" .. fullType,
        label = "Open box",
        input = fullType,
        outputs = repeatedOutputs(outputFullType, count or 6),
        emptyCan = false,
        source = Branding.displaySource(sourceLabel or sourceFor(fullType), "FFC Integrated Pantry"),
        rejectFrozen = true,
        rejectRotten = false,
        rejectBurned = true,
    }
end

function Registry.itemTypeExists(fullType)
    return itemTypeExists(fullType)
end

function Registry.operationForFullType(fullType)
    installStaticOperations()
    fullType = tostring(fullType or "")
    if fullType == "" then return nil end

    local static = Registry.static[fullType]
    if static then return static end

    if endsWith(fullType, "Open") or endsWith(fullType, "_Open") or endsWith(fullType, "_open") then
        return nil
    end

    if string.find(fullType, "^VFX%.Canned") then
        return inferredCanOperation(fullType, fullType .. "Open", "FFC Expanded Pantry")
    end
    if string.find(fullType, "^VFX%.Jar") then
        return inferredJarOperation(fullType, fullType .. "Open", "FFC Expanded Pantry")
    end
    if string.find(fullType, "^ExtraCraft%.Canned") then
        return inferredCanOperation(fullType, fullType .. "Open", "FFC Canning Bench")
    end
    if string.find(fullType, "^Ted%.Canned") then
        return inferredCanOperation(fullType, fullType .. "Open", "FFC Snack Shelf")
    end
    if string.find(fullType, "^MR%.") and (string.find(fullType, "Canned", 1, true) or string.find(fullType, "canned", 1, true)) then
        local openType = fullType .. "_open"
        if itemTypeExists(openType) then
            return inferredCanOperation(fullType, openType, "FFC Field Rations")
        end
        if endsWith(fullType, "_box") then
            return inferredBoxOperation(fullType, string.gsub(fullType, "_box$", ""), "FFC Field Rations", 25)
        end
    end
    if endsWith(fullType, "_Box") then
        local output = BOX_OUTPUT_OVERRIDES[fullType] or string.gsub(fullType, "_Box$", "")
        return inferredBoxOperation(fullType, output, sourceFor(fullType), 6)
    end
    if string.find(fullType, "^Base%.Canned") then
        local direct = fullType .. "Open"
        if itemTypeExists(direct) then
            return inferredCanOperation(fullType, direct, "FFC Vanilla Pantry")
        end
        local noTwo = string.gsub(fullType, "2$", "")
        if noTwo ~= fullType and itemTypeExists(noTwo .. "Open") then
            return inferredCanOperation(fullType, noTwo .. "Open", "FFC Vanilla Pantry")
        end
    end

    return nil
end

function Registry.operationForItem(item)
    return Registry.operationForFullType(Utils.getFullType(item))
end

function Registry.outputPreview(operation)
    if not operation then return "unknown" end
    if operation.randomOutputs and #operation.randomOutputs > 0 then
        return "one of " .. table.concat(operation.randomOutputs, ", ")
    end
    if operation.outputs and #operation.outputs > 0 then
        local order = {}
        local counts = {}
        for _, output in ipairs(operation.outputs) do
            if not counts[output] then
                counts[output] = 0
                order[#order + 1] = output
            end
            counts[output] = counts[output] + 1
        end
        local parts = {}
        for _, output in ipairs(order) do
            local count = counts[output] or 1
            if count > 1 then
                parts[#parts + 1] = tostring(count) .. "x " .. output
            else
                parts[#parts + 1] = output
            end
        end
        return table.concat(parts, ", ")
    end
    return "unknown"
end

function Registry.previewBlockReason(operation, record)
    if not operation or not record then return nil end
    if operation.rejectFrozen and record.frozen then return "Item is frozen. Thaw it before running this FFC operation." end
    if operation.rejectRotten and record.rotten then return "Item is rotten." end
    if operation.rejectBurned and record.burnt then return "Item is burned." end
    return nil
end

function Registry.isBlockedByRecord(operation, record)
    return Registry.previewBlockReason(operation, record) ~= nil
end

function Registry.listStatic()
    installStaticOperations()
    local out = {}
    for _, op in pairs(Registry.static) do
        out[#out + 1] = op
    end
    table.sort(out, function(a, b) return tostring(a.input) < tostring(b.input) end)
    return out
end

installStaticOperations()

return Registry
