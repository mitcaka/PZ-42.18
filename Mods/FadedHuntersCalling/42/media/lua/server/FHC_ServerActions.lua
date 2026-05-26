-- FHC_ServerActions.lua
-- Validated handlers for every network command the client can send.

require "FHC_ServerMain"
require "FHC_ServerValidation"
require "FHC_AnimalCallAttraction"

if not isServer() then return end

local S = FHC.Server
local V = S.V
local U = FHC.Utils
local SB = FHC.SB

local function itemFullType(item)
    if item and item.getFullType then
        return item:getFullType()
    end
    return nil
end

local function getInvItemById(player, id)
    if not player or id == nil then return nil end
    local inv = player:getInventory()
    if inv and inv.getItemWithID then
        local item = inv:getItemWithID(id)
        if item then return item end
    end
    if inv and inv.getAllEvalRecurse then
        local list = inv:getAllEvalRecurse(function(item)
            return item and item.getID and item:getID() == id
        end)
        if U.listSize(list) > 0 then
            return U.listGet(list, 0)
        end
    end
    return nil
end

local function addInvItem(player, fullType)
    local inv = player and player:getInventory() or nil
    if not inv or not fullType then return nil end
    local item = inv:AddItem(fullType)
    if item and sendAddItemToContainer then
        sendAddItemToContainer(inv, item)
    end
    return item
end

local function removeInvItem(player, item)
    if not player or not item then return false end
    local inv = player:getInventory()
    local container = item.getContainer and item:getContainer() or inv
    if player.removeFromHands then
        player:removeFromHands(item)
    end
    if container and container.Remove then
        container:Remove(item)
    elseif inv then
        inv:Remove(item)
        container = inv
    end
    if sendRemoveItemFromContainer and container then
        sendRemoveItemFromContainer(container, item)
    end
    if container and container.setDrawDirty then
        container:setDrawDirty(true)
    end
    return true
end

local function degradeTool(tool)
    if not tool or not tool.getCondition or not tool.setCondition then return end
    local cond = tool:getCondition()
    if cond and cond > 0 then
        tool:setCondition(cond - 1)
        if sendItemStats then
            sendItemStats(tool)
        end
    end
end

local function toolIsUsable(tool)
    if not tool then return false end
    if tool.getCondition and tool:getCondition() <= 0 then return false end
    return true
end

local function awardXP(player, perk, amount)
    if not player or not perk or not amount then return end
    if addXp then
        addXp(player, perk, amount)
    elseif player.getXp and player:getXp() then
        player:getXp():AddXP(perk, amount)
    end
end

local function awardRecipeXP(player, recipe)
    if not recipe or not recipe.xp then return end
    awardXP(player, U.perkByName(recipe.xp.perk), recipe.xp.amount or 0)
end

local function sendScentResult(player, ok, animalKey)
    if sendServerCommand then
        sendServerCommand(player, FHC.MODULE, FHC.CMD.ApplyScentResult,
            { ok = ok and true or false, animal = animalKey })
    end
end

local function sendAnimalCallResult(player, ok, animalKey, reason)
    if sendServerCommand then
        local cooldowns = player and player:getModData()[FHC.MD.PlayerAnimalCallCooldown] or nil
        sendServerCommand(player, FHC.MODULE, FHC.CMD.AnimalCallResult,
            {
                ok = ok and true or false,
                animal = animalKey,
                reason = reason,
                cooldownUntil = cooldowns and cooldowns[animalKey] or nil,
            })
    end
end

local function validateHubCraft(player, recipe, selections)
    if not recipe or type(selections) ~= "table" then return nil end
    if not U.recipeFeatureAllowed(recipe) then return nil end
    if not U.recipeSkillAllowed(player, recipe) then return nil end

    local chosen = {}
    local used = {}
    local pos = 1
    for slot, spec in ipairs(recipe.inputs or {}) do
        local count = tonumber(spec.count) or 1
        for _ = 1, count do
            local selected = selections[pos]
            if not selected or selected.slot ~= slot or selected.id == nil then return nil end
            local item = getInvItemById(player, selected.id)
            if not item or not U.itemMatchesSpec(item, spec) then return nil end
            local key = tostring(selected.id)
            if used[key] then return nil end
            if spec.keep and item.getCondition and item:getCondition() <= 0 then return nil end
            used[key] = true
            table.insert(chosen, { item = item, spec = spec })
            pos = pos + 1
        end
    end
    if selections[pos] ~= nil then return nil end
    return chosen
