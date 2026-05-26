-- B42 ammo-effect fire runtime for FWP flame fuel and incendiary shells.
if isServer() then return end

local MODULE_NAME = "FWPIncendiaryAmmo"
local COMMAND_FLAME = "Flame"
local MIN_INTERVAL_MS = 120
local MIN_RANGE = 2.0
local MAX_RANGE = 8.0
local DEFAULT_FLAME_FUEL_BURST = 5
local FLAME_FUEL_RANGE_TILES = 5
local lastDebugMs = 0

local function nowMs()
    if getTimestampMs then
        local value = getTimestampMs()
        if tonumber(value) then return tonumber(value) end
    end
    return math.floor((os.clock and os.clock() or 0) * 1000)
end

local function roundToGrid(v)
    if v >= 0 then return math.floor(v + 0.5) end
    return math.ceil(v - 0.5)
end

local function clamp(value, lo, hi)
    value = tonumber(value) or lo
    if value < lo then return lo end
    if value > hi then return hi end
    return value
end

local function debugFlame(message, force)
    local t = nowMs()
    if (not force) and (t - lastDebugMs) < 2000 then return end
    lastDebugMs = t
    print("[FWP INCENDIARY] " .. tostring(message))
end

local function normalizeAmmoType(ammoType)
    if ammoType == nil then return nil end
    if type(ammoType) ~= "string" and FWPGetAmmoItemKey then
        local resolved = FWPGetAmmoItemKey(ammoType)
        if resolved then ammoType = resolved end
    end
    local text = tostring(ammoType)
    if text == "fwp:flame_fuel" then return "Base.FlameFuel" end
    if text == "fwp:12g_incendiary_shells" then return "Base.FWP_12gIncendiaryShells" end
    return text
end

local function getAmmoEffectType(weapon)
    local md = weapon and weapon.getModData and weapon:getModData() or nil
    local ammoType = md and (md.FWP_B42PendingAmmoEffect or md.FWP_LastFiredAmmoType) or nil
    if ammoType then return normalizeAmmoType(ammoType) end
    if FWPPeekAmmoEffectType then
        local resolved = FWPPeekAmmoEffectType(weapon)
        if resolved then return normalizeAmmoType(resolved) end
    end
    if FWPGetAmmoItemKey then
        local resolved = FWPGetAmmoItemKey(weapon)
        if resolved then return normalizeAmmoType(resolved) end
    end
    return nil
end

local function isFireAmmo(ammoType)
    ammoType = normalizeAmmoType(ammoType)
    return ammoType == "Base.FlameFuel" or ammoType == "Base.FWP_12gIncendiaryShells"
end

local function startFireAt(square, fireLife, fireEnergy)
    if not (square and IsoFireManager and IsoFireManager.StartFire and getCell) then return false end
    fireLife = math.max(20, tonumber(fireLife) or 110)
    fireEnergy = math.max(80, tonumber(fireEnergy) or 450)
    local ok = pcall(IsoFireManager.StartFire, getCell(), square, true, fireLife, fireEnergy)
    if ok then return true end
    ok = pcall(IsoFireManager.StartFire, getCell(), square, true, fireEnergy)
    return ok == true
end

local function markSquareFueled(square, fuelSpent)
    if not (square and square.getModData) then return end
    local md = square:getModData()
    local amount = tonumber(md.FWP_FlameFuelAmount) or 0
    md.FWP_FlameFuel = true
    md.FWP_FlameFuelAmount = math.min(100, amount + (tonumber(fuelSpent) or DEFAULT_FLAME_FUEL_BURST))
    md.FWP_FlameFuelUntil = nowMs() + 5000
    if square.transmitModdata then
        pcall(square.transmitModdata, square)
    end
end

local function igniteCharacter(target, burnTime)
    if not target then return end
    if target.setBurnTime then target:setBurnTime(tonumber(burnTime) or 220) end
    if target.setOnFire then target:setOnFire(true) end
    if target.SetOnFire then target:SetOnFire() end
end

