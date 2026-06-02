require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/ClientCommands"
require "CSRAdminCommandCenter/Keybind"

local ACC = CSRAdminCommandCenter
ACC.ClientMain = ACC.ClientMain or {}

function ACC.ClientMain.onGameStart()
    ACC.log("Client layer ready. Press the configured keybind to open.")
end

if Events and Events.OnGameStart and not _G.__CSR_ACC_ClientMain then
    _G.__CSR_ACC_ClientMain = true
    Events.OnGameStart.Add(ACC.ClientMain.onGameStart)
end

return ACC.ClientMain

