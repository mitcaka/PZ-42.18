require "CSRAdminCommandCenter/ACC_Main"

local ACC = CSRAdminCommandCenter
ACC.ClientCommands = ACC.ClientCommands or {}

local Client = ACC.ClientCommands

Client.state = Client.state or {
    snapshot = nil,
    claimsPage = nil,
    claimActionResult = nil,
    cleanupStatus = nil,
    playersPage = nil,
    playerTrackState = nil,
    journalPage = nil,
    journalActionResult = nil,
    padlocksPage = nil,
    padlockActionResult = nil,
    debugState = nil,
    settingsState = nil,
    settingsResult = nil,
    exportResult = nil,
    lastDenied = nil,
    lastError = nil,
    selectedVehicle = nil,
    selectedPlayer = nil,
    selectedJournalRow = nil,
    selectedPadlock = nil,
}

local function player()
    return getPlayer and getPlayer() or nil
end

local function send(command, args)
    local p = player()
    if not p or not sendClientCommand then return end
    sendClientCommand(p, ACC.MODULE, command, args or {})
end

function Client.requestSnapshot()
    send(ACC.Commands.RequestSnapshot, {})
end

function Client.requestClaims(args)
    send(ACC.Commands.RequestClaims, args or {})
end

function Client.claimAction(args)
    send(ACC.Commands.ClaimAction, args or {})
end

function Client.requestCleanup()
    send(ACC.Commands.RequestCleanup, {})
end

function Client.requestPlayers(args)
    send(ACC.Commands.RequestPlayers, args or {})
end

function Client.setPlayerTracked(username, enabled)
    send(ACC.Commands.SetPlayerTracked, { username = username, enabled = enabled == true })
end

function Client.requestJournal(args)
    send(ACC.Commands.RequestJournal, args or {})
end

function Client.journalAction(args)
    send(ACC.Commands.JournalAction, args or {})
end

function Client.requestPadlocks(args)
    send(ACC.Commands.RequestPadlocks, args or {})
end

function Client.padlockAction(args)
    send(ACC.Commands.PadlockAction, args or {})
end

function Client.setDebugOption(key, enabled)
    send(ACC.Commands.SetDebugOption, { key = key, enabled = enabled == true })
end

function Client.requestSettings()
    send(ACC.Commands.RequestSettings, {})
end

function Client.setSetting(key, value, reset)
    send(ACC.Commands.SetSetting, { key = key, value = value, reset = reset == true })
end

function Client.requestExport()
    send(ACC.Commands.RequestExport, {})
end

function Client.setSelectedVehicle(row)
    Client.state.selectedVehicle = row
end

function Client.setSelectedPlayer(row)
    Client.state.selectedPlayer = row
end

function Client.setSelectedJournalRow(row)
    Client.state.selectedJournalRow = row
end

function Client.setSelectedPadlock(row)
    Client.state.selectedPadlock = row
end

local function halo(message, r, g, b)
    local p = player()
    if p and p.setHaloNote then
        p:setHaloNote(tostring(message or ""), r or 255, g or 255, b or 255, 220)
    end
end

function Client.onServerCommand(module, command, args)
    if module ~= ACC.MODULE then return end
    args = args or {}

    if command == ACC.Commands.Snapshot then
        Client.state.snapshot = args
        Client.state.debugState = args.debug or Client.state.debugState
        Client.state.cleanupStatus = args.cleanup or Client.state.cleanupStatus
        return
    end

    if command == ACC.Commands.ClaimsPage then
        Client.state.claimsPage = args
        if Client.state.selectedVehicle and type(args.rows) == "table" then
            local selectedId = tonumber(Client.state.selectedVehicle.id)
            for i = 1, #args.rows do
                if tonumber(args.rows[i].id) == selectedId then
                    Client.state.selectedVehicle = args.rows[i]
                    break
                end
            end
        end
        return
    end

    if command == ACC.Commands.ClaimActionResult then
        Client.state.claimActionResult = args
        halo(args.message or "Claim action complete", args.ok and 120 or 255, args.ok and 220 or 90, args.ok and 160 or 90)
        return
    end

    if command == ACC.Commands.CleanupStatus then
        Client.state.cleanupStatus = args
        return
    end

    if command == ACC.Commands.PlayersPage then
        Client.state.playersPage = args
        if Client.state.selectedPlayer and type(args.rows) == "table" then
            local selectedName = tostring(Client.state.selectedPlayer.username or "")
            for i = 1, #args.rows do
                if tostring(args.rows[i].username or "") == selectedName then
                    Client.state.selectedPlayer = args.rows[i]
                    break
                end
            end
        end
        return
    end

    if command == ACC.Commands.PlayerTrackState then
        Client.state.playerTrackState = args
        halo(args.message or "Player tracking updated", args.ok and 120 or 255, args.ok and 220 or 90, args.ok and 160 or 90)
        return
    end

    if command == ACC.Commands.JournalPage then
        Client.state.journalPage = args
        if Client.state.selectedJournalRow and type(args.rows) == "table" then
            local selectedKey = tostring(Client.state.selectedJournalRow.rowKey or "")
            local found = false
            for i = 1, #args.rows do
                if tostring(args.rows[i].rowKey or "") == selectedKey then
                    Client.state.selectedJournalRow = args.rows[i]
                    found = true
                    break
                end
            end
            if not found then Client.state.selectedJournalRow = nil end
        end
        return
    end

    if command == ACC.Commands.JournalActionResult then
        Client.state.journalActionResult = args
        halo(args.message or "Journal action complete", args.ok and 120 or 255, args.ok and 220 or 90, args.ok and 160 or 90)
        return
    end

    if command == ACC.Commands.PadlocksPage then
        Client.state.padlocksPage = args
        if Client.state.selectedPadlock and type(args.rows) == "table" then
            local selectedKey = tostring(Client.state.selectedPadlock.targetKey or "")
            for i = 1, #args.rows do
                if tostring(args.rows[i].targetKey or "") == selectedKey then
                    Client.state.selectedPadlock = args.rows[i]
                    break
                end
            end
        end
        return
    end

    if command == ACC.Commands.PadlockActionResult then
        Client.state.padlockActionResult = args
        halo(args.message or "Padlock action complete", args.ok and 120 or 255, args.ok and 220 or 90, args.ok and 160 or 90)
        return
    end

    if command == ACC.Commands.DebugState then
        Client.state.debugState = args.state or args
        if args.message and args.message ~= "" then halo(args.message, 120, 220, 160) end
        return
    end

    if command == ACC.Commands.SettingsState then
        Client.state.settingsState = args
        return
    end

    if command == ACC.Commands.SettingsResult then
        Client.state.settingsResult = args
        halo(args.message or "Setting updated", args.ok and 120 or 255, args.ok and 220 or 90, args.ok and 160 or 90)
        return
    end

    if command == ACC.Commands.ExportResult then
        Client.state.exportResult = args
        halo(args.message or "Export complete", 120, 220, 160)
        return
    end

    if command == ACC.Commands.AccessDenied then
        Client.state.lastDenied = args
        halo(args.reason or "Access denied", 255, 90, 90)
        return
    end

    if command == ACC.Commands.Error then
        Client.state.lastError = args
        halo(args.message or "Command center error", 255, 120, 90)
    end
end

if Events and Events.OnServerCommand and not _G.__CSR_ACC_ClientCommands then
    _G.__CSR_ACC_ClientCommands = true
    Events.OnServerCommand.Add(Client.onServerCommand)
end

return Client
