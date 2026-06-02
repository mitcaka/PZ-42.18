require "CSR_FeatureFlags"

-- Prevent accidental auto-vaulting over stair railings while leaving normal
-- flat-ground fence vaulting alone. Manual interact/climb still works because
-- this only touches the engine's auto-vault flag.

local active = {}

local function enabled()
    return CSR_FeatureFlags
        and CSR_FeatureFlags.isStairVaultGuardEnabled
        and CSR_FeatureFlags.isStairVaultGuardEnabled()
end

local function lower(v)
    return string.lower(tostring(v or ""))
end

local function squareHasStairs(square)
    if not square then return false end
    if square:HasStairs()
        or square:HasStairsNorth()
        or square:HasStairsWest()
        or square:HasStairsBelow() then
        return true
    end

    local objects = square:getObjects()
    if not objects then return false end
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        local sprite = obj and obj:getSprite() or nil
        local name = sprite and sprite:getName() or nil
        if name and lower(name):find("stair", 1, true) then
            return true
        end
    end
    return false
end

local function squareHasHoppable(square)
    if not square or not IsoFlagType then return false end
    return square:has(IsoFlagType.HoppableN)
        or square:has(IsoFlagType.HoppableW)
end

local function shouldBlockAutoVault(player)
    if not player or player:getVehicle() then return false end
    local square = player:getSquare()
    if not square then return false end
    local cell = square:getCell()
    if not cell then return false end

    local px, py, pz = square:getX(), square:getY(), square:getZ()
    local foundStairs = false
    local foundHoppable = false

    for dz = -1, 0 do
        local z = pz + dz
        if z >= 0 then
            for dy = -1, 1 do
                for dx = -1, 1 do
                    local checkSquare = cell:getGridSquare(px + dx, py + dy, z)
                    if squareHasStairs(checkSquare) then
                        foundStairs = true
                    end
                    if dz == 0 and squareHasHoppable(checkSquare) then
                        foundHoppable = true
                    end
                    if foundStairs and foundHoppable then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function setGuard(player, value)
    local wasActive = active[player] == true
    if value then
        if not wasActive then
            player:setIgnoreAutoVault(true)
            active[player] = true
        end
    elseif wasActive then
        player:setIgnoreAutoVault(false)
        active[player] = nil
    end
end

local function onPlayerUpdate(player)
    if not player then return end
    setGuard(player, enabled() and shouldBlockAutoVault(player))
end

local function onCreatePlayer()
    active = {}
end

if Events then
    if Events.OnPlayerUpdate then Events.OnPlayerUpdate.Add(onPlayerUpdate) end
    if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(onCreatePlayer) end
end

