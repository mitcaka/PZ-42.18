-- FHC_AnimalCallAttraction.lua
-- Short-lived animal-call lure effect. Runs only in SP/server authority.

require "FHC_Constants"
require "FHC_Utils"
require "FHC_Sandbox"

if isClient and isClient() then return end
if FHC.AnimalCallAttractionLoaded then return end
FHC.AnimalCallAttractionLoaded = true

local U = FHC.Utils
local SB = FHC.SB

local function activePlayers()
    local out = {}
    if isServer and isServer() then
        local players = getOnlinePlayers and getOnlinePlayers() or nil
        if players then
            for i = 0, U.listSize(players) - 1 do
                local player = U.listGet(players, i)
                local call = U.getActiveAnimalCall(player)
                if call then
                    table.insert(out, { player = player, call = call })
                end
            end
        end
    else
        for i = 0, 3 do
            local player = getSpecificPlayer and getSpecificPlayer(i) or nil
            local call = U.getActiveAnimalCall(player)
            if call then
                table.insert(out, { player = player, call = call })
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

function FHC.AttractAnimalsForCall(player, animalKey)
    if not player or not animalKey or not FHC.ANIMAL_CALLS[animalKey] then return 0 end
    local cell = getCell and getCell() or nil
    if not cell or not cell.getObjectList then return 0 end

    local radius = FHC.ANIMAL_CALL_RADIUS or 55
    local r2 = radius * radius
    local stopRadius = FHC.ANIMAL_CALL_STOP_RADIUS or 4
    local stop2 = stopRadius * stopRadius
    local okObjects, objects = U.tryCall(cell, "getObjectList")
    local moved = 0

    for i = 0, U.listSize(objects) - 1 do
        local animal = U.listGet(objects, i)
        local ax, ay, az = U.objectPosition(animal)
        local px, py, pz = U.objectPosition(player)
        if U.isLivingAnimal(animal) and az and pz and math.floor(pz) == math.floor(az) then
            local canonical = U.canonicalForAnimal(animal)
            if canonical == animalKey then
                local d2 = squaredDist(animal, player)
                if d2 <= r2 and d2 > stop2 then
                    if U.nudgeAnimalToward(animal, player) then
                        moved = moved + 1
                    end
                end
            end
        end
    end
    return moved
end

local function tick()
    if not SB.enabled() then return end
    if not U.throttled("fhc_animal_call_attraction", FHC.ANIMAL_CALL_ATTRACT_INTERVAL_MS or 1500) then return end

    local players = activePlayers()
    if #players == 0 then return end

    for _, entry in ipairs(players) do
        if entry.call and entry.call.animal then
            FHC.AttractAnimalsForCall(entry.player, entry.call.animal)
        end
    end
end

Events.OnTick.Add(tick)