end

local function applyHubCraft(player, recipe, chosen)
    for _, entry in ipairs(chosen or {}) do
        if entry.spec.keep then
            if entry.spec.degrade then degradeTool(entry.item) end
        else
            removeInvItem(player, entry.item)
        end
    end
    local outputCount = recipe.outputCount or 1
    for _ = 1, outputCount do
        addInvItem(player, recipe.output)
    end
    awardRecipeXP(player, recipe)
end

local function canonicalFromName(name)
    if not name then return nil end
    return FHC.ANIMAL_BY_ALIAS[string.lower(tostring(name))]
end

local function canonicalForCorpse(corpse)
    if not corpse then return nil end
    do
        local ok, rawType = U.tryCall(corpse, "getAnimalType")
        local canonical = ok and canonicalFromName(rawType) or nil
        if canonical then return canonical end
    end
    do
        local ok, rawName = U.tryCall(corpse, "getCarcassName")
        local name = ok and rawName and string.lower(tostring(rawName)) or nil
        if not name then return nil end
        for alias, canonical in pairs(FHC.ANIMAL_BY_ALIAS) do
            if string.find(name, alias, 1, true) then
                return canonical
            end
        end
    end
    return nil
end

local function isAnimalCorpse(obj)
    return U.isAnimalCorpse(obj)
end

local function findAnimalCorpseNear(x, y, z, expectedCanonical)
    local cell = getCell and getCell() or nil
    if not cell then return nil, nil end
    local sx, sy, sz = math.floor(x), math.floor(y), math.floor(z or 0)
    for dx = -1, 1 do
        for dy = -1, 1 do
                local okSq, sq = U.tryCall(cell, "getGridSquare", sx + dx, sy + dy, sz)
                if sq then
                    local okMoving, moving = U.tryCall(sq, "getStaticMovingObjects")
                    for i = 0, U.listSize(moving) - 1 do
                        local obj = U.listGet(moving, i)
                        if isAnimalCorpse(obj) then
                            local actual = canonicalForCorpse(obj)
                            if not expectedCanonical or not actual or actual == expectedCanonical then
                            return obj, actual
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

local function removeCorpse(corpse)
    if not corpse then return end
    local sq = corpse.getSquare and corpse:getSquare() or nil
    if sq and sq.removeCorpse then
        sq:removeCorpse(corpse, false)
    else
        if corpse.removeFromWorld then corpse:removeFromWorld() end
        if corpse.removeFromSquare then corpse:removeFromSquare() end
    end
    if corpse.invalidateCorpse then
        corpse:invalidateCorpse()
    end
end

local MAX_TRACKING_ROWS = 160
local MAX_TRAP_ROWS = 200
local TRAP_BOARD_RADIUS = 60
S.requestAt = S.requestAt or {}

local function serverNowMs()
    if getTimestampMs then return getTimestampMs() end
    if getTimeInMillis then return getTimeInMillis() end
    if os and os.time then return os.time() * 1000 end
    return math.floor((U.now() or 0) * 3600000)
end

local function requestThrottleKey(player, command)
    if player and player.getOnlineID then
        local id = player:getOnlineID()
        if id ~= nil then return tostring(command) .. ":id:" .. tostring(id) end
    end
    if player and player.getUsername then
        local username = player:getUsername()
        if username then return tostring(command) .. ":user:" .. tostring(username) end
    end
    return tostring(command) .. ":" .. tostring(player)
end

local function requestAllowed(player, command, intervalMs)
    local key = requestThrottleKey(player, command)
    local now = serverNowMs()
    local last = S.requestAt[key] or 0
    if (now - last) < (intervalMs or 1000) then return false end
    S.requestAt[key] = now
    return true
