-- FHC_ServerMain.lua
-- Server-side entry. Dispatches OnClientCommand traffic to validated handlers.

require "FHC_Constants"
require "FHC_Utils"
require "FHC_Sandbox"

if not isServer() then return end

FHC.Server = FHC.Server or {}
local S = FHC.Server
local U = FHC.Utils
local SB = FHC.SB

S.handlers = S.handlers or {}

function S.register(cmd, fn)
    S.handlers[cmd] = fn
end

local function onClientCommand(module, command, player, args)
    if module ~= FHC.MODULE then return end
    if not SB.enabled() then return end
    local h = S.handlers[command]
    if not h then
        U.warn("server: unknown command " .. tostring(command))
        return
    end
    U.safe(function() h(player, args or {}) end, "cmd:" .. command)
end

Events.OnClientCommand.Add(onClientCommand)

local function onServerStarted()
    U.log("server up; module=" .. FHC.MODULE .. " version=" .. FHC.VERSION)
end
Events.OnServerStarted.Add(onServerStarted)
