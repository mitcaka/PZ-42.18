-- Server-side B42 ammo-effect fire runtime for FWP flame fuel and incendiary shells.
if isClient() or not isServer() then return end

local MODULE_NAME = "FWPIncendiaryAmmo"
local COMMAND_FLAME = "Flame"
local MIN_INTERVAL_MS = 1000
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
    print("[FWP INCENDIARY] server " .. tostring(message))
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

local function getWeaponRange(weapon)
    local range = 5.0
    if weapon and weapon.getMaxRange then
        local value = weapon:getMaxRange()
        if tonumber(value) then range = tonumber(value) end
    end
    return clamp(range, MIN_RANGE, MAX_RANGE)
end

local function getWeaponFullType(weapon)
    if not weapon then return nil end
    if weapon.getFullType then
        local ok, fullType = pcall(weapon.getFullType, weapon)
        if ok and fullType then return tostring(fullType) end
    end
    if weapon.getModule and weapon.getType then
        return tostring(weapon:getModule()) .. "." .. tostring(weapon:getType())
    end
    return nil
end

local function isFlameFuelWeapon(weapon)
    if not (weapon and weapon.isRanged and weapon:isRanged()) then return false end
    if FWPGetAmmoItemKey then
        local ok, ammoItem = pcall(FWPGetAmmoItemKey, weapon)
        if ok and ammoItem == "Base.FlameFuel" then return true end
    end
    if weapon.getAmmoType then
        local ok, ammoType = pcall(function() return weapon:getAmmoType() end)
        local text = ok and tostring(ammoType or "") or ""
        if text == "fwp:flame_fuel" or text == "Base.FlameFuel" then return true end
    end
    local fullType = getWeaponFullType(weapon)
    return fullType == "Base.WD_Flame" or fullType == "Base.Musk" or fullType == "Base.M2A1"
end

local function findPlayerWeapon(playerObj, weaponId)
    if not playerObj then return nil end
    local primary = playerObj.getPrimaryHandItem and playerObj:getPrimaryHandItem() or nil
    if primary and primary.getID and weaponId and primary:getID() == weaponId then return primary end
    local secondary = playerObj.getSecondaryHandItem and playerObj:getSecondaryHandItem() or nil
    if secondary and secondary.getID and weaponId and secondary:getID() == weaponId then return secondary end
    return primary
end

local function getCurrentAmmoCount(weapon)
    if weapon and weapon.getCurrentAmmoCount then
        local ok, count = pcall(function() return weapon:getCurrentAmmoCount() end)
        if ok and tonumber(count) then return tonumber(count) end
    end
    return 0
end

local function hasUnlimitedAmmo(playerObj)
    if playerObj and playerObj.isUnlimitedAmmo then
        local ok, unlimited = pcall(function() return playerObj:isUnlimitedAmmo() end)
        if ok and unlimited == true then return true end
    end
    return false
end

local function consumeFlameFuel(playerObj, weapon, requestedFuel)
    requestedFuel = clamp(requestedFuel or DEFAULT_FLAME_FUEL_BURST, 1, DEFAULT_FLAME_FUEL_BURST)
    if hasUnlimitedAmmo(playerObj) then
        return requestedFuel
    end
    local currentAmmo = getCurrentAmmoCount(weapon)
    if currentAmmo <= 0 then
        return 0
    end
    local spent = math.min(requestedFuel, currentAmmo)
    if weapon and weapon.setCurrentAmmoCount then
        pcall(function()
            weapon:setCurrentAmmoCount(math.max(0, currentAmmo - spent))
        end)
    end
    if weapon and weapon.transmitModData then
        pcall(weapon.transmitModData, weapon)
    end
    if syncHandWeaponFields then
        pcall(syncHandWeaponFields, playerObj, weapon)
    end
    return spent
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

FWPOnFlameFuelBurst = function(playerObj, weapon, fuelSpent)
    local md = weapon and weapon.getModData and weapon:getModData() or nil
    if md then
        md.FWP_LastFiredAmmoType = "Base.FlameFuel"
        md.FWP_LastFiredAmmoMs = nowMs()
        if weapon and weapon.transmitModData then weapon:transmitModData() end
    end
    local dirX, dirY = getForwardDirection(playerObj)
    emitFlameCone(playerObj, weapon, dirX, dirY, fuelSpent)
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

local function onClientCommand(module, command, playerObj, args)
    if module ~= MODULE_NAME or command ~= COMMAND_FLAME then return end
    if not playerObj then return end
    local weapon = findPlayerWeapon(playerObj, args and args.weaponId or nil)
    if not weapon then
        debugFlame("flame command rejected: no player weapon")
        return
    end
    if not isFlameFuelWeapon(weapon) then
        debugFlame("flame command rejected: weapon is not flame fuel")
        return
    end
    local md = weapon.getModData and weapon:getModData() or nil
    local t = nowMs()
    if md and md.FWP_IncendiaryLastFlameMs and (t - tonumber(md.FWP_IncendiaryLastFlameMs)) < MIN_INTERVAL_MS then return end
    if md then
        md.FWP_IncendiaryLastFlameMs = t
        if weapon.transmitModData then weapon:transmitModData() end
    end
    local fuelSpent = clamp(args and args.fuelSpent or DEFAULT_FLAME_FUEL_BURST, 1, DEFAULT_FLAME_FUEL_BURST)
    if args and args.consumeFuel then
        fuelSpent = consumeFlameFuel(playerObj, weapon, fuelSpent)
        if fuelSpent <= 0 then
            debugFlame("flame command rejected: no server fuel")
            return
        end
    end
    local started = emitFlameCone(playerObj, weapon, args and args.dirX, args and args.dirY, fuelSpent)
    debugFlame("flame command accepted fuelSpent=" .. tostring(fuelSpent) .. " started=" .. tostring(started))
end

Events.OnWeaponHitCharacter.Add(onWeaponHitCharacter)
Events.OnClientCommand.Add(onClientCommand)
print("[FWP INCENDIARY] server ammo-effect runtime registered")
