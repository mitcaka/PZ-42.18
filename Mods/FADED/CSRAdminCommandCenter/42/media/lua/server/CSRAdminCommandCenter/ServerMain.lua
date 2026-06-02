require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/AdminCommands"
require "CSRAdminCommandCenter/CSRDetector"
require "CSRAdminCommandCenter/Persistence"
require "CSRAdminCommandCenter/VehicleTracker"
require "CSRAdminCommandCenter/ClaimsTracker"
require "CSRAdminCommandCenter/PlayerTracker"
require "CSRAdminCommandCenter/PadlockTracker"
require "CSRAdminCommandCenter/JournalTracker"
require "CSRAdminCommandCenter/VehicleClaimAuthority"
require "CSRAdminCommandCenter/SettingsManager"

local ACC = CSRAdminCommandCenter
ACC.ServerMain = ACC.ServerMain or {}

local ServerMain = ACC.ServerMain

function ServerMain.onClientCommand(module, command, player, args)
    ACC.PlayerTracker.observeClientCommand(module, command, player)
    ACC.JournalTracker.observeClientCommand(module, command, player, args or {})
    ACC.VehicleClaimAuthority.observeCSRCommand(module, command, player, args or {})
    ACC.AdminCommands.dispatch(module, command, player, args or {})
    ACC.Persistence.flush()
end

function ServerMain.onServerStarted()
    ACC.SettingsManager.applyPersisted()
    local detection = ACC.CSRDetector.detect()
    if detection.detected then
        ACC.log("CSR detected. Command center server layer ready.")
    else
        ACC.log("CSR not detected. Limited mode ready.")
    end
    if detection.testBranchActive then
        ACC.log("Warning: CommonSenseRebornTest is active. The command center targets the non-test CSR branch.")
    end
    ACC.VehicleClaimAuthority.onServerStarted()
    ACC.Persistence.flush()
end

if Events then
    if Events.OnClientCommand and not _G.__CSR_ACC_OnClientCommand then
        _G.__CSR_ACC_OnClientCommand = true
        Events.OnClientCommand.Add(ServerMain.onClientCommand)
    end
    if Events.OnServerStarted and not _G.__CSR_ACC_OnServerStarted then
        _G.__CSR_ACC_OnServerStarted = true
        Events.OnServerStarted.Add(ServerMain.onServerStarted)
    end
end

return ServerMain
