-- Admin-defined survivor settlement zones.
-- Mutation happens on the server; clients use this for local menu lookup.

SurvivorZones = SurvivorZones or {}

SurvivorZones.DefaultRadius = 25
SurvivorZones.DefaultPopulation = 4
SurvivorZones.DefaultCivilianPopulation = 2
SurvivorZones.MaxPopulation = 12
SurvivorZones.DefaultClan = "a5def10b-bab9-46b1-8e8c-d5152c86457e"
SurvivorZones.DefaultCivilianClan = "c167d1e0-c077-4ee5-b353-88b374de193d"
SurvivorZones.SchemaVersion = 1

SurvivorZones.Type = {
    Camp = "Camp",
    Safehouse = "Safehouse",
    TradingPost = "Trading Post",
    MilitiaOutpost = "Militia Outpost",
    MedicalShelter = "Medical Shelter",
    ScavengerDen = "Scavenger Den",
}

SurvivorZones.Clan = {
    Hermits = "a5def10b-bab9-46b1-8e8c-d5152c86457e",
    Officers = "d7ba1cc0-de47-4162-b5bd-6295c47b890d",
    ArmyDesert = "a2dec2f0-c76d-4640-8a71-733a547a1ebc",
    Civilians = "c167d1e0-c077-4ee5-b353-88b374de193d",
    Residents = "f52b03f4-c5b1-4bbb-a110-b74038312fe2",
    ShopAssistant = "473e2db3-c751-4a09-9a1d-d780e148b6a1",
    Security = "dcc2a5e9-2670-42f9-8ac2-65566e8f2537",
    Kitchen = "544f827c-cdb3-47d0-a895-3767b67a72c0",
    Gardeners = "76e0eb48-ee72-45ac-9b1b-56a66f597235",
    Janitors = "e195497c-9a14-4c1f-b15a-b8227d15a682",
    Medics = "f8c5c06b-2fd7-482d-8150-2be03d446927",
    Firemen = "989f4faf-53f2-4f8f-9603-496fb3efcb6a",
    Rangers = "3a424953-fa5b-418f-8f11-462e52bfd574",
    Veterans = "c4878ebb-c8e5-4932-8850-370ee9c77d61",
    PoliceBlue = "c4e24888-70f9-43ea-80f8-1bb2f6b9bd88",
    PoliceGray = "33894253-b965-4eb3-94e1-4d642cadac88",
}

SurvivorZones.Profiles = {
    [SurvivorZones.Type.Camp] = {
        guardCap = 2,
        civilianCap = 2,
        guardClanIds = {SurvivorZones.Clan.Hermits, SurvivorZones.Clan.Rangers, SurvivorZones.Clan.Veterans},
        civilianClanIds = {SurvivorZones.Clan.Civilians, SurvivorZones.Clan.Residents, SurvivorZones.Clan.Gardeners},
    },
    [SurvivorZones.Type.Safehouse] = {
        guardCap = 2,
        civilianCap = 4,
        guardClanIds = {SurvivorZones.Clan.Hermits, SurvivorZones.Clan.Officers},
        civilianClanIds = {SurvivorZones.Clan.Residents, SurvivorZones.Clan.Civilians, SurvivorZones.Clan.Janitors},
    },
    [SurvivorZones.Type.TradingPost] = {
        guardCap = 2,
        civilianCap = 5,
        guardClanIds = {SurvivorZones.Clan.Security, SurvivorZones.Clan.Officers},
        civilianClanIds = {SurvivorZones.Clan.ShopAssistant, SurvivorZones.Clan.Civilians, SurvivorZones.Clan.Kitchen},
    },
    [SurvivorZones.Type.MilitiaOutpost] = {
        guardCap = 5,
        civilianCap = 1,
        guardClanIds = {SurvivorZones.Clan.Officers, SurvivorZones.Clan.Veterans, SurvivorZones.Clan.Rangers, SurvivorZones.Clan.ArmyDesert},
        civilianClanIds = {SurvivorZones.Clan.Medics, SurvivorZones.Clan.Civilians},
    },
    [SurvivorZones.Type.MedicalShelter] = {
        guardCap = 1,
        civilianCap = 4,
        guardClanIds = {SurvivorZones.Clan.Security, SurvivorZones.Clan.Officers},
        civilianClanIds = {SurvivorZones.Clan.Medics, SurvivorZones.Clan.Civilians, SurvivorZones.Clan.Residents},
    },
    [SurvivorZones.Type.ScavengerDen] = {
        guardCap = 2,
        civilianCap = 3,
        guardClanIds = {SurvivorZones.Clan.Hermits, SurvivorZones.Clan.Rangers},
        civilianClanIds = {SurvivorZones.Clan.Civilians, SurvivorZones.Clan.Residents, SurvivorZones.Clan.Gardeners},
    },
}

