-- CSR_OutfitSetsUtil.lua  (v1.8.34)
-- Shared helpers for the Outfit Sets feature.
-- Inspired by Yuki's "Outfit Control" mod (Workshop id 3610760744) — used
-- with the author's permission. This is a from-scratch reimplementation
-- with different match semantics, multi-container scan in safehouses,
-- categories, and a sandbox-tunable wardrobe capacity bonus.
require "CSR_FeatureFlags"

CSR_OutfitSetsUtil = CSR_OutfitSetsUtil or {}

local sandbox = function() return SandboxVars and SandboxVars.CommonSenseReborn or {} end

-- Wardrobe-class furniture: we match by sprite CustomName like the source
-- mod, but expand the list and add a couple of safe synonyms.
local WARDROBE_NAMES = {
    ["Wardrobe"] = true,
    ["Shelves"] = true,
    ["Rack"] = true,
    ["Drawers"] = true,
    ["Chest"] = true,
    ["Locker"] = true,
    ["Crate"] = true,
    ["Clothes Stand"] = true,
    ["Dresser"] = true,
    ["Closet"] = true,
}

local CAPACITY_WARDROBE_NAMES = {
    ["Wardrobe"] = true,
    ["Dresser"] = true,
    ["Locker"] = true,
    ["Clothes Stand"] = true,
    ["Closet"] = true,
}

local OUTFIT_SLOTS_KEY = "csrOutfitSets"        -- player ModData
local OUTFIT_WARDROBE_ROOT_KEY = "CSR_OutfitWardrobes_v1"

CSR_OutfitSetsUtil._outfitWardrobeCache = CSR_OutfitSetsUtil._outfitWardrobeCache or {}
CSR_OutfitSetsUtil._capacityPatchInstalled = CSR_OutfitSetsUtil._capacityPatchInstalled or false

-- ─────────────────────────────────────────────────────
-- Sandbox accessors
-- ─────────────────────────────────────────────────────
function CSR_OutfitSetsUtil.isEnabled()
    return sandbox().EnableOutfitSets ~= false
end

-- 1 = anywhere, 2 = safehouse only.
function CSR_OutfitSetsUtil.accessMode()
    local v = tonumber(sandbox().OutfitSetsAccess) or 1
    return v
end

function CSR_OutfitSetsUtil.isSafehouseOnly()
    return CSR_OutfitSetsUtil.accessMode() == 2
end

function CSR_OutfitSetsUtil.allowMultiContainer()
    return sandbox().OutfitSetsMultiContainerScan ~= false
end

function CSR_OutfitSetsUtil.maxSlots()
    local v = tonumber(sandbox().OutfitSetsMaxSlots) or 8
    if v < 1 then v = 1 end
    if v > 64 then v = 64 end
    return v
end

function CSR_OutfitSetsUtil.capacityBonusPct()
    local v = tonumber(sandbox().OutfitSetsWardrobeBonusPct) or 30
    if v < 0 then v = 0 end
    if v > 200 then v = 200 end
    return v
end

-- ─────────────────────────────────────────────────────
-- Object classification
-- ─────────────────────────────────────────────────────
function CSR_OutfitSetsUtil.spriteName(obj)
    if not obj then return nil end
    if not obj.getSprite then return nil end
    local sp = obj:getSprite()
    if not sp then return nil end
    if not sp.getProperties then return nil end
    local props = sp:getProperties()
    if not props then return nil end
    local customName, groupName = nil, nil
    if props.get then
        customName = props:get("CustomName")
        groupName = props:get("GroupName")
    end
    return customName or groupName or nil
end

function CSR_OutfitSetsUtil.isWardrobeObject(obj)
    if not obj then return false end
    if not obj.getContainer then return false end
    local container = obj:getContainer()
    if not container then return false end
    -- Don't fire on fridges/freezers/cooking surfaces.
    local sp = obj.getSprite and obj:getSprite() or nil
    if sp then
        local props = sp.getProperties and sp:getProperties() or nil
        if props then
            local ct = props.get and props:get("container") or nil
            if ct == "fridge" or ct == "freezer" or ct == "stove" or ct == "microwave" then
                return false
            end
        end
    end
    local name = CSR_OutfitSetsUtil.spriteName(obj)
    if name and WARDROBE_NAMES[name] then return true end
    -- Fallback: container type strings PZ already exposes.
    local t = container.getType and container:getType() or nil
    if t == "wardrobe" or t == "wardrobedresser" or t == "clothingrack" or t == "clothingstand" then
        return true
    end
    return false
