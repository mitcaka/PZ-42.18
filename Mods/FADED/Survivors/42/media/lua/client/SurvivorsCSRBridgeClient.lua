require "SurvivorsCSRBridge"

if isServer() then return end

local Bridge = SurvivorsCSRBridge

function Bridge.request(command, args)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or not sendClientCommand then return false end

    sendClientCommand(player, Bridge.MODULE, "CSRRequest", {
        command = command,
        args = args or {},
    })
    return true
end

local function onServerCommand(module, command, args)
    if module ~= Bridge.MODULE then return end
    args = args or {}

    if command == "BridgeEvent" then
        Bridge.emit(args.event, args.payload or {})
    else
        Bridge.emit("ServerResponse", {
            command = command,
            payload = args,
        })
    end
end

Events.OnServerCommand.Add(onServerCommand)
