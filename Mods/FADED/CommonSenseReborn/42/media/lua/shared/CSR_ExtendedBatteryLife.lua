require "CSR_FeatureFlags"

CSR_ExtendedBatteryLife = CSR_ExtendedBatteryLife or {}

-- B42.18 vanilla drain rates for battery-powered light sources.
local LIGHT_DELTAS = {
    HandTorch                = 0.006,
    FlashLight_AngleHead    = 0.006,
    FlashLight_AngleHead_Army = 0.0057,
    Torch                    = 0.007,
    PenLight                 = 0.001,
    Lantern_CraftedElectric  = 0.007,
    Flashlight_Crafted       = 0.008,
}

local function scriptItem(id)
    local mgr = ScriptManager and ScriptManager.instance
    if not mgr or not mgr.getItem then return nil end
    return mgr:getItem("Base." .. id) or mgr:getItem(id)
end

function CSR_ExtendedBatteryLife.apply()
    if not CSR_FeatureFlags
            or not CSR_FeatureFlags.isExtendedBatteryLifeEnabled
            or not CSR_FeatureFlags.isExtendedBatteryLifeEnabled() then
        return
    end

    local multiplier = 1
    if CSR_FeatureFlags.getBatteryLifeMultiplier then
        multiplier = CSR_FeatureFlags.getBatteryLifeMultiplier()
    end
    if multiplier <= 1 then return end

    for id, baseline in pairs(LIGHT_DELTAS) do
        local item = scriptItem(id)
        if item and item.DoParam then
            item:DoParam("UseDelta = " .. string.format("%.8f", baseline / multiplier))
        end
    end
end

local function register(eventName)
    if Events and Events[eventName] then
        Events[eventName].Add(CSR_ExtendedBatteryLife.apply)
    end
end

register("OnInitWorld")
register("OnGameTimeLoaded")
register("OnNewGame")
register("OnServerStarted")

return CSR_ExtendedBatteryLife
