-- Server-side fire spawning for B42 FWP flamethrowers.
if isClient() then return end
if FWP_USE_INCENDIARY_AMMO_RUNTIME then return end

local MODULE_NAME = "FWPFlamethrower"
local COMMAND_FIRE = "Fire"
local MIN_INTERVAL_MS = 120
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

local function normalizeDirection(dx, dy)
    dx = tonumber(dx) or 0
    dy = tonumber(dy) or 0
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= 0.001 then return 0, 1 end
    return dx / len, dy / len
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
    if primary and not weaponId then return primary end
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

local function startFireAt(square, fireEnergy)
    if not (square and IsoFireManager and IsoFireManager.StartFire and getCell) then return false end
    fireEnergy = math.max(10, tonumber(fireEnergy) or 40)
    local ok = pcall(IsoFireManager.StartFire, getCell(), square, true, fireEnergy)
    if ok then return true end
    ok = pcall(IsoFireManager.StartFire, getCell(), square, true, 110, fireEnergy)
    return ok == true
end

local function onClientCommand(module, command, playerObj, args)
    if module ~= MODULE_NAME or command ~= COMMAND_FIRE then return end
    if not (playerObj and args) then return end

    local weapon = findPlayerWeapon(playerObj, args.weaponId)
    if not isFlameFuelWeapon(weapon) then return end
    if getCurrentAmmoCount(weapon) <= 0 then return end

    local md = weapon.getModData and weapon:getModData() or nil
    local t = nowMs()
    if md and md.FWP_FlameServerLastMs and (t - tonumber(md.FWP_FlameServerLastMs)) < MIN_INTERVAL_MS then
        return
    end
    if md then md.FWP_FlameServerLastMs = t end

    local dirX, dirY = normalizeDirection(args.dirX, args.dirY)
    local range = clamp(args.range, MIN_RANGE, MAX_RANGE)
    local firePower = clamp(args.firePower, 10, 90)
    local cell = getCell and getCell() or nil
    if not cell then return end

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
                    startFireAt(square, firePower)
                end
            end
        end
    end
end

Events.OnClientCommand.Add(onClientCommand)
