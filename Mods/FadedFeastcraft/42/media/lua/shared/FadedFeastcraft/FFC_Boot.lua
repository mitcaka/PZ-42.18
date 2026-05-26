require "FadedFeastcraft/FFC_Config"
require "FadedFeastcraft/FFC_Utils"
require "FadedFeastcraft/FFC_Branding"
require "FadedFeastcraft/FFC_SourcePackRegistry"
require "FadedFeastcraft/FFC_DistributionSafety"
require "FadedFeastcraft/FFC_CSRIntegration"
require "FadedFeastcraft/FFC_Balance"
require "FadedFeastcraft/FFC_Preservation"
require "FadedFeastcraft/FFC_Compatibility"
require "FadedFeastcraft/FFC_OperationRegistry"
require "FadedFeastcraft/FFC_SourceActionIndex"
require "FadedFeastcraft/FFC_ItemClassifier"
require "FadedFeastcraft/FFC_IngredientScanner"
require "FadedFeastcraft/FFC_ExpiryTracker"
require "FadedFeastcraft/FFC_AutoCookPlanner"
require "FadedFeastcraft/FFC_MealPlanner"
require "FadedFeastcraft/FFC_MealEffects"
require "FadedFeastcraft/FFC_DirectRecipeRegistry"
require "FadedFeastcraft/FFC_RecipeIndex"
require "FadedFeastcraft/FFC_CookingStation"
require "FadedFeastcraft/FFC_Net"

FadedFeastcraft = FadedFeastcraft or {}

if Events and Events.OnGameStart and not FadedFeastcraft.SharedBootRegistered then
    FadedFeastcraft.SharedBootRegistered = true
    Events.OnGameStart.Add(function()
        FadedFeastcraft.CSR.refresh()
        FadedFeastcraft.SourceActionIndex.build(true)
        FadedFeastcraft.RecipeIndex.build(true)
        if FadedFeastcraft.Compatibility and FadedFeastcraft.Compatibility.refresh then
            FadedFeastcraft.Compatibility.refresh()
        end
        FadedFeastcraft.Utils.debug("Shared boot complete")
    end)
end

return FadedFeastcraft
