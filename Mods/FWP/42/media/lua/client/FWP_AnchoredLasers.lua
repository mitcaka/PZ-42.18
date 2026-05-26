local FWP_LASER_BEAMS = {
    Laser_Green = "Base.FWP_LaserBeam_Green",
    Laser_Green_ON = "Base.FWP_LaserBeam_Green",
    Laser_Red = "Base.FWP_LaserBeam_Red",
    Laser_Red_ON = "Base.FWP_LaserBeam_Red",
    Laser_DVAL = "Base.FWP_LaserBeam_DVAL",
    Laser_DVAL_ON = "Base.FWP_LaserBeam_DVAL",
    Laser_PEQ15 = "Base.FWP_LaserBeam_PEQ15",
    Laser_PEQ15_ON = "Base.FWP_LaserBeam_PEQ15",
}

local function FWPPatchHideBeamPartAccess()
    if _G.FWP_HideBeamPartAccessPatched then
        return true
    end
    if not (__classmetatables and zombie and zombie.inventory and zombie.inventory.types and zombie.inventory.types.HandWeapon) then
        return false
    end
    local meta = __classmetatables[zombie.inventory.types.HandWeapon.class]
    if not (meta and meta.__index and meta.__index.getWeaponPart and meta.__index.setWeaponPart) then
        return false
    end
    local originalGetWeaponPart = meta.__index.getWeaponPart
    local originalSetWeaponPart = meta.__index.setWeaponPart
    meta.__index.getWeaponPart = function(item, partType, ...)
        if partType ~= "Hide_Beam" then
            return originalGetWeaponPart(item, partType, ...)
        end
        local okReal, real = pcall(originalGetWeaponPart, item, partType, ...)
        if okReal and real then
            return real
        end
        if not item.getModData then
            return nil
        end
        local cached = item:getModData().FWP_HideBeamPart
        if cached and instanceItem then
            return instanceItem(cached)
        end
        return nil
    end
    meta.__index.setWeaponPart = function(item, partType, weaponPart, ...)
        if partType ~= "Hide_Beam" then
            return originalSetWeaponPart(item, partType, weaponPart, ...)
        end
        local ok, result = pcall(originalSetWeaponPart, item, partType, weaponPart, ...)
        if item.getModData then
            local md = item:getModData()
            md.FWP_HideBeamPart = weaponPart and weaponPart.getFullType and weaponPart:getFullType() or nil
            if item.transmitModData then
                item:transmitModData()
            end
        end
        if ok then
            return result
        end
        return nil
    end
    _G.FWP_HideBeamPartAccessPatched = true
    return true
end

FWPPatchHideBeamPartAccess()
Events.OnGameStart.Add(FWPPatchHideBeamPartAccess)

local function FWPGetPart(weapon, slot)
    if not (weapon and slot) then
        return nil
    end
    if FWPGetWeaponPart then
        local ok, part = pcall(FWPGetWeaponPart, weapon, slot)
        if ok and part then
            return part
        end
    end
    if weapon.getWeaponPart then
        local ok, part = pcall(weapon.getWeaponPart, weapon, slot)
        if ok then
            return part
        end
    end
    return nil
end

local function FWPIsAnchoredLaserPart(part)
    if not (part and part.getType) then
        return false
    end
    local partType = tostring(part:getType() or "")
    if FWP_LASER_BEAMS[partType] then
        return true
    end
    if part.hasTag and FWPGetItemTag then
        local okLaser, hasLaser = pcall(function() return part:hasTag(FWPGetItemTag("Laser")) end)
        local okMulti, hasMulti = pcall(function() return part:hasTag(FWPGetItemTag("Multi_Laser")) end)
        return (okLaser and hasLaser == true) or (okMulti and hasMulti == true)
    end
    return partType:find("Laser", 1, true) ~= nil
end

