Recipe = Recipe or {}
Recipe.OnCreate = Recipe.OnCreate or {}

local function safeFoodSet(item, methodName, value)
    if not item or not methodName then return end
    local fn = item[methodName]
    if type(fn) == "function" then
        pcall(fn, item, value)
    end
end

function Recipe.OnCreate.AR_MergeResource(craftRecipeData, character)
    --print("Recipe.OnCreate.AR_MergeResource")

    -- getAllCreatedItems: 결과물
    -- getAllConsumedItems: 입력값 중 소모되는 물건
    -- getAllKeepInputItems: 입력값 중 유지하는 물건

    local totalUses = 0.0;
    local totalCalories = 0.0;
    local totalProteins = 0.0;
    local totalLipids = 0.0;
    local totalCarbohydrates = 0.0;

    local result = craftRecipeData:getAllCreatedItems():get(0)

    --print(' > getAllConsumedItems - ')
    for i = 0, craftRecipeData:getAllConsumedItems():size() - 1 do
        local item = craftRecipeData:getAllConsumedItems():get(i)
        totalUses = totalUses + item:getCurrentUsesFloat()
        totalCalories = totalCalories + item:getCalories()
        totalProteins = totalProteins + item:getProteins()
        totalLipids = totalLipids + item:getLipids()
        totalCarbohydrates = totalCarbohydrates + item:getCarbohydrates()
        --print('  current ' .. item:getFullType()..' uses - '.. item:getCurrentUsesFloat()
        --        ..' / Calories - '.. item:getCalories() ..' / Proteins - '.. item:getProteins()
        --        ..' / Lipids - '.. item:getLipids() ..' / Carbohydrates - '.. item:getCarbohydrates())
    end

    safeFoodSet(result, "setHungChange", -totalUses)
    safeFoodSet(result, "setHungerChange", -totalUses)
    safeFoodSet(result, "setCalories", totalCalories)
    safeFoodSet(result, "setProteins", totalProteins)
    safeFoodSet(result, "setLipids", totalLipids)
    safeFoodSet(result, "setCarbohydrates", totalCarbohydrates)
    --print('  returned ' .. result:getFullType()..' uses - '.. result:getCurrentUsesFloat()
    --        ..' / Calories - '.. result:getCalories() ..' / Proteins - '.. result:getProteins()
    --        ..' / Lipids - '.. result:getLipids() ..' / Carbohydrates - '.. result:getCarbohydrates())
end
