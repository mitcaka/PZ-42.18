require "FadedFeastcraft/FFC_ServerCommands"

FadedFeastcraft = FadedFeastcraft or {}

if Events and Events.OnGameStart and not FadedFeastcraft.ServerBootRegistered then
    FadedFeastcraft.ServerBootRegistered = true
    Events.OnGameStart.Add(function()
        if FadedFeastcraft.Compatibility and FadedFeastcraft.Compatibility.refresh then
            FadedFeastcraft.Compatibility.refresh()
        end
        FadedFeastcraft.Utils.debug("Server boot complete")
    end)
end