local function getData()
    local gmd = GetBanditModData and GetBanditModData() or nil
    if not gmd and ModData and ModData.getOrCreate then
        gmd = ModData.getOrCreate("Bandit")
    end
    if not gmd then return nil end

    gmd.SurvivorZones = gmd.SurvivorZones or {}
    gmd.SurvivorZoneVersion = gmd.SurvivorZoneVersion or SurvivorZones.SchemaVersion
    return gmd
end

local function nowHours()
    local gt = getGameTime and getGameTime() or nil
    if gt and gt.getWorldAgeHours then
        return gt:getWorldAgeHours()
    end
    return 0
end

local function clampInt(value, minValue, maxValue, fallback)
    local n = math.floor(tonumber(value) or fallback or minValue)
    if n < minValue then return minValue end
    if n > maxValue then return maxValue end
    return n
end

local function hasAccessName(access)
    access = tostring(access or ""):lower()
    return access == "admin" or access == "moderator" or access == "overseer" or access == "gm"
end

local function roleAllowsZoneAdmin()
    if isDebugEnabled and isDebugEnabled() then return true end
    if (not isClient or not isClient()) and (not isServer or not isServer()) then return true end
    if isClient and isClient() and isAdmin and isAdmin() then return true end
    if getAccessLevel then return hasAccessName(getAccessLevel()) end
    return false
end

local function hasRoleCapability(role, capability)
    if not role or not role.hasCapability or capability == nil then return false end
    local ok, result = pcall(role.hasCapability, role, capability)
    return ok and result == true
end

function SurvivorZones.IsAdmin(player)
    if roleAllowsZoneAdmin() then return true end
    if not player then return false end

    if player.getAccessLevel and hasAccessName(player:getAccessLevel()) then
        return true
    end

    if player.getRole and Capability then
        local role = player:getRole()
        return hasRoleCapability(role, Capability.ChangeAccessLevel)
            or hasRoleCapability(role, Capability.FactionCheat)
            or hasRoleCapability(role, Capability.EditItem)
    end

    return false
end

function SurvivorZones.NewId()
    if getRandomUUID then return "SZ_" .. tostring(getRandomUUID()) end
    return "SZ_" .. tostring(getTimestamp and getTimestamp() or os.time()) .. "_" .. tostring(ZombRand(99999))
end

function SurvivorZones.GetAll()
    local gmd = getData()
    return (gmd and gmd.SurvivorZones) or {}
end

function SurvivorZones.Get(zoneId)
    if not zoneId then return nil end
    return SurvivorZones.GetAll()[zoneId]
end

function SurvivorZones.Set(zone)
    if not zone or not zone.id then return nil end
    local gmd = getData()
    if not gmd then return nil end
    gmd.SurvivorZones[zone.id] = zone
    return zone
end

function SurvivorZones.Remove(zoneId)
    local gmd = getData()
    if not gmd or not zoneId then return nil end
    local zone = gmd.SurvivorZones[zoneId]
    gmd.SurvivorZones[zoneId] = nil
    return zone
end

function SurvivorZones.GetProfile(zoneType)
    return SurvivorZones.Profiles[zoneType] or SurvivorZones.Profiles[SurvivorZones.Type.Camp]
end

local function copyClanList(list, fallback)
    local ret = {}
    if type(list) == "table" then
        for _, cid in ipairs(list) do
            table.insert(ret, cid)
        end
    end
    if #ret == 0 and fallback then
        table.insert(ret, fallback)
    end
    return ret
end

function SurvivorZones.NormalizeBounds(args)
    args = args or {}
    local z = math.floor(tonumber(args.z or args.z1 or args.z2) or 0)

    local x1 = tonumber(args.x1)
    local y1 = tonumber(args.y1)
    local x2 = tonumber(args.x2)
    local y2 = tonumber(args.y2)

    if not x1 or not y1 or not x2 or not y2 then
        local cx = math.floor(tonumber(args.x or args.cx) or 0)
        local cy = math.floor(tonumber(args.y or args.cy) or 0)
        local radius = clampInt(args.radius, 5, 100, SurvivorZones.DefaultRadius)
        x1 = cx - radius
        y1 = cy - radius
        x2 = cx + radius
        y2 = cy + radius
    end

    x1 = math.floor(x1)
    y1 = math.floor(y1)
    x2 = math.floor(x2)
    y2 = math.floor(y2)

    if x2 < x1 then x1, x2 = x2, x1 end
    if y2 < y1 then y1, y2 = y2, y1 end

    return {
        x1 = x1,
        y1 = y1,
        x2 = x2,
        y2 = y2,
        z = z,
        x = math.floor((x1 + x2) / 2),
        y = math.floor((y1 + y2) / 2),
        radius = math.max(5, math.max(math.floor((x2 - x1) / 2), math.floor((y2 - y1) / 2))),
    }
end

