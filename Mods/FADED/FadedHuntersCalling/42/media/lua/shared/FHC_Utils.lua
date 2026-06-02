-- FHC_Utils.lua
-- Tiny, side-effect-free helpers. No globals beyond FHC.Utils.

require "FHC_Constants"

FHC.Utils = FHC.Utils or {}
FHC.ServerActiveScents = FHC.ServerActiveScents or {}
FHC.ServerActiveAnimalCalls = FHC.ServerActiveAnimalCalls or {}
FHC.ServerAnimalCallCooldowns = FHC.ServerAnimalCallCooldowns or {}
local U = FHC.Utils

function U.log(msg)
    if SandboxVars and SandboxVars.FadedHuntersCalling and SandboxVars.FadedHuntersCalling.Debug_Logging then
        print(FHC.LOG_PREFIX .. tostring(msg))
    end
end

function U.warn(msg)
    print(FHC.LOG_PREFIX .. "WARN: " .. tostring(msg))
end

function U.err(msg)
    print(FHC.LOG_PREFIX .. "ERR: " .. tostring(msg))
end

function U.isMP()
    return isClient and isClient() or false
end

function U.isHost()
    return isServer and isServer() or false
end

function U.now()
    local gt = getGameTime and getGameTime()
    if gt and gt.getWorldAgeHours then
        return gt:getWorldAgeHours()
    end
    return 0
end

function U.tryCall(target, methodName, ...)
    if not target or type(methodName) ~= "string" then return false, nil end
    local okMethod, method = pcall(function() return target[methodName] end)
    if not okMethod then return false, nil end
    if type(method) ~= "function" then return false, nil end
    return pcall(method, target, ...)
end

function U.listSize(list)
    local ok, size = U.tryCall(list, "size")
    size = ok and tonumber(size) or 0
    if not size or size <= 0 then return 0 end
    return math.floor(size)
end

function U.listGet(list, index)
    local ok, value = U.tryCall(list, "get", index)
    if ok then return value end
    return nil
end

function U.objectPosition(obj)
    local okX, x = U.tryCall(obj, "getX")
    local okY, y = U.tryCall(obj, "getY")
    local okZ, z = U.tryCall(obj, "getZ")
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if okX and okY and okZ and x and y and z then
        return x, y, z
    end
    return nil, nil, nil
end

function U.isInstance(obj, className)
    if not obj or not className or not instanceof then return false end
    local ok, result = pcall(instanceof, obj, className)
    return ok and result == true
end

function U.isLivingAnimal(obj)
    if not U.isInstance(obj, "IsoAnimal") then return false end
    local okExists, exists = U.tryCall(obj, "isExistInTheWorld")
    if okExists and not exists then return false end
    local okDead, dead = U.tryCall(obj, "isDead")
    if okDead and dead then return false end
    return true
end

function U.isAnimalCorpse(obj)
    if not U.isInstance(obj, "IsoDeadBody") then return false end
    local okAnimal, isAnimal = U.tryCall(obj, "isAnimal")
    if not okAnimal or not isAnimal then return false end
    local okSkeleton, isSkeleton = U.tryCall(obj, "isAnimalSkeleton")
    if okSkeleton and isSkeleton then return false end
    return true
end

-- Throttling helper. Returns true if the caller is allowed to run now.
-- Use one stable key per call-site.
local _lastFire = {}
function U.throttled(key, intervalMs)
    local t = getTimestampMs and getTimestampMs() or 0
    local last = _lastFire[key] or 0
    if (t - last) < (intervalMs or 500) then
        return false
    end
    _lastFire[key] = t
    return true
end

-- Distance squared between two world objects with x/y getters.
function U.dist2(a, b)
    if not a or not b then return math.huge end
    local ax, ay = U.objectPosition(a)
    local bx, by = U.objectPosition(b)
    if not ax or not bx then return math.huge end
    local dx = ax - bx
    local dy = ay - by
    return dx * dx + dy * dy
end

-- Find an item of fullType in player's inventory (NOT recursive into bags by default).
function U.findItemOfType(player, fullType, recurse)
    if not player then return nil end
    local inv = player:getInventory()
    if not inv then return nil end
    if recurse then
        return inv:getFirstTypeRecurse(fullType)
    end
    return inv:getFirstType(fullType)
end