local function igniteCharactersNear(square, playerObj, radius, burnTime)
    if not (square and square.getMovingObjects) then return end
    local moving = square:getMovingObjects()
    if not moving then return end
    local sx, sy, sz = square:getX(), square:getY(), square:getZ()
    radius = tonumber(radius) or 0.95
    for i = 0, moving:size() - 1 do
        local obj = moving:get(i)
        if obj and obj ~= playerObj and obj.getX and obj.getY and obj.getZ then
            local dz = math.abs((obj:getZ() or sz) - sz)
            local dx = obj:getX() - sx
            local dy = obj:getY() - sy
            if dz < 0.5 and (dx * dx + dy * dy) <= radius * radius then
                igniteCharacter(obj, burnTime)
            end
        end
    end
end

local function igniteAroundSquare(square, radius, fireEnergy, chance)
    if not (square and getCell) then return end
    radius = tonumber(radius) or 0
    fireEnergy = tonumber(fireEnergy) or 25
    chance = tonumber(chance) or 100
    startFireAt(square, 70, 320)
    for dx = -radius, radius do
        for dy = -radius, radius do
            if not (dx == 0 and dy == 0) and ZombRand(100) < chance then
                local neighbor = getCell():getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
                if neighbor then startFireAt(neighbor, 50, math.floor(fireEnergy * 12)) end
            end
        end
    end
end

local function normalizeDirection(dx, dy, fallbackX, fallbackY)
    dx = tonumber(dx) or 0
    dy = tonumber(dy) or 0
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= 0.001 then
        dx = fallbackX or 0
        dy = fallbackY or 1
        len = math.sqrt(dx * dx + dy * dy)
    end
    if len <= 0.001 then return 0, 1 end
    return dx / len, dy / len
end

local function getForwardDirection(playerObj)
    local dir = playerObj and playerObj.getForwardDirection and playerObj:getForwardDirection() or nil
    if dir and dir.getX and dir.getY then
        return normalizeDirection(dir:getX(), dir:getY(), 0, 1)
    end
    return 0, 1
end

local function getAimDirection(playerObj)
    local fallbackX, fallbackY = getForwardDirection(playerObj)
    if playerObj and playerObj.getAimVector and Vector2 and Vector2.new then
        local ok, vec = pcall(function()
            local aim = Vector2.new()
            return playerObj:getAimVector(aim)
        end)
        if ok and vec and vec.getX and vec.getY then
            return normalizeDirection(vec:getX(), vec:getY(), fallbackX, fallbackY)
        end
    end
    if not (playerObj and IsoUtils and getMouseX and getMouseY) then
        return fallbackX, fallbackY
    end
    local playerNum = playerObj.getPlayerNum and playerObj:getPlayerNum() or 0
    local zoom = 1.0
    local core = getCore and getCore() or nil
    if core and core.getZoom then
        local value = core:getZoom(playerNum)
        if tonumber(value) and tonumber(value) > 0 then zoom = tonumber(value) end
    end
    local z = playerObj:getZ()
    local worldX = IsoUtils.XToIso and IsoUtils.XToIso(getMouseX() * zoom, getMouseY() * zoom, z) or nil
    local worldY = IsoUtils.YToIso and IsoUtils.YToIso(getMouseX() * zoom, getMouseY() * zoom, z) or nil
    if not (worldX and worldY) then return fallbackX, fallbackY end
    return normalizeDirection(worldX - playerObj:getX(), worldY - playerObj:getY(), fallbackX, fallbackY)
end

local function getWeaponRange(weapon)
    local range = 5.0
    if weapon and weapon.getMaxRange then
        local value = weapon:getMaxRange()
        if tonumber(value) then range = tonumber(value) end
    end
    return clamp(range, MIN_RANGE, MAX_RANGE)
end

