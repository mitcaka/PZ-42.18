-- B42 flamethrower runtime for FWP flame-fuel weapons.
if isServer() then return end
if FWP_USE_INCENDIARY_AMMO_RUNTIME then return end

local MODULE_NAME = "FWPFlamethrower"
local COMMAND_FIRE = "Fire"
local MIN_INTERVAL_MS = 140
local MIN_RANGE = 2.0
local MAX_RANGE = 8.0

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
    return getWeaponFullType(weapon) == "Base.WD_Flame" or getWeaponFullType(weapon) == "Base.Musk" or getWeaponFullType(weapon) == "Base.M2A1"
end

local function hasUnlimitedAmmo(playerObj)
    if getDebug and getDebugOptions and getDebug() and getDebugOptions():getBoolean("Cheat.Player.UnlimitedAmmo") then
        return true
    end
    if playerObj and playerObj.isUnlimitedAmmo then
        local ok, unlimited = pcall(function() return playerObj:isUnlimitedAmmo() end)
        return ok and unlimited == true
    end
    return false
end

local function getCurrentAmmoCount(weapon)
    if weapon and weapon.getCurrentAmmoCount then
        local ok, count = pcall(function() return weapon:getCurrentAmmoCount() end)
        if ok and tonumber(count) then return tonumber(count) end
    end
    return 0
end

local function canEmitFlame(playerObj, weapon)
    if not isFlameFuelWeapon(weapon) then return false end
    if weapon.isJammed then
        local ok, jammed = pcall(function() return weapon:isJammed() end)
        if ok and jammed then return false end
    end
    return hasUnlimitedAmmo(playerObj) or getCurrentAmmoCount(weapon) > 0
end

local function getWeaponRange(weapon)
    local range = 5.0
    if weapon and weapon.getMaxRange then
        local ok, value = pcall(function() return weapon:getMaxRange() end)
        if ok and tonumber(value) then range = tonumber(value) end
    end
    return clamp(range, MIN_RANGE, MAX_RANGE)
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
    if not (playerObj and IsoUtils and getMouseX and getMouseY) then
        return fallbackX, fallbackY
    end

    local playerNum = playerObj.getPlayerNum and playerObj:getPlayerNum() or 0
    local zoom = 1.0
    local core = getCore and getCore() or nil
    if core and core.getZoom then
        local ok, value = pcall(core.getZoom, core, playerNum)
        if ok and tonumber(value) and tonumber(value) > 0 then zoom = tonumber(value) end
    end

    local z = playerObj:getZ()
    local worldX = IsoUtils.XToIso and IsoUtils.XToIso(getMouseX() * zoom, getMouseY() * zoom, z) or nil
    local worldY = IsoUtils.YToIso and IsoUtils.YToIso(getMouseX() * zoom, getMouseY() * zoom, z) or nil
    if not (worldX and worldY) then return fallbackX, fallbackY end
    return normalizeDirection(worldX - playerObj:getX(), worldY - playerObj:getY(), fallbackX, fallbackY)
end

local function startFireAt(square, fireEnergy)
    if not (square and IsoFireManager and IsoFireManager.StartFire and getCell) then return false end
    fireEnergy = math.max(10, tonumber(fireEnergy) or 40)
    local ok = pcall(IsoFireManager.StartFire, getCell(), square, true, fireEnergy)
    if ok then return true end
    ok = pcall(IsoFireManager.StartFire, getCell(), square, true, 110, fireEnergy)
    return ok == true
end

local function igniteCharactersNear(square, playerObj, radius)
    if not (square and square.getMovingObjects) then return end
    local ok, moving = pcall(function() return square:getMovingObjects() end)
    if not (ok and moving) then return end
    local sx, sy, sz = square:getX(), square:getY(), square:getZ()
    radius = tonumber(radius) or 0.85
    for i = 0, moving:size() - 1 do
        local obj = moving:get(i)
        if obj and obj ~= playerObj and obj.getX and obj.getY and obj.getZ and obj.SetOnFire then
            local dz = math.abs((obj:getZ() or sz) - sz)
            if dz < 0.5 then
                local dx = obj:getX() - sx
                local dy = obj:getY() - sy
                if (dx * dx + dy * dy) <= radius * radius then
                    pcall(obj.SetOnFire, obj)
                end
            end
        end
    end
end

local function emitFlameLocal(playerObj, weapon, dirX, dirY)
    local cell = getCell and getCell() or nil
    if not (playerObj and cell) then return false end
    local range = getWeaponRange(weapon)
    local firePower = 40
    if weapon and weapon.getFirePower then
        local ok, value = pcall(function() return weapon:getFirePower() end)
        if ok and tonumber(value) then firePower = tonumber(value) end
    end
    dirX, dirY = normalizeDirection(dirX, dirY, getForwardDirection(playerObj))

    local started = false
    local px, py, pz = playerObj:getX(), playerObj:getY(), playerObj:getZ()
    for step = 1, math.floor(range + 0.5) do
        local spread = 0.18 * math.max(0, step - 1)
        local sideX, sideY = -dirY, dirX
        for offset = -1, 1 do
            if offset == 0 or step >= 3 then
                local tx = px + dirX * step + sideX * spread * offset
                local ty = py + dirY * step + sideY * spread * offset
                local square = cell:getGridSquare(roundToGrid(tx), roundToGrid(ty), roundToGrid(pz))
                if square then
                    if startFireAt(square, firePower) then started = true end
                    igniteCharactersNear(square, playerObj, 0.95)
                end
            end
        end
    end
    return started
end

local function onWeaponSwing(playerObj, weapon)
    if not canEmitFlame(playerObj, weapon) then return end
    local md = weapon.getModData and weapon:getModData() or nil
    local t = nowMs()
    if md and md.FWP_FlameLastMs and (t - tonumber(md.FWP_FlameLastMs)) < MIN_INTERVAL_MS then
        return
    end
    if md then md.FWP_FlameLastMs = t end

    local dirX, dirY = getAimDirection(playerObj)
    if isClient and isClient() and sendClientCommand then
        sendClientCommand(playerObj, MODULE_NAME, COMMAND_FIRE, {
            weaponId = weapon.getID and weapon:getID() or nil,
            dirX = dirX,
            dirY = dirY,
            range = getWeaponRange(weapon),
            firePower = weapon.getFirePower and weapon:getFirePower() or 40
        })
    else
        emitFlameLocal(playerObj, weapon, dirX, dirY)
    end
end

Events.OnWeaponSwing.Add(onWeaponSwing)
print("[FWP FLAME] B42 flamethrower runtime registered")