end

local function clampRadius(value, maxRadius)
    local radius = tonumber(value) or 0
    if radius < 0 then radius = 0 end
    if radius > maxRadius then radius = maxRadius end
    return radius
end

local function trackingMaxRadius()
    local radius = 0
    if SB.nearbyPanel() then radius = math.max(radius, 12) end
    if SB.mapMarkers() then radius = math.max(radius, SB.mapMarkersRadius()) end
    if SB.outline() then radius = math.max(radius, SB.outlineRadius()) end
    return math.min(radius, 200)
end

local function addAnimalRow(rows, obj, canonical, kind)
    if #rows >= MAX_TRACKING_ROWS then return end
    local x, y, z = U.objectPosition(obj)
    if not x then return end
    local okType, atype = U.tryCall(obj, "getAnimalType")
    local okFemale, female = U.tryCall(obj, "isFemale")
    local okAge, age = U.tryCall(obj, "getAge")
    table.insert(rows, {
        x = x, y = y, z = z,
        canonical = canonical,
        type = okType and atype or canonical,
        age = okAge and (tonumber(age) or 0) or 0,
        gender = okFemale and (female and "F" or "M") or "?",
        kind = kind or "animal",
    })
end

local function scanAnimalCorpses(rows, player, radius)
    local cell = getCell and getCell() or nil
    if not cell or #rows >= MAX_TRACKING_ROWS then return end
    local corpseRadius = math.min(radius, SB.outlineRadius(), 40)
    if corpseRadius <= 0 then return end
    local plX, plY, plZ = U.objectPosition(player)
    if not plX then return end
    local r2 = corpseRadius * corpseRadius
    for sx = math.floor(plX - corpseRadius), math.ceil(plX + corpseRadius) do
        for sy = math.floor(plY - corpseRadius), math.ceil(plY + corpseRadius) do
            if #rows >= MAX_TRACKING_ROWS then return end
            local dx, dy = sx - plX, sy - plY
            if (dx * dx + dy * dy) <= r2 then
                local okSq, sq = U.tryCall(cell, "getGridSquare", sx, sy, math.floor(plZ))
                if sq then
                    local okMoving, moving = U.tryCall(sq, "getStaticMovingObjects")
                    for i = 0, U.listSize(moving) - 1 do
                        if #rows >= MAX_TRACKING_ROWS then return end
                        local obj = U.listGet(moving, i)
                        if isAnimalCorpse(obj) then
                            addAnimalRow(rows, obj, canonicalForCorpse(obj), "corpse")
                        end
                    end
                end
            end
        end
    end
end

local function scanAnimalsForPlayer(player, radius)
    local rows = {}
    if not player or radius <= 0 then return rows end
    local cell = getCell and getCell() or nil
    if not cell or not cell.getObjectList then return rows end
    local plX, plY, plZ = U.objectPosition(player)
    if not plX then return rows end
    local r2 = radius * radius
    local okList, list = U.tryCall(cell, "getObjectList")
    for i = 0, U.listSize(list) - 1 do
        if #rows >= MAX_TRACKING_ROWS then break end
        local obj = U.listGet(list, i)
        if U.isLivingAnimal(obj) then
            local x, y, z = U.objectPosition(obj)
            if x then
                local dx = x - plX
                local dy = y - plY
                if (dx * dx + dy * dy) <= r2 and math.floor(z) == math.floor(plZ) then
                addAnimalRow(rows, obj, U.canonicalForAnimal(obj), "animal")
                end
            end
        end
    end
    scanAnimalCorpses(rows, player, radius)
    return rows
end

local TRAP_SPRITE_HINTS = {
    "trap", "Trap"
}

local function spriteName(obj)
    local okSprite, sprite = U.tryCall(obj, "getSprite")
    local okName, name = U.tryCall(sprite, "getName")
    return okName and name or nil
end

local function isTrapObj(obj)
    if not obj then return false end
    local name = spriteName(obj)
    if not name then return false end
    for _, hint in ipairs(TRAP_SPRITE_HINTS) do
        if string.find(name, hint, 1, true) then return true end
    end
    return false
