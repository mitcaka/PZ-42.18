require "CSR_FeatureFlags"
require "CSR_PowerBar"
require "CSR_PowerLine"

-- CSR-side adapter for Solar Never Faded's optional bridge API.
-- This file never requires SNF files directly; CSR keeps no hard dependency.
CSR_SolarNeverFadedBridge = CSR_SolarNeverFadedBridge or {}

local Bridge = CSR_SolarNeverFadedBridge
local PROVIDER_ID = "CSR"
local LABEL = "CSR Wiring"

local function clamp(value, minValue, maxValue)
    value = tonumber(value)
    if not value then return minValue end
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function isPowerBarEnabled()
    return CSR_PowerBar
        and CSR_PowerBar.isFeatureEnabled
        and CSR_PowerBar.isFeatureEnabled() == true
end

local function isPowerLineEnabled()
    return CSR_PowerLine
        and CSR_PowerLine.isEnabled
        and CSR_PowerLine.isEnabled() == true
end

local function getConfiguredWiringReach()
    local reach = 0
    if isPowerBarEnabled() and CSR_PowerBar.maxWires then
        reach = math.max(reach, tonumber(CSR_PowerBar.maxWires()) or 0)
    end
    if isPowerLineEnabled() and CSR_PowerLine.maxLineLength then
        reach = math.max(reach, tonumber(CSR_PowerLine.maxLineLength()) or 0)
    end
    return reach
end

function Bridge.getAPI()
    local api = SolarNeverFadedCSRBridge
    if type(api) == "table" then return api end
    return nil
end

function Bridge.isAvailable()
    local api = Bridge.getAPI()
    return api ~= nil
end

function Bridge.isEnabled()
    local api = Bridge.getAPI()
    if not api then return false end
    if type(api.isEnabled) == "function" then
        return api.isEnabled() == true
    end
    return true
end

function Bridge.hasCSRWiring()
    return isPowerBarEnabled() or isPowerLineEnabled()
end

function Bridge.getWiringModifiers(_bankStatus)
    if not Bridge.hasCSRWiring() then return nil end

    local reach = getConfiguredWiringReach()
    if reach <= 0 then return nil end

    return {
        rangeBonus = math.floor(clamp(reach, 0, 15)),
        efficiencyBonus = 5,
        drainMultiplier = 0.95,
        label = LABEL,
    }
end

function Bridge.register()
    local api = Bridge.getAPI()
    if not api or type(api.registerWiringProvider) ~= "function" then
        return false
    end

    api.registerWiringProvider(PROVIDER_ID, Bridge.getWiringModifiers)
    Bridge._registeredApi = api
    return true
end

function Bridge.unregister()
    local api = Bridge.getAPI() or Bridge._registeredApi
    if api and type(api.unregisterWiringProvider) == "function" then
        api.unregisterWiringProvider(PROVIDER_ID)
    end
    Bridge._registeredApi = nil
end

function Bridge.isSolarBattery(item)
    local api = Bridge.getAPI()
    if not api or type(api.isSolarBattery) ~= "function" then return false end
    return api.isSolarBattery(item) == true
end

function Bridge.getBatteryCapacity(item)
    local api = Bridge.getAPI()
    if not api or type(api.getBatteryCapacity) ~= "function" then return nil end
    return api.getBatteryCapacity(item)
end

function Bridge.getSolarMultiplierAt(x, y, z)
    local api = Bridge.getAPI()
    if not api or type(api.getSolarMultiplierAt) ~= "function" then return 0, "unavailable" end
    return api.getSolarMultiplierAt(x, y, z)
end

function Bridge.getLoadedBankStatusAt(x, y, z)
    local api = Bridge.getAPI()
    if not api or type(api.getLoadedBankStatusAt) ~= "function" then return nil end
    return api.getLoadedBankStatusAt(x, y, z)
end

function Bridge.findNearestLoadedBank(x, y, z, radius)
    local api = Bridge.getAPI()
    if not api or type(api.findNearestLoadedBank) ~= "function" then return nil end
    return api.findNearestLoadedBank(x, y, z, radius)
end

local function install()
    Bridge.register()
end

Bridge.register()

if Events then
    if Events.OnGameStart then Events.OnGameStart.Add(install) end
    if Events.OnServerStarted then Events.OnServerStarted.Add(install) end
    if Events.OnTick then
        local tries = 0
        local function retryInstall()
            tries = tries + 1
            if Bridge.register() or tries >= 120 then
                Events.OnTick.Remove(retryInstall)
            end
        end
        Events.OnTick.Add(retryInstall)
    end
end

return Bridge
