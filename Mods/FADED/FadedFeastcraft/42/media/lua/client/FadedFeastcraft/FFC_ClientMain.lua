require "FadedFeastcraft/FFC_Boot"
require "FadedFeastcraft/FFC_ContextLauncher"
require "FadedFeastcraft/FFC_InventoryContextBridge"
require "FadedFeastcraft/FFC_MealEffectsClient"
require "FadedFeastcraft/FFC_AdminItemViewPatch"
require "FadedFeastcraft/UI/FFC_MenuButton"

FadedFeastcraft = FadedFeastcraft or {}

local Config = FadedFeastcraft.Config

function FadedFeastcraft.HandleCraftResult(args)
    if FFC_MainWindow and FFC_MainWindow.instance then
        local win = FFC_MainWindow.instance
        if win.onCraftResult then
            win:onCraftResult(args)
        else
            local message = tostring(args and args.message or "FFC response")
            win.detailLines = win.detailLines or {}
            if args and args.ok then
                win.selectedIngredientIds = {}
                win:refreshData()
            end
            win.detailLines = win.detailLines or {}
            win.detailLines[#win.detailLines + 1] = message
        end
    end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if player and HaloTextHelper then
        if args and args.ok then
            HaloTextHelper.addGoodText(player, tostring(args.message or "FFC complete"))
        else
            HaloTextHelper.addBadText(player, tostring(args and args.message or "FFC request failed"))
        end
    end
end

local function onServerCommand(module, command, args)
    if module ~= Config.NET_MODULE then return end
    if command == "CraftResult" then
        FadedFeastcraft.HandleCraftResult(args)
    end
end

if Events and Events.OnServerCommand and not FadedFeastcraft.ClientCommandRegistered then
    FadedFeastcraft.ClientCommandRegistered = true
    Events.OnServerCommand.Add(onServerCommand)
end

if Events and Events.OnGameStart and not FadedFeastcraft.ClientBootRegistered then
    FadedFeastcraft.ClientBootRegistered = true
    Events.OnGameStart.Add(function()
        FadedFeastcraft.CSR.refresh()
        FadedFeastcraft.SourceActionIndex.build(true)
        FadedFeastcraft.RecipeIndex.build(true)
        if FadedFeastcraft.Compatibility and FadedFeastcraft.Compatibility.refresh then
            FadedFeastcraft.Compatibility.refresh()
        end
        FadedFeastcraft.EnsureMenuButton()
    end)
end
