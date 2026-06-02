CSR_Throwables = CSR_Throwables or {}

CSR_Throwables.MODULE = "CommonSenseReborn"
CSR_Throwables.CMD_THROW = "ThrowableThrow"
CSR_Throwables.CMD_IMPACT = "ThrowableImpact"

local function sandbox()
    return SandboxVars and SandboxVars.CommonSenseReborn or {}
end

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function copyProfile(profile)
    if not profile then return nil end
    local out = {}
    for k, v in pairs(profile) do
        out[k] = v
    end
    return out
end

local PROFILE_PRESETS = {
    stone = {
        category = "stone",
        maxRange = 11,
        noiseRadius = 9,
        noiseVolume = 8,
        damageMin = 0.10,
        damageMax = 0.28,
        hitRadius = 1.25,
        breakChance = 0.00,
        scatter = 0.85,
    },
    brick = {
        category = "brick",
        maxRange = 8,
        noiseRadius = 14,
        noiseVolume = 12,
        damageMin = 0.28,
        damageMax = 0.70,
        hitRadius = 1.45,
        breakChance = 0.12,
        scatter = 1.20,
    },
    can = {
        category = "can",
        maxRange = 10,
        noiseRadius = 8,
        noiseVolume = 7,
        damageMin = 0.04,
        damageMax = 0.14,
        hitRadius = 1.10,
        breakChance = 0.00,
        scatter = 1.00,
    },
    foodCan = {
        category = "foodCan",
        maxRange = 9,
        noiseRadius = 9,
        noiseVolume = 8,
        damageMin = 0.06,
        damageMax = 0.18,
        hitRadius = 1.15,
        breakChance = 0.00,
        scatter = 1.05,
    },
    plasticBottle = {
        category = "plasticBottle",
        maxRange = 10,
        noiseRadius = 6,
        noiseVolume = 5,
        damageMin = 0.01,
        damageMax = 0.06,
        hitRadius = 1.00,
        breakChance = 0.00,
        scatter = 1.15,
    },
    glass = {
        category = "glass",
        maxRange = 9,
        noiseRadius = 11,
        noiseVolume = 10,
        damageMin = 0.06,
        damageMax = 0.22,
        hitRadius = 1.15,
        breakChance = 0.72,
        scatter = 1.10,
    },
    ceramic = {
        category = "ceramic",
        maxRange = 8,
        noiseRadius = 10,
        noiseVolume = 9,
        damageMin = 0.05,
        damageMax = 0.18,
        hitRadius = 1.10,
        breakChance = 0.65,
        scatter = 1.05,
    },
    ball = {
        category = "ball",
        maxRange = 13,
        noiseRadius = 7,
        noiseVolume = 6,
        damageMin = 0.02,
        damageMax = 0.13,
        hitRadius = 1.20,
        breakChance = 0.00,
        scatter = 1.35,
    },
    hardBall = {
        category = "hardBall",
        maxRange = 14,
        noiseRadius = 7,
        noiseVolume = 6,
        damageMin = 0.06,
        damageMax = 0.22,
        hitRadius = 1.10,
        breakChance = 0.00,
        scatter = 0.95,
    },
    dart = {
        category = "dart",
        maxRange = 12,
        noiseRadius = 3,
        noiseVolume = 3,
        damageMin = 0.07,
        damageMax = 0.20,
        hitRadius = 0.85,
        breakChance = 0.08,
        scatter = 0.65,
    },
    duck = {
        category = "duck",
        maxRange = 9,
        noiseRadius = 5,
        noiseVolume = 4,
        damageMin = 0.00,
        damageMax = 0.04,
        hitRadius = 1.00,
        breakChance = 0.00,
        scatter = 1.35,
    },
    knife = {
        category = "knife",
        maxRange = 9,
        noiseRadius = 4,
        noiseVolume = 4,
        damageMin = 0.18,
        damageMax = 0.52,
        hitRadius = 0.95,
        breakChance = 0.05,
        scatter = 0.80,
    },
    glowstick = {
        category = "glowstick",
        maxRange = 12,
        noiseRadius = 3,
        noiseVolume = 2,
        damageMin = 0.00,
        damageMax = 0.03,
        hitRadius = 0.85,
        breakChance = 0.00,
        scatter = 0.75,
    },
}

