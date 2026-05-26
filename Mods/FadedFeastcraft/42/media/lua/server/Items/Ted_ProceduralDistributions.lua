require "FadedFeastcraft/FFC_DistributionSafety"

if FadedFeastcraft and FadedFeastcraft.DistributionSafety then
    FadedFeastcraft.DistributionSafety.installProceduralFallback()
end

-- Ted Mod - TedDistributions.lua
-- Pune in: Ted/media/lua/server/Items/TedDistributions.lua

 function Ted_ProceduralDistributions()

    local burgerMult  = SandboxVars.TedBurgerSpawnRate             or 1.0
    local drinkMult   = SandboxVars.TedDrinkSpawnRate              or 1.0
    local alcoholMult = SandboxVars.TedAlcoholicBeveragesSpawnRate or 1.0
    local cannedMult  = SandboxVars.TedCannedSpawnRate             or 1.0
    local snackMult   = SandboxVars.TedSnacksSpawnRate             or 1.0
    local enableRat   = SandboxVars.EnableRatBurger

    -- ==========================================
    -- BURGERS
    -- ==========================================
    local burgerKitchen = ProceduralDistributions.list["BurgerKitchenFridge"].items
    table.insert(burgerKitchen, "Ted.Cheese Burger");            table.insert(burgerKitchen, 10 * burgerMult);
    table.insert(burgerKitchen, "Ted.BBQ Burger");               table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Bacon Burger");             table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Veggie Burger");            table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Ham Burger");               table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Grilled Cheese Burger");    table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Onion Burger");             table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Smash Burger");             table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Salmon Burger");            table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Butter Burger");            table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Paneer Tikka Burger");      table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chori Burger");             table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Green Chili Cheeseburger"); table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Australian Burger");        table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Islak Burger");             table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.BaconCheeseburger");        table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Bofsandwich");              table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.Angus Burger");             table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chili Burger");             table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chimichurri Burger");       table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chicken Shawarma");         table.insert(burgerKitchen, 10 * burgerMult);
    table.insert(burgerKitchen, "Ted.Beef Shawarma");            table.insert(burgerKitchen, 10 * burgerMult);
    if enableRat then
        table.insert(burgerKitchen, "Ted.Rat Burger");           table.insert(burgerKitchen, 1  * burgerMult);
    end

    local burgerKitchen = ProceduralDistributions.list["BurgerKitchenButcher"].items
    table.insert(burgerKitchen, "Ted.Cheese Burger");            table.insert(burgerKitchen, 10 * burgerMult);
    table.insert(burgerKitchen, "Ted.BBQ Burger");               table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Bacon Burger");             table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Veggie Burger");            table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Ham Burger");               table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Grilled Cheese Burger");    table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Onion Burger");             table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Smash Burger");             table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Salmon Burger");            table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Butter Burger");            table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Paneer Tikka Burger");      table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chori Burger");             table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Green Chili Cheeseburger"); table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Australian Burger");        table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Islak Burger");             table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.BaconCheeseburger");        table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Bofsandwich");              table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.Angus Burger");             table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chili Burger");             table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chimichurri Burger");       table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chicken Shawarma");         table.insert(burgerKitchen, 10 * burgerMult);
    table.insert(burgerKitchen, "Ted.Beef Shawarma");            table.insert(burgerKitchen, 10 * burgerMult);
    if enableRat then
        table.insert(burgerKitchen, "Ted.Rat Burger");           table.insert(burgerKitchen, 1  * burgerMult);
    end

    local burgerKitchen = ProceduralDistributions.list["BurgerKitchenFreezer"].items
    table.insert(burgerKitchen, "Ted.Cheese Burger");            table.insert(burgerKitchen, 10 * burgerMult);
    table.insert(burgerKitchen, "Ted.BBQ Burger");               table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Bacon Burger");             table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Veggie Burger");            table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Ham Burger");               table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Grilled Cheese Burger");    table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Onion Burger");             table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Smash Burger");             table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Salmon Burger");            table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Butter Burger");            table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Paneer Tikka Burger");      table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chori Burger");             table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Green Chili Cheeseburger"); table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Australian Burger");        table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Islak Burger");             table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.BaconCheeseburger");        table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Bofsandwich");              table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.Angus Burger");             table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chili Burger");             table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chimichurri Burger");       table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chicken Shawarma");         table.insert(burgerKitchen, 10 * burgerMult);
    table.insert(burgerKitchen, "Ted.Beef Shawarma");            table.insert(burgerKitchen, 10 * burgerMult);
    if enableRat then
        table.insert(burgerKitchen, "Ted.Rat Burger");           table.insert(burgerKitchen, 1  * burgerMult);
    end

    local burgerKitchen = ProceduralDistributions.list["ServingTrayBurgers"].items
    table.insert(burgerKitchen, "Ted.Cheese Burger");            table.insert(burgerKitchen, 10 * burgerMult);
    table.insert(burgerKitchen, "Ted.BBQ Burger");               table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Bacon Burger");             table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Veggie Burger");            table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Ham Burger");               table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Grilled Cheese Burger");    table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Onion Burger");             table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Smash Burger");             table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Salmon Burger");            table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Butter Burger");            table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Paneer Tikka Burger");      table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chori Burger");             table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Green Chili Cheeseburger"); table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Australian Burger");        table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Islak Burger");             table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.BaconCheeseburger");        table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Bofsandwich");              table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.Angus Burger");             table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chili Burger");             table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chimichurri Burger");       table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chicken Shawarma");         table.insert(burgerKitchen, 10 * burgerMult);
    table.insert(burgerKitchen, "Ted.Beef Shawarma");            table.insert(burgerKitchen, 10 * burgerMult);
    if enableRat then
        table.insert(burgerKitchen, "Ted.Rat Burger");           table.insert(burgerKitchen, 1  * burgerMult);
    end

    local burgerKitchen = ProceduralDistributions.list["DinerKitchenFridge"].items
    table.insert(burgerKitchen, "Ted.Cheese Burger");            table.insert(burgerKitchen, 10 * burgerMult);
    table.insert(burgerKitchen, "Ted.BBQ Burger");               table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Bacon Burger");             table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Veggie Burger");            table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Ham Burger");               table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Grilled Cheese Burger");    table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Onion Burger");             table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Smash Burger");             table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Salmon Burger");            table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Butter Burger");            table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Paneer Tikka Burger");      table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chori Burger");             table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Green Chili Cheeseburger"); table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Australian Burger");        table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Islak Burger");             table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.BaconCheeseburger");        table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Bofsandwich");              table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.Angus Burger");             table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chili Burger");             table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chimichurri Burger");       table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chicken Shawarma");         table.insert(burgerKitchen, 10 * burgerMult);
    table.insert(burgerKitchen, "Ted.Beef Shawarma");            table.insert(burgerKitchen, 10 * burgerMult);
    if enableRat then
        table.insert(burgerKitchen, "Ted.Rat Burger");           table.insert(burgerKitchen, 1  * burgerMult);
    end

    local burgerKitchen = ProceduralDistributions.list["MotelFridge"].items
    table.insert(burgerKitchen, "Ted.Cheese Burger");            table.insert(burgerKitchen, 10 * burgerMult);
    table.insert(burgerKitchen, "Ted.BBQ Burger");               table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Bacon Burger");             table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Veggie Burger");            table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Ham Burger");               table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Grilled Cheese Burger");    table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Onion Burger");             table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Smash Burger");             table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Salmon Burger");            table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Butter Burger");            table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Paneer Tikka Burger");      table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chori Burger");             table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Green Chili Cheeseburger"); table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Australian Burger");        table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Islak Burger");             table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.BaconCheeseburger");        table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Bofsandwich");              table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.Angus Burger");             table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chili Burger");             table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chimichurri Burger");       table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chicken Shawarma");         table.insert(burgerKitchen, 10 * burgerMult);
    table.insert(burgerKitchen, "Ted.Beef Shawarma");            table.insert(burgerKitchen, 10 * burgerMult);
    if enableRat then
        table.insert(burgerKitchen, "Ted.Rat Burger");           table.insert(burgerKitchen, 1  * burgerMult);
    end

    local burgerKitchen = ProceduralDistributions.list["RestaurantKitchenFridge"].items
    table.insert(burgerKitchen, "Ted.Cheese Burger");            table.insert(burgerKitchen, 10 * burgerMult);
    table.insert(burgerKitchen, "Ted.BBQ Burger");               table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Bacon Burger");             table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Veggie Burger");            table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Ham Burger");               table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Grilled Cheese Burger");    table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Onion Burger");             table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Smash Burger");             table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Salmon Burger");            table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Butter Burger");            table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Paneer Tikka Burger");      table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chori Burger");             table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Green Chili Cheeseburger"); table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Australian Burger");        table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Islak Burger");             table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.BaconCheeseburger");        table.insert(burgerKitchen, 8  * burgerMult);
    table.insert(burgerKitchen, "Ted.Bofsandwich");              table.insert(burgerKitchen, 4  * burgerMult);
    table.insert(burgerKitchen, "Ted.Angus Burger");             table.insert(burgerKitchen, 6  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chili Burger");             table.insert(burgerKitchen, 7  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chimichurri Burger");       table.insert(burgerKitchen, 5  * burgerMult);
    table.insert(burgerKitchen, "Ted.Chicken Shawarma");         table.insert(burgerKitchen, 10 * burgerMult);
    table.insert(burgerKitchen, "Ted.Beef Shawarma");            table.insert(burgerKitchen, 10 * burgerMult);
    if enableRat then
        table.insert(burgerKitchen, "Ted.Rat Burger");           table.insert(burgerKitchen, 1  * burgerMult);
    end

    -- ==========================================
    -- SNACKS
    -- ==========================================
    local snacks = ProceduralDistributions.list["CandyStoreSnacks"].items
    table.insert(snacks, "Ted.PlantainChips");      table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.Takis");              table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.Funyuns");            table.insert(snacks, 12 * snackMult);
    table.insert(snacks, "Ted.ShrimpCrackers");     table.insert(snacks, 8  * snackMult);
    table.insert(snacks, "Ted.TrailMix");           table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.Knoppers");           table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.KitKat");             table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.Oreo");               table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.DoritosNachoCheese"); table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.DoritosCoolRanch");   table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.DoritosSpicyChili");  table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosSweetChili");  table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosBBQSauce");    table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosTacoFlavor");  table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosSalsaGreen");  table.insert(snacks, 8  * snackMult);
    table.insert(snacks, "Ted.CheetosFlaminHot");   table.insert(snacks, 12 * snackMult);
    table.insert(snacks, "Ted.Pocky");              table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.Haribo");             table.insert(snacks, 12 * snackMult);
    table.insert(snacks, "Ted.Snickers");           table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.Smoki");              table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.BourbonBalls");       table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.CherryGummies");      table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.ColaGummies");        table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.MilkaCherry");        table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.MilkaChocolate");     table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.MilkaWholeHazelnut"); table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.Nutella");            table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.OrbitSweetBliss");    table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.OreoChocolate");      table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.PeachMilk");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.GummyEggs");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysCheese");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysBarbecue");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysSalt");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysSourCream");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysFlaminHot");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysHoney");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysSweetHeatBarbecue");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysPickle");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.NerdsCandy");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitApple");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitBubbleMint");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitStrawberry");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitSweetBliss");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitWinterMint");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacApple");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacFruit");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacOrange");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacSprite");          table.insert(snacks, 5  * snackMult);


    local snacks = ProceduralDistributions.list["FridgeSnacks"].items
    table.insert(snacks, "Ted.PlantainChips");      table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.Takis");              table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.Funyuns");            table.insert(snacks, 12 * snackMult);
    table.insert(snacks, "Ted.ShrimpCrackers");     table.insert(snacks, 8  * snackMult);
    table.insert(snacks, "Ted.TrailMix");           table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.Knoppers");           table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.KitKat");             table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.Oreo");               table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.DoritosNachoCheese"); table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.DoritosCoolRanch");   table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.DoritosSpicyChili");  table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosSweetChili");  table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosBBQSauce");    table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosTacoFlavor");  table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosSalsaGreen");  table.insert(snacks, 8  * snackMult);
    table.insert(snacks, "Ted.CheetosFlaminHot");   table.insert(snacks, 12 * snackMult);
    table.insert(snacks, "Ted.Pocky");              table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.Haribo");             table.insert(snacks, 12 * snackMult);
    table.insert(snacks, "Ted.Snickers");           table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.Smoki");              table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.BourbonBalls");       table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.CherryGummies");      table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.ColaGummies");        table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.MilkaCherry");        table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.MilkaChocolate");     table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.MilkaWholeHazelnut"); table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.Nutella");            table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.OrbitSweetBliss");    table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.OreoChocolate");      table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.PeachMilk");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.GummyEggs");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysCheese");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysBarbecue");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysSalt");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysSourCream");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysFlaminHot");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysHoney");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysSweetHeatBarbecue");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysPickle");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.NerdsCandy");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitApple");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitBubbleMint");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitStrawberry");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitSweetBliss");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitWinterMint");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacApple");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacFruit");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacOrange");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacSprite");          table.insert(snacks, 5  * snackMult);


    local snacks = ProceduralDistributions.list["MotelFridge"].items
    table.insert(snacks, "Ted.PlantainChips");      table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.Takis");              table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.Funyuns");            table.insert(snacks, 12 * snackMult);
    table.insert(snacks, "Ted.ShrimpCrackers");     table.insert(snacks, 8  * snackMult);
    table.insert(snacks, "Ted.TrailMix");           table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.Knoppers");           table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.KitKat");             table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.Oreo");               table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.DoritosNachoCheese"); table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.DoritosCoolRanch");   table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.DoritosSpicyChili");  table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosSweetChili");  table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosBBQSauce");    table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosTacoFlavor");  table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosSalsaGreen");  table.insert(snacks, 8  * snackMult);
    table.insert(snacks, "Ted.CheetosFlaminHot");   table.insert(snacks, 12 * snackMult);
    table.insert(snacks, "Ted.Pocky");              table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.Haribo");             table.insert(snacks, 12 * snackMult);
    table.insert(snacks, "Ted.Snickers");           table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.Smoki");              table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.BourbonBalls");       table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.CherryGummies");      table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.ColaGummies");        table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.MilkaCherry");        table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.MilkaChocolate");     table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.MilkaWholeHazelnut"); table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.Nutella");            table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.OrbitSweetBliss");    table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.OreoChocolate");      table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.PeachMilk");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.GummyEggs");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysCheese");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysBarbecue");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysSalt");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysSourCream");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysFlaminHot");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysHoney");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysSweetHeatBarbecue");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysPickle");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.NerdsCandy");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitApple");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitBubbleMint");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitStrawberry");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitSweetBliss");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitWinterMint");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacApple");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacFruit");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacOrange");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacSprite");          table.insert(snacks, 5  * snackMult);


    local snacks = ProceduralDistributions.list["StoreShelfSnacks"].items
    table.insert(snacks, "Ted.PlantainChips");      table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.Takis");              table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.Funyuns");            table.insert(snacks, 12 * snackMult);
    table.insert(snacks, "Ted.ShrimpCrackers");     table.insert(snacks, 8  * snackMult);
    table.insert(snacks, "Ted.TrailMix");           table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.Knoppers");           table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.KitKat");             table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.Oreo");               table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.DoritosNachoCheese"); table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.DoritosCoolRanch");   table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.DoritosSpicyChili");  table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosSweetChili");  table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosBBQSauce");    table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosTacoFlavor");  table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosSalsaGreen");  table.insert(snacks, 8  * snackMult);
    table.insert(snacks, "Ted.CheetosFlaminHot");   table.insert(snacks, 12 * snackMult);
    table.insert(snacks, "Ted.Pocky");              table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.Haribo");             table.insert(snacks, 12 * snackMult);
    table.insert(snacks, "Ted.Snickers");           table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.Smoki");              table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.BourbonBalls");       table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.CherryGummies");      table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.ColaGummies");        table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.MilkaCherry");        table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.MilkaChocolate");     table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.MilkaWholeHazelnut"); table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.Nutella");            table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.OrbitSweetBliss");    table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.OreoChocolate");      table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.PeachMilk");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.GummyEggs");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysCheese");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysBarbecue");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysSalt");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysSourCream");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysFlaminHot");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysHoney");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysSweetHeatBarbecue");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysPickle");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.NerdsCandy");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitApple");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitBubbleMint");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitStrawberry");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitSweetBliss");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitWinterMint");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacApple");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacFruit");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacOrange");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacSprite");          table.insert(snacks, 5  * snackMult);


    local snacks = ProceduralDistributions.list["WesternKitchenFridge"].items
    table.insert(snacks, "Ted.PlantainChips");      table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.Takis");              table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.Funyuns");            table.insert(snacks, 12 * snackMult);
    table.insert(snacks, "Ted.ShrimpCrackers");     table.insert(snacks, 8  * snackMult);
    table.insert(snacks, "Ted.TrailMix");           table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.Knoppers");           table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.KitKat");             table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.Oreo");               table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.DoritosNachoCheese"); table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.DoritosCoolRanch");   table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.DoritosSpicyChili");  table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosSweetChili");  table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosBBQSauce");    table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosTacoFlavor");  table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.DoritosSalsaGreen");  table.insert(snacks, 8  * snackMult);
    table.insert(snacks, "Ted.CheetosFlaminHot");   table.insert(snacks, 12 * snackMult);
    table.insert(snacks, "Ted.Pocky");              table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.Haribo");             table.insert(snacks, 12 * snackMult);
    table.insert(snacks, "Ted.Snickers");           table.insert(snacks, 15 * snackMult);
    table.insert(snacks, "Ted.Smoki");              table.insert(snacks, 10 * snackMult);
    table.insert(snacks, "Ted.BourbonBalls");       table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.CherryGummies");      table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.ColaGummies");        table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.MilkaCherry");        table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.MilkaChocolate");     table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.MilkaWholeHazelnut"); table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.Nutella");            table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.OrbitSweetBliss");    table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.OreoChocolate");      table.insert(snacks, 5  * snackMult);
    table.insert(snacks, "Ted.PeachMilk");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.GummyEggs");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysCheese");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysBarbecue");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysSalt");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysSourCream");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysFlaminHot");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysHoney");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysSweetHeatBarbecue");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.LaysPickle");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.NerdsCandy");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitApple");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitBubbleMint");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitStrawberry");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitSweetBliss");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.OrbitWinterMint");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacApple");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacFruit");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacOrange");          table.insert(snacks, 5  * snackMult);
	table.insert(snacks, "Ted.TicTacSprite");          table.insert(snacks, 5  * snackMult);

    -- Nutella separat in cafenea
    local snacks = ProceduralDistributions.list["CafeKitchenFridge"].items
    table.insert(snacks, "Ted.Nutella");            table.insert(snacks, 5 * snackMult);

    -- ==========================================
    -- DRINKS
    -- ==========================================
    local drinks = ProceduralDistributions.list["GasStorageCombo"].items
    table.insert(drinks, "Ted.TedsFizzyOrange");    table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.TedCherryBlast");     table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.TedCola");            table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.TedShake");           table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.TedTea");             table.insert(drinks, 8  * drinkMult);
    table.insert(drinks, "Ted.VoltEnergy");         table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.JoltCherry");         table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.MtnLightning");       table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.DrSkipper");          table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.ArizonaTea");         table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.MugRootBeer");        table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.Monster");            table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.RedBull");            table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.MatchaLatte");        table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.IceColdLemonade");    table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.Irn-Bru");            table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.GuaranaAntartica");   table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.ZuzuMilk");           table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.ChocolateMilk");      table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.BananaMilk");         table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.StrawberryMilk");     table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.PeachMilk");          table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.PeachJuice");          table.insert(drinks, 5  * drinkMult);

    local drinks = ProceduralDistributions.list["RestaurantKitchenFridge"].items
    table.insert(drinks, "Ted.TedsFizzyOrange");    table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.TedCherryBlast");     table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.TedCola");            table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.TedShake");           table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.TedTea");             table.insert(drinks, 8  * drinkMult);
    table.insert(drinks, "Ted.VoltEnergy");         table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.JoltCherry");         table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.MtnLightning");       table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.DrSkipper");          table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.ArizonaTea");         table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.MugRootBeer");        table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.Monster");            table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.RedBull");            table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.MatchaLatte");        table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.IceColdLemonade");    table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.Irn-Bru");            table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.GuaranaAntartica");   table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.ZuzuMilk");           table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.ChocolateMilk");      table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.BananaMilk");         table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.StrawberryMilk");     table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.PeachMilk");          table.insert(drinks, 5  * drinkMult);
	table.insert(drinks, "Ted.PeachJuice");          table.insert(drinks, 5  * drinkMult);

    local drinks = ProceduralDistributions.list["SpiffosKitchenFridge"].items
    table.insert(drinks, "Ted.TedsFizzyOrange");    table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.TedCherryBlast");     table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.TedCola");            table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.TedShake");           table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.TedTea");             table.insert(drinks, 8  * drinkMult);
    table.insert(drinks, "Ted.VoltEnergy");         table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.JoltCherry");         table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.MtnLightning");       table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.DrSkipper");          table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.ArizonaTea");         table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.MugRootBeer");        table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.Monster");            table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.RedBull");            table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.MatchaLatte");        table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.IceColdLemonade");    table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.Irn-Bru");            table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.GuaranaAntartica");   table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.ZuzuMilk");           table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.ChocolateMilk");      table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.BananaMilk");         table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.StrawberryMilk");     table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.PeachMilk");          table.insert(drinks, 5  * drinkMult);
	table.insert(drinks, "Ted.PeachJuice");          table.insert(drinks, 5  * drinkMult);

    local drinks = ProceduralDistributions.list["FridgeBottles"].items
    table.insert(drinks, "Ted.TedsFizzyOrange");    table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.TedCherryBlast");     table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.TedCola");            table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.TedShake");           table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.TedTea");             table.insert(drinks, 8  * drinkMult);
    table.insert(drinks, "Ted.VoltEnergy");         table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.JoltCherry");         table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.MtnLightning");       table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.DrSkipper");          table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.ArizonaTea");         table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.MugRootBeer");        table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.Monster");            table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.RedBull");            table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.MatchaLatte");        table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.IceColdLemonade");    table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.Irn-Bru");            table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.GuaranaAntartica");   table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.ZuzuMilk");           table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.ChocolateMilk");      table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.BananaMilk");         table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.StrawberryMilk");     table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.PeachMilk");          table.insert(drinks, 5  * drinkMult);
	table.insert(drinks, "Ted.PeachJuice");          table.insert(drinks, 5  * drinkMult);

    local drinks = ProceduralDistributions.list["FridgeOffice"].items
    table.insert(drinks, "Ted.TedsFizzyOrange");    table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.TedCherryBlast");     table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.TedCola");            table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.TedShake");           table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.TedTea");             table.insert(drinks, 8  * drinkMult);
    table.insert(drinks, "Ted.VoltEnergy");         table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.JoltCherry");         table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.MtnLightning");       table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.DrSkipper");          table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.ArizonaTea");         table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.MugRootBeer");        table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.Monster");            table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.RedBull");            table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.MatchaLatte");        table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.IceColdLemonade");    table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.Irn-Bru");            table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.GuaranaAntartica");   table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.ZuzuMilk");           table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.ChocolateMilk");      table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.BananaMilk");         table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.StrawberryMilk");     table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.PeachMilk");          table.insert(drinks, 5  * drinkMult);
	table.insert(drinks, "Ted.PeachJuice");          table.insert(drinks, 5  * drinkMult);

    local drinks = ProceduralDistributions.list["FridgeSoda"].items
    table.insert(drinks, "Ted.TedsFizzyOrange");    table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.TedCherryBlast");     table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.TedCola");            table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.TedShake");           table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.TedTea");             table.insert(drinks, 8  * drinkMult);
    table.insert(drinks, "Ted.VoltEnergy");         table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.JoltCherry");         table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.MtnLightning");       table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.DrSkipper");          table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.ArizonaTea");         table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.MugRootBeer");        table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.Monster");            table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.RedBull");            table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.MatchaLatte");        table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.IceColdLemonade");    table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.Irn-Bru");            table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.GuaranaAntartica");   table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.ZuzuMilk");           table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.ChocolateMilk");      table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.BananaMilk");         table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.StrawberryMilk");     table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.PeachMilk");          table.insert(drinks, 5  * drinkMult);
	table.insert(drinks, "Ted.PeachJuice");          table.insert(drinks, 5  * drinkMult);

    local drinks = ProceduralDistributions.list["CafeteriaDrinks"].items
    table.insert(drinks, "Ted.TedsFizzyOrange");    table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.TedCherryBlast");     table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.TedCola");            table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.TedShake");           table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.TedTea");             table.insert(drinks, 8  * drinkMult);
    table.insert(drinks, "Ted.VoltEnergy");         table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.JoltCherry");         table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.MtnLightning");       table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.DrSkipper");          table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.ArizonaTea");         table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.MugRootBeer");        table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.Monster");            table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.RedBull");            table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.MatchaLatte");        table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.IceColdLemonade");    table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.Irn-Bru");            table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.GuaranaAntartica");   table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.ZuzuMilk");           table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.ChocolateMilk");      table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.BananaMilk");         table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.StrawberryMilk");     table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.PeachMilk");          table.insert(drinks, 5  * drinkMult);
	table.insert(drinks, "Ted.PeachJuice");          table.insert(drinks, 5  * drinkMult);

    local drinks = ProceduralDistributions.list["StoreShelfDrinks"].items
    table.insert(drinks, "Ted.TedsFizzyOrange");    table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.TedCherryBlast");     table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.TedCola");            table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.TedShake");           table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.TedTea");             table.insert(drinks, 8  * drinkMult);
    table.insert(drinks, "Ted.VoltEnergy");         table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.JoltCherry");         table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.MtnLightning");       table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.DrSkipper");          table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.ArizonaTea");         table.insert(drinks, 12 * drinkMult);
    table.insert(drinks, "Ted.MugRootBeer");        table.insert(drinks, 10 * drinkMult);
    table.insert(drinks, "Ted.Monster");            table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.RedBull");            table.insert(drinks, 15 * drinkMult);
    table.insert(drinks, "Ted.MatchaLatte");        table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.IceColdLemonade");    table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.Irn-Bru");            table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.GuaranaAntartica");   table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.ZuzuMilk");           table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.ChocolateMilk");      table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.BananaMilk");         table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.StrawberryMilk");     table.insert(drinks, 5  * drinkMult);
    table.insert(drinks, "Ted.PeachMilk");          table.insert(drinks, 5  * drinkMult);
	table.insert(drinks, "Ted.PeachJuice");          table.insert(drinks, 5  * drinkMult);

    -- ==========================================
    -- CANNED FOOD
    -- ==========================================
    local canned = ProceduralDistributions.list["GigamartCannedFood"].items
    table.insert(canned, "Ted.CannedCabbageRolls");  table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.CannedSausages");      table.insert(canned, 7  * cannedMult);
    table.insert(canned, "Ted.CannedRavioli");       table.insert(canned, 7  * cannedMult);
    table.insert(canned, "Ted.CannedCurry");         table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.CannedKimchi");        table.insert(canned, 4  * cannedMult);
    table.insert(canned, "Ted.CannedFeijoada");      table.insert(canned, 4  * cannedMult);
    table.insert(canned, "Ted.CannedSpam");          table.insert(canned, 10 * cannedMult);
    table.insert(canned, "Ted.Ovaltine");            table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.PremiumCatFood");      table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.PremiumDogFood");      table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.CannedChickenPate");   table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.CannedDuckPate");      table.insert(canned, 5  * cannedMult);

    local canned = ProceduralDistributions.list["KitchenCannedFood"].items
    table.insert(canned, "Ted.CannedCabbageRolls");  table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.CannedSausages");      table.insert(canned, 7  * cannedMult);
    table.insert(canned, "Ted.CannedRavioli");       table.insert(canned, 7  * cannedMult);
    table.insert(canned, "Ted.CannedCurry");         table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.CannedKimchi");        table.insert(canned, 4  * cannedMult);
    table.insert(canned, "Ted.CannedFeijoada");      table.insert(canned, 4  * cannedMult);
    table.insert(canned, "Ted.CannedSpam");          table.insert(canned, 10 * cannedMult);
    table.insert(canned, "Ted.Ovaltine");            table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.PremiumCatFood");      table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.PremiumDogFood");      table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.CannedChickenPate");   table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.CannedDuckPate");      table.insert(canned, 5  * cannedMult);

    local canned = ProceduralDistributions.list["CrateCannedFood"].items
    table.insert(canned, "Ted.CannedCabbageRolls");  table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.CannedSausages");      table.insert(canned, 7  * cannedMult);
    table.insert(canned, "Ted.CannedRavioli");       table.insert(canned, 7  * cannedMult);
    table.insert(canned, "Ted.CannedCurry");         table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.CannedKimchi");        table.insert(canned, 4  * cannedMult);
    table.insert(canned, "Ted.CannedFeijoada");      table.insert(canned, 4  * cannedMult);
    table.insert(canned, "Ted.CannedSpam");          table.insert(canned, 10 * cannedMult);
    table.insert(canned, "Ted.Ovaltine");            table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.PremiumCatFood");      table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.PremiumDogFood");      table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.CannedChickenPate");   table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.CannedDuckPate");      table.insert(canned, 5  * cannedMult);

    local canned = ProceduralDistributions.list["WesternKitchenFridge"].items
    table.insert(canned, "Ted.CannedCabbageRolls");  table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.CannedSausages");      table.insert(canned, 7  * cannedMult);
    table.insert(canned, "Ted.CannedRavioli");       table.insert(canned, 7  * cannedMult);
    table.insert(canned, "Ted.CannedCurry");         table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.CannedKimchi");        table.insert(canned, 4  * cannedMult);
    table.insert(canned, "Ted.CannedFeijoada");      table.insert(canned, 4  * cannedMult);
    table.insert(canned, "Ted.CannedSpam");          table.insert(canned, 10 * cannedMult);
    table.insert(canned, "Ted.Ovaltine");            table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.PremiumCatFood");      table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.PremiumDogFood");      table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.CannedChickenPate");   table.insert(canned, 5  * cannedMult);
    table.insert(canned, "Ted.CannedDuckPate");      table.insert(canned, 5  * cannedMult);

    -- ==========================================
    -- ALCOHOL
    -- ==========================================
    local alcohol = ProceduralDistributions.list["BarShelfLiquor"].items
    table.insert(alcohol, "Ted.KentuckyGoldWhiskey"); table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Slivovitz");           table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Sake");                table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Noroc");               table.insert(alcohol, 10 * alcoholMult);
    table.insert(alcohol, "Ted.Kvass");               table.insert(alcohol, 10 * alcoholMult);
    table.insert(alcohol, "Ted.Absinthe");            table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Tequila");             table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Ouzo");                table.insert(alcohol, 5  * alcoholMult);

    local alcohol = ProceduralDistributions.list["BinBar"].items
    table.insert(alcohol, "Ted.KentuckyGoldWhiskey"); table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Slivovitz");           table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Sake");                table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Noroc");               table.insert(alcohol, 10 * alcoholMult);
    table.insert(alcohol, "Ted.Kvass");               table.insert(alcohol, 10 * alcoholMult);
    table.insert(alcohol, "Ted.Absinthe");            table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Tequila");             table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Ouzo");                table.insert(alcohol, 5  * alcoholMult);

    local alcohol = ProceduralDistributions.list["BarCratePool"].items
    table.insert(alcohol, "Ted.KentuckyGoldWhiskey"); table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Slivovitz");           table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Sake");                table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Noroc");               table.insert(alcohol, 10 * alcoholMult);
    table.insert(alcohol, "Ted.Kvass");               table.insert(alcohol, 10 * alcoholMult);
    table.insert(alcohol, "Ted.Absinthe");            table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Tequila");             table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Ouzo");                table.insert(alcohol, 5  * alcoholMult);

    local alcohol = ProceduralDistributions.list["SpiffosKitchenFridge"].items
    table.insert(alcohol, "Ted.KentuckyGoldWhiskey"); table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Slivovitz");           table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Sake");                table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Noroc");               table.insert(alcohol, 10 * alcoholMult);
    table.insert(alcohol, "Ted.Kvass");               table.insert(alcohol, 10 * alcoholMult);
    table.insert(alcohol, "Ted.Absinthe");            table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Tequila");             table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Ouzo");                table.insert(alcohol, 5  * alcoholMult);

    local alcohol = ProceduralDistributions.list["WesternKitchenFridge"].items
    table.insert(alcohol, "Ted.KentuckyGoldWhiskey"); table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Slivovitz");           table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Sake");                table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Noroc");               table.insert(alcohol, 10 * alcoholMult);
    table.insert(alcohol, "Ted.Kvass");               table.insert(alcohol, 10 * alcoholMult);
    table.insert(alcohol, "Ted.Absinthe");            table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Tequila");             table.insert(alcohol, 5  * alcoholMult);
    table.insert(alcohol, "Ted.Ouzo");                table.insert(alcohol, 5  * alcoholMult);

end

local function Ted_ProceduralDistributionsSafe()
    if FadedFeastcraft and FadedFeastcraft.DistributionSafety then
        FadedFeastcraft.DistributionSafety.run("TedFoodPack.Ted_ProceduralDistributions", Ted_ProceduralDistributions)
        return
    end
    Ted_ProceduralDistributions()
end

Events.OnPostDistributionMerge.Add(Ted_ProceduralDistributionsSafe)