-- True if player has any item from a list (recursive).
function U.hasAnyOf(player, list)
    if not player or not list then return false end
    local inv = player:getInventory()
    if not inv then return false end
    for _, ft in ipairs(list) do
        if inv:getFirstTypeRecurse(ft) then return true end
    end
    return false
end

function U.itemId(item)
    if item and item.getID then
        return item:getID()
    end
    return nil
end

function U.isRawMeatItem(item)
    if not item or not item.getFullType then return false end
    return FHC.RAW_MEAT_SET[item:getFullType()] == true
end

function U.perkByName(name)
    if not Perks or not name then return nil end
    local map = {
        MetalWelding = Perks.MetalWelding,
        Woodwork = Perks.Woodwork,
        Carving = Perks.Carving,
        Trapping = Perks.Trapping,
        Cooking = Perks.Cooking,
    }
    return map[name]
end

local function itemKey(item)
    local id = U.itemId(item)
    if id ~= nil then return "id:" .. tostring(id) end
    return item
end

local function collectionContainsString(collection, wanted)
    if not collection or not wanted then return false end
    local wantedLower = string.lower(tostring(wanted))

    if collection.contains then
        local ok, result = pcall(function() return collection:contains(wanted) end)
        if ok and result then return true end
    end

    if collection.size and collection.get then
        local ok, size = pcall(function() return collection:size() end)
        if ok and size then
            for i = 0, size - 1 do
                local okGet, value = pcall(function() return collection:get(i) end)
                if okGet and value and string.lower(tostring(value)) == wantedLower then
                    return true
                end
            end
        end
    end

    return false
end

function U.itemHasAnyTag(item, tags)
    if not item or not tags then return false end
    local fullType = item.getFullType and item:getFullType() or nil
    local itemType = item.getType and item:getType() or nil

    for _, tag in ipairs(tags) do
        local tagText = tostring(tag)
        local tagLower = string.lower(tagText)
        local fullLower = fullType and string.lower(tostring(fullType)) or nil
        local typeLower = itemType and string.lower(tostring(itemType)) or nil
        local tagAsFullType = string.gsub(tagLower, ":", ".")
        local tagTypeOnly = string.match(tagLower, "^[%w_]+[:%.](.+)$") or tagLower
        if fullLower == tagLower
            or fullLower == tagAsFullType
            or typeLower == tagLower
            or typeLower == tagTypeOnly then
            return true
        end

        if item.getTags then
            local ok, itemTags = pcall(function() return item:getTags() end)
            if ok and collectionContainsString(itemTags, tagText) then return true end
        end

        if item.getScriptItem then
            local okScript, scriptItem = pcall(function() return item:getScriptItem() end)
            if okScript and scriptItem and scriptItem.getTags then
                local okTags, scriptTags = pcall(function() return scriptItem:getTags() end)
                if okTags and collectionContainsString(scriptTags, tagText) then return true end
            end
        end
    end
    return false
end

function U.itemMatchesSpec(item, spec)
    if not item or not item.getFullType or not spec then return false end
    local ft = item:getFullType()
    if spec.types then
        for _, wanted in ipairs(spec.types) do
            if ft == wanted then return true end
        end
    end
    return U.itemHasAnyTag(item, spec.tags)
end

function U.findInventoryItemMatching(inv, spec, used)
    if not inv or not spec then return nil end
    local function matches(item)
        if not item then return false end
        if used and used[itemKey(item)] then return false end
        if spec.keep and item.getCondition and item:getCondition() <= 0 then return false end
        return U.itemMatchesSpec(item, spec)
    end

    local function scan(container)
        local items = container and container.getItems and container:getItems() or nil
        if not items then return nil end
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            local okMatch, isMatch = pcall(matches, item)
            if okMatch and isMatch then return item end
            if item and item.getInventory then
                local okInv, subInv = pcall(function() return item:getInventory() end)
                if okInv and subInv and subInv ~= container then
                    local found = scan(subInv)
                    if found then return found end
                end
            end
        end
        return nil
    end

    return scan(inv)
end

function U.findRecipeItems(player, recipe)
    if not player or not recipe or not recipe.inputs then return nil, nil end
    local inv = player:getInventory()
    if not inv then return nil, nil end

    local used = {}
    local selected = {}
    for slot, spec in ipairs(recipe.inputs) do
        local count = tonumber(spec.count) or 1
        for _ = 1, count do
            local item = U.findInventoryItemMatching(inv, spec, used)
            if not item then
                return nil, spec
            end
            used[itemKey(item)] = true
            table.insert(selected, { slot = slot, id = U.itemId(item), item = item })
        end
    end
    return selected, nil