local function FWPGetAnchoredLaserPart(weapon)
    local stock = FWPGetPart(weapon, "Stock")
    if FWPIsAnchoredLaserPart(stock) then
        return stock
    end
    local sling = FWPGetPart(weapon, "Sling")
    if FWPIsAnchoredLaserPart(sling) then
        return sling
    end
    local laser = FWPGetPart(weapon, "Laser")
    if FWPIsAnchoredLaserPart(laser) then
        return laser
    end
    return nil
end

local function FWPResolveBeamType(laser)
    if not (laser and laser.getType) then
        return nil
    end
    local partType = tostring(laser:getType() or "")
    local beamType = FWP_LASER_BEAMS[partType]
    if beamType then
        return beamType
    end
    if partType:find("Green", 1, true) then
        return "Base.FWP_LaserBeam_Green"
    end
    if partType:find("DVAL", 1, true) then
        return "Base.FWP_LaserBeam_DVAL"
    end
    if partType:find("PEQ15", 1, true) then
        return "Base.FWP_LaserBeam_PEQ15"
    end
    if laser.getColorGreen and laser:getColorGreen() > laser:getColorRed() then
        return "Base.FWP_LaserBeam_Green"
    end
    return "Base.FWP_LaserBeam_Red"
end

local function FWPHasLaserPower(weapon, laser)
    if not (weapon and weapon.getModData and laser and laser.getModData) then
        return true
    end
    local laserMd = laser:getModData()
    local weaponMd = weapon:getModData()
    if laserMd.Charge == nil then
        laserMd.Charge = weaponMd.Charge or 100
    end
    return tonumber(laserMd.Charge) == nil or tonumber(laserMd.Charge) > 0
end

local function FWPWantsLaserBeam(weapon, laser)
    if not (weapon and weapon.getModData and laser and laser.getType) then
        return false
    end
    local weaponMd = weapon:getModData()
    if weaponMd.LaserOn == true then
        return true
    end
    return tostring(laser:getType() or ""):find("_ON", 1, true) ~= nil
end

local function FWPRefreshWeaponModels(player)
    if not player then
        return
    end
    if player.resetEquippedHandsModels then
        pcall(function() player:resetEquippedHandsModels() end)
    end
    if player.resetModelNextFrame then
        pcall(function() player:resetModelNextFrame() end)
    end
end

local function FWPSetBeamPart(player, weapon, beamType)
    if not (weapon and weapon.setWeaponPart) then
        return
    end
    local current = FWPGetPart(weapon, "Hide_Beam")
    local currentType = current and current.getFullType and current:getFullType() or nil
    if currentType == beamType then
        return
    end
    if current then
        pcall(weapon.setWeaponPart, weapon, "Hide_Beam", nil)
    end
    if beamType then
        local beam = nil
        if instanceItem then
            local okBeam, created = pcall(instanceItem, beamType)
            if okBeam then
                beam = created
            end
        end
        if beam then
            pcall(weapon.setWeaponPart, weapon, "Hide_Beam", beam)
        end
    end
    FWPRefreshWeaponModels(player)
end

local function FWPUpdateAnchoredLaser(player)
    if not (player and player.getPrimaryHandItem) then
        return
    end
    local weapon = player:getPrimaryHandItem()
    if not (weapon and weapon.IsWeapon and weapon:IsWeapon() and weapon.isRanged and weapon:isRanged()) then
        return
    end
    local laser = FWPGetAnchoredLaserPart(weapon)
    if not laser then
        FWPSetBeamPart(player, weapon, nil)
        return
    end
    local beamType = FWPResolveBeamType(laser)
    if beamType and FWPWantsLaserBeam(weapon, laser) and FWPHasLaserPower(weapon, laser) then
        FWPSetBeamPart(player, weapon, beamType)
    else
        FWPSetBeamPart(player, weapon, nil)
    end
end

Events.OnPlayerUpdate.Add(FWPUpdateAnchoredLaser)
