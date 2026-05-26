FWP_BOWS = FWP_BOWS or {}

local function normalizeFullType(fullType)
    if not fullType then
        return nil
    end
    fullType = tostring(fullType)
    if fullType:sub(1, 10) == "Base.Base." then
        fullType = "Base." .. fullType:sub(11)
    end
    local colonPos = fullType:find(":", 1, true)
    if colonPos then
        local moduleName = fullType:sub(1, colonPos - 1)
        local itemName = fullType:sub(colonPos + 1)
        if moduleName ~= "" and itemName ~= "" then
            if moduleName:lower() == "base" then
                moduleName = "Base"
            end
            fullType = moduleName .. "." .. itemName
        end
    end
    if not fullType:find(".", 1, true) then
        fullType = "Base." .. fullType
    end
    return fullType
end

local function bow(id, tension, damageScale, reloadDuration)
    return {
        id = id,
        class = "bow",
        requiresCock = false,
        visualPartSlot = "AMMO",
        ammoPriority = { "Base.Arrow_Fiberglass" },
        defaultAmmoType = "Base.Arrow_Fiberglass",
        defaultFlightVisualItem = "Base.Arrow_Fiberglass",
        defaultFloorItemType = "Base.Arrow_Fiberglass",
        speedTilesPerSec = 15.0,
        minFlight = 0.18,
        maxFlight = 1.40,
        startZBias = 0.72,
        arcZ = 0.22,
        worldOzMax = 0.95,
        maxTargetDistance = 55.0,
        impactDamageRadius = 0.90,
        damageScale = damageScale or 1.85,
        tensionPower = tension or 5.0,
        dropStartRange = 14.0,
        dropPerTile = 0.065,
        groundImpactEpsilon = 0.04,
        muzzleAttachment = "muzzle",
        fallbackMuzzleModelScript = id,
        baseWeaponSprite = id,
        readyWeaponSprite = id .. "_FIRE",
        reloadDuration = reloadDuration or 36,
        loadDuration = reloadDuration or 36
    }
end

local function crossbow(id, tension, damageScale, reloadDuration)
    return {
        id = id,
        class = "crossbow",
        requiresCock = false,
        visualPartSlot = "AMMO",
        ammoPriority = { "Base.Bolt_Bear" },
        defaultAmmoType = "Base.Bolt_Bear",
        defaultFlightVisualItem = "Base.Bolt_Bear",
        defaultFloorItemType = "Base.Bolt_Bear",
        speedTilesPerSec = 17.0,
        minFlight = 0.18,
        maxFlight = 1.40,
        startZBias = 0.72,
        arcZ = 0.16,
        worldOzMax = 0.95,
        maxTargetDistance = 68.0,
        impactDamageRadius = 0.95,
        damageScale = damageScale or 2.35,
        tensionPower = tension or 8.0,
        dropStartRange = 20.0,
        dropPerTile = 0.045,
        groundImpactEpsilon = 0.04,
        muzzleAttachment = "muzzle",
        fallbackMuzzleModelScript = id,
        baseWeaponSprite = id,
        readyWeaponSprite = id .. "_FIRE",
        reloadDuration = reloadDuration or 42,
        loadDuration = reloadDuration or 42
    }
end

local function slingshot(id, ammoType, tension, damageScale, reloadDuration)
    return {
        id = id,
        class = "bow",
        requiresCock = false,
        visualPartSlot = "AMMO",
        ammoPriority = { ammoType },
        defaultAmmoType = ammoType,
        defaultFlightVisualItem = ammoType,
        defaultFloorItemType = ammoType,
        speedTilesPerSec = 12.0,
        minFlight = 0.12,
        maxFlight = 1.10,
        startZBias = 0.68,
        arcZ = 0.28,
        worldOzMax = 0.85,
        maxTargetDistance = 36.0,
        impactDamageRadius = 0.55,
        damageScale = damageScale or 0.55,
        tensionPower = tension or 2.0,
        dropStartRange = 8.0,
        dropPerTile = 0.095,
        groundImpactEpsilon = 0.04,
        muzzleAttachment = "muzzle",
        fallbackMuzzleModelScript = id,
        baseWeaponSprite = id,
        readyWeaponSprite = id .. "_FIRE",
        reloadDuration = reloadDuration or 24,
        loadDuration = reloadDuration or 24
    }
end

