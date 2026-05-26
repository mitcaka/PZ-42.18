local function FWPRegisterAmmoType(key, itemKey)
    if not (AmmoType and AmmoType.register) then
        return false
    end
    local ok, err = pcall(function()
        AmmoType.register(key, itemKey)
    end)
    if not ok and print then
        print("[FWP REGISTRY] AmmoType.register failed for " .. tostring(key) .. " -> " .. tostring(itemKey) .. ": " .. tostring(err))
    end
    return ok
end
local function FWPRegisterItemTag(tag)
    if Registries and Registries.ItemTags then
        local ok = pcall(function()
            Registries.ItemTags:add(tag)
        end)
        if ok then return end
    end
    if ItemTag and ItemTag.register then
        pcall(function()
            ItemTag.register(tag)
        end)
    end
end
FWPBodyLocation = FWPBodyLocation or {}
FWPBodyLocation.STUCK = FWPBodyLocation.STUCK or ItemBodyLocation.register("fwp:Stuck")
FWPBodyLocation.NV_EYES = FWPBodyLocation.NV_EYES or ItemBodyLocation.register("fwp:NV_Eyes")
FWPBodyLocation.SLING = FWPBodyLocation.SLING or ItemBodyLocation.register("fwp:FWPSling")
FWPRegisterItemTag("fwp:xbow")
FWPRegisterItemTag("fwp:slingshot")

-- FWP custom AmmoType registry bridges for B42.
FWPRegisterAmmoType("fwp:223_bullets", "Base.223Bullets")
FWPRegisterAmmoType("fwp:bb177", "Base.BB177")
FWPRegisterAmmoType("fwp:pb68", "Base.PB68")
FWPRegisterAmmoType("fwp:bullets45_lc", "Base.Bullets45LC")
FWPRegisterAmmoType("fwp:410g_shotgun_shells", "Base.410gShotgunShells")
FWPRegisterAmmoType("fwp:bullets50_mag", "Base.Bullets50MAG")
FWPRegisterAmmoType("fwp:545x39_bullets", "Base.545x39Bullets")
FWPRegisterAmmoType("fwp:40_heround", "Base.40HERound")
FWPRegisterAmmoType("fwp:40_incround", "Base.40INCRound")
FWPRegisterAmmoType("fwp:arrow_fiberglass", "Base.Arrow_Fiberglass")
FWPRegisterAmmoType("fwp:bolt_bear", "Base.Bolt_Bear")
FWPRegisterAmmoType("fwp:sling_shot_ammo_rock", "Base.SlingShotAmmo_Rock")
FWPRegisterAmmoType("fwp:sling_shot_ammo_marble", "Base.SlingShotAmmo_Marble")
FWPRegisterAmmoType("fwp:bullets22", "Base.Bullets22")
FWPRegisterAmmoType("fwp:762x39_bullets", "Base.762x39Bullets")
FWPRegisterAmmoType("fwp:50_bmgbullets", "Base.50BMGBullets")
FWPRegisterAmmoType("fwp:flare", "Base.Flare")
FWPRegisterAmmoType("fwp:flame_fuel", "Base.FlameFuel")
FWPRegisterAmmoType("fwp:water_ammo", "Base.WaterAmmo")
FWPRegisterAmmoType("fwp:smoke", "Base.Smoke")
FWPRegisterAmmoType("fwp:20g_shotgun_shells", "Base.20gShotgunShells")
FWPRegisterAmmoType("fwp:10g_shotgun_shells", "Base.10gShotgunShells")
FWPRegisterAmmoType("fwp:3006_bullets", "Base.3006Bullets")
FWPRegisterAmmoType("fwp:bullets57", "Base.Bullets57")
FWPRegisterAmmoType("fwp:bullets380", "Base.Bullets380")
FWPRegisterAmmoType("fwp:herocket", "Base.HERocket")
FWPRegisterAmmoType("fwp:762x54r_bullets", "Base.762x54rBullets")
FWPRegisterAmmoType("fwp:4g_shotgun_shells", "Base.4gShotgunShells")
FWPRegisterAmmoType("fwp:bullets4570", "Base.Bullets4570")
FWPRegisterItemTag("fwp:torch")
FWPRegisterItemTag("fwp:flex")
FWPRegisterItemTag("fwp:canignite")
FWPRegisterAmmoType("fwp:12g_incendiary_shells", "Base.FWP_12gIncendiaryShells")