end

function U.recipeFeatureAllowed(recipe)
    if not recipe then return false end
    if not U.sb("Enable_Mod", true) then return false end
    if not recipe.feature then return U.sb("Enable_Bushcraft", true) and true or false end
    return U.sb(recipe.feature, true) and true or false
end

function U.recipeSkillAllowed(player, recipe)
    if not player or not recipe or not recipe.skill then return true end
    local perk = U.perkByName(recipe.skill.perk)
    if not perk or not player.getPerkLevel then return true end
    return (player:getPerkLevel(perk) or 0) >= (recipe.skill.level or 0)
end

function U.findFirstRawMeat(player)
    if not player then return nil end
    local inv = player:getInventory()
    if not inv then return nil end
    for _, fullType in ipairs(FHC.RAW_MEAT_TYPES) do
        local item = inv:getFirstTypeRecurse(fullType)
        if item then return item end
    end
    return nil
end

-- Returns the FHC.ANIMALS canonical key for an IsoAnimal, or nil if unknown.
function U.canonicalForAnimal(animal)
    local ok, t = U.tryCall(animal, "getAnimalType")
    if not ok or not t then return nil end
    if not t then return nil end
    return FHC.ANIMAL_BY_ALIAS[string.lower(tostring(t))]
end

function U.nudgeAnimalToward(animal, target)
    if not animal or not target then return false end
    U.tryCall(animal, "setDebugAcceptance", target, 1.0)
    U.tryCall(animal, "setDebugStress", 0)
    U.tryCall(animal, "setIsAlerted", false)

    local tx, ty, tz = U.objectPosition(target)
    if not tx then return false end
    local x = math.floor(tx + 0.5)
    local y = math.floor(ty + 0.5)
    local z = math.floor(tz + 0.5)
    local ok = U.tryCall(animal, "pathToLocation", x, y, z)
    if ok then return true end

    ok = U.tryCall(animal, "pathToCharacter", target)
    if ok then return true end

    local okBehavior, behavior = U.tryCall(animal, "getPathFindBehavior2")
    if okBehavior and behavior then
        ok = U.tryCall(behavior, "pathToLocationF", tx, ty, tz)
        if ok then return true end
    end
    return false
end

function U.animalCallToken(animalKey)
    local call = animalKey and FHC.ANIMAL_CALLS and FHC.ANIMAL_CALLS[animalKey] or nil
    return call and call.token or nil
end

function U.playerKnowsAnimalCall(player, animalKey)
    local token = U.animalCallToken(animalKey)
    if not player or not token then return false end
    if player.getKnownRecipes then
        local known = player:getKnownRecipes()
        if known and known.contains and known:contains(token) then return true end
    end
    if player.isRecipeActuallyKnown then
        local ok, result = pcall(function() return player:isRecipeActuallyKnown(token) end)
        if ok and result then return true end
    end
    return false
end

function U.playAnimalCallSound(player, animalKey)
    local call = animalKey and FHC.ANIMAL_CALLS and FHC.ANIMAL_CALLS[animalKey] or nil
    if not player or not call or not call.sound then return false end
    return U.tryCall(player, "playSound", call.sound)
end

-- Apply yellow outline to an IsoAnimal or animal IsoDeadBody. alpha 0..1.
function U.setYellowOutline(target, playerNum, on, alpha)
    if not target then return end
    pcall(function()
        target:setOutlineHighlight(playerNum or 0, on and true or false)
        if on then
            target:setOutlineHighlightCol(playerNum or 0,
                FHC.COLOR.OutlineYellow.r,
                FHC.COLOR.OutlineYellow.g,
                FHC.COLOR.OutlineYellow.b,
                alpha or 0.85)
        end
    end)
end

-- Sandbox helpers (safe even if FHC sandbox keys are missing — returns the given default).
function U.sb(key, default)
    local sv = SandboxVars and SandboxVars.FadedHuntersCalling or nil
    if not sv then return default end
    local v = sv[key]
    if v == nil then return default end
    return v
end

-- Tracker the GUI should call to know if a feature is allowed (sandbox-on AND mod-on AND optional player toggle).
function U.featureAllowed(sandboxKey)
    if not U.sb("Enable_Mod", true) then return false end
    return U.sb(sandboxKey, true) and true or false
end

