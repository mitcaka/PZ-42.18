require "FadedFeastcraft/UI/FFC_MainWindow"
require "ISUI/ISToolTip"

FadedFeastcraft = FadedFeastcraft or {}

local function attachTooltip(option, description)
    if not option or not ISToolTip then return end
    local ok, tip = pcall(function()
        local created = ISToolTip:new()
        created:initialise()
        created:setVisible(false)
        created.description = description
        return created
    end)
    if ok and tip then
        option.toolTip = tip
    end
end

local function addWorldContext(player, context, worldobjects, test)
    if test or not context then return end
    local option = context:addOption("FFC", nil, FadedFeastcraft.ToggleWindow)
    attachTooltip(option, "Open Faded's Feastcraft.")
end

if Events and Events.OnFillWorldObjectContextMenu and not FadedFeastcraft.ContextLauncherRegistered then
    FadedFeastcraft.ContextLauncherRegistered = true
    Events.OnFillWorldObjectContextMenu.Add(addWorldContext)
end