end

function CSR_OutfitSetsUtil.isCapacityWardrobeObject(obj)
    if not obj then return false end
    if not obj.getContainer then return false end
    local container = obj:getContainer()
    if not container then return false end
    local sp = obj.getSprite and obj:getSprite() or nil
    if sp then
        local props = sp.getProperties and sp:getProperties() or nil
        if props then
            local ct = props.get and props:get("container") or nil
            if ct == "fridge" or ct == "freezer" or ct == "stove" or ct == "microwave" then
                return false
            end
        end
    end
    local name = CSR_OutfitSetsUtil.spriteName(obj)
    if name and CAPACITY_WARDROBE_NAMES[name] then return true end
    local t = container.getType and container:getType() or nil
    return t == "wardrobe"
        or t == "wardrobedresser"
        or t == "clothingrack"
        or t == "clothingstand"
end

-- Bag world object (right-click on a dropped backpack or worn clothing item).
function CSR_OutfitSetsUtil.isBagObject(obj)
    if not obj then return false end
    if instanceof(obj, "IsoWorldInventoryObject") then
        local item = obj.getItem and obj:getItem() or nil
        if item and item.IsInventoryContainer and item:IsInventoryContainer() then
            return true
        end
    end
    return false
end

function CSR_OutfitSetsUtil.objectSpriteId(obj)
    if not obj then return nil end
    local s = obj.getSpriteName and obj:getSpriteName() or nil
    if s and s ~= "" then return s end
    local sp = obj.getSprite and obj:getSprite() or nil
    if sp and sp.getName then return sp:getName() end
    return nil
end

function CSR_OutfitSetsUtil.objectRegistryKeyFromParts(x, y, z, sprite)
    local nx = math.floor(tonumber(x) or 0)
    local ny = math.floor(tonumber(y) or 0)
    local nz = math.floor(tonumber(z) or 0)
    local ns = tostring(sprite or "")
    if ns == "" then return "" end
    return tostring(nx) .. ":" .. tostring(ny) .. ":" .. tostring(nz) .. ":" .. ns
end

function CSR_OutfitSetsUtil.objectRegistryKey(obj)
    if not obj or not obj.getSquare then return "" end
    local sq = obj:getSquare()
    if not sq then return "" end
    return CSR_OutfitSetsUtil.objectRegistryKeyFromParts(
        sq:getX(),
        sq:getY(),
        sq:getZ(),
        CSR_OutfitSetsUtil.objectSpriteId(obj) or "")
end

function CSR_OutfitSetsUtil.objectCommandArgs(obj)
    if not obj then return nil end
    if not obj.getSquare then return nil end
    local sq = obj:getSquare()
    if not sq then return nil end
    local objectIndex = -1
    if obj.getObjectIndex then objectIndex = obj:getObjectIndex() end
    local sprite = CSR_OutfitSetsUtil.objectSpriteId(obj) or ""
    return {
        x = sq:getX(),
        y = sq:getY(),
        z = sq:getZ(),
        objectIndex = objectIndex or -1,
        sprite = sprite,
        key = CSR_OutfitSetsUtil.objectRegistryKeyFromParts(sq:getX(), sq:getY(), sq:getZ(), sprite),
    }
end

local function squareFromArgs(args)
    if not args or args.x == nil or args.y == nil then return nil end
    local cell = getCell and getCell() or nil
    if not cell then return nil end
    local x = tonumber(args.x)
    local y = tonumber(args.y)
    local z = tonumber(args.z or 0)
    if not x or not y or not z then return nil end
    return cell:getGridSquare(x, y, z)
end

