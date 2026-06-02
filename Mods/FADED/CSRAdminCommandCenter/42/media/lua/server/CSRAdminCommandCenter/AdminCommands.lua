require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/AdminAccess"
require "CSRAdminCommandCenter/CSRDetector"
require "CSRAdminCommandCenter/ClaimsTracker"
require "CSRAdminCommandCenter/CSRAdapter"
require "CSRAdminCommandCenter/CleanupTracker"
require "CSRAdminCommandCenter/DebugHooks"
require "CSRAdminCommandCenter/AnalyticsTracker"
require "CSRAdminCommandCenter/Exporter"
require "CSRAdminCommandCenter/Persistence"
require "CSRAdminCommandCenter/PlayerTracker"
require "CSRAdminCommandCenter/PadlockTracker"
require "CSRAdminCommandCenter/JournalTracker"
require "CSRAdminCommandCenter/VehicleClaimAuthority"
require "CSRAdminCommandCenter/SettingsManager"
require "CSRAdminCommandCenter/Utils/Time"

local ACC = CSRAdminCommandCenter
ACC.AdminCommands = ACC.AdminCommands or {}

local Commands = ACC.AdminCommands
Commands._lastByPlayer = Commands._lastByPlayer or {}

local function username(player)
    return ACC.AdminAccess.usernameFor(player)
end

local function playerKey(player)
    local name = username(player)
    local oid = ""
    if player and player.getOnlineID then
        oid = tostring(player:getOnlineID() or "")
    end
    return name .. "#" .. oid
end

local function send(player, command, payload)
    if not player or not sendServerCommand then return end
    sendServerCommand(player, ACC.MODULE, command, payload or {})
end

local function denied(player, command, reason)
    local access = ACC.AdminAccess.describe(player)
    ACC.Persistence.enqueue("access",
        "denied command=" .. tostring(command)
        .. " user=" .. tostring(access.username or "")
        .. " access=" .. tostring(access.normalized or "")
        .. " reason=" .. tostring(reason or ""))
    send(player, ACC.Commands.AccessDenied, {
        command = tostring(command or ""),
        reason = tostring(reason or "Access denied"),
        access = access,
    })
end

local function tooSoon(player, command)
    local key = playerKey(player) .. ":" .. tostring(command or "")
    local now = ACC.Time.nowSeconds()
    local last = tonumber(Commands._lastByPlayer[key]) or 0
    Commands._lastByPlayer[key] = now
    return now - last < 1
end

local function buildSnapshot(player)
    local detection = ACC.CSRDetector.detect()
    local claimRows = ACC.CSRAdapter.getAllClaimRows()
    local claims = ACC.ClaimsTracker.summary(claimRows)
    local cleanup = ACC.CleanupTracker.status()
    local debugState = ACC.DebugHooks.getState()
    local analytics = ACC.AnalyticsTracker.build(claimRows)
    local padlocks = ACC.PadlockTracker.summary()
    local journal = ACC.JournalTracker.summary()
    local authority = ACC.VehicleClaimAuthority.summary()
    local settings = ACC.SettingsManager.snapshot()

    return {
        version = ACC.VERSION,
        serverTime = ACC.Time.nowSeconds(),
        serverTimeText = ACC.Time.stamp(),
        access = ACC.AdminAccess.describe(player),
        detection = detection,
        population = ACC.CSRAdapter.onlinePopulation(),
        claims = claims,
        padlocks = padlocks,
        journal = journal,
        vehicleAuthority = authority,
        settings = settings,
        cleanup = cleanup,
        debug = debugState,
        analytics = analytics,
        recentAudit = ACC.ClaimsTracker.recentAudit(8),
        limitedWarning = detection.warning,
    }
end

local function isSettingsCommand(command)
    return command == ACC.Commands.RequestSettings or command == ACC.Commands.SetSetting
end

