--
-- CSR_VehicleCraftSurface (client)
-- =========================================================================
-- Unified "use a parked vehicle as a crafting surface" feature, covering:
--   * Hood (engine cover) -- with closed + parked + facing constraints
--   * Trunk / TruckBed / TruckBedOpen / TrailerTrunk / Cargo
--
-- Strategy: single fallback patch on ISEntityUI.FindCraftSurface. Vanilla's
-- HandcraftLogic + recipe visibility + Crafting UI all funnel through this
-- entry point, so one well-placed override covers every craft path
-- (right-click context, Crafting UI Start, recipe list).
--
-- Yields to:
--   * WayMoreCars              (mod id "WayMoreCars")               -- all
--   * VehicleTrunkCraftingSurface (mod id "VehicleTrunkCraftingSurface") -- trunk only
--
-- Sandbox gates:
--   * EnableVehicleCraftSurfaces  (master, default ON)
--   * EnableVehicleHoodCraft      (hood path, default ON)
--   * EnableVehicleTrunkCraft     (trunk path, default ON)
-- =========================================================================

CSR_VehicleCraftSurface = CSR_VehicleCraftSurface or {}

local CSR_FeatureFlags = CSR_FeatureFlags

local TRUNK_PART_IDS = {
    "TruckBed", "TruckBedOpen", "TrailerTrunk", "Trunk", "Cargo",
}
local TRUNK_KEYWORDS = { "truckbed", "trailertrunk", "trunk", "cargo" }
local TRUNK_MAX_AREA_DIST = 2.25

local HOOD_RANGE = 1.4

-- =========================================================================
-- Helpers
-- =========================================================================

local function getInteractVehicle(player)
    if not player or player:getVehicle() then return nil end
    local v = player.getUseableVehicle and player:getUseableVehicle() or nil
    if v then return v end
    return player.getNearVehicle and player:getNearVehicle() or nil
end

local function lowerContainsAny(s, list)
    if not s then return false end
    local l = string.lower(tostring(s))
    for _, kw in ipairs(list) do
        if string.find(l, kw, 1, true) then return true end
    end
    return false
end

local function getAreaAnchorObject(vehicle, area, player)
    if not vehicle or not area or area == "" then return nil end
    if vehicle:getAreaDist(area, player) > TRUNK_MAX_AREA_DIST then return nil end
    local sq = vehicle:getSquareForArea(area)
    if not sq then return nil end
    local pSq = player:getSquare()
    if pSq and pSq.canReachTo and not pSq:canReachTo(sq) then return nil end
    local objs = sq:getObjects()
    if objs and objs:size() > 0 then return objs:get(0) end
    return nil
end

-- =========================================================================
-- Hood detection (closed, parked, player at front bumper)
-- =========================================================================

local function getVehicleDirRadians(vehicle)
    local y = vehicle:getAngleY() or 0
    if y < 0.00001 and y > -0.00001 then y = 0.0001 end
    local angle = y - 90
    if math.abs(vehicle:getAngleZ() or 0) > 90 then angle = 90 - y end
    return -angle * (math.pi / 180)
end

local function findHoodAnchor(player, vehicle)
    if not (CSR_FeatureFlags and CSR_FeatureFlags.isVehicleHoodCraftEnabled()) then return nil end
    if math.abs(vehicle:getCurrentSpeedKmHour() or 0) > 0.2 then return nil end
    local script = vehicle:getScript()
    if not script or not script:getPartById("EngineDoor") then return nil end
    local hood = vehicle:getPartById("EngineDoor")
    if not hood or not hood:getInventoryItem() then return nil end
    if hood:getDoor() and hood:getDoor():isOpen() then return nil end
    local hoodArea = vehicle:getAreaCenter(hood:getArea())
    if not hoodArea then return nil end
    local dir = getVehicleDirRadians(vehicle)
    local hx = hoodArea:getX() + math.cos(dir) * -1
    local hy = hoodArea:getY() + math.sin(dir) * -1
    local dx = hx - player:getX()
    local dy = hy - player:getY()
    if (dx * dx + dy * dy) > (HOOD_RANGE * HOOD_RANGE) then return nil end
    -- Anchor: hood part's square via its area name.
    return getAreaAnchorObject(vehicle, hood:getArea(), player)
end

-- =========================================================================
-- Trunk / cargo detection (any cargo container area within reach)
-- =========================================================================

local function isCargoPart(part)
    if not part or not part:getItemContainer() then return false end
    return lowerContainsAny(part:getId(), TRUNK_KEYWORDS)
        or lowerContainsAny(part:getArea(), TRUNK_KEYWORDS)
end

local function findTrunkAnchor(player, vehicle)
    if not (CSR_FeatureFlags and CSR_FeatureFlags.isVehicleTrunkCraftEnabled()) then return nil end
    local seen = {}
    -- Fast path: known cargo part IDs.
    for _, partId in ipairs(TRUNK_PART_IDS) do
        local part = vehicle:getPartById(partId)
        if part then
            seen[part] = true
            if isCargoPart(part) then
                local anchor = getAreaAnchorObject(vehicle, part:getArea(), player)
                if anchor then return anchor end
            end
        end
    end
    -- Slow path: keyword scan over all parts (covers modded vehicles).
    local n = vehicle.getPartCount and vehicle:getPartCount() or 0
    for i = 0, n - 1 do
        local part = vehicle:getPartByIndex(i)
        if part and not seen[part] and isCargoPart(part) then
            local anchor = getAreaAnchorObject(vehicle, part:getArea(), player)
            if anchor then return anchor end
        end
    end
    return nil
end

-- =========================================================================
-- Public: combined finder
-- =========================================================================

function CSR_VehicleCraftSurface.findVehicleSurface(player, _radius)
    if not (CSR_FeatureFlags and CSR_FeatureFlags.isVehicleCraftSurfaceMasterEnabled()) then
        return nil
    end
    local vehicle = getInteractVehicle(player)
    if not vehicle then return nil end
    -- Try hood first (more constrained), then trunk (broader).
    local anchor = findHoodAnchor(player, vehicle)
    if anchor then return anchor end
    return findTrunkAnchor(player, vehicle)
end

-- =========================================================================
-- Patch: ISEntityUI.FindCraftSurface fallback
-- =========================================================================

local function installPatch()
    if not ISEntityUI or not ISEntityUI.FindCraftSurface then return end
    if ISEntityUI.__csr_craftSurfacePatched then return end
    ISEntityUI.__csr_craftSurfacePatched = true
    local _orig = ISEntityUI.FindCraftSurface
    ISEntityUI.FindCraftSurface = function(player, radius)
        local surface = _orig(player, radius)
        if surface then return surface end
        local ok, result = pcall(CSR_VehicleCraftSurface.findVehicleSurface, player, radius)
        if ok then return result end
        return nil
    end
end

Events.OnGameStart.Add(installPatch)
Events.OnCreatePlayer.Add(installPatch)
