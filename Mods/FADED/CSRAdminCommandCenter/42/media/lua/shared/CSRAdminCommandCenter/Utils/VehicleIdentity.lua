require "CSRAdminCommandCenter/ACC_Main"

local ACC = CSRAdminCommandCenter
ACC.VehicleIdentity = ACC.VehicleIdentity or {}

local VehicleIdentity = ACC.VehicleIdentity

local function safeString(fn, fallback)
    local value = fn()
    if value ~= nil then return tostring(value) end
    return tostring(fallback or "")
end

local function safeNumber(fn, fallback)
    local value = fn()
    if value ~= nil then return tonumber(value) or tonumber(fallback) or 0 end
    return tonumber(fallback) or 0
end

local function clean(value)
    local text = tostring(value or "")
    if text == "nil" then return "" end
    return text
end

local function isDurableKeyText(key)
    key = clean(key)
    if key == "" then return false end
    if string.sub(key, 1, 4) == "sql:" then return false end
    if tonumber(key) then return false end
    return true
end

local function addUnique(out, seen, value)
    value = clean(value)
    if not isDurableKeyText(value) then return end
    if value == "" or seen[value] then return end
    out[#out + 1] = value
    seen[value] = true
end

local function modDataFor(vehicle)
    if not vehicle or not vehicle.getModData then return nil end
    local data = vehicle:getModData()
    if type(data) == "table" then return data end
    return nil
end

function VehicleIdentity.isDurableKey(key)
    return isDurableKeyText(key)
end

function VehicleIdentity.durableKeyForRow(row)
    if type(row) ~= "table" then return "" end
    local key = clean(row.vehicleKey)
    if VehicleIdentity.isDurableKey(key) then return key end
    key = clean(row.key)
    if VehicleIdentity.isDurableKey(key) then return key end
    return ""
end

function VehicleIdentity.fromVehicle(vehicle, ensureFallback)
    if not vehicle then return nil end
    if ensureFallback == nil then ensureFallback = true end
    local md = modDataFor(vehicle)
    local storedKey = ""
    if md then
        storedKey = clean(md.CSR_VehicleClaimKey)
        if not VehicleIdentity.isDurableKey(storedKey) then storedKey = "" end
    end

    local ident = {
        vehicleKey = storedKey,
        vehicleScript = safeString(function()
            if vehicle.getScriptName then return vehicle:getScriptName() end
            if vehicle.getScript and vehicle:getScript() and vehicle:getScript().getFullName then
                return vehicle:getScript():getFullName()
            end
            return ""
        end, ""),
        lastVehicleX = safeNumber(function()
            if vehicle.getX then return vehicle:getX() end
            return 0
        end, 0),
        lastVehicleY = safeNumber(function()
            if vehicle.getY then return vehicle:getY() end
            return 0
        end, 0),
        lastVehicleZ = safeNumber(function()
            if vehicle.getZ then return vehicle:getZ() end
            return 0
        end, 0),
    }

    return ident
end

function VehicleIdentity.keyCandidates(vehicle, ensureFallback)
    local out = {}
    local seen = {}
    if not vehicle then return out end

    local ident = VehicleIdentity.fromVehicle(vehicle, ensureFallback == true)
    if type(ident) == "table" then
        addUnique(out, seen, ident.vehicleKey)
    end

    local md = modDataFor(vehicle)
    if md then
        addUnique(out, seen, md.CSR_VehicleClaimKey)
    end

    return out
end

function VehicleIdentity.durableKeyForVehicle(vehicle)
    if not vehicle then return "", nil end
    local ident = VehicleIdentity.fromVehicle(vehicle, false)
    local key = VehicleIdentity.durableKeyForRow(ident)
    if key ~= "" then return key, ident end

    local candidates = VehicleIdentity.keyCandidates(vehicle, false)
    for i = 1, #candidates do
        if VehicleIdentity.isDurableKey(candidates[i]) then
            return candidates[i], ident
        end
    end
    return "", ident
end

function VehicleIdentity.vehicleHasKey(vehicle, key)
    key = clean(key)
    if key == "" then return false end
    local candidates = VehicleIdentity.keyCandidates(vehicle, false)
    for i = 1, #candidates do
        if candidates[i] == key then return true end
    end
    return false
end

local function loadedVehicleList()
    local cell = nil
    if getCell then
        cell = getCell()
    end
    if not cell and getWorld then
        local world = getWorld()
        if world and world.getCell then cell = world:getCell() end
    end
    if cell and cell.getVehicles then
        return cell:getVehicles()
    end
    return nil
end

function VehicleIdentity.findLoadedVehicleByKey(key)
    key = clean(key)
    if key == "" then return nil end

    local vehicles = loadedVehicleList()
    if not vehicles or not vehicles.size or not vehicles.get then return nil end
    local count = tonumber(vehicles:size()) or 0
    for i = 0, count - 1 do
        local vehicle = vehicles:get(i)
        if VehicleIdentity.vehicleHasKey(vehicle, key) then return vehicle end
    end
    return nil
end

local function firstNonEmpty(...)
    local values = { ... }
    for i = 1, #values do
        local value = clean(values[i])
        if value ~= "" then return value end
    end
    return ""
end

function VehicleIdentity.loadedVehicleFor(row, snap)
    local expectedKey = firstNonEmpty(
        VehicleIdentity.durableKeyForRow(row),
        VehicleIdentity.durableKeyForRow(snap))

    if expectedKey ~= "" then
        local byKey = VehicleIdentity.findLoadedVehicleByKey(expectedKey)
        if byKey then
            return byKey, VehicleIdentity.fromVehicle(byKey, false), "", "vehicleKey"
        end

        return nil, nil, "", "vehicleKey"
    end

    return nil, nil, "", "no_csr_vehicle_key"
end

function VehicleIdentity.keyForRow(row)
    if type(row) ~= "table" then return "" end
    local key = VehicleIdentity.durableKeyForRow(row)
    if key ~= "" then return key end
    if tostring(row.kind or "") == "vehicle" then return "" end
    return tostring(row.id or "")
end

return VehicleIdentity