function Commands.dispatch(module, command, player, args)
    if module ~= ACC.MODULE then return false end
    args = args or {}

    if not ACC.AdminAccess.isEnabled() and not isSettingsCommand(command) then
        denied(player, command, "Command center disabled")
        return true
    end

    if isSettingsCommand(command) then
        if tooSoon(player, command) then return true end
        if not ACC.AdminAccess.hasSettingsAccess(player) then denied(player, command, "Settings access required"); return true end
        if command == ACC.Commands.RequestSettings then
            send(player, ACC.Commands.SettingsState, ACC.SettingsManager.snapshot())
            return true
        end
        local ok, message = ACC.SettingsManager.set(player, args)
        send(player, ACC.Commands.SettingsResult, {
            ok = ok == true,
            message = tostring(message or ""),
            key = tostring(args.key or ""),
        })
        send(player, ACC.Commands.SettingsState, ACC.SettingsManager.snapshot())
        send(player, ACC.Commands.Snapshot, buildSnapshot(player))
        return true
    end

    if command == ACC.Commands.Ping then
        if not ACC.AdminAccess.hasView(player) then denied(player, command, "View access required"); return true end
        send(player, ACC.Commands.Pong, { time = ACC.Time.nowSeconds() })
        return true
    end

    if command == ACC.Commands.RequestSnapshot then
        if tooSoon(player, command) then return true end
        if not ACC.AdminAccess.hasView(player) then denied(player, command, "View access required"); return true end
        send(player, ACC.Commands.Snapshot, buildSnapshot(player))
        return true
    end

    if command == ACC.Commands.RequestClaims then
        if tooSoon(player, command) then return true end
        if not ACC.AdminAccess.hasView(player) then denied(player, command, "View access required"); return true end
        send(player, ACC.Commands.ClaimsPage, ACC.ClaimsTracker.buildPage(args))
        return true
    end

    if command == ACC.Commands.ClaimAction then
        if tooSoon(player, command) then return true end
        if not ACC.AdminAccess.hasControl(player) then denied(player, command, "Control access required"); return true end
        local preRow = ACC.CSRAdapter.getClaimRowById(args.id)
        local ok, message = ACC.CSRAdapter.claimAction(player, args)
        if ok == true and preRow and preRow.kind == "vehicle" then
            if tostring(args.action or "") == "release" then
                if not ACC.CSRAdapter.getClaimRowById(args.id) then
                    ACC.VehicleClaimAuthority.markReleased(preRow, "acc_release", player)
                end
            else
                ACC.VehicleClaimAuthority.snapshotCurrentRows("acc_claim_action")
            end
        end
        send(player, ACC.Commands.ClaimActionResult, {
            ok = ok == true,
            message = tostring(message or ""),
            action = tostring(args.action or ""),
            id = tonumber(args.id) or 0,
        })
        send(player, ACC.Commands.ClaimsPage, ACC.ClaimsTracker.buildPage({
            page = tonumber(args.page) or 1,
            kind = tostring(args.kind or "all"),
            query = tostring(args.query or ""),
            owner = tostring(args.owner or ""),
        }))
        send(player, ACC.Commands.Snapshot, buildSnapshot(player))
        return true
    end

    if command == ACC.Commands.RequestCleanup then
        if not ACC.AdminAccess.hasView(player) then denied(player, command, "View access required"); return true end
        send(player, ACC.Commands.CleanupStatus, ACC.CleanupTracker.status())
        return true
    end

    if command == ACC.Commands.RequestPlayers then
        if tooSoon(player, command) then return true end
        if not ACC.AdminAccess.hasView(player) then denied(player, command, "View access required"); return true end
        send(player, ACC.Commands.PlayersPage, ACC.PlayerTracker.buildList(args))
        return true
    end

    if command == ACC.Commands.RequestJournal then
        if tooSoon(player, command) then return true end
        if not ACC.AdminAccess.hasView(player) then denied(player, command, "View access required"); return true end
        send(player, ACC.Commands.JournalPage, ACC.JournalTracker.buildPage(args))
        return true
    end

    if command == ACC.Commands.JournalAction then
        if tooSoon(player, command) then return true end
        local action = tostring(args.action or "")
        if ACC.JournalTracker.isEraseAction(action) then
            if not ACC.AdminAccess.hasDataErase(player) then denied(player, command, "Admin data erase access required"); return true end
        elseif not ACC.AdminAccess.hasControl(player) then
            denied(player, command, "Control access required")
            return true
        end
        local ok, message = ACC.JournalTracker.action(player, args)
        send(player, ACC.Commands.JournalActionResult, {
            ok = ok == true,
            message = tostring(message or ""),
            action = action,
            target = tostring(args.target or args.username or ""),
            rowKey = tostring(args.rowKey or ""),
        })
        send(player, ACC.Commands.JournalPage, ACC.JournalTracker.buildPage({
            page = tonumber(args.page) or 1,
            query = tostring(args.query or ""),
            force = true,
        }))
        send(player, ACC.Commands.Snapshot, buildSnapshot(player))
        return true
    end

    if command == ACC.Commands.SetPlayerTracked then
        if not ACC.AdminAccess.hasControl(player) then denied(player, command, "Control access required"); return true end
        local ok, message = ACC.PlayerTracker.setTracked(args.username, args.enabled == true, player)
        send(player, ACC.Commands.PlayerTrackState, {
            ok = ok == true,
            message = tostring(message or ""),
            username = tostring(args.username or ""),
            enabled = args.enabled == true,
        })
        send(player, ACC.Commands.PlayersPage, ACC.PlayerTracker.buildList({}))
        return true
    end

    if command == ACC.Commands.RequestPadlocks then
        if tooSoon(player, command) then return true end
        if not ACC.AdminAccess.hasView(player) then denied(player, command, "View access required"); return true end
        send(player, ACC.Commands.PadlocksPage, ACC.PadlockTracker.buildPage(args))
        return true
    end

    if command == ACC.Commands.PadlockAction then
        if tooSoon(player, command) then return true end
        if not ACC.AdminAccess.hasControl(player) then denied(player, command, "Control access required"); return true end
        local ok, message = ACC.PadlockTracker.action(player, args)
        send(player, ACC.Commands.PadlockActionResult, {
            ok = ok == true,
            message = tostring(message or ""),
            action = tostring(args.action or ""),
            targetKey = tostring(args.targetKey or ""),
        })
        send(player, ACC.Commands.PadlocksPage, ACC.PadlockTracker.buildPage({
            page = tonumber(args.page) or 1,
            query = tostring(args.query or ""),
            owner = tostring(args.owner or ""),
            targetKind = tostring(args.targetKind or "all"),
            force = true,
        }))
        send(player, ACC.Commands.Snapshot, buildSnapshot(player))
        return true
    end

    if command == ACC.Commands.SetDebugOption then
        if not ACC.AdminAccess.hasControl(player) then denied(player, command, "Control access required"); return true end
        local ok, message = ACC.DebugHooks.setOption(username(player), args.key, args.enabled == true)
        send(player, ACC.Commands.DebugState, {
            ok = ok == true,
            message = tostring(message or ""),
            state = ACC.DebugHooks.getState(),
        })
        return true
    end

    if command == ACC.Commands.RequestExport then
        if not ACC.AdminAccess.hasExport(player) then denied(player, command, "Admin export access required"); return true end
        send(player, ACC.Commands.ExportResult, ACC.Exporter.exportDiagnostics(username(player)))
        return true
    end

    send(player, ACC.Commands.Error, { message = "Unknown command: " .. tostring(command) })
    return true
end

return Commands
