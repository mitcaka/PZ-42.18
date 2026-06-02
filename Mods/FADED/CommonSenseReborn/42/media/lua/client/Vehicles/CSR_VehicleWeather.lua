--
-- CSR_VehicleWeather (client)
-- =========================================================================
-- Open-cabin weather exposure: rain and snow get inside the vehicle when a
-- door is missing/open, the windshield is missing/destroyed, or windows are
-- open/broken. Wets clothing first (water-resistant gear helps), overflow
-- hits body wetness. Optional cold-temperature drain. Optional foraging-
-- sight penalty when the windshield is gone.
--
-- Cadence: probed on a throttled player update, about once every 10 real
-- seconds per local player. That is responsive enough for testing while
-- still avoiding per-tick vehicle scans.
--
-- Disabled by sandbox EnableVehicleWeatherExposure.
-- =========================================================================

CSR_VehicleWeather = CSR_VehicleWeather or {}

local CSR_FeatureFlags = CSR_FeatureFlags

local function sandbox()
    return SandboxVars and SandboxVars.CommonSenseReborn or {}
end

local function intensityScale()
    local v = sandbox().VehicleWeatherIntensity or 100
    return (v / 100)
end

-- =========================================================================
-- Weather + exposure scoring
-- =========================================================================

local function num(v) return tonumber(v) or 0 end

local function getPrecipitation()
    local cm = getClimateManager and getClimateManager() or nil
    if not cm then return 0, 0 end
    local rain = cm.getPrecipitationIntensity and num(cm:getPrecipitationIntensity()) or 0
    local snow = cm.getSnowStrength and num(cm:getSnowStrength()) or 0
    return rain, snow
end

local function partId(part)
    if not part or not part.getId then return "" end
    return string.lower(tostring(part:getId() or ""))
end

local function isWindshieldPart(part)
    local id = partId(part)
    return string.find(id, "windshield", 1, true) ~= nil
        or string.find(id, "windscreen", 1, true) ~= nil
end

local function isRearWindshieldPart(part)
    if not isWindshieldPart(part) then return false end
    local id = partId(part)
    return string.find(id, "rear", 1, true) ~= nil
        or string.find(id, "back", 1, true) ~= nil
end

local function partHasItem(part)
    if not part or not part.getInventoryItem then return true end
    return part:getInventoryItem() ~= nil
end

local function windowIsOpen(win)
    if not win or not win.isOpen then return false end
    if win.isOpenable and not win:isOpenable() then return false end
    return win:isOpen() == true
end

local function windowIsDestroyed(win)
    if not win or not win.isDestroyed then return false end
    return win:isDestroyed() == true
end

local function doorIsOpen(door)
    if not door or not door.isOpen then return false end
    return door:isOpen() == true
end

local function computeExposure(vehicle)
    if not vehicle then return 0 end
    local exposure = 0
    local scored = {}

    local function scorePart(part)
        if not part or scored[part] then return end
        scored[part] = true
        local id = partId(part)
        local hasItem = partHasItem(part)
        local win = part.getWindow and part:getWindow() or nil
        local door = part.getDoor and part:getDoor() or nil
        if win then
            local ws = isWindshieldPart(part)
            local rear = isRearWindshieldPart(part)
            if (not hasItem) or windowIsDestroyed(win) then
                if ws then
                    exposure = exposure + (rear and 0.25 or 0.45)
                else
                    exposure = exposure + 0.12
                end
            elseif windowIsOpen(win) then
                exposure = exposure + (ws and 0.16 or 0.08)
            end
        elseif isWindshieldPart(part) and not hasItem then
            exposure = exposure + (isRearWindshieldPart(part) and 0.25 or 0.45)
        elseif string.find(id, "window", 1, true) and not hasItem then
            exposure = exposure + 0.12
        end
        if door then
            if not hasItem then
                exposure = exposure + 0.18
            elseif doorIsOpen(door) then
                exposure = exposure + 0.12
            end
        elseif string.find(id, "door", 1, true) and not hasItem then
            exposure = exposure + 0.18
        end
    end

    if vehicle.getPartCount and vehicle.getPartByIndex then
        local count = num(vehicle:getPartCount())
        for i = 0, count - 1 do
            scorePart(vehicle:getPartByIndex(i))
        end
    end

    if exposure > 1.0 then exposure = 1.0 end
    return exposure
end

local function hasBreachedWindshield(vehicle)
    if not vehicle or not vehicle.getPartCount or not vehicle.getPartByIndex then return false end
    local count = num(vehicle:getPartCount())
    for i = 0, count - 1 do
        local part = vehicle:getPartByIndex(i)
        if part and isWindshieldPart(part) then
            if part.getInventoryItem and not part:getInventoryItem() then return true end
            if part.getWindow then
                local win = part:getWindow()
                if win and windowIsDestroyed(win) then return true end
            end
        end
    end
    return false
end

-- =========================================================================
-- Wetness application (clothing first, overflow to body)
-- =========================================================================

