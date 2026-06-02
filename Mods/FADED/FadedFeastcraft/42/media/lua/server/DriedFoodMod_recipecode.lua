DriedFoodMod = DriedFoodMod or {}

DriedFoodMod.driedFoodItems = {
    "DriedFoodMod.FDriedSteak",
    "DriedFoodMod.FDriedChicken",
    "DriedFoodMod.FDriedPorkChop"
}

function DriedFoodMod.GetDriedFood(craftRecipeData, character)
    if not character then return end
    
    local items = craftRecipeData:getAllConsumedItems();
	local results = craftRecipeData:getAllCreatedItems();
    local inventory = character:getInventory();

    local randomIndex = ZombRand(1, #DriedFoodMod.driedFoodItems + 1);
    local selectedItem = DriedFoodMod.driedFoodItems[randomIndex];

    inventory:AddItem(selectedItem);
end

function DriedFoodMod.CookedReward(craftRecipeData, character)
    local items = craftRecipeData:getAllConsumedItems();
	local result = craftRecipeData:getAllCreatedItems():get(0);
    result:setCooked(true);
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(function()
        if FadedFeastcraft and FadedFeastcraft.Utils then
            FadedFeastcraft.Utils.debug("Embedded FFC Dry Storage callbacks loaded")
        end
    end)
end
