-- FHC_NearbyScan.lua
-- One cached animal scan read by nearby panel, map markers and outline.
-- In MP the scan rows are server-authored; SP uses the local world directly.

require "FHC_Constants"
require "FHC_Sandbox"
require "FHC_Utils"

if isServer() then return end

FHC.Scan = FHC.Scan or {}
local Scan = FHC.Scan
local U  = FHC.Utils
local SB = FHC.SB

Scan.results = Scan.results or {}     -- array of { x, y, z, canonical, type, age, gender, kind, ref? }
Scan.lastAt  = Scan.lastAt or 0
Scan.requestAt = Scan.requestAt or 0
Scan.radius  = Scan.radius or 10

function Scan.snapshot()
    return Scan.results
end

function Scan.invalidate()
    Scan.lastAt = 0
    Scan.requestAt = 0
end

function Scan.receiveServerResults(rows, radius)
    Scan.results = type(rows) == "table" and rows or {}
    Scan.radius = tonumber(radius) or Scan.radius or 0
    Scan.lastAt = getTimestampMs and getTimestampMs() or 0
end

local function wantedRadius(player)
    if not player then return false, 0 end
    local want, radius = false, 0
    if SB.nearbyPanel() and U.getToggle(player, FHC.TOGGLE.NearbyPanel) then
        want = true
        radius = math.max(radius, 12)
    end
    if SB.mapMarkers() and U.getToggle(player, FHC.TOGGLE.MapMarkers) then
        want = true
        radius = math.max(radius, SB.mapMarkersRadius())
    end
    if SB.outline() and U.getToggle(player, FHC.TOGGLE.AnimalOutline) then
        want = true
        radius = math.max(radius, SB.outlineRadius())
    end
    return want, radius
end

local function canonicalForCorpse(corpse)
    if not corpse then return nil end
    do
        local ok, t = U.tryCall(corpse, "getAnimalType")
        if t then return FHC.ANIMAL_BY_ALIAS[string.lower(tostring(t))] end
    end
    do
        local ok, rawName = U.tryCall(corpse, "getCarcassName")
        local name = ok and rawName and string.lower(tostring(rawName)) or nil
        if not name then return nil end
        for alias, canonical in pairs(FHC.ANIMAL_BY_ALIAS) do
            if string.find(name, alias, 1, true) then return canonical end
        end
    end
    return nil
end

local function addAnimalRow(out, obj, canonical, atype, kind)
    local x, y, z = U.objectPosition(obj)
    if not x then return end
    if not atype then
        local okType, rawType = U.tryCall(obj, "getAnimalType")
        atype = okType and rawType or canonical
    end
    local okFemale, female = U.tryCall(obj, "isFemale")
    local okAge, age = U.tryCall(obj, "getAge")
    table.insert(out, {
        x = x, y = y, z = z,
        canonical = canonical, type = atype,
        age = okAge and (tonumber(age) or 0) or 0,
        gender = okFemale and (female and "F" or "M") or "?",
        kind = kind or "animal",
        ref = obj,
    })
end

local function addCorpseRows(out, cell, player, radius)
    local plX, plY, plZ = U.objectPosition(player)
    if not plX then return end
    local r2 = radius * radius
    for sx = math.floor(plX - radius), math.ceil(plX + radius) do
        for sy = math.floor(plY - radius), math.ceil(plY + radius) do
            local dx, dy = sx - plX, sy - plY
            if (dx * dx + dy * dy) <= r2 then
                local okSq, sq = U.tryCall(cell, "getGridSquare", sx, sy, math.floor(plZ))
                if sq and sq.getStaticMovingObjects then
                    local okMoving, moving = U.tryCall(sq, "getStaticMovingObjects")
                    for j = 0, U.listSize(moving) - 1 do
                        local obj = U.listGet(moving, j)
                        if U.isAnimalCorpse(obj) then
                            addAnimalRow(out, obj, canonicalForCorpse(obj), nil, "corpse")
                        end
                    end
                end
            end
        end
    end
end

local function doLocalScan(player, radius)
    local cell = getCell()
    if not cell then return end
    local plX, plY, plZ = U.objectPosition(player)
    if not plX then return end
    local r2 = radius * radius
    local out = {}
    local okList, list = U.tryCall(cell, "getObjectList")
    for i = 0, U.listSize(list) - 1 do
        local obj = U.listGet(list, i)
        if U.isLivingAnimal(obj) then
            local x, y, z = U.objectPosition(obj)
            if x then
                local dx = x - plX
                local dy = y - plY
                if (dx * dx + dy * dy) <= r2 and math.floor(z) == math.floor(plZ) then
                    local okType, atype = U.tryCall(obj, "getAnimalType")
                    local canonical = okType and atype and FHC.ANIMAL_BY_ALIAS[string.lower(tostring(atype))] or nil
                    addAnimalRow(out, obj, canonical, atype, "animal")
                end
            end
        end
    end
    addCorpseRows(out, cell, player, radius)
    Scan.results = out
    Scan.lastAt = getTimestampMs and getTimestampMs() or 0
end

local function requestServerScan(player, radius)
    local t = getTimestampMs and getTimestampMs() or 0
    if (t - Scan.requestAt) < math.max(SB.scanThrottleMs() * 2, 1000) then return end
    Scan.requestAt = t
    sendClientCommand(player, FHC.MODULE, FHC.CMD.TrackingScanRequest, { radius = radius })
end

local function tick()
    local player = getSpecificPlayer(0)
    if not player then return end
    local want, radius = wantedRadius(player)
    if not want then
        Scan.results = {}
        return
    end
    Scan.radius = radius
    local t = getTimestampMs and getTimestampMs() or 0
    if (t - Scan.lastAt) < SB.scanThrottleMs() * 2 then return end
    if isClient and isClient() then
        requestServerScan(player, radius)
    else
        doLocalScan(player, radius)
    end
end

if FHC.Client and FHC.Client.lastTrackingResult then
    local pending = FHC.Client.lastTrackingResult
    Scan.receiveServerResults(pending.rows or {}, pending.radius or 0)
end

Events.OnPlayerUpdate.Add(tick)