end

local function trapStateParts(trap)
    if trap and trap.getModData then
        local md = trap:getModData()
        if md and md.animalType then return "caught", tostring(md.animalType) end
        if md and md.bait then return "baited", tostring(md.bait) end
    end
    return "empty", ""
end

local function scanTrapsForPlayer(player, radius)
    local rows = {}
    if not player or not SB.trapBoard() then return rows end
    local cell = getCell and getCell() or nil
    if not cell then return rows end
    local plX, plY, plZ = U.objectPosition(player)
    if not plX then return rows end
    local r2 = radius * radius
    for sx = math.floor(plX - radius), math.ceil(plX + radius) do
        for sy = math.floor(plY - radius), math.ceil(plY + radius) do
            if #rows >= MAX_TRAP_ROWS then break end
            local dx, dy = sx - plX, sy - plY
            if (dx * dx + dy * dy) <= r2 then
                local okSq, sq = U.tryCall(cell, "getGridSquare", sx, sy, math.floor(plZ))
                if sq then
                    local okObjects, objs = U.tryCall(sq, "getObjects")
                    for i = 0, U.listSize(objs) - 1 do
                        if #rows >= MAX_TRAP_ROWS then break end
                        local obj = U.listGet(objs, i)
                        if isTrapObj(obj) then
                            local stateKey, stateValue = trapStateParts(obj)
                            table.insert(rows, {
                                x = sx, y = sy, z = plZ,
                                stateKey = stateKey,
                                stateValue = stateValue,
                                spr = spriteName(obj) or "trap",
                                dist = math.sqrt(dx * dx + dy * dy),
                            })
                        end
                    end
                end
            end
        end
    end
    table.sort(rows, function(a, b) return a.dist < b.dist end)
    return rows
end

-- Journal entries are written to PLAYER modData. Server is the source of truth.
local function updateJournal(player, mutator)
    if not player then return end
    local md = player:getModData()
    local j = md[FHC.MD.PlayerJournal]
    if type(j) ~= "table" then
        j = { kills = {}, hides = 0, trapsSprung = 0, knownAnimals = {}, lastUpdate = U.now() }
    end
    mutator(j)
    j.lastUpdate = U.now()
    md[FHC.MD.PlayerJournal] = j
    if player.transmitModData then
        player:transmitModData()
    end
end

S.register(FHC.CMD.LogKill, function(player, args)
    -- Legacy client command kept registered for old clients, but ignored.
    -- Journal counters are written by validated server-side actions below.
end)

S.register(FHC.CMD.LogHide, function(player, args)
    -- Legacy client command kept registered for old clients, but ignored.
end)

S.register(FHC.CMD.LogTrapSprung, function(player, args)
    -- Legacy client command kept registered for old clients, but ignored.
end)

S.register(FHC.CMD.FieldDressComplete, function(player, args)
    if not SB.fieldDress() then return end
    if not V.checkArgs(args, { x = "number", y = "number", z = "number" }) then return end
    if not V.playerNearXYZ(player, args.x, args.y, args.z, 4) then
        U.warn("FieldDress: player too far from carcass")
        return
    end

    local expected = args.canonical and FHC.ANIMALS[args.canonical] and args.canonical or nil
    local carcass, actual = findAnimalCorpseNear(args.x, args.y, args.z, expected)
    if not carcass then
        U.warn("FieldDress: no valid animal carcass found")
        return
    end

    local knife = getInvItemById(player, args.knifeId)
    if SB.requireTools() and not toolIsUsable(knife) then
        U.warn("FieldDress: missing or broken knife")
        return
    end

    local canonical = actual or expected
    local meatType = FHC.MEAT_BY_ANIMAL[canonical or ""] or "Base.Smallanimalmeat"
    for i = 1, U.scaledYield(3) do
        addInvItem(player, meatType)
    end
    for i = 1, U.scaledYield(1) do
        addInvItem(player, "Base.FHC_RawHide")
    end
    if ZombRand(100) < 30 then
        addInvItem(player, "Base.FHC_Sinew")
    end
    degradeTool(knife)
    awardXP(player, Perks and (Perks.Butchering or Perks.Trapping), 5)
    removeCorpse(carcass)

    if canonical and FHC.ANIMALS[canonical] then
        updateJournal(player, function(j)
            j.kills[canonical] = (j.kills[canonical] or 0) + 1
            if not j.knownAnimals[canonical] then
                j.knownAnimals[canonical] = U.now()
            end
        end)
    end
end)