local EXACT_PROFILES = {
    ["Base.Stone"] = "stone",
    ["Base.SharpedStone"] = "stone",
    ["Base.Brick"] = "brick",
    ["Base.ClayBrick"] = "brick",
    ["Base.CSR_WeaponizedBrick"] = "brick",
    ["Base.PopEmpty"] = "can",
    ["Base.Pop2Empty"] = "can",
    ["Base.Pop3Empty"] = "can",
    ["Base.BeerCanEmpty"] = "can",
    ["Base.TinCanEmpty"] = "can",
    ["Base.WaterBottleEmpty"] = "plasticBottle",
    ["Base.PopBottleEmpty"] = "plasticBottle",
    ["Base.BleachEmpty"] = "plasticBottle",
    ["Base.WineEmpty"] = "glass",
    ["Base.WineEmpty2"] = "glass",
    ["Base.WhiskeyEmpty"] = "glass",
    ["Base.BeerEmpty"] = "glass",
    ["Base.Basketball"] = "ball",
    ["Base.Football"] = "ball",
    ["Base.Football2"] = "ball",
    ["Base.SoccerBall"] = "ball",
    ["Base.TennisBall"] = "ball",
    ["Base.Baseball"] = "hardBall",
    ["Base.GolfBall"] = "hardBall",
    ["Base.PoolBall"] = "hardBall",
    ["Base.Dart"] = "dart",
    ["Base.Mugl"] = "ceramic",
    ["Base.MugRed"] = "ceramic",
    ["Base.MugWhite"] = "ceramic",
    ["Base.MugSpiffo"] = "ceramic",
    ["Base.Teacup"] = "ceramic",
    ["Base.GlassTumbler"] = "glass",
    ["Base.GlassWine"] = "glass",
    ["Base.Plate"] = "ceramic",
    ["Base.PlateBlue"] = "ceramic",
    ["Base.PlateOrange"] = "ceramic",
    ["Base.PlateFancy"] = "ceramic",
    ["Base.Rubberducky"] = "duck",
    ["Base.KitchenKnife"] = "knife",
    ["Base.HuntingKnife"] = "knife",
    ["Base.BreadKnife"] = "knife",
    ["Base.Knife"] = "knife",
    ["Base.ButterKnife"] = "knife",
    ["Base.MeatCleaver"] = "knife",
    ["Base.CSR_GlowstickRed"] = "glowstick",
    ["Base.CSR_GlowstickGreen"] = "glowstick",
    ["Base.CSR_GlowstickBlue"] = "glowstick",
    ["Base.CSR_GlowstickWhite"] = "glowstick",
    ["Base.CSR_GlowstickYellow"] = "glowstick",
    ["Base.CSR_GlowstickPurple"] = "glowstick",
}

local GLOWSTICK_COLORS = {
    ["Base.CSR_GlowstickRed"] = { r = 255, g = 40, b = 28 },
    ["Base.CSR_GlowstickGreen"] = { r = 45, g = 255, b = 55 },
    ["Base.CSR_GlowstickBlue"] = { r = 45, g = 90, b = 255 },
    ["Base.CSR_GlowstickWhite"] = { r = 245, g = 245, b = 220 },
    ["Base.CSR_GlowstickYellow"] = { r = 255, g = 235, b = 35 },
    ["Base.CSR_GlowstickPurple"] = { r = 160, g = 65, b = 255 },
}

local FOOD_CAN_PROFILES = {
    ["Base.CannedBeans"] = true,
    ["Base.TinnedBeans"] = true,
    ["Base.CannedBolognese"] = true,
    ["Base.CannedBellPepper"] = true,
    ["Base.CannedBroccoli"] = true,
    ["Base.CannedCabbage"] = true,
    ["Base.CannedCarrots2"] = true,
    ["Base.CannedChili"] = true,
    ["Base.CannedCorn"] = true,
    ["Base.CannedCornedBeef"] = true,
    ["Base.CannedEggplant"] = true,
    ["Base.CannedFruitCocktail"] = true,
    ["Base.CannedLeek"] = true,
    ["Base.CannedMilk"] = true,
    ["Base.CannedMushroomSoup"] = true,
    ["Base.CannedPeaches"] = true,
    ["Base.CannedPeas"] = true,
    ["Base.CannedPineapple"] = true,
    ["Base.CannedPotato2"] = true,
    ["Base.CannedRedRadish"] = true,
    ["Base.CannedSardines"] = true,
    ["Base.CannedTomato2"] = true,
    ["Base.Dogfood"] = true,
    ["Base.TinnedSoup"] = true,
    ["Base.TunaTin"] = true,
}

local KNIFE_TYPES = {
    KitchenKnife = true,
    HuntingKnife = true,
    BreadKnife = true,
    Knife = true,
    ButterKnife = true,
    MeatCleaver = true,
}

