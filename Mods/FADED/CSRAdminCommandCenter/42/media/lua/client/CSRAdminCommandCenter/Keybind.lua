require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/UI/ACC_UIManager"

local ACC = CSRAdminCommandCenter
ACC.Keybind = ACC.Keybind or {}

local Keybind = ACC.Keybind

Keybind.defaultKey = Keyboard and Keyboard.KEY_F10 or 68
Keybind.option = Keybind.option or nil

local function configuredKey()
    if Keybind.option and Keybind.option.getValue then
        local value = Keybind.option:getValue()
        if value then return value end
    end
    return Keybind.defaultKey
end

function Keybind.onKeyPressed(key)
    if key == configuredKey() then
        ACC.UIManager.toggle()
    end
end

if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.create and not Keybind.option then
    local options = PZAPI.ModOptions:create("CSRAdminCommandCenter", "CSR Admin Command Center")
    if options and options.addKeyBind then
        Keybind.option = options:addKeyBind("openCommandCenter", "Open Command Center", Keybind.defaultKey)
    end
end

if Events and Events.OnKeyPressed and not _G.__CSR_ACC_Keybind then
    _G.__CSR_ACC_Keybind = true
    Events.OnKeyPressed.Add(Keybind.onKeyPressed)
end

return Keybind
