require "SurvivorsCSRBridge"

if isClient() then return end

local Bridge = SurvivorsCSRBridge

local function reply(player, command, payload)
    if not player or not sendServerCommand then return end
    sendServerCommand(player, Bridge.MODULE, command, payload or {})
end

local function onClientCommand(module, command, player, args)
    if module ~= Bridge.MODULE then return end
    args = args or {}

    if command == "CSRRequest" then
        local responseCommand, payload = Bridge.handleCSRRequest(player, args.command, args.args or {})
        reply(player, responseCommand, payload)
    elseif command == "Hello" then
        reply(player, "Status", Bridge.getStatus())
    end
end

Events.OnClientCommand.Add(onClientCommand)
