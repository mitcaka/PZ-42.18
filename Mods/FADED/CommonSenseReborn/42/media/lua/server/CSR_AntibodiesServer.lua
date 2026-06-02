if isClient and isClient() then
    return
end

require "CSR_FeatureFlags"
require "CSR_Antibodies"

local function forEachPlayer(callback)
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if players then
        for i = 0, players:size() - 1 do
            callback(players:get(i))
        end
        return
    end

    local count = getNumActivePlayers and getNumActivePlayers() or 1
    for i = 0, count - 1 do
        callback(getSpecificPlayer and getSpecificPlayer(i) or getPlayer())
    end
end

local function sendResult(player, ok, key)
    if not player or not sendServerCommand then return end
    sendServerCommand(player, CSR_Antibodies.MODULE, CSR_Antibodies.CMD_RESULT, {
        ok = ok == true,
        key = key,
        playerOnlineID = player.getOnlineID and player:getOnlineID() or nil,
    })
end

local function sendSnapshot(receiver, subject)
    if not receiver or not subject or not sendServerCommand then return end
    sendServerCommand(receiver, CSR_Antibodies.MODULE, CSR_Antibodies.CMD_SNAPSHOT, {
        snapshot = CSR_Antibodies.buildSnapshot(subject),
        playerOnlineID = receiver.getOnlineID and receiver:getOnlineID() or nil,
    })
end

local function resolveSubject(player, args)
    if args and args.targetOnlineID ~= nil then
        return CSR_Antibodies.findPlayerByOnlineID(args.targetOnlineID)
    end
    return player
end

local function onEveryOneMinute()
    if not CSR_FeatureFlags.isAntibodySystemEnabled() then return end

    forEachPlayer(function(player)
        if player and not player:isDead() then
            CSR_Antibodies.updatePlayer(player, 1)
            sendSnapshot(player, player)
        end
    end)
end

local function onClientCommand(module, command, player, args)
    if module ~= CSR_Antibodies.MODULE then return end
    if command ~= CSR_Antibodies.CMD_REQUEST
        and command ~= CSR_Antibodies.CMD_DRAW
        and command ~= CSR_Antibodies.CMD_INJECT then
        return
    end

    if not CSR_FeatureFlags.isAntibodySystemEnabled() then
        sendResult(player, false, "IGUI_CSR_Antibody_FailNotEnabled")
        return
    end

    args = args or {}
    local subject = resolveSubject(player, args)
    if command == CSR_Antibodies.CMD_REQUEST then
        if subject then
            sendSnapshot(player, subject)
        else
            sendResult(player, false, "IGUI_CSR_Antibody_FailInvalid")
        end
        return
    end

    if command == CSR_Antibodies.CMD_DRAW then
        local ok, key = CSR_Antibodies.applyDrawBlood(player, subject, args)
        sendResult(player, ok, key)
        if subject and subject ~= player then sendResult(subject, ok, key) end
        if subject then sendSnapshot(player, subject) end
        if subject and subject ~= player then sendSnapshot(subject, subject) end
        sendSnapshot(player, player)
        return
    end

    if command == CSR_Antibodies.CMD_INJECT then
        local ok, key = CSR_Antibodies.applyInjectSerum(player, subject, args)
        sendResult(player, ok, key)
        if subject and subject ~= player then sendResult(subject, ok, key) end
        if subject then sendSnapshot(player, subject) end
        if subject and subject ~= player then sendSnapshot(subject, subject) end
        sendSnapshot(player, player)
    end
end

if Events then
    if Events.EveryOneMinute and not _G.__CSR_AntibodiesServer_minute then
        _G.__CSR_AntibodiesServer_minute = true
        Events.EveryOneMinute.Add(onEveryOneMinute)
    end
    if Events.OnClientCommand and not _G.__CSR_AntibodiesServer_commands then
        _G.__CSR_AntibodiesServer_commands = true
        Events.OnClientCommand.Add(onClientCommand)
    end
end
