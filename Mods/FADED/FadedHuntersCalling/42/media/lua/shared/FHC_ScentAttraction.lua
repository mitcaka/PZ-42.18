-- FHC_ScentAttraction.lua
-- Timed animal scent lure effect. Runs on SP/server only so animal AI is driven by authority.

require "FHC_Constants"
require "FHC_Utils"
require "FHC_Sandbox"

if isClient and isClient() then return end

local U = FHC.Utils
local SB = FHC.SB

local function activePlayers()
    local out = {}
    if isServer and isServer() then
        local players = getOnlinePlayers and getOnlinePlayers() or nil
        if players then
            for i = 0, U.listSize(players) - 1 do
                local player = U.listGet(players, i)
                local scent = U.getActiveAnimalScent(player)
                if scent then
                    table.insert(out, { player = player, scent = scent })
                end
            end
        end
    else
        for i = 0, 3 do
            local player = getSpecificPlayer and getSpecificPlayer(i) or nil
            local scent = U.getActiveAnimalScent(player)
            if scent then
                table.insert(out, { player = player, scent = scent })
            end
        end
    end
    return out
end

local function squaredDist(a, b)
    local ax, ay = U.objectPosition(a)
    local bx, by = U.objectPosition(b)
    if not ax or not bx then return math.huge end
    local dx = ax - bx
    local dy = ay - by
    return dx * dx + dy * dy
end

local function tick()
    if not SB.enabled() then return end
    if not U.throttled("fhc_scent_attraction", FHC.SCENT_ATTRACT_INTERVAL_MS or 2000) then return end

    local players = activePlayers()
    if #players == 0 then return end

    local cell = getCell and getCell() or nil
    if not cell or not cell.getObjectList then return end

    local radius = FHC.SCENT_ATTRACT_RADIUS or 45
    local r2 = radius * radius
    local stopRadius = FHC.SCENT_STOP_RADIUS or 3
    local stop2 = stopRadius * stopRadius
    local okObjects, objects = U.tryCall(cell, "getObjectList")

    for i = 0, U.listSize(objects) - 1 do
        local animal = U.listGet(objects, i)
        if U.isLivingAnimal(animal) then
            local canonical = U.canonicalForAnimal(animal)
            if canonical then
                local bestPlayer, bestD2 = nil, r2 + 1
                local ax, ay, az = U.objectPosition(animal)
                for _, entry in ipairs(players) do
                    local player = entry.player
                    local px, py, pz = U.objectPosition(player)
                    if entry.scent.animal == canonical and player and az and pz and math.floor(pz) == math.floor(az) then
                        local d2 = squaredDist(animal, player)
                        if d2 <= r2 and d2 < bestD2 then
                            bestPlayer = player
                            bestD2 = d2
                        end
                    end
                end
                if bestPlayer and bestD2 > stop2 then
                    U.nudgeAnimalToward(animal, bestPlayer)
                end
            end
        end
    end
end

Events.OnTick.Add(tick)