-- Apply ProcessingSpeed multiplier to a base time in ticks/seconds.
function U.scaledTime(baseTime)
    local mul = tonumber(U.sb("ProcessingSpeed", 1.0)) or 1.0
    local diffIdx = tonumber(U.sb("Difficulty", 2)) or 2
    local diff = FHC.DIFFICULTY[diffIdx] or FHC.DIFFICULTY[2]
    if mul <= 0 then mul = 1.0 end
    return math.max(15, math.floor(baseTime * diff.timeMul / mul))
end

-- Apply yield multiplier (used by field dress / drying).
function U.scaledYield(baseYield)
    local diffIdx = tonumber(U.sb("Difficulty", 2)) or 2
    local diff = FHC.DIFFICULTY[diffIdx] or FHC.DIFFICULTY[2]
    return math.max(1, math.floor(baseYield * diff.yieldMul + 0.5))
end

-- Read a player toggle (returns sandbox default if missing).
function U.getToggle(player, key)
    if not player then return false end
    local md = player:getModData()
    local t = md[FHC.MD.PlayerToggles]
    if type(t) ~= "table" then
        t = FHC.DefaultToggles()
        md[FHC.MD.PlayerToggles] = t
    end
    if t[key] == nil then
        local def = FHC.DefaultToggles()
        t[key] = def[key]
    end
    return t[key] and true or false
end

function U.setToggle(player, key, value)
    if not player then return end
    local md = player:getModData()
    local t = md[FHC.MD.PlayerToggles]
    if type(t) ~= "table" then
        t = FHC.DefaultToggles()
    end
    t[key] = value and true or false
    md[FHC.MD.PlayerToggles] = t
end

-- Get the player journal (creates default empty structure if missing).
function U.getJournal(player)
    if not player then return nil end
    local md = player:getModData()
    local j = md[FHC.MD.PlayerJournal]
    if type(j) ~= "table" then
        j = {
            kills = {},        -- [canonical] = count
            hides = 0,         -- total cured
            trapsSprung = 0,
            knownAnimals = {}, -- [canonical] = first-seen world-age-hours
            lastUpdate = U.now(),
        }
        md[FHC.MD.PlayerJournal] = j
    end
    return j
end

local function scentAuthorityKey(player)
    if not player then return nil end
    if player.getOnlineID then
        local id = player:getOnlineID()
        if id ~= nil then return "id:" .. tostring(id) end
    end
    if player.getUsername then
        local username = player:getUsername()
        if username then return "user:" .. tostring(username) end
    end
    return tostring(player)
end

local function playerAuthorityKey(player)
    return scentAuthorityKey(player)
end

local function isScentAuthority()
    return isServer and isServer()
end

local function scentIsValid(scent)
    if type(scent) ~= "table" then return false end
    local animal = scent.animal
    if not animal or not FHC.SCENT_ITEMS[animal] then return false end
    local expiresAt = tonumber(scent.expiresAt) or 0
    return expiresAt > U.now()
end

function U.applyAnimalScent(player, animalKey, durationHours)
    if not player or not animalKey or not FHC.SCENT_ITEMS[animalKey] then return false end
    local now = U.now()
    local duration = tonumber(durationHours) or FHC.SCENT_DURATION_HOURS or 4.0
    if duration <= 0 then duration = FHC.SCENT_DURATION_HOURS or 4.0 end
    local scent = {
        animal = animalKey,
        startedAt = now,
        expiresAt = now + duration,
    }
    if isScentAuthority() then
        local key = scentAuthorityKey(player)
        if key then
            FHC.ServerActiveScents[key] = scent
        end
    end
    local md = player:getModData()
    md[FHC.MD.PlayerActiveScent] = scent
    if player.transmitModData then
        player:transmitModData()
    end
    return true
end

function U.clearAnimalScent(player)
    if not player then return end
    if isScentAuthority() then
        local key = scentAuthorityKey(player)
        if key then
            FHC.ServerActiveScents[key] = nil
        end
    end
    local md = player:getModData()
    if md[FHC.MD.PlayerActiveScent] ~= nil then
        md[FHC.MD.PlayerActiveScent] = nil
        if player.transmitModData then
            player:transmitModData()
        end
    end
end

