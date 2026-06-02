-- CSR_LighterUses.lua
-- Sandbox-tunable max uses for vanilla Lighter, Matches, and
-- LighterDisposable items. Re-applies via ScriptManager:DoParam at
-- OnInitWorld so the change covers freshly-spawned and existing items
-- (vanilla item scripts are mutable through DoParam).
--
-- Defaults match vanilla, so toggling the sandbox knobs is opt-in:
--   Lighter / LighterDisposable: 100 uses
--   Matches: 5 uses
--
-- Conflicts: any other mod that calls DoParam("MaxUses", ...) on the
-- same items will be overridden by whichever mod loads last. Setting
-- the values to 0 in sandbox preserves vanilla (we skip the DoParam).
require "CSR_FeatureFlags"

CSR_LighterUses = CSR_LighterUses or {}

local function applyMaxUses(itemId, maxUses)
    if not maxUses or maxUses <= 0 then return end
    local mgr = ScriptManager and ScriptManager.instance
    if not mgr or not mgr.getItem then return end
    pcall(function()
        local item = mgr:getItem(itemId)
        if not item or not item.DoParam then return end
        item:DoParam("MaxUses = " .. tostring(maxUses))
        local delta = 1.0 / maxUses
        item:DoParam("UseDelta = " .. string.format("%.6f", delta))
    end)
end

function CSR_LighterUses.apply()
    if not CSR_FeatureFlags or not CSR_FeatureFlags.isLighterUsesEnabled
            or not CSR_FeatureFlags.isLighterUsesEnabled() then
        return
    end
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    applyMaxUses("Base.Lighter",           tonumber(sb.LighterMaxUses)           or 0)
    applyMaxUses("Base.LighterDisposable", tonumber(sb.DisposableLighterMaxUses) or 0)
    applyMaxUses("Base.Matches",           tonumber(sb.MatchesMaxUses)           or 0)
end

if Events and Events.OnInitWorld then
    Events.OnInitWorld.Add(CSR_LighterUses.apply)
end

return CSR_LighterUses