local BLOCKED_TYPE_TERMS = {
    "gun", "rifle", "shotgun", "pistol", "revolver", "firearm", "ammo",
    "bullet", "shell", "magazine", "grenade", "bomb", "molotov", "spear",
    "katana", "machete", "axe", "bat", "club", "hammer", "crowbar",
    "screwdriver", "wrench", "saw", "torch", "key", "bag", "backpack",
    "container", "wallet", "money",
}

local function lowerItemText(item)
    local ft = item and item.getFullType and item:getFullType() or ""
    local typ = item and item.getType and item:getType() or ""
    local name = item and item.getDisplayName and item:getDisplayName() or ""
    return string.lower(tostring(ft) .. " " .. tostring(typ) .. " " .. tostring(name))
end

local function containsAny(text, terms)
    for i = 1, #terms do
        if string.find(text, terms[i], 1, true) then
            return true
        end
    end
    return false
end

local function isBlockedByClass(item, profile)
    if not item then return true end
    if item.isFavorite and item:isFavorite() then return true end
    if instanceof and instanceof(item, "InventoryContainer") then return true end
    if item.getCategory then
        local category = string.lower(tostring(item:getCategory() or ""))
        if category == "container" or category == "key" then return true end
    end
    if profile and profile.category == "knife" then
        return false
    end
    if item.IsWeapon and item:IsWeapon() then return true end
    if item.isRanged and item:isRanged() then return true end
    if item.isRequiresEquippedBothHands and item:isRequiresEquippedBothHands() then return true end
    if item.isTwoHandWeapon and item:isTwoHandWeapon() then return true end
    return containsAny(lowerItemText(item), BLOCKED_TYPE_TERMS)
end

local function itemWeight(item)
    if item and item.getActualWeight then
        local weight = item:getActualWeight()
        if weight then return weight end
    end
    if item and item.getWeight then
        local weight = item:getWeight()
        if weight then return weight end
    end
    return 0
end

local function isInPlayerInventory(player, item)
    if not player or not item or not item.getContainer then
        return false
    end
    local container = item:getContainer()
    if not container then
        return false
    end
    if player.getInventory and container == player:getInventory() then
        return true
    end
    return container.isInCharacterInventory and container:isInCharacterInventory(player) or false
end

function CSR_Throwables.getProfile(item)
    if not item or not item.getFullType then return nil end

    local fullType = item:getFullType()
    local presetKey = EXACT_PROFILES[fullType]
    if not presetKey and FOOD_CAN_PROFILES[fullType] then
        presetKey = "foodCan"
    end

    if not presetKey and item.getType and KNIFE_TYPES[item:getType()] then
        presetKey = "knife"
    end

    if not presetKey then
        return nil
    end

    local profile = copyProfile(PROFILE_PRESETS[presetKey])
    if not profile or isBlockedByClass(item, profile) then
        return nil
    end

    local weight = itemWeight(item)
    if profile.category ~= "brick" and profile.category ~= "ball" and weight > 2.5 then
        return nil
    end

    profile.fullType = fullType
    profile.weight = weight
    return profile
end

function CSR_Throwables.isGlowstickType(fullType)
    return GLOWSTICK_COLORS[tostring(fullType or "")] ~= nil
end

function CSR_Throwables.getGlowstickColor(fullType)
    return GLOWSTICK_COLORS[tostring(fullType or "")]
end

function CSR_Throwables.isThrowable(item)
    return CSR_Throwables.getProfile(item) ~= nil
end

function CSR_Throwables.validatePlayerItem(player, item)
    if not player or not item then
        return false, "Nothing to throw"
    end
    if player.isDead and player:isDead() then
        return false, "Cannot throw right now"
    end
    if player.getVehicle and player:getVehicle() then
        return false, "Cannot throw from a vehicle"
    end
    if not isInPlayerInventory(player, item) then
        return false, "Item not found"
    end
    if player.isEquippedClothing and player:isEquippedClothing(item) then
        return false, "Cannot throw worn clothing"
    end
    local profile = CSR_Throwables.getProfile(item)
    if not profile then
        return false, "Cannot throw that item"
    end
    return true, nil, profile
end

function CSR_Throwables.getSandboxMaxRange()
    return clamp(sandbox().ThrowableMaxRange or 12, 4, 20)
end

function CSR_Throwables.getMaxRange(profile)
    local cap = CSR_Throwables.getSandboxMaxRange()
    local range = profile and profile.maxRange or cap
    return math.max(2, math.min(range, cap))
end