function U.getActiveAnimalScent(player)
    if not player then return nil end
    if isScentAuthority() then
        local key = scentAuthorityKey(player)
        local scent = key and FHC.ServerActiveScents[key] or nil
        if not scentIsValid(scent) then
            U.clearAnimalScent(player)
            return nil
        end
        return scent
    end
    local md = player:getModData()
    local scent = md[FHC.MD.PlayerActiveScent]
    if not scentIsValid(scent) then
        U.clearAnimalScent(player)
        return nil
    end
    return scent
end

local function isAnimalCallAuthority()
    return isServer and isServer()
end

local function animalCallIsValid(call)
    if type(call) ~= "table" then return false end
    local animal = call.animal
    if not animal or not FHC.ANIMAL_CALLS[animal] then return false end
    local expiresAt = tonumber(call.expiresAt) or 0
    return expiresAt > U.now()
end

local function ensureCallCooldownTable(player)
    if not player then return nil end
    local md = player:getModData()
    local cooldowns = md[FHC.MD.PlayerAnimalCallCooldown]
    if type(cooldowns) ~= "table" then
        cooldowns = {}
        md[FHC.MD.PlayerAnimalCallCooldown] = cooldowns
    end
    return cooldowns
end

function U.getAnimalCallCooldownRemaining(player, animalKey)
    if not player or not animalKey then return 0 end
    local now = U.now()
    if isAnimalCallAuthority() then
        local key = playerAuthorityKey(player)
        local serverUntil = key and FHC.ServerAnimalCallCooldowns[key .. ":" .. tostring(animalKey)] or nil
        if serverUntil and serverUntil > now then return serverUntil - now end
    end
    local cooldowns = ensureCallCooldownTable(player)
    local untilTime = cooldowns and tonumber(cooldowns[animalKey]) or 0
    if untilTime and untilTime > now then return untilTime - now end
    return 0
end

function U.setAnimalCallCooldown(player, animalKey, untilTime)
    if not player or not animalKey then return end
    local cooldowns = ensureCallCooldownTable(player)
    if cooldowns then cooldowns[animalKey] = untilTime end
    if isAnimalCallAuthority() then
        local key = playerAuthorityKey(player)
        if key then FHC.ServerAnimalCallCooldowns[key .. ":" .. tostring(animalKey)] = untilTime end
    end
end

function U.applyAnimalCall(player, animalKey, durationHours)
    if not player or not animalKey or not FHC.ANIMAL_CALLS[animalKey] then return false end
    local now = U.now()
    local duration = tonumber(durationHours) or FHC.ANIMAL_CALL_DURATION_HOURS or 0.08
    if duration <= 0 then duration = FHC.ANIMAL_CALL_DURATION_HOURS or 0.08 end
    local cooldown = FHC.ANIMAL_CALL_COOLDOWN_HOURS or 0.25
    local call = {
        animal = animalKey,
        startedAt = now,
        expiresAt = now + duration,
    }
    if isAnimalCallAuthority() then
        local key = playerAuthorityKey(player)
        if key then FHC.ServerActiveAnimalCalls[key] = call end
    end
    local md = player:getModData()
    md[FHC.MD.PlayerActiveAnimalCall] = call
    U.setAnimalCallCooldown(player, animalKey, now + cooldown)
    if player.transmitModData then
        player:transmitModData()
    end
    return true
end

function U.clearAnimalCall(player)
    if not player then return end
    if isAnimalCallAuthority() then
        local key = playerAuthorityKey(player)
        if key then FHC.ServerActiveAnimalCalls[key] = nil end
    end
    local md = player:getModData()
    if md[FHC.MD.PlayerActiveAnimalCall] ~= nil then
        md[FHC.MD.PlayerActiveAnimalCall] = nil
        if player.transmitModData then
            player:transmitModData()
        end
    end
end

function U.getActiveAnimalCall(player)
    if not player then return nil end
    if isAnimalCallAuthority() then
        local key = playerAuthorityKey(player)
        local call = key and FHC.ServerActiveAnimalCalls[key] or nil
        if not animalCallIsValid(call) then
            U.clearAnimalCall(player)
            return nil
        end
        return call
    end
    local md = player:getModData()
    local call = md[FHC.MD.PlayerActiveAnimalCall]
    if not animalCallIsValid(call) then
        U.clearAnimalCall(player)
        return nil
    end
    return call
end

-- Safe pcall wrapper for one-shot Lua callbacks; logs on failure.
function U.safe(fn, label)
    local ok, err = pcall(fn)
    if not ok then
        U.warn((label or "anon") .. ": " .. tostring(err))
    end
end
