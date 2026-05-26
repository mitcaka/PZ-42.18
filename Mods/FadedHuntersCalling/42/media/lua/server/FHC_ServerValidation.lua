-- FHC_ServerValidation.lua
-- Shared validation helpers used by every command handler.

require "FHC_ServerMain"

if not isServer() then return end

FHC.Server = FHC.Server or {}
local V = {}
FHC.Server.V = V
local U = FHC.Utils
local SB = FHC.SB

-- Distance check (squared). 0 = same tile; default cap 8 tiles.
function V.playerNearXYZ(player, x, y, z, maxTiles)
    if not player or not x or not y then return false end
    if not SB.strictValidation() then return true end
    local px, py = U.objectPosition(player)
    if not px then return false end
    local dx = px - x
    local dy = py - y
    local d2 = dx * dx + dy * dy
    local cap = (maxTiles or 8); cap = cap * cap
    return d2 <= cap
end

function V.playerNearObject(player, obj, maxTiles)
    if not obj then return false end
    local x, y, z = U.objectPosition(obj)
    return V.playerNearXYZ(player, x, y, z, maxTiles)
end

function V.isAdmin(player)
    if not player then return false end
    if player.getAccessLevel then
        local lvl = player:getAccessLevel()
        if lvl == "Admin" or lvl == "GM" or lvl == "Overseer" or lvl == "Moderator" then
            return true
        end
    end
    return false
end

-- Sanity-check command args (must be a table, fields must be of expected type).
function V.checkArgs(args, schema)
    if type(args) ~= "table" then return false end
    for key, kind in pairs(schema) do
        local v = args[key]
        if kind == "number" and type(v) ~= "number" then return false end
        if kind == "string" and type(v) ~= "string" then return false end
        if kind == "bool" and type(v) ~= "boolean" then return false end
        if kind == "table" and type(v) ~= "table" then return false end
        if kind == "any" and v == nil then return false end
    end
    return true
end