local weaponProfiles = {
    ["Base.BowTechSR_350"] = bow("BowTechSR_350", 7.0, 2.15, 32),
    ["Base.HoytSpectra_1000"] = bow("HoytSpectra_1000", 7.0, 2.05, 34),
    ["Base.Genesis_X_Bow"] = bow("Genesis_X_Bow", 6.0, 1.90, 36),
    ["Base.Genesis_Bow"] = bow("Genesis_Bow", 5.0, 1.75, 38),
    ["Base.Genesis_Mini_Bow"] = bow("Genesis_Mini_Bow", 4.0, 1.55, 40),
    ["Base.HZRedback_RTS"] = crossbow("HZRedback_RTS", 8.0, 2.15, 42),
    ["Base.TenPointVaporRS_470"] = crossbow("TenPointVaporRS_470", 9.0, 2.70, 40),
    ["Base.MissionMXB_400"] = crossbow("MissionMXB_400", 8.0, 2.55, 42),
    ["Base.TenPointTurbo_XLT"] = crossbow("TenPointTurbo_XLT", 8.0, 2.45, 42),
    ["Base.TAC15"] = crossbow("TAC15", 9.0, 2.35, 44),
    ["Base.HortonScout_125"] = crossbow("HortonScout_125", 7.0, 2.10, 46),
    ["Base.SlingShot_Rock"] = slingshot("SlingShot", "Base.SlingShotAmmo_Rock", 2.0, 0.55, 24),
    ["Base.SlingShot_Marble"] = slingshot("SlingShot", "Base.SlingShotAmmo_Marble", 2.0, 0.45, 24),
    ["Base.WristRocket_Rock"] = slingshot("WristRocket", "Base.SlingShotAmmo_Rock", 2.5, 0.65, 22),
    ["Base.WristRocket_Marble"] = slingshot("WristRocket", "Base.SlingShotAmmo_Marble", 2.5, 0.55, 22)
}

local ammoProfiles = {
    ["Base.Arrow_Fiberglass"] = {
        ammoClass = "arrow",
        sharpness = 1.10,
        impactImpulse = 0.01,
        hitReaction = "arrow_light",
        mass = 0.10,
        flightYawOffset = 0.0,
        flightVisualZOffset = 0.0,
        flightVisualItemType = "Base.Arrow_Fiberglass",
        floorItemType = "Base.Arrow_Fiberglass"
    },
    ["Base.Bolt_Bear"] = {
        ammoClass = "bolt",
        sharpness = 1.25,
        impactImpulse = 0.01,
        hitReaction = "arrow_light",
        mass = 0.08,
        flightYawOffset = 0.0,
        flightVisualZOffset = 0.0,
        flightVisualItemType = "Base.Bolt_Bear",
        floorItemType = "Base.Bolt_Bear"
    },
    ["Base.SlingShotAmmo_Rock"] = {
        ammoClass = "stone",
        sharpness = 0.35,
        impactImpulse = 0.01,
        hitReaction = "arrow_light",
        mass = 0.05,
        flightYawOffset = 0.0,
        flightVisualZOffset = 0.0,
        flightVisualItemType = "Base.SlingShotAmmo_Rock",
        floorItemType = "Base.SlingShotAmmo_Rock"
    },
    ["Base.SlingShotAmmo_Marble"] = {
        ammoClass = "stone",
        sharpness = 0.25,
        impactImpulse = 0.01,
        hitReaction = "arrow_light",
        mass = 0.03,
        flightYawOffset = 0.0,
        flightVisualZOffset = 0.0,
        flightVisualItemType = "Base.SlingShotAmmo_Marble",
        floorItemType = "Base.SlingShotAmmo_Marble"
    }
}

for fullType, profile in pairs(weaponProfiles) do
    local normalized = normalizeFullType(fullType)
    if normalized ~= fullType then
        weaponProfiles[normalized] = profile
    end
    if profile and profile.ammoPriority then
        for i = 1, #profile.ammoPriority do
            profile.ammoPriority[i] = normalizeFullType(profile.ammoPriority[i])
        end
    end
    if profile and profile.defaultAmmoType then
        profile.defaultAmmoType = normalizeFullType(profile.defaultAmmoType)
    end
    if profile and profile.defaultFlightVisualItem then
        profile.defaultFlightVisualItem = normalizeFullType(profile.defaultFlightVisualItem)
    end
    if profile and profile.defaultFloorItemType then
        profile.defaultFloorItemType = normalizeFullType(profile.defaultFloorItemType)
    end
end

for fullType, profile in pairs(ammoProfiles) do
    local normalized = normalizeFullType(fullType)
    if normalized ~= fullType then
        ammoProfiles[normalized] = profile
    end
    if profile and profile.flightVisualItemType then
        profile.flightVisualItemType = normalizeFullType(profile.flightVisualItemType)
    end
    if profile and profile.floorItemType then
        profile.floorItemType = normalizeFullType(profile.floorItemType)
    end
    if profile and profile.weaponPart then
        profile.weaponPart = normalizeFullType(profile.weaponPart)
    end
end

FWP_BOWS.Weapons = weaponProfiles
FWP_BOWS.Ammo = ammoProfiles

function FWP_BOWS.normalizeFullType(fullType)
    return normalizeFullType(fullType)
end

function FWP_BOWS.getWeaponProfile(fullType)
    return weaponProfiles[normalizeFullType(fullType)]
end

function FWP_BOWS.getAmmoProfile(fullType)
    return ammoProfiles[normalizeFullType(fullType)]
end