function CSR_Throwables.getNoiseMultiplier()
    return clamp(sandbox().ThrowableNoiseMultiplier or 1.0, 0.0, 3.0)
end

function CSR_Throwables.getDamageMultiplier()
    return clamp(sandbox().ThrowableDamageMultiplier or 1.0, 0.0, 3.0)
end

function CSR_Throwables.getBreakMultiplier()
    return clamp(sandbox().ThrowableBreakChanceMultiplier or 1.0, 0.0, 3.0)
end

function CSR_Throwables.getActionTime(item, profile)
    local weight = profile and profile.weight or itemWeight(item)
    return math.floor(35 + math.min(55, weight * 18))
end

function CSR_Throwables.resolveLanding(player, args, profile)
    if not player or not args or not profile then
        return nil, "Invalid throw"
    end

    local targetX = tonumber(args.targetX)
    local targetY = tonumber(args.targetY)
    local targetZ = tonumber(args.targetZ)
    if not targetX or not targetY then
        return nil, "Invalid target"
    end

    local px = player.getX and player:getX() or 0
    local py = player.getY and player:getY() or 0
    local pz = player.getZ and player:getZ() or 0
    if not targetZ then targetZ = pz end
    if math.abs(targetZ - pz) > 1 then
        targetZ = pz
    end

    local dx = targetX + 0.5 - px
    local dy = targetY + 0.5 - py
    local distance = math.sqrt(dx * dx + dy * dy)
    local maxRange = CSR_Throwables.getMaxRange(profile)
    if distance > maxRange + 0.75 then
        local scale = maxRange / math.max(distance, 0.001)
        targetX = px + (dx * scale)
        targetY = py + (dy * scale)
        distance = maxRange
    end

    local aiming = 0
    if player.getPerkLevel and Perks and Perks.Aiming then
        aiming = tonumber(player:getPerkLevel(Perks.Aiming)) or 0
    end
    local strength = 0
    if player.getPerkLevel and Perks and Perks.Strength then
        strength = tonumber(player:getPerkLevel(Perks.Strength)) or 0
    end

    local scatter = math.max(0, (profile.scatter or 1.0) + (distance / math.max(maxRange, 1)) - (aiming * 0.08) - (strength * 0.04))
    local offsetX = 0
    local offsetY = 0
    if scatter > 0.05 then
        offsetX = ZombRandFloat(-scatter, scatter)
        offsetY = ZombRandFloat(-scatter, scatter)
    end

    local lx = math.floor(targetX + offsetX)
    local ly = math.floor(targetY + offsetY)
    local lz = math.floor(targetZ)
    local cell = getCell and getCell() or (player.getCell and player:getCell() or nil)
    local square = cell and cell.getGridSquare and cell:getGridSquare(lx, ly, lz) or nil
    if not square then
        square = player.getCurrentSquare and player:getCurrentSquare() or nil
    end
    if not square then
        return nil, "No landing square"
    end

    return {
        square = square,
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
        distance = distance,
    }
end

local function removeInventoryItem(player, item)
    if not item then return false end
    if player and player.getPrimaryHandItem and player:getPrimaryHandItem() == item and player.setPrimaryHandItem then
        player:setPrimaryHandItem(nil)
    end
    if player and player.getSecondaryHandItem and player:getSecondaryHandItem() == item and player.setSecondaryHandItem then
        player:setSecondaryHandItem(nil)
    end

    local container = item.getContainer and item:getContainer() or (player and player.getInventory and player:getInventory() or nil)
    if not container then return false end

    if container.DoRemoveItem then
        container:DoRemoveItem(item)
    elseif container.Remove then
        container:Remove(item)
    else
        return false
    end

    if sendRemoveItemFromContainer then
        sendRemoveItemFromContainer(container, item)
    end
    return true
end

local function dropItem(square, item)
    if not square or not item or not square.AddWorldInventoryItem then return false end
    square:AddWorldInventoryItem(item, ZombRandFloat(0.15, 0.85), ZombRandFloat(0.15, 0.85), 0.0)
    return true
end