function CSR_OutfitSetsUtil.findWardrobeObjectFromArgs(args)
    local sq = squareFromArgs(args)
    if not sq then return nil end
    local objects = sq.getObjects and sq:getObjects() or nil
    local objectIndex = tonumber(args.objectIndex)
    if objects and objectIndex and objectIndex >= 0 and objectIndex < objects:size() then
        local indexed = objects:get(objectIndex)
        if CSR_OutfitSetsUtil.isWardrobeObject(indexed) then return indexed end
    end

    local wantedSprite = tostring(args.sprite or "")
    local fallback = nil
    local function scan(list)
        if not list then return nil end
        for i = 0, list:size() - 1 do
            local obj = list:get(i)
            if CSR_OutfitSetsUtil.isWardrobeObject(obj) then
                if wantedSprite == "" or CSR_OutfitSetsUtil.objectSpriteId(obj) == wantedSprite then
                    return obj
                end
                fallback = fallback or obj
            end
        end
        return nil
    end

    local specialObjects = sq.getSpecialObjects and sq:getSpecialObjects() or nil
    return scan(objects) or scan(specialObjects) or fallback
end

local function outfitWardrobeRoot(create)
    if not getGameTime then return nil end
    local gt = getGameTime()
    if not gt or not gt.getModData then return nil end
    local root = gt:getModData()
    if not root then return nil end
    if create and type(root[OUTFIT_WARDROBE_ROOT_KEY]) ~= "table" then
        root[OUTFIT_WARDROBE_ROOT_KEY] = {}
    end
    return root[OUTFIT_WARDROBE_ROOT_KEY]
end

function CSR_OutfitSetsUtil.setOutfitWardrobeKey(key, enabled)
    key = tostring(key or "")
    if key == "" then return false end
    local cache = CSR_OutfitSetsUtil._outfitWardrobeCache
    if enabled then cache[key] = true else cache[key] = nil end
    local root = outfitWardrobeRoot(enabled == true)
    if root then
        if enabled then root[key] = true else root[key] = nil end
    end
    return true
end

function CSR_OutfitSetsUtil.isOutfitWardrobeKey(key)
    key = tostring(key or "")
    if key == "" then return false end
    if CSR_OutfitSetsUtil._outfitWardrobeCache[key] == true then return true end
    local root = outfitWardrobeRoot(false)
    return root and root[key] == true or false
end

function CSR_OutfitSetsUtil.isOutfitWardrobeObject(obj)
    return CSR_OutfitSetsUtil.isOutfitWardrobeKey(CSR_OutfitSetsUtil.objectRegistryKey(obj))
end

function CSR_OutfitSetsUtil.getOutfitWardrobeSnapshot()
    local out = {}
    local root = outfitWardrobeRoot(false)
    if root then
        for k, v in pairs(root) do
            if v == true then out[tostring(k)] = true end
        end
    else
        for k, v in pairs(CSR_OutfitSetsUtil._outfitWardrobeCache) do
            if v == true then out[tostring(k)] = true end
        end
    end
    return out
end

function CSR_OutfitSetsUtil.replaceOutfitWardrobeSnapshot(snapshot)
    CSR_OutfitSetsUtil._outfitWardrobeCache = {}
    if type(snapshot) ~= "table" then return end
    for k, v in pairs(snapshot) do
        if v == true then
            CSR_OutfitSetsUtil._outfitWardrobeCache[tostring(k)] = true
        end
    end
    CSR_OutfitSetsUtil.refreshInventoryUI()
end

-- ─────────────────────────────────────────────────────
-- Safehouse access check (player must own / be member of the claim).
-- ─────────────────────────────────────────────────────
function CSR_OutfitSetsUtil.playerHasSafehouseAccess(player, square)
    if not player or not square then return false end
    if not (SafeHouse and SafeHouse.getSafeHouse) then
        -- Fallback API name in some PZ builds.
        if not (SafeHouse and SafeHouse.getSafehouseForSquare) then return false end
    end
    local sh = nil
    if SafeHouse.getSafeHouse then sh = SafeHouse.getSafeHouse(square) end
    if not sh and SafeHouse.getSafehouseForSquare then sh = SafeHouse.getSafehouseForSquare(square) end
    if not sh then return false end
    local username = player.getUsername and player:getUsername() or ""
    if username == "" then return true end -- SP fallback
    if sh.getOwner and sh:getOwner() == username then return true end
    if sh.isOwner and sh:isOwner(username) then return true end
    if sh.getPlayers then
        local list = sh:getPlayers()
        if list then
            for i = 0, list:size() - 1 do
                if tostring(list:get(i)) == username then return true end
            end
        end
    end
    return false
end