S.register(FHC.CMD.DryingComplete, function(player, args)
    if not SB.meatDrying() then return end
    if not V.checkArgs(args, { x = "number", y = "number", z = "number" }) then return end
    if not V.playerNearXYZ(player, args.x, args.y, args.z, 6) then
        return
    end

    local meat = getInvItemById(player, args.meatId)
    local salt = getInvItemById(player, args.saltId)
    local knife = getInvItemById(player, args.knifeId)
    if not meat or not FHC.RAW_MEAT_SET[itemFullType(meat)] then return end
    if not salt or itemFullType(salt) ~= "Base.Salt" then return end
    if SB.requireTools() and not toolIsUsable(knife) then return end

    removeInvItem(player, meat)
    removeInvItem(player, salt)
    degradeTool(knife)
    addInvItem(player, "Base.FHC_DriedMeat")
    awardXP(player, Perks and Perks.Trapping, 4)
end)

S.register(FHC.CMD.HideCureComplete, function(player, args)
    if not SB.hideCuring() then return end
    if not V.checkArgs(args, { x = "number", y = "number", z = "number" }) then return end
    if not V.playerNearXYZ(player, args.x, args.y, args.z, 6) then return end

    local hide = getInvItemById(player, args.hideId)
    local knife = getInvItemById(player, args.knifeId)
    if not hide or itemFullType(hide) ~= "Base.FHC_SaltedHide" then return end
    if SB.requireTools() and not toolIsUsable(knife) then return end

    removeInvItem(player, hide)
    degradeTool(knife)
    addInvItem(player, "Base.FHC_CuredHide")
    awardXP(player, Perks and Perks.Trapping, 8)
    updateJournal(player, function(j) j.hides = (j.hides or 0) + 1 end)
end)

S.register(FHC.CMD.HubCraftComplete, function(player, args)
    if not V.checkArgs(args, { recipeId = "string", selections = "table" }) then return end
    local recipe = FHC.HUB_CRAFTS and FHC.HUB_CRAFTS[args.recipeId]
    local chosen = validateHubCraft(player, recipe, args.selections)
    if not chosen then
        U.warn("HubCraft: rejected " .. tostring(args.recipeId))
        return
    end
    applyHubCraft(player, recipe, chosen)
end)

S.register(FHC.CMD.ApplyScentComplete, function(player, args)
    if not V.checkArgs(args, { animal = "string", itemId = "number" }) then return end
    local item = getInvItemById(player, args.itemId)
    local animalKey = item and FHC.SCENT_BY_ITEM and FHC.SCENT_BY_ITEM[itemFullType(item)] or nil
    if not item or not animalKey or animalKey ~= args.animal then
        U.warn("ApplyScent: rejected " .. tostring(args.animal))
        sendScentResult(player, false, args.animal)
        return
    end
    removeInvItem(player, item)
    if U.applyAnimalScent(player, animalKey, FHC.SCENT_DURATION_HOURS) then
        sendScentResult(player, true, animalKey)
    else
        sendScentResult(player, false, animalKey)
    end
end)

