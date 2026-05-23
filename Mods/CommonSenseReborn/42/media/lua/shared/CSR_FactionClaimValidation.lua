require "CSR_FeatureFlags"

--[[
    CSR_FactionClaimValidation.lua (shared, v1.7.0)

    Pre-claim validation for faction safehouses. Adds checks beyond the basic
    "is the rectangle already claimed" gate that the existing faction claim
    server handler performs:

      1. Spawn-protection radius   - reject claims within N tiles of a vanilla
                                     spawn region (configurable; default 50).
      2. Residential-building hint - prefer real houses over generic large
                                     buildings (warehouses, factories) by
                                     checking the building's def for a
                                     "residential" room set (best-effort).
      3. Padding distance          - reject claims within FactionClaimPadding
                                     tiles of an existing safehouse (personal
                                     OR faction).  Prevents border-stacking.

    Each check uses explicit nil guards (no pcall masking) so that any genuine
    bug surfaces in the log rather than silently allowing the claim. The
    existing claim handler still owns the strict "rectangle already claimed"
    check, so this module never weakens security, only refuses claims for
    clearer reasons.

    Returns:
        ok  : true when the claim is allowed
        err : human-readable reason when ok=false
]]

CSR_FactionClaimValidation = CSR_FactionClaimValidation or {}

local function sandbox()
    return SandboxVars and SandboxVars.CommonSenseReborn or {}
end

-- Configurable knobs (defaults match sandbox-options.txt entries below).
local function getPadding()        return sandbox().FactionClaimPadding         or 0  end
local function getSpawnRadius()    return sandbox().FactionClaimSpawnRadius     or 50 end
local function isSpawnProtectOn()  return sandbox().FactionClaimRespectSpawn   ~= false end
local function isResidentialOnly() return sandbox().FactionClaimResidentialOnly == true end

-- ----------------------------------------------------------------------------
-- Helper: rectangle-distance (Chebyshev, in tiles) between two AABBs.
-- ----------------------------------------------------------------------------
local function rectDistance(ax, ay, aw, ah, bx, by, bw, bh)
    local dx = math.max(0, math.max(ax - (bx + bw), bx - (ax + aw)))
    local dy = math.max(0, math.max(ay - (by + bh), by - (ay + ah)))
    return math.max(dx, dy)
end

-- ----------------------------------------------------------------------------
-- Iterate every existing safehouse rectangle.
-- Returns table-of-tables: { {x,y,w,h,owner,facTag}, ... }
-- ----------------------------------------------------------------------------
local function listAllSafehouses()
    local out = {}
    if not (SafeHouse and SafeHouse.getSafehouseList) then return out end
    local list = SafeHouse.getSafehouseList()
    if not list or not list.size then return out end
    local sz = list:size()
    for i = 0, sz - 1 do
        local sh = list:get(i)
        if sh then
            local md = sh.getModData and sh:getModData()
            local facTag = md and md.csrFactionOwner or nil
            table.insert(out, {
                x = sh:getX(), y = sh:getY(),
                w = sh:getW(), h = sh:getH(),
                owner = sh:getOwner(),
                facTag = facTag,
            })
        end
    end
    return out
end

-- ----------------------------------------------------------------------------
-- Best-effort spawn-region proximity check.
-- B42 exposes spawn-region data via getSpawnRegions(); each region carries
-- one or more spawn points. If any of the calls in the chain returns nil
-- we simply fall through to "no protection" rather than blocking everything.
-- Note: method-existence is checked with `obj.method` (dot, gets the bound
-- method as a value); the call itself uses `obj:method()` (colon).
-- ----------------------------------------------------------------------------
local function hasNearbySpawnPoint(x, y, radius)
    if not getSpawnRegions then return false end
    local regions = getSpawnRegions()
    if not regions or not regions.size then return false end
    local rSz = regions:size()
    for i = 0, rSz - 1 do
        local region = regions:get(i)
        if region and region.getSpawnPoints then
            local pts = region:getSpawnPoints()
            if pts and pts.size then
                local pSz = pts:size()
                for j = 0, pSz - 1 do
                    local p = pts:get(j)
                    if p then
                        local px = (p.getPosX and p:getPosX()) or p.posX or 0
                        local py = (p.getPosY and p:getPosY()) or p.posY or 0
                        if math.abs(px - x) <= radius and math.abs(py - y) <= radius then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

-- ----------------------------------------------------------------------------
-- Heuristic: building looks residential.
--   * non-zero number of "rooms" of names matching kitchen/bedroom/livingroom.
--   * fewer than ~30 squares per room (warehouses/factories are huge).
-- This is intentionally lenient: when in doubt, return true.
-- ----------------------------------------------------------------------------
local function looksResidential(x, y)
    local cell = getCell and getCell()
    if not cell then return true end
    local sq = cell:getGridSquare(x, y, 0)
    if not sq then return true end
    local building = sq:getBuilding()
    if not building then return true end
    local def = building:getDef()
    if not def then return true end
    local rooms = def:getRooms()
    if not rooms or not rooms.size then return true end
    local rSz = rooms:size()
    if rSz <= 0 then return true end
    local resCount = 0
    for i = 0, rSz - 1 do
        local rd = rooms:get(i)
        if rd and rd.getName then
            local n = string.lower(rd:getName() or "")
            if n:find("kitchen") or n:find("bedroom") or n:find("livingroom")
               or n:find("bathroom") or n:find("dining") or n:find("hallway") then
                resCount = resCount + 1
            end
        end
    end
    return resCount > 0
end

-- ----------------------------------------------------------------------------
-- Public: validate a faction-claim attempt.
--   x,y,w,h     : building rectangle in world tiles
--   factionName : faction attempting the claim (used to skip self-padding)
--
-- Returns: ok (boolean), errorText (string or nil)
-- ----------------------------------------------------------------------------
function CSR_FactionClaimValidation.canClaim(x, y, w, h, factionName)
    -- Spawn protection
    if isSpawnProtectOn() then
        if hasNearbySpawnPoint(x, y, getSpawnRadius()) then
            return false, "Too close to a spawn region (within "
                .. tostring(getSpawnRadius()) .. " tiles)"
        end
    end

    -- Residential check
    if isResidentialOnly() and not looksResidential(x, y) then
        return false, "Faction safehouses must be claimed in residential buildings"
    end

    -- Padding against any existing safehouse (other than ourselves).
    local pad = getPadding()
    if pad > 0 then
        local all = listAllSafehouses()
        for _, e in ipairs(all) do
            -- Skip exact match (the engine will reject it separately as
            -- "already claimed" -- not our concern).
            if not (e.x == x and e.y == y) then
                local d = rectDistance(x, y, w, h, e.x, e.y, e.w, e.h)
                if d < pad then
                    return false, "Too close to another safehouse ("
                        .. tostring(math.floor(d)) .. " < " .. tostring(pad) .. " tiles)"
                end
            end
        end
    end

    return true, nil
end

return CSR_FactionClaimValidation