function SurvivorZones.Create(args)
    args = args or {}
    local bounds = SurvivorZones.NormalizeBounds(args)
    local zoneType = tostring(args.zoneType or args.type or SurvivorZones.Type.Camp)
    local profile = SurvivorZones.GetProfile(zoneType)
    local populationCap = clampInt(args.populationCap or args.size, 1, SurvivorZones.MaxPopulation, SurvivorZones.DefaultPopulation)
    local guardCap = clampInt(args.guardCap, 0, SurvivorZones.MaxPopulation, profile.guardCap or populationCap)
    local civilianCap = clampInt(args.civilianCap, 0, SurvivorZones.MaxPopulation, profile.civilianCap or SurvivorZones.DefaultCivilianPopulation)
    local zoneId = args.id or SurvivorZones.NewId()
    local baseId = args.baseId or ("SZB_" .. tostring(zoneId))

    local zone = {
        id = zoneId,
        baseId = baseId,
        name = args.name or (zoneType .. " " .. tostring(bounds.x) .. "," .. tostring(bounds.y)),
        type = zoneType,
        enabled = args.enabled ~= false,
        x = bounds.x,
        y = bounds.y,
        z = bounds.z,
        x1 = bounds.x1,
        y1 = bounds.y1,
        x2 = bounds.x2,
        y2 = bounds.y2,
        radius = bounds.radius,
        populationCap = populationCap,
        guardCap = guardCap,
        civilianCap = civilianCap,
        clanId = args.clanId or SurvivorZones.DefaultClan,
        guardClanIds = copyClanList(args.guardClanIds or profile.guardClanIds, args.clanId or SurvivorZones.DefaultClan),
        civilianClanIds = copyClanList(args.civilianClanIds or profile.civilianClanIds, args.civilianClanId or SurvivorZones.DefaultCivilianClan),
        noZombieSpawn = false,
        clearZombiesOnCreate = false,
        autoWalls = args.autoWalls == true,
        wallsBuilt = args.wallsBuilt == true,
        spawnOnCreate = args.spawnOnCreate ~= false,
        maintainPopulation = args.maintainPopulation ~= false,
        respawnCooldownHours = clampInt(args.respawnCooldownHours, 1, 240, 24),
        lastSpawnHour = tonumber(args.lastSpawnHour) or -99999,
        createdAt = nowHours(),
        createdBy = args.createdBy,
    }

    return SurvivorZones.Set(zone)
end

function SurvivorZones.ContainsPoint(zone, x, y, z, margin)
    if not zone or x == nil or y == nil then return false end
    margin = tonumber(margin) or 0
    local pz = math.floor(tonumber(z) or tonumber(zone.z) or 0)
    local zoneZ = math.floor(tonumber(zone.z) or 0)
    if pz ~= zoneZ then return false end

    return x >= (zone.x1 - margin)
        and x <= (zone.x2 + margin)
        and y >= (zone.y1 - margin)
        and y <= (zone.y2 + margin)
end

function SurvivorZones.GetZoneAt(x, y, z)
    for _, zone in pairs(SurvivorZones.GetAll()) do
        if zone.enabled ~= false and SurvivorZones.ContainsPoint(zone, x, y, z, 0) then
            return zone
        end
    end
    return nil
end

function SurvivorZones.GetNearest(x, y, z, maxDistance)
    local bestZone = nil
    local bestDist = maxDistance or math.huge

    for _, zone in pairs(SurvivorZones.GetAll()) do
        local sameZ = math.floor(tonumber(zone.z) or 0) == math.floor(tonumber(z) or 0)
        if sameZ then
            local dx = (tonumber(zone.x) or 0) - x
            local dy = (tonumber(zone.y) or 0) - y
            local dist = math.sqrt((dx * dx) + (dy * dy))
            if dist < bestDist then
                bestDist = dist
                bestZone = zone
            end
        end
    end

    return bestZone, bestDist
end

function SurvivorZones.GetRandomPoint(zone)
    if not zone then return nil end
    local x1 = math.floor(tonumber(zone.x1) or tonumber(zone.x) or 0)
    local y1 = math.floor(tonumber(zone.y1) or tonumber(zone.y) or 0)
    local x2 = math.floor(tonumber(zone.x2) or x1)
    local y2 = math.floor(tonumber(zone.y2) or y1)
    local w = math.max(1, x2 - x1 + 1)
    local h = math.max(1, y2 - y1 + 1)
    return x1 + ZombRand(w), y1 + ZombRand(h), math.floor(tonumber(zone.z) or 0)
end

function SurvivorZones.GetRandomWalkablePoint(zone, attempts)
    if not zone then return nil end
    local cell = getCell and getCell() or nil
    attempts = attempts or 30

    for _ = 1, attempts do
        local x, y, z = SurvivorZones.GetRandomPoint(zone)
        local sq = cell and cell:getGridSquare(x, y, z) or nil
        if sq and (not sq.isFree or sq:isFree(false)) then
            return x, y, z, sq
        end
    end

    return zone.x, zone.y, zone.z
end

function SurvivorZones.Transmit()
    if TransmitBanditModData then
        TransmitBanditModData()
    elseif ModData and ModData.transmit then
        ModData.transmit("Bandit")
    end
end