function CSR_OutfitSetsUtil.canUseHere(player, obj)
    if not CSR_OutfitSetsUtil.isEnabled() then return false end
    if not player or not obj then return false end
    local sq = obj.getSquare and obj:getSquare() or nil
    if not sq then return false end
    if CSR_OutfitSetsUtil.isSafehouseOnly() then
        return CSR_OutfitSetsUtil.playerHasSafehouseAccess(player, sq)
    end
    return true
end

-- ─────────────────────────────────────────────────────
-- Outfit data: stored per-player in player ModData.
--   md.csrOutfitSets[name] = { category=str, items={ {ft=str,bl=str}, ... } }
-- ─────────────────────────────────────────────────────
function CSR_OutfitSetsUtil.getAllOutfits(player)
    if not player or not player.getModData then return {} end
    local md = player:getModData()
    md[OUTFIT_SLOTS_KEY] = md[OUTFIT_SLOTS_KEY] or {}
    return md[OUTFIT_SLOTS_KEY]
end

function CSR_OutfitSetsUtil.getOutfit(player, name)
    if not name then return nil end
    return CSR_OutfitSetsUtil.getAllOutfits(player)[name]
end

function CSR_OutfitSetsUtil.deleteOutfit(player, name)
    local all = CSR_OutfitSetsUtil.getAllOutfits(player)
    all[name] = nil
end

function CSR_OutfitSetsUtil.outfitCount(player)
    local n = 0
    for _ in pairs(CSR_OutfitSetsUtil.getAllOutfits(player)) do n = n + 1 end
    return n
end

-- Items the player is currently wearing, formatted for storage.
function CSR_OutfitSetsUtil.snapshotWornItems(player)
    if not player or not player.getWornItems then return {} end
    local out = {}
    local worn = player:getWornItems()
    if not worn then return out end
    for i = 0, worn:size() - 1 do
        local entry = worn:get(i)
        local item = entry and entry.getItem and entry:getItem() or nil
        if item and CSR_OutfitSetsUtil.isWearable(item) then
            out[#out + 1] = {
                ft = item.getFullType and item:getFullType() or nil,
                bl = item.getBodyLocation and item:getBodyLocation() or "",
            }
        end
    end
    return out
end

function CSR_OutfitSetsUtil.saveOutfit(player, name, category)
    if not player or not name or name == "" then return false end
    local all = CSR_OutfitSetsUtil.getAllOutfits(player)
    if not all[name] and CSR_OutfitSetsUtil.outfitCount(player) >= CSR_OutfitSetsUtil.maxSlots() then
        return false, "MaxSlots"
    end
    local items = CSR_OutfitSetsUtil.snapshotWornItems(player)
    if #items == 0 then return false, "NothingWorn" end
    all[name] = { category = category or "", items = items }
    return true
end

-- ─────────────────────────────────────────────────────
-- Wearable filter
-- ─────────────────────────────────────────────────────
function CSR_OutfitSetsUtil.isWearable(item)
    if not item then return false end
    if item.IsClothing and item:IsClothing() then return true end
    if item.IsInventoryContainer and item:IsInventoryContainer() and item.canBeEquipped and item:canBeEquipped() then
        return true
    end
    return false
end