local function findNearestZombie(square, radius)
    if not square then return nil end
    local cell = square.getCell and square:getCell() or getCell()
    if not cell then return nil end

    local bestZombie = nil
    local bestDist = (radius * radius) + 0.01
    local sx = square:getX() + 0.5
    local sy = square:getY() + 0.5
    local sz = square:getZ()
    local r = math.ceil(radius)

    for x = square:getX() - r, square:getX() + r do
        for y = square:getY() - r, square:getY() + r do
            local sq = cell:getGridSquare(x, y, sz)
            local moving = sq and sq.getMovingObjects and sq:getMovingObjects() or nil
            if moving then
                for i = 0, moving:size() - 1 do
                    local obj = moving:get(i)
                    if obj and instanceof(obj, "IsoZombie") and not obj:isDead() then
                        local dx = (obj:getX() or x) - sx
                        local dy = (obj:getY() or y) - sy
                        local dist = dx * dx + dy * dy
                        if dist <= bestDist then
                            bestDist = dist
                            bestZombie = obj
                        end
                    end
                end
            end
        end
    end

    return bestZombie
end

local function damageZombie(player, zombie, damage)
    if not zombie or damage <= 0 then return false end
    if not zombie.getHealth or not zombie.setHealth then return false end
    local hp = zombie:getHealth()
    if not hp or hp <= 0 then return false end

    local after = hp - damage
    zombie:setHealth(after)
    if after <= 0 and zombie.Kill then
        zombie:Kill(player)
    end
    return true
end

local ACTION_LOOP_SOUNDS = {
    RummageInInventory = true,
    SliceMeat = true,
}

local CATEGORY_IMPACT_SOUNDS = {
    stone = "StoneHit",
    brick = "StoneHit",
    hardBall = "StoneHit",
}

local CATEGORY_BREAK_SOUNDS = {
    glass = "BreakGlassItem",
    ceramic = "BreakGlassItem",
}

local function safeImpactSound(sound)
    if not sound then return nil end
    sound = tostring(sound)
    if sound == "" or ACTION_LOOP_SOUNDS[sound] then
        return nil
    end
    return sound
end

local function itemSound(item, methodName)
    local method = item and item[methodName] or nil
    if not method then return nil end
    return safeImpactSound(method(item))
end

function CSR_Throwables.getImpactSound(item, profile, broke)
    local category = profile and profile.category or nil

    if broke then
        local sound = itemSound(item, "getBreakSound")
        if sound then return sound end
        sound = safeImpactSound(CATEGORY_BREAK_SOUNDS[category])
        if sound then return sound end
    end

    local sound = itemSound(item, "getHitFloorSound")
    if sound then return sound end

    sound = itemSound(item, "getPlaceOneSound")
    if sound then return sound end

    sound = itemSound(item, "getDropSound")
    if sound then return sound end

    sound = safeImpactSound(CATEGORY_IMPACT_SOUNDS[category])
    if sound then return sound end

    if broke then
        sound = safeImpactSound(CATEGORY_BREAK_SOUNDS[category])
        if sound then return sound end
    end

    return "PutItemInBag"
end

function CSR_Throwables.performThrow(player, item, args)
    local ok, reason, profile = CSR_Throwables.validatePlayerItem(player, item)
    if not ok then
        return { ok = false, reason = reason }
    end

    local landing, landingReason = CSR_Throwables.resolveLanding(player, args, profile)
    if not landing then
        return { ok = false, reason = landingReason }
    end

    if not removeInventoryItem(player, item) then
        return { ok = false, reason = "Could not remove item" }
    end

    local breakChance = math.min(1.0, (profile.breakChance or 0) * CSR_Throwables.getBreakMultiplier())
    local broke = breakChance > 0 and ZombRandFloat(0, 1) < breakChance
    if not broke then
        dropItem(landing.square, item)
    end

    local noiseRadius = math.max(0, math.floor((profile.noiseRadius or 0) * CSR_Throwables.getNoiseMultiplier()))
    local noiseVolume = math.max(0, math.floor((profile.noiseVolume or noiseRadius) * CSR_Throwables.getNoiseMultiplier()))
    if addSound and noiseRadius > 0 then
        addSound(player, landing.x, landing.y, landing.z, noiseRadius, noiseVolume)
    end

    local damage = 0
    local damageMult = CSR_Throwables.getDamageMultiplier()
    if damageMult > 0 then
        local minD = profile.damageMin or 0
        local maxD = profile.damageMax or minD
        damage = ZombRandFloat(minD, maxD) * damageMult
        local zombie = findNearestZombie(landing.square, profile.hitRadius or 1.0)
        if zombie then
            damageZombie(player, zombie, damage)
        else
            damage = 0
        end
    end

    return {
        ok = true,
        x = landing.x,
        y = landing.y,
        z = landing.z,
        sound = CSR_Throwables.getImpactSound(item, profile, broke),
        broke = broke,
        damage = damage,
        category = profile.category,
        itemType = item.getFullType and item:getFullType() or nil,
    }
end

return CSR_Throwables