local function emitFlameCone(playerObj, weapon, dirX, dirY, fuelSpent)
    local cell = getCell and getCell() or nil
    if not (playerObj and cell) then return false end
    local range = math.min(getWeaponRange(weapon), FLAME_FUEL_RANGE_TILES)
    local firePower = 40
    if weapon and weapon.getFirePower then
        local value = weapon:getFirePower()
        if tonumber(value) then firePower = tonumber(value) end
    end
    fuelSpent = clamp(fuelSpent or DEFAULT_FLAME_FUEL_BURST, 1, DEFAULT_FLAME_FUEL_BURST)
    local fuelScale = fuelSpent / DEFAULT_FLAME_FUEL_BURST
    range = clamp(range * (0.45 + (0.55 * fuelScale)), MIN_RANGE, FLAME_FUEL_RANGE_TILES)
    local fireLife = 80 + math.floor(18 * fuelSpent)
    local fireEnergy = math.max(350, firePower * 7)
    dirX, dirY = normalizeDirection(dirX, dirY, getForwardDirection(playerObj))
    local px, py, pz = playerObj:getX(), playerObj:getY(), playerObj:getZ()
    local started = false
    for step = 1, math.floor(range + 0.5) do
        local spread = 0.18 * math.max(0, step - 1)
        local sideX, sideY = -dirY, dirX
        for offset = -1, 1 do
            if offset == 0 or step >= 3 then
                local square = cell:getGridSquare(roundToGrid(px + dirX * step + sideX * spread * offset), roundToGrid(py + dirY * step + sideY * spread * offset), roundToGrid(pz))
                if square then
                    markSquareFueled(square, fuelSpent)
                    if startFireAt(square, fireLife, fireEnergy) then started = true end
                end
                igniteCharactersNear(square, playerObj, 0.95, 260 + (fuelSpent * 25))
            end
        end
    end
    return started
end

local function onWeaponHitCharacter(attacker, target, weapon, damage)
    if not (attacker and target and weapon) then return end
    if not (weapon.isRanged and weapon:isRanged()) then return end
    local ammoType = getAmmoEffectType(weapon)
    if not isFireAmmo(ammoType) then return end
    if ammoType == "Base.FWP_12gIncendiaryShells" then
        igniteCharacter(target, 260)
        if target.getSquare then igniteAroundSquare(target:getSquare(), 1, 22, 35) end
    elseif ammoType == "Base.FlameFuel" then
        igniteCharacter(target, 360)
        if target.getSquare then igniteAroundSquare(target:getSquare(), 0, 40, 100) end
    end
end

FWPOnFlameFuelBurst = function(playerObj, weapon, fuelSpent, consumeFuelOnServer)
    local md = weapon and weapon.getModData and weapon:getModData() or nil
    if md then
        md.FWP_LastFiredAmmoType = "Base.FlameFuel"
        md.FWP_LastFiredAmmoMs = nowMs()
        if weapon and weapon.transmitModData then weapon:transmitModData() end
    end
    local dirX, dirY = getAimDirection(playerObj)
    if isClient and isClient() and sendClientCommand then
        sendClientCommand(playerObj, MODULE_NAME, COMMAND_FLAME, {
            dirX = dirX,
            dirY = dirY,
            fuelSpent = fuelSpent or DEFAULT_FLAME_FUEL_BURST,
            consumeFuel = consumeFuelOnServer == true,
            weaponId = weapon and weapon.getID and weapon:getID() or nil
        })
        debugFlame("client flame command sent fuelSpent=" .. tostring(fuelSpent or DEFAULT_FLAME_FUEL_BURST))
    else
        local started = emitFlameCone(playerObj, weapon, dirX, dirY, fuelSpent)
        debugFlame("local flame burst fuelSpent=" .. tostring(fuelSpent or DEFAULT_FLAME_FUEL_BURST) .. " started=" .. tostring(started))
    end
end

FWPOnAmmoEffectFired = function(playerObj, weapon, ammoType)
    ammoType = normalizeAmmoType(ammoType)
    if not isFireAmmo(ammoType) then return end
    if ammoType == "Base.FlameFuel" then
        FWPOnFlameFuelBurst(playerObj, weapon, 1)
        return
    end
    local md = weapon and weapon.getModData and weapon:getModData() or nil
    if md then
        md.FWP_LastFiredAmmoType = ammoType
        md.FWP_LastFiredAmmoMs = nowMs()
        if weapon and weapon.transmitModData then weapon:transmitModData() end
    end
end

Events.OnWeaponHitCharacter.Add(onWeaponHitCharacter)
print("[FWP INCENDIARY] B42 ammo-effect runtime registered")