-- ─────────────────────────────────────────────────────
-- Search-pool gathering: player inventory + player worn + clicked container,
-- plus (when in safehouse + multi-scan enabled) every container in the room.
-- Returns an array of { item=InventoryItem, container=ItemContainer }
-- ─────────────────────────────────────────────────────
local function pushItemsFromContainer(out, container, seenContainers)
    if not container or seenContainers[container] then return end
    seenContainers[container] = true
    if not container.getItems then return end
    local items = container:getItems()
    if not items then return end
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it then out[#out + 1] = { item = it, container = container } end
    end
end

function CSR_OutfitSetsUtil.gatherSearchPool(player, primaryContainer, primaryObj)
    local out = {}
    local seen = {}
    if not player then return out end
    -- Player main inventory (recursive walk handled by getItems plus sub-bags).
    local inv = player:getInventory()
    pushItemsFromContainer(out, inv, seen)
    if inv and inv.getItems then
        local items = inv:getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if it and it.getInventory and it.IsInventoryContainer and it:IsInventoryContainer() then
                pushItemsFromContainer(out, it:getInventory(), seen)
            end
        end
    end
    -- Worn list.
    if player.getWornItems then
        local worn = player:getWornItems()
        for i = 0, worn:size() - 1 do
            local entry = worn:get(i)
            local item = entry and entry.getItem and entry:getItem() or nil
            if item then out[#out + 1] = { item = item, container = item:getContainer() } end
        end
    end
    -- Primary clicked container (wardrobe).
    pushItemsFromContainer(out, primaryContainer, seen)

    -- Multi-container scan: only in safehouse-only mode AND when allowed AND
    -- the player actually has access to the safehouse the wardrobe sits in.
    if CSR_OutfitSetsUtil.isSafehouseOnly() and CSR_OutfitSetsUtil.allowMultiContainer()
       and primaryObj and primaryObj.getSquare then
        local sq = primaryObj:getSquare()
        if sq and CSR_OutfitSetsUtil.playerHasSafehouseAccess(player, sq) then
            local cell = getCell()
            local room = sq.getRoom and sq:getRoom() or nil
            local squares = nil
            if room and room.getSquares then
                squares = room:getSquares()
            end
            if squares and squares.size then
                for i = 0, squares:size() - 1 do
                    local rsq = squares:get(i)
                    if rsq and rsq.getObjects then
                        local objs = rsq:getObjects()
                        for j = 0, objs:size() - 1 do
                            local o = objs:get(j)
                            local c = o and o.getContainer and o:getContainer() or nil
                            if c then pushItemsFromContainer(out, c, seen) end
                        end
                    end
                end
            else
                -- Fallback: 4-tile radius scan.
                if cell then
                    local r = 4
                    local sx, sy, sz = sq:getX(), sq:getY(), sq:getZ()
                    for x = sx - r, sx + r do
                        for y = sy - r, sy + r do
                            local rsq = cell:getGridSquare(x, y, sz)
                            if rsq and rsq.getObjects then
                                local objs = rsq:getObjects()
                                for j = 0, objs:size() - 1 do
                                    local o = objs:get(j)
                                    local c = o and o.getContainer and o:getContainer() or nil
                                    if c then pushItemsFromContainer(out, c, seen) end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return out
end

-- ─────────────────────────────────────────────────────
-- Best-condition match for a saved-outfit slot entry.
-- ─────────────────────────────────────────────────────
local function itemConditionRatio(item)
    if not item then return 0 end
    local mx = item.getConditionMax and item:getConditionMax() or 0
    if not mx or mx == 0 then return 1 end
    local cv = item.getCondition and item:getCondition() or mx
    return (tonumber(cv) or 0) / (tonumber(mx) or 1)
end

function CSR_OutfitSetsUtil.pickBestMatch(pool, ft, bl, alreadyUsed)
    if not pool or not ft then return nil end
    local best, bestScore = nil, -1
    for i = 1, #pool do
        local entry = pool[i]
        local it = entry.item
        if it and not alreadyUsed[it]
           and CSR_OutfitSetsUtil.isWearable(it)
           and it.getFullType and it:getFullType() == ft then
            -- Body-location tiebreak (some items share fulltype but not bl).
            local ibl = it.getBodyLocation and it:getBodyLocation() or ""
            local score = itemConditionRatio(it)
            if bl and bl ~= "" and ibl == bl then score = score + 0.5 end
            if score > bestScore then
                bestScore = score; best = entry
            end
        end
    end
    return best
end

-- ─────────────────────────────────────────────────────
-- Wardrobe capacity bonus. In SP this is a read-only effective-capacity
-- adjustment for true wardrobes; in MP it only applies to server-approved
-- Outfit Wardrobes from the registry.
-- ─────────────────────────────────────────────────────
function CSR_OutfitSetsUtil.refreshInventoryUI()
    if ISInventoryPage and ISInventoryPage.dirtyUI then ISInventoryPage.dirtyUI() end
    if not getPlayer or not getPlayerData then return end
    local player = getPlayer()
    if not player or not player.getPlayerNum then return end
    local playerData = getPlayerData(player:getPlayerNum())
    if playerData then
        if playerData.playerInventory then playerData.playerInventory:refreshBackpacks() end
        if playerData.lootInventory then playerData.lootInventory:refreshBackpacks() end
    end
end

function CSR_OutfitSetsUtil.applyCapacityValue(obj, capacity, baseCapacity, transmit)
    local newCap = tonumber(capacity) or 0
    if newCap <= 0 then return end
    CSR_OutfitSetsUtil.refreshInventoryUI()
    return true, newCap, tonumber(baseCapacity) or newCap
end

function CSR_OutfitSetsUtil.applyCapacityBonus(obj, transmit)
    if not obj then return end
    local pct = CSR_OutfitSetsUtil.capacityBonusPct()
    if pct <= 0 then return end
    if not CSR_OutfitSetsUtil.isCapacityWardrobeObject(obj) then return end
    if isClient and isClient() and not CSR_OutfitSetsUtil.isOutfitWardrobeObject(obj) then return end
    if isServer and isServer() and not (isClient and isClient())
            and not CSR_OutfitSetsUtil.isOutfitWardrobeObject(obj) then return end
    if not obj.getContainer then return end
    local container = obj:getContainer()
    if not container then return end
    local cap = 0
    if container.getCapacity then cap = container:getCapacity() end
    if not cap or cap <= 0 then return end
    local newCap = math.floor(cap * (1 + pct / 100))
    return true, newCap, cap
end

function CSR_OutfitSetsUtil.requestCapacityBonus(player, obj)
    return CSR_OutfitSetsUtil.applyCapacityBonus(obj, false)
end

function CSR_OutfitSetsUtil.capacityBonusAppliesToObject(obj)
    if CSR_OutfitSetsUtil.capacityBonusPct() <= 0 then return false end
    if not CSR_OutfitSetsUtil.isCapacityWardrobeObject(obj) then return false end
    if isClient and isClient() then
        return CSR_OutfitSetsUtil.isOutfitWardrobeObject(obj)
    end
    if isServer and isServer() then
        return CSR_OutfitSetsUtil.isOutfitWardrobeObject(obj)
    end
    return true
end

local function capacityParent(container)
    if not container or not container.getParent then return nil end
    return container:getParent()
end

function CSR_OutfitSetsUtil.adjustEffectiveCapacity(container, player, currentCapacity)
    local parent = capacityParent(container)
    if not CSR_OutfitSetsUtil.capacityBonusAppliesToObject(parent) then
        return currentCapacity
    end
    local base = tonumber(currentCapacity) or 0
    if base <= 0 and container and container.getCapacity then
        base = tonumber(container:getCapacity()) or 0
    end
    if base <= 0 then return currentCapacity end
    return math.floor(base * (1 + CSR_OutfitSetsUtil.capacityBonusPct() / 100))
end

function CSR_OutfitSetsUtil.installCapacityPatch()
    if CSR_OutfitSetsUtil._capacityPatchInstalled then return true end
    if not ItemContainer or not __classmetatables or not ItemContainer.class then return false end
    local mt = __classmetatables[ItemContainer.class]
    local index = mt and mt.__index or nil
    if not index or not index.getEffectiveCapacity or not index.hasRoomFor then return false end

    local originalGetEffectiveCapacity = index.getEffectiveCapacity
    local originalHasRoomFor = index.hasRoomFor

    index.getEffectiveCapacity = function(container, player)
        local capacity = originalGetEffectiveCapacity(container, player)
        return CSR_OutfitSetsUtil.adjustEffectiveCapacity(container, player, capacity)
    end

    index.hasRoomFor = function(container, player, item)
        local parent = capacityParent(container)
        if CSR_OutfitSetsUtil.capacityBonusAppliesToObject(parent) then
            local itemWeight = tonumber(item)
            if not itemWeight then
                if item and item.getUnequippedWeight then
                    itemWeight = tonumber(item:getUnequippedWeight()) or 0
                else
                    itemWeight = 0
                end
            end
            local content = container.getContentsWeight and (tonumber(container:getContentsWeight()) or 0) or 0
            local capacity = container.getEffectiveCapacity and (tonumber(container:getEffectiveCapacity(player)) or 0) or 0
            return content + itemWeight <= capacity
        end
        return originalHasRoomFor(container, player, item)
    end

    CSR_OutfitSetsUtil._capacityPatchInstalled = true
    return true
end

local function installCapacityPatchOnTick()
    if CSR_OutfitSetsUtil.installCapacityPatch() and Events and Events.OnTick then
        Events.OnTick.Remove(installCapacityPatchOnTick)
    end
end

if Events and Events.OnTick then
    Events.OnTick.Add(installCapacityPatchOnTick)
else
    CSR_OutfitSetsUtil.installCapacityPatch()
end

return CSR_OutfitSetsUtil
