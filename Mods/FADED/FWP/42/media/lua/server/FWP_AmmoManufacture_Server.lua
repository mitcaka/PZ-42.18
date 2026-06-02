local function onClientCommand(module, command, player, args)
    if module ~= FWPAmmoManufacture.MODULE or command ~= FWPAmmoManufacture.COMMAND_CRAFT then
        return
    end
    if not player or type(args) ~= "table" then
        return
    end
    FWPAmmoManufacture.performCraft(player, args.recipeId)
end

if Events and Events.OnClientCommand then
    Events.OnClientCommand.Add(onClientCommand)
end
