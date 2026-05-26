-- FHC_AnimalOutline.lua
-- Yellow outline for server-approved animal/carcass scan rows.

require "FHC_Constants"
require "FHC_Sandbox"
require "FHC_Utils"
require "Foraging/ISSearchManager"
require "Foraging/ISSearchWindow"

if isServer() then return end

local U  = FHC.Utils
local SB = FHC.SB

local PLAYER_NUM = 0
local lastHi = {}
local lastHiCount = 0

local function clearAll()
    for obj, _ in pairs(lastHi) do
        if obj then U.setYellowOutline(obj, PLAYER_NUM, false) end
    end
    lastHi = {}
    lastHiCount = 0
end

local function shouldRun(player)
    if not SB.outline() then return false end
    if not U.getToggle(player, FHC.TOGGLE.AnimalOutline) then return false end
    local alwaysOn = U.getToggle(player, FHC.TOGGLE.OutlineAlwaysOn)
    if alwaysOn and SB.outlineAlwaysOnAllowed() then
        return true
    end
    local mgr = ISSearchManager and ISSearchManager.getManager and ISSearchManager.getManager(player)
    local win = ISSearchWindow and ISSearchWindow.players and ISSearchWindow.players[player]
    return mgr and mgr.isSearchMode
        and win and win.searchFocusCategory == "Tracks"
end

local function sameTile(obj, row)
    if not obj or not row then return false end
    local x, y, z = U.objectPosition(obj)
    if not x then return false end
    return math.abs(x - row.x) <= 1.0
        and math.abs(y - row.y) <= 1.0
        and math.floor(z) == math.floor(row.z or 0)
end

local function resolveAnimal(cell, row)
    if row.ref then return row.ref end
    if not cell or not row then return nil end
    if row.kind == "corpse" then
        local okSq, sq = U.tryCall(cell, "getGridSquare", math.floor(row.x), math.floor(row.y), math.floor(row.z or 0))
        if sq then
            local okMoving, moving = U.tryCall(sq, "getStaticMovingObjects")
            for i = 0, U.listSize(moving) - 1 do
                local obj = U.listGet(moving, i)
                if U.isAnimalCorpse(obj) and sameTile(obj, row) then
                    return obj
                end
            end
        end
        return nil
    end

    local okList, list = U.tryCall(cell, "getObjectList")
    for i = 0, U.listSize(list) - 1 do
        local obj = U.listGet(list, i)
        if U.isLivingAnimal(obj) and sameTile(obj, row) then
            local okType, atype = U.tryCall(obj, "getAnimalType")
            local canonical = okType and atype and FHC.ANIMAL_BY_ALIAS[string.lower(tostring(atype))] or nil
            if not row.canonical or not canonical or row.canonical == canonical then
                return obj
            end
        end
    end
    return nil
end

local function update()
    if not U.throttled("fhc_outline", SB.scanThrottleMs()) then return end
    local player = getSpecificPlayer(PLAYER_NUM)
    if not player then return end
    if not shouldRun(player) then
        if lastHiCount > 0 then clearAll() end
        return
    end

    local trackingLvl = (player.getPerkLevel and Perks and Perks.Tracking)
        and player:getPerkLevel(Perks.Tracking) or 0
    local alpha = math.min(0.55 + (trackingLvl / 20), 1.0)
    local cell = getCell()
    if not cell then return end

    local newHi = {}
    local newHiCount = 0
    local snap = FHC.Scan and FHC.Scan.snapshot() or {}
    for _, row in ipairs(snap) do
        local obj = resolveAnimal(cell, row)
        if obj then
            U.setYellowOutline(obj, PLAYER_NUM, true, alpha)
            newHi[obj] = true
            newHiCount = newHiCount + 1
        end
    end

    for obj, _ in pairs(lastHi) do
        if not newHi[obj] and obj then
            U.setYellowOutline(obj, PLAYER_NUM, false)
        end
    end
    lastHi = newHi
    lastHiCount = newHiCount
end

Events.OnPlayerUpdate.Add(update)