S.register(FHC.CMD.AnimalCallComplete, function(player, args)
    if not V.checkArgs(args, { animal = "string" }) then return end
    local animalKey = args.animal
    if not FHC.ANIMAL_CALLS or not FHC.ANIMAL_CALLS[animalKey] then
        U.warn("AnimalCall: invalid animal " .. tostring(animalKey))
        sendAnimalCallResult(player, false, animalKey, "invalid")
        return
    end
    if not U.playerKnowsAnimalCall(player, animalKey) then
        U.warn("AnimalCall: locked " .. tostring(animalKey))
        sendAnimalCallResult(player, false, animalKey, "locked")
        return
    end
    local remaining = U.getAnimalCallCooldownRemaining(player, animalKey)
    if remaining > 0 then
        sendAnimalCallResult(player, false, animalKey, "cooldown")
        return
    end

    if not U.applyAnimalCall(player, animalKey, FHC.ANIMAL_CALL_DURATION_HOURS) then
        sendAnimalCallResult(player, false, animalKey, "failed")
        return
    end
    if FHC.AttractAnimalsForCall then
        FHC.AttractAnimalsForCall(player, animalKey)
    end
    sendAnimalCallResult(player, true, animalKey, nil)
end)

S.register(FHC.CMD.TrackingScanRequest, function(player, args)
    if not V.checkArgs(args, { radius = "number" }) then return end
    if not requestAllowed(player, FHC.CMD.TrackingScanRequest, math.max(SB.scanThrottleMs(), 500)) then return end
    local maxRadius = trackingMaxRadius()
    local radius = clampRadius(args.radius, maxRadius)
    local rows = scanAnimalsForPlayer(player, radius)
    if sendServerCommand then
        sendServerCommand(player, FHC.MODULE, FHC.CMD.TrackingScanResult,
            { radius = radius, rows = rows })
    end
end)

S.register(FHC.CMD.TrapBoardRequest, function(player, args)
    if not V.checkArgs(args, { radius = "number" }) then return end
    if not requestAllowed(player, FHC.CMD.TrapBoardRequest, 1000) then return end
    local radius = clampRadius(args.radius, TRAP_BOARD_RADIUS)
    local rows = scanTrapsForPlayer(player, radius)
    if sendServerCommand then
        sendServerCommand(player, FHC.MODULE, FHC.CMD.TrapBoardResult,
            { radius = radius, rows = rows })
    end
end)

-- Admin: report population summary back to the requesting admin.
S.register(FHC.CMD.AdminPopReport, function(player, args)
    if not SB.adminPop() or not V.isAdmin(player) then return end
    local counts = {}
    local cell = getCell and getCell() or nil
    if cell and cell.getObjectList then
        local okList, list = U.tryCall(cell, "getObjectList")
        for i = 0, U.listSize(list) - 1 do
            local obj = U.listGet(list, i)
            if U.isLivingAnimal(obj) then
                local okType, t = U.tryCall(obj, "getAnimalType")
                if t then
                    counts[t] = (counts[t] or 0) + 1
                end
            end
        end
    end
    sendServerCommand(player, FHC.MODULE, "popReportResult", { counts = counts })
end)

-- Admin: cull up to N animals of a given type within the requester's cell.
S.register(FHC.CMD.AdminPopCull, function(player, args)
    if not SB.adminPop() or not V.isAdmin(player) then return end
    if not V.checkArgs(args, { animalType = "string", maxCount = "number" }) then return end
    local cap = math.max(0, math.min(args.maxCount, 50))
    if cap == 0 then return end
    local typeLower = string.lower(args.animalType)
    local culled = 0
    local cell = getCell and getCell() or nil
    if not cell then return end
    local okList, list = U.tryCall(cell, "getObjectList")
    local toRemove = {}
    for i = 0, U.listSize(list) - 1 do
        if culled >= cap then break end
        local obj = U.listGet(list, i)
        if U.isLivingAnimal(obj) then
            local okType, t = U.tryCall(obj, "getAnimalType")
            if okType and t and string.lower(tostring(t)) == typeLower then
                table.insert(toRemove, obj)
                culled = culled + 1
            end
        end
    end
    for _, obj in ipairs(toRemove) do
        pcall(function() obj:removeFromWorld(); obj:removeFromSquare() end)
    end
    U.log("Admin " .. tostring(player:getUsername()) .. " culled " .. culled .. " " .. typeLower)
    sendServerCommand(player, FHC.MODULE, "popCullResult", { culled = culled, animalType = typeLower })
end)