local function applyWetness(player, target)
    if target <= 0 then return end
    local inv = player:getInventory()
    if not inv then return end
    local items = inv:getItems()
    if not items then return end
    local equipped = {}
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and player:isEquipped(item)
            and item.getCategory and item:getCategory() == "Clothing"
            and item.getClothingItem and item:getClothingItem()
            and item.getCoveredParts and item:getCoveredParts()
            and item:getCoveredParts():size() > 0
        then
            equipped[#equipped + 1] = item
        end
    end
    table.sort(equipped, function(a, b)
        local ar = a.getWaterResistance and num(a:getWaterResistance()) or 0
        local br = b.getWaterResistance and num(b:getWaterResistance()) or 0
        return ar > br
    end)
    local remaining = target
    for _, item in ipairs(equipped) do
        if remaining <= 0 then break end
        local res = item.getWaterResistance and num(item:getWaterResistance()) or 0
        local absorbed = remaining * (1 - res * 0.6)
        if absorbed > 0 and item.getWetness and item.setWetness then
            local newWet = num(item:getWetness()) + absorbed
            if newWet > 100 then newWet = 100 end
            item:setWetness(newWet)
            remaining = remaining - absorbed * 0.4
        end
    end
    if remaining > 0 then
        local bd = player:getBodyDamage()
        if bd and bd.increaseBodyWetness then
            bd:increaseBodyWetness(remaining / 18)
        end
    end
end

local function applyTemperatureDrain(player, exposure, weatherKind)
    if sandbox().VehicleWeatherTemperature == false then return end
    local cm = getClimateManager()
    if not cm then return end
    local airTemp
    if cm.getAirTemperatureForCharacter then
        airTemp = num(cm:getAirTemperatureForCharacter(player, false))
    elseif cm.getTemperature then
        airTemp = num(cm:getTemperature())
    else
        airTemp = 20
    end
    -- Any rain / snow exposure cools you, scaled by how cold it already is.
    -- (Previously we bailed out for airTemp >= 15 + non-snow rain, which
    --  effectively disabled the drain for mid-summer storms.)
    local stats = player:getStats()
    if not stats or not stats.getTemperature or not stats.setTemperature then return end
    local cur = num(stats:getTemperature())
    local drop = exposure * 0.3
    if weatherKind == "snow" then drop = drop + 0.2 end
    if airTemp < 5 then drop = drop + 0.15 end
    if airTemp >= 15 and weatherKind ~= "snow" then drop = drop * 0.4 end
    if cur - drop > 30 then
        stats:setTemperature(cur - drop)
    end
end

-- =========================================================================
-- Per-player driver
-- =========================================================================

local function tickPlayer(player)
    if not player or player:isDead() then return end
    if not CSR_FeatureFlags or not CSR_FeatureFlags.isVehicleWeatherExposureEnabled() then return end
    local vehicle = player.getVehicle and player:getVehicle() or nil
    if not vehicle then return end
    local rain, snow = getPrecipitation()
    local debug = false
    if rain <= 0 and snow <= 0 then
        if debug then print("[CSR VehicleWeather] skip: no precipitation (rain=", rain, " snow=", snow, ")") end
        return
    end
    local exposure = computeExposure(vehicle)
    if exposure <= 0 then
        if debug then print("[CSR VehicleWeather] skip: sealed cabin (rain=", rain, " snow=", snow, ")") end
        return
    end

    local speedKmh = math.abs(num(vehicle.getCurrentSpeedKmHour and vehicle:getCurrentSpeedKmHour()))
    local speedMul = 1 + (speedKmh / 30)
    local weatherKind = (snow > 0) and "snow" or "rain"
    local intensity = (snow > 0 and snow or rain)

    local target = exposure * intensity * 6.0 * speedMul * intensityScale()
    if debug then
        print(string.format("[CSR VehicleWeather] tick exposure=%.2f %s=%.2f speed=%.1f target=%.2f",
            exposure, weatherKind, intensity, speedKmh, target))
    end
    applyWetness(player, target)
    applyTemperatureDrain(player, exposure, weatherKind)
end

local _lastWeatherPulse = {}

local function nowMs()
    if getTimestampMs then return getTimestampMs() end
    if os and os.time then return os.time() * 1000 end
    return 0
end

local function onPlayerUpdate(player)
    if not CSR_FeatureFlags or not CSR_FeatureFlags.isVehicleWeatherExposureEnabled() then return end
    if not player then return end
    local key = player.getPlayerNum and player:getPlayerNum() or 0
    local now = nowMs()
    if now > 0 and _lastWeatherPulse[key] and now - _lastWeatherPulse[key] < 10000 then return end
    _lastWeatherPulse[key] = now
    tickPlayer(player)
end

local function onEveryOneMinute()
    if Events and Events.OnPlayerUpdate then return end
    if not CSR_FeatureFlags or not CSR_FeatureFlags.isVehicleWeatherExposureEnabled() then return end
    local n = getNumActivePlayers and getNumActivePlayers() or 1
    for i = 0, n - 1 do
        local p = getSpecificPlayer(i)
        if p then tickPlayer(p) end
    end
end

if Events and Events.OnPlayerUpdate then
    Events.OnPlayerUpdate.Add(onPlayerUpdate)
else
    Events.EveryOneMinute.Add(onEveryOneMinute)
end

-- =========================================================================
-- Foraging sight penalty when windshield is missing / destroyed
-- =========================================================================

if forageSystem and forageSystem.getLightLevelPenalty and not forageSystem.__csr_lightPatched then
    forageSystem.__csr_lightPatched = true
    local _orig = forageSystem.getLightLevelPenalty
    function forageSystem.getLightLevelPenalty(_character, _square, _doReduction)
        local penalty = _orig(_character, _square, _doReduction)
        if not CSR_FeatureFlags or not CSR_FeatureFlags.isVehicleWeatherExposureEnabled() then
            return penalty
        end
        if not (sandbox().VehicleWeatherForagePenalty ~= false) then return penalty end
        local v = _character and _character.getVehicle and _character:getVehicle() or nil
        if not v then return penalty end
        if not hasBreachedWindshield(v) then return penalty end
        local rain, snow = getPrecipitation()
        local extra = 0.3 + (rain + snow) * 0.5
        local speedKmh = math.abs(num(v.getCurrentSpeedKmHour and v:getCurrentSpeedKmHour()))
        extra = extra + (speedKmh / 60)
        return num(penalty) + extra
    end
end
